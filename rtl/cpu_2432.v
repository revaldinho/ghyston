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
                 output [3:0]  o_ram_wr
                 );

  // Register file is 14x32b
  reg [31:0]                   rf_q [14:1];
  reg [31:0]                   pc_d, pc_q;
  reg [31:0]                   psr_d, psr_q;
  reg [3:0]                    rf_wr_en_d;

  reg                          pm1_stage_valid_d, pm1_stage_valid_q;
  reg                          pm2_stage_valid_d, pm2_stage_valid_q;  
  reg                          p0_stage_valid_d, p0_stage_valid_q;
  reg [5:0]                    p0_opcode_d, p0_opcode_q;
  reg                          p0_ead_use_imm_d, p0_ead_use_imm_q;
  // ID the dest/source registers with additional one-hot bits for RZERO, PSR, PC + the original instr field
  reg [6:0]                    p0_rdest_d, p0_rdest_q;
  reg [6:0]                    p0_rsrc0_d, p0_rsrc0_q;
  reg [6:0]                    p0_rsrc1_d, p0_rsrc1_q;
  // Pre-assembled from whichever instruction format is in use, sign extended to 32b
  reg [31:0]                   p0_imm_d, p0_imm_q;
  reg [3:0]                    p0_cond_d, p0_cond_q;
  reg [31:0]                   p0_result_d ;

  reg                          p1_jump_taken_d, p1_jump_taken_q;
  reg                          p1_stage_valid_d, p1_stage_valid_q;
  reg [31:0]                   p1_ead_d, p1_ead_q;
  reg [31:0]                   p1_src0_data_d, p1_src0_data_q;
  reg                          p1_ram_rd_d, p1_ram_rd_q;
  reg [3:0]                    p1_ram_wr_d, p1_ram_wr_q;
  reg [6:0]                    p1_rdest_d, p1_rdest_q;
  reg [6:0]                    p1_rsrc0_d, p1_rsrc0_q;
  reg [6:0]                    p1_rsrc1_d, p1_rsrc1_q;
  reg [5:0]                    p1_opcode_d, p1_opcode_q;
  reg [31:0]                   p1_ram_dout_d;

  reg                          mcp_q;
  wire [31:0]                  alu_dout;
  wire                         mcp_w;
  wire                         clk_en_w = i_clk_en & !mcp_q;

  assign o_iaddr  = pc_q[23:0];
  assign o_daddr  = p1_ead_d[23:0];
  assign o_ram_rd = p1_ram_rd_d;
  assign o_ram_wr = p1_ram_wr_d;
  assign o_dout   = p1_ram_dout_d;


  // Barrel shifter/ALU is effectively after Pipe stage 1
  alu u0 (
          .din_a( p1_src0_data_q ) ,
          .din_b( p1_ead_q ) ,
          .cin( psr_q[`C] ),
          .vin( psr_q[`V] ),
          .opcode( p1_opcode_q ),
          .dout( alu_dout ),
          .cout( alu_cout ),
          .mcp_out(mcp_w),
          .vout( alu_vout )
          );
  // Pipe Stage 0
  always @( * ) begin

    // defaults
    pm2_stage_valid_d = !p1_jump_taken_d;                      // invalidate any instruction behind a taken jump
    pm1_stage_valid_d = pm2_stage_valid_q & !p1_jump_taken_d ;                      // invalidate any instruction behind a taken jump    
    p0_stage_valid_d =  pm1_stage_valid_q & !p1_jump_taken_d ;   // invalidate any instruction behind a taken jump
    p0_ead_use_imm_d = 1'b0;     // expect EAD = rsrc1 + EAD
    p0_cond_d = 4'b0;            // default cond field to be 'unconditional'
    p0_rdest_d = { i_instr[`RDST_RNG]==`RZERO, i_instr[`RDST_RNG]==`RPSR, i_instr[`RDST_RNG]==`RPC, i_instr[`RDST_RNG] };
    p0_rsrc0_d = { i_instr[`RSRC0_RNG]==`RZERO, i_instr[`RSRC0_RNG]==`RPSR, i_instr[`RSRC0_RNG]==`RPC, i_instr[`RSRC0_RNG] };
    p0_rsrc1_d = { i_instr[`RSRC1_RNG]==`RZERO, i_instr[`RSRC1_RNG]==`RPSR, i_instr[`RSRC1_RNG]==`RPC, i_instr[`RSRC1_RNG] };

    p0_opcode_d = 6'b000000;
    p0_imm_d = 32'b000000;

    // Pick and expand the opcode
    // Expand the immediate with sign extension
    // Expand the register selection fields and direct unused fields to RZERO
    if ( i_instr[23] == 1'b1 ) begin               // Format B
      p0_opcode_d = { 3'b100, i_instr[20:18]};
      if ( p0_opcode_d==`ADD|| p0_opcode_d==`SUB )
        p0_imm_d = { {24{i_instr[22]}}, i_instr[22:21], i_instr[5:0]};
      else
        p0_imm_d = { 24'b0, i_instr[22:21],i_instr[5:0]};
    end
    else if (i_instr[23:21] == 3'b000) begin    // Format A
      p0_opcode_d = { i_instr[23:18]};
      p0_rsrc0_d = {3'b000, i_instr[`RDST_RNG]};
      p0_rdest_d = 7'b1000000;
      // Always sign extend in Format A
      p0_imm_d = { {22{i_instr[13]}}, i_instr[13:10],i_instr[5:0]};
      p0_cond_d = i_instr[17:14];
    end
    else if (i_instr[23:21] == 3'b001) begin    // Format C
      p0_opcode_d = { i_instr[23:18]};
      p0_rsrc0_d = 7'b1000000 ; // Unused set to RZero
      p0_imm_d = { 26'b0, i_instr[5:0]};
    end
    else if (i_instr[23:21] == 3'b010) begin     // Format D
      p0_opcode_d = { i_instr[23:20], 2'b00};
      p0_rdest_d = 7'b0010000 ; // LJMP or LCALL instructions dest is PC
      p0_rsrc0_d = 7'b1000000 ; // Unused set to RZero
      p0_rsrc1_d = 7'b1000000 ; // Unused set to RZero
      p0_imm_d = { 12'b0, i_instr[17:14],i_instr[19:18],i_instr[9:6],i_instr[13:10], i_instr[5:0]};
      p0_ead_use_imm_d = 1'b1;
    end
    else begin     // Format E
      p0_opcode_d = { i_instr[23:20], 2'b00};
      p0_rsrc0_d = {3'b000,  i_instr[`RDST_RNG]} ; // Need to read the destination register for MOVT
      p0_rsrc1_d = 7'b1000000 ; // Unused set to RZero
      p0_imm_d = { 16'b0, i_instr[19:18],i_instr[9:6],i_instr[13:10],i_instr[5:0]};
      p0_ead_use_imm_d = 1'b1;
    end // else: !if(i_instr[23:22] == 3'b010)
  end // always @ ( * )

  always @ ( * ) begin
    // Update the PC usually by incrementing but loading directly with the EAD result for taken branches and jumps

    if ( p1_jump_taken_q ) begin
`ifdef DEBUG_D
      $display("Jumping to %08x with opcode %06X", p1_ead_q, p1_opcode_q);
`endif      
      pc_d = p1_ead_q;
    end else begin
      pc_d = pc_q + 1 ;
`ifdef DEBUG_D      
      $display("Incrementing PC to  %08x", pc_d);
`endif      
    end


    // default is to retain PSR
    psr_d = psr_q;
    // default result to be from ALU
    p0_result_d = alu_dout;

    // Compute the result ready for assigning to the RF and propagating forward to flags for calculation in next cycle
    // Need to present the byte in the correct location for writing to the register file
    if ( p1_opcode_q == `LD_B && p1_stage_valid_q ) begin
      p0_result_d = { 24'b0, (i_din >> p1_ead_q[1:0])};
      psr_d[`Z] = !(|p0_result_d);
      psr_d[`S] = alu_dout[31];
    end

    else if ( p1_opcode_q == `LD_H && p1_stage_valid_q ) begin
      p0_result_d = {16'b0, (i_din >> p1_ead_q[0])};
      psr_d[`Z] = !(|p0_result_d);
      psr_d[`S] = alu_dout[31];
    end

    else if ( p1_opcode_q == `LD_W && p1_stage_valid_q ) begin
      p0_result_d = i_din ;
      psr_d[`Z] = !(|p0_result_d);
      psr_d[`S] = alu_dout[31];
    end
    else if ( p1_rdest_q[5] )
      psr_d = alu_dout;
    else if ( p1_rdest_q[4] ) begin
      // DO nothing - only BRA/JMP/CALL can affect PC !
    end

    else if ( p1_opcode_q == `STO_B ||
              p1_opcode_q == `STO_H ||
              p1_opcode_q == `STO_W ||
              p1_opcode_q == `BRA_CC ||
              p1_opcode_q == `CALL_CC ||
              p1_opcode_q == `LJMP ||
              p1_opcode_q == `LCALL ) begin
      // No flag setting for these instructions
      p0_result_d = alu_dout;
    end
    else begin
      psr_d[`C] = alu_cout;
      psr_d[`V] = alu_vout;
      psr_d[`S] = alu_dout[31];
      psr_d[`Z] = !(|alu_dout);
      p0_result_d = alu_dout;
    end

  end

  // Pipe Stage 1
  always @(*) begin
    // Invalidate next stage if JUMP and condition true for two cycles
    p1_stage_valid_d = p0_stage_valid_q ;
    p1_ram_wr_d = 4'b0000;
    p1_ram_dout_d = p1_src0_data_d;
    p1_ram_rd_d = 1'b0;

    if ( p1_stage_valid_d ) begin
      p1_ram_rd_d = ( p0_opcode_q == `LD_B || p0_opcode_q == `LD_H || p0_opcode_q == `LD_W );
      if ( p0_opcode_q == `STO_B && p1_stage_valid_d) begin
        p1_ram_wr_d   = 4'b0001 <<p1_ead_d[1:0] ;
        p1_ram_dout_d = p1_src0_data_d << (p1_ead_d[1:0]*8);
      end
      else if ( p0_opcode_q == `STO_H ) begin
        p1_ram_wr_d = 4'b0011 << p1_ead_d[0] ;
        p1_ram_dout_d = p1_src0_data_d << (p1_ead_d[0]*16);
      end
      else if ( p0_opcode_q == `STO_W ) begin
        p1_ram_wr_d = 4'b1111;
        p1_ram_dout_d = p1_src0_data_d;
      end
    end // if ( p1_stage_valid_d )
  end // always @ (*)

  always @(*) begin
    // Set JMP bits if a jump/branch is to be taken
    p1_jump_taken_d = 0;

    if ( p0_stage_valid_q ) begin
      p1_jump_taken_d = (p0_opcode_q == `LJMP || p0_opcode_q == `LCALL);
      if ( p0_opcode_q==`BRA_CC || p0_opcode_q==`CALL_CC) begin
        case (p0_cond_q)
	  `EQ: p1_jump_taken_d = (psr_q[`Z]==1);    // Equal
	  `NE: p1_jump_taken_d = (psr_q[`Z]==0);    // Not equal
	  `CS: p1_jump_taken_d = (psr_q[`C]==1);    // Unsigned higher or same (or carry set).
	  `CC: p1_jump_taken_d = (psr_q[`C]==0);    // Unsigned lower (or carry clear).
	  `MI: p1_jump_taken_d = (psr_q[`S]==1);    // Negative. The mnemonic stands for "minus".
	  `PL: p1_jump_taken_d = (psr_q[`S]==0);    // Positive or zero. The mnemonic stands for "plus".
	  `VS: p1_jump_taken_d = (psr_q[`V]==1);    // Signed overflow. The mnemonic stands for "V set".
	  `VC: p1_jump_taken_d = (psr_q[`V]==0);    // No signed overflow. The mnemonic stands for "V clear".
	  `HI: p1_jump_taken_d = ((psr_q[`C]==1) && (psr_q[`Z]==0)); // Unsigned higher.
	  `LS: p1_jump_taken_d = ((psr_q[`C]==0) || (psr_q[`Z]==1)); // Unsigned lower or same.
	  `GE: p1_jump_taken_d = (psr_q[`S]==psr_q[`V]);             // Signed greater than or equal.
	  `LT: p1_jump_taken_d = (psr_q[`S]!=psr_q[`V]);             // Signed less than.
	  `GT: p1_jump_taken_d = ((psr_q[`Z]==0) && (psr_q[`S]==psr_q[`V])); // Signed greater than.
	  `LE: p1_jump_taken_d = ((psr_q[`Z]==1) || (psr_q[`S]!=psr_q[`V])); // Signed less than or equal.
	  default: p1_jump_taken_d = 1'b1 ;            // Always - unconditional
        endcase // case (p0_cond_q)
      end // if ( p0_opcode_q==`BRA_CC || p0_opcode_q==`CALL_CC)
    end // if ( p0_stage_valid_q )

    // Pass through expanded opcode and dest/source register Ids
    p1_opcode_d = p0_opcode_q;
    p1_rdest_d = p0_rdest_q;
    p1_rsrc0_d = p0_rsrc0_q;
    p1_rsrc1_d = p0_rsrc1_q;

    // Pick source, immediate and EAD data from the instruction format

    if ( p0_ead_use_imm_q )
      p1_ead_d = p0_imm_q;
    else
      p1_ead_d = p0_imm_q +
                 ((p0_rsrc1_q[6]) ? 32'b0:
                  (p0_rsrc1_q[5]) ? psr_q:
                  (p0_rsrc1_q[4]) ? pc_q:
                  rf_q[(p0_rsrc1_q[3:0])]);

    p1_src0_data_d = ((p0_rsrc0_q[6]) ? 32'b0:
                      (p0_rsrc0_q[5]) ? psr_q:
                      (p0_rsrc0_q[4]) ? pc_q:
                      rf_q[(p0_rsrc0_q[3:0])]);

  end


  always @ ( posedge i_clk ) begin
    if (clk_en_w) begin
      // Register Write - select the result and write the register file
      // Writes to Zero reg, PSR and PC don't go to the register file
      if ( p1_stage_valid_q &&  !(|(p1_rdest_q[6:4])) ) begin
        if ( p1_opcode_q == `LD_B )
          rf_q[p1_rdest_q] = {24'b0, p0_result_d[7:0]};
        else if ( p1_opcode_q == `LD_H )
          rf_q[p1_rdest_q] = {16'b0, p0_result_d[15:0]};
        else begin
`ifdef DEBUG_D          
          $display("Writing %6X to R%d" , p0_result_d, p1_rdest_q);
`endif          
          rf_q[p1_rdest_q]= p0_result_d;
        end
      end // if ( p1_stage_valid_q && |(p1_rdest_q[6:4]) )
    end // if (clk_en)
  end // always @ ( posedge i_clk or negedge i_rstb )


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
      pc_q             <= 0;
      psr_q            <= 0;
      pm1_stage_valid_q <= 1;
      pm2_stage_valid_q <= 1;      
      p0_stage_valid_q <= 0;
      p0_opcode_q      <= 0;
      p0_ead_use_imm_q <= 0;
      p0_rdest_q       <= 0;
      p0_rsrc0_q       <= 0;
      p0_rsrc1_q       <= 0;
      p0_imm_q         <= 0;
      p0_cond_q        <= 0;
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
    end
    else
      if ( clk_en_w ) begin
        pc_q <= pc_d;
        psr_q <= psr_d;
        pm2_stage_valid_q <= pm2_stage_valid_d;        
        pm1_stage_valid_q <= pm1_stage_valid_d;

        p0_stage_valid_q <= p0_stage_valid_d;
        p0_opcode_q <= p0_opcode_d;
        p0_ead_use_imm_q <= p0_ead_use_imm_d;
        p0_rdest_q <= p0_rdest_d;
        p0_rsrc0_q <= p0_rsrc0_d;
        p0_rsrc1_q <= p0_rsrc1_d;
        p0_imm_q <= p0_imm_d;
        p0_cond_q <= p0_cond_d;

        p1_jump_taken_q <= p1_jump_taken_d;
        p1_stage_valid_q <= p1_stage_valid_d;
        p1_ead_q <= p1_ead_d;
        p1_src0_data_q <= p1_src0_data_d;
        p1_ram_rd_q <= p1_ram_rd_d;
        p1_ram_wr_q <= p1_ram_wr_d;
        p1_rdest_q <= p1_rdest_d;
        p1_rsrc0_q <= p1_rsrc0_d;
        p1_rsrc1_q <= p1_rsrc1_d;
        p1_opcode_q <= p1_opcode_d;
      end
  end



endmodule
