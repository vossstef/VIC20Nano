//Copyright (C)2014-2020 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.7 Beta
//Created Time: 2020-09-25 14:14:49
create_clock -name clk_x1 -period 12.5 -waveform {0 6.25} [get_nets {clk_x1}]
create_clock -name clk_x2 -period 6.25 -waveform {0 3.125} [get_nets {memory_clk}]
set_clock_groups -exclusive -group [get_clocks {clk_x1 clk_x2}]
set_false_path -from [get_clocks {clk_x1}] -to [get_clocks {clk_x2}] 
