`include "cpu_2432.vh"

// Define this to allow 32x32 multiplies, but the result is still truncated to 32b anyway and
// this then needs multiple DSP slices and the final structure reduces the max clock speed by
// around a half. A multi-cycle flag is provided to allow an extra cycle for these long multiplies
// to complete without slowing down the machine for all other instructions.
//`define MUL32 1

`define OP_ASR (opcode==`ASR)
`define OP_ROR (opcode==`ROR)
`define OP_ROL (opcode==`ROL)
`define OP_ASL (opcode==`ASL)
`define OP_LSR (opcode==`LSR)

`define ROT16 ((distance & 5'b10000)!=0)
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
           output        mcp_out,
           output        vout
           );

  reg [31:0]             dout_r;
  reg                    vout_r;
  reg                    cout_r;
  reg                    mcp_out_r;
  wire [31:0]            shifted_w;
  wire                   shifted_c;

  assign dout = dout_r;
  assign cout = cout_r;
  assign vout = vout_r;
  assign mcp_out = mcp_out_r;


  barrel_shifter u0 (
                     .din(din_a),
                     .distance(din_b[4:0]),
                     .opcode(opcode),
                     .dout(shifted_w),
                     .cout(shifted_c)
                     );

  always @(*) begin
    cout_r = cin;
    vout_r = vin;
    mcp_out_r = 1'b0;

    case ( opcode )
      //MOVT will have the bits shifted to the top of the word before writing the regfile
      `LMOVT      :{cout_r,dout_r} = {cin, din_b[15:0], din_a[15:0]} ;
      `LMOV, `MOV :{cout_r,dout_r} = {cin, din_b} ;
      `AND        :{cout_r,dout_r} = {1'b0,(din_a & din_b)};
      `OR         :{cout_r,dout_r} = {1'b0,(din_a | din_b)};
      `XOR        :{cout_r,dout_r} = {1'b0, din_a ^ din_b};
`ifdef MUL32
      // Wide multiply 32b x32b = 32b (truncated) uses 3 cycles and stretches the clock cycle to complete
      `MUL        :{mcp_out_r,cout_r,dout_r} = {1'b1, din_a * din_b};
`else
      // Restrict multiplies to 18x18 to fit a single DSP slice on a Spartan 6 FPGA and single cycle execution
      `MUL        :{cout_r,dout_r} = {din_a[17:0] * din_b[17:0]};
`endif
      //`DIV        :{cout_r,dout_r} = {din_a[17:0] / din_b[17:0]};
      `ADD        :{cout_r,dout_r} = {din_a + din_b};
      `SUB, `CMP  :{cout_r,dout_r} = {din_a - din_b};
      `BTST       :{cout_r,dout_r} = {cin, din_a & (32'b1<<din_b[4:0])};
      `BSET       :{cout_r,dout_r} = {cin, din_a | (32'b1<<din_b[4:0])};
      `BCLR       :{cout_r,dout_r} = {cin, din_a & !(32'b1<<din_b[4:0])};
      `ASR, `ROR, `LSR, `ASL, `ROL:
        {cout_r,dout_r} = {shifted_c, shifted_w};
      default :{cout_r,dout_r} = {cin,din_b} ;
    endcase // case opcode

    if ( opcode==`ADD)
      // overflow if -ve + -ve = +ve  or +ve + +ve = -ve
      vout_r =  ( din_a[31] & din_b[31] & !dout_r[31]) ||
                ( !din_a[31] & !din_b[31] & dout_r[31]) ;
    else if ( opcode==`SUB || opcode==`CMP)
      // overflow if -ve - +ve = +ve  or +ve - -ve = -ve
      vout_r =  ( din_a[31] & !din_b[31] & !dout_r[31]) ||
                ( !din_a[31] & din_b[31] & dout_r[31]) ;
    else if ( opcode==`MUL)
      vout_r = !(din_a[31] ^ din_b[31] ^ dout_r[31]);    
  end

endmodule // alu

module barrel_shifter(
                      input [31:0] din,
                      input [4:0] distance,
                      input [5:0] opcode,
                      output [31:0] dout,
                      output cout
                      );

  wire [31:0] stg0;
  wire [31:0] r_stg1, r_stg2, r_stg3, r_stg4, r_stg5;
  wire [31:0] l_stg1, l_stg2, l_stg3, l_stg4, l_stg5;
  wire [31:0] r_mask1, r_mask2, r_mask3, r_mask4, r_mask5;
  wire [31:0] r_sign1, r_sign2, r_sign3, r_sign4, r_sign5;
  wire [31:0] l_mask1, l_mask2, l_mask3, l_mask4, l_mask5;
  reg [31:0] dout_r;

  assign stg0 = din;
  assign dout = dout_r;

  // ROR
  // LSR - any bits wrapping around should be zeroed
  // ASR - any bits wrapping around should be set to the original sign bit
  assign r_stg1 = ( `ROT16 ) ? { stg0[15:0],  stg0[31:16]}  : stg0;
  assign r_stg2 = ( `ROT8 ) ?  { r_stg1[7:0], r_stg1[31:8]} : r_stg1;
  assign r_stg3 = ( `ROT4 ) ?  { r_stg2[3:0], r_stg2[31:4]} : r_stg2;
  assign r_stg4 = ( `ROT2 ) ?  { r_stg3[1:0], r_stg3[31:2]} : r_stg3;
  assign r_stg5 = ( `ROT1 ) ?  { r_stg4[0],   r_stg4[31:1]} : r_stg4;

  assign r_mask1 = ( `ROT16 ) ? 32'h0000FFFF : 32'hFFFFFFFF;
  assign r_mask2 = ( `ROT8 ) ?  {8'b0 ,r_mask1[31:8]} : r_mask1;
  assign r_mask3 = ( `ROT4 ) ?  {4'b0 ,r_mask2[31:4]} : r_mask2;
  assign r_mask4 = ( `ROT2 ) ?  {2'b0 ,r_mask3[31:2]} : r_mask3;
  assign r_mask5 = ( `ROT1 ) ?  {1'b0 ,r_mask4[31:1]} : r_mask4;

  assign r_sign1 = ( `ROT16 ) ? {{16{din[31]}}, 16'b0} : 32'b0;
  assign r_sign2 = ( `ROT8 ) ?  {{8{din[31]}}, r_sign1[31:8]} : r_sign1;
  assign r_sign3 = ( `ROT4 ) ?  {{4{din[31]}}, r_sign2[31:4]} : r_sign2;
  assign r_sign4 = ( `ROT2 ) ?  {{2{din[31]}}, r_sign3[31:2]} : r_sign3;
  assign r_sign5 = ( `ROT1 ) ?  {{1{din[31]}}, r_sign4[31:1]} : r_sign4;

  // ROL without
  // ASL without - any bits wrapping around should be zeroed
  assign l_stg1 = ( `ROT16 ) ? { stg0[15:0],   stg0[31:16]}   : stg0;
  assign l_stg2 = ( `ROT8 ) ?  { l_stg1[23:0], l_stg1[31:24]} : l_stg1;
  assign l_stg3 = ( `ROT4 ) ?  { l_stg2[27:0], l_stg2[31:28]} : l_stg2;
  assign l_stg4 = ( `ROT2 ) ?  { l_stg3[29:0], l_stg3[31:30]} : l_stg3;
  assign l_stg5 = ( `ROT1 ) ?  { l_stg4[30],   l_stg4[31]}    : l_stg4;

  assign l_mask1 = ( `ROT16 ) ? 32'hFFFF0000: 32'hFFFFFFFF;
  assign l_mask2 = ( `ROT8 ) ?  { l_mask1[23:0], 8'b0} : l_mask1;
  assign l_mask3 = ( `ROT4 ) ?  { l_mask2[27:0], 4'b0} : l_mask2;
  assign l_mask4 = ( `ROT2 ) ?  { l_mask3[29:0], 2'b0} : l_mask3;
  assign l_mask5 = ( `ROT1 ) ?  { l_mask4[30],   1'b0} : l_mask4;

  // Carry out is a copy of the last bit which would wrap around and re-enter the shifter
  assign cout = ( `OP_ASL | `OP_ROL ) ? l_stg5[0] : r_stg5[31];

  // Final stage to pick between left/right rotation and mask as required
  always @ ( * ) begin
    case( opcode )
      `ASR: dout_r = (r_stg5 & r_mask5 ) | r_sign5;
      `LSR: dout_r = (r_stg5 & r_mask5 ) ;
      `ROR: dout_r = r_stg5;
      `ASL: dout_r = (l_stg5 & l_mask5 ) ;
      `ROL: dout_r = l_stg5;
      default: dout_r=din;
    endcase
  end

endmodule

module barrel_shifter_nc(
                         input [31:0] din,
                         input [4:0] distance,
                         input [5:0] opcode,
                         output [31:0] dout
                         );

  wire [31:0] stg0;
  wire [31:0] r_stg1, r_stg2, r_stg3, r_stg4, r_stg5;
  wire [31:0] l_stg1, l_stg2, l_stg3, l_stg4, l_stg5;

  assign stg0 = din;

  // ROR
  // LSR - any bits wrapping around should be zeroed
  // ASR - any bits wrapping around should be set to the original sign bit
  assign r_stg1 = ( `ROT16 ) ? { (`OP_ASR) ? {16{din[31]}}: (`OP_LSR) ? 16'b0: stg0[15:0],  stg0[31:16]}: stg0;
  assign r_stg2 = ( `ROT8 ) ?  { (`OP_ASR) ? {8{din[31]}}: (`OP_LSR) ? 8'b0: r_stg1[7:0], r_stg1[31:8]} : r_stg1;
  assign r_stg3 = ( `ROT4 ) ?  { (`OP_ASR) ? {4{din[31]}}: (`OP_LSR) ? 4'b0: r_stg2[3:0], r_stg2[31:4]} : r_stg2;
  assign r_stg4 = ( `ROT2 ) ?  { (`OP_ASR) ? {2{din[31]}}: (`OP_LSR) ? 2'b0: r_stg3[1:0], r_stg3[31:2]} : r_stg3;
  assign r_stg5 = ( `ROT1 ) ?  { (`OP_ASR) ? {1{din[31]}}: (`OP_LSR) ? 1'b0: r_stg4[0],   r_stg4[31:1]} : r_stg4;

  // ROL without
  // ASL without - any bits wrapping around should be zeroed
  assign l_stg1 = ( `ROT16 ) ? { stg0[15:0],   (`OP_ASL) ? 16'b0 : stg0[31:16]}  : stg0;
  assign l_stg2 = ( `ROT8 ) ?  { l_stg1[23:0], (`OP_ASL) ? 8'b0  :l_stg1[31:24]} : l_stg1;
  assign l_stg3 = ( `ROT4 ) ?  { l_stg2[27:0], (`OP_ASL) ? 4'b0  :l_stg2[31:28]} : l_stg2;
  assign l_stg4 = ( `ROT2 ) ?  { l_stg3[29:0], (`OP_ASL) ? 2'b0  :l_stg3[31:30]} : l_stg3;
  assign l_stg5 = ( `ROT1 ) ?  { l_stg4[30],   (`OP_ASL) ? 1'b0  :l_stg4[31]}    : l_stg4;

  assign dout = ( `OP_ROL || `OP_ASL ) ? l_stg5 : r_stg5;

endmodule
