cmake_minimum_required(VERSION 3.10)
project(uart_rx VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(SIM_SRC_FILES 
    rx_unit_test_main.cpp
 )

set(SUPPORTING_VERILOG_FILES 
    ../lib/uart_rx.v
 )

 # Call our project macro to setup simulation and synthesis projects
fpga_project(
    TARGET uart_rx
    SYNTH_BY_DEFAULT
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG rx_unit_test.v
    SUPPORT_VERILOG ${SUPPORTING_VERILOG_FILES}
  )
