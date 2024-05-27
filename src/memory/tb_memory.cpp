#include <stdlib.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vmemory.h"

vluint64_t sim_time = 0;

void run_test(Vmemory *memory, VerilatedVcdC *trace);

int main()
{
    Vmemory *memory = new Vmemory;

    Verilated::traceEverOn(true);
    VerilatedVcdC *trace = new VerilatedVcdC;
    memory->trace(trace, 5);
    trace->open("waveform.vcd");

    run_test(memory, trace);

    trace->close();
    delete memory;
    exit(EXIT_SUCCESS);
}

void tick(Vmemory *memory, VerilatedVcdC *trace)
{
    memory->clk ^= 1;
    memory->eval();

    sim_time += 1;
    trace->dump(sim_time);
}

void cycle(Vmemory *memory, VerilatedVcdC *trace)
{
    tick(memory, trace);
    tick(memory, trace);
}

void n_cycles(Vmemory *memory, VerilatedVcdC *trace, size_t n_cycles)
{
    for (size_t i = 0; i < n_cycles; ++i) {
        cycle(memory, trace);
    }
}

void run_test(Vmemory *memory, VerilatedVcdC *trace)
{
    n_cycles(memory, trace, 2);

    // Write test #1
    memory->input_address = 0x13;
    memory->mode = 0b010; // LW/SW (32 bits with sign extend)
    memory->input_data = 0x9FF1188AA;

    n_cycles(memory, trace, 3);
    memory->we = 1;
    n_cycles(memory, trace, 1);
    memory->we = 0;

    // Write test #1
    memory->input_address = 0x101;
    memory->mode = 0b001; // LH/SH (16 bits with sign extend)
    memory->input_data = 0x77BB;

    n_cycles(memory, trace, 3);
    memory->we = 1;
    memory->mode = 0b000; // LB/SB (8 bits with sign extend)
    n_cycles(memory, trace, 1);
    memory->we = 0;

    n_cycles(memory, trace, 2);
    memory->mode = 0b100; // LBU (8 bits with zero extend)
    n_cycles(memory, trace, 1);
}
