// Program counter

`include "defines.sv"

module pc
(
    input logic clk,
    input logic en,
    input logic [1:0] pc_mode,
    input logic [`DWORD_BITS - 1:0] pc_new,
    input logic [`WORD_BITS - 1:0] imm,
    input logic [`DWORD_BITS - 1:0] reg_val,
    output logic [`DWORD_BITS - 1:0] pc_out
);

    logic [`DWORD_BITS - 1:0] pc_val  /* verilator public */;
    assign pc_out = pc_val;

    logic [`DWORD_BITS - 1:0] pc_src1;
    logic [`DWORD_BITS - 1:0] pc_src2;

    always_comb begin
        case (pc_mode)
            `PC_4: begin
                pc_src1 = pc_val;
                pc_src2 = 4;
            end
            `PC_IMM: begin
                pc_src1 = pc_new;
                pc_src2 = { {`WORD_BITS {imm[`WORD_BITS - 1]}}, imm};
            end
            `PC_REG: begin
                pc_src1 = reg_val;
                pc_src2 = { {`WORD_BITS {imm[`WORD_BITS - 1]}}, imm};
            end
            default: begin
                pc_src1 = 0;
                pc_src2 = 0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (en) begin
            pc_val <= pc_src1 + pc_src2;
        end
    end

endmodule
