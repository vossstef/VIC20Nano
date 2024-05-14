-- -----------------------------------------------------------------------
-- core timer
-- -----------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;

-- -----------------------------------------------------------------------

entity core_timer is
port(
	clk32       : in  std_logic;

	io_cycle    : out std_logic;
	refresh     : out std_logic
);
end;

-- -----------------------------------------------------------------------

architecture rtl of core_timer is

constant CYCLE_EXT0: unsigned(4 downto 0) := to_unsigned( 0, 5);
constant CYCLE_EXT1: unsigned(4 downto 0) := to_unsigned( 1, 5);
constant CYCLE_EXT2: unsigned(4 downto 0) := to_unsigned( 2, 5);
constant CYCLE_EXT3: unsigned(4 downto 0) := to_unsigned( 3, 5);
constant CYCLE_DMA0: unsigned(4 downto 0) := to_unsigned( 4, 5);
constant CYCLE_DMA1: unsigned(4 downto 0) := to_unsigned( 5, 5);
constant CYCLE_DMA2: unsigned(4 downto 0) := to_unsigned( 6, 5);
constant CYCLE_DMA3: unsigned(4 downto 0) := to_unsigned( 7, 5);
constant CYCLE_EXT4 : unsigned(4 downto 0) := to_unsigned( 8, 5);
constant CYCLE_EXT5 : unsigned(4 downto 0) := to_unsigned( 9, 5);
constant CYCLE_EXT6 : unsigned(4 downto 0) := to_unsigned(10, 5);
constant CYCLE_EXT7 : unsigned(4 downto 0) := to_unsigned(11, 5);
constant CYCLE_VIC0 : unsigned(4 downto 0) := to_unsigned(12, 5);
constant CYCLE_VIC1 : unsigned(4 downto 0) := to_unsigned(13, 5);
constant CYCLE_VIC2 : unsigned(4 downto 0) := to_unsigned(14, 5);
constant CYCLE_VIC3 : unsigned(4 downto 0) := to_unsigned(15, 5);
constant CYCLE_CPU0 : unsigned(4 downto 0) := to_unsigned(16, 5);
constant CYCLE_CPU1 : unsigned(4 downto 0) := to_unsigned(17, 5);
constant CYCLE_CPU2 : unsigned(4 downto 0) := to_unsigned(18, 5);
constant CYCLE_CPU3 : unsigned(4 downto 0) := to_unsigned(19, 5);
constant CYCLE_CPU4 : unsigned(4 downto 0) := to_unsigned(20, 5);
constant CYCLE_CPU5 : unsigned(4 downto 0) := to_unsigned(21, 5);
constant CYCLE_CPU6 : unsigned(4 downto 0) := to_unsigned(22, 5);
constant CYCLE_CPU7 : unsigned(4 downto 0) := to_unsigned(23, 5);
constant CYCLE_CPU8 : unsigned(4 downto 0) := to_unsigned(24, 5);
constant CYCLE_CPU9 : unsigned(4 downto 0) := to_unsigned(25, 5);
constant CYCLE_CPUA : unsigned(4 downto 0) := to_unsigned(26, 5);
constant CYCLE_CPUB : unsigned(4 downto 0) := to_unsigned(27, 5);
constant CYCLE_CPUC : unsigned(4 downto 0) := to_unsigned(28, 5);
constant CYCLE_CPUD : unsigned(4 downto 0) := to_unsigned(29, 5);
constant CYCLE_CPUE : unsigned(4 downto 0) := to_unsigned(30, 5);
constant CYCLE_CPUF : unsigned(4 downto 0) := to_unsigned(31, 5);


signal sysCycle     : unsigned(4 downto 0) := (others => '0');
attribute syn_preserve : integer;
attribute syn_preserve of sysCycle : signal is 1;
signal rfsh_cycle   : unsigned(1 downto 0);

begin

io_cycle <= '1' when
	(sysCycle >= CYCLE_EXT0 and sysCycle<= CYCLE_EXT3) or
	(sysCycle>= CYCLE_EXT4 and sysCycle <= CYCLE_EXT7 and rfsh_cycle /= "00")  else '0';

process(clk32)
begin
	if rising_edge(clk32) then
		sysCycle <= sysCycle+1;
		if sysCycle = CYCLE_CPUF then
		rfsh_cycle <= rfsh_cycle + 1;

		end if;
		
		refresh <= '0';
		if sysCycle = CYCLE_DMA3 and rfsh_cycle = "00" then
			refresh <= '1';
		end if;
	end if;
end process;

end architecture;
