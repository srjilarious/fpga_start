cmake_minimum_required(VERSION 3.10)
project(vga_test VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(SIM_SRC_FILES 
    main.cpp
 )

set(SUPPORTING_VERILOG_FILES 
    test_pattern.v
    ../lib/vga_controller.v
 )

 # Call our project macro to setup simulation and synthesis projects
fpga_project(
    TARGET vga_test
    SYNTH_BY_DEFAULT
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG top.v
    SUPPORT_VERILOG ${SUPPORTING_VERILOG_FILES}
  )
