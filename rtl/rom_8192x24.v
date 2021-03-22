module rom_8192x24 (
                     output reg [23:0] dout,
                     input [12:0]      address,
                     input             clk,
                     input             cs_b
                     );

  parameter MEM_INIT_FILE = "rom.hex";

  (* KEEP="TRUE" *) reg [23:0]                           rom [0:8191];

  initial begin
    if (MEM_INIT_FILE != "") begin
      $readmemh(MEM_INIT_FILE, rom);
    end
  end

  always @(posedge clk)
    if (!cs_b) begin
      dout <= rom[address];
    end

endmodule
