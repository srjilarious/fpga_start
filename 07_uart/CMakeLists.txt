cmake_minimum_required(VERSION 3.10)
project(uart_loopback VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(SIM_SRC_FILES 
    loopback_main.cpp
 )

set(SUPPORTING_VERILOG_FILES 
    ../lib/uart_tx.v
    ../lib/uart_rx.v
 )

 # Call our project macro to setup simulation and synthesis projects
fpga_project(
    TARGET uart_loopback
    SYNTH_BY_DEFAULT
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG loopback.v
    SUPPORT_VERILOG ${SUPPORTING_VERILOG_FILES}
  )
