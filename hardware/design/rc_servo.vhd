-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
-- unit name:     Servo
--
-- description:
--
--   This file implements the servo PWM generator module.
--   The module receives an angle input (0 to 179) and generates a PWM signal
--   to control an RC servo motor.
--   The PWM period is 20 ms (50 Hz) and the pulse width is linearly interpolated
--   between a minimum of 600 us and a maximum of 2400 us based on the angle.
--
--   Two main processes are implemented:
--     1. DUTY_CYCLE_CALC: Computes the duty cycle corresponding to the given angle.
--     2. PWM_GEN: Generates the PWM output signal by comparing the counter with the duty cycle.
-----------------------------------------------------------------------------
-- Copyright (c) 2023 Faculty of Electrical Engineering
-----------------------------------------------------------------------------
-- The MIT License
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rc_servo is
  port (
    clk_i   : in  std_logic;              --! Clock signal (50 MHz).
    rst_i   : in  std_logic;              --! Asynchronous reset signal (active low).
    angle_i : in  unsigned(7 downto 0);   --! Servo angle input (0 to 179).
    pwm_o   : out std_logic               --! PWM output signal.
  );
end rc_servo;

architecture arch of rc_servo is

  --! @brief Fixed parameter values.
  --! @details Defines clock frequency, PWM frequency, and pulse width limits.
  constant c_CLK_HZ       : integer := 50000000;  --! Clock frequency: 50 MHz.
  constant c_PULSE_HZ     : integer := 50;        --! PWM frequency: 50 Hz.
  constant c_MIN_PULSE_US : integer := 600;       --! Minimum pulse width: 600 us.
  constant c_MAX_PULSE_US : integer := 2400;      --! Maximum pulse width: 2400 us.
  constant c_STEP_COUNT   : integer := 180;       --! Number of servo positions (0 to 179).

  --! @brief Calculated values for PWM generation.
  --! @details Computes clock cycles per microsecond, corresponding pulse count limits,
  --!          count increment per servo step, and maximum counter value per PWM period.
  constant c_CYCLES_PER_US   : integer := c_CLK_HZ / 1000000;                               --! Clock cycles per microsecond.
  constant c_MIN_COUNT       : integer := c_MIN_PULSE_US * c_CYCLES_PER_US;                 --! Minimum pulse count.
  constant c_MAX_COUNT       : integer := c_MAX_PULSE_US * c_CYCLES_PER_US;                 --! Maximum pulse count.
  constant c_CYCLES_PER_STEP : integer := (c_MAX_COUNT - c_MIN_COUNT) / (c_STEP_COUNT - 1); --! Pulse count increment per step.
  constant c_COUNTER_MAX     : integer := (c_CLK_HZ / c_PULSE_HZ) - 1;                      --! Max counter value for period.

  --! @brief Internal signals used for PWM generation.
  signal counter    : integer range 0 to c_COUNTER_MAX := 0;          --! Counter for clock cycles in a PWM period.
  signal duty_cycle : integer range 0 to c_MAX_COUNT := c_MIN_COUNT;  --! Current duty cycle count.
  signal pwm_reg    : std_logic := '0';                               --! Internal signal for PWM output.

begin

  -------------------------------------------------------------------------
  --! @brief Process for calculating duty cycle.
  --! @details
  --!   Computes the duty cycle based on the input angle using linear interpolation.
  --!   The formula used is:
  --!     duty_cycle = c_MIN_COUNT + angle * c_CYCLES_PER_STEP
  -------------------------------------------------------------------------
  process(angle_i)
    variable angle_int : integer;
  begin
    angle_int := to_integer(angle_i);
    if angle_int < 0 then
      angle_int := 0;
    elsif angle_int > c_STEP_COUNT - 1 then
      angle_int := c_STEP_COUNT - 1;
    end if;
    duty_cycle <= c_MIN_COUNT + angle_int * c_CYCLES_PER_STEP;
  end process;

  -------------------------------------------------------------------------
  --! @brief Process for generating the PWM output signal.
  --! @details
  --!   - Counts clock cycles for each PWM period.
  --!   - Sets the PWM output high ('1') when the counter is less than the duty_cycle,
  --!     otherwise sets it low ('0').
  --!   - Supports asynchronous reset via rst_i.
  -------------------------------------------------------------------------
  process(clk_i, rst_i)
  begin
    if rst_i = '0' then
      counter <= 0;
      pwm_reg <= '0';
    elsif rising_edge(clk_i) then
      if counter < c_COUNTER_MAX then
        counter <= counter + 1;
      else
        counter <= 0;
      end if;

      if counter < duty_cycle then
        pwm_reg <= '1';
      else
        pwm_reg <= '0';
      end if;
    end if;
  end process;

  pwm_o <= pwm_reg;

end architecture arch;
