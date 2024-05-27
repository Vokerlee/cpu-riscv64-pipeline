// Memory buffer

`include "defines.sv"

/* verilator lint_off UNUSEDSIGNAL */

module memory
    #(parameter ADDR_BITS  = 24)
(
    input logic clk,
    input logic we,
    // Address + access mode
    input logic [`DWORD_BITS - 1:0] input_address,
    input logic [2:0] mode, // funct3 in risc-v instructions
    // Data
    input  logic [`DWORD_BITS - 1:0] input_data,
    output logic [`DWORD_BITS - 1:0] output_data
);

    logic [`BYTE_BITS - 1:0] buffer [(1 << ADDR_BITS) - 1:0] /* verilator public */;
    logic [ADDR_BITS - 1:0] address = input_address[ADDR_BITS - 1:0];

    // mode is funct3 in decode stage:
    // 000 - LB/SB (8 bits with sign extend)
    // 001 - LH/SH (16 bits with sign extend)
    // 010 - LW/SW (32 bits with sign extend)
    // 011 - LD/SD (64 bits)
    // 100 - LBU (8 bits with zero extend)
    // 101 - LHU (16 bits with zero extend)
    // 110 - LWU (32 bits with zero extend)

    logic is_hword = (mode[1:0] == 2'b01);
    logic is_word  = (mode[1:0] == 2'b10);
    logic is_dword = (mode[1:0] == 2'b11);

    logic zero_ext = mode[2];
    logic sign_ext = ~zero_ext;

    // {Sign/zero}-extension
    logic [`DWORD_BITS - 1:0] data_byte = {
        {(`DWORD_BITS - `BYTE_BITS) {sign_ext && buffer[address][`BYTE_BITS - 1]}},
        buffer[address]
    };
    logic [`DWORD_BITS - 1:0] data_hword = {
        {(`DWORD_BITS - `HWORD_BITS) {sign_ext && buffer[address + 1][`BYTE_BITS - 1]}},
        buffer[address + 1], buffer[address]
    };
    logic [`DWORD_BITS - 1:0] data_word  = {
        {(`DWORD_BITS - `WORD_BITS) {sign_ext && buffer[address + 3][`BYTE_BITS - 1]}},
        buffer[address + 3], buffer[address + 2], buffer[address + 1], buffer[address]
    };
    logic [`DWORD_BITS - 1:0] data_dword  = {
        buffer[address + 7], buffer[address + 6], buffer[address + 5], buffer[address + 4],
        buffer[address + 3], buffer[address + 2], buffer[address + 1], buffer[address]
    };
    assign output_data = (is_hword) ? data_hword :
                         (is_word)  ? data_word  :
                         (is_dword) ? data_dword :
                                      data_byte;
    always_ff @(posedge clk)
    begin
        if (we)
        begin
            buffer[address] <= input_data[7:0];

            if (is_hword) begin

                buffer[address + 1] <= input_data[15:8];
            end
            else if (is_word) begin
                buffer[address + 1] <= input_data[15:8];
                buffer[address + 2] <= input_data[23:16];
                buffer[address + 3] <= input_data[31:24];
            end
            else if (is_dword) begin
                buffer[address + 1] <= input_data[15:8];
                buffer[address + 2] <= input_data[23:16];
                buffer[address + 3] <= input_data[31:24];
                buffer[address + 4] <= input_data[39:32];
                buffer[address + 5] <= input_data[47:40];
                buffer[address + 6] <= input_data[55:48];
                buffer[address + 7] <= input_data[63:56];
            end
        end
    end

endmodule

/* verilator lint_on UNUSEDSIGNAL */
