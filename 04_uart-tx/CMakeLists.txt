cmake_minimum_required(VERSION 3.10)
project(uart VERSION 1.0.0 LANGUAGES CXX)

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
        main.cpp
    )

add_executable (
        uart
        ${SRC_FILES}
    )

foreach(_LIB ${CONAN_LIBS})
    target_link_libraries(uart PRIVATE ${_LIB})
endforeach()

# foreach(_LIB ${CONAN_LIBS_RELEASE})
#     target_link_libraries(uart PRIVATE optimized ${_LIB})
# endforeach()
    
# foreach(_LIB ${CONAN_LIBS_DEBUG})
#     target_link_libraries(uart PRIVATE debug ${_LIB})
# endforeach()

target_include_directories(uart PRIVATE "../support")

# Add the Verilated circuit to the target
verilate (
        uart TRACE
        INCLUDE_DIRS "." "../lib"
        SOURCES ./top.v
        VERILATOR_ARGS "-DSIMULATION" "-Wall"
    )
    
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
  # using Visual Studio C++
  add_definitions(/D_CRT_SECURE_NO_WARNINGS)
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set_target_properties (
        uart PROPERTIES 
        VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    )

add_custom_command (
        TARGET uart POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/../assets ${CMAKE_BINARY_DIR}/bin/assets
    )
