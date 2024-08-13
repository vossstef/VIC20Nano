`timescale 1ns/1ps
module psram_syn_top(
               clk,
               rst_n,
               O_psram_ck,
               O_psram_ck_n,
               IO_psram_rwds,
               O_psram_reset_n,
               IO_psram_dq,
               O_psram_cs_n,
               init_calib,
                error
               );

localparam  DQ_WIDTH = 32;
localparam  ADDR_WIDTH = 21;
localparam  CS_WIDTH = 4;

input                   clk;
input                   rst_n;

output[CS_WIDTH-1:0]    O_psram_ck;
output[CS_WIDTH-1:0]    O_psram_ck_n;
inout [CS_WIDTH-1:0]    IO_psram_rwds;
inout [DQ_WIDTH-1:0]    IO_psram_dq;
output[CS_WIDTH-1:0]    O_psram_reset_n;
output[CS_WIDTH-1:0]    O_psram_cs_n;

output                  error;

output                  init_calib;


wire [4*DQ_WIDTH-1:0]   wr_data/* synthesis syn_keep=1 */;
wire [4*DQ_WIDTH-1:0]   rd_data/* synthesis syn_keep=1 */;
wire                    cmd;
wire                    cmd_en;
wire [ADDR_WIDTH-1:0]   addr;
wire                    init_done;
wire [16-1:0]           data_mask;

wire                    memory_clk;
wire                    pll_lock;


PLL u_PLL
(
  .CLKIN    (clk),
  .CLKFB    (1'b0),
  .RESET    (~rst_n),
  .RESET_P  (1'b0),
  .RESET_I  (1'b0),
  .RESET_S  (1'b0),
  .FBDSEL   ({6{1'b0}}),
  .IDSEL    ({6{1'b0}}),
  .ODSEL    ({6{1'b0}}),
  .DUTYDA   ({4{1'b0}}),
  .PSDA     ({4{1'b0}}),
  .FDLY     (4'b0000),
  .CLKOUT   (memory_clk),
  .LOCK     (pll_lock),
  .CLKOUTP  (),
  .CLKOUTD  (),
  .CLKOUTD3 ()
);
defparam u_PLL.FCLKIN = "50.0";
defparam u_PLL.DYN_IDIV_SEL= "false";
defparam u_PLL.IDIV_SEL = 4;    //9
defparam u_PLL.DYN_FBDIV_SEL= "false";
defparam u_PLL.FBDIV_SEL = 11;  //32
defparam u_PLL.PSDA_SEL= "0000";
defparam u_PLL.DYN_DA_EN = "false";
defparam u_PLL.DYN_ODIV_SEL = "false";
defparam u_PLL.DUTYDA_SEL= "1000";
defparam u_PLL.CLKOUT_FT_DIR = 1'b1;
defparam u_PLL.CLKOUTP_FT_DIR = 1'b1;
defparam u_PLL.CLKFB_SEL = "internal";
defparam u_PLL.ODIV_SEL = 4;
defparam u_PLL.CLKOUT_BYPASS = "false";
defparam u_PLL.CLKOUTP_BYPASS = "false";
defparam u_PLL.CLKOUTD_BYPASS = "false";
defparam u_PLL.DYN_SDIV_SEL = 2;
defparam u_PLL.CLKOUTD_SRC = "CLKOUT";
defparam u_PLL.CLKOUTD3_SRC = "CLKOUT";
defparam u_PLL.DEVICE = "GW1NR-9";


PSRAM_Memory_Interface_HS_Top u_psram_top(
                      .clk(clk),
                      .memory_clk (memory_clk),
                      .pll_lock(pll_lock),
                      .rst_n(rst_n),  //rst_n
                      .O_psram_ck(O_psram_ck),
                      .O_psram_ck_n(O_psram_ck_n),
                      .IO_psram_rwds(IO_psram_rwds),
                      .IO_psram_dq(IO_psram_dq),
                      .O_psram_reset_n(O_psram_reset_n),
                      .O_psram_cs_n(O_psram_cs_n),
                      .wr_data(wr_data),
                      .rd_data(rd_data),
                      .rd_data_valid(rd_data_valid),
                      .addr(addr),
                      .cmd(cmd),
                      .cmd_en(cmd_en),
                      .clk_out(clk_x1),
                      .data_mask(data_mask),
                      .init_calib(init_calib)
                     );
psram_test u_test(
                  .clk(clk_x1),
                  .rst_n(rst_n), //rst_n
                  .init_done(init_calib),
                  .cmd(cmd),
                  .cmd_en(cmd_en),
                  .addr(addr),
                  .wr_data(wr_data),
                  .data_mask(data_mask),
                  .rd_data(rd_data),
                  .rd_data_valid(rd_data_valid),
                  .error(error)
                  );

endmodule
