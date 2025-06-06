create_clock -name m0s[3] -period 50.0 -waveform {0 5} [get_ports {m0s[3]}] -add
create_clock -name flash_clk -period 15.625 -waveform {0 5} [get_nets {flash_clk}]
create_clock -name clk32 -period 27.955 -waveform {0 5} [get_nets {clk32}]
create_clock -name clk64 -period 13.976 -waveform {0 5} [get_nets {clk64}]
create_clock -name clk_27mhz -period 37.037 -waveform {0 5} [get_ports {clk_27mhz}]
//create_clock -name clk_audio -period 20833.332 -waveform {0 5} [get_nets {video_inst/clk_audio}] -add
create_clock -name mspi_clk -period 15.625 -waveform {0 5} [get_ports {mspi_clk}] -add
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
set_clock_groups -asynchronous -group [get_clocks {flash_clk}] 
//                               -group [get_clocks {clk_audio}] 
//                               -group [get_clocks {clk_spi}] 
                               -group [get_clocks {m0s[3]}] 
                               -group [get_clocks {clk64}] 
                               -group [get_clocks {clk32}] 
