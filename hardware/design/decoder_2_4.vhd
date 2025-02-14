-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:  Decoder 2-4
--
-- description:
--
--  This file implements  2-4 decoder with enable input.
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Faculty of Electrical Engineering
-------------------------------------------------------------------------------
-- The MIT License
-------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

--! @brief 2-to-4 decoder with enable input
--! @details The decoder takes a 2-bit input and an enable signal.
--! When enable is active, it sets one of the four outputs high based on the input value.
--! When enable is not active, all outputs remain low.
entity decoder_2_4 is
  port(
    A_i : in  std_logic_vector(1 downto 0);
    E_i : in  std_logic;
    Y_o : out std_logic_vector(3 downto 0)
  );
end decoder_2_4;

--! @brief Decoder architecture implementation
--! @details Implements the truth table logic using conditional assignment.

architecture arch of decoder_2_4 is
begin
  Y_o <= "1000"  when A_i = "11" and E_i = '1' else
         "0100"  when A_i = "10" and E_i = '1' else
         "0010"  when A_i = "01" and E_i = '1' else
         "0001"  when A_i = "00" and E_i = '1' else
         "0000";  --! All outputs low when enable is '0'
end arch;
