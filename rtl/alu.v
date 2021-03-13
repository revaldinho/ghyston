`include "cpu_2432.vh"

// Define this to allow 32x32 multiplies, but the result is still truncated to 32b anyway and
// this then needs multiple DSP slices and the final structure reduces the max clock speed by
// around a half. A multi-cycle flag is provided to allow an extra cycle for these long multiplies
// to complete without slowing down the machine for all other instructions.

`ifdef SHIFT16
  `define ROT16 ((distance & 5'b10000)!=0)
`else
  `define ROT16 1'b0
`endif

`define ROT8  ((distance & 5'b01000)!=0)
`define ROT4  ((distance & 5'b00100)!=0)
`define ROT2  ((distance & 5'b00010)!=0)
`define ROT1  ((distance & 5'b00001)!=0)

module alu(
           input [31:0]  din_a,
           input [31:0]  din_b,
           input         cin,
           input         vin,
           input [5:0]   opcode,
           output [31:0] dout,
           output        cout,
           output reg    qnzout,
           output reg    mcp_out,
           output reg    vout
           );

  reg [31:0]             alu_dout;
  reg                    alu_cout;
  wire [31:0]            shifted_w;
  wire                   shifted_c;

  barrel_shifter u0 (
                     .din(din_a),
                     .distance(din_b[4:0]),
                     .opcode(opcode),
                     .cin(cin),
                     .dout(shifted_w),
                     .cout(shifted_c)
                     );

  assign {cout,dout} = ( opcode==`ASR ||
                         opcode==`ROR ||
                         opcode==`LSR ||
                         opcode==`ASL ||
                         opcode==`ROL) ? {shifted_c, shifted_w} : { alu_cout, alu_dout};


  always @ (*) begin
    qnzout = |alu_dout;
  end
  
  always @(*) begin
    alu_cout = cin;
    vout = vin;
    mcp_out = 1'b0;
    alu_dout = 32'bx;
    case ( opcode )
      //MOVT will have the bits shifted to the top of the word before writing the regfile
      `LMOVT      :{alu_cout,alu_dout} = {cin, din_b[15:0], din_a[15:0]} ;
      `LMOV, `MOV :{alu_cout,alu_dout} = {cin, din_b} ;
      `AND        :{alu_cout,alu_dout} = {1'b0,(din_a & din_b)};
      `OR         :{alu_cout,alu_dout} = {1'b0,(din_a | din_b)};
      `XOR        :{alu_cout,alu_dout} = {1'b0, din_a ^ din_b};
`ifdef INCLUDE_MUL
`ifdef MUL32
      // Wide multiply 32b x32b = 32b (truncated) uses 3 cycles and stretches the clock cycle to complete
      `MUL        :{mcp_out,alu_cout,alu_dout} = {1'b1, din_a * din_b};
`else
      // Restrict multiplies to 18x18 to fit a single DSP slice on a Spartan 6 FPGA and single cycle execution
      `MUL        :{alu_cout,alu_dout} = {din_a[17:0] * din_b[17:0]};
`endif
`endif
      `ADD, `DJNZ       :{alu_cout,alu_dout} = {din_a + din_b};
      `SUB, `CMP        :{alu_cout,alu_dout} = {din_a - din_b};
      `BTST             :{alu_cout,alu_dout} = {cin, din_a & (32'b1<<din_b[4:0])};
      `BSET             :{alu_cout,alu_dout} = {cin, din_a | (32'b1<<din_b[4:0])};
      `BCLR             :{alu_cout,alu_dout} = {cin, din_a & !(32'b1<<din_b[4:0])};
      default           :{alu_cout,alu_dout} = {cin,din_b} ;
    endcase // case opcode

    if ( opcode==`ADD)
      // overflow if -ve + -ve = +ve  or +ve + +ve = -ve
      vout =  ( din_a[31] & din_b[31] & !dout[31]) ||
                ( !din_a[31] & !din_b[31] & dout[31]) ;
    else if ( opcode==`SUB || opcode==`CMP)
      // overflow if -ve - +ve = +ve  or +ve - -ve = -ve
      vout =  ( din_a[31] & !din_b[31] & !dout[31]) ||
                ( !din_a[31] & din_b[31] & dout[31]) ;
`ifdef INCLUDE_MUL
    else if ( opcode==`MUL)
      vout = !(din_a[31] ^ din_b[31] ^ dout[31]);
`endif
  end

endmodule // alu

module barrel_shifter(
                      input [31:0]      din,
                      input [4:0]       distance,
                      input [5:0]       opcode,
                      input             cin,
                      output reg [31:0] dout,
                      output reg        cout
                      );

  reg  [64:0] stg0;

  wire [64:0] l_stg1, r_stg1;
  wire [64:0] l_stg2, r_stg2;
  wire [64:0] l_stg3, r_stg3;
  wire [64:0] l_stg4, r_stg4;
  wire [64:0] l_stg5, r_stg5;

  always @ ( * ) begin
    dout = 32'bx;
    cout = cin;
    case ( opcode )
      `ASL : begin
        stg0 = {32'b0, cin, din};
        {cout, dout } = {l_stg5[32:0]};
      end
      `ROL : begin
        stg0 = {din, cin, din};
        {dout, cout } = l_stg5[64:32];
      end
      `ROR : begin
        stg0 = {din, cin, din};
        {cout, dout } = r_stg5[32:0];
      end
      `ASR : begin
        stg0 = { din, cin, {32{din[31]}}} ;
        {dout, cout} = { r_stg5[64:32]};
      end
      `LSR : begin
        stg0 = { din, cin, 32'b0};
        {dout, cout} = { r_stg5[64:32]};
      end
      default: stg0=65'bx;
    endcase // case ( opcode )
  end

  // ROR - rotate through carry
  assign r_stg1 = ( `ROT16 ) ? { stg0[15:0],  stg0[64:16]}  : stg0;
  assign r_stg1 = ( `ROT16 ) ? { stg0[15:0],  stg0[64:16]}  : stg0;
  assign r_stg2 = ( `ROT8 ) ?  { r_stg1[7:0], r_stg1[64:8]} : r_stg1;
  assign r_stg3 = ( `ROT4 ) ?  { r_stg2[3:0], r_stg2[64:4]} : r_stg2;
  assign r_stg4 = ( `ROT2 ) ?  { r_stg3[1:0], r_stg3[64:2]} : r_stg3;
  assign r_stg5 = ( `ROT1 ) ?  { r_stg4[0],   r_stg4[64:1]} : r_stg4;

  // ROL - rotate through carry
  assign l_stg1 = ( `ROT16 ) ? { stg0[48:0],   stg0[64:49]}   : stg0;
  assign l_stg2 = ( `ROT8 ) ?  { l_stg1[56:0], l_stg1[64:57]} : l_stg1;
  assign l_stg3 = ( `ROT4 ) ?  { l_stg2[60:0], l_stg2[64:61]} : l_stg2;
  assign l_stg4 = ( `ROT2 ) ?  { l_stg3[62:0], l_stg3[64:63]} : l_stg3;
  assign l_stg5 = ( `ROT1 ) ?  { l_stg4[63:0], l_stg4[64]}    : l_stg4;

endmodule
