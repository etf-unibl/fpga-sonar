# Ultrasonic Sensor HC-SR04

The HC-SR04 Ultrasonic Sensor is a widely used distance measuring device that operates based on the principle of sound wave reflection. It is commonly used in robotics, automation, and various measurement applications.

## Overview

The HC-SR04 consists of a transmitter and a receiver. The transmitter emits an ultrasonic pulse, and the receiver detects the echo after it bounces off an object. The time delay between the transmitted and received signal is used to calculate the distance.

![Ultrasonic sensor HC-SR04](https://github.com/user-attachments/assets/7934d3c6-a6ec-49b7-b9ee-250883e7fe85)

## Key Characteristics of HC-SR04

- **Operating Voltage:** 5V DC
- **Operating Current:** 15mA
- **Measuring Range:** 2cm to 400cm
- **Resolution:** 0.3cm
- **Operating Frequency:** 40kHz
- **Measurement Angle:** ~15°
- **Trigger Input Signal:** 10µs TTL pulse
- **Echo Output Signal:** TTL signal proportional to the distance measured

## Working Principle

1. The Trigger pin receives a 10µs HIGH pulse.
2. The sensor emits eight 40kHz ultrasonic pulses.
3. These pulses travel through the air until they hit an obstacle.
4. The echo signal is received by the sensor’s receiver.
5. The Echo pin outputs a HIGH pulse whose duration corresponds to the time taken for the pulse to return.If those pulses are not reflected back, the echo signal times out and goes low after 38ms (38 milliseconds). Thus a pulse of 38ms indicates no obstruction within the range of the sensor.

6. Distance is calculated using the formula:
   
   
$$
\[
Distance = \frac{Time \times SpeedofSound}{2}´
\]
$$
   
   where **Speed of Sound ≈ 343m/s (or 0.034 cm/µs)** at room temperature.
    
   
   

## Advantages of HC-SR04


- The sensor provides precise measurements within a range of 2 cm to 400 cm.
- The HC-SR04 has a quick response time, allowing it to be used in dynamic projects like robots that need to react quickly to obstacles.
- Since it uses ultrasonic waves, the HC-SR04 does not require physical contact with the object, making it suitable for measuring the distance of objects that can't be physically touched or could damage mechanical sensors.

## Disadvantages of HC-SR04

- Sensitive to environmental noise
- Cannot measure transparent or highly absorbent surfaces effectively
- Limited to detecting objects within a narrow beam angle (~15°)

## HC-SR04 Timing Diagram

| Description           | Value               |
|----------------------|-------------------|
| Trigger Pulse Width  | 10µs              |
| Echo Pulse Width     | Proportional to Distance |
| Minimum Range       | 2cm               |
| Maximum Range       | 400cm             |
| Speed of Sound      | 343m/s            |

## Pin Assignment

| Pin  | Description          |
|------|----------------------|
| VCC  | 5V Power Supply      |
| Trig | Trigger Input        |
| Echo | Echo Output          |
| GND  | Ground               |

## Applications

- Obstacle detection in robotics
- Distance measurement in automation systems
- Parking sensors in vehicles
- Liquid level detection

This documentation provides a comprehensive overview of the HC-SR04 Ultrasonic Sensor and serves as a reference for technical and project needs.

