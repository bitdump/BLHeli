This tree contains the BLHeli assembly code for sensorless brushless motor electronic speed control (ESC) boards.
It is designed specifically for use with Eflite mCP X, but may also be used on other helicopters, multicopters or planes.

This tree contains SiLabs assembly code for SiLabs MCU based ESCs. 

Features
--------------------
- Can be configured for helicopter MAIN motor or TAIL motor operation. Or as MULTIcopter motor operation.
- Main motor operation has governor functionality and multicopter motor operation has closed loop functionality.
- Motor operation can be damped for fast motor retardation.
- Many parameters can be programmed, either from PC applications for setup and configuration, or from the TX.
- Supports 1kHz, 2kHz, 4kHz, 8kHz or 12kHz positive or negative pwm as input signal, as well as regular 1-2ms PPM signal.

Supported Hardware
--------------------
- Lots of different ESCs. See the doc "BLHeli supported SiLabs ESCs.pdf" for details.

Operation and use
--------------------
- See the doc "BLHeli manual SiLabs RevN.x.pdf".

Coding tools
--------------------
The software is written and debugged in the SiLabs IDE.
Compilation is done using Raisonance Ride7 and Rkit-51 toolchain.

For more information, check out this thread:

http://www.helifreak.com/showthread.php?t=390517

