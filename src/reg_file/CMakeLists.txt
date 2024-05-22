cmake_minimum_required(VERSION 3.20)

project(reg_file)

add_executable(tb_reg_file tb_reg_file.cpp)
target_compile_features(tb_reg_file PRIVATE cxx_std_17)
target_compile_options(tb_reg_file PRIVATE -Wall -Wextra -Wpedantic)

verilate(
    tb_reg_file
    SOURCES reg_file.sv
    TRACE BUILD
    INCLUDE_DIRS ${RISCV_PIPELINE_SRC_DIR}
    VERILATOR_ARGS -cc -Wall --exe
)

target_include_directories(
    tb_reg_file SYSTEM PRIVATE ${VERILATOR_ROOT}/include)
