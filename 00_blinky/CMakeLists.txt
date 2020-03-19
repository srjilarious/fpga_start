cmake_minimum_required(VERSION 3.10)
project(blinky VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(SIM_SRC_FILES 
    main.cpp
 )

# Call our project macro to setup simulation and synthesis projects
fpga_project(
    TARGET blinky
    SYNTH_BY_DEFAULT
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG top.v
  )
