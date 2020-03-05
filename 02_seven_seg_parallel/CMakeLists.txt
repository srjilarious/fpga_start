cmake_minimum_required(VERSION 3.10)
project(seven_seg_parallel VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(SIM_SRC_FILES 
    main.cpp
    ../support/SevenSegDisplay.cpp
 )

set(SUPPORTING_VERILOG_FILES 
    ../lib/hex_to_7seg.v
 )

 # Call our project macro to setup simulation and synthesis projects
fpga_project(
    TARGET seven_seg_parallel
    SYNTH_BY_DEFAULT
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG top.v
    SUPPORT_VERILOG ${SUPPORTING_VERILOG_FILES}
  )

add_custom_command (
        TARGET seven_seg_parallel POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/../assets ${CMAKE_BINARY_DIR}/bin/assets
    )
