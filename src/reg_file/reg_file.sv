// Register file with GPR (32 registers)

module reg_file
    #(parameter REG_FILE_BITS = 5,
                REG_FILE_SIZE = 1 << REG_FILE_BITS,
                REG_SIZE      = 64)
(
    input logic clk,
    input logic we,
    // Enable possibility to read 2 registers at once
    input logic [REG_FILE_BITS - 1:0] read_num1,
    input logic [REG_FILE_BITS - 1:0] read_num2,
    output logic [REG_SIZE - 1:0] to_read_data1,
    output logic [REG_SIZE - 1:0] to_read_data2,
    // Write only 1 register at once
    input logic [REG_FILE_BITS - 1:0] write_num,
    input logic [REG_SIZE - 1:0] to_write_data
);

    logic [REG_SIZE - 1:0] file [REG_FILE_SIZE - 1:0];

    assign to_read_data1 = (read_num1 == 0) ? 0 : file[read_num1];
    assign to_read_data2 = (read_num2 == 0) ? 0 : file[read_num2];

    // For future (writeback sync): all other ops will be in posedge
    always_ff @(negedge clk) begin
        if (we)
            file[write_num] <= to_write_data;
    end

endmodule
