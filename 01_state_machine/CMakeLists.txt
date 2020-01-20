cmake_minimum_required(VERSION 3.11)
project(state_machine VERSION 1.0.0 LANGUAGES CXX)

#Find verilator
find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Use C++ 17 standard.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(SRC_FILES 
    main.cpp
    )

add_executable(
    state_machine 
    ${SRC_FILES}
    )

# Add the Verilated circuit to the target
verilate(state_machine TRACE
    INCLUDE_DIRS "." "../lib"
    SOURCES ./top.v)

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
  # using Visual Studio C++
  add_definitions(/D_CRT_SECURE_NO_WARNINGS)
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set_target_properties(state_machine PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

