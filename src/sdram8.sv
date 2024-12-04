//
// sdram8.sv
//
// sdram controller implementation
// Copyright (c) 2018 Sorgelig
//
// Based on sdram module by Till Harbaum
// 
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//
// adapted for TN20k internal 64mbit sdram 32 bit wide
// 2024 Stefan Voss

module sdram
(

	// interface to the MT48LC16M16 chip
	output            SDRAM_CLK,
	inout  reg [31:0] SDRAM_DQ,   // 16 bit bidirectional data bus
	output reg [10:0] SDRAM_A,    // 13 bit multiplexed address bus
	output      [3:0] SD_DQM,
	output reg  [1:0] SDRAM_BA,   // two banks
	output            SDRAM_nCS,  // a single chip select
	output reg        SDRAM_nWE,  // write enable
	output reg        SDRAM_nRAS, // row address select
	output reg        SDRAM_nCAS, // columns address select
	output            SDRAM_CKE,

	// cpu/chipset interface
	input             init,			// init signal after FPGA config to initialize RAM
	input             clk,			// sdram is accessed at up to 128MHz
	input             clkref,		// reference clock to sync to
	
	input       [7:0] din,			// data input from chipset/cpu
	output      [7:0] dout,			// data output to chipset/cpu
	input      [22:0] addr,       // 25 bit byte address
	input             oe,         // cpu/chipset requests read
	input             we         // cpu/chipset requests write
);

reg [1:0] bt;
assign SDRAM_CLK = clk;
assign SDRAM_CKE = 1;
assign SDRAM_nCS = 0;
assign SD_DQM = {bt} == 2'd0 ? 4'b0111:
                {bt} == 2'd1 ? 4'b1011:
                {bt} == 2'd2 ? 4'b1101:
                               4'b1110;

// no burst configured
localparam RASCAS_DELAY   = 3'd3;   // tRCD=20ns
localparam BURST_LENGTH   = 3'b000; // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd2;   // 2/3 allowed
localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
localparam NO_WRITE_BURST = 1'b1;   // 0= write burst enabled, 1=only single access write

localparam MODE = { 1'b0, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};

localparam STATE_IDLE  = 3'd0;   // first state in cycle
localparam STATE_START = 3'd1;   // state in which a new command can be started
localparam STATE_CONT  = STATE_START  + RASCAS_DELAY; // 4 command can be continued
localparam STATE_LAST  = 3'd7;   // last state in cycle

reg  [2:0] q;
reg [22:0] a;
reg        wr;
reg        ram_req=0;
reg [31:0] data;

// access manager
always @(posedge clk) begin
    reg old_rd, old_we, old_ref;

    old_ref<=clkref;

    if(q==STATE_IDLE) begin
        old_rd<=oe;
        old_we<=we;
        ram_req <= 0;
        wr <= 0;

        if((~old_rd & oe) | (~old_we & we)) begin
            ram_req <= 1;
            wr <= we;
            a <= addr;
        end
    end

    q <= q + 3'd1;
    if(old_ref ^ clkref) begin
        if (clkref) q <= 0;
        old_rd <= 0;
        old_we <= 0;
    end
end

localparam MODE_NORMAL = 2'b00;
localparam MODE_RESET  = 2'b01;
localparam MODE_LDM    = 2'b10;
localparam MODE_PRE    = 2'b11;

// initialization 
reg [1:0] mode;
reg [4:0] reset;

initial begin
	reset=5'h1f;
end

always @(posedge clk) begin
	reg init_old;
	init_old <= init;

	if(init_old & ~init) reset <= 5'h1f;
	else if(q == STATE_LAST) begin
		if(reset != 0) begin
			reset <= reset - 5'd1;
			if(reset == 14)     mode <= MODE_PRE;
			else if(reset == 3) mode <= MODE_LDM;
			else                mode <= MODE_RESET;
		end
		else mode <= MODE_NORMAL;
	end
end

localparam CMD_NOP             = 3'b111;
localparam CMD_ACTIVE          = 3'b011;
localparam CMD_READ            = 3'b101;
localparam CMD_WRITE           = 3'b100;
localparam CMD_BURST_TERMINATE = 3'b110;
localparam CMD_PRECHARGE       = 3'b010;
localparam CMD_AUTO_REFRESH    = 3'b001;
localparam CMD_LOAD_MODE       = 3'b000;

wire [7:0] ram_dout = {bt} == 2'd0 ? data[31:24]: 
                      {bt} == 2'd1 ? data[23:16]:
                      {bt} == 2'd2 ? data[15:8] :
                                     data[7:0];
assign dout = oe ? ram_dout : 8'hFF;

assign SDRAM_DQ = (ram_req == 1'b1 && wr == 1'b1 && mode == MODE_NORMAL && q == STATE_CONT) ? {din, din, din, din} : 32'bzzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz;

// SDRAM state machines
always @(posedge clk) begin
	if(q == STATE_START) SDRAM_BA <= (mode == MODE_NORMAL) ? a[20:19] : 2'b00;

	casex({ram_req,wr,mode,q})
		{2'b1X, MODE_NORMAL, STATE_START}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_ACTIVE;
		{2'b11, MODE_NORMAL, STATE_CONT }: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_WRITE;
		{2'b10, MODE_NORMAL, STATE_CONT }: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_READ;
		{2'b0X, MODE_NORMAL, STATE_START}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_AUTO_REFRESH;

		// init
		{2'bXX,    MODE_LDM, STATE_START}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_LOAD_MODE;
		{2'bXX,    MODE_PRE, STATE_START}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_PRECHARGE;

		                          default: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} <= CMD_NOP;
	endcase

	casex({ram_req,mode,q})
		{1'b1,  MODE_NORMAL, STATE_START}: {bt, SDRAM_A} <= {a[22:21],a[18:8]};
		{1'b1,  MODE_NORMAL, STATE_CONT }: SDRAM_A <= {3'b100, a[7:0]};
		// init
		{1'bX,     MODE_LDM, STATE_START}: SDRAM_A <= MODE;
		{1'bX,     MODE_PRE, STATE_START}: SDRAM_A <= 11'b10000000000;

		                          default: SDRAM_A <= 11'b00000000000;
	endcase

	if ((q == STATE_CONT+CAS_LATENCY+1) && (~wr & ram_req)) data <= SDRAM_DQ;
end


endmodule
