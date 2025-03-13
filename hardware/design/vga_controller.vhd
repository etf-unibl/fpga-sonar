-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:     VGA Controller
--
-- description:
--
--   This module implements a VGA controller for a 640x480 resolution display.
--   It generates horizontal and vertical synchronization signals, manages
--   video timing, and provides pixel position outputs. This controller does
--   not handle rendering graphics or colors; it only provides timing and
--   position signals necessary for a separate drawing module.
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
entity vga_controller is
  port(
    clk_i   : in  std_logic; --! Clock signal
    rst_i   : in  std_logic; --! Reset signal
    vclk_o  : out std_logic; --! VGA pixel clock
    hsync_o : out std_logic; --! Horizontal sync signal
    vsync_o : out std_logic; --! Vertical sync signal
    blank_o : out std_logic; --! Blanking signal
    sync_o  : out std_logic; --! Sync signal (always '0')
    hpos_o  : out integer;   --! Current horizontal position
    vpos_o  : out integer;   --! Current vertical position
    de_o    : out std_logic  --! Data enable signal
  );
end entity vga_controller;

architecture arch of vga_controller is

  --! @brief VGA timing constants for 640x480 resolution.
  constant c_HD  : integer := 640; --! Horizontal display (640 pixels)
  constant c_HFP : integer := 16;  --! Horizontal front porch
  constant c_HSP : integer := 96;  --! Horizontal sync pulse
  constant c_HBP : integer := 48;  --! Horizontal back porch

  constant c_VD  : integer := 480; --! Vertical display (480 pixels)
  constant c_VFP : integer := 10;  --! Vertical front porch
  constant c_VSP : integer := 2;   --! Vertical sync pulse
  constant c_VBP : integer := 33;  --! Vertical back porch

  -- Internal signals
  signal clk25 : std_logic := '0'; --! 25 MHz clock signal
  signal hpos  : integer   := 0;   --! Current horizontal position
  signal vpos  : integer   := 0;   --! Current vertical position
  signal hs    : std_logic := '0'; --! Horizontal sync signal
  signal vs    : std_logic := '0'; --! Vertical sync signal
  signal de    : std_logic := '0'; --! Data enable signal

begin

  --! @brief Sync signal is always set to '0'.
  sync_o <= '0';

  --! @brief VGA pixel clock generation.
  vclk_o <= clk25;

  --! @brief Clock division process.
  --! Divides the input clock to generate a 25 MHz clock signal.
  clk_div : process(clk_i)
  begin
    if rising_edge(clk_i) then
      clk25 <= not clk25;
    end if;
  end process clk_div;

  --! @brief Horizontal position counter.
  --! Counts horizontal pixels and resets when the total width is reached.
  horizontal_counter : process(clk25, rst_i)
  begin
    if rst_i = '0' then
      hpos <= 0;
    elsif rising_edge(clk25) then
      if hpos = c_HD + c_HFP + c_HSP + c_HBP - 1 then
        hpos <= 0;
      else
        hpos <= hpos + 1;
      end if;
    end if;
  end process horizontal_counter;

  --! @brief Vertical position counter.
  --! Counts vertical pixels and resets when the total height is reached.
  vertical_counter : process(clk25, rst_i)
  begin
    if rst_i = '0' then
      vpos <= 0;
    elsif rising_edge(clk25) then
      if hpos = c_HD + c_HFP + c_HSP + c_HBP - 1 then
        if vpos = c_VD + c_VFP + c_VSP + c_VBP - 1 then
          vpos <= 0;
        else
          vpos <= vpos + 1;
        end if;
      end if;
    end if;
  end process vertical_counter;

  --! @brief Horizontal sync generation.
  --! Generates the horizontal sync pulse based on the horizontal position.
  horizontal_sync : process(clk25, rst_i)
  begin
    if rst_i = '0' then
      hs <= '0';
      hsync_o <= '0';
    elsif rising_edge(clk25) then
      if (hpos >= (c_HD + c_HFP)) and (hpos < c_HD + c_HFP + c_HSP) then
        hs <= '0';
      else
        hs <= '1';
      end if;
      hsync_o <= hs;
    end if;
  end process horizontal_sync;

  --! @brief Vertical sync generation.
  --! Generates the vertical sync pulse based on the vertical position.
  vertical_sync : process(clk25, rst_i)
  begin
    if rst_i = '0' then
      vs <= '0';
      vsync_o <= '0';
    elsif rising_edge(clk25) then
      if (vpos >= (c_VD + c_VFP)) and (vpos < c_VD + c_VFP + c_VSP) then
        vs <= '0';
      else
        vs <= '1';
      end if;
      vsync_o <= vs;
    end if;
  end process vertical_sync;

  --! @brief Data enable signal generation.
  --! Generates the blanking signal and data enable signal.
  video_on : process(clk25, rst_i)
  begin
    if rst_i = '0' then
      de <= '0';
      blank_o <= '0';
    elsif rising_edge(clk25) then
      if hpos < c_HD and vpos < c_VD then
        de <= '1';
      else
        de <= '0';
      end if;
      blank_o <= de;
    end if;
  end process video_on;

  -- Output current positions and data enable
  hpos_o <= hpos;
  vpos_o <= vpos;
  de_o   <= de;

end architecture arch;