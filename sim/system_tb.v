`timescale 1ns / 1ns
`include "cpu_2432.vh"

module system_tb() ;
  reg         clk, reset_b, clken;
  wire [31:0] gpio_w;
  integer     cycle;

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
    cycle = 0;
    #1005 reset_b = 1;
    #10000 ;
`ifdef RAM_DUMP_FILE_D
    $writememh(RAM_DUMP_FILE, dut_0.dram_0.ram);
`endif
    $finish;
  end

  always begin
    #50 clk = !clk;
    if (clk ) cycle = cycle+1;
  end

always @ ( posedge clk ) begin
  $display( "%10d: %04X : %06X : %d %d%d : %08X %d%d%d%d" , cycle,
            dut_0.cpu_0.o_iaddr,
            dut_0.cpu_0.i_instr,
            dut_0.cpu_0.p2_jump_taken_q,
            dut_0.cpu_0.p0_stage_valid_q,
            dut_0.cpu_0.p1_stage_valid_q,
            dut_0.cpu_0.p0_result_d,
            dut_0.cpu_0.psr_q[`C],
            dut_0.cpu_0.psr_q[`Z],
            dut_0.cpu_0.psr_q[`V],            
            dut_0.cpu_0.psr_q[`S],                        
            );
end



endmodule
