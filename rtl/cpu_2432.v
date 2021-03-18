
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

  reg [31:0]                   psr_d, psr_q;
  reg [3:0]                    rf_wr_en_d;
  reg                          rstb_q;
  reg [31:0]                   p0_pc_d, p0_pc_q;
  reg                          p0_stage_valid_d;
`ifndef TWO_STAGE_PIPE
  reg [23:0]                   p0_instr_q;
  reg                          p0_stage_valid_q;
`endif
  reg [31:0]                   p0_result_d ;
  reg                          p0_moe_d, p0_moe_q;

  reg                          p1_ead_use_imm_d, p1_ead_use_imm_q;
  reg [31:0]                   p1_imm_d, p1_imm_q;
  reg [31:0]                   p1_pc_d, p1_pc_q;
  reg                          p1_jump_taken_d, p1_jump_taken_q;
  reg                          p1_stage_valid_d, p1_stage_valid_q;
  reg [31:0]                   p1_ead_d, p1_ead_q;
  reg [31:0]                   p1_src0_data_d, p1_src0_data_q;
`ifdef DJNZ_INSTR
  reg [31:0]                   p1_src1_data_d, p1_src1_data_q;
`endif
  reg                          p1_ram_rd_d, p1_ram_rd_q;
  reg                          p1_ram_wr_d, p1_ram_wr_q;
  reg [5:0]                    p1_rdest_d, p1_rdest_q;
  reg [5:0]                    p1_rsrc0_d, p1_rsrc0_q;
  reg [5:0]                    p1_rsrc1_d, p1_rsrc1_q;
  reg [5:0]                    p1_opcode_d, p1_opcode_q;
  reg [3:0]                    p1_cond_d, p1_cond_q;
  reg [31:0]                   p1_ram_dout_d;
  reg                          p1_rf_wr_d, p1_rf_wr_q;

  reg                          p2_jump_taken_d, p2_jump_taken_q ;
  reg [31:0]                   p2_pc_d, p2_pc_q;

  reg                          mcp_q;
  wire [31:0]                  alu_dout;
  wire                         mcp_w;
  wire                         clk_en_w = i_clk_en & !mcp_q;
  wire [31:0]                  rf_dout_0;
  wire [31:0]                  rf_dout_1;
  wire [3:0]                   rf_wen;
  wire [23:0]                  raw_instr_w;
  wire                         qnz_w;

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
  assign o_dout   = p1_ram_dout_d;

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
`ifdef DJNZ_INSTR
          .din_b( p1_src1_data_q),
`else
          .din_b( p1_ead_q),
`endif
          .cin( psr_q[`C] ),
          .vin( psr_q[`V] ),
          .opcode( p1_opcode_q ),
          .dout( alu_dout ),
          .cout( alu_cout ),
          .qnzout(qnz_w),
          .mcp_out(mcp_w),
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
    p1_imm_d = 32'b000000;
    // Expand or pad the opcode, unpack immediates and update any implied register source/dests
    if (raw_instr_w[23:21] == 3'b000 ) begin // Format A
      if ( raw_instr_w[23:18] == `NOT ) begin
        p1_opcode_d =  raw_instr_w[23:18];
      end
      p1_imm_d = { 18'b0, raw_instr_w[11:4], raw_instr_w[17:16], raw_instr_w[3:0]};
      p1_rsrc0_d = 6'b000000 ; // Unused set to RZero
    end
    else if (raw_instr_w[23:21] == 3'b001 ) begin // Format B
      p1_rf_wr_d = 0; // no register writes from a STO
      p1_rdest_d = 6'b000000 ; // Unused set to RZero
      p1_imm_d = { 18'b0, raw_instr_w[15:12], raw_instr_w[7:4], raw_instr_w[17:16], raw_instr_w[3:0]};
    end
    else if (raw_instr_w[23:21] == 3'b010 ) begin // Format C
      // Sign extend immediates
      p1_imm_d = { {22{raw_instr_w[7]}}, raw_instr_w[7:4], raw_instr_w[17:16], raw_instr_w[3:0]};
`ifdef DJNZ_INSTR
      if ( raw_instr_w[23:18] == `DJNZ ) begin
        p1_ead_use_imm_d = 1;
        p1_opcode_d =  raw_instr_w[23:18]; // use full opcode
      end
      else
`endif
        begin
        p1_rf_wr_d = 0; // default is no RF write for format C
        p1_rdest_d = 6'b000000 ;
        p1_ead_use_imm_d = raw_instr_w[18] || ( p1_opcode_d== `JMP || p1_opcode_d==`JSR);
        if ( p1_opcode_d == `JMP || p1_opcode_d == `JSR ) begin // C2
          p1_opcode_d = { raw_instr_w[`OPCODE_RNG] };
          if ( p1_opcode_d == `JSR)
            p1_rf_wr_d = 1;
            p1_rdest_d = 6'b001110 ; // Rlink= R14
          p1_imm_d = { 14'b0, raw_instr_w[15:4], raw_instr_w[17:16], raw_instr_w[3:0]};
          p1_rsrc0_d = 6'b000000 ; // Unused set to RZero
          p1_rsrc1_d = 6'b000000 ; // Unused set to RZero
        end
        else begin
          if ( p1_opcode_d == `JRSRCC)
            p1_rf_wr_d = 1;
            p1_rdest_d = 6'b001110 ; // Rlink= R14
          p1_cond_d = raw_instr_w[`RDST_RNG];
        end // else: !if( p1_opcode_d == `JMP || p1_opcode_d == `JSR )
      end // else: !if(raw_instr_w[23:21] == 3'b010 )
    end
    else if (raw_instr_w[23:21] == 3'b011 ) begin // Format D - Blank out two LSBs
      p1_opcode_d = { raw_instr_w[23:20], 2'b00};
      // No need to read reg for MOVT - dealt with by byte enables
      p1_rsrc0_d = 6'b000000 ; // Unused set to RZero
      p1_rsrc1_d = 6'b000000 ; // Unused set to RZero
      p1_imm_d = { 16'b0, raw_instr_w[19:18], raw_instr_w[11:4], raw_instr_w[17:16], raw_instr_w[3:0] };
      p1_ead_use_imm_d = 1'b1;
    end
    else begin // Format E
      // Sign extended data for arithmetic operations
      if ( p1_opcode_d == `CMP || p1_opcode_d== `BTST )
        p1_rf_wr_d = 0;
      if (p1_ead_use_imm_d )
        p1_rsrc1_d = 6'b000000 ; // Unused set to RZero
`ifdef INCLUDE_MUL
      if ( p1_opcode_d == `MUL || p1_opcode_d == `ADD || p1_opcode_d == `SUB)
`else
      if ( p1_opcode_d == `ADD || p1_opcode_d == `SUB)
`endif
        p1_imm_d = { {22{raw_instr_w[7]}} ,raw_instr_w[7:4], raw_instr_w[17:16], raw_instr_w[3:0] };
      else
        p1_imm_d = { 22'b0 ,raw_instr_w[7:4], raw_instr_w[17:16], raw_instr_w[3:0] };
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
    p0_moe_d = rstb_q & !((p1_opcode_d == `LD_W) &&
                          (p1_opcode_d == `STO_W));  // rstb_q FF delays coming out of reset by 1 cycle
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
          $display("Delay one cycle or write-through for R%d", p1_rdest_d[3:0]);
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
`ifdef DJNZ_INSTR
      else if (p1_rsrc0_q[3:0]==4'b1111 || p1_opcode_q == `DJNZ )
`else
      else if (p1_rsrc0_q[3:0]==4'b1111 )
`endif
        // BRAnch or DJNZ
        // need to read the PC associated with the jump instruction
        // and ensure that stalling is accounted for
`ifdef TWO_STAGE_PIPE
          p0_pc_d = p1_ead_q + p1_pc_q ;
`else
          p0_pc_d = p1_ead_q + p2_pc_q ;
`endif
      else
        p0_pc_d = p1_ead_q + p1_src0_data_q ;
    // If pipe0 is moving then increment PC
    else if (p0_moe_d)
      p0_pc_d = p0_pc_q + 1;
    else
      p0_pc_d = p0_pc_q;
  end

  always @ ( * ) begin
    // Compute the result ready for assigning to the RF
    p0_result_d = alu_dout;
    if ( p1_stage_valid_q ) begin
      if ( p1_opcode_q == `LD_W )
        p0_result_d = i_din ;
      else if (p1_opcode_q == `JSR || p1_opcode_q == `JRSRCC)
        // Value to put into link register and retain flags
`ifdef TWO_STAGE_PIPE
        p0_result_d = p1_pc_q+1; // should come through ALU or be part of RET instuction ie JR CC Rlink, +1
`else
        p0_result_d = p2_pc_q+1; // should come through ALU or be part of RET instuction ie JR CC Rlink, +1
`endif
    end // if ( p1_stage_valid_q )
  end

  always @ ( * ) begin
    // Compute the flag result  - default is to retain PSR
    psr_d = psr_q;
    if ( p1_stage_valid_q ) begin
        if ( p1_opcode_q == `LD_W ) begin
          psr_d[`Z] = !(|p0_result_d);
          psr_d[`S] = p0_result_d[31];
        end
        else if ( p1_rdest_q[5] ) begin
          psr_d = alu_dout;
        end
        else if ( p1_opcode_q == `STO_W ||
                  p1_opcode_q == `JRCC ||
                  p1_opcode_q == `JRSRCC ||
                  p1_opcode_q == `JMP ||
                  p1_opcode_q == `JSR ||
                  p1_opcode_q == `JRSRCC
`ifdef DJNZ_INSTR
                  || p1_opcode_q == `DJNZ
`endif
                  ) begin
          // Retain flags
          psr_d = psr_q;
        end
        else begin
          psr_d[`C] = alu_cout;
          psr_d[`V] = alu_vout;
          psr_d[`S] = alu_dout[31];
          psr_d[`Z] = !(|alu_dout);
        end
    end
  end

  // Pipe Stage 1
  always @(*) begin
    // Invalidate next stage if JUMP and condition true for two cycles
    p1_ram_wr_d = 1'b0;
    p1_ram_dout_d = p1_src0_data_d;
    p1_ram_rd_d = 1'b0;
    p1_pc_d = p0_pc_q;
    p2_pc_d = p1_pc_q;

`ifdef TWO_STAGE_PIPE
    p1_stage_valid_d = rstb_q & p0_moe_d & !p2_jump_taken_d ;  // invalidate any instruction behind a taken jump
`else
    p1_stage_valid_d = p0_stage_valid_q & !p2_jump_taken_d ;  // invalidate any instruction behind a taken jump
`endif
    if ( p1_stage_valid_d ) begin
      p1_ram_rd_d = (p1_opcode_d == `LD_W );
      if ( p1_opcode_d == `STO_W ) begin
        p1_ram_wr_d = 1'b1;
        p1_ram_dout_d = p1_src0_data_d;
      end
    end // if ( p1_stage_valid_d )
  end // always @ (*)

  always @(*) begin
    // Set JMP bits if a jump/branch is to be taken
    p2_jump_taken_d = 0;
    if ( p1_stage_valid_q ) begin
      if (p1_opcode_q == `JMP || p1_opcode_q == `JSR )
        p2_jump_taken_d = 1'b1;
`ifdef DJNZ_INSTR
      else if ( p1_opcode_q==`DJNZ )
        p2_jump_taken_d = qnz_w;
`endif
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
`ifdef DJNZ_INSTR
    // For DJNZ make second input to ALU -1 - ie all 0xF's
    p1_src1_data_d = p1_ead_d | {32{(p1_opcode_d == `DJNZ)}};
`endif
  end

  // Special MCP control for 32x32 multiplications
  always @ ( posedge i_clk or negedge i_rstb ) begin
    if ( ! i_rstb )
      mcp_q <= 1'b0;
    else
      // MCP flop gets set but then zeroed after one cycle
      mcp_q <= mcp_w & !mcp_q;
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
        psr_q <= psr_d;
        p0_pc_q <= p0_pc_d;

        p1_pc_q <= p1_pc_d;
        p1_cond_q <= p1_cond_d;
        p1_jump_taken_q <= p1_jump_taken_d;
        p1_stage_valid_q <= p1_stage_valid_d;
        p1_ead_q <= p1_ead_d;
        p1_src0_data_q <= p1_src0_data_d;
`ifdef DJNZ_INSTR
        p1_src1_data_q <= p1_src1_data_d;
`endif
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
