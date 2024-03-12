-------------------------------------------------------------------------
--  VIC20 Top level for Tang Nano
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

    -- SPI interface Sipeed M0S Dock external BL616 uC
    m0s         : inout std_logic_vector(5 downto 0);
    --
    tmds_clk_n  : out std_logic;
    tmds_clk_p  : out std_logic;
    tmds_d_n    : out std_logic_vector( 2 downto 0);
    tmds_d_p    : out std_logic_vector( 2 downto 0);
    -- sd interface
    sd_clk      : out std_logic;
    sd_cmd      : inout std_logic;
    sd_dat      : inout std_logic_vector(3 downto 0);
    ws2812      : out std_logic;
    -- "Magic" port names that the gowin compiler connects to the on-chip SDRAM
    O_sdram_clk  : out std_logic;
    O_sdram_cke  : out std_logic;
    O_sdram_cs_n : out std_logic;            -- chip select
    O_sdram_cas_n : out std_logic;           -- columns address select
    O_sdram_ras_n : out std_logic;           -- row address select
    O_sdram_wen_n : out std_logic;           -- write enable
    IO_sdram_dq  : inout std_logic_vector(31 downto 0); -- 32 bit bidirectional data bus
    O_sdram_addr : out std_logic_vector(10 downto 0);  -- 11 bit multiplexed address bus
    O_sdram_ba   : out std_logic_vector(1 downto 0);     -- two banks
    O_sdram_dqm  : out std_logic_vector(3 downto 0);     -- 32/4
    -- Gamepad
    joystick_clk  : out std_logic;
    joystick_mosi : out std_logic;
    joystick_miso : inout std_logic; -- midi_out
    joystick_cs   : inout std_logic; -- midi_in
    -- spi flash interface
    mspi_cs       : out std_logic;
    mspi_clk      : out std_logic;
    mspi_di       : inout std_logic;
    mspi_hold     : inout std_logic;
    mspi_wp       : inout std_logic;
    mspi_do       : inout std_logic
    );
end;

architecture Behavioral_top of VIC20_TOP is

signal clk64          : std_logic;
signal clk32          : std_logic;
signal pll_locked     : std_logic;
signal clk_pixel_x10  : std_logic;
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
signal idle         : std_logic;
signal dram_addr    : std_logic_vector(22 downto 0);
signal dram_addr_s  : std_logic_vector(22 downto 0);
signal ram_scramble : std_logic_vector(1 downto 0);
signal ram_ready    : std_logic;
signal cb_D         : std_logic;
signal addr         : std_logic_vector(22 downto 0);
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
signal joyDigital   : std_logic_vector(6 downto 0);
signal joyNumpad    : std_logic_vector(6 downto 0);
signal joyMouse     : std_logic_vector(6 downto 0);
signal joyPaddle    : std_logic_vector(6 downto 0); 
signal joyPaddle2   : std_logic_vector(6 downto 0); 
signal numpad       : std_logic_vector(7 downto 0);
signal joyDS2       : std_logic_vector(6 downto 0);
-- joystick interface
signal joyA        : std_logic_vector(6 downto 0);
signal joyB        : std_logic_vector(6 downto 0);
signal port_1_sel  : std_logic_vector(2 downto 0);
signal port_2_sel  : std_logic_vector(2 downto 0);
-- mouse / paddle
signal pot1        : std_logic_vector(7 downto 0);
signal pot2        : std_logic_vector(7 downto 0);
signal pot3        : std_logic_vector(7 downto 0);
signal pot4        : std_logic_vector(7 downto 0);
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
signal sd_img_mounted : std_logic_vector(3 downto 0);
signal sd_img_mounted_d : std_logic;
signal sd_rd          : std_logic_vector(3 downto 0);
signal sd_wr          : std_logic_vector(3 downto 0);
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
signal sid_filter     : std_logic;
signal turbo_mode     : std_logic_vector(1 downto 0);
signal turbo_speed    : std_logic_vector(1 downto 0);
signal flash_ready    : std_logic;
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
signal joystick_cs_i   : std_logic;
signal joystick_miso_i : std_logic;
signal frz_hbl         : std_logic;
signal frz_vbl         : std_logic;
signal system_pause    : std_logic;
signal paddle_1        : std_logic_vector(7 downto 0);
signal paddle_2        : std_logic_vector(7 downto 0);
signal paddle_3        : std_logic_vector(7 downto 0);
signal paddle_4        : std_logic_vector(7 downto 0);
signal key_r1          : std_logic;
signal key_r2          : std_logic;
signal key_l1          : std_logic;
signal key_l2          : std_logic;
signal key_triangle    : std_logic;
signal key_square      : std_logic;
signal key_circle      : std_logic;
signal key_cross       : std_logic;
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
signal i_center        : std_logic_vector(1 downto 0);

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
        DEVICE: in string := "GW2A-18";
        DYN_IDIV_SEL: in string := "false";
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
  m0s(5)      <= 'Z';

joystick_cs     <= joystick_cs_i;
joystick_miso_i <= joystick_miso;

-- https://store.curiousinventor.com/guides/PS2/
-- https://hackaday.io/project/170365-blueretro/log/186471-playstation-playstation-2-spi-interface

gamepad: entity work.dualshock2
    port map (
    clk           => clk32,
    rst           => system_reset(0) and not pll_locked,
    vsync         => vsync,
    ds2_dat       => joystick_miso_i,
    ds2_cmd       => joystick_mosi,
    ds2_att       => joystick_cs_i,
    ds2_clk       => joystick_clk,
    ds2_ack       => '0',
    stick_lx      => paddle_1,
    stick_ly      => paddle_2,
    stick_rx      => paddle_3,
    stick_ry      => paddle_4,
    key_up        => open,
    key_down      => open,
    key_left      => open,
    key_right     => open,
    key_l1        => key_l1,
    key_l2        => key_l2,
    key_r1        => key_r1,
    key_r2        => key_r2,
    key_triangle  => key_triangle,
    key_square    => key_square,
    key_circle    => key_circle,
    key_cross     => key_cross,
    key_start     => open,
    key_select    => open,
    key_lstick    => open,
    key_rstick    => open,
    debug1        => open,
    debug2        => open
    );

led_ws2812: entity work.ws2812
  port map
  (
   clk    => clk32,
   color  => ws2812_color,
   data   => ws2812
  );

	process(clk32, disk_reset)
    variable reset_cnt : integer range 0 to 2147483647;
    begin
		if disk_reset = '1' then
      disk_chg_trg <= '0';
			reset_cnt := 64000000;
      elsif rising_edge(clk32) then
			if reset_cnt /= 0 then
				reset_cnt := reset_cnt - 1;
			end if;
		end if;

  if reset_cnt = 0 then
    disk_chg_trg <= '1';
  else 
    disk_chg_trg <= '0';
  end if;
end process;

disk_reset <= c1541_osd_reset or not pll_locked or c1541_reset or not flash_lock;

-- rising edge sd_change triggers detection of new disk
process(clk32, pll_locked)
  begin
  if pll_locked = '0' then
    sd_change <= '0';
    disk_g64 <= '0';
    disk_g64_d <= '0';
    sd_img_size_d <= (others => '0');
    sd_img_mounted_d <= '0';
    disk_chg_trg_d <= '0';
    elsif rising_edge(clk32) then
      sd_img_size_d <= sd_img_size;
      sd_img_mounted_d <= sd_img_mounted(0);
      disk_chg_trg_d <= disk_chg_trg;
      disk_g64_d <= disk_g64;
      if (sd_img_size /= sd_img_size_d) or (disk_chg_trg_d = '0' and disk_chg_trg = '1') then
          sd_change  <= '1';
          else
          sd_change  <= '0';
      if sd_img_size >= 333744 then  -- g64 disk selected
        disk_g64 <= '1';
      else
        disk_g64 <= '0';
      end if;
      if (disk_g64 /= disk_g64_d) then
        c1541_reset  <= '1'; -- reset needed after G64 change
        else
        c1541_reset  <= '0';
        end if;
      end if;
  end if;
end process;

c1541_sd_inst : entity work.c1541_sd
port map
 (
    clk32         => clk32,
    reset         => (not flash_ready) or disk_reset,
    pause         => '0',
    ce            => '0',

    disk_num      => (others =>'0'),
    disk_change   => sd_change, 
    disk_mount    => '1',
    disk_readonly => system_floppy_wprot(0),
    disk_g64      => disk_g64,

    iec_atn_i     => iec_atn_o,
    iec_data_i    => iec_data_o,
    iec_clk_i     => iec_clk_o,

    iec_atn_o     => iec_atn_i,
    iec_data_o    => iec_data_i,
    iec_clk_o     => iec_clk_i,

    -- Userport parallel bus to 1541 disk
    par_data_i    => "11111111",
    par_stb_i     => '1',
    par_data_o    => open,
    par_stb_o     => open,

    sd_lba        => sd_lba,
    sd_rd         => sd_rd(0),
    sd_wr         => sd_wr(0),
    sd_ack        => sd_busy,

    sd_buff_addr  => sd_byte_index,
    sd_buff_dout  => sd_rd_data,
    sd_buff_din   => sd_wr_data,
    sd_buff_wr    => sd_rd_byte_strobe,

    led           => led1541,
    ext_en        => ext_en,
    c1541rom_cs   => c1541rom_cs,
    c1541rom_addr => c1541rom_addr,
    c1541rom_data => c1541rom_data
);
ext_en <= '1' when dos_sel(0) = '0' else '0'; -- dolphindos, speeddos
sd_rd(3 downto 1) <= "000";
sd_wr(3 downto 1) <= "000";
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

      audio_l => vic_audio & "000000000000", 
      audio_r => vic_audio & "000000000000",
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

-- system_reset[1] indicates whether a reset is requested. This
-- can either be triggered implicitely by the user changing hardware
-- specs or explicitely via an OSD menu entry.
-- A cold boot means that the ram contents becomes invalid. We achieve this
-- by scrambling the RAM address space a little bit on every rising edge
-- of system_reset[1] 
process(clk32)
begin
  if rising_edge(clk32) then
    cb_D <= system_reset(1);
      if system_reset(1) = '1' and cb_D = '0' then  --rising edge of reset trigger
        ram_scramble <= ram_scramble + 1;
      end if;
    end if;
end process;

-- RAM is scrambled by xor'ing adress lines 2 and 3 with the scramble bits
dram_addr_s <= cart_addr(22 downto 4) & (cart_addr(3 downto 2) xor ram_scramble) & cart_addr(1 downto 0);

addr <= dram_addr_s;
cs <= cart_ce;
we <= cart_we;
din <= std_logic_vector(c64_data_out);
sdram_data <= unsigned(dout);

dram_inst: entity work.sdram8
   port map(
    -- SDRAM side interface
    sd_clk    => O_sdram_clk,   -- sd clock
    sd_cke    => O_sdram_cke,   -- clock enable
    sd_data   => IO_sdram_dq,   -- 32 bit bidirectional data bus
    sd_addr   => O_sdram_addr,  -- 11 bit multiplexed address bus
    sd_dqm    => O_sdram_dqm,   -- two byte masks
    sd_ba     => O_sdram_ba,    -- two banks
    sd_cs     => O_sdram_cs_n,  -- a single chip select
    sd_we     => O_sdram_wen_n, -- write enable
    sd_ras    => O_sdram_ras_n, -- row address select
    sd_cas    => O_sdram_cas_n, -- columns address select
    -- cpu/chipset interface
    clk       => clk32,         -- sdram is accessed at 32MHz
    reset_n   => pll_locked,    -- init signal after FPGA config to initialize RAM
    ready     => ram_ready,     -- ram is ready and has been initialized
    refresh   => idle,          -- chipset requests a refresh cycle
    din       => din,           -- data input from chipset/cpu
    dout      => dout,
    addr      => addr,          -- 23 bit word address
    ds        => "00",
    cs        => cs,            -- cpu/chipset requests read/wrie
    we        => we             -- cpu/chipset requests write
  );

-- Clock tree and all frequencies in Hz
-- TN20k VIC20
--                  PAL  / NTSC  
-- pll         357750000  329400000
-- serdes      178875000  164700000
-- dram         71550000   65880000
-- core /pixel  35775000   32940000
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
            DEVICE => "GW2AR-18C",
            DYN_IDIV_SEL => "true",
            IDIV_SEL => 3,
            DYN_FBDIV_SEL => "true",
            FBDIV_SEL => 52,
            DYN_ODIV_SEL => "false",
            ODIV_SEL => 2,
            PSDA_SEL => "0110",   
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
            CLKOUTP  => open,
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

-- 64.125Mhz for flash controller c1541 ROM
flashclock: rPLL
        generic map (
          FCLKIN => "27",
          DEVICE => "GW2AR-18C",
          DYN_IDIV_SEL => "false",
          IDIV_SEL => 7,
          DYN_FBDIV_SEL => "false",
          FBDIV_SEL => 18,
          DYN_ODIV_SEL => "false",
          ODIV_SEL => 8,
          PSDA_SEL => "0110", -- phase shift 135°
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
leds(2 downto 1) <= "00";
leds(3) <= spi_ext;
leds(5 downto 4) <= system_leds;

-- 4 3 2 1 0 digital c64
joyDS2     <=    ("00" & (key_l1 or key_r1) & key_circle & key_square & key_cross & key_triangle);
joyDigital <= not("11" & io(0) & io(4) & io(3) & io(2) & io(1));
joyUsb1    <=    ("00" & joystick1(4) & joystick1(0) & joystick1(1) & joystick1(2) & joystick1(3));
joyUsb2    <=    ("00" & joystick2(4) & joystick2(0) & joystick2(1) & joystick2(2) & joystick2(3));
joyNumpad  <=     "00" & numpad(4) & numpad(0) & numpad(1) & numpad(2) & numpad(3);
joyMouse   <=     "00" & mouse_btns(0) & "000" & mouse_btns(1);
joyPaddle  <=    ("00" & '0' & key_l1 & key_l2 & "00"); -- bound to physical paddle position DS2
joyPaddle2 <=    ("00" & '0' & key_r1 & key_r2 & "00");

-- send external DB9 joystick port to µC
db9_joy <= not('1' & io(0), io(2), io(1), io(4), io(3));

process(clk32)
begin
	if rising_edge(clk32) then
    case port_1_sel is
      when "000"  => joyA <= joyDigital;
      when "001"  => joyA <= joyUsb1;
      when "010"  => joyA <= joyUsb2;
      when "011"  => joyA <= joyNumpad;
      when "100"  => joyA <= joyDS2;
      when "101"  => joyA <= joyMouse;
      when "110"  => joyA <= joyPaddle;
      when "111"  => joyA <= (others => '0');
      when others => null;
    end case;
  end if;
end process;

process(clk32)
begin
	if rising_edge(clk32) then
    case port_2_sel is
      when "000"  => joyB <= joyDigital;
      when "001"  => joyB <= joyUsb1;
      when "010"  => joyB <= joyUsb2;
      when "011"  => joyB <= joyNumpad;
      when "100"  => joyB <= joyDS2;
      when "101"  => joyB <= joyMouse;
      when "110"  => joyB <= joyPaddle2;
      when "111"  => joyB <= (others => '0');
      when others => null;
      end case;
  end if;
end process;

-- paddle pins - mouse
pot1 <= not paddle_1 when port_1_sel = "110" else ('0' & std_logic_vector(mouse_x_pos(6 downto 1)) & '0');
pot2 <= not paddle_2 when port_1_sel = "110" else ('0' & std_logic_vector(mouse_y_pos(6 downto 1)) & '0');
pot3 <= not paddle_3 when port_2_sel = "110" else ('0' & std_logic_vector(mouse_x_pos(6 downto 1)) & '0');
pot4 <= not paddle_4 when port_2_sel = "110" else ('0' & std_logic_vector(mouse_y_pos(6 downto 1)) & '0');

process(clk32, system_reset(0))
 variable mov_x: signed(6 downto 0);
 variable mov_y: signed(6 downto 0);
begin
  if  system_reset(0) = '1' then
    mouse_x_pos <= (others => '0');
    mouse_y_pos <= (others => '0');
  elsif rising_edge(clk32) then
    if mouse_strobe = '1' then
     -- due to limited resolution on the c64 side, limit the mouse movement speed
     if mouse_x > 40 then mov_x:="0101000"; elsif mouse_x < -40 then mov_x:= "1011000"; else mov_x := mouse_x(6 downto 0); end if;
     if mouse_y > 40 then mov_y:="0101000"; elsif mouse_y < -40 then mov_y:= "1011000"; else mov_y := mouse_y(6 downto 0); end if;
     mouse_x_pos <= mouse_x_pos - mov_x;
     mouse_y_pos <= mouse_y_pos + mov_y;
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
  mouse_strobe    => mouse_strobe
 );

 port_2_sel <= "000";

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
  system_i_ram_ext0   => i_ram_ext(0),
  system_i_ram_ext1   => i_ram_ext(1),
  system_i_ram_ext2   => i_ram_ext(2),
  system_i_ram_ext3   => i_ram_ext(3),
  system_i_ram_ext4   => i_ram_ext(4),
  system_i_center     => i_center,
  system_crt_write    => open,

  int_out_n           => m0s(4),
  int_in              => std_logic_vector(unsigned'("0000" & sdc_int & '0' & hid_int & '0')),
  int_ack             => int_ack,

  buttons             => std_logic_vector(unsigned'(reset & user)), -- S0 and S1 buttons on Tang Nano 20k
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

-- c1541 ROM's SPI Flash, offset in spi flash $200000
flash_inst: entity work.flash 
port map(
    clk       => flash_clk,
    resetn    => flash_lock,
    ready     => flash_ready,
    busy      => open,
    address   => ("0010" & "000" & dos_sel & c1541rom_addr),
    cs        => c1541rom_cs,
    dout      => c1541rom_data,
    mspi_cs   => mspi_cs,
    mspi_di   => mspi_di,
    mspi_hold => mspi_hold,
    mspi_wp   => mspi_wp,
    mspi_do   => mspi_do
);

vic_inst: entity work.VIC20
	port map(
		--
		i_sysclk      => clk32,
		i_sysclk_en   => v20_en,
		i_reset       => system_reset(0) or not pll_locked,
		o_p2h         => open,

		-- serial bus pins
		atn_o         => iec_atn_o,
		clk_o         => iec_clk_o,
		clk_i         => iec_clk_i,
		data_o        => iec_data_o,
		data_i        => iec_data_i,
		--
		i_joy         => not joyA(3 downto 0), -- 0 up, 1 down, 2 left,  3 right
		i_fire        => not joyA(4),          -- all low active
		i_potx        => pot1,
		i_poty        => pot2,

		--
		i_ram_ext_ro  => (others => '0'), -- read-only region if set
		i_ram_ext     => i_ram_ext,       -- at $A000(8k),$6000(8k),$4000(8k),$2000(8k),$0400(3k)
		--
		i_extmem_en   => '0',
		o_extmem_sel  => open,
		o_extmem_r_wn => open,
		o_extmem_addr => open,
		i_extmem_data => (others => '0'),
		o_extmem_data => open,
		o_io2_sel     => open,
		o_io3_sel     => open,
		o_blk123_sel  => open,
		o_blk5_sel    => open,
		o_ram123_sel  => open,
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

		cass_write    => open,
		cass_read     => '1',
		cass_motor    => open,
		cass_sw       => '1',

		--configures "embedded" core memory
		rom_std       => '1',
		conf_clk      => clk32,
		conf_wr       => '0',
		conf_ai       => (others => '0'),
		conf_di       => (others => '0')
	);

end Behavioral_top;
