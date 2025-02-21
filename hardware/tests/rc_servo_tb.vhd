-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
-- unit name:    rc_servo_tb
--
-- description:
--
--   This file implements a testbench for the RC servo PWM controller.
--   The testbench verifies that the PWM signal cycles through three
--   fixed servo positions (0, 90, 180 degrees) by checking the duty cycle
--   at each update interval.
--
--   The PWM signal has a period of 20 ms (50 Hz), and the servo position
--   updates every 50 PWM periods (approximately 1 second).
-----------------------------------------------------------------------------
-- Copyright (c) 2024 Faculty of Electrical Engineering
-----------------------------------------------------------------------------
-- The MIT License
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vunit_lib;
context vunit_lib.vunit_context;

entity rc_servo_tb is
  generic (runner_cfg : string);
end rc_servo_tb;

architecture arch of rc_servo_tb is
  signal clk_i  : std_logic := '0';
  signal rst_i  : std_logic := '0';
  signal pwm_o  : std_logic;

  -- Constants from the design
  constant c_CLK_HZ       : integer := 50000000;  -- Clock frequency: 50 MHz
  constant c_PULSE_HZ     : integer := 50;        -- PWM frequency: 50 Hz
  constant c_MIN_PULSE_US : integer := 600;       -- Minimum pulse width (600 us)
  constant c_MAX_PULSE_US : integer := 2400;      -- Maximum pulse width (2400 us)
  constant c_STEP_COUNT   : integer := 3;         -- Number of servo positions

  -- Derived constants
  constant c_CYCLES_PER_US   : integer := c_CLK_HZ / 1000000; -- Clock cycles per microsecond
  constant c_MIN_COUNT       : integer := c_MIN_PULSE_US * c_CYCLES_PER_US; -- Counter value for min duty cycle
  constant c_MAX_COUNT       : integer := c_MAX_PULSE_US * c_CYCLES_PER_US; -- Counter value for max duty cycle
  constant c_CYCLES_PER_STEP : integer := (c_MAX_COUNT - c_MIN_COUNT) / (c_STEP_COUNT - 1); -- Step size for duty cycle change
  constant c_COUNTER_MAX     : integer := (c_CLK_HZ / c_PULSE_HZ) - 1;  -- Max counter value for 20 ms period
  constant c_UPDATE_PERIOD   : integer := 50;  -- Number of PWM periods before position update (50 periods = 1s)

  -- Clock period
  constant c_CLK_PERIOD : time := 20 ns; -- 50 MHz clock period

-- Declare the rc_servo component
  component rc_servo
    port (
    clk_i  : in std_logic;
    rst_i  : in std_logic;
    pwm_o  : out std_logic
  );
  end component;


begin
  uut : rc_servo
    port map (
      clk_i => clk_i,
      rst_i => rst_i,
      pwm_o => pwm_o
    );

  -- Clock signal
  clk_process : process
  begin
    while true loop
      clk_i <= '0';
      wait for c_CLK_PERIOD / 2;
      clk_i <= '1';
      wait for c_CLK_PERIOD / 2;
    end loop;
  end process clk_process;

-- PWM_MONITOR: Captures the PWM pulse width at each rising and
-- falling edge, calculates the expected duty cycle based on the
-- servo position, and asserts correctness.

  pwm_monitor_process : process
    variable pulse_start_time  : time := 0 ns;
    variable pulse_width       : time := 0 ns;
    variable pulse_width_us    : integer := 0;
    variable position          : integer := 0; -- 0, 1, 2
    variable expected_pulse    : integer := 0;
    constant PWM_PERIOD        : time := 20 ms;
    variable current_time_ms   : integer := 0;
  begin
    test_runner_setup(runner, runner_cfg);
    while now < 4 sec loop
      wait until rising_edge(pwm_o);
      pulse_start_time := now;

      wait until falling_edge(pwm_o);
      pulse_width := now - pulse_start_time;
      pulse_width_us := integer(pulse_width / 1 us);

      -- The position changes based on time (every second)
      position := (now / (PWM_PERIOD * c_UPDATE_PERIOD)) mod c_STEP_COUNT;

        -- Calculating expected duty cycle
      expected_pulse := (position * c_CYCLES_PER_STEP + c_MIN_COUNT) / c_CYCLES_PER_US;

        -- Current time in ms
      current_time_ms := integer(now / 1 ms);
      report "Time: " & integer'image(current_time_ms) & " ms, PWM width: " &
               integer'image(pulse_width_us) & " us (Expected: " & integer'image(expected_pulse) & " us)"
            severity note;

        -- Check real and expected duty cycle
      assert abs(pulse_width_us - expected_pulse) <= 10
            report "ERROR: Expected " & integer'image(expected_pulse) &
                   " us, but PWM width is: " & integer'image(pulse_width_us) & " us"
            severity error;

      wait for 20 ms;
    end loop;

      report "Simulation completed. PWM check successful." severity note;
    test_runner_cleanup(runner);
    wait;
  end process pwm_monitor_process;

 -- STIMULUS: Initializes the simulation and applies the clock signal.
  stimulus_process : process
  begin
    -- Reset
    rst_i <= '0';
    wait for 100 ns;
    rst_i <= '1';

    -- Simulation runs for a few seconds to observe servo position changes.
    wait for 4 sec;

    assert false report "Testbench completed!" severity note;
    wait;
  end process stimulus_process;

end architecture arch;
