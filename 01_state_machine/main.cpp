#include "../support/TestBench.h"
#include "Vstate_machine.h"

#include <memory>


struct TB : public TestBench<Vstate_machine>
{
    virtual ~TB() = default;

    // We overload the setClock signal method so we can reference different
    // clock signals for different FPGA boards.
    void setClock(uint8_t val) { mCore->i_clk = val; }
};

// In simulation we have the states change every 64 ticks, so we have a 
// relatively low number of overall ticks to see if our circuit is working.
const int NumSimulationTicks = 600;

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    TB tb;

    tb.openTrace("trace.vcd");

    for(int ii = 0; ii < NumSimulationTicks; ii++)
    {
        tb.tick();
    }

    tb.closeTrace();
}
