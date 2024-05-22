cmake_minimum_required(VERSION 3.20)

project(memory)

add_executable(tb_memory tb_memory.cpp)
target_compile_features(tb_memory PRIVATE cxx_std_17)
target_compile_options(tb_memory PRIVATE -Wall -Wextra -Wpedantic)

verilate(
    tb_memory
    SOURCES memory.sv
    TRACE BUILD
    INCLUDE_DIRS ${RISCV_PIPELINE_SRC_DIR}
    VERILATOR_ARGS -cc -Wall --exe
)

target_include_directories(
    tb_memory SYSTEM PRIVATE ${VERILATOR_ROOT}/include)
