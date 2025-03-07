-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
-----------------------------------------------------------------------------
--
-- unit name:     Sonar_Controller_tb
--
-- description:
--
--   This file implements a testbench for the Sonar Controller.
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
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Include VUnit libraries for assertions.
library vunit_lib;
context vunit_lib.vunit_context;

entity Sonar_Controller_tb is
  generic (runner_cfg : string);
end entity Sonar_Controller_tb;

architecture arch of Sonar_Controller_tb is
  constant CLK_PERIOD          : time    := 20 ns;  -- 50 MHz clock
  constant CONVERSION_FACTOR   : integer := 2900;
  constant TRIGGER_PULSE_COUNT : integer := 500;    -- Same value as in design

  signal clk_tb          : std_logic := '0';
  signal reset_tb        : std_logic := '1';
  signal start_tb        : std_logic := '1';
  signal echo_tb         : std_logic := '0';
  signal trigger_tb      : std_logic;
  signal done_tb         : std_logic;
  signal distance_cm_tb  : std_logic_vector(9 downto 0);
  signal object_found_tb : std_logic;

  component Sonar_Controller is
    port (
        clk_i          : in  std_logic;
        reset_i        : in  std_logic;
        start_i        : in  std_logic;
        echo_i         : in  std_logic;
        trigger_o      : out std_logic;
        done_o         : out std_logic;
        distance_cm_o  : out std_logic_vector(9 downto 0);
        object_found_o : out std_logic
    );
  end component;

begin
  uut : Sonar_Controller
      port map (
          clk_i          => clk_tb,
          reset_i        => reset_tb,
          start_i        => start_tb,
          echo_i         => echo_tb,
          trigger_o      => trigger_tb,
          done_o         => done_tb,
          distance_cm_o  => distance_cm_tb,
          object_found_o => object_found_tb
      );

  -- Generate clock signal
  clk_tb <= not clk_tb after CLK_PERIOD/2;

  main : process
    -- Pulse_echo procedure:
    procedure pulse_echo(echo_cycles : integer) is
    begin
      wait for 10 us;
      -- Wait for fixed time corresponding to the trigger pulse duration (10 us)
      wait for CLK_PERIOD * TRIGGER_PULSE_COUNT;
      -- Activate echo pulse for a specific duration
      echo_tb <= '1';
      wait for CLK_PERIOD * echo_cycles;
      echo_tb <= '0';
      -- Wait until the controller completes the measurement (done signal becomes '0')
      wait until done_tb = '0';
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      -- Reset the system for each test
      reset_tb <= '0';
      start_tb <= '1';
      wait for CLK_PERIOD * 2;
      reset_tb <= '1';
      wait for CLK_PERIOD * 2;

      if run("test_normal_distance") then
        -- Test normal distance (200 cm)
        start_tb <= '0';
        pulse_echo(200 * CONVERSION_FACTOR);
        check_equal(unsigned(distance_cm_tb), 200, "Normal distance check");
        check_equal(object_found_tb, '0', "Object found status");

      elsif run("test_min_valid_distance") then
        -- Test minimum distance (3 cm, below the 4 cm threshold)
        start_tb <= '0';
        pulse_echo(4 * CONVERSION_FACTOR);
        check_equal(unsigned(distance_cm_tb), 4, "Minimum distance check");
        check_equal(object_found_tb, '0', "Object found status");

      elsif run("test_max_valid_distance") then
        -- Test maximum valid distance (400 cm)
        start_tb <= '0';
        pulse_echo(400 * CONVERSION_FACTOR);
        check_equal(unsigned(distance_cm_tb), 400, "Maximum valid distance check");
        check_equal(object_found_tb, '0', "Object found status");

      elsif run("test_timeout_distance") then
        -- Test exceeding maximum distance (>400 cm)
        start_tb <= '0';
        pulse_echo(401 * CONVERSION_FACTOR); -- Duration longer than maximum (timeout)
        check_equal(unsigned(distance_cm_tb), 1023, "Timeout distance check");
        check_equal(object_found_tb, '1', "Object not found status");

      elsif run("test_too_close_distance") then
        -- Test too close distance (3 cm, below the 4 cm threshold)
        start_tb <= '0';
        pulse_echo(3 * CONVERSION_FACTOR);
        check_equal(unsigned(distance_cm_tb), 0, "Too close distance check");
        check_equal(object_found_tb, '0', "Object found status");

      elsif run("test_reset_behavior") then
        -- Test reset during measurement
        start_tb <= '0';
        wait for CLK_PERIOD * TRIGGER_PULSE_COUNT;  -- Wait for trigger pulse to finish
        reset_tb <= '0';
        wait for CLK_PERIOD * 2;
        check_equal(done_tb, '1', "Reset during measurement check");
      end if;
    end loop;

    test_runner_cleanup(runner);
    wait;
  end process;

  test_runner_watchdog(runner, 100 ms);
end architecture arch;
