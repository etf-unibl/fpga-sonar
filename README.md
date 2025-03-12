# FPGA-based sonar

## Introduction
This project implements a simple sonar device on an FPGA platform. The project uses a servo motor that continuously rotates an ultrasonic sensor across a given area, the sensor attempts to detect objects and measure their distances. The sensor's readings are processed and visualized on a standard 640x480 VGA display. The chosen FPGA platform for hosting the device is the DE1-SoC board.

---
## System overview
This system uses an FPGA to:
- Control an **Ultrasonic Sensor** (for distance measurement)
- Drive an **RC Servo** (to change or track angle)
- Display real-time data on a monitor via a **VGA Module** <br>

All modules are synchronized to the same system clock (**clk**) and reset (**rst**), ensuring consistent timing and operation.

![fpga_sonar](https://github.com/user-attachments/assets/d8b92e8a-8a8f-43a5-ae86-68276216fae8)
_Picture 1.1_ Diagram representation of system

Blue arrows are representing signals that are sent by main cotroler and orange lines are signals that main controller recieves.

---
## Components
### Main Controller
- **Role:** Central coordinator of the system.  
- **Key Signals:**  
  - **Angle:**  
    - Sent to the RC Servo to position it.  
    - Forwarded to the VGA Module for on-screen visualization.  
  - **Distance:**  
    - Received from the Ultrasonic Sensor.  
    - Forwarded to the VGA Module for display.
  - **Start:**
    - Initiates distance measurement in the Ultrasonic Sensor.     
- **Functionality:**  
  - Receives `distance` data from the Ultrasonic Sensor.  
  - Updates the servo `angle` to control scanning or positioning.  
  - Passes both `angle` and `distance` to the VGA Module.

### RC Servo
- **Role:** Mechanical actuator that positions based on the `angle` signal.  
- **Key Signal:**  
  - **Angle:** Received from the Main Controller.  
- **Functionality:**  
  - Interprets the `angle` command to rotate the servo accordingly.  
  - Physically adjust the Ultrasonic Sensor’s orientation.
- **Documentation:**  
  [Hitec HS-422 Datasheet & Setup Guide](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/rc-servo.md)  

### Ultrasonic Sensor
- **Role:** Measures distance to nearby objects using ultrasonic pulses.  
- **Key Signal:**
  - **Distance:** Sent to the Main Controller.
  - **Start:** Triggers the distance measurement process.   
- **Functionality:**  
  - Sends out ultrasonic pulses and captures echoes.  
  - Calculates the time delay to determine `distance`.  
  - Provides the `distance` value to the Main Controller for further use.
- **Documentation:**  
  [HC-SR04 Datasheet & Setup Guide](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/hc-sr04.md)  <br>
  
  The Interface Circuit for adapting **HC-SR04** output to **DE1-SoC Board** input:<br>
  [Interface Circuit](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/interface_circuit.md) <br>
  
### VGA Module
- **Role:** Handles video output to a monitor, showing real-time system data.  
- **Key Signals:**  
  - **Angle:** From the Main Controller, used to display servo position or scanning angle.  
  - **Distance:** From the Main Controller, used to display measured distance.  
- **Functionality:**  
  - Generates VGA timing signals (HSYNC, VSYNC, etc.).  
  - Renders graphics/text indicating the `angle` and `distance` on the screen.
- **Documentation:**  
  [VGA Display Datasheet & Setup Guide](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/VGA.md)

---
## FPGA Platform (DE1-SoC Board)
The chosen FPGA Platform for hosting the design is **DE1-SoC Board**. The DE1-SoC Development Kit is a robust hardware design platform built around the **Altera System-on-Chip FPGA**. <br> For comprehensive information (Specifications, Diagrams, Resources etc.) please refer to [terasic.com/DE1-SoC Board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=836)
- **Overview of the GPIO pins:**
  [DE1-SoC Board GPIO pins](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/GPIO.md)  

---
## VUnit Framework
Is used to simplify and automate the process of testing/verifying the used hardware designs.
- **Userguide:**
  [VUnit Framework Userguide](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/VUnitFramework_UserGuide.md)
