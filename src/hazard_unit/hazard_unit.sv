// Hazard unit

`include "defines.sv"

module hazard_unit
(
    input logic reg_write_mem, reg_write_writeback,
    input logic [4:0] rs1_decode, rs2_decode, rd_execute,
    input logic [4:0] rs1_execute, rs2_execute, rd_mem, rd_writeback,
    input logic mem_read_execute, taken_branch,
    output logic [1:0] forward_rs1_execute, forward_rs2_execute,
    output logic flush_execute, stall_decode, stall_fetch
);
    // Create stall for memory-load & new basic block
    wire stall = mem_read_execute & ((rs1_decode == rd_execute) || (rs2_decode == rd_execute));
    assign flush_execute = stall || taken_branch, stall_decode = stall, stall_fetch = stall;

    assign forward_rs1_execute = {2 {(rs1_execute != 5'h0)}} &
    (
        (reg_write_mem       & (rd_mem       == rs1_execute)) ? `FW_MEM :
        (reg_write_writeback & (rd_writeback == rs1_execute)) ? `FW_WB :
                                                                `NO_FW
    );

    assign forward_rs2_execute = {2 {(rs2_execute != 5'h0)}} &
    (
        (reg_write_mem       & (rd_mem       == rs2_execute)) ? `FW_MEM :
        (reg_write_writeback & (rd_writeback == rs2_execute)) ? `FW_WB :
                                                                `NO_FW
    );

endmodule
