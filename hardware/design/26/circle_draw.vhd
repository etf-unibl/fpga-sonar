-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:     VGA Controller that Draws Colored Zones
--
-- description:
--
--   This file implements a simple VGA controller which is able to draw
--   multiple colored zones on the screen. The zones are defined by their
--   boundaries and are drawn in different colors (red, yellow, and green)
--   on a white background.
--
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
use ieee.numeric_std.all;

--! @brief Circle drawing logic for VGA display.
--! This module draws concentric circles (red, yellow, and green) on the screen
--! based on the current horizontal and vertical positions.
entity circle_draw is
  port(
    clk_i   : in  std_logic; --! Clock signal
    rst_i   : in  std_logic; --! Reset signal
    hpos_i  : in  integer;   --! Current horizontal position
    vpos_i  : in  integer;   --! Current vertical position
    de_i    : in  std_logic; --! Data enable signal
    r_o     : out std_logic_vector(7 downto 0); --! Red color (8 bits)
    g_o     : out std_logic_vector(7 downto 0); --! Green color (8 bits)
    b_o     : out std_logic_vector(7 downto 0)  --! Blue color (8 bits)
  );
end entity circle_draw;

architecture arch of circle_draw is

  --! @brief Circle parameters.
  constant c_CIRCLE_X_CENTER : integer := 320; --! X-coordinate of the circle
  constant c_CIRCLE_Y_CENTER : integer := 480; --! Y-coordinate of the circle
  constant c_RED_RADIUS      : integer := 160; --! Radius of the red circle
  constant c_YELLOW_RADIUS   : integer := 320; --! Radius of the yellow circle
  constant c_GREEN_RADIUS    : integer := 480; --! Radius of the green circle

begin

  --! @brief Drawing concentric circles.
  --! This process calculates the distance from the center and draws circles
  --! based on the distance squared.
  draw : process(clk_i, rst_i)
    variable x_diff : integer;
    variable y_diff : integer;
    variable distance_squared : integer;
  begin
    if rst_i = '0' then
      r_o <= (others => '0');
      g_o <= (others => '0');
      b_o <= (others => '0');
    elsif rising_edge(clk_i) then
      if de_i = '1' then
        -- Calculate distance from the center
        x_diff := hpos_i - c_CIRCLE_X_CENTER;
        y_diff := vpos_i - c_CIRCLE_Y_CENTER;
        distance_squared := (x_diff * x_diff) + (y_diff * y_diff);

        -- Draw concentric circles
        if (distance_squared <= c_RED_RADIUS * c_RED_RADIUS) and
        (vpos_i <= c_CIRCLE_Y_CENTER) then
          r_o <= (others => '1');
          g_o <= (others => '0');
          b_o <= (others => '0');
        elsif (distance_squared <= c_YELLOW_RADIUS * c_YELLOW_RADIUS) and
        (vpos_i <= c_CIRCLE_Y_CENTER) then
          r_o <= (others => '1');
          g_o <= (others => '1');
          b_o <= (others => '0');
        elsif (distance_squared <= c_GREEN_RADIUS * c_GREEN_RADIUS) and
        (vpos_i <= c_CIRCLE_Y_CENTER) then
          r_o <= (others => '0');
          g_o <= (others => '1');
          b_o <= (others => '0');
        else
          r_o <= (others => '0');
          g_o <= (others => '0');
          b_o <= (others => '0');
        end if;
      else
        r_o <= (others => '0');
        g_o <= (others => '0');
        b_o <= (others => '0');
      end if;
    end if;
  end process draw;

end architecture arch;
