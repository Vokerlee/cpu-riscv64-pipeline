// Memory buffer

`define BYTE_BITS  8
`define HWORD_BITS 16
`define WORD_BITS  32
`define DWORD_BITS 64

module memory
    #(parameter MEM_BITS  = 20,
                DATA_SIZE = `DWORD_BITS)
(
    input logic clk,
    input logic we,
    // Address + access mode
    input logic [MEM_BITS - 1:0] address,
    input logic [2:0] mode, // funct3 in risc-v instructions
    // Data
    input  logic [DATA_SIZE - 1:0] to_write_data,
    output logic [DATA_SIZE - 1:0] to_read_data
);

    logic [DATA_SIZE - 1:0] buffer [(1 << MEM_BITS) - 1:0] /* verilator public */;

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
    logic [DATA_SIZE - 1:0] data_byte = {
        {(DATA_SIZE - `BYTE_BITS) {sign_ext && buffer[address][`BYTE_BITS - 1]}},
        buffer[address][`BYTE_BITS - 1:0]
    };
    logic [DATA_SIZE - 1:0] data_hword = {
        {(DATA_SIZE - `HWORD_BITS) {sign_ext && buffer[address][`HWORD_BITS - 1]}},
        buffer[address][`HWORD_BITS - 1:0]
    };
    logic [DATA_SIZE - 1:0] data_word  = {
        {(DATA_SIZE - `WORD_BITS) {sign_ext && buffer[address][`WORD_BITS - 1]}},
        buffer[address][`WORD_BITS - 1:0]
    };
    logic [DATA_SIZE - 1:0] data_dword = buffer[address];

    assign to_read_data = (is_hword) ? data_hword :
                          (is_word)  ? data_word  :
                          (is_dword) ? data_dword :
                                       data_byte;
    always_ff @(posedge clk)
    begin
        if (we)
        begin
            buffer[address][7:0] <= to_write_data[7:0];

            if (is_hword) begin
                buffer[address][15:8] <= to_write_data[15:8];
            end
            else if (is_word) begin
                buffer[address][31:8] <= to_write_data[31:8];
            end
            else if (is_dword) begin
                buffer[address][DATA_SIZE - 1:8] <= to_write_data[DATA_SIZE - 1:8];
            end
        end
    end

endmodule
