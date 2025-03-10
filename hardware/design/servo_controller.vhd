-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
-- unit name:     Servo_Controller
--
-- description:
--
--   This file implements the servo controller module.
--   The module generates a PWM signal for controlling an RC servo motor.
--   It updates the servo angle using a triangular waveform.
--   The angle is updated every g_UPDATE_PERIOD PWM periods.
--
--   The module instantiates the servo module, which receives the servo angle and
--   generates the PWM output signal.
-----------------------------------------------------------------------------
-- Copyright (c) 2023 Faculty of Electrical Engineering
-----------------------------------------------------------------------------
-- The MIT License
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity servo_controller is
  generic (
    g_UPDATE_PERIOD : integer := 10  --! Number of PWM periods between angle updates.
  );
  port (
    clk_i       : in  std_logic;  --! Clock signal (50 MHz).
    rst_i       : in  std_logic;  --! Asynchronous reset (active low).
    servo_pwm_o : out std_logic   --! PWM output to servo module.
  );
end servo_controller;

architecture arch of servo_controller is

  --! @brief Constant declarations.
  --! @details
  --!   Defines clock frequency, PWM frequency, and related timing parameters.
  constant c_CLK_HZ            : integer := 50000000;              --! Clock frequency: 50 MHz.
  constant c_PULSE_HZ          : integer := 50;                    --! PWM frequency: 50 Hz.
  constant c_PWM_PERIOD_CYCLES : integer := c_CLK_HZ / c_PULSE_HZ; --! Number of clock cycles per PWM period.

  constant c_MIN_ANGLE : integer := 0;    --! Minimum servo angle.
  constant c_MAX_ANGLE : integer := 179;  --! Maximum servo angle.
  constant c_FULL_CYCLE  : integer := 2 * c_MAX_ANGLE;  --! Full cycle for the triangular waveform (e.g., 358).

  --! @brief Signal declarations.
  signal servo_angle        : unsigned(7 downto 0) := (others => '0');         --! Current servo angle.
  signal pwm_period_counter : integer range 0 to c_PWM_PERIOD_CYCLES - 1 := 0; --! Counter for clock cycles within a PWM period.
  signal update_counter     : integer range 0 to g_UPDATE_PERIOD - 1 := 0;     --! Counter for PWM periods between angle updates.
  signal phase              : integer range 0 to c_FULL_CYCLE := 0;            --! Current phase of the triangular waveform.

begin

  -------------------------------------------------------------------------
  --! @brief Main process for updating the servo angle.
  --! @details
  --!   This process updates the PWM period counter and, upon completion of a PWM period,
  --!   increments the update counter. When the update counter reaches g_UPDATE_PERIOD, it
  --!   updates the phase of the triangular waveform and computes the new servo angle.
  --!   The servo angle is computed based on the phase such that it increases linearly
  --!   to c_MAX_ANGLE and then decreases, forming a triangular waveform.
  -------------------------------------------------------------------------
  process(clk_i, rst_i)
  begin
    if rst_i = '0' then
      pwm_period_counter <= 0;
      update_counter     <= 0;
      phase              <= 0;
      servo_angle        <= to_unsigned(c_MIN_ANGLE, servo_angle'length);
    elsif rising_edge(clk_i) then
      if pwm_period_counter < c_PWM_PERIOD_CYCLES - 1 then
        pwm_period_counter <= pwm_period_counter + 1;
      else
        pwm_period_counter <= 0;
        --! Update the update_counter; when it reaches the set limit, update the phase.
        if update_counter < g_UPDATE_PERIOD - 1 then
          update_counter <= update_counter + 1;
        else
          update_counter <= 0;
          if phase < c_FULL_CYCLE then
            phase <= phase + 1;
          else
            phase <= 0;
          end if;
        end if;
        --! Calculate the servo angle based on the triangular waveform phase.
        if phase <= c_MAX_ANGLE then
          servo_angle <= to_unsigned(phase, servo_angle'length);
        else
          servo_angle <= to_unsigned(2 * c_MAX_ANGLE - phase, servo_angle'length);
        end if;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------
  --! @brief Instantiation of the servo module.
  --! @details
  --!   The servo module receives the computed servo angle and generates a PWM signal
  --!   to control an RC servo motor.
  -------------------------------------------------------------------------
  u_servo : entity work.rc_servo
    port map (
      clk_i   => clk_i,
      rst_i   => rst_i,
      angle_i => servo_angle,
      pwm_o   => servo_pwm_o
    );

end architecture arch;
