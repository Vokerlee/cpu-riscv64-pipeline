// Register file with GPR (32 registers)

`include "defines.sv"

module reg_file
    #(parameter REG_FILE_BITS = 5,
                REG_FILE_SIZE = 1 << REG_FILE_BITS,
                REG_SIZE      = `DWORD_BITS)
(
    input logic clk,
    input logic we,
    // Enable possibility to read 2 registers at once
    input logic [REG_FILE_BITS - 1:0] read_num1,
    input logic [REG_FILE_BITS - 1:0] read_num2,
    output logic [REG_SIZE - 1:0] output_data1,
    output logic [REG_SIZE - 1:0] output_data2,
    // Write only 1 register at once
    input logic [REG_FILE_BITS - 1:0] write_num,
    input logic [REG_SIZE - 1:0] input_data
);

    logic [REG_SIZE - 1:0] file [REG_FILE_SIZE - 1:0];

    assign output_data1 = (read_num1 == 0) ? 0 : file[read_num1];
    assign output_data2 = (read_num2 == 0) ? 0 : file[read_num2];

    // For future (writeback sync): all other ops will be in posedge
    always_ff @(negedge clk) begin
        if (we)
            file[write_num] <= input_data;
    end

endmodule
