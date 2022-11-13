#include "../support/TestBench.h"
#include "Vblinky_ice40.h"

#include <memory>

// 1048576 is the number of ticks until the 20th bit of num_counter will 
// change.
const int NumSimulationTicks = 1048576 + 100;

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vblinky_ice40>>();

    tb->openTrace("trace.vcd");

    for(int ii = 0; ii < NumSimulationTicks; ii++)
    {
        tb->tick();
    }

    tb->closeTrace();
}
