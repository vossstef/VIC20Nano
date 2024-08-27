--
-- A simulation model of VIC20 hardware
--
-- All rights reserved
-- (c) copyright 2003-2009 by MikeJ (Mike Johnson)
-- http://www.FPGAArcade.com - mikej <at> fpgaarcade <dot> com
-- (c) copyright 2011...2015 by WoS (Wolfgang Scherr)
-- http://www.pin4.at - WoS <at> pin4 <dot> at
--
-- $Id: vic20.vhd 2205 2017-08-04 19:28:32Z mikej $
--
----------------------------------------------------------------------------
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission; any commercial use is forbidden as well.
--
-- This code must be run on Replay hardware only.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email vic20@fpgaarcade.com
--

library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity VIC20 is
	port (
		--
		i_sysclk     : in  std_logic;  -- comes from CLK_A via DCM (divided by 4)
		i_sysclk_en  : in  std_logic;  -- 8.867236 MHz enable signal
		i_reset      : in  std_logic;
		o_p2h        : out std_logic;

		-- serial bus pins
		atn_o        : out std_logic; -- open drain
		clk_o        : out std_logic; -- open drain
		clk_i        : in  std_logic;
		data_o       : out std_logic; -- open drain
		data_i       : in  std_logic;
		--
		i_joy        : in  std_logic_vector(3 downto 0); -- 0 up, 1 down, 2 left,  3 right
		i_fire       : in  std_logic;                    -- all low active
		i_potx       : in  std_logic_vector(7 downto 0);
		i_poty       : in  std_logic_vector(7 downto 0);

		--
		i_ram_ext_ro : in  std_logic_vector(4 downto 0); -- read-only region if set
		i_ram_ext    : in  std_logic_vector(4 downto 0); -- at $A000(8k),$6000(8k),$4000(8k),$2000(8k),$0400(3k)
		--
		i_extmem_en  : in  std_logic;
		o_extmem_sel : out std_logic;
		o_extmem_r_wn: out std_logic;
		o_extmem_addr: out std_logic_vector(15 downto 0);
		i_extmem_data: in  std_logic_vector(7 downto 0);
		o_extmem_data: out std_logic_vector(7 downto 0);
		o_io2_sel    : out std_logic;
		o_io3_sel    : out std_logic;
		o_blk123_sel : out std_logic;
		o_blk5_sel   : out std_logic;
		o_ram123_sel : out std_logic;
		--
		o_ce_pix     : out std_logic;
		o_video_r    : out std_logic_vector(3 downto 0);
		o_video_g    : out std_logic_vector(3 downto 0);
		o_video_b    : out std_logic_vector(3 downto 0);
		o_hsync      : out std_logic;
		o_vsync      : out std_logic;
		o_hblank     : out std_logic;
		o_vblank     : out std_logic;
		i_center     : in  std_logic_vector(1 downto 0);
		i_pal        : in  std_logic;
		i_wide       : in  std_logic;
		--
		ps2_key      : in  std_logic_vector(10 downto 0);
  	keyboard_matrix_out : out  std_logic_vector(7 downto 0);
	  keyboard_matrix_in  :  in  std_logic_vector(7 downto 0);
		tape_play    : out std_logic;
		--
		o_audio      : out std_logic_vector(5 downto 0);

		cass_write   : out std_logic;
		cass_read    : in  std_logic;
		cass_motor   : out std_logic;
		cass_sw      : in  std_logic;

		--configures "embedded" core memory
		rom_std      : in  std_logic;
		conf_clk     : in  std_logic;
		conf_wr      : in  std_logic;
		conf_ai      : in  std_logic_vector(15 downto 0);
		conf_di      : in  std_logic_vector(7 downto 0);

    -- external flash memory
    flash_clk    : in  std_logic;
    flash_lock   : in  std_logic;
    mspi_cs      : out  std_logic;
    mspi_di      : inout std_logic;
    mspi_do      : inout std_logic
	);
end;

-- PAL version runs with a 8,867,236 Hz Quartz which is divided by two
--

architecture RTL of VIC20 is

signal reset_l            : std_logic;
signal ena_4              : std_logic;
signal reset_l_sampled    : std_logic;
-- cpu
signal c_ena              : std_logic;
signal c_addr             : std_logic_vector(23 downto 0);
signal c_din              : std_logic_vector(7 downto 0);
    signal c_din_s            : std_logic_vector(7 downto 0);
signal c_dout             : std_logic_vector(7 downto 0);
signal c_rw_l             : std_logic;
signal c_irq_l            : std_logic;
signal c_nmi_l            : std_logic;
--
signal io_sel_l           : std_logic_vector(3 downto 0);
signal blk_sel_l          : std_logic_vector(7 downto 0);
signal ram_sel_l          : std_logic_vector(7 downto 0);

-- vic
signal vic_addr           : std_logic_vector(13 downto 0);
signal vic_oe_l           : std_logic;
signal vic_dout           : std_logic_vector( 7 downto 0);
signal vic_din            : std_logic_vector(11 downto 0);
signal p2_h               : std_logic;
signal p2_h_rise          : std_logic;
signal p2_h_fall          : std_logic;
signal ena_1mhz           : std_logic;
signal via1_dout          : std_logic_vector( 7 downto 0);
signal via2_dout          : std_logic_vector( 7 downto 0);

signal vic_audio          : std_logic_vector( 5 downto 0);
signal lp_output          : std_logic_vector(15 downto 0);
signal lp_filtered        : std_logic_vector(15 downto 0);

-- video system
signal v_addr             : std_logic_vector(13 downto 0);
signal v_data             : std_logic_vector( 7 downto 0);
signal v_data_oe_l        : std_logic;
signal v_data_read_mux    : std_logic_vector( 7 downto 0);
signal v_data_read_muxr   : std_logic_vector( 7 downto 0);
signal v_rw_l             : std_logic;
signal col_ram_sel_l      : std_logic;

-- ram
signal ram0_dout          : std_logic_vector(7 downto 0);
signal ram45_dout         : std_logic_vector(7 downto 0);
signal ram67_dout         : std_logic_vector(7 downto 0);
signal ramex0_dout        : std_logic_vector(7 downto 0);
signal ramex1_dout        : std_logic_vector(7 downto 0);
signal ramex2_dout        : std_logic_vector(7 downto 0);
signal ramex3_dout        : std_logic_vector(7 downto 0);
signal cart_dout          : std_logic_vector(7 downto 0);
--
signal col_ram_dout       : std_logic_vector(3 downto 0);

-- rom
signal char_rom_dout      : std_logic_vector(7 downto 0);
signal basic_rom_dout     : std_logic_vector(7 downto 0);
signal pal_rom_dout_dl    : std_logic_vector(7 downto 0);
signal ntsc_rom_dout_dl   : std_logic_vector(7 downto 0);
signal pal_rom_dout_o     : std_logic_vector(7 downto 0);
signal ntsc_rom_dout_o    : std_logic_vector(7 downto 0);

-- expansion
signal expansion_din      : std_logic_vector(7 downto 0);
signal expansion_nmi_l    : std_logic;
signal expansion_irq_l    : std_logic;
signal extmem             : std_logic;

-- VIAs
signal via1_nmi           : std_logic;
signal via1_pa_in         : std_logic_vector(7 downto 0);
signal via1_pa_out        : std_logic_vector(7 downto 0);

signal via2_irq           : std_logic;

signal keybd_col_out      : std_logic_vector(7 downto 0);
signal keybd_col_oe       : std_logic_vector(7 downto 0);
signal keybd_col_out_s    : std_logic_vector(7 downto 0);
signal keybd_col_in       : std_logic_vector(7 downto 0);
signal keybd_row_in       : std_logic_vector(7 downto 0);
signal keybd_row_out      : std_logic_vector(7 downto 0);
signal keybd_row_oe       : std_logic_vector(7 downto 0);
signal keybd_row_out_s    : std_logic_vector(7 downto 0);
signal keybd_restore      : std_logic;

signal joy                : std_logic_vector(3 downto 0);
signal light_pen          : std_logic;

signal serial_srq_in      : std_logic;
signal serial_atn_out_l   : std_logic;
signal serial_atn_in      : std_logic; -- the vic does not listen to atn_in
signal serial_clk_out_l   : std_logic;
signal serial_clk_in      : std_logic;
signal serial_data_out_l  : std_logic;
signal serial_data_in     : std_logic;

-- user port
signal user_port_cb1_in   : std_logic;
signal user_port_cb2_in   : std_logic;
signal user_port_in       : std_logic_vector(7 downto 0);
-- misc
signal sw_reg             : std_logic_vector(3 downto 0);

signal video_r            : std_logic_vector(3 downto 0);
signal video_g            : std_logic_vector(3 downto 0);
signal video_b            : std_logic_vector(3 downto 0);
signal hsync              : std_logic;
signal vsync              : std_logic;

signal reset_key          : std_logic;
signal reset              : std_logic;

signal iec_data_d1        : std_logic;
signal iec_clk_d1         : std_logic;
signal iec_data_d2        : std_logic;
signal iec_clk_d2         : std_logic;
signal iec_data           : std_logic;
signal iec_clk            : std_logic;

signal motor              : std_logic;
signal conf_en_s          : std_logic;

signal flash              : std_logic_vector(7 downto 0);

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

begin

	o_p2h <= p2_h;

	process (i_sysclk) begin
		if rising_edge(i_sysclk) then
			iec_data_d1<=data_i;
			iec_data_d2<=iec_data_d1;
			iec_data   <=iec_data_d2;

			iec_clk_d1 <=clk_i;
			iec_clk_d2 <=iec_clk_d1;
			iec_clk    <=iec_clk_d2;
		end if;
	end process;

  o_ce_pix <= ena_4;

  expansion_nmi_l <= '1';
  expansion_irq_l <= '1';

  -- user port
  user_port_cb1_in <= '0';
  user_port_cb2_in <= '0';
  user_port_in <= x"00";

  -- tape
  cass_motor <= motor;

  -- serial
  serial_srq_in <= '1';
  serial_clk_in <= not serial_clk_out_l and iec_clk;
  serial_data_in <= not serial_data_out_l and iec_data;
  serial_atn_in <= not serial_atn_out_l;
  atn_o <= not serial_atn_out_l;
  clk_o <= not serial_clk_out_l;
  data_o <= not serial_data_out_l;

  -- joy
  joy <= i_joy;        -- 0 up, 1 down, 2 left,  3 right
  light_pen <= i_fire; -- also used for fire button

  reset <= (i_reset or reset_key);
  reset_l <= not reset;

  u_clocks : entity work.VIC20_CLOCKS
    port map (
      I_SYSCLK          => i_sysclk,
      I_SYSCLK_EN       => i_sysclk_en,
      I_RESET_L         => reset_l,
      --
      O_ENA             => ena_4,
      O_RESET_L         => reset_l_sampled
      );

  c_ena <= ena_1mhz and ena_4; -- clk ena
  c_din_s <= c_dout when c_rw_l = '0' else c_din;

  cpu : entity work.T65
      port map (
          Mode    => "00",
          Res_n   => reset_l_sampled,
          Enable  => c_ena,
          Clk     => i_sysclk,
          Rdy     => '1',
          Abort_n => '1',
          IRQ_n   => c_irq_l,
          NMI_n   => c_nmi_l,
          SO_n    => '1',
          R_W_n   => c_rw_l,
          Sync    => open,
          EF      => open,
          MF      => open,
          XF      => open,
          ML_n    => open,
          VP_n    => open,
          VDA     => open,
          VPA     => open,
          A       => c_addr,
          DI      => c_din_s,
          DO      => c_dout
      );

  vic : entity work.M6561
    port map (
      I_CLK           => i_sysclk,
      I_ENA_4         => ena_4,
      I_RESET_L       => reset_l,
      O_ENA_1MHZ      => ena_1mhz,
      O_P2_H          => p2_h,
      O_P2_H_RISE     => p2_h_rise,
      O_P2_H_FALL     => p2_h_fall,

      I_RW_L          => v_rw_l,

      I_ADDR          => v_addr(13 downto 0),
      O_ADDR          => vic_addr(13 downto 0),

      I_DATA          => vic_din,
      O_DATA          => vic_dout,
      O_DATA_OE_L     => vic_oe_l,
      --
      O_AUDIO         => O_AUDIO,

      O_VIDEO_R       => video_r,
      O_VIDEO_G       => video_g,
      O_VIDEO_B       => video_b,

      O_HSYNC         => hsync,
      O_VSYNC         => vsync,
      O_COMP_SYNC_L   => open,
		O_HBLANK        => o_hblank,
		O_VBLANK        => o_vblank,
      --
		I_CENTER        => I_CENTER,
		I_PAL           => i_pal,
		I_WIDE          => i_wide,
      --
      I_LIGHT_PEN     => light_pen,
      I_POTX          => i_potx,
      I_POTY          => i_poty
      );

  via1: entity work.via6522
  port map (
    clock       => i_sysclk,
    rising      => p2_h_rise,
    falling     => p2_h_fall,
    reset       => not reset_l_sampled,

    addr        => c_addr(3 downto 0),
    wen         => c_addr(4) and not io_sel_l(0) and not c_rw_l,
    ren         => c_addr(4) and not io_sel_l(0) and c_rw_l,
    data_in     => v_data(7 downto 0),
    data_out    => via1_dout,

    -- pio --
    port_a_o    => via1_pa_out,
    port_a_i    => via1_pa_in,
    port_b_i    => user_port_in,

    -- handshake pins
    ca1_i       => keybd_restore,

    ca2_o       => motor,
    ca2_i       => motor,

    cb1_i       => user_port_cb1_in,
    cb2_i       => user_port_cb2_in,

    irq         => via1_nmi
  );

  serial_atn_out_l <= via1_pa_out(7);
  via1_pa_in(7) <= serial_atn_in;
  via1_pa_in(6) <= cass_sw;
  via1_pa_in(5) <= light_pen;
  via1_pa_in(4) <= joy(2);
  via1_pa_in(3) <= joy(1);
  via1_pa_in(2) <= joy(0);
  via1_pa_in(1) <= serial_data_in;
  via1_pa_in(0) <= serial_clk_in;

  via2: entity work.via6522
  port map (
    clock       => i_sysclk,
    rising      => p2_h_rise,
    falling     => p2_h_fall,
    reset       => not reset_l_sampled,

    addr        => c_addr(3 downto 0),
    wen         => c_addr(5) and not io_sel_l(0) and not c_rw_l,
    ren         => c_addr(5) and not io_sel_l(0) and c_rw_l,
    data_in     => v_data(7 downto 0),
    data_out    => via2_dout,

		-- pio --
    port_a_o    => keybd_row_out,
    port_a_t    => keybd_row_oe,
    port_a_i    => keybd_row_in,

    port_b_o    => keybd_col_out,
    port_b_t    => keybd_col_oe,
    port_b_i    => (joy(3) and keybd_col_in(7)) & keybd_col_in(6 downto 0),

    -- handshake pins
    ca1_i       => cass_read,

    ca2_o       => serial_clk_out_l,
    ca2_i       => serial_clk_out_l,
    cb1_i       => serial_srq_in,
    cb2_o       => serial_data_out_l,
    cb2_i       => serial_data_out_l,

    irq         => via2_irq
  );

  cass_write <= keybd_col_out(3);
  keybd_row_out_s <= keybd_row_out or not keybd_row_oe;
  keybd_col_out_s <= keybd_col_out or not keybd_col_oe;

  reset_key <= '0';
  keybd_restore <= '0';
  tape_play <= '0';

keyboard_inst: entity work.vic20_keyboard
port map (
	clk => I_SYSCLK,
	reset => '0',

	keyboard_matrix_out => keyboard_matrix_out,
	keyboard_matrix_in => keyboard_matrix_in,

  pai => keybd_row_out_s,
  pao => keybd_row_in,
  pbi => keybd_col_out_s,
  pbo => keybd_col_in,

  shift_mod => "00",

	restore_key => open,
	tape_play => open,
	mod_key => open,
	backwardsReadingEnabled => '1'
);

  p_irq_resolve : process(expansion_irq_l, expansion_nmi_l,
                          via2_irq, via1_nmi)
  begin
    c_irq_l <= '1';
    if (expansion_irq_l = '0') or (via2_irq = '1') then
      c_irq_l <= '0';
    end if;

    c_nmi_l <= '1';
    if (expansion_nmi_l = '0') or (via1_nmi = '1') then
      c_nmi_l <= '0';
    end if;
  end process;

  --
  -- decode
  --
  p_io_addr_decode : process(c_addr)
  begin
    io_sel_l <= "1111";
    if (c_addr(15 downto 13) = "100") then -- blk4
      case c_addr(12 downto 10) is
        when "000" => io_sel_l <= "1111";
        when "001" => io_sel_l <= "1111";
        when "010" => io_sel_l <= "1111";
        when "011" => io_sel_l <= "1111";
        when "100" => io_sel_l <= "1110"; -- VIAs
        when "101" => io_sel_l <= "1101"; -- colour RAM
        when "110" => io_sel_l <= "1011";
        when "111" => io_sel_l <= "0111";
        when others => null;
      end case;
    end if;
  end process;

  p_blk_addr_decode : process(c_addr, blk_sel_l)
  begin
    blk_sel_l <= "11111111";
    case c_addr(15 downto 13) is
      when "000" => blk_sel_l <= "11111110";
      when "001" => blk_sel_l <= "11111101"; -- RAM ext.  ($2000...)
      when "010" => blk_sel_l <= "11111011"; -- RAM ext.  ($4000...)
      when "011" => blk_sel_l <= "11110111"; -- RAM ext.  ($6000...)
      when "100" => blk_sel_l <= "11101111";
      when "101" => blk_sel_l <= "11011111"; -- cartridge ($A000...)
      when "110" => blk_sel_l <= "10111111"; -- basic     ($C000...)
      when "111" => blk_sel_l <= "01111111"; -- kernal    ($E000...)
      when others => null;
    end case;
	 o_blk123_sel<=(not c_addr(15)) and (c_addr(14) or c_addr(13));
	 o_blk5_sel<=not blk_sel_l(5);
  end process;

  p_v_mux : process(c_addr, c_dout, c_rw_l, p2_h, vic_addr, v_data_read_mux,
                         blk_sel_l, io_sel_l)
  begin
    -- simplified data source mux
    if (p2_h = '0') then
      v_addr(13 downto 0) <= vic_addr(13 downto 0);
      v_data <= v_data_read_mux(7 downto 0);
      v_rw_l <= '1';
      col_ram_sel_l <= '0';
    else -- cpu
      v_addr(13 downto 0) <= blk_sel_l(4) & c_addr(12 downto 0);
      v_data <= c_dout;
      v_rw_l <= c_rw_l;
      col_ram_sel_l <= io_sel_l(1);
    end if;
  end process;

  p_ram_addr_decode : process(v_addr, blk_sel_l, p2_h, ram_sel_l)
  begin
    ram_sel_l <= "11111111";
    if ((p2_h = '1') and (blk_sel_l(0) = '0')) or -- cpu
       ((p2_h = '0') and (v_addr(13) = '1')) then
      case v_addr(12 downto 10) is
        when "000" => ram_sel_l <= "11111110"; -- RM        ($0000...)
        when "001" => ram_sel_l <= "11111101"; -- RAM ext.  ($0400...)
        when "010" => ram_sel_l <= "11111011"; -- RAM ext.  ($0800...)
        when "011" => ram_sel_l <= "11110111"; -- RAM ext.  ($0C00...)
        when "100" => ram_sel_l <= "11101111"; -- RAM       ($1000...)
        when "101" => ram_sel_l <= "11011111"; -- RAM       ($1400...)
        when "110" => ram_sel_l <= "10111111"; -- RAM       ($1800...)
        when "111" => ram_sel_l <= "01111111"; -- RAM       ($1C00...)
        when others => null;
      end case;
    end if;
	 o_ram123_sel<=not (ram_sel_l(1) and ram_sel_l(2) and ram_sel_l(3));
  end process;

  p_vic_din_mux : process(p2_h, col_ram_dout, v_data)
  begin
    if (p2_h = '0') then
      vic_din(11 downto 8) <= col_ram_dout;
    else
      vic_din(11 downto 8) <= v_data(3 downto 0);
    end if;

    vic_din(7 downto 0) <= v_data(7 downto 0);
  end process;

  p_v_read_mux : process(p2_h, col_ram_sel_l, ram_sel_l, vic_oe_l, v_addr,
                         col_ram_dout, ram0_dout, ram45_dout, ram67_dout,
                         vic_dout, char_rom_dout, v_data_read_muxr)
  begin
    -- simplified data read mux
    if (col_ram_sel_l = '0' and p2_h='1') then
      v_data_read_mux <= v_data_read_muxr(7 downto 4) & col_ram_dout;
      v_data_oe_l     <= '0';
    elsif (vic_oe_l = '0') then
      v_data_read_mux <= vic_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(0) = '0') then
      v_data_read_mux <= ram0_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(4) = '0') then
      v_data_read_mux <= ram45_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(5) = '0') then
      v_data_read_mux <= ram45_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(6) = '0') then
      v_data_read_mux <= ram67_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(7) = '0') then
      v_data_read_mux <= ram67_dout;
      v_data_oe_l     <= '0';
    elsif (v_addr(13 downto 12) = "00") then
      v_data_read_mux <= char_rom_dout;
      v_data_oe_l     <= '0';
    else
      -- take emulated floating bus
      v_data_read_mux <= v_data_read_muxr;
      v_data_oe_l <= '1';
    end if;
  end process;

  -- emulate floating bus with last value kept
  p_v_bus_hold : process
  begin
    wait until rising_edge(I_SYSCLK);
    if (ena_4 = '1') then
      v_data_read_muxr <= v_data_read_mux;
    end if;
  end process;

  p_cpu_read_mux : process(p2_h, c_addr, io_sel_l, ram_sel_l, blk_sel_l,
                           v_data_read_mux, via1_dout, via2_dout, v_data_oe_l,
                           basic_rom_dout, i_pal, pal_rom_dout_dl, ntsc_rom_dout_dl, pal_rom_dout_o, ntsc_rom_dout_o, i_extmem_data, extmem, i_extmem_en,
									I_RAM_EXT, ramex0_dout, ramex1_dout, ramex2_dout, ramex3_dout, cart_dout)
  begin

    if (p2_h = '0') then -- vic is on the bus
      c_din <= "00000000";
    elsif (io_sel_l(0) = '0') and (c_addr(4) = '1') then -- blk4
      c_din <= via1_dout;
    elsif (io_sel_l(0) = '0') and (c_addr(5) = '1') then -- blk5
      c_din <= via2_dout;
    elsif (blk_sel_l(6) = '0') then
      c_din <= basic_rom_dout;
    elsif (blk_sel_l(7) = '0' and i_pal = '1') then
      c_din <= pal_rom_dout_dl and pal_rom_dout_o;
    elsif (blk_sel_l(7) = '0') then
      c_din <= ntsc_rom_dout_dl and ntsc_rom_dout_o;
    elsif (v_data_oe_l = '0') then
      c_din <= v_data_read_mux;
    elsif (extmem = '1') then
      c_din <= i_extmem_data;
    elsif (i_extmem_en = '1') then
      c_din <= x"FF";
    elsif (ram_sel_l(1) and ram_sel_l(2) and ram_sel_l(3))='0' and I_RAM_EXT(0)='1' then
      c_din <= ramex0_dout;
    elsif blk_sel_l(1)='0' and I_RAM_EXT(1)='1' then
      c_din <= ramex1_dout;
    elsif blk_sel_l(2)='0' and I_RAM_EXT(2)='1' then
      c_din <= ramex2_dout;
    elsif blk_sel_l(3)='0' and I_RAM_EXT(3)='1' then		
      c_din <= ramex3_dout;
    elsif blk_sel_l(5)='0' and I_RAM_EXT(4)='1' then
      c_din <= cart_dout;
    else
      c_din <= x"FF";
    end if;
  end process;
  
  --
  -- extension memory - connected to external dram controller
  --
  -- at $C000-$FFFF according to I_EXTERNAL_ROM
  -- at $6000(8k),$4000(8k),$2000(8k),$0400(3k) according to I_RAM_EXT
  -- at $A000(8k) according to I_CART_EN
  extmem        <= i_extmem_en when (ram_sel_l(1) and ram_sel_l(2) and ram_sel_l(3))='0' and I_RAM_EXT(0)='1' else
                   i_extmem_en when blk_sel_l(1)='0' and I_RAM_EXT(1)='1' else
                   i_extmem_en when blk_sel_l(2)='0' and I_RAM_EXT(2)='1' else
                   i_extmem_en when blk_sel_l(3)='0' and I_RAM_EXT(3)='1' else
                   i_extmem_en when blk_sel_l(5)='0' and I_RAM_EXT(4)='1' else
                   i_extmem_en when io_sel_l(2)='0' else
                   i_extmem_en when io_sel_l(3)='0' else
                   '0';
  o_extmem_sel  <= extmem and p2_h;
  o_extmem_r_wn <= c_rw_l or not blk_sel_l(6) or not blk_sel_l(7) or ( not(blk_sel_l(5)) and i_ram_ext_ro(4) ); -- disable write if we emulate a ROM on $A000
  o_extmem_addr <= c_addr(15 downto 0);
  o_extmem_data <= c_dout;
  o_io2_sel <= not io_sel_l(2);
  o_io3_sel <= not io_sel_l(3);
  
  --
  -- main memory
  --
  rams0 : entity work.ram_conf_1024x8
    generic map (
      START_AI => "000000"   -- 0x0000
    )
    port map (
      CLK     => i_sysclk,
      CLK_EN  => ena_4,
      ENn     => ram_sel_l(0),
      WRn     => v_rw_l,
      ADDR    => v_addr(9 downto 0),
      DIN     => v_data,
      DOUT    => ram0_dout,

      CONF_CLK=> conf_clk,
      CONF_WR => conf_wr,
      CONF_AI => conf_ai,
      CONF_DI => conf_di
      );
  rams45 : entity work.ram_conf_2048x8
    generic map (
      START_AI => "00010"   -- 0x1000
    )
    port map (
      CLK     => i_sysclk,
      CLK_EN  => ena_4,
      EN1n    => ram_sel_l(4),
      EN2n    => ram_sel_l(5),
      WRn     => v_rw_l,
      ADDR    => v_addr(10 downto 0),
      DIN     => v_data,
      DOUT    => ram45_dout,

      CONF_CLK=> conf_clk,
      CONF_WR => conf_wr,
      CONF_AI => conf_ai,
      CONF_DI => conf_di
      );

  rams67 : entity work.ram_conf_2048x8
    generic map (
      START_AI => "00011"   -- 0x1800
    )
    port map (
      CLK     => i_sysclk,
      CLK_EN  => ena_4,
      EN1n    => ram_sel_l(6),
      EN2n    => ram_sel_l(7),
      WRn     => v_rw_l,
      ADDR    => v_addr(10 downto 0),
      DIN     => v_data,
      DOUT    => ram67_dout,

      CONF_CLK=> conf_clk,
      CONF_WR => conf_wr,
      CONF_AI => conf_ai,
      CONF_DI => conf_di
      );

  col_ram : entity work.ram_conf_1024x4
    generic map (
      START_AI => "100101"   -- 0x9400
   )
    port map (
      CLK     => i_sysclk,
      CLK_EN  => ena_4,
      ENn     => col_ram_sel_l,
      WRn     => v_rw_l,
      ADDR    => v_addr(9 downto 0),
      DIN     => v_data(3 downto 0),
      DOUT    => col_ram_dout,

      CONF_CLK=> conf_clk,
      CONF_WR => conf_wr,
      CONF_AI => conf_ai,
      CONF_DI => conf_di
      );


--  ramex0 : entity work.ram_conf_8192x8
--    generic map (
--      START_AI => "100101"   -- 0x9400
--   )
--    port map (
--      CLK     => i_sysclk,
--      CLK_EN  => ena_4,
--      ENn     => col_ram_sel_l,
--      WRn     => v_rw_l,
--      ADDR    => v_addr(9 downto 0),
--      DIN     => v_data(3 downto 0),
--      DOUT    => col_ram_dout,

--      CONF_CLK=> conf_clk,
--      CONF_WR => conf_wr,
--      CONF_AI => conf_ai,
--      CONF_DI => conf_di
--    );

--  ramex0 : entity work.ram_conf_8192x8
--    generic map (
--      START_AI  => "000"  -- 0x0000 (0x400-0xFFF)
--    )
--    port map (
--      CLK     => i_sysclk,
--      CLK_EN  => ena_4,
--      ENn     => (ram_sel_l(1) and ram_sel_l(2) and ram_sel_l(3)) or not I_RAM_EXT(0) or not p2_h,
--      WRn     => c_rw_l or i_ram_ext_ro(0),
--      ADDR    => c_addr(12 downto 0),
--      DIN     => c_dout,
--      DOUT    => ramex0_dout,

--      CONF_CLK=> conf_clk,
--      CONF_WR => conf_wr,
--      CONF_AI => conf_ai,
--      CONF_DI => conf_di
--    );

  ramex1 : entity work.ram_conf_8192x8
    generic map (
      START_AI  => "001"  -- 0x2000
    )
    port map (
      CLK     => i_sysclk,
      CLK_EN  => ena_4,
      ENn     => blk_sel_l(1) or not I_RAM_EXT(1) or not p2_h,
      WRn     => c_rw_l or i_ram_ext_ro(1),
      ADDR    => c_addr(12 downto 0),
      DIN     => c_dout,
      DOUT    => ramex1_dout,
      CONF_CLK=> conf_clk,
      CONF_WR => conf_wr,
      CONF_AI => conf_ai,
      CONF_DI => conf_di
    );

  ramex2 : entity work.ram_conf_8192x8
    generic map (
      START_AI  => "010"  -- 0x4000
    )
    port map (
      CLK     => i_sysclk,
      CLK_EN  => ena_4,
      ENn     => blk_sel_l(2) or not I_RAM_EXT(2) or not p2_h,
      WRn     => c_rw_l or i_ram_ext_ro(2),
      ADDR    => c_addr(12 downto 0),
      DIN     => c_dout,
      DOUT    => ramex2_dout,

      CONF_CLK=> conf_clk,
      CONF_WR => conf_wr,
      CONF_AI => conf_ai,
      CONF_DI => conf_di
    );

--  ramex3 : entity work.ram_conf_8192x8
--    generic map (
--      START_AI  => "011"  -- 0x6000
--    )
--    port map (
--      CLK     => i_sysclk,
--      CLK_EN  => ena_4,
--      ENn     => blk_sel_l(3) or not I_RAM_EXT(3) or not p2_h,
--      WRn     => c_rw_l or i_ram_ext_ro(3),
--      ADDR    => c_addr(12 downto 0),
--      DIN     => c_dout,
--      DOUT    => ramex3_dout,

--      CONF_CLK=> conf_clk,
--      CONF_WR => conf_wr,
--      CONF_AI => conf_ai,
--      CONF_DI => conf_di
--    );

  cart : entity work.ram_conf_8192x8
    generic map (
      START_AI  => "101"  -- 0xA000
    )
    port map (
      CLK     => i_sysclk,
      CLK_EN  => ena_4,
      ENn     => blk_sel_l(5) or not I_RAM_EXT(4) or not p2_h,
      WRn     => c_rw_l  or i_ram_ext_ro(4),
      ADDR    => c_addr(12 downto 0),
      DIN     => c_dout,
      DOUT    => cart_dout,

      CONF_CLK=> conf_clk,
      CONF_WR => conf_wr,
      CONF_AI => conf_ai,
      CONF_DI => conf_di
    );
	 
  --
  -- roms
  --

    -- VIC20's character ROM
  char_rom : entity work.Gowin_pROM_char
      port map (
          dout  => char_rom_dout,
          clk   => i_sysclk,
          oce   => '1',
          ce    => '1',
          reset => '0',
          ad    => v_addr(11 downto 0)
      );

-- future (Kernal) Basic and Character ROM's SPI Flash, offset in spi flash $000000
flash_inst: entity work.flash 
port map(
    clk       => flash_clk,
    resetn    => flash_lock,
    ready     => open,
    busy      => open,
    address   => 8x"00" & "00" & c_addr(13) & c_addr(12 downto 0),
    cs        => p2_h_fall,
    dout      => flash, -- basic_rom_dout,
    mspi_cs   => mspi_cs,
    mspi_di   => mspi_di,
    mspi_hold => open,
    mspi_wp   => open,
    mspi_do   => mspi_do
);

  basic_rom_dout <= flash;

  pal_rom_dout_o <= flash;
  pal_rom_dout_dl <= "11111111";
  ntsc_rom_dout_o <= flash;
  ntsc_rom_dout_dl <= "11111111";

	conf_en_s <= '1' when conf_wr = '1' and CONF_AI(15 DOWNTO 13) = "111" else '0';

--  kernal_rom_pal_o : entity work.gen_rom
--    generic map ("rtl/roms/kernal.901486-07.mif", 13)

--  kernal_rom_ntsc_o : entity work.gen_rom
--    generic map ("rtl/roms/kernal.901486-06.mif", 13)

	 
  p_video_output : process
  begin
    wait until rising_edge(i_sysclk);
    if (i_sysclk_en = '1') then
      O_VIDEO_R <= video_r;
      O_VIDEO_G <= video_g;
      O_VIDEO_B <= video_b;

      -- usually sync is always low-active...
      O_HSYNC   <= not hsync;
      O_VSYNC   <= not vsync;
    end if;
  end process;

end RTL;
