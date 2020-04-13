#include "../support/TestBench.h"
#include "Vtop.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vtop>>();

    const int NumTicksPerState = 3;//tb->m_core->CONFIG_BAUD_TICK;
    const int TickToSample = (NumTicksPerState+1)/2;

    tb->openTrace("trace.vcd");

    auto console = spdlog::stdout_color_mt("simulation");
    console->info("RAM test:");

    // Skip the first tick when the ram data has not yet loaded.
    tb->tick();

    // Run through the design enough to print out the contents twice.
    for(int ii = 0; ii < 1024; ii++) {
        unsigned char val = 
            (tb->m_core->PIN_8 << 7) |
            (tb->m_core->PIN_7 << 6) |
            (tb->m_core->PIN_6 << 5) |
            (tb->m_core->PIN_5 << 4) |
            (tb->m_core->PIN_4 << 3) |
            (tb->m_core->PIN_3 << 2) |
            (tb->m_core->PIN_2 << 1) |
            (tb->m_core->PIN_1);

        if(ii > 0 && (ii % 16) == 0) {
            printf("\n");
        }
        printf("%02x ", val);

        tb->tick();
    }
}