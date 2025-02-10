library ieee;
use ieee.std_logic_1164.all;

entity decoder_2_4 is port
(
	i_A : in std_logic_vector(1 downto 0);
	i_E : in std_logic;
	o_Y : out std_logic_vector(3 downto 0)
);
end decoder_2_4;

architecture arch_decoder_2_4 of decoder_2_4 is
begin 

	   o_Y <= "1000"  when  ( i_A = "11" and i_E = '1' ) else
						"0100"  when  ( i_A = "10" and i_E = '1' ) else
						"0010"  when  ( i_A = "01" and i_E = '1') else
						"0001"  when  ( i_A = "00" and i_E = '1') else
						"0000"; -- when i_E is 0 or i_A is not corect

	
end arch_decoder_2_4;