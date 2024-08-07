// A bridge controller connecting DDR3 to NES.
// nand2mario, 2022.10
// 
//
// This also uses ddr3_tester to verify that the DDR3 is initialized and read/write actually 
// works. If not, busy will stay 1 and fail_high/fail_low will be 1. The user can choose to 
// reset the controller to try initialization again. 
//
module MemoryController(
    input clk,                // Main logic clock (1/3 of pclk)
    input pclk,               // DDR3 controller clock 78 Mhz
    input fclk,               // DDR3 memory clock 315 Mhz
    input ck,                 // Phase-shifted fclk 315 90°
    input resetn,
    input read,               // Set to 1 to read from RAM
    input write,              // Set to 1 to write to RAM
    input refresh,            // Set to 1 to auto-refresh RAM
    input [21:0] addr,        // Address to read / write
    input [7:0] din,          // Data to write
    output reg [7:0] dout,  // Last read data a, available 2 cycles after read is set
    output reg busy,          // 1 while an operation is in progress
                              // staying 1 for more than 10ms means initialization or testing has failed
                              // if this happens, check: write_level_done, read_calib_done, fail_high, fail_low
    output write_level_done,  // write leveling status, this is 1st part of initialization
    output [7:0] wstep,
    output read_calib_done,   // read calibration status, this is 2nd half of initialization
    output [1:0] rclkpos,
    output [2:0] rclksel,
    output testing,
    output [3:0] test_state,
    output fail_high,         // error in higher byte r/w testing. 1 if initialization succeeds but r/w testing fails
    output fail_low,         

    // debug interface
    output reg [7:0] debug,
    output reg fail,          // FIXME: fail pin is currently not useful

    // Physical DDR3 interface
    inout  [15:0] DDR3_DQ,    // 16 bit bidirectional data bus
    inout  [1:0] DDR3_DQS,    // DQ strobe for high and low bytes
    output [13:0] DDR3_A,     // 14 bit multiplexed address bus
    output [2:0] DDR3_BA,     // 3 banks
    output DDR3_nCS,          // chip select
    output DDR3_nWE,          // write enable
    output DDR3_nRAS,         // row address select
    output DDR3_nCAS,         // columns address select
    output DDR3_CK,
    output DDR3_nRESET,
    output DDR3_CKE,
    output DDR3_ODT,
    output [1:0] DDR3_DM
);

localparam INIT = 2'd0;
localparam TEST = 2'd1;
localparam NORMAL = 2'd2;

reg [25:0] MemAddr;
reg [1:0] state;
reg MemRD, MemWR, MemRefresh;
reg [15:0] MemDin;
wire [15:0] MemDout;
reg [2:0] cycles;
reg r_read_a;
wire MemBusy, MemDataReady;
wire  tester_rd, tester_wr, tester_refresh;
wire [25:0] tester_addr;
wire [15:0] tester_din;

// DDR3 driver
ddr3_controller #(
    .ROW_WIDTH(13),
    .COL_WIDTH(10),
    .BANK_WIDTH(3)
) u_ddr3 (
    .pclk(pclk),
    .fclk(fclk),
    .ck(ck), 
    .resetn(resetn),
	.addr(testing ? tester_addr : MemAddr),
    .rd(testing ? tester_rd : MemRD),
    .wr(testing ? tester_wr : MemWR),
    .refresh(testing ? tester_refresh : MemRefresh),
	.din(testing ? tester_din : MemDin),
    .dout(MemDout),
    .dout128(),
    .data_ready(MemDataReady), // available 6 cycles after wr is set
    .busy(MemBusy), // = 1'b1,  // 0: ready for next command
    .write_level_done(write_level_done),
    .wstep(wstep),
    .read_calib_done(read_calib_done),
    .rclkpos(rclkpos),
    .rclksel(rclksel),
    .debug(),

    .DDR3_nRESET(DDR3_nRESET),
    .DDR3_DQ(DDR3_DQ),      // 16 bit bidirectional data bus
    .DDR3_DQS(DDR3_DQS),    // DQ strobes
    .DDR3_A(DDR3_A),        // 13 bit multiplexed address bus
    .DDR3_BA(DDR3_BA),      // two banks
    .DDR3_nCS(DDR3_nCS),    // a single chip select
    .DDR3_nWE(DDR3_nWE),    // write enable
    .DDR3_nRAS(DDR3_nRAS),  // row address select
    .DDR3_nCAS(DDR3_nCAS),  // columns address select
    .DDR3_CK(DDR3_CK),
    .DDR3_CKE(DDR3_CKE),
    .DDR3_ODT(DDR3_ODT),
    .DDR3_DM(DDR3_DM)
);

ddr3_tester u_tester (
    .clk(clk), 
    .resetn(resetn), 
    .start(~MemBusy), 
    .running(testing), 
    .state(test_state),
    .fail_high(fail_high), 
    .fail_low(fail_low),
    .rd(tester_rd), 
    .wr(tester_wr), 
    .refresh(tester_refresh),
    .addr(tester_addr), 
    .din(tester_din),
    .dout(MemDout), 
    .data_ready(MemDataReady), 
    .busy(MemBusy)
);

always @(posedge clk) begin
    MemWR <= 1'b0; 
    MemRD <= 1'b0; 
    MemRefresh <= 1'b0;
    cycles <= cycles == 3'd7 ? 3'd7 : cycles + 3'd1;
    
    // Initiate read or write
    if (!busy) begin
        if (read  || write || refresh) begin
            MemAddr <= {4'b0, addr};
            MemWR <= write;
            MemRD <= read;
            MemRefresh <= refresh;
            busy <= 1'b1;
            MemDin <= {din, din};
            cycles <= 3'd1;
            r_read_a <= read;
        end 
    end else if (state == INIT && ~MemBusy) begin
        // initialization is done, now test memory read/write
        state <= TEST;
    end else if (state == TEST && ~testing) begin
        state <= NORMAL;
        busy <= 1'b0;
    end else begin
        // Wait for operation to finish and latch incoming data on read.
        if (cycles == 3'd4) begin
            busy <= 0;
            if (r_read_a) begin
                if (~MemDataReady) // assert data ready
                    fail <= 1'b1;
                if (r_read_a) 
                    dout <= fail_low ? MemDout[15:8] : MemDout[7:0];
                debug <= MemDout[15:8] ^ MemDout[7:0]; // unused dout[] leads to compile errors
                r_read_a <= 1'b0;
            end
        end
    end

    if (~resetn) begin
        busy <= 1'b1;
        fail <= 1'b0;
        state <= INIT;
    end
end
endmodule
