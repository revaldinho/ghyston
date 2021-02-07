module ram_8192x32 ( 
                     input [31:0]      din, 
                     output reg [31:0] dout, 
                     input [12:0]      address, 
                     input             rnw, 
                     input             clk, 
                     input [3:0]       cs_b
                     );

  
   reg [31:0] ram [0:8191];

   always @(posedge clk) begin
     if (!cs_b[0] & !rnw) 
       ram[address][7:0] <= din[7:0];
     if (!cs_b[1] & !rnw) 
       ram[address][15:8] <= din[15:8];
     if (!cs_b[2] & !rnw) 
       ram[address][23:16] <= din[23:16];
     if (!cs_b[3] & !rnw) 
       ram[address][31:24] <= din[31:24];
     
     dout <= ram[address];     
   end
           
endmodule
