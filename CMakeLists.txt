# Minimum version is CMake 3.26
cmake_minimum_required(VERSION 3.26)

# Export compile commands for the language server
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Project instantiation
project(ibis VERSION 0.1.0.6)

# Find Verilator package
find_package(verilator REQUIRED HINTS $ENV{VERILATOR_ROOT})

# Configure the project header
configure_file(include/configuration.txt
    ${PROJECT_SOURCE_DIR}/include/configuration.hpp)

# Build our main executable
add_executable(${PROJECT_NAME}
    src/con.cpp
    src/test.cpp
    src/main.cpp)

verilate(${PROJECT_NAME} PREFIX Vibis_ripple_carry SOURCES
  rtl/ibis_ripple_carry.sv)
verilate(${PROJECT_NAME} PREFIX Vibis_tmds_encoder SOURCES
  rtl/ibis_tmds_encoder.sv)
verilate(${PROJECT_NAME} PREFIX Vibis_vga_timing SOURCES
  rtl/ibis_vga_timing.sv
  rtl/ibis_phase_accumulator_dual.sv
  rtl/ibis_phase_accumulator.sv)
verilate(${PROJECT_NAME} PREFIX Vibis_phase_accumulator SOURCES
  rtl/ibis_phase_accumulator.sv)
verilate(${PROJECT_NAME} PREFIX Vibis_phase_accumulator_dual SOURCES
  rtl/ibis_phase_accumulator_dual.sv
  rtl/ibis_phase_accumulator.sv)

# Use C++20 on target too
set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD_REQUIRED TRUE)
set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD 20)

# Include headers here
target_include_directories(${PROJECT_NAME} PRIVATE include)

# Finally link
target_link_libraries(${PROJECT_NAME})
