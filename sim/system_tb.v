`timescale 1ns / 1ns

module system_tb() ;
  reg         clk, reset_b, clken;
  wire [31:0] gpio_w;

  parameter   VCD_FILE="", RAM_DUMP_FILE="";

  system   dut_0
    (
        .i_clk(clk),
        .i_clk_en(clken),
        .i_rstb(reset_b),
        .io_gpio(gpio_w)
        );

`ifdef MEM_INIT_FILE_D
  defparam dut_0.irom_0.MEM_INIT_FILE = `MEM_INIT_FILE_D ;
`else
  defparam dut_0.irom_0.MEM_INIT_FILE = "rom.hex" ;
`endif

`ifdef VCD_FILE_D  
  defparam VCD_FILE = `VCD_FILE_D ;
`else
  defparam VCD_FILE = "test.vcd" ;
`endif

`ifdef RAM_DUMP_FILE_D  
  defparam RAM_DUMP_FILE = `RAM_DUMP_FILE_D ;
`else
  defparam RAM_DUMP_FILE = "test.vcd" ;
`endif

  initial begin
`ifdef VCD_FILE_D
    $dumpfile(VCD_FILE);
    $dumpvars;
`endif
    { clk, reset_b}  = 0;
    clken = 1'b1;
    #1005 reset_b = 1;
    #4000 ;
`ifdef RAM_DUMP_FILE_D    
    $writememh(RAM_DUMP_FILE, dut_0.dram_0.ram);
`endif    
    $finish;
  end

  always begin
    #50 clk = !clk;
  end

endmodule
