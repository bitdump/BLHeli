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
; And the input signal can be PPM (1-2ms) or OneShot125 (125-250us) at rates up to several hundred Hz.
; The code adapts itself to the various input modes/frequencies
; The code ESC can also be programmed to accept inverted input signal.
;
; The first lines of the software must be modified according to the chosen environment:
; Uncomment the selected ESC and main/tail/multi mode
; BESCNO EQU "ESC"_"mode" 						
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
; - Rev11.0 Fixed bug of programming default values for governor in MULTI mode
;           Disabled interrupts explicitly some places, to avoid possibilities for unintentional fet switching
;           Changed interrupt disable strategy, to always allow pwm interrupts, to avoid noise when running at low rpms
;           Added governor middle range for MAIN mode
;           Added bidirectional mode for TAIL and MULTI mode with PPM input
;           Changed and improved demag compensation
;           Miscellaneous other changes
; - Rev11.1 Fixed bug of slow acceleration response for MAIN mode running without governor
;           Fixed bug with PWM input, where throttle remains high even when zeroing throttle (seen on V922 tail)
;           Fixed bug in bidirectional operation, where direction change could cause reset
;           Improved autorotation bailout for MAIN
;           Reduced min speed back to 1220 erpm
;           Misc code cleanups
; - Rev11.2 Fixed throttle calibration bug
;           Added high side driver precharge for all-nfet ESCs
;           Optimized timing in general and for demag compensation in particular
;           Auto bailout functionality modified
;           Governor is deactivated for throttle inputs below 10%
;           Increased beacon delay times
; - Rev12.0 Added programmable main spoolup time
;           Added programmable temperature protection enable
;           Bidirectional mode stop/start improved. Motor is now stopped before starting
;           Power is limited for very low rpms (when BEMF is low), in order to avoid sync loss 
;           Damped light mode is made more smooth and quiet, particularly at low and high rpms
;           Comparator signal qualification scheme is changed
;           Demag compensation scheme is significantly changed
;           Increased jitter tolerance for PPM frequency measurement
;           Fully damped mode removed, and damped light only supported on damped capable ESCs
;           Default tail mode changed to damped light
;           Miscellaneous other changes
; - Rev12.1 Fixed bug in tail code
;           Improved startup for Atmel
;           Added support for multiple high BEC voltages
;           Added support for RPM output
; - Rev12.2 Improved running smoothness, particularly for damped light
;           Avoiding lockup at full throttle when input signal is noisy
;           Avoiding detection of 1-wire programming signal as valid throttle signal
; - Rev13.0 Removed stepped start
;           Removed throttle change rate and damping force parameters
;           Added support for OneShot125
;           Improved commutation timing accuracy
; - Rev13.1 Removed startup ramp for MULTI
;           Improved startup for some odd ESCs
; - Rev13.2 Still tweaking startup to make it more reliable and faster for all ESC/motor combos
;           Increased deadband for bidirectional operation
;           Relaxed signal detection criteria
;           Added support for running 48MHz capable SiLabs MCUs at 48MHz
;           Added bootlader to SiLabs code
;           Miscellaneous other changes
; - Rev14.0 Improved running at high timing
;           Improved running at high RPMs and increased max RPM limit
;           Avoid being locked in bootloader (implemented in Suite 13202)
;           Improved reliability of 3D (bidirectional) mode and startup
;           Smoother running and greatly reduced step to full power in damped light mode
;           Removed low voltage limiting for MULTI
;           Added pwm dither parameter
;           Added setting for enable/disable of low RPM power protection
;           Added setting for enable/disable of PWM input
;           Better AFW and damping for some ESCs (that have a slow high side driver)
;           Miscellaneous other changes
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
; The code disables interrupts in interrupt routines, in order to avoid too nested interrupts
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
; Motor startup:
; Startup is the only phase, before normal bemf commutation run begins.
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
XP_35A_SW_Main 				EQU 19
XP_35A_SW_Tail 				EQU 20
XP_35A_SW_Multi 				EQU 21
DP_3A_Main 					EQU 22
DP_3A_Tail  					EQU 23
DP_3A_Multi  					EQU 24
Supermicro_3p5A_Main 			EQU 25
Supermicro_3p5A_Tail 			EQU 26   
Supermicro_3p5A_Multi 			EQU 27   
Turnigy_Plush_6A_Main 			EQU 28
Turnigy_Plush_6A_Tail 			EQU 29   
Turnigy_Plush_6A_Multi 			EQU 30   
Turnigy_Plush_10A_Main 			EQU 31
Turnigy_Plush_10A_Tail 			EQU 32   
Turnigy_Plush_10A_Multi 			EQU 33   
Turnigy_Plush_12A_Main 			EQU 34
Turnigy_Plush_12A_Tail 			EQU 35   
Turnigy_Plush_12A_Multi 			EQU 36   
Turnigy_Plush_18A_Main 			EQU 37
Turnigy_Plush_18A_Tail 			EQU 38   
Turnigy_Plush_18A_Multi 			EQU 39   
Turnigy_Plush_25A_Main 			EQU 40
Turnigy_Plush_25A_Tail 			EQU 41   
Turnigy_Plush_25A_Multi 			EQU 42   
Turnigy_Plush_30A_Main 			EQU 43
Turnigy_Plush_30A_Tail 			EQU 44   
Turnigy_Plush_30A_Multi 			EQU 45   
Turnigy_Plush_40A_Main 			EQU 46
Turnigy_Plush_40A_Tail 			EQU 47   
Turnigy_Plush_40A_Multi 			EQU 48   
Turnigy_Plush_60A_Main 			EQU 49
Turnigy_Plush_60A_Tail 			EQU 50   
Turnigy_Plush_60A_Multi 			EQU 51   
Turnigy_Plush_80A_Main 			EQU 52
Turnigy_Plush_80A_Tail 			EQU 53   
Turnigy_Plush_80A_Multi 			EQU 54   
Turnigy_Plush_Nfet_18A_Main 		EQU 55
Turnigy_Plush_Nfet_18A_Tail 		EQU 56   
Turnigy_Plush_Nfet_18A_Multi 		EQU 57   
Turnigy_Plush_Nfet_25A_Main 		EQU 58
Turnigy_Plush_Nfet_25A_Tail 		EQU 59   
Turnigy_Plush_Nfet_25A_Multi 		EQU 60   
Turnigy_Plush_Nfet_30A_Main 		EQU 61
Turnigy_Plush_Nfet_30A_Tail 		EQU 62   
Turnigy_Plush_Nfet_30A_Multi 		EQU 63   
Turnigy_AE_20A_Main 			EQU 64
Turnigy_AE_20A_Tail 			EQU 65   
Turnigy_AE_20A_Multi 			EQU 66   
Turnigy_AE_25A_Main 			EQU 67
Turnigy_AE_25A_Tail 			EQU 68   
Turnigy_AE_25A_Multi 			EQU 69   
Turnigy_AE_30A_Main 			EQU 70
Turnigy_AE_30A_Tail 			EQU 71   
Turnigy_AE_30A_Multi 			EQU 72   
Turnigy_AE_45A_Main 			EQU 73
Turnigy_AE_45A_Tail 			EQU 74   
Turnigy_AE_45A_Multi 			EQU 75   
Turnigy_KForce_40A_Main 			EQU 76   
Turnigy_KForce_40A_Tail 			EQU 77   
Turnigy_KForce_40A_Multi 		EQU 78   
Turnigy_KForce_70A_HV_Main 		EQU 79   
Turnigy_KForce_70A_HV_Tail 		EQU 80   
Turnigy_KForce_70A_HV_Multi 		EQU 81   
Turnigy_KForce_120A_HV_Main 		EQU 82   
Turnigy_KForce_120A_HV_Tail 		EQU 83   
Turnigy_KForce_120A_HV_Multi 		EQU 84   
Turnigy_KForce_120A_HV_v2_Main	EQU 85   
Turnigy_KForce_120A_HV_v2_Tail 	EQU 86   
Turnigy_KForce_120A_HV_v2_Multi 	EQU 87   
Skywalker_20A_Main 				EQU 88
Skywalker_20A_Tail 				EQU 89   
Skywalker_20A_Multi 			EQU 90   
Skywalker_40A_Main 				EQU 91
Skywalker_40A_Tail 				EQU 92   
Skywalker_40A_Multi 			EQU 93   
HiModel_Cool_22A_Main 			EQU 94
HiModel_Cool_22A_Tail 			EQU 95   
HiModel_Cool_22A_Multi 			EQU 96   
HiModel_Cool_33A_Main 			EQU 97
HiModel_Cool_33A_Tail 			EQU 98   
HiModel_Cool_33A_Multi 			EQU 99  
HiModel_Cool_41A_Main 			EQU 100
HiModel_Cool_41A_Tail 			EQU 101  
HiModel_Cool_41A_Multi 			EQU 102  
RCTimer_6A_Main 				EQU 103   
RCTimer_6A_Tail 				EQU 104  
RCTimer_6A_Multi 				EQU 105  
Align_RCE_BL15X_Main			EQU 106   
Align_RCE_BL15X_Tail 			EQU 107  
Align_RCE_BL15X_Multi 			EQU 108  
Align_RCE_BL15P_Main			EQU 109  
Align_RCE_BL15P_Tail 			EQU 110  
Align_RCE_BL15P_Multi 			EQU 111  
Align_RCE_BL35X_Main			EQU 112  
Align_RCE_BL35X_Tail 			EQU 113  
Align_RCE_BL35X_Multi 			EQU 114  
Align_RCE_BL35P_Main			EQU 115   
Align_RCE_BL35P_Tail 			EQU 116  
Align_RCE_BL35P_Multi 			EQU 117  
Gaui_GE_183_18A_Main			EQU 118   
Gaui_GE_183_18A_Tail 			EQU 119  
Gaui_GE_183_18A_Multi 			EQU 120  
H_King_10A_Main				EQU 121   
H_King_10A_Tail 				EQU 122  
H_King_10A_Multi 				EQU 123  
H_King_20A_Main				EQU 124   
H_King_20A_Tail 				EQU 125  
H_King_20A_Multi 				EQU 126  
H_King_35A_Main				EQU 127   
H_King_35A_Tail 				EQU 128 
H_King_35A_Multi 				EQU 129  
H_King_50A_Main				EQU 130   
H_King_50A_Tail 				EQU 131  
H_King_50A_Multi 				EQU 132  
Polaris_Thunder_12A_Main			EQU 133   
Polaris_Thunder_12A_Tail 		EQU 134  
Polaris_Thunder_12A_Multi 		EQU 135  
Polaris_Thunder_20A_Main			EQU 136   
Polaris_Thunder_20A_Tail 		EQU 137  
Polaris_Thunder_20A_Multi 		EQU 138  
Polaris_Thunder_30A_Main			EQU 139   
Polaris_Thunder_30A_Tail 		EQU 140  
Polaris_Thunder_30A_Multi 		EQU 141  
Polaris_Thunder_40A_Main			EQU 142   
Polaris_Thunder_40A_Tail 		EQU 143  
Polaris_Thunder_40A_Multi 		EQU 144  
Polaris_Thunder_60A_Main			EQU 145   
Polaris_Thunder_60A_Tail 		EQU 146  
Polaris_Thunder_60A_Multi 		EQU 147  
Polaris_Thunder_80A_Main			EQU 148   
Polaris_Thunder_80A_Tail 		EQU 149  
Polaris_Thunder_80A_Multi 		EQU 150  
Polaris_Thunder_100A_Main		EQU 151   
Polaris_Thunder_100A_Tail 		EQU 152  
Polaris_Thunder_100A_Multi 		EQU 153  
Platinum_Pro_30A_Main			EQU 154   
Platinum_Pro_30A_Tail 			EQU 155  
Platinum_Pro_30A_Multi 			EQU 156  
Platinum_Pro_150A_Main			EQU 157   
Platinum_Pro_150A_Tail 			EQU 158  
Platinum_Pro_150A_Multi 			EQU 159  
Platinum_50Av3_Main				EQU 160   
Platinum_50Av3_Tail 			EQU 161  
Platinum_50Av3_Multi 			EQU 162  
EAZY_3Av2_Main					EQU 163   
EAZY_3Av2_Tail 				EQU 164  
EAZY_3Av2_Multi 				EQU 165  
Tarot_30A_Main					EQU 166   
Tarot_30A_Tail 				EQU 167  
Tarot_30A_Multi 				EQU 168  
SkyIII_30A_Main				EQU 169   
SkyIII_30A_Tail 				EQU 170  
SkyIII_30A_Multi 				EQU 171  
EMAX_20A_Main					EQU 172   
EMAX_20A_Tail 					EQU 173  
EMAX_20A_Multi 				EQU 174  
EMAX_40A_Main					EQU 175   
EMAX_40A_Tail 					EQU 176  
EMAX_40A_Multi 				EQU 177  
XRotor_10A_Main				EQU 178   
XRotor_10A_Tail 				EQU 179  
XRotor_10A_Multi 				EQU 180  
XRotor_20A_Main				EQU 181   
XRotor_20A_Tail 				EQU 182  
XRotor_20A_Multi 				EQU 183  
XRotor_40A_Main				EQU 184   
XRotor_40A_Tail 				EQU 185  
XRotor_40A_Multi 				EQU 186  
MDRX62H_Main					EQU 187   
MDRX62H_Tail 					EQU 188  
MDRX62H_Multi 					EQU 189  
RotorGeeks_20A_Main				EQU 190   
RotorGeeks_20A_Tail 			EQU 191  
RotorGeeks_20A_Multi 			EQU 192  
Flycolor_Fairy_6A_Main			EQU 193   
Flycolor_Fairy_6A_Tail 			EQU 194  
Flycolor_Fairy_6A_Multi 			EQU 195  
Flycolor_Fairy_30A_Main			EQU 196   
Flycolor_Fairy_30A_Tail 			EQU 197  
Flycolor_Fairy_30A_Multi 		EQU 198  
FVT_Littlebee_20A_Main			EQU 199  
FVT_Littlebee_20A_Tail			EQU 200  
FVT_Littlebee_20A_Multi			EQU 201  


;**** **** **** **** ****
; Select the ESC and mode to use (or unselect all for use with external batch compile file)
;BESCNO EQU XP_3A_Main 
;BESCNO EQU XP_3A_Tail
;BESCNO EQU XP_3A_Multi
;BESCNO EQU XP_7A_Main
;BESCNO EQU XP_7A_Tail
;BESCNO EQU XP_7A_Multi
;BESCNO EQU XP_7A_Fast_Main
;BESCNO EQU XP_7A_Fast_Tail
;BESCNO EQU XP_7A_Fast_Multi
;BESCNO EQU XP_12A_Main
;BESCNO EQU XP_12A_Tail 
;BESCNO EQU XP_12A_Multi
;BESCNO EQU XP_18A_Main 
;BESCNO EQU XP_18A_Tail 
;BESCNO EQU XP_18A_Multi
;BESCNO EQU XP_25A_Main 
;BESCNO EQU XP_25A_Tail 
;BESCNO EQU XP_25A_Multi
;BESCNO EQU XP_35A_SW_Main
;BESCNO EQU XP_35A_SW_Tail 
;BESCNO EQU XP_35A_SW_Multi
;BESCNO EQU DP_3A_Main 						
;BESCNO EQU DP_3A_Tail 
;BESCNO EQU DP_3A_Multi 
;BESCNO EQU Supermicro_3p5A_Main
;BESCNO EQU Supermicro_3p5A_Tail 
;BESCNO EQU Supermicro_3p5A_Multi
;BESCNO EQU Turnigy_Plush_6A_Main 
;BESCNO EQU Turnigy_Plush_6A_Tail 
;BESCNO EQU Turnigy_Plush_6A_Multi
;BESCNO EQU Turnigy_Plush_10A_Main 
;BESCNO EQU Turnigy_Plush_10A_Tail 
;BESCNO EQU Turnigy_Plush_10A_Multi
;BESCNO EQU Turnigy_Plush_12A_Main 
;BESCNO EQU Turnigy_Plush_12A_Tail 
;BESCNO EQU Turnigy_Plush_12A_Multi 
;BESCNO EQU Turnigy_Plush_18A_Main 
;BESCNO EQU Turnigy_Plush_18A_Tail 
;BESCNO EQU Turnigy_Plush_18A_Multi
;BESCNO EQU Turnigy_Plush_25A_Main 
;BESCNO EQU Turnigy_Plush_25A_Tail
;BESCNO EQU Turnigy_Plush_25A_Multi
;BESCNO EQU Turnigy_Plush_30A_Main 
;BESCNO EQU Turnigy_Plush_30A_Tail 
;BESCNO EQU Turnigy_Plush_30A_Multi
;BESCNO EQU Turnigy_Plush_40A_Main 
;BESCNO EQU Turnigy_Plush_40A_Tail 
;BESCNO EQU Turnigy_Plush_40A_Multi
;BESCNO EQU Turnigy_Plush_60A_Main
;BESCNO EQU Turnigy_Plush_60A_Tail 
;BESCNO EQU Turnigy_Plush_60A_Multi
;BESCNO EQU Turnigy_Plush_80A_Main
;BESCNO EQU Turnigy_Plush_80A_Tail 
;BESCNO EQU Turnigy_Plush_80A_Multi
;BESCNO EQU Turnigy_Plush_Nfet_18A_Main
;BESCNO EQU Turnigy_Plush_Nfet_18A_Tail 
;BESCNO EQU Turnigy_Plush_Nfet_18A_Multi 
;BESCNO EQU Turnigy_Plush_Nfet_25A_Main 
;BESCNO EQU Turnigy_Plush_Nfet_25A_Tail
;BESCNO EQU Turnigy_Plush_Nfet_25A_Multi
;BESCNO EQU Turnigy_Plush_Nfet_30A_Main  
;BESCNO EQU Turnigy_Plush_Nfet_30A_Tail 
;BESCNO EQU Turnigy_Plush_Nfet_30A_Multi
;BESCNO EQU Turnigy_AE_20A_Main 
;BESCNO EQU Turnigy_AE_20A_Tail 
;BESCNO EQU Turnigy_AE_20A_Multi
;BESCNO EQU Turnigy_AE_25A_Main 
;BESCNO EQU Turnigy_AE_25A_Tail 
;BESCNO EQU Turnigy_AE_25A_Multi
;BESCNO EQU Turnigy_AE_30A_Main 
;BESCNO EQU Turnigy_AE_30A_Tail 
;BESCNO EQU Turnigy_AE_30A_Multi
;BESCNO EQU Turnigy_AE_45A_Main
;BESCNO EQU Turnigy_AE_45A_Tail 
;BESCNO EQU Turnigy_AE_45A_Multi
;BESCNO EQU Turnigy_KForce_40A_Main
;BESCNO EQU Turnigy_KForce_40A_Tail 
;BESCNO EQU Turnigy_KForce_40A_Multi 
;BESCNO EQU Turnigy_KForce_70A_HV_Main
;BESCNO EQU Turnigy_KForce_70A_HV_Tail 
;BESCNO EQU Turnigy_KForce_70A_HV_Multi
;BESCNO EQU Turnigy_KForce_120A_HV_Main
;BESCNO EQU Turnigy_KForce_120A_HV_Tail 
;BESCNO EQU Turnigy_KForce_120A_HV_Multi
;BESCNO EQU Turnigy_KForce_120A_HV_v2_Main
;BESCNO EQU Turnigy_KForce_120A_HV_v2_Tail 
;BESCNO EQU Turnigy_KForce_120A_HV_v2_Multi
;BESCNO EQU Skywalker_20A_Main
;BESCNO EQU Skywalker_20A_Tail
;BESCNO EQU Skywalker_20A_Multi
;BESCNO EQU Skywalker_40A_Main 
;BESCNO EQU Skywalker_40A_Tail 
;BESCNO EQU Skywalker_40A_Multi
;BESCNO EQU HiModel_Cool_22A_Main
;BESCNO EQU HiModel_Cool_22A_Tail
;BESCNO EQU HiModel_Cool_22A_Multi
;BESCNO EQU HiModel_Cool_33A_Main
;BESCNO EQU HiModel_Cool_33A_Tail
;BESCNO EQU HiModel_Cool_33A_Multi
;BESCNO EQU HiModel_Cool_41A_Main
;BESCNO EQU HiModel_Cool_41A_Tail
;BESCNO EQU HiModel_Cool_41A_Multi
;BESCNO EQU RCTimer_6A_Main
;BESCNO EQU RCTimer_6A_Tail
;BESCNO EQU RCTimer_6A_Multi
;BESCNO EQU Align_RCE_BL15X_Main
;BESCNO EQU Align_RCE_BL15X_Tail
;BESCNO EQU Align_RCE_BL15X_Multi
;BESCNO EQU Align_RCE_BL15P_Main
;BESCNO EQU Align_RCE_BL15P_Tail
;BESCNO EQU Align_RCE_BL15P_Multi 
;BESCNO EQU Align_RCE_BL35X_Main 
;BESCNO EQU Align_RCE_BL35X_Tail
;BESCNO EQU Align_RCE_BL35X_Multi
;BESCNO EQU Align_RCE_BL35P_Main
;BESCNO EQU Align_RCE_BL35P_Tail
;BESCNO EQU Align_RCE_BL35P_Multi
;BESCNO EQU Gaui_GE_183_18A_Main
;BESCNO EQU Gaui_GE_183_18A_Tail
;BESCNO EQU Gaui_GE_183_18A_Multi
;BESCNO EQU H_King_10A_Main 
;BESCNO EQU H_King_10A_Tail 
;BESCNO EQU H_King_10A_Multi
;BESCNO EQU H_King_20A_Main
;BESCNO EQU H_King_20A_Tail
;BESCNO EQU H_King_20A_Multi
;BESCNO EQU H_King_35A_Main
;BESCNO EQU H_King_35A_Tail
;BESCNO EQU H_King_35A_Multi
;BESCNO EQU H_King_50A_Main
;BESCNO EQU H_King_50A_Tail
;BESCNO EQU H_King_50A_Multi
;BESCNO EQU Polaris_Thunder_12A_Main
;BESCNO EQU Polaris_Thunder_12A_Tail
;BESCNO EQU Polaris_Thunder_12A_Multi
;BESCNO EQU Polaris_Thunder_20A_Main
;BESCNO EQU Polaris_Thunder_20A_Tail
;BESCNO EQU Polaris_Thunder_20A_Multi
;BESCNO EQU Polaris_Thunder_30A_Main
;BESCNO EQU Polaris_Thunder_30A_Tail
;BESCNO EQU Polaris_Thunder_30A_Multi
;BESCNO EQU Polaris_Thunder_40A_Main
;BESCNO EQU Polaris_Thunder_40A_Tail
;BESCNO EQU Polaris_Thunder_40A_Multi
;BESCNO EQU Polaris_Thunder_60A_Main
;BESCNO EQU Polaris_Thunder_60A_Tail
;BESCNO EQU Polaris_Thunder_60A_Multi
;BESCNO EQU Polaris_Thunder_80A_Main
;BESCNO EQU Polaris_Thunder_80A_Tail
;BESCNO EQU Polaris_Thunder_80A_Multi
;BESCNO EQU Polaris_Thunder_100A_Main
;BESCNO EQU Polaris_Thunder_100A_Tail
;BESCNO EQU Polaris_Thunder_100A_Multi
;BESCNO EQU Platinum_Pro_30A_Main
;BESCNO EQU Platinum_Pro_30A_Tail
;BESCNO EQU Platinum_Pro_30A_Multi
;BESCNO EQU Platinum_Pro_150A_Main
;BESCNO EQU Platinum_Pro_150A_Tail
;BESCNO EQU Platinum_Pro_150A_Multi
;BESCNO EQU Platinum_50Av3_Main
;BESCNO EQU Platinum_50Av3_Tail
;BESCNO EQU Platinum_50Av3_Multi 
;BESCNO EQU EAZY_3Av2_Main
;BESCNO EQU EAZY_3Av2_Tail
;BESCNO EQU EAZY_3Av2_Multi
;BESCNO EQU Tarot_30A_Main
;BESCNO EQU Tarot_30A_Tail
;BESCNO EQU Tarot_30A_Multi
;BESCNO EQU SkyIII_30A_Main
;BESCNO EQU SkyIII_30A_Tail
;BESCNO EQU SkyIII_30A_Multi
;BESCNO EQU EMAX_20A_Main
;BESCNO EQU EMAX_20A_Tail
;BESCNO EQU EMAX_20A_Multi 
;BESCNO EQU EMAX_40A_Main
;BESCNO EQU EMAX_40A_Tail
;BESCNO EQU EMAX_40A_Multi 
;BESCNO EQU XRotor_10A_Main
;BESCNO EQU XRotor_10A_Tail
;BESCNO EQU XRotor_10A_Multi 
;BESCNO EQU XRotor_20A_Main
;BESCNO EQU XRotor_20A_Tail
;BESCNO EQU XRotor_20A_Multi 
;BESCNO EQU XRotor_40A_Main
;BESCNO EQU XRotor_40A_Tail
;BESCNO EQU XRotor_40A_Multi
;BESCNO EQU MDRX62H_Main
;BESCNO EQU MDRX62H_Tail
;BESCNO EQU MDRX62H_Multi 
;BESCNO EQU RotorGeeks_20A_Main
;BESCNO EQU RotorGeeks_20A_Tail
;BESCNO EQU RotorGeeks_20A_Multi
;BESCNO EQU Flycolor_Fairy_6A_Main
;BESCNO EQU Flycolor_Fairy_6A_Tail
;BESCNO EQU Flycolor_Fairy_6A_Multi
;BESCNO EQU Flycolor_Fairy_30A_Main
;BESCNO EQU Flycolor_Fairy_30A_Tail
;BESCNO EQU Flycolor_Fairy_30A_Multi
;BESCNO EQU FVT_Littlebee_20A_Main
;BESCNO EQU FVT_Littlebee_20A_Tail
;BESCNO EQU FVT_Littlebee_20A_Multi


;**** **** **** **** ****
; ESC selection statements
IF BESCNO == XP_3A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_3A.inc)			; Select XP 3A pinout
ENDIF

IF BESCNO == XP_3A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_3A.inc)			; Select XP 3A pinout
ENDIF

IF BESCNO == XP_3A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_3A.inc)			; Select XP 3A pinout
ENDIF

IF BESCNO == XP_7A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_7A.inc)			; Select XP 7A pinout
ENDIF

IF BESCNO == XP_7A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_7A.inc)			; Select XP 7A pinout
ENDIF

IF BESCNO == XP_7A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_7A.inc)			; Select XP 7A pinout
ENDIF

IF BESCNO == XP_7A_Fast_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_7A_Fast.inc)		; Select XP 7A Fast pinout
ENDIF

IF BESCNO == XP_7A_Fast_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_7A_Fast.inc)		; Select XP 7A Fast pinout
ENDIF

IF BESCNO == XP_7A_Fast_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_7A_Fast.inc)		; Select XP 7A Fast pinout
ENDIF

IF BESCNO == XP_12A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_12A.inc)			; Select XP 12A pinout
ENDIF

IF BESCNO == XP_12A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_12A.inc)			; Select XP 12A pinout
ENDIF

IF BESCNO == XP_12A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_12A.inc)			; Select XP 12A pinout
ENDIF

IF BESCNO == XP_18A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_18A.inc)			; Select XP 18A pinout
ENDIF

IF BESCNO == XP_18A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_18A.inc)			; Select XP 18A pinout
ENDIF

IF BESCNO == XP_18A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_18A.inc)			; Select XP 18A pinout
ENDIF

IF BESCNO == XP_25A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_25A.inc)			; Select XP 25A pinout
ENDIF

IF BESCNO == XP_25A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_25A.inc)			; Select XP 25A pinout
ENDIF

IF BESCNO == XP_25A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_25A.inc)			; Select XP 25A pinout
ENDIF

IF BESCNO == XP_35A_SW_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XP_35A_SW.inc)			; Select XP 35A SW pinout
ENDIF

IF BESCNO == XP_35A_SW_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XP_35A_SW.inc)			; Select XP 35A SW pinout
ENDIF

IF BESCNO == XP_35A_SW_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XP_35A_SW.inc)			; Select XP 35A SW pinout
ENDIF

IF BESCNO == DP_3A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (DP_3A.inc)			; Select DP 3A pinout
ENDIF

IF BESCNO == DP_3A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (DP_3A.inc)			; Select DP 3A pinout
ENDIF

IF BESCNO == DP_3A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (DP_3A.inc)			; Select DP 3A pinout
ENDIF

IF BESCNO == Supermicro_3p5A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Supermicro_3p5A.inc)	; Select Supermicro 3.5A pinout
ENDIF

IF BESCNO == Supermicro_3p5A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Supermicro_3p5A.inc)	; Select Supermicro 3.5A pinout
ENDIF

IF BESCNO == Supermicro_3p5A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Supermicro_3p5A.inc)	; Select Supermicro 3.5A pinout
ENDIF

IF BESCNO == Turnigy_Plush_6A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_6A.inc)	; Select Turnigy Plush 6A pinout
ENDIF

IF BESCNO == Turnigy_Plush_6A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_6A.inc)	; Select Turnigy Plush 6A pinout
ENDIF

IF BESCNO == Turnigy_Plush_6A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_6A.inc)	; Select Turnigy Plush 6A pinout
ENDIF

IF BESCNO == Turnigy_Plush_10A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_10A.inc)	; Select Turnigy Plush 10A pinout
ENDIF

IF BESCNO == Turnigy_Plush_10A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_10A.inc)	; Select Turnigy Plush 10A pinout
ENDIF

IF BESCNO == Turnigy_Plush_10A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_10A.inc)	; Select Turnigy Plush 10A pinout
ENDIF

IF BESCNO == Turnigy_Plush_12A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_12A.inc)	; Select Turnigy Plush 12A pinout
ENDIF

IF BESCNO == Turnigy_Plush_12A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_12A.inc)	; Select Turnigy Plush 12A pinout
ENDIF

IF BESCNO == Turnigy_Plush_12A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_12A.inc)	; Select Turnigy Plush 12A pinout
ENDIF

IF BESCNO == Turnigy_Plush_18A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_18A.inc)	; Select Turnigy Plush 18A pinout
ENDIF

IF BESCNO == Turnigy_Plush_18A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_18A.inc)	; Select Turnigy Plush 18A pinout
ENDIF

IF BESCNO == Turnigy_Plush_18A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_18A.inc)	; Select Turnigy Plush 18A pinout
ENDIF

IF BESCNO == Turnigy_Plush_25A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_25A.inc)	; Select Turnigy Plush 25A pinout
ENDIF

IF BESCNO == Turnigy_Plush_25A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_25A.inc)	; Select Turnigy Plush 25A pinout
ENDIF

IF BESCNO == Turnigy_Plush_25A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_25A.inc)	; Select Turnigy Plush 25A pinout
ENDIF

IF BESCNO == Turnigy_Plush_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_30A.inc)	; Select Turnigy Plush 30A pinout
ENDIF

IF BESCNO == Turnigy_Plush_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_30A.inc)	; Select Turnigy Plush 30A pinout
ENDIF

IF BESCNO == Turnigy_Plush_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_30A.inc)	; Select Turnigy Plush 30A pinout
ENDIF

IF BESCNO == Turnigy_Plush_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_40A.inc)	; Select Turnigy Plush 40A pinout
ENDIF

IF BESCNO == Turnigy_Plush_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_40A.inc)	; Select Turnigy Plush 40A pinout
ENDIF

IF BESCNO == Turnigy_Plush_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_40A.inc)	; Select Turnigy Plush 40A pinout
ENDIF

IF BESCNO == Turnigy_Plush_60A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_60A.inc)	; Select Turnigy Plush 60A pinout
ENDIF

IF BESCNO == Turnigy_Plush_60A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_60A.inc)	; Select Turnigy Plush 60A pinout
ENDIF

IF BESCNO == Turnigy_Plush_60A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_60A.inc)	; Select Turnigy Plush 60A pinout
ENDIF

IF BESCNO == Turnigy_Plush_80A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_80A.inc)	; Select Turnigy Plush 80A pinout
ENDIF

IF BESCNO == Turnigy_Plush_80A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_80A.inc)	; Select Turnigy Plush 80A pinout
ENDIF

IF BESCNO == Turnigy_Plush_80A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_80A.inc)	; Select Turnigy Plush 80A pinout
ENDIF

IF BESCNO == Turnigy_Plush_Nfet_18A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_Nfet_18A.inc)	; Select Turnigy Plush Nfet 18A pinout
ENDIF

IF BESCNO == Turnigy_Plush_Nfet_18A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_Nfet_18A.inc)	; Select Turnigy Plush Nfet 18A pinout
ENDIF

IF BESCNO == Turnigy_Plush_Nfet_18A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_Nfet_18A.inc)	; Select Turnigy Plush Nfet 18A pinout
ENDIF

IF BESCNO == Turnigy_Plush_Nfet_25A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_Nfet_25A.inc)	; Select Turnigy Plush Nfet 25A pinout
ENDIF

IF BESCNO == Turnigy_Plush_Nfet_25A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_Nfet_25A.inc)	; Select Turnigy Plush Nfet 25A pinout
ENDIF

IF BESCNO == Turnigy_Plush_Nfet_25A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_Nfet_25A.inc)	; Select Turnigy Plush Nfet 25A pinout
ENDIF

IF BESCNO == Turnigy_Plush_Nfet_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_Plush_Nfet_30A.inc)	; Select Turnigy Plush Nfet 30A pinout
ENDIF

IF BESCNO == Turnigy_Plush_Nfet_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_Plush_Nfet_30A.inc)	; Select Turnigy Plush Nfet 30A pinout
ENDIF

IF BESCNO == Turnigy_Plush_Nfet_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_Plush_Nfet_30A.inc)	; Select Turnigy Plush Nfet 30A pinout
ENDIF

IF BESCNO == Turnigy_AE_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_AE_20A.inc)		; Select Turnigy AE-20A pinout
ENDIF

IF BESCNO == Turnigy_AE_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_AE_20A.inc)		; Select Turnigy AE-20A pinout
ENDIF

IF BESCNO == Turnigy_AE_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_AE_20A.inc)		; Select Turnigy AE-20A pinout
ENDIF

IF BESCNO == Turnigy_AE_25A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_AE_25A.inc)		; Select Turnigy AE-25A pinout
ENDIF

IF BESCNO == Turnigy_AE_25A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_AE_25A.inc)		; Select Turnigy AE-25A pinout
ENDIF

IF BESCNO == Turnigy_AE_25A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_AE_25A.inc)		; Select Turnigy AE-25A pinout
ENDIF

IF BESCNO == Turnigy_AE_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_AE_30A.inc)		; Select Turnigy AE-30A pinout
ENDIF

IF BESCNO == Turnigy_AE_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_AE_30A.inc)		; Select Turnigy AE-30A pinout
ENDIF

IF BESCNO == Turnigy_AE_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_AE_30A.inc)		; Select Turnigy AE-30A pinout
ENDIF

IF BESCNO == Turnigy_AE_45A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_AE_45A.inc)		; Select Turnigy AE-45A pinout
ENDIF

IF BESCNO == Turnigy_AE_45A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_AE_45A.inc)		; Select Turnigy AE-45A pinout
ENDIF

IF BESCNO == Turnigy_AE_45A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_AE_45A.inc)		; Select Turnigy AE-45A pinout
ENDIF

IF BESCNO == Turnigy_KForce_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_KForce_40A.inc)	; Select Turnigy KForce 40A pinout
ENDIF

IF BESCNO == Turnigy_KForce_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_KForce_40A.inc)	; Select Turnigy KForce 40A pinout
ENDIF

IF BESCNO == Turnigy_KForce_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_KForce_40A.inc)	; Select Turnigy KForce 40A pinout
ENDIF

IF BESCNO == Turnigy_KForce_70A_HV_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_KForce_70A_HV.inc)	; Select Turnigy KForce 70A HV pinout
ENDIF

IF BESCNO == Turnigy_KForce_70A_HV_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_KForce_70A_HV.inc)	; Select Turnigy KForce 70A HV pinout
ENDIF

IF BESCNO == Turnigy_KForce_70A_HV_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_KForce_70A_HV.inc)	; Select Turnigy KForce 70A HV pinout
ENDIF

IF BESCNO == Turnigy_KForce_120A_HV_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_KForce_120A_HV.inc)	; Select Turnigy KForce 120A HV pinout
ENDIF

IF BESCNO == Turnigy_KForce_120A_HV_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_KForce_120A_HV.inc)	; Select Turnigy KForce 120A HV pinout
ENDIF

IF BESCNO == Turnigy_KForce_120A_HV_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_KForce_120A_HV.inc)	; Select Turnigy KForce 120A HV pinout
ENDIF

IF BESCNO == Turnigy_KForce_120A_HV_v2_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Turnigy_KForce_120A_HV_v2.inc); Select Turnigy KForce 120A HV v2 pinout
ENDIF

IF BESCNO == Turnigy_KForce_120A_HV_v2_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Turnigy_KForce_120A_HV_v2.inc); Select Turnigy KForce 120A HV v2 pinout
ENDIF

IF BESCNO == Turnigy_KForce_120A_HV_v2_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Turnigy_KForce_120A_HV_v2.inc); Select Turnigy KForce 120A HV v2 pinout
ENDIF

IF BESCNO == Skywalker_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Skywalker_20A.inc)		; Select Skywalker 20A pinout
ENDIF

IF BESCNO == Skywalker_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Skywalker_20A.inc)		; Select Skywalker 20A pinout
ENDIF

IF BESCNO == Skywalker_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Skywalker_20A.inc)		; Select Skywalker 20A pinout
ENDIF

IF BESCNO == Skywalker_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Skywalker_40A.inc)		; Select Skywalker 40A pinout
ENDIF

IF BESCNO == Skywalker_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Skywalker_40A.inc)		; Select Skywalker 40A pinout
ENDIF

IF BESCNO == Skywalker_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Skywalker_40A.inc)		; Select Skywalker 40A pinout
ENDIF

IF BESCNO == HiModel_Cool_22A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (HiModel_Cool_22A.inc)	; Select HiModel Cool 22A pinout
ENDIF

IF BESCNO == HiModel_Cool_22A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (HiModel_Cool_22A.inc)	; Select HiModel Cool 22A pinout
ENDIF

IF BESCNO == HiModel_Cool_22A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (HiModel_Cool_22A.inc)	; Select HiModel Cool 22A pinout
ENDIF

IF BESCNO == HiModel_Cool_33A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (HiModel_Cool_33A.inc)	; Select HiModel Cool 33A pinout
ENDIF

IF BESCNO == HiModel_Cool_33A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (HiModel_Cool_33A.inc)	; Select HiModel Cool 33A pinout
ENDIF

IF BESCNO == HiModel_Cool_33A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (HiModel_Cool_33A.inc)	; Select HiModel Cool 33A pinout
ENDIF

IF BESCNO == HiModel_Cool_41A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (HiModel_Cool_41A.inc)	; Select HiModel Cool 41A pinout
ENDIF

IF BESCNO == HiModel_Cool_41A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (HiModel_Cool_41A.inc)	; Select HiModel Cool 41A pinout
ENDIF

IF BESCNO == HiModel_Cool_41A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (HiModel_Cool_41A.inc)	; Select HiModel Cool 41A pinout
ENDIF

IF BESCNO == RCTimer_6A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (RCTimer_6A.inc)		; Select RC Timer 6A pinout
ENDIF

IF BESCNO == RCTimer_6A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (RCTimer_6A.inc)		; Select RC Timer 6A pinout
ENDIF

IF BESCNO == RCTimer_6A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (RCTimer_6A.inc)		; Select RC Timer 6A pinout
ENDIF

IF BESCNO == Align_RCE_BL15X_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Align_RCE_BL15X.inc)	; Select Align RCE-BL15X pinout
ENDIF

IF BESCNO == Align_RCE_BL15X_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Align_RCE_BL15X.inc)	; Select Align RCE-BL15X pinout
ENDIF

IF BESCNO == Align_RCE_BL15X_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Align_RCE_BL15X.inc)	; Select Align RCE-BL15X pinout
ENDIF

IF BESCNO == Align_RCE_BL15P_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Align_RCE_BL15P.inc)	; Select Align RCE-BL15P pinout
ENDIF

IF BESCNO == Align_RCE_BL15P_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Align_RCE_BL15P.inc)	; Select Align RCE-BL15P pinout
ENDIF

IF BESCNO == Align_RCE_BL15P_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Align_RCE_BL15P.inc)	; Select Align RCE-BL15P pinout
ENDIF

IF BESCNO == Align_RCE_BL35X_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Align_RCE_BL35X.inc)	; Select Align RCE-BL35X pinout
ENDIF

IF BESCNO == Align_RCE_BL35X_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Align_RCE_BL35X.inc)	; Select Align RCE-BL35X pinout
ENDIF

IF BESCNO == Align_RCE_BL35X_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Align_RCE_BL35X.inc)	; Select Align RCE-BL35X pinout
ENDIF

IF BESCNO == Align_RCE_BL35P_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Align_RCE_BL35P.inc)	; Select Align RCE-BL35P pinout
ENDIF

IF BESCNO == Align_RCE_BL35P_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Align_RCE_BL35P.inc)	; Select Align RCE-BL35P pinout
ENDIF

IF BESCNO == Align_RCE_BL35P_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Align_RCE_BL35P.inc)	; Select Align RCE-BL35P pinout
ENDIF

IF BESCNO == Gaui_GE_183_18A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Gaui_GE_183_18A.inc)	; Select Gaui GE-183 18A pinout
ENDIF

IF BESCNO == Gaui_GE_183_18A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Gaui_GE_183_18A.inc)	; Select Gaui GE-183 18A pinout
ENDIF

IF BESCNO == Gaui_GE_183_18A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Gaui_GE_183_18A.inc)	; Select Gaui GE-183 18A pinout
ENDIF

IF BESCNO == H_King_10A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (H_King_10A.inc)		; Select H-King 10A pinout
ENDIF

IF BESCNO == H_King_10A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (H_King_10A.inc)		; Select H-King 10A pinout
ENDIF

IF BESCNO == H_King_10A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (H_King_10A.inc)		; Select H-King 10A pinout
ENDIF

IF BESCNO == H_King_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (H_King_20A.inc)		; Select H-King 20A pinout
ENDIF

IF BESCNO == H_King_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (H_King_20A.inc)		; Select H-King 20A pinout
ENDIF

IF BESCNO == H_King_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (H_King_20A.inc)		; Select H-King 20A pinout
ENDIF

IF BESCNO == H_King_35A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (H_King_35A.inc)		; Select H-King 35A pinout
ENDIF

IF BESCNO == H_King_35A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (H_King_35A.inc)		; Select H-King 35A pinout
ENDIF

IF BESCNO == H_King_35A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (H_King_35A.inc)		; Select H-King 35A pinout
ENDIF

IF BESCNO == H_King_50A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (H_King_50A.inc)		; Select H-King 50A pinout
ENDIF

IF BESCNO == H_King_50A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (H_King_50A.inc)		; Select H-King 50A pinout
ENDIF

IF BESCNO == H_King_50A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (H_King_50A.inc)		; Select H-King 50A pinout
ENDIF

IF BESCNO == Polaris_Thunder_12A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_12A.inc)	; Select Polaris Thunder 12A pinout
ENDIF

IF BESCNO == Polaris_Thunder_12A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_12A.inc)	; Select Polaris Thunder 12A pinout
ENDIF

IF BESCNO == Polaris_Thunder_12A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_12A.inc)	; Select Polaris Thunder 12A pinout
ENDIF

IF BESCNO == Polaris_Thunder_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_20A.inc)	; Select Polaris Thunder 20A pinout
ENDIF

IF BESCNO == Polaris_Thunder_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_20A.inc)	; Select Polaris Thunder 20A pinout
ENDIF

IF BESCNO == Polaris_Thunder_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_20A.inc)	; Select Polaris Thunder 20A pinout
ENDIF

IF BESCNO == Polaris_Thunder_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_30A.inc)	; Select Polaris Thunder 30A pinout
ENDIF

IF BESCNO == Polaris_Thunder_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_30A.inc)	; Select Polaris Thunder 30A pinout
ENDIF

IF BESCNO == Polaris_Thunder_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_30A.inc)	; Select Polaris Thunder 30A pinout
ENDIF

IF BESCNO == Polaris_Thunder_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_40A.inc)	; Select Polaris Thunder 40A pinout
ENDIF

IF BESCNO == Polaris_Thunder_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_40A.inc)	; Select Polaris Thunder 40A pinout
ENDIF

IF BESCNO == Polaris_Thunder_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_40A.inc)	; Select Polaris Thunder 40A pinout
ENDIF

IF BESCNO == Polaris_Thunder_60A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_60A.inc)	; Select Polaris Thunder 60A pinout
ENDIF

IF BESCNO == Polaris_Thunder_60A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_60A.inc)	; Select Polaris Thunder 60A pinout
ENDIF

IF BESCNO == Polaris_Thunder_60A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_60A.inc)	; Select Polaris Thunder 60A pinout
ENDIF

IF BESCNO == Polaris_Thunder_80A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_80A.inc)	; Select Polaris Thunder 80A pinout
ENDIF

IF BESCNO == Polaris_Thunder_80A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_80A.inc)	; Select Polaris Thunder 80A pinout
ENDIF

IF BESCNO == Polaris_Thunder_80A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_80A.inc)	; Select Polaris Thunder 80A pinout
ENDIF

IF BESCNO == Polaris_Thunder_100A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Polaris_Thunder_100A.inc); Select Polaris Thunder 100A pinout
ENDIF

IF BESCNO == Polaris_Thunder_100A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Polaris_Thunder_100A.inc); Select Polaris Thunder 100A pinout
ENDIF

IF BESCNO == Polaris_Thunder_100A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Polaris_Thunder_100A.inc); Select Polaris Thunder 100A pinout
ENDIF

IF BESCNO == Platinum_Pro_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Platinum_Pro_30A.inc)	; Select Platinum Pro 30A pinout
ENDIF

IF BESCNO == Platinum_Pro_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Platinum_Pro_30A.inc)	; Select Platinum Pro 30A pinout
ENDIF

IF BESCNO == Platinum_Pro_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Platinum_Pro_30A.inc)	; Select Platinum Pro 30A pinout
ENDIF

IF BESCNO == Platinum_Pro_150A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Platinum_Pro_150A.inc)	; Select Platinum Pro 150A pinout
ENDIF

IF BESCNO == Platinum_Pro_150A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Platinum_Pro_150A.inc)	; Select Platinum Pro 150A pinout
ENDIF

IF BESCNO == Platinum_Pro_150A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Platinum_Pro_150A.inc)	; Select Platinum Pro 150A pinout
ENDIF

IF BESCNO == Platinum_50Av3_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Platinum_50Av3.inc)		; Select Platinum 50A v3 pinout
ENDIF

IF BESCNO == Platinum_50Av3_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Platinum_50Av3.inc)		; Select Platinum 50A v3 pinout
ENDIF

IF BESCNO == Platinum_50Av3_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Platinum_50Av3.inc)		; Select Platinum 50A v3 pinout
ENDIF

IF BESCNO == EAZY_3Av2_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (EAZY_3Av2.inc)			; Select Eazy 3A v2 pinout
ENDIF

IF BESCNO == EAZY_3Av2_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (EAZY_3Av2.inc)			; Select Eazy 3A v2 pinout
ENDIF

IF BESCNO == EAZY_3Av2_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (EAZY_3Av2.inc)			; Select Eazy 3A v2 pinout
ENDIF

IF BESCNO == Tarot_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Tarot_30A.inc)			; Select Tarot 30A pinout
ENDIF

IF BESCNO == Tarot_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Tarot_30A.inc)			; Select Tarot 30A pinout
ENDIF

IF BESCNO == Tarot_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Tarot_30A.inc)			; Select Tarot 30A pinout
ENDIF

IF BESCNO == SkyIII_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (SkyIII_30A.inc)		; Select SkyIII 30A pinout
ENDIF

IF BESCNO == SkyIII_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (SkyIII_30A.inc)		; Select SkyIII 30A pinout
ENDIF

IF BESCNO == SkyIII_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (SkyIII_30A.inc)		; Select SkyIII 30A pinout
ENDIF

IF BESCNO == EMAX_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (EMAX_20A.inc)			; Select EMAX 20A pinout
ENDIF

IF BESCNO == EMAX_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (EMAX_20A.inc)			; Select EMAX 20A pinout
ENDIF

IF BESCNO == EMAX_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (EMAX_20A.inc)			; Select EMAX 20A pinout
ENDIF

IF BESCNO == EMAX_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (EMAX_40A.inc)			; Select EMAX 40A pinout
ENDIF

IF BESCNO == EMAX_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (EMAX_40A.inc)			; Select EMAX 40A pinout
ENDIF

IF BESCNO == EMAX_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (EMAX_40A.inc)			; Select EMAX 40A pinout
ENDIF

IF BESCNO == XRotor_10A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XRotor_10A.inc)		; Select XRotor 10A pinout
ENDIF

IF BESCNO == XRotor_10A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XRotor_10A.inc)		; Select XRotor 10A pinout
ENDIF

IF BESCNO == XRotor_10A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XRotor_10A.inc)		; Select XRotor 10A pinout
ENDIF

IF BESCNO == XRotor_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XRotor_20A.inc)		; Select XRotor 20A pinout
ENDIF

IF BESCNO == XRotor_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XRotor_20A.inc)		; Select XRotor 20A pinout
ENDIF

IF BESCNO == XRotor_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XRotor_20A.inc)		; Select XRotor 20A pinout
ENDIF

IF BESCNO == XRotor_40A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (XRotor_40A.inc)		; Select XRotor 40A pinout
ENDIF

IF BESCNO == XRotor_40A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (XRotor_40A.inc)		; Select XRotor 40A pinout
ENDIF

IF BESCNO == XRotor_40A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (XRotor_40A.inc)		; Select XRotor 40A pinout
ENDIF

IF BESCNO == MDRX62H_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (MDRX62H.inc)			; Select MDRX62H pinout
ENDIF

IF BESCNO == MDRX62H_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (MDRX62H.inc)			; Select MDRX62H pinout
ENDIF

IF BESCNO == MDRX62H_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (MDRX62H.inc)			; Select MDRX62H pinout
ENDIF

IF BESCNO == RotorGeeks_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (RotorGeeks_20A.inc)		; Select RotorGeeks 20A pinout
ENDIF

IF BESCNO == RotorGeeks_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (RotorGeeks_20A.inc)		; Select RotorGeeks 20A pinout
ENDIF

IF BESCNO == RotorGeeks_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (RotorGeeks_20A.inc)		; Select RotorGeeks 20A pinout
ENDIF

IF BESCNO == Flycolor_Fairy_6A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Flycolor_Fairy_6A.inc)	; Select Flycolor Fairy 6A pinout
ENDIF

IF BESCNO == Flycolor_Fairy_6A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Flycolor_Fairy_6A.inc)	; Select Flycolor Fairy 6A pinout
ENDIF

IF BESCNO == Flycolor_Fairy_6A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Flycolor_Fairy_6A.inc)	; Select Flycolor Fairy 6A pinout
ENDIF

IF BESCNO == Flycolor_Fairy_30A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (Flycolor_Fairy_30A.inc)	; Select Flycolor Fairy 30A pinout
ENDIF

IF BESCNO == Flycolor_Fairy_30A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (Flycolor_Fairy_30A.inc)	; Select Flycolor Fairy 30A pinout
ENDIF

IF BESCNO == Flycolor_Fairy_30A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (Flycolor_Fairy_30A.inc)	; Select Flycolor Fairy 30A pinout
ENDIF

IF BESCNO == FVT_Littlebee_20A_Main
MODE 	EQU 	0				; Choose mode. Set to 0 for main motor
$include (FVT_Littlebee_20A.inc)	; Select Favourite Littlebee 20A pinout
ENDIF

IF BESCNO == FVT_Littlebee_20A_Tail
MODE 	EQU 	1				; Choose mode. Set to 1 for tail motor
$include (FVT_Littlebee_20A.inc)	; Select Favourite Littlebee 20A pinout
ENDIF

IF BESCNO == FVT_Littlebee_20A_Multi
MODE 	EQU 	2				; Choose mode. Set to 2 for multirotor
$include (FVT_Littlebee_20A.inc)	; Select Favourite Littlebee 20A pinout
ENDIF


; Not generally released ESCs
;MODE 	EQU 	2				; Choose mode
;$include (Nixie.inc)			; Select Nixie pinout


;**** **** **** **** ****
; TX programming defaults
;
; Parameter dependencies:
; - Governor P gain, I gain and Range is only used if one of the three governor modes is selected
; - Governor setup target is only used if Setup governor mode is selected (or closed loop mode is on for multi)
;
; MAIN
DEFAULT_PGM_MAIN_P_GAIN 			EQU 7 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MAIN_I_GAIN 			EQU 7 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MAIN_GOVERNOR_MODE 	EQU 1 	; 1=Tx 		2=Arm 		3=Setup		4=Off
DEFAULT_PGM_MAIN_GOVERNOR_RANGE 	EQU 1 	; 1=High		2=Middle		3=Low
DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	EQU 4 	; 1=Off		2=3.0V/c		3=3.1V/c		4=3.2V/c		5=3.3V/c	6=3.4V/c
DEFAULT_PGM_MAIN_COMM_TIMING		EQU 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
IF DAMPED_MODE_ENABLE == 1
DEFAULT_PGM_MAIN_PWM_FREQ 		EQU 2 	; 1=High 		2=Low		3=DampedLight
ELSE
DEFAULT_PGM_MAIN_PWM_FREQ 		EQU 2 	; 1=High 		2=Low	
ENDIF
DEFAULT_PGM_MAIN_DEMAG_COMP 		EQU 1 	; 1=Disabled	2=Low		3=High
DEFAULT_PGM_MAIN_DIRECTION		EQU 1 	; 1=Normal 	2=Reversed
DEFAULT_PGM_MAIN_RCP_PWM_POL 		EQU 1 	; 1=Positive 	2=Negative
DEFAULT_PGM_MAIN_GOV_SETUP_TARGET	EQU 180	; Target for governor in setup mode. Corresponds to 70% throttle
DEFAULT_PGM_MAIN_REARM_START		EQU 0 	; 1=Enabled 	0=Disabled
DEFAULT_PGM_MAIN_BEEP_STRENGTH	EQU 120	; Beep strength
DEFAULT_PGM_MAIN_BEACON_STRENGTH	EQU 200	; Beacon strength
DEFAULT_PGM_MAIN_BEACON_DELAY		EQU 4 	; 1=1m		2=2m			3=5m			4=10m		5=Infinite

; TAIL
DEFAULT_PGM_TAIL_GAIN 			EQU 3 	; 1=0.75 		2=0.88 		3=1.00 		4=1.12 		5=1.25
DEFAULT_PGM_TAIL_IDLE_SPEED 		EQU 4 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_TAIL_COMM_TIMING		EQU 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
IF DAMPED_MODE_ENABLE == 1
DEFAULT_PGM_TAIL_PWM_FREQ	 	EQU 3 	; 1=High 		2=Low 		3=DampedLight 
ELSE
DEFAULT_PGM_TAIL_PWM_FREQ	 	EQU 1 	; 1=High 		2=Low		
ENDIF
DEFAULT_PGM_TAIL_DEMAG_COMP 		EQU 1 	; 1=Disabled	2=Low		3=High
DEFAULT_PGM_TAIL_DIRECTION		EQU 1 	; 1=Normal 	2=Reversed	3=Bidirectional
DEFAULT_PGM_TAIL_RCP_PWM_POL 		EQU 1 	; 1=Positive 	2=Negative
DEFAULT_PGM_TAIL_BEEP_STRENGTH	EQU 250	; Beep strength
DEFAULT_PGM_TAIL_BEACON_STRENGTH	EQU 250	; Beacon strength
DEFAULT_PGM_TAIL_BEACON_DELAY		EQU 4 	; 1=1m		2=2m			3=5m			4=10m		5=Infinite
DEFAULT_PGM_TAIL_PWM_DITHER		EQU 3 	; 1=1		2=3			3=7			4=15			5=31

; MULTI
DEFAULT_PGM_MULTI_P_GAIN 		EQU 9 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MULTI_I_GAIN 		EQU 9 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
DEFAULT_PGM_MULTI_GOVERNOR_MODE 	EQU 4 	; 1=HiRange	2=MidRange	3=LoRange		4=Off
DEFAULT_PGM_MULTI_GAIN 			EQU 3 	; 1=0.75 		2=0.88 		3=1.00 		4=1.12 		5=1.25
DEFAULT_PGM_MULTI_COMM_TIMING		EQU 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
IF DAMPED_MODE_ENABLE == 1
DEFAULT_PGM_MULTI_PWM_FREQ	 	EQU 1 	; 1=High 		2=Low 		3=DampedLight 
ELSE
DEFAULT_PGM_MULTI_PWM_FREQ	 	EQU 1 	; 1=High 		2=Low
ENDIF
DEFAULT_PGM_MULTI_DEMAG_COMP 		EQU 2 	; 1=Disabled	2=Low		3=High
DEFAULT_PGM_MULTI_DIRECTION		EQU 1 	; 1=Normal 	2=Reversed	3=Bidirectional
DEFAULT_PGM_MULTI_RCP_PWM_POL 	EQU 1 	; 1=Positive 	2=Negative
DEFAULT_PGM_MULTI_BEEP_STRENGTH	EQU 40	; Beep strength
DEFAULT_PGM_MULTI_BEACON_STRENGTH	EQU 80	; Beacon strength
DEFAULT_PGM_MULTI_BEACON_DELAY	EQU 4 	; 1=1m		2=2m			3=5m			4=10m		5=Infinite
DEFAULT_PGM_MULTI_PWM_DITHER		EQU 3 	; 1=1		2=3			3=7			4=15			5=31

; COMMON
DEFAULT_PGM_ENABLE_TX_PROGRAM 	EQU 1 	; 1=Enabled 	0=Disabled
DEFAULT_PGM_PPM_MIN_THROTTLE		EQU 37	; 4*37+1000=1148
DEFAULT_PGM_PPM_MAX_THROTTLE		EQU 208	; 4*208+1000=1832
DEFAULT_PGM_PPM_CENTER_THROTTLE	EQU 122	; 4*122+1000=1488 (used in bidirectional mode)
DEFAULT_PGM_BEC_VOLTAGE_HIGH		EQU 0	; 0=Low		1+= High or higher	
DEFAULT_PGM_ENABLE_TEMP_PROT	 	EQU 1 	; 1=Enabled 	0=Disabled
DEFAULT_PGM_ENABLE_POWER_PROT 	EQU 1 	; 1=Enabled 	0=Disabled
DEFAULT_PGM_ENABLE_PWM_INPUT	 	EQU 0 	; 1=Enabled 	0=Disabled

;**** **** **** **** ****
; Constant definitions for main
IF MODE == 0

GOV_SPOOLRATE		EQU	2	; Number of steps for governor requested pwm per 32ms
RCP_TIMEOUT_PPM	EQU	10	; Number of timer2H overflows (about 32ms) before considering rc pulse lost
RCP_TIMEOUT		EQU	64	; Number of timer2L overflows (about 128us) before considering rc pulse lost
RCP_SKIP_RATE		EQU 	32	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
RCP_MIN			EQU 	0	; This is minimum RC pulse length
RCP_MAX			EQU 	255	; This is maximum RC pulse length
RCP_VALIDATE		EQU 	2	; Require minimum this pulse length to validate RC pulse
RCP_STOP			EQU 	1	; Stop motor at or below this pulse length
RCP_STOP_LIMIT		EQU 	5	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

PWM_START			EQU	50 	; PWM used as max power during start

COMM_TIME_RED		EQU 	2	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
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

PWM_START			EQU	50 	; PWM used as max power during start

COMM_TIME_RED		EQU 	2	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
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
RCP_STOP_LIMIT		EQU 	5	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

PWM_START			EQU	50 	; PWM used as max power during start

COMM_TIME_RED		EQU 	2	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
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

Bit_Access:				DS	1		; MUST BE AT THIS ADDRESS. Variable at bit accessible address (for non interrupt routines)
Bit_Access_Int:			DS	1		; Variable at bit accessible address (for interrupts)

Requested_Pwm:				DS	1		; Requested pwm (from RC pulse value)
Governor_Req_Pwm:			DS	1		; Governor requested pwm (sets governor target)
Current_Pwm:				DS	1		; Current pwm
Current_Pwm_Limited:		DS	1		; Current pwm that is limited
Current_Pwm_Lim_Dith:		DS	1		; Current pwm that is limited and dithered (applied to the motor output)
Rcp_Prev_Edge_L:			DS	1		; RC pulse previous edge timer3 timestamp (lo byte)
Rcp_Prev_Edge_H:			DS	1		; RC pulse previous edge timer3 timestamp (hi byte)
Rcp_Outside_Range_Cnt:		DS	1		; RC pulse outside range counter (incrementing) 
Rcp_Timeout_Cnt:			DS	1		; RC pulse timeout counter (decrementing) 
Rcp_Skip_Cnt:				DS	1		; RC pulse skip counter (decrementing) 

Flags0:					DS	1    	; State flags. Reset upon init_start
T3_PENDING				EQU 	0		; Timer3 pending flag
RCP_MEAS_PWM_FREQ			EQU	1		; Measure RC pulse pwm frequency
PWM_ON					EQU	2		; Set in on part of pwm cycle
PWM_TIMER0_OVERFLOW			EQU	3		; Set for 48MHz MCUs when PWM timer 0 overflows
DEMAG_ENABLED				EQU 	4		; Set when demag compensation is enabled (above a min speed and throttle)
DEMAG_DETECTED				EQU 	5		; Set when excessive demag time is detected
DEMAG_CUT_POWER			EQU 	6		; Set when demag compensation cuts power
;						EQU 	7

Flags1:					DS	1    	; State flags. Reset upon init_start 
MOTOR_SPINNING				EQU	0		; Set when in motor is spinning
STARTUP_PHASE				EQU 	1		; Set when in startup phase
INITIAL_RUN_PHASE			EQU	2		; Set when in initial run phase, before synchronized run is achieved
DIR_CHANGE_BRAKE			EQU 	3		; Set when braking before direction change
COMP_TIMED_OUT				EQU 	4		; Set when comparator reading timed out
GOV_ACTIVE				EQU 	5		; Set when governor is active (enabled when speed is above minimum)
;						EQU 	6
;						EQU 	7

Flags2:					DS	1		; State flags. NOT reset upon init_start
RCP_UPDATED				EQU 	0		; New RC pulse length value available
RCP_EDGE_NO				EQU 	1		; RC pulse edge no. 0=rising, 1=falling
PGM_PWMOFF_DAMPED			EQU	2		; Programmed pwm off damped mode
PGM_PWM_HIGH_FREQ			EQU	3		; Progremmed pwm high frequency
RCP_PPM					EQU 	4		; RC pulse ppm type input (set also when oneshot is set)
RCP_PPM_ONESHOT125			EQU 	5		; RC pulse ppm type input is OneShot125
;						EQU 	6	
;						EQU 	7	

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

Startup_Cnt:				DS	1		; Startup phase commutations counter (incrementing)
Initial_Run_Rot_Cnt:		DS	1		; Initial run rotations counter (incrementing)
Demag_Detected_Metric:		DS	1		; Metric used to gauge demag event frequency
Demag_Pwr_Off_Thresh:		DS	1		; Metric threshold above which power is cut
Low_Rpm_Pwr_Slope:			DS	1		; Sets the slope of power increase for low rpms

Prev_Comm_L:				DS	1		; Previous commutation timer3 timestamp (lo byte)
Prev_Comm_H:				DS	1		; Previous commutation timer3 timestamp (hi byte)
Prev_Prev_Comm_L:			DS	1		; Pre-previous commutation timer3 timestamp (lo byte)
Prev_Prev_Comm_H:			DS	1		; Pre-previous commutation timer3 timestamp (hi byte)
Comm_Period4x_L:			DS	1		; Timer3 counts between the last 4 commutations (lo byte)
Comm_Period4x_H:			DS	1		; Timer3 counts between the last 4 commutations (hi byte)
Comm_Diff:				DS	1		; Timer3 count difference between the last two commutations
Comm_Phase:				DS	1		; Current commutation phase
Comparator_Read_Cnt: 		DS	1		; Number of comparator reads done

Gov_Target_L:				DS	1		; Governor target (lo byte)
Gov_Target_H:				DS	1		; Governor target (hi byte)
Gov_Integral_L:			DS	1		; Governor integral error (lo byte)
Gov_Integral_H:			DS	1		; Governor integral error (hi byte)
Gov_Integral_X:			DS	1		; Governor integral error (ex byte)
Gov_Proportional_L:			DS	1		; Governor proportional error (lo byte)
Gov_Proportional_H:			DS	1		; Governor proportional error (hi byte)
Gov_Prop_Pwm:				DS	1		; Governor calculated new pwm based upon proportional error
Gov_Arm_Target:			DS	1		; Governor arm target value

Wt_Advance_L:				DS	1		; Timer3 counts for commutation advance timing (lo byte)
Wt_Advance_H:				DS	1		; Timer3 counts for commutation advance timing (hi byte)
Wt_Zc_Scan_L:				DS	1		; Timer3 counts from commutation to zero cross scan (lo byte)
Wt_Zc_Scan_H:				DS	1		; Timer3 counts from commutation to zero cross scan (hi byte)
Wt_Zc_Timeout_L:			DS	1		; Timer3 counts for zero cross scan timeout (lo byte)
Wt_Zc_Timeout_H:			DS	1		; Timer3 counts for zero cross scan timeout (hi byte)
Wt_Comm_L:				DS	1		; Timer3 counts from zero cross to commutation (lo byte)
Wt_Comm_H:				DS	1		; Timer3 counts from zero cross to commutation (hi byte)
Next_Wt_L:				DS	1		; Timer3 counts for next wait period (lo byte)
Next_Wt_H:				DS	1		; Timer3 counts for next wait period (hi byte)

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
Auto_Bailout_Armed:			DS	1		; Set when auto rotation bailout is armed 

Pwm_Limit:				DS	1		; Maximum allowed pwm 
Pwm_Limit_Spoolup:			DS	1		; Maximum allowed pwm during spoolup
Pwm_Limit_Low_Rpm:			DS	1		; Maximum allowed pwm for low rpms
Pwm_Spoolup_Beg:			DS	1		; Pwm to begin main spoolup with
Pwm_Motor_Idle:			DS	1		; Motor idle speed pwm
Pwm_Dither_Decoded:			DS	1		; Decoded pwm dither value
Pwm_Dither_Excess_Power:		DS	1		; Excess power (above max) from pwm dither
Random:					DS	1		; Random number from LFSR 

Spoolup_Limit_Cnt:			DS	1		; Interrupt count for spoolup limit
Spoolup_Limit_Skip:			DS	1		; Interrupt skips for spoolup limit increment (1=no skips, 2=skip one etc)
Main_Spoolup_Time_3x:		DS	1		; Main spoolup time x3
Main_Spoolup_Time_10x:		DS	1		; Main spoolup time x10
Main_Spoolup_Time_15x:		DS	1		; Main spoolup time x15

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

Skip_T2_Int:				DS	1		; Set for 48MHz MCUs when timer 2 interrupt shall be ignored 
Skip_T2h_Int:				DS	1		; Set for 48MHz MCUs when timer 2 high interrupt shall be ignored 
Timer0_Overflow_Value:		DS	1		; Remaining timer 0 wait time used with 48MHz MCUs
Clock_Set_At_48MHz:			DS	1		; Variable set if 48MHz MCUs run at 48MHz
DampingFET:				DS	1		; Port position of fet used for damping
Brake_Cnt:				DS	1		; Number of rotations for braking

; Indirect addressing data segment. The variables below must be in this sequence
ISEG AT 080h					
Pgm_Gov_P_Gain:			DS	1		; Programmed governor P gain
Pgm_Gov_I_Gain:			DS	1		; Programmed governor I gain
Pgm_Gov_Mode:				DS	1		; Programmed governor mode
Pgm_Low_Voltage_Lim:		DS	1		; Programmed low voltage limit
Pgm_Motor_Gain:			DS	1		; Programmed motor gain
Pgm_Motor_Idle:			DS	1		; Programmed motor idle speed
Pgm_Startup_Pwr:			DS	1		; Programmed startup power
Pgm_Pwm_Freq:				DS	1		; Programmed pwm frequency
Pgm_Direction:				DS	1		; Programmed rotation direction
Pgm_Input_Pol:				DS	1		; Programmed input pwm polarity
Initialized_L_Dummy:		DS	1		; Place holder
Initialized_H_Dummy:		DS	1		; Place holder
Pgm_Enable_TX_Program:		DS 	1		; Programmed enable/disable value for TX programming
Pgm_Main_Rearm_Start:		DS 	1		; Programmed enable/disable re-arming main every start 
Pgm_Gov_Setup_Target:		DS 	1		; Programmed main governor setup target
_Pgm_Startup_Rpm:			DS	1		; Programmed startup rpm (unused - place holder)
_Pgm_Startup_Accel:			DS	1		; Programmed startup acceleration (unused - place holder)
_Pgm_Volt_Comp:			DS	1		; Place holder
Pgm_Comm_Timing:			DS	1		; Programmed commutation timing
_Pgm_Damping_Force:			DS	1		; Programmed damping force (unused - place holder)
Pgm_Gov_Range:				DS	1		; Programmed governor range
_Pgm_Startup_Method:		DS	1		; Programmed startup method (unused - place holder)
Pgm_Ppm_Min_Throttle:		DS	1		; Programmed throttle minimum
Pgm_Ppm_Max_Throttle:		DS	1		; Programmed throttle maximum
Pgm_Beep_Strength:			DS	1		; Programmed beep strength
Pgm_Beacon_Strength:		DS	1		; Programmed beacon strength
Pgm_Beacon_Delay:			DS	1		; Programmed beacon delay
_Pgm_Throttle_Rate:			DS	1		; Programmed throttle rate (unused - place holder)
Pgm_Demag_Comp:			DS	1		; Programmed demag compensation
Pgm_BEC_Voltage_High:		DS	1		; Programmed BEC voltage
Pgm_Ppm_Center_Throttle:		DS	1		; Programmed throttle center (in bidirectional mode)
Pgm_Main_Spoolup_Time:		DS	1		; Programmed main spoolup time
Pgm_Enable_Temp_Prot:		DS	1		; Programmed temperature protection enable
Pgm_Enable_Power_Prot:		DS	1		; Programmed low rpm power protection enable
Pgm_Enable_Pwm_Input:		DS	1		; Programmed PWM input signal enable
Pgm_Pwm_Dither:			DS	1		; Programmed output PWM dither

; The sequence of the variables below is no longer of importance
Pgm_Gov_P_Gain_Decoded:		DS	1		; Programmed governor decoded P gain
Pgm_Gov_I_Gain_Decoded:		DS	1		; Programmed governor decoded I gain
Pgm_Startup_Pwr_Decoded:		DS	1		; Programmed startup power decoded


; Indirect addressing data segment
ISEG AT 0D0h					
Tag_Temporary_Storage:		DS	48		; Temporary storage for tags when updating "Eeprom"


;**** **** **** **** ****
CSEG AT 1A00h            ; "Eeprom" segment
EEPROM_FW_MAIN_REVISION		EQU	14		; Main revision of the firmware
EEPROM_FW_SUB_REVISION		EQU	0		; Sub revision of the firmware
EEPROM_LAYOUT_REVISION		EQU	20		; Revision of the EEPROM layout

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
Eep_Pgm_Direction:			DB	DEFAULT_PGM_MAIN_DIRECTION		; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:			DB	DEFAULT_PGM_MAIN_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:			DB	0A5h							; EEPROM initialized signature low byte
Eep_Initialized_H:			DB	05Ah							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
Eep_Main_Rearm_Start:		DB	DEFAULT_PGM_MAIN_REARM_START		; EEPROM re-arming main enable
Eep_Pgm_Gov_Setup_Target:	DB	DEFAULT_PGM_MAIN_GOV_SETUP_TARGET	; EEPROM main governor setup target
_Eep_Pgm_Startup_Rpm:		DB	0FFh	
_Eep_Pgm_Startup_Accel:		DB	0FFh	
_Eep_Pgm_Volt_Comp:			DB	0FFh	
Eep_Pgm_Comm_Timing:		DB	DEFAULT_PGM_MAIN_COMM_TIMING		; EEPROM copy of programmed commutation timing
_Eep_Pgm_Damping_Force:		DB	0FFh						
Eep_Pgm_Gov_Range:			DB	DEFAULT_PGM_MAIN_GOVERNOR_RANGE	; EEPROM copy of programmed governor range
_Eep_Pgm_Startup_Method:		DB	0FFh	
Eep_Pgm_Ppm_Min_Throttle:	DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		DB	DEFAULT_PGM_MAIN_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		DB	DEFAULT_PGM_MAIN_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		DB	DEFAULT_PGM_MAIN_BEACON_DELAY		; EEPROM copy of programmed beacon delay
_Eep_Pgm_Throttle_Rate:		DB	0FFh	
Eep_Pgm_Demag_Comp:			DB	DEFAULT_PGM_MAIN_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
_Eep_Pgm_Ppm_Center_Throttle:	DB	0FFh							
Eep_Pgm_Main_Spoolup_Time:	DB	DEFAULT_PGM_MAIN_SPOOLUP_TIME		; EEPROM copy of programmed main spoolup time
Eep_Pgm_Temp_Prot_Enable:	DB	DEFAULT_PGM_ENABLE_TEMP_PROT		; EEPROM copy of programmed temperature protection enable
Eep_Pgm_Enable_Power_Prot:	DB	DEFAULT_PGM_ENABLE_POWER_PROT		; EEPROM copy of programmed low rpm power protection enable
Eep_Pgm_Enable_Pwm_Input:	DB	DEFAULT_PGM_ENABLE_PWM_INPUT		; EEPROM copy of programmed PWM input signal enable
_Eep_Pgm_Pwm_Dither:		DB	0FFh	
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
Eep_Pgm_Direction:			DB	DEFAULT_PGM_TAIL_DIRECTION		; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:			DB	DEFAULT_PGM_TAIL_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:			DB	05Ah							; EEPROM initialized signature low byte
Eep_Initialized_H:			DB	0A5h							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
_Eep_Main_Rearm_Start:		DB	0FFh							
_Eep_Pgm_Gov_Setup_Target:	DB	0FFh							
_Eep_Pgm_Startup_Rpm:		DB	0FFh
_Eep_Pgm_Startup_Accel:		DB	0FFh
_Eep_Pgm_Volt_Comp:			DB	0FFh	
Eep_Pgm_Comm_Timing:		DB	DEFAULT_PGM_TAIL_COMM_TIMING		; EEPROM copy of programmed commutation timing
_Eep_Pgm_Damping_Force:		DB	0FFh
_Eep_Pgm_Gov_Range:			DB	0FFh	
_Eep_Pgm_Startup_Method:		DB	0FFh
Eep_Pgm_Ppm_Min_Throttle:	DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		DB	DEFAULT_PGM_TAIL_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		DB	DEFAULT_PGM_TAIL_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		DB	DEFAULT_PGM_TAIL_BEACON_DELAY		; EEPROM copy of programmed beacon delay
_Eep_Pgm_Throttle_Rate:		DB	0FFh
Eep_Pgm_Demag_Comp:			DB	DEFAULT_PGM_TAIL_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
Eep_Pgm_Ppm_Center_Throttle:	DB	DEFAULT_PGM_PPM_CENTER_THROTTLE	; EEPROM copy of programmed center throttle (final value is 4x+1000=1488)
_Eep_Pgm_Main_Spoolup_Time:	DB	0FFh
Eep_Pgm_Temp_Prot_Enable:	DB	DEFAULT_PGM_ENABLE_TEMP_PROT		; EEPROM copy of programmed temperature protection enable
Eep_Pgm_Enable_Power_Prot:	DB	DEFAULT_PGM_ENABLE_POWER_PROT		; EEPROM copy of programmed low rpm power protection enable
Eep_Pgm_Enable_Pwm_Input:	DB	DEFAULT_PGM_ENABLE_PWM_INPUT		; EEPROM copy of programmed PWM input signal enable
Eep_Pgm_Pwm_Dither:			DB	DEFAULT_PGM_TAIL_PWM_DITHER		; EEPROM copy of programmed output PWM dither
ENDIF

IF MODE == 2
Eep_Pgm_Gov_P_Gain:			DB	DEFAULT_PGM_MULTI_P_GAIN			; EEPROM copy of programmed closed loop P gain
Eep_Pgm_Gov_I_Gain:			DB	DEFAULT_PGM_MULTI_I_GAIN			; EEPROM copy of programmed closed loop I gain
Eep_Pgm_Gov_Mode:			DB	DEFAULT_PGM_MULTI_GOVERNOR_MODE	; EEPROM copy of programmed closed loop mode
_Eep_Pgm_Low_Voltage_Lim:	DB	0FFh							
Eep_Pgm_Motor_Gain:			DB	DEFAULT_PGM_MULTI_GAIN			; EEPROM copy of programmed tail gain
_Eep_Pgm_Motor_Idle:		DB	0FFh							; EEPROM copy of programmed tail idle speed
Eep_Pgm_Startup_Pwr:		DB	DEFAULT_PGM_MULTI_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:			DB	DEFAULT_PGM_MULTI_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction:			DB	DEFAULT_PGM_MULTI_DIRECTION		; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:			DB	DEFAULT_PGM_MULTI_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:			DB	055h							; EEPROM initialized signature low byte
Eep_Initialized_H:			DB	0AAh							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
_Eep_Main_Rearm_Start:		DB	0FFh							
_Eep_Pgm_Gov_Setup_Target:	DB	0FFh							
_Eep_Pgm_Startup_Rpm:		DB	0FFh
_Eep_Pgm_Startup_Accel:		DB	0FFh
_Eep_Pgm_Volt_Comp:			DB	0FFh	
Eep_Pgm_Comm_Timing:		DB	DEFAULT_PGM_MULTI_COMM_TIMING		; EEPROM copy of programmed commutation timing
_Eep_Pgm_Damping_Force:		DB	0FFh
_Eep_Pgm_Gov_Range:			DB	0FFh	
_Eep_Pgm_Startup_Method:		DB	0FFh
Eep_Pgm_Ppm_Min_Throttle:	DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		DB	DEFAULT_PGM_MULTI_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		DB	DEFAULT_PGM_MULTI_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		DB	DEFAULT_PGM_MULTI_BEACON_DELAY	; EEPROM copy of programmed beacon delay
_Eep_Pgm_Throttle_Rate:		DB	0FFh
Eep_Pgm_Demag_Comp:			DB	DEFAULT_PGM_MULTI_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
Eep_Pgm_Ppm_Center_Throttle:	DB	DEFAULT_PGM_PPM_CENTER_THROTTLE	; EEPROM copy of programmed center throttle (final value is 4x+1000=1488)
_Eep_Pgm_Main_Spoolup_Time:	DB	0FFh
Eep_Pgm_Temp_Prot_Enable:	DB	DEFAULT_PGM_ENABLE_TEMP_PROT		; EEPROM copy of programmed temperature protection enable
Eep_Pgm_Enable_Power_Prot:	DB	DEFAULT_PGM_ENABLE_POWER_PROT		; EEPROM copy of programmed low rpm power protection enable
Eep_Pgm_Enable_Pwm_Input:	DB	DEFAULT_PGM_ENABLE_PWM_INPUT		; EEPROM copy of programmed PWM input signal enable
Eep_Pgm_Pwm_Dither:			DB	DEFAULT_PGM_MULTI_PWM_DITHER		; EEPROM copy of programmed output PWM dither
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
STARTUP_POWER_TABLE:  	DB 	04h, 06h, 08h, 0Ch, 10h, 18h, 20h, 30h, 40h, 60h, 80h, 0A0h, 0C0h
PWM_DITHER_TABLE:  		DB 	00h, 07h, 0Fh, 1Fh, 3Fh
IF MODE == 0
  IF DAMPED_MODE_ENABLE == 1
	TX_PGM_PARAMS_MAIN:  	DB 	13, 13, 4, 3, 6, 13, 5, 3, 3, 2, 2
  ENDIF
  IF DAMPED_MODE_ENABLE == 0
	TX_PGM_PARAMS_MAIN:  	DB 	13, 13, 4, 3, 6, 13, 5, 2, 3, 2, 2
  ENDIF
ENDIF
IF MODE == 1
  IF DAMPED_MODE_ENABLE == 1
TX_PGM_PARAMS_TAIL:  	DB 	5, 5, 13, 5, 3, 5, 3, 3, 2
  ENDIF
  IF DAMPED_MODE_ENABLE == 0
TX_PGM_PARAMS_TAIL:  	DB 	5, 5, 13, 5, 2, 5, 3, 3, 2
  ENDIF
ENDIF
IF MODE == 2
  IF DAMPED_MODE_ENABLE == 1
TX_PGM_PARAMS_MULTI:  	DB 	13, 13, 4, 5, 13, 5, 3, 5, 3, 3, 2
  ENDIF
  IF DAMPED_MODE_ENABLE == 0
TX_PGM_PARAMS_MULTI:  	DB 	13, 13, 4, 5, 13, 5, 2, 5, 3, 3, 2
  ENDIF 
ENDIF



;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer0 interrupt routine
;
; Assumptions: DPTR register must be set to desired pwm_nfet_on label
; Requirements: Temp variables can NOT be used since PSW.3 is not set
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t0_int:	; Used for pwm control
	clr 	EA			; Disable all interrupts
IF MCU_48MHZ == 1
	; Check overflow flag
	jnb	Flags0.PWM_TIMER0_OVERFLOW, t0_int_start; Execute this interrupt

	clr	Flags0.PWM_TIMER0_OVERFLOW
	mov	TL0, Timer0_Overflow_Value	; Set timer 
	setb	EA			; Enable all interrupts
	reti

t0_int_start:
ENDIF
	push	PSW			; Preserve registers through interrupt
	push	ACC		
	; Check if pwm is on
	jb	Flags0.PWM_ON, t0_int_pwm_off	; Is pwm on?

	; Pwm on cycle
	mov	A, Current_Pwm_Limited
	jz	t0_int_pwm_on_exit

t0_int_pwm_on_execute:
	clr	A					
	jmp	@A+DPTR					; Jump to pwm on routines. DPTR should be set to one of the pwm_nfet_on labels

t0_int_pwm_on_exit:
	; Set timer for coming on cycle length
	mov 	A, Current_Pwm_Limited		; Load current pwm
		cpl	A						; cpl is 255-x
IF MCU_48MHZ == 0
	mov	TL0, A					; Write start point for timer
ELSE
	clr	C
	rlc	A
	jc	t0_int_pwm_on_set_timer

	mov	TL0, #0
	setb	Flags0.PWM_TIMER0_OVERFLOW
	mov	Timer0_Overflow_Value, A
	ajmp	t0_int_pwm_on_timer_set

t0_int_pwm_on_set_timer:
	mov	TL0, A
t0_int_pwm_on_timer_set:
ENDIF
	; Set other variables
	mov	TL1, #0					; Reset timer1	
IF MCU_48MHZ == 1
	mov	TH1, #0		
ENDIF
	setb	Flags0.PWM_ON				; Set pwm on flag
	; Exit interrupt
	pop	ACC			; Restore preserved registers
	pop	PSW
	setb	EA			; Enable all interrupts
	reti


	; Pwm off cycle
t0_int_pwm_off:
IF MCU_48MHZ == 0
	mov	TL0, Current_Pwm_Lim_Dith	; Load new timer setting
ELSE
	clr	C
	mov	A, Current_Pwm_Lim_Dith
	rlc	A
	jc	t0_int_pwm_off_set_timer 

	mov	TL0, #0
	setb	Flags0.PWM_TIMER0_OVERFLOW
	mov	Timer0_Overflow_Value, A
	ajmp	t0_int_pwm_off_timer_set

t0_int_pwm_off_set_timer:
	mov	TL0, A
t0_int_pwm_off_timer_set:
ENDIF
	; Clear pwm on flag
	clr	Flags0.PWM_ON	
	; Set full PWM (on all the time) if current PWM near max. This will give full power, but at the cost of a small "jump" in power
	mov	A, Current_Pwm_Lim_Dith		; Load current pwm
	cpl	A						; Full pwm?
	jz	t0_int_pwm_off_fullpower_exit	; Yes - exit

IF DAMPED_MODE_ENABLE == 1
	; Do not execute damped pwm when stopped
	jnb	Flags1.MOTOR_SPINNING, t0_int_pwm_off_exit_nfets_off

	; If damped operation, set pFETs on in pwm_off
	jb	Flags2.PGM_PWMOFF_DAMPED, t0_int_pwm_off_damped	; Damped operation?
ENDIF

t0_int_pwm_off_exit_nfets_off:	
	; Separate exit commands here for minimum delay
	mov	TL1, #0		; Reset timer1	
IF MCU_48MHZ == 1
	mov	TH1, #0		
ENDIF
	pop	ACC			; Restore preserved registers
	pop	PSW
	All_nFETs_Off 		; Switch off all nfets
	setb	EA			; Enable all interrupts
	reti

t0_int_pwm_off_damped:
IF PFETON_DELAY < 128
	All_nFETs_Off 				; Switch off all nfets
IF PFETON_DELAY NE 0
	mov	A, #PFETON_DELAY
	djnz	ACC, $	
ENDIF
	Damping_FET_on
ENDIF
IF PFETON_DELAY >= 128			; "Negative", 1's complement
	Damping_FET_on				; Damping fet on
	mov	A, #PFETON_DELAY
	cpl	A
	All_nFETs_Off 				; Switch off all nfets
ENDIF
t0_int_pwm_off_fullpower_exit:	
	mov	TL1, #0		; Reset timer1	
IF MCU_48MHZ == 1
	mov	TH1, #0		
ENDIF
	pop	ACC			; Restore preserved registers
	pop	PSW
	setb	EA			; Enable all interrupts
	reti


pwm_nofet:	; Dummy pwm on cycle
	ajmp	t0_int_pwm_on_exit

pwm_afet:		; Pwm on cycle afet on
	jnb	Flags1.MOTOR_SPINNING, pwm_afet_exit
	jb	Flags0.DEMAG_CUT_POWER, pwm_afet_exit 
	AnFET_on	
pwm_afet_exit:
	ajmp	t0_int_pwm_on_exit

pwm_bfet:		; Pwm on cycle bfet on
	jnb	Flags1.MOTOR_SPINNING, pwm_bfet_exit
	jb	Flags0.DEMAG_CUT_POWER, pwm_bfet_exit 
	BnFET_on
pwm_bfet_exit:
	ajmp	t0_int_pwm_on_exit

pwm_cfet:		; Pwm on cycle cfet on
	jnb	Flags1.MOTOR_SPINNING, pwm_cfet_exit
	jb	Flags0.DEMAG_CUT_POWER, pwm_cfet_exit 
	CnFET_on
pwm_cfet_exit:
	ajmp	t0_int_pwm_on_exit

pwm_afet_damped:	
	ApFET_off
	jnb	Flags1.MOTOR_SPINNING, pwm_afet_damped_exit
	jb	Flags0.DEMAG_CUT_POWER, pwm_afet_damped_exit 
IF NFETON_DELAY NE 0
	mov	A, #NFETON_DELAY					; Set delay
	djnz ACC,	$
ENDIF
	AnFET_on								; Switch nFET
pwm_afet_damped_exit:
	ajmp	t0_int_pwm_on_exit

pwm_bfet_damped:
	BpFET_off
	jnb	Flags1.MOTOR_SPINNING, pwm_bfet_damped_exit
	jb	Flags0.DEMAG_CUT_POWER, pwm_bfet_damped_exit 
IF NFETON_DELAY NE 0
	mov	A, #NFETON_DELAY					; Set delay
	djnz ACC,	$
ENDIF
	BnFET_on								; Switch nFET
pwm_bfet_damped_exit:
	ajmp	t0_int_pwm_on_exit

pwm_cfet_damped:	
	CpFET_off
	jnb	Flags1.MOTOR_SPINNING, pwm_cfet_damped_exit
	jb	Flags0.DEMAG_CUT_POWER, pwm_cfet_damped_exit 
IF NFETON_DELAY NE 0
	mov	A, #NFETON_DELAY					; Set delay
	djnz ACC,	$
ENDIF
	CnFET_on								; Switch nFET
pwm_cfet_damped_exit: 
	ajmp	t0_int_pwm_on_exit


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer2 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t2_int:	; Happens every 128us for low byte and every 32ms for high byte
	clr	EA
	clr	ET2			; Disable timer2 interrupts
	anl	EIE1, #0EFh	; Disable PCA0 interrupts
	push	PSW			; Preserve registers through interrupt
	push	ACC
	setb	PSW.3		; Select register bank 1 for interrupt routines
	setb	EA
IF MCU_48MHZ == 1
	mov	A, Clock_Set_At_48MHz
	jz 	t2_int_start

	; Check skip variable
	mov	A, Skip_T2_Int
	jz	t2_int_start				; Execute this interrupt

	mov	Skip_T2_Int, #0
	ajmp	t2_int_exit

t2_int_start:
	mov	Skip_T2_Int, #1			; Skip next interrupt
ENDIF
	; Clear low byte interrupt flag
	clr	TF2L						; Clear interrupt flag
	; Check RC pulse timeout counter
	mov	A, Rcp_Timeout_Cnt			; RC pulse timeout count zero?
	jz	t2_int_pulses_absent		; Yes - pulses are absent

	; Decrement timeout counter (if PWM)
	jb	Flags2.RCP_PPM, t2_int_skip_start	; If flag is set (PPM) - branch

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

	jb	Flags2.RCP_PPM, t2_int_ppm_timeout_set	; If flag is set (PPM) - branch

	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT	; For PWM, set timeout count to start value

t2_int_ppm_timeout_set:
	mov	New_Rcp, Temp1				; Store new pulse length
	setb	Flags2.RCP_UPDATED		 	; Set updated flag

t2_int_skip_start:
	jb	Flags2.RCP_PPM, t2_int_rcp_update_start	; If flag is set (PPM) - branch

	; Check RC pulse skip counter
	mov	A, Rcp_Skip_Cnt			
	jz 	t2_int_skip_end			; If RC pulse skip count is zero - end skipping RC pulse detection
	
	; Decrement skip counter (only if edge counter is zero)
	dec	Rcp_Skip_Cnt				; Decrement
	ajmp	t2_int_rcp_update_start

t2_int_skip_end:
	; Skip counter has reached zero, start looking for RC pulses again
	Rcp_Int_Enable 				; Enable RC pulse interrupt
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	
t2_int_rcp_update_start:
	; Process updated RC pulse
	jb	Flags2.RCP_UPDATED, ($+5)	; Is there an updated RC pulse available?
	ajmp	t2_int_current_pwm_done		; No - update pwm limits and exit

	mov	Temp1, New_Rcp				; Load new pulse value
	jb	Flags0.RCP_MEAS_PWM_FREQ, ($+5)	; If measure RCP pwm frequency flag set - do not clear flag

	clr	Flags2.RCP_UPDATED		 	; Flag that pulse has been evaluated

	; Use a gain of 1.0625x for pwm input if not governor mode
	jb	Flags2.RCP_PPM, t2_int_pwm_min_run	; If flag is set (PPM) - branch

IF MODE == 0	; Main - do not adjust gain
	ajmp	t2_int_pwm_min_run
ELSE

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
ENDIF

t2_int_pwm_min_run: 
IF MODE == 1	; Tail - limit minimum pwm
	; Limit minimum pwm
	clr	C
	mov	A, Temp1
	subb	A, Pwm_Motor_Idle			; Is requested pwm lower than minimum?
	jnc	t2_int_pwm_update			; No - branch

	mov	A, Pwm_Motor_Idle			; Yes - limit pwm to Pwm_Motor_Idle	
	mov	Temp1, A
ENDIF

t2_int_pwm_update: 
	; Update requested_pwm
	mov	Requested_Pwm, Temp1		; Set requested pwm
IF MODE >= 1	; Tail or multi
	; Limit pwm during direct start
	mov	A, Flags1
	anl	A, #((1 SHL STARTUP_PHASE)+(1 SHL INITIAL_RUN_PHASE))
	jz	t2_int_current_pwm_update

	mov	A, Startup_Cnt				; Add an extra power boost during start
	clr	C
	rrc	A
	clr	C
	rrc	A
	add	A, Requested_Pwm			
	mov	Requested_Pwm, A
	jnc	($+5)

	mov	Requested_Pwm, #0FFh

t2_int_current_pwm_update: 
ENDIF
IF MODE == 0 OR MODE == 2	; Main or multi
	mov	Temp1, #Pgm_Gov_Mode		; Governor mode?
	cjne	@Temp1, #4, t2_int_pwm_exit	; Yes - branch
ENDIF

	mov	Current_Pwm, Requested_Pwm	; Set equal as default
t2_int_current_pwm_done:
IF MODE >= 1	; Tail or multi
	; Set current_pwm_limited
	mov	Temp1, Current_Pwm			; Default not limited
	clr	C
	mov	A, Current_Pwm				; Check against limit
	subb	A, Pwm_Limit
	jc	($+4)					; If current pwm below limit - branch

	mov	Temp1, Pwm_Limit			; Limit pwm

IF MODE == 2	; Multi
	; Limit pwm for low rpms
	clr	C
	mov	A, Temp1					; Check against limit
	subb	A, Pwm_Limit_Low_Rpm
	jc	($+4)					; If current pwm below limit - branch

	mov	Temp1, Pwm_Limit_Low_Rpm		; Limit pwm

ENDIF
	mov	Current_Pwm_Limited, Temp1
	; Dither
	mov	A, Pwm_Dither_Decoded		; Load pwm dither
	jnz	($+4)					; If active - branch
	ajmp	t2_int_current_pwm_no_dither

	clr	C
	mov	A, Temp1
	mov	Temp3, Pwm_Dither_Decoded				
	subb	A, Temp3					; Calculate pwm minus dither value
	jnc	t2_int_current_pwm_full_dither; If pwm more than dither value, then do full dither

	mov	A, Temp1					; Set dither level to current pwm
	mov	Temp3, A				
	clr	A						; Set pwm minus dither

t2_int_current_pwm_full_dither:
	mov	Temp2, A					; Load pwm minus dither value
	mov	A, Temp3					; Load dither	
	clr	C
	rlc	A						; Shift left once
	mov	Temp4, A
	mov	A, Random					; Load random number
	cpl	A						; Invert to create proper DC bias in random code
	anl	A, Temp4					; And with double dither value
	add	A, Temp2					; Add pwm minus dither
	jc	t2_int_current_pwm_dither_max_excess_power	; If dither cause power above max - branch and increase excess 

	add	A, Pwm_Dither_Excess_Power	; Add excess power from previous cycles
	mov	Temp1, A
	mov	A, Pwm_Dither_Excess_Power	; Decrement excess power
	jz	($+4)
	dec	Pwm_Dither_Excess_Power
	jc	t2_int_current_pwm_dither_max_power; If dither cause power above max - branch

	ajmp	t2_int_current_pwm_no_dither

t2_int_current_pwm_dither_max_excess_power:
	inc	Temp3					; Add one to dither in order to always reach max power
	clr	C
	mov	A, Pwm_Dither_Excess_Power
	subb	A, Temp3					; Limit excess power 
	jnc	($+4)
	inc	Pwm_Dither_Excess_Power

t2_int_current_pwm_dither_max_power:
	mov	Temp1, #255				; Set power to max

t2_int_current_pwm_no_dither:
	mov	Current_Pwm_Lim_Dith, Temp1
ENDIF
t2_int_pwm_exit:	
	; Set demag enabled if pwm is above limit
	clr	C
	mov	A, Current_Pwm_Limited	
	subb	A, #40h					; Set if above 25%
	jc	($+4)

	setb	Flags0.DEMAG_ENABLED

t2_int_exit:	
	; Check if high byte flag is set
	jb	TF2H, t2h_int		
	pop	ACC			; Restore preserved registers
	pop	PSW
	clr	PSW.3		; Select register bank 0 for main program routines	
	orl	EIE1, #10h	; Enable PCA0 interrupts
	setb	ET2			; Enable timer2 interrupts
	reti

t2h_int:
IF MCU_48MHZ == 1
	mov	A, Clock_Set_At_48MHz
	jz 	t2h_int_start

	; Check skip variable
	mov	A, Skip_T2h_Int
	jz	t2h_int_start				; Execute this interrupt

	mov	Skip_T2h_Int, #0
	ajmp	t2h_int_exit

t2h_int_start:
	mov	Skip_T2h_Int, #1			; Skip next interrupt
ENDIF
	; High byte interrupt (happens every 32ms)
	clr	TF2H					; Clear interrupt flag
	mov	Temp1, #GOV_SPOOLRATE	; Load governor spool rate
	; Check RC pulse timeout counter (used here for PPM only)
	mov	A, Rcp_Timeout_Cnt			; RC pulse timeout count zero?
	jz	t2h_int_rcp_stop_check		; Yes - do not decrement

	; Decrement timeout counter (if PPM)
	jnb	Flags2.RCP_PPM, t2h_int_rcp_stop_check	; If flag is not set (PWM) - branch

	dec	Rcp_Timeout_Cnt			; No flag set (PPM) - decrement

t2h_int_rcp_stop_check:
	; Check RC pulse against stop value
	clr	C
	mov	A, New_Rcp				; Load new pulse value
	subb	A, #RCP_STOP				; Check if pulse is below stop value
	jc	t2h_int_rcp_stop

	; RC pulse higher than stop value, reset stop counter
	mov	Rcp_Stop_Cnt, #0			; Reset rcp stop counter
	ajmp	t2h_int_rcp_gov_pwm

t2h_int_rcp_stop:	
	; RC pulse less than stop value
	mov	Auto_Bailout_Armed, #0		; Disarm bailout		
	mov	Spoolup_Limit_Cnt, #0
	mov	A, Rcp_Stop_Cnt			; Increment stop counter
	add	A, #1
	mov	Rcp_Stop_Cnt, A
	jnc	t2h_int_rcp_gov_pwm			; Branch if counter has not wrapped

	mov	Rcp_Stop_Cnt, #0FFh			; Set stop counter to max

t2h_int_rcp_gov_pwm:
IF MODE == 0	; Main
	; Update governor variables
	mov	Temp2, #Pgm_Gov_Mode			; Governor target by arm mode?
	cjne	@Temp2, #2, t2h_int_rcp_gov_by_setup	; No - branch

	jnb	Flags1.GOV_ACTIVE, t2h_int_rcp_gov_by_tx; If governor not active - branch (this ensures soft spoolup by tx)

	clr	C
	mov	A, Requested_Pwm
	subb	A, #50						; Is requested pwm below 20%?
	jc	t2h_int_rcp_gov_by_tx			; Yes - branch (this enables a soft spooldown)

	mov	Requested_Pwm, Gov_Arm_Target		; Yes - load arm target

t2h_int_rcp_gov_by_setup:
	mov	Temp2, #Pgm_Gov_Mode			; Governor target by setup mode?
	cjne	@Temp2, #3, t2h_int_rcp_gov_by_tx		; No - branch

	jnb	Flags1.GOV_ACTIVE, t2h_int_rcp_gov_by_tx; If governor not active - branch (this ensures soft spoolup by tx)

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

	djnz	Spoolup_Limit_Skip, t2h_int_exit	; Jump if skip count is not reached

	mov	Spoolup_Limit_Skip, #1			; Reset skip count. Default is fast spoolup
	mov	Temp1, #5						; Default fast increase
	clr	C
	mov	A, Spoolup_Limit_Cnt
	subb	A, Main_Spoolup_Time_3x			; No spoolup until 3*N*32ms

	jc	t2h_int_exit

	clr	C
	mov	A, Spoolup_Limit_Cnt
	subb	A, Main_Spoolup_Time_10x			; Slow spoolup until "100"*N*32ms
	jnc	t2h_int_rcp_limit_middle_ramp

	mov	Temp1, #1						; Slow initial spoolup
	mov	Spoolup_Limit_Skip, #3			
	jmp	t2h_int_rcp_set_limit

t2h_int_rcp_limit_middle_ramp:
	clr	C
	mov	A, Spoolup_Limit_Cnt
	subb	A, Main_Spoolup_Time_15x			; Faster spoolup until "150"*N*32ms
	jnc	t2h_int_rcp_set_limit

	mov	Temp1, #1						; Faster middle spoolup
	mov	Spoolup_Limit_Skip, #1			

t2h_int_rcp_set_limit:
	; Do not increment spoolup limit if higher pwm is not requested, unless governor is active
	clr	C
	mov	A, Pwm_Limit_Spoolup
	subb	A, Current_Pwm
	jc	t2h_int_rcp_inc_limit			; If Current_Pwm is larger than Pwm_Limit_Spoolup - branch

	mov	Temp2, #Pgm_Gov_Mode			; Governor mode?
	cjne	@Temp2, #4, ($+5)
	ajmp	t2h_int_rcp_bailout_arm			; No - branch

	jb	Flags1.GOV_ACTIVE, t2h_int_rcp_inc_limit	; If governor active - branch 

	mov	Pwm_Limit_Spoolup, Current_Pwm	; Set limit to what current pwm is
	mov	A, Spoolup_Limit_Cnt			; Check if spoolup limit count is 255. If it is, then this is a "bailout" ramp
	inc	A
	jz	($+5)

	mov	Spoolup_Limit_Cnt, Main_Spoolup_Time_3x	; Stay in an early part of the spoolup sequence (unless "bailout" ramp)

	mov	Spoolup_Limit_Skip, #1			; Set skip count
	mov	Governor_Req_Pwm, #60			; Set governor requested speed to ensure that it requests higher speed
									; 20=Fail on jerk when governor activates
									; 30=Ok
									; 100=Fail on small governor settling overshoot on low headspeeds
									; 200=Fail on governor settling overshoot
	jmp	t2h_int_exit					; Exit

t2h_int_rcp_inc_limit:
	mov	A, Pwm_Limit_Spoolup			; Increment spoolup pwm
	add	A, Temp1
	jnc	t2h_int_rcp_no_limit			; If below 255 - branch

	mov	Pwm_Limit_Spoolup, #0FFh
	ajmp	t2h_int_rcp_bailout_arm

t2h_int_rcp_no_limit:
	mov	Pwm_Limit_Spoolup, A
t2h_int_rcp_bailout_arm:
	mov	A, Pwm_Limit_Spoolup
	inc	A
	jnz	t2h_int_exit

	mov	Auto_Bailout_Armed, #255			; Arm bailout
	mov	Spoolup_Limit_Cnt, #255			

ENDIF
t2h_int_exit:
	pop	ACC			; Restore preserved registers
	pop	PSW
	clr	PSW.3		; Select register bank 0 for main program routines	
	orl	EIE1, #10h	; Enable PCA0 interrupts
	setb	ET2			; Enable timer2 interrupts
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer3 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t3_int:	; Used for commutation timing
	push	PSW				; Preserve registers through interrupt
	push	ACC
	clr 	EA				; Disable all interrupts
	anl	EIE1, #7Fh		; Disable timer3 interrupts
	clr	Flags0.T3_PENDING 	; Flag that timer has wrapped
IF MCU_48MHZ == 1
	clr	C
	mov	A, Next_Wt_L
	rlc	A
	mov	Next_Wt_L, A
	mov	A, Next_Wt_H
	rlc	A
	mov	Next_Wt_H, A
ENDIF
	; Set up next wait
	mov	TMR3CN, #00h		; Timer3 disabled and interrupt flag cleared
	clr	C
	clr	A
	subb	A, Next_Wt_L		; Set wait value
	mov	TMR3L, A	
	clr	A
	subb	A, Next_Wt_H		
	mov	TMR3H, A
	mov	TMR3CN, #04h		; Timer3 enabled and interrupt flag cleared
	pop	ACC				; Restore preserved registers
	pop	PSW
	setb	EA				; Enable all interrupts
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; PCA interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
pca_int:	; Used for RC pulse timing
	clr	EA
	anl	EIE1, #0EFh	; Disable PCA0 interrupts
	clr	ET2			; Disable timer2 interrupts
	push	PSW			; Preserve registers through interrupt
	push	ACC
	push	B
	setb	PSW.3		; Select register bank 1 for interrupt routines
	setb	EA
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
	jnb	Flags2.RCP_PPM, ($+5)		; If flag is not set (PWM) - branch

	ajmp	pca_int_set_timeout			; If PPM - ignore trig as noise

	mov	Temp1, #RCP_MIN			; Set RC pulse value to minimum
	Read_Rcp_Int 					; Test RC signal level again
	jnb	ACC.Rcp_In, ($+5)			; Is it high?

	ajmp	pca_int_set_timeout			; Yes - set new timeout and exit

	mov	New_Rcp, Temp1				; Store new pulse length
	ajmp	pca_int_limited			; Set new RC pulse, new timeout and exit

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
	mov	Temp7, #8					; Set default period tolerance requirement (MSB)
	mov	Temp3, #0					; (LSB)
	; Check if pulse is too short
	clr	C
	mov	A, Temp1
	subb	A, #low(140)				; If pulse below 70us, not accepted
	mov	A, Temp2
	subb	A, #high(140)
	jnc	rcp_int_check_12kHz

	mov	Rcp_Period_Diff_Accepted, #0	; Set not accepted 
	ajmp	pca_int_store_data

rcp_int_check_12kHz:
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
	mov	Temp3, #10				; Set period tolerance requirement (LSB)
	ajmp	pca_int_restore_edge_set_msb

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
	mov	Temp3, #15				; Set period tolerance requirement (LSB)
	ajmp	pca_int_restore_edge_set_msb

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
	mov	Temp3, #30				; Set period tolerance requirement (LSB)
	ajmp	pca_int_restore_edge_set_msb

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
	mov	Temp3, #60				; Set period tolerance requirement (LSB)
	ajmp	pca_int_restore_edge_set_msb

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
	mov	Temp3, #120				; Set period tolerance requirement (LSB)

pca_int_restore_edge_set_msb:
	mov	Temp7, #0					; Set period tolerance requirement (MSB)
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
	clr	C
	mov	A, Temp5
	subb	A, Temp3						; Check difference
	mov	A, Temp6
	subb	A, Temp7						
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
	mov	Temp1, #RCP_VALIDATE
	ajmp	pca_int_limited

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

	jb	Flags2.RCP_PPM_ONESHOT125, ($+5)
	ajmp	rcp_int_fall_not_oneshot

	mov	A, Temp2						; Oneshot125 - move to I_Temp5/6
	mov	Temp6, A
	mov	A, Temp1
	mov	Temp5, A
	ajmp	rcp_int_fall_check_range

rcp_int_fall_not_oneshot:
	mov	A, Temp2						; No - 2kHz. Divide by 2
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
rcp_int_fall_check_range:
	; Skip range limitation if pwm frequency measurement
	jb	Flags0.RCP_MEAS_PWM_FREQ, pca_int_ppm_check_full_range 		

	; Check if 2160us or above (in order to ignore false pulses)
	clr	C
	mov	A, Temp5						; Is pulse 2160us or higher?
	subb	A, #28
	mov	A, Temp6
	subb A, #2
	jc	($+4)						; No - proceed

	ajmp	pca_int_ppm_outside_range		; Yes - ignore pulse

pca_int_ppm_below_full_range:
	; Check if below 800us (in order to ignore false pulses)
	mov	A, Temp6
	jnz	pca_int_ppm_check_full_range

	clr	C
	mov	A, Temp5						; Is pulse below 800us?
	subb	A, #200
	jnc	pca_int_ppm_check_full_range		; No - proceed

pca_int_ppm_outside_range:
	inc	Rcp_Outside_Range_Cnt
	clr	C
	mov	A, Rcp_Outside_Range_Cnt
	subb	A, #10						; Allow a given number of outside pulses
	jnc	($+4)			
	ajmp	pca_int_set_timeout				; If below limit - ignore pulse

	mov	New_Rcp, #0					; Set pulse length to zero
	setb	Flags2.RCP_UPDATED		 		; Set updated flag
	ajmp	pca_int_set_timeout			

pca_int_ppm_check_full_range:
	mov	A, Rcp_Outside_Range_Cnt
	jz	($+4)

	dec	Rcp_Outside_Range_Cnt

	; Calculate "1000us" plus throttle minimum
	mov	A, #0						; Set 1000us as default minimum
	jb	Flags3.FULL_THROTTLE_RANGE, pca_int_ppm_calculate	; Check if full range is chosen

IF MODE >= 1	; Tail or multi
	mov	Temp1, #Pgm_Direction			; Check if bidirectional operation (store in Temp2)
	mov	A, @Temp1				
	mov	Temp2, A				
ENDIF
	mov	Temp1, #Pgm_Ppm_Min_Throttle		; Min throttle value is in 4us units
IF MODE >= 1	; Tail or multi
	cjne	Temp2, #3, ($+5)

	mov	Temp1, #Pgm_Ppm_Center_Throttle	; Center throttle value is in 4us units
ENDIF
	mov	A, @Temp1				

pca_int_ppm_calculate:
	add	A, #250						; Add 1000us to minimum
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
IF MODE >= 1	; Tail or multi
	mov	Bit_Access_Int.0, C
	cjne	Temp2, #3, pca_int_ppm_bidir_dir_set; If not bidirectional operation - branch

	mov	C, Bit_Access_Int.0
	jnc	pca_int_ppm_bidir_fwd			; If result is positive - branch				

pca_int_ppm_bidir_rev:
	jb	Flags3.PGM_DIR_REV, pca_int_ppm_bidir_dir_set	; If same direction - branch

	clr	EA							; Direction change, turn off all fets
	setb	Flags3.PGM_DIR_REV
	ajmp	pca_int_ppm_bidir_dir_change

pca_int_ppm_bidir_fwd:
	jnb	Flags3.PGM_DIR_REV, pca_int_ppm_bidir_dir_set	; If same direction - branch

	clr	EA							; Direction change, turn off all fets
	clr	Flags3.PGM_DIR_REV

pca_int_ppm_bidir_dir_change:
	jb	Flags1.DIR_CHANGE_BRAKE, pca_int_ppm_bidir_dir_change_powered_off

	lcall switch_power_off
	mov	Brake_Cnt, #0

pca_int_ppm_bidir_dir_change_powered_off:
	setb	Flags1.DIR_CHANGE_BRAKE			; Set brake flag

pca_int_ppm_bidir_dir_set:
	setb	EA
	mov	C, Bit_Access_Int.0
ENDIF
	jnc	pca_int_ppm_neg_checked			; If result is positive - branch

IF MODE >= 1	; Tail or multi
	cjne	Temp2, #3, pca_int_ppm_unidir_neg 	; If not bidirectional operation - branch

	mov	A, Temp5						; Change sign		
	cpl	A
	add	A, #1
	mov	Temp5, A
	mov	A, Temp6							
	cpl	A
	addc	A, #0
	mov	Temp6, A
	jmp	pca_int_ppm_neg_checked

pca_int_ppm_unidir_neg:
ENDIF
	mov	Temp1, #RCP_MIN				; Yes - set to minimum
	mov	Temp2, #0
	ajmp	pca_int_pwm_divide_done

pca_int_ppm_neg_checked:
IF MODE >= 1	; Tail or multi
	cjne	Temp2, #3, pca_int_ppm_bidir_done	; If not bidirectional operation - branch

	mov	A, Temp5						; Multiply value by 2
	rlc	A
	mov	Temp5 A
	mov	A, Temp6
	rlc	A
	mov	Temp6 A
	clr	C							; Subtract deadband
	mov	A, Temp5
	subb	A, #10		
	mov	Temp5, A
	mov	A, Temp6
	subb	A, #0
	mov	Temp6, A
	jnc	pca_int_ppm_bidir_done

	mov	Temp5, #RCP_MIN
	mov	Temp6, #0

pca_int_ppm_bidir_done:
ENDIF
	clr	C							; Check that RC pulse is within legal range (max 255)
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
	clr	Flags2.RCP_PPM				; Default, flag is not set (PWM)
	mov	A, Temp4					; Check if all flags are cleared
	jnz	pca_int_set_timeout

	setb	Flags2.RCP_PPM				; Set flag (PPM)

pca_int_set_timeout:
	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT	; Set timeout count to start value
	jnb	Flags2.RCP_PPM, pca_int_ppm_timeout_set	; If flag is not set (PWM) - branch

	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT_PPM	; No flag set means PPM. Set timeout count

pca_int_ppm_timeout_set:
	jnb	Flags0.RCP_MEAS_PWM_FREQ, ($+5)	; Is measure RCP pwm frequency flag set?

	ajmp pca_int_exit				; Yes - exit

	jb	Flags2.RCP_PPM, pca_int_exit	; If flag is set (PPM) - branch

	Rcp_Int_Disable 				; Disable RC pulse interrupt

pca_int_exit:	; Exit interrupt routine	
	jb	Flags2.RCP_PPM, ($+6)		; If flag is set (PPP) - branch

	mov	Rcp_Skip_Cnt, #RCP_SKIP_RATE	; Load number of skips

	pop	B			; Restore preserved registers
	pop	ACC			
	pop	PSW
	clr	PSW.3		; Select register bank 0 for main program routines	
	setb	ET2			; Enable timer2 interrupts
	orl	EIE1, #10h	; Enable PCA0 interrupts
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
	jmp	waitxms_o

wait3ms:	
	mov	Temp2, #3
	jmp	waitxms_o

wait10ms:	
	mov	Temp2, #10
	jmp	waitxms_o

wait30ms:	
	mov	Temp2, #30
	jmp	waitxms_o

wait100ms:	
	mov	Temp2, #100
	jmp	waitxms_o

wait200ms:	
	mov	Temp2, #200
	jmp	waitxms_o

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
	djnz	Temp4,	beep
	BpFET_off			; BpFET off
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
IF MODE == 0	; Main
calc_governor_target:
	mov	Temp1, #Pgm_Gov_Mode			; Governor mode?
	cjne	@Temp1, #4, governor_speed_check	; Yes
	jmp	calc_governor_target_exit		; No

governor_speed_check:
	; Stop governor for stop RC pulse	
	clr	C
	mov	A, New_Rcp				; Check RC pulse against stop value
	subb	A, #(RCP_MAX/10)			; Is pulse below stop value?
	jc	governor_deactivate			; Yes - deactivate

	mov	A, Flags1
	anl	A, #((1 SHL STARTUP_PHASE)+(1 SHL INITIAL_RUN_PHASE))
	jnz	governor_deactivate			; Deactivate if any startup phase set

	; Skip speed check if governor is already active
	jb	Flags1.GOV_ACTIVE, governor_target_calc

	; Check speed (do not run governor for low speeds)
	mov	Temp1, #05h				; Default high range activation limit value (~62500 eRPM)
	mov	Temp2, #Pgm_Gov_Range
	mov	A, @Temp2					; Check if high range (Temp2 has #Pgm_Gov_Range)
	dec	A
	jz	governor_act_lim_set		; If high range - branch

	mov	Temp1, #0Ah				; Middle range activation limit value (~31250 eRPM)
	dec	A
	jz	governor_act_lim_set		; If middle range - branch
	
	mov	Temp1, #12h				; Low range activation limit value (~17400 eRPM)

governor_act_lim_set:
	clr	C
	mov	A, Comm_Period4x_H
	subb	A, Temp1
	jc	governor_activate			; If speed above min limit  - run governor

governor_deactivate:
	jnb	Flags1.GOV_ACTIVE, governor_first_deactivate_done; This code is executed continuously. Only execute the code below the first time
 
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
	clr	Flags1.GOV_ACTIVE
	jmp	calc_governor_target_exit

governor_activate:
	setb	Flags1.GOV_ACTIVE

governor_target_calc:
	; Governor calculations
	mov	Temp2, #Pgm_Gov_Range
	mov	A, @Temp2				; Check high, middle or low range
	dec	A
	jnz	calc_governor_target_middle

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
	jmp	calc_governor_subtract_025

calc_governor_target_middle:
	mov	A, @Temp2				; Check middle or low range (Temp2 has #Pgm_Gov_Range)
	dec	A
	dec	A
	jnz	calc_governor_target_low

	mov	A, Governor_Req_Pwm		; Load governor requested pwm
	cpl	A					; Calculate 255-pwm (invert pwm) 
	; Calculate comm period target (1 + 4*((255-Requested_Pwm)/256))
	rlc	A					; Msb to carry
	rlc	A					; To bit0
	rlc	A					; To bit1
	mov	Temp2, A				; Now 2 lsbs are valid for H
	rrc	A					
	mov	Temp1, A				; Now 6 msbs are valid for L
	mov	A, Temp2
	anl	A, #03h				; Calculate H byte
	inc	A					; Add 1
	mov	Temp2, A
	mov	A, Temp1
	anl	A, #0FCh				; Calculate L byte
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
	mov	Temp1, A				; Now 5 msbs are valid for L
	mov	A, Temp2
	anl	A, #07h				; Calculate H byte
	inc	A					; Add 1
	inc	A					; Add 1 more
	mov	Temp2, A
	mov	A, Temp1
	anl	A, #0F8h				; Calculate L byte
calc_governor_subtract_025:
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
IF MODE == 1	; Tail
calc_governor_target:
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
	clr	Flags1.GOV_ACTIVE
	jmp	calc_governor_target_exit

governor_activate:
	mov	Temp1, #Pgm_Gov_Mode		; Store gov mode
	mov	A, @Temp1
	mov	Temp5, A
	setb	Flags1.GOV_ACTIVE
	mov	A, Requested_Pwm			; Load requested pwm
	mov	Governor_Req_Pwm, A			; Set governor requested pwm
	; Calculate comm period target 2*(51000/Requested_Pwm)
	mov	Temp1, #38h				; Load 51000
	mov	Temp2, #0C7h
	mov	Temp3, Comm_Period4x_L		; Load comm period
	mov	Temp4, Comm_Period4x_H		
	; Set speed range. Bare Comm_Period4x corresponds to 400k eRPM, because it is 500n units
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

	jmp	governor_store_int_error		; No - store integral error

governor_int_max_pwm:
	mov	A, Gov_Proportional_H
	jb	ACC.7, calc_governor_int_error_exit	; Is proportional error negative - branch (high byte is always zero)

	jmp	governor_store_int_error		; Positive - store integral error

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
; Set pwm limit low rpm
;
; No assumptions
;
; Sets power limit for low rpms and disables demag for low rpms
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
set_pwm_limit_low_rpm:
	; Set pwm limit and demag disable for low rpms
	mov	Temp1, #0FFh					; Default full power
	clr	Flags0.DEMAG_ENABLED			; Default disabled
	mov	A, Flags1
	anl	A, #((1 SHL STARTUP_PHASE)+(1 SHL INITIAL_RUN_PHASE))
	jnz	set_pwm_limit_low_rpm_exit		; Exit if any startup phase set

	setb	Flags0.DEMAG_ENABLED			; Enable demag
	clr	C
	mov	A, Comm_Period4x_H
	subb	A, #0Ah						; ~31250 eRPM
	jc	set_pwm_demag_done				; If speed above - branch

	clr	C
	mov	A, Current_Pwm_Limited	
	subb	A, #40h						; Do not disable if pwm above 25%
	jnc	set_pwm_demag_done

	clr	Flags0.DEMAG_ENABLED			; Disable demag

set_pwm_demag_done:
	mov	Temp2, #Pgm_Enable_Power_Prot		; Check if low RPM power protection is enabled
	mov	A, @Temp2
	jz	set_pwm_limit_low_rpm_exit		; Exit if disabled

	mov	A, Comm_Period4x_H
	jz	set_pwm_limit_low_rpm_exit		; Avoid divide by zero

	mov	A, #255						; Divide 255 by Comm_Period4x_H
	mov	B, Comm_Period4x_H
	div	AB
	mov	B, Low_Rpm_Pwr_Slope			; Multiply by slope
	mul	AB
	mov	Temp1, A						; Set new limit				
	xch	A, B
	jz	($+4)						; Limit to max
	
	mov	Temp1, #0FFh				

	clr	C
	mov	A, Temp1						; Limit to min
	subb	A, Pwm_Spoolup_Beg
	jnc	set_pwm_limit_low_rpm_exit

	mov	Temp1, Pwm_Spoolup_Beg				

set_pwm_limit_low_rpm_exit:
	mov	Pwm_Limit_Low_Rpm, Temp1				
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
IF MODE >= 1	; Tail or multi
	; If not supported, then exit
	jmp	measure_lipo_exit
ENDIF
IF MODE == 0	; Main
	; Load programmed low voltage limit
	mov	Temp1, #Pgm_Low_Voltage_Lim	; Load limit
	mov	A, @Temp1				
	mov	Bit_Access, A				; Store in Bit_Access
	; Set commutation to BpFET on
	call	comm5comm6			
	; Start adc
	Start_Adc 
	; Wait for ADC reference to settle, and then start again
	call	wait1ms
	Start_Adc
	; Wait for ADC conversion to complete
measure_lipo_wait_adc:
	Get_Adc_Status 
	jb	AD0BUSY, measure_lipo_wait_adc
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
	jz	measure_lipo_exit		; Exit if disabled

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
ENDIF
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
	mov	A, Temp2					; Move ADC MSB to Temp3
	mov	Temp3, A
	mov	Temp2, #Pgm_Enable_Temp_Prot	; Is temp protection enabled?
	mov	A, @Temp2
	jz	temp_check_exit			; No - branch

	mov	A, Temp3					; Is temperature reading below 256?
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
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #192			; No - limit pwm

	clr	C
	subb	A, #TEMP_LIMIT_STEP			; Is temperature below second limit
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #128			; No - limit pwm

	clr	C
	subb	A, #TEMP_LIMIT_STEP			; Is temperature below third limit
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #64				; No - limit pwm

	clr	C
	subb	A, #TEMP_LIMIT_STEP			; Is temperature below final limit
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #0				; No - limit pwm

temp_check_exit:
	Set_Adc_Ip_Volt				; Select adc input for next conversion
	ret

check_voltage_start:
IF MODE == 0	; Main 
	; Check if low voltage limiting is enabled
	mov	A, Temp8
	clr	C
	subb	A, #1					; Is low voltage limit disabled?
	jz	check_voltage_good			; Yes - voltage declared good

	mov	A, #ADC_LIMIT_L			; Is low voltage limit zero (ESC does not support it)?
	jz	check_voltage_good			; Yes - voltage declared good

	; Check if ADC is saturated
	clr	C
	mov	A, Temp1
	subb	A, #0FFh
	mov	A, Temp2
	subb	A, #03h
	jnc	check_voltage_good			; ADC saturated, can not make judgement

	; Check voltage against limit
	clr	C
	mov	A, Temp1
	subb	A, Lipo_Adc_Limit_L
	mov	A, Temp2
	subb	A, Lipo_Adc_Limit_H
	jnc	check_voltage_good			; If voltage above limit - branch

	; Decrease pwm limit
	mov  A, Pwm_Limit
	jz	check_voltage_lim			; If limit zero - branch

	dec	Pwm_Limit					; Decrement limit
	jmp	check_voltage_lim

check_voltage_good:
	; Increase pwm limit
	mov  A, Pwm_Limit
	cpl	A			
	jz	check_voltage_lim			; If limit max - branch

	inc	Pwm_Limit					; Increment limit

check_voltage_lim:
	mov	Temp1, Pwm_Limit			; Set limit
	clr	C
	mov	A, Current_Pwm
	subb	A, Temp1
	jnc	check_voltage_spoolup_lim	; If current pwm above limit - branch and limit	

	mov	Temp1, Current_Pwm			; Set current pwm (no limiting)

check_voltage_spoolup_lim:
	; Slow spoolup
	clr	C
	mov	A, Temp1
	subb	A, Pwm_Limit_Spoolup
	jc	check_voltage_exit			; If current pwm below limit - branch	

	mov	Temp1, Pwm_Limit_Spoolup
	mov	A, Pwm_Limit_Spoolup		; Check if spoolup limit is max
	cpl	A
	jz	check_voltage_exit			; If max - branch
 
	mov	Pwm_Limit, Pwm_Limit_Spoolup	; Set pwm limit to spoolup limit during ramp (to avoid governor integral buildup)

check_voltage_exit:
	mov  Current_Pwm_Limited, Temp1
	mov	Current_Pwm_Lim_Dith, Temp1
ENDIF
IF MODE == 1	; Tail
	; Increase pwm limit
	mov  A, Pwm_Limit
	cpl	A			
	jz	check_voltage_lim			; If limit max - branch

	inc	Pwm_Limit					; Increment limit

check_voltage_lim:
ENDIF
IF MODE == 2	; Multi
	; Set current pwm limited if closed loop mode
	mov	Temp2, #Pgm_Gov_Mode			; Governor mode?
	cjne	@Temp2, #4, check_voltage_set_pwm_gov	; Yes - branch

	mov  A, Pwm_Limit
	add	A, #16			
	jnc	($+4)					; If not max - branch

	mov	A, #255

	mov	Pwm_Limit, A				; Increment limit 
	ajmp	check_voltage_pwm_done

check_voltage_set_pwm_gov:
	; Limit pwm for low rpms
	clr	C
	mov	A, Temp1					; Check against limit
	subb	A, Pwm_Limit_Low_Rpm
	jc	($+4)					; If current pwm below limit - branch

	mov	Temp1, Pwm_Limit_Low_Rpm		; Limit pwm

	mov  Current_Pwm_Limited, Temp1
	mov	Current_Pwm_Lim_Dith, Temp1
check_voltage_pwm_done:
ENDIF
	; Set adc mux for next conversion
	mov	A, Adc_Conversion_Cnt		; Is next conversion for temperature?
	cjne	A, #(TEMP_CHECK_RATE-1), check_voltage_ret

	Set_Adc_Ip_Temp				; Select temp sensor for next conversion

check_voltage_ret:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Set startup PWM routine
;
; Either the SETTLE_PHASE or the STEPPER_PHASE flag must be set
;
; Used for pwm control during startup
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
set_startup_pwm:	
	; Adjust startup power
	mov	A, #PWM_START					; Set power
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
	mov	Current_Pwm_Lim_Dith, Temp1
	mov	Pwm_Spoolup_Beg, Temp1			; Yes - update spoolup beginning pwm (will use PWM_SETTLE or PWM_SETTLE/2)			
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Initialize timing routine
;
; No assumptions
;
; Part of initialization before motor start
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
initialize_timing: 
	mov	Comm_Period4x_L, #00h				; Set commutation period registers
	mov	Comm_Period4x_H, #0F0h
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Calculate next commutation timing routine
;
; No assumptions
;
; Called immediately after each commutation
; Also sets up timer 3 to wait advance timing
; Two entry points are used
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
calc_next_comm_timing:		; Entry point for run phase
	; Read commutation time
	mov	TMR2CN, #20h		; Timer2 disabled
	mov	Temp1, TMR2L		; Load timer value
	mov	Temp2, TMR2H	
	mov	TMR2CN, #24h		; Timer2 enabled
IF MCU_48MHZ == 1
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
ENDIF
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
IF MCU_48MHZ == 1
	anl	A, #7Fh
ENDIF
	mov	Temp2, A
	jnb	Flags1.STARTUP_PHASE, calc_next_comm_startup_done	

	mov	Temp5, Prev_Prev_Comm_L
	mov	Temp6, Prev_Prev_Comm_H
	mov	Prev_Prev_Comm_L, Temp3
	mov	Prev_Prev_Comm_H, Temp4
	clr	C
	mov	A, Temp4
	subb	A, Temp6				; Calculate previous commutation time (hi byte only)
IF MCU_48MHZ == 1
	anl	A, #7Fh
ENDIF
	mov	Temp4, A
	clr	C
	mov	A, Temp2
	subb	A, Temp4				; Calculate the difference between the two previous commutation times (hi bytes only)
	mov	Comm_Diff, A
	mov	Temp1, Prev_Comm_L		; Reload this commutation time	
	mov	Temp2, Prev_Comm_H
	clr	C
	mov	A, Temp1
	subb	A, Temp5				; Calculate the new commutation time based upon the two last commutations (to reduce sensitivity to offset)
	mov	Temp1, A
	mov	A, Temp2
	subb	A, Temp6
IF MCU_48MHZ == 1
	anl	A, #7Fh
ENDIF
	mov	Temp2, A

	clr	C
	mov	A, Comm_Period4x_H		; Average with previous and save
	rrc	A
	mov	Temp4, A
	mov	A, Comm_Period4x_L
	rrc	A
	mov	Temp3, A
	mov	A, Temp1			
	add	A, Temp3
	mov	Comm_Period4x_L, A
	mov	A, Temp2
	addc	A, Temp4
	mov	Comm_Period4x_H, A
	ajmp	calc_new_wait_times_setup

calc_next_comm_startup_done:
	; Calculate new commutation time 
	mov	Temp3, Comm_Period4x_L	; Comm_Period4x(-l-h) holds the time of 4 commutations
	mov	Temp4, Comm_Period4x_H
	mov	Temp5, Comm_Period4x_L	; Copy variables
	mov	Temp6, Comm_Period4x_H
	mov	Temp7, #4				; Divide Comm_Period4x 4 times as default
	mov	Temp8, #2				; Divide new commutation time 2 times as default
	clr	C
	mov	A, Temp4
	subb	A, #04h
	jc	($+4)

	dec	Temp7				; Reduce averaging time constant for low speeds
	dec	Temp8

	clr	C
	mov	A, Temp4
	subb	A, #08h
	jc	($+4)

	dec	Temp7				; Reduce averaging time constant more for even lower speeds
	dec	Temp8

calc_next_comm_avg_period_div:
	clr	C
	mov	A, Temp6					
	rrc	A					; Divide by 2
	mov	Temp6, A	
	mov	A, Temp5				
	rrc	A
	mov	Temp5, A
	djnz	Temp7, calc_next_comm_avg_period_div

	clr	C
	mov	A, Temp3
	subb	A, Temp5				; Subtract a fraction
	mov	Temp3, A
	mov	A, Temp4
	subb	A, Temp6
	mov	Temp4, A
	mov	A, Temp8				; Divide new time
	jz	calc_next_comm_new_period_div_done

calc_next_comm_new_period_div:
	clr	C
	mov	A, Temp2					
	rrc	A					; Divide by 2
	mov	Temp2, A	
	mov	A, Temp1				
	rrc	A
	mov	Temp1, A
	djnz	Temp8, calc_next_comm_new_period_div

calc_next_comm_new_period_div_done:
	mov	A, Temp3
	add	A, Temp1				; Add the divided new time
	mov	Temp3, A
	mov	A, Temp4
	addc	A, Temp2
	mov	Temp4, A
	mov	Comm_Period4x_L, Temp3	; Store Comm_Period4x_X
	mov	Comm_Period4x_H, Temp4
	jnc	calc_new_wait_times_setup; If period larger than 0xffff - go to slow case

	mov	Comm_Period4x_L, #0FFh	; Set commutation period registers to very slow timing (0xffff)
	mov	Comm_Period4x_H, #0FFh

calc_new_wait_times_setup:	
	; Load programmed commutation timing
	jnb	Flags1.STARTUP_PHASE, calc_new_wait_per_startup_done	; Set dedicated timing during startup

	mov	Temp8, #3
	ajmp	calc_new_wait_per_demag_done

calc_new_wait_per_startup_done:
	mov	Temp1, #Pgm_Comm_Timing	; Load timing setting
	mov	A, @Temp1				
	mov	Temp8, A				; Store in Temp8
	clr	C
	mov	A, Demag_Detected_Metric	; Check demag metric
	subb	A, #130
	jc	calc_new_wait_per_demag_done

	inc	Temp8				; Increase timing

	clr	C
	mov	A, Demag_Detected_Metric
	subb	A, #160
	jc	($+3)

	inc	Temp8				; Increase timing again

	clr	C
	mov	A, Temp8				; Limit timing to max
	subb	A, #6
	jc	($+4)

	mov	Temp8, #5				; Set timing to max

calc_new_wait_per_demag_done:
	mov	Temp7, #(COMM_TIME_RED SHL 1)
	jnb	Flags2.PGM_PWMOFF_DAMPED, ($+4)	; More reduction for damped

	inc	Temp7				; Increase more

	clr	C
	mov	A, Comm_Period4x_H		; More reduction for higher rpms
	subb	A, #3				; 104k eRPM
	jnc	calc_new_wait_per_low

	inc	Temp7				; Increase
	inc	Temp7

	jnb	Flags2.PGM_PWMOFF_DAMPED, calc_new_wait_per_low	; More reduction for damped

	inc	Temp7				; Increase more

calc_new_wait_per_low:
	clr	C
	mov	A, Comm_Period4x_H		; More reduction for higher rpms
	subb	A, #2				; 156k eRPM
	jnc	calc_new_wait_per_high

	inc	Temp7				; Increase more
	inc	Temp7

	jnb	Flags2.PGM_PWMOFF_DAMPED, calc_new_wait_per_high	; More reduction for damped

	inc	Temp7				; Increase more

calc_new_wait_per_high:
	; Load current commutation timing
	mov	A, Comm_Period4x_H		; Divide 4 times
	swap	A
	anl	A, #00Fh
	mov	Temp2, A
	mov	A, Comm_Period4x_H
	swap	A
	anl	A, #0F0h
	mov	Temp1, A
	mov	A, Comm_Period4x_L
	swap	A
	anl	A, #00Fh
	add	A, Temp1
	mov	Temp1, A

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
	jnc	calc_new_wait_times_exit	; Check that result is still above minumum

load_min_time:
	mov	Temp1, #(COMM_TIME_MIN SHL 1)
	clr	A
	mov	Temp2, A

calc_new_wait_times_exit:	
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait advance timing routine
;
; No assumptions
; NOTE: Be VERY careful if using temp registers. They are passed over this routine
;
; Waits for the advance timing to elapse and sets up the next zero cross wait
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait_advance_timing:	
	jnb	Flags0.T3_PENDING, ($+5)
	ajmp	wait_advance_timing

	; Setup next wait time
	mov	Next_Wt_L, Wt_ZC_Timeout_L
	mov	Next_Wt_H, Wt_ZC_Timeout_H
	setb	Flags0.T3_PENDING
	orl	EIE1, #80h	; Enable timer3 interrupts
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
	mov	Wt_Zc_Timeout_L, Temp1	; Set 15deg time for zero cross scan timeout
	mov	Wt_Zc_Timeout_H, Temp2
	clr	C
	mov	A, Temp8				; (Temp8 has Pgm_Comm_Timing)
	subb	A, #3				; Is timing normal?
	jz	store_times_decrease	; Yes - branch

	mov	A, Temp8				
	jb	ACC.0, adjust_timing_two_steps	; If an odd number - branch

	mov	A, Temp1				; Add 7.5deg and store in Temp1/2
	add	A, Temp5
	mov	Temp1, A
	mov	A, Temp2
	addc	A, Temp6
	mov	Temp2, A
	mov	A, Temp5				; Store 7.5deg in Temp3/4
	mov	Temp3, A
	mov	A, Temp6			
	mov	Temp4, A
	jmp	store_times_up_or_down

adjust_timing_two_steps:
	mov	A, Temp1				; Add 15deg and store in Temp1/2
	add	A, Temp1
	mov	Temp1, A
	mov	A, Temp2
	addc	A, Temp2
	mov	Temp2, A
	clr	C
	mov	A, Temp1
	subb	A, #(COMM_TIME_MIN SHL 1)
	mov	Temp1, A
	mov	A, Temp2
	subb	A, #0
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
	mov	Wt_Comm_L, Temp3		; Now commutation time (~60deg) divided by 4 (~15deg nominal)
	mov	Wt_Comm_H, Temp4
	mov	Wt_Advance_L, Temp1		; New commutation advance time (~15deg nominal)
	mov	Wt_Advance_H, Temp2
	mov	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5deg)
	mov	Wt_Zc_Scan_H, Temp6
	ret

store_times_decrease:
	mov	Wt_Comm_L, Temp1		; Now commutation time (~60deg) divided by 4 (~15deg nominal)
	mov	Wt_Comm_H, Temp2
	mov	Wt_Advance_L, Temp3		; New commutation advance time (~15deg nominal)
	mov	Wt_Advance_H, Temp4
	mov	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5deg)
	mov	Wt_Zc_Scan_H, Temp6
	jnb	Flags1.STARTUP_PHASE, store_times_exit

	clr	C
	mov	A, Startup_Cnt			
	subb	A, #3
	jc	store_times_exit

	mov	A, Comm_Diff			; Compensate commutation wait for comparator offset
	rlc	A
	mov	A, Comm_Diff
	rrc	A
	add	A, Wt_Comm_H
	jc	store_times_exit
	jb	ACC.7, store_times_exit

	mov	Wt_Comm_L, #0
	mov	Wt_Comm_H, A 

store_times_exit:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait before zero cross scan routine
;
; No assumptions
;
; Waits for the zero cross scan wait time to elapse
; Also sets up timer 3 for the zero cross scan timeout time
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait_before_zc_scan:	
	; Calculate random number
	mov	A, Random
	clr	C
	rlc	A
	jnc	wait_before_zc_scan_rand

	xrl	A, #06Bh		; Sequence length of 35, when initialized to 1

wait_before_zc_scan_rand:          
	mov	Random, A

wait_before_zc_scan_wait:          
	jnb	Flags0.T3_PENDING, ($+5)
	ajmp	wait_before_zc_scan_wait

	setb	Flags0.T3_PENDING
	orl	EIE1, #80h			; Enable timer3 interrupts
	mov	A, Flags1
	anl	A, #((1 SHL STARTUP_PHASE)+(1 SHL INITIAL_RUN_PHASE))
	jz	wait_before_zc_scan_exit		

	mov	Temp1, Comm_Period4x_L	; Set long timeout when starting
	mov	Temp2, Comm_Period4x_H
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A

IF MCU_48MHZ == 1
	clr	C
	mov	A, Temp1
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A
ENDIF
	anl	EIE1, #7Fh			; Disable timer3 interrupts
	mov	TMR3CN, #00h			; Timer3 disabled and interrupt flag cleared
	clr	C
	clr	A
	subb	A, Temp1				; Set timeout
	mov	TMR3L, A
	clr	A
	subb	A, Temp2		
	mov	TMR3H, A
	mov	TMR3CN, #04h			; Timer3 enabled and interrupt flag cleared

	setb	Flags0.T3_PENDING
	orl	EIE1, #80h			; Enable timer3 interrupts

wait_before_zc_scan_exit:          
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
	setb	Flags0.DEMAG_DETECTED		; Set demag detected flag as default
	mov	Comparator_Read_Cnt, #0		; Reset number of comparator reads
	mov	Bit_Access, #00h			; Desired comparator output
	jmp	wait_for_comp_out_start

wait_for_comp_out_high:
	setb	Flags0.DEMAG_DETECTED		; Set demag detected flag as default
	mov	Comparator_Read_Cnt, #0		; Reset number of comparator reads
	mov	Bit_Access, #40h			; Desired comparator output

wait_for_comp_out_start:
	jnb	Flags1.DIR_CHANGE_BRAKE, wait_for_comp_brake_done	; Is it a direction change?

	ApFET_off						; Switch off one fet, so that comparator can be used

wait_for_comp_brake_done:
	mov	A, Flags1					; Clear demag detected flag if start phases
	anl	A, #((1 SHL STARTUP_PHASE)+(1 SHL INITIAL_RUN_PHASE))
	jz	($+4)
		
	clr	Flags0.DEMAG_DETECTED

	setb	EA						; Enable interrupts
	; Set number of comparator readings
	mov	Temp1, #1					; Number of OK readings required
	clr	C						; Set number of readings higher for lower speeds
	mov 	A, Comm_Period4x_H			
	subb	A, #05h
	jc	comp_wait_on_comp_able

	mov	Temp1, #2

	subb	A, #05h
	jc	comp_wait_no_of_readings

	mov	Temp1, #3

	subb	A, #05h					; Set number of consecutive readings higher for lower speeds
	jc	comp_wait_no_of_readings

	mov	Temp1, #6

comp_wait_no_of_readings:
	jnb	Flags1.STARTUP_PHASE, ($+5)		; Set many samples during startup
	mov	Temp1, #10

comp_wait_on_comp_able:
	jb	Flags0.T3_PENDING, comp_wait_on_comp_able_not_timed_out	; Has zero cross scan timeout elapsed?

	mov	A, Comparator_Read_Cnt			; Check that comparator has been read
	jz	comp_wait_on_comp_able_not_timed_out	; If not read - branch

	setb	EA							; Enable interrupts
	setb	Flags1.COMP_TIMED_OUT
	ret								; Yes - return


comp_wait_on_comp_able_not_timed_out:
	setb	EA							; Enable interrupts
	nop								; Allocate only just enough time to capture interrupt
	nop
	clr	EA							; Disable interrupts
	mov	A, Comm_Period4x_H				; Reduce required distance to pwm transition for higher speeds
	clr	C
	mov	Temp4, A
	subb	A, #0Fh
	jc	($+4)

	mov	Temp4, #0Fh

	mov	A, Temp4
	add	A, #5
	jnb	Flags2.PGM_PWM_HIGH_FREQ, ($+4)	; More delay for high pwm frequency

	rl	A

	jb	Flags0.PWM_ON, ($+4)			; More delay for pwm off

	rl	A

	mov	Temp2, A
	jnb	Flags1.STARTUP_PHASE, ($+5)		; Set a long delay from pwm on/off events during startup
	mov	Temp2, #130
	jnb	Flags1.INITIAL_RUN_PHASE, ($+5)		
	mov	Temp2, #65

IF MCU_48MHZ == 0
	mov	A, TL1
ELSE
	mov	A, TH1
	rrc	A
	mov	A, TL1
	rrc	A
ENDIF
	clr	C
	subb	A, Temp2
	jc	comp_wait_on_comp_able		; Re-evaluate pwm cycle

	inc	Comparator_Read_Cnt			; Increment comparator read count
	Read_Comp_Out					; Read comparator output
	anl	A, #40h
	cjne	A, Bit_Access, comp_read_wrong
	ajmp	comp_read_ok
	
comp_read_wrong:
	jnb	Flags1.STARTUP_PHASE, comp_read_wrong_not_startup

	inc	Temp1					; Increment number of OK readings required
	clr	C
	mov	A, Temp1
	subb	A, #10					; If above initial requirement - go back and restart
	jc	($+4)
	ajmp	wait_for_comp_out_start

	clr	C
	mov	A, Startup_Cnt				; For the first commutations - go back and restart
	subb	A, #6
	jnc	($+4)
	ajmp	wait_for_comp_out_start

	ajmp	comp_wait_on_comp_able		; If below initial requirement - continue to look for good ones

comp_read_wrong_not_startup:
	jb	Flags0.DEMAG_DETECTED, ($+5)	
	ajmp	wait_for_comp_out_start		; If comparator output is not correct, and timeout already extended - go back and restart

	clr	Flags0.DEMAG_DETECTED		; Clear demag detected flag
	anl	EIE1, #7Fh				; Disable timer3 interrupts
	mov	TMR3CN, #00h				; Timer3 disabled and interrupt flag cleared
	mov	Temp7, Comm_Period4x_L		; Set timeout to comm period 4x value
	mov	Temp8, Comm_Period4x_H
IF MCU_48MHZ == 1
	clr	C
	mov	A, Temp7
	rlc	A
	mov	Temp7, A
	mov	A, Temp8
	rlc	A
	mov	Temp8, A
ENDIF
	clr	C
	clr	A
	subb	A, Temp7		
	mov	TMR3L, A
	clr	A
	subb	A, Temp8		
	mov	TMR3H, A
	mov	TMR3CN, #04h				; Timer3 enabled and interrupt flag cleared
	setb	Flags0.T3_PENDING
	orl	EIE1, #80h				; Enable timer3 interrupts
	ajmp	wait_for_comp_out_start		; If comparator output is not correct - go back and restart

comp_read_ok:
	clr	C
	mov	A, Startup_Cnt				; Force a timeout for the first commutations			
	subb	A, #2
	jnc	($+4)
	ajmp	wait_for_comp_out_start

	jnb	Flags0.DEMAG_DETECTED, ($+5)	; Do not accept correct comparator output if it is demag	
	ajmp	wait_for_comp_out_start

	djnz	Temp1, comp_read_ok_jmp		; Decrement readings counter - repeat comparator reading if not zero
	ajmp	($+4)

comp_read_ok_jmp:
	ajmp	comp_wait_on_comp_able	

	clr	Flags1.COMP_TIMED_OUT
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
	jnb	Flags1.DIR_CHANGE_BRAKE, eval_comp_brake_done	; Is it a direction change?

	All_pFETs_off						; Turn off braking fets
IF NFETON_DELAY NE 0
	mov	A, #NFETON_DELAY				
	djnz ACC,	$
ENDIF
	AnFET_on							; Turn on nfets (for high side driver charging)
	BnFET_on
	CnFET_on
	mov	A, #20				
	djnz ACC,	$
	All_nFETs_off						; Turn off nfets again
IF PFETON_DELAY < 128
IF PFETON_DELAY NE 0
	mov	A, #PFETON_DELAY				
	djnz ACC,	$
ENDIF
ENDIF
	All_pFETs_on						; Turn on braking

eval_comp_brake_done:
	mov	A, Flags1
	anl	A, #((1 SHL STARTUP_PHASE)+(1 SHL INITIAL_RUN_PHASE))
	jz	eval_comp_check_timeout

	jb	Flags1.INITIAL_RUN_PHASE, ($+5)	; Do not increment beyond startup phase
	inc	Startup_Cnt					; Increment counter
	jmp	eval_comp_exit

eval_comp_check_timeout:
	jnb	Flags1.COMP_TIMED_OUT, eval_comp_exit	; Has timeout elapsed?
	jb	Flags0.DEMAG_DETECTED, eval_comp_exit	; Do not exit run mode if it is a demag situation
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
	mov	Temp1, Wt_Comm_L	; Set wait commutation value
	mov	Temp2, Wt_Comm_H
IF MCU_48MHZ == 1
	clr	C
	mov	A, Temp1
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A
ENDIF
	anl	EIE1, #7Fh		; Disable timer3 interrupts
	mov	TMR3CN, #00h		; Timer3 disabled and interrupt flag cleared
	clr	C
	clr	A
	subb	A, Temp1		
	mov	TMR3L, A
	clr	A
	subb	A, Temp2		
	mov	TMR3H, A
	mov	TMR3CN, #04h		; Timer3 enabled and interrupt flag cleared
	; Setup next wait time
	mov	Next_Wt_L, Wt_Advance_L
	mov	Next_Wt_H, Wt_Advance_H
	setb	Flags0.T3_PENDING
	orl	EIE1, #80h		; Enable timer3 interrupts
	setb	EA				; Enable interrupts again
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
	; Update demag metric
	mov	Temp1, #0
	jnb	Flags0.DEMAG_ENABLED, ($+8); If demag disabled - branch
	jnb	Flags0.DEMAG_DETECTED, ($+5)

	mov	Temp1, #1

	mov	A, Demag_Detected_Metric	; Sliding average of 8, 256 when demag and 0 when not. Limited to minimum 120
	mov	B, #7
	mul	AB					; Multiply by 7
	mov	Temp2, A
	mov	A, B					; Add new value for current demag status
	add	A, Temp1				
	mov	B, A
	mov	A, Temp2
	mov	C, B.0				; Divide by 8
	rrc	A					
	mov	C, B.1
	rrc	A
	mov	C, B.2
	rrc	A
	mov	Demag_Detected_Metric, A
	clr	C
	subb	A, #120				; Limit to minimum 120
	jnc	($+5)

	mov	Demag_Detected_Metric, #120

	clr	C
	mov	A, Demag_Detected_Metric	; Check demag metric
	subb	A, Demag_Pwr_Off_Thresh
	jc	wait_for_comm_wait		; Cut power if many consecutive demags. This will help retain sync during hard accelerations

	setb	Flags0.DEMAG_CUT_POWER	; Set demag power cut flag
	All_nFETs_off

wait_for_comm_wait:
	jnb Flags0.T3_PENDING, ($+5)			
	ajmp	wait_for_comm_wait					

	; Setup next wait time
	mov	Next_Wt_L, Wt_Zc_Scan_L
	mov	Next_Wt_H, Wt_Zc_Scan_H
	setb	Flags0.T3_PENDING
	orl	EIE1, #80h			; Enable timer3 interrupts
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
; Comm phase 1 to comm phase 2
comm1comm2:	
	jb	Flags1.DIR_CHANGE_BRAKE, comm_12_brake	; Is it a direction change?
	Set_RPM_Out
	jb	Flags3.PGM_DIR_REV, comm12_rev

	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #2
	BpFET_off 				; Turn off pfet
	ApFET_on					; Turn on pfet
	setb	EA
	Set_Comp_Phase_B 			; Set comparator phase
	jmp	comm_exit

comm12_rev:	
	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #2
	BpFET_off 				; Turn off pfet
	CpFET_on					; Turn on pfet (reverse)
	setb	EA
	Set_Comp_Phase_B 			; Set comparator phase
	jmp	comm_exit

comm_12_brake:
	Set_Comp_Phase_A 			; Set comparator phase to A
	jmp	comm_exit


; Comm phase 2 to comm phase 3
comm2comm3:	
	jb	Flags1.DIR_CHANGE_BRAKE, comm_12_brake	; Is it a direction change?
	Clear_RPM_Out
	jnb	Flags2.PGM_PWMOFF_DAMPED, comm23_nondamp

	; Comm2Comm3 Damped
	jb	Flags3.PGM_DIR_REV, comm23_damp_rev

	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #3
	mov	DPTR, #pwm_bfet_damped	
	mov	DampingFET, #(1 SHL BpFET)
	CnFET_off					; Turn off fets
	CpFET_off						
	jnb	Flags0.PWM_ON, comm23_nfet_off	; Is pwm on?
	BnFET_on					; Pwm on - turn on nfet
	ajmp	comm23_fets_done
comm23_nfet_off:
	BpFET_on					; Pwm off - switch damping fets	
comm23_fets_done:
	setb	EA
	Set_Comp_Phase_C 			; Set comparator phase
	ajmp	comm_exit

	; Comm2Comm3 Damped reverse
comm23_damp_rev:
	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #3
	mov	DPTR, #pwm_bfet_damped	
	mov	DampingFET, #(1 SHL BpFET)
	AnFET_off					; Turn off fets (reverse)
	ApFET_off						
	jnb	Flags0.PWM_ON, comm23_nfet_off_rev	; Is pwm on?
	BnFET_on					; Pwm on - turn on nfet
	ajmp	comm23_fets_done_rev
comm23_nfet_off_rev:
	BpFET_on					; Pwm off - switch damping fets	
comm23_fets_done_rev:
	setb	EA
	Set_Comp_Phase_A 			; Set comparator phase (reverse)
	ajmp	comm_exit

	; Comm2Comm3 Non-damped
comm23_nondamp:
	jb	Flags3.PGM_DIR_REV, comm23_nondamp_rev

	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #3
	mov	DPTR, #pwm_bfet	
	CnFET_off					; Turn off nfet
	jnb	Flags0.PWM_ON, comm23_nfet_done	; Is pwm on?
	BnFET_on					; Yes - turn on nfet
comm23_nfet_done:
	setb	EA
	Set_Comp_Phase_C 			; Set comparator phase
	ajmp	comm_exit

	; Comm2Comm3 Non-damped reverse
comm23_nondamp_rev:
	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #3
	mov	DPTR, #pwm_bfet	
	AnFET_off					; Turn off nfet (reverse)
	jnb	Flags0.PWM_ON, comm23_nfet_done_rev	; Is pwm on?
	BnFET_on					; Yes - turn on nfet
comm23_nfet_done_rev:
	setb	EA
	Set_Comp_Phase_A 			; Set comparator phase (reverse)
	ajmp	comm_exit


; Comm phase 3 to comm phase 4
comm3comm4:	
	jb	Flags1.DIR_CHANGE_BRAKE, comm_34_brake	; Is it a direction change?
	Set_RPM_Out
	jb	Flags3.PGM_DIR_REV, comm34_rev

	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #4
	ApFET_off 				; Turn off pfet
	CpFET_on					; Turn on pfet
	setb	EA
	Set_Comp_Phase_A 			; Set comparator phase
	jmp	comm_exit

comm34_rev:	
	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #4
	CpFET_off 				; Turn off pfet (reverse)
	ApFET_on					; Turn on pfet (reverse)
	setb	EA
	Set_Comp_Phase_C 			; Set comparator phase (reverse)
	jmp	comm_exit

comm_34_brake:
	Set_Comp_Phase_A 			; Set comparator phase to A
	jmp	comm_exit


; Comm phase 4 to comm phase 5
comm4comm5:	
	jb	Flags1.DIR_CHANGE_BRAKE, comm_34_brake	; Is it a direction change?
	Clear_RPM_Out
	jnb	Flags2.PGM_PWMOFF_DAMPED, comm45_nondamp

	; Comm4Comm5 Damped
	jb	Flags3.PGM_DIR_REV, comm45_damp_rev

	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #5
	mov	DPTR, #pwm_afet_damped	
	mov	DampingFET, #(1 SHL ApFET)
	BnFET_off					; Turn off fets
	BpFET_off						
	jnb	Flags0.PWM_ON, comm45_nfet_off	; Is pwm on?
	AnFET_on					; Pwm on - turn on nfet
	ajmp	comm45_fets_done
comm45_nfet_off:
	ApFET_on					; Pwm off - switch damping fets	
comm45_fets_done:
	setb	EA
	Set_Comp_Phase_B 			; Set comparator phase
	ajmp	comm_exit

	; Comm4Comm5 Damped reverse
comm45_damp_rev:
	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #5
	mov	DPTR, #pwm_cfet_damped	; (reverse)
	mov	DampingFET, #(1 SHL CpFET)	; (reverse)
	BnFET_off					; Turn off fets
	BpFET_off						
	jnb	Flags0.PWM_ON, comm45_nfet_off_rev	; Is pwm on?
	CnFET_on					; Pwm on - turn on nfet (reverse)
	ajmp	comm45_fets_done_rev
comm45_nfet_off_rev:
	CpFET_on					; Pwm off - switch damping fets (reverse)	
comm45_fets_done_rev:
	setb	EA
	Set_Comp_Phase_B 			; Set comparator phase
	ajmp	comm_exit

	; Comm4Comm5 Non-damped
comm45_nondamp:
	jb	Flags3.PGM_DIR_REV, comm45_nondamp_rev

	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #5
	mov	DPTR, #pwm_afet	
	BnFET_off					; Turn off nfet
	jnb	Flags0.PWM_ON, comm45_nfet_done	; Is pwm on?
	AnFET_on					; Yes - turn on nfet
comm45_nfet_done:
	setb	EA
	Set_Comp_Phase_B 			; Set comparator phase
	ajmp	comm_exit

	; Comm4Comm5 Non-damped reverse
comm45_nondamp_rev:
	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #5
	mov	DPTR, #pwm_cfet		;  (reverse)
	BnFET_off					; Turn off nfet
	jnb	Flags0.PWM_ON, comm45_nfet_done	; Is pwm on?
	CnFET_on					; Yes - turn on nfet (reverse)
	setb	EA
	Set_Comp_Phase_B 			; Set comparator phase
	ajmp	comm_exit


; Comm phase 5 to comm phase 6
comm5comm6:	
	jb	Flags1.DIR_CHANGE_BRAKE, comm_56_brake	; Is it a direction change?
	Set_RPM_Out
	jb	Flags3.PGM_DIR_REV, comm56_rev

	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #6
	CpFET_off 				; Turn off pfet
	BpFET_on					; Turn on pfet
	setb	EA
	Set_Comp_Phase_C 			; Set comparator phase
	jmp	comm_exit

comm56_rev:
	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #6
	ApFET_off 				; Turn off pfet (reverse)
	BpFET_on					; Turn on pfet
	setb	EA
	Set_Comp_Phase_A 			; Set comparator phase (reverse)
	jmp	comm_exit

comm_56_brake:
	Set_Comp_Phase_A 			; Set comparator phase to A
	jmp	comm_exit


; Comm phase 6 to comm phase 1
comm6comm1:	
	jb	Flags1.DIR_CHANGE_BRAKE, comm_56_brake	; Is it a direction change?
	Clear_RPM_Out
	jnb	Flags2.PGM_PWMOFF_DAMPED, comm61_nondamp

	; Comm6Comm1 Damped
	jb	Flags3.PGM_DIR_REV, comm61_damp_rev

	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #1
	mov	DPTR, #pwm_cfet_damped	
	mov	DampingFET, #(1 SHL CpFET)
	AnFET_off					; Turn off fets
	ApFET_off						
	jnb	Flags0.PWM_ON, comm61_nfet_off	; Is pwm on?
	CnFET_on					; Pwm on - turn on nfet
	ajmp	comm61_fets_done
comm61_nfet_off:
	CpFET_on					; Pwm off - switch damping fets	
comm61_fets_done:
	setb	EA
	Set_Comp_Phase_A 			; Set comparator phase
	ajmp	comm_exit

	; Comm6Comm1 Damped reverse
comm61_damp_rev:
	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #1
	mov	DPTR, #pwm_afet_damped	; (reverse)	
	mov	DampingFET, #(1 SHL ApFET)	; (reverse)
	CnFET_off					; Turn off fets (reverse)
	CpFET_off						
	jnb	Flags0.PWM_ON, comm61_nfet_off_rev	; Is pwm on?
	AnFET_on					; Pwm on - turn on nfet
	ajmp	comm61_fets_done_rev
comm61_nfet_off_rev:
	ApFET_on					; Pwm off - switch damping fets (reverse)	
comm61_fets_done_rev:
	setb	EA
	Set_Comp_Phase_C 			; Set comparator phase (reverse)
	ajmp	comm_exit

	; Comm6Comm1 Non-damped
comm61_nondamp:
	jb	Flags3.PGM_DIR_REV, comm61_nondamp_rev

	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #1
	mov	DPTR, #pwm_cfet	
	AnFET_off					; Turn off nfet
	jnb	Flags0.PWM_ON, comm61_nfet_done	; Is pwm on?
	CnFET_on					; Yes - turn on nfet
comm61_nfet_done:
	setb	EA
	Set_Comp_Phase_A 			; Set comparator phase
	ajmp	comm_exit

	; Comm6Comm1 Non-damped reverse
comm61_nondamp_rev:
	clr 	EA					; Disable all interrupts
	mov	Comm_Phase, #1
	mov	DPTR, #pwm_afet		; (reverse)
	CnFET_off					; Turn off nfet (reverse)
	jnb	Flags0.PWM_ON, comm61_nfet_done_rev	; Is pwm on?
	AnFET_on					; Yes - turn on nfet (reverse)
comm61_nfet_done_rev:
	setb	EA
	Set_Comp_Phase_C 			; Set comparator phase (reverse)

comm_exit:
	clr	Flags0.DEMAG_CUT_POWER	; Clear demag power cut flag
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
	mov	DPTR, #pwm_nofet	; Set DPTR register to pwm_nofet		
	mov	DampingFET, #0
	All_nFETs_Off			; Turn off all nfets
	All_pFETs_Off			; Turn off all pfets
	clr	Flags0.PWM_ON		; Set pwm cycle to pwm off
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
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_I_GAIN
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_GOVERNOR_MODE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM
	inc	Temp1
	mov	@Temp1, #0FFh	; Motor gain
	inc	Temp1
	mov	@Temp1, #0FFh	; Motor idle
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_STARTUP_PWR
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_PWM_FREQ
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_DIRECTION
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_RCP_PWM_POL

	mov	Temp1, #Pgm_Enable_TX_Program
	mov	@Temp1, #DEFAULT_PGM_ENABLE_TX_PROGRAM
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_REARM_START
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_GOV_SETUP_TARGET
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup rpm	
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup accel
	inc	Temp1
	mov	@Temp1, #0FFh	; Voltage comp
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_COMM_TIMING
	inc	Temp1
	mov	@Temp1, #0FFh	; Damping force
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_GOVERNOR_RANGE
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup method	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_PPM_MIN_THROTTLE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_PPM_MAX_THROTTLE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_BEEP_STRENGTH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_BEACON_STRENGTH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_BEACON_DELAY
	inc	Temp1
	mov	@Temp1, #0FFh	; Throttle rate
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_DEMAG_COMP
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_BEC_VOLTAGE_HIGH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_PPM_CENTER_THROTTLE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAIN_SPOOLUP_TIME
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_TEMP_PROT
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_POWER_PROT
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_PWM_INPUT
	inc	Temp1
	mov	@Temp1, #0FFh	; Pwm dither
ENDIF
IF MODE == 1	; Tail
	mov	Temp1, #Pgm_Gov_P_Gain
	mov	@Temp1, #0FFh	
	inc	Temp1
	mov	@Temp1, #0FFh	; Governor I gain
	inc	Temp1
	mov	@Temp1, #0FFh	; Governor mode
	inc	Temp1
	mov	@Temp1, #0FFh	; Low voltage limit
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_GAIN
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_IDLE_SPEED
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_STARTUP_PWR
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_PWM_FREQ
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_DIRECTION
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_RCP_PWM_POL

	mov	Temp1, #Pgm_Enable_TX_Program
	mov	@Temp1, #DEFAULT_PGM_ENABLE_TX_PROGRAM
	inc	Temp1
	mov	@Temp1, #0FFh	; Main rearm start
	inc	Temp1
	mov	@Temp1, #0FFh	; Governor setup target
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup rpm	
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup accel
	inc	Temp1
	mov	@Temp1, #0FFh	; Voltage comp
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_COMM_TIMING
	inc	Temp1
	mov	@Temp1, #0FFh	; Damping force	
	inc	Temp1
	mov	@Temp1, #0FFh	; Governor range
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup method	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_PPM_MIN_THROTTLE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_PPM_MAX_THROTTLE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_BEEP_STRENGTH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_BEACON_STRENGTH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_BEACON_DELAY
	inc	Temp1
	mov	@Temp1, #0FFh	; Throttle rate	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_DEMAG_COMP
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_BEC_VOLTAGE_HIGH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_PPM_CENTER_THROTTLE
	inc	Temp1
	mov	@Temp1, #0FFh	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_TEMP_PROT
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_POWER_PROT
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_PWM_INPUT
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_TAIL_PWM_DITHER
ENDIF
IF MODE == 2	; Multi
	mov	Temp1, #Pgm_Gov_P_Gain
	mov	@Temp1, #DEFAULT_PGM_MULTI_P_GAIN
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_I_GAIN
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_GOVERNOR_MODE
	inc	Temp1
	mov	@Temp1, #0FFh	; Low voltage limit
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_GAIN
	inc	Temp1
	mov	@Temp1, #0FFh	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_STARTUP_PWR
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_PWM_FREQ
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_DIRECTION
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_RCP_PWM_POL

	mov	Temp1, #Pgm_Enable_TX_Program
	mov	@Temp1, #DEFAULT_PGM_ENABLE_TX_PROGRAM
	inc	Temp1
	mov	@Temp1, #0FFh	; Main rearm start
	inc	Temp1
	mov	@Temp1, #0FFh	; Governor setup target
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup rpm	
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup accel
	inc	Temp1
	mov	@Temp1, #0FFh	; Voltage comp
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_COMM_TIMING
	inc	Temp1
	mov	@Temp1, #0FFh	; Damping force	
	inc	Temp1
	mov	@Temp1, #0FFh	; Governor range
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup method	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_PPM_MIN_THROTTLE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_PPM_MAX_THROTTLE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_BEEP_STRENGTH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_BEACON_STRENGTH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_BEACON_DELAY
	inc	Temp1
	mov	@Temp1, #0FFh	; Throttle rate	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_DEMAG_COMP
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_BEC_VOLTAGE_HIGH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_PPM_CENTER_THROTTLE
	inc	Temp1
	mov	@Temp1, #0FFh	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_TEMP_PROT
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_POWER_PROT
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_PWM_INPUT
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MULTI_PWM_DITHER
ENDIF
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
	; Load programmed pwm frequency
	mov	Temp1, #Pgm_Pwm_Freq	; Load pwm freq
	mov	A, @Temp1				
	mov	Temp8, A				; Store in Temp8
	clr	Flags2.PGM_PWMOFF_DAMPED
IF DAMPED_MODE_ENABLE == 1
	cjne	Temp8, #3, ($+5)
	setb	Flags2.PGM_PWMOFF_DAMPED
ENDIF
	; Load programmed direction
	mov	Temp1, #Pgm_Direction	
IF MODE >= 1	; Tail or multi
	mov	A, @Temp1				
	clr	C
	subb	A, #3
	jz	decode_params_dir_set
ENDIF

	clr	Flags3.PGM_DIR_REV
	mov	A, @Temp1				
	jnb	ACC.1, ($+5)
	setb	Flags3.PGM_DIR_REV
decode_params_dir_set:
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
; Decode settings
;
; No assumptions
;
; Decodes various settings
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
decode_settings:
	; Decode governor gains
	mov	Temp1, #Pgm_Gov_P_Gain	; Decode governor P gain	
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #GOV_GAIN_TABLE
	movc A, @A+DPTR	
	mov	Temp1, #Pgm_Gov_P_Gain_Decoded
	mov	@Temp1, A	
	mov	Temp1, #Pgm_Gov_I_Gain	; Decode governor I gain
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #GOV_GAIN_TABLE
	movc A, @A+DPTR	
	mov	Temp1, #Pgm_Gov_I_Gain_Decoded
	mov	@Temp1, A	
	; Decode startup power
	mov	Temp1, #Pgm_Startup_Pwr		
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #STARTUP_POWER_TABLE
	movc A, @A+DPTR	
	mov	Temp1, #Pgm_Startup_Pwr_Decoded
	mov	@Temp1, A	
IF MODE == 0	; Main
	; Decode spoolup time
	mov	Temp1, #Pgm_Main_Spoolup_Time		
	mov	A, @Temp1
	mov	Temp1, A		; Store
	jnz	($+3)		; If not zero - branch
	
	inc	Temp1

	clr	C
	mov	A, Temp1
	subb	A, #17		; Limit to 17 max
	jc	($+4)

	mov	Temp1, #17

	mov	A, Temp1
	add	A, Temp1
	add	A, Temp1		; Now 3x
	mov	Main_Spoolup_Time_3x, A
	add	A, Main_Spoolup_Time_3x
	add	A, Main_Spoolup_Time_3x
	add	A, Temp1		; Now 10x
	mov	Main_Spoolup_Time_10x, A
	add	A, Main_Spoolup_Time_3x
	add	A, Temp1		
	add	A, Temp1		; Now 15x
	mov	Main_Spoolup_Time_15x, A
ENDIF
	; Decode demag compensation
	mov	Temp1, #Pgm_Demag_Comp		
	mov	A, @Temp1				
	mov	Demag_Pwr_Off_Thresh, #255	; Set default
	mov	Low_Rpm_Pwr_Slope, #12		; Set default

	cjne	A, #2, decode_demag_high

	mov	Demag_Pwr_Off_Thresh, #160	; Settings for demag comp low
	mov	Low_Rpm_Pwr_Slope, #10		

decode_demag_high:
	cjne	A, #3, decode_demag_done

	mov	Demag_Pwr_Off_Thresh, #130	; Settings for demag comp high
	mov	Low_Rpm_Pwr_Slope, #5		

decode_demag_done:
	; Decode pwm dither
	mov	Temp1, #Pgm_Pwm_Dither		
	mov	A, @Temp1				
	dec	A	
	mov	DPTR, #PWM_DITHER_TABLE
	movc A, @A+DPTR	
	mov	Pwm_Dither_Decoded, A
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
IF HIGH_BEC_VOLTAGE == 1
	Set_BEC_Lo			; Set default to low
	mov	Temp1, #Pgm_BEC_Voltage_High		
	mov	A, @Temp1				
	jz	set_bec_voltage_exit	

	Set_BEC_Hi			; Set to high

set_bec_voltage_exit:
ENDIF
IF HIGH_BEC_VOLTAGE == 2
	Set_BEC_0				; Set default to low
	mov	Temp1, #Pgm_BEC_Voltage_High		
	mov	A, @Temp1				
	cjne	A, #1, set_bec_voltage_2	

	Set_BEC_1				; Set to level 1

set_bec_voltage_2:
	cjne	A, #2, set_bec_voltage_exit	

	Set_BEC_2				; Set to level 2

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
test_throttle_gain:
	inc	Ppm_Throttle_Gain
	mov	A, Temp5
	mov	B, Ppm_Throttle_Gain	; A has difference, B has gain
	mul	AB
	clr	C
	mov	A, B
	subb	A, #128
	jc	test_throttle_gain
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Average throttle 
;
; Outputs result in Temp3
;
; Averages throttle calibration readings
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
average_throttle:
	setb	Flags3.FULL_THROTTLE_RANGE	; Set range to 1000-2020us
	call	find_throttle_gain	; Set throttle gain
	call wait30ms		
	mov	Temp3, #0
	mov	Temp4, #0
	mov	Temp5, #16		; Average 16 measurments
average_throttle_meas:
	call	wait3ms			; Wait for new RC pulse value
	mov	A, New_Rcp		; Get new RC pulse value
	add	A, Temp3
	mov	Temp3, A
	mov	A, #0
	addc A, Temp4
	mov	Temp4, A
	djnz	Temp5, average_throttle_meas

	mov	Temp5, #4			; Shift 4 times
average_throttle_div:
	clr	C
	mov	A, Temp4   		; Shift right 
	rrc	A      
	mov	Temp4, A   
	mov	A, Temp3   
	rrc	A      
	mov	Temp3, A   
	djnz	Temp5, average_throttle_div

	mov	Temp7, A   		; Copy to Temp7
	clr	Flags3.FULL_THROTTLE_RANGE	
	call	find_throttle_gain	; Set throttle gain
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
	; Check flash lock byte
	mov	A, RSTSRC			
	jb	ACC.6, ($+6)		; Check if flash access error was reset source 

	mov	Bit_Access, #0		; No - then this is the first try

	inc	Bit_Access
	mov	DPTR, #LOCK_BYTE_ADDRESS_16K	; First try is for 16k flash size
	mov	A, Bit_Access
	dec	A
	jz	lock_byte_test

	mov	DPTR, #LOCK_BYTE_ADDRESS_8K	; Second try is for 8k flash size
	dec	A
	jz	lock_byte_test

lock_byte_test:
	movc A, @A+DPTR		; Read lock byte
	inc	A				
	jz	lock_byte_ok		; If lock byte is 0xFF, then start code execution

IF ONE_S_CAPABLE == 0		
	mov	RSTSRC, #12h		; Generate hardware reset and set VDD monitor
ELSE
	mov	RSTSRC, #10h		; Generate hardware reset and disable VDD monitor
ENDIF

lock_byte_ok:
	; Select register bank 0 for main program routines
	clr	PSW.3			; Select register bank 0 for main program routines	
	; Disable the WDT.
IF SIGNATURE_001 == 0f3h		
	anl	PCA0MD, #NOT(40h)	; Clear watchdog enable bit
ENDIF
IF SIGNATURE_001 == 0f8h		
	mov	WDTCN, #0DEh		; Disable watchdog
	mov	WDTCN, #0ADh		
ENDIF
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
IF SIGNATURE_001 == 0f3h		
	orl	OSCICN, #03h		; Set clock divider to 1 (not supported on 'f850)
ENDIF
IF SIGNATURE_001 == 0f8h		
	mov	CLKSEL, #00h		; Set clock divider to 1 (not supported on 'f3xx)
ENDIF
	mov	A, Bit_Access_Int	; Set to 0xFF upon bootloader exit
	cpl	A
	jz	reset_cal_done

	mov	A, OSCICL				
	add	A, #04h			; 24.5MHz to 24MHz (~0.5% per step)
	jb	ACC.7, reset_cal_done	; Is carry (7bit) set? - skip next instruction

	mov	OSCICL, A

reset_cal_done:
	; Switch power off
	call	switch_power_off
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
	; Set default programmed parameters
	call	set_default_parameters
	; Read all programmed parameters
	call read_all_eeprom_parameters
	; Set beep strength
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
	; Initializing beep
	clr	EA				; Disable interrupts explicitly
	call wait200ms	
	call beep_f1
	call wait30ms
	call beep_f2
	call wait30ms
	call beep_f3
	call wait30ms
IF MODE <= 1	; Main or tail
	; Wait for receiver to initialize
	call	wait1s
	call	wait200ms
	call	wait200ms
	call	wait100ms
ENDIF

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; No signal entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
init_no_signal:
	; Disable interrupts explicitly
	clr	EA				
	; Clear RAM
	clr	A				; Clear accumulator
	mov	Temp1, A			; Clear Temp1
clear_ram:	
	mov	@Temp1, A			; Clear RAM
	djnz Temp1, clear_ram	; Is A not zero? - jump
	; Check if input signal is high for more than 15ms
	mov	Temp1, #250
input_high_check_1:
	mov	Temp2, #250
input_high_check_2:
	jnb	RTX_PORT.RTX_PIN, bootloader_done	; Look for low
	djnz	Temp2, input_high_check_2
	djnz	Temp1, input_high_check_1

	ljmp	1C00h			; Jump to bootloader

bootloader_done:
	; Initialize LFSR
	mov	Random, #1
	; Set default programmed parameters
	call	set_default_parameters
	; Read all programmed parameters
	call read_all_eeprom_parameters
	; Decode parameters
	call	decode_parameters
	; Decode settings
	call	decode_settings
	; Set BEC voltage
	call	set_bec_voltage
	; Find throttle gain from stored min and max settings
	call	find_throttle_gain
	; Set beep strength
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
	; Switch power off
	call	switch_power_off
	; Set clock frequency
IF MCU_48MHZ == 1
	Set_MCU_Clk_24MHz
ENDIF
	; Timer control
	mov	TCON, #50h		; Timer0 and timer1 enabled
	; Timer mode
	mov	TMOD, #12h		; Timer0 as 8bit, timer1 as 16bit
	; Timer2: clk/12 for 128us and 32ms interrupts
	mov	TMR2CN, #24h		; Timer2 enabled, low counter interrups enabled 
	; Timer3: clk/12 for commutation timing
	mov	TMR3CN, #04h		; Timer3 enabled
	; PCA
	mov	PCA0CN, #40h		; PCA enabled
	; Enable interrupts
	mov	IE, #22h			; Enable timer0 and timer2 interrupts
	mov	IP, #02h			; High priority to timer0 interrupts
	mov	EIE1, #90h		; Enable timer3 and PCA0 interrupts
	; Initialize comparator
	mov	CPT0CN, #80h		; Comparator enabled, no hysteresis
	mov	CPT0MD, #00h		; Comparator response time 100ns
IF COMP1_USED == 1			
	mov	CPT1CN, #80h		; Comparator enabled, no hysteresis
	mov	CPT1MD, #00h		; Comparator response time 100ns
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
	mov	Temp4, #3						; Number of attempts before going back to detect input signal
measure_pwm_freq_start:	
	mov	Temp3, #12					; Number of pulses to measure
measure_pwm_freq_loop:	
	; Check if period diff was accepted
	mov	A, Rcp_Period_Diff_Accepted
	jnz	measure_pwm_freq_wait

	mov	Temp3, #12					; Reset number of pulses to measure
	djnz	Temp4, ($+5)					; If it is not zero - proceed
	ljmp	init_no_signal					; Go back to detect input signal

measure_pwm_freq_wait:
	call	wait30ms						; Wait 30ms for new pulse
	jb	Flags2.RCP_UPDATED, ($+6)		; Is there an updated RC pulse available - proceed
	ljmp	init_no_signal					; Go back to detect input signal

	clr	Flags2.RCP_UPDATED		 		; Flag that pulse has been evaluated
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
	mov	Temp1, #Pgm_Enable_PWM_Input		; Check if PWM input is enabled
	mov	A, @Temp1
	jnz	test_for_oneshot				; If it is - proceed

	setb	Flags2.RCP_PPM					; Set PPM flag
	mov	A, Flags3						; Clear pwm frequency flags
	anl	A, #NOT((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ)+(1 SHL RCP_PWM_FREQ_12KHZ))
	mov	Flags3, A

test_for_oneshot:	
	; Test whether signal is OnShot125
	clr	Flags2.RCP_PPM_ONESHOT125		; Clear OneShot125 flag
	mov	Rcp_Outside_Range_Cnt, #0		; Reset out of range counter
	call wait100ms						; Wait for new RC pulse
	jnb	Flags2.RCP_PPM, validate_rcp_start	; If flag is not set (PWM) - branch

	clr	C
	mov	A, Rcp_Outside_Range_Cnt			; Check how many pulses were outside normal PPM range (800-2160us)
	subb	A, #10						
	jc	validate_rcp_start

	setb	Flags2.RCP_PPM_ONESHOT125		; Set OneShot125 flag

	; Validate RC pulse
validate_rcp_start:	
	call wait3ms						; Wait for next pulse (NB: Uses Temp1/2!) 
	mov	Temp1, #RCP_VALIDATE			; Set validate level as default
	jnb	Flags2.RCP_PPM, ($+5)			; If flag is not set (PWM) - branch

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
IF MODE >= 1	; Tail or multi
	mov	Temp1, #Pgm_Direction	; Check if bidirectional operation
	mov	A, @Temp1				
	cjne	A, #3, ($+5)

	ajmp	program_by_tx_checked	; Disable tx programming if bidirectional operation
ENDIF

	call wait3ms
	mov	Temp1, #Pgm_Enable_TX_Program; Start programming mode entry if enabled
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
	jb	Flags2.RCP_PPM, throttle_high_cal_start	; If flag is set (PPM) - branch

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
IF MODE <= 1	; Main or tail
	mov	Temp8, #5				; Set 3 seconds wait time
ELSE
	mov	Temp8, #2				; Set 1 seconds wait time
ENDIF
throttle_high_cal:			
	setb	Flags3.FULL_THROTTLE_RANGE	; Set range to 1000-2020us
	call	find_throttle_gain		; Set throttle gain
	call wait100ms				; Wait for new throttle value
	clr	EA					; Disable interrupts (freeze New_Rcp value)
	clr	Flags3.FULL_THROTTLE_RANGE	; Set programmed range
	call	find_throttle_gain		; Set throttle gain
	mov	Temp7, New_Rcp			; Store new RC pulse value
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #(RCP_MAX/2)		; Is RC pulse above midstick?
	setb	EA					; Enable interrupts
	jc	arm_target_updated		; No - branch

	call wait1ms		
	clr	EA					; Disable all interrupts
	call beep_f4
	setb	EA					; Enable all interrupts
	djnz	Temp8, throttle_high_cal	; Continue to wait

	call	average_throttle
	clr	C
	mov	A, Temp7				; Limit to max 250
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
	call	find_throttle_gain		; Set throttle gain
	call wait100ms
	clr	EA					; Disable interrupts (freeze New_Rcp value)
	clr	Flags3.FULL_THROTTLE_RANGE	; Set programmed range
	call	find_throttle_gain		; Set throttle gain
	mov	Temp7, New_Rcp			; Store new RC pulse value
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #(RCP_MAX/2)		; Below midstick?
	setb	EA					; Enable interrupts
	jnc	throttle_low_cal_start	; No - start over

	call wait1ms		
	clr	EA					; Disable all interrupts
	call beep_f1
	call wait10ms
	call beep_f1
	setb	EA					; Enable all interrupts
	djnz	Temp8, throttle_low_cal	; Continue to wait

	call	average_throttle
	mov	A, Temp7				
	add	A, #5				; Add about 2%
	mov	Temp1, #Pgm_Ppm_Min_Throttle	; Store
	mov	@Temp1, A			
	call wait200ms				
	call erase_and_store_all_in_eeprom	
	call	success_beep_inverted

program_by_tx_entry_wait_ppm:	
	call wait100ms
	call	find_throttle_gain		; Set throttle gain
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
	mov	Temp1, #RCP_STOP		; Default stop value
	mov	Temp2, #Pgm_Direction	; Check if bidirectional operation
	mov	A, @Temp2				
	cjne	A, #3, ($+5)			; No - branch

	mov	Temp1, #(RCP_STOP+4)	; Higher stop value for bidirectional

	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, Temp1				; Below stop?
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
	mov	Temp1, #25		; Approximately 1 min
	dec	A
	jz	beep_delay_set

	mov	Temp1, #50		; Approximately 2 min
	dec	A
	jz	beep_delay_set

	mov	Temp1, #125		; Approximately 5 min
	dec	A
	jz	beep_delay_set

	mov	Temp1, #250		; Approximately 10 min
	dec	A
	jz	beep_delay_set

	mov	Power_On_Wait_Cnt_H, #0		; Reset counter for infinite delay

beep_delay_set:
	clr	C
	mov	A, Power_On_Wait_Cnt_H
	subb	A, Temp1				; Check against chosen delay
	jc	wait_for_power_on_no_beep; Has delay elapsed?

	dec	Power_On_Wait_Cnt_H		; Decrement high wait counter
	mov	Power_On_Wait_Cnt_L, #180; Set low wait counter
	mov	Temp1, #Pgm_Beacon_Strength
	mov	Beep_Strength, @Temp1
	clr 	EA					; Disable all interrupts
	call beep_f4				; Signal that there is no signal
	setb	EA					; Enable all interrupts
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
	call wait100ms				; Wait for new RC pulse to be measured

wait_for_power_on_no_beep:
	call wait10ms
	mov	A, Rcp_Timeout_Cnt				; Load RC pulse timeout counter value
	jnz	wait_for_power_on_ppm_not_missing	; If it is not zero - proceed

	jnb	Flags2.RCP_PPM, wait_for_power_on_ppm_not_missing	; If flag is not set (PWM) - branch

	jmp	init_no_signal					; If ppm and pulses missing - go back to detect input signal

wait_for_power_on_ppm_not_missing:
	mov	Temp1, #RCP_STOP
	jb	Flags2.RCP_PPM, ($+5)	; If flag is set (PPM) - branch

	mov	Temp1, #(RCP_STOP+5) 	; Higher than stop (for pwm)

	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, Temp1		 		; Higher than stop (plus some hysteresis)?
	jc	wait_for_power_on_loop	; No - start over

IF MODE >= 1	; Tail or multi
	mov	Temp1, #Pgm_Direction	; Check if bidirectional operation
	mov	A, @Temp1				
	clr	C
	subb	A, #3
	jz 	wait_for_power_on_check_timeout	; Do not wait if bidirectional operation
ENDIF

	lcall wait100ms			; Wait to see if start pulse was only a glitch

wait_for_power_on_check_timeout:
	mov	A, Rcp_Timeout_Cnt		; Load RC pulse timeout counter value
	jnz	($+5)				; If it is not zero - proceed

	ljmp	init_no_signal			; If it is zero (pulses missing) - go back to detect input signal


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Start entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
init_start:
	clr	EA
	call switch_power_off
	clr	A
	mov	Requested_Pwm, A		; Set requested pwm to zero
	mov	Governor_Req_Pwm, A		; Set governor requested pwm to zero
	mov	Current_Pwm, A			; Set current pwm to zero
	mov	Current_Pwm_Limited, A	; Set limited current pwm to zero
	mov	Current_Pwm_Lim_Dith, A
	mov	Pwm_Dither_Excess_Power, A
	setb	EA
	mov	Temp1, #Pgm_Motor_Idle	; Set idle pwm to programmed value	
	mov	A, @Temp1				
	clr	C
	rlc	A
	mov	Pwm_Motor_Idle, A
	clr	A
	mov	Gov_Target_L, A		; Set target to zero
	mov	Gov_Target_H, A
	mov	Gov_Integral_L, A		; Set integral to zero
	mov	Gov_Integral_H, A
	mov	Gov_Integral_X, A
	mov	Adc_Conversion_Cnt, A
	mov	Flags0, A				; Clear flags0
	mov	Flags1, A				; Clear flags1
	mov	Demag_Detected_Metric, A	; Clear demag metric
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
	clr	EA					; Disable interrupts to avoid that Requested_Pwm is overwritten
	mov	Pwm_Limit, #0FFh		; Set pwm limit to max
	call set_startup_pwm
	mov	Pwm_Limit, Requested_Pwm
	mov	Pwm_Limit_Spoolup, Requested_Pwm
	mov	Pwm_Limit_Low_Rpm, Requested_Pwm
	setb	EA
	mov	Requested_Pwm, #1			; Set low pwm again after calling set_startup_pwm
	mov	Current_Pwm, #1
	mov	Current_Pwm_Limited, #1	
	mov	Current_Pwm_Lim_Dith, #1
	mov	Spoolup_Limit_Cnt, Auto_Bailout_Armed
	mov	Spoolup_Limit_Skip, #1			
	; Begin startup sequence
IF MCU_48MHZ == 1
	Set_MCU_Clk_48MHz
ENDIF
	setb	Flags1.MOTOR_SPINNING		; Set motor spinning flag
	setb	Flags1.STARTUP_PHASE		; Set startup phase flag
	mov	Startup_Cnt, #0			; Reset counter
	call comm5comm6				; Initialize commutation
	call comm6comm1				
	call	calc_next_comm_timing		; Set virtual commutation point
	call	calc_next_comm_timing		
	call initialize_timing			; Initialize timing
	call	calc_next_comm_timing		
	call calc_new_wait_times			; Calculate new wait times
	call	initialize_timing			; Initialize timing
	call	wait_before_zc_scan			; Set up comparator timeout
	jmp	run1



;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Run entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
damped_transition:
	; Transition from nondamped to damped if applicable
	clr	EA
	call	decode_parameters		; Set programmed parameters
	setb	EA
	mov	Adc_Conversion_Cnt, #0	; Make sure a voltage reading is done next time
	Set_Adc_Ip_Volt			; Set adc measurement to voltage

; Run 1 = B(p-on) + C(n-pwm) - comparator A evaluated
; Out_cA changes from low to high
run1:
	call wait_for_comp_out_high	; Wait zero cross wait and wait for high
	call setup_comm_wait		; Setup wait time from zero cross to commutation
	call	evaluate_comparator_integrity	; Check whether comparator reading has been normal
	call calc_governor_target	; Calculate governor target
	call wait_for_comm			; Wait from zero cross to commutation
	call comm1comm2			; Commutate
	call calc_next_comm_timing	; Calculate next timing and start advance timing wait
	call wait_advance_timing		; Wait advance timing and start zero cross wait
	call calc_new_wait_times
	call wait_before_zc_scan		; Wait zero cross wait and start zero cross timeout

; Run 2 = A(p-on) + C(n-pwm) - comparator B evaluated
; Out_cB changes from high to low
run2:
	call wait_for_comp_out_low
	call setup_comm_wait	
	call	evaluate_comparator_integrity	
	jnb	Flags1.GOV_ACTIVE, ($+6)
	lcall calc_governor_prop_error
	call	set_pwm_limit_low_rpm
	call wait_for_comm
	call comm2comm3
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Run 3 = A(p-on) + B(n-pwm) - comparator C evaluated
; Out_cC changes from low to high
run3:
	call wait_for_comp_out_high
	call setup_comm_wait	
	call	evaluate_comparator_integrity	
	jnb	Flags1.GOV_ACTIVE, ($+6)
	lcall calc_governor_int_error
	call wait_for_comm
	call comm3comm4
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Run 4 = C(p-on) + B(n-pwm) - comparator A evaluated
; Out_cA changes from high to low
run4:
	call wait_for_comp_out_low
	call setup_comm_wait	
	call	evaluate_comparator_integrity	
	jnb	Flags1.GOV_ACTIVE, ($+6)
	lcall calc_governor_prop_correction
	call wait_for_comm
	call comm4comm5
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Run 5 = C(p-on) + A(n-pwm) - comparator B evaluated
; Out_cB changes from low to high
run5:
	call wait_for_comp_out_high
	call setup_comm_wait	
	call	evaluate_comparator_integrity	
	jnb	Flags1.GOV_ACTIVE, ($+6)
	lcall calc_governor_int_correction
	call wait_for_comm
	call comm5comm6
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

; Run 6 = B(p-on) + A(n-pwm) - comparator C evaluated
; Out_cC changes from high to low
run6:
	call start_adc_conversion
	call wait_for_comp_out_low
	call setup_comm_wait	
	call	evaluate_comparator_integrity	
	call wait_for_comm
	call comm6comm1
	call check_temp_voltage_and_limit_power
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

	; Check if it is direct startup
	jnb	Flags1.STARTUP_PHASE, normal_run_checks
	jb	Flags1.DIR_CHANGE_BRAKE, normal_run_checks	; If a direction change - branch

	; Set spoolup power variables
	mov	Pwm_Limit, Pwm_Spoolup_Beg		; Set initial max power
	mov	Pwm_Limit_Spoolup, Pwm_Spoolup_Beg	; Set initial slow spoolup power
	mov	Spoolup_Limit_Cnt, Auto_Bailout_Armed
	mov	Spoolup_Limit_Skip, #1			
	; Check startup counter
	mov	Temp2, #24				; Set nominal startup parameters
	mov	Temp3, #12
	clr	C
	mov	A, Startup_Cnt				; Load counter
	subb	A, Temp2					; Is counter above requirement?
	jc	direct_start_check_rcp		; No - proceed

	clr	Flags1.STARTUP_PHASE		; Clear startup phase flag
	setb	Flags1.INITIAL_RUN_PHASE		; Set initial run phase flag
	mov	Initial_Run_Rot_Cnt, Temp3	; Set initial run rotation count
IF MODE == 1	; Tail
	mov	Pwm_Limit, #0FFh			; Allow full power
	mov	Pwm_Limit_Spoolup, #0FFh	
ENDIF
IF MODE == 2	; Multi
	mov	Pwm_Limit, Pwm_Spoolup_Beg
	mov	Pwm_Limit_Low_Rpm, Pwm_Spoolup_Beg
	mov	Pwm_Limit_Spoolup, #0FFh	
ENDIF
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
	jnb	Flags1.INITIAL_RUN_PHASE, initial_run_phase_done	; If not initial run phase - branch
	jb	Flags1.DIR_CHANGE_BRAKE, initial_run_phase_done	; If a direction change - branch

	; Decrement startup rotaton count
	mov	A, Initial_Run_Rot_Cnt
	dec	A
	; Check number of nondamped rotations
	jnz 	normal_run_check_startup_rot	; Branch if counter is not zero

	clr	Flags1.INITIAL_RUN_PHASE		; Clear initial run phase flag
	jmp damped_transition			; Do damped transition if counter is zero

normal_run_check_startup_rot:
	mov	Initial_Run_Rot_Cnt, A		; Not zero - store counter

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

	mov	Pwm_Limit_Spoolup, Pwm_Spoolup_Beg		; If yes - set initial max powers
	mov	Spoolup_Limit_Cnt, Auto_Bailout_Armed	; And set spoolup parameters
	mov	Spoolup_Limit_Skip, #1			

run6_check_rcp_stop_count:
ENDIF
	; Exit run loop after a given time
	clr	C
	mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter low byte value
	subb	A, #RCP_STOP_LIMIT			; Is number of stop RC pulses above limit?
	jnc	run_to_wait_for_power_on		; Yes, go back to wait for poweron

run6_check_rcp_timeout:
	jnb	Flags2.RCP_PPM, run6_check_speed	; If flag is not set (PWM) - branch

	mov	A, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	jz	run_to_wait_for_power_on		; If it is zero - go back to wait for poweron

run6_check_speed:
	mov	Temp1, #0F0h				; Default minimum speed
	jnb	Flags1.DIR_CHANGE_BRAKE, run6_brake_done; Is it a direction change?

	inc	Brake_Cnt					; "Timeout" on braking (in case comparator noise keeps motor "running")
	clr	C
	mov	A, Brake_Cnt
	subb	A, #150 
	jnc	run_to_wait_for_power_on
	mov	Temp1, #50h				; Bidirectional braking termination speed

run6_brake_done:
	clr	C
	mov	A, Comm_Period4x_H			; Is Comm_Period4x more than 32ms (~1220 eRPM)?
	subb	A, Temp1
	jnc	run_to_wait_for_power_on		; Yes - go back to motor start
	jmp	run1						; Go back to run 1


run_to_wait_for_power_on:	
	jnb	Flags1.DIR_CHANGE_BRAKE, run_to_wait_for_power_on_brake_done; Is it a direction change?

	All_pFETs_on
	call wait30ms					; Additional braking for motor to stop
	
run_to_wait_for_power_on_brake_done:
	clr	EA
	call switch_power_off
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, @Temp1	
	mov	Temp7, A					; Store setting in Temp7
	mov	@Temp1, #2				; Set low pwm mode (in order to turn off damping)
	call	decode_parameters			; (Decode_parameters uses Temp1 and Temp8)
	mov	Temp1, #Pgm_Pwm_Freq
	mov	A, Temp7
	mov	@Temp1, A					; Restore settings
	clr	A
	mov	Requested_Pwm, A			; Set requested pwm to zero
	mov	Governor_Req_Pwm, A			; Set governor requested pwm to zero
	mov	Current_Pwm, A				; Set current pwm to zero
	mov	Current_Pwm_Limited, A		; Set limited current pwm to zero
	mov	Current_Pwm_Lim_Dith, A	
	mov	Pwm_Motor_Idle, A			; Set motor idle to zero
	clr	Flags1.MOTOR_SPINNING		; Clear motor spinning flag
IF MCU_48MHZ == 1
	Set_MCU_Clk_24MHz
ENDIF
	setb	EA
	call	wait1ms					; Wait for pwm to be stopped
	call switch_power_off
IF MODE == 0	; Main
	jnb	Flags2.RCP_PPM, run_to_next_state_main	; If flag is not set (PWM) - branch

	mov	A, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	jnz	run_to_next_state_main		; If it is not zero - branch

	jmp	init_no_signal				; If it is zero (pulses missing) - go back to detect input signal

run_to_next_state_main:
	mov	Temp1, #Pgm_Main_Rearm_Start
	mov	A, @Temp1	
	clr	C
	subb	A, #1					; Is re-armed start enabled?
	jc 	jmp_wait_for_power_on		; No - do like tail and start immediately

	jmp	validate_rcp_start			; Yes - go back to validate RC pulse

jmp_wait_for_power_on:
	jmp	wait_for_power_on			; Go back to wait for power on
ENDIF
IF MODE >= 1	; Tail or multi
	jnb	Flags2.RCP_PPM, jmp_wait_for_power_on	; If flag is not set (PWM) - branch

	mov	A, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	jnz	jmp_wait_for_power_on		; If it is not zero - go back to wait for poweron

	jmp	init_no_signal				; If it is zero (pulses missing) - go back to detect input signal

jmp_wait_for_power_on:
	jmp	wait_for_power_on			; Go back to wait for power on
ENDIF

;**** **** **** **** **** **** **** **** **** **** **** **** ****

$include (BLHeliTxPgm.inc)			; Include source code for programming the ESC with the TX
$include (BLHeliBootLoad.inc)			; Include source code for bootloader

;**** **** **** **** **** **** **** **** **** **** **** **** ****





; TEST code size
;CSEG AT 1E00h		; Last code segment. Take care that there is enough space!
;nop



END