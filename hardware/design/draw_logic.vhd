-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:     draw_logic
--
-- description:
--
--   This module handles the drawing logic for a VGA display. It renders three
--   concentric half-circles (red, yellow, and green) and a small black circle
--   that moves in a predefined path between these zones, simulating an object
--   detection system.
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

--! @brief Drawing logic for VGA display with moving object simulation.
--! This module draws three concentric half-circles (red, yellow, and green)
--! and a small black circle that moves between these zones.
entity draw_logic is
  port(
    clk_i  : in  std_logic; --! Clock signal
    rst_i  : in  std_logic; --! Reset signal
    hPos_i : in  integer;   --! Current horizontal position
    vPos_i : in  integer;   --! Current vertical position
    r_o    : out std_logic_vector(7 downto 0); --! Red color output (8 bits)
    g_o    : out std_logic_vector(7 downto 0); --! Green color output (8 bits)
    b_o    : out std_logic_vector(7 downto 0)  --! Blue color output (8 bits)
  );
end entity draw_logic;

architecture arch of draw_logic is

  --! @brief Circle parameters.
  constant c_CIRCLE_X_CENTER : integer := 320; --! X-coordinate of the circle center
  constant c_CIRCLE_Y_CENTER : integer := 480; --! Y-coordinate of the circle center (bottom of the screen)
  constant c_RED_RADIUS      : integer := 160; --! Radius of the red circle
  constant c_YELLOW_RADIUS   : integer := 320; --! Radius of the yellow circle
  constant c_GREEN_RADIUS    : integer := 480; --! Radius of the green circle

  --! @brief Small circle parameters.
  constant c_SMALL_CIRCLE_RADIUS   : integer := 5; --! Radius of the small black circle
  constant c_SMALL_CIRCLE_DURATION : integer := 100_000_000; --! Duration for small circle to complete a cycle

  --! @brief Angles for each zone.
  constant c_ANGLE_RED    : integer := 30;  --! Angle for the red zone (30 degrees)
  constant c_ANGLE_YELLOW : integer := 90;  --! Angle for the yellow zone (90 degrees)
  constant c_ANGLE_GREEN  : integer := 120; --! Angle for the green zone (120 degrees)

  --! @brief Precalculated trigonometric values.
  constant c_SCALE   : integer := 1000; --! Scaling factor for trigonometric calculations
  constant c_PI      : integer := 3141; --! Pi value scaled by 1000
  constant c_COS_30  : integer := 866;  --! Cosine of 30 degrees scaled by 1000
  constant c_SIN_30  : integer := 500;  --! Sine of 30 degrees scaled by 1000
  constant c_COS_90  : integer := 0;    --! Cosine of 90 degrees scaled by 1000
  constant c_SIN_90  : integer := 1000; --! Sine of 90 degrees scaled by 1000
  constant c_COS_120 : integer := -500; --! Cosine of 120 degrees scaled by 1000
  constant c_SIN_120 : integer := 866;  --! Sine of 120 degrees scaled by 1000

  --! @brief Signals for distances.
  signal red_distance : integer := 100; --! Distance for the red zone
  signal yellow_distance   : integer := 200; --! Distance for the yellow zone
  signal green_distance : integer := 400; --! Distance for the green zone

  --! @brief Signals for the small circle position.
  signal small_circle_x : integer := 0; --! X position of the small circle
  signal small_circle_y : integer := 0; --! Y position of the small circle

  --! @brief Signals for timing and position control.
  signal counter : integer := 0; --! Counter for timing
  signal position   : integer := 0; --! Current position of the small circle movement
  signal cycle_complete : std_logic := '0'; --! Indicates if the cycle is complete

begin

  --! @brief Process for counting time and changing phases.
  --! This process handles the timing and position transitions for the small circle.
  process(clk_i, rst_i)
  begin
    if rst_i = '0' then
      counter <= 0;
      position <= 0;
      cycle_complete <= '0';
    elsif rising_edge(clk_i) then
      if cycle_complete = '0' then
        if counter < c_SMALL_CIRCLE_DURATION then
          counter <= counter + 1;
        else
          counter <= 0;
          if position < 4 then
            position <= position + 1; -- Move to the next position
          else
            position <= 0; -- Reset position to the beginning
            cycle_complete <= '0'; -- Reset the cycle complete signal
          end if;
        end if;
      end if;
    end if;
  end process;

  --! @brief Process for setting the position of the small circle.
  --! This process updates the position of the small circle based on the current position.
  process(position, red_distance, yellow_distance, green_distance)
  begin
    case position is
      when 0 => -- Red zone (30 degrees)
        small_circle_x <= c_CIRCLE_X_CENTER + (red_distance * c_COS_30) / c_SCALE;
        small_circle_y <= c_CIRCLE_Y_CENTER - (red_distance * c_SIN_30) / c_SCALE;
      when 1 => -- Yellow zone (90 degrees)
        small_circle_x <= c_CIRCLE_X_CENTER + (yellow_distance * c_COS_90) / c_SCALE;
        small_circle_y <= c_CIRCLE_Y_CENTER - (yellow_distance * c_SIN_90) / c_SCALE;
      when 2 => -- Green zone (120 degrees)
        small_circle_x <= c_CIRCLE_X_CENTER + (green_distance * c_COS_120) / c_SCALE;
        small_circle_y <= c_CIRCLE_Y_CENTER - (green_distance * c_SIN_120) / c_SCALE;
      when 3 => -- Yellow zone (90 degrees, returning)
        small_circle_x <= c_CIRCLE_X_CENTER + (yellow_distance * c_COS_90) / c_SCALE;
        small_circle_y <= c_CIRCLE_Y_CENTER - (yellow_distance * c_SIN_90) / c_SCALE;
      when 4 => -- Red zone (30 degrees, returning)
        small_circle_x <= c_CIRCLE_X_CENTER + (red_distance * c_COS_30) / c_SCALE;
        small_circle_y <= c_CIRCLE_Y_CENTER - (red_distance * c_SIN_30) / c_SCALE;
      when others =>
        small_circle_x <= 0;
        small_circle_y <= 0;
    end case;
  end process;

  --! @brief Process for rendering the display.
  --! This process handles the rendering of the concentric circles and the small black circle.
  process(hPos_i, vPos_i, small_circle_x, small_circle_y, position)
    variable x_diff : integer;
    variable y_diff : integer;
    variable distance_squared : integer;
    variable small_circle_distance_squared : integer;
  begin
    -- Calculate distance from the center
    x_diff := hPos_i - c_CIRCLE_X_CENTER;
    y_diff := vPos_i - c_CIRCLE_Y_CENTER;
    distance_squared := (x_diff * x_diff) + (y_diff * y_diff);

    -- Calculate distance from the small circle
    x_diff := hPos_i - small_circle_x;
    y_diff := vPos_i - small_circle_y;
    small_circle_distance_squared := (x_diff * x_diff) + (y_diff * y_diff);

    -- Render zones and the small circle
    if (distance_squared <= c_RED_RADIUS * c_RED_RADIUS) and (vPos_i <= c_CIRCLE_Y_CENTER) then
      if small_circle_distance_squared <= c_SMALL_CIRCLE_RADIUS * c_SMALL_CIRCLE_RADIUS then
        r_o <= (others => '0');
        g_o <= (others => '0');
        b_o <= (others => '0'); -- Black circle
      else
        r_o <= (others => '1');
        g_o <= (others => '0');
        b_o <= (others => '0'); -- Red zone
      end if;
    elsif (distance_squared <= c_YELLOW_RADIUS * c_YELLOW_RADIUS) and (vPos_i <= c_CIRCLE_Y_CENTER) then
      if small_circle_distance_squared <= c_SMALL_CIRCLE_RADIUS * c_SMALL_CIRCLE_RADIUS then
        r_o <= (others => '0');
        g_o <= (others => '0');
        b_o <= (others => '0'); -- Black circle
      else
        r_o <= (others => '1');
        g_o <= (others => '1');
        b_o <= (others => '0'); -- Yellow zone
      end if;
    elsif (distance_squared <= c_GREEN_RADIUS * c_GREEN_RADIUS) and (vPos_i <= c_CIRCLE_Y_CENTER) then
      if small_circle_distance_squared <= c_SMALL_CIRCLE_RADIUS * c_SMALL_CIRCLE_RADIUS then
        r_o <= (others => '0');
        g_o <= (others => '0');
        b_o <= (others => '0'); -- Black circle
      else
        r_o <= (others => '0');
        g_o <= (others => '1');
        b_o <= (others => '0'); -- Green zone
      end if;
    else
      r_o <= (others => '0');
      g_o <= (others => '0');
      b_o <= (others => '0'); -- Black background
    end if;
  end process;

end architecture arch;
