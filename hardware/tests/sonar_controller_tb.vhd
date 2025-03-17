-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
--
-- Unit Name:     integrated_system_tb
--
-- Description:
--
--   This file implements a testbench for the integrated system that combines
--   the RC servo PWM generator, the ultrasonic sensor, and the VGA drawing logic.
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
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
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
library vunit_lib;
context vunit_lib.vunit_context;

entity integrated_system_tb is
  generic (
    runner_cfg : string;
    tb_path    : string  -- (if required for CSV reference)
  );
end entity integrated_system_tb;

architecture arch of integrated_system_tb is

  ----------------------------------------------------------------------------
  -- Constants and Signals
  ----------------------------------------------------------------------------
  constant c_CLK_HZ       : integer := 50000000;  -- Clock frequency: 50 MHz.
  constant c_PULSE_HZ     : integer := 50;        -- PWM frequency: 50 Hz.
  constant c_MIN_PULSE_US : integer := 600;       -- Minimum pulse width: 600 us.
  constant c_MAX_PULSE_US : integer := 2400;      -- Maximum pulse width: 2400 us.
  constant c_STEP_COUNT   : integer := 180;       -- Number of servo positions (0 to 179).

  constant c_CYCLES_PER_US   : integer := c_CLK_HZ / 1000000;                               -- Clock cycles per microsecond.
  constant c_MIN_COUNT       : integer := c_MIN_PULSE_US * c_CYCLES_PER_US;                 -- Minimum pulse count.
  constant c_MAX_COUNT       : integer := c_MAX_PULSE_US * c_CYCLES_PER_US;                 -- Maximum pulse count.
  constant c_CYCLES_PER_STEP : integer := (c_MAX_COUNT - c_MIN_COUNT) / (c_STEP_COUNT - 1); -- Pulse count increment per step.
  constant c_COUNTER_MAX     : integer := (c_CLK_HZ / c_PULSE_HZ) - 1;                      -- Maximum counter value for period.

  constant CLK_PERIOD          : time    := 20 ns;
  constant CONVERSION_FACTOR   : integer := 2900;
  constant TRIGGER_PULSE_COUNT : integer := 500;

  -- Global Signals
  signal clk_tb          : std_logic := '0';
  signal reset_tb        : std_logic := '1';

  signal angle_tb        : unsigned(7 downto 0) := (others => '0'); -- Angle (0 to 179)
  signal pwm_tb          : std_logic;                          -- PWM output signal

  signal start_tb        : std_logic := '1';
  signal echo_tb         : std_logic := '0';
  signal trigger_tb      : std_logic;
  signal done_tb         : std_logic;
  signal distance_cm_tb  : std_logic_vector(8 downto 0);
  signal object_found_tb : std_logic;

  signal vclk_tb  : std_logic;
  signal hsync_tb : std_logic;
  signal vsync_tb : std_logic;
  signal blank_tb : std_logic;
  signal sync_tb  : std_logic;
  signal r_tb     : std_logic_vector(7 downto 0);
  signal g_tb     : std_logic_vector(7 downto 0);
  signal b_tb     : std_logic_vector(7 downto 0);
  signal hpos_tb  : integer;
  signal vpos_tb  : integer;
  signal de_tb    : std_logic;

  -- Blinking Signals
  signal blink_counter  : integer   := 0;    -- Counter for blinking
  signal blink_state    : std_logic := '0';  -- Blink state (0 = off, 1 = on)
  constant c_BLINK_RATE : integer   := 3000000; -- Blink rate

  ----------------------------------------------------------------------------
  -- Helper Functions
  ----------------------------------------------------------------------------
  function to_string(slv : std_logic_vector) return string is
    variable l         : line;
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

  ----------------------------------------------------------------------------
  -- Component Declarations
  ----------------------------------------------------------------------------
  component rc_servo is
    port (
      clk_i   : in  std_logic;
      rst_i   : in  std_logic;
      angle_i : in  unsigned(7 downto 0);
      pwm_o   : out std_logic
    );
  end component;

  component Ultrasonic_Sensor is
    port (
      clk_i          : in  std_logic;
      rst_i          : in  std_logic;
      start_i        : in  std_logic;
      echo_i         : in  std_logic;
      trigger_o      : out std_logic;
      done_o         : out std_logic;
      distance_cm_o  : out std_logic_vector(8 downto 0);
      object_found_o : out std_logic
    );
  end component;

  component vga_controller is
    port (
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
    port (
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

begin
  ----------------------------------------------------------------------------
  -- Module Instantiation
  ----------------------------------------------------------------------------
  uut_servo : rc_servo
    port map (
      clk_i   => clk_tb,
      rst_i   => reset_tb,
      angle_i => angle_tb,
      pwm_o   => pwm_tb
    );

  uut_ultrasonic : Ultrasonic_Sensor
    port map (
      clk_i          => clk_tb,
      rst_i          => reset_tb,
      start_i        => start_tb,
      echo_i         => echo_tb,
      trigger_o      => trigger_tb,
      done_o         => done_tb,
      distance_cm_o  => distance_cm_tb,
      object_found_o => object_found_tb
    );

  uut_vga_ctrl : vga_controller
    port map (
      clk_i   => clk_tb,
      rst_i   => reset_tb,
      vclk_o  => vclk_tb,
      hsync_o => hsync_tb,
      vsync_o => vsync_tb,
      blank_o => blank_tb,
      sync_o  => sync_tb,
      hpos_o  => hpos_tb,
      vpos_o  => vpos_tb,
      de_o    => de_tb
    );

  uut_draw : draw_logic
    port map (
      clk_i      => clk_tb,
      rst_i      => reset_tb,
      hpos_i     => hpos_tb,
      vpos_i     => vpos_tb,
      de_i       => de_tb,
      angle_i    => angle_tb,
      distance_i => distance_cm_tb,
      r_o        => r_tb,
      g_o        => g_tb,
      b_o        => b_tb
    );

  ----------------------------------------------------------------------------
  -- Process for Controlling Blinking
  ----------------------------------------------------------------------------
  process(clk_tb)
  begin
    if rising_edge(clk_tb) then
      if reset_tb = '0' then
        blink_counter <= 0;
        blink_state   <= '0';
      else
        if blink_counter = c_BLINK_RATE then
          blink_counter <= 0;
          blink_state   <= not blink_state;  -- Toggle blink state
        else
          blink_counter <= blink_counter + 1;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- Clock Generation Process
  ----------------------------------------------------------------------------
  clk_gen : process
  begin
    while true loop
      clk_tb <= '0';
      wait for CLK_PERIOD/2;
      clk_tb <= '1';
      wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process clk_gen;

  ----------------------------------------------------------------------------
  -- Main Test Process
  ----------------------------------------------------------------------------
  main_proc : process
    variable pulse_start_time : time := 0 ns;
    variable pulse_width      : time := 0 ns;
    variable pulse_width_us   : integer := 0;  -- Calculated pulse width in microseconds
    variable expected_pulse   : integer := 0;  -- Expected pulse width in microseconds

    -- Procedure for generating echo pulse
    procedure pulse_echo(echo_cycles : integer) is
    begin
      wait for 10 us;  -- Wait before echo pulse
      wait for CLK_PERIOD * TRIGGER_PULSE_COUNT;  -- Wait after the trigger pulse
      echo_tb <= '1';
      wait for CLK_PERIOD * echo_cycles;
      echo_tb <= '0';
      wait until done_tb = '1';  -- Wait until measurement is complete
    end procedure;

    ----------------------------------------------------------------------------
    -- CSV-based Verification Procedure
    ----------------------------------------------------------------------------
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
      wait until (hpos_tb = 0 and vpos_tb = 0);

      file_open(csv_file, tb_path & file_name, read_mode);
      readline(csv_file, csv_line);  -- Skip header

      while not endfile(csv_file) loop
        wait until rising_edge(vclk_tb) and reset_tb = '1';

        readline(csv_file, csv_line);  -- Read CSV line
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
        check_equal(hpos_tb, x_ref,
          "Horizontal position mismatch: CSV (" & integer'image(x_ref) & ", " &
          integer'image(y_ref) & ") vs Actual (" &
          integer'image(hpos_tb) & ", " & integer'image(vpos_tb) & ")"
        );

        check_equal(vpos_tb, y_ref,
          "Vertical position mismatch: CSV (" & integer'image(x_ref) & ", " &
          integer'image(y_ref) & ") vs Actual (" &
          integer'image(hpos_tb) & ", " & integer'image(vpos_tb) & ")"
        );

        -- Assert HSYNC signal
        check_equal(hsync_tb, integer_to_std_logic(hsync_ref),
          "HSYNC error at (" & integer'image(hpos_tb) & ", " & integer'image(vpos_tb) & "):" & LF &
          "Expected " & integer'image(hsync_ref) & ", got " & std_logic'image(hsync_tb)
        );

        -- Assert VSYNC signal
        check_equal(vsync_tb, integer_to_std_logic(vsync_ref),
          "VSYNC error at (" & integer'image(hpos_tb) & ", " & integer'image(vpos_tb) & "):" & LF &
          "Expected " & integer'image(vsync_ref) & ", got " & std_logic'image(vsync_tb)
        );

        -- Assert BLANK signal
        check_equal(blank_tb, integer_to_std_logic(blank_ref),
          "BLANK error at (" & integer'image(hpos_tb) & ", " & integer'image(vpos_tb) & "):" & LF &
          "Expected " & integer'image(blank_ref) & ", got " & std_logic'image(blank_tb)
        );

        -- Assert Color Values (RGB)
        check_equal(r_tb & g_tb & b_tb, rgb_24,
          "Color error at (" & integer'image(hpos_tb) & ", " & integer'image(vpos_tb) & "):" & LF &
          "Expected " & to_string(rgb_24) & ", got " & to_string(r_tb & g_tb & b_tb)
        );
      end loop;
      file_close(csv_file);
    end procedure verify_test_case;

  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      -- Reset the system for each test
      reset_tb <= '0';
      start_tb <= '1';
      wait for CLK_PERIOD * 2;
      reset_tb <= '1';
      wait for CLK_PERIOD * 2;

      if run("test_normal_distance100") then
        ----------------------------------------------------------------------------
        -- Phase 1: RC Servo PWM Test (Angle: 30 degrees)
        ----------------------------------------------------------------------------
        angle_tb <= "00011110";  -- Set angle to 30degrees (binary representation)
        wait for 100 ns;         -- Small stabilization wait

        -- Measure PWM signal pulse width
        wait until rising_edge(pwm_tb);
        pulse_start_time := now;
        wait until falling_edge(pwm_tb);
        pulse_width    := now - pulse_start_time;
        pulse_width_us := integer(pulse_width / 1 us);

        -- Calculate expected pulse width
        expected_pulse := c_MIN_PULSE_US + (30 * (c_MAX_PULSE_US - c_MIN_PULSE_US)) / (c_STEP_COUNT - 1);
        check_equal((abs(pulse_width_us - expected_pulse) <= 10), true,
          "Error: Expected " & integer'image(expected_pulse) &
          " us, calculated " & integer'image(pulse_width_us) & " us");

        ----------------------------------------------------------------------------
        -- Phase 2: Ultrasonic Sensor Test (100 cm)
        ----------------------------------------------------------------------------
        start_tb <= '0';  -- Begin measurement
        pulse_echo(100 * CONVERSION_FACTOR);  -- Simulate echo for 100 cm
        check_equal(unsigned(distance_cm_tb), 100, "Normal distance 100cm check");
        check_equal(object_found_tb, '1', "Object found status");

        ----------------------------------------------------------------------------
        -- Phase 3: VGA Drawing Test
        ----------------------------------------------------------------------------
        -- In this simplified test, we assume the drawing logic renders a point
        -- at a fixed position based on CSV reference.
        verify_test_case("vga_reference_1.csv", 2);

      elsif run("test_less_than_minimum_distance") then
        ----------------------------------------------------------------------------
        -- Phase 1: RC Servo PWM Test (Angle: 30 degrees)
        ----------------------------------------------------------------------------
        angle_tb <= "00011110";  -- Set angle to 30 degrees
        wait for 100 ns;         -- Small stabilization wait

        wait until rising_edge(pwm_tb);
        pulse_start_time := now;
        wait until falling_edge(pwm_tb);
        pulse_width    := now - pulse_start_time;
        pulse_width_us := integer(pulse_width / 1 us);

        expected_pulse := c_MIN_PULSE_US + (30 * (c_MAX_PULSE_US - c_MIN_PULSE_US)) / (c_STEP_COUNT - 1);
        check_equal((abs(pulse_width_us - expected_pulse) <= 10), true,
          "Error: Expected " & integer'image(expected_pulse) &
          " us, calculated " & integer'image(pulse_width_us) & " us");

        ----------------------------------------------------------------------------
        -- Phase 2: Ultrasonic Sensor Test (Too Close: 1 cm)
        ----------------------------------------------------------------------------
        start_tb <= '0';  -- Begin measurement
        pulse_echo(1 * CONVERSION_FACTOR);  -- Simulate echo for 1 cm
        check_equal(unsigned(distance_cm_tb), 0, "Too close distance check");
        check_equal(object_found_tb, '0', "Object found status");

        ----------------------------------------------------------------------------
        -- Phase 3: VGA Drawing Test
        ----------------------------------------------------------------------------
        verify_test_case("vga_reference_0.csv", 1);

      elsif run("test_normal_distance200") then
        ----------------------------------------------------------------------------
        -- Phase 1: RC Servo PWM Test (Angle: 90 degrees)
        ----------------------------------------------------------------------------
        angle_tb <= "01011010";  -- Set angle to 90 degrees (binary representation)
        wait for 100 ns;         -- Small stabilization wait

        wait until rising_edge(pwm_tb);
        pulse_start_time := now;
        wait until falling_edge(pwm_tb);
        pulse_width    := now - pulse_start_time;
        pulse_width_us := integer(pulse_width / 1 us);

        expected_pulse := c_MIN_PULSE_US + (90 * (c_MAX_PULSE_US - c_MIN_PULSE_US)) / (c_STEP_COUNT - 1);
        check_equal((abs(pulse_width_us - expected_pulse) <= 10), true,
          "Error: Expected " & integer'image(expected_pulse) &
          " us, calculated " & integer'image(pulse_width_us) & " us");

        ----------------------------------------------------------------------------
        -- Phase 2: Ultrasonic Sensor Test (200 cm)
        ----------------------------------------------------------------------------
        start_tb <= '0';  -- Begin measurement
        pulse_echo(200 * CONVERSION_FACTOR);  -- Simulate echo for 200 cm
        check_equal(unsigned(distance_cm_tb), 200, "Normal distance 200cm check");
        check_equal(object_found_tb, '1', "Object found status");

        ----------------------------------------------------------------------------
        -- Phase 3: VGA Drawing Test
        ----------------------------------------------------------------------------
        verify_test_case("vga_reference_2.csv", 3);

      elsif run("test_normal_distance400") then
        ----------------------------------------------------------------------------
        -- Phase 1: RC Servo PWM Test (Angle: 120 degrees)
        ----------------------------------------------------------------------------
        angle_tb <= "01111000";  -- Set angle to 120 degrees (binary representation)
        wait for 100 ns;         -- Small stabilization wait

        wait until rising_edge(pwm_tb);
        pulse_start_time := now;
        wait until falling_edge(pwm_tb);
        pulse_width    := now - pulse_start_time;
        pulse_width_us := integer(pulse_width / 1 us);

        expected_pulse := c_MIN_PULSE_US + (120 * (c_MAX_PULSE_US - c_MIN_PULSE_US)) / (c_STEP_COUNT - 1);
        check_equal((abs(pulse_width_us - expected_pulse) <= 10), true,
          "Error: Expected " & integer'image(expected_pulse) &
          " us, calculated " & integer'image(pulse_width_us) & " us");

        ----------------------------------------------------------------------------
        -- Phase 2: Ultrasonic Sensor Test (400 cm)
        ----------------------------------------------------------------------------
        start_tb <= '0';  -- Begin measurement
        pulse_echo(400 * CONVERSION_FACTOR);  -- Simulate echo for 400 cm
        check_equal(unsigned(distance_cm_tb), 400, "Maximum valid distance check");
        check_equal(object_found_tb, '1', "Object found status");

        ----------------------------------------------------------------------------
        -- Phase 3: VGA Drawing Test
        ----------------------------------------------------------------------------
        verify_test_case("vga_reference_3.csv", 4);

      elsif run("test_more_than_maximum_distance") then
        ----------------------------------------------------------------------------
        -- Phase 1: RC Servo PWM Test (Angle: 120 degrees)
        ----------------------------------------------------------------------------
        angle_tb <= "01111000";  -- Set angle to 120 degrees (binary representation)
        wait for 100 ns;         -- Small stabilization wait

        wait until rising_edge(pwm_tb);
        pulse_start_time := now;
        wait until falling_edge(pwm_tb);
        pulse_width    := now - pulse_start_time;
        pulse_width_us := integer(pulse_width / 1 us);

        expected_pulse := c_MIN_PULSE_US + (120 * (c_MAX_PULSE_US - c_MIN_PULSE_US)) / (c_STEP_COUNT - 1);
        check_equal((abs(pulse_width_us - expected_pulse) <= 10), true,
          "Error: Expected " & integer'image(expected_pulse) &
          " us, calculated " & integer'image(pulse_width_us) & " us");

        ----------------------------------------------------------------------------
        -- Phase 2: Ultrasonic Sensor Test (Timeout: 401 cm)
        ----------------------------------------------------------------------------
        start_tb <= '0';  -- Begin measurement
        pulse_echo(401 * CONVERSION_FACTOR);  -- Simulate echo for 401 cm (timeout)
        check_equal(unsigned(distance_cm_tb), 512, "Timeout distance check");
        check_equal(object_found_tb, '0', "Object not found status");

        ----------------------------------------------------------------------------
        -- Phase 3: VGA Drawing Test
        ----------------------------------------------------------------------------
        verify_test_case("vga_reference_0.csv", 5);
      end if;
    end loop;

    test_runner_cleanup(runner);
    wait;
  end process main_proc;

end architecture arch;
