// Implementation of the MegaCart for VIC20 FPGA
// Copyright (c) 2021 by Alastair M. Robinson
// 
// Modified for MiSTer (c) 2022 Alexey Melnikov
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

module megacart
(
	input         clk,
	input         reset_n,

	input  [15:0] vic_addr,
	input         vic_wr_n,
	input         vic_io2_sel,
	input         vic_io3_sel,
	input         vic_blk123_sel,
	input         vic_blk5_sel,
	input         vic_ram123_sel,
	input   [7:0] vic_data,

	output [22:0] mc_addr,
	output        mc_wr_n,
	output        mc_nvram_sel,
	output reg    mc_soft_reset
);

// The MegaCart consists of a 2 megabyte ROM which is split into a high and low half.
// Each half is split into 8k banks.
// Any bank from the low half can be mapped to 0x2000 - 0x7fff, repeated three times.
// A bank from the high or low half can be mapped to 0xa000 - 0xbfff

// Need to be able to write-block RAM at 0x2000

// The cart also contains 32k RAM which can be mapped to 0x2000 or 0xa000
// Need to be able to override the core's RAM settings.

// There is also 8k of NVRAM which is mapped to
// 0x400 - 0xfff (3k) and 0x9800 - 0x9fff (2K) - so 3k is unmapped

// There are control registers at
// 0x9c80 - bank_high_reg

// 0x9d00 - bank_low_reg

// 0x9d80 - lsb -> nvram_en  (but incompletely decoded, so value to both bank regs, too)

// 0x9e00 - reset

// From the VIC20 core we already have external DRAM mapped for 0x400 - 0xfff,
// 0x2000-0x7fff and 0xa000-0xbfff, and it's easy to add selects for IO space.


// Perhaps implement this as a wedge between the VIC and SDRAM, for easy bypassing?


// Incoming signals wanted:
// vic_sel_ram123  -  Accessing RAM at 0x400 - 0xfff
// vic_sel_blk123  -  Accessing RAM or ROM from 0x2000 - 0x7fff
// vic_sel_blk5  -  Access RAM or ROM at 0xa000 - 0xbfff
// vic_sel_io2  -  IO space (+NVRAM)
// vic_sel_io3  -  IO space (+NVRAM)

// From these signals we must create
// sel_nvram -> bank 10 (assuming we can put NVRAM in SDRAM)
// sel_megacart -> bank 01
// if neither is asserted, then regular RAM access -> bank 00

// If we don't do any address mangling, nvram will be mapped like so:
// 0x0000 -> 0x03ff : not accessible;
// 0x0400 -> 0x0fff : bank 2, 0x400 - 0xfff
// 0x1000 -> 0x17ff : not accessible
// 0x1800 -> 0x1fff : bank 2, 0x9800 -> 09fff
// We can unmangle this when loading and saving NVRAM

reg       bank_ena;
reg [7:0] bank_high;
reg [7:0] bank_low;
reg       nvram_ena_l;

// The effective bank is 0x7f on reset, or controlled by bank_high/low once
// a soft reset has executed and toggled the ena flag.
wire [6:0] eff_bank_low  = bank_ena ? bank_low[6:0]  : 7'h7f;
wire [6:0] eff_bank_high = bank_ena ? bank_high[6:0] : 7'h7f;
wire       ram_low_ena   = bank_ena & bank_low[7];
wire       ram_high_ena  = bank_ena & bank_high[7];
wire       ram_wp_n      = bank_high[6];

// High ROM can be mapped to blk5 (0xa000-0xbfff)
wire   rom_high_sel = reset_n & (!ram_high_ena & vic_blk5_sel);
// Low ROM can be mapped to blk123 (0x2000-0x7fff) or blk5 (0xa000-0xbfff)
wire   rom_low_sel  = reset_n & !ram_low_ena & (vic_blk5_sel | vic_blk123_sel); 

// RAM is selected any time blk123 or 5 is selected and both ram_low_ena and ram_high_ena are high - or when ram123 is selected.
wire   mc_ram_sel   = ram_low_ena & ram_high_ena & (vic_blk123_sel | vic_blk5_sel);

// NVRAM is selected in io2/3 + ram123 blocks if nvram_ena_l is low
assign mc_nvram_sel = reset_n & (vic_ram123_sel | vic_io2_sel | vic_io3_sel);

// Output modified write signal.
// If ram_wp is low we block writes to RAM
// but still let through writes to NVRAM if nvram is enabled.
wire   mc_wr_en     = (mc_ram_sel & ram_wp_n) | (!nvram_ena_l & mc_nvram_sel);
assign mc_wr_n      = ~reset_n | vic_wr_n | ~mc_wr_en;
					
// Address mapping:
assign mc_addr      = rom_high_sel ? {3'b001, eff_bank_high, vic_addr[12:0]}:
					       rom_low_sel  ? {3'b000, eff_bank_low,  vic_addr[12:0]}:
												 {3'b100, 4'b0000,       vic_addr[15:0]}; // Cart RAM

// IO3, 0x9c00 -> 0x9fff
// (If nvram is enabled, writes here also go to nvram)
always @(posedge clk) begin
	mc_soft_reset <= 0;
	if(!reset_n) begin
		nvram_ena_l<= 0;
		bank_ena   <= 0;
	end
	else begin
		if(vic_io3_sel & ~vic_wr_n) begin
			if(vic_addr[7]) bank_high <= vic_data;
			if(vic_addr[8]) bank_low <= vic_data;
			if(vic_addr[8] & vic_addr[7]) nvram_ena_l <= vic_data[0];
			if(vic_addr[9]) begin
				mc_soft_reset <= 1;
				bank_ena <= ~bank_ena;
			end
		end
	end
end

endmodule
