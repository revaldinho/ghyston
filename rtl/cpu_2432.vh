// PSR register bits
`define Z        0
`define C        1
`define S        2
`define V        3
`define EI       4


// Condition Codes
`define EQ 4'h0 // Equal
`define NE 4'h1 // Not equal
`define CS 4'h2 // Unsigned higher or same (or carry set).
`define CC 4'h3 // Unsigned lower (or carry clear).
`define MI 4'h4 // Negative. The mnemonic stands for "minus".
`define PL 4'h5 // Positive or zero. The mnemonic stands for "plus".
`define VS 4'h6 // Signed overflow. The mnemonic stands for "V set".
`define VC 4'h7 // No signed overflow. The mnemonic stands for "V clear".
`define HI 4'h8 // Unsigned higher.
`define LS 4'h9 // Unsigned lower or same.
`define GE 4'hA // Signed greater than or equal.
`define LT 4'hB // Signed less than.
`define GT 4'hC // Signed greater than.
`define LE 4'hD // Signed less than or equal.
`define AL 4'hF // Always - unconditional

`define OPCODE_RNG  23:18
`define RDST_RNG    15:12
`define COND_RNG    15:12
`define RSRC0_RNG   11:8
`define RSRC1_RNG   7:4

// Register aliasses
`define RZERO    0
`define RPSR     14
`define RPC      15


// All opcodes are extended to 6 bits with the LSBs padded to zeros as listed below
//  
// These instructions use only 4 opcode bits with the two LSBs as immediate data
`define LMOV   6'b011000
`define LMOVT  6'b011100

// Define 5 MSBs only for these instructions where the LSB indicates direct or register source
`define LD_W   6'b000100
`define MOV    6'b000110
`define STO_W  6'b001100
`define JRCC   6'b010000 
`define JRSRCC 6'b010010
`define AND    6'b100000
`define OR     6'b100010
`define XOR    6'b100100
`ifdef INCLUDE_MUL
  `define MUL    6'b100110
`endif
`define ADD    6'b101000
`define SUB    6'b101010
`define ASR    6'b101100
`define LSR    6'b101110
`define ROR    6'b110000
`define ASL    6'b110010
`define ROL    6'b110100
`define BSET   6'b110110
`define BCLR   6'b111000
`define BTST   6'b111010
`define CMP    6'b111100

// These instructions need to use all 6 opcode bits
`define RETI   6'b010101
`define JMP    6'b010110
`define JSR    6'b010111

`define TWO_STAGE_PIPE 1
// Including single cycle MUL18x18 limits clock speed to ~60MHz
`define INCLUDE_MUL 1
// Making full 32x32 MUL slows clock speed down further
//`define MUL32 1
// Define this to allow shifts of 16-31bits in one instruction, otherwise limited to 0-15
//`define SHIFT16 1
`define BYPASS_EN_D 1
//`define HALF_RATE_D 1
