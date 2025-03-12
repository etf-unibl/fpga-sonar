# fpga-sonar

### Introduction
This project implements a simple sonar device on an FPGA platform. The project uses a servo motor that continuously rotates an ultrasonic sensor across a given area, the sensor attempts to detect objects and measure their distances. The sensor's readings are processed and visualized on a standard 640x480 VGA display. The chosen FPGA platform for hosting the device is the DE1-SoC board.

---
## Components

### 1. Ultrasonic Sensor (HC-SR04)
- **Function:** Measures the distances of detected objects using ultrasonic waves.
- **Documentation:**  
  [HC-SR04 Datasheet & Setup Guide](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/hc-sr04.md)

  The Interface Circuit for adapting **HC-SR04** output to **DE1-SoC Board** input:<br>
  [Interface Circuit](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/interface_circuit.md)

### 2. Servo Motor (Hitec HS-422 Deluxe Standard Servo)
- **Function:** Rotates the sensor to scan across the environment.
- **Documentation:**  
  [Hitec HS-422 Datasheet & Setup Guide](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/rc-servo.md)  

### 3. VGA Display (640x480)
- **Function:** Displays a graphical representation of the sensor’s readings (the measured distances).
- **Documentation:**  
  [VGA Display Datasheet & Setup Guide](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/VGA.md)
---

### FPGA Platform (DE1-SoC Board)
The chosen FPGA Platform for hosting the design is **DE1-SoC Board**. The DE1-SoC Development Kit is a robust hardware design platform built around the **Altera System-on-Chip FPGA**. <br> For comprehensive information (Specifications, Diagrams, Resources etc.) please refer to [terasic.com/DE1-SoC Board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=836)
- **Overview of the GPIO pins:**
  [DE1-SoC Board GPIO pins](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/GPIO.md)  


### VUnit Framework
Is used to simplify and automate the process of testing/verifying the used hardware designs.
- **Userguide:**
  [VUnit Framework Userguide](https://github.com/etf-unibl/fpga-sonar/blob/main/docs/VUnitFramework_UserGuide.md)
