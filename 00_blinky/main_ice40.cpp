#include "../support/TestBench.h"
#include "Vblinky_ice40.h"

#include <memory>
#include <cstdint>

// 1048576 is the number of ticks until the 20th bit of num_counter will 
// change.
const int NumSimulationTicks = 1048576 + 100;

struct TB : public TestBench<Vblinky_ice40>
{
    virtual ~TB() = default;

    // We overload the setClock signal method so we can reference different
    // clock signals for different FPGA boards.
    void setClock(uint8_t val) { mCore->CLK = val; }
};

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
