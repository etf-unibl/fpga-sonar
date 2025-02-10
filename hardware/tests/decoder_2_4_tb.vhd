library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vunit_lib;
context vunit_lib.vunit_context;

entity decoder_2_4_tb is 
	generic (runner_cfg : string);
end decoder_2_4_tb;

architecture testbench of decoder_2_4_tb is

    signal i_A : std_logic_vector(1 downto 0);
    signal i_E : std_logic;
    signal o_Y : std_logic_vector(3 downto 0);
    
    -- Instanca dekodera
    component decoder_2_4
        port(
            i_A : in std_logic_vector(1 downto 0);
            i_E : in std_logic;
            o_Y : out std_logic_vector(3 downto 0)
        );
    end component;
    
begin
    
    uut: decoder_2_4 port map (i_A => i_A, i_E => i_E, o_Y => o_Y);
    
    process
    begin
	
	    test_runner_setup(runner, runner_cfg);
       
        i_A <= "00"; i_E <= '0';
        wait for 10 ns;
        assert o_Y = "0000" report "Test failed for i_A = 00, i_E = 0" severity error;
        
        i_A <= "00"; i_E <= '1';
        wait for 10 ns;
        assert o_Y = "0001" report "Test failed for i_A = 00, i_E = 1" severity error;
        
        i_A <= "01";
        wait for 10 ns;
        assert o_Y = "0010" report "Test failed for i_A = 01, i_E = 1" severity error;
          
        i_A <= "10";
        wait for 10 ns;
        assert o_Y = "0100" report "Test failed for i_A = 10, i_E = 1" severity error;
        
        i_A <= "11";
        wait for 10 ns;
        assert o_Y = "1000" report "Test failed for i_A = 11, i_E = 1" severity error;
        
        i_E <= '0';
        wait for 10 ns;
        assert o_Y = "0000" report "Test failed for i_A = 11, i_E = 0" severity error;
        
		 test_runner_cleanup(runner);
        
        wait;
		
	   
    end process;
    
end testbench;
