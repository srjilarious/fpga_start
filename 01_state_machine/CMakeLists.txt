cmake_minimum_required(VERSION 3.10)
project(state_machine VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(MAIN_VERILOG_FILE
    top.v
  )
set(SIM_SRC_FILES 
    main.cpp
 )

set(SFML_SIM_SRC_FILES 
    main_sfml.cpp
  )

# Do some initialization like find verilator, include conan, etc.
fpga_project_setup()

fpga_simulation_project(
    TARGET state_machine
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG ${MAIN_VERILOG_FILE}
  )

# Add a second simulation target using SFML.
fpga_simulation_project(
    TARGET state_machine_sfml
    SIM_SRC_FILES ${SFML_SIM_SRC_FILES}
    TOP_LEVEL_VERILOG ${MAIN_VERILOG_FILE}
  )

ice40_synthesis(
    TARGET state_machine_synth
    SYNTH_BY_DEFAULT
    TOP_LEVEL_VERILOG ${MAIN_VERILOG_FILE}
    PCF_FILE pins.pcf
  )
