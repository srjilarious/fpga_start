#include "../support/TestBench.h"
#include "obj_dir/Vtop.h"

#include <memory>

// In simulation we have the states change every 64 ticks, so we have a 
// relatively low number of overall ticks to see if our circuit is working.
const int NumSimulationTicks = 600;

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vtop>>();

    tb->openTrace("trace.vcd");

    for(int ii = 0; ii < NumSimulationTicks; ii++)
    {
        tb->tick();
    }

    tb->closeTrace();
}
