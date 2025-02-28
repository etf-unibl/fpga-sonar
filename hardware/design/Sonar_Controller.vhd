-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:     Sonar Controller
--
-- description:
--
--   This file implements a simple sonar controller which is able to detecting objects.
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--======================================================================
-- Entity Declaration
--======================================================================
-- This entity defines the interface to the Sonar_Controller.
-- It includes:
--   - clk:          A 50 MHz clock (20 ns per cycle).
--   - reset:        An asynchronous reset to initialize the module.
--   - start:        A signal to begin a measurement.
--   - echo:         The input from the HC‑SR04 sensor.
--                   The sensor drives echo high immediately after the trigger.
--   - trigger:      The output to the HC‑SR04 sensor to initiate the ultrasonic burst.
--   - done:         Indicates when the measurement (and conversion) is complete.
--   - distance_cm:  The computed distance in centimeters (16-bit vector).
--   - object_found: '1' if a valid echo was detected (object present), '0' otherwise.
--======================================================================
entity Sonar_Controller is
  Port (
    clk          : in  std_logic;                         -- 50 MHz clock, each cycle = 20 ns.
    reset        : in  std_logic;                         -- Asynchronous reset.
    start        : in  std_logic;                         -- Start measurement signal.
    echo         : in  std_logic;                         -- Echo input from HC‑SR04 sensor.
    trigger      : out std_logic;                         -- Trigger output to HC‑SR04.
    done         : out std_logic;                         -- Measurement complete indicator.
    distance_cm  : out std_logic_vector(9 downto 0);       -- Computed distance in centimeters.
    object_found : out std_logic                          -- '1' if object detected, '0' otherwise.
  );
end Sonar_Controller;

architecture Behavioral of Sonar_Controller is

  --======================================================================
  -- Finite State Machine (FSM) Declaration
  --======================================================================
  -- The FSM transitions through the following states:
  --   IDLE:           Wait for the start command.
  --   TRIGGER_PULSE:  Generate a 10 µs trigger pulse to the sensor.
  --   MEASURE_ECHO:   Count clock cycles while the echo is high.
  --                   If echo falls before timeout, an object is detected.
  --                   If echo remains high for 38 ms, the sensor times out (no object).
  --   DONE_STATE:           Convert the echo counter to a distance in centimeters,
  --                   signal completion, and then wait for start deassertion.
  type state_type is (IDLE, TRIGGER_PULSE, MEASURE_ECHO, DONE_STATE);
  signal state : state_type := IDLE;

  --======================================================================
  -- Constant Definitions
  --======================================================================
  -- TRIGGER_PULSE_COUNT:
  --   - The sensor requires a 10 µs trigger pulse.
  --   - At 50 MHz, 10 µs corresponds to 500 clock cycles.
  --
  -- MEASURE_TIMEOUT_COUNT:
  --   - The echo is expected to time out after 38 ms if no object is detected.
  --   - At 50 MHz, 38 ms corresponds to 1,900,000 cycles.
  constant TRIGGER_PULSE_COUNT : integer := 500;      -- 10 µs trigger pulse (500 cycles).
  constant MEASURE_TIMEOUT_COUNT : integer := 1900000;  -- 38 ms timeout (1,900,000 cycles).

  --======================================================================
  -- Signal Declarations for Counters and Registers
  --======================================================================
  -- trigger_counter:
  --   - Counts clock cycles during the trigger pulse generation.
  --
  -- echo_counter:
  --   - Counts clock cycles during which the echo remains high.
  --   - Represents the duration of the echo pulse.
  --
  -- distance_reg:
  --   - Holds the computed distance in centimeters after conversion.
  --
  -- done_reg and found:
  --   - done_reg signals that measurement and conversion are complete.
  --   - found indicates whether a valid echo was received (object detected).
  signal trigger_counter : integer range 0 to TRIGGER_PULSE_COUNT := 0;
  signal echo_counter    : unsigned(31 downto 0) := (others => '0');
  signal distance_reg    : unsigned(9 downto 0) := (others => '0');
  signal done_reg        : std_logic := '0';
  signal found           : std_logic := '0';

begin

  --======================================================================
  -- Main Process: Synchronous with clk and asynchronous reset.
  -- This process implements the FSM that controls the sonar measurement.
  --======================================================================
  process(clk, reset)
  begin
    if reset = '1' then
      -- Asynchronous reset: initialize state, outputs, and counters.
      state           <= IDLE;
      trigger         <= '0';
      trigger_counter <= 0;
      echo_counter    <= (others => '0');
      distance_reg    <= (others => '0');
      done_reg        <= '0';
      found           <= '0';
      
    elsif rising_edge(clk) then
      case state is
        --====================================================================
        -- IDLE State:
        --   - System waits for a start command.
        --   - All signals and counters are reset to default.
        --====================================================================
        when IDLE =>
          trigger         <= '0';
          trigger_counter <= 0;
          echo_counter    <= (others => '0');
			 distance_reg    <= (others => '0');
          done_reg        <= '0';
          found           <= '0';
          if start = '1' then
            state <= TRIGGER_PULSE;  -- Begin measurement by sending trigger pulse.
          end if;
          
        --====================================================================
        -- TRIGGER_PULSE State:
        --   - Generates a 10 µs pulse on the trigger output.
        --   - After 500 clock cycles (10 µs), the trigger is deasserted.
        --====================================================================
        when TRIGGER_PULSE =>
          trigger <= '1';  -- Assert trigger signal.
          if trigger_counter < TRIGGER_PULSE_COUNT then
            trigger_counter <= trigger_counter + 1;
          else
            -- End trigger pulse: deassert trigger and transition to echo measurement.
            trigger         <= '0';
            trigger_counter <= 0;
            state           <= MEASURE_ECHO;
          end if;
          
        --====================================================================
        -- MEASURE_ECHO State:
        --   - Measures the duration of the echo pulse.
        --   - The sensor is assumed to drive echo high immediately after the trigger.
        --   - If echo goes low before the 38 ms timeout, an object is detected.
        --   - If echo remains high until the timeout, it indicates no object.
        --====================================================================
        when MEASURE_ECHO =>
          if (echo = '0' and echo_counter = 0) then
            -- At the beginning, no echo detected yet; remain in the same state.
            state <= MEASURE_ECHO;
          elsif echo = '1' then
            if echo_counter < to_unsigned(MEASURE_TIMEOUT_COUNT, 32) then
              echo_counter <= echo_counter + 1;
            else
              -- Timeout reached: echo remained high for 38 ms.
              found <= '0';
              state <= DONE_STATE;
            end if;
          else  -- echo = '0' but echo_counter is not 0: echo went low after some count.
            if echo_counter < to_unsigned(MEASURE_TIMEOUT_COUNT, 32) then
              found <= '1';
            else 
              found <= '0';
            end if;  
            state <= DONE_STATE;
          end if;

          
        --====================================================================
        -- DONE State:
        --   - Converts the measured echo duration into a distance (in cm).
        --   - Conversion: distance_cm ≈ echo_counter / 2900.
        --       (This factor incorporates the 20 ns clock period, the speed of sound,
        --        and the division by 2 for the round-trip.)
        --   - If no object is detected (timeout), distance is set to zero.
        --   - The system waits for the start signal to be deasserted before returning to IDLE.
        --====================================================================
        when DONE_STATE =>
          if found = '1' then
            distance_reg <= to_unsigned( to_integer(echo_counter) / 2900, distance_reg'length );
          else
            distance_reg <= (others => '0');
          end if;
          done_reg <= '1';  -- Signal that measurement and conversion are complete.
          -- Return to IDLE when start is released  
          if start = '0' then
            state <= IDLE;  -- Reset state when start is released.
          end if;
		  
        when others =>
          state <= IDLE;

      end case;
    end if;
  end process;

  --======================================================================
  -- Output Assignments:
  --   - distance_cm: The computed distance in centimeters.
  --   - done:        Indicates that the measurement is complete.
  --   - object_found: '1' if an object was detected (echo pulse ended before timeout),
  --                   '0' if the echo timed out (38 ms with no object).
  --======================================================================
  distance_cm  <= std_logic_vector(distance_reg);
  done         <= done_reg;
  object_found <= found;
  
end Behavioral;
