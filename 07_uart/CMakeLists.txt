cmake_minimum_required(VERSION 3.10)
project(uart_rx VERSION 1.0.0 LANGUAGES CXX)

#Find verilator
find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Use C++ 17 standard.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Add all of our conan packages to our build.
include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
#include(${CMAKE_BINARY_DIR}/conanbuildinfo_multi.cmake)
conan_basic_setup()

set ( 
        SRC_FILES 
        loopback_main.cpp
    )

add_executable (
        uart_loopback
        ${SRC_FILES}
    )

target_link_libraries(uart_loopback PRIVATE ${CONAN_LIBS})

# foreach(_LIB ${CONAN_LIBS_RELEASE})
#     target_link_libraries(uart PRIVATE optimized ${_LIB})
# endforeach()
    
# foreach(_LIB ${CONAN_LIBS_DEBUG})
#     target_link_libraries(uart PRIVATE debug ${_LIB})
# endforeach()

target_include_directories(uart_loopback PRIVATE "../support")

# Add the Verilated circuit to the target
verilate (
        uart_loopback TRACE
        INCLUDE_DIRS "." "../lib"
        SOURCES ./loopback.v
        VERILATOR_ARGS "-DSIMULATION" "-Wall"
    )
    
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
  # using Visual Studio C++
  add_definitions(/D_CRT_SECURE_NO_WARNINGS)
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set_target_properties (
        uart_loopback PROPERTIES 
        VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    )


# Custom target to run yosys synthesis steps
add_custom_target(uart_loopback_synth)

set(YOYSYS_DIR /mnt/d/code/tools/yosys/bin)
set(ICE40_DIR /mnt/d/code/tools/ice40/bin)
message("CMAKE BINARY DIR: ${CMAKE_BINARY_DIR}")

set(YOSYS_ARGS -p "verilog_defaults -add -I ${CMAKE_BINARY_DIR}/../../lib\; read_verilog ${CMAKE_BINARY_DIR}/../../lib/uart_tx.v\; read_verilog ${CMAKE_BINARY_DIR}/../../lib/uart_rx.v\; synth_ice40 -top loopback -json hardware.json" -q ${CMAKE_BINARY_DIR}/../loopback.v)
message("HAVE ARGS ${YOSYS_ARGS}")

add_custom_command(
  TARGET uart_loopback_synth
  COMMAND yosys ARGS ${YOSYS_ARGS}
  VERBATIM
  )

set(NEXTPNR_ARGS --lp8k --package cm81 --json hardware.json --pcf ${CMAKE_BINARY_DIR}/../pins.pcf --asc hardware.asc -q)
add_custom_command(
  TARGET uart_loopback_synth
  DEPENDS hardware.json
  COMMAND nextpnr-ice40 ARGS ${NEXTPNR_ARGS}
  VERBATIM
  )

set(ICEPACK_ARGS hardware.asc loopback.bin)
add_custom_command(
  TARGET uart_loopback_synth
  DEPENDS hardware.asc
  COMMAND icepack ARGS ${ICEPACK_ARGS}
  VERBATIM
  )

