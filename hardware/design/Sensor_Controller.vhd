-------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar.git
-------------------------------------------------------------------------------
--
-- unit name:  Sensor Controller
--
-- description:
--
--  The design implements an Ultrasonic Sensor Controller that should be used
--  when integrating the module with the rest of the project.
--
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

--! @brief Entity declaration for Sensor_Controller.
entity Sensor_Controller is
  port (
    clk_i          : in  std_logic;                     --! 50 MHz clock input.
    reset_i        : in  std_logic;                     --! Asynchronous reset (active low).
    start_i        : in  std_logic;                     --! Start measurement signal (active low).
    echo_i         : in  std_logic;                     --! Echo input from HC-SR04 sensor.
    trigger_o      : out std_logic;                     --! Trigger output to HC-SR04.
    done_o         : out std_logic;                     --! Measurement complete indicator.
    distance_cm_o  : out std_logic_vector(9 downto 0);  --! Computed distance in centimeters.
    object_found_o : out std_logic                      --! '1' if an object is detected.
  );
end Sensor_Controller;

--! @brief Behavioral architecture for Sensor_Controller.
architecture arch of Sensor_Controller is

  --! @brief Component declaration for the Ultrasonic_Sensor.
  component Ultrasonic_Sensor is
    port(
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

  --! @brief Instantiation of the Ultrasonic_Sensor component.
  Ultrasonic_Sensor_inst : Ultrasonic_Sensor
    port map(
      clk_i          => clk_i,
      reset_i        => reset_i,
      start_i        => start_i,
      echo_i         => echo_i,
      trigger_o      => trigger_o,
      done_o         => done_o,
      distance_cm_o  => distance_cm_o,
      object_found_o => object_found_o
    );

end arch;
