-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
--
-- unit name:     vga_controller_tb
--
-- description:
--
--   This file implements a testbench for the vga_controller design
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

entity vga_controller_tb is
  generic (
    runner_cfg : string;
    tb_path    : string
    );
end entity;

architecture sim of vga_controller_tb is
    component vga_controller is
      port(
        clk_i   : in  STD_LOGIC;  -- Clock signal
        RST_i   : in  STD_LOGIC;  -- Reset signal
        VCLK_o  : out STD_LOGIC;  -- VGA pixel clock output (25 MHz)
        HSYNC_o : out STD_LOGIC;  -- Horizontal sync output
        VSYNC_o : out STD_LOGIC;  -- Vertical sync output
        BLANK_o : out STD_LOGIC;  -- Blanking signal output
        SYNC_o  : out STD_LOGIC;  -- Sync signal
        R_o     : out STD_LOGIC_VECTOR(7 downto 0); -- Red channel (8 bits)
        G_o     : out STD_LOGIC_VECTOR(7 downto 0); -- Green channel (8 bits)
        B_o     : out STD_LOGIC_VECTOR(7 downto 0)  -- Blue channel (8 bits)
        );
    end component;

    signal clk_50MHz : std_logic := '0';
    signal RST       : std_logic := '0';
    signal VCLK      : std_logic;
    signal HSYNC     : std_logic;
    signal VSYNC     : std_logic;
    signal BLANK     : std_logic;
    signal SYNC      : std_logic;
    signal R, G, B   : std_logic_vector(7 downto 0);

    -- Original counters
    signal h_counter : integer := 0;
    signal v_counter : integer := 0;

    -- Helper functions
    function to_string(slv : std_logic_vector) return string is
        variable l : line;
        variable color_txt : string(1 to 8);
    begin
        hwrite(l, slv);  -- Write hex value

        -- Check for specific color patterns
        if l.all(1 to 6) = "FF0000" then    -- Red
            color_txt := " (red)  ";
        elsif l.all(1 to 6) = "FFFFFF" then -- White
            color_txt := " (white)";
        elsif l.all(1 to 6) = "000000" then -- Black
            color_txt := " (black)";
        else
            color_txt := "        ";
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

    -- Instantiate DUT
    dut : vga_controller
        port map(
            clk_i   => clk_50MHz,
            RST_i   => RST,
            VCLK_o  => VCLK,
            HSYNC_o => HSYNC,
            VSYNC_o => VSYNC,
            BLANK_o => BLANK,
            SYNC_o  => SYNC,
            R_o     => R,
            G_o     => G,
            B_o     => B
        );

    -- 50 MHz clock generation
    clk_50MHz <= not clk_50MHz after 10 ns;

    -- Reset generation
    reset_proc : process
    begin
        RST <= '0';
        wait for 20 ns;
        RST <= '1';
        wait;
    end process;

    -- Position counters
    process(VCLK, RST)
    begin
        if RST = '0' then
            h_counter <= 0;
            v_counter <= 0;
        elsif rising_edge(VCLK) then
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


    -- CSV-based verification with counters
    -- The design uses a synchronous clk25-based robust build that updates outputs on the rising edge of clk25,
    -- this ensures predictable timing and stable behavior across the design.
    -- This build appears delayed by one clock cycle, resulting in a one-pixel horizontal shift.
    -- This shift is expected and is accounted for in the testbench analysis by shifting the values in the CSV.
    -- While an alternative, combinational design with assigning outputs using concurrent statements might
    -- align the output values exactly (without a one-cycle delay), it is less robust overall.

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

            wait until rising_edge(VCLK) and RST = '1';

            readline(csv_file, csv_line); -- Read CSV line
            read(csv_line, x_ref);
            read(csv_line, comma);
            read(csv_line, y_ref);
            read(csv_line, comma);
            hread(csv_line, rgb_24);
            read(csv_line, comma);
            read(csv_line, hsync_ref);
            read(csv_line, comma);
            read(csv_line, vsync_ref);
            read(csv_line, comma);
            read(csv_line, blank_ref);

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

           -- Verify HSYNC
           check_equal(HSYNC, integer_to_std_logic(hsync_ref),
             "HSYNC error at (" & integer'image(h_counter) & "," & integer'image(v_counter) & "):" & LF &
             "expected " & integer'image(hsync_ref) & ", got " & std_logic'image(HSYNC)
           );

           -- Verify VSYNC
           check_equal(VSYNC, integer_to_std_logic(vsync_ref),
             "VSYNC error at (" & integer'image(h_counter) & "," & integer'image(v_counter) & "):" & LF &
             "expected " & integer'image(vsync_ref) & ", got " & std_logic'image(VSYNC)
           );

           -- Verify BLANK
           check_equal(BLANK, integer_to_std_logic(blank_ref),
             "BLANK error at (" & integer'image(h_counter) & "," & integer'image(v_counter) & "):" & LF &
             "expected " & integer'image(blank_ref) & ", got " & std_logic'image(BLANK)
           );

           -- Verify color values (red square region)
           -- Check that the concatenation of R, G, B equals the 24-bit reference.
           check_equal(R & G & B, rgb_24,
             "Color error at (" & integer'image(h_counter) & "," & integer'image(v_counter) & "):" & LF &
             "expected " & to_string(rgb_24) & ", got " & to_string(R & G & B)
           );
        end loop;

        -- Cleanup and completion
        file_close(csv_file);
        report "All pixels verified successfully!" severity note;
        -- End simulation via VUnit's mechanism
        test_runner_cleanup(runner);
        wait;
    end process;

end architecture;
