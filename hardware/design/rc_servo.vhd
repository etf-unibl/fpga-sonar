-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
-- unit name:     RC Servo Controller
--
-- description:
--
--   This file implements an RC servo PWM controller.
--   The controller cycles through a fixed number of servo positions
--   (180 positions) by generating a PWM signal.
--   The PWM period is 20 ms (50 Hz) and the duty cycle is updated on each PWM period.
--   The servo reverses direction when reaching the boundaries (position 0 or 179).
--
--   Two main processes are implemented:
--     1. PWM_AND_STEP: Counts clock cycles in each PWM period and updates the servo position
--        along with recalculating the duty cycle for the next PWM period.
--     2. PWM_GEN: Generates the PWM output signal by comparing the counter with the duty cycle.
-----------------------------------------------------------------------------
-- Copyright (c) 2023 Faculty of Electrical Engineering
-----------------------------------------------------------------------------
-- The MIT License
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief RC Servo Controller entity.
--! @details Generates a PWM signal to control an RC servo motor.
entity rc_servo is
  port (
    clk_i      : in  std_logic;  --! Clock signal.
    rst_i      : in  std_logic;  --! Asynchronous reset signal (active low).
    pwm_o      : out std_logic   --! PWM output signal.
  );
end rc_servo;

--! @brief RC Servo Controller RTL architecture.
--! @details Implements the logic for PWM signal generation and servo position control.
architecture arch of rc_servo is

  --! @brief Fixed parameter values.
  --! @details Defines clock frequency, PWM frequency, minimum and maximum pulse widths,
  --!          and the total number of servo positions.
  constant c_CLK_HZ       : integer := 50000000;  --! Clock frequency: 50 MHz.
  constant c_PULSE_HZ     : integer := 50;        --! PWM frequency: 50 Hz.
  constant c_MIN_PULSE_US : integer := 600;       --! Minimum pulse width: 600 us (0.6 ms).
  constant c_MAX_PULSE_US : integer := 2400;      --! Maximum pulse width: 2400 us (2.4 ms).
  constant c_STEP_COUNT   : integer := 180;       --! Number of servo positions (0 to 179).

  --! @brief Calculated values for PWM generation.
  --! @details Computes clock cycles per microsecond, count values corresponding to pulse widths,
  --!          the count increment per servo step, and the maximum counter value per PWM period.
  constant c_CYCLES_PER_US   : integer := c_CLK_HZ / 1000000;   --! Clock cycles per microsecond.
  constant c_MIN_COUNT       : integer := c_MIN_PULSE_US * c_CYCLES_PER_US;  --! Minimum count for pulse width.
  constant c_MAX_COUNT       : integer := c_MAX_PULSE_US * c_CYCLES_PER_US;  --! Maximum count for pulse width.
  constant c_CYCLES_PER_STEP : integer := (c_MAX_COUNT - c_MIN_COUNT) / (c_STEP_COUNT - 1); --! Count increment per servo step.
  constant c_COUNTER_MAX     : integer := (c_CLK_HZ / c_PULSE_HZ) - 1;  --! Maximum counter value for one PWM period (20 ms).

  --! @brief Internal signals used for PWM generation and servo control.
  signal counter     : integer range 0 to c_COUNTER_MAX := 0;  --! Counter for clock cycles in a PWM period.
  signal duty_cycle  : integer range 0 to c_MAX_COUNT := c_MIN_COUNT;  --! Current duty cycle count.
  signal current_pos : integer range 0 to c_STEP_COUNT-1 := 0;  --! Current servo position index.
  signal direction   : integer range -1 to 1 := 1;  --! Direction of servo movement: 1 = increasing, -1 = decreasing.
  signal pwm_reg     : std_logic := '0';  --! Internal signal for PWM output.

begin

  pwm_o <= pwm_reg;

  -------------------------------------------------------------------------
  --! @brief Process for PWM period counting and servo position update.
  --! @details
  --!   - Counts clock cycles for each PWM period.
  --!   - On completing a PWM period, resets the counter and updates the servo position.
  --!   - Recalculates the duty cycle based on the new servo position.
  --!   - Supports asynchronous reset via rst_i.
  -------------------------------------------------------------------------
  PWM_AND_STEP : process(clk_i, rst_i)
    variable new_pos : integer;
  begin
    if rst_i = '0' then
      counter     <= 0;
      current_pos <= 0;
      duty_cycle  <= c_MIN_COUNT;
      direction   <= 1;
    elsif rising_edge(clk_i) then
      if counter < c_COUNTER_MAX then
        counter <= counter + 1;
      else
        counter <= 0;
        -- Change direction if the servo has reached either boundary.
        if current_pos = c_STEP_COUNT - 1 then
          direction <= -1;
        elsif current_pos = 0 then
          direction <= 1;
        end if;
        new_pos := current_pos + direction;
        current_pos <= new_pos;
        duty_cycle <= new_pos * c_CYCLES_PER_STEP + c_MIN_COUNT;
      end if;
    end if;
  end process PWM_AND_STEP;

  -------------------------------------------------------------------------
  --! @brief Process for generating the PWM output signal.
  --! @details
  --!   - On each clock cycle, compares the current counter with the duty_cycle.
  --!   - Sets the PWM output high ('1') when the counter is less than the duty_cycle; otherwise, sets it low ('0').
  --!   - Immediately resets the output to '0' when rst_i is active.
  -------------------------------------------------------------------------
  PWM_GEN : process(clk_i, rst_i)
  begin
    if rst_i = '0' then
      pwm_reg <= '0';
    elsif rising_edge(clk_i) then
      if counter < duty_cycle then
        pwm_reg <= '1';
      else
        pwm_reg <= '0';
      end if;
    end if;
  end process PWM_GEN;

end architecture arch;
