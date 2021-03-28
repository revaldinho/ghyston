/*
 * General configuration
 *
 */

//`define TWO_STAGE_PIPE 1
// Including single cycle MUL18x18 limits clock speed to ~90MHz
`define MUL_INSTR 1
// Define this to allow shifts of 16-31bits in one instruction, but speed limited to ~94MHz, otherwise limited to 0-15
`define SHIFT16 1
`define BYPASS_EN_D 1
//`define HALF_RATE_D 1
`define NEG_INSTR 1
`define ZLOOP_INSTR 1
`define DJNZ_Z_INSTR 1
`define DJCC_CS_INSTR 1
/* ****************************** */

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
// Format A. Opcodes need all 6 bits
`ifdef DJCC_CS_INSTR
  `define DJCC  6'h00
  `define DJCS  6'h01
`endif
`ifdef DJNZ_Z_INSTR
  `define DJNZ  6'h02
  `define DJZ   6'h03
`endif
`ifdef ZLOOP_INSTR
  `define ZLOOP 6'h04
`endif
`define RETI  6'h05
// Format A1
`define JMP   6'h06
`define JSR   6'h07
// Format B. Direct or register ops, LSB is zero
`define JRCC   6'h08
`define JRSRCC 6'h0A
// Format D. Direct or register ops, LSB is zero
`define LD     6'h0C
`define STO    6'h0E
// Format C. These instructions use only 4 opcode bits with the two LSBs
// as immediate data so define only the 4 MSBs and zero the others
`define LMOV   6'h10
`define LMOVT  6'h14
// Format E. Define 5 MSBs only for these instructions where the LSB
// indicates direct or register source
`define AND    6'h20
`define OR     6'h22
`define XOR    6'h24
`ifdef NEG_INSTR
  `define NEG    6'h26
`endif
`define ASR    6'h28
`define LSR    6'h2A
`define ROR    6'h2C
`define ASL    6'h2E
`define ROL    6'h30
`define BSET   6'h32
`define BCLR   6'h34
`define BTST   6'h36
`define ADD    6'h38
`define SUB    6'h3A
`define CMP    6'h3C
`ifdef MUL_INSTR
  `define MUL    6'h3E
`endif
