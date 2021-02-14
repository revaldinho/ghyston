module grf1w2r (
                input [3:0]   i_waddr,
                input [3:0]   i_wen,
                input [3:0]   i_raddr_0,
                input [3:0]   i_raddr_1,
                input         i_cs_b,
                input [31:0]  i_din,
                input         i_clk,
                input         i_clk_en,

                output reg [31:0] o_dout_0,
                output reg [31:0] o_dout_1
                );

  // Synchronous write, asynchronous read with write-through/bypassing
  reg [31:0]                  rf_q [15:0];
  wire [31:0] din = {
                     (i_wen[3]     )?i_din[31:24]:rf_q[i_waddr][31:24],
                     (i_wen[2])?i_din[23:16]:rf_q[i_waddr][23:16],
                     (i_wen[1])?i_din[15:8]:rf_q[i_waddr][15:8],
                     (i_wen[0])?i_din[7:0]:rf_q[i_waddr][7:0]
                     };

  integer     i;
  
  
  // Bypassing when a valid write address is same as read address
  always @ (*) begin
    o_dout_0 = rf_q[i_raddr_0];    
    o_dout_1 = rf_q[i_raddr_1];    

    if ( !i_wen && !i_cs_b ) begin
      if (i_waddr == i_raddr_0 )
        o_dout_0 = din;      
      else
        o_dout_0 = rf_q[i_raddr_0];
      if (i_waddr == i_raddr_1 )
        o_dout_1 = din;      
      else
        o_dout_1 = rf_q[i_raddr_1];
    end
  end 
  
  always @ ( posedge i_clk ) begin
    if (i_clk_en)
      if ( !i_cs_b) begin
        rf_q[i_waddr] <= din;
        $display("Writing %6X to R%d" , din, i_waddr);
`ifdef DEBUG_D        
        for ( i=0 ; i< 6 ; i= i+1) begin
          $display("Reg %02d = %08X", i, rf_q[i]);
        end
`endif        
      end    
  end

endmodule // grf1w2r
