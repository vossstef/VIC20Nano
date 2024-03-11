----------------------------------------------------------------------------------
--
-- Description:
-- RAM 2048 x 8 bit: sync. write, sync. read, configurable
--
-- (c) copyright 2011...2013 by Wolfgang Scherr
-- http://www.pin4.at - ws_arcade <at> pin4.at
--
-- All Rights Reserved
--
-- Version 1.0
-- SVN: $Id: ram_conf_2048x8.vhd 647 2014-05-17 11:47:04Z wolfgang.scherr $
--
-------------------------------------------------------------------------------
-- Redistribution and use in source or synthesized forms are permitted
-- provided that the following conditions are met (or a prior written
-- permission was given otherwise):
--
-- * Redistributions of source code must retain this original header
--   incl. author, contributors, conditions, copyright and disclaimer.
--
-- * Redistributions in synthesized (binary) form must also contain
--   the soure code according to this conditions to keep it "open".
--
-- * Neither the name of the author nor the names of contributors may
--   be used to endorse or promote products derived from this code.
--
-- * This code is only allowed to be used on:
--   - Replay hardware (from fpgaarcade.com)
--
-- * Feedback or bug reports are welcome, but please check on the 
--   web sites given in the header first for any updates available.
--
-- * You are responsible for any legal issues arising from your use
--   or your own distribution of this code.
----------------------------------------------------------------------
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-- LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
-- FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
-- AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
-- STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS  CODE OR ANY WORK
-- PRODUCTS, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_conf_2048x8 is
  generic (
    START_AI    : std_logic_vector(4 downto 0) := "00000"
  );
  port (
    CLK         : in  std_logic;
    CLK_EN      : in  std_logic;
    -- standard channel (read/write)
    EN1n        : in  std_logic;
    EN2n        : in  std_logic;
    WRn         : in  std_logic;
    ADDR        : in  std_logic_vector(10 downto 0);
    DIN         : in  std_logic_vector(7 downto 0);
    DOUT        : out std_logic_vector(7 downto 0);
    -- setup bus (write only, starts at START_AI)
    CONF_CLK    : in  std_logic;
    CONF_WR     : in  std_logic;
    CONF_AI     : in  std_logic_vector(15 downto 0);
    CONF_DI     : in  std_logic_vector(7 downto 0)
    );
end ram_conf_2048x8;

architecture RTL of ram_conf_2048x8 is

  type ram_arr_t is array(2047 downto 0) of std_logic_vector(7 downto 0);
  signal ram_s : ram_arr_t := (others => "11111111"); -- most likely init value of real RAM

  signal read_en_s : std_logic;
  signal write_en_s : std_logic;
  signal conf_en_s : std_logic;

begin

	conf_en_s <= '1' when (CONF_AI(15 DOWNTO 15-START_AI'left)=START_AI) else '0';

--	ram: work.gen_dpram
--	generic map(11,8)
--	port map
--	(
--		clock_a		=> CLK,
--		enable_a		=> CLK_EN and (NOT(EN1n) or NOT(EN2n)),
--		address_a	=> ADDR,
--		data_a		=> DIN,
--		wren_a		=> not WRn,
--		q_a			=> DOUT,

--		clock_b		=> CONF_CLK,
--		address_b	=> CONF_AI(ADDR'left downto 0),
--		data_b		=> CONF_DI,
--		wren_b		=> CONF_WR and conf_en_s
--	);
  ram2k: entity work.Gowin_DPB_2k
  port map (
      douta => DOUT,
      doutb => open,
      clka => CLK,
      ocea => '1',
      cea => CLK_EN and (NOT(EN1n) or NOT(EN2n)),
      reseta => '0',
      wrea => not WRn,
      clkb => CONF_CLK,
      oceb => '1',
      ceb => '1',
      resetb => '0',
      wreb => CONF_WR and conf_en_s,
      ada => ADDR,
      dina => DIN,
      adb => CONF_AI(ADDR'left downto 0),
      dinb => CONF_DI
  );

end RTL;
