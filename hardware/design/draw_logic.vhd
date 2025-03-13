-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:     Draw Logic for VGA Controller
--
-- description:
--
--   This module implements the drawing logic for a VGA controller. It draws
--   concentric circles (red, yellow, green) and an object (point) based on
--   the given angle and distance. The object blinks at a defined rate.
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

--! @brief Draw Logic for VGA Controller.
--! This module draws concentric circles and an object (point) based on the
--! given angle and distance. The object blinks at a defined rate.
entity draw_logic is
  port (
    clk_i       : in  std_logic; --! Clock signal
    rst_i       : in  std_logic; --! Reset signal
    hPos_i      : in  integer;   --! Horizontal position
    vPos_i      : in  integer;   --! Vertical position
    de_i        : in  std_logic; --! Data enable signal
    angle_i     : in  unsigned(7 downto 0); --! Angle input (0-179)
    distance_i  : in  std_logic_vector(8 downto 0); --! Distance input (2-400)
    r_o         : out std_logic_vector(7 downto 0); --! Red color output
    g_o         : out std_logic_vector(7 downto 0); --! Green color output
    b_o         : out std_logic_vector(7 downto 0)  --! Blue color output
  );
end entity draw_logic;

architecture arch of draw_logic is

  -- Constants for screen center and circle radii
  constant c_SCREEN_CENTER_X : integer := 320; --! X center of the screen
  constant c_SCREEN_CENTER_Y : integer := 480; --! Y center of the screen
  constant c_RED_RADIUS    : integer := 160; --! Radius for red zone
  constant c_YELLOW_RADIUS : integer := 320; --! Radius for yellow zone
  constant c_GREEN_RADIUS  : integer := 480; --! Radius for green zone

  -- Look-up table for sine values (0 to 90, scaled to 1000)
  type trig_lut is array (0 to 90) of integer;
  constant c_SIN_LUT : trig_lut := (
    0, 17, 35, 52, 70, 87, 105, 122, 139, 156,
    173, 190, 208, 225, 242, 259, 276, 292, 309, 326,
    342, 358, 375, 391, 407, 423, 438, 454, 470, 485,
    500, 515, 530, 544, 558, 573, 588, 601, 615, 629,
    642, 656, 670, 682, 695, 707, 718, 731, 743, 754,
    766, 777, 788, 799, 809, 819, 829, 839, 848, 857,
    866, 875, 883, 891, 899, 906, 913, 920, 927, 933,
    940, 945, 951, 956, 961, 966, 970, 974, 978, 982,
    985, 988, 990, 992, 994, 996, 997, 999, 999, 999,
    1000
  );

  -- Signals for object position
  signal obj_x       : integer := 0; --! X position of the object
  signal obj_y       : integer := 0; --! Y position of the object
  signal valid_angle : boolean := false; --! Flag for valid angle
  signal valid_dist  : boolean := false; --! Flag for valid distance

  -- Blinking signals
  signal blink_counter : integer := 0; --! Counter for blinking
  signal blink_state   : std_logic := '0'; --! Blink state (0 = off, 1 = on)
  constant c_BLINK_RATE  : integer := 3000000; --! Blink rate(adjust for speed)

  -- Function to calculate sine using LUT
  function sin_lookup(angle : integer) return integer is
  begin
    if angle <= 90 then
      return c_SIN_LUT(angle);
    else
      return c_SIN_LUT(180 - angle); -- Symmetry for 90 - 180
    end if;
  end function sin_lookup;

  -- Function to calculate cosine using LUT
  function cos_lookup(angle : integer) return integer is
  begin
    if angle <= 90 then
      return -c_SIN_LUT(90 - angle);
    else
      return c_SIN_LUT(angle - 90); -- Symmetry for 90 - 180
    end if;
  end function cos_lookup;

begin

  -----------------------------------------------------------------------------
  -- Process to calculate object position based on angle and distance
  -----------------------------------------------------------------------------
  process(clk_i)
    variable int_angle       : integer; -- Integer angle
    variable int_distance    : integer; -- Integer distance
    variable int_distance_px : integer; -- Distance in pixels
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        -- Reset object position
        obj_x <= 0;
        obj_y <= 0;
      else
        -- Convert input values to integers
        int_angle := to_integer(angle_i);
        int_distance := to_integer(unsigned(distance_i));

        -- Validate angle and distance
        valid_angle <= (int_angle >= 0 and int_angle <= 179);
        valid_dist  <= (int_distance >= 2 and int_distance <= 400);

        -- Calculate object position if valid
        if valid_angle and valid_dist then
          -- Scale distance to pixels (400 cm -> 480 pixels)
          int_distance_px := (int_distance * 480) / 400;

          -- Calculate object coordinates (from bottom of the screen)
          obj_x <= c_SCREEN_CENTER_X + (int_distance_px *
          cos_lookup(int_angle)) / 1000;
          obj_y <= c_SCREEN_CENTER_Y - (int_distance_px *
          sin_lookup(int_angle)) / 1000; -- Y from bottom
        else
          -- Invalid input, reset object position
          obj_x <= 0;
          obj_y <= 0;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Process to control blinking
  -----------------------------------------------------------------------------
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        blink_counter <= 0;
        blink_state <= '0';
      else
        if blink_counter = c_BLINK_RATE then
          blink_counter <= 0;
          blink_state <= not blink_state; -- Toggle blink state
        else
          blink_counter <= blink_counter + 1;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Process to draw concentric circles and object
  -----------------------------------------------------------------------------
  process(hPos_i, vPos_i, obj_x, obj_y, de_i, valid_angle,
          valid_dist, blink_state)
    variable x_diff : integer; -- X difference from center
    variable y_diff : integer; -- Y difference from center
    variable distance_squared : integer; -- Squared distance from center
  begin
    if de_i = '1' then
      -- Draw the object (point) if valid and blinking state is on
      if valid_angle and valid_dist and blink_state = '1' and
         (hPos_i >= obj_x - 3 and hPos_i <= obj_x + 3) and
         (vPos_i >= obj_y - 3 and vPos_i <= obj_y + 3) then
        r_o <= (others => '0');
        g_o <= (others => '0');
        b_o <= (others => '0');
      else
        -- Draw concentric circles (from bottom of the screen)
        x_diff := hPos_i - c_SCREEN_CENTER_X;
        y_diff := c_SCREEN_CENTER_Y - vPos_i; -- Y is measured from the bottom
        distance_squared := (x_diff * x_diff) + (y_diff * y_diff);

        -- Red zone
        if distance_squared <= c_RED_RADIUS * c_RED_RADIUS then
          r_o <= (others => '1'); -- Red
          g_o <= (others => '0');
          b_o <= (others => '0');
        -- Yellow zone
        elsif distance_squared <= c_YELLOW_RADIUS * c_YELLOW_RADIUS then
          r_o <= (others => '1'); -- Yellow
          g_o <= (others => '1');
          b_o <= (others => '0');
        -- Green zone
        elsif distance_squared <= c_GREEN_RADIUS * c_GREEN_RADIUS then
          r_o <= (others => '0'); -- Green
          g_o <= (others => '1');
          b_o <= (others => '0');
        -- Background
        else
          r_o <= (others => '0'); -- Black
          g_o <= (others => '0');
          b_o <= (others => '0');
        end if;
      end if;
    else
      -- Blanking period
      r_o <= (others => '0');
      g_o <= (others => '0');
      b_o <= (others => '0');
    end if;
  end process;

end architecture arch;
