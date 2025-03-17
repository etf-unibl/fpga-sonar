-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:   Ultrasonic Sensor
--
-- description:
--
--  This design implements a simple Ultrasonic Sensor logic in form of a finite state machine (FSM) to:
--    - Generate a 10 us trigger pulse.
--    - Measure the echo pulse from the HC-SR04.
--    - Compute the distance in centimeters.
--    - Indicate whether an object was detected.
--
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Faculty of Electrical Engineering
-------------------------------------------------------------------------------
-- The MIT License
-------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief Entity declaration for Ultrasonic_Sensor.
entity Ultrasonic_Sensor is
  port (
    clk_i          : in  std_logic;                     --! 50 MHz clock input.
    rst_i          : in  std_logic;                     --! Asynchronous reset (active low).
    start_i        : in  std_logic;                     --! Start measurement signal (active low).
    echo_i         : in  std_logic;                     --! Echo input from HC-SR04 sensor.
    trigger_o      : out std_logic;                     --! Trigger output to HC-SR04.
    done_o         : out std_logic;                     --! Measurement complete indicator.
    distance_cm_o  : out std_logic_vector(8 downto 0);  --! Computed distance in centimeters.
    object_found_o : out std_logic                      --! '1' if an object is detected.
  );
end Ultrasonic_Sensor;

--! @brief Behavioral architecture for Ultrasonic_Sensor.
architecture arch of Ultrasonic_Sensor is

  --! @brief FSM states for sonar measurement.
  type t_state_type is (IDLE, TRIGGER_PULSE, MEASURE_ECHO, DONE_STATE);
  signal state : t_state_type := IDLE;

  --! @brief Number of clock cycles for the 10 us trigger pulse.
  constant c_TRIGGER_PULSE_COUNT : integer := 500;

  --! @brief Maximum clock cycles for echo measurement timeout (38 ms).
  constant c_MEASURE_TIMEOUT_COUNT : integer := 1900000;

  --! @brief Conversion factor for distance calculation.
  constant c_DISTANCE_CONVERSION_FACTOR : integer := 2900;

  --! @brief Max/Min distance for the Ultrasonic Sensor
  constant c_MAX_DISTANCE : integer := 400;
  constant c_MIN_DISTANCE : integer := 2;

  --! @brief Counter for trigger pulse generation.
  signal trigger_counter : integer range 0 to c_TRIGGER_PULSE_COUNT := 0;

  --! @brief Counter for measuring the echo pulse duration.
  signal echo_counter    : unsigned(31 downto 0) := (others => '0');

  --! @brief Register holding the computed distance.
  signal distance_reg    : unsigned(8 downto 0) := (others => '0');

  --! @brief Signal indicating measurement completion.
  signal done_reg        : std_logic := '0';

  --! @brief Flag indicating if an object was detected.
  signal found           : std_logic := '0';


begin

  -------------------------------------------------------------------------
  --! @brief Main control process implementing the FSM for the HC-SR04 measurement sequence.
  --! @details Manages state transitions between operational phases:
  --!         - IDLE: Waits for start signal
  --!         - TRIGGER_PULSE: Generates 10us trigger pulse
  --!         - MEASURE_ECHO: Captures echo pulse duration
  --!         - DONE_STATE: Finalizes calculation and signals assignments
  -------------------------------------------------------------------------
  process(clk_i, rst_i)
  begin
    if rst_i = '0' then
      state           <= IDLE;                --! Reset state to IDLE.
      done_reg        <= '0';                 --! Clear the done indicator.
      trigger_o         <= '0';               --! Ensure trigger is deasserted.
      trigger_counter <= 0;                   --! Reset trigger counter.
      echo_counter    <= (others => '0');     --! Reset echo counter.
      distance_reg    <= (others => '0');     --! Reset distance register.
      found           <= '0';                 --! Clear object detected flag.
    elsif rising_edge(clk_i) then
      case state is
        when IDLE =>
          done_reg        <= '0';              --! Clear done flag.
          trigger_o         <= '0';            --! Ensure trigger is off.
          trigger_counter <= 0;                --! Reset trigger counter.
          echo_counter    <= (others => '0');  --! Reset echo counter.
          distance_reg    <= (others => '0');  --! Reset distance register.
          found           <= '0';              --! Clear object detected flag.
          if start_i = '0' then                --! Start measurement when start signal is active.
            state <= TRIGGER_PULSE;
          end if;

        when TRIGGER_PULSE =>
          trigger_o <= '1';                   --! Assert trigger signal.
          if trigger_counter < c_TRIGGER_PULSE_COUNT then
            trigger_counter <= trigger_counter + 1;
          else
            trigger_o         <= '0';         --! Deassert trigger after pulse duration.
            trigger_counter <= 0;
            state           <= MEASURE_ECHO;  --! Move to echo measurement state.
          end if;

        when MEASURE_ECHO =>
          if echo_i = '1' then
            if echo_counter < to_unsigned(c_MEASURE_TIMEOUT_COUNT, 32) then
              echo_counter <= echo_counter + 1;  --! Count echo pulse duration.
            else
              found <= '0';                   --! Timeout reached; no object detected.
              state <= DONE_STATE;
            end if;
          elsif echo_i = '0' and echo_counter > 0 then
            if to_unsigned(to_integer(echo_counter) / c_DISTANCE_CONVERSION_FACTOR, distance_reg'length) < c_MIN_DISTANCE or
               to_unsigned(to_integer(echo_counter) / c_DISTANCE_CONVERSION_FACTOR, distance_reg'length) > c_MAX_DISTANCE then
              found <= '0';               --! Detected object is either too close or too far for accurate measurement.
            else
              found <= '1';              --! Echo pulse ended; object detected.
            end if;
            state <= DONE_STATE;         --! Move to Done state.
          end if;

        when DONE_STATE =>
          done_reg <= '1';                    --! Indicate measurement complete.
          if found = '1' then
             --! Calculate distance in centimeters.
            distance_reg <= to_unsigned(to_integer(echo_counter) / c_DISTANCE_CONVERSION_FACTOR, distance_reg'length);
          else
            if to_unsigned(to_integer(echo_counter) / c_DISTANCE_CONVERSION_FACTOR, distance_reg'length) > c_MAX_DISTANCE then
              distance_reg <= (others => '1');    --! Value when object is too far.
            elsif to_unsigned(to_integer(echo_counter) / c_DISTANCE_CONVERSION_FACTOR, distance_reg'length) < c_MIN_DISTANCE then
              distance_reg <= (others => '0');    --! Value when object is too close.
            end if;
          end if;
          if start_i = '1' then              --! Return to IDLE when start signal is deasserted.
            state <= IDLE;
          end if;

        when others =>
          state    <= IDLE;                --! Default to IDLE.
          done_reg <= '0';
      end case;
    end if;
  end process;

  --! @brief Output assignments.
  distance_cm_o   <= std_logic_vector(distance_reg);   --! Computed distance output.
  done_o          <= done_reg;                     --! Measurement completion.
  object_found_o  <= found;                        --! Object detection flag.

end arch;
