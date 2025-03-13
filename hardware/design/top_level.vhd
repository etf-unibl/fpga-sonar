-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:     Top-Level VGA Controller
--
-- description:
--
--   This module is the top-level entity for the VGA controller. It instantiates
--   the VGA controller and the drawing logic, connecting their signals to
--   generate a VGA output with concentric circles and a blinking object.
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

--! @brief Top-Level VGA Controller.
--! This module instantiates the VGA controller and the drawing logic,
--! connecting their signals to generate a VGA output with concentric circles
--! and a blinking object.
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

  component vga_controller is
    port(
      clk_i   : in  std_logic;
      rst_i   : in  std_logic;
      vclk_o  : out std_logic;
      hsync_o : out std_logic;
      vsync_o : out std_logic;
      blank_o : out std_logic;
      sync_o  : out std_logic;
      hpos_o  : out integer;
      vpos_o  : out integer;
      de_o    : out std_logic
    );
  end component;

  component draw_logic is
    port(
      clk_i      : in  std_logic;
      rst_i      : in  std_logic;
      hpos_i     : in  integer;
      vpos_i     : in  integer;
      de_i       : in  std_logic;
      angle_i    : in  std_logic_vector(7 downto 0);
      distance_i : in  std_logic_vector(8 downto 0);
      r_o        : out std_logic_vector(7 downto 0);
      g_o        : out std_logic_vector(7 downto 0);
      b_o        : out std_logic_vector(7 downto 0)
    );
  end component;

  signal hpos  : integer; --! Horizontal position
  signal vpos  : integer; --! Vertical position
  signal de    : std_logic; --! Data enable signal
  signal angle : std_logic_vector(7 downto 0) := "00000000"; --! (0 degrees)
  signal distance : std_logic_vector(8 downto 0) := "011001001"; --! (201 cm)

begin

  -- Instantijacija VGA kontrolera
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

  -- Instantijacija draw_logic modula
  draw_logic_inst : draw_logic
    port map(
      clk_i      => clk_i,
      rst_i      => rst_i,
      hpos_i     => hpos,
      vpos_i     => vpos,
      de_i       => de,
      angle_i    => angle,
      distance_i => distance,
      r_o        => r_o,
      g_o        => g_o,
      b_o        => b_o
    );

end architecture arch;
