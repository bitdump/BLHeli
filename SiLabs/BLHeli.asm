$NOMOD51
;**** **** **** **** ****
;
; BLHeli program for controlling brushless motors in helicopters and multirotors
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
; The software was initially designed for use with Eflite mCP X, but is now adapted to copters/planes in general
;
; The software was inspired by and started from from Bernard Konze's BLMC: http://home.versanet.de/~bkonze/blc_6a/blc_6a.htm
; And also Simon Kirby's TGY: https://github.com/sim-/tgy
;
; This file is best viewed with tab width set to 5
;
; The input signal can be positive 1kHz, 2kHz, 4kHz, 8kHz or 12kHz PWM (e.g. taken from the "resistor tap" on mCPx)
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
; - Rev6.1: Added input signal qualification criteria for PPM, to avoid triggering on noise spikes (fix for plush hardware)
;           Changed main and multi mode stop criteria. Will now be in run mode, even if RC pulse input is zero
;           Fixed bug in commutation that caused rough running in damped light mode
;           Miscellaneous other changes
; - Rev7.0  Added direct startup mode programmability
;           Added throttle calibration. Min>=1000us and Max<=2000us. Difference must be >520us, otherwise max is shifted so that difference=520us
;           Added programmable throttle change rate
;           Added programmable beep strength, beacon strength and beacon delay
;           Reduced power step to full power significantly
;           Miscellaneous other changes
; - Rev8.0  Added a 2 second delay after power up, to wait for receiver initialization
;           Added a programming option for disabling low voltage limit, and made it default for MULTI
;           Added programable demag compensation, using the concept of SimonK
;           Improved robustness against noisy input signal
;           Refined direct startup
;           Removed voltage compensation
;           Miscellaneous other changes
; - Rev9.0  Increased programming range for startup power, and made its default ESC dependent
;           Made default startup method ESC dependent
;           Even more smooth and gentle spoolup for MAIN, to suit larger helis
;           Improved transition from stepped startup to run
;           Refined direct startup
; - Rev9.1  Fixed bug that changed FW revision after throttle calibration or TX programming
; - Rev9.2  Altered timing of throttle calibration in order to work with MultiWii calibration firmware
;           Reduced main spoolup time to around 5 seconds
;           Changed default beacon delay to 3 minutes
; - Rev9.3  Fixed bug in Plush 60/80A temperature reading, that caused failure in operation above 4S
;           Corrected temperature limit for HiModel cool 22/33/41A, RCTimer 6A, Skywalker 20/40A, Turnigy AE45A, Plush 40/60/80A. Limit was previously set too high
; - Rev9.4  Improved timing for increased maximum rpm limit
; - Rev10.0 Added closed loop mode for multi
;           Added high/low BEC voltage option (for the ESCs where HW supports it)
;           Added method of resetting all programmed parameter values to defaults by TX programming
;           Added Turnigy K-force 40A and Turnigy K-force 120A HV ESCs
;           Enabled fully damped mode for several ESCs
;           Extended startup power range downwards to enable very smooth start for large heli main motors
;           Extended damping force with a highest setting
;           Corrected temperature limits for F310 chips (Plush 40A and AE 45A)
;           Implemented temperature reading average in order to avoid problems with ADC noise on Skywalkers
;           Increased switching delays for XP 7A fast, in order to avoid cross conduction of N and P fets
;           Miscellaneous other changes
; - Rev10.1 Relaxed RC signal jitter requirement during frequency measurement
;           Corrected bug that prevented using governor low
;           Enabled vdd monitor always, in order to reduce likelihood of accidental overwriting of adjustments
;           Fixed bug that caused stop for PPM input above 2048us, and moved upper accepted limit to 2160us
; - Rev10.2 Corrected temperature limit for AE20-30/XP7-25, where limit was too high
;           Corrected temperature limit for 120HV, where limit was too low
;           Fixed bug that caused AE20/25/30A not to run in reverse
; - Rev10.3 Removed vdd monitor for 1S capable ESCs, in order to avoid brownouts/resets
;           Made auto bailout spoolup for main more smooth
; - Rev10.4 Ensured that main spoolup and governor activation will always be smooth, regardless of throttle input
;           Added capability to operate on 12kHz input signal too
;
;
;**** **** **** **** ****
; Up to 8K Bytes of In-System Self-Programmable Flash
; 768 Bytes Internal SRAM
;
;**** **** **** **** ****
; Master clock is internal 24MHz oscillator
; Timer 0 (167/500ns counts) always counts up and is used for
; - PWM generation
; Timer 1 (167/500ns counts) always counts up and is not used
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
; - Brushless motor control with 6 states for each electrical 360 degrees
; - An advance timing of 0deg has zero cross 30deg after one commutation and 30deg before the next
; - Timing advance in this implementation is set to 15deg nominally
; - "Damped" commutation schemes are available, where more than one pfet is on when pwm is off. This will absorb energy from bemf and make step settling more damped.
; Motor sequence starting from zero crossing:
; - Timer wait: Wt_Comm			15deg	; Time to wait from zero cross to actual commutation
; - Timer wait: Wt_Advance		15deg	; Time to wait for timing advance. Nominal commutation point is after this
; - Timer wait: Wt_Zc_Scan		7.5deg	; Time to wait before looking for zero cross
; - Scan for zero cross			22.5deg	, Nominal, with some motor variations
;
; Motor startup in stepper mode:
; Initial motor rotations are done with the motor controlled as a stepper motor.
; In this stepper motor mode comparator information is not used.
; Settle phase is the first, where there are a few commutations with increasing step length, in order to settle the motor in a predefined position.
; Stepper phase comes next, where there is a step length decrease sequence.
; Direct startup is the last phase, for synchronization before normal bemf commutation run begins.
; Motor startup in direct mode:
; Direct startup is the only phase, before normal bemf commutation run begins.
;
;**** **** **** **** ****
; List of enumerated supported ESCs and modes  (main, tail or multi)
XP_3A_Main 					EQU 1
XP_3A_Tail 					EQU 2
XP_3A_Multi 					EQU 3
XP_7A_Main 					EQU 4
XP_7A_Tail 					EQU 5
XP_7A_Multi 					EQU 6
XP_7A_Fast_Main 				EQU 7
XP_7A_Fast_Tail 				EQU 8
XP_7A_Fast_Multi 				EQU 9
XP_12A_Main 					EQU 10
XP_12A_Tail 					EQU 11
XP_12A_Multi 					EQU 12
XP_18A_Main 					EQU 13
XP_18A_Tail 					EQU 14
XP_18A_Multi 					EQU 15
XP_25A_Main 					EQU 16
XP_25A_Tail 					EQU 17
XP_25A_Multi 					EQU 18
DP_3A_Main 					EQU 19
DP_3A_Tail  					EQU 20
DP_3A_Multi  					EQU 21
Supermicro_3p5A_Main 			EQU 22
Supermicro_3p5A_Tail 			EQU 23   
Supermicro_3p5A_Multi 			EQU 24   
Turnigy_Plush_6A_Main 			EQU 25
Turnigy_Plush_6A_Tail 			EQU 26   
Turnigy_Plush_6A_Multi 			EQU 27   
Turnigy_Plush_10A_Main 			EQU 28
Turnigy_Plush_10A_Tail 			EQU 29   
Turnigy_Plush_10A_Multi 			EQU 30   
Turnigy_Plush_12A_Main 			EQU 31
Turnigy_Plush_12A_Tail 			EQU 32   
Turnigy_Plush_12A_Multi 			EQU 33   
Turnigy_Plush_18A_Main 			EQU 34
Turnigy_Plush_18A_Tail 			EQU 35   
Turnigy_Plush_18A_Multi 			EQU 36   
Turnigy_Plush_25A_Main 			EQU 37
Turnigy_Plush_25A_Tail 			EQU 38   
Turnigy_Plush_25A_Multi 			EQU 39   
Turnigy_Plush_30A_Main 			EQU 40
Turnigy_Plush_30A_Tail 			EQU 41   
Turnigy_Plush_30A_Multi 			EQU 42   
Turnigy_Plush_40A_Main 			EQU 43
Turnigy_Plush_40A_Tail 			EQU 44   
Turnigy_Plush_40A_Multi 			EQU 45   
Turnigy_Plush_60A_Main 			EQU 46
Turnigy_Plush_60A_Tail 			EQU 47   
Turnigy_Plush_60A_Multi 			EQU 48   
Turnigy_Plush_80A_Main 			EQU 49
Turnigy_Plush_80A_Tail 			EQU 50   
Turnigy_Plush_80A_Multi 			EQU 51   
Turnigy_AE_20A_Main 			EQU 52
Turnigy_AE_20A_Tail 			EQU 53   
Turnigy_AE_20A_Multi 			EQU 54   
Turnigy_AE_25A_Main 			EQU 55
Turnigy_AE_25A_Tail 			EQU 56   
Turnigy_AE_25A_Multi 			EQU 57   
Turnigy_AE_30A_Main 			EQU 58
Turnigy_AE_30A_Tail 			EQU 59   
Turnigy_AE_30A_Multi 			EQU 60   
Turnigy_AE_45A_Main 			EQU 61
Turnigy_AE_45A_Tail 			EQU 62   
Turnigy_AE_45A_Multi 			EQU 63   
Turnigy_KForce_40A_Main 			EQU 64   
Turnigy_KForce_40A_Tail 			EQU 65   
Turnigy_KForce_40A_Multi 		EQU 66   
Turnigy_KForce_120A_HV_Main 		EQU 67   
Turnigy_KForce_120A_HV_Tail 		EQU 68   
Turnigy_KForce_120A_HV_Multi 		EQU 69   
Turnigy_KForce_120A_HV_v2_Main	EQU 70   
Turnigy_KForce_120A_HV_v2_Tail 	EQU 71   
Turnigy_KForce_120A_HV_v2_Multi 	EQU 72   
Skywalker_20A_Main 				EQU 73
Skywalker_20A_Tail 				EQU 74   
Skywalker_20A_Multi 			EQU 75   
Skywalker_40A_Main 				EQU 76
Skywalker_40A_Tail 				EQU 77   
Skywalker_40A_Multi 			EQU 78   
HiModel_Cool_22A_Main 			EQU 79
HiModel_Cool_22A_Tail 			EQU 80   
HiModel_Cool_22A_Multi 			EQU 81   
HiModel_Cool_33A_Main 			EQU 82
HiModel_Cool_33A_Tail 			EQU 83   
HiModel_Cool_33A_Multi 			EQU 84   
HiModel_Cool_41A_Main 			EQU 85
HiModel_Cool_41A_Tail 			EQU 86   
HiModel_Cool_41A_Multi 			EQU 87   
RCTimer_6A_Main 				EQU 88   
RCTimer_6A_Tail 				EQU 89   
RCTimer_6A_Multi 				EQU 90   
Align_RCE_BL15X_Main			EQU 91   
Align_RCE_BL15X_Tail 			EQU 92   
Align_RCE_BL15X_Multi 			EQU 93   
Align_RCE_BL15P_Main			EQU 94   
Align_RCE_BL15P_Tail 			EQU 95   
Align_RCE_BL15P_Multi 			EQU 96   
Align_RCE_BL35X_Main			EQU 97   
Align_RCE_BL35X_Tail 			EQU 98   
Align_RCE_BL35X_Multi 			EQU 99   
Align_RCE_BL35P_Main			EQU 100   
Align_RCE_BL35P_Tail 			EQU 101  
Align_RCE_BL35P_Multi 			EQU 102  
Gaui_GE_183_18A_Main			EQU 103   
Gaui_GE_183_18A_Tail 			EQU 104  
Gaui_GE_183_18A_Multi 			EQU 105  
H_King_10A_Main				EQU 106   
H_King_10A_Tail 				EQU 107  
H_King_10A_Multi 				EQU 108  
H_King_20A_Main				EQU 109   
H_King_20A_Tail 				EQU 110  
H_King_20A_Multi 				EQU 111  
H_King_35A_Main				EQU 112   
H_King_35A_Tail 				EQU 113 
H_King_35A_Multi 				EQU 114  
H_King_50A_Main				EQU 115   
H_King_50A_Tail 				EQU 116  
H_King_50A_Multi 				EQU 117  
Polaris_Thunder_12A_Main			EQU 118   
Polaris_Thunder_12A_Tail 		EQU 119  
Polaris_Thunder_12A_Multi 		EQU 120  
Polaris_Thunder_20A_Main			EQU 121   
Polaris_Thunder_20A_Tail 		EQU 122  
Polaris_Thunder_20A_Multi 		EQU 123  
Polaris_Thunder_30A_Main			EQU 124   
Polaris_Thunder_30A_Tail 		EQU 125  
Polaris_Thunder_30A_Multi 		EQU 126  
Polaris_Thunder_40A_Main			EQU 127   
Polaris_Thunder_40A_Tail 		EQU 128  
Polaris_Thunder_40A_Multi 		EQU 129  
Polaris_Thunder_60A_Main			EQU 130   
Polaris_Thunder_60A_Tail 		EQU 131  
Polaris_Thunder_60A_Multi 		EQU 132  
Polaris_Thunder_80A_Main			EQU 133   
Polaris_Thunder_80A_Tail 		EQU 134  
Polaris_Thunder_80A_Multi 		EQU 135  
Polaris_Thunder_100A_Main		EQU 136   
Polaris_Thunder_100A_Tail 		EQU 137  
Polaris_Thunder_100A_Multi 		EQU 138  
Platinum_Pro_30A_Main			EQU 139   
Platinum_Pro_30A_Tail 			EQU 140  
Platinum_Pro_30A_Multi 			EQU 141  
EAZY_3Av2_Main			EQU 142   
EAZY_3Av2_Tail 			EQU 143  
EAZY_3Av2_Multi 			EQU 144  

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
;BESC EQU Turnigy_Plush_40A_Main
;BESC EQU Turnigy_Plush_40A_Tail 
;BESC EQU Turnigy_Plush_40A_Multi
;BESC EQU Turnigy_Plush_60A_Main
;BESC EQU Turnigy_Plush_60A_Tail 
;BESC EQU Turnigy_Plush_60A_Multi
;BESC EQU Turnigy_Plush_80A_Main
;BESC EQU Turnigy_Plush_80A_Tail 
;BESC EQU Turnigy_Plush_80A_Multi
;BESC EQU Turnigy_AE_20A_Main 
;BESC EQU Turnigy_AE_20A_Tail 
;BESC EQU Turnigy_AE_20A_Multi
;BESC EQU Turnigy_AE_25A_Main 
;BESC EQU Turnigy_AE_25A_Tail 
;BESC EQU Turnigy_AE_25A_Multi
;BESC EQU Turnigy_AE_30A_Main 
;BESC EQU Turnigy_AE_30A_Tail 
;BESC EQU Turnigy_AE_30A_Multi
;BESC EQU Turnigy_AE_45A_Main
;BESC EQU Turnigy_AE_45A_Tail 
;BESC EQU Turnigy_AE_45A_Multi
;BESC EQU Turnigy_KForce_40A_Main
;BESC EQU Turnigy_KForce_40A_Tail 
;BESC EQU Turnigy_KForce_40A_Multi
;BESC EQU Turnigy_KForce_120A_HV_Main
;BESC EQU Turnigy_KForce_120A_HV_Tail 
;BESC EQU Turnigy_KForce_120A_HV_Multi
;BESC EQU Turnigy_KForce_120A_HV_v2_Main
;BESC EQU Turnigy_KForce_120A_HV_v2_Tail 
;BESC EQU Turnigy_KForce_120A_HV_v2_Multi
;BESC EQU Skywalker_20A_Main
;BESC EQU Skywalker_20A_Tail 
;BESC EQU Skywalker_20A_Multi
;BESC EQU Skywalker_40A_Main 
;BESC EQU Skywalker_40A_Tail 
;BESC EQU Skywalker_40A_Multi
;BESC EQU HiModel_Cool_22A_Main
;BESC EQU HiModel_Cool_22A_Tail
;BESC EQU HiModel_Cool_22A_Multi
;BESC EQU HiModel_Cool_33A_Main
;BESC EQU HiModel_Cool_33A_Tail
;BESC EQU HiModel_Cool_33A_Multi
;BESC EQU HiModel_Cool_41A_Main
;BESC EQU HiModel_Cool_41A_Tail
;BESC EQU HiModel_Cool_41A_Multi
;BESC EQU RCTimer_6A_Main
;BESC EQU RCTimer_6A_Tail
;BESC EQU RCTimer_6A_Multi
;BESC EQU Align_RCE_BL15X_Main 
;BESC EQU Align_RCE_BL15X_Tail
;BESC EQU Align_RCE_BL15X_Multi
;BESC EQU Align_RCE_BL15P_Main
;BESC EQU Align_RCE_BL15P_Tail
;BESC EQU Align_RCE_BL15P_Multi
;BESC EQU Align_RCE_BL35X_Main 
;BESC EQU Align_RCE_BL35X_Tail
;BESC EQU Align_RCE_BL35X_Multi
;BESC EQU Align_RCE_BL35P_Main
;BESC EQU Align_RCE_BL35P_Tail
;BESC EQU Align_RCE_BL35P_Multi
;BESC EQU Gaui_GE_183_18A_Main
;BESC EQU Gaui_GE_183_18A_Tail
;BESC EQU Gaui_GE_183_18A_Multi
;BESC EQU H_King_10A_Main
;BESC EQU H_King_10A_Tail
;BESC EQU H_King_10A_Multi
;BESC EQU H_King_20A_Main
;BESC EQU H_King_20A_Tail
;BESC EQU H_King_20A_Multi
;BESC EQU H_King_35A_Main
;BESC EQU H_King_35A_Tail
;BESC EQU H_King_35A_Multi
;BESC EQU H_King_50A_Main
;BESC EQU H_King_50A_Tail
;BESC EQU H_King_50A_Multi
;BESC EQU Polaris_Thunder_12A_Main
;BESC EQU Polaris_Thunder_12A_Tail
;BESC EQU Polaris_Thunder_12A_Multi
;BESC EQU Polaris_Thunder_20A_Main
;BESC EQU Polaris_Thunder_20A_Tail
;BESC EQU Polaris_Thunder_20A_Multi
;BESC EQU Polaris_Thunder_30A_Main
;BESC EQU Polaris_Thunder_30A_Tail
;BESC EQU Polaris_Thunder_30A_Multi
;BESC EQU Polaris_Thunder_40A_Main
;BESC EQU Polaris_Thunder_40A_Tail
;BESC EQU Polaris_Thunder_40A_Multi
;BESC EQU Polaris_Thunder_60A_Main
;BESC EQU Polaris_Thunder_60A_Tail
;BESC EQU Polaris_Thunder_60A_Multi
;BESC EQU Polaris_Thunder_80A_Main
;BESC EQU Polaris_Thunder_80A_Tail
;BESC EQU Polaris_Thunder_80A_Multi
;BESC EQU Polaris_Thunder_100A_Main
;BESC EQU Polaris_Thunder_100A_Tail
;BESC EQU Polaris_Thunder_100A_Multi
;BESC EQU Platinum_Pro_30A_Main
;BESC EQU Platinum_Pro_30A_Tail
;BESC EQU Platinum_Pro_30A_Multi
;BESC EQU EAZY_3Av2_Main
;BESC EQU EAZY_3Av2_Tail
;BESC EQU EAZY_3Av2_Multi


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

IF BESC == Turnigy_Plush_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_40A.inc)	; Select Turnigy Plush 40A pinout
ENDIF

IF BESC == Turnigy_Plush_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_40A.inc)	; Select Turnigy Plush 40A pinout
ENDIF

IF BESC == Turnigy_Plush_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_40A.inc)	; Select Turnigy Plush 40A pinout
ENDIF

IF BESC == Turnigy_Plush_60A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_60A.inc)	; Select Turnigy Plush 60A pinout
ENDIF

IF BESC == Turnigy_Plush_60A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_60A.inc)	; Select Turnigy Plush 60A pinout
ENDIF

IF BESC == Turnigy_Plush_60A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_60A.inc)	; Select Turnigy Plush 60A pinout
ENDIF

IF BESC == Turnigy_Plush_80A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_80A.inc)	; Select Turnigy Plush 80A pinout
ENDIF

IF BESC == Turnigy_Plush_80A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_80A.inc)	; Select Turnigy Plush 80A pinout
ENDIF

IF BESC == Turnigy_Plush_80A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_80A.inc)	; Select Turnigy Plush 80A pinout
ENDIF

IF BESC == Turnigy_AE_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_AE_20A.inc)		; Select Turnigy AE-20A pinout
ENDIF

IF BESC == Turnigy_AE_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_AE_20A.inc)		; Select Turnigy AE-20A pinout
ENDIF

IF BESC == Turnigy_AE_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_AE_20A.inc)		; Select Turnigy AE-20A pinout
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

IF BESC == Turnigy_AE_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_AE_30A.inc)		; Select Turnigy AE-30A pinout
ENDIF

IF BESC == Turnigy_AE_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_AE_30A.inc)		; Select Turnigy AE-30A pinout
ENDIF

IF BESC == Turnigy_AE_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_AE_30A.inc)		; Select Turnigy AE-30A pinout
ENDIF

IF BESC == Turnigy_AE_45A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_AE_45A.inc)		; Select Turnigy AE-45A pinout
ENDIF

IF BESC == Turnigy_AE_45A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_AE_45A.inc)		; Select Turnigy AE-45A pinout
ENDIF

IF BESC == Turnigy_AE_45A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_AE_45A.inc)		; Select Turnigy AE-45A pinout
ENDIF

IF BESC == Turnigy_KForce_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_KForce_40A.inc)	; Select Turnigy KForce 40A pinout
ENDIF

IF BESC == Turnigy_KForce_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_KForce_40A.inc)	; Select Turnigy KForce 40A pinout
ENDIF

IF BESC == Turnigy_KForce_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_KForce_40A.inc)	; Select Turnigy KForce 40A pinout
ENDIF

IF BESC == Turnigy_KForce_120A_HV_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_KForce_120A_HV.inc)	; Select Turnigy KForce 120A HV pinout
ENDIF

IF BESC == Turnigy_KForce_120A_HV_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_KForce_120A_HV.inc)	; Select Turnigy KForce 120A HV pinout
ENDIF

IF BESC == Turnigy_KForce_120A_HV_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_KForce_120A_HV.inc)	; Select Turnigy KForce 120A HV pinout
ENDIF

IF BESC == Turnigy_KForce_120A_HV_v2_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_KForce_120A_HV_v2.inc); Select Turnigy KForce 120A HV v2 pinout
ENDIF

IF BESC == Turnigy_KForce_120A_HV_v2_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_KForce_120A_HV_v2.inc); Select Turnigy KForce 120A HV v2 pinout
ENDIF

IF BESC == Turnigy_KForce_120A_HV_v2_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_KForce_120A_HV_v2.inc); Select Turnigy KForce 120A HV v2 pinout
ENDIF

IF BESC == Skywalker_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Skywalker_20A.inc)		; Select Skywalker 20A pinout
ENDIF

IF BESC == Skywalker_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Skywalker_20A.inc)		; Select Skywalker 20A pinout
ENDIF

IF BESC == Skywalker_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Skywalker_20A.inc)		; Select Skywalker 20A pinout
ENDIF

IF BESC == Skywalker_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Skywalker_40A.inc)		; Select Skywalker 40A pinout
ENDIF

IF BESC == Skywalker_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Skywalker_40A.inc)		; Select Skywalker 40A pinout
ENDIF

IF BESC == Skywalker_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Skywalker_40A.inc)		; Select Skywalker 40A pinout
ENDIF

IF BESC == HiModel_Cool_22A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (HiModel_Cool_22A.inc)	; Select HiModel Cool 22A pinout
ENDIF

IF BESC == HiModel_Cool_22A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (HiModel_Cool_22A.inc)	; Select HiModel Cool 22A pinout
ENDIF

IF BESC == HiModel_Cool_22A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (HiModel_Cool_22A.inc)	; Select HiModel Cool 22A pinout
ENDIF

IF BESC == HiModel_Cool_33A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (HiModel_Cool_33A.inc)	; Select HiModel Cool 33A pinout
ENDIF

IF BESC == HiModel_Cool_33A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (HiModel_Cool_33A.inc)	; Select HiModel Cool 33A pinout
ENDIF

IF BESC == HiModel_Cool_33A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (HiModel_Cool_33A.inc)	; Select HiModel Cool 33A pinout
ENDIF

IF BESC == HiModel_Cool_41A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (HiModel_Cool_41A.inc)	; Select HiModel Cool 41A pinout
ENDIF

IF BESC == HiModel_Cool_41A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (HiModel_Cool_41A.inc)	; Select HiModel Cool 41A pinout
ENDIF

IF BESC == HiModel_Cool_41A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (HiModel_Cool_41A.inc)	; Select HiModel Cool 41A pinout
ENDIF

IF BESC == RCTimer_6A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (RCTimer_6A.inc)		; Select RC Timer 6A pinout
ENDIF

IF BESC == RCTimer_6A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (RCTimer_6A.inc)		; Select RC Timer 6A pinout
ENDIF

IF BESC == RCTimer_6A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (RCTimer_6A.inc)		; Select RC Timer 6A pinout
ENDIF

IF BESC == Align_RCE_BL15X_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Align_RCE_BL15X.inc)	; Select Align RCE-BL15X pinout
ENDIF

IF BESC == Align_RCE_BL15X_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Align_RCE_BL15X.inc)	; Select Align RCE-BL15X pinout
ENDIF

IF BESC == Align_RCE_BL15X_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Align_RCE_BL15X.inc)	; Select Align RCE-BL15X pinout
ENDIF

IF BESC == Align_RCE_BL15P_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Align_RCE_BL15P.inc)	; Select Align RCE-BL15P pinout
ENDIF

IF BESC == Align_RCE_BL15P_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Align_RCE_BL15P.inc)	; Select Align RCE-BL15P pinout
ENDIF

IF BESC == Align_RCE_BL15P_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Align_RCE_BL15P.inc)	; Select Align RCE-BL15P pinout
ENDIF

IF BESC == Align_RCE_BL35X_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Align_RCE_BL35X.inc)	; Select Align RCE-BL35X pinout
ENDIF

IF BESC == Align_RCE_BL35X_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Align_RCE_BL35X.inc)	; Select Align RCE-BL35X pinout
ENDIF

IF BESC == Align_RCE_BL35X_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Align_RCE_BL35X.inc)	; Select Align RCE-BL35X pinout
ENDIF

IF BESC == Align_RCE_BL35P_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Align_RCE_BL35P.inc)	; Select Align RCE-BL35P pinout
ENDIF

IF BESC == Align_RCE_BL35P_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Align_RCE_BL35P.inc)	; Select Align RCE-BL35P pinout
ENDIF

IF BESC == Align_RCE_BL35P_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Align_RCE_BL35P.inc)	; Select Align RCE-BL35P pinout
ENDIF

IF BESC == Gaui_GE_183_18A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Gaui_GE_183_18A.inc)	; Select Gaui GE-183 18A pinout
ENDIF

IF BESC == Gaui_GE_183_18A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Gaui_GE_183_18A.inc)	; Select Gaui GE-183 18A pinout
ENDIF

IF BESC == Gaui_GE_183_18A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Gaui_GE_183_18A.inc)	; Select Gaui GE-183 18A pinout
ENDIF

IF BESC == H_King_10A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (H_King_10A.inc)		; Select H-King 10A pinout
ENDIF

IF BESC == H_King_10A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (H_King_10A.inc)		; Select H-King 10A pinout
ENDIF

IF BESC == H_King_10A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (H_King_10A.inc)		; Select H-King 10A pinout
ENDIF

IF BESC == H_King_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (H_King_20A.inc)		; Select H-King 20A pinout
ENDIF

IF BESC == H_King_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (H_King_20A.inc)		; Select H-King 20A pinout
ENDIF

IF BESC == H_King_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (H_King_20A.inc)		; Select H-King 20A pinout
ENDIF

IF BESC == H_King_35A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (H_King_35A.inc)		; Select H-King 35A pinout
ENDIF

IF BESC == H_King_35A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (H_King_35A.inc)		; Select H-King 35A pinout
ENDIF

IF BESC == H_King_35A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (H_King_35A.inc)		; Select H-King 35A pinout
ENDIF

IF BESC == H_King_50A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (H_King_50A.inc)		; Select H-King 50A pinout
ENDIF

IF BESC == H_King_50A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (H_King_50A.inc)		; Select H-King 50A pinout
ENDIF

IF BESC == H_King_50A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (H_King_50A.inc)		; Select H-King 50A pinout
ENDIF

IF BESC == Polaris_Thunder_12A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_12A.inc)	; Select Polaris Thunder 12A pinout
ENDIF

IF BESC == Polaris_Thunder_12A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_12A.inc)	; Select Polaris Thunder 12A pinout
ENDIF

IF BESC == Polaris_Thunder_12A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_12A.inc)	; Select Polaris Thunder 12A pinout
ENDIF

IF BESC == Polaris_Thunder_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_20A.inc)	; Select Polaris Thunder 20A pinout
ENDIF

IF BESC == Polaris_Thunder_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_20A.inc)	; Select Polaris Thunder 20A pinout
ENDIF

IF BESC == Polaris_Thunder_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_20A.inc)	; Select Polaris Thunder 20A pinout
ENDIF

IF BESC == Polaris_Thunder_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_30A.inc)	; Select Polaris Thunder 30A pinout
ENDIF

IF BESC == Polaris_Thunder_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_30A.inc)	; Select Polaris Thunder 30A pinout
ENDIF

IF BESC == Polaris_Thunder_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_30A.inc)	; Select Polaris Thunder 30A pinout
ENDIF

IF BESC == Polaris_Thunder_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_40A.inc)	; Select Polaris Thunder 40A pinout
ENDIF

IF BESC == Polaris_Thunder_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_40A.inc)	; Select Polaris Thunder 40A pinout
ENDIF

IF BESC == Polaris_Thunder_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_40A.inc)	; Select Polaris Thunder 40A pinout
ENDIF

IF BESC == Polaris_Thunder_60A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_60A.inc)	; Select Polaris Thunder 60A pinout
ENDIF

IF BESC == Polaris_Thunder_60A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_60A.inc)	; Select Polaris Thunder 60A pinout
ENDIF

IF BESC == Polaris_Thunder_60A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_60A.inc)	; Select Polaris Thunder 60A pinout
ENDIF

IF BESC == Polaris_Thunder_80A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_80A.inc)	; Select Polaris Thunder 80A pinout
ENDIF

IF BESC == Polaris_Thunder_80A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_80A.inc)	; Select Polaris Thunder 80A pinout
ENDIF

IF BESC == Polaris_Thunder_80A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_80A.inc)	; Select Polaris Thunder 80A pinout
ENDIF

IF BESC == Polaris_Thunder_100A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_100A.inc); Select Polaris Thunder 100A pinout
ENDIF

IF BESC == Polaris_Thunder_100A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_100A.inc); Select Polaris Thunder 100A pinout
ENDIF

IF BESC == Polaris_Thunder_100A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_100A.inc); Select Polaris Thunder 100A pinout
ENDIF

IF BESC == Platinum_Pro_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Platinum_Pro_30A.inc)	; Select Platinum Pro 30A pinout
ENDIF

IF BESC == Platinum_Pro_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Platinum_Pro_30A.inc)	; Select Platinum Pro 30A pinout
ENDIF

IF BESC == Platinum_Pro_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Platinum_Pro_30A.inc)	; Select Platinum Pro 30A pinout
ENDIF

IF BESC == EAZY_3Av2_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (EAZY_3Av2.inc)	; Select Platinum Pro 30A pinout
ENDIF

IF BESC == EAZY_3Av2_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (EAZY_3Av2.inc)	; Select Platinum Pro 30A pinout
ENDIF

IF BESC == EAZY_3Av2_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (EAZY_3Av2.inc)	; Select Platinum Pro 30A pinout
ENDIF


;**** **** **** **** ****
; TX programming defaults
;
; Parameter dependencies:
; - Governor P gain, I gain and Range is only used if one of the three governor modes is selected
; - Governor setup target is only used if Setup governor mode is selected (or closed loop mode is on for multi)
; - Startup rpm and startup accel is only used if stepped startup method is selected
; - Damping force is only used if DampedLight or Damped is selected
;
; Main
DEFAULT_PGM_MAIN_P_GAIN 			EQU 7 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MAIN_I_GAIN 			EQU 7 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MAIN_GOVERNOR_MODE 	EQU 1 	; 1=Tx 		2=Arm 		3=Setup		4=Off
DEFAULT_PGM_MAIN_GOVERNOR_RANGE 	EQU 1 	; 1=High		2=Low
DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	EQU 4 	; 1=Off		2=3.0V/c		3=3.1V/c		4=3.2V/c		5=3.3V/c	6=3.4V/c
DEFAULT_PGM_MAIN_STARTUP_RPM		EQU 3 	; 1=0.67		2=0.8 		3=1.00 		4=1.25 		5=1.5
DEFAULT_PGM_MAIN_STARTUP_ACCEL	EQU 1 	; 1=0.4 		2=0.7 		3=1.0 		4=1.5 		5=2.3
DEFAULT_PGM_MAIN_COMM_TIMING		EQU 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_MAIN_THROTTLE_RATE	EQU 13	; 1=2		2=3			3=4			4=6 			5=8	 	6=12 	7=16	  8=24  9=32  10=48  11=64  12=128 13=255
DEFAULT_PGM_MAIN_DAMPING_FORCE	EQU 1 	; 1=VeryLow 	2=Low 		3=MediumLow 	4=MediumHigh 	5=High	6=Highest
DEFAULT_PGM_MAIN_PWM_FREQ 		EQU 2 	; 1=High 		2=Low		3=DampedLight
DEFAULT_PGM_MAIN_DEMAG_COMP 		EQU 1 	; 1=Disabled	2=15/0		3=15/7.5		4=7.5/7.5  	5=7.5/15  (degrees blind advance / power off)
DEFAULT_PGM_MAIN_DIRECTION_REV	EQU 1 	; 1=Normal 	2=Reversed
DEFAULT_PGM_MAIN_RCP_PWM_POL 		EQU 1 	; 1=Positive 	2=Negative
DEFAULT_PGM_MAIN_GOV_SETUP_TARGET	EQU 180	; Target for governor in setup mode. Corresponds to 70% throttle
DEFAULT_PGM_MAIN_REARM_START		EQU 0 	; 1=Enabled 	0=Disabled
DEFAULT_PGM_MAIN_BEEP_STRENGTH	EQU 120	; Beep strength
DEFAULT_PGM_MAIN_BEACON_STRENGTH	EQU 200	; Beacon strength
DEFAULT_PGM_MAIN_BEACON_DELAY		EQU 4 	; 1=30s		2=1m			3=2m			4=3m			5=Infinite
; Tail
DEFAULT_PGM_TAIL_GAIN 			EQU 3 	; 1=0.75 		2=0.88 		3=1.00 		4=1.12 		5=1.25
DEFAULT_PGM_TAIL_IDLE_SPEED 		EQU 4 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_TAIL_STARTUP_RPM		EQU 3 	; 1=0.67		2=0.8 		3=1.00 		4=1.25 		5=1.5
DEFAULT_PGM_TAIL_STARTUP_ACCEL	EQU 5 	; 1=0.4 		2=0.7 		3=1.0 		4=1.5 		5=2.3
DEFAULT_PGM_TAIL_COMM_TIMING		EQU 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_TAIL_THROTTLE_RATE	EQU 13	; 1=2		2=3			3=4			4=6 			5=8	 	6=12 	7=16	  8=24  9=32  10=48  11=64  12=128 13=255
DEFAULT_PGM_TAIL_DAMPING_FORCE	EQU 5 	; 1=VeryLow 	2=Low 		3=MediumLow 	4=MediumHigh 	5=High	6=Highest
IF DAMPED_MODE_ENABLE == 1
DEFAULT_PGM_TAIL_PWM_FREQ	 	EQU 4 	; 1=High 		2=Low 		3=DampedLight  4=Damped 	
ELSE
DEFAULT_PGM_TAIL_PWM_FREQ	 	EQU 3 	; 1=High 		2=Low		3=DampedLight
ENDIF
DEFAULT_PGM_TAIL_DEMAG_COMP 		EQU 1 	; 1=Disabled	2=15/0		3=15/7.5		4=7.5/7.5  	5=7.5/15  (degrees blind advance / power off)
DEFAULT_PGM_TAIL_DIRECTION_REV	EQU 1 	; 1=Normal 	2=Reversed
DEFAULT_PGM_TAIL_RCP_PWM_POL 		EQU 1 	; 1=Positive 	2=Negative
DEFAULT_PGM_TAIL_BEEP_STRENGTH	EQU 250	; Beep strength
DEFAULT_PGM_TAIL_BEACON_STRENGTH	EQU 250	; Beacon strength
DEFAULT_PGM_TAIL_BEACON_DELAY		EQU 4 	; 1=30s		2=1m			3=2m			4=3m			5=Infinite
; Multi
DEFAULT_PGM_MULTI_P_GAIN 		EQU 9 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MULTI_I_GAIN 		EQU 9 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MULTI_GOVERNOR_MODE 	EQU 4 	; 1=HiRange	2=MidRange	3=LoRange		4=Off
DEFAULT_PGM_MULTI_GAIN 			EQU 3 	; 1=0.75 		2=0.88 		3=1.00 		4=1.12 		5=1.25
DEFAULT_PGM_MULTI_LOW_VOLTAGE_LIM	EQU 1 	; 1=Off		2=3.0V/c		3=3.1V/c		4=3.2V/c		5=3.3V/c	6=3.4V/c
DEFAULT_PGM_MULTI_STARTUP_RPM		EQU 1 	; 1=0.67		2=0.8 		3=1.00 		4=1.25 		5=1.5
DEFAULT_PGM_MULTI_STARTUP_ACCEL	EQU 5 	; 1=0.4 		2=0.7 		3=1.0 		4=1.5 		5=2.3
DEFAULT_PGM_MULTI_COMM_TIMING		EQU 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_MULTI_THROTTLE_RATE	EQU 13	; 1=2		2=3			3=4			4=6 			5=8	 	6=12 	7=16	  8=24  9=32  10=48  11=64  12=128 13=255
DEFAULT_PGM_MULTI_DAMPING_FORCE	EQU 6 	; 1=VeryLow 	2=Low 		3=MediumLow 	4=MediumHigh 	5=High	6=Highest
IF DAMPED_MODE_ENABLE == 1
DEFAULT_PGM_MULTI_PWM_FREQ	 	EQU 1 	; 1=High 		2=Low 		3=DampedLight  4=Damped 	
ELSE
DEFAULT_PGM_MULTI_PWM_FREQ	 	EQU 1 	; 1=High 		2=Low		3=DampedLight
ENDIF
DEFAULT_PGM_MULTI_DEMAG_COMP 		EQU 2 	; 1=Disabled	2=15/0		3=15/7.5		4=7.5/7.5  	5=7.5/15  (degrees blind advance / power off)
DEFAULT_PGM_MULTI_DIRECTION_REV	EQU 1 	; 1=Normal 	2=Reversed
DEFAULT_PGM_MULTI_RCP_PWM_POL 	EQU 1 	; 1=Positive 	2=Negative
DEFAULT_PGM_MULTI_BEEP_STRENGTH	EQU 40	; Beep strength
DEFAULT_PGM_MULTI_BEACON_STRENGTH	EQU 80	; Beacon strength
DEFAULT_PGM_MULTI_BEACON_DELAY	EQU 4 	; 1=30s		2=1m			3=2m			4=3m			5=Infinite
; Common
DEFAULT_PGM_ENABLE_TX_PROGRAM 	EQU 1 	; 1=Enabled 	0=Disabled
DEFAULT_PGM_PPM_MIN_THROTTLE		EQU 37	; 4*37+1000=1148
DEFAULT_PGM_PPM_MAX_THROTTLE		EQU 208	; 4*208+1000=1832
DEFAULT_PGM_BEC_VOLTAGE_HIGH		EQU 0	; 0=Low		1= High

;**** **** **** **** ****
; Constant definitions for main
IF MODE == 0

GOV_SPOOLRATE		EQU	1	; Number of steps for governor requested pwm per 32ms

RCP_TIMEOUT_PPM	EQU	10	; Number of timer2H overflows (about 32ms) before considering rc pulse lost
RCP_TIMEOUT		EQU	64	; Number of timer2L overflows (about 128us) before considering rc pulse lost
RCP_SKIP_RATE		EQU 	32	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
RCP_MIN			EQU 	0	; This is minimum RC pulse length
RCP_MAX			EQU 	255	; This is maximum RC pulse length
RCP_VALIDATE		EQU 	2	; Require minimum this pulse length to validate RC pulse
RCP_STOP			EQU 	1	; Stop motor at or below this pulse length
RCP_STOP_LIMIT		EQU 	250	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

PWM_SETTLE		EQU 	50 	; PWM used when in start settling phase (also max power during direct start)
PWM_STEPPER		EQU 	80 	; PWM used when in start stepper phase

COMM_TIME_RED		EQU 	8	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
COMM_TIME_MIN		EQU 	1	; Minimum time (in us) for commutation wait

TEMP_CHECK_RATE	EQU 	8	; Number of adc conversions for each check of temperature (the other conversions are used for voltage)

ENDIF
; Constant definitions for tail
IF MODE == 1

GOV_SPOOLRATE		EQU	1	; Number of steps for governor requested pwm per 32ms
RCP_TIMEOUT_PPM	EQU	10	; Number of timer2H overflows (about 32ms) before considering rc pulse lost
RCP_TIMEOUT		EQU 	24	; Number of timer2L overflows (about 128us) before considering rc pulse lost
RCP_SKIP_RATE		EQU 	6	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
RCP_MIN			EQU 	0	; This is minimum RC pulse length
RCP_MAX			EQU 	255	; This is maximum RC pulse length
RCP_VALIDATE		EQU 	2	; Require minimum this pulse length to validate RC pulse
RCP_STOP			EQU 	1	; Stop motor at or below this pulse length
RCP_STOP_LIMIT		EQU 	130	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

PWM_SETTLE		EQU 	50 	; PWM used when in start settling phase (also max power during direct start)
PWM_STEPPER		EQU 	120 	; PWM used when in start stepper phase

COMM_TIME_RED		EQU 	8	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
COMM_TIME_MIN		EQU 	1	; Minimum time (in us) for commutation wait

TEMP_CHECK_RATE	EQU 	8	; Number of adc conversions for each check of temperature (the other conversions are used for voltage)

ENDIF
; Constant definitions for multi
IF MODE == 2

GOV_SPOOLRATE		EQU	1	; Number of steps for governor requested pwm per 32ms

RCP_TIMEOUT_PPM	EQU	10	; Number of timer2H overflows (about 32ms) before considering rc pulse lost
RCP_TIMEOUT		EQU 	24	; Number of timer2L overflows (about 128us) before considering rc pulse lost
RCP_SKIP_RATE		EQU 	6	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
RCP_MIN			EQU 	0	; This is minimum RC pulse length
RCP_MAX			EQU 	255	; This is maximum RC pulse length
RCP_VALIDATE		EQU 	2	; Require minimum this pulse length to validate RC pulse
RCP_STOP			EQU 	1	; Stop motor at or below this pulse length
RCP_STOP_LIMIT		EQU 	250	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

PWM_SETTLE		EQU 	50 	; PWM used when in start settling phase (also max power during direct start)
PWM_STEPPER		EQU 	120 	; PWM used when in start stepper phase

COMM_TIME_RED		EQU 	8	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
COMM_TIME_MIN		EQU 	1	; Minimum time (in us) for commutation wait

TEMP_CHECK_RATE	EQU 	8	; Number of adc conversions for each check of temperature (the other conversions are used for voltage)

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

Bit_Access:				DS	1		; Variable at bit accessible address (for non interrupt routines)
Bit_Access_Int:			DS	1		; Variable at bit accessible address (for interrupts)

Requested_Pwm:				DS	1		; Requested pwm (from RC pulse value)
Governor_Req_Pwm:			DS	1		; Governor requested pwm (sets governor target)
Current_Pwm:				DS	1		; Current pwm
Current_Pwm_Limited:		DS	1		; Current pwm that is limited (applied to the motor output)
Rcp_Prev_Edge_L:			DS	1		; RC pulse previous edge timer3 timestamp (lo byte)
Rcp_Prev_Edge_H:			DS	1		; RC pulse previous edge timer3 timestamp (hi byte)
Rcp_Timeout_Cnt:			DS	1		; RC pulse timeout counter (decrementing) 
Rcp_Skip_Cnt:				DS	1		; RC pulse skip counter (decrementing) 
Rcp_Edge_Cnt:				DS	1		; RC pulse edge counter 

Flags0:					DS	1    	; State flags. Reset upon init_start
T3_PENDING				EQU 	0		; Timer3 pending flag
RCP_MEAS_PWM_FREQ			EQU	1		; Measure RC pulse pwm frequency
PWM_ON					EQU	2		; Set in on part of pwm cycle
DEMAG_DETECTED				EQU 	3		; Set when excessive demag time is detected
DEMAG_CUT_POWER			EQU 	4		; Set when demag compensation cuts power
;						EQU 	5
;						EQU 	6
;						EQU 	7

Flags1:					DS	1    	; State flags. Reset upon init_start 
MOTOR_SPINNING				EQU	0		; Set when in motor is spinning
SETTLE_PHASE				EQU 	1		; Set when in motor start settling phase
STEPPER_PHASE				EQU	2		; Set when in motor start stepper motor phase
DIRECT_STARTUP_PHASE		EQU 	3		; Set when in direct startup phase
INITIAL_RUN_PHASE			EQU	4		; Set when in initial run phase, before synchronized run is achieved
;						EQU 	5	
;						EQU 	6	
;						EQU 	7

Flags2:					DS	1		; State flags. NOT reset upon init_start
RCP_UPDATED				EQU 	0		; New RC pulse length value available
RCP_EDGE_NO				EQU 	1		; RC pulse edge no. 0=rising, 1=falling
PGM_PWMOFF_DAMPED			EQU	2		; Programmed pwm off damped mode. Set when fully damped or damped light mode is selected
PGM_PWMOFF_DAMPED_FULL		EQU	3		; Programmed pwm off fully damped mode. Set when all pfets shall be on in pwm_off period
PGM_PWMOFF_DAMPED_LIGHT		EQU	4		; Programmed pwm off damped light mode. Set when only 2 pfets shall be on in pwm_off period
PGM_PWM_HIGH_FREQ			EQU	5		; Progremmed pwm high frequency
CURR_PWMOFF_DAMPED			EQU	6		; Currently running pwm off cycle is damped
CURR_PWMOFF_COMP_ABLE		EQU	7		; Currently running pwm off cycle is usable for comparator

Flags3:					DS	1		; State flags. NOT reset upon init_start
RCP_PWM_FREQ_1KHZ			EQU 	0		; RC pulse pwm frequency is 1kHz
RCP_PWM_FREQ_2KHZ			EQU 	1		; RC pulse pwm frequency is 2kHz
RCP_PWM_FREQ_4KHZ			EQU 	2		; RC pulse pwm frequency is 4kHz
RCP_PWM_FREQ_8KHZ			EQU 	3		; RC pulse pwm frequency is 8kHz
RCP_PWM_FREQ_12KHZ			EQU 	4		; RC pulse pwm frequency is 12kHz
PGM_DIR_REV				EQU 	5		; Programmed direction. 0=normal, 1=reversed
PGM_RCP_PWM_POL			EQU	6		; Programmed RC pulse pwm polarity. 0=positive, 1=negative
FULL_THROTTLE_RANGE			EQU 	7		; When set full throttle range is used (1000-2000us) and stored calibration values are ignored

;**** **** **** **** ****
; RAM definitions
DSEG AT 30h						; Ram data segment, direct addressing

Initial_Arm:				DS	1		; Variable that is set during the first arm sequence after power on

Power_On_Wait_Cnt_L: 		DS	1		; Power on wait counter (lo byte)
Power_On_Wait_Cnt_H: 		DS	1		; Power on wait counter (hi byte)

Stepper_Step_Beg_L:			DS	1		; Stepper phase step time at the beginning (lo byte)
Stepper_Step_Beg_H:			DS	1		; Stepper phase step time at the beginning (hi byte)
Stepper_Step_End_L:			DS	1		; Stepper phase step time at the end (lo byte)
Stepper_Step_End_H:			DS	1		; Stepper phase step time at the end (hi byte)
Startup_Rot_Cnt:			DS	1		; Startup phase rotations counter
Direct_Startup_Ok_Cnt:		DS	1		; Direct startup phase ok comparator waits counter (incrementing)

Prev_Comm_L:				DS	1		; Previous commutation timer3 timestamp (lo byte)
Prev_Comm_H:				DS	1		; Previous commutation timer3 timestamp (hi byte)
Comm_Period4x_L:			DS	1		; Timer3 counts between the last 4 commutations (lo byte)
Comm_Period4x_H:			DS	1		; Timer3 counts between the last 4 commutations (hi byte)
Comm_Phase:				DS	1		; Current commutation phase
Comp_Wait_Reads: 			DS	1		; Comparator wait comparator reads

Gov_Target_L:				DS	1		; Governor target (lo byte)
Gov_Target_H:				DS	1		; Governor target (hi byte)
Gov_Integral_L:			DS	1		; Governor integral error (lo byte)
Gov_Integral_H:			DS	1		; Governor integral error (hi byte)
Gov_Integral_X:			DS	1		; Governor integral error (ex byte)
Gov_Proportional_L:			DS	1		; Governor proportional error (lo byte)
Gov_Proportional_H:			DS	1		; Governor proportional error (hi byte)
Gov_Prop_Pwm:				DS	1		; Governor calculated new pwm based upon proportional error
Gov_Arm_Target:			DS	1		; Governor arm target value
Gov_Active:				DS	1		; Governor active (enabled when speed is above minimum)

Wt_Advance_L:				DS	1		; Timer3 counts for commutation advance timing (lo byte)
Wt_Advance_H:				DS	1		; Timer3 counts for commutation advance timing (hi byte)
Wt_Zc_Scan_L:				DS	1		; Timer3 counts from commutation to zero cross scan (lo byte)
Wt_Zc_Scan_H:				DS	1		; Timer3 counts from commutation to zero cross scan (hi byte)
Wt_Comm_L:				DS	1		; Timer3 counts from zero cross to commutation (lo byte)
Wt_Comm_H:				DS	1		; Timer3 counts from zero cross to commutation (hi byte)
Wt_Stepper_Step_L:			DS	1		; Timer3 counts for stepper step (lo byte)
Wt_Stepper_Step_H:			DS	1		; Timer3 counts for stepper step (hi byte)

Rcp_PrePrev_Edge_L:			DS	1		; RC pulse pre previous edge pca timestamp (lo byte)
Rcp_PrePrev_Edge_H:			DS	1		; RC pulse pre previous edge pca timestamp (hi byte)
Rcp_Edge_L:				DS	1		; RC pulse edge pca timestamp (lo byte)
Rcp_Edge_H:				DS	1		; RC pulse edge pca timestamp (hi byte)
Rcp_Prev_Period_L:			DS	1		; RC pulse previous period (lo byte)
Rcp_Prev_Period_H:			DS	1		; RC pulse previous period (hi byte)
Rcp_Period_Diff_Accepted:	DS	1		; RC pulse period difference acceptable
New_Rcp:					DS	1		; New RC pulse value in pca counts
Prev_Rcp_Pwm_Freq:			DS	1		; Previous RC pulse pwm frequency (used during pwm frequency measurement)
Curr_Rcp_Pwm_Freq:			DS	1		; Current RC pulse pwm frequency (used during pwm frequency measurement)
Rcp_Stop_Cnt:				DS	1		; Counter for RC pulses below stop value 

Pwm_Limit:				DS	1		; Maximum allowed pwm 
Pwm_Limit_Spoolup:			DS	1		; Maximum allowed pwm during spoolup of main
Pwm_Spoolup_Beg:			DS	1		; Pwm to begin main spoolup with
Pwm_Motor_Idle:			DS	1		; Motor idle speed pwm
Pwm_On_Cnt:				DS	1		; Pwm on event counter (used to increase pwm off time for low pwm)
Pwm_Off_Cnt:				DS	1		; Pwm off event counter (used to run some pwm cycles without damping)

Spoolup_Limit_Cnt:			DS	1		; Interrupt count for spoolup limit
Spoolup_Limit_Skip:			DS	1		; Interrupt skips for spoolup limit increment (1=no skips, 2=skip one etc)

Damping_Period:			DS	1		; Damping on/off period
Damping_On:				DS	1		; Damping on part of damping period

Lipo_Adc_Reference_L:		DS	1		; Voltage reference adc value (lo byte)
Lipo_Adc_Reference_H:		DS	1		; Voltage reference adc value (hi byte)
Lipo_Adc_Limit_L:			DS	1		; Low voltage limit adc value (lo byte)
Lipo_Adc_Limit_H:			DS	1		; Low voltage limit adc value (hi byte)
Adc_Conversion_Cnt:			DS	1		; Adc conversion counter

Current_Average_Temp:		DS	1		; Current average temperature (lo byte ADC reading, assuming hi byte is 1)

Ppm_Throttle_Gain:			DS	1		; Gain to be applied to RCP value for PPM input
Beep_Strength:				DS	1		; Strength of beeps

Tx_Pgm_Func_No:			DS	1		; Function number when doing programming by tx
Tx_Pgm_Paraval_No:			DS	1		; Parameter value number when doing programming by tx
Tx_Pgm_Beep_No:			DS	1		; Beep number when doing programming by tx

; Indirect addressing data segment
ISEG AT 080h					
Pgm_Gov_P_Gain:			DS	1		; Programmed governor P gain
Pgm_Gov_I_Gain:			DS	1		; Programmed governor I gain
Pgm_Gov_Mode:				DS	1		; Programmed governor mode

Pgm_Low_Voltage_Lim:		DS	1		; Programmed low voltage limit
Pgm_Motor_Gain:			DS	1		; Programmed motor gain
Pgm_Motor_Idle:			DS	1		; Programmed motor idle speed
Pgm_Startup_Pwr:			DS	1		; Programmed startup power
Pgm_Pwm_Freq:				DS	1		; Programmed pwm frequency
Pgm_Direction_Rev:			DS	1		; Programmed rotation direction
Pgm_Input_Pol:				DS	1		; Programmed input pwm polarity
Initialized_L_Dummy:		DS	1		; Place holder
Initialized_H_Dummy:		DS	1		; Place holder
Pgm_Enable_TX_Program:		DS 	1		; Programmed enable/disable value for TX programming
Pgm_Main_Rearm_Start:		DS 	1		; Programmed enable/disable re-arming main every start 
Pgm_Gov_Setup_Target:		DS 	1		; Programmed main governor setup target
Pgm_Startup_Rpm:			DS	1		; Programmed startup rpm
Pgm_Startup_Accel:			DS	1		; Programmed startup acceleration
Pgm_Volt_Comp_Dummy:		DS	1		; Place holder
Pgm_Comm_Timing:			DS	1		; Programmed commutation timing
Pgm_Damping_Force:			DS	1		; Programmed damping force
Pgm_Gov_Range:				DS	1		; Programmed governor range
Pgm_Startup_Method:			DS	1		; Programmed startup method
Pgm_Ppm_Min_Throttle:		DS	1		; Programmed throttle minimum
Pgm_Ppm_Max_Throttle:		DS	1		; Programmed throttle maximum
Pgm_Beep_Strength:			DS	1		; Programmed beep strength
Pgm_Beacon_Strength:		DS	1		; Programmed beacon strength
Pgm_Beacon_Delay:			DS	1		; Programmed beacon delay
Pgm_Throttle_Rate:			DS	1		; Programmed throttle rate
Pgm_Demag_Comp:			DS	1		; Programmed demag compensation
Pgm_BEC_Voltage_High:		DS	1		; Programmed BEC voltage

Pgm_Gov_P_Gain_Decoded:		DS	1		; Programmed governor decoded P gain
Pgm_Gov_I_Gain_Decoded:		DS	1		; Programmed governor decoded I gain
Pgm_Throttle_Rate_Decoded:	DS	1		; Programmed throttle rate decoded
Pgm_Startup_Pwr_Decoded:		DS	1		; Programmed startup power decoded
Pgm_Demag_Comp_Wait_Decoded:	DS	1		; Programmed demag compensation wait decoded
Pgm_Demag_Comp_Power_Decoded:	DS	1		; Programmed demag compensation power cut decoded


; Indirect addressing data segment
ISEG AT 0D0h					
Tag_Temporary_Storage:		DS	48		; Temporary storage for tags when updating "Eeprom"


;**** **** **** **** ****
CSEG AT 1A00h            ; "Eeprom" segment
EEPROM_FW_MAIN_REVISION		EQU	10		; Main revision of the firmware
EEPROM_FW_SUB_REVISION		EQU	4		; Sub revision of the firmware
EEPROM_LAYOUT_REVISION		EQU	16		; Revision of the EEPROM layout

Eep_FW_Main_Revision:		DB	EEPROM_FW_MAIN_REVISION			; EEPROM firmware main revision number
Eep_FW_Sub_Revision:		DB	EEPROM_FW_SUB_REVISION			; EEPROM firmware sub revision number
Eep_Layout_Revision:		DB	EEPROM_LAYOUT_REVISION			; EEPROM layout revision number

IF MODE == 0
Eep_Pgm_Gov_P_Gain:			DB	DEFAULT_PGM_MAIN_P_GAIN			; EEPROM copy of programmed governor P gain
Eep_Pgm_Gov_I_Gain:			DB	DEFAULT_PGM_MAIN_I_GAIN			; EEPROM copy of programmed governor I gain
Eep_Pgm_Gov_Mode:			DB	DEFAULT_PGM_MAIN_GOVERNOR_MODE	; EEPROM copy of programmed governor mode

Eep_Pgm_Low_Voltage_Lim:		DB	DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	; EEPROM copy of programmed low voltage limit
_Eep_Pgm_Motor_Gain:		DB	0FFh							
_Eep_Pgm_Motor_Idle:		DB	0FFh							
Eep_Pgm_Startup_Pwr:		DB	DEFAULT_PGM_MAIN_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:			DB	DEFAULT_PGM_MAIN_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction_Rev:		DB	DEFAULT_PGM_MAIN_DIRECTION_REV	; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:			DB	DEFAULT_PGM_MAIN_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:			DB	0A5h							; EEPROM initialized signature low byte
Eep_Initialized_H:			DB	05Ah							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
Eep_Main_Rearm_Start:		DB	DEFAULT_PGM_MAIN_REARM_START		; EEPROM re-arming main enable
Eep_Pgm_Gov_Setup_Target:	DB	DEFAULT_PGM_MAIN_GOV_SETUP_TARGET	; EEPROM main governor setup target
Eep_Pgm_Startup_Rpm:		DB	DEFAULT_PGM_MAIN_STARTUP_RPM		; EEPROM copy of programmed startup rpm
Eep_Pgm_Startup_Accel:		DB	DEFAULT_PGM_MAIN_STARTUP_ACCEL	; EEPROM copy of programmed startup acceleration
_Eep_Pgm_Volt_Comp:			DB	0FFh	
Eep_Pgm_Comm_Timing:		DB	DEFAULT_PGM_MAIN_COMM_TIMING		; EEPROM copy of programmed commutation timing
Eep_Pgm_Damping_Force:		DB	DEFAULT_PGM_MAIN_DAMPING_FORCE	; EEPROM copy of programmed damping force
Eep_Pgm_Gov_Range:			DB	DEFAULT_PGM_MAIN_GOVERNOR_RANGE	; EEPROM copy of programmed governor range
Eep_Pgm_Startup_Method:		DB	DEFAULT_PGM_MAIN_STARTUP_METHOD	; EEPROM copy of programmed startup method
Eep_Pgm_Ppm_Min_Throttle:	DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		DB	DEFAULT_PGM_MAIN_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		DB	DEFAULT_PGM_MAIN_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		DB	DEFAULT_PGM_MAIN_BEACON_DELAY		; EEPROM copy of programmed beacon delay
Eep_Pgm_Throttle_Rate:		DB	DEFAULT_PGM_MAIN_THROTTLE_RATE	; EEPROM copy of programmed throttle rate
Eep_Pgm_Demag_Comp:			DB	DEFAULT_PGM_MAIN_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
ENDIF

IF MODE == 1
_Eep_Pgm_Gov_P_Gain:		DB	0FFh							
_Eep_Pgm_Gov_I_Gain:		DB	0FFh							
_Eep_Pgm_Gov_Mode:			DB 	0FFh							

_Eep_Pgm_Low_Voltage_Lim:	DB	0FFh							
Eep_Pgm_Motor_Gain:			DB	DEFAULT_PGM_TAIL_GAIN			; EEPROM copy of programmed tail gain
Eep_Pgm_Motor_Idle:			DB	DEFAULT_PGM_TAIL_IDLE_SPEED		; EEPROM copy of programmed tail idle speed
Eep_Pgm_Startup_Pwr:		DB	DEFAULT_PGM_TAIL_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:			DB	DEFAULT_PGM_TAIL_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction_Rev:		DB	DEFAULT_PGM_TAIL_DIRECTION_REV	; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:			DB	DEFAULT_PGM_TAIL_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:			DB	05Ah							; EEPROM initialized signature low byte
Eep_Initialized_H:			DB	0A5h							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
_Eep_Main_Rearm_Start:		DB	0FFh							
_Eep_Pgm_Gov_Setup_Target:	DB	0FFh							
Eep_Pgm_Startup_Rpm:		DB	DEFAULT_PGM_TAIL_STARTUP_RPM		; EEPROM copy of programmed startup rpm
Eep_Pgm_Startup_Accel:		DB	DEFAULT_PGM_TAIL_STARTUP_ACCEL	; EEPROM copy of programmed startup acceleration
_Eep_Pgm_Volt_Comp:			DB	0FFh	
Eep_Pgm_Comm_Timing:		DB	DEFAULT_PGM_TAIL_COMM_TIMING		; EEPROM copy of programmed commutation timing
Eep_Pgm_Damping_Force:		DB	DEFAULT_PGM_TAIL_DAMPING_FORCE	; EEPROM copy of programmed damping force
_Eep_Pgm_Gov_Range:			DB	0FFh	
Eep_Pgm_Startup_Method:		DB	DEFAULT_PGM_TAIL_STARTUP_METHOD	; EEPROM copy of programmed startup method
Eep_Pgm_Ppm_Min_Throttle:	DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		DB	DEFAULT_PGM_TAIL_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		DB	DEFAULT_PGM_TAIL_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		DB	DEFAULT_PGM_TAIL_BEACON_DELAY		; EEPROM copy of programmed beacon delay
Eep_Pgm_Throttle_Rate:		DB	DEFAULT_PGM_TAIL_THROTTLE_RATE	; EEPROM copy of programmed throttle rate
Eep_Pgm_Demag_Comp:			DB	DEFAULT_PGM_TAIL_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
ENDIF

IF MODE == 2
Eep_Pgm_Gov_P_Gain:			DB	DEFAULT_PGM_MULTI_P_GAIN			; EEPROM copy of programmed closed loop P gain
Eep_Pgm_Gov_I_Gain:			DB	DEFAULT_PGM_MULTI_I_GAIN			; EEPROM copy of programmed closed loop I gain
Eep_Pgm_Gov_Mode:			DB	DEFAULT_PGM_MULTI_GOVERNOR_MODE	; EEPROM copy of programmed closed loop mode

Eep_Pgm_Low_Voltage_Lim:		DB	DEFAULT_PGM_MULTI_LOW_VOLTAGE_LIM	; EEPROM copy of programmed low voltage limit
Eep_Pgm_Motor_Gain:			DB	DEFAULT_PGM_MULTI_GAIN			; EEPROM copy of programmed tail gain
_Eep_Pgm_Motor_Idle:		DB	0FFh							; EEPROM copy of programmed tail idle speed
Eep_Pgm_Startup_Pwr:		DB	DEFAULT_PGM_MULTI_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:			DB	DEFAULT_PGM_MULTI_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction_Rev:		DB	DEFAULT_PGM_MULTI_DIRECTION_REV	; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:			DB	DEFAULT_PGM_MULTI_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:			DB	055h							; EEPROM initialized signature low byte
Eep_Initialized_H:			DB	0AAh							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
_Eep_Main_Rearm_Start:		DB	0FFh							
_Eep_Pgm_Gov_Setup_Target:	DB	0FFh							
Eep_Pgm_Startup_Rpm:		DB	DEFAULT_PGM_MULTI_STARTUP_RPM		; EEPROM copy of programmed startup rpm
Eep_Pgm_Startup_Accel:		DB	DEFAULT_PGM_MULTI_STARTUP_ACCEL	; EEPROM copy of programmed startup acceleration
_Eep_Pgm_Volt_Comp:			DB	0FFh	
Eep_Pgm_Comm_Timing:		DB	DEFAULT_PGM_MULTI_COMM_TIMING		; EEPROM copy of programmed commutation timing
Eep_Pgm_Damping_Force:		DB	DEFAULT_PGM_MULTI_DAMPING_FORCE	; EEPROM copy of programmed damping force
_Eep_Pgm_Gov_Range:			DB	0FFh	
Eep_Pgm_Startup_Method:		DB	DEFAULT_PGM_MULTI_STARTUP_METHOD	; EEPROM copy of programmed startup method
Eep_Pgm_Ppm_Min_Throttle:	DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		DB	DEFAULT_PGM_MULTI_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		DB	DEFAULT_PGM_MULTI_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		DB	DEFAULT_PGM_MULTI_BEACON_DELAY	; EEPROM copy of programmed beacon delay
Eep_Pgm_Throttle_Rate:		DB	DEFAULT_PGM_MULTI_THROTTLE_RATE	; EEPROM copy of programmed throttle rate
Eep_Pgm_Demag_Comp:			DB	DEFAULT_PGM_MULTI_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
ENDIF


Eep_Dummy:				DB	0FFh							; EEPROM address for safety reason

CSEG AT 1A60h
Eep_Name:					DB	"                "				; Name tag (16 Bytes)

;**** **** **** **** ****
       		Interrupt_Table_Definition		; SiLabs interrupts
CSEG AT 80h			; Code segment after interrupt vectors 

;**** **** **** **** ****

; Table definitions
GOV_GAIN_TABLE:   		DB 	02h, 03h, 04h, 06h, 08h, 0Ch, 10h, 18h, 20h, 30h, 40h, 60h, 80h
THROTTLE_RATE_TABLE:  	DB 	02h, 03h, 04h, 06h, 08h, 0Ch, 10h, 18h, 20h, 30h, 40h, 80h, 0FFh
STARTUP_POWER_TABLE:  	DB 	04h, 06h, 08h, 0Ch, 10h, 18h, 20h, 30h, 40h, 60h, 80h, 0A0h, 0C0h
DEMAG_WAIT_TABLE:  		DB 	0, 0, 0, 1, 1
DEMAG_POWER_TABLE:  	DB 	0, 3, 2, 2, 1
IF MODE == 0
TX_PGM_PARAMS_MAIN:  	DB 	13, 13, 4, 2, 6, 2, 13, 5, 5, 5, 13, 6, 3, 5, 2, 2
ENDIF
IF MODE == 1
  IF DAMPED_MODE_ENABLE == 1
TX_PGM_PARAMS_TAIL:  	DB 	5, 5, 2, 13, 5, 5, 5, 13, 6, 4, 5, 2, 2
  ENDIF
  IF DAMPED_MODE_ENABLE == 0
TX_PGM_PARAMS_TAIL:  	DB 	5, 5, 2, 13, 5, 5, 5, 13, 6, 3, 5, 2, 2
  ENDIF
ENDIF
IF MODE == 2
  IF DAMPED_MODE_ENABLE == 1
TX_PGM_PARAMS_MULTI:  	DB 	13, 13, 4, 5, 6, 2, 13, 5, 5, 5, 13, 6, 4, 5, 2, 2
  ENDIF
  IF DAMPED_MODE_ENABLE == 0
TX_PGM_PARAMS_MULTI:  	DB 	13, 13, 4, 5, 6, 2, 13, 5, 5, 5, 13, 6, 3, 5, 2, 2
  ENDIF
ENDIF

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer0 interrupt routine
;
; Assumptions: DPTR register must be set to desired pwm_nfet_on label
; Requirements: Temp variables can NOT be used since PWSW.3 is not set
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t0_int:	; Used for pwm control
	clr 	EA			; Disable all interrupts
	push	PSW			; Preserve registers through interrupt
	push	ACC		
	; Check if pwm is on
	jb	Flags0.PWM_ON, t0_int_pwm_off	; Is pwm on?

	; Pwm on cycle. 
	jnb	Current_Pwm_Limited.7, t0_int_pwm_on_low_pwm	; Jump for low pwm (<50%)

t0_int_pwm_on_execute:
	clr	A					
	jmp	@A+DPTR					; No - jump to pwm on routines. DPTR should be set to one of the pwm_nfet_on labels

t0_int_pwm_on_low_pwm:
	; Do not execute pwm when stopped
	jnb	Flags1.MOTOR_SPINNING, t0_int_pwm_on_stopped

IF MODE == 0 OR MODE == 2	; Main or multi
	jmp	t0_int_pwm_on_execute
ENDIF
IF MODE == 1				; Tail
	; Skip pwm on cycles for very low pwm
	inc	Pwm_On_Cnt				; Increment event counter
	clr	C
	mov	A, #5					; Only skip for very low pwm
	subb	A, Current_Pwm_Limited		; Check skipping shall be done (for low pwm only)
	jc	t0_int_pwm_on_execute

	subb	A, Pwm_On_Cnt				; Check if on cycle is to be skipped
	jc	t0_int_pwm_on_execute

	mov	TL0, #120					; Write start point for timer
	mov	A, Current_Pwm_Limited
	jnz	($+5)
	mov	TL0, #0					; Write start point for timer (long time for zero pwm)
	jmp	t0_int_pwm_on_exit_no_timer_update
ENDIF

t0_int_pwm_on_stopped:
	jmp	t0_int_pwm_on_exit


t0_int_pwm_off:
	jnb	Flags1.DIRECT_STARTUP_PHASE, t0_int_pwm_off_start_checked
	All_nFETs_Off 					; Switch off all nfets early during direct start, for a smooth start
t0_int_pwm_off_start_checked:
	; Pwm off cycle
	mov	TL0, Current_Pwm_Limited		; Load new timer setting
	; Clear pwm on flag
	clr	Flags0.PWM_ON	
	; Set full PWM (on all the time) if current PWM near max. This will give full power, but at the cost of a small "jump" in power
	mov	A, Current_Pwm_Limited		; Load current pwm
	cpl	A						; Full pwm?
	jnz	($+4)					; No - branch
	ajmp	t0_int_pwm_off_fullpower_exit	; Yes - exit

	inc	Pwm_Off_Cnt				; Increment event counter
	; Do not execute pwm when stopped
	jnb	Flags1.MOTOR_SPINNING, t0_int_pwm_off_stopped

	; If damped operation, set pFETs on in pwm_off
	jb	Flags2.PGM_PWMOFF_DAMPED, t0_int_pwm_off_damped	; Damped operation?

	; Separate exit commands here for minimum delay
	mov	TL1, #0		; Reset timer1	
	pop	ACC			; Restore preserved registers
	pop	PSW
	All_nFETs_Off 		; Switch off all nfets
	setb	EA			; Enable all interrupts
	reti

t0_int_pwm_off_stopped:
	All_nFETs_Off 					; Switch off all nfets
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_damped:
	setb	Flags2.CURR_PWMOFF_DAMPED	; Set damped status
	clr	Flags2.CURR_PWMOFF_COMP_ABLE	; Set comparator unusable status
	mov	A, Damping_On
	jz	t0_int_pwm_off_do_damped		; Highest damping - apply damping always

	clr	C
	mov	A, Pwm_Off_Cnt				; Is damped on number reached?
	dec	A
	subb	A, Damping_On
	jc	t0_int_pwm_off_do_damped		; No - apply damping

	clr	Flags2.CURR_PWMOFF_DAMPED	; Set non damped status
	setb	Flags2.CURR_PWMOFF_COMP_ABLE	; Set comparator usable status
	clr	C
	mov	A, Pwm_Off_Cnt					
	subb	A, Damping_Period			; Is damped period number reached?
	jnc	t0_int_pwm_off_clr_cnt		; Yes - Proceed

	jmp	t0_int_pwm_off_exit			; No - Branch

t0_int_pwm_off_clr_cnt:
	mov	Pwm_Off_Cnt, #0			; Yes - clear counter
	jmp	t0_int_pwm_off_exit			; Not damped cycle - exit	

t0_int_pwm_off_do_damped:
	; Delay to allow nFETs to go off before pFETs are turned on (only in full damped mode)
	jb	Flags2.PGM_PWMOFF_DAMPED_LIGHT, t0_int_pwm_off_damped_light	; If damped light operation - branch

	All_nFETs_Off 					; Switch off all nfets
	mov	A, #PFETON_DELAY
	djnz	ACC, $	
	All_pFETs_On 					; Switch on all pfets
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_damped_light:
IF DAMPED_MODE_ENABLE == 1
	setb	Flags2.CURR_PWMOFF_COMP_ABLE	; Set comparator usable status always for damped light mode on fully damped capable escs
ENDIF
	All_nFETs_Off 					; Switch off all nfets
	mov	A, Comm_Phase				; Turn on pfets according to commutation phase
	jb	ACC.2, t0_int_pwm_off_comm_4_5_6
	jb	ACC.1, t0_int_pwm_off_comm_2_3

IF DAMPED_MODE_ENABLE == 0
	ApFET_On			; Comm phase 1 - turn on A
ELSE
	mov	A, #PFETON_DELAY
	djnz	ACC, $	
	CpFET_On			; Comm phase 1 - turn on C
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_2_3:
	jb	ACC.0, t0_int_pwm_off_comm_3
IF DAMPED_MODE_ENABLE == 0
	BpFET_On			; Comm phase 2 - turn on B
ELSE
	mov	A, #PFETON_DELAY
	djnz	ACC, $	
	CpFET_On			; Comm phase 2 - turn on C
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_3:
IF DAMPED_MODE_ENABLE == 0
	CpFET_On			; Comm phase 3 - turn on C
ELSE
	mov	A, #PFETON_DELAY
	djnz	ACC, $	
	BpFET_On			; Comm phase 3 - turn on B
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_4_5_6:
	jb	ACC.1, t0_int_pwm_off_comm_6
	jb	ACC.0, t0_int_pwm_off_comm_5

IF DAMPED_MODE_ENABLE == 0
	ApFET_On			; Comm phase 4 - turn on A
ELSE
	mov	A, #PFETON_DELAY
	djnz	ACC, $	
	BpFET_On			; Comm phase 4 - turn on B
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_5:
IF DAMPED_MODE_ENABLE == 0
	BpFET_On			; Comm phase 5 - turn on B
ELSE
	mov	A, #PFETON_DELAY
	djnz	ACC, $	
	ApFET_On			; Comm phase 5 - turn on A
ENDIF
	jmp	t0_int_pwm_off_exit

t0_int_pwm_off_comm_6:
IF DAMPED_MODE_ENABLE == 0
	CpFET_On			; Comm phase 6 - turn on C
ELSE
	mov	A, #PFETON_DELAY
	djnz	ACC, $	
	ApFET_On			; Comm phase 6 - turn on A
ENDIF

t0_int_pwm_off_exit:	; Exit from pwm off cycle
	mov	TL1, #0		; Reset timer1	
	pop	ACC			; Restore preserved registers
	pop	PSW
	All_nFETs_Off 		; Switch off all nfets
	setb	EA			; Enable all interrupts
	reti

t0_int_pwm_off_fullpower_exit:	; Exit from pwm off cycle, leaving power on
	pop	ACC			; Restore preserved registers
	pop	PSW
	setb	EA			; Enable all interrupts
	reti



pwm_nofet_on:	; Dummy pwm on cycle
	ajmp	t0_int_pwm_on_exit

pwm_afet_on:	; Pwm on cycle afet on (bfet off)
	AnFET_on	
	BnFET_off
	ajmp	t0_int_pwm_on_exit

pwm_bfet_on:	; Pwm on cycle bfet on (cfet off)
	BnFET_on
	CnFET_off
	ajmp	t0_int_pwm_on_exit

pwm_cfet_on:	; Pwm on cycle cfet on (afet off)
	CnFET_on
	AnFET_off
	ajmp	t0_int_pwm_on_exit

pwm_anfet_bpfet_on_fast:	; Pwm on cycle anfet on (bnfet off) and bpfet on (used in damped state 6)
	ApFET_off
	AnFET_on								; Switch nFETs
	CpFET_off
	BnFET_off 							
	ajmp	t0_int_pwm_on_exit
pwm_anfet_bpfet_on_safe:	; Pwm on cycle anfet on (bnfet off) and bpfet on (used in damped state 6)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ApFET_off
	CpFET_off
	mov	A, #NFETON_DELAY					; Set full delay
	djnz ACC,	$
	AnFET_on								; Switch nFETs
	BnFET_off 							
	ajmp	t0_int_pwm_on_exit

pwm_anfet_cpfet_on_fast:	; Pwm on cycle anfet on (bnfet off) and cpfet on (used in damped state 5)
	ApFET_off
	AnFET_on								; Switch nFETs
	BpFET_off
	BnFET_off								
	ajmp	t0_int_pwm_on_exit
pwm_anfet_cpfet_on_safe:	; Pwm on cycle anfet on (bnfet off) and cpfet on (used in damped state 5)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ApFET_off
	BpFET_off
	mov	A, #NFETON_DELAY					; Set full delay
	djnz ACC,	$
	AnFET_on								; Switch nFETs
	BnFET_off								
	ajmp	t0_int_pwm_on_exit

pwm_bnfet_cpfet_on_fast:	; Pwm on cycle bnfet on (cnfet off) and cpfet on (used in damped state 4)
	BpFET_off
	BnFET_on								; Switch nFETs
	ApFET_off
	CnFET_off								
	ajmp	t0_int_pwm_on_exit
pwm_bnfet_cpfet_on_safe:	; Pwm on cycle bnfet on (cnfet off) and cpfet on (used in damped state 4)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	BpFET_off
	ApFET_off
	mov	A, #NFETON_DELAY					; Set full delay
	djnz ACC,	$
	BnFET_on								; Switch nFETs
	CnFET_off								
	ajmp	t0_int_pwm_on_exit

pwm_bnfet_apfet_on_fast:	; Pwm on cycle bnfet on (cnfet off) and apfet on (used in damped state 3)
	BpFET_off
	BnFET_on								; Switch nFETs
	CpFET_off
	CnFET_off								
	ajmp	t0_int_pwm_on_exit
pwm_bnfet_apfet_on_safe:	; Pwm on cycle bnfet on (cnfet off) and apfet on (used in damped state 3)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	BpFET_off
	CpFET_off
	mov	A, #NFETON_DELAY					; Set full delay
	djnz ACC,	$
	BnFET_on								; Switch nFETs
	CnFET_off								
	ajmp	t0_int_pwm_on_exit

pwm_cnfet_apfet_on_fast:	; Pwm on cycle cnfet on (anfet off) and apfet on (used in damped state 2)
	CpFET_off
	CnFET_on								; Switch nFETs
	BpFET_off
	AnFET_off								
	ajmp	t0_int_pwm_on_exit
pwm_cnfet_apfet_on_safe:	; Pwm on cycle cnfet on (anfet off) and apfet on (used in damped state 2)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	CpFET_off
	BpFET_off
	mov	A, #NFETON_DELAY					; Set full delay
	djnz ACC,	$
	CnFET_on								; Switch nFETs
	AnFET_off								
	ajmp	t0_int_pwm_on_exit

pwm_cnfet_bpfet_on_fast:	; Pwm on cycle cnfet on (anfet off) and bpfet on (used in damped state 1)
	CpFET_off
	CnFET_on								; Switch nFETs
	ApFET_off
	AnFET_off								
	ajmp	t0_int_pwm_on_exit
pwm_cnfet_bpfet_on_safe:	; Pwm on cycle cnfet on (anfet off) and bpfet on (used in damped state 1)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	CpFET_off
	ApFET_off
	mov	A, #NFETON_DELAY					; Set full delay
	djnz ACC,	$
	CnFET_on								; Switch nFETs
	AnFET_off								
	ajmp	t0_int_pwm_on_exit

t0_int_pwm_on_exit:
	; Set timer for coming on cycle length
	mov 	A, Current_Pwm_Limited		; Load current pwm
	cpl	A						; cpl is 255-x
	mov	TL0, A					; Write start point for timer
	; Set other variables
	mov	TL1, #0					; Reset timer1	
	mov	Pwm_On_Cnt, #0				; Reset pwm on event counter
	setb	Flags0.PWM_ON				; Set pwm on flag
t0_int_pwm_on_exit_no_timer_update:
	; Exit interrupt
	pop	ACC			; Restore preserved registers
	pop	PSW
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
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
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
	clr	Flags2.RCP_EDGE_NO			; Set first edge flag
	Read_Rcp_Int 					; Look once more at value of Rcp_In
	jnb	ACC.Rcp_In, ($+5)			; Is it high?
	mov	Temp2, #RCP_MAX			; Yes - set RCP_MAX
	clr	C
	mov	A, Temp1
	subb	A, Temp2					; Compare the two readings of Rcp_In
	jnz 	t2_int_pulses_absent		; Go back if they are not equal

	jnb	Flags0.RCP_MEAS_PWM_FREQ, ($+6)	; Is measure RCP pwm frequency flag set?

	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT	; Yes - set timeout count to start value

	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
	jz	t2_int_ppm_timeout_set		; If no flag is set (PPM) - branch

	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT	; For PWM, set timeout count to start value

t2_int_ppm_timeout_set:
	mov	New_Rcp, Temp1				; Store new pulse length
	setb	Flags2.RCP_UPDATED		 	; Set updated flag


t2_int_skip_start:
	; Check RC pulse skip counter
	mov	A, Rcp_Skip_Cnt			
	jz 	t2_int_skip_end			; If RC pulse skip count is zero - end skipping RC pulse detection
	
	; Decrement skip counter (only if edge counter is zero)
	dec	Rcp_Skip_Cnt				; Decrement
	ajmp	t2_int_rcp_update_start

t2_int_skip_end:
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
	jz	t2_int_rcp_update_start		; If no flag is set (PPM) - branch

	; Skip counter has reached zero, start looking for RC pulses again
	Rcp_Int_Enable 				; Enable RC pulse interrupt
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	
t2_int_rcp_update_start:
	; Process updated RC pulse
	jb	Flags2.RCP_UPDATED, ($+5)	; Is there an updated RC pulse available?
	ajmp	t2_int_pwm_exit			; No - exit

	mov	A, New_Rcp				; Load new pulse value
	mov	Temp1, A
	clr	Flags2.RCP_UPDATED		 	; Flag that pulse has been evaluated
	; Use a gain of 1.0625x for pwm input if not governor mode
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
	jz	t2_int_pwm_min_run			; If no flag is set (PPM) - branch

IF MODE <= 1	; Main or tail
	mov	Temp2, #Pgm_Gov_Mode		; Governor mode?
	cjne	@Temp2, #4, t2_int_pwm_min_run; Yes - branch
ENDIF
IF MODE == 2	; Multi
	mov	Temp2, #Pgm_Gov_Mode		; Closed loop mode?
	cjne	@Temp2, #4, t2_int_pwm_min_run; Yes - branch
ENDIF

	; Limit the maximum value to avoid wrap when scaled to pwm range
	clr	C
	mov	A, Temp1
	subb	A, #240			; 240 = (255/1.0625) Needs to be updated according to multiplication factor below		
	jc	t2_int_rcp_update_mult

	mov	A, #240			; Set requested pwm to max
	mov	Temp1, A		

t2_int_rcp_update_mult:	
	; Multiply by 1.0625 (optional adjustment gyro gain)
	mov	A, Temp1
	swap	A			; After this "0.0625"
	anl	A, #0Fh
	add	A, Temp1
	mov	Temp1, A		
	; Adjust tail gain
	mov	Temp2, #Pgm_Motor_Gain
	cjne	@Temp2, #3, ($+5)			; Is gain 1?
	ajmp	t2_int_pwm_min_run			; Yes - skip adjustment

	clr	C
	rrc	A			; After this "0.5"
	clr	C
	rrc	A			; After this "0.25"
	mov	Bit_Access_Int, @Temp2				; (Temp2 has #Pgm_Motor_Gain)
	jb	Bit_Access_Int.0, t2_int_rcp_gain_corr	; Branch if bit 0 in gain is set

	clr	C
	rrc	A			; After this "0.125"

t2_int_rcp_gain_corr:
	jb	Bit_Access_Int.2, t2_int_rcp_gain_pos	; Branch if bit 2 in gain is set

	clr	C
	xch	A, Temp1
	subb	A, Temp1					; Apply negative correction
	mov	Temp1, A
	ajmp	t2_int_pwm_min_run

t2_int_rcp_gain_pos:
	add	A, Temp1					; Apply positive correction
	mov	Temp1, A
	jnc	t2_int_pwm_min_run			; Above max?

	mov	A, #0FFh					; Yes - limit
	mov	Temp1, A

t2_int_pwm_min_run: 
	; Limit minimum pwm
	clr	C
	mov	A, Temp1
	subb	A, Pwm_Motor_Idle			; Is requested pwm lower than minimum?
	jnc	t2_int_pwm_update			; No - branch

	mov	A, Pwm_Motor_Idle			; Yes - limit pwm to Pwm_Motor_Idle	
	mov	Temp1, A

t2_int_pwm_update: 
	; Check if any startup phase flags are set
	mov	A, Flags1
	anl	A, #((1 SHL SETTLE_PHASE)+(1 SHL STEPPER_PHASE))
	jnz	t2_int_pwm_exit			; Exit if any startup phase set (pwm controlled by set_startup_pwm)

	; Update requested_pwm
	mov	Requested_Pwm, Temp1		; Set requested pwm
	; Limit pwm during direct start
	jnb	Flags1.DIRECT_STARTUP_PHASE, t2_int_current_pwm_update

	clr	C
	mov	A, Requested_Pwm			; Limit pwm during direct start
	subb	A, Pwm_Limit
	jc	t2_int_current_pwm_update

	mov	Requested_Pwm, Pwm_Limit

t2_int_current_pwm_update: 
IF MODE <= 1	; Main or tail
	mov	Temp1, #Pgm_Gov_Mode		; Governor mode?
	cjne	@Temp1, #4, t2_int_pwm_exit	; Yes - branch
ENDIF
IF MODE == 2	; Multi
	mov	Temp1, #Pgm_Gov_Mode		; Closed loop mode?
	cjne	@Temp1, #4, t2_int_pwm_exit	; Yes - branch
ENDIF

	; Update current pwm, with limited throttle change rate
	clr	C
	mov	A, Requested_Pwm	
	subb	A, Current_Pwm				; Is requested pwm larger than current pwm?
	jc	t2_int_set_current_pwm		; No - proceed

	mov	Temp1, #Pgm_Throttle_Rate_Decoded		
	subb	A, @Temp1					; Is difference larger than throttle change rate?
	jc	t2_int_set_current_pwm		; No - proceed

	mov	A, Current_Pwm				; Increase current pwm by throttle change rate
	add	A, @Temp1
	mov	Current_Pwm, A
	jnc	t2_int_current_pwm_done		; Is result above max?

	mov	Current_Pwm, #0FFh			; Yes - limit
	jmp	t2_int_current_pwm_done

t2_int_set_current_pwm:
	mov	Current_Pwm, Requested_Pwm	; Set equal as default
t2_int_current_pwm_done:
IF MODE == 1	; Tail
	; If tail, then set current_pwm_limited
	mov	Current_Pwm_Limited, Current_Pwm	; Default not limited
	clr	C
	mov	A, Current_Pwm					; Check against limit
	subb	A, Pwm_Limit
	jc	($+5)						; If current pwm below limit - branch

	mov	Current_Pwm_Limited, Pwm_Limit	; Limit pwm
ENDIF
IF MODE == 2	; Multi
	; If multi, then set current_pwm_limited
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
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
	jnz	t2h_int_rcp_stop_check		; If a flag is set (PWM) - branch

	dec	Rcp_Timeout_Cnt			; No flag set (PPM) - decrement

t2h_int_rcp_stop_check:
	; Check RC pulse against stop value
	clr	C
	mov	A, New_Rcp			; Load new pulse value
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
	mov	Temp2, #Pgm_Gov_Mode			; Governor target by arm mode?
	cjne	@Temp2, #2, t2h_int_rcp_gov_by_setup	; No - branch

	mov	A, Gov_Active					; Is governor active?
	jz	t2h_int_rcp_gov_by_tx			; No - branch (this ensures soft spoolup by tx)

	clr	C
	mov	A, Requested_Pwm
	subb	A, #50						; Is requested pwm below 20%?
	jc	t2h_int_rcp_gov_by_tx			; Yes - branch (this enables a soft spooldown)

	mov	Requested_Pwm, Gov_Arm_Target		; Yes - load arm target

t2h_int_rcp_gov_by_setup:
	mov	Temp2, #Pgm_Gov_Mode			; Governor target by setup mode?
	cjne	@Temp2, #3, t2h_int_rcp_gov_by_tx		; No - branch

	mov	A, Gov_Active					; Is governor active?
	jz	t2h_int_rcp_gov_by_tx			; No - branch (this ensures soft spoolup by tx)

	clr	C
	mov	A, Requested_Pwm
	subb	A, #50						; Is requested pwm below 20%?
	jc	t2h_int_rcp_gov_by_tx			; Yes - branch (this enables a soft spooldown)

	mov	Temp2, #Pgm_Gov_Setup_Target		; Gov by setup - load setup target
	mov	Requested_Pwm, @Temp2

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

	inc	Spoolup_Limit_Cnt				; Increment spoolup count
	mov	A, Spoolup_Limit_Cnt
	jnz	($+4)						; Wrapped?

	dec	Spoolup_Limit_Cnt				; Yes - decrement

	djnz	Spoolup_Limit_Skip, t2h_int_rcp_exit	; Jump if skip count is not reached

	mov	Spoolup_Limit_Skip, #1			; Reset skip count. Default is fast spoolup
	mov	Temp1, #3						; Default fast increase

	clr	C
	mov	A, Spoolup_Limit_Cnt
	subb	A, #(3*MAIN_SPOOLUP_TIME)		; No spoolup until "30"*32ms
	jc	t2h_int_rcp_exit

	clr	C
	mov	A, Spoolup_Limit_Cnt
	subb	A, #(10*MAIN_SPOOLUP_TIME)		; Slow spoolup until "100"*32ms
	jnc	t2h_int_rcp_limit_middle_ramp

	mov	Temp1, #1						; Slow initial spoolup
	mov	Spoolup_Limit_Skip, #3			
	jmp	t2h_int_rcp_set_limit

t2h_int_rcp_limit_middle_ramp:
	clr	C
	mov	A, Spoolup_Limit_Cnt
	subb	A, #(15*MAIN_SPOOLUP_TIME)		; Faster spoolup until "150"*32ms
	jnc	t2h_int_rcp_set_limit

	mov	Temp1, #1						; Faster middle spoolup
	mov	Spoolup_Limit_Skip, #1			

t2h_int_rcp_set_limit:
	; Do not increment spoolup limit if higher pwm is not requested, unless governor is active
	clr	C
	mov	A, Pwm_Limit_Spoolup
	subb	A, Current_Pwm
	jc	t2h_int_rcp_inc_limit			; If Current_Pwm is larger than Pwm_Limit_Spoolup - branch

	mov	A, Gov_Active					; Is governor active?
	jnz	t2h_int_rcp_inc_limit			; Yes - branch

	mov	Pwm_Limit_Spoolup, Current_Pwm	; Set limit to what current pwm is
	mov	A, Spoolup_Limit_Cnt			; Check if spoolup limit count is 255. If it is, ten this is a "bailout" ramp
	inc	A
	jz	($+5)

	mov	Spoolup_Limit_Cnt, #(3*MAIN_SPOOLUP_TIME)	; Stay in an early part of the spoolup sequence (unless "bailout" ramp)

	mov	Spoolup_Limit_Skip, #1			; Set skip count
	mov	Governor_Req_Pwm, #60			; Set governor requested speed to ensure that it requests higher speed
									; 20=Fail on jerk when governor activates
									; 30=Ok
									; 100=Fail on small governor settling overshoot on low headspeeds
									; 200=Fail on governor settling overshoot
	jmp	t2h_int_rcp_exit				; Exit

t2h_int_rcp_inc_limit:
	clr	C
	mov	A, Pwm_Limit_Spoolup			; Increment spoolup pwm
	add	A, Temp1
	jnc	t2h_int_rcp_no_limit			; If below 255 - branch

	mov	Pwm_Limit_Spoolup, #0FFh
	ajmp	t2h_int_rcp_exit

t2h_int_rcp_no_limit:
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
	push	B
	setb	PSW.3		; Select register bank 1 for interrupt routines
	; Get the PCA counter values
	Get_Rcp_Capture_Values
	; Clear interrupt flag
	Rcp_Clear_Int_Flag 				
	; Check which edge it is
	jnb	Flags2.RCP_EDGE_NO, ($+5)	; Is it a first edge trig?
	ajmp pca_int_second_meas_pwm_freq	; No - branch to second

	Rcp_Int_Second					; Yes - set second edge trig
	setb	Flags2.RCP_EDGE_NO			; Set second edge flag
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
	clr	Flags2.RCP_EDGE_NO			; Set first edge flag
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
	jnz	($+4)					; If a flag is set (PWM) - proceed

	ajmp	pca_int_set_timeout			; If PPM - ignore trig as noise

	mov	Temp1, #RCP_MIN			; Set RC pulse value to minimum
	Read_Rcp_Int 					; Test RC signal level again
	jnb	ACC.Rcp_In, ($+5)			; Is it high?
	ajmp	pca_int_set_timeout			; Yes - set new timeout and exit

	mov	New_Rcp, Temp1				; Store new pulse length
	ajmp	pca_int_set_timeout			; Set new timeout and exit

pca_int_second_meas_pwm_freq:
	; Prepare for next interrupt
	Rcp_Int_First 					; Set first edge trig
	clr	Flags2.RCP_EDGE_NO			; Set first edge flag
	; Check if pwm frequency shall be measured
	jb	Flags0.RCP_MEAS_PWM_FREQ, ($+5)	; Is measure RCP pwm frequency flag set?
	ajmp	pca_int_fall				; No - skip measurements

	; Set second edge trig only during pwm frequency measurement
	Rcp_Int_Second 				; Set second edge trig
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	setb	Flags2.RCP_EDGE_NO			; Set second edge flag
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
	mov	Temp3, #250				; Set default period tolerance requirement
	; Check if pwm frequency is 12kHz
	clr	C
	mov	A, Temp1
	subb	A, #low(200)				; If below 100us, 12kHz pwm is assumed
	mov	A, Temp2
	subb	A, #high(200)
	jnc	pca_int_check_8kHz

	clr	A
	setb	ACC.RCP_PWM_FREQ_12KHZ
	mov	Temp4, A
	mov	Temp3, #10				; Set period tolerance requirement
	ajmp	pca_int_restore_edge

pca_int_check_8kHz:
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
	mov	Temp3, #15				; Set period tolerance requirement
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
	mov	Temp3, #30				; Set period tolerance requirement
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
	mov	Temp3, #60				; Set period tolerance requirement
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
	mov	Temp3, #120				; Set period tolerance requirement

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
	subb	A, Temp3						; Check difference
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
	jnb	Flags3.RCP_PWM_FREQ_12KHZ, ($+5)	; Is RC input pwm frequency 12kHz?
	ajmp	pca_int_pwm_divide_done			; Yes - branch forward
	jnb	Flags3.RCP_PWM_FREQ_8KHZ, ($+5)	; Is RC input pwm frequency 8kHz?
	ajmp	pca_int_pwm_divide_done			; Yes - branch forward

	jnb	Flags3.RCP_PWM_FREQ_4KHZ, ($+5)	; Is RC input pwm frequency 4kHz?
	ajmp	pca_int_pwm_divide				; Yes - branch forward

	mov	A, Temp2						; No - 2kHz. Divide by 2 again
	clr	C
	rrc	A
	mov	Temp2, A
	mov	A, Temp1					
	rrc	A
	mov	Temp1, A

	jnb	Flags3.RCP_PWM_FREQ_2KHZ, ($+5)	; Is RC input pwm frequency 2kHz?
	ajmp	pca_int_pwm_divide				; Yes - branch forward

	mov	A, Temp2						; No - 1kHz. Divide by 2 again
	clr	C
	rrc	A
	mov	Temp2, A
	mov	A, Temp1					
	rrc	A
	mov	Temp1, A

	jnb	Flags3.RCP_PWM_FREQ_1KHZ, ($+5)	; Is RC input pwm frequency 1kHz?
	ajmp	pca_int_pwm_divide				; Yes - branch forward

	mov	A, Temp2						; No - PPM. Divide by 2 (to bring range to 256) and move to Temp5/6
	clr	C
	rrc	A
	mov	Temp6, A
	mov	A, Temp1					
	rrc	A
	mov	Temp5, A
	; Skip range limitation if pwm frequency measurement
	jb	Flags0.RCP_MEAS_PWM_FREQ, pca_int_ppm_check_full_range 		

	; Check if 2160us or above (in order to ignore false pulses)
	clr	C
	mov	A, Temp5						; Is pulse 2160us or higher?
	subb	A, #28
	mov	A, Temp6
	subb A, #2
	jc	($+5)						; No - proceed

	ljmp	pca_int_set_timeout				; Yes - ignore pulse

	; Check if below 800us (in order to ignore false pulses)
	mov	A, Temp6
	jnz	pca_int_ppm_check_full_range

	clr	C
	mov	A, Temp5						; Is pulse below 800us?
	subb	A, #200
	jnc	pca_int_ppm_check_full_range		; No - proceed

	jmp	pca_int_exit					; Yes - ignore pulse

pca_int_ppm_check_full_range:
	; Calculate "1000us" plus throttle minimum
	mov	A, #0						; Set 1000us as default minimum
	jb	Flags3.FULL_THROTTLE_RANGE, pca_int_ppm_calculate	; Check if full range is chosen

	mov	Temp1, #Pgm_Ppm_Min_Throttle		; Min throttle value is in 4us units
	mov	A, @Temp1				

pca_int_ppm_calculate:
	add	A, #250
	mov	Temp7, A
	clr	A
	addc	A, #0
	mov	Temp8, A

	clr	C
	mov	A, Temp5						; Subtract minimum
	subb	A, Temp7
	mov	Temp5, A
	mov	A, Temp6					
	subb	A, Temp8
	mov	Temp6, A
	jnc	pca_int_ppm_neg_checked			; Is result negative?

	mov	Temp1, #RCP_MIN				; Yes - set to minimum
	mov	Temp2, #0
	ajmp	pca_int_pwm_divide_done

pca_int_ppm_neg_checked:
	clr	C							; Check that RC pulse is within legal range (1000+4*255=2020)
	mov	A, Temp5
	subb	A, #RCP_MAX				
	mov	A, Temp6
	subb	A, #0
	jc	pca_int_ppm_max_checked

	mov	Temp1, #RCP_MAX
	mov	Temp2, #0
	ajmp	pca_int_pwm_divide_done

pca_int_ppm_max_checked:
	mov	A, Temp5						; Multiply throttle value by gain
	mov	B, Ppm_Throttle_Gain
	mul	AB
	xch	A, B
	mov	C, B.7						; Multiply result by 2 (unity gain is 128)
	rlc	A
	mov	Temp1, A						; Transfer to Temp1/2
	mov	Temp2, #0
	jc	pca_int_ppm_limit_after_mult
	
	jmp	pca_int_limited			

pca_int_ppm_limit_after_mult:
	mov	Temp1, #RCP_MAX
	mov	Temp2, #0
	jmp	pca_int_limited			

pca_int_pwm_divide:
	mov	A, Temp2						; Divide by 2
	clr	C
	rrc	A
	mov	Temp2, A
	mov	A, Temp1					
	rrc	A
	mov	Temp1, A

pca_int_pwm_divide_done:
	jnb	Flags3.RCP_PWM_FREQ_12KHZ, pca_int_check_legal_range	; Is RC input pwm frequency 12kHz?
	mov	A, Temp2						; Yes - check that value is not more than 255
	jz	($+4)

	mov	Temp1, #RCP_MAX

	clr	C
	mov	A, Temp1						; Multiply by 1.5				
	rrc	A
	addc	A, Temp1
	mov	Temp1, A
	clr	A
	addc	A, #0
	mov	Temp2, A

pca_int_check_legal_range:
	; Check that RC pulse is within legal range
	clr	C
	mov	A, Temp1
	subb	A, #RCP_MAX				
	mov	A, Temp2
	subb	A, #0
	jc	pca_int_limited

	mov	Temp1, #RCP_MAX

pca_int_limited:
	; RC pulse value accepted
	mov	New_Rcp, Temp1				; Store new pulse length
	setb	Flags2.RCP_UPDATED		 	; Set updated flag
	jb	Flags0.RCP_MEAS_PWM_FREQ, ($+5)	; Is measure RCP pwm frequency flag set?
	ajmp	pca_int_set_timeout			; No - skip measurements

	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	cpl	A
	anl	A, Flags3					; Clear all pwm frequency flags
	orl	A, Temp4					; Store pwm frequency value in flags
	mov	Flags3, A

pca_int_set_timeout:
	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT	; Set timeout count to start value
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
	jnz	pca_int_ppm_timeout_set		; If a flag is set - branch

	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT_PPM	; No flag set means PPM. Set timeout count

pca_int_ppm_timeout_set:
	jnb	Flags0.RCP_MEAS_PWM_FREQ, ($+5)	; Is measure RCP pwm frequency flag set?
	ajmp pca_int_exit				; Yes - exit

	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
	jz	pca_int_exit				; If no flag is set (PPM) - branch

	Rcp_Int_Disable 				; Disable RC pulse interrupt

pca_int_exit:	; Exit interrupt routine	
	mov	Rcp_Skip_Cnt, #RCP_SKIP_RATE	; Load number of skips
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
	jnz	($+5)					; If a flag is set (PWM) - branch

	mov	Rcp_Skip_Cnt, #10			; Load number of skips

	pop	B			; Restore preserved registers
	pop	ACC			
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
	mov	Temp3, #20	; Off wait loop length
	mov	Temp4, #120	; Number of beep pulses
	jmp	beep

beep_f2:	; Entry point 2, load beeper frequency 2 settings
	mov	Temp3, #16
	mov	Temp4, #140
	jmp	beep

beep_f3:	; Entry point 3, load beeper frequency 3 settings
	mov	Temp3, #13
	mov	Temp4, #180
	jmp	beep

beep_f4:	; Entry point 4, load beeper frequency 4 settings
	mov	Temp3, #11
	mov	Temp4, #200
	jmp	beep

beep:	; Beep loop start
	mov	Temp5, Current_Pwm_Limited	; Store value
	mov	Current_Pwm_Limited, #1		; Set to a nonzero value
	mov	Temp2, #2					; Must be an even number (or direction will change)
beep_onoff:
	cpl	Flags3.PGM_DIR_REV			; Toggle between using A fet and C fet
	clr	A
	BpFET_off			; BpFET off
	djnz	ACC, $		; Allow some time after pfet is turned off
	BnFET_on			; BnFET on (in order to charge the driver of the BpFET)
	djnz	ACC, $		; Let the nfet be turned on a while
	BnFET_off			; BnFET off again
	djnz	ACC, $		; Allow some time after nfet is turned off
	BpFET_on			; BpFET on
	djnz	ACC, $		; Allow some time after pfet is turned on
	; Turn on nfet
	AnFET_on			; AnFET on
	mov	A, Beep_Strength
	djnz	ACC, $		
	; Turn off nfet
	AnFET_off			; AnFET off
	mov	A, #150		; 25µs off
	djnz	ACC, $		
	djnz	Temp2, beep_onoff
	; Copy variable
	mov	A, Temp3
	mov	Temp1, A	
beep_off:		; Fets off loop
	djnz	ACC, $
	djnz	Temp1,	beep_off

beep_recharge_done:
	djnz	Temp4,	beep
	BpFET_off			; BpFET off
	mov	Current_Pwm_Limited, Temp5	; Restore value
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Division 16bit unsigned by 16bit unsigned
;
; Dividend shall be in Temp2/Temp1, divisor in Temp4/Temp3
; Result will be in Temp2/Temp1
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
div_u16_by_u16:	
	clr	C       
	mov	Temp5, #0
	mov	Temp6, #0
	mov	B, #0
div_u16_by_u16_div1:
	inc	B      			; Increment counter for each left shift
	mov	A, Temp3   		; Shift left the divisor
	rlc	A      		
	mov	Temp3, A   	
	mov	A, Temp4   	
	rlc	A      	  	
	mov	Temp4, A   	
	jnc	div_u16_by_u16_div1	; Repeat until carry flag is set from high-byte
div_u16_by_u16_div2:        
	mov	A, Temp4   		; Shift right the divisor
	rrc	A      
	mov	Temp4, A   
	mov	A, Temp3   
	rrc	A      
	mov	Temp3, A   
	clr	C      
 	mov	A, Temp2  		; Make a safe copy of the dividend
 	mov	Temp8, A   
 	mov	A, Temp1  		
 	mov	Temp7, A   
 	mov	A, Temp1   		; Move low-byte of dividend into accumulator
	subb	A, Temp3  		; Dividend - shifted divisor = result bit (no factor, only 0 or 1)
 	mov	Temp1, A   		; Save updated dividend 
 	mov	A, Temp2   		; Move high-byte of dividend into accumulator
	subb	A, Temp4  		; Subtract high-byte of divisor (all together 16-bit substraction)
 	mov	Temp2, A   		; Save updated high-byte back in high-byte of divisor
	jnc	div_u16_by_u16_div3	; If carry flag is NOT set, result is 1
  	mov	A, Temp8  		; Otherwise result is 0, save copy of divisor to undo subtraction
 	mov	Temp2, A   
 	mov	A, Temp7  		
 	mov	Temp1, A   
div_u16_by_u16_div3:
	cpl	C      			; Invert carry, so it can be directly copied into result
 	mov	A, Temp5 
	rlc	A      			; Shift carry flag into temporary result
 	mov	Temp5, A   
 	mov	A, Temp6
	rlc	A
 	mov	Temp6,A		
	djnz	B, div_u16_by_u16_div2 	;Now count backwards and repeat until "B" is zero
  	mov	A, Temp6  		; Move result to Temp2/Temp1
 	mov	Temp2, A   
 	mov	A, Temp5  		
 	mov	Temp1, A   
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Multiplication 16bit signed by 8bit unsigned
;
; Multiplicand shall be in Temp2/Temp1, multiplicator in Temp3
; Result will be in Temp2/Temp1. Result will divided by 16
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
mult_s16_by_u8_div_16:
	mov	A, Temp1		; Read input to math registers
	mov	B, Temp2
	mov	Bit_Access, Temp3
	setb	PSW.4		; Select register bank 2 for math routines
	mov	Temp1, A		; Store in math registers
	mov	Temp2, B		
	mov	Temp4, #0		; Set sign in Temp4 and test sign
	jnb	B.7, mult_s16_by_u8_positive	

	mov	Temp4, #0FFh
	cpl	A
	add	A, #1
	mov	Temp1, A
	mov	A, Temp2
	cpl	A
	addc	A, #0
	mov	Temp2, A
mult_s16_by_u8_positive:
	mov	A, Temp1		; Multiply LSB with multiplicator
	mov	B, Bit_Access
	mul	AB
	mov	Temp6, B		; Place MSB in Temp6
	mov	Temp1, A		; Place LSB in Temp1 (result)
	mov	A, Temp2		; Multiply MSB with multiplicator
	mov	B, Bit_Access
	mul	AB
	mov	Temp8, B		; Place in Temp8/7
	mov	Temp7, A
	mov	A, Temp6		; Add up
	add	A, Temp7
	mov	Temp2, A
	mov	A, #0
	addc	A, Temp8
	mov	Temp3, A
	mov	Temp5, #4		; Set number of divisions
mult_s16_by_u8_div_loop:
	clr	C			; Rotate right 
	mov	A, Temp3
	rrc	A
	mov	Temp3, A
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	djnz	Temp5, mult_s16_by_u8_div_loop

	mov	B, Temp4		; Test sign
	jnb	B.7, mult_s16_by_u8_exit	

	mov	A, Temp1
	cpl	A
	add	A, #1
	mov	Temp1, A
	mov	A, Temp2
	cpl	A
	addc	A, #0
	mov	Temp2, A

mult_s16_by_u8_exit:
	mov	A, Temp1		; Store output
	mov	B, Temp2
	clr	PSW.4		; Select normal register bank
	mov	Temp1, A		
	mov	Temp2, B
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
IF MODE <= 1	; Main or tail
calc_governor_target:
	mov	Temp1, #Pgm_Gov_Mode			; Governor mode?
	cjne	@Temp1, #4, governor_speed_check	; Yes
	jmp	calc_governor_target_exit		; No

governor_speed_check:
	; Stop governor for stop RC pulse	
	clr	C
	mov	A, New_Rcp				; Check RC pulse against stop value
	subb	A, #RCP_STOP				; Is pulse below stop value?
	jc	governor_deactivate			; Yes - deactivate

	; Skip speed check if governor is alrady active
	mov	A, Gov_Active
	jnz	governor_target_calc

	; Check speed (do not run governor for low speeds)
	mov	Temp1, #05h				; Default high range activation limit value (~62500 eRPM)
	clr	C
	mov	Temp2, #Pgm_Gov_Range
	cjne	@Temp2, #2, ($+5)

	mov	Temp1, #12h				; Low range activation limit value (~17400 eRPM)

	clr	C
	mov	A, Comm_Period4x_L
	subb	A, #00h
	mov	A, Comm_Period4x_H
	subb	A, Temp1
	jc	governor_activate			; If speed above min limit  - run governor

governor_deactivate:
	mov	A, Gov_Active
	jz	governor_first_deactivate_done; This code is executed continuously. Only execute the code below the first time

	mov	Pwm_Limit_Spoolup, Pwm_Spoolup_Beg
	mov	Spoolup_Limit_Cnt, #255
	mov	Spoolup_Limit_Skip, #1			

governor_first_deactivate_done:
	mov	Current_Pwm, Requested_Pwm	; Set current pwm to requested
	clr	A
	mov	Gov_Target_L, A			; Set target to zero
	mov	Gov_Target_H, A
	mov	Gov_Integral_L, A			; Set integral to zero
	mov	Gov_Integral_H, A
	mov	Gov_Integral_X, A
	mov	Gov_Active, A
	jmp	calc_governor_target_exit

governor_activate:
	mov	Gov_Active, #1

governor_target_calc:
	; Governor calculations
	clr	C
	mov	Temp2, #Pgm_Gov_Range
	mov	A, @Temp2				; Check high or low range (Temp2 has #Pgm_Gov_Range)
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
ENDIF
IF MODE == 2	; Multi
calc_governor_target:
	mov	Temp1, #Pgm_Gov_Mode			; Closed loop mode?
	cjne	@Temp1, #4, governor_target_calc	; Yes - branch
	jmp	calc_governor_target_exit		; No

governor_target_calc:
	; Stop governor for stop RC pulse	
	clr	C
	mov	A, New_Rcp				; Check RC pulse against stop value
	subb	A, #RCP_STOP				; Is pulse below stop value?
	jc	governor_deactivate			; Yes - deactivate

	jmp	governor_activate			; No - activate

governor_deactivate:
	mov	Current_Pwm, Requested_Pwm	; Set current pwm to requested
	clr	A
	mov	Gov_Target_L, A			; Set target to zero
	mov	Gov_Target_H, A
	mov	Gov_Integral_L, A			; Set integral to zero
	mov	Gov_Integral_H, A
	mov	Gov_Integral_X, A
	mov	Gov_Active, A
	jmp	calc_governor_target_exit

governor_activate:
	mov	Temp1, #Pgm_Gov_Mode		; Store gov mode
	mov	A, @Temp1
	mov	Temp5, A
	mov	Gov_Active, #1
	mov	A, Requested_Pwm		; Load requested pwm
	mov	Governor_Req_Pwm, A		; Set governor requested pwm
	; Calculate comm period target 2*(51000/Requested_Pwm)
	mov	Temp1, #38h				; Load 51000
	mov	Temp2, #0C7h
	mov	Temp3, Comm_Period4x_L		; Load comm period
	mov	Temp4, Comm_Period4x_H		
	; Set speed range. Bare Comm_Period4x corresponds to 400k rpm, because it is 500n units
	clr	C
	mov	A, Temp4
	rrc	A
	mov	Temp4, A
	mov	A, Temp3
	rrc	A
	mov	Temp3, A  				; 200k eRPM range here
	; Check range
	mov	A, Temp5
	dec	A
	jz	governor_activate_range_set	; 200k eRPM? - branch
governor_activate_100k:
	clr	C
	mov	A, Temp4
	rrc	A
	mov	Temp4, A
	mov	A, Temp3
	rrc	A
	mov	Temp3, A  				; 100k eRPM range here
	mov	A, Temp5					; Check range again
	dec	A
	dec	A
	jz	governor_activate_range_set	; 100k eRPM? - branch
governor_activate_50k:
	clr	C
	mov	A, Temp4
	rrc	A
	mov	Temp4, A
	mov	A, Temp3
	rrc	A
	mov	Temp3, A  				; 50k eRPM range here
governor_activate_range_set:
	call	div_u16_by_u16
	; Store governor target
	mov	Gov_Target_L, Temp1
	mov	Gov_Target_H, Temp2
calc_governor_target_exit:
	ret						
ENDIF

; Second governor routine - calculate governor proportional error
calc_governor_prop_error:
	; Exit if governor is inactive
	mov	A, Gov_Active
	jz	calc_governor_prop_error_exit

IF MODE <= 1	; Main or tail
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
ENDIF
IF MODE == 2	; Multi
	; Calculate error
	clr	C
	mov	A, Gov_Target_L
	subb	A, Governor_Req_Pwm
	mov	Temp1, A
	mov	A, Gov_Target_H
	subb	A, #0
	mov	Temp2, A
ENDIF
	; Check error and limit
	jnc	governor_check_prop_limit_pos	; Check carry

	clr	C
	mov	A, Temp1
	subb	A, #80h					; Is error too negative?
	mov	A, Temp2
	subb	A, #0FFh
	jc	governor_limit_prop_error_neg	; Yes - limit
	jmp	governor_store_prop_error

governor_check_prop_limit_pos:
	clr	C
	mov	A, Temp1
	subb	A, #7Fh					; Is error too positive?
	mov	A, Temp2
	subb	A, #00h
	jnc	governor_limit_prop_error_pos	; Yes - limit
	jmp	governor_store_prop_error

governor_limit_prop_error_pos:
	mov	Temp1, #7Fh				; Limit to max positive (2's complement)
	mov	Temp2, #00h
	jmp	governor_store_prop_error

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
	mov	A, Gov_Proportional_L
	add	A, Gov_Integral_L
	mov	Temp1, A
	mov	A, Gov_Proportional_H
	addc	A, Gov_Integral_H
	mov	Temp2, A
	mov	Bit_Access, Gov_Proportional_H		; Sign extend high byte
	clr	A
	jnb	Bit_Access.7, ($+4)			
	cpl	A
	addc	A, Gov_Integral_X
	mov	Temp3, A
	; Check integral and limit
	jnb	ACC.7, governor_check_int_limit_pos	; Check sign bit

	clr	C
	mov	A, Temp3
	subb	A, #0F0h					; Is error too negative?
	jc	governor_limit_int_error_neg	; Yes - limit
	jmp	governor_check_pwm

governor_check_int_limit_pos:
	clr	C
	mov	A, Temp3
	subb	A, #0Fh					; Is error too positive?
	jnc	governor_limit_int_error_pos	; Yes - limit
	jmp	governor_check_pwm

governor_limit_int_error_pos:
	mov	Temp1, #0FFh				; Limit to max positive (2's complement)
	mov	Temp2, #0FFh
	mov	Temp3, #0Fh
	jmp	governor_check_pwm

governor_limit_int_error_neg:
	mov	Temp1, #00h				; Limit to max negative (2's complement)
	mov	Temp2, #00h
	mov	Temp3, #0F0h

governor_check_pwm:
	; Check current pwm
	clr	C
	mov	A, Current_Pwm
	subb	A, Pwm_Limit				; Is current pwm at or above pwm limit?
	jnc	governor_int_max_pwm		; Yes - branch

	mov	A, Current_Pwm				; Is current pwm at zero?
	jz	governor_int_min_pwm		; Yes - branch

	ajmp	governor_store_int_error		; No - store integral error

governor_int_max_pwm:
	mov	A, Gov_Proportional_H
	jb	ACC.7, calc_governor_int_error_exit	; Is proportional error negative - branch (high byte is always zero)
	ajmp	governor_store_int_error		; Positive - store integral error

governor_int_min_pwm:
	mov	A, Gov_Proportional_H
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
	; Load proportional gain
	mov	Temp1, #Pgm_Gov_P_Gain_Decoded; Load proportional gain
	mov	A, @Temp1				
	mov	Temp3, A					; Store in Temp3
	; Load proportional
	clr	C
	mov	A, Gov_Proportional_L		; Nominal multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Gov_Proportional_H
	rlc	A
	mov	Temp2, A
	; Apply gain
	call	mult_s16_by_u8_div_16
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
	jmp	governor_store_prop_corr		; No - store proportional correction

governor_corr_prop_min_pwm:
	mov	Temp1, #1					; Load minimum pwm
	jmp	governor_store_prop_corr

governor_corr_neg_prop:
	; Add negative proportional
	mov	A, Temp1
	cpl	A
	add	A, #1
	add	A, Governor_Req_Pwm
	mov	Temp1, A
	; Check result
	jc	governor_corr_prop_max_pwm	; Is result above max?
	jmp	governor_store_prop_corr		; No - store proportional correction

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
	; Load integral gain
	mov	Temp1, #Pgm_Gov_I_Gain_Decoded; Load integral gain
	mov	A, @Temp1				
	mov	Temp3, A					; Store in Temp3
	; Load integral
	mov	Temp1, Gov_Integral_H
	mov	Temp2, Gov_Integral_X
	; Apply gain
	call	mult_s16_by_u8_div_16
	; Check integral and limit
	mov	A, Temp2
	jnb	ACC.7, governor_check_int_corr_limit_pos	; Check sign bit

	clr	C
	mov	A, Temp1
	subb	A, #01h					; Is integral too negative?
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
	mov	Temp1, #01h				; Limit to max negative (2's complement)
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
	mov	Temp1, #0					; Load minimum pwm
	jmp	governor_store_int_corr

governor_corr_neg_int:
	; Add negative integral
	mov	A, Temp1
	cpl	A
	add	A, #1
	add	A, Gov_Prop_Pwm
	mov	Temp1, A
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
	; If tail, then exit
	jmp	measure_lipo_exit
ENDIF
measure_lipo_start:
	; Load programmed low voltage limit
	mov	Temp1, #Pgm_Low_Voltage_Lim	; Load limit
	mov	A, @Temp1				
	mov	Bit_Access, A				; Store in Bit_Access
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
	mov	A, #ADC_LIMIT_H		; Divide 3.0V value by 2
	rrc	A
	mov	Temp6, A
	mov	A, #ADC_LIMIT_L
	rrc	A
	mov	Temp5, A
	mov	A, #ADC_LIMIT_L		; Calculate 1.5*3.0V=4.5V value
	add	A, Temp5
	mov	Temp5, A
	mov	A, #ADC_LIMIT_H		
	addc	A, Temp6
	mov	Temp6, A
	mov	A, Temp5				; Copy step
	mov	Temp3, A
	mov	A, Temp6	
	mov	Temp4, A
measure_lipo_cell_loop:
	; Check voltage against xS lower limit
	clr	C
	mov	A, Temp1
	subb	A, Temp3				; Voltage above limit?
	mov	A, Temp2
	subb A, Temp4
	jc	measure_lipo_adjust		; No - branch

	; Set xS voltage limit
	mov	A, Lipo_Adc_Limit_L		
	add	A, #ADC_LIMIT_L
	mov	Lipo_Adc_Limit_L, A
	mov	A, Lipo_Adc_Limit_H		
	addc	A, #ADC_LIMIT_H
	mov	Lipo_Adc_Limit_H, A
	; Set (x+1)S lower limit
	mov	A, Temp3
	add	A, Temp5				; Add step
	mov	Temp3, A
	mov	A, Temp4
	addc	A, Temp6
	mov	Temp4, A
	jmp	measure_lipo_cell_loop	; Check for one more battery cell

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
	mov	A, Lipo_Adc_Limit_L		; Set adc reference for voltage compensation
	add	A, Temp1
	mov	Lipo_Adc_Reference_L, A
	mov	A, Lipo_Adc_Limit_H
	addc	A, Temp2
	mov	Lipo_Adc_Reference_H, A
	; Divide three times to get to 3.125%
	mov	Temp3, #3
measure_lipo_divide_loop:
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1	
	rrc	A
	mov	Temp1, A			
	djnz	Temp3, measure_lipo_divide_loop

	; Add the programmed number of 0.1V (or 3.125% increments)
	mov	Temp3, Bit_Access		; Load programmed limit (Bit_Access has Pgm_Low_Voltage_Lim)
	dec	Temp3
	jnz	measure_lipo_limit_on	; Is low voltage limiting on?

	mov	Lipo_Adc_Limit_L, #0	; No - set limit to zero
	mov	Lipo_Adc_Limit_H, #0
	jmp	measure_lipo_exit	

measure_lipo_limit_on:
	dec	Temp3
	mov	A, Temp3
	jz	measure_lipo_update

measure_lipo_add_loop:
	mov	A, Temp7			; Add 3.125%
	add	A, Temp1
	mov	Temp7, A
	mov	A, Temp8
	addc	A, Temp2
	mov	Temp8, A
	djnz	Temp3, measure_lipo_add_loop

measure_lipo_update:
	; Set ADC limit
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
; Check temperature, power supply voltage and limit power
;
; No assumptions
;
; Used to limit main motor power in order to maintain the required voltage
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
check_temp_voltage_and_limit_power:
	; Load programmed low voltage limit
	mov	Temp1, #Pgm_Low_Voltage_Lim	
	mov	A, @Temp1
	mov	Temp8, A					; Store in Temp8		
	; Wait for ADC conversion to complete
	Get_Adc_Status 
	jb	AD0BUSY, check_temp_voltage_and_limit_power
	; Read ADC result
	Read_Adc_Result
	; Stop ADC
	Stop_Adc

	inc	Adc_Conversion_Cnt			; Increment conversion counter
	clr	C
	mov	A, Adc_Conversion_Cnt		; Is conversion count equal to temp rate?
	subb	A, #TEMP_CHECK_RATE
	jc	check_voltage_start			; No - check voltage

	mov	Adc_Conversion_Cnt, #0		; Yes - temperature check. Reset counter
	mov	A, Temp2					; Is temperature reading below 256?
	jnz	temp_average_inc_dec		; No - proceed

	mov	A, Current_Average_Temp		; Yes -  decrement average
	jz	temp_average_updated		; Already zero - no change
	jmp	temp_average_dec			; Decrement 

temp_average_inc_dec:
	clr	C
	mov	A, Temp1					; Check if current temperature is above or below average
	subb	A, Current_Average_Temp
	jz	temp_average_updated_load_acc	; Equal - no change

	mov	A, Current_Average_Temp		; Above - increment average
	jnc	temp_average_inc				

	jz	temp_average_updated		; Below - decrement average if average is not already zero
temp_average_dec:
	dec	A						; Decrement average
	jmp	temp_average_updated

temp_average_inc:
	inc	A						; Increment average
	jz	temp_average_dec
	jmp	temp_average_updated

temp_average_updated_load_acc:
	mov	A, Current_Average_Temp
temp_average_updated:
	mov	Current_Average_Temp, A
	clr	C
	subb	A, #TEMP_LIMIT				; Is temperature below first limit?
	mov	Temp1, A
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

check_voltage_start:
IF MODE == 0 OR MODE == 2	; Main or multi
	; Check if low voltage limiting is enabled
	mov	A, Temp8
	clr	C
	subb	A, #1					; Is low voltage limit disabled?
	jz	check_voltage_good			; Yes - voltage declared good

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
	mov	A, Current_Pwm
	subb	A, Temp1
	jnc	check_voltage_spoolup_lim	; If current pwm above limit - branch and limit	

	mov	Temp1, Current_Pwm			; Set current pwm (no limiting)

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
	cjne	A, #(TEMP_CHECK_RATE-1), ($+6)

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
	; Set pwm values according to startup phase flags
	jnb	Flags1.SETTLE_PHASE, ($+5)		; Is it motor start settle phase?
	mov	Temp1, #PWM_SETTLE				; Yes - set settle power
	jnb	Flags1.STEPPER_PHASE, ($+5)		; Is it motor start stepper phase?
	mov	Temp1, #PWM_STEPPER				; Yes - set stepper power

	; Update pwm variables if any startup phase flag is set
	mov	A, Flags1
	anl	A, #((1 SHL SETTLE_PHASE)+(1 SHL STEPPER_PHASE))
	jz	startup_pwm_exit				; If no startup phase set - exit

	; Adjust startup power
	mov	A, Temp1						; Multiply startup power by programmed value
	mov	Temp2, #Pgm_Startup_Pwr_Decoded
	mov	B, @Temp2
	mul	AB
	xch	A, B
	mov	C, B.7						; Multiply result by 2 (unity gain is 128)
	rlc	A
	mov	Temp1, A						; Transfer to Temp1
	clr	C
	mov	A, Temp1						; Check against limit
	subb	A, Pwm_Limit	
	jc	startup_pwm_set_pwm				; If pwm below limit - branch

	mov	Temp1, Pwm_Limit				; Limit pwm

startup_pwm_set_pwm:
	; Set pwm variables
	mov	Requested_Pwm, Temp1			; Update requested pwm
	mov	Current_Pwm, Temp1				; Update current pwm
	mov	Current_Pwm_Limited, Temp1		; Update limited version of current pwm
	jnb	Flags1.SETTLE_PHASE, startup_pwm_exit	; Is it motor start settle phase?

	mov	Pwm_Spoolup_Beg, Temp1			; Yes - update spoolup beginning pwm (will use PWM_SETTLE or PWM_SETTLE/2)			

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
	; Load programmed startup rpm
	mov	Temp1, #Pgm_Startup_Rpm		; Load startup rpm
	mov	A, @Temp1				
	mov	Temp8, A					; Store in Temp8
	; Check startup rpm setting and set step accordingly
	clr	C
	mov	A, Temp8
	subb	A, #5
	jnc	stepper_step_high
	clr	C
	mov	A, Temp8
	subb	A, #4
	jnc	stepper_step_med_high
	clr	C
	mov	A, Temp8
	subb	A, #3
	jnc	stepper_step_med
	clr	C
	mov	A, Temp8
	subb	A, #2
	jnc	stepper_step_med_low
	clr	C
	mov	A, Temp8
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
	mov	Comm_Period4x_L, #00h				; Set commutation period registers
	mov	Comm_Period4x_H, #08h
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

calc_next_comm_timing:		; Entry point for run phase
	mov	Temp1, Wt_Advance_L	; Set up advance timing wait 
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
	mov	Comm_Period4x_L, #0FFh	; Set commutation period registers to very slow timing (0xffff)
	mov	Comm_Period4x_H, #0FFh
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait advance timing routine
;
; No assumptions
;
; Waits for the advance timing to elapse
; Also sets up timer 1 to wait the zero cross scan wait time
; And has a separate entry point for just setting up zero cross scan wait
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait_advance_timing:	
	jnb	Flags0.T3_PENDING, ($+5)
	ajmp	wait_advance_timing

setup_zc_scan_wait:
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
	; Load programmed commutation timing
	mov	Temp1, #Pgm_Comm_Timing	; Load timing setting
	mov	A, @Temp1				
	mov	Temp8, A				; Store in Temp8
	mov	Temp7, #(COMM_TIME_RED SHL 1)	
	jnb	Flags0.DEMAG_DETECTED, calc_new_wait_check_startup	; Demag detected?

	mov	Temp8, #5				; Yes - set high timing

calc_new_wait_check_startup:
	jnb	Flags1.DIRECT_STARTUP_PHASE, calc_new_wait_dir_start_set	; Set timing for direct start

	mov	Temp8, #3				; Set medium timing
	mov	Temp7, #0				; Set no comm time reduction

calc_new_wait_dir_start_set:
	; Load current commutation timing
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
	subb	A, Temp7
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
	mov	A, Temp8				; (Temp8 has Pgm_Comm_Timing)
	subb	A, #3				; Is timing normal?
	jz	store_times_decrease	; Yes - branch

	mov	A, Temp8				
	jb	ACC.0, adjust_timing_two_steps	; If an odd number - branch

	mov	A, Temp1				; Add 7.5° and store in Temp1/2
	add	A, Temp5
	mov	Temp1, A
	mov	A, Temp2
	addc	A, Temp6
	mov	Temp2, A
	mov	A, Temp5				; Store 7.5° in Temp3/4
	mov	Temp3, A
	mov	A, Temp6			
	mov	Temp4, A
	jmp	store_times_up_or_down

adjust_timing_two_steps:
	mov	A, Temp1				; Add 15° and store in Temp1/2
	add	A, Temp1
	mov	Temp1, A
	mov	A, Temp2
	addc	A, Temp2
	mov	Temp2, A
	mov	Temp3, #(COMM_TIME_MIN SHL 1)	; Store minimum time in Temp3/4
	clr	A
	mov	Temp4, A

store_times_up_or_down:
	clr	C
	mov	A, Temp8				
	subb	A, #3				; Is timing higher than normal?
	jc	store_times_decrease	; No - branch

store_times_increase:
	mov	Wt_Comm_L, Temp3		; Now commutation time (~60°) divided by 4 (~15° nominal)
	mov	Wt_Comm_H, Temp4
	mov	Wt_Advance_L, Temp1		; New commutation advance time (~15° nominal)
	mov	Wt_Advance_H, Temp2
	mov	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5°)
	mov	Wt_Zc_Scan_H, Temp6
	ret

store_times_decrease:
	mov	Wt_Comm_L, Temp1		; Now commutation time (~60°) divided by 4 (~15° nominal)
	mov	Wt_Comm_H, Temp2
	mov	Wt_Advance_L, Temp3		; New commutation advance time (~15° nominal)
	mov	Wt_Advance_H, Temp4
	mov	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5°)
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
	ajmp	wait_before_zc_scan

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
	mov	Comp_Wait_Reads, #0
	mov	Bit_Access, #00h			; Desired comparator output
	jmp	wait_for_comp_out_start

wait_for_comp_out_high:
	mov	Comp_Wait_Reads, #0
	mov	Bit_Access, #40h			; Desired comparator output

wait_for_comp_out_start:
	setb	EA						; Enable interrupts
	inc	Comp_Wait_Reads
	jb	Flags0.T3_PENDING, ($+4)		; Has zero cross scan timeout elapsed?
	ret							; Yes - return

	; Set default comparator response times
	mov	CPT0MD, #0				; Set fast response (100ns) as default		
IF COMP1_USED==1			
	mov	CPT1MD, #0				; Set fast response (100ns) as default		
ENDIF
	; Select number of comparator readings based upon current rotation speed
	mov 	A, Comm_Period4x_H			; Load rotation period
	clr	C
	rrc	A						; Divide by 4
	clr	C
	rrc	A
	mov	Temp1, A
	inc	Temp1					; Add one to be sure it is always larger than zero
	jz	comp_wait_on_comp_able		; If minimum number of readings - jump directly to reading
	; For damped mode, do fewer comparator readings (since comparator info is primarily only available in the pwm on period)
	jnb	Flags2.PGM_PWMOFF_DAMPED, comp_wait_set_max_readings

	clr	C
	rrc	A						; Divide by 4 again
	clr	C
	rrc	A
	mov	Temp1, A
	inc	Temp1					; Add one to be sure it is always larger than zero

comp_wait_set_max_readings:
	clr	C
	mov	A, Temp1					; Limit to a max of 10
	subb	A, #10
	jc	($+4)

	mov	Temp1, #10

	jnb	Flags2.PGM_PWM_HIGH_FREQ, comp_wait_set_response_time	; Jump if pwm frequency is low

	clr	C
	mov	A, Temp1					; Limit to a max of 4
	subb	A, #4
	jc	($+4)

	mov	Temp1, #4

comp_wait_set_response_time:
	clr	C
	mov	A, Comm_Period4x_H			; Is Comm_Period4x_H less than 1ms?
	subb	A, #8
	jc	comp_wait_on_comp_able		; Yes - jump

	mov	CPT0MD, #2				; Set medium response (300ns)
IF COMP1_USED==1			
	mov	CPT1MD, #2				; Set medium response (300ns)
ENDIF
	clr	C
	mov	A, Comm_Period4x_H			; Is Comm_Period4x_H less than 2ms?
	subb	A, #16
	jc	comp_wait_on_comp_able		; Yes - jump

	mov	CPT0MD, #3				; Set slow response (1000ns) 	
IF COMP1_USED==1			
	mov	CPT1MD, #3				; Set slow response (1000ns) 	
ENDIF

comp_wait_on_comp_able:
	jb	Flags0.T3_PENDING, ($+6)		; Has zero cross scan timeout elapsed?
	setb	EA						; Enable interrupts
	ret							; Yes - return

	mov	Temp2, #COMP_PWM_HIGH_ON_DELAY	; Wait time after pwm has been switched on (motor wire electrical settling)
	jb	Flags2.PGM_PWM_HIGH_FREQ, ($+5)
	mov	Temp2, #COMP_PWM_LOW_ON_DELAY
	setb	EA							; Enable interrupts
	nop								; Allocate only just enough time to capture interrupt
	nop
	clr	EA							; Disable interrupts
	jb	Flags0.PWM_ON, pwm_wait_startup	; If pwm on - proceed

	mov	Temp2, #COMP_PWM_HIGH_OFF_DELAY	; Wait time after pwm has been switched off (motor wire electrical settling)
	jb	Flags2.PGM_PWM_HIGH_FREQ, ($+5)
	mov	Temp2, #COMP_PWM_LOW_OFF_DELAY	
	jnb	Flags2.CURR_PWMOFF_COMP_ABLE, comp_wait_on_comp_able	; If comparator is not usable in pwm off - go back

pwm_wait_startup:						
	jnb	Flags1.DIRECT_STARTUP_PHASE, pwm_wait	; Set a long delay from pwm on/off events during direct startup

	mov	Temp2, #120
pwm_wait:						
	clr	C
	mov	A, TL1
	subb	A, Temp2
IF DAMPED_MODE_ENABLE==0				
	jc	comp_wait_on_comp_able		; Re-evaluate pwm cycle for slower escs
ENDIF
IF DAMPED_MODE_ENABLE==1				; Assume same pwm cycle for fast escs
	jb	Flags1.DIRECT_STARTUP_PHASE, ($+5)
	jc	pwm_wait
	jc	comp_wait_on_comp_able		; Re-evaluate pwm cycle during direct start
ENDIF

comp_read:
	Read_Comp_Out 					; Read comparator output
	cpl	A
	anl	A, #40h
	cjne	A, Bit_Access, ($+5)		; If comparator output is correct - proceed

	ajmp	wait_for_comp_out_start		; If comparator output is not correct - go back and restart

	djnz	Temp1, comp_wait_on_comp_able	; Decrement readings counter - repeat comparator reading if not zero

	setb	EA						; Enable interrupts
	ret							


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Evaluate comparator integrity
;
; No assumptions
;
; Checks comparator signal behaviour versus expected behaviour
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
evaluate_comparator_integrity:
	clr	Flags0.DEMAG_DETECTED			; Clear demag detected flag
	; Check if demag compensation is enabled
	mov	Temp1, #Pgm_Demag_Comp			; Load programmed demag compensation
	mov	A, @Temp1				
	dec	A
	jz	eval_comp_no_demag

	; Check if a demag situation has occurred
	mov	A, Comp_Wait_Reads				; Check if there were no waits (there shall be some). If none a demag situation has occurred
	dec	A
	jnz	eval_comp_no_demag

	setb	Flags0.DEMAG_DETECTED			; Set demag detected flag

eval_comp_no_demag:
	jnb	Flags1.DIRECT_STARTUP_PHASE, eval_comp_check_timeout

	inc	Direct_Startup_Ok_Cnt			; Increment ok counter
	jb	Flags0.T3_PENDING, eval_comp_exit

	mov	Direct_Startup_Ok_Cnt, #0		; Reset ok counter
	jmp	eval_comp_exit

eval_comp_check_timeout:
	jb	Flags0.T3_PENDING, eval_comp_exit	; Has timeout elapsed?
	dec	SP							; Routine exit without "ret" command
	dec	SP
	ljmp	run_to_wait_for_power_on			; Yes - exit run mode

eval_comp_exit:
	ret


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
	; Store motor power
	mov	Temp7, Current_Pwm_Limited			
	; Check if a demag situation has occurred
	jnb	Flags0.DEMAG_DETECTED, wait_for_comm_wait; Demag detected?

	; Load programmed demag compensation
	mov	Temp1, #Pgm_Demag_Comp_Power_Decoded	; Yes - load programmed demag compensation power decoded
	mov	A, @Temp1				
	mov	Temp8, A							; Store in Temp8

	; Check for first power off
	cjne	Temp8, #1, wait_for_comm_blind

	setb	Flags0.DEMAG_CUT_POWER				; Turn off motor power
	mov	Current_Pwm_Limited, #0				
	All_nFETs_off

	; Wait a blind wait
wait_for_comm_blind:
	call	setup_zc_scan_wait					; Setup a zero cross scan wait (7.5 deg)
wait_demag_default_zc1:	
	jnb	Flags0.DEMAG_CUT_POWER, ($+6)			; Cut motor power if set
	mov	Current_Pwm_Limited, #0			
	jnb	Flags0.T3_PENDING, ($+5)
	ajmp	wait_demag_default_zc1

	; Check for second power off
	cjne	Temp8, #2, wait_for_comm_second_blind_wait

	setb	Flags0.DEMAG_CUT_POWER				; Turn off motor power
	mov	Current_Pwm_Limited, #0				
	All_nFETs_off

	; Check for another blind wait
wait_for_comm_second_blind_wait:
	mov	Temp1, #Pgm_Demag_Comp_Wait_Decoded	; Yes - load programmed demag compensation wait decoded
	cjne	@Temp1, #1, wait_for_comm_power3

	call	setup_zc_scan_wait					; Setup a zero cross scan wait (7.5 deg)
wait_demag_default_zc2:	
	jnb	Flags0.DEMAG_CUT_POWER, ($+6)			; Cut motor power if set
	mov	Current_Pwm_Limited, #0			
	jnb	Flags0.T3_PENDING, ($+5)
	ajmp	wait_demag_default_zc2

wait_for_comm_power3:
	; Check for third power off
	cjne	Temp8, #3, wait_for_comm_setup

	setb	Flags0.DEMAG_CUT_POWER				; Turn off motor power
	mov	Current_Pwm_Limited, #0				
	All_nFETs_off

wait_for_comm_setup:
	call	setup_comm_wait					; Setup commutation wait
wait_for_comm_wait:
	jnb	Flags0.DEMAG_CUT_POWER, ($+6)			; Cut motor power if set
	mov	Current_Pwm_Limited, #0			
	jnb Flags0.T3_PENDING, ($+5)				
	ajmp	wait_for_comm_wait					

	jnb	Flags0.DEMAG_DETECTED, wait_for_comm_exit	; Was there a demag situation?

	clr	Flags0.DEMAG_CUT_POWER				; Restore motor power again
	mov	Current_Pwm_Limited, Temp7			

wait_for_comm_exit:
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
	jb	Flags2.PGM_PWMOFF_DAMPED, comm12_damp
	jmp	comm12_nondamp
comm12_damp:
IF DAMPED_MODE_ENABLE == 0
	mov	DPTR, #pwm_cnfet_apfet_on_fast
	jb	Flags2.PGM_PWMOFF_DAMPED_LIGHT, comm12_nondamp
ENDIF
IF DAMPED_MODE_ENABLE == 1
	mov	DPTR, #pwm_cnfet_apfet_on_safe	
ENDIF
	jnb	Flags2.CURR_PWMOFF_DAMPED, comm12_nondamp		; If pwm off not damped - branch
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
	jb	Flags2.PGM_PWMOFF_DAMPED, comm23_damp
	jmp	comm23_nondamp
comm23_damp:
IF DAMPED_MODE_ENABLE == 0
	mov	DPTR, #pwm_bnfet_apfet_on_fast
ENDIF
IF DAMPED_MODE_ENABLE == 1
	mov	DPTR, #pwm_bnfet_apfet_on_safe	
ENDIF
	jnb	Flags2.CURR_PWMOFF_DAMPED, comm23_nfet			; If pwm off not damped - branch
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
	jb	Flags2.PGM_PWMOFF_DAMPED, comm34_damp
	jmp	comm34_nondamp
comm34_damp:
IF DAMPED_MODE_ENABLE == 0
	mov	DPTR, #pwm_bnfet_cpfet_on_fast
	jb	Flags2.PGM_PWMOFF_DAMPED_LIGHT, comm34_nondamp
ENDIF
IF DAMPED_MODE_ENABLE == 1
	mov	DPTR, #pwm_bnfet_cpfet_on_safe
ENDIF
	jnb	Flags2.CURR_PWMOFF_DAMPED, comm34_nondamp		; If pwm off not damped - branch
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
	jb	Flags2.PGM_PWMOFF_DAMPED, comm45_damp
	jmp	comm45_nondamp
comm45_damp:
IF DAMPED_MODE_ENABLE == 0
	mov	DPTR, #pwm_anfet_cpfet_on_fast
ENDIF
IF DAMPED_MODE_ENABLE == 1
	mov	DPTR, #pwm_anfet_cpfet_on_safe
ENDIF
	jnb	Flags2.CURR_PWMOFF_DAMPED, comm45_nfet			; If pwm off not damped - branch
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
	jb	Flags2.PGM_PWMOFF_DAMPED, comm56_damp
	jmp	comm56_nondamp
comm56_damp:
IF DAMPED_MODE_ENABLE == 0
	mov	DPTR, #pwm_anfet_bpfet_on_fast
	jb	Flags2.PGM_PWMOFF_DAMPED_LIGHT, comm56_nondamp
ENDIF
IF DAMPED_MODE_ENABLE == 1
	mov	DPTR, #pwm_anfet_bpfet_on_safe
ENDIF
	jnb	Flags2.CURR_PWMOFF_DAMPED, comm56_nondamp		; If pwm off not damped - branch
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
	jb	Flags2.PGM_PWMOFF_DAMPED, comm61_damp
	jmp	comm61_nondamp
comm61_damp:
IF DAMPED_MODE_ENABLE == 0
	mov	DPTR, #pwm_cnfet_bpfet_on_fast
ENDIF
IF DAMPED_MODE_ENABLE == 1
	mov	DPTR, #pwm_cnfet_bpfet_on_safe
ENDIF
	jnb	Flags2.CURR_PWMOFF_DAMPED, comm61_nfet			; If pwm off not damped - branch
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
	; Load programmed startup acceleration
	mov	Temp1, #Pgm_Startup_Accel	; Load startup accel
	mov	A, @Temp1				
	mov	Temp8, A					; Store in Temp8
	; Check acceleration setting and set step size accordingly
	clr	C
	mov	A, Temp8
	subb	A, #5
	jnc	dec_step_high
	clr	C
	mov	A, Temp8
	subb	A, #4
	jnc	dec_step_med_high
	clr	C
	mov	A, Temp8
	subb	A, #3
	jnc	dec_step_med
	clr	C
	mov	A, Temp8
	subb	A, #2
	jnc	dec_step_med_low
	clr	C
	mov	A, Temp8
	subb	A, #1
	jnc	dec_step_low

dec_step_high:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(30 SHL 1)		
	mov	Temp1, A
	jmp	decrement_step_exit
dec_step_med_high:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(20 SHL 1)		
	mov	Temp1, A
	jmp	decrement_step_exit
dec_step_med:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(13 SHL 1)		
	mov	Temp1, A
	jmp	decrement_step_exit
dec_step_med_low:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(9 SHL 1)		
	mov	Temp1, A
	jmp	decrement_step_exit
dec_step_low:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(5 SHL 1)		
	mov	Temp1, A
	jmp	decrement_step_exit

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
	jnb Flags0.T3_PENDING, ($+6)	; Timer pending?
	ljmp	stepper_timer_wait		; Yes, go back
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
	mov	Temp1, #Pgm_Gov_P_Gain
	mov	@Temp1, #DEFAULT_PGM_MAIN_P_GAIN
	mov	Temp1, #Pgm_Gov_I_Gain
	mov	@Temp1, #DEFAULT_PGM_MAIN_I_GAIN
	mov	Temp1, #Pgm_Gov_Mode
	mov	@Temp1, #DEFAULT_PGM_MAIN_GOVERNOR_MODE
	mov	Temp1, #Pgm_Gov_Range
	mov	@Temp1, #DEFAULT_PGM_MAIN_GOVERNOR_RANGE
	mov	Temp1, #Pgm_Low_Voltage_Lim
	mov	@Temp1, #DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM
	mov	Temp1, #Pgm_Startup_Pwr
	mov	@Temp1, #DEFAULT_PGM_MAIN_STARTUP_PWR
	mov	Temp1, #Pgm_Startup_Rpm
	mov	@Temp1, #DEFAULT_PGM_MAIN_STARTUP_RPM
	mov	Temp1, #Pgm_Startup_Accel
	mov	@Temp1, #DEFAULT_PGM_MAIN_STARTUP_ACCEL
	mov	Temp1, #Pgm_Startup_Method
	mov	@Temp1, #DEFAULT_PGM_MAIN_STARTUP_METHOD
	mov	Temp1, #Pgm_Comm_Timing
	mov	@Temp1, #DEFAULT_PGM_MAIN_COMM_TIMING
	mov	Temp1, #Pgm_Throttle_Rate
	mov	@Temp1, #DEFAULT_PGM_MAIN_THROTTLE_RATE
	mov	Temp1, #Pgm_Damping_Force
	mov	@Temp1, #DEFAULT_PGM_MAIN_DAMPING_FORCE
	mov	Temp1, #Pgm_Pwm_Freq
	mov	@Temp1, #DEFAULT_PGM_MAIN_PWM_FREQ
	mov	Temp1, #Pgm_Demag_Comp
	mov	@Temp1, #DEFAULT_PGM_MAIN_DEMAG_COMP
	mov	Temp1, #Pgm_Direction_Rev
	mov	@Temp1, #DEFAULT_PGM_MAIN_DIRECTION_REV
	mov	Temp1, #Pgm_Input_Pol
	mov	@Temp1, #DEFAULT_PGM_MAIN_RCP_PWM_POL
	mov	Temp1, #Pgm_Motor_Idle
	mov	@Temp1, #0
ENDIF
IF MODE == 1	; Tail
	mov	Temp1, #Pgm_Motor_Gain
	mov	@Temp1, #DEFAULT_PGM_TAIL_GAIN
	mov	Temp1, #Pgm_Motor_Idle
	mov	@Temp1, #DEFAULT_PGM_TAIL_IDLE_SPEED
	mov	Temp1, #Pgm_Startup_Pwr
	mov	@Temp1, #DEFAULT_PGM_TAIL_STARTUP_PWR
	mov	Temp1, #Pgm_Startup_Rpm
	mov	@Temp1, #DEFAULT_PGM_TAIL_STARTUP_RPM
	mov	Temp1, #Pgm_Startup_Accel
	mov	@Temp1, #DEFAULT_PGM_TAIL_STARTUP_ACCEL
	mov	Temp1, #Pgm_Startup_Method
	mov	@Temp1, #DEFAULT_PGM_TAIL_STARTUP_METHOD
	mov	Temp1, #Pgm_Comm_Timing
	mov	@Temp1, #DEFAULT_PGM_TAIL_COMM_TIMING
	mov	Temp1, #Pgm_Throttle_Rate
	mov	@Temp1, #DEFAULT_PGM_TAIL_THROTTLE_RATE
	mov	Temp1, #Pgm_Damping_Force
	mov	@Temp1, #DEFAULT_PGM_TAIL_DAMPING_FORCE
	mov	Temp1, #Pgm_Pwm_Freq
	mov	@Temp1, #DEFAULT_PGM_TAIL_PWM_FREQ
	mov	Temp1, #Pgm_Demag_Comp
	mov	@Temp1, #DEFAULT_PGM_TAIL_DEMAG_COMP
	mov	Temp1, #Pgm_Direction_Rev
	mov	@Temp1, #DEFAULT_PGM_TAIL_DIRECTION_REV
	mov	Temp1, #Pgm_Input_Pol
	mov	@Temp1, #DEFAULT_PGM_TAIL_RCP_PWM_POL
	mov	Temp1, #Pgm_Gov_Mode
	mov	@Temp1, #4
ENDIF
IF MODE == 2	; Multi
	mov	Temp1, #Pgm_Gov_P_Gain
	mov	@Temp1, #DEFAULT_PGM_MAIN_P_GAIN
	mov	Temp1, #Pgm_Gov_I_Gain
	mov	@Temp1, #DEFAULT_PGM_MAIN_I_GAIN
	mov	Temp1, #Pgm_Gov_Mode
	mov	@Temp1, #DEFAULT_PGM_MAIN_GOVERNOR_MODE
	mov	Temp1, #Pgm_Motor_Gain
	mov	@Temp1, #DEFAULT_PGM_MULTI_GAIN
	mov	Temp1, #Pgm_Low_Voltage_Lim
	mov	@Temp1, #DEFAULT_PGM_MULTI_LOW_VOLTAGE_LIM
	mov	Temp1, #Pgm_Startup_Pwr
	mov	@Temp1, #DEFAULT_PGM_MULTI_STARTUP_PWR
	mov	Temp1, #Pgm_Startup_Rpm
	mov	@Temp1, #DEFAULT_PGM_MULTI_STARTUP_RPM
	mov	Temp1, #Pgm_Startup_Accel
	mov	@Temp1, #DEFAULT_PGM_MULTI_STARTUP_ACCEL
	mov	Temp1, #Pgm_Startup_Method
	mov	@Temp1, #DEFAULT_PGM_MULTI_STARTUP_METHOD
	mov	Temp1, #Pgm_Comm_Timing
	mov	@Temp1, #DEFAULT_PGM_MULTI_COMM_TIMING
	mov	Temp1, #Pgm_Throttle_Rate
	mov	@Temp1, #DEFAULT_PGM_MULTI_THROTTLE_RATE
	mov	Temp1, #Pgm_Damping_Force
	mov	@Temp1, #DEFAULT_PGM_MULTI_DAMPING_FORCE
	mov	Temp1, #Pgm_Pwm_Freq
	mov	@Temp1, #DEFAULT_PGM_MULTI_PWM_FREQ
	mov	Temp1, #Pgm_Demag_Comp
	mov	@Temp1, #DEFAULT_PGM_MULTI_DEMAG_COMP
	mov	Temp1, #Pgm_Direction_Rev
	mov	@Temp1, #DEFAULT_PGM_MULTI_DIRECTION_REV
	mov	Temp1, #Pgm_Input_Pol
	mov	@Temp1, #DEFAULT_PGM_MULTI_RCP_PWM_POL
	mov	Temp1, #Pgm_Motor_Idle
	mov	@Temp1, #0
ENDIF
	mov	Temp1, #Pgm_Enable_TX_Program
	mov	@Temp1, #DEFAULT_PGM_ENABLE_TX_PROGRAM
	mov	Temp1, #Pgm_Main_Rearm_Start
	mov	@Temp1, #DEFAULT_PGM_MAIN_REARM_START
	mov	Temp1, #Pgm_Gov_Setup_Target
	mov	@Temp1, #DEFAULT_PGM_MAIN_GOV_SETUP_TARGET
	mov	Temp1, #Pgm_Ppm_Min_Throttle
	mov	@Temp1, #DEFAULT_PGM_PPM_MIN_THROTTLE
	mov	Temp1, #Pgm_Ppm_Max_Throttle
	mov	@Temp1, #DEFAULT_PGM_PPM_MAX_THROTTLE
	mov	Temp1, #Pgm_Beep_Strength
	mov	@Temp1, #DEFAULT_PGM_MAIN_BEEP_STRENGTH
	mov	Temp1, #Pgm_Beacon_Strength
	mov	@Temp1, #DEFAULT_PGM_MAIN_BEACON_STRENGTH
	mov	Temp1, #Pgm_Beacon_Delay
	mov	@Temp1, #DEFAULT_PGM_MAIN_BEACON_DELAY
	mov	Temp1, #Pgm_BEC_Voltage_High
	mov	@Temp1, #DEFAULT_PGM_BEC_VOLTAGE_HIGH
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
	; Load programmed damping force
	mov	Temp1, #Pgm_Damping_Force; Load damping force
	mov	A, @Temp1				
	mov	Temp8, A				; Store in Temp8
	; Decode damping
	mov	Damping_Period, #9		; Set default
	mov	Damping_On, #1
	clr	C
	cjne	Temp8, #2, decode_damping_3	; Look for 2

	mov	Damping_Period, #5
	mov	Damping_On, #1
	jmp	decode_damping_done

decode_damping_3:
	clr	C
	cjne	Temp8, #3, decode_damping_4	; Look for 3

	mov	Damping_Period, #5
	mov	Damping_On, #2
	jmp	decode_damping_done

decode_damping_4:
	clr	C
	cjne	Temp8, #4, decode_damping_5	; Look for 4

	mov	Damping_Period, #5
	mov	Damping_On, #3
	jmp	decode_damping_done

decode_damping_5:
	clr	C
	cjne	Temp8, #5, decode_damping_6	; Look for 5

	mov	Damping_Period, #9
	mov	Damping_On, #7

decode_damping_6:
	clr	C
	cjne	Temp8, #6, decode_damping_done; Look for 6

	mov	Damping_Period, #0
	mov	Damping_On, #0

decode_damping_done:
	; Load programmed pwm frequency
	mov	Temp1, #Pgm_Pwm_Freq	; Load pwm freq
	mov	A, @Temp1				
	mov	Temp8, A				; Store in Temp8
IF MODE == 0	; Main
	clr	Flags2.PGM_PWMOFF_DAMPED_LIGHT
	clr	C
	cjne	Temp8, #3, ($+5)
	setb	Flags2.PGM_PWMOFF_DAMPED_LIGHT
	clr	Flags2.PGM_PWMOFF_DAMPED_FULL
ENDIF
IF MODE >= 1	; Tail or multi
	clr	Flags2.PGM_PWMOFF_DAMPED_LIGHT
	clr	C
	cjne	Temp8, #3, ($+5)
	setb	Flags2.PGM_PWMOFF_DAMPED_LIGHT
	clr	Flags2.PGM_PWMOFF_DAMPED_FULL
	clr	C
	cjne	Temp8, #4, ($+5)
	setb	Flags2.PGM_PWMOFF_DAMPED_FULL
ENDIF
	clr	Flags2.PGM_PWMOFF_DAMPED		; Set damped flag if fully damped or damped light is set
	mov	A, #((1 SHL PGM_PWMOFF_DAMPED_FULL)+(1 SHL PGM_PWMOFF_DAMPED_LIGHT))
	anl	A, Flags2					; Check if any damped mode is set
	jz	($+4)
	setb	Flags2.PGM_PWMOFF_DAMPED
	clr	Flags2.CURR_PWMOFF_DAMPED	; Set non damped status as start
	jz	($+4)
	setb	Flags2.CURR_PWMOFF_DAMPED	; Set non damped status as start if damped
	setb	Flags2.CURR_PWMOFF_COMP_ABLE	; Set comparator usable status
	jz	($+4)
	clr	Flags2.CURR_PWMOFF_COMP_ABLE	; Set comparator not usable status if damped
	clr	Flags3.PGM_DIR_REV
	mov	Temp1, #Pgm_Direction_Rev	
	mov	A, @Temp1				
	jnb	ACC.1, ($+5)
	setb	Flags3.PGM_DIR_REV
	clr	Flags3.PGM_RCP_PWM_POL
	mov	Temp1, #Pgm_Input_Pol	
	mov	A, @Temp1				
	jnb	ACC.1, ($+5)
	setb	Flags3.PGM_RCP_PWM_POL
	clr	C
	mov	A, Temp8			
	subb	A, #2
	jz	decode_pwm_freq_low

	mov	CKCON, #01h		; Timer0 set for clk/4 (22kHz pwm)
	setb	Flags2.PGM_PWM_HIGH_FREQ
	jmp	decode_pwm_freq_end

decode_pwm_freq_low:
	mov	CKCON, #00h		; Timer0 set for clk/12 (8kHz pwm)
	clr	Flags2.PGM_PWM_HIGH_FREQ

decode_pwm_freq_end:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Decode governor gain
;
; No assumptions
;
; Decodes governor gains
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
decode_governor_gains:
	; Decode governor gains
	mov	Temp1, #Pgm_Gov_P_Gain	; Decode governor P gain	
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #GOV_GAIN_TABLE
	movc A, @A+DPTR	
	mov	Temp1, #Pgm_Gov_P_Gain_Decoded
	mov	@Temp1, A	
	mov	Temp1, #Pgm_Gov_I_Gain	; Decode governor P gain
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #GOV_GAIN_TABLE
	movc A, @A+DPTR	
	mov	Temp1, #Pgm_Gov_I_Gain_Decoded
	mov	@Temp1, A	
	call	switch_power_off		; Reset DPTR
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Decode throttle rate
;
; No assumptions
;
; Decodes throttle rate
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
decode_throttle_rate:
	; Decode throttle rate
	mov	Temp1, #Pgm_Throttle_Rate		
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #THROTTLE_RATE_TABLE
	movc A, @A+DPTR	
	mov	Temp1, #Pgm_Throttle_Rate_Decoded
	mov	@Temp1, A	
	call	switch_power_off			; Reset DPTR
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Decode startup power
;
; No assumptions
;
; Decodes startup power
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
decode_startup_power:
	; Decode startup power
	mov	Temp1, #Pgm_Startup_Pwr		
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #STARTUP_POWER_TABLE
	movc A, @A+DPTR	
	mov	Temp1, #Pgm_Startup_Pwr_Decoded
	mov	@Temp1, A	
	call	switch_power_off			; Reset DPTR
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Decode demag compensation
;
; No assumptions
;
; Decodes throttle rate
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
decode_demag_comp:
	; Decode demag compensation
	mov	Temp1, #Pgm_Demag_Comp		
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #DEMAG_WAIT_TABLE
	movc A, @A+DPTR	
	mov	Temp1, #Pgm_Demag_Comp_Wait_Decoded
	mov	@Temp1, A	
	mov	Temp1, #Pgm_Demag_Comp		
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #DEMAG_POWER_TABLE
	movc A, @A+DPTR	
	mov	Temp1, #Pgm_Demag_Comp_Power_Decoded
	mov	@Temp1, A	
	call	switch_power_off			; Reset DPTR
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Set BEC voltage
;
; No assumptions
;
; Sets the BEC output voltage low or high
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
set_bec_voltage:
	; Set bec voltage
IF DUAL_BEC_VOLTAGE == 1
	Set_BEC_Lo			; Set default to low
	mov	Temp1, #Pgm_BEC_Voltage_High		
	mov	A, @Temp1				
	jz	set_bec_voltage_exit	

	Set_BEC_Hi			; Set to high

set_bec_voltage_exit:
ENDIF
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Find throttle gain
;
; The difference between max and min throttle must be more than 520us (a Pgm_Ppm_xxx_Throttle difference of 130)
;
; Finds throttle gain from throttle calibration values
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
find_throttle_gain:
	; Load programmed minimum and maximum throttle
	mov	Temp1, #Pgm_Ppm_Min_Throttle
	mov	A, @Temp1				
	mov	Temp3, A			
	mov	Temp1, #Pgm_Ppm_Max_Throttle
	mov	A, @Temp1				
	mov	Temp4, A			
	; Check if full range is chosen
	jnb	Flags3.FULL_THROTTLE_RANGE, find_throttle_gain_calculate

	mov	Temp3, #0			
	mov	Temp4, #255		

find_throttle_gain_calculate:
	; Calculate difference
	clr	C
	mov	A, Temp4
	subb	A, Temp3
	mov	Temp5, A
	; Check that difference is minimum 130
	clr	C
	subb	A, #130
	jnc	($+4)

	mov	Temp5, #130

	; Find gain
	mov	Ppm_Throttle_Gain, #0
test_gain:
	inc	Ppm_Throttle_Gain
	mov	A, Temp5
	mov	B, Ppm_Throttle_Gain	; A has difference, B has gain
	mul	AB
	clr	C
	mov	A, B
	subb	A, #128
	jc	test_gain
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
IF ONE_S_CAPABLE == 0		
	mov 	RSTSRC, #02h   	; Set VDD monitor as a reset source (PORSF) if not 1S capable                                
ELSE
	mov 	RSTSRC, #00h   	; Do not set VDD monitor as a reset source for 1S ESCSs, in order to avoid resets due to it                              
ENDIF
	; Set clock frequency
	orl	OSCICN, #03h		; Set clock divider to 1
	mov	A, OSCICL				
	add	A, #04h			; 24.5MHz to 24MHz (~0.5% per step)
	jc	reset_cal_done		; Is carry set? - skip next instruction

	mov	OSCICL, A

reset_cal_done:
	; Ports initialization
	mov	P0, #P0_INIT				
	mov	P0MDOUT, #P0_PUSHPULL				
	mov	P0MDIN, #P0_DIGITAL				
	mov	P0SKIP, #P0_SKIP				
	mov	P1, #P1_INIT				
	mov	P1MDOUT, #P1_PUSHPULL				
	mov	P1MDIN, #P1_DIGITAL				
	mov	P1SKIP, #P1_SKIP				
IF PORT3_EXIST == 1
	mov	P2, #P2_INIT				
ENDIF
	mov	P2MDOUT, #P2_PUSHPULL				
IF PORT3_EXIST == 1
	mov	P2MDIN, #P2_DIGITAL				
	mov	P2SKIP, #P2_SKIP				
	mov	P3, #P3_INIT				
	mov	P3MDOUT, #P3_PUSHPULL				
	mov	P3MDIN, #P3_DIGITAL				
ENDIF

	; Initialize the XBAR and related functionality
	Initialize_Xbar		
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
	; Read all programmed parameters
	call read_all_eeprom_parameters
	; Decode parameters
	call	decode_parameters
	; Decode governor gains
	call	decode_governor_gains
	; Decode throttle rate
	call	decode_throttle_rate
	; Decode startup power
	call	decode_startup_power
	; Decode demag compensation
	call	decode_demag_comp
	; Set BEC voltage
	call	set_bec_voltage
	; Find throttle gain from stored min and max settings
	call	find_throttle_gain
	; Set beep strength
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
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

	; Wait for receiver to initialize
	call	wait1s
	call	wait200ms
	call	wait200ms
	call	wait100ms

	; Enable interrupts
	mov	IE, #22h			; Enable timer0 and timer2 interrupts
	mov	IP, #02h			; High priority to timer0 interrupts
	mov	EIE1, #90h		; Enable timer3 and PCA0 interrupts
	mov	EIP1, #10h		; High priority to PCA interrupts
	; Initialize comparator
	mov	CPT0CN, #80h		; Comparator enabled, no hysteresis
	mov	CPT0MD, #03h		; Comparator response time 1us
IF COMP1_USED==1			
	mov	CPT1CN, #80h		; Comparator enabled, no hysteresis
	mov	CPT1MD, #03h		; Comparator response time 1us
ENDIF
	; Initialize ADC
	Initialize_Adc			; Initialize ADC operation
	call	wait1ms
	setb	EA				; Enable all interrupts
	; Measure number of lipo cells
	call Measure_Lipo_Cells			; Measure number of lipo cells
	; Initialize rc pulse
	Rcp_Int_Enable		 			; Enable interrupt
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	clr	Flags2.RCP_EDGE_NO			; Set first edge flag
	call wait200ms
	; Set initial arm variable
	mov	Initial_Arm, #1

	; Measure PWM frequency
measure_pwm_freq_init:	
	setb	Flags0.RCP_MEAS_PWM_FREQ 		; Set measure pwm frequency flag
measure_pwm_freq_start:	
	mov	Temp3, #5						; Number of pulses to measure
measure_pwm_freq_loop:	
	; Check if period diff was accepted
	mov	A, Rcp_Period_Diff_Accepted
	jnz	($+4)

	mov	Temp3, #5						; Reset number of pulses to measure

	call wait3ms						; Wait for next pulse (NB: Uses Temp1/2!) 
	mov	A, New_Rcp					; Load value
	clr	C
	subb	A, #RCP_VALIDATE				; Higher than validate level?
	jc	measure_pwm_freq_start			; No - start over

	mov	A, Flags3						; Check pwm frequency flags
	anl	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	mov	Prev_Rcp_Pwm_Freq, Curr_Rcp_Pwm_Freq		; Store as previous flags for next pulse 
	mov	Curr_Rcp_Pwm_Freq, A					; Store current flags for next pulse 
	cjne	A, Prev_Rcp_Pwm_Freq, measure_pwm_freq_start	; Go back if new flags not same as previous

	djnz	Temp3, measure_pwm_freq_loop				; Go back if not required number of pulses seen

	; Clear measure pwm frequency flag
	clr	Flags0.RCP_MEAS_PWM_FREQ 		
	; Set up RC pulse interrupts after pwm frequency measurement
	Rcp_Int_First 						; Enable interrupt and set to first edge
	Rcp_Clear_Int_Flag 					; Clear interrupt flag
	clr	Flags2.RCP_EDGE_NO				; Set first edge flag
	call wait100ms						; Wait for new RC pulse

	; Validate RC pulse
validate_rcp_start:	
	call wait3ms						; Wait for next pulse (NB: Uses Temp1/2!) 
	mov	Temp1, #RCP_VALIDATE			; Set validate level as default
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3						; Check pwm frequency flags
	jnz	($+4)						; If a flag is set (PWM) - branch

	mov	Temp1, #0						; Set level to zero for PPM (any level will be accepted)

	clr	C
	mov	A, New_Rcp					; Load value
	subb	A, Temp1						; Higher than validate level?
	jc	validate_rcp_start				; No - start over

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
	mov	Temp1, #Pgm_Enable_TX_Program; Yes - start programming mode entry if enabled
	mov	A, @Temp1				
	clr	C
	subb	A, #1				; Is TX programming enabled?
	jnc 	arming_initial_arm_check	; Yes - proceed

	jmp	program_by_tx_checked	; No - branch

arming_initial_arm_check:
	mov	A, Initial_Arm			; Yes - check if it is initial arm sequence
	clr	C
	subb	A, #1				; Is it the initial arm sequence?
	jnc 	arming_ppm_check		; Yes - proceed

	jmp 	program_by_tx_checked	; No - branch

arming_ppm_check:
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3				; Check pwm frequency flags
	jz	throttle_high_cal_start	; If no flag is set (PPM) - branch

	; PWM tx program entry
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_MAX			; Is RC pulse max?
	jnc	program_by_tx_entry_pwm	; Yes - proceed

	jmp	program_by_tx_checked	; No - branch

program_by_tx_entry_pwm:	
	clr	EA					; Disable all interrupts
	call beep_f4
	setb	EA					; Enable all interrupts
	call wait100ms
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_STOP			; Below stop?
	jnc	program_by_tx_entry_pwm	; No - start over

program_by_tx_entry_wait_pwm:	
	clr	EA					; Disable all interrupts
	call beep_f1
	call wait10ms
	call beep_f1
	setb	EA					; Enable all interrupts
	call wait100ms
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_MAX			; At or above max?
	jc	program_by_tx_entry_wait_pwm	; No - start over

	jmp	program_by_tx			; Yes - enter programming mode

	; PPM throttle calibration and tx program entry
throttle_high_cal_start:
	mov	Temp8, #5				; Set 3 seconds wait time
throttle_high_cal:			
	setb	Flags3.FULL_THROTTLE_RANGE	; Set range to 1000-2020us
	call	Find_Throttle_Gain		; Set throttle gain
	call wait100ms				; Wait for new throttle value
	clr	EA					; Disable interrupts (freeze New_Rcp value)
	clr	Flags3.FULL_THROTTLE_RANGE	; Set programmed range
	call	Find_Throttle_Gain		; Set throttle gain
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #(RCP_MAX/2)		; Is RC pulse above midstick?
	setb	EA					; Enable interrupts
	jc	arm_target_updated		; No - branch

	clr	EA					; Disable all interrupts
	call beep_f4
	setb	EA					; Enable all interrupts
	djnz	Temp8, throttle_high_cal	; Yes - continue to wait

	clr	C
	mov	A, New_Rcp			; Limit to max 250
	subb	A, #5				; Subtract about 2% and ensure that it is 250 or lower
	mov	Temp1, #Pgm_Ppm_Max_Throttle	; Store
	mov	@Temp1, A			
	call wait200ms				
	call erase_and_store_all_in_eeprom	
	call	success_beep

throttle_low_cal_start:
	mov	Temp8, #10			; Set 3 seconds wait time
throttle_low_cal:			
	setb	Flags3.FULL_THROTTLE_RANGE	; Set range to 1000-2020us
	call	Find_Throttle_Gain		; Set throttle gain
	call wait100ms
	clr	EA					; Disable interrupts (freeze New_Rcp value)
	clr	Flags3.FULL_THROTTLE_RANGE	; Set programmed range
	call	Find_Throttle_Gain		; Set throttle gain
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #(RCP_MAX/2)		; Below midstick?
	setb	EA					; Enable interrupts
	jnc	throttle_low_cal_start	; No - start over

	clr	EA					; Disable all interrupts
	call beep_f1
	call wait10ms
	call beep_f1
	setb	EA					; Enable all interrupts
	djnz	Temp8, throttle_low_cal	; Yes - continue to wait

	mov	A, New_Rcp			
	add	A, #5				; Add about 2%
	mov	Temp1, #Pgm_Ppm_Min_Throttle	; Store
	mov	@Temp1, A			
	call wait200ms				
	call erase_and_store_all_in_eeprom	
	call	success_beep_inverted

program_by_tx_entry_wait_ppm:	
	call wait100ms
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_MAX			; At or above max?
	jc	program_by_tx_entry_wait_ppm	; No - start over

	jmp	program_by_tx			; Yes - enter programming mode

program_by_tx_checked:
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, Gov_Arm_Target		; Is RC pulse larger than arm target?
	jc	arm_target_updated		; No - do not update

	mov	Gov_Arm_Target, New_Rcp	; Yes - update arm target

arm_target_updated:
	call wait100ms				; Wait for new throttle value
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_STOP			; Below stop?
	jc	arm_end_beep			; Yes - proceed

	jmp	arming_start			; No - start over

arm_end_beep:
	; Beep arm sequence end signal
	clr 	EA					; Disable all interrupts
	call beep_f4				; Signal that rcpulse is ready
	call beep_f4
	call beep_f4
	setb	EA					; Enable all interrupts
	call wait200ms

	; Clear initial arm variable
	mov	Initial_Arm, #0

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
	mov	Temp1, #Pgm_Beacon_Delay
	mov	A, @Temp1
	mov	Temp1, #40		; Approximately 30 sec
	dec	A
	jz	beep_delay_set

	mov	Temp1, #80		; Approximately 1 min
	dec	A
	jz	beep_delay_set

	mov	Temp1, #160		; Approximately 2 min
	dec	A
	jz	beep_delay_set

	mov	Temp1, #240		; Approximately 3 min
	dec	A
	jz	beep_delay_set

	mov	Power_On_Wait_Cnt_H, #0		; Reset counter for infinite delay

beep_delay_set:
	clr	C
	mov	A, Power_On_Wait_Cnt_H
	subb	A, Temp1				; Check against chosen delay
	jc	wait_for_power_on_no_beep; Has delay elapsed?

	dec	Power_On_Wait_Cnt_H		; Decrement high wait counter
	mov	Temp1, #Pgm_Beacon_Strength
	mov	Beep_Strength, @Temp1
	clr 	EA					; Disable all interrupts
	call beep_f4				; Signal that there is no signal
	setb	EA					; Enable all interrupts
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
	call wait100ms				; Wait for new RC pulse to be measured

wait_for_power_on_no_beep:
	call wait3ms
	mov	A, Rcp_Timeout_Cnt				; Load RC pulse timeout counter value
	jnz	wait_for_power_on_ppm_not_missing	; If it is not zero - proceed

	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3						; Check pwm frequency flags
	jnz	wait_for_power_on_ppm_not_missing	; If a flag is set (PWM) - branch

	jmp	measure_pwm_freq_init			; If ppm and pulses missing - go back to measure pwm frequency

wait_for_power_on_ppm_not_missing:
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #(RCP_STOP+5) 		; Higher than stop (plus some hysteresis)?
	jc	wait_for_power_on_loop	; No - start over

	call	wait100ms				; Wait to see if start pulse was only a glitch
	mov	A, Rcp_Timeout_Cnt		; Load RC pulse timeout counter value
	jnz	($+5)				; If it is not zero - proceed

	ljmp	measure_pwm_freq_init	; If it is zero (pulses missing) - go back to measure pwm frequency


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
	mov	Current_Pwm_Limited, A	; Set limited current pwm to zero
	mov	Pwm_Limit, #0FFh		; Set pwm limit to max
	mov	Temp1, #Pgm_Motor_Idle
	mov	Pwm_Motor_Idle, @Temp1	; Set idle pwm to programmed value			
	mov	Gov_Target_L, A		; Set target to zero
	mov	Gov_Target_H, A
	mov	Gov_Integral_L, A		; Set integral to zero
	mov	Gov_Integral_H, A
	mov	Gov_Integral_X, A
	mov	Adc_Conversion_Cnt, A
	mov	Gov_Active, A
	mov	Flags0, A				; Clear flags0
	mov	Flags1, A				; Clear flags1
	mov	Rcp_Stop_Cnt, A		; Set RC pulse stop count to zero
	call initialize_all_timings	; Initialize timing
	;**** **** **** **** ****
	; Motor start beginning
	;**** **** **** **** **** 
	mov	Adc_Conversion_Cnt, #TEMP_CHECK_RATE	; Make sure a temp reading is done
	Set_Adc_Ip_Temp
	call wait1ms
	call start_adc_conversion
read_initial_temp:
	Get_Adc_Status 
	jb	AD0BUSY, read_initial_temp
	Read_Adc_Result						; Read initial temperature
	mov	A, Temp2
	jnz	($+3)							; Is reading below 256?

	mov	Temp1, A							; Yes - set average temperature value to zero

	mov	Current_Average_Temp, Temp1			; Set initial average temperature
	call check_temp_voltage_and_limit_power
	mov	Adc_Conversion_Cnt, #TEMP_CHECK_RATE	; Make sure a temp reading is done next time
	Set_Adc_Ip_Temp

	; Go to the desired startup mode
	mov	Temp1, #Pgm_Startup_Method
	mov	A, @Temp1
	jnb	ACC.0, direct_method_start

	jmp	stepper_method_start

direct_method_start:
	; Set up start operating conditions
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, @Temp1	
	mov	Temp7, A				; Store setting in Temp7
	mov	@Temp1, #2			; Set nondamped low frequency pwm mode
	call	decode_parameters		; (Decode_parameters uses Temp1 and Temp8)
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, Temp7
	mov	@Temp1, A				; Restore settings
	; Set max allowed power
	setb	Flags1.SETTLE_PHASE		; Set settle phase power as max
	clr	EA					; Disable interrupts to avoid that Requested_Pwm is overwritten
	call set_startup_pwm
	mov	Pwm_Limit, Requested_Pwm
	mov	Pwm_Limit_Spoolup, Requested_Pwm
	setb	EA
	clr	Flags1.SETTLE_PHASE		
	mov	Current_Pwm_Limited, #0		; Set low pwm again after calling set_startup_pwm
	mov	Spoolup_Limit_Cnt, #0
	mov	Spoolup_Limit_Skip, #1			
	; Begin startup sequence
	setb	Flags1.MOTOR_SPINNING		; Set motor spinning flag
	setb	Flags1.DIRECT_STARTUP_PHASE	; Set direct startup phase flag
	mov	Direct_Startup_Ok_Cnt, #0	; Reset ok counter
	call comm5comm6				; Initialize commutation
	call comm6comm1				
	call	calc_next_comm_timing		; Set virtual commutation point
	call initialize_all_timings		; Initialize timing
	jmp	run1


stepper_method_start:
	; Set up start operating conditions
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, @Temp1	
	mov	Temp7, A				; Store setting in Temp7
	mov	@Temp1, #3			; Set damped light mode
	mov	Temp1, #Pgm_Damping_Force
	mov	A, @Temp1	
	mov	Temp6, A				; Store setting in Temp6
	mov	@Temp1, #5			; Set high damping force
	call	decode_parameters		; (Decode_parameters uses Temp1 and Temp8)
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, Temp7
	mov	@Temp1, A				; Restore settings
	mov	Temp1, #Pgm_Damping_Force
	mov	A, Temp6
	mov	@Temp1, A				
	; Begin startup sequence
	setb	Flags1.MOTOR_SPINNING	; Set motor spinning flag
	setb	Flags1.SETTLE_PHASE		; Set motor start settling phase flag
	setb	Flags2.CURR_PWMOFF_DAMPED; Set damped status, in order to ensure that pfets will be turned off in an initial pwm on
	call comm5comm6			; Initialize commutation
	call comm6comm1			
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
	clr	Flags1.SETTLE_PHASE		; Clear settling phase flag
	setb	Flags1.STEPPER_PHASE	; Set motor start stepper phase flag

	;**** **** **** **** ****
	; Stepper phase beginning
	;**** **** **** **** **** 
stepper_rot_beg:
	call start_adc_conversion
	call check_temp_voltage_and_limit_power
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
	mov	A, New_Rcp				; Load new pulse value
	subb	A, #RCP_STOP				; Check if pulse is below stop value
	jnc	stepper_rot_beg

	jmp	run_to_wait_for_power_on

stepper_rot_exit:
	; Wait for step
	call stepper_timer_wait
	; Clear stepper phase
	clr	Flags1.STEPPER_PHASE		; Clear motor start stepper phase flag
	; Set dondamped low pwm frequency
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, @Temp1	
	mov	Temp7, A					; Store setting in Temp7
	mov	@Temp1, #2				; Set nondamped low frequency pwm mode
	call	decode_parameters			; (Decode_parameters uses Temp1 and Temp8)
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, Temp7
	mov	@Temp1, A					; Restore settings
	; Set spoolup power variables (power is now controlled from RCP)
	mov	Pwm_Limit, Requested_Pwm
	mov	Pwm_Limit_Spoolup, Pwm_Spoolup_Beg
	mov	Current_Pwm_Limited, Pwm_Spoolup_Beg
	mov	Spoolup_Limit_Cnt, #0
	mov	Spoolup_Limit_Skip, #1			
	; Set direct startup phase to aquire sync quickly
	setb	Flags1.DIRECT_STARTUP_PHASE	; Set direct startup phase flag
	mov	Direct_Startup_Ok_Cnt, #0	; Reset ok counter
	clr	EA						; Disable interrupts
	ApFET_off						; Ap off. Turn off unused pfets (to turn off damping fets that might be on)
	CpFET_off						; Cp off
	mov	A, #45					; 8us delay for pfets to go off
	djnz	ACC, $
	setb	EA						; Enable interrupts
	call comm6comm1				
	call calc_next_comm_timing		; Calculate next timing and start advance timing wait
	call wait_advance_timing			; Wait advance timing and start zero cross wait
	call calc_new_wait_times
	call wait_before_zc_scan			; Wait zero cross wait and start zero cross timeout
	mov	Adc_Conversion_Cnt, #0		; Make sure a voltage reading is done next time
	Set_Adc_Ip_Volt				; Set adc measurement to voltage
	jmp	run1



;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Run entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
damped_transition:
	; Transition from nondamped to damped if applicable
	call	decode_parameters		; Set programmed parameters
	call	comm6comm1
	mov	Adc_Conversion_Cnt, #0	; Make sure a voltage reading is done next time
	Set_Adc_Ip_Volt			; Set adc measurement to voltage

; Run 1 = B(p-on) + C(n-pwm) - comparator A evaluated
; Out_cA changes from high to low
run1:
	call wait_for_comp_out_high	; Wait zero cross wait and wait for high
	call	evaluate_comparator_integrity	; Check whether comparator reading has been normal
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
	call	evaluate_comparator_integrity
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
	call	evaluate_comparator_integrity
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
	call	evaluate_comparator_integrity
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
	call	evaluate_comparator_integrity
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
	call	evaluate_comparator_integrity
	call setup_comm_wait	
	call check_temp_voltage_and_limit_power
	call wait_for_comm
	call comm6comm1
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

	; Check if it is direct startup
	jnb	Flags1.DIRECT_STARTUP_PHASE, normal_run_checks

	; Set spoolup power variables
IF MODE == 0 OR MODE == 2
	mov	Pwm_Limit, Pwm_Spoolup_Beg		; Set initial max power
	mov	Pwm_Limit_Spoolup, Pwm_Spoolup_Beg	; Set initial slow spoolup power
ENDIF
IF MODE == 1
	mov	Pwm_Limit, #0FFh			; Allow full power
	mov	Pwm_Limit_Spoolup, #0FFh	
ENDIF
	mov	Spoolup_Limit_Cnt, #0
	mov	Spoolup_Limit_Skip, #1			
	; Check startup ok counter
	clr	C
	mov	A, Direct_Startup_Ok_Cnt		; Load ok counter
	subb	A, #100					; Is counter above requirement?
	jc	direct_start_check_rcp		; No - proceed

	clr	Flags1.DIRECT_STARTUP_PHASE	; Clear direct startup phase flag
	setb	Flags1.INITIAL_RUN_PHASE		; Set initial run phase flag
	mov	Startup_Rot_Cnt, #20		; Set startup rotation count
	jmp	normal_run_checks

direct_start_check_rcp:
	clr	C
	mov	A, New_Rcp				; Load new pulse value
	subb	A, #RCP_STOP				; Check if pulse is below stop value
	jc	($+5)

	ljmp	run1						; Continue to run 

	jmp	run_to_wait_for_power_on


normal_run_checks:
	; Check if it is initial run phase
	jnb	Flags1.INITIAL_RUN_PHASE, initial_run_phase_done; If not initial run phase - branch

	; Decrement startup rotaton count
	mov	A, Startup_Rot_Cnt
	dec	A
	; Check number of nondamped rotations
	jnz 	normal_run_check_startup_rot	; Branch if counter is not zero

	clr	Flags1.INITIAL_RUN_PHASE		; Clear initial run phase flag
	ljmp damped_transition			; Do damped transition if counter is zero

normal_run_check_startup_rot:
	mov	Startup_Rot_Cnt, A			; Not zero - store counter

	clr	C
	mov	A, New_Rcp				; Load new pulse value
	subb	A, #RCP_STOP				; Check if pulse is below stop value
	jc	($+5)

	ljmp	run1						; Continue to run 

	jmp	run_to_wait_for_power_on


initial_run_phase_done:
IF MODE == 0	; Main
	; Check if throttle is zeroed
	clr	C
	mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	subb	A, #1					; Is number of stop RC pulses above limit?
	jc	run6_check_rcp_stop_count	; If no - branch

	mov	Pwm_Limit_Spoolup, Pwm_Spoolup_Beg	; If yes - set initial max powers
	mov	Spoolup_Limit_Cnt, #255			; And set spoolup parameters
	mov	Spoolup_Limit_Skip, #1			

run6_check_rcp_stop_count:
ENDIF
	; Exit run loop after a given time
	clr	C
	mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	subb	A, #RCP_STOP_LIMIT			; Is number of stop RC pulses above limit?
	jnc	run_to_wait_for_power_on		; Yes, go back to wait for poweron

run6_check_rcp_timeout:
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3					; Check pwm frequency flags
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
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, @Temp1	
	mov	Temp7, A				; Store setting in Temp7
	mov	@Temp1, #2			; Set low pwm mode (in order to turn off damping)
	call	decode_parameters		; (Decode_parameters uses Temp1 and Temp8)
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, Temp7
	mov	@Temp1, A				; Restore settings
	clr	A
	mov	Requested_Pwm, A		; Set requested pwm to zero
	mov	Governor_Req_Pwm, A		; Set governor requested pwm to zero
	mov	Current_Pwm, A			; Set current pwm to zero
	mov	Current_Pwm_Limited, A	; Set limited current pwm to zero
	mov	Pwm_Motor_Idle, A		; Set motor idle to zero
	clr	Flags1.MOTOR_SPINNING	; Clear motor spinning flag
	call	wait1ms				; Wait for pwm to be stopped
	call switch_power_off
IF MODE == 0	; Main
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3				; Check pwm frequency flags
	jnz	run_to_next_state_main	; If a flag is set (PWM) - branch

	mov	A, Rcp_Timeout_Cnt		; Load RC pulse timeout counter value
	jnz	run_to_next_state_main	; If it is not zero - branch

	jmp	measure_pwm_freq_init	; If it is zero (pulses missing) - go back to measure pwm frequency

run_to_next_state_main:
	mov	Temp1, #Pgm_Startup_Method	; Check if it is stepped startup
	mov	A, @Temp1
	jnb	ACC.0, run_to_next_state_main_wait_done	; If direct startup - jump

	call	wait1s					; 3 second delay before new startup (in stepped mode)
	call	wait1s
	call	wait1s
run_to_next_state_main_wait_done:
	mov	Temp1, #Pgm_Main_Rearm_Start
	mov	A, @Temp1	
	clr	C
	subb	A, #1				; Is re-armed start enabled?
	jc 	jmp_wait_for_power_on	; No - do like tail and start immediately

	jmp	validate_rcp_start		; Yes - go back to validate RC pulse

jmp_wait_for_power_on:
	jmp	wait_for_power_on		; Go back to wait for power on
ENDIF
IF MODE >= 1	; Tail or multi
	mov	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	anl	A, Flags3				; Check pwm frequency flags
	jnz	jmp_wait_for_power_on	; If a flag is set (PWM) - branch

	mov	A, Rcp_Timeout_Cnt		; Load RC pulse timeout counter value
	jnz	jmp_wait_for_power_on	; If it is not zero - go back to wait for poweron

	jmp	measure_pwm_freq_init	; If it is zero (pulses missing) - go back to measure pwm frequency

jmp_wait_for_power_on:
	jmp	wait_for_power_on		; Go back to wait for power on
ENDIF

;**** **** **** **** **** **** **** **** **** **** **** **** ****

$include (BLHeliTxPgm.inc)		; Include source code for programming the ESC with the TX

;**** **** **** **** **** **** **** **** **** **** **** **** ****




END
