//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.03 (64-bit) 
//Created Time: 2025-01-30 22:25:56
create_clock -name clk32 -period 31.746 -waveform {0 15} [get_nets {clk32}]
create_clock -name clk_pixel_x10 -period 2.801 -waveform {0 1.4} [get_nets {clk_pixel_x10}]
create_clock -name clk_x4 -period 11.181 -waveform {0 5} [get_nets {clk_x4}]
create_clock -name clk_27mhz -period 37.037 -waveform {0 17} [get_ports {clk_27mhz}]
create_clock -name flash_clk -period 10 -waveform {0 5} [get_nets {flash_clk}]
create_clock -name clk64 -period 15.873 -waveform {0 5} [get_nets {clk64}]
create_clock -name mspi_clk -period 10 -waveform {0 5} [get_ports {mspi_clk}] -add
create_clock -name ds_clk -period 8000 -waveform {0 4000} [get_nets {gamepad_p1/clk_spi}] -add
create_clock -name clk_audio -period 20833.332 -waveform {0 5} [get_nets {video_inst/clk_audio}] -add
create_clock -name clk_pixel_x5 -period 6.349 -waveform {0 3.25} [get_nets {clk_pixel_x5}] -add
create_clock -name m0s -period 50 -waveform {0 25} [get_ports {m0s[3]}] -add
create_clock -name ds2_clk -period 8000 -waveform {0 4000} [get_nets {gamepad_p2/clk_spi}] -add
set_clock_groups -asynchronous -group [get_clocks {clk_pixel_x10}] -group [get_clocks {flash_clk}]
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
