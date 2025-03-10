-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
--
-- unit name:     top_level_tb
--
-- description:
--
--   This file implements a testbench for the VGA controller circle drawing logic
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

entity top_level_tb is
  generic (
    runner_cfg : string;
    tb_path    : string
    );
end entity top_level_tb;

architecture arch of top_level_tb is

   component top_level is
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
   end component;

  -- Signals for interfacing with the top-level design
  signal clk_i   : std_logic := '0';
  signal rst_i   : std_logic := '0';
  signal vclk_o  : std_logic;
  signal hsync_o : std_logic;
  signal vsync_o : std_logic;
  signal blank_o : std_logic;
  signal sync_o  : std_logic;
  signal h_counter : integer := 0;
  signal v_counter : integer := 0;
  signal r_o     : std_logic_vector(7 downto 0);
  signal g_o     : std_logic_vector(7 downto 0);
  signal b_o     : std_logic_vector(7 downto 0);

  constant c_CLK_PERIOD : time := 20 ns;


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

begin

  -- Instantiate the top-level design
  DUT : top_level
    port map (
      clk_i   => clk_i,
      rst_i   => rst_i,
      vclk_o  => vclk_o,
      hsync_o => hsync_o,
      vsync_o => vsync_o,
      blank_o => blank_o,
      sync_o  => sync_o,
      r_o     => r_o,
      g_o     => g_o,
      b_o     => b_o
    );

    -- Position counter
    pos_counters : process(vclk_o, rst_i)
    begin
        if rst_i = '0' then
            h_counter <= 0;
            v_counter <= 0;
        elsif rising_edge(vclk_o) then
            if h_counter = 799 then
                h_counter <= 0;
                if v_counter = 524 then
                    v_counter <= 0;
                else
                    v_counter <= v_counter + 1;
                end if;
            else
                h_counter <= h_counter + 1;
            end if;
        end if;
    end process;

  -- Clock generation
  clk_gen : process
  begin
    while true loop
      clk_i <= '0';
      wait for c_CLK_PERIOD/2;
      clk_i <= '1';
      wait for c_CLK_PERIOD/2;
    end loop;
  end process clk_gen;

  -- Reset generation
  reset_proc : process
  begin
      rst_i <= '0';
      wait for c_CLK_PERIOD;
      rst_i <= '1';
      wait;
  end process;


  -- CSV-based verification with counters
  verify_proc : process
    file csv_file     : text;
    variable csv_line : line;
    variable x_ref    : integer;
    variable y_ref    : integer;
    variable hsync_ref : integer;
    variable vsync_ref : integer;
    variable blank_ref : integer;
    variable comma    : character;
    variable rgb_24   : std_logic_vector(23 downto 0);
  begin
   test_runner_setup(runner, runner_cfg);


    -- Open reference file
    file_open(csv_file, tb_path & "vga_reference.csv", read_mode);
    readline(csv_file, csv_line); -- Skip header

       -- Verification loop
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
            check_equal(h_counter, x_ref,
              "Position mismatch (horizontal): CSV: (" & integer'image(x_ref) & "," &
              integer'image(y_ref) & ") vs Actual: (" &
              integer'image(h_counter) & "," &
              integer'image(v_counter) & ")"
            );

            check_equal(v_counter, y_ref,
              "Position mismatch (vertical): CSV: (" & integer'image(x_ref) & "," &
              integer'image(y_ref) & ") vs Actual: (" &
              integer'image(h_counter) & "," &
              integer'image(v_counter) & ")"
            );

            -- Assert HSYNC Signal
            check_equal(hsync_o, integer_to_std_logic(hsync_ref),
              "HSYNC error at (" & integer'image(h_counter) & "," & integer'image(v_counter) & "):" & LF &
              "expected " & integer'image(hsync_ref) & ", got " & std_logic'image(hsync_o)
            );

            -- Assert VSYNC Signal
            check_equal(vsync_o, integer_to_std_logic(vsync_ref),
              "VSYNC error at (" & integer'image(h_counter) & "," & integer'image(v_counter) & "):" & LF &
              "expected " & integer'image(vsync_ref) & ", got " & std_logic'image(vsync_o)
            );

            -- Assert BLANK Signal
            check_equal(blank_o, integer_to_std_logic(blank_ref),
              "BLANK error at (" & integer'image(h_counter) & "," & integer'image(v_counter) & "):" & LF &
              "expected " & integer'image(blank_ref) & ", got " & std_logic'image(blank_o)
            );

            -- Assert Color Values (RGB)
            check_equal(r_o & g_o & b_o, rgb_24,
              "Color error at (" & integer'image(h_counter) & "," & integer'image(v_counter) & "):" & LF &
              "expected " & to_string(rgb_24) & ", got " & to_string(r_o & g_o & b_o)
            );
        end loop;

        -- Cleanup and completion
        file_close(csv_file);
        report "All pixels verified successfully!" severity note;
        -- End simulation via VUnit's mechanism
        test_runner_cleanup(runner);
        wait;
  end process verify_proc;

end architecture arch;
