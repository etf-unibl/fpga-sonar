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
entity Sonar_Controller is
  Port (
    clk          : in  std_logic;                         -- 50 MHz clock, each cycle = 20 ns.
    reset        : in  std_logic;                         -- Asynchronous reset.
    start        : in  std_logic;                         -- Start measurement signal.
    echo         : in  std_logic;                         -- Echo input from HC‑SR04 sensor.
    trigger      : out std_logic;                         -- Trigger output to HC‑SR04.
    done         : out std_logic;                         -- Measurement complete indicator.
    distance_cm  : out std_logic_vector(9 downto 0);     -- Computed distance in centimeters.
    object_found : out std_logic                          -- '1' if object detected, '0' otherwise.
  );
end Sonar_Controller;

architecture Behavioral of Sonar_Controller is

  --======================================================================
  -- Finite State Machine (FSM) Declaration
  --======================================================================
  type state_type is (IDLE, TRIGGER_PULSE, MEASURE_ECHO, DONE_STATE);
  signal state : state_type := IDLE;

  --======================================================================
  -- Constant Definitions
  --======================================================================
  constant TRIGGER_PULSE_COUNT : integer := 500;       -- 10 µs trigger pulse (500 cycles).
  constant MEASURE_TIMEOUT_COUNT : integer := 1900000;  -- 38 ms timeout (1,900,000 cycles).
  constant DISTANCE_CONVERSION_FACTOR : integer := 2900;  -- Conversion factor for distance.

  --======================================================================
  -- Signal Declarations for Counters and Registers
  --======================================================================
  signal trigger_counter : integer range 0 to TRIGGER_PULSE_COUNT := 0;
  signal echo_counter    : unsigned(31 downto 0) := (others => '0');
  signal distance_reg    : unsigned(9 downto 0) := (others => '0');
  signal done_reg        : std_logic := '0';
  signal found           : std_logic := '0';
  signal start_reg       : std_logic := '0';  -- To prevent re-triggering while already running.

begin

  --======================================================================
  -- Main Control Process: FSM to control the overall state transitions.
  --======================================================================
  process(clk, reset)
  begin
    if reset = '0' then
      state <= IDLE;  -- Reset state to IDLE on reset
      done_reg <= '0';  -- Ensure done_reg is reset
      trigger <= '0';  -- Ensure trigger is off
      trigger_counter <= 0;  -- Reset trigger counter
      echo_counter <= (others => '0');  -- Reset echo counter
      distance_reg <= (others => '0');  -- Reset distance register
      found <= '0';  -- Reset found flag
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          done_reg <= '0';  -- Ensure done_reg is reset
			 trigger <= '0';  -- Ensure trigger is off
			 trigger_counter <= 0;  -- Reset trigger counter
			 echo_counter <= (others => '0');  -- Reset echo counter
			 distance_reg <= (others => '0');  -- Reset distance register
			 found <= '0';  -- Reset found flag
          if start = '0' then
            state <= TRIGGER_PULSE;  -- Move to TRIGGER_PULSE state when start signal is high
          end if;

        when TRIGGER_PULSE =>
       --   done_reg <= '0';  -- Ensure done_reg is reset in TRIGGER_PULSE state
          trigger <= '1';  -- Assert trigger signal
          if trigger_counter < TRIGGER_PULSE_COUNT then
            trigger_counter <= trigger_counter + 1;
          else
            trigger <= '0';  -- Deassert trigger after pulse duration
            trigger_counter <= 0;
            state <= MEASURE_ECHO;  -- Move to MEASURE_ECHO state
          end if;

        when MEASURE_ECHO =>
      --    done_reg <= '0';  -- Ensure done_reg is reset in MEASURE_ECHO state
          if echo = '1' then
            if echo_counter < to_unsigned(MEASURE_TIMEOUT_COUNT, 32) then
              echo_counter <= echo_counter + 1;  -- Measure echo pulse duration
            else
              found <= '0';  -- Timeout reached, no object detected
              state <= DONE_STATE;  -- Move to DONE_STATE
            end if;
          elsif echo = '0' and echo_counter > 0 then
            found <= '1';  -- Object detected
            state <= DONE_STATE;  -- Move to DONE_STATE
          end if;

        when DONE_STATE =>
          done_reg <= '1';  -- Indicate measurement completion
          if found = '1' then
            distance_reg <= to_unsigned(to_integer(echo_counter) / DISTANCE_CONVERSION_FACTOR, distance_reg'length);  -- Calculate distance
          else
            distance_reg <= (others => '0');  -- No object detected, set distance to 0
          end if;
          if start = '1' then
            state <= IDLE;  -- Reset state to IDLE when start signal goes low
          end if;

        when others =>
          state <= IDLE;  -- Default to IDLE state
          done_reg <= '0';  -- Ensure done_reg is reset

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
  done         <=not done_reg;
  object_found <=not found;

end Behavioral;
