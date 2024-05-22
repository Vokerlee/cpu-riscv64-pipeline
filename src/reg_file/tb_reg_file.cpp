#include <stdlib.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vreg_file.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

void run_test(Vreg_file *regs, VerilatedVcdC *trace);

int main()
{
    Vreg_file *regs = new Vreg_file;

    Verilated::traceEverOn(true);
    VerilatedVcdC *trace = new VerilatedVcdC;
    regs->trace(trace, 5);
    trace->open("waveform.vcd");

    run_test(regs, trace);

    trace->close();
    delete regs;
    exit(EXIT_SUCCESS);
}

void tick(Vreg_file *regs, VerilatedVcdC *trace)
{
    regs->clk ^= 1;
    regs->eval();

    sim_time += 1;
    trace->dump(sim_time);
}

void cycle(Vreg_file *regs, VerilatedVcdC *trace)
{
    tick(regs, trace);
    tick(regs, trace);
}

void n_cycles(Vreg_file *regs, VerilatedVcdC *trace, size_t n_cycles)
{
    for (size_t i = 0; i < n_cycles; ++i) {
        cycle(regs, trace);
    }
}

void run_test(Vreg_file *regs, VerilatedVcdC *trace)
{
    n_cycles(regs, trace, 2);

    // Write test
    regs->write_num = 0x11;
    regs->input_data = -32;

    n_cycles(regs, trace, 3);

    regs->we = 1;
    n_cycles(regs, trace, 1);
    regs->we = 0;

    n_cycles(regs, trace, 2);

    // Read test
    regs->read_num1 = 0x11;
    regs->read_num2 = 0x10;

    n_cycles(regs, trace, 2);
}
