cmake_minimum_required(VERSION 3.10)
project(text_screen VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(SIM_SRC_FILES 
    main.cpp
 )

set(SUPPORTING_VERILOG_FILES 
    tile_layer.v
    ../lib/vga_controller.v
 )

 # Call our project macro to setup simulation and synthesis projects
fpga_project(
    TARGET text_screen
    SYNTH_BY_DEFAULT
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG top.v
    SUPPORT_VERILOG ${SUPPORTING_VERILOG_FILES}
  )

# The synth target needs the ram contents file in the build directory.
add_custom_command (
    TARGET text_screen_synth PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_CURRENT_SOURCE_DIR}/ram_contents.mem ${CMAKE_BINARY_DIR}/ram_contents.mem
)
add_custom_command (
    TARGET text_screen_synth PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_CURRENT_SOURCE_DIR}/text_buffer.mem ${CMAKE_BINARY_DIR}/ram_contents.mem
)

# The simulation loads the ram contents when run, which we assume is run from within the /bin directory.
add_custom_command (
    TARGET text_screen PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_CURRENT_SOURCE_DIR}/ram_contents.mem ${CMAKE_BINARY_DIR}/bin/ram_contents.mem
)
add_custom_command (
    TARGET text_screen PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_CURRENT_SOURCE_DIR}/text_buffer.mem ${CMAKE_BINARY_DIR}/bin/ram_contents.mem
)
