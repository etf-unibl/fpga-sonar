## Generated SDC file "vga_controller.out.sdc"

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
## VERSION "Version 20.1.1 Build 720 11/11/2020 SJ Lite Edition"

## DATE    "Wed Feb 12 11:15:49 2025"

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

create_clock -name {clk25} -period 1.000 -waveform { 0.000 0.500 } [get_registers {clk25}]
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

set_clock_uncertainty -rise_from [get_clocks {clk25}] -rise_to [get_clocks {clk_i}]  0.350  
set_clock_uncertainty -rise_from [get_clocks {clk25}] -fall_to [get_clocks {clk_i}]  0.350  
set_clock_uncertainty -rise_from [get_clocks {clk25}] -rise_to [get_clocks {clk25}]  0.380  
set_clock_uncertainty -rise_from [get_clocks {clk25}] -fall_to [get_clocks {clk25}]  0.380  
set_clock_uncertainty -fall_from [get_clocks {clk25}] -rise_to [get_clocks {clk_i}]  0.350  
set_clock_uncertainty -fall_from [get_clocks {clk25}] -fall_to [get_clocks {clk_i}]  0.350  
set_clock_uncertainty -fall_from [get_clocks {clk25}] -rise_to [get_clocks {clk25}]  0.380  
set_clock_uncertainty -fall_from [get_clocks {clk25}] -fall_to [get_clocks {clk25}]  0.380  


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
# Pin planer
#**************************************************************
set_location_assignment PIN_J14 -to B_o[7]
set_location_assignment PIN_G15 -to B_o[6]
set_location_assignment PIN_F15 -to B_o[5]
set_location_assignment PIN_H14 -to B_o[4]
set_location_assignment PIN_F14 -to B_o[3]
set_location_assignment PIN_H13 -to B_o[2]
set_location_assignment PIN_G13 -to B_o[1]
set_location_assignment PIN_B13 -to B_o[0]
set_location_assignment PIN_F10 -to BLANK
set_location_assignment PIN_E11 -to G_o[7]
set_location_assignment PIN_F11 -to G_o[6]
set_location_assignment PIN_G12 -to G_o[5]
set_location_assignment PIN_G11 -to G_o[4]
set_location_assignment PIN_G10 -to G_o[3]
set_location_assignment PIN_H12 -to G_o[2]
set_location_assignment PIN_J10 -to G_o[1]
set_location_assignment PIN_J9 -to G_o[0]
set_location_assignment PIN_B11 -to HSYNC
set_location_assignment PIN_F13 -to R_o[7]
set_location_assignment PIN_E12 -to R_o[6]
set_location_assignment PIN_D12 -to R_o[5]
set_location_assignment PIN_C12 -to R_o[4]
set_location_assignment PIN_B12 -to R_o[3]
set_location_assignment PIN_E13 -to R_o[2]
set_location_assignment PIN_C13 -to R_o[1]
set_location_assignment PIN_A13 -to R_o[0]
set_location_assignment PIN_AA14 -to RST
set_location_assignment PIN_C10 -to SYNC
set_location_assignment PIN_A11 -to VCLK
set_location_assignment PIN_D11 -to VSYNC
set_location_assignment PIN_AF14 -to CLK
