-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
--
-- unit name:     vga_draw_logic_tb
--
-- description:
--
--   This file implements a testbench for the VGA drawing logic
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
use std.textio.all;
use ieee.std_logic_textio.all;

-- Include VUnit libraries for assertions.
library vunit_lib;
context vunit_lib.vunit_context;

entity vga_draw_logic_tb is
  generic (
    runner_cfg : string;
    tb_path    : string
    );
end entity vga_draw_logic_tb;

architecture arch of vga_draw_logic_tb is



  constant clk_period : time := 20 ns;

   -- Helper functions

    function to_string(slv : std_logic_vector) return string is
    variable l : line;
    variable color_txt : string(1 to 9);
    begin
        hwrite(l, slv);  -- Write hex value

        -- Check for specific color patterns
        if l.all(1 to 6) = "FF0000" then    -- Red
            color_txt := " (red)   ";
        elsif l.all(1 to 6) = "FFFFFF" then  -- White
            color_txt := " (white) ";
        elsif l.all(1 to 6) = "000000" then  -- Black
            color_txt := " (black) ";
        elsif l.all(1 to 6) = "FFFF00" then  -- Yellow
            color_txt := " (yellow)";
        elsif l.all(1 to 6) = "00FF00" then  -- Green
            color_txt := " (green) ";
        else
            color_txt := "         ";
        end if;

        return l.all(1 to 6) & color_txt;
    end function;


    function integer_to_std_logic(i : integer) return std_logic is
    begin
        if i /= 0 then
            return '1';
        else
            return '0';
        end if;
    end function;

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
      angle_i    : in  unsigned(7 downto 0);
      distance_i : in  std_logic_vector(8 downto 0);
      r_o        : out std_logic_vector(7 downto 0);
      g_o        : out std_logic_vector(7 downto 0);
      b_o        : out std_logic_vector(7 downto 0)
    );
  end component;


  -- Signals for interfacing with the designs
  signal clk_i   : std_logic := '0';
  signal rst_i   : std_logic := '0';
  signal vclk_o  : std_logic;
  signal hsync_o : std_logic;
  signal vsync_o : std_logic;
  signal blank_o : std_logic;
  signal sync_o  : std_logic;
  signal r_o     : std_logic_vector(7 downto 0);
  signal g_o     : std_logic_vector(7 downto 0);
  signal b_o     : std_logic_vector(7 downto 0);
  signal hpos     : integer;
  signal vpos     : integer;
  signal de       : std_logic;
  signal angle    : unsigned(7 downto 0) := "00000000"; -- (0 degrees)
  signal distance : std_logic_vector(8 downto 0) := "011001001"; -- (201 cm)
  -- Blinking signals
  signal blink_counter   : integer   := 0; -- Counter for blinking
  signal blink_state     : std_logic := '0'; -- Blink state (0 = off, 1 = on)
  constant c_BLINK_RATE  : integer   := 3000000; -- Blink rate


begin

  -- Instantiate  vga_controller
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

  -- Instantiate  draw_logic
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
  ----------------------------------------------------------------------------
  -- Clock generation process
  ----------------------------------------------------------------------------
  clk_gen : process
  begin
    while true loop
      clk_i <= '0';
      wait for clk_period/2;
      clk_i <= '1';
      wait for clk_period/2;
    end loop;
  end process clk_gen;

  ----------------------------------------------------------------------------
  -- Reset generation process
  ----------------------------------------------------------------------------
  reset_proc : process
  begin
      rst_i <= '0';
      wait for clk_period;
      rst_i <= '1';
      wait;
  end process;

  ----------------------------------------------------------------------------
  -- CSV-based Verification process
  ----------------------------------------------------------------------------
  verify_proc : process

     procedure verify_test_case(
    file_name     : string;
    test_case_num : integer
  ) is
    file csv_file      : text;
    variable csv_line  : line;
    variable x_ref     : integer;
    variable y_ref     : integer;
    variable hsync_ref : integer;
    variable vsync_ref : integer;
    variable blank_ref : integer;
    variable comma     : character;
    variable rgb_24    : std_logic_vector(23 downto 0);
  begin

      wait until blink_state = '1';
      wait until hpos = 0 and vpos = 0;

        file_open(csv_file, tb_path & file_name, read_mode);
        readline(csv_file, csv_line); -- Skip header

        while not endfile(csv_file) loop

            wait until rising_edge(vclk_o) and rst_i = '1';

            readline(csv_file, csv_line); -- Read CSV line
            read(csv_line, x_ref);
            read(csv_line, comma);
            read(csv_line, y_ref);
            read(csv_line, comma);
            read(csv_line, hsync_ref);
            read(csv_line, comma);
            read(csv_line, vsync_ref);
            read(csv_line, comma);
            read(csv_line, blank_ref);
            read(csv_line, comma);
            hread(csv_line, rgb_24);

            -- Verify coordinates using counters:
            check_equal(hpos, x_ref,
              "Position mismatch (horizontal): CSV: (" & integer'image(x_ref) & "," &
              integer'image(y_ref) & ") vs Actual: (" &
              integer'image(hpos) & "," &
              integer'image(vpos) & ")"
            );

            check_equal(vpos, y_ref,
              "Position mismatch (vertical): CSV: (" & integer'image(x_ref) & "," &
              integer'image(y_ref) & ") vs Actual: (" &
              integer'image(hpos) & "," &
              integer'image(vpos) & ")"
            );

            -- Assert HSYNC Signal
            check_equal(hsync_o, integer_to_std_logic(hsync_ref),
              "HSYNC error at (" & integer'image(hpos) & "," & integer'image(vpos) & "):" & LF &
              "expected " & integer'image(hsync_ref) & ", got " & std_logic'image(hsync_o)
            );

            -- Assert VSYNC Signal
            check_equal(vsync_o, integer_to_std_logic(vsync_ref),
              "VSYNC error at (" & integer'image(hpos) & "," & integer'image(vpos) & "):" & LF &
              "expected " & integer'image(vsync_ref) & ", got " & std_logic'image(vsync_o)
            );

            -- Assert BLANK Signal
            check_equal(blank_o, integer_to_std_logic(blank_ref),
              "BLANK error at (" & integer'image(hpos) & "," & integer'image(vpos) & "):" & LF &
              "expected " & integer'image(blank_ref) & ", got " & std_logic'image(blank_o)
            );

            -- Assert Color Values (RGB)
            check_equal(r_o & g_o & b_o, rgb_24,
              "Color error at (" & integer'image(hpos) & "," & integer'image(vpos) & "):" & LF &
              "expected " & to_string(rgb_24) & ", got " & to_string(r_o & g_o & b_o)
            );
        end loop;


         file_close(csv_file);
         report "Test case " & integer'image(test_case_num) &
            " (angle=" & integer'image(to_integer(unsigned(angle))) &
            " degrees, distance=" & integer'image(to_integer(unsigned(distance))) &
            " cm) verified successfully!"
          severity note;

        end procedure verify_test_case;

  begin
  test_runner_setup(runner, runner_cfg);
  while test_suite loop

   if run("test_less_than_minimum_distance") then
     -- Test Case 1:
     -- Test with a distance less than the minimum (2 cm),
     -- so no object should be shown.
     -- Expected behavior: No object (i.e., background color remains as defined)
     angle    <= "00011110"; -- 30 degrees
     distance <= "000000001"; -- 1 cm
     verify_test_case("vga_reference_0.csv", 1);

   elsif run("test_redzone_distance") then
     -- Test Case 2:
     -- Red zone test with a valid distance (100 cm) at 30 degrees.
     -- Expected behavior: Object appears in the red zone.
     angle    <= "00011110"; -- 30 degrees
     distance <= "001100100"; -- 100 cm
     verify_test_case("vga_reference_1.csv", 2);

   elsif run("test_yellowzone_distance") then
     -- Test Case 3:
     -- Yellow zone test with a valid distance (200 cm) at 90 degrees.
     -- Expected behavior: Object appears in the yellow zone.
     angle    <= "01011010"; -- 90 degrees
     distance <= "011001000"; -- 200 cm
     verify_test_case("vga_reference_2.csv", 3);

   elsif run("test_greenzone_distance") then
     -- Test Case 4:
     -- Green zone test with a valid distance (400 cm) at 120 degrees.
     -- Expected behavior: Object appears in the green zone.
     angle    <= "01111000"; -- 120 degrees
     distance <= "110010000"; -- 400 cm
     verify_test_case("vga_reference_3.csv", 4);

   elsif run("test_more_than_maximum_distance") then
     -- Test Case 5:
     -- Test with a distance exceeding the maximum (400 cm) at 120 degrees,
     -- so no object should be shown.
     -- Expected behavior: No object (i.e., background color remains as defined)
     angle    <= "01111000"; -- 120 degrees
     distance <= "110010001"; -- 401 cm
     verify_test_case("vga_reference_0.csv", 5);
   end if;
    end loop;
     -- Cleanup and completion
     report "All Test cases verified successfully!" severity note;
     test_runner_cleanup(runner);
     wait;

  end process verify_proc;

end architecture arch;
