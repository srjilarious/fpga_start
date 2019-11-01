
#include <verilated_vcd_c.h>


template<class MODULE>	
class TestBench 
{
protected:
    unsigned long	m_tickcount;
    VerilatedVcdC	*m_trace;

public:
    MODULE	*m_core;
    
    TestBench(void) : m_tickcount(0l), m_trace(nullptr) {
        // According to the Verilator spec, you *must* call
        // traceEverOn before calling any of the tracing functions
        // within Verilator.
        Verilated::traceEverOn(true);

        m_core = new MODULE;
    }

    virtual ~TestBench(void) {
        delete m_core;
        m_core = NULL;
    }

    // Open/create a trace file
    virtual	void openTrace(const char *vcdname) {
        if (!m_trace) {
            m_trace = new VerilatedVcdC;
            m_core->trace(m_trace, 99);
            m_trace->open(vcdname);
        }
    }

    // Close a trace file
    virtual void closeTrace(void) {
        if (m_trace) {
            m_trace->close();
            m_trace = NULL;
        }
    }

    virtual void reset(void) {
        //m_core->i_reset = 1;
        // Make sure any inheritance gets applied
        this->tick();
        //m_core->i_reset = 0;
    }

    virtual void tick(void) {
        // Increment our own internal time reference
        m_tickcount++;


        // Make sure any combinatorial logic depending upon
        // inputs that may have changed before we called tick()
        // has settled before the rising edge of the clock.
        m_core->CLK = 0;
        m_core->eval();

        if(m_trace) m_trace->dump((vluint64_t)10*m_tickcount-2);

        // Toggle the clock

        // Rising edge
        m_core->CLK = 1;
        m_core->eval();

        if(m_trace) m_trace->dump((vluint64_t)10*m_tickcount);

        // Falling edge
        m_core->CLK = 0;
        m_core->eval();

        if (m_trace) {
            // This portion, though, is a touch different.
            // After dumping our values as they exist on the
            // negative clock edge ...
            m_trace->dump((vluint64_t)10*m_tickcount+5);
            //
            // We'll also need to make sure we flush any I/O to
            // the trace file, so that we can use the assert()
            // function between now and the next tick if we want to.
            m_trace->flush();
        }
    }

    virtual bool isDone(void) { return (Verilated::gotFinish()); }
};

