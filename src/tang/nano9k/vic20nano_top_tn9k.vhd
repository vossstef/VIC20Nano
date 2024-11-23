-------------------------------------------------------------------------
--  VIC20 Top level for Tang Nano 9k
--  2024 Stefan Voss
--  based on the work of many others
--
-------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.ALL;

entity VIC20_TOP is
  port
  (
    clk_27mhz   : in std_logic;
    reset       : in std_logic; -- S2 button
    user        : in std_logic; -- S1 button
    leds_n      : out std_logic_vector(5 downto 0);
    io          : in std_logic_vector(4 downto 0);
    -- USB-C BL616 UART
    uart_rx     : in std_logic;
    uart_tx     : out std_logic;
    -- SPI interface Sipeed M0S Dock external BL616 uC
    m0s         : inout std_logic_vector(4 downto 0);
    --
    tmds_clk_n  : out std_logic;
    tmds_clk_p  : out std_logic;
    tmds_d_n    : out std_logic_vector( 2 downto 0);
    tmds_d_p    : out std_logic_vector( 2 downto 0);
    -- sd interface
    sd_clk      : out std_logic;
    sd_cmd      : inout std_logic;
    sd_dat      : inout std_logic_vector(3 downto 0);

    -- Gamepad Dualshock P1
    ds_clk          : out std_logic;
    ds_mosi         : out std_logic;
    ds_miso         : in std_logic; -- midi_out
    ds_cs           : out std_logic; -- midi_in
    -- spi flash interface
    mspi_cs       : out std_logic;
    mspi_clk      : out std_logic;
    mspi_di       : inout std_logic;
    mspi_do       : inout std_logic;
    -- Magic ports for PSRAM to be inferred
    -- Gowin interface is for 2 dies.
    O_psram_ck    : out std_logic_vector( 1 downto 0);
    O_psram_ck_n  : out std_logic_vector( 1 downto 0);
    IO_psram_rwds : inout std_logic_vector( 1 downto 0);
    IO_psram_dq   : inout std_logic_vector( 15 downto 0);
    O_psram_reset_n : out std_logic_vector( 1 downto 0);
    O_psram_cs_n  : out std_logic_vector( 1 downto 0)
    );
end;

architecture Behavioral_top of VIC20_TOP is

signal clk64          : std_logic;
signal clk64_90       : std_logic;
signal clk32          : std_logic;
signal pll_locked     : std_logic;
signal clk_pixel_x10  : std_logic;
signal clk_pixel_x10_90 : std_logic;
signal clk_pixel_x5   : std_logic;
signal mspi_clk_x5    : std_logic;
attribute syn_keep : integer;
attribute syn_keep of clk64         : signal is 1;
attribute syn_keep of clk32         : signal is 1;
attribute syn_keep of clk_pixel_x10 : signal is 1;
attribute syn_keep of clk_pixel_x5  : signal is 1;
attribute syn_keep of mspi_clk_x5   : signal is 1;

signal audio_data_l  : std_logic_vector(17 downto 0);
signal audio_data_r  : std_logic_vector(17 downto 0);

-- external memory
signal c64_addr     : unsigned(15 downto 0);
signal c64_data_out : unsigned(7 downto 0);
signal sdram_data   : unsigned(7 downto 0);
signal dout         : std_logic_vector(7 downto 0);
signal dout16       : std_logic_vector(15 downto 0);
--signal idle         : std_logic;
signal dram_addr    : std_logic_vector(22 downto 0);
signal ram_ready    : std_logic;
signal cb_D         : std_logic;
--signal addr         : std_logic_vector(22 downto 0);
signal cs           : std_logic;
signal we           : std_logic;
signal din          : std_logic_vector(7 downto 0);
signal ds           : std_logic_vector(1 downto 0);

-- IEC
signal iec_data_o  : std_logic;
signal iec_data_i  : std_logic;
signal iec_clk_o   : std_logic;
signal iec_clk_i   : std_logic;
signal iec_atn_o   : std_logic;
signal iec_atn_i   : std_logic;

  -- keyboard
signal keyboard_matrix_out : std_logic_vector(7 downto 0);
signal keyboard_matrix_in  : std_logic_vector(7 downto 0);
signal joyUsb1      : std_logic_vector(6 downto 0);
signal joyUsb2      : std_logic_vector(6 downto 0);
signal joyUsb1A     : std_logic_vector(6 downto 0);
signal joyUsb2A     : std_logic_vector(6 downto 0);
signal joyDigital   : std_logic_vector(6 downto 0);
signal joyNumpad    : std_logic_vector(6 downto 0);
signal joyMouse     : std_logic_vector(6 downto 0);
signal joyDS2A_p1   : std_logic_vector(6 downto 0); 
signal numpad       : std_logic_vector(7 downto 0);
signal joyDS2_p1    : std_logic_vector(6 downto 0);
-- joystick interface
signal joyA        : std_logic_vector(6 downto 0);
signal port_1_sel  : std_logic_vector(3 downto 0);
-- mouse / paddle
signal pot1        : std_logic_vector(7 downto 0);
signal pot2        : std_logic_vector(7 downto 0);
signal mouse_x_pos : signed(10 downto 0);
signal mouse_y_pos : signed(10 downto 0);

signal ram_ce      :  std_logic;
signal ram_we      :  std_logic;
signal romCE       :  std_logic;

signal ntscMode    :  std_logic;
signal hsync       :  std_logic;
signal vsync       :  std_logic;
signal r           :  unsigned(7 downto 0);
signal g           :  unsigned(7 downto 0);
signal b           :  unsigned(7 downto 0);

signal pb_out      : std_logic_vector(7 downto 0);
signal pc2_n       : std_logic;
signal pb_in       : std_logic_vector(7 downto 0);
signal flag2_n     : std_logic;

-- BL616 interfaces
signal mcu_start      : std_logic;
signal mcu_sys_strobe : std_logic;
signal mcu_hid_strobe : std_logic;
signal mcu_osd_strobe : std_logic;
signal mcu_sdc_strobe : std_logic;
signal data_in_start  : std_logic;
signal mcu_data_out   : std_logic_vector(7 downto 0);
signal hid_data_out   : std_logic_vector(7 downto 0);
signal osd_data_out   : std_logic_vector(7 downto 0) :=  X"55";
signal sys_data_out   : std_logic_vector(7 downto 0);
signal sdc_data_out   : std_logic_vector(7 downto 0);
signal hid_int        : std_logic;
signal system_scanlines : std_logic_vector(1 downto 0);
signal system_volume  : std_logic_vector(1 downto 0);
signal joystick1       : std_logic_vector(7 downto 0);
signal joystick2       : std_logic_vector(7 downto 0);
signal mouse_btns     : std_logic_vector(1 downto 0);
signal mouse_x        : signed(7 downto 0);
signal mouse_y        : signed(7 downto 0);
signal mouse_strobe   : std_logic;
signal freeze         : std_logic;
signal freeze_sync    : std_logic;
signal c64_pause      : std_logic;
signal old_sync       : std_logic;
signal osd_status     : std_logic;
signal ws2812_color   : std_logic_vector(23 downto 0);
signal system_reset   : std_logic_vector(1 downto 0);
signal disk_reset     : std_logic;
signal disk_chg_trg   : std_logic;
signal disk_chg_trg_d : std_logic;
signal sd_img_size    : std_logic_vector(31 downto 0);
signal sd_img_size_d  : std_logic_vector(31 downto 0);
signal sd_img_mounted : std_logic_vector(4 downto 0);
signal sd_img_mounted_d : std_logic;
signal sd_rd          : std_logic_vector(4 downto 0);
signal sd_wr          : std_logic_vector(4 downto 0);
signal sd_lba         : std_logic_vector(31 downto 0);
signal sd_busy        : std_logic;
signal sd_done        : std_logic;
signal sd_rd_byte_strobe : std_logic;
signal sd_byte_index  : std_logic_vector(8 downto 0);
signal sd_rd_data     : std_logic_vector(7 downto 0);
signal sd_wr_data     : std_logic_vector(7 downto 0);
signal sd_change      : std_logic;
signal sdc_int        : std_logic;
signal sdc_iack       : std_logic;
signal int_ack        : std_logic_vector(7 downto 0);
signal spi_ext        : std_logic;
signal spi_io_din     : std_logic;
signal spi_io_ss      : std_logic;
signal spi_io_clk     : std_logic;
signal spi_io_dout    : std_logic;
signal disk_g64       : std_logic;
signal disk_g64_d     : std_logic;
signal c1541_reset    : std_logic;
signal c1541_osd_reset : std_logic;
signal system_wide_screen : std_logic;
signal system_floppy_wprot : std_logic_vector(1 downto 0);
signal leds           : std_logic_vector(5 downto 0);
signal system_leds    : std_logic_vector(1 downto 0);
signal led1541        : std_logic;

signal cart_ce        : std_logic;
signal cart_we        : std_logic;

signal cart_addr      : std_logic_vector(22 downto 0);
signal db9_joy        : std_logic_vector(5 downto 0);
signal turbo_mode     : std_logic_vector(1 downto 0);
signal turbo_speed    : std_logic_vector(1 downto 0);
signal dos_sel        : std_logic_vector(1 downto 0);
signal c1541rom_cs    : std_logic;
signal c1541rom_addr  : std_logic_vector(14 downto 0);
signal c1541rom_data  : std_logic_vector(7 downto 0);
signal ext_en         : std_logic;
signal freeze_key     : std_logic;
signal disk_access    : std_logic;
signal c64_iec_clk_old : std_logic;
signal drive_iec_clk_old : std_logic;
signal drive_stb_i_old : std_logic;
signal drive_stb_o_old : std_logic;
signal hsync_out       : std_logic;
signal vsync_out       : std_logic;
signal hblank          : std_logic;
signal vblank          : std_logic;
signal frz_hs          : std_logic;
signal frz_vs          : std_logic;
signal hbl_out         : std_logic; 
signal vbl_out         : std_logic;
signal st_midi         : std_logic_vector(2 downto 0);
signal frz_hbl         : std_logic;
signal frz_vbl         : std_logic;
signal system_pause    : std_logic;
signal paddle_1        : std_logic_vector(7 downto 0);
signal paddle_2        : std_logic_vector(7 downto 0);
signal key_r1          : std_logic;
signal key_r2          : std_logic;
signal key_l1          : std_logic;
signal key_l2          : std_logic;
signal key_triangle    : std_logic;
signal key_square      : std_logic;
signal key_circle      : std_logic;
signal key_cross       : std_logic;
signal key_up          : std_logic;
signal key_down        : std_logic;
signal key_left        : std_logic;
signal key_right       : std_logic;
signal key_start       : std_logic;
signal key_select      : std_logic;
signal ntscModeD       : std_logic;
signal audio_div       : unsigned(8 downto 0);
signal flash_clk       : std_logic;
signal flash_lock      : std_logic;
---
signal v20_en          : std_logic; 
signal video_r         : std_logic_vector(3 downto 0);
signal video_g         : std_logic_vector(3 downto 0);
signal video_b         : std_logic_vector(3 downto 0);
signal vic_audio       : std_logic_vector(5 downto 0);
signal IDSEL           : std_logic_vector(5 downto 0);
signal FBDSEL          : std_logic_vector(5 downto 0);
signal i_ram_ext       : std_logic_vector(4 downto 0) := "11111";
signal extram          : std_logic_vector(4 downto 0);
signal i_ram_ext_ro    : std_logic_vector(4 downto 0);
signal ext_ro          : std_logic_vector(4 downto 0);
signal i_center        : std_logic_vector(1 downto 0);
signal crt_writeable   : std_logic; 
-- loader
signal load_crt        : std_logic := '0';
signal load_prg        : std_logic := '0';
signal load_rom        : std_logic := '0';
signal load_tap        : std_logic := '0';
signal disk_lba        : std_logic_vector(31 downto 0);
signal loader_lba      : std_logic_vector(31 downto 0);
signal loader_busy     : std_logic;
signal img_select      : std_logic_vector(2 downto 0);
signal ioctl_download  : std_logic := '0';
signal old_download    : std_logic;
signal ioctl_load_addr : std_logic_vector(22 downto 0);
signal ioctl_wr        : std_logic;
signal ioctl_data      : std_logic_vector(7 downto 0);
signal ioctl_addr      : std_logic_vector(22 downto 0);
signal ioctl_wait      : std_logic := '0';
signal dl_addr         : std_logic_vector(15 downto 0);
signal dl_data         : std_logic_vector(7 downto 0);
signal dl_wr           : std_logic;
signal addr            : std_logic_vector(15 downto 0);
signal cart_reset      : std_logic := '0';
signal cart_blk        : std_logic_vector(4 downto 0)  := "00000";
signal state           : std_logic_vector(3 downto 0)  := "0000";
signal vic_wr_n        : std_logic;
signal vic_io2_sel     : std_logic;
signal vic_io3_sel     : std_logic;
signal vic_blk123_sel  : std_logic;
signal vic_blk5_sel    : std_logic;
signal vic_ram123_sel  : std_logic;
signal vic_data        : std_logic_vector(7 downto 0);
signal vic_addr        : std_logic_vector(15 downto 0);
signal sdram_out       : std_logic_vector(7 downto 0);
signal ioctl_wr_d      : std_logic;
signal extmem_sel      : std_logic;
signal p2_h            : std_logic;
signal resetvic20      : std_logic;
signal old_reset       : std_logic;
signal tap_play_addr  : std_logic_vector(22 downto 0);
signal tap_last_addr  : std_logic_vector(22 downto 0);
signal tap_version    : std_logic_vector(1 downto 0);
signal cass_write     : std_logic;
signal cass_motor     : std_logic;
signal cass_sense     : std_logic;
signal cass_read      : std_logic;
signal cass_run       : std_logic;
signal cass_finish    : std_logic;
signal cass_snd       : std_logic;
signal tap_download   : std_logic;
signal tap_reset      : std_logic;
signal tap_loaded     : std_logic;
signal tap_play_btn   : std_logic;
signal tap_wrreq      : std_logic_vector(1 downto 0);
signal tap_wrfull     : std_logic;
signal tap_start      : std_logic;
signal read_cyc       : std_logic := '0';
signal tap_rd         : std_logic := '0';
signal tap_data_ready : std_logic := '1';
signal tap_wr         : std_logic := '0';
signal cass_aud       : std_logic;
signal audio_l        : std_logic_vector(17 downto 0);
signal audio_r        : std_logic_vector(17 downto 0);

signal io_cycle        : std_logic;
signal io_cycleD       : std_logic;
signal io_cycle_rD     : std_logic;
signal io_cycle_ce     : std_logic;
signal io_cycle_we     : std_logic;
signal io_cycle_addr   : std_logic_vector(22 downto 0);
signal io_cycle_data   : std_logic_vector(7 downto 0);
signal ioctl_req_wr    : std_logic := '0';
signal img_present     : std_logic := '0';
signal c1541_sd_rd     : std_logic;
signal c1541_sd_wr     : std_logic;

signal mspi_hold       : std_logic;
signal mspi_wp         : std_logic;
signal c1541_osd_reset_d  : std_logic;
signal drambusy        : std_logic;
signal rd_data_valid   : std_logic;
signal rd_data         : std_logic_vector(63 downto 0) ;
attribute syn_keep of rd_data : signal is 1;
attribute syn_keep of rd_data_valid : signal is 1;
signal tap_cycle       : std_logic;
signal tap_autoplay, wait_psram, wait_psram_rd,tap_wr_d,tap_rd_d  : std_logic;
signal psaddr          : std_logic_vector(21 downto 0);
signal joystick0ax     : std_logic_vector(7 downto 0);
signal joystick0ay     : std_logic_vector(7 downto 0);
signal joystick1ax     : std_logic_vector(7 downto 0);
signal joystick1ay     : std_logic_vector(7 downto 0);
signal joystick_strobe : std_logic;
signal joystick1_x_pos : std_logic_vector(7 downto 0);
signal joystick1_y_pos : std_logic_vector(7 downto 0);
signal joystick2_x_pos : std_logic_vector(7 downto 0);
signal joystick2_y_pos : std_logic_vector(7 downto 0);
signal extra_button0   : std_logic_vector(7 downto 0);
signal extra_button1   : std_logic_vector(7 downto 0);
signal detach_reset    : std_logic;
signal user_port_cb1_in  : std_logic;
signal user_port_cb2_in  : std_logic;
signal user_port_cb1_out : std_logic;
signal user_port_cb2_out : std_logic;
signal user_port_in      : std_logic_vector(7 downto 0);
signal user_port_out     : std_logic_vector(7 downto 0);
signal uart_rxD          : std_logic_vector(1 downto 0);
signal uart_rx_filtered  : std_logic;

constant TAP_ADDR      : std_logic_vector(22 downto 0) := 23x"200000";

component CLKDIV
    generic (
        DIV_MODE : STRING := "2";
        GSREN: in string := "false"
    );
    port (
        CLKOUT: out std_logic;
        HCLKIN: in std_logic;
        RESETN: in std_logic;
        CALIB: in std_logic
    );
end component;

component rPLL
    generic (
        FCLKIN: in string := "100.0";
        DEVICE: in string := "GW1NR-9C";                 DYN_IDIV_SEL: in string := "false";
        IDIV_SEL: in integer := 0;
        DYN_FBDIV_SEL: in string := "false";
        FBDIV_SEL: in integer := 0;
        DYN_ODIV_SEL: in string := "false";
        ODIV_SEL: in integer := 8;
        PSDA_SEL: in string := "0000";
        DYN_DA_EN: in string := "false";
        DUTYDA_SEL: in string := "1000";
        CLKOUT_FT_DIR: in bit := '1';
        CLKOUTP_FT_DIR: in bit := '1';
        CLKOUT_DLY_STEP: in integer := 0;
        CLKOUTP_DLY_STEP: in integer := 0;
        CLKOUTD3_SRC: in string := "CLKOUT";
        CLKFB_SEL: in string := "internal";
        CLKOUT_BYPASS: in string := "false";
        CLKOUTP_BYPASS: in string := "false";
        CLKOUTD_BYPASS: in string := "false";
        CLKOUTD_SRC: in string := "CLKOUT";
        DYN_SDIV_SEL: in integer := 2
    );
    port (
        CLKOUT: out std_logic;
        LOCK: out std_logic;
        CLKOUTP: out std_logic;
        CLKOUTD: out std_logic;
        CLKOUTD3: out std_logic;
        RESET: in std_logic;
        RESET_P: in std_logic;
        CLKIN: in std_logic;
        CLKFB: in std_logic;
        FBDSEL: in std_logic_vector(5 downto 0);
        IDSEL: in std_logic_vector(5 downto 0);
        ODSEL: in std_logic_vector(5 downto 0);
        PSDA: in std_logic_vector(3 downto 0);
        DUTYDA: in std_logic_vector(3 downto 0);
        FDLY: in std_logic_vector(3 downto 0)
    );
end component;

begin
-- ----------------- SPI input parser ----------------------
-- map output data onto both spi outputs
  spi_io_din  <= m0s(1);
  spi_io_ss   <= m0s(2);
  spi_io_clk  <= m0s(3);
  m0s(0)      <= spi_io_dout; -- M0 Dock

-- https://store.curiousinventor.com/guides/PS2/
-- https://hackaday.io/project/170365-blueretro/log/186471-playstation-playstation-2-spi-interface

gamepad: entity work.dualshock2
    port map (
    clk           => clk32,
    rst           => system_reset(0) and not pll_locked,
    vsync         => vsync,
    ds2_dat       => ds_miso,
    ds2_cmd       => ds_mosi,
    ds2_att       => ds_cs,
    ds2_clk       => ds_clk,
    ds2_ack       => '0',
    stick_lx      => paddle_1,
    stick_ly      => paddle_2,
    stick_rx      => open,
    stick_ry      => open,
    key_up        => key_up,
    key_down      => key_down,
    key_left      => key_left,
    key_right     => key_right,
    key_l1        => key_l1,
    key_l2        => key_l2,
    key_r1        => key_r1,
    key_r2        => key_r2,
    key_triangle  => key_triangle,
    key_square    => key_square,
    key_circle    => key_circle,
    key_cross     => key_cross,
    key_start     => key_start,
    key_select    => key_select,
    key_lstick    => open,
    key_rstick    => open,
    debug1        => open,
    debug2        => open
    );


sd_lba <= loader_lba;
sd_rd(0) <= '0';
sd_wr(0) <= '0';
sdc_iack <= int_ack(3);

sd_card_inst: entity work.sd_card
generic map (
    CLK_DIV  => 1
  )
    port map (
    rstn            => pll_locked, 
    clk             => clk32,
  
    -- SD card signals
    sdclk           => sd_clk,
    sdcmd           => sd_cmd,
    sddat           => sd_dat,

    -- mcu interface
    data_strobe     => mcu_sdc_strobe,
    data_start      => mcu_start,
    data_in         => mcu_data_out,
    data_out        => sdc_data_out,

    -- interrupt to signal communication request
    irq             => sdc_int,
    iack            => sdc_iack,

    -- output file/image information. Image size is e.g. used by fdc to 
    -- translate between sector/track/side and lba sector
    image_size      => sd_img_size,           -- length of image file
    image_mounted   => sd_img_mounted,

    -- user read sector command interface (sync with clk)
    rstart          => sd_rd,
    wstart          => sd_wr, 
    rsector         => sd_lba,
    rbusy           => sd_busy,
    rdone           => sd_done,           --  done from sd reader acknowledges/clears start

    -- sector data output interface (sync with clk)
    inbyte          => sd_wr_data,        -- sector data output interface (sync with clk)
    outen           => sd_rd_byte_strobe, -- when outen=1, a byte of sector content is read out from outbyte
    outaddr         => sd_byte_index,     -- outaddr from 0 to 511, because the sector size is 512
    outbyte         => sd_rd_data         -- a byte of sector content
);

process(clk32)
begin
  if rising_edge(clk32) then
    old_sync <= freeze_sync;
      if not old_sync and freeze_sync then
          freeze <= osd_status and system_pause;
        end if;
  end if;
end process;

audio_div  <= to_unsigned(342,9) when ntscMode = '1' else to_unsigned(371,9);
cass_aud <= cass_read and not cass_sense and not cass_motor;
audio_l <= (vic_audio & "000000000000") or (5x"00" & cass_aud & 12x"00000");
audio_r <= audio_l;

video_inst: entity work.video 
port map(
      pll_lock     => pll_locked, 
      clk          => clk32,
      clk_pixel_x5 => clk_pixel_x5,
      audio_div    => audio_div,
      
      v20_en       => v20_en,

      ntscmode  => ntscMode,
      vb_in     => vblank,
      hb_in     => hblank,
      hs_in_n   => hsync,
      vs_in_n   => vsync,

      r_in      => std_logic_vector(video_r),
      g_in      => std_logic_vector(video_g),
      b_in      => std_logic_vector(video_b),

      audio_l => audio_l,
      audio_r => audio_r,
      osd_status => osd_status,

      mcu_start => mcu_start,
      mcu_osd_strobe => mcu_osd_strobe,
      mcu_data  => mcu_data_out,

      -- values that can be configure by the user via osd
      system_wide_screen => system_wide_screen,
      system_scanlines => system_scanlines,
      system_volume => system_volume,

      tmds_clk_n => tmds_clk_n,
      tmds_clk_p => tmds_clk_p,
      tmds_d_n   => tmds_d_n,
      tmds_d_p   => tmds_d_p
      );

      O_psram_reset_n <= pll_locked & pll_locked;
      sdram_out <= dout16(7 downto 0);
      psaddr <= ioctl_addr(21 downto 0) when tap_download = '1' else tap_play_addr(21 downto 0);

      dram_inst: entity work.PsramController
        generic map (
          LATENCY  => 3,
          FREQ     => 71550000,
          CS_DELAY => false )
        port map
        (
          clk           => clk64, 
          clk_p         => clk64_90,
          resetn        => pll_locked,
          read          => tap_rd,
          write         => tap_wr,
          byte_write    => '0',
          addr          => psaddr,
          din           => ioctl_data & ioctl_data,
          dout          => dout16,
          busy          => drambusy,
          O_psram_ck    => O_psram_ck,
          O_psram_ck_n  => O_psram_ck_n,
          IO_psram_rwds => IO_psram_rwds,
          IO_psram_dq   => IO_psram_dq,
          O_psram_cs_n  => O_psram_cs_n
    );

-- Clock tree and all frequencies in Hz
-- TN20k VIC20
--                  PAL  / NTSC  
-- pll         357750000  329400000
-- serdes      178875000  164700000
-- dram         71550000   65880000
-- core /pixel  35775000   32940000
-- psram       119250000
-- IDIV_SEL     3         4
-- FBDIV_SEL   52         60
-- ODIV_SEL     2         2

process(clk32)
begin
  if rising_edge(clk32) then
    ntscModeD <= ntscMode;
    IDSEL  <= "111100" when ntscModeD = '0' else "111011";
    FBDSEL <= "001011" when ntscModeD = '0' else "000011";
  end if;
end process;

mainclock: rPLL
        generic map (
          FCLKIN => "27",
          DEVICE => "GW1NR-9C",
          DYN_IDIV_SEL => "false",
          IDIV_SEL => 3,
          DYN_FBDIV_SEL => "false",
          FBDIV_SEL => 52,
          DYN_ODIV_SEL => "false",
          ODIV_SEL => 2,
          PSDA_SEL => "0100",
          DYN_DA_EN => "false",
          DUTYDA_SEL => "1000",
          CLKOUT_FT_DIR => '1',
          CLKOUTP_FT_DIR => '1',
          CLKOUT_DLY_STEP => 0,
          CLKOUTP_DLY_STEP => 0,
          CLKFB_SEL => "internal",
          CLKOUT_BYPASS => "false",
          CLKOUTP_BYPASS => "false",
          CLKOUTD_BYPASS => "false",
          DYN_SDIV_SEL => 2,
          CLKOUTD_SRC => "CLKOUT",
          CLKOUTD3_SRC => "CLKOUT"
        )
        port map (
            CLKOUT   => clk_pixel_x10,
            LOCK     => pll_locked,
            CLKOUTP  => clk_pixel_x10_90,
            CLKOUTD  => open,
            CLKOUTD3 => open,
            RESET    => '0',
            RESET_P  => '0',
            CLKIN    => clk_27mhz,
            CLKFB    => '0',
            FBDSEL   => FBDSEL,
            IDSEL    => IDSEL,
            ODSEL    => (others => '0'),
            PSDA     => (others => '0'),
            DUTYDA   => (others => '0'),
            FDLY     => (others => '1')
        );

div1_inst: CLKDIV
generic map(
    DIV_MODE => "5",
    GSREN    => "false"
)
port map(
    CLKOUT => clk64,
    HCLKIN => clk_pixel_x10,
    RESETN => pll_locked,
    CALIB  => '0'
);

div2_inst: CLKDIV
generic map(
  DIV_MODE => "2",
  GSREN    => "false"
)
port map(
    CLKOUT => clk32,
    HCLKIN => clk64,
    RESETN => pll_locked,
    CALIB  => '0'
);

div3_inst: CLKDIV
generic map(
    DIV_MODE => "2",
    GSREN    => "false"
)
port map(
    CLKOUT => clk_pixel_x5,
    HCLKIN => clk_pixel_x10,
    RESETN => pll_locked,
    CALIB  => '0'
);

div4_inst: CLKDIV
generic map(
    DIV_MODE => "5",
    GSREN    => "false"
)
port map(
    CLKOUT => clk64_90,
    HCLKIN => clk_pixel_x10_90,
    RESETN => pll_locked,
    CALIB  => '0'
);

-- TN20k  Winbond 25Q64JVIQ
-- TP25k  XTX XT25F64FWOIG
-- TM138k Winbond 25Q128BVEA
-- phase shift 135° TN, TP and 270° TM

flashclock: rPLL
        generic map (
          FCLKIN => "27",
          DEVICE => "GW1NR-9C",
          DYN_IDIV_SEL => "false",
          IDIV_SEL => 7,
          DYN_FBDIV_SEL => "false",
          FBDIV_SEL => 18,
          DYN_ODIV_SEL => "false",
          ODIV_SEL => 8,
          PSDA_SEL => "0111", -- phase shift 157°
          DYN_DA_EN => "false",
          DUTYDA_SEL => "1000",
          CLKOUT_FT_DIR => '1',
          CLKOUTP_FT_DIR => '1',
          CLKOUT_DLY_STEP => 0,
          CLKOUTP_DLY_STEP => 0,
          CLKFB_SEL => "internal",
          CLKOUT_BYPASS => "false",
          CLKOUTP_BYPASS => "false",
          CLKOUTD_BYPASS => "false",
          DYN_SDIV_SEL => 2,
          CLKOUTD_SRC => "CLKOUT",
          CLKOUTD3_SRC => "CLKOUT"
        )
        port map (
            CLKOUT   => flash_clk, -- clock Flash controller
            LOCK     => flash_lock,
            CLKOUTP  => mspi_clk, -- phase shifted clock SPI Flash
            CLKOUTD  => open,
            CLKOUTD3 => open,
            RESET    => '0',
            RESET_P  => '0',
            CLKIN    => clk_27mhz,
            CLKFB    => '0',
            FBDSEL   => (others => '0'),
            IDSEL    => (others => '0'),
            ODSEL    => (others => '0'),
            PSDA     => (others => '0'),
            DUTYDA   => (others => '0'),
            FDLY     => (others => '1')
        );

leds_n <=  not leds;
leds(0) <= led1541;

--                    6   5  4  3  2  1  0
--                  TR3 TR2 TR RI LE DN UP digital c64 
joyDS2_p1  <= key_circle  & key_cross  & key_square  & key_right  & key_left  & key_down  & key_up;
joyDigital <= not('1'& '1' & io(0) & io(3) & io(4) & io(1) & io(2));
joyUsb1    <= joystick1(6 downto 4) & joystick1(0) & joystick1(1) & joystick1(2) & joystick1(3);
joyUsb2    <= joystick2(6 downto 4) & joystick2(0) & joystick2(1) & joystick2(2) & joystick2(3);
joyNumpad  <= '0' & numpad(5 downto 4) & numpad(0) & numpad(1) & numpad(2) & numpad(3);
joyMouse   <= "00" & mouse_btns(0) & "000" & mouse_btns(1);
joyDS2A_p1 <= "00" & '0' & key_cross  & key_square  & "00"; -- DS2 left stick
joyUsb1A   <= "00" & '0' & joystick1(5) & joystick1(4) & "00"; -- Y,X button
joyUsb2A   <= "00" & '0' & joystick2(5) & joystick2(4) & "00"; -- Y,X button

-- send external DB9 joystick port to µC
db9_joy <= not('1' & io(0), io(2), io(1), io(4), io(3));

process(clk32)
begin
	if rising_edge(clk32) then
    case port_1_sel is
      when "0000"  => joyA <= joyDigital;
      when "0001"  => joyA <= joyUsb1;
      when "0010"  => joyA <= joyUsb2;
      when "0011"  => joyA <= joyNumpad;
      when "0100"  => joyA <= joyDS2_p1;
      when "0101"  => joyA <= joyMouse;
      when "0110"  => joyA <= joyDS2A_p1;
      when "0111"  => joyA <= joyUsb1A;
      when "1000"  => joyA <= joyUsb2A;
      when "1001"  => joyA <= (others => '0');
      when others  => joyA <= (others => '0');
    end case;
  end if;
end process;

-- paddle pins - mouse
pot1 <= not paddle_1 when port_1_sel = "0110" else 
        joystick1_x_pos(7 downto 0) when port_1_sel = "0111" else
        joystick2_x_pos(7 downto 0) when port_1_sel = "1000" else
        '0' & std_logic_vector(mouse_x_pos(6 downto 1)) & '0' when port_1_sel = "0101" else 
        x"ff";

pot2 <= not paddle_2 when port_1_sel = "0110" else 
        joystick1_y_pos(7 downto 0) when port_1_sel = "0111" else 
        joystick2_y_pos(7 downto 0) when port_1_sel = "1000" else
        '0' & std_logic_vector(mouse_y_pos(6 downto 1)) & '0' when port_1_sel = "0101" else 
        x"ff";

process(clk32, system_reset(0))
 variable mov_x: signed(6 downto 0);
 variable mov_y: signed(6 downto 0);
begin
  if  system_reset(0) = '1' then
    mouse_x_pos <= (others => '0');
    mouse_y_pos <= (others => '0');
    joystick1_x_pos <= x"ff";
    joystick1_y_pos <= x"ff";
    joystick2_x_pos <= x"ff";
    joystick2_y_pos <= x"ff";
    elsif rising_edge(clk32) then
    if mouse_strobe = '1' then
     -- due to limited resolution on the c64 side, limit the mouse movement speed
      if mouse_x > 40 then mov_x:="0101000"; elsif mouse_x < -40 then mov_x:= "1011000"; else mov_x := mouse_x(6 downto 0); end if;
      if mouse_y > 40 then mov_y:="0101000"; elsif mouse_y < -40 then mov_y:= "1011000"; else mov_y := mouse_y(6 downto 0); end if;
      mouse_x_pos <= mouse_x_pos - mov_x;
      mouse_y_pos <= mouse_y_pos + mov_y;
     elsif joystick_strobe = '1' then
      joystick1_x_pos <= std_logic_vector(joystick0ax(7 downto 0));
      joystick1_y_pos <= std_logic_vector(joystick0ay(7 downto 0));
      joystick2_x_pos <= std_logic_vector(joystick1ax(7 downto 0));
      joystick2_y_pos <= std_logic_vector(joystick1ay(7 downto 0));
      end if;
  end if;
end process;

mcu_spi_inst: entity work.mcu_spi 
port map (
  clk            => clk32,
  reset          => not pll_locked,
  -- SPI interface to BL616 MCU
  spi_io_ss      => spi_io_ss,      -- SPI CSn
  spi_io_clk     => spi_io_clk,     -- SPI SCLK
  spi_io_din     => spi_io_din,     -- SPI MOSI
  spi_io_dout    => spi_io_dout,    -- SPI MISO
  -- byte interface to the various core components
  mcu_sys_strobe => mcu_sys_strobe, -- byte strobe for system control target
  mcu_hid_strobe => mcu_hid_strobe, -- byte strobe for HID target  
  mcu_osd_strobe => mcu_osd_strobe, -- byte strobe for OSD target
  mcu_sdc_strobe => mcu_sdc_strobe, -- byte strobe for SD card target
  mcu_start      => mcu_start,
  mcu_sys_din    => sys_data_out,
  mcu_hid_din    => hid_data_out,
  mcu_osd_din    => osd_data_out,
  mcu_sdc_din    => sdc_data_out,
  mcu_dout       => mcu_data_out
);

-- decode SPI/MCU data received for human input devices (HID) 
hid_inst: entity work.hid
 port map 
 (
  clk             => clk32,
  reset           => not pll_locked,
  -- interface to receive user data from MCU (mouse, kbd, ...)
  data_in_strobe  => mcu_hid_strobe,
  data_in_start   => mcu_start,
  data_in         => mcu_data_out,
  data_out        => hid_data_out,

  -- input local db9 port events to be sent to MCU
  db9_port        => db9_joy,
  irq             => hid_int,
  iack            => int_ack(1),
  -- output HID data received from USB
  joystick0       => joystick1,
  joystick1       => joystick2,
  numpad          => numpad,
  keyboard_matrix_out => keyboard_matrix_out,
  keyboard_matrix_in  => keyboard_matrix_in,
  key_restore     => freeze_key,
  tape_play       => open,
  mod_key         => open,
  mouse_btns      => mouse_btns,
  mouse_x         => mouse_x,
  mouse_y         => mouse_y,
  mouse_strobe    => mouse_strobe,
  joystick0ax     => joystick0ax,
  joystick0ay     => joystick0ay,
  joystick1ax     => joystick1ax,
  joystick1ay     => joystick1ay,
  joystick_strobe => joystick_strobe,
  extra_button0   => extra_button0,
  extra_button1   => extra_button1
  );

module_inst: entity work.sysctrl 
 port map 
 (
  clk                 => clk32,
  reset               => not pll_locked,
--
  data_in_strobe      => mcu_sys_strobe,
  data_in_start       => mcu_start,
  data_in             => mcu_data_out,
  data_out            => sys_data_out,

  -- values that can be configured by the user
  system_chipset      => open,
  system_memory       => open,
  system_reset        => system_reset,
  system_scanlines    => system_scanlines,
  system_volume       => system_volume,
  system_wide_screen  => system_wide_screen,
  system_floppy_wprot => system_floppy_wprot,
  system_port_1       => port_1_sel,
  system_dos_sel      => dos_sel,
  system_1541_reset   => c1541_osd_reset,
  system_video_std    => ntscMode,
  system_i_ram_ext0   => extram(0),
  system_i_ram_ext1   => extram(1),
  system_i_ram_ext2   => extram(2),
  system_i_ram_ext3   => extram(3),
  system_i_ram_ext4   => extram(4),
  system_i_center     => i_center,
  system_crt_write    => crt_writeable,
  system_detach_reset => detach_reset,
  cold_boot           => open,

  int_out_n           => m0s(4),
  int_in              => unsigned'(x"0" & sdc_int & '0' & hid_int & '0'),
  int_ack             => int_ack,

  buttons             => unsigned'(not reset & not user), -- S0 and S1 buttons
  leds                => system_leds,         -- two leds can be controlled from the MCU
  color               => ws2812_color -- a 24bit color to e.g. be used to drive the ws2812
);

process(clk32)
variable toX:	integer;
begin
  if rising_edge(clk32) then
    c64_iec_clk_old   <= iec_clk_i;
    drive_iec_clk_old <= iec_clk_o;
    drive_stb_i_old   <= pc2_n;
    drive_stb_o_old   <= flag2_n;
    if ( c64_iec_clk_old /= iec_clk_i or drive_iec_clk_old /= iec_clk_o or ((drive_stb_i_old /= pc2_n or drive_stb_o_old /= flag2_n) and ext_en = '1') ) then
        disk_access <= '1';
        toX := 16000000; -- 0.5s
    elsif (toX /= 0) then
      toX := toX - 1;
    else  
      disk_access <= '0';
    end if;
  end if;
end process;

ext_ro <=   (cart_blk(4) and not crt_writeable)
          & (cart_blk(3) and not crt_writeable)
          & (cart_blk(2) and not crt_writeable)
          & (cart_blk(1) and not crt_writeable)
          & (cart_blk(0) and not crt_writeable);

i_ram_ext_ro <= ext_ro;
i_ram_ext <= extram or cart_blk;

resetvic20 <= system_reset(0) or not pll_locked or cart_reset or detach_reset;

vic_inst: entity work.VIC20
	port map(
		--
		i_sysclk      => clk32,
		i_sysclk_en   => v20_en,
		i_reset       => resetvic20,
		o_p2h         => p2_h,

		-- serial bus pins
		atn_o         => iec_atn_o,
		clk_o         => iec_clk_o,
		clk_i         => iec_clk_i,
		data_o        => iec_data_o,
		data_i        => iec_data_i,
		--
		i_joy         => not joyA(3 downto 0), -- 0 up, 1 down, 2 left,  3 right
		i_fire        => not joyA(4),          -- all low active
		i_potx        => not pot1,
		i_poty        => not pot2,

		--
		i_ram_ext_ro  => i_ram_ext_ro, -- read-only region if set
		i_ram_ext     => i_ram_ext,    -- at $A000(8k),$6000(8k),$4000(8k),$2000(8k),$0400(3k)
		--
		i_extmem_en   => '0',
		o_extmem_sel  => extmem_sel,
		o_extmem_r_wn => vic_wr_n,
		o_extmem_addr => vic_addr,
		i_extmem_data => (others => '0'),
		o_extmem_data => vic_data,
		o_io2_sel     => vic_io2_sel,
		o_io3_sel     => vic_io3_sel,
		o_blk123_sel  => vic_blk123_sel,
		o_blk5_sel    => vic_blk5_sel,
		o_ram123_sel  => vic_ram123_sel,
		--
		o_ce_pix      => open,
		o_video_r     => video_r,
		o_video_g     => video_g,
		o_video_b     => video_b,
		o_hsync       => hsync,
		o_vsync       => vsync,
		o_hblank      => hblank,
		o_vblank      => vblank,
		i_center      => i_center,
		i_pal         => not ntscMode,
		i_wide        => '0',
		--
		ps2_key       => (others => '0'),
  -- keyboard interface
    keyboard_matrix_out => keyboard_matrix_out,
    keyboard_matrix_in  => keyboard_matrix_in,
		tape_play     => open,
		--
		o_audio       => vic_audio,

		cass_write    => cass_write,
		cass_read     => cass_read,
		cass_motor    => cass_motor,
		cass_sw       => cass_sense,

		--configures "embedded" core memory
		rom_std       => '1',
		conf_clk      => clk32,
		conf_wr       => dl_wr,
		conf_ai       => dl_addr,
		conf_di       => dl_data,

    -- user port RS232
    user_port_cb1_in  => user_port_cb1_in,
    user_port_cb2_in  => user_port_cb2_in,
    user_port_cb1_out => user_port_cb1_out,
    user_port_cb2_out => user_port_cb2_out,
    user_port_in      => user_port_in,
    user_port_out     => user_port_out,

    flash_clk    => flash_clk,
    flash_lock   => flash_lock,
    mspi_cs      => mspi_cs,
    mspi_di      => mspi_di,
    mspi_do      => mspi_do
	);

  crt_inst : entity work.loader_sd_card
  port map (
    clk               => clk32,
    system_reset      => system_reset,
  
    sd_lba            => loader_lba,
    sd_rd             => sd_rd(4 downto 1),
    sd_wr             => sd_wr(4 downto 1),
    sd_busy           => sd_busy,
    sd_done           => sd_done,
  
    sd_byte_index     => sd_byte_index,
    sd_rd_data        => sd_rd_data,
    sd_rd_byte_strobe => sd_rd_byte_strobe,
  
    sd_img_mounted    => sd_img_mounted,
    loader_busy       => loader_busy,
    load_crt          => load_crt,
    load_prg          => load_prg,
    load_rom          => load_rom,
    load_tap          => load_tap,
    sd_img_size       => sd_img_size,
    leds              => leds(5 downto 1),
    img_select        => img_select,
  
    ioctl_download    => ioctl_download,
    ioctl_addr        => ioctl_addr,
    ioctl_data        => ioctl_data,
    ioctl_wr          => ioctl_wr,
    ioctl_wait        => ioctl_wait
  );

process(clk32)
begin
  if rising_edge(clk32) then
    dl_wr <= '0';
    old_download <= ioctl_download;

    if ioctl_download and load_prg then
      state <= x"0";
      if ioctl_wr then
        if ioctl_addr = 0 then
                addr(7 downto 0)  <= ioctl_data;
        elsif ioctl_addr = 1 then
            addr(15 downto 8) <= ioctl_data;
        elsif addr < x"A000" then
              dl_addr <= addr;
              dl_data <= ioctl_data;
              dl_wr <= '1';
              addr <= addr + 1;
        end if;
      end if;
    end if;

    if old_download = '1' and ioctl_download = '0' and load_prg = '1' then
        state <= x"1"; end if;

    if state /= x"0" then state <= state + 1; end if;

    case(state) is
       when x"1" => dl_addr <= x"002d"; dl_data <= addr(7 downto 0); dl_wr <= '1';
       when x"3" => dl_addr <= x"002e"; dl_data <= addr(15 downto 8); dl_wr <= '1';
       when x"5" => dl_addr <= x"002f"; dl_data <= addr(7 downto 0); dl_wr <= '1';
       when x"7" => dl_addr <= x"0030"; dl_data <= addr(15 downto 8); dl_wr <= '1';
       when x"9" => dl_addr <= x"0031"; dl_data <= addr(7 downto 0); dl_wr <= '1';
       when x"B" => dl_addr <= x"0032"; dl_data <= addr(15 downto 8); dl_wr <= '1';
       when x"D" => dl_addr <= x"00ae"; dl_data <= addr(7 downto 0); dl_wr <= '1';
       when x"F" => dl_addr <= x"00af"; dl_data <= addr(15 downto 8); dl_wr <= '1';
       when others => 
    end case;

    if ioctl_download and load_rom then
      state <= x"0";
      if ioctl_wr = '1' then
          dl_addr <= ioctl_addr(15 downto 0) or x"E000";
          dl_data <= ioctl_data;
          dl_wr <= '1';
      end if;
    end if;

    if ioctl_download and load_crt then
      if ioctl_wr then
        if ioctl_addr = 0 and load_crt = '1' then
              addr(7 downto 0) <= ioctl_data;
        elsif ioctl_addr = 1 and load_crt = '1' then 
              addr(15 downto 8) <= ioctl_data;
        elsif addr < x"C000" then
          if addr(15 downto 13) = "000" then cart_blk(0) <= '1'; end if;
          if addr(15 downto 13) = "001" then cart_blk(1) <= '1'; end if;
          if addr(15 downto 13) = "010" then cart_blk(2) <= '1'; end if;
          if addr(15 downto 13) = "011" then cart_blk(3) <= '1'; end if;
          if addr(15 downto 13) = "101" then cart_blk(4) <= '1'; end if;
          dl_addr <= addr(15 downto 0);
          dl_data <= ioctl_data;
          dl_wr <= '1';
          addr <= addr + 1;
        end if;
      end if;
    end if;

    if old_download /= ioctl_download and (load_crt or load_rom) = '1' then
        cart_reset <= ioctl_download;
      end if;

    if (system_reset(1) or detach_reset) = '1' then
      cart_reset <= '0';
      cart_blk <= (others => '0');
    end if;
    
   end if;
end process;

-------------- TAP -------------------

process(clk32)
begin
  if rising_edge(clk32) then
    old_reset <= resetvic20;
    tap_wr <= '0';

    if old_reset = '0' and resetvic20 = '1' then 
      ioctl_wait <= '0'; 
    end if;

    if ioctl_wr = '1' and load_tap = '1' and drambusy = '0' then
      ioctl_wait <= '1';
      tap_wr <= '1';
      if ioctl_addr = 12 then tap_version <= ioctl_data(1 downto 0); end if;
    elsif tap_wr = '0' then
      ioctl_wait <= '0';
    end if;
  end if;
end process;

tap_download <= ioctl_download and load_tap;
tap_reset <= '1' when resetvic20 = '1' or tap_download = '1'or tap_last_addr = 0 or cass_finish = '1' or (cass_run = '1'and ((unsigned(tap_last_addr) - unsigned(tap_play_addr)) < 80)) else '0';
tap_loaded <= '1' when (tap_play_addr < tap_last_addr) else '0';

process(clk32)
begin
  if rising_edge(clk32) then
      if tap_reset = '1' then
        tap_last_addr <= ioctl_addr + 2 when tap_download = '1' else (others => '0');
        tap_play_addr <= (others => '0');
        tap_rd <= '0';
        tap_cycle <= '0';
        tap_autoplay <= tap_download;
      else
        tap_rd <= '0';
        tap_wrreq(0) <= '0';
        tap_autoplay <= '0';

        if tap_rd = '0' and tap_wrreq(0) = '0' then
          if tap_cycle = '1' then
            if drambusy = '0' then
              tap_play_addr <= tap_play_addr + 1;
              tap_cycle <= '0';
              tap_wrreq(0) <= '1';
            end if;  -- rd_data_valid
          elsif tap_wrfull = '0' and tap_loaded = '1' and drambusy = '0' then
            tap_rd <= '1';
            tap_cycle <= '1';
          end if;
        end if;

        end if; --tap_reset
  end if; -- rising_edge
end process;

c1530_inst: entity work.c1530
port map (
  clk32           => clk32,
  restart_tape    => tap_reset,
  wav_mode        => '0',
  tap_version     => tap_version,
  host_tap_in     => sdram_out,
  host_tap_wrreq  => tap_wrreq(0),
  tap_fifo_wrfull => tap_wrfull,
  tap_fifo_error  => cass_finish,
  cass_read       => cass_read,
  cass_write      => cass_write,
  cass_motor      => cass_motor,
  cass_sense      => cass_sense,
  cass_run        => cass_run,
  osd_play_stop_toggle => tap_autoplay,
  ear_input       => '0'
);

-- UART_RX synchronizer
process(clk32)
begin
    if rising_edge(clk32) then
      uart_rxD(0) <= uart_rx;
      uart_rxD(1) <= uart_rxD(0);
      if uart_rxD(0) = uart_rxD(1) then
        uart_rx_filtered <= uart_rxD(1);
      end if;
    end if;
end process;

-- connect user port RS232
process (all)
begin
  -- CB1_i RXD
  -- PB0_i RXD in
  -- PB1_o RTS out
  -- PB2_o DTR out
  -- PB3_i RI in
  -- PB4_i DCD in
  -- PB5
  -- PB6_i CTS in
  -- PB7_i DSR in
  -- CB2_o TXD
  user_port_in <= user_port_out;
  --user_port_cb1_in <= user_port_cb1_out;
  user_port_cb2_in <= user_port_cb2_out;

  uart_tx <= user_port_cb2_out;
  user_port_cb1_in <= uart_rx_filtered;
  user_port_in(0) <= uart_rx_filtered;
  -- Zeromodem
  user_port_in(6) <= not user_port_out(1);  -- RTS > CTS
  user_port_in(4) <= not user_port_out(2);  -- DTR > DCD
  user_port_in(7) <= not user_port_out(2);  -- DTR > DSR
end process;

end Behavioral_top;
