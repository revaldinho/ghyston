
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

`define OPCODE_RNG  23:19
`define RDST_RNG    17:14
`define COND_RNG    17:14
`define RSRC0_RNG   13:10
`define RSRC1_RNG   9:6

// Register aliasses
`define RZERO    0
`define RPSR     14
`define RPC      15

// Opcodes
`define  LD_B	6'b000000  // Rd	-	Rs	Imm	3	000	3	0
`define  LD_H	6'b000001  // Rd	-	Rs	Imm	3	000	3	1
`define  LD_W	6'b000010  // Rd	-	Rs	Imm	3	000	3	2
`define  STO_B	6'b000011  // Rd	-	Rs	Imm	3	000	3	3
`define  STO_H	6'b000100  // Rd	-	Rs	Imm	3	000	3	4
`define  STO_W	6'b000101  // Rd	-	Rs	Imm	3	000	3	5
`define  BRA_CC	6'b000110  // CC	-	Rs/PC	Imm	3	000	3	6
`define  CALL_CC 6'b000111  // CC	-	Rs	Imm	3	000	3	7
`define  AND	6'b100000  // Rd	Rs	Rs	Imm	1	1	3	0
`define  OR	6'b100001  // Rd	Rs	Rs	Imm	1	1	3	1
`define  XOR	6'b100010  // Rd	Rs	Rs	Imm	1	1	3	2
`define  MUL	6'b100011  // Rd	Rs	Rs	Imm	1	1	3	3
`define  RET	6'b100100  // Rd	Rs	Rs	Imm	1	1	3	4
`define  RETI	6'b100101  // Rd	Rs	Rs	Imm	1	1	3	5
`define  ADD	6'b100110  // Rd	Rs	Rs	Imm	1	1	3	6
`define  SUB	6'b100111  // Rd	Rs	Rs	Imm	1	1	3	7
`define  ASR	6'b001000  // Rd	Rs	Rs	Imm	3	001	3	0
`define  LSR	6'b001001  // Rd	Rs	Rs	Imm	3	001	3	1
`define  BSET	6'b001010  // Rd	Rs	Rs	Imm	3	001	3	2
`define  BCLR	6'b001011  // Rd	Rs	Rs	Imm	3	001	3	3
`define  BTST	6'b001100  // Rd	Rs	Rs	Imm	3	001	3	4
`define  ROR	6'b001101  // Rd	Rs	Rs	Imm	3	001	3	5
`define  ASL	6'b001110  // Rd	Rs	Rs	Imm	3	001	3	6
`define  ROL	6'b001111  // Rd	Rs	Rs	Imm	3	001	3	7
`define  LJMP	6'b010000  // -	-	-	Imm	3	010	1	0
`define  LCALL	6'b010100  // -	-	-	imm	3	010	1	1
`define  MOV	6'b011000  // Rd	-	-	Imm	3	011	1	0
`define  MOVT	6'b011100  // Rd	-	-	Imm	3	011	1	1
