// Instruction decoder (RV64I)

`include "defines.sv"

module decoder
(
    input  logic [`WORD_BITS - 1:0] raw_instr,
    // General values
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [`WORD_BITS - 1:0] imm,
    // Instruction-dependent values
    output logic [`ALU_TYPE_BITS - 1:0] alu_op,
    output logic [2:0] mem_mode, // if instruction is load/store
    output logic mem_read, mem_write,
    output logic invalid_bit, exception_bit,
    output logic reg_write, jump, branch, branch_inv_cond,
    // ALU src1 modes:
    //     2'b00 -> rs1,       2'b01 -> pc,                                     2'b{other} is invalid
    // ALU src2 modes:
    //     2'b00 -> rs2,       2'b01 -> imm,         2'b10 -> 4,                2'b{other} is invalid
    // PC modes:
    //     2'b00 -> (pc += 4), 2'b01 -> (pc += imm), 2'b10 -> (pc = reg + imm), 2'b{other} is invalid
    output logic [1:0] alu_src1_mode, alu_src2_mode, pc_mode
);

    // General instruction description
    logic [6:0] opcode = raw_instr[6:0];
    assign rd          = raw_instr[11:7];
    logic [2:0] funct3 = raw_instr[14:12];
    assign rs1         = raw_instr[19:15];
    assign rs2         = raw_instr[24:20];
    logic [6:0] funct7 = raw_instr[31:25];

    assign mem_mode = funct3;

    // All possible immediate types in RISC-V
    logic [`WORD_BITS - 1:0] imm_i, imm_s, imm_b, imm_u, imm_j, shamt;
    assign imm_i = { {20 {raw_instr[31]}}, raw_instr[31:20]};
    assign imm_s = { {20 {raw_instr[31]}}, raw_instr[31:25], raw_instr[11:7]};
    assign imm_b = { {20 {raw_instr[31]}}, raw_instr[7],
                                            raw_instr[30:25], raw_instr[11:8], 1'b0};
    assign imm_u = { raw_instr[31:12], {12 {1'b0}}};
    assign imm_j = { {12 {raw_instr[31]}}, raw_instr[19:12],
                                            raw_instr[20], raw_instr[30:21], 1'b0};
    assign shamt = {{27 {1'b0}}, raw_instr[24:20]};

    // Choose immediate by opcode
    assign imm = (opcode == `LUI)        ? imm_u :
                 (opcode == `AUIPC)      ? imm_u :
                 (opcode == `JAL)        ? imm_j :
                 (opcode == `JALR)       ? imm_i :
                 (opcode == `BRANCH_OP)  ? imm_b :
                 (opcode == `LOAD_OP)    ? imm_i :
                 (opcode == `STORE_OP)   ? imm_s :
                 (opcode == `REG_IMM_OP && funct3 == 3'b001) ? shamt : // SLLI
                 (opcode == `REG_IMM_OP && funct3 == 3'b101) ? shamt : // SRLI, SRAI
                 (opcode == `REG_IMM_OP) ? imm_i :
                                           `WORD_BITS'b0;

    always_comb begin
        case(opcode)
            `LUI: begin
                mem_read = 0; mem_write = 0; reg_write = 1; alu_op = `ALU_SRC2;
                invalid_bit = 0; exception_bit = 0; jump = 0; branch = 0;
                alu_src1_mode = 2'b00; alu_src2_mode = 2'b01; pc_mode = `PC_4;
                branch_inv_cond = 0;
            end
            `AUIPC: begin
                mem_read = 0; mem_write = 0; reg_write = 1; alu_op = `ALU_ADD;
                invalid_bit = 0; exception_bit = 0; jump = 0; branch = 0;
                alu_src1_mode = 2'b01; alu_src2_mode = 2'b01; pc_mode = `PC_4;
                branch_inv_cond = 0;
            end
            `JAL: begin
                mem_read = 0; mem_write = 0; reg_write = 1; alu_op = `ALU_INVALID;
                invalid_bit = 0; exception_bit = 0; jump = 1; branch = 0;
                alu_src1_mode = 2'b01; alu_src2_mode = 2'b11; pc_mode = `PC_IMM;
                branch_inv_cond = 0;
            end
            `JALR: begin
                mem_read = 0; mem_write = 0; reg_write = 1; alu_op = `ALU_INVALID;
                invalid_bit = 0; exception_bit = 0; jump = 1; branch = 0;
                alu_src1_mode = 2'b01; alu_src2_mode = 2'b11; pc_mode = `PC_REG;
                branch_inv_cond = 0;
            end
            `BRANCH_OP: begin
                mem_read = 0; mem_write = 0; reg_write = 0; alu_op = `ALU_INVALID;
                invalid_bit = 0; exception_bit = 0; jump = 0; branch = 1;
                alu_src1_mode = 2'b00; alu_src2_mode = 2'b00; pc_mode = `PC_IMM;
                branch_inv_cond = 0;

                if (funct3 == 3'b000) begin
                    alu_op = `ALU_SUB; // beq
                end else if (funct3 == 3'b001) begin
                    alu_op = `ALU_SUB; // bne
                    branch_inv_cond = 1;
                end else if (funct3 == 3'b100) begin
                    alu_op = `ALU_SLT; // blt
                end else if (funct3 == 3'b101) begin
                    alu_op = `ALU_SLT; // bge
                    branch_inv_cond = 1;
                end else if (funct3 == 3'b110) begin
                    alu_op = `ALU_SLTU; // bltu
                end else if (funct3 == 3'b111) begin
                    alu_op = `ALU_SLTU; // bgeu
                    branch_inv_cond = 1;
                end
            end
            `LOAD_OP: begin
                mem_read = 1; mem_write = 0; reg_write = 1; alu_op = `ALU_ADD;
                invalid_bit = 0; exception_bit = 0; jump = 0; branch = 0;
                alu_src1_mode = 2'b00; alu_src2_mode = 2'b01; pc_mode = `PC_4;
                branch_inv_cond = 0;
            end
            `STORE_OP: begin
                mem_read = 0; mem_write = 1; reg_write = 0; alu_op = `ALU_ADD;
                invalid_bit = 0; exception_bit = 0; jump = 0; branch = 0;
                alu_src1_mode = 2'b00; alu_src2_mode = 2'b01; pc_mode = `PC_4;
                branch_inv_cond = 0;
            end
            `REG_IMM_OP: begin
                mem_read = 0; mem_write = 0; reg_write = 1; alu_op = `ALU_INVALID;
                invalid_bit = 0; exception_bit = 0; jump = 0; branch = 0;
                alu_src1_mode = 2'b00; alu_src2_mode = 2'b01; pc_mode = `PC_4;
                branch_inv_cond = 0;

                if (funct3 == 3'b000) begin
                    alu_op = `ALU_ADD; // addi
                end else if (funct3 == 3'b001) begin
                    alu_op = `ALU_SHL; // slli
                end else if (funct3 == 3'b010) begin
                    alu_op = `ALU_SLT; // slti
                end else if (funct3 == 3'b011) begin
                    alu_op = `ALU_SLTU; // sltiu
                end else if (funct3 == 3'b100) begin
                    alu_op = `ALU_XOR; // xori
                end else if (funct3 == 3'b101) begin
                    if (funct7 == 7'b0000000) begin
                        alu_op = `ALU_SHR; // srli
                    end else begin
                        alu_op = `ALU_SHA; // srai
                    end
                end else if (funct3 == 3'b110) begin
                    alu_op = `ALU_OR; // ori
                end else if (funct3 == 3'b111) begin
                    alu_op = `ALU_AND; // andi
                end
            end
            `REG_REG_OP: begin
                mem_read = 0; mem_write = 0; reg_write = 1; alu_op = `ALU_INVALID;
                invalid_bit = 0; exception_bit = 0; jump = 0; branch = 0;
                alu_src1_mode = 2'b00; alu_src2_mode = 2'b00; pc_mode = `PC_4;
                branch_inv_cond = 0;

                if (funct3 == 3'b000) begin
                    if (funct7 == 7'b0000000) begin
                        alu_op = `ALU_ADD;
                    end else begin
                        alu_op = `ALU_SUB;
                    end
                end else if (funct3 == 3'b111) begin
                    alu_op = `ALU_AND;
                end else if (funct3 == 3'b110) begin
                    alu_op = `ALU_OR;
                end else if (funct3 == 3'b100) begin
                    alu_op = `ALU_XOR;
                end else if (funct3 == 3'b001) begin
                    alu_op = `ALU_SHL;
                end else if (funct3 == 3'b101) begin
                    if (funct7 == 7'b0000000) begin
                        alu_op = `ALU_SHR;
                    end else if (funct7 == 7'b0100000) begin
                        alu_op = `ALU_SHA;
                    end
                end else if (funct3 == 3'b010) begin
                    alu_op = `ALU_SLT;
                end else if (funct3 == 3'b011) begin
                    alu_op = `ALU_SLTU;
                end
            end
            `SYS_CALL: begin
                mem_read = 0; mem_write = 0; reg_write = 0; alu_op = `ALU_INVALID;
                invalid_bit = 0; exception_bit = 1; jump = 0; branch = 0;
                alu_src1_mode = 2'b00; alu_src2_mode = 2'b00; pc_mode = `PC_4;
                branch_inv_cond = 0;
            end
            default: begin // at least used for stalls
                mem_read = 0; mem_write = 0; reg_write = 0; alu_op = `ALU_INVALID;
                invalid_bit = 1; exception_bit = 0; jump = 0; branch = 0;
                alu_src1_mode = 2'b00; alu_src2_mode = 2'b00; pc_mode = `PC_4;
                branch_inv_cond = 0;
            end
        endcase
    end

endmodule
