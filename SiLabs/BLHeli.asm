$NOMOD51
;**** **** **** **** ****
;
; BLHeli program for controlling brushless motors in helicopters
;
; Copyright 2011, 2012 Steffen Skaug
; This program is distributed under the terms of the GNU General Public License
;
; This file is part of BLHeli.
;
; BLHeli is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; BLHeli is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with BLHeli.  If not, see <http://www.gnu.org/licenses/>.
;
;**** **** **** **** ****
;
; This software is intended for SiLabs 8bit controllers in a micro heli environment.
;
; The software was inspired by and started from from Bernard Konze's BLMC: http://home.versanet.de/~b-konze/blc_6a/blc_6a.htm
; And also Simon Kirby's TGY: https://github.com/sim-/tgy
;
; This file is best viewed with tab width set to 5
;
; The input signal can be positive 1kHz, 2kHz, 4kHz or 8kHz PWM (taken from the "resistor tap" on mCPx)
; And the input signal can be PPM (1-2ms) at rates up to several hundred Hz.
; The code adapts itself to the various input modes/frequencies
; The code ESC can also be programmed to accept inverted input signal.
;
; The first lines of the software must be modified according to the chosen environment:
; Uncomment the selected ESC and main/tail/multi mode
; BESC EQU "ESC"_"mode" 						
; 
;**** **** **** **** ****
; Revision history:
; - Rev1.0: Initial revision based upon BLHeli for AVR controllers
; - Rev2.0: Changed "Eeprom" initialization, layout and defaults
;           Various changes and improvements to comparator reading. Now using timer1 for time from pwm on/off
;           Beeps are made louder
;           Added programmable low voltage limit
;           Added programmable damped tail mode (only for 1S ESCs)
;           Added programmable motor rotation direction
; - Rev2.1: (minor changes by 4712)
;		  Added Disable TX Programming by PC Setup Application 
;		  therfore changed EEPROM_LAYOUT_REVISION = 8					
;		  Added Vdd Monitor as reset source when writing to "EEProm"
;		  Changed for use of batch file to assemble, link and make hex files	
; - Rev2.2: (minor changes by 4712)
;           Added Disable Throttle Re-Arming every motor start by PC Setup Application 
; - Rev2.3: (minor changes by 4712)
;           Added bugfixed (2x CLR C before j(n)c operations)thx Steffen!			
; - Rev2.4: Revisions 2.1 to 2.3 integrated
; - Rev3.0: Added PPM (1050us-1866us) as accepted input signal
;           Added startup rpm as a programming parameter
;           Added startup acceleration as a programming parameter
;           Added option for using voltage measurements to compensate motor power
;           Added governor target by setup as a governor mode option
;           Governor is kept active regardless of rpm
;           Smooth governor spoolup/down in arm and setup modes
;           Increased governor P and I gain programming ranges
;           Increased and changed low voltage limit programming range
;           Disabled tx programming entry for all but the first arming sequence after power on
;           Made it possible to skip parameters in tx programming by setting throttle midstick
;           Made it default not to rearm for every restart
; - Rev3.1: Fixed bug that prevented chosen parameter to be set in tx programming
; - Rev3.2: ...also updated the EEPROM revision parameter
; - Rev3.3: Fixed negative number bug in voltage compensation
;           Fixed bug in startup power calculation for non-default power
;           Prevented possibility for voltage compensation fighting low voltage limiting
;           Applied overall spoolup control to ensure soft spoolup in any mode
;           Added a delay of 3 seconds from initiation of main motor stop until new startup is allowed
;           Reduced beep power to reduce power consumption for very strong motors/ESCs
; - Rev3.4: Fixed bug that prevented full power in governor arm and setup modes
;           Increased NFETON_DELAY for XP_7A and XP_12A to allow for more powerful fets
;           Increased initial spoolup power, and linked to startup power
; - Rev4.0: Fixed bug that made tail tx program beeps very weak
;           Added thermal protection feature
;           Governor P and I gain ranges are extended up to 8.0x gain
;           Startup sequence is aborted upon zero throttle
;           Avoided voltage compensation function induced latency for tail when voltage compensation is not enabled
;           Improved input signal frequency detection robustness
; - Rev4.1: Increased thermal protection temperature limits
; - Rev5.0: Added multi(copter) operating mode. TAIL define changed to MODE with three modes: MAIN, TAIL and MULTI
;           Added programmable commutation timing
;           Added a damped light mode that has less damping, but that can be used with all escs
;           Added programmable damping force
;           Added thermal protection for startup too
;           Added wait beeps when waiting more than 30 sec for throttle above zero (after having been armed)
;           Modified tail idling to provide option for very low speeds
;           Changed PPM range to 1150-1830us
;           Arming sequence is dropped for PPM input, unless it is governor arm mode
;           Loss of input signal will immediately stop the motor for PPM input
;           Bug corrected in Turnigy Plush 6A voltage measurement setup
;           FET switching delays are set for original fets. Stronger/doubled/tripled etc fets may require faster pfet off switching
;           Miscellaneous other changes
; - Rev6.0: Reverted comparator reading routine to rev5.0 equivalent, in order to avoid tail motor stops
;           Added governor range programmability
;           Implemented startup retry sequence with varying startup power for multi mode
;           In damped light mode, damping is now applied to the active nfet phase for fully damped capable ESCs
;
;**** **** **** **** ****
; Up to 8K Bytes of In-System Self-Programmable Flash
; 768 Bytes Internal SRAM
;
;**** **** **** **** ****
; Master clock is internal 24MHz oscillator
; Timer 0 (167/500ns counts) always counts up and is used for
; - PWM generation
; Timer 1 (167/500ns counts) always counts up and is used for
; - Time from pwm on/off event 
; Timer 2 (500ns counts) always counts up and is used for
; - RC pulse timeout/skip counts and commutation times
; Timer 3 (500ns counts) always counts up and is used for
; - Commutation timeouts
; PCA0 (500ns counts) always counts up and is used for
; - RC pulse measurement
;
;**** **** **** **** ****
; Interrupt handling
; The F330/2 does not disable interrupts when entering an interrupt routine.
; Also some interrupt flags need to be cleared by software
; The code disables interrupts in interrupt routines, in order to avoid nested interrupts
; - Interrupts are disabled during beeps, to avoid audible interference from interrupts
; - RC pulse interrupts are periodically disabled in order to reduce interference with pwm interrupts.
;
;**** **** **** **** ****
; Motor control:
; - Brushless motor control with 6 states for each electrical 60 degrees
; - An advance timing of 0deg has zero cross 30deg after one commutation and 30deg before the next
; - Timing advance in this implementation is set to 15deg
; - A "damped" commutation scheme is used, where all pfets are on when pwm is off. This will absorb energy from bemf and make step settling more damped.
; Motor sequence starting from zero crossing:
; - Timer wait: Wt_Comm			15deg	; Time to wait from zero cross to actual commutation
; - Timer wait: Wt_Advance		15deg	; Time to wait for timing advance. Nominal commutation point is after this
; - Timer wait: Wt_Zc_Scan		7.5deg	; Time to wait before looking for zero cross
; - Scan for zero cross			22.5deg	, Nominal, with some motor variations
;
; Motor startup:
; Initial motor rotations are done with the motor controlled as a stepper motor.
; In this stepper motor mode comparator information is not used.
; Settle phase is the first, where there are a few commutations with increasing step length, in order to settle the motor in a predefined position.
; Stepper phase comes next, where there is a step length decrease sequence.
; Aquisition phase is the final phase, for stabilisation before normal bemf commutation run begins.
;
;**** **** **** **** ****
; List of enumerated supported ESCs and modes  (main, tail or multi)
XP_3A_Main 			EQU 1
XP_3A_Tail 			EQU 2
XP_3A_Multi 			EQU 3
XP_7A_Main 			EQU 4
XP_7A_Tail 			EQU 5
XP_7A_Multi 			EQU 6
XP_7A_Fast_Main 		EQU 7
XP_7A_Fast_Tail 		EQU 8
XP_7A_Fast_Multi 		EQU 9
XP_12A_Main 			EQU 10
XP_12A_Tail 			EQU 11
XP_12A_Multi 			EQU 12
XP_18A_Main 			EQU 13
XP_18A_Tail 			EQU 14
XP_18A_Multi 			EQU 15
XP_25A_Main 			EQU 16
XP_25A_Tail 			EQU 17
XP_25A_Multi 			EQU 18
DP_3A_Main 			EQU 19
DP_3A_Tail  			EQU 20
DP_3A_Multi  			EQU 21
Supermicro_3p5A_Main 	EQU 22
Supermicro_3p5A_Tail 	EQU 23   
Supermicro_3p5A_Multi 	EQU 24   
Turnigy_Plush_6A_Main 	EQU 25
Turnigy_Plush_6A_Tail 	EQU 26   
Turnigy_Plush_6A_Multi 	EQU 27   
Turnigy_Plush_10A_Main 	EQU 28
Turnigy_Plush_10A_Tail 	EQU 29   
Turnigy_Plush_10A_Multi 	EQU 30   
Turnigy_Plush_12A_Main 	EQU 31
Turnigy_Plush_12A_Tail 	EQU 32   
Turnigy_Plush_12A_Multi 	EQU 33   
Turnigy_Plush_18A_Main 	EQU 34
Turnigy_Plush_18A_Tail 	EQU 35   
Turnigy_Plush_18A_Multi 	EQU 36   
Turnigy_Plush_25A_Main 	EQU 37
Turnigy_Plush_25A_Tail 	EQU 38   
Turnigy_Plush_25A_Multi 	EQU 39   
Turnigy_Plush_30A_Main 	EQU 40
Turnigy_Plush_30A_Tail 	EQU 41   
Turnigy_Plush_30A_Multi 	EQU 42   
Turnigy_AE_25A_Main 	EQU 43
Turnigy_AE_25A_Tail 	EQU 44   
Turnigy_AE_25A_Multi 	EQU 45   

;**** **** **** **** ****
; Select the ESC and mode to use (or unselect all for use with external batch compile file)
;BESC EQU XP_3A_Main  
;BESC EQU XP_3A_Tail
;BESC EQU XP_3A_Multi
;BESC EQU XP_7A_Main 
;BESC EQU XP_7A_Tail
;BESC EQU XP_7A_Multi 
;BESC EQU XP_7A_Fast_Main
;BESC EQU XP_7A_Fast_Tail
;BESC EQU XP_7A_Fast_Multi 
;BESC EQU XP_12A_Main 
;BESC EQU XP_12A_Tail 
;BESC EQU XP_12A_Multi
;BESC EQU XP_18A_Main 
;BESC EQU XP_18A_Tail 
;BESC EQU XP_18A_Multi
;BESC EQU XP_25A_Main 
;BESC EQU XP_25A_Tail 
;BESC EQU XP_25A_Multi
;BESC EQU DP_3A_Main 						
;BESC EQU DP_3A_Tail
;BESC EQU DP_3A_Multi
;BESC EQU Supermicro_3p5A_Main
;BESC EQU Supermicro_3p5A_Tail 
;BESC EQU Supermicro_3p5A_Multi
;BESC EQU Turnigy_Plush_6A_Main 
;BESC EQU Turnigy_Plush_6A_Tail 
;BESC EQU Turnigy_Plush_6A_Multi
;BESC EQU Turnigy_Plush_10A_Main 
;BESC EQU Turnigy_Plush_10A_Tail 
;BESC EQU Turnigy_Plush_10A_Multi
;BESC EQU Turnigy_Plush_12A_Main 
;BESC EQU Turnigy_Plush_12A_Tail 
;BESC EQU Turnigy_Plush_12A_Multi
;BESC EQU Turnigy_Plush_18A_Main 
;BESC EQU Turnigy_Plush_18A_Tail 
;BESC EQU Turnigy_Plush_18A_Multi
;BESC EQU Turnigy_Plush_25A_Main 
;BESC EQU Turnigy_Plush_25A_Tail 
;BESC EQU Turnigy_Plush_25A_Multi
;BESC EQU Turnigy_Plush_30A_Main 
;BESC EQU Turnigy_Plush_30A_Tail 
;BESC EQU Turnigy_Plush_30A_Multi
;BESC EQU Turnigy_AE_25A_Main 
;BESC EQU Turnigy_AE_25A_Tail 
;BESC EQU Turnigy_AE_25A_Multi

;**** **** **** **** ****
; ESC selection statements
IF BESC == XP_3A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_3A.inc)			; Select XP 3A pinout
ENDIF

IF BESC == XP_3A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_3A.inc)			; Select XP 3A pinout
ENDIF

IF BESC == XP_3A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_3A.inc)			; Select XP 3A pinout
ENDIF

IF BESC == XP_7A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_7A.inc)			; Select XP 7A pinout
ENDIF

IF BESC == XP_7A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_7A.inc)			; Select XP 7A pinout
ENDIF

IF BESC == XP_7A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_7A.inc)			; Select XP 7A pinout
ENDIF

IF BESC == XP_7A_Fast_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_7A_Fast.inc)		; Select XP 7A Fast pinout
ENDIF

IF BESC == XP_7A_Fast_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_7A_Fast.inc)		; Select XP 7A Fast pinout
ENDIF

IF BESC == XP_7A_Fast_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_7A_Fast.inc)		; Select XP 7A Fast pinout
ENDIF

IF BESC == XP_12A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_12A.inc)			; Select XP 12A pinout
ENDIF

IF BESC == XP_12A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_12A.inc)			; Select XP 12A pinout
ENDIF

IF BESC == XP_12A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_12A.inc)			; Select XP 12A pinout
ENDIF

IF BESC == XP_18A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_18A.inc)			; Select XP 18A pinout
ENDIF

IF BESC == XP_18A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_18A.inc)			; Select XP 18A pinout
ENDIF

IF BESC == XP_18A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_18A.inc)			; Select XP 18A pinout
ENDIF

IF BESC == XP_25A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_25A.inc)			; Select XP 25A pinout
ENDIF

IF BESC == XP_25A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_25A.inc)			; Select XP 25A pinout
ENDIF

IF BESC == XP_25A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_25A.inc)			; Select XP 25A pinout
ENDIF

IF BESC == DP_3A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (DP_3A.inc)			; Select DP 3A pinout
ENDIF

IF BESC == DP_3A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (DP_3A.inc)			; Select DP 3A pinout
ENDIF

IF BESC == DP_3A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (DP_3A.inc)			; Select DP 3A pinout
ENDIF

IF BESC == Supermicro_3p5A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Supermicro_3p5A.inc)	; Select Supermicro 3.5A pinout
ENDIF

IF BESC == Supermicro_3p5A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Supermicro_3p5A.inc)	; Select Supermicro 3.5A pinout
ENDIF

IF BESC == Supermicro_3p5A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Supermicro_3p5A.inc)	; Select Supermicro 3.5A pinout
ENDIF

IF BESC == Turnigy_Plush_6A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_6A.inc)	; Select Turnigy Plush 6A pinout
ENDIF

IF BESC == Turnigy_Plush_6A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_6A.inc)	; Select Turnigy Plush 6A pinout
ENDIF

IF BESC == Turnigy_Plush_6A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_6A.inc)	; Select Turnigy Plush 6A pinout
ENDIF

IF BESC == Turnigy_Plush_10A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_10A.inc)	; Select Turnigy Plush 10A pinout
ENDIF

IF BESC == Turnigy_Plush_10A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_10A.inc)	; Select Turnigy Plush 10A pinout
ENDIF

IF BESC == Turnigy_Plush_10A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_10A.inc)	; Select Turnigy Plush 10A pinout
ENDIF

IF BESC == Turnigy_Plush_12A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_12A.inc)	; Select Turnigy Plush 12A pinout
ENDIF

IF BESC == Turnigy_Plush_12A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_12A.inc)	; Select Turnigy Plush 12A pinout
ENDIF

IF BESC == Turnigy_Plush_12A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_12A.inc)	; Select Turnigy Plush 12A pinout
ENDIF

IF BESC == Turnigy_Plush_18A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_18A.inc)	; Select Turnigy Plush 18A pinout
ENDIF

IF BESC == Turnigy_Plush_18A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_18A.inc)	; Select Turnigy Plush 18A pinout
ENDIF

IF BESC == Turnigy_Plush_18A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_18A.inc)	; Select Turnigy Plush 18A pinout
ENDIF

IF BESC == Turnigy_Plush_25A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_25A.inc)	; Select Turnigy Plush 25A pinout
ENDIF

IF BESC == Turnigy_Plush_25A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_25A.inc)	; Select Turnigy Plush 25A pinout
ENDIF

IF BESC == Turnigy_Plush_25A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_25A.inc)	; Select Turnigy Plush 25A pinout
ENDIF

IF BESC == Turnigy_Plush_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_30A.inc)	; Select Turnigy Plush 30A pinout
ENDIF

IF BESC == Turnigy_Plush_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_30A.inc)	; Select Turnigy Plush 30A pinout
ENDIF

IF BESC == Turnigy_Plush_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_30A.inc)	; Select Turnigy Plush 30A pinout
ENDIF

IF BESC == Turnigy_AE_25A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_AE_25A.inc)		; Select Turnigy AE-25A pinout
ENDIF

IF BESC == Turnigy_AE_25A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_AE_25A.inc)		; Select Turnigy AE-25A pinout
ENDIF

IF BESC == Turnigy_AE_25A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_AE_25A.inc)		; Select Turnigy AE-25A pinout
ENDIF

;**** **** **** **** ****

TX_PGM		EQU	1			; Set to 0 to disable tx programming (reduces code size)

;**** **** **** **** ****
; TX programming defaults
DEFAULT_PGM_MAIN_P_GAIN 			EQU 7 ; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MAIN_I_GAIN 			EQU 7 ; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MAIN_GOVERNOR_MODE 	EQU 1 ; 1=Tx 		2=Arm 		3=Setup		4=Off
DEFAULT_PGM_MAIN_GOVERNOR_RANGE 	EQU 1 ; 1=High		2=Low
DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	EQU 3 ; 1=3.0V/c	2=3.1V/c		3=3.2V/c		4=3.3V/c		5=3.4V/c		
DEFAULT_PGM_MAIN_STARTUP_PWR 		EQU 3 ; 1=0.50 	2=0.75 		3=1.00 		4=1.25 		5=1.50
DEFAULT_PGM_MAIN_STARTUP_RPM		EQU 3 ; 1=0.67		2=0.8 		3=1.00 		4=1.25 		5=1.5
DEFAULT_PGM_MAIN_STARTUP_ACCEL	EQU 1 ; 1=0.4 		2=0.7 		3=1.0 		4=1.5 		5=2.3
DEFAULT_PGM_MAIN_COMM_TIMING		EQU 3 ; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_MAIN_DAMPING_FORCE	EQU 1 ; 1=VeryLow 	2=Low 		3=MediumLow 	4=MediumHigh 	5=High
DEFAULT_PGM_MAIN_PWM_FREQ 		EQU 2 ; 1=High 	2=Low		3=DampedLight
DEFAULT_PGM_MAIN_VOLT_COMP 		EQU 1 ; 1=Disabled	2=Enabled
DEFAULT_PGM_MAIN_DIRECTION_REV	EQU 1 ; 1=Normal 	2=Reversed
DEFAULT_PGM_MAIN_RCP_PWM_POL 		EQU 1 ; 1=Positive 	2=Negative

DEFAULT_PGM_TAIL_GAIN 			EQU 3 ; 1=0.75 	2=0.88 		3=1.00 		4=1.12 		5=1.25
DEFAULT_PGM_TAIL_IDLE_SPEED 		EQU 4 ; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_TAIL_STARTUP_PWR 		EQU 3 ; 1=0.50 	2=0.75 		3=1.00 		4=1.25 		5=1.50
DEFAULT_PGM_TAIL_STARTUP_RPM		EQU 3 ; 1=0.67		2=0.8 		3=1.00 		4=1.25 		5=1.5
DEFAULT_PGM_TAIL_STARTUP_ACCEL	EQU 5 ; 1=0.4 		2=0.7 		3=1.0 		4=1.5 		5=2.3
DEFAULT_PGM_TAIL_COMM_TIMING		EQU 3 ; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_TAIL_DAMPING_FORCE	EQU 5 ; 1=VeryLow 	2=Low 		3=MediumLow 	4=MediumHigh 	5=High
IF DAMPED_MODE_ENABLE == 1
DEFAULT_PGM_TAIL_PWM_FREQ	 	EQU 4 ; 1=High 	2=Low 		3=DampedLight  4=Damped 	
ELSE
DEFAULT_PGM_TAIL_PWM_FREQ	 	EQU 3 ; 1=High 	2=Low		3=DampedLight
ENDIF
DEFAULT_PGM_TAIL_VOLT_COMP 		EQU 1 ; 1=Disabled	2=Enabled
DEFAULT_PGM_TAIL_DIRECTION_REV	EQU 1 ; 1=Normal 	2=Reversed
DEFAULT_PGM_TAIL_RCP_PWM_POL 		EQU 1 ; 1=Positive 	2=Negative

DEFAULT_PGM_MULTI_GAIN 			EQU 3 ; 1=0.75 	2=0.88 		3=1.00 		4=1.12 		5=1.25
DEFAULT_PGM_MULTI_LOW_VOLTAGE_LIM	EQU 3 ; 1=3.0V/c	2=3.1V/c		3=3.2V/c		4=3.3V/c		5=3.4V/c		
DEFAULT_PGM_MULTI_STARTUP_PWR 	EQU 1 ; 1=0.50 	2=0.75 		3=1.00 		4=1.25 		5=1.50
DEFAULT_PGM_MULTI_STARTUP_RPM		EQU 1 ; 1=0.67		2=0.8 		3=1.00 		4=1.25 		5=1.5
DEFAULT_PGM_MULTI_STARTUP_ACCEL	EQU 5 ; 1=0.4 		2=0.7 		3=1.0 		4=1.5 		5=2.3
DEFAULT_PGM_MULTI_COMM_TIMING		EQU 3 ; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_MULTI_DAMPING_FORCE	EQU 2 ; 1=VeryLow 	2=Low 		3=MediumLow 	4=MediumHigh 	5=High
IF DAMPED_MODE_ENABLE == 1
DEFAULT_PGM_MULTI_PWM_FREQ	 	EQU 1 ; 1=High 	2=Low 		3=DampedLight  4=Damped 	
ELSE
DEFAULT_PGM_MULTI_PWM_FREQ	 	EQU 1 ; 1=High 	2=Low		3=DampedLight
ENDIF
DEFAULT_PGM_MULTI_VOLT_COMP 		EQU 1 ; 1=Disabled	2=Enabled
DEFAULT_PGM_MULTI_DIRECTION_REV	EQU 1 ; 1=Normal 	2=Reversed
DEFAULT_PGM_MULTI_RCP_PWM_POL 	EQU 1 ; 1=Positive 	2=Negative

DEFAULT_ENABLE_TX_PGM 			EQU 1 ; 1=Enabled 	0=Disabled
DEFAULT_MAIN_REARM_START			EQU 0 ; 1=Enabled 	0=Disabled
DEFAULT_PGM_MAIN_GOV_SETUP_TARGET	EQU 180	; Target for governor in setup mode. Corresponds to 70% throttle

;**** **** **** **** ****
; Constant definitions for main
IF MODE == 0

GOV_SPOOLRATE		EQU	1	; Number of steps for governor requested pwm per 32ms

RCP_TIMEOUT		EQU	64	; Number of timer2L overflows (about 128us) before considering rc pulse lost
RCP_SKIP_RATE		EQU 	32	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
RCP_MIN			EQU 	0	; This is minimum RC pulse length
RCP_MAX			EQU 	250	; This is maximum RC pulse length
RCP_VALIDATE		EQU 	2	; Require minimum this pulse length to validate RC pulse
RCP_STOP			EQU 	1	; Stop motor at or below this pulse length
RCP_STOP_LIMIT		EQU 	3	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

PWM_SETTLE		EQU 	50 	; PWM used when in start settling mode
PWM_STEPPER		EQU 	80 	; PWM used when in start stepper mode
PWM_AQUISITION		EQU 	80 	; PWM used when in start aquisition mode
PWM_INITIAL_RUN	EQU 	40 	; PWM used when in initial run mode 

COMM_TIME_RED		EQU 	5	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
COMM_TIME_MIN		EQU 	5	; Minimum time (in us) for commutation wait

AQUISITION_ROTATIONS	EQU 	2	; Number of rotations to do in the aquisition phase
DAMPED_RUN_ROTATIONS	EQU 	1	; Number of rotations to do in the damped run phase

TEMP_CHECK_RATE		EQU 	8	; Number of adc conversions for each check of temperature (the other conversions are used for voltage)

ENDIF
; Constant definitions for tail
IF MODE == 1

GOV_SPOOLRATE		EQU	1	; Number of steps for governor requested pwm per 32ms

RCP_TIMEOUT		EQU 	24	; Number of timer2L overflows (about 128us) before considering rc pulse lost
RCP_SKIP_RATE		EQU 	6	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
RCP_MIN			EQU 	0	; This is minimum RC pulse length
RCP_MAX			EQU 	250	; This is maximum RC pulse length
RCP_VALIDATE		EQU 	2	; Require minimum this pulse length to validate RC pulse
RCP_STOP			EQU 	1	; Stop motor at or below this pulse length
RCP_STOP_LIMIT		EQU 	100	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

PWM_SETTLE		EQU 	50 	; PWM used when in start settling mode
PWM_STEPPER		EQU 	120 	; PWM used when in start stepper mode
PWM_AQUISITION		EQU 	80 	; PWM used when in start aquisition mode
PWM_INITIAL_RUN	EQU 	40 	; PWM used when in initial run mode 

COMM_TIME_RED		EQU 	5	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
COMM_TIME_MIN		EQU 	5	; Minimum time (in us) for commutation wait

AQUISITION_ROTATIONS	EQU 	2	; Number of rotations to do in the aquisition phase
DAMPED_RUN_ROTATIONS	EQU 	1	; Number of rotations to do in the damped run phase

TEMP_CHECK_RATE		EQU 	8	; Number of adc conversions for each check of temperature (the other conversions are used for voltage)

ENDIF
; Constant definitions for multi
IF MODE == 2

GOV_SPOOLRATE		EQU	1	; Number of steps for governor requested pwm per 32ms

RCP_TIMEOUT		EQU 	24	; Number of timer2L overflows (about 128us) before considering rc pulse lost
RCP_SKIP_RATE		EQU 	6	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
RCP_MIN			EQU 	0	; This is minimum RC pulse length
RCP_MAX			EQU 	250	; This is maximum RC pulse length
RCP_VALIDATE		EQU 	2	; Require minimum this pulse length to validate RC pulse
RCP_STOP			EQU 	1	; Stop motor at or below this pulse length
RCP_STOP_LIMIT		EQU 	3	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

PWM_SETTLE		EQU 	50 	; PWM used when in start settling mode
PWM_STEPPER		EQU 	120 	; PWM used when in start stepper mode
PWM_AQUISITION		EQU 	80 	; PWM used when in start aquisition mode
PWM_INITIAL_RUN	EQU 	40 	; PWM used when in initial run mode 

COMM_TIME_RED		EQU 	5	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
COMM_TIME_MIN		EQU 	5	; Minimum time (in us) for commutation wait

AQUISITION_ROTATIONS	EQU 	2	; Number of rotations to do in the aquisition phase
DAMPED_RUN_ROTATIONS	EQU 	1	; Number of rotations to do in the damped run phase

TEMP_CHECK_RATE		EQU 	8	; Number of adc conversions for each check of temperature (the other conversions are used for voltage)

ENDIF

;**** **** **** **** ****
; Temporary register definitions
Temp1		EQU	R0
Temp2		EQU	R1
Temp3		EQU	R2
Temp4		EQU	R3
Temp5		EQU	R4
Temp6		EQU	R5
Temp7		EQU	R6
Temp8		EQU	R7

;**** **** **** **** ****
; Register definitions
DSEG AT 20h					; Variables segment 

Bit_Access:		DS	1		; Variable at bit accessible address (for non interrupt routines)
Bit_Access_Int:	DS	1		; Variable at bit accessible address (for interrupts)

Requested_Pwm:		DS	1		; Requested pwm (from RC pulse value)
Governor_Req_Pwm:	DS	1		; Governor requested pwm (sets governor target)
Current_Pwm:		DS	1		; Current pwm
Current_Pwm_Comp:	DS	1		; Current pwm that is voltage compensated
Current_Pwm_Limited:DS	1		; Current pwm that is limited (applied to the motor output)
Rcp_Prev_Edge_L:	DS	1		; RC pulse previous edge timer3 timestamp (lo byte)
Rcp_Prev_Edge_H:	DS	1		; RC pulse previous edge timer3 timestamp (hi byte)
Rcp_Timeout_Cnt:	DS	1		; RC pulse timeout counter (decrementing) 
Rcp_Skip_Cnt:		DS	1		; RC pulse skip counter (decrementing) 
Rcp_Edge_Cnt:		DS	1		; RC pulse edge counter 

Flags0:			DS	1    	; State flags 
T3_PENDING		EQU 	0		; Timer3 pending flag
RCP_MEAS_PWM_FREQ	EQU	1		; Measure RC pulse pwm frequency
PWM_ON			EQU	2		; Set in on part of pwm cycle
;				EQU 	3
SETTLE_MODE		EQU 	4		; Set when in motor start settling mode
STEPPER_MODE		EQU	5		; Set when in motor start stepper motor mode
AQUISITION_MODE	EQU	6		; Set when in motor start aquisition mode
INITIAL_RUN_MODE	EQU	7		; Set when in initial rotations of run mode 

Flags1:				DS	1		; State flags
RCP_UPDATED			EQU 	0		; New RC pulse length value available
RCP_EDGE_NO			EQU 	1		; RC pulse edge no. 0=rising, 1=falling
PGM_PWMOFF_DAMPED_FULL	EQU	2		; Programmed pwm off damped mode. Set when all pfets shall be on in pwm_off period
PGM_PWMOFF_DAMPED_LIGHT	EQU	3		; Programmed pwm off damped light mode. Set when only 2 pfets shall be on in pwm_off period
CURR_PWMOFF_DAMPED		EQU	4		; Currently running pwm off cycle is damped
CURR_PWMOFF_COMP_ABLE	EQU	5		; Currently running pwm off cycle is usable for comparator
;					EQU 	6
;					EQU 	7

Flags2:				DS	1		; State flags
RCP_PWM_FREQ_1KHZ		EQU 	0		; RC pulse pwm frequency is 1kHz
RCP_PWM_FREQ_2KHZ		EQU 	1		; RC pulse pwm frequency is 2kHz
RCP_PWM_FREQ_4KHZ		EQU 	2		; RC pulse pwm frequency is 4kHz
RCP_PWM_FREQ_8KHZ		EQU 	3		; RC pulse pwm frequency is 8kHz
PGM_DIR_REV			EQU 	4		; Programmed direction. 0=normal, 1=reversed
PGM_RCP_PWM_POL		EQU	5		; Programmed RC pulse pwm polarity. 0=positive, 1=negative
;					EQU 	6
;					EQU 	7

;**** **** **** **** ****
; RAM definitions
DSEG AT 30h					; Ram data segment 

Initial_Arm:			DS	1		; Variable that is set during the first arm sequence after power on

Power_On_Wait_Cnt_L: 	DS	1		; Power on wait counter (lo byte)
Power_On_Wait_Cnt_H: 	DS	1		; Power on wait counter (hi byte)

Stepper_Step_Beg_L:		DS	1		; Stepper mode step time at the beginning (lo byte)
Stepper_Step_Beg_H:		DS	1		; Stepper mode step time at the beginning (hi byte)
Stepper_Step_End_L:		DS	1		; Stepper mode step time at the end (lo byte)
Stepper_Step_End_H:		DS	1		; Stepper mode step time at the end (hi byte)
Startup_Rot_Cnt:		DS	1		; Startup mode rotations counter (decrementing) 

Prev_Comm_L:			DS	1		; Previous commutation timer3 timestamp (lo byte)
Prev_Comm_H:			DS	1		; Previous commutation timer3 timestamp (hi byte)
Comm_Period4x_L:		DS	1		; Timer3 counts between the last 4 commutations (lo byte)
Comm_Period4x_H:		DS	1		; Timer3 counts between the last 4 commutations (hi byte)
Comm_Phase:			DS	1		; Current commutation phase

Gov_Target_L:			DS	1		; Governor target (lo byte)
Gov_Target_H:			DS	1		; Governor target (hi byte)
Gov_Integral_L:		DS	1		; Governor integral error (lo byte)
Gov_Integral_H:		DS	1		; Governor integral error (hi byte)
Gov_Integral_X:		DS	1		; Governor integral error (ex byte)
Gov_Proportional_L:		DS	1		; Governor proportional error (lo byte)
Gov_Proportional_H:		DS	1		; Governor proportional error (hi byte)
Gov_Prop_Pwm:			DS	1		; Governor calculated new pwm based upon proportional error
Gov_Arm_Target:		DS	1		; Governor arm target value
Gov_Active:			DS	1		; Governor active (enabled when speed is above minimum)

Wt_Advance_L:			DS	1		; Timer3 counts for commutation advance timing (lo byte)
Wt_Advance_H:			DS	1		; Timer3 counts for commutation advance timing (hi byte)
Wt_Zc_Scan_L:			DS	1		; Timer3 counts from commutation to zero cross scan (lo byte)
Wt_Zc_Scan_H:			DS	1		; Timer3 counts from commutation to zero cross scan (hi byte)
Wt_Comm_L:			DS	1		; Timer3 counts from zero cross to commutation (lo byte)
Wt_Comm_H:			DS	1		; Timer3 counts from zero cross to commutation (hi byte)
Wt_Stepper_Step_L:		DS	1		; Timer3 counts for stepper step (lo byte)
Wt_Stepper_Step_H:		DS	1		; Timer3 counts for stepper step (hi byte)

Rcp_PrePrev_Edge_L:		DS	1		; RC pulse pre previous edge pca timestamp (lo byte)
Rcp_PrePrev_Edge_H:		DS	1		; RC pulse pre previous edge pca timestamp (hi byte)
Rcp_Edge_L:			DS	1		; RC pulse edge pca timestamp (lo byte)
Rcp_Edge_H:			DS	1		; RC pulse edge pca timestamp (hi byte)
Rcp_Prev_Period_L:		DS	1		; RC pulse previous period (lo byte)
Rcp_Prev_Period_H:		DS	1		; RC pulse previous period (hi byte)
Rcp_Period_Diff_Accepted:DS	1		; RC pulse period difference acceptable
New_Rcp:				DS	1		; New RC pulse value in pca counts
Prev_Rcp_Pwm_Freq:		DS	1		; Previous RC pulse pwm frequency (used during pwm frequency measurement)
Curr_Rcp_Pwm_Freq:		DS	1		; Current RC pulse pwm frequency (used during pwm frequency measurement)
Rcp_Stop_Cnt:			DS	1		; Counter for RC pulses below stop value 

Pwm_Limit:			DS	1		; Maximum allowed pwm 
Pwm_Limit_Spoolup:		DS	1		; Maximum allowed pwm during spoolup of main
Pwm_Spoolup_Beg:		DS	1		; Pwm to begin main spoolup with
Pwm_Motor_Idle:		DS	1		; Motor idle speed pwm
Pwm_On_Cnt:			DS	1		; Pwm on event counter (used to increase pwm off time for low pwm)
Pwm_Off_Cnt:			DS	1		; Pwm off event counter (used to run some pwm cycles without damping)

Damping_Period:		DS	1		; Damping on/off period
Damping_On:			DS	1		; Damping on part of damping period

Lipo_Adc_Reference_L:	DS	1		; Voltage reference adc value (lo byte)
Lipo_Adc_Reference_H:	DS	1		; Voltage reference adc value (hi byte)
Lipo_Adc_Limit_L:		DS	1		; Low voltage limit adc value (lo byte)
Lipo_Adc_Limit_H:		DS	1		; Low voltage limit adc value (hi byte)
Voltage_Comp_Factor:	DS	1		; Voltage compensation factor for pwm
Adc_Conversion_Cnt:		DS	1		; Adc conversion counter

Tx_Pgm_Func_No:		DS	1		; Function number when doing programming by tx
Tx_Pgm_Paraval_No:		DS	1		; Parameter value number when doing programming by tx
Tx_Pgm_Beep_No:		DS	1		; Beep number when doing programming by tx

Pgm_Gov_P_Gain:		DS	1		; Programmed governor P gain
Pgm_Gov_I_Gain:		DS	1		; Programmed governor I gain
Pgm_Gov_Mode:			DS	1		; Programmed governor mode
Pgm_Gov_Range:			DS	1		; Programmed governor range
Pgm_Low_Voltage_Lim:	DS	1		; Programmed low voltage limit
Pgm_Motor_Gain:		DS	1		; Programmed motor gain
Pgm_Motor_Idle:		DS	1		; Programmed motor idle speed
Pgm_Startup_Pwr:		DS	1		; Programmed startup power
Curr_Startup_Pwr:		DS	1		; Current startup power
Startup_Try_No:		DS	1		; Startup try number

Pgm_Enable_TX_Pgm:		DS 	1		; Programmed enable/disable value for TX programming
Pgm_Main_Rearm_Start:	DS 	1		; Programmed enable/disable re-arming main every start 
Pgm_Gov_Setup_Target:	DS 	1		; Programmed main governor setup target
Pgm_Startup_Rpm:		DS	1		; Programmed startup rpm
Pgm_Startup_Accel:		DS	1		; Programmed startup acceleration
Pgm_Comm_Timing:		DS	1		; Programmed commutation timing
Pgm_Damping_Force:		DS	1		; Programmed damping force
Pgm_Pwm_Freq:			DS	1		; Programmed pwm frequency
Pgm_Volt_Comp:			DS	1		; Programmed voltage compensation
Pgm_Direction_Rev:		DS	1		; Programmed rotation direction
Pgm_Input_Pol:			DS	1		; Programmed input pwm polarity

DSEG AT 80h					
Tag_Temporary_Storage:	DS	48		; Temporary storage for tags when updating "Eeprom"


;**** **** **** **** ****
CSEG AT 1A00h            ; "Eeprom" segment
EEPROM_FW_MAIN_REVISION	EQU	6		; Main revision of the firmware
EEPROM_FW_SUB_REVISION	EQU	0		; Sub revision of the firmware
EEPROM_LAYOUT_REVISION	EQU	12		; Revision of the EEPROM layout

Eep_FW_Main_Revision:	DB	EEPROM_FW_MAIN_REVISION			; EEPROM firmware main revision number
Eep_FW_Sub_Revision:	DB	EEPROM_FW_SUB_REVISION			; EEPROM firmware sub revision number
Eep_Layout_Revision:	DB	EEPROM_LAYOUT_REVISION			; EEPROM layout revision number

IF MODE == 0
Eep_Pgm_Gov_P_Gain:		DB	DEFAULT_PGM_MAIN_P_GAIN			; EEPROM copy of programmed governor P gain
Eep_Pgm_Gov_I_Gain:		DB	DEFAULT_PGM_MAIN_I_GAIN			; EEPROM copy of programmed governor I gain
Eep_Pgm_Gov_Mode:		DB	DEFAULT_PGM_MAIN_GOVERNOR_MODE	; EEPROM copy of programmed governor mode

Eep_Pgm_Low_Voltage_Lim:	DB	DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	; EEPROM copy of programmed low voltage limit
_Eep_Pgm_Motor_Gain:	DB	0FFh							
_Eep_Pgm_Motor_Idle:	DB	0FFh							
Eep_Pgm_Startup_Pwr:	DB	DEFAULT_PGM_MAIN_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:		DB	DEFAULT_PGM_MAIN_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction_Rev:	DB	DEFAULT_PGM_MAIN_DIRECTION_REV	; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:		DB	DEFAULT_PGM_MAIN_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:		DB	0A5h							; EEPROM initialized signature low byte
Eep_Initialized_H:		DB	05Ah							; EEPROM initialized signature high byte
Eep_Enable_TX_Pgm:		DB	DEFAULT_ENABLE_TX_PGM			; EEPROM TX programming enable
Eep_Main_Rearm_Start:	DB	DEFAULT_MAIN_REARM_START			; EEPROM re-arming main enable
Eep_Pgm_Gov_Setup_Target:DB	DEFAULT_PGM_MAIN_GOV_SETUP_TARGET	; EEPROM main governor setup target
Eep_Pgm_Startup_Rpm:	DB	DEFAULT_PGM_MAIN_STARTUP_RPM		; EEPROM copy of programmed startup rpm
Eep_Pgm_Startup_Accel:	DB	DEFAULT_PGM_MAIN_STARTUP_ACCEL	; EEPROM copy of programmed startup acceleration
Eep_Pgm_Volt_Comp:		DB	DEFAULT_PGM_MAIN_VOLT_COMP		; EEPROM copy of programmed voltage compensation
Eep_Pgm_Comm_Timing:	DB	DEFAULT_PGM_MAIN_COMM_TIMING		; EEPROM copy of programmed commutation timing
Eep_Pgm_Damping_Force:	DB	DEFAULT_PGM_MAIN_DAMPING_FORCE	; EEPROM copy of programmed damping force
Eep_Pgm_Gov_Range:		DB	DEFAULT_PGM_MAIN_GOVERNOR_RANGE	; EEPROM copy of programmed governor range
ENDIF

IF MODE == 1
_Eep_Pgm_Gov_P_Gain:	DB	0FFh							
_Eep_Pgm_Gov_I_Gain:	DB	0FFh							
_Eep_Pgm_Gov_Mode:		DB 	0FFh							

_Eep_Pgm_Low_Voltage_Lim:DB	0FFh							
Eep_Pgm_Motor_Gain:		DB	DEFAULT_PGM_TAIL_GAIN			; EEPROM copy of programmed tail gain
Eep_Pgm_Motor_Idle:		DB	DEFAULT_PGM_TAIL_IDLE_SPEED		; EEPROM copy of programmed tail idle speed
Eep_Pgm_Startup_Pwr:	DB	DEFAULT_PGM_TAIL_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:		DB	DEFAULT_PGM_TAIL_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction_Rev:	DB	DEFAULT_PGM_TAIL_DIRECTION_REV	; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:		DB	DEFAULT_PGM_TAIL_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:		DB	05Ah							; EEPROM initialized signature low byte
Eep_Initialized_H:		DB	0A5h							; EEPROM initialized signature high byte
Eep_Enable_TX_Pgm:		DB	DEFAULT_ENABLE_TX_PGM			; EEPROM TX programming enable
_Eep_Main_Rearm_Start:	DB	0FFh							
_Eep_Pgm_Gov_Setup_Target:DB	0FFh							
Eep_Pgm_Startup_Rpm:	DB	DEFAULT_PGM_TAIL_STARTUP_RPM		; EEPROM copy of programmed startup rpm
Eep_Pgm_Startup_Accel:	DB	DEFAULT_PGM_TAIL_STARTUP_ACCEL	; EEPROM copy of programmed startup acceleration
Eep_Pgm_Volt_Comp:		DB	DEFAULT_PGM_TAIL_VOLT_COMP		; EEPROM copy of programmed voltage compensation
Eep_Pgm_Comm_Timing:	DB	DEFAULT_PGM_TAIL_COMM_TIMING		; EEPROM copy of programmed commutation timing
Eep_Pgm_Damping_Force:	DB	DEFAULT_PGM_TAIL_DAMPING_FORCE	; EEPROM copy of programmed damping force
Eep_Pgm_Gov_Range:		DB	0FFh	
ENDIF

IF MODE == 2
_Eep_Pgm_Gov_P_Gain:	DB	0FFh							
_Eep_Pgm_Gov_I_Gain:	DB	0FFh							
_Eep_Pgm_Gov_Mode:		DB	0FFh							

Eep_Pgm_Low_Voltage_Lim:	DB	DEFAULT_PGM_MULTI_LOW_VOLTAGE_LIM	; EEPROM copy of programmed low voltage limit
Eep_Pgm_Motor_Gain:		DB	DEFAULT_PGM_MULTI_GAIN			; EEPROM copy of programmed tail gain
Eep_Pgm_Motor_Idle:		DB	0FFh							; EEPROM copy of programmed tail idle speed
Eep_Pgm_Startup_Pwr:	DB	DEFAULT_PGM_MULTI_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:		DB	DEFAULT_PGM_MULTI_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction_Rev:	DB	DEFAULT_PGM_MULTI_DIRECTION_REV	; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:		DB	DEFAULT_PGM_MULTI_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:		DB	055h							; EEPROM initialized signature low byte
Eep_Initialized_H:		DB	0AAh							; EEPROM initialized signature high byte
Eep_Enable_TX_Pgm:		DB	DEFAULT_ENABLE_TX_PGM			; EEPROM TX programming enable
_Eep_Main_Rearm_Start:	DB	0FFh							
_Eep_Pgm_Gov_Setup_Target:DB	0FFh							
Eep_Pgm_Startup_Rpm:	DB	DEFAULT_PGM_MULTI_STARTUP_RPM		; EEPROM copy of programmed startup rpm
Eep_Pgm_Startup_Accel:	DB	DEFAULT_PGM_MULTI_STARTUP_ACCEL	; EEPROM copy of programmed startup acceleration
Eep_Pgm_Volt_Comp:		DB	DEFAULT_PGM_MULTI_VOLT_COMP		; EEPROM copy of programmed voltage compensation
Eep_Pgm_Comm_Timing:	DB	DEFAULT_PGM_MULTI_COMM_TIMING		; EEPROM copy of programmed commutation timing
Eep_Pgm_Damping_Force:	DB	DEFAULT_PGM_MULTI_DAMPING_FORCE	; EEPROM copy of programmed damping force
Eep_Pgm_Gov_Range:		DB	0FFh	
ENDIF

Eep_Dummy:			DB	0FFh							; EEPROM address for safety reason

CSEG AT 1A50h
Eep_ESC_MCU:			DB	"#BLHELI#F330#   "				; Project and MCU tag (16 Bytes)

CSEG AT 1A60h
Eep_Name:				DB	"                "				; Name tag (16 Bytes)

;**** **** **** **** ****
	Interrupt_Table_Definition		; SiLabs interrupts
CSEG AT 80h			; Code segment after interrupt vectors 

;**** **** **** **** ****

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer0 interrupt routine
;
; Assumptions: DPTR register must be set to desired pwm_nfet_on label
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t0_int:	; Used for pwm control
	clr 	EA			; Disable all interrupts
	push	PSW			; Preserve registers through interrupt
	push	ACC
	setb	PSW.3		; Select register bank 1 for interrupt routines
	; Reset timer1
	mov	TL1, #0		
	; Check if pwm is on
	jb	Flags0.PWM_ON, t0_int_pwm_off	; Is pwm on?

	; Pwm on cycle
	inc	Pwm_On_Cnt				; Increment event counter
	; Do not execute pwm on for zero pwm
	mov	A, Current_Pwm_Limited
	jnz	t0_int_pwm_on_execute
	jmp	t0_int_pwm_on_exit

t0_int_pwm_on_execute:
	; Skip pwm on cycles for very low pwm
	clr	C
	mov	A, #5					; Only skip for very low pwm
	subb	A, Current_Pwm_Limited		; Check skipping shall be done (for low pwm only)
	jc	t0_int_pwm_on_no_skip

	subb	A, Pwm_On_Cnt				; Check if on cycle is to be skipped
	jc	t0_int_pwm_on_no_skip


	mov	TL0, #150					; Write start point for timer
	jmp	t0_int_pwm_on_exit

t0_int_pwm_on_no_skip:
	; Set timer for coming on cycle length
	mov 	A, Current_Pwm_Limited		; Load current pwm
	cpl	A						; cpl is 255-x
	mov	TL0, A					; Write start point for timer
	; Proceed with pwm on
	mov	Pwm_On_Cnt, #0				; Reset pwm on event counter
	setb	Flags0.PWM_ON				; Set pwm on flag
	clr	A
	jmp	@A+DPTR					; No - jump to pwm on routines. DPTR should be set to one of the pwm_nfet_on labels



t0_int_pwm_off:
	; Pwm off cycle. Set timer for coming off cycle length
	mov	TL0, Current_Pwm_Limited		; Load new timer setting
	; Clear pwm on flag
	clr	Flags0.PWM_ON	
	; Set full PWM (on all the time) if current PWM near max. This will give full power, but at the cost of a small "jump" in power
	clr	C
	mov	A, Current_Pwm_Limited		; Load current pwm
	subb	A, #255					; Above full pwm?
	jc	($+4)					; No - branch
	ajmp	t0_int_pwm_off_exit			; Yes - exit

	All_nFETs_Off 					; No - switch off all nfets
	inc	Pwm_Off_Cnt				; Increment event counter
	; Do not execute pwm off damped for zero pwm
	mov	A, Current_Pwm_Limited
	jnz	t0_int_pwm_off_execute
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_execute:
	; If damped operation, set pFETs on in pwm_off
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, t0_int_pwm_off_damped	; Damped light operation?
	jb	Flags1.PGM_PWMOFF_DAMPED_FULL, t0_int_pwm_off_damped	; Fully damped operation?
	clr	Flags1.CURR_PWMOFF_DAMPED	; Set non damped status
	setb	Flags1.CURR_PWMOFF_COMP_ABLE	; Set comparator usable status
	jmp	t0_int_pwm_off_exit			; Not damped - exit	

t0_int_pwm_off_damped:
	setb	Flags1.CURR_PWMOFF_DAMPED	; Set damped status
	clr	Flags1.CURR_PWMOFF_COMP_ABLE	; Set comparator unusable status
	clr	C
	mov	A, Pwm_Off_Cnt				; Is damped on number reached?
	dec	A
	subb	A, Damping_On
	jc	t0_int_pwm_off_do_damped		; No - apply damping

	setb	Flags1.CURR_PWMOFF_COMP_ABLE	; Set comparator usable status

	clr	C
	mov	A, Pwm_Off_Cnt					
	subb	A, Damping_Period			; Is damped period number reached?
	jc	($+5)					; No - Branch

	mov	Pwm_Off_Cnt, #0			; Yes - clear counter

	jmp	t0_int_pwm_off_exit			; Not damped - exit	

t0_int_pwm_off_do_damped:
	; Delay to allow nFETs to go off before pFETs are turned on (only in full damped mode)
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, t0_int_pwm_off_damped_light	; If damped light operation - branch

	mov	A, #PFETON_DELAY
	djnz	ACC, $	
	All_pFETs_On 					; Switch on all pfets
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_damped_light:
IF DAMPED_MODE_ENABLE == 1
	setb	Flags1.CURR_PWMOFF_COMP_ABLE	; Set comparator usable status always for damped light mode on fully damped capable escs
ENDIF
	mov	A, Comm_Phase				; Turn on pfets according to commutation phase
	jb	ACC.2, t0_int_pwm_off_comm_4_5_6
	jb	ACC.1, t0_int_pwm_off_comm_2_3

IF DAMPED_MODE_ENABLE == 0
	ApFET_On			; Comm phase 1 - turn on A
ELSE
	CpFET_On			; Comm phase 1 - turn on C
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_2_3:
	jb	ACC.0, t0_int_pwm_off_comm_3
IF DAMPED_MODE_ENABLE == 0
	BpFET_On			; Comm phase 2 - turn on B
ELSE
	CpFET_On			; Comm phase 2 - turn on C
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_3:
IF DAMPED_MODE_ENABLE == 0
	CpFET_On			; Comm phase 3 - turn on C
ELSE
	BpFET_On			; Comm phase 3 - turn on B
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_4_5_6:
	jb	ACC.1, t0_int_pwm_off_comm_6
	jb	ACC.0, t0_int_pwm_off_comm_5

IF DAMPED_MODE_ENABLE == 0
	ApFET_On			; Comm phase 4 - turn on A
ELSE
	BpFET_On			; Comm phase 4 - turn on B
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_5:
IF DAMPED_MODE_ENABLE == 0
	BpFET_On			; Comm phase 5 - turn on B
ELSE
	ApFET_On			; Comm phase 5 - turn on A
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_6:
IF DAMPED_MODE_ENABLE == 0
	CpFET_On			; Comm phase 6 - turn on C
ELSE
	ApFET_On			; Comm phase 6 - turn on A
ENDIF

t0_int_pwm_off_exit:	; Exit from pwm off cycle
	pop	ACC			; Restore preserved registers
	pop	PSW
	clr	PSW.3		; Select register bank 0 for main program routines	
	setb	EA			; Enable all interrupts
	reti



pwm_nofet_on:	; Dummy pwm on cycle
	ajmp	t0_int_pwm_on_exit

pwm_afet_on:	; Pwm on cycle afet on (bfet off)
	BnFET_off
	AnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_bfet_on:	; Pwm on cycle bfet on (cfet off)
	CnFET_off
	BnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_cfet_on:	; Pwm on cycle cfet on (afet off)
	AnFET_off
	CnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_anfet_bpfet_on:	; Pwm on cycle anfet on (bnfet off) and bpfet on (used in damped state 6)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #5							; Set low delay as default
	jnb	Flags1.PGM_PWMOFF_DAMPED_FULL, ($+5)	; Fully damped operation?
	mov	A, #NFETON_DELAY					; Yes - set full delay
	ApFET_off
	CpFET_off
	djnz ACC,	$
	BnFET_off 							; Switch nFETs
	AnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_anfet_cpfet_on:	; Pwm on cycle anfet on (bnfet off) and cpfet on (used in damped state 5)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #5							; Set low delay as default
	jnb	Flags1.PGM_PWMOFF_DAMPED_FULL, ($+5)	; Fully damped operation?
	mov	A, #NFETON_DELAY					; Yes - set full delay
	ApFET_off
	BpFET_off
	djnz ACC,	$
	BnFET_off								; Switch nFETs
	AnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_bnfet_cpfet_on:	; Pwm on cycle bnfet on (cnfet off) and cpfet on (used in damped state 4)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #5							; Set low delay as default
	jnb	Flags1.PGM_PWMOFF_DAMPED_FULL, ($+5)	; Fully damped operation?
	mov	A, #NFETON_DELAY					; Yes - set full delay
	BpFET_off
	ApFET_off
	djnz ACC,	$
	CnFET_off								; Switch nFETs
	BnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_bnfet_apfet_on:	; Pwm on cycle bnfet on (cnfet off) and apfet on (used in damped state 3)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #5							; Set low delay as default
	jnb	Flags1.PGM_PWMOFF_DAMPED_FULL, ($+5)	; Fully damped operation?
	mov	A, #NFETON_DELAY					; Yes - set full delay
	BpFET_off
	CpFET_off
	djnz ACC,	$
	CnFET_off								; Switch nFETs
	BnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_cnfet_apfet_on:	; Pwm on cycle cnfet on (anfet off) and apfet on (used in damped state 2)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #5							; Set low delay as default
	jnb	Flags1.PGM_PWMOFF_DAMPED_FULL, ($+5)	; Fully damped operation?
	mov	A, #NFETON_DELAY					; Yes - set full delay
	CpFET_off
	BpFET_off
	djnz ACC,	$
	AnFET_off								; Switch nFETs
	CnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_cnfet_bpfet_on:	; Pwm on cycle cnfet on (anfet off) and bpfet on (used in damped state 1)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #5							; Set low delay as default
	jnb	Flags1.PGM_PWMOFF_DAMPED_FULL, ($+5)	; Fully damped operation?
	mov	A, #NFETON_DELAY					; Yes - set full delay
	CpFET_off
	ApFET_off
	djnz ACC,	$
	AnFET_off								; Switch nFETs
	CnFET_on
	ajmp	t0_int_pwm_on_exit

t0_int_pwm_on_exit:
	pop	ACC			; Restore preserved registers
	pop	PSW
	clr	PSW.3		; Select register bank 0 for main program routines	
	setb	EA			; Enable all interrupts
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer2 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t2_int:	; Happens every 128us for low byte and every 32ms for high byte
	clr 	EA			; Disable all interrupts
	push	PSW			; Preserve registers through interrupt
	push	ACC
	setb	PSW.3		; Select register bank 1 for interrupt routines
	; Clear low byte interrupt flag
	clr	TF2L						; Clear interrupt flag
	; Check RC pulse timeout counter
	mov	A, Rcp_Timeout_Cnt			; RC pulse timeout count zero?
	jz	t2_int_pulses_absent		; Yes - pulses are absent

	; Decrement timeout counter (if PWM)
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2					; Check pwm frequency flags
	jz	t2_int_skip_start			; If no flag is set (PPM) - branch

	dec	Rcp_Timeout_Cnt			; No - decrement
	ajmp	t2_int_skip_start

t2_int_pulses_absent:
	; Timeout counter has reached zero, pulses are absent
	mov	Temp1, #RCP_MIN			; RCP_MIN as default
	mov	Temp2, #RCP_MIN			
	Read_Rcp_Int 					; Look at value of Rcp_In
	jnb	ACC.Rcp_In, ($+5)			; Is it high?
	mov	Temp1, #RCP_MAX			; Yes - set RCP_MAX
	Rcp_Int_First 					; Set interrupt trig to first again
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	clr	Flags1.RCP_EDGE_NO			; Set first edge flag
	Read_Rcp_Int 					; Look once more at value of Rcp_In
	jnb	ACC.Rcp_In, ($+5)			; Is it high?
	mov	Temp2, #RCP_MAX			; Yes - set RCP_MAX
	clr	C
	mov	A, Temp1
	subb	A, Temp2					; Compare the two readings of Rcp_In
	jnz 	t2_int_pulses_absent		; Go back if they are not equal

	jnb	Flags0.RCP_MEAS_PWM_FREQ, ($+6)	; Is measure RCP pwm frequency flag set?

	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT	; Yes - set timeout count to start value

	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2					; Check pwm frequency flags
	jz	t2_int_ppm_timeout_set		; If no flag is set (PPM) - branch

	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT	; Set timeout count to start value

t2_int_ppm_timeout_set:
	mov	New_Rcp, Temp1				; Store new pulse length
	setb	Flags1.RCP_UPDATED		 	; Set updated flag

t2_int_skip_start:
	; Check RC pulse skip counter
	mov	A, Rcp_Skip_Cnt			
	jz 	t2_int_skip_end			; If RC pulse skip count is zero - end skipping RC pulse detection
	
	; Decrement skip counter (only if edge counter is zero)
	dec	Rcp_Skip_Cnt				; Decrement
	ajmp	t2_int_rcp_update_start

t2_int_skip_end:
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2					; Check pwm frequency flags
	jz	t2_int_rcp_update_start		; If no flag is set (PPM) - branch

	; Skip counter has reached zero, start looking for RC pulses again
	Rcp_Int_Enable 				; Enable RC pulse interrupt
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	
t2_int_rcp_update_start:
	; Process updated RC pulse
	jb	Flags1.RCP_UPDATED, ($+5)	; Is there an updated RC pulse available?
	ajmp	t2_int_pwm_exit			; No - exit

	mov	A, New_Rcp				; Load new pulse value
	mov	Temp1, A
	clr	Flags1.RCP_UPDATED		 	; Flag that pulse has been evaluated
	; Limit the maximum value to avoid wrap when scaled to pwm range
IF MODE >= 1	; Tail or multi
	clr	C
	subb	A, #240			; 240 = (255/1.0625) Needs to be updated according to multiplication factor below		
	jc	t2_int_rcp_update_mult

	mov	A, #240			; Set requested pwm to max
	mov	Temp1, A		
ENDIF

t2_int_rcp_update_mult:	
IF MODE >= 1	; Tail or multi
	; Multiply by 1.0625 (optional adjustment gyro gain)
	mov	A, Temp1
	swap	A			; After this "0.0625"
	anl	A, #0Fh
	add	A, Temp1
	mov	Temp1, A		
	; Adjust tail gain
	mov	Temp2, Pgm_Motor_Gain	
	cjne	Temp2, #3, ($+5)			; Is gain 1?
	ajmp	t2_int_pwm_min_run			; Yes - skip adjustment

	clr	C
	rrc	A			; After this "0.5"
	clr	C
	rrc	A			; After this "0.25"
	mov	Bit_Access_Int, Pgm_Motor_Gain	
	jb	Bit_Access_Int.0, t2_int_rcp_gain_corr	; Branch if bit 0 in gain is set

	clr	C
	rrc	A			; After this "0.125"

t2_int_rcp_gain_corr:
	jb	Bit_Access_Int.2, t2_int_rcp_gain_pos	; Branch if bit 2 in gain is set

	xch	A, Temp1
	clr	C
	subb	A, Temp1					; Apply negative correction
	mov	Temp1, A
	ajmp	t2_int_pwm_min_run

t2_int_rcp_gain_pos:
	add	A, Temp1					; Apply positive correction
	mov	Temp1, A
	jnc	t2_int_pwm_min_run			; Above max?

	mov	A, #0FFh					; Yes - limit
	mov	Temp1, A

ENDIF

t2_int_pwm_min_run: 
	; Limit minimum pwm
	clr	C
	mov	A, Temp1
	subb	A, Pwm_Motor_Idle			; Is requested pwm lower than minimum?
	jnc	t2_int_pwm_update			; No - branch

	mov	A, Pwm_Motor_Idle			; Yes - limit pwm to Pwm_Motor_Idle	
	mov	Temp1, A

t2_int_pwm_update: 
	; Check if any startup mode flags are set
	mov	A, Flags0
	anl	A, #((1 SHL SETTLE_MODE)+(1 SHL STEPPER_MODE)+(1 SHL AQUISITION_MODE)+(1 SHL INITIAL_RUN_MODE))
	jnz	t2_int_pwm_exit			; Exit if any startup mode set (pwm controlled by set_startup_pwm)

	; Update requested_pwm
	mov	Requested_Pwm, Temp1		; Set requested pwm

	mov	Temp1, Pgm_Gov_Mode			; Governor mode?
	cjne	Temp1, #4, t2_int_pwm_exit	; Yes - branch

	; Update current pwm
	mov	Current_Pwm, Requested_Pwm
IF MODE >= 1	; Tail or multi
	; If tail/multi and voltage compensation is not enabled, then set current_pwm_limited
	clr	C
	mov	A, Pgm_Volt_Comp
	subb	A, #2
	jnc	t2_int_pwm_exit

	mov	Current_Pwm_Limited, Current_Pwm	; Default not limited
	clr	C
	mov	A, Current_Pwm					; Check against limit
	subb	A, Pwm_Limit
	jc	($+5)						; If current pwm below limit - branch

	mov	Current_Pwm_Limited, Pwm_Limit	; Limit pwm
ENDIF

t2_int_pwm_exit:	
	; Check if high byte flag is set
	jb	TF2H, t2h_int		
	pop	ACC			; Restore preserved registers
	pop	PSW
	clr	PSW.3		; Select register bank 0 for main program routines	
	setb	EA			; Enable all interrupts
	reti

t2h_int:
	; High byte interrupt (happens every 32ms)
	clr	TF2H					; Clear interrupt flag
	mov	Temp1, #GOV_SPOOLRATE	; Load governor spool rate
	; Check RC pulse timeout counter (used here for PPM only)
	mov	A, Rcp_Timeout_Cnt			; RC pulse timeout count zero?
	jz	t2h_int_rcp_stop_check		; Yes - do not decrement

	; Decrement timeout counter (if PPM)
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2					; Check pwm frequency flags
	jnz	t2h_int_rcp_stop_check		; If a flag is set (PWM) - branch

	dec	Rcp_Timeout_Cnt			; No flag set (PPM) - decrement

t2h_int_rcp_stop_check:
	; Check RC pulse against stop value
	mov	A, New_Rcp			; Load new pulse value
	clr	C
	subb	A, #RCP_STOP			; Check if pulse is below stop value
	jc	t2h_int_rcp_stop

	; RC pulse higher than stop value, reset stop counter
	mov	Rcp_Stop_Cnt, #0		; Reset rcp stop counter
	ajmp	t2h_int_rcp_gov_pwm

t2h_int_rcp_stop:	
	; RC pulse less than stop value, increment stop counter
	mov	A, Rcp_Stop_Cnt		; Load rcp stop counter
	inc	A					; Check if counter is max
	jz	t2h_int_rcp_gov_pwm		; Branch if counter is equal to max

	inc	Rcp_Stop_Cnt			; Increment stop counter 

t2h_int_rcp_gov_pwm:
IF MODE == 0	; Main
	mov	A, Pgm_Gov_Mode				; Governor target by arm mode?
	cjne	A, #2, t2h_int_rcp_gov_by_setup	; No - branch

	mov	A, Gov_Active					; Is governor active?
	jz	t2h_int_rcp_gov_by_tx			; No - branch (this ensures soft spoolup by tx)

	clr	C
	mov	A, Requested_Pwm
	subb	A, #50						; Is requested pwm below 20%?
	jc	t2h_int_rcp_gov_by_tx			; Yes - branch (this enables a soft spooldown)

	mov	Requested_Pwm, Gov_Arm_Target		; Yes - load arm target

t2h_int_rcp_gov_by_setup:
	mov	A, Pgm_Gov_Mode				; Governor target by setup mode?
	cjne	A, #3, t2h_int_rcp_gov_by_tx		; No - branch

	mov	A, Gov_Active					; Is governor active?
	jz	t2h_int_rcp_gov_by_tx			; No - branch (this ensures soft spoolup by tx)

	clr	C
	mov	A, Requested_Pwm
	subb	A, #50						; Is requested pwm below 20%?
	jc	t2h_int_rcp_gov_by_tx			; Yes - branch (this enables a soft spooldown)

	mov	Requested_Pwm, Pgm_Gov_Setup_Target; Gov by setup - load setup target

t2h_int_rcp_gov_by_tx:
	clr	C
	mov	A, Governor_Req_Pwm
	subb	A, Requested_Pwm				; Is governor requested pwm equal to requested pwm?
	jz	t2h_int_rcp_gov_pwm_done			; Yes - branch

	jc	t2h_int_rcp_gov_pwm_inc			; No - if lower, then increment

	dec	Governor_Req_Pwm				; No - if higher, then decrement
	ajmp	t2h_int_rcp_gov_pwm_done

t2h_int_rcp_gov_pwm_inc:
	inc	Governor_Req_Pwm				; Increment

t2h_int_rcp_gov_pwm_done:
	djnz	Temp1, t2h_int_rcp_gov_pwm		; If not number of steps processed - go back
	mov	A, Pwm_Limit_Spoolup			; Increment spoolup pwm, for a 8 seconds spoolup
	inc	A
	jnz	($+3)						; Limit to 255

	dec	A

	mov	Pwm_Limit_Spoolup, A
ENDIF
IF MODE == 2	; Multi
	mov	A, Pwm_Limit_Spoolup			; Increment spoolup pwm, for a 0.8 seconds spoolup
	clr	C
	add	A, #10
	jnc	t2h_int_rcp_no_limit			; If below 255 - branch

	mov	Pwm_Limit_Spoolup, #0FFh
	ajmp	t2h_int_rcp_exit

t2h_int_rcp_no_limit:
	mov	Pwm_Limit_Spoolup, A
ENDIF

t2h_int_rcp_exit:
	pop	ACC			; Restore preserved registers
	pop	PSW
	clr	PSW.3		; Select register bank 0 for main program routines	
	setb	EA			; Enable all interrupts
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer3 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t3_int:	; Used for commutation timing
	clr 	EA			; Disable all interrupts
	anl	TMR3CN, #07Fh		; Clear interrupt flag
	clr	Flags0.T3_PENDING 	; Flag that timer has wrapped
	setb	EA			; Enable all interrupts
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; PCA interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
pca_int:	; Used for RC pulse timing
	clr 	EA			; Disable all interrupts
	push	PSW			; Preserve registers through interrupt
	push	ACC
	setb	PSW.3		; Select register bank 1 for interrupt routines
	; Get PCA0 capture values
	mov	Temp1, PCA0CPL0
	mov	Temp2, PCA0CPH0
	; Clear interrupt flag
	Rcp_Clear_Int_Flag 				
	; Check which edge it is
	jnb	Flags1.RCP_EDGE_NO, ($+5)	; Is it a first edge trig?
	ajmp pca_int_second_meas_pwm_freq	; No - branch to second

	Rcp_Int_Second					; Yes - set second edge trig
	setb	Flags1.RCP_EDGE_NO			; Set second edge flag
	; Read RC signal level
	Read_Rcp_Int			
	; Test RC signal level
	jb	ACC.Rcp_In, ($+5)			; Is it high?
	ajmp	pca_int_fail_minimum		; No - jump to fail minimum

	; RC pulse was high, store RC pulse start timestamp
	mov	Rcp_Prev_Edge_L, Temp1
	mov	Rcp_Prev_Edge_H, Temp2
	ajmp	pca_int_exit				; Exit

pca_int_fail_minimum:
	; Prepare for next interrupt
	Rcp_Int_First					; Set interrupt trig to first again
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	clr	Flags1.RCP_EDGE_NO			; Set first edge flag
	mov	Temp1, #RCP_MIN			; Set RC pulse value to minimum
	Read_Rcp_Int 					; Test RC signal level again
	jnb	ACC.Rcp_In, ($+5)			; Is it high?
	ajmp	pca_int_set_timeout			; Yes - set new timeout and exit

	mov	New_Rcp, Temp1				; Store new pulse length
	ajmp	pca_int_set_timeout			; Set new timeout and exit

pca_int_second_meas_pwm_freq:
	; Prepare for next interrupt
	Rcp_Int_First 					; Set first edge trig
	clr	Flags1.RCP_EDGE_NO			; Set first edge flag
	; Check if pwm frequency shall be measured
	jb	Flags0.RCP_MEAS_PWM_FREQ, ($+5)	; Is measure RCP pwm frequency flag set?
	ajmp	pca_int_fall				; No - skip measurements

	; Set second edge trig only during pwm frequency measurement
	Rcp_Int_Second 				; Set second edge trig
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	setb	Flags1.RCP_EDGE_NO			; Set second edge flag
	; Store edge data to RAM
	mov	Rcp_Edge_L, Temp1
	mov	Rcp_Edge_H, Temp2
	; Calculate pwm frequency
	clr	C
	mov	A, Temp1
	subb	A, Rcp_PrePrev_Edge_L	
	mov	Temp1, A
	mov	A, Temp2
	subb	A, Rcp_PrePrev_Edge_H
	mov	Temp2, A
	clr	A
	mov	Temp4, A
	; Check if pwm frequency is 8kHz
	clr	C
	mov	A, Temp1
	subb	A, #low(360)				; If below 180us, 8kHz pwm is assumed
	mov	A, Temp2
	subb	A, #high(360)
	jnc	pca_int_check_4kHz

	clr	A
	setb	ACC.RCP_PWM_FREQ_8KHZ
	mov	Temp4, A
	ajmp	pca_int_restore_edge

pca_int_check_4kHz:
	; Check if pwm frequency is 4kHz
	clr	C
	mov	A, Temp1
	subb	A, #low(720)				; If below 360us, 4kHz pwm is assumed
	mov	A, Temp2
	subb	A, #high(720)
	jnc	pca_int_check_2kHz

	clr	A
	setb	ACC.RCP_PWM_FREQ_4KHZ
	mov	Temp4, A
	ajmp	pca_int_restore_edge

pca_int_check_2kHz:
	; Check if pwm frequency is 2kHz
	clr	C
	mov	A, Temp1
	subb	A, #low(1440)				; If below 720us, 2kHz pwm is assumed
	mov	A, Temp2
	subb	A, #high(1440)
	jnc	pca_int_check_1kHz

	clr	A
	setb	ACC.RCP_PWM_FREQ_2KHZ
	mov	Temp4, A
	ajmp	pca_int_restore_edge

pca_int_check_1kHz:
	; Check if pwm frequency is 1kHz
	clr	C
	mov	A, Temp1
	subb	A, #low(2200)				; If below 1100us, 1kHz pwm is assumed
	mov	A, Temp2
	subb	A, #high(2200)
	jnc	pca_int_restore_edge

	clr	A
	setb	ACC.RCP_PWM_FREQ_1KHZ
	mov	Temp4, A

pca_int_restore_edge:
	; Calculate difference between this period and previous period
	clr	C
	mov	A, Temp1
	subb	A, Rcp_Prev_Period_L
	mov	Temp5, A
	mov	A, Temp2
	subb	A, Rcp_Prev_Period_H
	mov	Temp6, A
	; Make positive
	jnb	ACC.7, pca_int_check_diff
	mov	A, Temp5
	cpl	A
	add	A, #1
	mov	Temp5, A
	mov	A, Temp6
	cpl	A
	mov	Temp6, A

pca_int_check_diff:
	; Check difference
	mov	Rcp_Period_Diff_Accepted, #0		; Set not accepted as default
	jnz	pca_int_store_data				; Check if high byte is zero

	clr	C
	mov	A, Temp5
	subb	A, #10						; Check difference
	jnc	pca_int_store_data

	mov	Rcp_Period_Diff_Accepted, #1		; Set accepted

pca_int_store_data:
	; Store previous period
	mov	Rcp_Prev_Period_L, Temp1
	mov	Rcp_Prev_Period_H, Temp2
	; Restore edge data from RAM
	mov	Temp1, Rcp_Edge_L
	mov	Temp2, Rcp_Edge_H
	; Store pre previous edge
	mov	Rcp_PrePrev_Edge_L, Temp1
	mov	Rcp_PrePrev_Edge_H, Temp2

pca_int_fall:
	; RC pulse edge was second, calculate new pulse length
	clr	C
	mov	A, Temp1
	subb	A, Rcp_Prev_Edge_L	
	mov	Temp1, A
	mov	A, Temp2
	subb	A, Rcp_Prev_Edge_H
	mov	Temp2, A
	jnb	Flags2.RCP_PWM_FREQ_8KHZ, ($+5)	; Is RC input pwm frequency 8kHz?
	ajmp	pca_int_pwm_divide_done			; Yes - branch forward

	jnb	Flags2.RCP_PWM_FREQ_4KHZ, ($+5)	; Is RC input pwm frequency 4kHz?
	ajmp	pca_int_pwm_divide				; Yes - branch forward

	mov	A, Temp2						; No - 2kHz. Divide by 2 again
	clr	C
	rrc	A
	mov	Temp2, A
	mov	A, Temp1					
	rrc	A
	mov	Temp1, A

	jnb	Flags2.RCP_PWM_FREQ_2KHZ, ($+5)	; Is RC input pwm frequency 2kHz?
	ajmp	pca_int_pwm_divide				; Yes - branch forward

	mov	A, Temp2						; No - 1kHz. Divide by 2 again
	clr	C
	rrc	A
	mov	Temp2, A
	mov	A, Temp1					
	rrc	A
	mov	Temp1, A

	jnb	Flags2.RCP_PWM_FREQ_1KHZ, ($+5)	; Is RC input pwm frequency 1kHz?
	ajmp	pca_int_pwm_divide				; Yes - branch forward

	mov	A, Temp1						; No - PPM. Subtract 1150us and multiply by 1.5
	clr	C
	subb	A, #low(575)
	mov	Temp1, A
	mov	A, Temp2					
	subb	A, #high(575)
	mov	Temp2, A
	jnc	pca_int_ppm_neg_checked			; Is result negative?

	mov	Temp1, #RCP_MIN				; Yes - set to minimum
	mov	Temp2, #0
	ajmp	pca_int_limited

pca_int_ppm_neg_checked:
	mov	A, Temp2						; Divide by 2 and move to Temp5/6
	clr	C
	rrc	A
	mov	Temp6, A
	mov	A, Temp1					
	rrc	A
	mov	Temp5, A
	mov	A, Temp1						; Add a half
	add	A, Temp5
	mov	Temp1, A
	mov	A, Temp2					
	addc	A, Temp6
	mov	Temp2, A

pca_int_pwm_divide:
	mov	A, Temp2						; Divide by 2
	clr	C
	rrc	A
	mov	Temp2, A
	mov	A, Temp1					
	rrc	A
	mov	Temp1, A

pca_int_pwm_divide_done:
	; Check that RC pulse is within legal range
	clr	C
	mov	A, Temp1
	subb	A, #RCP_MAX				
	mov	A, Temp2
	subb	A, #0
	jc	pca_int_limited

	mov	Temp1, #RCP_MAX

pca_int_limited:
	mov	Temp2, New_Rcp 			; Load pulse length to be used as previous
	; RC pulse value accepted
	mov	New_Rcp, Temp1				; Store new pulse length
	jb	Flags0.RCP_MEAS_PWM_FREQ, ($+5)	; Is measure RCP pwm frequency flag set?
	ajmp	pca_int_set_timeout			; No - skip measurements

	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	cpl	A
	anl	A, Flags2					; Clear all pwm frequency flags
	orl	A, Temp4					; Store pwm frequency value in flags
	mov	Flags2, A

pca_int_set_timeout:
	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT	; Set timeout count to start value
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2					; Check pwm frequency flags
	jnz	pca_int_ppm_timeout_set		; If a flag is set - branch

	mov	Rcp_Timeout_Cnt, #3			; No flag set means PPM. Set timeout count

pca_int_ppm_timeout_set:
	setb	Flags1.RCP_UPDATED		 	; Set updated flag
	jnb	Flags0.RCP_MEAS_PWM_FREQ, ($+5)	; Is measure RCP pwm frequency flag set?
	ajmp pca_int_exit				; Yes - exit

	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2					; Check pwm frequency flags
	jz	pca_int_exit				; If no flag is set (PPM) - branch

	Rcp_Int_Disable 				; Disable RC pulse interrupt

pca_int_exit:	; Exit interrupt routine	
	mov	Rcp_Skip_Cnt, #RCP_SKIP_RATE	; Load number of skips
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2					; Check pwm frequency flags
	jnz	($+5)					; If a flag is set (PWM) - branch

	mov	Rcp_Skip_Cnt, #10			; Load number of skips

	pop	ACC			; Restore preserved registers
	pop	PSW
	clr	PSW.3		; Select register bank 0 for main program routines	
	setb	EA			; Enable all interrupts
	reti




;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait xms ~(x*4*250)  (Different entry points)	
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait1ms:	
	mov	Temp2, #1
	ajmp	waitxms_o

wait3ms:	
	mov	Temp2, #3
	ajmp	waitxms_o

wait10ms:	
	mov	Temp2, #10
	ajmp	waitxms_o

wait30ms:	
	mov	Temp2, #30
	ajmp	waitxms_o

wait100ms:	
	mov	Temp2, #100
	ajmp	waitxms_o

wait200ms:	
	mov	Temp2, #200
	ajmp	waitxms_o

waitxms_o:	; Outer loop
	mov	Temp1, #23
waitxms_m:	; Middle loop
	clr	A
	djnz	ACC, $	; Inner loop (42.7us - 1024 cycles)
	djnz	Temp1, waitxms_m
	djnz	Temp2, waitxms_o
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Beeper routines (4 different entry points) 
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
beep_f1:	; Entry point 1, load beeper frequency 1 settings
	mov	Temp3, #24	; Off wait loop length
	mov	Temp4, #120	; Number of beep pulses
	ajmp	beep

beep_f2:	; Entry point 2, load beeper frequency 2 settings
	mov	Temp3, #21
	mov	Temp4, #140
	ajmp	beep

beep_f3:	; Entry point 3, load beeper frequency 3 settings
	mov	Temp3, #18
	mov	Temp4, #180
	ajmp	beep

beep_f4:	; Entry point 4, load beeper frequency 4 settings
	mov	Temp3, #15
	mov	Temp4, #200
	ajmp	beep

beep:	; Beep loop start
	mov	Temp2, #2		; Must be an even number (or direction will change)
beep_onoff:
	cpl	Flags2.PGM_DIR_REV	; Toggle between using A fet and C fet
	clr	A
	BpFET_on			; BpFET on
	djnz	ACC, $		; Allow some time after pfet is turned on
	; Turn on nfet
	AnFET_on			; AnFET on
IF MODE == 0	; Main
	mov	A, #120		; 20탎 on
ENDIF
IF MODE == 1	; Tail
	mov	A, #250		; 42탎 on
ENDIF
IF MODE == 2	; Multi
	mov	A, #60		; 10탎 on
ENDIF
	djnz	ACC, $		
	; Turn off nfet
	AnFET_off			; AnFET off
	mov	A, #150		; 25탎 off
	djnz	ACC, $		
	djnz	Temp2, beep_onoff
	; Copy variable
	mov	A, Temp3
	mov	Temp1, A	
beep_off:		; Fets off loop
	djnz	ACC, $
	djnz	Temp1,	beep_off
	djnz	Temp4,	beep
	BpFET_off			; BpFET off
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Calculate governor routines
;
; No assumptions
;
; Governs headspeed based upon the Comm_Period4x variable and pwm
; The governor task is split into several routines in order to distribute processing time
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
; First governor routine - calculate governor target
calc_governor_target:
	mov	A, Pgm_Gov_Mode			; Governor mode?
	cjne	A, #4, governor_speed_check	; Yes
	ajmp	calc_governor_target_exit	; No

governor_speed_check:
	; Skip speed check if governor is alrady active
	mov	A, Gov_Active
	jnz	governor_target_calc

	; Check speed (do not run governor for low speeds)
	mov	Temp1, #05h				; Default high range activation limit value (~62500 eRPM)
	clr	C
	mov	A, Pgm_Gov_Range
	subb	A, #2
	jnz	($+4)

	mov	Temp1, #12h				; Low range activation limit value (~17400 eRPM)

	clr	C
	mov	A, Comm_Period4x_L
	subb	A, #00h
	mov	A, Comm_Period4x_H
	subb	A, Temp1
	jc	governor_activate			; If speed above min limit  - run governor

	mov	Current_Pwm, Requested_Pwm	; Set current pwm to requested
	clr	A
	mov	Gov_Target_L, A			; Set target to zero
	mov	Gov_Target_H, A
	mov	Gov_Integral_L, A			; Set integral to zero
	mov	Gov_Integral_H, A
	mov	Gov_Integral_X, A
	mov	Gov_Active, A
	ajmp	calc_governor_target_exit

governor_activate:
	mov	Gov_Active, #1
governor_target_calc:
	; Governor calculations
	clr	C
	mov	A, Pgm_Gov_Range		; Check high or low range
	subb	A, #2
	jz	calc_governor_target_low

	mov	A, Governor_Req_Pwm		; Load governor requested pwm
	cpl	A					; Calculate 255-pwm (invert pwm) 
	; Calculate comm period target (1 + 2*((255-Requested_Pwm)/256) - 0.25)
	rlc	A					; Msb to carry
	rlc	A					; To bit0
	mov	Temp2, A				; Now 1 lsb is valid for H
	rrc	A					
	mov	Temp1, A				; Now 7 msbs are valid for L
	mov	A, Temp2
	anl	A, #01h				; Calculate H byte
	inc	A					; Add 1
	mov	Temp2, A
	mov	A, Temp1
	anl	A, #0FEh				; Calculate L byte
	clr	C
	subb	A, #40h				; Subtract 0.25
	mov	Temp1, A
	mov	A, Temp2
	subb	A, #0
	mov	Temp2, A
	jmp	calc_governor_store_target

calc_governor_target_low:
	mov	A, Governor_Req_Pwm		; Load governor requested pwm
	cpl	A					; Calculate 255-pwm (invert pwm) 
	; Calculate comm period target (2 + 8*((255-Requested_Pwm)/256) - 0.25)
	rlc	A					; Msb to carry
	rlc	A					; To bit0
	rlc	A					; To bit1
	rlc	A					; To bit2
	mov	Temp2, A				; Now 3 lsbs are valid for H
	rrc	A					
	mov	Temp1, A				; Now 4 msbs are valid for L
	mov	A, Temp2
	anl	A, #07h				; Calculate H byte
	inc	A					; Add 1
	inc	A					; Add 1 more
	mov	Temp2, A
	mov	A, Temp1
	anl	A, #0F8h				; Calculate L byte
	clr	C
	subb	A, #40h				; Subtract 0.25
	mov	Temp1, A
	mov	A, Temp2
	subb	A, #0
	mov	Temp2, A

calc_governor_store_target:
	; Store governor target
	mov	Gov_Target_L, Temp1
	mov	Gov_Target_H, Temp2
calc_governor_target_exit:
	ret						


; Second governor routine - calculate governor proportional error
calc_governor_prop_error:
	; Exit if governor is inactive
	mov	A, Gov_Active
	jz	calc_governor_prop_error_exit

	; Load comm period and divide by 2
	clr	C
	mov	A, Comm_Period4x_H
	rrc	A
	mov	Temp2, A
	mov	A, Comm_Period4x_L
	rrc	A
	mov	Temp1, A
	; Calculate error
	clr	C
	mov	A, Gov_Target_L
	subb	A, Temp1
	mov	Temp1, A
	mov	A, Gov_Target_H
	subb	A, Temp2
	mov	Temp2, A
	; Check error and limit (to low byte)
	jnb	ACC.7, governor_check_prop_limit_pos	; Check sign bit

	clr	C
	mov	A, Temp1
	subb	A, #80h					; Is error too negative?
	mov	A, Temp2
	subb	A, #0FFh
	jc	governor_limit_prop_error_neg	; Yes - limit
	ajmp	governor_store_prop_error

governor_check_prop_limit_pos:
	clr	C
	mov	A, Temp1
	subb	A, #7Fh					; Is error too positive?
	mov	A, Temp2
	subb	A, #00h
	jnc	governor_limit_prop_error_pos	; Yes - limit
	ajmp	governor_store_prop_error

governor_limit_prop_error_pos:
	mov	Temp1, #7Fh				; Limit to max positive (2's complement)
	mov	Temp2, #00h
	ajmp	governor_store_prop_error

governor_limit_prop_error_neg:
	mov	Temp1, #80h				; Limit to max negative (2's complement)
	mov	Temp2, #0FFh

governor_store_prop_error:
	; Store proportional
	mov	Gov_Proportional_L, Temp1
	mov	Gov_Proportional_H, Temp2
calc_governor_prop_error_exit:
	ret						


; Third governor routine - calculate governor integral error
calc_governor_int_error:
	; Exit if governor is inactive
	mov	A, Gov_Active
	jz	calc_governor_int_error_exit

	; Add proportional to integral
	mov	A, Gov_Integral_L
	add	A, Gov_Proportional_L
	mov	Temp1, A
	mov	A, Gov_Integral_H
	addc	A, Gov_Proportional_H
	mov	Temp2, A
	mov	A, Gov_Integral_X
	addc	A, Gov_Proportional_H
	mov	Temp3, A
	; Check integral and limit
	jnb	ACC.7, governor_check_int_limit_pos	; Check sign bit

	clr	C
	mov	A, Temp3
	subb	A, #0F0h					; Is error too negative?
	jc	governor_limit_int_error_neg	; Yes - limit
	ajmp	governor_check_pwm

governor_check_int_limit_pos:
	clr	C
	mov	A, Temp3
	subb	A, #0Fh					; Is error too positive?
	jnc	governor_limit_int_error_pos	; Yes - limit
	ajmp	governor_check_pwm

governor_limit_int_error_pos:
	mov	Temp1, #0FFh				; Limit to max positive (2's complement)
	mov	Temp2, #0FFh
	mov	Temp3, #0Fh
	ajmp	governor_check_pwm

governor_limit_int_error_neg:
	mov	Temp1, #00h				; Limit to max negative (2's complement)
	mov	Temp2, #00h
	mov	Temp3, #0F0h

governor_check_pwm:
	; Check current pwm
	clr	C
	mov	A, Current_Pwm
	subb	A, Pwm_Limit				; Is current pwm above pwm limit?
	jnc	governor_int_max_pwm		; Yes - branch

	clr	C
	mov	A, Current_Pwm
	subb	A, #1					; Is current below pwm min?
	jc	governor_int_min_pwm		; Yes - branch
	ajmp	governor_store_int_error		; No - store integral error

governor_int_max_pwm:
	mov	A, Gov_Proportional_L
	jb	ACC.7, calc_governor_int_error_exit	; Is proportional error negative - branch (high byte is always zero)
	ajmp	governor_store_int_error		; Positive - store integral error

governor_int_min_pwm:
	mov	A, Gov_Proportional_L
	jnb	ACC.7, calc_governor_int_error_exit	; Is proportional error positive - branch (high byte is always zero)

governor_store_int_error:
	; Store integral
	mov	Gov_Integral_L, Temp1
	mov	Gov_Integral_H, Temp2
	mov	Gov_Integral_X, Temp3
calc_governor_int_error_exit:
	ret						


; Fourth governor routine - calculate governor proportional correction
calc_governor_prop_correction:
	; Exit if governor is inactive
	mov	A, Gov_Active
	jnz	calc_governor_prop_corr
	jmp	calc_governor_prop_corr_exit

calc_governor_prop_corr:
	; Load proportional
	mov	Bit_Access, Gov_Proportional_L	; Only low byte required (high byte is always zero)
	; Apply proportional gain
	clr	A
	jnb	Bit_Access.7, ($+4)			; Sign extend high byte
	cpl	A
	mov	Temp2, A
	clr	C
	mov	A, Gov_Proportional_L		; Nominal multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A
	mov	A, Pgm_Gov_P_Gain			; Load proportional gain
	jb	ACC.0, ($+5)				; Is lsb 1?
	ajmp	calc_governor_prop_corr_15	; No - go to multiply by 1.5	

	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #7					; Is proportional gain 1?
	jnz	calc_governor_prop_corr_not1	; No - branch
	ajmp	governor_limit_prop_corr

calc_governor_prop_corr_not1:
	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #9					; Is proportional gain 2 or higher?
	jc	calc_governor_prop_corr_lt1e	; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #11					; Is proportional gain 4 or higher?
	jnc	($+5)					; Yes - proceed
	ljmp	governor_limit_prop_corr		; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #13					; Is proportional gain 8 or higher?
	jnc	($+5)					; Yes - proceed
	ljmp	governor_limit_prop_corr		; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	ajmp	governor_limit_prop_corr

calc_governor_prop_corr_lt1e:
	mov	A, Temp2					; Divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #5					; Is proportional gain 0.5?
	jz	governor_limit_prop_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #3					; Is proportional gain 0.25?
	jz	governor_limit_prop_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	ajmp	governor_limit_prop_corr

calc_governor_prop_corr_15:
	mov	A, Temp2					; Load a copy
	mov	Temp4, A
	mov	A, Temp1
	mov	Temp3, A
	mov	A, Temp4					; Divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp4, A
	mov	A, Temp3
	rrc	A
	mov	Temp3, A
	mov	A, Temp1
	add	A, Temp3					; Add a half
	mov	Temp1, A
	mov	A, Temp2
	addc	A, Temp4					
	mov	Temp2, A

	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #8					; Is proportional gain less than 1.5?
	jc	calc_governor_prop_corr_lt1o	; Yes - branch

	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #10					; Is proportional gain 3 or higher?
	jc	governor_limit_prop_corr		; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #12					; Is proportional gain 6 or higher?
	jc	governor_limit_prop_corr		; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	ajmp	governor_limit_prop_corr

calc_governor_prop_corr_lt1o:
	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #6					; Is proportional gain 0.75?
	jz	governor_limit_prop_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #4					; Is proportional gain 0.375?
	jz	governor_limit_prop_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A

governor_limit_prop_corr:
	; Check error and limit (to low byte)
	mov	A, Temp2
	jnb	ACC.7, governor_check_prop_corr_limit_pos	; Check sign bit

	clr	C
	mov	A, Temp1
	subb	A, #80h					; Is error too negative?
	mov	A, Temp2
	subb	A, #0FFh
	jc	governor_limit_prop_corr_neg	; Yes - limit
	ajmp	governor_apply_prop_corr

governor_check_prop_corr_limit_pos:
	clr	C
	mov	A, Temp1
	subb	A, #7Fh					; Is error too positive?
	mov	A, Temp2
	subb	A, #00h
	jnc	governor_limit_prop_corr_pos	; Yes - limit
	ajmp	governor_apply_prop_corr

governor_limit_prop_corr_pos:
	mov	Temp1, #7Fh				; Limit to max positive (2's complement)
	mov	Temp2, #00h
	ajmp	governor_apply_prop_corr

governor_limit_prop_corr_neg:
	mov	Temp1, #80h				; Limit to max negative (2's complement)
	mov	Temp2, #0FFh

governor_apply_prop_corr:
	; Test proportional sign
	mov	A, Temp1
	jb	ACC.7, governor_corr_neg_prop	; If proportional negative - go to correct negative

	; Subtract positive proportional
	clr	C
	mov	A, Governor_Req_Pwm
	subb	A, Temp1
	mov	Temp1, A
	; Check result
	jc	governor_corr_prop_min_pwm	; Is result negative?

	clr	C
	mov	A, Temp1					; Is result below pwm min?
	subb	A, #1
	jc	governor_corr_prop_min_pwm	; Yes
	ajmp	governor_store_prop_corr		; No - store proportional correction

governor_corr_prop_min_pwm:
	mov	Temp1, #1					; Load minimum pwm
	ajmp	governor_store_prop_corr

governor_corr_neg_prop:
	; Add negative proportional
	mov	A, Temp1
	cpl	A
	add	A, #1
	add	A, Governor_Req_Pwm
	mov	Temp1, A
	; Check result
	jc	governor_corr_prop_max_pwm	; Is result above max?
	ajmp	governor_store_prop_corr		; No - store proportional correction

governor_corr_prop_max_pwm:
	mov	Temp1, #255				; Load maximum pwm
governor_store_prop_corr:
	; Store proportional pwm
	mov	Gov_Prop_Pwm, Temp1
calc_governor_prop_corr_exit:
	ret


; Fifth governor routine - calculate governor integral correction
calc_governor_int_correction:
	; Exit if governor is inactive
	mov	A, Gov_Active
	jnz	calc_governor_int_corr
	jmp	calc_governor_int_corr_exit

calc_governor_int_corr:
	; Load integral
	mov	Temp1, Gov_Integral_H
	mov	Temp2, Gov_Integral_X
	; Apply integrator gain
	mov	A, Pgm_Gov_I_Gain			; Load integral gain
	jb	ACC.0, ($+6)				; Is lsb 1?
	ljmp	calc_governor_int_corr_15	; No - go to multiply by 1.5	

	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #7					; Is integral gain 1?
	jnz	calc_governor_int_corr_not1	; No - branch
	jmp	governor_limit_int_corr

calc_governor_int_corr_not1:
	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #9					; Is integral gain 2 or higher?
	jc	calc_governor_int_corr_lt1e	; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #11					; Is integral gain 4 or higher?
	jnc	($+5)					; Yes - proceed
	ljmp	governor_limit_int_corr		; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #13					; Is integral gain 8 or higher?
	jnc	($+5)					; Yes - proceed
	ljmp	governor_limit_int_corr		; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	jmp	governor_limit_int_corr

calc_governor_int_corr_lt1e:
	mov	A, Temp2					; Divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #5					; Is integral gain 0.5?
	jz	governor_limit_int_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #3					; Is integral gain 0.25?
	jz	governor_limit_int_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	jmp	governor_limit_int_corr

calc_governor_int_corr_15:
	mov	A, Temp2					; Load a copy
	mov	Temp4, A
	mov	A, Temp1
	mov	Temp3, A
	mov	A, Temp4					; Divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp4, A
	mov	A, Temp3
	rrc	A
	mov	Temp3, A
	mov	A, Temp1
	add	A, Temp3					; Add a half
	mov	Temp1, A
	mov	A, Temp2
	addc	A, Temp4					
	mov	Temp2, A

	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #8					; Is integral gain less than 1.5?
	jc	calc_governor_int_corr_lt1o	; Yes - branch

	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #10					; Is integral gain 3 or higher?
	jc	governor_limit_int_corr		; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #12					; Is integral gain 6 or higher?
	jc	governor_limit_int_corr		; No - branch

	clr	C
	mov	A, Temp1					; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A

	jmp	governor_limit_int_corr

calc_governor_int_corr_lt1o:
	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	mov	A, Pgm_Gov_I_Gain
	clr	C
	subb	A, #6					; Is integral gain 0.75?
	jz	governor_limit_int_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #4					; Is integral gain 0.375?
	jz	governor_limit_int_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A

governor_limit_int_corr:
	; Check integral and limit
	mov	A, Temp2
	jnb	ACC.7, governor_check_int_corr_limit_pos	; Check sign bit

	clr	C
	mov	A, Temp1
	subb	A, #00h					; Is integral too negative?
	mov	A, Temp2
	subb	A, #0FFh
	jc	governor_limit_int_corr_neg	; Yes - limit
	jmp	governor_apply_int_corr

governor_check_int_corr_limit_pos:
	clr	C
	mov	A, Temp1
	subb	A, #0FFh					; Is integral too positive?
	mov	A, Temp2
	subb	A, #00h
	jnc	governor_limit_int_corr_pos	; Yes - limit
	jmp	governor_apply_int_corr

governor_limit_int_corr_pos:
	mov	Temp1, #0FFh				; Limit to max positive (2's complement)
	mov	Temp2, #00h
	jmp	governor_apply_int_corr

governor_limit_int_corr_neg:
	mov	Temp1, #00h				; Limit to max negative (2's complement)
	mov	Temp2, #0FFh

governor_apply_int_corr:
	; Test integral sign
	mov	A, Temp2
	jb	ACC.7, governor_corr_neg_int	; If integral negative - go to correct negative

	; Subtract positive integral
	clr	C
	mov	A, Gov_Prop_Pwm
	subb	A, Temp1
	mov	Temp1, A
	; Check result
	jc	governor_corr_int_min_pwm	; Is result negative?

	clr	C
	mov	A, Temp1					; Is result below pwm min?
	subb	A, #1
	jc	governor_corr_int_min_pwm	; Yes
	jmp	governor_store_int_corr		; No - store correction

governor_corr_int_min_pwm:
	mov	Temp1, #1					; Load minimum pwm
	jmp	governor_store_int_corr

governor_corr_neg_int:
	; Add negative integral
	mov	A, Temp1
	cpl	A
	add	A, #1
	add	A, Gov_Prop_Pwm
	mov	Temp1, A
	mov	A, Temp2
	addc	A, #0
	; Check result
	jc	governor_corr_int_max_pwm	; Is result above max?
	jmp	governor_store_int_corr		; No - store correction

governor_corr_int_max_pwm:
	mov	Temp1, #255				; Load maximum pwm
governor_store_int_corr:
	; Store current pwm
	mov	Current_Pwm, Temp1
calc_governor_int_corr_exit:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Measure lipo cells
;
; No assumptions
;
; Measure voltage and calculate lipo cells
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
measure_lipo_cells:
IF MODE == 1	; Tail
	; If tail, then exit if voltage compensation is not enabled
	clr	C
	mov	A, Pgm_Volt_Comp
	subb	A, #2
	jnc	measure_lipo_start
	jmp	measure_lipo_exit
ENDIF
measure_lipo_start:
	; Set commutation to BpFET on
	call	comm5comm6			
	; Start adc
	Start_Adc 
	; Wait for ADC conversion to complete
	Get_Adc_Status 
	jb	AD0BUSY, measure_lipo_cells
	; Read ADC result
	Read_Adc_Result
	; Stop ADC
	Stop_Adc
	; Switch power off
	call	switch_power_off		
	; Set limit step
	mov	Lipo_Adc_Limit_L, #ADC_LIMIT_L
	mov	Lipo_Adc_Limit_H, #ADC_LIMIT_H
	clr	C
	mov	A, #ADC_LIMIT_L		; Divide 3.0V value by 2
	rrc	A
	mov	Temp5, A
	mov	A, #ADC_LIMIT_H
	rrc	A
	mov	Temp6, A
	clr	C
	mov	A, #ADC_LIMIT_L		; Calculate 1.5*3.0V=4.5V value
	addc	A, Temp5
	mov	Temp5, A
	mov	A, #ADC_LIMIT_H		
	addc	A, Temp6
	mov	Temp6, A
	; Check voltage against 2S lower limit
	mov	A, Temp5				; Copy step
	mov	Temp3, A
	mov	A, Temp6	
	mov	Temp4, A
	clr	C
	mov	A, Temp1
	subb	A, Temp3				; Voltage above limit?
	mov	A, Temp2
	subb A, Temp4
	jc	measure_lipo_adjust		; No - branch

	; Set 2S voltage limit
	mov	A, Lipo_Adc_Limit_L		
	add	A, #ADC_LIMIT_L
	mov	Lipo_Adc_Limit_L, A
	mov	A, Lipo_Adc_Limit_H		
	addc	A, #ADC_LIMIT_H
	mov	Lipo_Adc_Limit_H, A
	; Set 3S lower limit
	mov	A, Temp3
	add	A, Temp5				; Add step
	mov	Temp3, A
	mov	A, Temp4
	addc	A, Temp6
	mov	Temp4, A
	; Check voltage against 3S lower limit
	clr	C
	mov	A, Temp1
	subb	A, Temp3				; Voltage above limit?
	mov	A, Temp2
	subb A, Temp4
	jc	measure_lipo_adjust		; No - branch

	; Set 3S voltage limit
	mov	A, Lipo_Adc_Limit_L		
	add	A, #ADC_LIMIT_L
	mov	Lipo_Adc_Limit_L, A
	mov	A, Lipo_Adc_Limit_H		
	addc	A, #ADC_LIMIT_H
	mov	Lipo_Adc_Limit_H, A
	; Set 4S lower limit
	mov	A, Temp3
	add	A, Temp5				; Add step
	mov	Temp3, A
	mov	A, Temp4
	addc	A, Temp6
	mov	Temp4, A
	; Check voltage against 4S lower limit
	clr	C
	mov	A, Temp1
	subb	A, Temp3				; Voltage above limit?
	mov	A, Temp2
	subb A, Temp4
	jc	measure_lipo_adjust		; No - branch

	; Set 4S voltage limit
	mov	A, Lipo_Adc_Limit_L		
	add	A, #ADC_LIMIT_L
	mov	Lipo_Adc_Limit_L, A
	mov	A, Lipo_Adc_Limit_H		
	addc	A, #ADC_LIMIT_H
	mov	Lipo_Adc_Limit_H, A

measure_lipo_adjust:
	mov	Temp7, Lipo_Adc_Limit_L
	mov	Temp8, Lipo_Adc_Limit_H
	; Calculate 3.125%
	clr	C
	mov	A, Lipo_Adc_Limit_H
	rrc	A
	mov	Temp2, A
	mov	A, Lipo_Adc_Limit_L	
	rrc	A
	mov	Temp1, A			; After this 50%
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1	
	rrc	A
	mov	Temp1, A			; After this 25%
	mov	A, Lipo_Adc_Limit_L			; Set adc reference
	add	A, Temp1
	mov	Lipo_Adc_Reference_L, A
	mov	A, Lipo_Adc_Limit_H
	addc	A, Temp2
	mov	Lipo_Adc_Reference_H, A
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	Temp6, A	; Store 12.5%
	mov	A, Temp1	
	rrc	A
	mov	Temp1, A			; After this 12.5%
	mov	Temp5, A	; Store 12.5%
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	Temp4, A	; Store 6.25%
	mov	A, Temp1	
	rrc	A
	mov	Temp1, A			; After this 6.25%
	mov	Temp3, A	; Store 6.25%
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1	
	rrc	A
	mov	Temp1, A			; After this 3.125%
	clr	C
	mov	A, Pgm_Low_Voltage_Lim
	subb	A, #1			; Is limit 3.0V?
	jz	measure_lipo_update	; Yes - branch

	clr	C
	mov	A, Pgm_Low_Voltage_Lim
	subb	A, #5			; Is limit 3.4V?
	jnz	measure_lipo_625	; No - branch

	mov	A, Temp7			; Add 12.5%
	add	A, Temp5
	mov	Temp7, A
	mov	A, Temp8
	addc	A, Temp6
	mov	Temp8, A
	ajmp measure_lipo_update

measure_lipo_625:
	clr	C
	mov	A, Pgm_Low_Voltage_Lim
	subb	A, #3			; Is limit 3.2V or higher?
	jc	measure_lipo_3125	; No - branch

	mov	A, Temp7			; Add 6.25%
	add	A, Temp3
	mov	Temp7, A
	mov	A, Temp8
	addc	A, Temp4
	mov	Temp8, A

measure_lipo_3125:
	clr	C
	mov	A, Pgm_Low_Voltage_Lim
	subb	A, #1			; Is limit 3.0V?
	jz	measure_lipo_update	; Yes - branch

	clr	C
	mov	A, Pgm_Low_Voltage_Lim
	subb	A, #3			; Is limit 3.2V?
	jz	measure_lipo_update	; Yes - branch

	mov	A, Temp7			; Add 3.125%
	add	A, Temp1
	mov	Temp7, A
	mov	A, Temp8
	addc	A, Temp2
	mov	Temp8, A

measure_lipo_update:
	mov	Lipo_Adc_Limit_L, Temp7
	mov	Lipo_Adc_Limit_H, Temp8

measure_lipo_exit:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Start ADC conversion
;
; No assumptions
;
; Start conversion used for measuring power supply voltage
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
start_adc_conversion:
	; Start adc
	Start_Adc 
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Check temperature, power supply voltage, compensate current pwm and limit power
;
; No assumptions
;
; Used to compensate main motor power for battery voltage and
; to limit main motor power in order to maintain the required voltage
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
check_temp_voltage_compensate_and_limit_power:
	; Wait for ADC conversion to complete
	Get_Adc_Status 
	jb	AD0BUSY, check_temp_voltage_compensate_and_limit_power
	; Read ADC result
	Read_Adc_Result
	; Stop ADC
	Stop_Adc

	inc	Adc_Conversion_Cnt			; Increment conversion counter
	clr	C
	mov	A, Adc_Conversion_Cnt		; Is conversion count equal to temp rate?
	subb	A, #TEMP_CHECK_RATE
	jc	check_voltage_comp_start		; No - check voltage

	mov	Adc_Conversion_Cnt, #0		; Yes - temperature check. Reset counter
	clr	C
	mov	A, Temp1					; Is temperature below first limit
	subb	A, #TEMP_LIMIT_L
	mov	Temp1, A
	mov	A, Temp2
	subb	A, #TEMP_LIMIT_H
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #192			; No - limit pwm

	clr	C
	mov	A, Temp1					; Is temperature below second limit
	subb	A, #TEMP_LIMIT_STEP
	mov	Temp1, A
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #128			; No - limit pwm

	clr	C
	mov	A, Temp1					; Is temperature below third limit
	subb	A, #TEMP_LIMIT_STEP
	mov	Temp1, A
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #64				; No - limit pwm

	clr	C
	mov	A, Temp1					; Is temperature below final limit
	subb	A, #TEMP_LIMIT_STEP
	mov	Temp1, A
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #0				; No - limit pwm

temp_check_exit:
	Set_Adc_Ip_Volt				; Select adc input for next conversion
	ret

check_voltage_comp_start:
	; Skip compensation part if voltage compensation is not enabled
	clr	C
	mov	A, Pgm_Volt_Comp
	subb	A, #2
	jc	check_voltage_comp_skip
	; Check range of adc reading and adc reference
	mov	A, Temp2
	mov	Temp4, A
	mov	A, Temp1
	mov	Temp3, A
	mov	Temp6, Lipo_Adc_Reference_H
	mov	Temp5, Lipo_Adc_Reference_L
	mov	A, Temp4
	orl	A, Temp6
	mov	Bit_Access, A
	jnb	Bit_Access.1, check_voltage_input_shifted_once

	clr	C
	mov	A, Temp4
	rrc	A
	mov	Temp4, A
	mov	A, Temp3	
	rrc	A
	mov	Temp3, A			; After this adc reading is shifted once
	clr	C
	mov	A, Temp6
	rrc	A
	mov	Temp6, A
	mov	A, Temp5	
	rrc	A
	mov	Temp5, A			; After this adc reference is shifted once

check_voltage_input_shifted_once:
	mov	A, Temp4
	orl	A, Temp6
	mov	Bit_Access, A
	jnb	Bit_Access.0, check_voltage_input_shifted_twice

	clr	C
	mov	A, Temp4
	rrc	A
	mov	Temp4, A
	mov	A, Temp3	
	rrc	A
	mov	Temp3, A			; After this shifted twice and guaranteed to be within 8bit
	clr	C
	mov	A, Temp6
	rrc	A
	mov	Temp6, A
	mov	A, Temp5	
	rrc	A
	mov	Temp5, A			; After this adc reference is shifted once

check_voltage_input_shifted_twice:
	; Multiply adc value with voltage compensation factor
	mov	A, Temp3
	mov	B, Voltage_Comp_Factor
	mul	AB			
	; Compare result with adc reference
	mov	A, B					; Shift result left once, to match ADC scale
	rlc	A				
	clr	C
	subb	A, Temp5				; Compare with reference
	mov	C, ACC.7				; Preserve sign of 2's complement number
	rrc	A					; Divide error by 2
	mov	Temp3, A				; Store error
	mov	A, Voltage_Comp_Factor
	subb	A, Temp3				; Subract error
	mov	Temp3, A
	; Do not update voltage compensation factor if low voltage limit is activated (to avoid interaction)
	mov	A, Pwm_Limit
	cpl	A
	jnz	check_voltage_compensate_power

	mov	Voltage_Comp_Factor, Temp3; Set new factor

check_voltage_compensate_power:
	; Multiply current pwm with voltage compensation factor
	mov	A, Current_Pwm
	mov	B, Voltage_Comp_Factor
	mul	AB			
	; Shift result
	mov	Temp4, B
	mov	Temp3, A
	mov	A, Temp3
	rlc	A
	mov	A, Temp4
	rlc	A
	jnc	($+4)				; If result is below max pwm - branch 

	mov	A, #0FFh

	mov	Current_Pwm_Comp, A
IF MODE >= 1	; Tail or multi
	mov	Current_Pwm_Limited, A			; Set this also here, for tail operation. Default not limited
	clr	C
	mov	A, Current_Pwm_Comp				; Check against limit
	subb	A, Pwm_Limit
	jc	($+5)						; If current pwm below limit - branch

	mov	Current_Pwm_Limited, Pwm_Limit	; Limit pwm
ENDIF
	ajmp	check_voltage_limit_start

check_voltage_comp_skip:
	mov	Current_Pwm_Comp, Current_Pwm

check_voltage_limit_start:
IF MODE == 0 OR MODE == 2	; Main or multi
	; Check if ADC is saturated
	clr	C
	mov	A, Temp1
	subb	A, #0FFh
	mov	A, Temp2
	subb	A, #03h
	jnc	check_voltage_good		; ADC saturated, can not make judgement

	; Check voltage against limit
	clr	C
	mov	A, Temp1
	subb	A, Lipo_Adc_Limit_L
	mov	A, Temp2
	subb	A, Lipo_Adc_Limit_H
	jnc	check_voltage_good		; If voltage above limit - branch

	; Decrease pwm limit
	mov  A, Pwm_Limit
	jz	check_voltage_lim		; If limit zero - branch

	dec	Pwm_Limit				; Decrement limit
	jmp	check_voltage_lim

check_voltage_good:
	; Increase pwm limit
	mov  A, Pwm_Limit
	cpl	A			
	jz	check_voltage_lim		; If limit max - branch

	inc	Pwm_Limit				; Increment limit

check_voltage_lim:
	mov	Temp1, Pwm_Limit			; Set limit
	clr	C
	mov	A, Current_Pwm_Comp
	subb	A, Temp1
	jnc	check_voltage_spoolup_lim	; If current pwm above limit - branch and limit	

	mov	Temp1, Current_Pwm_Comp		; Set current pwm (no limiting)

check_voltage_spoolup_lim:
	mov  Current_Pwm_Limited, Temp1
	; Slow spoolup
	clr	C
	mov	A, Current_Pwm_Limited
	subb	A, Pwm_Limit_Spoolup
	jc	check_voltage_exit			; If current pwm below limit - branch	

	mov	Current_Pwm_Limited, Pwm_Limit_Spoolup
	mov	A, Pwm_Limit_Spoolup		; Check if spoolup limit is max
	cpl	A
	jz	check_voltage_exit			; If max - branch
 
	mov	Pwm_Limit, Pwm_Limit_Spoolup	; Set pwm limit to spoolup limit during ramp (to avoid governor integral buildup)

check_voltage_exit:
ENDIF
	; Set adc mux for next conversion
	clr	C
	mov	A, Adc_Conversion_Cnt		; Is next conversion for temperature?
	subb	A, #(TEMP_CHECK_RATE-1)
	jnz	($+5)					; No - skip changing adc input mux

	Set_Adc_Ip_Temp				; Select temp sensor for next conversion

	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Set startup PWM routine
;
; No assumptions
;
; Used for pwm control during startup
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
set_startup_pwm:	
	; Set pwm values according to startup mode flags
	jnb	Flags0.SETTLE_MODE, ($+5)	; Is it motor start settle mode?
	mov	Temp1, #PWM_SETTLE			; Yes - set settle power
	jnb	Flags0.STEPPER_MODE, ($+5)	; Is it motor start stepper mode?
	mov	Temp1, #PWM_STEPPER			; Yes - set stepper power
	jnb	Flags0.AQUISITION_MODE, ($+5)	; Is it motor start aquisition mode?
	mov	Temp1, #PWM_AQUISITION		; Yes - set aquisition power
	jnb	Flags0.INITIAL_RUN_MODE, ($+5); Is it initial run mode?
	mov	Temp1, #PWM_INITIAL_RUN		; Yes - set initial run power

	; Update pwm variables if any startup mode flag is set
	mov	A, Flags0
	anl	A, #((1 SHL SETTLE_MODE)+(1 SHL STEPPER_MODE)+(1 SHL AQUISITION_MODE)+(1 SHL INITIAL_RUN_MODE))
	jz	startup_pwm_exit		; If no startup mode set - exit

	; Adjust startup power
	mov	Temp2, Curr_Startup_Pwr	
	cjne	Temp2, #3, ($+6)			; Is gain 1?
	ljmp	startup_pwm_set_pwm			; Yes - skip adjustment

	clr	C
	mov	A, Temp1
	rrc	A			; After this "0.5"
	mov	Bit_Access_Int, Curr_Startup_Pwr	
	jb	Bit_Access_Int.0, startup_pwm_corr		; Branch if bit 0 in gain is set

	clr	C
	rrc	A			; After this "0.25"

startup_pwm_corr:
	jb	Bit_Access_Int.2, startup_pwm_gain_pos	; Branch if bit 2 in gain is set

	xch	A, Temp1
	clr	C
	subb	A, Temp1					; Apply negative correction
	mov	Temp1, A
	jmp	startup_pwm_set_pwm

startup_pwm_gain_pos:
	add	A, Temp1					; Apply positive correction
	mov	Temp1, A
	jnc	startup_pwm_check_limit		; Above max?

	mov	A, #0FFh					; Yes - limit
	mov	Temp1, A

startup_pwm_check_limit:
	clr	C
	mov	A, Temp1					; Check against limit
	subb	A, Pwm_Limit
	jc	startup_pwm_set_pwm			; If pwm below limit - branch

	mov	Temp1, Pwm_Limit			; Limit pwm

startup_pwm_set_pwm:
	; Set pwm variables
	mov	Requested_Pwm, Temp1		; Update requested pwm
	mov	Current_Pwm, Temp1			; Update current pwm
	mov	Current_Pwm_Comp, Temp1		; Update compensated version of current pwm
	mov	Current_Pwm_Limited, Temp1	; Update limited version of current pwm
	jnb	Flags0.SETTLE_MODE, startup_pwm_exit	; Is it motor start aquisition mode?

	mov	Pwm_Spoolup_Beg, Temp1				; Update spoolup beginning pwm (will use PWM_SETTLE)

startup_pwm_exit:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Initialize all timings routine
;
; No assumptions
;
; Part of initialization before motor start
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
initialize_all_timings: 
	; Check startup rpm setting and set step accordingly
	clr	C
	mov	A, Pgm_Startup_Rpm
	subb	A, #5
	jnc	stepper_step_high
	clr	C
	mov	A, Pgm_Startup_Rpm
	subb	A, #4
	jnc	stepper_step_med_high
	clr	C
	mov	A, Pgm_Startup_Rpm
	subb	A, #3
	jnc	stepper_step_med
	clr	C
	mov	A, Pgm_Startup_Rpm
	subb	A, #2
	jnc	stepper_step_med_low
	clr	C
	mov	A, Pgm_Startup_Rpm
	subb	A, #1
	jnc	stepper_step_low

stepper_step_high:
	mov	Stepper_Step_Beg_L, #low(2000 SHL 1)
	mov	Stepper_Step_Beg_H, #high(2000 SHL 1)
	mov	Stepper_Step_End_L, #low(670 SHL 1)
	mov	Stepper_Step_End_H, #high(670 SHL 1)
	ajmp	stepper_step_set
stepper_step_med_high:
	mov	Stepper_Step_Beg_L, #low(2400 SHL 1)
	mov	Stepper_Step_Beg_H, #high(2400 SHL 1)
	mov	Stepper_Step_End_L, #low(800 SHL 1)
	mov	Stepper_Step_End_H, #high(800 SHL 1)
	ajmp	stepper_step_set
stepper_step_med:
	mov	Stepper_Step_Beg_L, #low(3000 SHL 1)	; ~3300 eRPM 
	mov	Stepper_Step_Beg_H, #high(3000 SHL 1)
	mov	Stepper_Step_End_L, #low(1000 SHL 1)	; ~10000 eRPM
	mov	Stepper_Step_End_H, #high(1000 SHL 1)
	ajmp	stepper_step_set
stepper_step_med_low:
	mov	Stepper_Step_Beg_L, #low(3750 SHL 1)
	mov	Stepper_Step_Beg_H, #high(3750 SHL 1)
	mov	Stepper_Step_End_L, #low(1250 SHL 1)
	mov	Stepper_Step_End_H, #high(1250 SHL 1)
	ajmp	stepper_step_set
stepper_step_low:
	mov	Stepper_Step_Beg_L, #low(4500 SHL 1)
	mov	Stepper_Step_Beg_H, #high(4500 SHL 1)
	mov	Stepper_Step_End_L, #low(1500 SHL 1)
	mov	Stepper_Step_End_H, #high(1500 SHL 1)
	ajmp	stepper_step_set

stepper_step_set:
	mov	Wt_Stepper_Step_L, Stepper_Step_Beg_L	; Initialize stepper step time 
	mov	Wt_Stepper_Step_H, Stepper_Step_Beg_H
	mov	Temp3, #0FFh			; Initialization value ~8.2ms
	mov	Temp4, #3Fh
	mov	Wt_Comm_L, Temp3		; Initialize wait from zero cross to commutation
	mov	Wt_Comm_H, Temp4
	mov	Wt_Advance_L, Temp3		; Initialize wait for timing advance
	mov	Wt_Advance_H, Temp4
	mov	Temp4, #1Fh			; About half
	mov	Wt_Zc_Scan_L, Temp3		; Initialize wait before zero cross scan
	mov	Wt_Zc_Scan_H, Temp4
	mov	Comm_Period4x_H, Temp3	; Set commutation period registers to very slow timing
	mov	Comm_Period4x_L, Temp3
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Calculate next commutation timing routine
;
; No assumptions
;
; Called immediately after each commutation
; Also sets up timer 1 to wait advance timing
; Two entry points are used
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
calc_next_comm_timing_start:	; Entry point for startup
	mov	Temp1, Wt_Stepper_Step_L	; Set up stepper step wait 
	mov	Temp2, Wt_Stepper_Step_H
	jmp	read_timer

calc_next_comm_timing:		; Entry point for run mode
	mov	Temp1, Wt_Advance_L		; Set up advance timing wait 
	mov	Temp2, Wt_Advance_H
read_timer:
	; Set up next wait
	mov	TMR3CN, #00h		; Timer3 disabled
	clr	C
	clr	A
	subb	A, Temp1			; Set wait to zero cross scan value
	mov	TMR3L, A
	clr	A
	subb	A, Temp2		
	mov	TMR3H, A
	mov	TMR3CN, #04h		; Timer3 enabled
	setb	Flags0.T3_PENDING
	; Read commutation time
	mov	TMR2CN, #20h		; Timer2 disabled
	mov	Temp1, TMR2L		; Load timer value
	mov	Temp2, TMR2H	
	mov	TMR2CN, #24h		; Timer2 enabled
	; Calculate this commutation time
	mov	Temp3, Prev_Comm_L
	mov	Temp4, Prev_Comm_H
	mov	Prev_Comm_L, Temp1		; Store timestamp as previous commutation
	mov	Prev_Comm_H, Temp2
	clr	C
	mov	A, Temp1
	subb	A, Temp3				; Calculate the new commutation time
	mov	Temp1, A
	mov	A, Temp2
	subb	A, Temp4
	mov	Temp2, A
	; Calculate next zero cross scan timeout 
	mov	Temp3, Comm_Period4x_L	; Comm_Period4x(-l-h-x) holds the time of 4 commutations
	mov	Temp4, Comm_Period4x_H
	clr	C
	mov	A, Temp4					
	rrc	A					; Divide by 2
	mov	Temp6, A	
	mov	A, Temp3				
	rrc	A
	mov	Temp5, A
	clr	C
	mov	A, Temp6				
	rrc	A					; Divide by 2 again
	mov	Temp6, A
	mov	A, Temp5				
	rrc	A
	mov	Temp5, A
	clr	C
	mov	A, Temp3
	subb	A, Temp5				; Subtract a quarter
	mov	Temp3, A
	mov	A, Temp4
	subb	A, Temp6
	mov	Temp4, A

	mov	A, Temp3
	add	A, Temp1				; Add the new time
	mov	Temp3, A
	mov	A, Temp4
	addc	A, Temp2
	mov	Temp4, A
	mov	Comm_Period4x_L, Temp3	; Store Comm_Period4x_X
	mov	Comm_Period4x_H, Temp4
	jc	calc_next_comm_slow		; If period larger than 0xffff - go to slow case
	ret

calc_next_comm_slow:
	mov	Comm_Period4x_H, #0FFh	; Set commutation period registers to very slow timing (0xffff)
	mov	Comm_Period4x_L, #0FFh
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait advance timing routine
;
; No assumptions
;
; Waits for the advance timing to elapse
; Also sets up timer 1 to wait the zero cross scan wait time
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait_advance_timing:	
	jnb	Flags0.T3_PENDING, ($+5)
	ajmp	wait_advance_timing

	mov	TMR3CN, #00h		; Timer3 disabled
	clr	C
	clr	A
	subb	A, Wt_Zc_Scan_L	; Set wait to zero cross scan value
	mov	TMR3L, A
	clr	A
	subb	A, Wt_Zc_Scan_H		
	mov	TMR3H, A
	mov	TMR3CN, #04h		; Timer3 enabled
	setb	Flags0.T3_PENDING
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Calculate new wait times routine
;
; No assumptions
;
; Calculates new wait times
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
calc_new_wait_times:	
	mov	Temp2, Comm_Period4x_H	; Load Comm_Period4x
	mov	Temp1, Comm_Period4x_L	
	mov	Temp3, #4				; Divide 4 times
divide_wait_times:
	clr	C
	mov	A, Temp2				
	rrc	A					; Divide by 2
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	djnz	Temp3, divide_wait_times

	clr	C
	mov	A, Temp1
	subb	A, #(COMM_TIME_RED SHL 1)
	mov	Temp1, A
	mov	A, Temp2				
	subb	A, #0
	mov	Temp2, A
	jc	load_min_time			; Check that result is still positive

	clr	C
	mov	A, Temp1
	subb	A, #(COMM_TIME_MIN SHL 1)
	mov	A, Temp2				
	subb	A, #0
	jnc	adjust_timing			; Check that result is still above minumum

load_min_time:
	mov	Temp1, #(COMM_TIME_MIN SHL 1)
	clr	A
	mov	Temp2, A

adjust_timing:
	mov	A, Temp2				; Copy values
	mov	Temp4, A
	mov	A, Temp1
	mov	Temp3, A
	clr	C
	mov	A, Temp2				
	rrc	A					; Divide by 2
	mov	Temp6, A
	mov	A, Temp1
	rrc	A
	mov	Temp5, A
	clr	C
	mov	A, Pgm_Comm_Timing
	subb	A, #3				; Is timing normal?
	jz	store_times_decrease	; Yes - branch

	mov	A, Pgm_Comm_Timing
	jb	ACC.0, adjust_timing_two_steps	; If an odd number - branch

	clr	C
	mov	A, Temp1				; Add 7.5� and store in Temp1/2
	addc	A, Temp5
	mov	Temp1, A
	mov	A, Temp2
	addc	A, Temp6
	mov	Temp2, A
	mov	A, Temp5				; Store 7.5� in Temp3/4
	mov	Temp3, A
	mov	A, Temp6			
	mov	Temp4, A
	jmp	store_times_up_or_down

adjust_timing_two_steps:
	clr	C
	mov	A, Temp1				; Add 15� and store in Temp1/2
	addc	A, Temp1
	mov	Temp1, A
	mov	A, Temp2
	addc	A, Temp2
	mov	Temp2, A
	mov	Temp3, #(COMM_TIME_MIN SHL 1)	; Store minimum time in Temp3/4
	clr	A
	mov	Temp4, A

store_times_up_or_down:
	clr	C
	mov	A, Pgm_Comm_Timing
	subb	A, #3				; Is timing higher than normal?
	jc	store_times_decrease	; No - branch

store_times_increase:
	mov	Wt_Comm_L, Temp3		; Now commutation time (~60�) divided by 4 (~15� nominal)
	mov	Wt_Comm_H, Temp4
	mov	Wt_Advance_L, Temp1		; New commutation advance time (~15� nominal)
	mov	Wt_Advance_H, Temp2
	mov	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5�)
	mov	Wt_Zc_Scan_H, Temp6
	ret

store_times_decrease:
	mov	Wt_Comm_L, Temp1		; Now commutation time (~60�) divided by 4 (~15� nominal)
	mov	Wt_Comm_H, Temp2
	mov	Wt_Advance_L, Temp3		; New commutation advance time (~15� nominal)
	mov	Wt_Advance_H, Temp4
	mov	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5�)
	mov	Wt_Zc_Scan_H, Temp6
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait before zero cross scan routine
;
; No assumptions
;
; Waits for the zero cross scan wait time to elapse
; Also sets up timer 1 to wait the zero cross scan timeout time
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait_before_zc_scan:	
	jnb	Flags0.T3_PENDING, ($+5)
	jmp	wait_before_zc_scan

	mov	TMR3CN, #00h		; Timer3 disabled
	clr	C
	clr	A
	subb	A, Comm_Period4x_L	; Set wait to zero comm period 4x value
	mov	TMR3L, A
	clr	A
	subb	A, Comm_Period4x_H		
	mov	TMR3H, A
	mov	TMR3CN, #04h		; Timer3 enabled
	setb	Flags0.T3_PENDING
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait for comparator to go low/high routines
;
; No assumptions
;
; Waits for the zero cross scan wait time to elapse
; Then scans for comparator going low/high
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait_for_comp_out_low:
	setb	EA						; Enable interrupts
	jb	Flags0.T3_PENDING, ($+4)		; Has zero cross scan timeout elapsed?
	ret							; Yes - return

	; Select number of comparator readings based upon current pwm
	mov 	A, Current_Pwm_Limited		; Load current pwm
	cpl	A						; Invert
	swap	A						; Swap nibbles (bits7:4 go to bits3:0)
	clr	C
	rrc	A						; Shift right (original bits7:5 will now be in bits2:0)
	anl	A, #07h					; Take 3 lsbs (that were originally msbs)
	inc	A						; Add 1 to ensure always 1 or higher
	mov	Temp2, A
comp_low_wait_on_pwm:
	setb	EA						; Enable interrupts
	nop							; Wait for interrupt to be caught
	jb	Flags0.T3_PENDING, ($+4)		; Has zero cross scan timeout elapsed?
	ret							; Yes - return

	clr	EA						; Disable interrupts
	jb	Flags0.PWM_ON, pwm_wait_low	; If pwm on - proceed
	jnb	Flags1.CURR_PWMOFF_COMP_ABLE, comp_low_wait_on_pwm	; If comparator is not usable in pwm off - go back

pwm_wait_low:						
	mov	Temp1, #4					; Wait some cycles after pwm has been switched on (motor wire electrical settling)
	clr	C
	mov	A, TL1
	subb	A, Temp1
	jc	pwm_wait_low	

comp_read_low:
	Read_Comp_Out 				; Read comparator output
	mov	Bit_Access, A
	jnb	Bit_Access.6, ($+6)		; Is comparator output low?
	ljmp	wait_for_comp_out_low	; No - go back
	djnz	Temp2, comp_read_low	; Decrement readings counter - repeat comparator reading if not zero
	setb	EA					; Enable interrupts
	ret						; Yes - return

wait_for_comp_out_high:
	setb	EA						; Enable interrupts
	jb	Flags0.T3_PENDING, ($+4)		; Has zero cross scan timeout elapsed?
	ret							; Yes - return

	; Select number of comparator readings based upon current pwm
	mov 	A, Current_Pwm_Limited		; Load current pwm
	cpl	A						; Invert
	swap	A						; Swap nibbles (bits7:4 go to bits3:0)
	clr	C
	rrc	A						; Shift right (original bits7:5 will now be in bits2:0)
	anl	A, #07h					; Take 3 lsbs (that were originally msbs)
	inc	A						; Add 1 to ensure always 1 or higher
	mov	Temp2, A
comp_high_wait_on_pwm:
	setb	EA						; Enable interrupts
	nop							; Wait for interrupt to be caught
	jb	Flags0.T3_PENDING, ($+4)		; Has zero cross scan timeout elapsed?
	ret							; Yes - return

	clr	EA						; Disable interrupts
	jb	Flags0.PWM_ON, pwm_wait_high	; If pwm on - proceed
	jnb	Flags1.CURR_PWMOFF_COMP_ABLE, comp_high_wait_on_pwm	; If comparator is not usable in pwm off - go back

pwm_wait_high:							
	mov	Temp1, #4					; Wait some cycles after pwm has been switched on (motor wire electrical settling)
	clr	C
	mov	A, TL1
	subb	A, Temp1
	jc	pwm_wait_high	

comp_read_high:
	Read_Comp_Out 				; Read comparator output
	mov	Bit_Access, A
	jb	Bit_Access.6, ($+6)		; Is comparator output high?
	ljmp	wait_for_comp_out_high	; No - go back
	djnz	Temp2, comp_read_high	; Decrement readings counter - repeat comparator reading if not zero
	setb	EA					; Enable interrupts
	ret						; Yes - return


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Setup commutation timing routine
;
; No assumptions
;
; Sets up and starts wait from commutation to zero cross
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
setup_comm_wait: 
	mov	TMR3CN, #00h		; Timer3 disabled
	clr	C
	clr	A
	subb	A, Wt_Comm_L		; Set wait commutation value
	mov	TMR3L, A
	clr	A
	subb	A, Wt_Comm_H		
	mov	TMR3H, A
	mov	TMR3CN, #04h		; Timer3 enabled
	setb	Flags0.T3_PENDING
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait for commutation routine
;
; No assumptions
;
; Waits from zero cross to commutation 
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait_for_comm: 
	jnb Flags0.T3_PENDING, ($+5)	; Timer pending?
	ajmp	wait_for_comm			; Yes, go back
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Commutation routines
;
; No assumptions
;
; Performs commutation switching 
; Damped routines uses all pfets on when in pwm off to dampen the motor
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
comm1comm2:	
	clr 	EA					; Disable all interrupts
	BpFET_off					; Bp off
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, comm12_damp
	jb	Flags1.PGM_PWMOFF_DAMPED_FULL, comm12_damp
	jmp	comm12_nondamp
comm12_damp:
	mov	DPTR, #pwm_cnfet_apfet_on	
IF DAMPED_MODE_ENABLE == 0
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, comm12_nondamp
ENDIF
	jnb	Flags1.CURR_PWMOFF_DAMPED, comm12_nondamp		; If pwm off not damped - branch
	CpFET_off				
	mov	A, #NFETON_DELAY		; Delay
	djnz ACC,	$
comm12_nondamp:
	ApFET_on					; Ap on
	Set_Comp_Phase_B 			; Set comparator to phase B
	mov	Comm_Phase, #2
	setb	EA					; Enable all interrupts
	ret

comm2comm3:	
	clr 	EA					; Disable all interrupts
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, comm23_damp
	jb	Flags1.PGM_PWMOFF_DAMPED_FULL, comm23_damp
	jmp	comm23_nondamp
comm23_damp:
	mov	DPTR, #pwm_bnfet_apfet_on
	jnb	Flags1.CURR_PWMOFF_DAMPED, comm23_nondamp		; If pwm off not damped - branch
	BpFET_off				
	CpFET_off				
	mov	A, #NFETON_DELAY		; Delay
	djnz ACC,	$
	jmp	comm23_nfet
comm23_nondamp:
	mov	DPTR, #pwm_bfet_on	
comm23_nfet:
	CnFET_off					; Cn off
	jnb	Flags0.PWM_ON, comm23_cp	; Is pwm on?
	BnFET_on					; Yes - Bn on
comm23_cp:
	Set_Comp_Phase_C 			; Set comparator to phase C
	mov	Comm_Phase, #3
	setb	EA					; Enable all interrupts
	ret

comm3comm4:	
	clr 	EA					; Disable all interrupts
	ApFET_off					; Ap off
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, comm34_damp
	jb	Flags1.PGM_PWMOFF_DAMPED_FULL, comm34_damp
	jmp	comm34_nondamp
comm34_damp:
	mov	DPTR, #pwm_bnfet_cpfet_on
IF DAMPED_MODE_ENABLE == 0
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, comm34_nondamp
ENDIF
	jnb	Flags1.CURR_PWMOFF_DAMPED, comm34_nondamp		; If pwm off not damped - branch
	BpFET_off				
	mov	A, #NFETON_DELAY		; Delay
	djnz ACC,	$
comm34_nondamp:
	CpFET_on					; Cp on
	Set_Comp_Phase_A 			; Set comparator to phase A
	mov	Comm_Phase, #4
	setb	EA					; Enable all interrupts
	ret

comm4comm5:	
	clr 	EA					; Disable all interrupts
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, comm45_damp
	jb	Flags1.PGM_PWMOFF_DAMPED_FULL, comm45_damp
	jmp	comm45_nondamp
comm45_damp:
	mov	DPTR, #pwm_anfet_cpfet_on
	jnb	Flags1.CURR_PWMOFF_DAMPED, comm45_nondamp		; If pwm off not damped - branch
	ApFET_off				
	BpFET_off				
	mov	A, #NFETON_DELAY		; Delay
	djnz ACC,	$
	jmp	comm45_nfet
comm45_nondamp:
	mov	DPTR, #pwm_afet_on
comm45_nfet:
	BnFET_off					; Bn off
	jnb	Flags0.PWM_ON, comm45_cp	; Is pwm on?
	AnFET_on					; Yes - An on
comm45_cp:
	Set_Comp_Phase_B 			; Set comparator to phase B
	mov	Comm_Phase, #5
	setb	EA					; Enable all interrupts
	ret

comm5comm6:	
	clr 	EA					; Disable all interrupts
	CpFET_off					; Cp off
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, comm56_damp
	jb	Flags1.PGM_PWMOFF_DAMPED_FULL, comm56_damp
	jmp	comm56_nondamp
comm56_damp:
	mov	DPTR, #pwm_anfet_bpfet_on
IF DAMPED_MODE_ENABLE == 0
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, comm56_nondamp
ENDIF
	jnb	Flags1.CURR_PWMOFF_DAMPED, comm56_nondamp		; If pwm off not damped - branch
	ApFET_off				
	mov	A, #NFETON_DELAY		; Delay
	djnz ACC,	$
comm56_nondamp:
	BpFET_on					; Bp on
	Set_Comp_Phase_C 			; Set comparator to phase C
	mov	Comm_Phase, #6
	setb	EA					; Enable all interrupts
	ret

comm6comm1:	
	clr 	EA					; Disable all interrupts
	jb	Flags1.PGM_PWMOFF_DAMPED_LIGHT, comm61_damp
	jb	Flags1.PGM_PWMOFF_DAMPED_FULL, comm61_damp
	jmp	comm61_nondamp
comm61_damp:
	mov	DPTR, #pwm_cnfet_bpfet_on
	jnb	Flags1.CURR_PWMOFF_DAMPED, comm61_nondamp		; If pwm off not damped - branch
	ApFET_off				
	CpFET_off				
	mov	A, #NFETON_DELAY		; Delay
	djnz ACC,	$
	jmp	comm61_nfet
comm61_nondamp:
	mov	DPTR, #pwm_cfet_on
comm61_nfet:
	AnFET_off					; An off
	jnb	Flags0.PWM_ON, comm61_cp	; Is pwm on?
	CnFET_on					; Yes - Cn on
comm61_cp:
	Set_Comp_Phase_A 			; Set comparator to phase A
	mov	Comm_Phase, #1
	setb	EA					; Enable all interrupts
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Switch power off routine
;
; No assumptions
;
; Switches all fets off 
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
switch_power_off:
	mov	DPTR, #pwm_nofet_on	; Set DPTR register to pwm_nofet_on label		
	All_nFETs_Off			; Turn off all nfets
	All_pFETs_Off			; Turn off all pfets
	ret			


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Decrement stepper step routine
;
; No assumptions
;
; Decrements the stepper step 
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
decrement_stepper_step:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, Stepper_Step_End_L		; Minimum Stepper_Step_End
	mov	A, Wt_Stepper_Step_H
	subb	A, Stepper_Step_End_H	
	jnc	decrement_step				; Branch if same or higher than minimum
	ret

decrement_step:
	; Check acceleration setting and set step size accordingly
	clr	C
	mov	A, Pgm_Startup_Accel
	subb	A, #5
	jnc	dec_step_high
	clr	C
	mov	A, Pgm_Startup_Accel
	subb	A, #4
	jnc	dec_step_med_high
	clr	C
	mov	A, Pgm_Startup_Accel
	subb	A, #3
	jnc	dec_step_med
	clr	C
	mov	A, Pgm_Startup_Accel
	subb	A, #2
	jnc	dec_step_med_low
	clr	C
	mov	A, Pgm_Startup_Accel
	subb	A, #1
	jnc	dec_step_low

dec_step_high:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(30 SHL 1)		
	mov	Temp1, A
	ajmp	decrement_step_exit
dec_step_med_high:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(20 SHL 1)		
	mov	Temp1, A
	ajmp	decrement_step_exit
dec_step_med:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(13 SHL 1)		
	mov	Temp1, A
	ajmp	decrement_step_exit
dec_step_med_low:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(9 SHL 1)		
	mov	Temp1, A
	ajmp	decrement_step_exit
dec_step_low:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(5 SHL 1)		
	mov	Temp1, A
	ajmp	decrement_step_exit

decrement_step_exit:
	mov	A, Wt_Stepper_Step_H
	subb	A, #0		
	mov	Temp2, A
	mov	Wt_Stepper_Step_L, Temp1		
	mov	Wt_Stepper_Step_H, Temp2
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Stepper timer wait
;
; No assumptions
;
; Waits for the stepper step timer to elapse
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
stepper_timer_wait:
	jnb Flags0.T3_PENDING, ($+5)	; Timer pending?
	ajmp	stepper_timer_wait		; Yes, go back
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Set default parameters
;
; No assumptions
;
; Sets default programming parameters
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
set_default_parameters:
IF MODE == 0	; Main
	mov	Pgm_Gov_P_Gain, #DEFAULT_PGM_MAIN_P_GAIN
	mov	Pgm_Gov_I_Gain, #DEFAULT_PGM_MAIN_I_GAIN
	mov	Pgm_Gov_Mode, #DEFAULT_PGM_MAIN_GOVERNOR_MODE
	mov	Pgm_Gov_Range, #DEFAULT_PGM_MAIN_GOVERNOR_RANGE
	mov	Pgm_Low_Voltage_Lim, #DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM
	mov	Pgm_Startup_Pwr, #DEFAULT_PGM_MAIN_STARTUP_PWR
	mov	Pgm_Startup_Rpm, #DEFAULT_PGM_MAIN_STARTUP_RPM
	mov	Pgm_Startup_Accel, #DEFAULT_PGM_MAIN_STARTUP_ACCEL
	mov	Pgm_Comm_Timing, #DEFAULT_PGM_MAIN_COMM_TIMING
	mov	Pgm_Damping_Force, #DEFAULT_PGM_MAIN_DAMPING_FORCE
	mov	Pgm_Pwm_Freq, #DEFAULT_PGM_MAIN_PWM_FREQ
	mov	Pgm_Direction_Rev, #DEFAULT_PGM_MAIN_DIRECTION_REV
	mov	Pgm_Input_Pol, #DEFAULT_PGM_MAIN_RCP_PWM_POL
	mov	Pgm_Motor_Idle, #0
ENDIF
IF MODE == 1	; Tail
	mov	Pgm_Motor_Gain, #DEFAULT_PGM_TAIL_GAIN
	mov	Pgm_Motor_Idle, #DEFAULT_PGM_TAIL_IDLE_SPEED
	mov	Pgm_Startup_Pwr, #DEFAULT_PGM_TAIL_STARTUP_PWR
	mov	Pgm_Startup_Rpm, #DEFAULT_PGM_TAIL_STARTUP_RPM
	mov	Pgm_Startup_Accel, #DEFAULT_PGM_TAIL_STARTUP_ACCEL
	mov	Pgm_Comm_Timing, #DEFAULT_PGM_TAIL_COMM_TIMING
	mov	Pgm_Damping_Force, #DEFAULT_PGM_TAIL_DAMPING_FORCE
	mov	Pgm_Pwm_Freq, #DEFAULT_PGM_TAIL_PWM_FREQ
	mov	Pgm_Direction_Rev, #DEFAULT_PGM_TAIL_DIRECTION_REV
	mov	Pgm_Input_Pol, #DEFAULT_PGM_TAIL_RCP_PWM_POL
	mov	Pgm_Gov_Mode, #4
ENDIF
IF MODE == 2	; Multi
	mov	Pgm_Motor_Gain, #DEFAULT_PGM_MULTI_GAIN
	mov	Pgm_Low_Voltage_Lim, #DEFAULT_PGM_MULTI_LOW_VOLTAGE_LIM
	mov	Pgm_Startup_Pwr, #DEFAULT_PGM_MULTI_STARTUP_PWR
	mov	Pgm_Startup_Rpm, #DEFAULT_PGM_MULTI_STARTUP_RPM
	mov	Pgm_Startup_Accel, #DEFAULT_PGM_MULTI_STARTUP_ACCEL
	mov	Pgm_Comm_Timing, #DEFAULT_PGM_MULTI_COMM_TIMING
	mov	Pgm_Damping_Force, #DEFAULT_PGM_MULTI_DAMPING_FORCE
	mov	Pgm_Pwm_Freq, #DEFAULT_PGM_MULTI_PWM_FREQ
	mov	Pgm_Direction_Rev, #DEFAULT_PGM_MULTI_DIRECTION_REV
	mov	Pgm_Input_Pol, #DEFAULT_PGM_MULTI_RCP_PWM_POL
	mov	Pgm_Gov_Mode, #4
ENDIF
	mov 	Pgm_Enable_TX_Pgm, #DEFAULT_ENABLE_TX_PGM
	mov 	Pgm_Main_Rearm_Start, #DEFAULT_MAIN_REARM_START 
	mov	Pgm_Gov_Setup_Target, #DEFAULT_PGM_MAIN_GOV_SETUP_TARGET
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Decode parameters
;
; No assumptions
;
; Decodes programming parameters
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
decode_parameters:
	; Decode damping
	mov	Damping_Period, #9		; Set default
	mov	Damping_On, #1
	clr	C
	mov	A, Pgm_Damping_Force	; Look for 2
	subb	A, #2
	jnz	decode_damping_3

	mov	Damping_Period, #5
	mov	Damping_On, #1
	jmp	decode_damping_done

decode_damping_3:
	clr	C
	mov	A, Pgm_Damping_Force	; Look for 3
	subb	A, #3
	jnz	decode_damping_4

	mov	Damping_Period, #5
	mov	Damping_On, #2
	jmp	decode_damping_done

decode_damping_4:
	clr	C
	mov	A, Pgm_Damping_Force	; Look for 4
	subb	A, #4
	jnz	decode_damping_5

	mov	Damping_Period, #5
	mov	Damping_On, #3
	jmp	decode_damping_done

decode_damping_5:
	clr	C
	mov	A, Pgm_Damping_Force	; Look for 5
	subb	A, #5
	jnz	decode_damping_done

	mov	Damping_Period, #9
	mov	Damping_On, #7

decode_damping_done:
IF MODE == 0	; Main
	clr	Flags1.PGM_PWMOFF_DAMPED_LIGHT
	clr	C
	mov	A, Pgm_Pwm_Freq
	subb	A, #3
	jnz	($+4)
	setb	Flags1.PGM_PWMOFF_DAMPED_LIGHT
	clr	Flags1.PGM_PWMOFF_DAMPED_FULL
ENDIF
IF MODE >= 1	; Tail or multi
	clr	Flags1.PGM_PWMOFF_DAMPED_LIGHT
	clr	C
	mov	A, Pgm_Pwm_Freq
	subb	A, #3
	jnz	($+4)
	setb	Flags1.PGM_PWMOFF_DAMPED_LIGHT
	clr	Flags1.PGM_PWMOFF_DAMPED_FULL
	clr	C
	mov	A, Pgm_Pwm_Freq
	subb	A, #4
	jnz	($+4)					
	setb	Flags1.PGM_PWMOFF_DAMPED_FULL
ENDIF
	clr	Flags2.PGM_DIR_REV
	mov	A, Pgm_Direction_Rev
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_DIR_REV
	clr	Flags2.PGM_RCP_PWM_POL
	mov	A, Pgm_Input_Pol
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_RCP_PWM_POL
	clr	C
	mov	A, Pgm_Pwm_Freq	; Check if low frequency is programmed
	subb	A, #2
	jz	decode_pwm_freq_low

	mov	CKCON, #01h		; Timer0 set for clk/4 (22kHz pwm)
	jmp	decode_parameters_exit

decode_pwm_freq_low:
	mov	CKCON, #00h		; Timer0 set for clk/12 (8kHz pwm)

decode_parameters_exit:
	ret




;**** **** **** **** **** **** **** **** **** **** **** **** ****
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Main program start
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;**** **** **** **** **** **** **** **** **** **** **** **** ****

IF TX_PGM == 1
$include (BLHeliTxPgm.inc)		; Include source code for programming the ESC with the TX
ENDIF

;**** **** **** **** **** **** **** **** **** **** **** **** ****
reset:
	; Select register bank 0 for main program routines
	clr	PSW.3			; Select register bank 0 for main program routines	
	; Disable the WDT.
	anl	PCA0MD, #NOT(40h)	; Clear watchdog enable bit
	; Initialize stack
	mov	SP, #0c0h			; Stack = 64 upper bytes of RAM
	; Initialize VDD monitor
	orl	VDM0CN, #080h    	; Enable the VDD monitor
	call	wait1ms			; Wait at least 100us
	; Set clock frequency
	orl	OSCICN, #03h		; Set clock divider to 1
	mov	A, OSCICL				
	add	A, #04h			; 24.5MHz to 24MHz (~0.5% per step)
	jc	reset_cal_done		; Is carry set? - skip next instruction

	mov	OSCICL, A

reset_cal_done:
	; Ports initialization
	mov	P0, #P0_INIT				
	mov	P1, #P1_INIT				
	mov	P0MDOUT, #P0_PUSHPULL				
	mov	P1MDOUT, #P1_PUSHPULL				
	mov	P2MDOUT, #P2_PUSHPULL				
	mov	P0MDIN, #P0_DIGITAL				
	mov	P1MDIN, #P1_DIGITAL				
	mov	P0SKIP, #P0_SKIP				
	mov	P1SKIP, #P1_SKIP				
	mov	XBR1, #41h		; Xbar enabled, CEX0 routed to pin Rcp_In			
	; Switch power off
	call	switch_power_off
	; Clear RAM
	clr	A				; Clear accumulator
	mov	Temp1, A			; Clear Temp1
clear_ram:	
	mov	@Temp1, A			; Clear RAM
	djnz Temp1, clear_ram	; Is A not zero? - jump
	; Set default programmed parameters
	call	set_default_parameters
IF TX_PGM == 1
	; Read programmed parameters
	call read_eeprom_parameters
ENDIF
	; Decode parameters
	call	decode_parameters
	; Switch power off
	call	switch_power_off
	; Timer control
	mov	TCON, #50h		; Timer0 and timer1 enabled
	; Timer mode
	mov	TMOD, #02h		; Timer0 as 8bit
	; Timer2: clk/12 for 128us and 32ms interrupts
	mov	TMR2CN, #24h		; Timer2 enabled, low counter interrups enabled 
	; Timer3: clk/12 for commutation timing
	mov	TMR3CN, #04h		; Timer3 enabled
	; PCA
	mov	PCA0CN, #40h		; PCA enabled
	; Initializing beep
	call wait200ms	
	call beep_f1
	call wait30ms
	call beep_f2
	call wait30ms
	call beep_f3
	call wait30ms
	; Enable interrupts
	mov	IE, #22h			; Enable timer0 and timer2 interrupts
	mov	IP, #02h			; High priority to timer0 interrupts
	mov	EIE1, #90h		; Enable timer3 and PCA0 interrupts
	mov	EIP1, #10h		; High priority to PCA interrupts
	; Initialize comparator
	mov	CPT0CN, #80h		; Comparator enabled, no hysteresis
	; Initialize ADC
	Initialize_Adc			; Initialize ADC operation
	call	wait1ms
	setb	EA				; Enable all interrupts
	; Measure number of lipo cells
	call Measure_Lipo_Cells			; Measure number of lipo cells
	; Initialize rc pulse
	Rcp_Int_Enable		 			; Enable interrupt
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	clr	Flags1.RCP_EDGE_NO			; Set first edge flag
	call wait200ms
	; Set initial arm variable
	mov	Initial_Arm, #1

	; Measure PWM frequency
measure_pwm_freq_init:	
	setb	Flags0.RCP_MEAS_PWM_FREQ 		; Set measure pwm frequency flag
measure_pwm_freq_start:	
	mov	Temp3, #10					; Number of pulses to measure
measure_pwm_freq_loop:	
	; Check if period diff was accepted
	mov	A, Rcp_Period_Diff_Accepted
	jnz	($+4)

	mov	Temp3, #10					; Reset number of pulses to measure

	call wait3ms						; Wait for next pulse (NB: Uses Temp1/2!) 
	mov	A, New_Rcp					; Load value
	clr	C
	subb	A, #RCP_VALIDATE				; Higher than validate level?
	jc	measure_pwm_freq_start			; No - start over

	mov	A, Flags2						; Check pwm frequency flags
	anl	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	mov	Prev_Rcp_Pwm_Freq, Curr_Rcp_Pwm_Freq		; Store as previous flags for next pulse 
	mov	Curr_Rcp_Pwm_Freq, A					; Store current flags for next pulse 
	cjne	A, Prev_Rcp_Pwm_Freq, measure_pwm_freq_start	; Go back if new flags not same as previous

	djnz	Temp3, measure_pwm_freq_loop				; Go back if not required number of pulses seen

	clr	Flags0.RCP_MEAS_PWM_FREQ 		; Clear measure pwm frequency flag
	call wait100ms						; Wait for new RC pulse

	; Validate RC pulse
validate_rcp_start:	
	call wait3ms						; Wait for next pulse (NB: Uses Temp1/2!) 
	mov	Temp1, #RCP_VALIDATE			; Set validate level as default
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2						; Check pwm frequency flags
	jnz	($+4)						; If a flag is set (not PPM) - branch

	mov	Temp1, #0						; Set level to zero

	mov	Temp2, Pgm_Gov_Mode				; Governor arm mode?
	cjne	Temp2, #2, ($+5)				; No - branch

	mov	Temp1, #RCP_VALIDATE			; Set validate level as default

	clr	C
	mov	A, New_Rcp					; Load value
	subb	A, Temp1						; Higher than validate level?
	jc	validate_rcp_start				; No - start over

	; Set up RC pulse interrupts after pwm frequency measurement
	Rcp_Int_First 						; Enable interrupt and set to first edge
	Rcp_Clear_Int_Flag 					; Clear interrupt flag
	clr	Flags1.RCP_EDGE_NO				; Set first edge flag

	; Beep arm sequence start signal
	clr 	EA							; Disable all interrupts
	call beep_f1						; Signal that RC pulse is ready
	call beep_f1
	call beep_f1
	setb	EA							; Enable all interrupts
	call wait200ms	

	; Arming sequence start
	mov	Gov_Arm_Target, #0		; Clear governor arm target
arming_start:
	call wait3ms
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_MAX			; Is RC pulse max?
	jc	program_by_tx_checked	; No - branch

IF TX_PGM == 1
	mov 	A, Pgm_Enable_TX_Pgm	; Yes - start programming mode entry if enabled
	clr	C
	subb	A, #1				; Is TX programming enabled?
	jc 	program_by_tx_checked	; No - branch

	mov	A, Initial_Arm			; Yes - check if it is initial arm sequence
	clr	C
	subb	A, #1				; Is it the initial arm sequence?
	jc 	program_by_tx_checked	; No - branch

	jmp	program_by_tx			; Yes - enter programming mode
ENDIF

program_by_tx_checked:
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, Gov_Arm_Target		; Is RC pulse larger than arm target?
	jc	arm_target_updated		; No - do not update

	mov	Gov_Arm_Target, New_Rcp	; Yes - update arm target

arm_target_updated:
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_STOP			; Below stop?
	jnc	arming_start			; No - start over

	; Beep arm sequence end signal
	clr 	EA					; Disable all interrupts
	call beep_f4				; Signal that rcpulse is ready
	call beep_f4
	call beep_f4
	setb	EA					; Enable all interrupts
	call wait200ms

	; Clear initial arm variable
	mov	Initial_Arm, #0
	; Set startup try number variable
	mov	Startup_Try_No, #0
	; Set programmed startup power
	mov	Curr_Startup_Pwr, Pgm_Startup_Pwr

	; Armed and waiting for power on
wait_for_power_on:
	clr	A
	mov	Power_On_Wait_Cnt_L, A	; Clear wait counter
	mov	Power_On_Wait_Cnt_H, A	
wait_for_power_on_loop:
	inc	Power_On_Wait_Cnt_L		; Increment low wait counter
	mov	A, Power_On_Wait_Cnt_L
	cpl	A
	jnz	wait_for_power_on_no_beep; Counter wrapping (about 1 sec)?

	inc	Power_On_Wait_Cnt_H		; Increment high wait counter
	clr	C
	mov	A, Power_On_Wait_Cnt_H
	subb	A, #40				; Approximately 30 sec
	jc	wait_for_power_on_no_beep; Has 30 sec elapsed?

	dec	Power_On_Wait_Cnt_H		; Decrement high wait counter
	clr 	EA					; Disable all interrupts
	call beep_f4				; Signal that there is no signal
	setb	EA					; Enable all interrupts
	call wait100ms				; Wait for new RC pulse to be measured

wait_for_power_on_no_beep:
	call wait3ms
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #(RCP_STOP+20) 		; Higher than stop (plus some hysteresis)?
	jc	wait_for_power_on_loop	; No - start over

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Start entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
init_start:
	call switch_power_off
	clr	A
	mov	Requested_Pwm, A		; Set requested pwm to zero
	mov	Governor_Req_Pwm, A		; Set governor requested pwm to zero
	mov	Current_Pwm, A			; Set current pwm to zero
	mov	Current_Pwm_Comp, A		; Set compensated current pwm to zero
	mov	Current_Pwm_Limited, A	; Set limited current pwm to zero
	mov	Pwm_Spoolup_Beg, A		; Set spoolup beginning pwm to zero
	mov	Pwm_Limit, #0FFh		; Set pwm limit to max
	mov	Pwm_Motor_Idle, Pgm_Motor_Idle	; Set idle pwm to programmed value
	mov	Gov_Target_L, A		; Set target to zero
	mov	Gov_Target_H, A
	mov	Gov_Integral_L, A		; Set integral to zero
	mov	Gov_Integral_H, A
	mov	Gov_Integral_X, A
	mov	Voltage_Comp_Factor, #80h; Set voltage compensation factor to "1"
	mov	Adc_Conversion_Cnt, A
	mov	Gov_Active, A
	mov	Flags0, A				; Clear flags0
	mov	Rcp_Stop_Cnt, A		; Set RC pulse stop count to zero
	call initialize_all_timings	; Initialize timing
	;**** **** **** **** ****
	; Settle mode beginning
	;**** **** **** **** **** 
	mov	Adc_Conversion_Cnt, #TEMP_CHECK_RATE	; Make sure a temp reading is done
	Set_Adc_Ip_Temp
	call wait1ms
	call start_adc_conversion
	call check_temp_voltage_compensate_and_limit_power
	mov	Adc_Conversion_Cnt, #TEMP_CHECK_RATE	; Make sure a temp reading is done next time
	Set_Adc_Ip_Temp
	; Set up start operating conditions
	mov	Temp1, Pgm_Pwm_Freq		; Store settings
	mov	Temp2, Pgm_Damping_Force	
	mov	Pgm_Pwm_Freq, #3		; Set damped light mode
	mov	Pgm_Damping_Force, #5	; Set high damping force
	call	decode_parameters
	mov	Pgm_Pwm_Freq, Temp1		; Restore settings
	mov	Pgm_Damping_Force, Temp2
	; Begin startup sequence
	setb	Flags0.SETTLE_MODE		; Set motor start settling mode flag
	setb	Flags1.CURR_PWMOFF_DAMPED; Set damped status, in order to ensure that pfets will be turned off in an initial pwm on
	call comm6comm1			; Initialize commutation
	call set_startup_pwm
	call wait1ms
	call comm1comm2
	call wait1ms
	call wait1ms
	call comm2comm3
	call wait3ms			
	call comm3comm4
	call wait3ms			
	call wait3ms			
	call comm4comm5
	call wait10ms				; Settle rotor
	call comm5comm6
	call wait3ms				
	call wait1ms			
	clr	Flags0.SETTLE_MODE		; Clear settling mode flag
	setb	Flags0.STEPPER_MODE		; Set motor start stepper mode flag

	;**** **** **** **** ****
	; Stepper mode beginning
	;**** **** **** **** **** 
stepper_rot_beg:
	call start_adc_conversion
	call check_temp_voltage_compensate_and_limit_power
	call set_startup_pwm
	mov	Adc_Conversion_Cnt, #TEMP_CHECK_RATE	; Make sure a temp reading is done next time
	Set_Adc_Ip_Temp

	call comm6comm1				; Commutate
	call calc_next_comm_timing_start	; Update timing and set timer
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm1comm2			
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm2comm3			
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm3comm4			
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm4comm5			
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm5comm6			
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step	
	; Check stepper step versus end criteria
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, Stepper_Step_End_L		; Minimum Stepper_Step_End
	mov	A, Wt_Stepper_Step_H
	subb	A, Stepper_Step_End_H
	jc	stepper_rot_exit			; Branch if lower than minimum

	; Wait for step
	call stepper_timer_wait
	clr	C
	mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	subb	A, #(RCP_STOP_LIMIT+7)		; Is number of stop RC pulses above limit?
	jc	stepper_rot_beg			; No, next rotation

	jmp	run_to_wait_for_power_on

stepper_rot_exit:
	; Set aquisition mode
	clr	Flags0.STEPPER_MODE			; Clear motor start stepper mode flag
	setb	Flags0.AQUISITION_MODE		; Set aquisition mode flag
	; Set aquisition rotation count
	mov	Startup_Rot_Cnt, #AQUISITION_ROTATIONS
	; Wait for step
	call stepper_timer_wait			; As the last part of stepper mode
	
	;**** **** **** **** ****
	; Aquisition mode beginning
	;**** **** **** **** **** 
aquisition_rot_beg:
	call start_adc_conversion
	call check_temp_voltage_compensate_and_limit_power
	call set_startup_pwm
	mov	Adc_Conversion_Cnt, #TEMP_CHECK_RATE	; Make sure a temp reading is done next time
	Set_Adc_Ip_Temp

	call comm6comm1				; Commutate
	call calc_next_comm_timing_start	; Update timing and set timer
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm1comm2
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm2comm3
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm3comm4
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm4comm5
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step
	call stepper_timer_wait

	call comm5comm6
	call calc_next_comm_timing_start	
	call calc_new_wait_times
	call decrement_stepper_step
	; Decrement startup rotation count
	mov	A, Startup_Rot_Cnt
	dec	A
	; Check number of aquisition rotations
	jz aquisition_rot_exit		; Branch if counter is zero
	
	; Store counter
	mov	Startup_Rot_Cnt, A
	; Wait for step
	call stepper_timer_wait
	clr	C
	mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	subb	A, #(RCP_STOP_LIMIT+3)		; Is number of stop RC pulses above limit?
	jc	aquisition_rot_beg			; No, next rotation

	jmp	run_to_wait_for_power_on

aquisition_rot_exit:
	clr	Flags0.AQUISITION_MODE	; Clear aquisition mode flag
	setb	Flags0.INITIAL_RUN_MODE	; Set initial run mode flag
	call stepper_timer_wait		; As the last part of aquisition mode

	call comm6comm1
	call calc_next_comm_timing	
	call wait_advance_timing		; Wait advance timing and start zero cross wait
	call calc_new_wait_times
	call wait_before_zc_scan		; Wait zero cross wait and start zero cross timeout


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Run entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
	; Set damped run rotation count
	mov	Startup_Rot_Cnt, #DAMPED_RUN_ROTATIONS

; Damped run 1 = B(p-on) + C(n-pwm) - comparator A evaluated
; Out_cA changes from high to low
damped_run1:
	call start_adc_conversion
	call check_temp_voltage_compensate_and_limit_power
	call set_startup_pwm
	mov	Adc_Conversion_Cnt, #TEMP_CHECK_RATE	; Make sure a temp reading is done next time
	Set_Adc_Ip_Temp

	call wait_for_comp_out_high	; Wait zero cross wait and wait for high
	jb	Flags0.T3_PENDING, ($+6)	; Has timeout elapsed?
	ljmp	run_to_wait_for_power_on	; Yes - exit run mode

	call setup_comm_wait		; Setup wait time from zero cross to commutation
	call wait_for_comm			; Wait from zero cross to commutation
	call comm1comm2			; Commutate
	call calc_next_comm_timing	; Calculate next timing and start advance timing wait
	call wait_advance_timing		; Wait advance timing and start zero cross wait
	call calc_new_wait_times
	call wait_before_zc_scan		; Wait zero cross wait and start zero cross timeout

; Damped run 2 = A(p-on) + C(n-pwm) - comparator B evaluated
; Out_cB changes from low to high
damped_run2:
	call wait_for_comp_out_low
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait		
	call wait_for_comm
	call comm2comm3
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Damped run 3 = A(p-on) + B(n-pwm) - comparator C evaluated
; Out_cC changes from high to low
damped_run3:
	call wait_for_comp_out_high
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait		
	call wait_for_comm
	call comm3comm4
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Damped run 4 = C(p-on) + B(n-pwm) - comparator A evaluated
; Out_cA changes from low to high
damped_run4:
	call wait_for_comp_out_low
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait		
	call wait_for_comm
	call comm4comm5
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Damped run 5 = C(p-on) + A(n-pwm) - comparator B evaluated
; Out_cB changes from high to low
damped_run5:
	call wait_for_comp_out_high
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait		
	call wait_for_comm
	call comm5comm6
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Damped run 6 = B(p-on) + A(n-pwm) - comparator C evaluated
; Out_cC changes from low to high
damped_run6:
	call wait_for_comp_out_low
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait		
	call wait_for_comm
	call comm6comm1
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

	; Decrement startup rotaton count
	mov	A, Startup_Rot_Cnt
	dec	A
	; Check number of damped rotations
	jz damped_transition			; Branch if counter is zero

	mov	Startup_Rot_Cnt, A			; No - store counter
	clr	C
	mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	subb	A, #RCP_STOP_LIMIT			; Is number of stop RC pulses above limit?
	jnc	($+5)					; Yes, branch

	ljmp	damped_run1				; Continue to run damped

	jmp	run_to_wait_for_power_on


damped_transition:
	; Transition from damped to non-damped
	call	decode_parameters		; Set programmed parameters
	clr	C
	mov	A, Pgm_Pwm_Freq		; Is it damped mode?
	subb	A, #3
	jnc	damped_transition_exit	; Yes - skip transition operations

	All_pFETs_Off 				; Turn off all pfets
	BpFET_on					; Bp on
	mov	A, #45				; 8us delay for pfets to go off
	djnz	ACC, $
	mov	DPTR, #pwm_cfet_on		; Set DPTR register to desired pwm_nfet_on label		
damped_transition_exit:
	setb	EA					; Enable interrupts
	mov	Adc_Conversion_Cnt, #0	; Make sure a voltage reading is done next time
	Set_Adc_Ip_Volt			; Set adc measurement to voltage

; Run 1 = B(p-on) + C(n-pwm) - comparator A evaluated
; Out_cA changes from high to low
run1:
	call wait_for_comp_out_high	; Wait zero cross wait and wait for high
	jb	Flags0.T3_PENDING, ($+6)	; Has timeout elapsed?
	ljmp	run_to_wait_for_power_on	; Yes - exit run mode

	call setup_comm_wait		; Setup wait time from zero cross to commutation
	call calc_governor_target	; Calculate governor target
	call wait_for_comm			; Wait from zero cross to commutation
	call comm1comm2			; Commutate
	call calc_next_comm_timing	; Calculate next timing and start advance timing wait
	call wait_advance_timing		; Wait advance timing and start zero cross wait
	call calc_new_wait_times
	call wait_before_zc_scan		; Wait zero cross wait and start zero cross timeout

; Run 2 = A(p-on) + C(n-pwm) - comparator B evaluated
; Out_cB changes from low to high
run2:
	call wait_for_comp_out_low
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait	
	call calc_governor_prop_error
	call wait_for_comm
	call comm2comm3
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Run 3 = A(p-on) + B(n-pwm) - comparator C evaluated
; Out_cC changes from high to low
run3:
	call wait_for_comp_out_high
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait	
	call calc_governor_int_error
	call wait_for_comm
	call comm3comm4
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Run 4 = C(p-on) + B(n-pwm) - comparator A evaluated
; Out_cA changes from low to high
run4:
	call wait_for_comp_out_low
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait	
	call calc_governor_prop_correction
	call wait_for_comm
	call comm4comm5
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Run 5 = C(p-on) + A(n-pwm) - comparator B evaluated
; Out_cB changes from high to low
run5:
	call wait_for_comp_out_high
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait	
	call calc_governor_int_correction
	call wait_for_comm
	call comm5comm6
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Run 6 = B(p-on) + A(n-pwm) - comparator C evaluated
; Out_cC changes from low to high
run6:
	call wait_for_comp_out_low
	call start_adc_conversion
	jb	Flags0.T3_PENDING, ($+6)
	ljmp	run_to_wait_for_power_on

	call setup_comm_wait	
	call check_temp_voltage_compensate_and_limit_power
	call wait_for_comm
	call comm6comm1
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

	jnb	Flags0.INITIAL_RUN_MODE, initial_run_mode_done; If not initial run mode - branch

IF MODE == 0
	mov	Pwm_Limit_Spoolup, Pwm_Spoolup_Beg	; Set initial slow spoolup power
	mov	Pwm_Limit, Pwm_Spoolup_Beg
ENDIF
IF MODE == 1
	mov	Pwm_Limit_Spoolup, #0FFh			; Allow full power
ENDIF
IF MODE == 2
	mov	Pwm_Limit_Spoolup, Pwm_Spoolup_Beg	; Set initial slow spoolup power
	mov	Pwm_Limit, Pwm_Spoolup_Beg
ENDIF

initial_run_mode_done:
	clr	Flags0.INITIAL_RUN_MODE		; Clear initial run mode flag

	clr	C
	mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	subb	A, #RCP_STOP_LIMIT			; Is number of stop RC pulses above limit?
	jnc	run_to_wait_for_power_on		; Yes, go back to wait for poweron

	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2					; Check pwm frequency flags
	jnz	run6_check_speed			; If a flag is set (PWM) - branch

	mov	A, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	jz	run_to_wait_for_power_on		; If it is zero - go back to wait for poweron

run6_check_speed:
	clr	C
	mov	A, Comm_Period4x_H			; Is Comm_Period4x more than 32ms (~1220 eRPM)?
	subb	A, #0F0h
	jnc	run_to_wait_for_power_on		; Yes - go back to motor start
	jmp	run1						; Go back to run 1

run_to_wait_for_power_on:	
	call switch_power_off
	mov	Temp1, Pgm_Pwm_Freq		; Store settings
	mov	Pgm_Pwm_Freq, #2		; Set low pwm mode (in order to turn off damping)
	call	decode_parameters
	mov	Pgm_Pwm_Freq, Temp1		; Restore settings
	clr	A
	mov	Requested_Pwm, A		; Set requested pwm to zero
	mov	Governor_Req_Pwm, A		; Set governor requested pwm to zero
	mov	Current_Pwm, A			; Set current pwm to zero
	mov	Current_Pwm_Comp, A		; Set compensated current pwm to zero
	mov	Current_Pwm_Limited, A	; Set limited current pwm to zero
	mov	Pwm_Spoolup_Beg, A		; Set spoolup beginning pwm to zero
	mov	Pwm_Motor_Idle, A		; Set motor idle to zero
IF MODE == 0	; Main
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2				; Check pwm frequency flags
	jnz	run_to_next_state_main	; If a flag is set (PWM) - branch

	mov	A, Rcp_Timeout_Cnt		; Load RC pulse timeout counter value
	jnz	run_to_next_state_main	; If it is not zero - branch

	jmp	measure_pwm_freq_init	; If it is zero (pulses missing) - go back to measure pwm frequency

run_to_next_state_main:
	call	wait1s				; 3 seconds delay before new startup
	call	wait1s
	call	wait1s
	mov 	A, Pgm_Main_Rearm_Start
	clr	C
	subb	A, #1				; Is re-armed start enabled?
	jc 	jmp_wait_for_power_on	; No - do like tail and start immediately

	jmp	validate_rcp_start		; Yes - go back to validate RC pulse

jmp_wait_for_power_on:
	jmp	wait_for_power_on		; Go back to wait for power on
ENDIF
IF MODE == 1	; Tail
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2				; Check pwm frequency flags
	jnz	jmp_wait_for_power_on	; If a flag is set (PWM) - branch

	mov	A, Rcp_Timeout_Cnt		; Load RC pulse timeout counter value
	jnz	jmp_wait_for_power_on	; If it is not zero - go back to wait for poweron

	jmp	measure_pwm_freq_init	; If it is zero (pulses missing) - go back to measure pwm frequency

jmp_wait_for_power_on:
	jmp	wait_for_power_on		; Go back to wait for power on
ENDIF
IF MODE == 2	; Multi
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	anl	A, Flags2				; Check pwm frequency flags
	jnz	check_startup_failure	; If a flag is set (PWM) - branch

	mov	A, Rcp_Timeout_Cnt		; Load RC pulse timeout counter value
	jnz	check_startup_failure	; If it is not zero - branch

	jmp	measure_pwm_freq_init	; If it is zero (pulses missing) - go back to measure pwm frequency

check_startup_failure:
	; Check if it was a startup failure
	mov	A, #((1 SHL SETTLE_MODE)+(1 SHL STEPPER_MODE)+(1 SHL AQUISITION_MODE)+(1 SHL INITIAL_RUN_MODE))
	anl	A, Flags0				; Check startup flags
	jz	jmp_wait_for_power_on	; If no flag is set (not a startup failure) - branch

	; Increment startup try number variable
	inc	Startup_Try_No
	clr	C
	mov	A, Startup_Try_No		; Check startup try
	subb	A, #3	
	jc	nominal_startup_power	; If it has not reached end of nominal - branch

	clr	C
	mov	A, Startup_Try_No		; Check startup try
	subb	A, #8	
	jc	incremental_startup_power; If it has not reached max - branch

	mov	Startup_Try_No, #0		; Reset startup try
	mov	Curr_Startup_Pwr, Pgm_Startup_Pwr
	call	wait200ms				; Delay before new startup
	call	wait200ms				
	call	wait100ms				
	jmp	wait_for_power_on		; Go back to wait for power on

nominal_startup_power:
	mov	Curr_Startup_Pwr, Pgm_Startup_Pwr
	jmp	wait_for_power_on		; Go back to wait for power on

incremental_startup_power:
	mov	Curr_Startup_Pwr, Startup_Try_No
	clr	C
	mov	A, Curr_Startup_Pwr		; Calculate startup power from startup try
	subb	A, #2
	mov	Curr_Startup_Pwr, A
	jmp	wait_for_power_on		; Go back to wait for power on

jmp_wait_for_power_on:
	mov	Startup_Try_No, #0		; Reset startup try
	jmp	wait_for_power_on		; Go back to wait for power on
ENDIF



END