`define GPIO_MODE_REG 3'b000
`define GPIO_DATA_REG 3'b001

module gpio (
             input         i_clk,
             input         i_rstb,
             input [2:0]   i_addr,
             input [31:0]  i_din,
             input         i_wr_en,
             output [31:0] o_dout,
             inout [31:0]  io_gpio,
             output [3:0]  o_irq
             );


  reg [31:0]               gpio_mode_d, gpio_mode_q;
  reg [31:0]               gpio_dout_d, gpio_dout_q;
  reg [31:0]               gpio_din_d,  gpio_din_q;
  reg [31:0]               gpio_din2_d, gpio_din2_q;
  reg [31:0]               io_gpio_r;

  integer                  i;

  assign o_dout = gpio_din2_q;
  assign o_irq  = 4'b0;
  assign io_gpio = io_gpio_r;

  always @ ( * ) begin
    io_gpio_r = 32'bz;
    for (i=0; i<32; i= i+1)
      io_gpio_r[i] = (gpio_mode_q[i]) ? gpio_dout_q[i] : 1'bz;
  end

  always @ (*) begin
    gpio_din_d = io_gpio_r;
    gpio_din2_d = gpio_din_q;
    gpio_mode_d = gpio_mode_q;
    gpio_dout_d = gpio_dout_q;

    if ( i_addr == `GPIO_MODE_REG ) begin
      gpio_mode_d = (i_wr_en) ? i_din : gpio_mode_q;
    end
    else if (i_addr == `GPIO_DATA_REG ) begin
      gpio_dout_d = (i_wr_en) ? i_din : gpio_dout_q;
    end
  end

  always @ ( posedge i_clk or negedge i_rstb )
    if ( !i_rstb ) begin
      gpio_mode_q = 31'b0;
      gpio_dout_q = 31'b0;
      gpio_din_q  = 31'b0;
      gpio_din2_q = 31'b0;
    end
    else begin
      gpio_mode_q = gpio_mode_d;
      gpio_dout_q = gpio_dout_d;
      gpio_din_q = gpio_din_d;
      gpio_din2_q = gpio_din2_d;
    end

endmodule // gpio
