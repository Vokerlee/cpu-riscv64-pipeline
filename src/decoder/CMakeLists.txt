cmake_minimum_required(VERSION 3.20)

project(decoder)

add_executable(tb_decoder tb_decoder.cpp)
target_compile_features(tb_decoder PRIVATE cxx_std_17)
target_compile_options(tb_decoder PRIVATE -Wall -Wextra -Wpedantic
    -I${RISCV_PIPELINE_INC_DIR})

verilate(
    tb_decoder
    SOURCES decoder.sv
    TRACE BUILD
    INCLUDE_DIRS ${RISCV_PIPELINE_SRC_DIR}
    VERILATOR_ARGS -cc -Wall --exe -Wno-UNUSEDSIGNAL
)

target_include_directories(
    tb_decoder SYSTEM PRIVATE ${VERILATOR_ROOT}/include)
