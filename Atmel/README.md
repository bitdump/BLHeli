This tree contains the BLHeli assembly code for sensorless brushless motor electronic speed control (ESC) boards.
It is designed specifically for use with Eflite mCP X, but may also be used on other helicopters, multicopters or planes.

This tree contains AVR assembly code for Atmel MCU based ESCs. 

Features
--------------------
- Can be configured for helicopter MAIN motor or TAIL motor operation. Or as MULTIcopter motor operation.
- Main motor operation has governor functionality and multicopter motor operation has closed loop functionality.
- Motor operation can be damped for fast motor retardation.
- Many parameters can be programmed, either from PC applications for setup and configuration, or from the TX.
- Supports 1kHz, 2kHz, 4kHz, 8kHz or 12kHz positive or negative pwm as input signal, as well as regular 1-2ms PPM and OneShot125 signal.

Supported Hardware
--------------------
- Lots of different ESCs. See the doc "[BLHeli supported Atmel ESCs.pdf](BLHeli supported Atmel ESCs.pdf)" for details.

Operation and use
--------------------
- See the doc "[BLHeli manual Atmel Rev14.x.pdf](BLHeli manual Atmel Rev14.x.pdf)".

Coding tools
--------------------
The software is written, compiled and debugged in the AVR Studio 4 IDE.

For more information, check out this thread:

http://www.rcgroups.com/forums/showthread.php?t=2136895


