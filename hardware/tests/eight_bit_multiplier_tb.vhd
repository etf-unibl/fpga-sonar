-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/pds-2024
-----------------------------------------------------------------------------
--
-- unit name:     TEST
--
-- description:
--
--   This file has the testing purpose for creating the first github pull request.
--
-----------------------------------------------------------------------------
-- Copyright (c) 2024 Faculty of Electrical Engineering
-----------------------------------------------------------------------------
-- The MIT License
-----------------------------------------------------------------------------
-- Copyright 2024 Faculty of Electrical Engineering
--
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom
-- the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE
-----------------------------------------------------------------------------	

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vunit_lib;
context vunit_lib.vunit_context;

entity eight_bit_multiplier_tb is
	generic (runner_cfg : string);
end eight_bit_multiplier_tb;

architecture tb_arch of eight_bit_multiplier_tb is

    -- deklarisanje komponente
    component eight_bit_multiplier
        port (
            A_i   : in  std_logic_vector(7 downto 0);
            B_i   : in  std_logic_vector(7 downto 0);
            RES_o : out std_logic_vector(15 downto 0)
        );
    end component;

    -- signali testbench-a
    signal A_test   : std_logic_vector(7 downto 0);
    signal B_test   : std_logic_vector(7 downto 0);
    signal RES_test : std_logic_vector(15 downto 0);

begin

    
    uut: eight_bit_multiplier
        port map ( A_i   => A_test, B_i   => B_test, RES_o => RES_test );

    
    tb: process
        variable res : unsigned(15 downto 0);
    begin
	    test_runner_setup(runner, runner_cfg);
        -- inicijalizaciija ulaza
        A_test <= (others => '0');
        B_test <= (others => '0');
		 
        wait for 10 ns;
		 
       
 -- petlja koja prolazi kroz sve kombinacije A_i i  B_i
        for i in 0 to 255 loop
            for j in 0 to 255 loop
               
			   -- odkomentarisati ovu liniju
              --  wait for 10 ns;

                -- ocekivana vrijednost ulaznih signala
                
					 res := unsigned(A_test) * unsigned(B_test);
                
                assert (to_integer(unsigned(RES_test)) = to_integer(res)) report "Error detected! A = " & 
						integer'image(to_integer(unsigned(A_test))) & ", B = " & 
					   integer'image(to_integer(unsigned(B_test))) & ", Expected = " & 
					   integer'image(to_integer(unsigned(A_test)) * to_integer(unsigned(B_test))) & ", Got = " &
					   integer'image(to_integer(unsigned(RES_test))) severity error;
					 
					 B_test <= std_logic_vector(unsigned(B_test) + 1);
            end loop;
				A_test <= std_logic_vector(unsigned(A_test) + 1);
				
        end loop;



        --ako je sve uredu ispisi
        report "Test completed successfully.";
		test_runner_cleanup(runner);
        wait;
    end process;

end tb_arch;

