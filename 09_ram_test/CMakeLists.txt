cmake_minimum_required(VERSION 3.10)
project(uart_loopback VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(SIM_SRC_FILES 
    main.cpp
 )

# set(SUPPORTING_VERILOG_FILES 
#     ../lib/uart_tx.v
#     ../lib/uart_rx.v
#  )

 # Call our project macro to setup simulation and synthesis projects
fpga_project(
    TARGET ram_test
    SYNTH_BY_DEFAULT
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG top.v
  )

# The synth target needs the ram contents file in the build directory.
add_custom_command (
    TARGET ram_test_synth PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_CURRENT_SOURCE_DIR}/ram_contents.mem ${CMAKE_BINARY_DIR}/ram_contents.mem
)

# The simulation loads the ram contents when run, which we assume is run from within the /bin directory.
add_custom_command (
    TARGET ram_test PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_CURRENT_SOURCE_DIR}/ram_contents.mem ${CMAKE_BINARY_DIR}/bin/ram_contents.mem
)