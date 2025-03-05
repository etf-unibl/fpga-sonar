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

--! @brief Top-level module for the VGA controller and circle drawing logic.
--! This module instantiates the VGA controller and circle drawing logic,
--! connecting their signals to generate a VGA output with concentric circles.
entity top_level is
  port(
    clk_i   : in  std_logic; --! Clock signal
    rst_i   : in  std_logic; --! Reset signal
    vclk_o  : out std_logic; --! VGA pixel clock
    hsync_o : out std_logic; --! Horizontal sync signal
    vsync_o : out std_logic; --! Vertical sync signal
    blank_o : out std_logic; --! Blanking signal
    sync_o  : out std_logic; --! Sync signal (always '0')
    r_o     : out std_logic_vector(7 downto 0); --! Red color (8 bits)
    g_o     : out std_logic_vector(7 downto 0); --! Green color (8 bits)
    b_o     : out std_logic_vector(7 downto 0)  --! Blue color (8 bits)
  );
end entity top_level;

architecture arch of top_level is

  --! @brief Component declaration for the VGA controller.
  component vga_controller is
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
  end component;

  --! @brief Component declaration for the circle drawing logic.
  component draw_logic is
    port(
      clk_i   : in  std_logic; --! Clock signal
      rst_i   : in  std_logic; --! Reset signal
      hpos_i  : in  integer;   --! Current horizontal position
      vpos_i  : in  integer;   --! Current vertical position
      r_o     : out std_logic_vector(7 downto 0); --! Red color (8 bits)
      g_o     : out std_logic_vector(7 downto 0); --! Green color (8 bits)
      b_o     : out std_logic_vector(7 downto 0)  --! Blue color (8 bits)
    );
  end component;

  -- Internal signals
  signal hpos  : integer; --! Current horizontal position
  signal vpos  : integer; --! Current vertical position
  signal de    : std_logic; --! Data enable signal

begin

  --! @brief Instantiation of the VGA controller component.
  vga_controller_inst : vga_controller
    port map(
      clk_i   => clk_i,
      rst_i   => rst_i,
      vclk_o  => vclk_o,
      hsync_o => hsync_o,
      vsync_o => vsync_o,
      blank_o => blank_o,
      sync_o  => sync_o,
      hpos_o  => hpos,
      vpos_o  => vpos,
      de_o    => de
    );

  --! @brief Instantiation of the circle drawing logic component.
  draw_logic_inst : draw_logic
    port map(
      clk_i  => clk_i,
      rst_i  => rst_i,
      hpos_i => hpos,
      vpos_i => vpos,
      r_o    => r_o,
      g_o    => g_o,
      b_o    => b_o
    );

end architecture arch;
