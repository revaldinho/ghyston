`include "cpu_2432.vh"

`ifdef SHIFT_32
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
           input         shift_instr,
           output [31:0] dout,
           output        cout,
           output reg    djtaken,
           output reg    vout
           );

  reg [31:0]             alu_dout;
  reg                    alu_cout;
  reg                    borrow_out;
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

  assign {cout,dout} = ( shift_instr ) ? {shifted_c, shifted_w} : { alu_cout, alu_dout};

  always @(*) begin
    alu_cout = cin;
    vout = vin;
    alu_dout = 32'bx;
    djtaken = 1'bx;
    borrow_out = 1'bx;

    case ( opcode )
      //MOVT will have the bits shifted to the top of the word before writing the regfile
      `LMOVT      :{alu_cout,alu_dout} = {cin, din_b[15:0], din_a[15:0]} ;
      `LMOV       :{alu_cout,alu_dout} = {cin, din_b} ;
      `AND        :{alu_cout,alu_dout} = {1'b0,(din_a & din_b)};
      `OR         :{alu_cout,alu_dout} = {1'b1,(din_a | din_b)};
      `XOR        :{alu_cout,alu_dout} = {cin,(din_a ^ din_b)};
      // Restrict multiplies to 18x18 to fit a single DSP slice on a Spartan
      // 6 FPGA and single cycle execution
`ifdef MUL_INSTR
      `MUL        : begin
        {alu_cout,alu_dout} = din_a[17:0] * din_b[17:0];
        vout = !(din_a[31] ^ din_b[31] ^ alu_dout[31]);
      end
`endif
`ifdef PRED_INSTR
      `ADDIF, `ADD      :
`else
      `ADD              :
`endif
        begin
        // overflow if -ve + -ve = +ve  or +ve + +ve = -ve
        {alu_cout,alu_dout} = din_a + din_b;
        vout =  ( din_a[31] & din_b[31] & !alu_dout[31]) ||
                ( !din_a[31] & !din_b[31] & alu_dout[31]) ;
      end
`ifdef DJNZ_Z_INSTR
      `DJNZ : begin
        {alu_cout,alu_dout} = {din_a - 32'b01};
        djtaken = (din_a != 32'h00000001); // Jump if result will be NON-zero
      end
      `DJZ : begin
        {alu_cout,alu_dout} = {din_a - 32'b01};
        djtaken = (din_a == 32'h00000001); // Jump if result will be zero
      end
`endif
`ifdef PRED_INSTR
      `SUBIF :  begin
        {borrow_out,alu_dout} = din_a - din_b;
        alu_cout = !borrow_out;
        // overflow if -ve - +ve = +ve  or +ve - -ve = -ve
        vout =  ( din_a[31] & !din_b[31] & !alu_dout[31]) ||
                ( !din_a[31] & din_b[31] & alu_dout[31]) ;
      end
`endif
`ifdef DJMI_PL_INSTR
      `DJPL : begin
        {alu_cout,alu_dout} = {din_a - 32'b01};
	djtaken = din_a[31] | ( !(|din_a[30:0])); // Jump if result will be negative, ie A already negative or = 0
      end
      `DJMI : begin
        {alu_cout,alu_dout} = {din_a - 32'b01};
	djtaken = !din_a[31] & ( |din_a[30:0]); // Jump if result be positive, ia A is positive and non-zero
      end
`endif
`ifdef NEG_INSTR
      `NEG : begin
        alu_dout = (~din_b)+1;
      end
`endif
      `SUB, `CMP :
        begin
          {borrow_out,alu_dout} = din_a - din_b;
          alu_cout = !borrow_out;
          // overflow if -ve - +ve = +ve  or +ve - -ve = -ve
          vout =  ( din_a[31] & !din_b[31] & !alu_dout[31]) ||
                  ( !din_a[31] & din_b[31] & alu_dout[31]) ;
        end

      `BTST             :{alu_cout,alu_dout} = {cin, din_a & (32'b1 <<  (din_b & 32'h01F))};
      `BSET             :{alu_cout,alu_dout} = {cin, din_a | (32'b1 <<  (din_b & 32'h01F))};
      `BCLR             :{alu_cout,alu_dout} = {cin, din_a & ~(32'b1 << (din_b &  32'h01F))};
      default           :{alu_cout,alu_dout} = {cin,din_b} ;
    endcase // case opcode
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
`ifdef PRED_INSTR
      `ASR, `ASRIF : begin
        stg0 = { din, cin, {32{din[31]}}} ;
        {dout, cout} = { r_stg5[64:32]};
      end
`else
      `ASR : begin
        stg0 = { din, cin, {32{din[31]}}} ;
        {dout, cout} = { r_stg5[64:32]};
      end
`endif
      `LSR : begin
        stg0 = { din, cin, 32'b0};
        {dout, cout} = { r_stg5[64:32]};
      end
      default: stg0=65'bx;
    endcase // case ( opcode )
  end

  // ROR - rotate through carry
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
