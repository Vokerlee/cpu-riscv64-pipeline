// Arithmetic-logical unit

`include "defines.sv"

module alu
    #(parameter DATA_SIZE = `DWORD_BITS)
(
    input logic [DATA_SIZE - 1:0] input_data1, input_data2,
    input logic [`ALU_TYPE_BITS - 1:0] alu_op,
    output logic [DATA_SIZE - 1:0] output_data,
    output logic zero_out
);

    assign zero_out = (output_data === 0);
    logic [4:0] shamt = input_data2[4:0];

    always_comb begin
        case (alu_op)
            `ALU_ADD:  output_data = input_data1 + input_data2;
            `ALU_SUB:  output_data = input_data1 - input_data2;
            `ALU_AND:  output_data = input_data1 & input_data2;
            `ALU_OR:   output_data = input_data1 | input_data2;
            `ALU_XOR:  output_data = input_data1 ^ input_data2;
            `ALU_SHL:  output_data = input_data1 << shamt;
            `ALU_SHR:  output_data = input_data1 >> shamt;
            `ALU_SHA:  output_data = $signed(input_data1) >>> $signed(shamt);
            `ALU_SLT:  output_data = {{DATA_SIZE - 1 {1'b0}}, $signed(input_data1) < $signed(input_data2)};
            `ALU_SLTU: output_data = {{DATA_SIZE - 1 {1'b0}}, input_data1 < input_data2};
            `ALU_SRC1: output_data = input_data1;
            `ALU_SRC2: output_data = input_data2;
            default:   output_data = 0;
        endcase
    end

endmodule
