#include <stdlib.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Valu.h"

vluint64_t sim_time = 0;

void run_test(Valu *alu, VerilatedVcdC *trace);

int main()
{
    Valu *alu = new Valu;

    Verilated::traceEverOn(true);
    VerilatedVcdC *trace = new VerilatedVcdC;
    alu->trace(trace, 5);
    trace->open("waveform.vcd");

    run_test(alu, trace);

    trace->close();
    delete alu;
    exit(EXIT_SUCCESS);
}

void run_test(Valu *alu, VerilatedVcdC *trace)
{
    alu->input_data1 = 0x9999;
    alu->input_data2 = 0xABC921;

    for (size_t alu_op = 0; alu_op < 0b1111; alu_op++) {
        alu->alu_op = alu_op;
        alu->eval();
        sim_time += 1;
        trace->dump(sim_time);
    }
}
