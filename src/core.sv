// Core logic of CPU pipeline

`include "defines.sv"

module core
(
    input logic clk, input logic R
);
    // Wire/regs declarations
    logic [`DWORD_BITS - 1:0] instr_fetched, instr_decoded;
    logic [4:0] rs1_decoded, rs1_execute /* verilator public */, rs2_decoded, rs2_execute /* verilator public */;
    logic [`DWORD_BITS - 1:0] rs1_decoded_val, rs1_execute_val, rs2_decoded_val, rs2_execute_val;
    logic [4:0] rd_decoded, rd_execute /* verilator public */, rd_mem, rd_writeback;

    logic [`ALU_TYPE_BITS - 1:0] alu_op_decoded, alu_op_execute;
    logic [1:0] alu_src1_decoded, alu_src1_execute, alu_src2_decoded, alu_src2_execute;
    logic [`WORD_BITS - 1:0] imm_decoded, imm_execute;
    logic [`DWORD_BITS - 1:0] alu_out_execute, alu_out_mem, alu_out_writeback;
    logic alu_zero_flag;

    logic invalid_decoded = 1'b0, invalid_execute = 1'b0, invalid_mem = 1'b0, invalid_writeback = 1'b0;
    logic exception_decoded /* verilator public */, exception_execute /* verilator public */,
          exception_mem, exception_writeback;

    logic [2:0] mem_mode_decoded, mem_mode_execute, mem_mode_mem;
    logic mem_read_decoded, mem_read_execute, mem_read_mem, mem_read_writeback;
    logic mem_write_decoded, mem_write_execute, mem_write_mem;
    logic reg_write_decoded, reg_write_execute, reg_write_mem, reg_write_writeback;

    logic branch_inv_cond_decoded, branch_inv_cond_execute;
    logic branch_decoded, branch_execute;
    logic jmp_decoded, jmp_execute;

    // Enable-reset flags
    logic flush_execute, stall_fetch, stall_decode /* verilator public */; // controlled by hazard-unit
    logic branch_taken_execute /* verilator public */;
    logic [`DWORD_BITS - 1:0] result_writeback;

    logic enable_pc, enable_decode, enable_execute, enable_mem, enable_writeback /* verilator public */;
    logic reset_decode, reset_execute /* verilator public */, reset_mem, reset_writeback;

    assign enable_decode = !stall_decode & !exception_writeback;
    assign reset_decode = R | branch_taken_execute ;

    assign enable_execute = !exception_writeback;
    assign reset_execute = R | flush_execute;

    assign enable_mem = !exception_writeback;
    assign reset_mem = R;

    assign enable_writeback = !exception_writeback;
    assign reset_writeback = R;

    // PC-related flags/values
    assign enable_pc = !stall_fetch & !exception_writeback;

    logic [1:0] pc_mode_decoded, pc_mode_execute, next_pc_mode;
    logic [`DWORD_BITS - 1:0] pc_fetched, pc_decode, pc_execute /* verilator public */;
    assign next_pc_mode = (branch_taken_execute) ? pc_mode_execute : `PC_4; // else += 4

// Fetch stage

    pc pc(clk, enable_pc, next_pc_mode, pc_execute, imm_execute, rs1_forwarded_val, pc_fetched);
    memory instr_memory(.clk(clk), .we(0), .input_address(pc_fetched),
                        .mode(`WORD_UNSIGNED), .input_data(0), .output_data(instr_fetched));

    latch #(.DATA_SIZE(128)) latch_decode
        (.clk(clk), .R(reset_decode), .en(enable_decode),
         .input_data({pc_fetched, instr_fetched}), .output_data({pc_decode, instr_decoded}));

    // Decoder-dispatch stage

    decoder decoder(.raw_instr(instr_decoded[`WORD_BITS - 1:0]), .rs1(rs1_decoded), .rs2(rs2_decoded), .rd(rd_decoded),
                    .alu_op(alu_op_decoded), .alu_src1_mode(alu_src1_decoded), .alu_src2_mode(alu_src2_decoded),
                    .imm(imm_decoded), .mem_mode(mem_mode_decoded), .mem_read(mem_read_decoded),
                    .mem_write(mem_write_decoded), .invalid_bit(invalid_decoded), .exception_bit(exception_decoded),
                    .pc_mode(pc_mode_decoded), .reg_write(reg_write_decoded),
                    .branch(branch_decoded), .branch_inv_cond(branch_inv_cond_decoded), .jump(jmp_decoded));

    // Read rs1/rs2 values, write writeback register
    reg_file reg_file(.clk(clk), .we(reg_write_writeback), .read_num1(rs1_decoded), .read_num2(rs2_decoded),
                      .write_num(rd_writeback), .input_data(result_writeback),
                      .output_data1(rs1_decoded_val), .output_data2(rs2_decoded_val));

    // Decode-execute transition

    latch #(.DATA_SIZE(260)) latch_execute(.clk(clk), .R(reset_execute), .en(enable_execute),
        .input_data({pc_decode, rs1_decoded_val, rs2_decoded_val, imm_decoded,
                     rs1_decoded, rs2_decoded, rd_decoded, alu_op_decoded,
                     mem_mode_decoded, mem_read_decoded, mem_write_decoded, reg_write_decoded,
                     alu_src1_decoded, alu_src2_decoded, pc_mode_decoded, branch_decoded, branch_inv_cond_decoded,
                     jmp_decoded, exception_decoded, invalid_decoded}),
        .output_data({pc_execute, rs1_execute_val, rs2_execute_val, imm_execute,
                      rs1_execute, rs2_execute, rd_execute, alu_op_execute,
                      mem_mode_execute, mem_read_execute, mem_write_execute, reg_write_execute,
                      alu_src1_execute, alu_src2_execute, pc_mode_execute, branch_execute, branch_inv_cond_execute,
                      jmp_execute, exception_execute, invalid_execute}));

    // Execute stage

    logic [1:0] forward_rs1_execute, forward_rs2_execute; // controlled by hazard_unit
    logic [`DWORD_BITS - 1:0] rs1_forwarded_val, rs2_forwarded_val, alu_src1_execute_val, alu_src2_execute_val;

    assign rs1_forwarded_val = (forward_rs1_execute[1] == 1'b1) ? alu_out_mem :
                               (forward_rs1_execute[0] == 1'b1) ? result_writeback :
                                                                  rs1_execute_val;
    assign rs2_forwarded_val = (forward_rs2_execute[1] == 1'b1) ? alu_out_mem :
                               (forward_rs2_execute[0] == 1'b1) ? result_writeback :
                                                                  rs2_execute_val;

    assign alu_src1_execute_val = (alu_src1_execute == 2'b00) ? rs1_forwarded_val :
                                                                pc_execute;
    assign alu_src2_execute_val =
        (alu_src2_execute == 2'b00) ? rs2_forwarded_val :
        (alu_src2_execute == 2'b01) ? { {`WORD_BITS {imm_execute[`WORD_BITS - 1]}}, imm_execute} :
                                      4;

    alu alu(.input_data1(alu_src1_execute_val), .input_data2(alu_src2_execute_val),
            .alu_op(alu_op_execute), .output_data(alu_out_execute), .zero_out(alu_zero_flag));

    assign branch_taken_execute = (branch_execute & (alu_zero_flag ^ (~branch_inv_cond_execute))) | jmp_execute;

    // Execute-memory transition

    logic [`DWORD_BITS - 1:0] mem_write_data;
    latch #(.DATA_SIZE(128)) latch_mem1(.clk(clk), .R(reset_mem), .en(enable_mem),
                                        .input_data({alu_out_execute, rs2_forwarded_val}),
                                        .output_data({alu_out_mem, mem_write_data}));
    latch #(.DATA_SIZE(13)) latch_mem2(.clk(clk), .R(reset_mem), .en(enable_mem),
                                       .input_data({mem_mode_execute, mem_read_execute, mem_write_execute, reg_write_execute,
                                                    rd_execute, exception_execute, invalid_execute}),
                                       .output_data({mem_mode_mem, mem_read_mem, mem_write_mem, reg_write_mem,
                                                     rd_mem, exception_mem, invalid_mem}));

    // Memory stage

    logic [`DWORD_BITS - 1:0] mem_read_data;
    memory data_memory(.clk(clk), .we(mem_write_mem), .input_address(alu_out_mem),
                       .mode(mem_mode_mem), .input_data(mem_write_data), .output_data(mem_read_data));

    // Memory-writeback transition

    logic [`DWORD_BITS - 1:0] mem_read_data_writeback;

    latch #(.DATA_SIZE(128)) latch_writeback1
        (.clk(clk), .R(reset_writeback), .en(enable_writeback),
         .input_data({mem_read_data, alu_out_mem}), .output_data({mem_read_data_writeback, alu_out_writeback}));
    latch #(.DATA_SIZE(9)) latch_writeback2
        (.clk(clk), .R(reset_writeback), .en(enable_writeback),
         .input_data({reg_write_mem,        mem_read_mem,       rd_mem,       exception_mem,       invalid_mem}),
         .output_data({reg_write_writeback, mem_read_writeback, rd_writeback, exception_writeback, invalid_writeback}));

    // Write-back stage

    assign result_writeback = (mem_read_writeback) ? mem_read_data_writeback :
                                                     alu_out_writeback;

    hazard_unit hu(.reg_write_mem(reg_write_mem), .reg_write_writeback(reg_write_writeback),
                   .rs1_decode(rs1_decoded), .rs2_decode(rs2_decoded), .rd_execute(rd_execute),
                   .rs1_execute(rs1_execute), .rs2_execute(rs2_execute), .rd_mem(rd_mem), .rd_writeback(rd_writeback),
                   .mem_read_execute(mem_read_execute), .taken_branch(branch_taken_execute),
                   .forward_rs1_execute(forward_rs1_execute), .forward_rs2_execute(forward_rs2_execute),
                   .flush_execute(flush_execute), .stall_decode(stall_decode), .stall_fetch(stall_fetch));

endmodule
