VC=verilator

VERILOG_CODE=top.v
TEST_BENCH=main.cpp
TEST_NAME=state_machine_1
ENABLE_TRACE=1

VERILATOR_TRACE=
ifeq ($(ENABLE_TRACE), 1)
	VERILATOR_TRACE=--trace
	CPP_TRACE=-DVERILATOR_TRACE
endif

state_machine_1:
	$(VC) $(VERILATOR_TRACE) -DSIMULATION -Wall -y ../lib  -CFLAGS "--std=c++14 -I../support $(CPP_TRACE)" --cc $(VERILOG_CODE) --exe $(TEST_BENCH) && \
	cd obj_dir && \
	make -f ./Vtop.mk && \
	cp ./Vtop ../$(TEST_NAME)
