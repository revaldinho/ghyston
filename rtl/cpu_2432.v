`include "cpu_2432.vh"

module cpu_2432 (
                 input [23:0]  i_instr,
                 input         i_clk,
                 input         i_clk_en,
                 input         i_rstb,
                 input [31:0]  i_din,
                 output [23:0] o_iaddr,
                 output [23:0] o_daddr,
                 output [31:0] o_dout,
                 output        o_ram_rd,
                 output        o_ram_wr
                 );

  reg [31:0]                   next_pc;
  reg [31:0]                   psr_d, psr_q;
  reg [3:0]                    rf_wr_en_d;
  reg                          rstb_q;
  reg [31:0]                   p0_pc_d, p0_pc_q;
  reg                          p0_stage_valid_d;
`ifndef TWO_STAGE_PIPE
  reg [23:0]                   p0_instr_q;
  reg                          p0_stage_valid_q;
`endif
`ifdef ZLOOP_INSTR
  reg                          p0_zloop_valid_d, p0_zloop_valid_q;
  reg [31:0]                   p0_zloop_start_d, p0_zloop_start_q;
  reg [31:0]                   p0_zloop_end_d, p0_zloop_end_q;
`endif
  reg [31:0]                   p0_result_d ;
  reg                          p0_moe_d, p0_moe_q;

  reg                          p1_djxx_instr_d, p1_djxx_instr_q;
  reg                          p1_shift_instr_d, p1_shift_instr_q;
  reg                          p1_retain_flags_d, p1_retain_flags_q;
  reg                          p1_ead_use_imm_d, p1_ead_use_imm_q;
  reg [31:0]                   p1_imm_d, p1_imm_q;
  reg [31:0]                   p1_pc_d, p1_pc_q;
  reg                          p1_jump_taken_d, p1_jump_taken_q;
  reg                          p1_stage_valid_d, p1_stage_valid_q;
  reg [31:0]                   p1_ead_d, p1_ead_q;
  reg [31:0]                   p1_src0_data_d,  p1_src0_data_q;
  reg [31:0]                   p1_src1_data_d, p1_src1_data_q;
  reg                          p1_ram_rd_d, p1_ram_rd_q;
  reg                          p1_ram_wr_d, p1_ram_wr_q;
  reg [5:0]                    p1_rdest_d, p1_rdest_q;
  reg [5:0]                    p1_rsrc0_d, p1_rsrc0_q;
  reg [5:0]                    p1_rsrc1_d, p1_rsrc1_q;
  reg [5:0]                    p1_opcode_d, p1_opcode_q;
  reg [3:0]                    p1_cond_d, p1_cond_q;
  reg                          p1_rf_wr_d, p1_rf_wr_q;



  reg                          p2_jump_taken_d, p2_jump_taken_q ;
  reg [31:0]                   p2_pc_d, p2_pc_q;

  wire [31:0]                  alu_dout;
  wire                         clk_en_w = i_clk_en ;
  wire [31:0]                  rf_dout_0;
  wire [31:0]                  rf_dout_1;
  wire [3:0]                   rf_wen;
  wire [23:0]                  raw_instr_w;
  wire                         djtaken_w;

`ifdef TWO_STAGE_PIPE
  assign raw_instr_w = i_instr;
`else
  assign raw_instr_w = p0_instr_q;
`endif

`ifndef BYPASS_EN_D
  wire [3:0]                   rf0_wen;
`endif

  assign o_iaddr  = p0_pc_d[23:0];
  assign o_daddr  = p1_ead_d[23:0];
  assign o_ram_rd = p1_ram_rd_d;
  assign o_ram_wr = p1_ram_wr_d;
  assign o_dout   = p1_src0_data_d;

  assign rf_wen = { (p1_rf_wr_q ),
                    (p1_rf_wr_q ),
                    (p1_rf_wr_q && p1_opcode_q != `LMOVT),
                    (p1_rf_wr_q && p1_opcode_q != `LMOVT) };

`ifndef BYPASS_EN_D
  assign rf0_wen = { (p1_rf_wr_d ),
                     (p1_rf_wr_d ),
                     (p1_rf_wr_d && p1_opcode_d != `LMOVT),
                     (p1_rf_wr_d && p1_opcode_d != `LMOVT) };
`endif

  // General Register File
  grf1w2r u0(
             .i_waddr(p1_rdest_q[3:0]),
             .i_cs_b ( !(p1_stage_valid_q &&  !(|(p1_rdest_q[5:4])))),
             .i_wen(rf_wen),
             .i_raddr_0(p1_rsrc0_d[3:0]),
             .i_raddr_1(p1_rsrc1_d[3:0]),
             .i_din(p0_result_d),
             .i_clk(i_clk),
             .i_clk_en(clk_en_w),
             .o_dout_0(rf_dout_0),
             .o_dout_1(rf_dout_1)
             );

  // Barrel shifter/ALU is effectively after Pipe stage 1
  alu u1 (
          .din_a( p1_src0_data_q),
          .din_b( p1_src1_data_q),
          .cin( psr_q[`C] ),
          .vin( psr_q[`V] ),
          .opcode( p1_opcode_q ),
          .shift_instr(p1_shift_instr_q),
          .dout( alu_dout ),
          .cout( alu_cout ),
          .djtaken(djtaken_w),
          .vout( alu_vout )
          );

  // Pipe Stage 1
  always @( * ) begin
    // defaults
    p1_rf_wr_d = 1'b1;           // default is for result to be written to reg file
    p1_cond_d = 4'hF;            // default cond field to be 'unconditional'
    // Reg     =   PSR               PC                   RF Addr
    p1_rdest_d = { 1'b0, raw_instr_w[`RDST_RNG]==`RPC , raw_instr_w[`RDST_RNG] };
    p1_rsrc0_d = { 1'b0, raw_instr_w[`RSRC0_RNG]==`RPC, raw_instr_w[`RSRC0_RNG] };
    p1_rsrc1_d = { 1'b0, raw_instr_w[`RSRC1_RNG]==`RPC, raw_instr_w[`RSRC1_RNG] };
    // Most instructions use 5 MSBs as instruction and 1 bit as direct flag
    p1_opcode_d = { raw_instr_w[23:19], 1'b0};      // Blank out LSB
    p1_ead_use_imm_d = raw_instr_w[18];
    // default to sign extending a 10 bit immediate
    p1_imm_d = { {22{raw_instr_w[7]}}, raw_instr_w[7:4], raw_instr_w[17:16], raw_instr_w[3:0]};

    if ( raw_instr_w[23] ) begin // Format E covers most instructions 0b1xxxxx
      if ( p1_opcode_d == `CMP || p1_opcode_d== `BTST )
        p1_rf_wr_d = 0;          // No register write for these instructions
    end
    else if ( raw_instr_w[23:21] == 3'b000) begin // Format A: DJxx, ZLOOP, RETI, JMP,JSR
      p1_ead_use_imm_d = 1'b1;                    // All format A instructions use an immediate
      p1_opcode_d = raw_instr_w[`OPCODE_RNG] ;    // ..and need full 6 bit opcode
`ifdef ZLOOP_INSTR
      if ( p1_opcode_d == `JMP || p1_opcode_d == `ZLOOP)
`else
      if ( p1_opcode_d == `JMP )
`endif
        p1_rf_wr_d = 0;          // No register write for these instructions (JMP write PC only, ZLOOP internal state)
      else if ( p1_opcode_d == `JSR) begin
        p1_rdest_d = 6'b001110 ; // JSR writes R14 with return address
      end
      if ( p1_opcode_d == `JMP || p1_opcode_d == `JSR) begin
        // Zero-extended long immediate
        p1_imm_d = { 14'b0, raw_instr_w[15:4], raw_instr_w[17:16], raw_instr_w[3:0]};
      end
    end
    else if (raw_instr_w[23:21] == 3'b010 ) begin   // Format C: LMOV/T
      p1_ead_use_imm_d = 1'b1;                      // Always use immediate, obviously
      p1_opcode_d = { raw_instr_w[23:20], 2'b00};   // Blank out bottom two bits of opcode which are used as immediate
      // No need to read reg for MOVT - dealt with by byte enables
      p1_imm_d = { 16'b0, raw_instr_w[19:18], raw_instr_w[11:4], raw_instr_w[17:16], raw_instr_w[3:0] }; // zero-ext long immediate
    end
    else if (raw_instr_w[23:20] == 4'b0011 ) begin  // Format D: Load/Store
      if ( p1_opcode_d == `STO ) begin
        p1_rsrc0_d = p1_rdest_d; // dest register is actually the source for a STO
        p1_rf_wr_d = 0; // no register writes from a STO
      end
      // zero-extended 14 bit immediate
      p1_imm_d = { 18'b0, raw_instr_w[15:12], raw_instr_w[7:4], raw_instr_w[17:16], raw_instr_w[3:0]};
    end
    else if ( raw_instr_w[23:20] == 4'b0010) begin // Format B: JRCC (BRA), JRSRCC (BSR)
      p1_cond_d = raw_instr_w[`RDST_RNG];  // Finally use the destination register field as a conditional
      if ( p1_opcode_d == `JRCC)
        p1_rf_wr_d = 0;                    // Branch instruction does not write register file
      else
        p1_rdest_d = 6'b001110 ;           // Rlink= R14 for JRSR
      //$display("JR code=%02X src0=%02X data0=%08X src1=%02X data1=%08X", p1_cond_d, p1_rsrc0_d, rf_dout_0, p1_rsrc1_d, rf_dout_1);
    end
    else begin
      $display("Illegal opcode %06X", raw_instr_w);
      $finish;
    end
  end

  always @ ( * ) begin
    p0_stage_valid_d = rstb_q & p0_moe_d & (!(p2_jump_taken_d && p1_stage_valid_q)) ; // invalidate any instruction behind a taken jump
  end

  always @ ( * ) begin
    // Check for back to back reg write/reads which need to stall for 1 cycle (and no more than one cycle)
    // rather than use a combinatorial bypass
//`define BYPASS_EN_D 1
`ifdef BYPASS_EN_D
    p0_moe_d = rstb_q & !((p1_opcode_d == `LD) &&
                          (p1_opcode_d == `STO));  // rstb_q FF delays coming out of reset by 1 cycle
`else
//  `define HALF_RATE_D 1
  `ifdef HALF_RATE_D
    p0_moe_d = !p0_moe_q;
  `else
    p0_moe_d =  ;
//    $display("%02X %d %X %d %02X %02X %02X", p0_opcode_d, p0_moe_q,rf0_wen, p0_stage_valid_q, p1_rdest_d, p0_rsrc0_d, p0_rsrc1_d);
    if ( p0_moe_q )
      if ((|rf0_wen) & !(|p1_rdest_d[5:4])) begin
        if ( (p1_rdest_d == p0_rsrc0_d) || (p1_rdest_d == p0_rsrc1_d) ) begin
//          $display("Delay one cycle or write-through for R%d", p1_rdest_d[3:0]);
          p0_moe_d = 1'b0;
        end
      end
  `endif // !`ifdef HALFRATE
`endif
  end // always @ (*)

  always @ ( * ) begin
    // If a jump is take always load the PC directly even if pipe0 stage is stalled because
    // a jump will invalidate anything in earlier stages anyway
    if ( p2_jump_taken_d && p1_stage_valid_q)
      if ( p1_opcode_q == `JMP || p1_opcode_q == `JSR )
        p0_pc_d = p1_ead_q;
      else if (p1_rsrc0_q[3:0]==4'b1111 || p1_djxx_instr_q)
        // BRAnch or DJxx
        // need to read the PC associated with the jump instruction
        // and ensure that stalling is accounted for
`ifdef TWO_STAGE_PIPE
          p0_pc_d = p1_ead_q + p1_pc_q ;
`else
          p0_pc_d = p1_ead_q + p2_pc_q ;
`endif
      else
        p0_pc_d = p1_ead_q + p1_src0_data_q ;
    else if (p0_moe_d) begin
      next_pc = p0_pc_q + 1;  // default is to increment PC
`ifdef ZLOOP_INSTR
      p0_pc_d = (p0_zloop_valid_q && (next_pc==p0_zloop_end_q)) ? p0_zloop_start_q : next_pc;
`else
      p0_pc_d = next_pc;
`endif
    end
    else
      p0_pc_d = p0_pc_q;
  end


  always @ ( * ) begin
    // Compute the result ready for assigning to the RF
`ifdef ZLOOP_INSTR
    p0_zloop_start_d = p0_zloop_start_q;
    p0_zloop_end_d = p0_zloop_end_q;
    p0_zloop_valid_d = p0_zloop_valid_q;
`endif
    p0_result_d = alu_dout;
    if ( p1_stage_valid_q ) begin
      if ( p1_opcode_q == `LD )
        p0_result_d = i_din ;
`ifdef ZLOOP_INSTR
      else if ( p1_opcode_q == `ZLOOP ) begin
        p0_zloop_valid_d = 1'b1;
  `ifdef TWO_STAGE_PIPE
        p0_zloop_end_d = p1_ead_q + p1_pc_q ;
        p0_zloop_start_d = p1_pc_q+1; // should come through ALU or be part of RET instuction ie JR CC Rlink, +1
  `else
        p0_zloop_end_d = p1_ead_q + p2_pc_q ;
        p0_zloop_start_d = p2_pc_q+1; // should come through ALU or be part of RET instuction ie JR CC Rlink, +1
  `endif
      end
`endif
      else if (p1_opcode_q == `JSR || p1_opcode_q == `JRSRCC) begin
        // Value to put into link register and retain flags
`ifdef TWO_STAGE_PIPE
        p0_result_d = p1_pc_q+1; // should come through ALU or be part of RET instuction ie JR CC Rlink, +1
`else
        p0_result_d = p2_pc_q+1; // should come through ALU or be part of RET instuction ie JR CC Rlink, +1
`endif
      end
    end // if ( p1_stage_valid_q )
  end // always @ ( * )


  always @ ( * ) begin
    // Compute the flag result  - default is to retain PSR
    psr_d = psr_q;
    if ( p1_stage_valid_q ) begin
      if ( p1_rdest_q[5] )
        psr_d = alu_dout;
      else if ( p1_retain_flags_q )
        psr_d = psr_q;
      else begin
        psr_d[`C] = alu_cout;
        psr_d[`V] = alu_vout;
        psr_d[`S] = alu_dout[31];
        psr_d[`Z] = !(|alu_dout);
      end
    end
  end // always @ ( * )


  // Pipe Stage 1
  always @(*) begin
    p1_retain_flags_d = ( p1_opcode_d == `LD || p1_opcode_d == `STO ||
                        p1_opcode_d == `JRCC || p1_opcode_d == `JRSRCC ||
                        p1_opcode_d[5:3] == 3'b000 ) ; // JMP,JSR,DJNZ,ZLOOP instructions
    p1_djxx_instr_d = (
`ifdef DJNZ_Z_INSTR
                       p1_opcode_d == `DJNZ || p1_opcode_d == `DJZ ||
`endif
`ifdef DJMI_PL_INSTR
                       p1_opcode_d == `DJMI || p1_opcode_d == `DJPL ||
`endif
                       1'b0 );

    p1_shift_instr_d = ( p1_opcode_d ==`ASR || p1_opcode_d ==`ROR ||
                         p1_opcode_d ==`LSR || p1_opcode_d ==`ASL ||
                         p1_opcode_d ==`ROL);

    p1_ram_wr_d = 1'b0;
    p1_ram_rd_d = 1'b0;
    p1_pc_d = p0_pc_q;
    p2_pc_d = p1_pc_q;
    // Invalidate next stage if JUMP and condition true for two cycles
`ifdef TWO_STAGE_PIPE
    p1_stage_valid_d = rstb_q & p0_moe_d & !p2_jump_taken_d ;  // invalidate any instruction behind a taken jump
`else
    p1_stage_valid_d = p0_stage_valid_q & !p2_jump_taken_d ;  // invalidate any instruction behind a taken jump
`endif
    if ( p1_stage_valid_d ) begin
      p1_ram_rd_d = (p1_opcode_d == `LD );
      if ( p1_opcode_d == `STO ) begin
        p1_ram_wr_d = 1'b1;
      end
    end // if ( p1_stage_valid_d )
  end // always @ (*)

  always @(*) begin
    // Set JMP bits if a jump/branch is to be taken
    p2_jump_taken_d = 0;
    if ( p1_stage_valid_q ) begin
      if (p1_opcode_q == `JMP || p1_opcode_q == `JSR )
        p2_jump_taken_d = 1'b1;
      else if ( p1_djxx_instr_q )
        p2_jump_taken_d = djtaken_w;
      else if ( p1_opcode_q==`JRCC || p1_opcode_q==`JRSRCC) begin
        case (p1_cond_q)
	  `EQ: p2_jump_taken_d = (psr_q[`Z]==1);    // Equal
	  `NE: p2_jump_taken_d = (psr_q[`Z]==0);    // Not equal
	  `CS: p2_jump_taken_d = (psr_q[`C]==1);    // Unsigned higher or same (or carry set).
	  `CC: p2_jump_taken_d = (psr_q[`C]==0);    // Unsigned lower (or carry clear).
	  `MI: p2_jump_taken_d = (psr_q[`S]==1);    // Negative. The mnemonic stands for "minus".
	  `PL: p2_jump_taken_d = (psr_q[`S]==0);    // Positive or zero. The mnemonic stands for "plus".
	  `VS: p2_jump_taken_d = (psr_q[`V]==1);    // Signed overflow. The mnemonic stands for "V set".
	  `VC: p2_jump_taken_d = (psr_q[`V]==0);    // No signed overflow. The mnemonic stands for "V clear".
	  `HI: p2_jump_taken_d = ((psr_q[`C]==1) && (psr_q[`Z]==0)); // Unsigned higher.
	  `LS: p2_jump_taken_d = ((psr_q[`C]==0) || (psr_q[`Z]==1)); // Unsigned lower or same.
	  `GE: p2_jump_taken_d = (psr_q[`S]==psr_q[`V]);             // Signed greater than or equal.
	  `LT: p2_jump_taken_d = (psr_q[`S]!=psr_q[`V]);             // Signed less than.
	  `GT: p2_jump_taken_d = ((psr_q[`Z]==0) && (psr_q[`S]==psr_q[`V])); // Signed greater than.
	  `LE: p2_jump_taken_d = ((psr_q[`Z]==1) || (psr_q[`S]!=psr_q[`V])); // Signed less than or equal.
	  default: p2_jump_taken_d = 1'b1 ;            // Always - unconditional
        endcase
      end // if ( p1_opcode_q==`JRCC || p1_opcode_q==`JRSRCC)
      else
        p2_jump_taken_d = 1'b0;
    end
  end // always @ (*)

  always @ ( * ) begin
    // Register File read every cycle
    // Pick source, immediate and EAD data from the instruction format
    if ( p1_ead_use_imm_d )
      p1_ead_d = p1_imm_d;
    else
      p1_ead_d =  ((p1_rsrc1_d[5]) ? psr_q:
                   (p1_rsrc1_d[4]) ? p0_pc_q:
                   rf_dout_1 );
    p1_src0_data_d = ((p1_rsrc0_d[5]) ? psr_q:
                     (p1_rsrc0_d[4]) ? p0_pc_q:
                     rf_dout_0);
    p1_src1_data_d = p1_ead_d ;
  end

  // Edge triggered state
  always @ ( posedge i_clk or negedge i_rstb ) begin
    if ( !i_rstb ) begin
      psr_q            <= 0;
      p0_pc_q          <= 0;
      p0_moe_q         <= 0;
`ifndef TWO_STAGE_PIPE
      p0_instr_q       <= 0;
      p0_stage_valid_q <= 0;
`endif
      p1_djxx_instr_q   <= 0;
      p1_shift_instr_q  <= 0;
      p1_retain_flags_q <= 0;
      p1_pc_q          <= 0;
      p1_jump_taken_q  <= 0;
      p1_stage_valid_q <= 0;
      p1_ead_q         <= 0;
      p1_src0_data_q   <= 0;
      p1_ram_rd_q      <= 0;
      p1_ram_wr_q      <= 0;
      p1_rdest_q       <= 0;
      p1_rsrc0_q       <= 0;
      p1_rsrc1_q       <= 0;
      p1_opcode_q      <= 0;
      p1_cond_q        <= 0;
      p1_rf_wr_q       <= 0;
      p2_jump_taken_q  <= 0;
`ifdef ZLOOP_INSTR
      p0_zloop_valid_q <= 0;
      p0_zloop_start_q <= 0;
      p0_zloop_end_q   <= 0;
`endif
      rstb_q           <= 0;
    end
    else
      if ( clk_en_w ) begin
        rstb_q   <= i_rstb;
        p0_moe_q <= p0_moe_d;
`ifndef TWO_STAGE_PIPE
        p0_instr_q <= i_instr;
        p0_stage_valid_q <= p0_stage_valid_d;
`endif
`ifdef ZLOOP_INSTR
        p0_zloop_valid_q <= p0_zloop_valid_d;
        p0_zloop_start_q <= p0_zloop_start_d;
        p0_zloop_end_q <= p0_zloop_end_d;
`endif
        psr_q <= psr_d;
        p0_pc_q <= p0_pc_d;
        p1_shift_instr_q  <= p1_shift_instr_d;
        p1_djxx_instr_q <= p1_djxx_instr_d;
        p1_retain_flags_q <= p1_retain_flags_d;
        p1_pc_q <= p1_pc_d;
        p1_cond_q <= p1_cond_d;
        p1_jump_taken_q <= p1_jump_taken_d;
        p1_stage_valid_q <= p1_stage_valid_d;
        p1_ead_q <= p1_ead_d;
        p1_src0_data_q <= p1_src0_data_d;
        p1_src1_data_q <= p1_src1_data_d;
        p1_ram_rd_q <= p1_ram_rd_d;
        p1_ram_wr_q <= p1_ram_wr_d;
        p1_rdest_q <= p1_rdest_d;
        p1_rsrc0_q <= p1_rsrc0_d;
        p1_rsrc1_q <= p1_rsrc1_d;
        p1_opcode_q <= p1_opcode_d;
        p1_rf_wr_q <= p1_rf_wr_d;
        p2_pc_q <= p2_pc_d;
        p2_jump_taken_q <= p2_jump_taken_d;
      end
  end
endmodule
