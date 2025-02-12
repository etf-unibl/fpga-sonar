# VGA Interface

Video Graphics Array, commonly known as VGA, is a video display standard and connection type that has been widely used in the computer industry for decades. First introduced by IBM in 1987, VGA quickly became the default graphics standard for PCs and laid the foundation for modern computer displays.
The standard VGA connector is the blue connector with three rows of five pins. It is typically used to connect VGA cables to older monitors and TVs. This connector is larger compared to mini-VGA connectors, and adapters are available for compatibility between the two types. All VGA connectors carry analog RGBHV (red, green, blue, horizontal sync, vertical sync) video signals. 
The VGA interface includes no affordances for hot swapping, the ability to connect or disconnect the output device during operation, although in practice this can be done and usually does not cause damage to the hardware.

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/8/81/Vga-cable.jpg/800px-Vga-cable.jpg" alt="VGA kabl" width="400">


## Key characteristics of VGA are: 

- Unlike modern digital standards, VGA transmits video as analog signals
- Resolution support: Originally designed for 640x480 pixels, but later extended to support higher resolutions
- Color depth: Initially supported 256 colors
- Refresh rate: 60 Hz standard, with some implementations supporting higher rates

## Advantages of VGA are: 

- Widespread compatibility with older devices
- Simple, robust connector design
- No licensing fees
- Analog signal allows for some flexibility in timing and resolutions

## Disadvantages of VGA are:

- Lower maximum resolution compared to modern standards
- Signal degradation over long cables or with interference

While VGA has been largely superseded by digital interfaces like DVI or HDMI for consumer devices, it still finds use in several areas: older hardware, embedded systems where simplicity is important, large display systems etc.

## VGA Controller 
We need a clock divider to generate the pixel clock. The pixel clock frequency is 25.175MHz in the specification, but we will use 25MHz. We will only concentrate on the 5 signals out of 15 pins in this project. These signals are Red, Grn, Blue, HS, and VS. Red, Grn, and Blue are three analog signals that specify the color of a point on the screen, while HS and VS provide a positional reference of where the point should be displayed on the screen.


![image](https://digilent.com/reference/_media/learn/programmable-logic/tutorials/vga-display-congroller/1-vga-pinout.png)


This table down represents the timing parameters for a VGA (Video Graphics Array) display. It defines the horizontal and vertical timing needed to properly drive a display with a pixel clock of 25.175 MHz (which is standard for 640x480 and 60Hz VGA resolution). 
Here’s what each parameter means:

- Pixel Clock (tclk): The period of each pixel, determining how fast pixels are clocked in; a frequency of 25.175 MHz corresponds to a 39.7 ns pixel period
- Hor Sync Time (ths): The duration of the horizontal sync pulse, which tells the monitor to start a new scanline
- Hor Back Porch (thbp): The time after the sync pulse but before the actual image starts
- Hor Front Porch (thfp): The time after the displayed image but before the next sync pulse
- Hor Addr Video Time (thaddr): The time in which active pixels (actual image) are sent to the screen
- Hor L/R Border (thbd): Indicates whether there is a border (not used in standard VGA)
- V Sync Time (tvs): The time for the vertical sync pulse, which signals the start of a new frame
- V Back Porch (tvbp): The time after the vertical sync before the active display starts
- V Front Porch (tvfp): The time after the displayed image but before the next vertical sync pulse
- V Addr Video Time (tvaddr): The active frame area where actual image lines are displayed
- V T/B Border (tvbd): Similar to the horizontal border, but for vertical positioning


|  Description        | Notation | Time     | Width/Freq |
| --------------------| ---------| ---------| -----------|
| Pixel Clock         | tclk	 | 39.7 ns  | 25.175MHz  |
| Hor Sync Time       | ths	 | 3.81 μs  | 96 Pixels  |
| Hor Back Porch      | thbp     | 1.91 μs  | 48 Pixels  |
| Hor Front Porch     | thfp	 | 0.636 μs | 16 Pixels  |
| Hor Addr Video Time | thaddr	 | 25.42 μs | 640 Pixels |
| Hor L/R Border      | thbd	 | 0 μs     | 0 Pixels   |
| V Sync Time	      | tvs	 | 0.064 ms | 2 Lines    |
| V Back Porch        | tvbp	 | 1.048 ms | 33 Lines   |
| V Front Porch       | tvfp	 | 0.318 ms | 10 Lines   |
| V Addr Video Time   | tvaddr	 | 15.25 ms | 480 Lines  |
| V T/B Border        | tvbd	 | 0 ms	    | 0 Lines    |

The VGA signal draws pixels row-by-row (horizontal timing), scanning from left to right. Once a full row is drawn, a horizontal sync pulse (ths) signals the start of the next row.After drawing 480 rows, a vertical sync pulse (tvs) signals the start of a new frame. The back and front porch times provide necessary delays to allow monitors to synchronize properly.

## Pin Assignment 

![image](https://i.sstatic.net/NDfpg.png)

Dodatno, potrebno je postaviti pinove: VCLK -> PIN_A11, BLANK -> PIN_F10, SYNC_o -> PIN_C10
