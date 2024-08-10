set_device GW1NR-LV9QN88PC6/I5 -name GW1NR-9C

add_file src/dualshock2.v
add_file src/gowin_dpb/gowin_dpb_track_buffer_b.v
add_file src/gowin_dpb/gowin_dpb_trkbuf.v
add_file src/gowin_dpb/sector_dpram.v
add_file src/hdmi/audio_clock_regeneration_packet.sv
add_file src/hdmi/audio_info_frame.sv
add_file src/hdmi/audio_sample_packet.sv
add_file src/hdmi/auxiliary_video_information_info_frame.sv
add_file src/hdmi/hdmi.sv
add_file src/hdmi/packet_assembler.sv
add_file src/hdmi/packet_picker.sv
add_file src/hdmi/serializer.sv
add_file src/hdmi/source_product_description_info_frame.sv
add_file src/hdmi/tmds_channel.sv
add_file src/misc/flash_dspi.v
add_file src/misc/hid.v
add_file src/misc/mcu_spi.v
add_file src/misc/osd_u8g2.v
add_file src/misc/scandoubler.v
add_file src/misc/sd_card.v
add_file src/misc/sd_rw.v
add_file src/misc/sdcmd_ctrl.v
add_file src/misc/sysctrl.v
add_file src/misc/video.v
add_file src/misc/video_analyzer.v
add_file src/gowin_dpb/gowin_dpb_1k.vhd
add_file src/gowin_dpb/gowin_dpb_1k_x4.vhd
add_file src/gowin_dpb/gowin_dpb_2k.vhd
add_file src/gowin_dpb/gowin_dpb_8k.vhd
add_file src/gowin_prom/gowin_prom_basic.vhd
add_file src/gowin_prom/gowin_prom_char.vhd
add_file src/gowin_sdpb/gowin_sdpb_kernal_8k.vhd
add_file src/gowin_sp/gowin_sp_2k.vhd
add_file src/gowin_sp/gowin_sp_8k.vhd
add_file src/m6522.vhd
add_file src/m6561.vhd
add_file src/ram_conf_1024x4.vhd
add_file src/ram_conf_1024x8.vhd
add_file src/ram_conf_2048x8.vhd
add_file src/ram_conf_8192x8.vhd
add_file src/t65/T65.vhd
add_file src/t65/T65_ALU.vhd
add_file src/t65/T65_MCode.vhd
add_file src/t65/T65_Pack.vhd
add_file src/vic20_tn9k.vhd
add_file src/vic20_clocks.vhd
add_file src/vic20_keyboard.vhd
add_file src/vic20nano_top_tn9k.vhd
add_file src/vic20nano_top_tn9k.cst
add_file src/vic20nano_top_tn9k.sdc
add_file src/loader_sd_card.sv
add_file src/c1530.vhd
add_file src/fifo_sc_hs/fifo_sc_hs.vhd

set_option -synthesis_tool gowinsynthesis
set_option -output_base_name vic20nano_tn9k
set_option -verilog_std sysv2017
set_option -vhdl_std vhd2008
set_option -top_module VIC20_TOP
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
set_option -print_all_synthesis_warning 1
set_option -rw_check_on_ram 0
set_option -user_code 00000001
set_option -bit_security 0

#run syn
run all