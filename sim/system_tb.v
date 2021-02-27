
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
    #105 reset_b = 1;
    #500000 ;
`ifdef RAM_DUMP_FILE_D
    $writememh(RAM_DUMP_FILE, dut_0.dram_0.ram);
`endif
    $finish;
  end

  always begin
    #10 clk = !clk;
    if (clk ) cycle = cycle+1;
  end

always @ ( posedge clk ) begin
  $display( "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ");  
  $display( "P0: %10d: %02X : %02X : %d : %X %X %X %08X : %X : %d %d %d" , cycle,
            dut_0.cpu_0.p0_pc_q,
            dut_0.cpu_0.p0_opcode_q,
            dut_0.cpu_0.p0_ead_use_imm_q,
            dut_0.cpu_0.p0_rdest_q,
            dut_0.cpu_0.p0_rsrc0_q,
            dut_0.cpu_0.p0_rsrc1_q,
            dut_0.cpu_0.p0_imm_q,
            dut_0.cpu_0.p0_cond_q,
            dut_0.cpu_0.rstb_q,      
            dut_0.cpu_0.p0_moe_q,
            dut_0.cpu_0.p0_stage_valid_q );

  $display( "P1: %10d: %02X : %02X : - : %X %X %X -------- : %X : - - %d " , cycle,
            dut_0.cpu_0.p1_pc_q,
            dut_0.cpu_0.p1_opcode_q,
            dut_0.cpu_0.p1_rdest_q,
            dut_0.cpu_0.p1_rsrc0_q,
            dut_0.cpu_0.p1_rsrc1_q,
            dut_0.cpu_0.p1_cond_q,
            dut_0.cpu_0.p1_stage_valid_q );

  $display("FLAGS C=%d Z=%d V=%d S=%d",
           dut_0.cpu_0.psr_q[`C],
           dut_0.cpu_0.psr_q[`Z],
           dut_0.cpu_0.psr_q[`V],
           dut_0.cpu_0.psr_q[`S]);
           
  
  $display("RF R0 =%08X R1 =%08X R2 =%08X R3 =%08X R4 =%08X R5 =%08X R6 =%08X R7 =%08X",
           dut_0.cpu_0.u0.rf_q[0],
           dut_0.cpu_0.u0.rf_q[1],
           dut_0.cpu_0.u0.rf_q[2],
           dut_0.cpu_0.u0.rf_q[3],
           dut_0.cpu_0.u0.rf_q[4],
           dut_0.cpu_0.u0.rf_q[5],
           dut_0.cpu_0.u0.rf_q[6],
           dut_0.cpu_0.u0.rf_q[7]);
  
  $display("RF R8 =%08X R9 =%08X R10=%08X R11=%08X R12=%08X R13=%08X R14=%08X R15=%08X",
           dut_0.cpu_0.u0.rf_q[8],
           dut_0.cpu_0.u0.rf_q[9],
           dut_0.cpu_0.u0.rf_q[10],
           dut_0.cpu_0.u0.rf_q[11],
           dut_0.cpu_0.u0.rf_q[12],
           dut_0.cpu_0.u0.rf_q[13],
           dut_0.cpu_0.u0.rf_q[14],
           dut_0.cpu_0.u0.rf_q[15]);
  
end



endmodule
