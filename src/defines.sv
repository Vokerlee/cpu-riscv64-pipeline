// General data types
`define BYTE_BITS  8
`define HWORD_BITS 16
`define WORD_BITS  32
`define DWORD_BITS 64
`define QWORD_BITS 128

// Register-file specific
`define REG_FILE_SIZE_BITS 5
`define REG_FILE_SIZE (1 << `REG_FILE_SIZE_BITS)

// ALU defines
`define ALU_INVALID 4'b0000
`define ALU_ADD     4'b0001
`define ALU_SUB     4'b0010
`define ALU_AND     4'b0011
`define ALU_OR      4'b0100
`define ALU_XOR     4'b0101
`define ALU_SHL     4'b0110
`define ALU_SHR     4'b0111
`define ALU_SHA     4'b1000
`define ALU_SLT     4'b1001
`define ALU_SLTU    4'b1010
`define ALU_SRC1    4'b1011
`define ALU_SRC2    4'b1100
`define ALU_TYPE_BITS 4

// RV64I opcodes (cover all instrs except FENCE, FENCE.TSO, PAUSE, ECALL, EBREAK)
`define LUI        7'b0110111
`define AUIPC      7'b0010111
`define JAL        7'b1101111
`define JALR       7'b1100111
`define BRANCH_OP  7'b1100011
`define LOAD_OP    7'b0000011
`define STORE_OP   7'b0100011
`define REG_IMM_OP 7'b0010011
`define REG_REG_OP 7'b0110011
`define SYS_CALL   7'b1110011

// PC modes
`define PC_4   2'b00
`define PC_IMM 2'b01
`define PC_REG 2'b10

// Memory modes
`define BYTE_SIGNED    3'b000
`define HWORD_SIGNED   3'b001
`define WORD_SIGNED    3'b010
`define DWORD_SIGNED   3'b011
`define BYTE_UNSIGNED  3'b100
`define HWORD_UNSIGNED 3'b101
`define WORD_UNSIGNED  3'b110

// Forwarding
`define NO_FW  2'b00
`define FW_WB  2'b01
`define FW_MEM 2'b10
