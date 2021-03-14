
`timescale 1ns / 1ns
`include "cpu_2432.vh"

module system_tb() ;
  reg         clk, reset_b, clken;
  wire [31:0] gpio_w;
  integer     cycle;
  integer     instr_count;
    

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
    instr_count = 0;    
    { clk, reset_b}  = 0;
    clken = 1'b1;
    cycle = 0;
    #3005 reset_b = 1;
    #500000000 ;
`ifdef RAM_DUMP_FILE_D
    $writememh(RAM_DUMP_FILE, dut_0.dram_0.ram);
`endif
    $finish;
  end

  always @ ( negedge clk ) begin
    if ( dut_0.cpu_0.p1_stage_valid_d )
      instr_count = instr_count+1;       
    if (dut_0.cpu_daddr_w == 24'hFFFFFF &&
        dut_0.ram_wr_w == 1'b1) begin
      $display("Simulation terminated at time", $time); 
      $display("Executed %d instructions ", instr_count); 
     
`ifdef RAM_DUMP_FILE_D
    $writememh(RAM_DUMP_FILE, dut_0.dram_0.ram);
`endif      
      $finish;
    end
  end
  
  
  always begin
    #500 clk = !clk;
    if (clk ) cycle = cycle+1;
  end

always @ ( negedge clk ) begin
  $display( "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ");
`ifdef TWO_STAGE_PIPE
  $display( "P0: %10d: %02X : %08X : %d : %d " , cycle,
            dut_0.cpu_0.p0_pc_q,
            dut_0.cpu_0.raw_instr_w,
            dut_0.cpu_0.rstb_q,      
            dut_0.cpu_0.p0_moe_q );
`else  
  $display( "P0: %10d: %02X : %08X : %d : %d %d " , cycle,
            dut_0.cpu_0.p0_pc_q,
            dut_0.cpu_0.p0_instr_q,
            dut_0.cpu_0.rstb_q,      
            dut_0.cpu_0.p0_moe_q,
            dut_0.cpu_0.p0_stage_valid_q );
`endif
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

  $display("p0_pc_d=%08x p0_pc_q=%08x p2_jump_taken_d=%d",
            dut_0.cpu_0.p0_pc_d,           
            dut_0.cpu_0.p0_pc_q,
           dut_0.cpu_0.p2_jump_taken_d           
);
  
           
end



endmodule
