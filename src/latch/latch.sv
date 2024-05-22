// Latch for pipeline stages

`include "defines.sv"

module latch
    #(parameter DATA_SIZE = `DWORD_BITS)
(
    input logic clk,
    input logic R,
    input logic en,
    input logic  [DATA_SIZE - 1:0] input_data,
    output logic [DATA_SIZE - 1:0] output_data
);

    logic [DATA_SIZE - 1:0] buffer;
    assign output_data = buffer;

    always_ff @(posedge clk)
    begin
        if (en && !R)
            buffer <= input_data;
        else if (R)
            buffer <= 0;
    end

endmodule
