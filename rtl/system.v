
module system(
              input         i_clk,
              input         i_clk_en,
              input         i_rstb,
              inout [31:0]  io_gpio
              );

  wire [23:0]               instr_w;
  wire [23:0]               iaddr_w;
  wire [23:0]               cpu_daddr_w;
  wire                      ram_rd_w;
  wire [3:0]                ram_wr_w;
  wire [31:0]               ram_dout_w, cpu_din_w;
  wire [31:0]               cpu_dout_w;
  wire [3:0]                gpio0_irq_w;
  wire [31:0]               gpio_dout_w;
  
  // GPIO/RAM multiplexer
  assign cpu_din_w = ( cpu_daddr_w[23]) ? gpio_dout_w:
                     ram_dout_w;
  
  cpu_2432  cpu_0 (
                   .i_instr(instr_w),
                   .i_clk(i_clk),
                   .i_clk_en(i_clk_en),
                   .i_rstb(i_rstb),
                   .i_din(cpu_din_w),
                   .o_iaddr(iaddr_w),
                   .o_daddr(cpu_daddr_w),
                   .o_dout(cpu_dout_w),
                   .o_ram_rd(ram_rd_w),
                   .o_ram_wr(ram_wr_w)
                   );


   gpio gpio_0 (
                .i_clk(i_clk),
                .i_rstb(i_rstb),
                .i_addr(cpu_daddr_w[2:0]),
                .i_din(ram_dout_w),
                .i_wr_en(ram_wr_w),
                .o_dout(gpio_dout_w),
                .io_gpio(io_gpio),
                .o_irq(gpio0_irq_w)
                );

  rom_8192x24 irom_0 (
                      .dout(instr_w),
                      .address(iaddr_w[12:0]),
                      .clk(i_clk),
                      .cs_b(1'b0)
                      );

  // CPU_2432 uses Byte addressing, so use only word addresses (ignore 2 lsbs)
  // for a 32b wide RAM and control byte writes via the cs_b bits
  ram_8192x32 dram_0 (
                      .din(cpu_dout_w),
                      .dout(ram_dout_w),
                      .address(cpu_daddr_w[14:2]),
                      .rnw(! (|ram_wr_w) ),
                      .clk(i_clk),
                      .cs_b( {! (ram_wr_w[3] | ram_rd_w),
                              ! (ram_wr_w[2] | ram_rd_w),
                              ! (ram_wr_w[1] | ram_rd_w),
                              ! (ram_wr_w[0] | ram_rd_w)}
                             )
                      );

endmodule // system
