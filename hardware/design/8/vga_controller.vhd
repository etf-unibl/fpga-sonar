-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:     VGA_Controller
--
-- description:
--
--   This file implements a simple VGA controller which is able to draw a
--   10x10 pixels red square in the screen center on a white background.
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

--! @brief VGA controller for a 640x480 resolution display.
--! This controller generates horizontal and vertical sync signals, controls
--! the pixel data (RGB), and manages video timing.
--! It also allows drawing a red square on the screen at a specified location
entity vga_controller is
  port(
    clk_i   : in  STD_LOGIC; --! Clock signal
    RST_i   : in  STD_LOGIC; --! Reset signal
    VCLK_o  : out STD_LOGIC;
    HSYNC_o : out STD_LOGIC;
    VSYNC_o : out STD_LOGIC;
    BLANK_o : out STD_LOGIC;
    SYNC_o  : out STD_LOGIC;
    R_o     : out STD_LOGIC_VECTOR(7 downto 0);
    G_o     : out STD_LOGIC_VECTOR(7 downto 0);
    B_o     : out STD_LOGIC_VECTOR(7 downto 0) --! RGB color (8 bits each)
    );
end entity vga_controller;

architecture arch of vga_controller is

    --! @brief VGA timing constants for 640x480 resolution.
    --! These constants define the number of pixels for each section (display,
    --! front porch, sync pulse, back porch).
  constant c_HD  : integer   := 640; -- Horizontal Display (640)
  constant c_HFP : integer   := 16;  -- Right border (front porch)
  constant c_HSP : integer   := 96;  -- Sync pulse (Retrace)
  constant c_HBP : integer   := 48;  -- Left border (back porch)

  constant c_VD  : integer   := 480; -- Vertical Display (480)
  constant c_VFP : integer   := 10;  -- Right border (front porch)
  constant c_VSP : integer   := 2;   -- Sync pulse (Retrace)
  constant c_VBP : integer   := 33;  -- Left border (back porch)

    -- Internal signals
  signal clk25 : std_logic := '0'; --! 25 MHz clock signal
  signal hPos  : integer   := 0;   --! Current horizontal position
  signal vPos  : integer   := 0;   --! Current vertical position
  signal hs    : std_logic := '0'; --! Horizontal sync signal
  signal vs    : std_logic := '0'; --! Vertical sync signal
  signal de    : std_logic := '0'; --! Data enable signal

begin

--! @brief Sync signal is always set to '0'
  SYNC_o <= '0';

--! @brief VGA pixel clock generation
--! This process divides the input clock to generate a 25 MHz clock signal.
  VCLK_o <= clk25;

  clk_div : process(clk_i)
  begin
    if clk_i'event and clk_i = '1' then
      clk25 <= not clk25; --! Toggle the clk25 signal every clock cycle
    end if;
  end process clk_div;

--! @brief Horizontal position counter
--! This process counts horizontal pixels and resets when the total width
--! (c_HD + front porch + sync pulse + back porch) is reached.
  Horizontal_position_counter : process(clk25, RST_i)
  begin
    if RST_i = '0' then
      hPos <= 0; --! Reset horizontal position
    elsif clk25'event and clk25 = '1' then
      if hPos = c_HD + c_HFP + c_HSP + c_HBP - 1 then
        hPos <= 0; --! Reset horizontal position when reaching end of line
      else
        hPos <= hPos + 1; --! Increment horizontal position
      end if;
    end if;
  end process Horizontal_position_counter;

--! @brief Vertical position counter
--! This process counts vertical pixels and resets when the total height (c_VD +
--! front porch + sync pulse + back porch) is reached.
  Vertical_position_counter : process(clk25, RST_i)
  begin
    if RST_i = '0' then
      vPos <= 0; --! Reset vertical position
    elsif clk25'event and clk25 = '1' then
      if hPos = c_HD + c_HFP + c_HSP + c_HBP - 1 then
        if vPos = c_VD + c_VFP + c_VSP + c_VBP - 1 then
          vPos <= 0; --! Reset vertical position
        else
          vPos <= vPos + 1; --! Increment vertical position
        end if;
      end if;
    end if;
  end process Vertical_position_counter;

--! @brief Horizontal sync generation
--! This process generates the horizontal sync pulse (HSYNC_o) based on the
--! horizontal position.
  Horizontal_Synchronisation : process(clk25, RST_i)
  begin
    if RST_i = '0' then
      hs <= '0'; --! Reset horizontal sync
      HSYNC_o <= '0'; --! Reset HSYNC_o output
    elsif clk25'event and clk25 = '1' then
      if(hPos >= (c_HD + c_HFP)) and (hPos < c_HD + c_HFP + c_HSP) then
        hs <= '0'; --! Sync pulse during the retrace period
      else
        hs <= '1'; --! Active video area
      end if;
      HSYNC_o <= hs; --! Output horizontal sync signal
    end if;
  end process Horizontal_Synchronisation;

--! @brief Vertical sync generation
--! This process generates the vertical sync pulse (VSYNC_o) based on the
--! vertical position.
  Vertical_Synchronisation : process(clk25, RST_i)
  begin
    if RST_i = '0' then
      vs <= '0'; --! Reset vertical sync
      VSYNC_o <= '0'; --! Reset VSYNC_o output
    elsif clk25'event and clk25 = '1' then
      if(vPos >= (c_VD + c_VFP)) and (vPos < c_VD + c_VFP + c_VSP) then
        vs <= '0'; --! Sync pulse during the retrace period
      else
        vs <= '1'; --! Active video area
      end if;
      VSYNC_o <= vs; --! Output vertical sync signal
    end if;
  end process Vertical_Synchronisation;

--! @brief Data enable signal generation
--! This process generates the blanking signal (BLANK_o) and data enable (de).
--! The de signal enables the display of valid pixel data.
  video_on : process(clk25, RST_i)
  begin
    if RST_i = '0' then
      de <= '0'; --! Reset data enable
      BLANK_o <= '0'; --! Reset blanking signal
    elsif clk25'event and clk25 = '1' then
      if hPos < c_HD and vPos < c_VD then
        de <= '1'; --! Enable data during active video area
      else
        de <= '0'; --! Disable data during blanking period
      end if;
      BLANK_o <= de; --! Output blanking signal
    end if;
  end process video_on;

--! @brief Drawing a red square
--! This process draws a 10x10 red square at the center of the screen.
--! If the pixel is inside the square's area, it is drawn in red, otherwise white.
  draw : process(clk25, RST_i)
  begin
    if RST_i = '0' then
      R_o <= (others => '0'); --! Reset RGB to black
      G_o <= (others => '0');
      B_o <= (others => '0');
    elsif clk25'event and clk25 = '1' then
      if de = '1' then
          --! Draw a 10x10 red square at the center of the screen
        if (hPos >= 315 and hPos < 325) and (vPos >= 235 and vPos < 245) then
          R_o <= (others => '1'); --! Red color
          G_o <= (others => '0');
          B_o <= (others => '0');
        else
          R_o <= (others => '1'); --! White color
          G_o <= (others => '1');
          B_o <= (others => '1');
        end if;
      else
        R_o <= (others => '0'); --! Reset RGB to black if no valid data
        G_o <= (others => '0');
        B_o <= (others => '0');
      end if;
    end if;
  end process draw;
end arch;
