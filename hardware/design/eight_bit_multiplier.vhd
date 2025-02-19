-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-----------------------------------------------------------------------------
--
-- unit name:     Eight bit multiplier
--
-- description:
--
--   This file implements an eight bit multiplier with addition of partial products.
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
--! @brief Eight-bit multiplier entity
--! This entity defines an 8-bit multiplier that produces a 16-bit result.
--! It takes two 8-bit unsigned inputs and outputs their product
entity eight_bit_multiplier is
  port (
    A_i   : in  std_logic_vector(7 downto 0);
    B_i   : in  std_logic_vector(7 downto 0);
    RES_o : out std_logic_vector(15 downto 0)
  );
end eight_bit_multiplier;
--! @brief Eight-bit multiplier architecture
--! Implements multiplication using partial product addition.
architecture arch of eight_bit_multiplier is
begin
--! Process that performs multiplication by partial addition
  process(A_i, B_i)
    variable p : unsigned(15 downto 0);
    variable tempA : unsigned(15 downto 0);
    variable tempB : unsigned(7 downto 0);
  begin
    p := (others => '0');
    tempA := "00000000" & unsigned(A_i);
    tempB := unsigned(B_i);
    for i in 0 to 7 loop
      if  tempB(i) = '1' then
        p := p + tempA;
      end if;
      tempA := tempA sll 1;
    end loop;
    RES_o <= std_logic_vector(p);
  end process;
end arch;
