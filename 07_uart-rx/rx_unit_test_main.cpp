#include "../support/TestBench.h"
#include "Vrx_unit_test.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>


#include <memory>

// In simulation we have the states change every 64 ticks, so we have a 
// relatively low number of overall ticks to see if our circuit is working.
constexpr int AmountSimulationTicks = 2000;

// The capital A should trigger the LED to turn on in our 
// unit test.
const char* message = "rAd";
const size_t messageLength = 3;
int messageIdx = 0;

const int WaitingState = -1;
const int StartState = 0;
const int StopState = 9;

int currState = WaitingState;
int stateTick = 0;

unsigned char currByte = message[0];

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vrx_unit_test>>();

    const int NumTicksPerState = 3;//tb->m_core->CONFIG_BAUD_TICK;
    const int TickToSample = (NumTicksPerState+1)/2;

    tb->openTrace("trace.vcd");

    auto console = spdlog::stdout_color_mt("simulation");
    console->info("UART RX unit test!\nNumTicksPerState={}, TickToSample={}", NumTicksPerState, TickToSample);

    // We start with the RX data pin high so we don't start reading in our UART RX core.
    tb->m_core->PIN_1 = 1;

    // Delay a few ticks before starting.
    for(int ii = 0; ii < 10; ii++) {

        tb->tick();
    }

    for(int ii = 0; ii < AmountSimulationTicks; ii++) 
    {
        printf(".");
        tb->tick();

        stateTick++;

        switch(currState) 
        {
            case WaitingState:

                // Keep the line high while not sending anything.
                tb->m_core->PIN_1 = 1;

                // We sit for a few cycles before sending the next byte.
                if(stateTick > 2*NumTicksPerState) {
                    currState = StartState;
                    stateTick = 0;

                    // Keep the line low to begin the start bit.
                    tb->m_core->PIN_1 = 0;
                
                    printf(">"); fflush(stdout);
                }
                break;

            case StartState:
                if(stateTick >= NumTicksPerState) {
                    // Start hitting the default case and reading in bits.
                    currState++;
                    stateTick = 0;

                    // Set the input to the first bit
                    tb->m_core->PIN_1 = currByte & 0x1;
                    printf("%c", tb->m_core->PIN_1 ? '1' : '0');
                }
                else {
                    tb->m_core->PIN_1 = 0;
                }
                break;

            case StopState:
                if(stateTick >= NumTicksPerState) {
                    // Done sending the byte, so move to next one.
                    currState = WaitingState;

                    // Check that our uart rx core received the byte correctly
                    // by checking the simulation debug signal.
                    if(tb->m_core->o_current_rx_byte != message[messageIdx]) {
                        printf("ERROR: Expected uart_rx to have 0x%x '%c' but contains 0x%x '%c'!\n",
                                 message[messageIdx],
                                 message[messageIdx], 
                                 tb->m_core->o_current_rx_byte,
                                 tb->m_core->o_current_rx_byte
                                );
                    }
                    else {
                        printf("\nUART RX Received 0x%x ('%c')\n", tb->m_core->o_current_rx_byte, 
                        tb->m_core->o_current_rx_byte);
                    }

                    messageIdx = (messageIdx + 1) % messageLength;
                    currByte = message[messageIdx];
                    printf("\nNext byte: '%c'\n", currByte);
                    stateTick = 0;
                }

                tb->m_core->PIN_1 = 1;
                break;

            // We assume we're receiving a bit in this state.
            default:
                if(stateTick >= NumTicksPerState) {
                    // Move to next bit, or roll up to StopState
                    currState++;
                    stateTick = 0;

                    // Set the next bit in the sequence
                    currByte >>= 1;

                    if(currState == StopState) {
                        tb->m_core->PIN_1 = 1;
                        printf("<");
                    } 
                    else {
                        tb->m_core->PIN_1 = currByte & 0x1;
                        printf("%c", tb->m_core->PIN_1 ? '1' : '0');
                    }
                }
                break;
        }
    }

    tb->closeTrace();
}
