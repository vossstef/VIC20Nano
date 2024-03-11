library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.ALL;

entity vic20_keyboard is
	port (
		clk     : in std_logic;
		reset   : in std_logic;
		
		keyboard_matrix_out : out std_logic_vector(7 downto 0);
		keyboard_matrix_in  : in std_logic_vector(7 downto 0);
	
		shift_mod: in std_logic_vector(1 downto 0);
		pai     :  in std_logic_vector(7 downto 0);
		pbi     :  in std_logic_vector(7 downto 0);
		pao     : out std_logic_vector(7 downto 0);
		pbo     : out std_logic_vector(7 downto 0);
		
		restore_key : out std_logic;
		mod_key     : out std_logic;
		tape_play   : out std_logic;
		backwardsReadingEnabled : in std_logic
	);
end vic20_keyboard;

architecture rtl of vic20_keyboard is

begin
	mod_key <= '0';
	restore_key <= '0';
	tape_play <= '0';

	matrix: process(clk)
	begin
		if rising_edge(clk) then
			keyboard_matrix_out <= pbi;
			-- reading A, scan pattern on B
			pao(0) <= pai(0) and keyboard_matrix_in(0);
			pao(1) <= pai(1) and keyboard_matrix_in(1);
			pao(2) <= pai(2) and keyboard_matrix_in(2);
			pao(3) <= pai(3) and keyboard_matrix_in(3);
			pao(4) <= pai(4) and keyboard_matrix_in(4);
			pao(5) <= pai(5) and keyboard_matrix_in(5);
			pao(6) <= pai(6) and keyboard_matrix_in(6);
			pao(7) <= pai(7) and keyboard_matrix_in(7);
			-- reading B, scan pattern on A
			pbo(0) <= pbi(0);
			pbo(1) <= pbi(1);
			pbo(2) <= pbi(2);
			pbo(3) <= pbi(3);
			pbo(4) <= pbi(4);
			pbo(5) <= pbi(5);
			pbo(6) <= pbi(6);
			pbo(7) <= pbi(7);
    	end if;
	end process;
end architecture;
