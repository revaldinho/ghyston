module ram_8192x32 (
                    input [31:0]      din,
                    output reg [31:0] dout,
                    input [12:0]      address,
                    input             rnw,
                    input             clk,
                    input             cs_b
                    );

  reg [31:0]                           ram [0:8191];
  reg [12:0]                           raddr_r;
  parameter MEM_INIT_FILE = "ram.hex";

  initial begin
    if (MEM_INIT_FILE != "") begin
      $readmemh(MEM_INIT_FILE, ram);
    end
  end

  always @ ( posedge clk ) begin
    if (!cs_b & !rnw) begin
      ram[address] <= din;
      $display("RAM Write addr=%08x data=%08x", address, din );
    end
    if (!cs_b & rnw) begin
      dout <= ram[address];
      $display("RAM Read addr=%08x data=%08x", address, ram[address] );
    end
   end

endmodule
