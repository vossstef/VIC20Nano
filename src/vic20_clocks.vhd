--
-- A simulation model of VIC20 hardware (clocking)
-- 
-- All rights reserved
-- (c) copyright 2003-2009 by MikeJ (Mike Johnson)
-- http://www.FPGAArcade.com - mikej <at> fpgaarcade <dot> com
-- (c) copyright 2011...2015 by WoS (Wolfgang Scherr)
-- http://www.pin4.at - WoS <at> pin4 <dot> at
--
-- $Id: vic20_clocks.vhd 1328 2015-05-22 19:29:53Z wolfgang.scherr $
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

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity VIC20_CLOCKS is
  port (
    I_SYSCLK          : in  std_logic;
    I_SYSCLK_EN       : in  std_logic;
    I_RESET_L         : in  std_logic;
    --
    O_ENA             : out std_logic;
    O_RESET_L         : out std_logic
    );
end;

architecture RTL of VIC20_CLOCKS is

  signal delay_count : unsigned(11 downto 0) := (others => '0');
  signal div_cnt     : std_logic;

begin
  p_delay : process(I_RESET_L, I_SYSCLK)
  begin
    if (I_RESET_L = '0') then
      delay_count <= x"000"; -- longer delay for cpu
      O_RESET_L <= '0';
    elsif rising_edge(I_SYSCLK) then
      if (I_SYSCLK_EN='1') then
        if (delay_count = (x"FFF")) then
          O_RESET_L <= '1';
        else
          delay_count <= delay_count + "1";
          O_RESET_L <= '0';
        end if;
      end if;
    end if;
  end process;

  p_clk_div : process(I_SYSCLK)
  begin
    if rising_edge(I_SYSCLK) then
      O_ENA <= '0';
      if I_SYSCLK_EN='1' then
        div_cnt <= not div_cnt;
        O_ENA   <= div_cnt;
      else
      end if;
    end if;
  end process;
end RTL;
