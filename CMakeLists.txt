# Copyright 2025 Roland Metivier
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may 
# not use this file except in compliance with the License, or, at your option, 
# the Apache License version 2.0.
#
# You may obtain a copy of the License at
#
# https://solderpad.org/licenses/SHL-2.1/
#
# Unless required by applicable law or agreed to in writing, any work distributed 
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
# CONDITIONS OF ANY KIND, either express or implied.
#
# See the License for the specific language governing permissions and limitations 
# under the License.
# Minimum version is CMake 3.26
cmake_minimum_required(VERSION 3.26)

# Export compile commands for the language server
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Project instantiation
project(ibis VERSION 0.1.0.23)

# Find Verilator package
find_package(verilator REQUIRED HINTS $ENV{VERILATOR_ROOT})

# Find raylib
find_package(raylib REQUIRED VERSION 5.5)

# Configure the project header
configure_file(include/configuration.txt
    ${PROJECT_SOURCE_DIR}/include/configuration.hpp)

# Glob test cases
file(GLOB ${PROJECT_NAME}_TESTS "src/test_*.cpp")

# Build our main executable
add_executable(${PROJECT_NAME}
    src/con.cpp
    ${${PROJECT_NAME}_TESTS}
    src/test.cpp
    src/framebuffer.cpp
    src/main.cpp)

verilate(${PROJECT_NAME} PREFIX Vibis_tmds_encoder SOURCES
  rtl/ibis_tmds_encoder.sv
  rtl/ibis_popcnt6.sv)
verilate(${PROJECT_NAME} PREFIX Vibis_vga_timing SOURCES
  rtl/ibis_vga_timing.sv)
verilate(${PROJECT_NAME} PREFIX Vibis_popcnt6 SOURCES
  rtl/ibis_popcnt6.sv)
verilate(${PROJECT_NAME} PREFIX Vibis_texture_mapper SOURCES
  rtl/ibis_texture_mapper.sv)
verilate(${PROJECT_NAME} PREFIX Vibis_blitter SOURCES
  rtl/ibis_blitter.sv)

# Use C++23 on target too
set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD_REQUIRED TRUE)
set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD 23)

# Include headers here
target_include_directories(${PROJECT_NAME} PRIVATE include)

# Finally link
target_link_libraries(${PROJECT_NAME} PRIVATE raylib)
