#include "../support/TestBench.h"
#include "Vloopback.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <memory>


// Extracted code from the uart-tx test bench for rxing a byte from our uart-
// tx core.
class Uart
{
    enum RxState : int {
        RxWaitingState = -1,
        RxStartState = 0,
        RxStopState = 9
    };

    enum TxState : int {
        TxWaitingState = -1,
        TxStartState = 0,
        TxStopState = 9
    };

public:
    Uart(int numTicksPerState);

    // Process the simulated UART.  Return true when a byte has been received.
    bool process(bool input, bool& pinOut);
    bool canSendByte() const { return mTxState == TxState::TxWaitingState; }
    void beginSendChar(unsigned char c);

    char getReceivedByte() const { return static_cast<char>(mCurrRxData); }

private:
    int mRxState = RxState::RxWaitingState;
    int mTxState = TxState::TxWaitingState;

    int mRxStateTick = 0;
    int mTxStateTick = 0;

    int mNumTicksPerState;
    int mTickToSample;

    unsigned char mCurrTxData;
    unsigned char mCurrRxData;

    bool processRx(bool input);
    void processTx(bool& pinOut);
};

Uart::Uart(int numTicksPerState) 
    : mNumTicksPerState(numTicksPerState),
      mTickToSample((numTicksPerState+1)/2)
{
}

bool
Uart::processRx(bool input) 
{
    mRxStateTick++;

    bool finishedRead = false;
    switch(mRxState) 
    {
        case RxState::RxWaitingState:
            // We sit here and wait for the data line to be pulled low.
            if(input == 0) {
                mRxState = RxState::RxStartState;
                mRxStateTick = 0;
                mCurrRxData = 0;
                //printf(">"); fflush(stdout);
            }
            break;

        case RxState::RxStartState:
            // Sample the data line in the middle of the current bit waveform.
            if(mRxStateTick == mTickToSample) {
                // If the start signal is not low, something went wrong.
                if(input != 0) {
                    mRxState = RxState::RxWaitingState;
                    printf("!"); fflush(stdout);
                }
            }
            else if(mRxStateTick >= mNumTicksPerState) {
                // Start hitting the default case and reading in bits.
                mRxState++;
                mRxStateTick = 0;
            }
            break;

        case RxState::RxStopState:
            // Sample the data line in the middle of the current bit waveform.
            if(mRxStateTick == mTickToSample) {
                // If the start signal is not high, something went wrong,
                // so throw away the byte and start over.
                if(input != 1) {
                    mCurrRxData = 0;
                    mRxState = RxState::RxWaitingState;
                    printf("!"); fflush(stdout);
                }
            }
            else if(mRxStateTick >= mNumTicksPerState) {
                // Done reading the byte, so print it out.
                mRxState = RxState::RxWaitingState;
                //printf(" '%c'(0x%02x)\n", mCurrRxData, mCurrRxData);
                mRxStateTick = 0;
                finishedRead = true;
            }
            break;

        // We assume we're receiving a bit in this state.
        default:
            // Sample the data line in the middle of the current bit waveform.
            if(mRxStateTick == mTickToSample) {
                // Sample the current bit
                mCurrRxData = (input<<7) | (mCurrRxData >> 1);
                //printf("%c", input ? '1' : '0'); fflush(stdout);
            }
            else if(mRxStateTick >= mNumTicksPerState) {
                // Move to next bit, or roll up to StopState
                mRxState++;
                mRxStateTick = 0;
            }
            break;
    }

    return finishedRead;
}

void
Uart::processTx(bool& pinOut) 
{
    mTxStateTick++;

    switch(mTxState) 
    {
        case TxState::TxWaitingState:
            // Keep the line high while not sending anything.
            pinOut = 1;
            break;

        case TxState::TxStartState:
            if(mTxStateTick >= mNumTicksPerState) {
                // Start hitting the default case and reading in bits.
                mTxState++;
                mTxStateTick = 0;

                // Set the input to the first bit
                pinOut = mCurrTxData & 0x1;
                //printf("%c", pinOut ? '1' : '0');
            }
            else {
                pinOut = 0;
            }
            break;

        case TxState::TxStopState:
            if(mTxStateTick >= mNumTicksPerState) {
                // Done sending the byte, so move to next one.
                mTxState = TxState::TxWaitingState;
                mTxStateTick = 0;
            }

            pinOut = 1;
            break;

        // We assume we're receiving a bit in this state.
        default:
            if(mTxStateTick >= mNumTicksPerState) {
                // Move to next bit, or roll up to StopState
                mTxState++;
                mTxStateTick = 0;

                if(mTxState == TxState::TxStopState) {
                    pinOut = 1;
                } 
                else {
                    // Set the next bit in the sequence
                    mCurrTxData >>= 1;
                    pinOut = mCurrTxData & 0x1;
                }
            }
            break;
    }
}

bool
Uart::process(bool input, bool& pinOut) 
{
    processTx(pinOut);
    return processRx(input);
}

void 
Uart::beginSendChar(unsigned char c)
{
    mCurrTxData = c;
    mTxState = TxState::TxStartState;

    // We need the pin to go low for the start state one more.
    mTxStateTick = -1;
}

const std::string message = "Testing testing, hello world!\n";
int messageIdx = 0;

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vloopback>>();

    //tb->openTrace("trace.vcd");

    auto console = spdlog::stdout_color_mt("simulation");
    console->info("UART Loopback simulation!");

    tb->m_core->PIN_1 = 1;
    for(int ii = 0; ii < 10; ii++) tb->tick();
    
    Uart uart(tb->m_core->CONFIG_BAUD_TICK);

    uart.beginSendChar(message[messageIdx++]);

    // Pulled high means no data to send yet.
    bool pinOut = true;
    while(true)
    {
        tb->tick();

        // Match the verilog module's RX to our TX and its TX to our RX.
        if(uart.process(tb->m_core->PIN_2, pinOut)) {
            printf("%c", uart.getReceivedByte());
            fflush(stdin);

            uart.beginSendChar(message[messageIdx]);
            messageIdx = (++messageIdx) % message.size();
        }

        tb->m_core->PIN_1 = pinOut;
    }

    tb->closeTrace();
}
