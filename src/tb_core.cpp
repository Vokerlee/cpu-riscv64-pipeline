#include <cstdlib>
#include <cstring>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "elf64_parser.h"
#include "Vcore.h"
#include "Vcore_core.h"
#include "Vcore_memory.h"
#include "Vcore_pc.h"
#include "Vcore_reg_file.h"

vluint64_t sim_time = 0;

void run_test(Vcore *core, VerilatedVcdC *trace, elf64_parser::Elf64Data *elf_data);

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::cerr << "Required filename argument with binary file" << std::endl;
        exit(EXIT_FAILURE);
    }

    Vcore *core = new Vcore;

    Verilated::traceEverOn(true);
    VerilatedVcdC *trace = new VerilatedVcdC;
    core->trace(trace, 5);
    trace->open("waveform.vcd");

    elf64_parser::Elf64Data elf_data = elf64_parser::get_riscv64_elf_data(argv[1]);
    run_test(core, trace, &elf_data);

    trace->close();
    delete core;
    exit(EXIT_SUCCESS);
}

void tick(Vcore *core, VerilatedVcdC *trace)
{
    core->clk ^= 1;
    core->eval();

    sim_time += 1;
    trace->dump(sim_time);
}

void cycle(Vcore *core, VerilatedVcdC *trace)
{
    tick(core, trace);
    tick(core, trace);
}

void n_cycles(Vcore *core, VerilatedVcdC *trace, size_t n_cycles)
{
    for (size_t i = 0; i < n_cycles; ++i) {
        cycle(core, trace);
    }
}

size_t get_segment_by_addr(const elf64_parser::Elf64Data &elf_data, size_t entry_point)
{
    for (size_t i = 0; i < elf_data.segs.size(); ++i) {
        if (entry_point >= elf_data.segs[i].start_addr &&
            entry_point < (elf_data.segs[i].start_addr +
                           elf_data.segs[i].data.size() * sizeof(uint32_t)))
            return i;
    }

    return -1;
}

void run_test(Vcore *core, VerilatedVcdC *trace, elf64_parser::Elf64Data *elf_data)
{
    size_t code_segment = get_segment_by_addr(*elf_data, elf_data->entry);
    std::memcpy(reinterpret_cast<uint8_t *>(&core->core->instr_memory->buffer.m_storage) +
                elf_data->segs[code_segment].start_addr,
                elf_data->segs[code_segment].data.data(),
                elf_data->segs[code_segment].data.size() * sizeof(uint32_t));

    // core->core->valid_writeback = 1;
    core->core->reg_file->file[0x02] = 0x100000; // stack pointer
    core->core->pc->pc_val = elf_data->entry;

    size_t n_max_ticks = 1000;
    do {
    // while (true) {
        tick(core, trace);

        if (--n_max_ticks == 0)
            break;
    } while (core->core->enable_writeback == 1);
}
