//  Megacart NVRAM interface
//
//  Copyright (c) 2021 by Alastair M. Robinson
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//
// The NVRAM is nominally 8k, but not all 8k is accessible.
// 0x0000 -> 0x03ff : 1k - not accessible;
// 0x0400 -> 0x0fff : 3k - VIC Expansion memory, mapped directly.
// 0x1000 -> 0x17ff : 2k - not accessible
// 0x1800 -> 0x1fff : 2k - Mapped to IO2/IO3 space (0x9800 - 0x9ffff)

// To avoid wasting BRAM, implement as 2 chunks of 2k each, and one chunk of 1k.
// sel_io23 = a[11] & a[12]; // high 2k @ 0x1800
// sel_e1 = a[11] & ~a[12]; // upper 2k of 3k expansion @ 0x800
// sel_e2 = a[10] & ~a[11] & ~a[12]; // first 1k of 3k expansion @ 0x400

// Two RAM ports will be needed - one for the VIC20 to access, the other connects to user_io.
// The user_io interface will be multiplexed between the 1541 emulation and the NVRAM, so
// we'll make an effort not to activate the NVRAM loading or saving process while the
// disk drive is active.  We'll use the led_disk signal (which has been modified
// to incorporate the internal sd_busy signal) for this.

// We'll receive a momentary pulse on img_mounted[1] when the NVRAM is mounted.
// We need to respond to this by reading the blocks in turn.  
// FIXME - We should hold the VIC in reset while doing this.
// (Though we could avoid this if the RAM is disabled while loading.)

// Saving the NVRAM is triggered by a status bit.  Upon receipt of the save trigger
// we must write each block.  
// FIXME - We don't want to reset the VIC while doing this, but can we pause it?


module megacart_nvram
(
	// Port A
	input clk_a,
	input [12:0] a_a,
	input [7:0] d_a,
	output [7:0] q_a,
	input we_a,

	// Port B
	input clk_b,
	input reset_n,
	input readnv, // Momentary high pulse
	input writenv, // "Momentary" high pulse
	input uio_busy, // Is the disk drive using the UIO interface?
	output reg nvram_sel, // Own the UIO interface
	output [31:0] sd_lba,
	output reg sd_rd,
	output reg sd_wr,
	input sd_ack,
	output [7:0] sd_buff_din,
	input [7:0] sd_buff_dout,
	input sd_buff_wr,
	input [8:0] sd_buff_addr,
	input [31:0] img_size
);

localparam IDLE=1'b0;
localparam ACTIVE=1'b1;
reg state;
reg img_present;
reg [3:0] lba;
assign sd_lba = {28'b0,lba};
reg sd_ack_d;

// UIO arbitration
reg pending;
reg sd_write;
reg rd_d,wr_d;

always @(posedge clk_b,negedge reset_n) begin
	if(!reset_n) begin
		img_present<=1'b0;
		nvram_sel<=1'b0;
		rd_d<=1'b0;
		wr_d<=1'b0;
		pending<=1'b0;
		state<=IDLE;
	end else begin

		sd_ack_d<=sd_ack;
		rd_d<=readnv;
		wr_d<=writenv;

		if(~sd_ack_d && sd_ack) begin // Remove request on rising edge of ack.
			sd_rd<=1'b0;
			sd_wr<=1'b0;
		end

		case(state)

			IDLE: begin

				if(pending && !uio_busy) begin
					pending<=1'b0;
					nvram_sel<=1'b1;
					lba<=0;
					sd_rd<=!sd_write;
					sd_wr<=sd_write;
					state<=ACTIVE;
				end

				if(rd_d && !readnv) begin
					pending<=|img_size;
					img_present<=|img_size;
					sd_write<=1'b0;
				end

				if(wr_d && !writenv && img_present) begin
					sd_write<=1'b1;
					pending<=1'b1;
				end
			end

			ACTIVE: begin
				if(sd_ack_d & ~sd_ack) begin // Falling edge of request signal
					if(&lba) begin // Last sector?
						nvram_sel<=1'b0; // Release the UIO interface
						// Trigger a reset at this point
						state <= IDLE;
					end else begin
						lba <= lba + 1'd1;
						sd_rd<=!sd_write;
						sd_wr<=sd_write;
					end
				end
			end
			
		endcase
	end
end

wire [12:0] a_b = {lba,sd_buff_addr};
wire [7:0] d_b = sd_buff_dout;
wire [7:0] q_b;
assign sd_buff_din = q_b;
wire we_b = sd_buff_wr & sd_ack;


// Three individual dual-port RAMs, 5k in total, to avoid wasting BRAM.

// A 2K block @ 0x1800
reg [7:0] blk_io23[2048];
// A 2K block @ 0x0800
reg [7:0] blk_e1[2048];
// A 1K block @ 0x0400
reg [7:0] blk_e2[1024];


// Port A - interface to VIC

wire sel_io23_a = a_a[11] & a_a[12]; // high 2k @ 0x1800
wire sel_e1_a = a_a[11] & ~a_a[12]; // upper 2k of 3k expansion @ 0x800
wire sel_e2_a = a_a[10] & ~a_a[11] & ~a_a[12]; // first 1k of 3k expansion @ 0x400
reg [7:0] q_io23_a;
reg [7:0] q_e1_a;
reg [7:0] q_e2_a;

// Port B - interface to Host

wire sel_io23_b = a_b[11] & a_b[12]; // high 2k @ 0x1800
wire sel_e1_b = a_b[11] & ~a_b[12]; // upper 2k of 3k expansion @ 0x800
wire sel_e2_b = a_b[10] & ~a_b[11] & ~a_b[12]; // first 1k of 3k expansion @ 0x400
reg [7:0] q_io23_b;
reg [7:0] q_e1_b;
reg [7:0] q_e2_b;

// blk_io23

always @(posedge clk_a) begin
	if(sel_io23_a) begin
		if(we_a)	blk_io23[a_a]<=d_a;
	end
	q_io23_a<=blk_io23[a_a];
end

always @(posedge clk_b) begin
	if(sel_io23_b) begin
		if(we_b)	blk_io23[a_b]<=d_b;
	end
	q_io23_b<=blk_io23[a_b];
end

// blk e1

always @(posedge clk_a) begin
	if(sel_e1_a) begin
		if(we_a)	blk_e1[a_a]<=d_a;
	end
	q_e1_a<=blk_e1[a_a];
end

always @(posedge clk_b) begin
	if(sel_e1_b) begin
		if(we_b)	blk_e1[a_b]<=d_b;
	end
	q_e1_b<=blk_e1[a_b];
end

// blk e2

always @(posedge clk_a) begin
	if(sel_e2_a) begin
		if(we_a)	blk_e2[a_a]<=d_a;
	end
	q_e2_a<=blk_e2[a_a];
end

always @(posedge clk_b) begin
	if(sel_e2_b) begin
		if(we_b)	blk_e2[a_b]<=d_b;
	end
	q_e2_b<=blk_e2[a_b];
end

// Output muxes

assign q_a = sel_io23_a ? q_io23_a : (sel_e1_a ? q_e1_a : q_e2_a);
assign q_b = sel_io23_b ? q_io23_b : (sel_e1_b ? q_e1_b: q_e2_b);

endmodule
