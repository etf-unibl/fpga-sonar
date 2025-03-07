----------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
----------------------------------------------------------------------------------
-- unit name:     rc_servo_tb
--
-- description:
--
-- This testbench implements a simulation for a module that generates a PWM signal
-- to control an RC servo motor. The purpose of the testbench is to verify the
-- correctness of the PWM generator for different input angles (0 to 179 degrees).
-- The PWM signal has a period of 20 ms (50 Hz), and the pulse width is linearly
-- interpolated between a minimum value of 600 us and a maximum value of 2400 us,
-- depending on the input angle.
--
----------------------------------------------------------------------------------
-- Copyright (c) 2024 Faculty of Electrical Engineering
----------------------------------------------------------------------------------
-- The MIT License
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vunit_lib;
context vunit_lib.vunit_context;

entity rc_servo_tb is
generic (runner_cfg : string);
end rc_servo_tb;

architecture arch of rc_servo_tb is

  component rc_servo
    port (
      clk_i   : in  std_logic;
      rst_i   : in  std_logic;
      angle_i : in  unsigned(7 downto 0);
      pwm_o   : out std_logic
    );
  end component;

  signal clk_i   : std_logic := '0'; -- Clock signal (50 MHz)
  signal rst_i   : std_logic := '0'; -- Reset signal (active low)
  signal angle_i : unsigned(7 downto 0) := (others => '0'); -- Angle from 0 to 179
  signal pwm_o   : std_logic; -- PWM output signal

  constant c_CLK_HZ       : integer := 50000000;  -- Clock frequency: 50 MHz.
  constant c_PULSE_HZ     : integer := 50;        -- PWM frequency: 50 Hz.
  constant c_MIN_PULSE_US : integer := 600;       -- Minimum pulse width: 600 us.
  constant c_MAX_PULSE_US : integer := 2400;      -- Maximum pulse width: 2400 us.
  constant c_STEP_COUNT   : integer := 180;       -- Number of servo positions (0 to 179).

  constant c_CYCLES_PER_US   : integer := c_CLK_HZ / 1000000;                               -- Clock cycles per microsecond.
  constant c_MIN_COUNT       : integer := c_MIN_PULSE_US * c_CYCLES_PER_US;                 -- Minimum pulse count.
  constant c_MAX_COUNT       : integer := c_MAX_PULSE_US * c_CYCLES_PER_US;                 -- Maximum pulse count.
  constant c_CYCLES_PER_STEP : integer := (c_MAX_COUNT - c_MIN_COUNT) / (c_STEP_COUNT - 1); -- Pulse count increment per step.
  constant c_COUNTER_MAX     : integer := (c_CLK_HZ / c_PULSE_HZ) - 1;                      -- Max counter value for period.

  constant CLK_PERIOD : time := 20 ns; -- 50 MHz clock period

  signal stop_simulation : boolean := false;

begin

  uut : rc_servo
    port map (
      clk_i => clk_i,
      rst_i => rst_i,
      angle_i => angle_i,
      pwm_o => pwm_o
    );

  clk_process : process
  begin
    while not stop_simulation loop
      clk_i <= '0';
      wait for CLK_PERIOD / 2;
      clk_i <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process clk_process;

  -- Proces for testing different angles
  test_process : process
    type angle_array is array (0 to 9) of integer;
    constant angles : angle_array := (0, 20, 45, 60, 90, 120, 135, 160, 179, 50); -- 10 angles
    variable pulse_start_time  : time := 0 ns;
    variable pulse_width       : time := 0 ns;
    variable pulse_width_us    : integer := 0; -- calculated duty cycle for angle
    variable expected_pulse    : integer := 0; -- expected duty cycle for angle
  begin
  test_runner_setup(runner, runner_cfg);
    -- Rreset active low
    rst_i <= '0';
    wait for 100 ns;
    rst_i <= '1';
    wait for 100 ns;

    for i in angles'range loop
      angle_i <= to_unsigned(angles(i), 8);
      wait for 1 ms;

      -- Start of PWM signal
      wait until rising_edge(pwm_o);
      pulse_start_time := now;

      -- End of PWM signal
      wait until falling_edge(pwm_o);
      pulse_width := now - pulse_start_time;
      pulse_width_us := integer(pulse_width / 1 us);

      -- Calculate expected duty_cycle
      expected_pulse := c_MIN_PULSE_US + (angles(i) * (c_MAX_PULSE_US - c_MIN_PULSE_US)) / (c_STEP_COUNT - 1);

      report "Angle: " & integer'image(angles(i)) &
             ", PWM width: " & integer'image(pulse_width_us) & " us (Expected: " & integer'image(expected_pulse) & " us)"
          severity note;

      assert abs(pulse_width_us - expected_pulse) <= 10
          report "Error: Expected " & integer'image(expected_pulse) &
                 " us, calculated " & integer'image(pulse_width_us) & " us"
          severity error;

      wait for 20 ms - pulse_width;
    end loop;

    -- End of simulation
    report "Simulation completed. All tests passed successfully." severity note;
    stop_simulation <= true;
    test_runner_cleanup(runner);
    wait;
  end process;

end architecture arch;
