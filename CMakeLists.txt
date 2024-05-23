cmake_minimum_required(VERSION 3.20)
project(riscv_pipeline)

set(RISCV_PIPELINE_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(RISCV_PIPELINE_INC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)

set(RISCV_PIPELINE_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${RISCV_PIPELINE_BINARY_DIR}/bin)

find_package(verilator)

if (NOT verilator_FOUND)
    message(
      FATAL_ERROR
      "Verilator was not found."
    )
endif()

# add_executable(core src/core.cpp)
# target_compile_features(core PRIVATE cxx_std_17)
# target_compile_options(core PRIVATE -Wall -Wextra -Wpedantic)

# verilate(
#     core
#     SOURCES src/reg_file.sv
#     TRACE BUILD
#     VERILATOR_ARGS -cc -Wall --exe
# )

# target_include_directories(
#   core SYSTEM PRIVATE ${VERILATOR_ROOT}/include)

add_subdirectory(${RISCV_PIPELINE_SRC_DIR}/reg_file)
add_subdirectory(${RISCV_PIPELINE_SRC_DIR}/memory)
add_subdirectory(${RISCV_PIPELINE_SRC_DIR}/decoder)
