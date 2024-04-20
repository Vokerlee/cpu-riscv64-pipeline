cmake_minimum_required(VERSION 3.20)
project(riscv_pipeline)

find_package(verilator)

if (NOT verilator_FOUND)
    message(
      FATAL_ERROR
      "Verilator was not found."
    )
endif()

add_executable(core src/Vcore_logic.cpp)
target_compile_features(core PRIVATE cxx_std_17)
target_compile_options(core PRIVATE -Wall -Wextra -Wpedantic)

verilate(
    core
    SOURCES src/core_logic.sv
    -Isrc
    TRACE
    VERILATOR_ARGS -cc -Wall --exe
)

target_include_directories(
  core SYSTEM PRIVATE ${VERILATOR_ROOT}/include)