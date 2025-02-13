-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
-- unit name:     RC Servo Controller
--
-- description:
--
--   This file implements an RC servo pwm_o controller.
--   The controller cycles through a fixed number of servo positions
--   (three positions) by generating a pwm_o signal.
--   The pwm_o period is 20 ms (50 Hz) and the duty cycle is updated every
--   50 periods (approximately 1 second) to change the servo position.
--
--   Two main processes are implemented:
--     1. PWM_AND_STEP: Counts clock cycles over a pwm_o period, updates
--        the update counter, and cyclically adjusts the servo position
--        and corresponding duty cycle.
--     2. PWM_GEN: Generates the pwm_o output signal by comparing the
--        counter with the duty cycle.
-----------------------------------------------------------------------------
-- Copyright (c) 2023 Faculty of Electrical Engineering
-----------------------------------------------------------------------------
-- The MIT License
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief RC Servo Controller entity.
--! @details Generates a pwm_o signal used to control an RC servo motor.
entity rc_servo is
  port (
    clk_i : in  std_logic;  --! Clock signal.
    rst_i : in  std_logic;  --! Reset signal (active low).
    pwm_o : out std_logic   --! pwm_o output signal.
  );
end rc_servo;

--! @brief RC Servo Controller RTL architecture.
--! @details Implements the logic for generating pwm_o signals for RC servo control.
architecture arch of rc_servo is

  --! @brief Fixed parameter values.
  constant c_CLK_HZ       : integer := 50000000;  --! Clock frequency: 50 MHz.
  constant c_PULSE_HZ     : integer := 50;        --! pwm_o frequency: 50 Hz.
  constant c_MIN_PULSE_US : integer := 600;       --! Minimum pulse width in microseconds (600 us).
  constant c_MAX_PULSE_US : integer := 2400;      --! Maximum pulse width in microseconds (2400 us).
  constant c_STEP_COUNT   : integer := 3;         --! Number of servo positions.

  --! @brief Calculated values for pwm_o generation.
  constant c_CYCLES_PER_US   : integer := c_CLK_HZ / 1000000; --! Number of clock cycles per microsecond.
  constant c_MIN_COUNT       : integer := c_MIN_PULSE_US * c_CYCLES_PER_US; --! Count for minimum pulse width.
  constant c_MAX_COUNT       : integer := c_MAX_PULSE_US * c_CYCLES_PER_US; --! Count for maximum pulse width.
  constant c_CYCLES_PER_STEP : integer := (c_MAX_COUNT - c_MIN_COUNT) / (c_STEP_COUNT - 1); --! Count increment per servo step.
  constant c_COUNTER_MAX     : integer := (c_CLK_HZ / c_PULSE_HZ) - 1;  --! Max counter value for one pwm_o period (20 ms)
  constant c_UPDATE_PERIOD   : integer := 50;  --! Number of pwm_o periods per servo position update (50 periods = 1 s).

  --! @brief Internal signals used for pwm_o control.
  signal counter        : integer range 0 to c_COUNTER_MAX := 0; --! Counter for clock cycles within a pwm_o period.
  signal duty_cycle     : integer range 0 to c_MAX_COUNT := c_MIN_COUNT; --! Current pwm_o duty cycle count.
  signal current_pos    : integer range 0 to c_STEP_COUNT-1 := 0; --! Current servo position index.
  signal update_counter : integer range 0 to c_UPDATE_PERIOD-1 := 0; --! Counter for pwm_o periods to control update timing.

begin

  -----------------------------------------------------------------------------
  --! @brief Process for pwm_o period counting and servo position update.
  --! @details
  --!   - Increments the pwm_o period counter on every clock cycle.
  --!   - After each full pwm_o period, increments the update counter.
  --!   - When the update counter reaches the c_UPDATE_PERIOD (50 periods), it:
  --!       * Resets the update counter.
  --!       * Updates the servo position cyclically (0 -> 1 -> 2 -> 0).
  --!       * Recalculates the duty cycle based on the new position.
  --!   - The reset (rst_i) is active low.
  -----------------------------------------------------------------------------
  PWM_AND_STEP : process(clk_i)
    variable new_pos  : integer;
    variable new_duty : integer;
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then  --! Active low reset.
        counter        <= 0;
        update_counter <= 0;
        current_pos    <= 0;
        duty_cycle     <= c_MIN_COUNT;
      else
        if counter < c_COUNTER_MAX then
          counter <= counter + 1;
        else
          counter <= 0;
          if update_counter < c_UPDATE_PERIOD - 1 then
            update_counter <= update_counter + 1;
          else
            update_counter <= 0;
            --! Update servo position cyclically: 0 -> 1 -> 2 -> 0.
            if current_pos < c_STEP_COUNT - 1 then
              new_pos := current_pos + 1;
            else
              new_pos := 0;
            end if;
            current_pos <= new_pos;
            new_duty := new_pos * c_CYCLES_PER_STEP + c_MIN_COUNT;
            duty_cycle <= new_duty;
          end if;
        end if;
      end if;
    end if;
  end process PWM_AND_STEP;

  -----------------------------------------------------------------------------
  --! @brief Process for generating the pwm_o output signal.
  --! @details
  --!   - On every rising edge of the clock, compares the current counter value with the duty_cycle.
  --!   - Sets the pwm_o output high ('1') when counter < duty_cycle; otherwise, sets it low ('0').
  --!   - On reset, the pwm_o output is set to '0'.
  -----------------------------------------------------------------------------
  PWM_GEN : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        pwm_o <= '0';
      else
        if counter < duty_cycle then
          pwm_o <= '1';
        else
          pwm_o <= '0';
        end if;
      end if;
    end if;
  end process PWM_GEN;

end architecture arch;
