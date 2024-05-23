cmake_minimum_required(VERSION 3.20)

project(alu)

add_executable(tb_alu tb_alu.cpp)
target_compile_features(tb_alu PRIVATE cxx_std_17)
target_compile_options(tb_alu PRIVATE -Wall -Wextra -Wpedantic)

verilate(
    tb_alu
    SOURCES alu.sv
    TRACE BUILD
    INCLUDE_DIRS ${RISCV_PIPELINE_SRC_DIR}
    VERILATOR_ARGS -cc -Wall --exe
)

target_include_directories(
    tb_alu SYSTEM PRIVATE ${VERILATOR_ROOT}/include)
