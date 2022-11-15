#include <verilated_vcd_c.h>
#include <memory>

template<class MODULE>
class TestBench 
{
protected:
    unsigned long	mTickCount;
    std::unique_ptr<VerilatedVcdC>	mTrace;

public:
    std::unique_ptr<MODULE>	mCore;
    
    TestBench(void) : mTickCount(0l), mTrace(nullptr) {
        // According to the Verilator spec, you *must* call
        // traceEverOn before calling any of the tracing functions
        // within Verilator.
        Verilated::traceEverOn(true);

        mCore = std::make_unique<MODULE>();
    }

    virtual ~TestBench(void) = default;

    // Open/create a trace file
    virtual	void openTrace(const char *vcdname) {
        if (!mTrace) {
            mTrace = std::make_unique<VerilatedVcdC>();
            mCore->trace(mTrace.get(), 99);
            mTrace->open(vcdname);
        }
    }

    // Close a trace file
    virtual void closeTrace(void) {
        if (mTrace) {
            mTrace->close();
            mTrace = nullptr;
        }
    }

    // virtual void reset(void) {
    //     //mCore->i_reset = 1;
    //     // Make sure any inheritance gets applied
    //     tick();
    //     //mCore->i_reset = 0;
    // }

    virtual void tick(void) {
        // Increment our own internal time reference
        mTickCount++;

        // Make sure any combinatorial logic depending upon
        // inputs that may have changed before we called tick()
        // has settled before the rising edge of the clock.
        setClock(0);
        mCore->eval();

        if(mTrace) mTrace->dump((vluint64_t)10*mTickCount-2);

        // Toggle the clock

        // Rising edge
        setClock(1);
        mCore->eval();

        if(mTrace) mTrace->dump((vluint64_t)10*mTickCount);

        // Falling edge
        setClock(0);
        mCore->eval();

        if (mTrace) {
            // This portion, though, is a touch different.
            // After dumping our values as they exist on the
            // negative clock edge ...
            mTrace->dump((vluint64_t)10*mTickCount+5);
            //
            // We'll also need to make sure we flush any I/O to
            // the trace file, so that we can use the assert()
            // function between now and the next tick if we want to.
            mTrace->flush();
        }
    }

    // Abstract method that a simulation must override to let us set
    // the clock signal.
    virtual void setClock(uint8_t val) = 0;

    virtual bool isDone(void) { return (Verilated::gotFinish()); }
};

