module core_logic (
    input logic clk,
    input logic R,
    output logic [31:0] PC_out, Imm_out,
    output logic [4:0] RS1_out = 0, RS2_out = 0, RD_out = 0
);

    // logic [31:0] RS1, RS2, Imm;
    // logic we = 0;

    reg_file regs(
        .clk(clk), .we(we), .read_num1(1), .read_num2(1), .write_num(4),
        .in_value(100));

endmodule
