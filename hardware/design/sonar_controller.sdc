## Generated SDC file "sonar_controller.sdc"

## Copyright (C) 2020  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 20.1.0 Build 711 06/05/2020 SJ Lite Edition"

## DATE    "Thu Mar 13 14:14:08 2025"

##
## DEVICE  "5CSEMA5F31C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {vga_controller:vga_controller_inst|clk25} -period 1.000 -waveform { 0.000 0.500 } [get_registers {vga_controller:vga_controller_inst|clk25}]
create_clock -name {clk_i} -period 1.000 -waveform { 0.000 0.500 } [get_ports {clk_i}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}] -setup 0.310  
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}] -hold 0.270  
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}] -setup 0.310  
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}] -hold 0.270  
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}] -setup 0.310  
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}] -hold 0.270  
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}] -setup 0.310  
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}] -hold 0.270  
set_clock_uncertainty -rise_from [get_clocks {vga_controller:vga_controller_inst|clk25}] -rise_to [get_clocks {clk_i}]  0.350  
set_clock_uncertainty -rise_from [get_clocks {vga_controller:vga_controller_inst|clk25}] -fall_to [get_clocks {clk_i}]  0.350  
set_clock_uncertainty -rise_from [get_clocks {vga_controller:vga_controller_inst|clk25}] -rise_to [get_clocks {vga_controller:vga_controller_inst|clk25}]  0.380  
set_clock_uncertainty -rise_from [get_clocks {vga_controller:vga_controller_inst|clk25}] -fall_to [get_clocks {vga_controller:vga_controller_inst|clk25}]  0.380  
set_clock_uncertainty -fall_from [get_clocks {vga_controller:vga_controller_inst|clk25}] -rise_to [get_clocks {clk_i}]  0.350  
set_clock_uncertainty -fall_from [get_clocks {vga_controller:vga_controller_inst|clk25}] -fall_to [get_clocks {clk_i}]  0.350  
set_clock_uncertainty -fall_from [get_clocks {vga_controller:vga_controller_inst|clk25}] -rise_to [get_clocks {vga_controller:vga_controller_inst|clk25}]  0.380  
set_clock_uncertainty -fall_from [get_clocks {vga_controller:vga_controller_inst|clk25}] -fall_to [get_clocks {vga_controller:vga_controller_inst|clk25}]  0.380  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************


#**************************************************************
# Pin assignment
#**************************************************************

set_location_assignment PIN_J14 -to b_o[7]
set_location_assignment PIN_G15 -to b_o[6]
set_location_assignment PIN_F15 -to b_o[5]
set_location_assignment PIN_H14 -to b_o[4]
set_location_assignment PIN_F14 -to b_o[3]
set_location_assignment PIN_H13 -to b_o[2]
set_location_assignment PIN_G13 -to b_o[1]
set_location_assignment PIN_B13 -to b_o[0]
set_location_assignment PIN_F10 -to blank_o
set_location_assignment PIN_E11 -to g_o[7]
set_location_assignment PIN_F11 -to g_o[6]
set_location_assignment PIN_G12 -to g_o[5]
set_location_assignment PIN_G11 -to g_o[4]
set_location_assignment PIN_G10 -to g_o[3]
set_location_assignment PIN_H12 -to g_o[2]
set_location_assignment PIN_J10 -to g_o[1]
set_location_assignment PIN_J9 -to g_o[0]
set_location_assignment PIN_B11 -to hsync_o
set_location_assignment PIN_F13 -to r_o[7]
set_location_assignment PIN_E12 -to r_o[6]
set_location_assignment PIN_D12 -to r_o[5]
set_location_assignment PIN_C12 -to r_o[4]
set_location_assignment PIN_B12 -to r_o[3]
set_location_assignment PIN_E13 -to r_o[2]
set_location_assignment PIN_C13 -to r_o[1]
set_location_assignment PIN_A13 -to r_o[0]
set_location_assignment PIN_AA14 -to rst_i
set_location_assignment PIN_C10 -to sync_o
set_location_assignment PIN_A11 -to vclk_o
set_location_assignment PIN_D11 -to vsync_o
set_location_assignment PIN_AF14 -to clk_i
set_location_assignment PIN_AC18 -to servo_pwm_o
set_location_assignment PIN_AB17 -to trigger_o
set_location_assignment PIN_AA21 -to echo_i