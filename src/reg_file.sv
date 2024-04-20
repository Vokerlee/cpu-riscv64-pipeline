// Register file with GPR (32 registers)

module reg_file
    #(parameter REG_FILE_BITS = 5,
                REG_FILE_SIZE = 32,
                REG_SIZE      = 32)
(
    input logic clk,
    input logic we,
    // Enable possibility to read 2 registers at once
    input logic [REG_FILE_BITS - 1:0] read_num1,
    input logic [REG_FILE_BITS - 1:0] read_num2,
    // Write only 1 register at once
    input logic [REG_FILE_BITS - 1:0] write_num,
    input logic [REG_SIZE - 1:0] in_value,
    output logic [REG_SIZE - 1:0] out_reg1,
    output logic [REG_SIZE - 1:0] out_reg2
);

    logic [REG_SIZE - 1:0] reg_file[REG_FILE_SIZE - 1:0];

    assign out_reg1 = (read_num1 == 0) ? 0 : reg_file[read_num1];
    assign out_reg2 = (read_num2 == 0) ? 0 : reg_file[read_num2];

    // For future (writeback sync): all other ops will be in posedge
    always_ff @(negedge clk)
    begin
        if (we)
            reg_file[write_num] <= in_value;
    end

endmodule
