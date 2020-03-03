#include "../support/TestBench.h"
#include "Vtx_unit_test.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>


#include <memory>

// In simulation we have the states change every 64 ticks, so we have a 
// relatively low number of overall ticks to see if our circuit is working.
constexpr int AmountSimulationTicks = 2000;

const int WaitingState = -1;
const int StartState = 0;
const int StopState = 9;

int currState = WaitingState;
int stateTick = 0;
unsigned char currByte = 0;

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vtx_unit_test>>();

    const int NumTicksPerState = 3;//tb->m_core->CONFIG_BAUD_TICK;
    const int TickToSample = (NumTicksPerState+1)/2;

    tb->openTrace("trace.vcd");

    auto console = spdlog::stdout_color_mt("simulation");
    console->info("UART TX simulation!\nNumTicksPerState={}, TickToSample={}", NumTicksPerState, TickToSample);



    for(int ii = 0; ii < AmountSimulationTicks; ii++) 
    {
        tb->tick();

        switch(currState) 
        {
            case WaitingState:
                // We sit here and wait for the data line to be pulled low.
                if(tb->m_core->PIN_1 == 0) {
                    currState = StartState;
                    stateTick = 0;
                    //printf(">"); fflush(stdout);
                }
                break;

            case StartState:
                stateTick++;

                // Sample the data line in the middle of the current bit waveform.
                if(stateTick == TickToSample) {
                    // If the start signal is not low, something went wrong.
                    if(tb->m_core->PIN_1 != 0) {
                        currState = WaitingState;
                        //printf("!"); fflush(stdout);
                    }
                }
                else if(stateTick >= NumTicksPerState) {
                    // Start hitting the default case and reading in bits.
                    currState++;
                    stateTick = 0;
                }
                break;

            case StopState:
                stateTick++;

                // Sample the data line in the middle of the current bit waveform.
                if(stateTick == TickToSample) {
                    // If the start signal is not high, something went wrong,
                    // so throw away the byte and start over.
                    if(tb->m_core->PIN_1 != 1) {
                        currByte = 0;
                        currState = WaitingState;
                        //printf("!"); fflush(stdout);
                    }
                }
                else if(stateTick >= NumTicksPerState) {
                    // Done reading the byte, so print it out.
                    currState = WaitingState;
                    //printf(" '%c'(0x%02x)\n", currByte, currByte);
                    printf("%c", currByte);
                    stateTick = 0;
                }
                break;

            // We assume we're receiving a bit in this state.
            default:
                stateTick++;
                // Sample the data line in the middle of the current bit waveform.
                if(stateTick == TickToSample) {
                    // Sample the current bit
                    currByte = (currByte >> 1) | (tb->m_core->PIN_1<<7);
                    //printf("%c", tb->m_core->PIN_1 ? '1' : '0'); fflush(stdout);

                }
                else if(stateTick >= NumTicksPerState) {
                    // Move to next bit, or roll up to StopState
                    currState++;
                    stateTick = 0;
                }
                break;
        }
    }

    tb->closeTrace();
}
