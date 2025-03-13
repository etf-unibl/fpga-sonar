---------------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2024
-- https://github.com/etf-unibl/fpga-sonar
---------------------------------------------------------------------------------
-- unit name:     Sonar controller module
--
-- description:
--
-- This module integrates a servo motor, an ultrasonic sensor, and a VGA
-- display to create a real-time object detection and visualization system.
-- It generates a start signal for the ultrasonic sensor, produces a PWM
-- signal to control the servo angle, and measures the distance to detected
-- objects. The measured distance and current servo angle are then sent to
-- the VGA display, where the detected object is graphically represented.
--
---------------------------------------------------------------------------------
-- Copyright (c) 2024 Faculty of Electrical Engineering
---------------------------------------------------------------------------------
-- The MIT License
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sonar_controller is
  generic (
    g_UPDATE_PERIOD : integer := 5  --! Number of PWM periods between angle updates.
  );
  port (
    clk_i          : in  std_logic; --! Clock signal (50 MHz)
    rst_i          : in  std_logic; --! Asynchronous reset (active low)
    servo_pwm_o    : out std_logic; --! PWM output to servo module
    vclk_o         : out std_logic; --! VGA clock
    hsync_o        : out std_logic; --! Horizontal sync signal
    vsync_o        : out std_logic; --! Vertical sync signal
    blank_o        : out std_logic; --! Blanking signal
    sync_o         : out std_logic; --! Sync signal (always '0')
    r_o            : out std_logic_vector(7 downto 0); --! Red color (8 bits)
    g_o            : out std_logic_vector(7 downto 0); --! Green color (8 bits)
    b_o            : out std_logic_vector(7 downto 0); --! Blue color (8 bits)
    echo_i         : in  std_logic;                    --! Echo input from HC-SR04 sensor
    trigger_o      : out std_logic                     --! Trigger output to HC-SR04

  );
end sonar_controller;

architecture arch of sonar_controller is

  --! @brief Constant declarations
  --! @details
  --! Defines clock frequency, PWM frequency, and related timing parameters
  constant c_CLK_HZ            : integer := 50000000;              --! Clock frequency: 50 MHz
  constant c_PULSE_HZ          : integer := 50;                    --! PWM frequency: 50 Hz
  constant c_PWM_PERIOD_CYCLES : integer := c_CLK_HZ / c_PULSE_HZ; --! Number of clock cycles per PWM period

  constant c_MIN_ANGLE : integer := 0;    --! Minimum servo angle
  constant c_MAX_ANGLE : integer := 180;  --! Maximum servo angle
  constant c_FULL_CYCLE  : integer := 2 * c_MAX_ANGLE;  --! Full cycle for the triangular waveform (e.g., 358)

  --! @brief Signal declarations.
  signal servo_angle        : unsigned(7 downto 0) := (others => '0');         --! Current servo angle
  signal pwm_period_counter : integer range 0 to c_PWM_PERIOD_CYCLES - 1 := 0; --! PWM cycle counter
  signal update_counter     : integer range 0 to g_UPDATE_PERIOD - 1 := 0;     --! Counter for PWM periods between angle updates
  signal phase              : integer range 0 to c_FULL_CYCLE := 0;            --! Current phase
  signal hpos               : integer;   --! Horizontal position
  signal vpos               : integer;   --! Vertical position
  signal de                 : std_logic; --! Display enable signal
  signal distance_cm        : std_logic_vector(8 downto 0); --! Measured distance in cm
  signal done               : std_logic; --! Measurement complete indicator.
  signal object_found       : std_logic; --! '1' if an object is detected.
  signal sonar_start        : std_logic; --! Start measurement signal (active low)

  component vga_controller is
    port(
      clk_i   : in  std_logic; --! Clock signal
      rst_i   : in  std_logic; --! Reset signal
      vclk_o  : out std_logic; --! VGA pixel clock
      hsync_o : out std_logic; --! Horizontal sync signal
      vsync_o : out std_logic; --! Vertical sync signal
      blank_o : out std_logic; --! Blanking signal
      sync_o  : out std_logic; --! Sync signal (always '0')
      hpos_o  : out integer;   --! Current horizontal position
      vpos_o  : out integer;   --! Current vertical position
      de_o    : out std_logic  --! Display enable signal
    );
  end component;

  component draw_logic is
    port(
      clk_i      : in  std_logic; --! Clock signal
      rst_i      : in  std_logic; --! Reset signal
      hpos_i     : in  integer;   --! Horizontal position
      vpos_i     : in  integer;   --! Vertical position
      de_i       : in  std_logic; --! Display enable signal
      angle_i    : in  unsigned(7 downto 0);         --! Angle input (0-179)
      distance_i : in  std_logic_vector(8 downto 0); --! Distance input (2-400)
      r_o        : out std_logic_vector(7 downto 0); --! Red color output
      g_o        : out std_logic_vector(7 downto 0); --! Green color output
      b_o        : out std_logic_vector(7 downto 0)  --! Blue color output
    );
  end component;
  --! @brief Component declaration for the Ultrasonic_Sensor.
  component Ultrasonic_Sensor is
    port(
      clk_i          : in  std_logic; --! Clock signal
      rst_i          : in  std_logic; --! Reset signal
      start_i        : in  std_logic; --! Start measurement signal (active low)
      echo_i         : in  std_logic; --! Echo input from HC-SR04 sensor
      trigger_o      : out std_logic; --! Trigger output to HC-SR04
      done_o         : out std_logic; --! Measurement complete indicator
      distance_cm_o  : out std_logic_vector(8 downto 0); --! Computed distance in cm
      object_found_o : out std_logic                     --! '1' if an object is detected.
    );
  end component;

  component rc_servo is
    port (
    clk_i   : in  std_logic;            --! Clock signal
    rst_i   : in  std_logic;            --! Asynchronous reset signal (active low)
    angle_i : in  unsigned(7 downto 0); --! Servo angle input (0 to 179)
    pwm_o   : out std_logic             --! PWM output signal
  );
  end component;
begin

  -------------------------------------------------------------------------------
  --! @brief Main process for controlling the sonar
  --! @details
  --! This process controls the servo motor movement and generates the sonar start
  --! signal at specific intervals.
  -------------------------------------------------------------------------------
  process(clk_i, rst_i)
  begin
    if rst_i = '0' then
      pwm_period_counter <= 0;                                            --! Reset the PWM period counter
      update_counter     <= 0;
      phase              <= 0;
      servo_angle        <= to_unsigned(c_MIN_ANGLE, servo_angle'length); --! Set the servo angle to minimum
      sonar_start        <= '0';                                          --! Disable the sonar initially
    elsif rising_edge(clk_i) then
      if pwm_period_counter < c_PWM_PERIOD_CYCLES - 1 then
        pwm_period_counter <= pwm_period_counter + 1;
        sonar_start <= '0';
      else
        pwm_period_counter <= 0;
        if update_counter < g_UPDATE_PERIOD - 1 then
          update_counter <= update_counter + 1;
          sonar_start    <= '0';
        else
          update_counter <= 0;
          if phase < c_FULL_CYCLE then
            phase <= phase + 1;
          else
            phase <= 0;
          end if;
          sonar_start <= '1';
        end if;
        if phase <= c_MAX_ANGLE then
          servo_angle <= to_unsigned(phase, servo_angle'length);
        else
          servo_angle <= to_unsigned(2 * c_MAX_ANGLE - phase, servo_angle'length);
        end if;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------
  --! @brief Instantiation of the servo module.
  --! @details
  --! The servo module receives the computed servo angle and generates
  --! a PWM signal to control an RC servo motor.
  -------------------------------------------------------------------------------
  servo_inst : rc_servo
    port map (
      clk_i   => clk_i,
      rst_i   => rst_i,
      angle_i => servo_angle,
      pwm_o   => servo_pwm_o
    );
  -------------------------------------------------------------------------------
  --! @brief Instantiation of the VGA module.
  --! @details
  --! The VGA module consists of vga_controller and draw_logic.
  --! The vga_controller is responsible for configuring the VGA display and
  --! generating synchronization signals, while the draw_logic module renders
  --! the object in a specific zone based on the angle and distance measurements.
  -------------------------------------------------------------------------------
  vga_controller_inst : vga_controller
    port map(
      clk_i   => clk_i,
      rst_i   => rst_i,
      vclk_o  => vclk_o,
      hsync_o => hsync_o,
      vsync_o => vsync_o,
      blank_o => blank_o,
      sync_o  => sync_o,
      hpos_o  => hpos,
      vpos_o  => vpos,
      de_o    => de
    );

  draw_logic_inst : draw_logic
    port map(
      clk_i      => clk_i,
      rst_i      => rst_i,
      hpos_i     => hpos,
      vpos_i     => vpos,
      de_i       => de,
      angle_i    => servo_angle,
      distance_i => distance_cm,
      r_o        => r_o,
      g_o        => g_o,
      b_o        => b_o
    );
  -------------------------------------------------------------------------------
  --! @brief Instantiation of the Ultrasonic sensor module
  --! @details
  --! The sensor receives a start signal and attempts to detect an object
  --! based on the trigger signal. If an object is found, it returns an echo
  --! signal and calculates the distance at which the object was detected.
  -------------------------------------------------------------------------------
  Ultrasonic_Sensor_inst : Ultrasonic_Sensor
    port map(
      clk_i          => clk_i,
      rst_i          => rst_i,
      start_i        => sonar_start,
      echo_i         => echo_i,
      trigger_o      => trigger_o,
      done_o         => done,
      distance_cm_o  => distance_cm,
      object_found_o => object_found
    );
end architecture arch;
