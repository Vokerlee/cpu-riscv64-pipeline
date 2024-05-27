#include <cstdlib>
#include <stdlib.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "elf64_parser.h"
#include "Vdecoder.h"

vluint64_t sim_time = 0;

void run_test(Vdecoder *decoder, VerilatedVcdC *trace, const elf64_parser::Elf64Data &elf_data);

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::cerr << "Required filename argument with binary file" << std::endl;
        exit(EXIT_FAILURE);
    }

    Vdecoder *decoder = new Vdecoder;

    Verilated::traceEverOn(true);
    VerilatedVcdC *trace = new VerilatedVcdC;
    decoder->trace(trace, 5);
    trace->open("waveform.vcd");

    elf64_parser::Elf64Data elf_data = elf64_parser::get_riscv64_elf_data(argv[1]);
    run_test(decoder, trace, elf_data);

    trace->close();
    delete decoder;
    exit(EXIT_SUCCESS);
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

void run_test(Vdecoder *decoder, VerilatedVcdC *trace, const elf64_parser::Elf64Data &elf_data)
{
    size_t code_segment = get_segment_by_addr(elf_data, elf_data.entry);
    size_t segment_offset = elf_data.entry - elf_data.segs[code_segment].start_addr;

    for (size_t instr = 0; instr < (elf_data.segs[code_segment].data.size() -
                                    segment_offset / sizeof(uint32_t)); instr++) {
        decoder->raw_instr = elf_data.segs[code_segment].data[segment_offset / sizeof(uint32_t) + instr];
        decoder->eval();
        sim_time += 1;
        trace->dump(sim_time);
    }
}
