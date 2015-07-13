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
; BESC EQU "ESC"_"mode" 						
; 
;**** **** **** **** ****
; Revision history:
; - Rev0.0: Initial revision
; - Rev1.0: Governor functionality added
; - Rev1.1: Increased tail gain to 1.0625. Implemented for tail only
;		  Decreased governor proportional and integral gain by 4
; 		  Fixed bug that caused tail power not always to be max
; - Rev1.2: Governor integral gain should be higher in order to achieve full PWM range
;           Integral gain can be higher, and is increased by 2x. An integral of +-128 can now be added to requested PWM
; - Rev1.3: Governor integral extended to 24bit
;		  Governor proportional gain increased by 2x	
;		  Added slow spoolup/down for governor
;		  Set pwm to 100% (do not turn off nFET) for high values of current pwm
;		  Added support for PPM input (1us to 2us pulse)
;		  Removed USE_COMP_STORED as it was never used
; - Rev2.0  Added measurement of pwm frequency and support for 1kHz, 2kHz, 4kHz and 8kHz
;           Optimized pwm on and off routines
;           Improved mosfet switching in beep routines, to reduce current draw
;           Added support for ICP1 interrupt pin input
;           Added ADC measurement of supply voltage, with limiting of main motor power for low voltage
;           Miscellaneous other changes
; - Rev2.1  Rewritten INT0 routine to be similar to ICP
;           Reduced validation threshold (RCP_VALIDATE)
;           Removed requirement for RCP to go to zero again in tail arming sequence
;           Removed PPM support
; - Rev2.2  Added support for HC 5A 1S ESC with Atmega48V MPU
;           Increased governor proportional gain by 2x
; - Rev3.0  Added functionality for programming from TX
;           Added low voltage limit scaling for 2S and 3S
; - Rev11.2 Copied over from the SiLabs version and adapted to Atmel
;           Now requiring a 16MHz capable MCU for fullspec performance
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
; - Rev13.0 Removed throttle change rate and damping force parameters
;           Temperature protection default set to off
;           Added support for OneShot125
;           Improved commutation timing accuracy
; - Rev13.1 Removed startup ramp for MULTI
;           Improved startup for some odd ESCs
; - Rev13.2 Still tweaking startup to make it more reliable and faster for all ESC/motor combos
;           Increased deadband for bidirectional operation
;           Relaxed signal detection criteria
;           Miscellaneous other changes
; - Rev14.0 Improved running at high RPMs and increased max RPM limit
;           Improved reliability of 3D (bidirectional) mode and startup
;           Avoid being locked in bootloader (implemented in Suite 13202)
;           Smoother running and greatly reduced step to full power in damped light mode
;           Removed low voltage limiting for MULTI
;           Added pwm dither parameter
;           Added setting for enable/disable of low RPM power protection
;           Added setting for enable/disable of PWM input
;           Better AFW and damping for some ESCs (that have a slow high side driver)
;           Miscellaneous other changes
;
;
;
;**** **** **** **** ****
; 8K Bytes of In-System Self-Programmable Flash
; 1K Bytes Internal SRAM
; 512 Bytes Internal EEPROM
; 16MHz clock
;
;**** **** **** **** **** 
; Timer 0 (500ns counts) always counts up and is used for
; - RC pulse timeout and skip counts
; Timer 1 (500ns counts) always counts up and is used for
; - RC pulse measurement (via external interrupt 0 or input capture pin)
; - Commutation timing (via output compare register A interrupt)
; Timer 2 (500ns counts) always counts up and is used for
; - PWM generation
;
;**** **** **** **** ****
; Interrupt handling
; The Atmega8 disables all interrupts when entering an interrupt routine,
; The code reenables interrupts in some interrupt routines, in order to nest pwm interrupts
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
; Select the ESC and mode to use (or unselect all for use with external batch compile file);
;#define BLUESERIES_12A_MAIN 
;#define BLUESERIES_12A_TAIL
;#define BLUESERIES_12A_MULTI 
;#define BLUESERIES_20A_MAIN
;#define BLUESERIES_20A_TAIL
;#define BLUESERIES_20A_MULTI 
;#define BLUESERIES_30A_MAIN
;#define BLUESERIES_30A_TAIL
;#define BLUESERIES_30A_MULTI 
;#define BLUESERIES_40A_MAIN
;#define BLUESERIES_40A_TAIL
;#define BLUESERIES_40A_MULTI 
;#define BLUESERIES_60A_MAIN
;#define BLUESERIES_60A_TAIL
;#define BLUESERIES_60A_MULTI
;#define BLUESERIES_70A_MAIN
;#define BLUESERIES_70A_TAIL
;#define BLUESERIES_70A_MULTI
;#define HK_UBEC_6A_MAIN
;#define HK_UBEC_6A_TAIL
;#define HK_UBEC_6A_MULTI
;#define HK_UBEC_10A_MAIN
;#define HK_UBEC_10A_TAIL
;#define HK_UBEC_10A_MULTI
;#define HK_UBEC_20A_MAIN
;#define HK_UBEC_20A_TAIL
;#define HK_UBEC_20A_MULTI
;#define HK_UBEC_30A_MAIN
;#define HK_UBEC_30A_TAIL
;#define HK_UBEC_30A_MULTI
;#define HK_UBEC_40A_MAIN
;#define HK_UBEC_40A_TAIL
;#define HK_UBEC_40A_MULTI
;#define SUPERSIMPLE_18A_MAIN
;#define SUPERSIMPLE_18A_TAIL
;#define SUPERSIMPLE_18A_MULTI
;#define SUPERSIMPLE_20A_MAIN
;#define SUPERSIMPLE_20A_TAIL
;#define SUPERSIMPLE_20A_MULTI
;#define SUPERSIMPLE_30A_MAIN
;#define SUPERSIMPLE_30A_TAIL
;#define SUPERSIMPLE_30A_MULTI
;#define SUPERSIMPLE_40A_MAIN
;#define SUPERSIMPLE_40A_TAIL
;#define SUPERSIMPLE_40A_MULTI
;#define MULTISTAR_10Av2_MAIN			
;#define MULTISTAR_10Av2_TAIL
;#define MULTISTAR_10Av2_MULTI
;#define MULTISTAR_15A_MAIN			; Inverted input
;#define MULTISTAR_15A_TAIL
;#define MULTISTAR_15A_MULTI
;#define MULTISTAR_20A_MAIN			; Inverted input
;#define MULTISTAR_20A_TAIL
;#define MULTISTAR_20A_MULTI
;#define MULTISTAR_20A_NFET_MAIN		; Inverted input
;#define MULTISTAR_20A_NFET_TAIL
;#define MULTISTAR_20A_NFET_MULTI
;#define MULTISTAR_20Av2_MAIN			
;#define MULTISTAR_20Av2_TAIL
;#define MULTISTAR_20Av2_MULTI
;#define MULTISTAR_30A_MAIN			; Inverted input
;#define MULTISTAR_30A_TAIL
;#define MULTISTAR_30A_MULTI
;#define MULTISTAR_45A_MAIN			; Inverted input
;#define MULTISTAR_45A_TAIL
;#define MULTISTAR_45A_MULTI
;#define MYSTERY_12A_MAIN			
;#define MYSTERY_12A_TAIL
;#define MYSTERY_12A_MULTI 
;#define MYSTERY_30A_MAIN			
;#define MYSTERY_30A_TAIL
;#define MYSTERY_30A_MULTI
;#define MYSTERY_40A_MAIN			
;#define MYSTERY_40A_TAIL
;#define MYSTERY_40A_MULTI
;#define SUNRISE_HIMULTI_20A_MAIN		; Inverted input
;#define SUNRISE_HIMULTI_20A_TAIL
;#define SUNRISE_HIMULTI_20A_MULTI
;#define SUNRISE_HIMULTI_30A_MAIN		; Inverted input
;#define SUNRISE_HIMULTI_30A_TAIL
;#define SUNRISE_HIMULTI_30A_MULTI
;#define SUNRISE_HIMULTI_40A_MAIN		; Inverted input
;#define SUNRISE_HIMULTI_40A_TAIL
;#define SUNRISE_HIMULTI_40A_MULTI 
;#define RCTIMER_40A_MAIN			
;#define RCTIMER_40A_TAIL
;#define RCTIMER_40A_MULTI
;#define RCTIMER_NFS_30A_MAIN			; ICP1 as input		
;#define RCTIMER_NFS_30A_TAIL
;#define RCTIMER_NFS_30A_MULTI
;#define YEP_7A_MAIN					
;#define YEP_7A_TAIL
;#define YEP_7A_MULTI
;#define AFRO_12A_MAIN				; ICP1 as input		
;#define AFRO_12A_TAIL
;#define AFRO_12A_MULTI
;#define AFRO_20A_MAIN				; ICP1 as input		
;#define AFRO_20A_TAIL
;#define AFRO_20A_MULTI
;#define AFRO_20A_HV_MAIN			; ICP1 as input		
;#define AFRO_20A_HV_TAIL
;#define AFRO_20A_HV_MULTI
;#define AFRO_30A_MAIN				; ICP1 as input		
;#define AFRO_30A_TAIL
;#define AFRO_30A_MULTI
;#define SUNRISE_BLHELI_SLIM_20A_MAIN	
;#define SUNRISE_BLHELI_SLIM_20A_TAIL
;#define SUNRISE_BLHELI_SLIM_20A_MULTI
;#define SUNRISE_BLHELI_SLIM_30A_MAIN	
;#define SUNRISE_BLHELI_SLIM_30A_TAIL
;#define SUNRISE_BLHELI_SLIM_30A_MULTI
;#define DYS_SN20A_MAIN				; ICP1 as input		
;#define DYS_SN20A_TAIL
;#define DYS_SN20A_MULTI 



;**** **** **** **** ****
; ESC selection statements
#if defined(BLUESERIES_12A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "BlueSeries_12A.inc"		; Select BlueSeries 12A pinout
#endif

#if defined(BLUESERIES_12A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "BlueSeries_12A.inc"		; Select BlueSeries 12A pinout
#endif

#if defined(BLUESERIES_12A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "BlueSeries_12A.inc"		; Select BlueSeries 12A pinout
#endif

#if defined(BLUESERIES_20A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "BlueSeries_20A.inc"		; Select BlueSeries 20A pinout
#endif

#if defined(BLUESERIES_20A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "BlueSeries_20A.inc"		; Select BlueSeries 20A pinout
#endif

#if defined(BLUESERIES_20A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "BlueSeries_20A.inc"		; Select BlueSeries 20A pinout
#endif

#if defined(BLUESERIES_30A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "BlueSeries_30A.inc"		; Select BlueSeries 30A pinout
#endif

#if defined(BLUESERIES_30A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "BlueSeries_30A.inc"		; Select BlueSeries 30A pinout
#endif

#if defined(BLUESERIES_30A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "BlueSeries_30A.inc"		; Select BlueSeries 30A pinout
#endif

#if defined(BLUESERIES_40A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "BlueSeries_40A.inc"		; Select BlueSeries 40A pinout
#endif

#if defined(BLUESERIES_40A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "BlueSeries_40A.inc"		; Select BlueSeries 40A pinout
#endif

#if defined(BLUESERIES_40A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "BlueSeries_40A.inc"		; Select BlueSeries 40A pinout
#endif

#if defined(BLUESERIES_60A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "BlueSeries_60A.inc"		; Select BlueSeries 60A pinout
#endif

#if defined(BLUESERIES_60A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "BlueSeries_60A.inc"		; Select BlueSeries 60A pinout
#endif

#if defined(BLUESERIES_60A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "BlueSeries_60A.inc"		; Select BlueSeries 60A pinout
#endif

#if defined(BLUESERIES_70A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "BlueSeries_70A.inc"		; Select BlueSeries 70A pinout
#endif

#if defined(BLUESERIES_70A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "BlueSeries_70A.inc"		; Select BlueSeries 70A pinout
#endif

#if defined(BLUESERIES_70A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "BlueSeries_70A.inc"		; Select BlueSeries 70A pinout
#endif

#if defined(HK_UBEC_6A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "HK_UBEC_6A.inc"		; Select Hobbyking UBEC 6A pinout
#endif

#if defined(HK_UBEC_6A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "HK_UBEC_6A.inc"		; Select Hobbyking UBEC 6A pinout
#endif

#if defined(HK_UBEC_6A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "HK_UBEC_6A.inc"		; Select Hobbyking UBEC 6A pinout
#endif

#if defined(HK_UBEC_10A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "HK_UBEC_10A.inc"		; Select Hobbyking UBEC 10A pinout
#endif

#if defined(HK_UBEC_10A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "HK_UBEC_10A.inc"		; Select Hobbyking UBEC 10A pinout
#endif

#if defined(HK_UBEC_10A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "HK_UBEC_10A.inc"		; Select Hobbyking UBEC 10A pinout
#endif

#if defined(HK_UBEC_20A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "HK_UBEC_20A.inc"		; Select Hobbyking UBEC 20A pinout
#endif

#if defined(HK_UBEC_20A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "HK_UBEC_20A.inc"		; Select Hobbyking UBEC 20A pinout
#endif

#if defined(HK_UBEC_20A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "HK_UBEC_20A.inc"		; Select Hobbyking UBEC 20A pinout
#endif

#if defined(HK_UBEC_30A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "HK_UBEC_30A.inc"		; Select Hobbyking UBEC 30A pinout
#endif

#if defined(HK_UBEC_30A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "HK_UBEC_30A.inc"		; Select Hobbyking UBEC 30A pinout
#endif

#if defined(HK_UBEC_30A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "HK_UBEC_30A.inc"		; Select Hobbyking UBEC 30A pinout
#endif

#if defined(HK_UBEC_40A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "HK_UBEC_40A.inc"		; Select Hobbyking UBEC 40A pinout
#endif

#if defined(HK_UBEC_40A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "HK_UBEC_40A.inc"		; Select Hobbyking UBEC 40A pinout
#endif

#if defined(HK_UBEC_40A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "HK_UBEC_40A.inc"		; Select Hobbyking UBEC 40A pinout
#endif

#if defined(SUPERSIMPLE_18A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "SuperSimple_18A.inc"	; Select SuperSimple 18A pinout
#endif

#if defined(SUPERSIMPLE_18A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "SuperSimple_18A.inc"	; Select SuperSimple 18A pinout
#endif

#if defined(SUPERSIMPLE_18A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "SuperSimple_18A.inc"	; Select SuperSimple 18A pinout
#endif

#if defined(SUPERSIMPLE_20A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "SuperSimple_20A.inc"	; Select SuperSimple 20A pinout
#endif

#if defined(SUPERSIMPLE_20A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "SuperSimple_20A.inc"	; Select SuperSimple 20A pinout
#endif

#if defined(SUPERSIMPLE_20A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "SuperSimple_20A.inc"	; Select SuperSimple 20A pinout
#endif

#if defined(SUPERSIMPLE_30A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "SuperSimple_30A.inc"	; Select SuperSimple 30A pinout
#endif

#if defined(SUPERSIMPLE_30A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "SuperSimple_30A.inc"	; Select SuperSimple 30A pinout
#endif

#if defined(SUPERSIMPLE_30A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "SuperSimple_30A.inc"	; Select SuperSimple 30A pinout
#endif

#if defined(SUPERSIMPLE_40A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "SuperSimple_40A.inc"	; Select SuperSimple 40A pinout
#endif

#if defined(SUPERSIMPLE_40A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "SuperSimple_40A.inc"	; Select SuperSimple 40A pinout
#endif

#if defined(SUPERSIMPLE_40A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "SuperSimple_40A.inc"	; Select SuperSimple 40A pinout
#endif

#if defined(MULTISTAR_10Av2_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Multistar_10Av2.inc"	; Select Multistar 10A v2 pinout
#endif

#if defined(MULTISTAR_10Av2_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Multistar_10Av2.inc"	; Select Multistar 10A v2 pinout
#endif

#if defined(MULTISTAR_10Av2_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Multistar_10Av2.inc"	; Select Multistar 10A v2 pinout
#endif

#if defined(MULTISTAR_15A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Multistar_15A.inc"		; Select Multistar 15A pinout
#endif

#if defined(MULTISTAR_15A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Multistar_15A.inc"		; Select Multistar 15A pinout
#endif

#if defined(MULTISTAR_15A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Multistar_15A.inc"		; Select Multistar 15A pinout
#endif

#if defined(MULTISTAR_20A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Multistar_20A.inc"		; Select Multistar 20A pinout
#endif

#if defined(MULTISTAR_20A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Multistar_20A.inc"		; Select Multistar 20A pinout
#endif

#if defined(MULTISTAR_20A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Multistar_20A.inc"		; Select Multistar 20A pinout
#endif

#if defined(MULTISTAR_20A_NFET_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Multistar_20A_NFET.inc"	; Select Multistar 20A NFET pinout
#endif

#if defined(MULTISTAR_20A_NFET_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Multistar_20A_NFET.inc"	; Select Multistar 20A NFET pinout
#endif

#if defined(MULTISTAR_20A_NFET_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Multistar_20A_NFET.inc"	; Select Multistar 20A NFET pinout
#endif

#if defined(MULTISTAR_20Av2_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Multistar_20Av2.inc"	; Select Multistar 20A v2 pinout
#endif

#if defined(MULTISTAR_20Av2_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Multistar_20Av2.inc"	; Select Multistar 20A v2 pinout
#endif

#if defined(MULTISTAR_20Av2_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Multistar_20Av2.inc"	; Select Multistar 20A v2 pinout
#endif

#if defined(MULTISTAR_30A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Multistar_30A.inc"		; Select Multistar 30A pinout
#endif

#if defined(MULTISTAR_30A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Multistar_30A.inc"		; Select Multistar 30A pinout
#endif

#if defined(MULTISTAR_30A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Multistar_30A.inc"		; Select Multistar 30A pinout
#endif

#if defined(MULTISTAR_45A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Multistar_45A.inc"		; Select Multistar 45A pinout
#endif

#if defined(MULTISTAR_45A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Multistar_45A.inc"		; Select Multistar 45A pinout
#endif

#if defined(MULTISTAR_45A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Multistar_45A.inc"		; Select Multistar 45A pinout
#endif

#if defined(MYSTERY_12A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Mystery_12A.inc"		; Select Mystery 12A pinout
#endif

#if defined(MYSTERY_12A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Mystery_12A.inc"		; Select Mystery 12A pinout
#endif

#if defined(MYSTERY_12A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Mystery_12A.inc"		; Select Mystery 12A pinout
#endif

#if defined(MYSTERY_30A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Mystery_30A.inc"		; Select Mystery 30A pinout
#endif

#if defined(MYSTERY_30A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Mystery_30A.inc"		; Select Mystery 30A pinout
#endif

#if defined(MYSTERY_30A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Mystery_30A.inc"		; Select Mystery 30A pinout
#endif

#if defined(MYSTERY_40A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Mystery_40A.inc"		; Select Mystery 40A pinout
#endif

#if defined(MYSTERY_40A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Mystery_40A.inc"		; Select Mystery 40A pinout
#endif

#if defined(MYSTERY_40A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Mystery_40A.inc"		; Select Mystery 40A pinout
#endif

#if defined(SUNRISE_HIMULTI_20A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Sunrise_HiMulti_20A.inc"	; Select Sunrise HiMulti 20A pinout
#endif

#if defined(SUNRISE_HIMULTI_20A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Sunrise_HiMulti_20A.inc"	; Select Sunrise HiMulti 20A pinout
#endif

#if defined(SUNRISE_HIMULTI_20A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Sunrise_HiMulti_20A.inc"	; Select Sunrise HiMulti 20A pinout
#endif

#if defined(SUNRISE_HIMULTI_30A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Sunrise_HiMulti_30A.inc"	; Select Sunrise HiMulti 30A pinout
#endif

#if defined(SUNRISE_HIMULTI_30A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Sunrise_HiMulti_30A.inc"	; Select Sunrise HiMulti 30A pinout
#endif

#if defined(SUNRISE_HIMULTI_30A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Sunrise_HiMulti_30A.inc"	; Select Sunrise HiMulti 30A pinout
#endif

#if defined(SUNRISE_HIMULTI_40A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Sunrise_HiMulti_40A.inc"	; Select Sunrise HiMulti 40A pinout
#endif

#if defined(SUNRISE_HIMULTI_40A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Sunrise_HiMulti_40A.inc"	; Select Sunrise HiMulti 40A pinout
#endif

#if defined(SUNRISE_HIMULTI_40A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Sunrise_HiMulti_40A.inc"	; Select Sunrise HiMulti 40A pinout
#endif

#if defined(RCTIMER_40A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "RCTimer_40A.inc"		; Select RCTimer 40A pinout
#endif

#if defined(RCTIMER_40A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "RCTimer_40A.inc"		; Select RCTimer 40A pinout
#endif

#if defined(RCTIMER_40A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "RCTimer_40A.inc"		; Select RCTimer 40A pinout
#endif

#if defined(RCTIMER_NFS_30A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "RCTimer_NFS_30A.inc"	; Select RCTimer NFS 30A pinout
#endif

#if defined(RCTIMER_NFS_30A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "RCTimer_NFS_30A.inc"	; Select RCTimer NFS 30A pinout
#endif

#if defined(RCTIMER_NFS_30A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "RCTimer_NFS_30A.inc"	; Select RCTimer NFS 30A pinout
#endif

#if defined(YEP_7A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "YEP_7A.inc"			; Select YEP 7A pinout
#endif

#if defined(YEP_7A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "YEP_7A.inc"			; Select YEP 7A pinout
#endif

#if defined(YEP_7A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "YEP_7A.inc"			; Select YEP 7A pinout
#endif

#if defined(AFRO_12A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "AFRO_12A.inc"			; Select AFRO 12A pinout
#endif

#if defined(AFRO_12A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "AFRO_12A.inc"			; Select AFRO 12A pinout
#endif

#if defined(AFRO_12A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "AFRO_12A.inc"			; Select AFRO 12A pinout
#endif

#if defined(AFRO_20A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "AFRO_20A.inc"			; Select AFRO 20A pinout
#endif

#if defined(AFRO_20A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "AFRO_20A.inc"			; Select AFRO 20A pinout
#endif

#if defined(AFRO_20A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "AFRO_20A.inc"			; Select AFRO 20A pinout
#endif

#if defined(AFRO_20A_HV_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "AFRO_20A_HV.inc"		; Select AFRO 20A HV pinout
#endif

#if defined(AFRO_20A_HV_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "AFRO_20A_HV.inc"		; Select AFRO 20A HV pinout
#endif

#if defined(AFRO_20A_HV_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "AFRO_20A_HV.inc"		; Select AFRO 20A HV pinout
#endif

#if defined(AFRO_30A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "AFRO_30A.inc"			; Select AFRO 30A pinout
#endif

#if defined(AFRO_30A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "AFRO_30A.inc"			; Select AFRO 30A pinout
#endif

#if defined(AFRO_30A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "AFRO_30A.inc"			; Select AFRO 30A pinout
#endif

#if defined(SUNRISE_BLHELI_SLIM_20A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Sunrise_BLHeli_Slim_20A.inc"	; Select Sunrise BLHeli slim 20A pinout
#endif

#if defined(SUNRISE_BLHELI_SLIM_20A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Sunrise_BLHeli_Slim_20A.inc"	; Select Sunrise BLHeli slim 20A pinout
#endif

#if defined(SUNRISE_BLHELI_SLIM_20A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Sunrise_BLHeli_Slim_20A.inc"	; Select Sunrise BLHeli slim 20A pinout
#endif

#if defined(SUNRISE_BLHELI_SLIM_30A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "Sunrise_BLHeli_Slim_30A.inc"	; Select Sunrise BLHeli slim 30A pinout
#endif

#if defined(SUNRISE_BLHELI_SLIM_30A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "Sunrise_BLHeli_Slim_30A.inc"	; Select Sunrise BLHeli slim 30A pinout
#endif

#if defined(SUNRISE_BLHELI_SLIM_30A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "Sunrise_BLHeli_Slim_30A.inc"	; Select Sunrise BLHeli slim 30A pinout
#endif

#if defined(DYS_SN20A_MAIN)
.EQU	MODE 	= 	0			; Choose mode. Set to 0 for main motor
.INCLUDE "DYS_SN20A.inc"			; Select DYS SN20A pinout
#endif

#if defined(DYS_SN20A_TAIL)
.EQU	MODE 	= 	1			; Choose mode. Set to 1 for tail motor
.INCLUDE "DYS_SN20A.inc"			; Select DYS SN20A pinout
#endif

#if defined(DYS_SN20A_MULTI)
.EQU	MODE 	= 	2			; Choose mode. Set to 2 for multirotor
.INCLUDE "DYS_SN20A.inc"			; Select DYS SN20A pinout
#endif


;**** **** **** **** ****
; TX programming defaults
;
; Parameter dependencies:
; - Governor P gain, I gain and Range is only used if one of the three governor modes is selected
; - Governor setup target is only used if Setup governor mode is selected (or closed loop mode is on for multi)
;
; Main
.EQU	DEFAULT_PGM_MAIN_P_GAIN 			= 7 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
.EQU	DEFAULT_PGM_MAIN_I_GAIN 			= 7 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
.EQU	DEFAULT_PGM_MAIN_GOVERNOR_MODE 	= 1 	; 1=Tx 		2=Arm 		3=Setup		4=Off
.EQU	DEFAULT_PGM_MAIN_GOVERNOR_RANGE 	= 1 	; 1=High		2=Middle		3=Low
.EQU	DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	= 4 	; 1=Off		2=3.0V/c		3=3.1V/c		4=3.2V/c		5=3.3V/c	6=3.4V/c
.EQU	DEFAULT_PGM_MAIN_COMM_TIMING		= 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
.IF DAMPED_MODE_ENABLE == 1
.EQU	DEFAULT_PGM_MAIN_PWM_FREQ 		= 2 	; 1=High 		2=Low		3=DampedLight
.ELSE
.EQU	DEFAULT_PGM_MAIN_PWM_FREQ 		= 2 	; 1=High 		2=Low		
.ENDIF
.EQU	DEFAULT_PGM_MAIN_DEMAG_COMP 		= 1 	; 1=Disabled	2=Low		3=High
.EQU	DEFAULT_PGM_MAIN_DIRECTION		= 1 	; 1=Normal 	2=Reversed
.EQU	DEFAULT_PGM_MAIN_RCP_PWM_POL 		= 1 	; 1=Positive 	2=Negative
.EQU	DEFAULT_PGM_MAIN_GOV_SETUP_TARGET	= 180; Target for governor in setup mode. Corresponds to 70% throttle
.EQU	DEFAULT_PGM_MAIN_REARM_START		= 0 	; 1=Enabled 	0=Disabled
.EQU	DEFAULT_PGM_MAIN_BEEP_STRENGTH	= 120; Beep strength
.EQU	DEFAULT_PGM_MAIN_BEACON_STRENGTH	= 200; Beacon strength
.EQU	DEFAULT_PGM_MAIN_BEACON_DELAY		= 4 	; 1=1m		2=2m			3=5m			4=10m		5=Infinite

; Tail
.EQU	DEFAULT_PGM_TAIL_GAIN 			= 3 	; 1=0.75 		2=0.88 		3=1.00 		4=1.12 		5=1.25
.EQU	DEFAULT_PGM_TAIL_IDLE_SPEED 		= 4 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
.EQU	DEFAULT_PGM_TAIL_COMM_TIMING		= 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
.IF DAMPED_MODE_ENABLE == 1
.EQU	DEFAULT_PGM_TAIL_PWM_FREQ	 	= 3 	; 1=High 		2=Low 		3=DampedLight 
.ELSE
.EQU	DEFAULT_PGM_TAIL_PWM_FREQ	 	= 1 	; 1=High 		2=Low		
.ENDIF
.EQU	DEFAULT_PGM_TAIL_DEMAG_COMP 		= 1 	; 1=Disabled	2=Low		3=High
.EQU	DEFAULT_PGM_TAIL_DIRECTION		= 1 	; 1=Normal 	2=Reversed	3=Bidirectional
.EQU	DEFAULT_PGM_TAIL_RCP_PWM_POL 		= 1 	; 1=Positive 	2=Negative
.EQU	DEFAULT_PGM_TAIL_BEEP_STRENGTH	= 250; Beep strength
.EQU	DEFAULT_PGM_TAIL_BEACON_STRENGTH	= 250; Beacon strength
.EQU	DEFAULT_PGM_TAIL_BEACON_DELAY		= 4 	; 1=1m		2=2m			3=5m			4=10m		5=Infinite
.EQU	DEFAULT_PGM_TAIL_PWM_DITHER		= 3 	; 1=1		2=3			3=7			4=15			5=31

; Multi
.EQU	DEFAULT_PGM_MULTI_P_GAIN 		= 9 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
.EQU	DEFAULT_PGM_MULTI_I_GAIN 		= 9 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
.EQU	DEFAULT_PGM_MULTI_GOVERNOR_MODE 	= 4 	; 1=HiRange	2=MidRange	3=LoRange		4=Off
.EQU	DEFAULT_PGM_MULTI_GAIN 			= 3 	; 1=0.75 		2=0.88 		3=1.00 		4=1.12 		5=1.25
.EQU	DEFAULT_PGM_MULTI_COMM_TIMING		= 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
.IF DAMPED_MODE_ENABLE == 1
.EQU	DEFAULT_PGM_MULTI_PWM_FREQ	 	= 1 	; 1=High 		2=Low 		3=DampedLight 
.ELSE
.EQU	DEFAULT_PGM_MULTI_PWM_FREQ	 	= 1 	; 1=High 		2=Low
.ENDIF
.EQU	DEFAULT_PGM_MULTI_DEMAG_COMP 		= 2 	; 1=Disabled	2=Low		3=High
.EQU	DEFAULT_PGM_MULTI_DIRECTION		= 1 	; 1=Normal 	2=Reversed	3=Bidirectional
.EQU	DEFAULT_PGM_MULTI_RCP_PWM_POL 	= 1 	; 1=Positive 	2=Negative
.EQU	DEFAULT_PGM_MULTI_BEEP_STRENGTH	= 40	; Beep strength
.EQU	DEFAULT_PGM_MULTI_BEACON_STRENGTH	= 80	; Beacon strength
.EQU	DEFAULT_PGM_MULTI_BEACON_DELAY	= 4 	; 1=1m		2=2m			3=5m			4=10m		5=Infinite
.EQU	DEFAULT_PGM_MULTI_PWM_DITHER		= 3 	; 1=1		2=3			3=7			4=15			5=31

; Common
.EQU	DEFAULT_PGM_ENABLE_TX_PROGRAM 	= 1 	; 1=Enabled 	0=Disabled
.EQU	DEFAULT_PGM_PPM_MIN_THROTTLE		= 37	; 4*37+1000=1148
.EQU	DEFAULT_PGM_PPM_MAX_THROTTLE		= 208; 4*208+1000=1832
.EQU	DEFAULT_PGM_PPM_CENTER_THROTTLE	= 122; 4*122+1000=1488 (used in bidirectional mode)
.EQU	DEFAULT_PGM_BEC_VOLTAGE_HIGH		= 0	; 0=Low		1= High
.EQU	DEFAULT_PGM_ENABLE_TEMP_PROT	 	= 0 	; 1=Enabled 	0=Disabled
.EQU	DEFAULT_PGM_ENABLE_POWER_PROT 	= 1 	; 1=Enabled 	0=Disabled
.EQU	DEFAULT_PGM_ENABLE_PWM_INPUT	 	= 0 	; 1=Enabled 	0=Disabled

;**** **** **** **** ****
; Constant definitions for main
.IF MODE == 0

.EQU	GOV_SPOOLRATE		=	2	; Number of steps for governor requested pwm per 32ms

.EQU	RCP_TIMEOUT_PPM	=	10	; Number of timer2H overflows (about 32ms) before considering rc pulse lost
.EQU	RCP_TIMEOUT		=	64	; Number of timer2L overflows (about 128us) before considering rc pulse lost
.EQU	RCP_SKIP_RATE		= 	32	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
.EQU	RCP_MIN			= 	0	; This is minimum RC pulse length
.EQU	RCP_MAX			= 	255	; This is maximum RC pulse length
.EQU	RCP_VALIDATE		= 	2	; Require minimum this pulse length to validate RC pulse
.EQU	RCP_STOP			= 	1	; Stop motor at or below this pulse length
.EQU	RCP_STOP_LIMIT		= 	5	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

.EQU	PWM_START			= 	50 	; PWM used as max power during start

.EQU	COMM_TIME_RED		= 	2	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
.EQU	COMM_TIME_MIN		= 	1	; Minimum time (in us) for commutation wait

.EQU	TEMP_CHECK_RATE	= 	8	; Number of adc conversions for each check of temperature (the other conversions are used for voltage)

.ENDIF
; Constant definitions for tail
.IF MODE == 1

.EQU	GOV_SPOOLRATE		=	1	; Number of steps for governor requested pwm per 32ms
.EQU	RCP_TIMEOUT_PPM	=	10	; Number of timer2H overflows (about 32ms) before considering rc pulse lost
.EQU	RCP_TIMEOUT		= 	24	; Number of timer2L overflows (about 128us) before considering rc pulse lost
.EQU	RCP_SKIP_RATE		= 	6	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
.EQU	RCP_MIN			= 	0	; This is minimum RC pulse length
.EQU	RCP_MAX			= 	255	; This is maximum RC pulse length
.EQU	RCP_VALIDATE		= 	2	; Require minimum this pulse length to validate RC pulse
.EQU	RCP_STOP			= 	1	; Stop motor at or below this pulse length
.EQU	RCP_STOP_LIMIT		= 	130	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

.EQU	PWM_START			= 	50 	; PWM used as max power during start

.EQU	COMM_TIME_RED		= 	2	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
.EQU	COMM_TIME_MIN		= 	1	; Minimum time (in us) for commutation wait

.EQU	TEMP_CHECK_RATE	= 	8	; Number of adc conversions for each check of temperature (the other conversions are used for voltage)

.ENDIF
; Constant definitions for multi
.IF MODE == 2

.EQU	GOV_SPOOLRATE		=	1	; Number of steps for governor requested pwm per 32ms

.EQU	RCP_TIMEOUT_PPM	=	10	; Number of timer2H overflows (about 32ms) before considering rc pulse lost
.EQU	RCP_TIMEOUT		= 	24	; Number of timer2L overflows (about 128us) before considering rc pulse lost
.EQU	RCP_SKIP_RATE		= 	6	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
.EQU	RCP_MIN			= 	0	; This is minimum RC pulse length
.EQU	RCP_MAX			= 	255	; This is maximum RC pulse length
.EQU	RCP_VALIDATE		= 	2	; Require minimum this pulse length to validate RC pulse
.EQU	RCP_STOP			= 	1	; Stop motor at or below this pulse length
.EQU	RCP_STOP_LIMIT		= 	5	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

.EQU	PWM_START			= 	50 	; PWM used as max power during start

.EQU	COMM_TIME_RED		= 	2	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
.EQU	COMM_TIME_MIN		= 	1	; Minimum time (in us) for commutation wait

.EQU	TEMP_CHECK_RATE	= 	8	; Number of adc conversions for each check of temperature (the other conversions are used for voltage)

.ENDIF

;**** **** **** **** ****
; Register definitions
.DEF	Mul_Res_L			= R0		; Reserved for mul instruction
.DEF	Mul_Res_H			= R1		; Reserved for mul instruction
.DEF	Zero				= R2		; Register variable initialized to 0, always at 0
.DEF	I_Sreg			= R3		; Status register saved in interrupts
.DEF	II_Sreg			= R4		; Status register saved in nested interrupts (pwm interrupts from timer2)
.DEF	Current_Pwm_Limited	= R5		; Current_Pwm_Limited is allocated to a register for fast access

.DEF	Temp1			= R16	; Main temporary
.DEF	Temp2			= R17	; Main temporary (Temp1/2 must be two consecutive registers)
.DEF	Temp3			= R18	; Main temporary 
.DEF	Temp4			= R19	; Main temporary
.DEF	Temp5			= R6		; Main temporary (limited operations)
.DEF	Temp6			= R7		; Main temporary (limited operations)
.DEF	Temp7			= R8		; Main temporary (limited operations)
.DEF	Temp8			= R9		; Main temporary (limited operations)

.DEF	I_Temp1			= R20	; Interrupt temporary
.DEF	I_Temp2			= R21	; Interrupt temporary 
.DEF	I_Temp3			= R10	; Interrupt temporary (limited operations)
.DEF	I_Temp4			= R11	; Interrupt temporary (limited operations)
.DEF	I_Temp5			= R12	; Interrupt temporary (limited operations)
.DEF	I_Temp6			= R13	; Interrupt temporary (limited operations)
.DEF	I_Temp7			= R14	; Interrupt temporary (limited operations)
.DEF	I_Temp8			= R15	; Interrupt temporary (limited operations)

.DEF	Flags0				=	R22    	; State flags. Reset upon init_start
.EQU	OC1A_PENDING			= 	0		; Timer1 output compare pending flag
.EQU	RCP_MEAS_PWM_FREQ		=	1		; Measure RC pulse pwm frequency
.EQU	PWM_ON				=	2		; Set in on part of pwm cycle
.EQU	DEMAG_ENABLED			= 	3		; Set when demag compensation is enabled (above a min speed and throttle)
.EQU	DEMAG_DETECTED			= 	4		; Set when excessive demag time is detected
.EQU	DEMAG_CUT_POWER		= 	5		; Set when demag compensation cuts power
.EQU	GOV_ACTIVE			= 	6		; Set when governor is active
.EQU	DIR_CHANGE_BRAKE		= 	7		; Set when braking before direction change


.DEF	Flags1				=	R23    	; State flags. Reset upon init_start 
.EQU	MOTOR_SPINNING			=	0		; Set when in motor is spinning
.EQU	STARTUP_PHASE			= 	1		; Set when in startup phase
.EQU	INITIAL_RUN_PHASE		=	2		; Set when in initial run phase, before synchronized run is achieved
.EQU	ADC_READ_TEMP			= 	3		; Set when ADC input shall be set to read temperature
.EQU	COMP_TIMED_OUT			= 	4		; Set when comparator reading timed out
;.EQU					= 	5
;.EQU					= 	6
;.EQU					= 	7


.DEF	Flags2				=	R24		; State flags. NOT reset upon init_start
.EQU	RCP_UPDATED			= 	0		; New RC pulse length value available
.EQU	RCP_EDGE_NO			= 	1		; RC pulse edge no. 0=rising, 1=falling
.EQU	PGM_PWMOFF_DAMPED		=	2		; Programmed pwm off damped mode
.EQU	PGM_PWM_HIGH_FREQ		=	3		; Progremmed pwm high frequency
.EQU	RCP_INT_NESTED_ENABLED	= 	4		; Set when RC pulse interrupt is enabled around nested interrupts
.EQU	RCP_PPM				= 	5		; RC pulse ppm type input (set also when oneshot is set)
.EQU	RCP_PPM_ONESHOT125		= 	6		; RC pulse ppm type input is OneShot125
;.EQU					= 	7


.DEF	Flags3				=	R25		; State flags. NOT reset upon init_start
.EQU	RCP_PWM_FREQ_1KHZ		= 	0		; RC pulse pwm frequency is 1kHz
.EQU	RCP_PWM_FREQ_2KHZ		= 	1		; RC pulse pwm frequency is 2kHz
.EQU	RCP_PWM_FREQ_4KHZ		= 	2		; RC pulse pwm frequency is 4kHz
.EQU	RCP_PWM_FREQ_8KHZ		= 	3		; RC pulse pwm frequency is 8kHz
.EQU	RCP_PWM_FREQ_12KHZ		= 	4		; RC pulse pwm frequency is 12kHz
.EQU	PGM_DIR_REV			= 	5		; Programmed direction. 0=normal, 1=reversed
.EQU	PGM_RCP_PWM_POL		=	6		; Programmed RC pulse pwm polarity. 0=positive, 1=negative
.EQU	FULL_THROTTLE_RANGE		= 	7		; When set full throttle range is used (1000-2000us) and stored calibration values are ignored


; Here the general temporary register XYZ are placed (R26-R31)

; XH: General temporary used by main routines
; XL: General temporary used by interrupt routines
; Y: General temporary used by timer2 pwm interrupt routine
; Z: Address of current PWM FET ON routine (eg: pwm_afet_on)

;**** **** **** **** ****
; RAM definitions
.DSEG				; Data segment
.ORG SRAM_START
Ram_Reg:					.BYTE	1		; Additional "register" in RAM
Timer0_Int_Cnt:			.BYTE	1		; Timer0 interrupt counter

Requested_Pwm:				.BYTE	1		; Requested pwm (from RC pulse value)
Governor_Req_Pwm:			.BYTE	1		; Governor requested pwm (sets governor target)
Current_Pwm:				.BYTE	1		; Current pwm
Current_Pwm_Lim_Dith:		.BYTE	1		; Current pwm that is limited and dithered (applied to the motor output)
Rcp_Prev_Edge_L:			.BYTE	1		; RC pulse previous edge timer3 timestamp (lo byte)
Rcp_Prev_Edge_H:			.BYTE	1		; RC pulse previous edge timer3 timestamp (hi byte)
Rcp_Outside_Range_Cnt:		.BYTE	1		; RC pulse outside range counter (incrementing) 
Rcp_Timeout_Cnt:			.BYTE	1		; RC pulse timeout counter (decrementing) 
Rcp_Skip_Cnt:				.BYTE	1		; RC pulse skip counter (decrementing) 

Initial_Arm:				.BYTE	1		; Variable that is set during the first arm sequence after power on

Power_On_Wait_Cnt_L: 		.BYTE	1		; Power on wait counter (lo byte)
Power_On_Wait_Cnt_H: 		.BYTE	1		; Power on wait counter (hi byte)

Startup_Cnt:				.BYTE	1		; Startup phase commutations counter (incrementing)
Initial_Run_Rot_Cnt:		.BYTE	1		; Initial run rotations counter (incrementing)
Demag_Detected_Metric:		.BYTE	1		; Metric used to gauge demag event frequency
Demag_Pwr_Off_Thresh:		.BYTE	1		; Metric threshold above which power is cut
Low_Rpm_Pwr_Slope:			.BYTE	1		; Sets the slope of power increase for low rpms

Prev_Comm_L:				.BYTE	1		; Previous commutation timer timestamp (lo byte)
Prev_Comm_H:				.BYTE	1		; Previous commutation timer timestamp (hi byte)
Prev_Prev_Comm_L:			.BYTE	1		; Pre-previous commutation timer timestamp (lo byte)
Prev_Prev_Comm_H:			.BYTE	1		; Pre-previous commutation timer timestamp (hi byte)
Comm_Period4x_L:			.BYTE	1		; Timer3 counts between the last 4 commutations (lo byte)
Comm_Period4x_H:			.BYTE	1		; Timer3 counts between the last 4 commutations (hi byte)
Comm_Diff:				.BYTE	1		; Timer3 count difference between the last two commutations
Comm_Phase:				.BYTE	1		; Current commutation phase
Comparator_Read_Cnt: 		.BYTE	1		; Number of comparator reads done

Gov_Target_L:				.BYTE	1		; Governor target (lo byte)
Gov_Target_H:				.BYTE	1		; Governor target (hi byte)
Gov_Integral_L:			.BYTE	1		; Governor integral error (lo byte)
Gov_Integral_H:			.BYTE	1		; Governor integral error (hi byte)
Gov_Integral_X:			.BYTE	1		; Governor integral error (ex byte)
Gov_Proportional_L:			.BYTE	1		; Governor proportional error (lo byte)
Gov_Proportional_H:			.BYTE	1		; Governor proportional error (hi byte)
Gov_Prop_Pwm:				.BYTE	1		; Governor calculated new pwm based upon proportional error
Gov_Arm_Target:			.BYTE	1		; Governor arm target value

Wt_Advance_L:				.BYTE	1		; Timer3 counts for commutation advance timing (lo byte)
Wt_Advance_H:				.BYTE	1		; Timer3 counts for commutation advance timing (hi byte)
Wt_Zc_Scan_L:				.BYTE	1		; Timer3 counts from commutation to zero cross scan (lo byte)
Wt_Zc_Scan_H:				.BYTE	1		; Timer3 counts from commutation to zero cross scan (hi byte)
Wt_Zc_Timeout_L:			.BYTE	1		; Timer3 counts for zero cross scan timeout (lo byte)
Wt_Zc_Timeout_H:			.BYTE	1		; Timer3 counts for zero cross scan timeout (hi byte)
Wt_Comm_L:				.BYTE	1		; Timer3 counts from zero cross to commutation (lo byte)
Wt_Comm_H:				.BYTE	1		; Timer3 counts from zero cross to commutation (hi byte)
Next_Wt_L:				.BYTE	1		; Timer3 counts for next wait period (lo byte)
Next_Wt_H:				.BYTE	1		; Timer3 counts for next wait period (hi byte)

Rcp_PrePrev_Edge_L:			.BYTE	1		; RC pulse pre previous edge pca timestamp (lo byte)
Rcp_PrePrev_Edge_H:			.BYTE	1		; RC pulse pre previous edge pca timestamp (hi byte)
Rcp_Edge_L:				.BYTE	1		; RC pulse edge pca timestamp (lo byte)
Rcp_Edge_H:				.BYTE	1		; RC pulse edge pca timestamp (hi byte)
Rcp_Prev_Period_L:			.BYTE	1		; RC pulse previous period (lo byte)
Rcp_Prev_Period_H:			.BYTE	1		; RC pulse previous period (hi byte)
Rcp_Period_Diff_Accepted:	.BYTE	1		; RC pulse period difference acceptable
New_Rcp:					.BYTE	1		; New RC pulse value in pca counts
Prev_Rcp_Pwm_Freq:			.BYTE	1		; Previous RC pulse pwm frequency (used during pwm frequency measurement)
Curr_Rcp_Pwm_Freq:			.BYTE	1		; Current RC pulse pwm frequency (used during pwm frequency measurement)
Rcp_Stop_Cnt:				.BYTE	1		; Counter for RC pulses below stop value (lo byte) 
Auto_Bailout_Armed:			.BYTE	1		; Set when auto rotation bailout is armed 

Pwm_Limit:				.BYTE	1		; Maximum allowed pwm 
Pwm_Limit_Spoolup:			.BYTE	1		; Maximum allowed pwm during spoolup of main
Pwm_Limit_Low_Rpm:			.BYTE	1		; Maximum allowed pwm for low rpms
Pwm_Spoolup_Beg:			.BYTE	1		; Pwm to begin main spoolup with
Pwm_Motor_Idle:			.BYTE	1		; Motor idle speed pwm
Pwm_Prev_Edge:				.BYTE	1		; Timestamp from timer 2 when pwm toggles on or off
Pwm_Dither_Decoded:			.BYTE	1		; Decoded pwm dither value
Pwm_Dither_Excess_Power:		.BYTE	1		; Excess power (above max) from pwm dither
Random:					.BYTE	1		; Random number from LFSR 

Spoolup_Limit_Cnt:			.BYTE	1		; Interrupt count for spoolup limit
Spoolup_Limit_Skip:			.BYTE	1		; Interrupt skips for spoolup limit increment (1=no skips, 2=skip one etc)
Main_Spoolup_Time_3x:		.BYTE	1		; Main spoolup time x3
Main_Spoolup_Time_10x:		.BYTE	1		; Main spoolup time x10
Main_Spoolup_Time_15x:		.BYTE	1		; Main spoolup time x15

Lipo_Adc_Reference_L:		.BYTE	1		; Voltage reference adc value (lo byte)
Lipo_Adc_Reference_H:		.BYTE	1		; Voltage reference adc value (hi byte)
Lipo_Adc_Limit_L:			.BYTE	1		; Low voltage limit adc value (lo byte)
Lipo_Adc_Limit_H:			.BYTE	1		; Low voltage limit adc value (hi byte)
Adc_Conversion_Cnt:			.BYTE	1		; Adc conversion counter

Current_Average_Temp_Adc:	.BYTE	1		; Current average temp ADC reading (lo byte of ADC, assuming hi byte is 0)

Ppm_Throttle_Gain:			.BYTE	1		; Gain to be applied to RCP value for PPM input
Beep_Strength:				.BYTE	1		; Strength of beeps

Tx_Pgm_Func_No:			.BYTE	1		; Function number when doing programming by tx
Tx_Pgm_Paraval_No:			.BYTE	1		; Parameter value number when doing programming by tx
Tx_Pgm_Beep_No:			.BYTE	1		; Beep number when doing programming by tx
DampingFET:				.BYTE	1		; Port position of fet used for damping
Brake_Cnt:				.BYTE	1		; Number of rotations for braking

; The variables below must be in this sequence
Pgm_Gov_P_Gain:			.BYTE	1		; Programmed governor P gain
Pgm_Gov_I_Gain:			.BYTE	1		; Programmed governor I gain
Pgm_Gov_Mode:				.BYTE	1		; Programmed governor mode
Pgm_Low_Voltage_Lim:		.BYTE	1		; Programmed low voltage limit
Pgm_Motor_Gain:			.BYTE	1		; Programmed motor gain
Pgm_Motor_Idle:			.BYTE	1		; Programmed motor idle speed
Pgm_Startup_Pwr:			.BYTE	1		; Programmed startup power
Pgm_Pwm_Freq:				.BYTE	1		; Programmed pwm frequency
Pgm_Direction:				.BYTE	1		; Programmed rotation direction
Pgm_Input_Pol:				.BYTE	1		; Programmed input pwm polarity
Initialized_L_Dummy:		.BYTE	1		; Place holder
Initialized_H_Dummy:		.BYTE	1		; Place holder
Pgm_Enable_TX_Program:		.BYTE 	1		; Programmed enable/disable value for TX programming
Pgm_Main_Rearm_Start:		.BYTE 	1		; Programmed enable/disable re-arming main every start 
Pgm_Gov_Setup_Target:		.BYTE 	1		; Programmed main governor setup target
_Pgm_Startup_Rpm:			.BYTE	1		; Programmed startup rpm (unused - place holder)
_Pgm_Startup_Accel:			.BYTE	1		; Programmed startup acceleration (unused - place holder)
_Pgm_Volt_Comp:			.BYTE	1		; Place holder
Pgm_Comm_Timing:			.BYTE	1		; Programmed commutation timing
_Pgm_Damping_Force:			.BYTE	1		; Programmed damping force (unused - place holder)
Pgm_Gov_Range:				.BYTE	1		; Programmed governor range
Pgm_Startup_Method:			.BYTE	1		; Programmed startup method
Pgm_Ppm_Min_Throttle:		.BYTE	1		; Programmed throttle minimum
Pgm_Ppm_Max_Throttle:		.BYTE	1		; Programmed throttle maximum
Pgm_Beep_Strength:			.BYTE	1		; Programmed beep strength
Pgm_Beacon_Strength:		.BYTE	1		; Programmed beacon strength
Pgm_Beacon_Delay:			.BYTE	1		; Programmed beacon delay
_Pgm_Throttle_Rate:			.BYTE	1		; Programmed throttle rate (unused - place holder)
Pgm_Demag_Comp:			.BYTE	1		; Programmed demag compensation
Pgm_BEC_Voltage_High:		.BYTE	1		; Programmed BEC voltage
Pgm_Ppm_Center_Throttle:		.BYTE	1		; Programmed throttle center (in bidirectional mode)
Pgm_Main_Spoolup_Time:		.BYTE	1		; Programmed main spoolup time
Pgm_Enable_Temp_Prot:		.BYTE	1		; Programmed temperature protection enable
Pgm_Enable_Power_Prot:		.BYTE	1		; Programmed low rpm power protection enable
Pgm_Enable_Pwm_Input:		.BYTE	1		; Programmed PWM input signal enable
Pgm_Pwm_Dither:			.BYTE	1		; Programmed output PWM dither

; The sequence of the variables below is no longer of importance
Pgm_Gov_P_Gain_Decoded:		.BYTE	1		; Programmed governor decoded P gain
Pgm_Gov_I_Gain_Decoded:		.BYTE	1		; Programmed governor decoded I gain
Pgm_Startup_Pwr_Decoded:		.BYTE	1		; Programmed startup power decoded


.EQU	SRAM_BYTES	= 255		; Bytes used in SRAM. Used for number of bytes to reset

;**** **** **** **** ****
.ESEG				; Eeprom segment
.ORG 0				

.EQU	EEPROM_FW_MAIN_REVISION		=	14		; Main revision of the firmware
.EQU	EEPROM_FW_SUB_REVISION		=	0		; Sub revision of the firmware
.EQU	EEPROM_LAYOUT_REVISION		=	20		; Revision of the EEPROM layout

Eep_FW_Main_Revision:		.DB	EEPROM_FW_MAIN_REVISION			; EEPROM firmware main revision number
Eep_FW_Sub_Revision:		.DB	EEPROM_FW_SUB_REVISION			; EEPROM firmware sub revision number
Eep_Layout_Revision:		.DB	EEPROM_LAYOUT_REVISION			; EEPROM layout revision number

.IF MODE == 0
Eep_Pgm_Gov_P_Gain:			.DB	DEFAULT_PGM_MAIN_P_GAIN			; EEPROM copy of programmed governor P gain
Eep_Pgm_Gov_I_Gain:			.DB	DEFAULT_PGM_MAIN_I_GAIN			; EEPROM copy of programmed governor I gain
Eep_Pgm_Gov_Mode:			.DB	DEFAULT_PGM_MAIN_GOVERNOR_MODE	; EEPROM copy of programmed governor mode
Eep_Pgm_Low_Voltage_Lim:		.DB	DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	; EEPROM copy of programmed low voltage limit
_Eep_Pgm_Motor_Gain:		.DB	0xFF							
_Eep_Pgm_Motor_Idle:		.DB	0xFF							
Eep_Pgm_Startup_Pwr:		.DB	DEFAULT_PGM_MAIN_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:			.DB	DEFAULT_PGM_MAIN_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction:			.DB	DEFAULT_PGM_MAIN_DIRECTION		; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:			.DB	DEFAULT_PGM_MAIN_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:			.DB	0xA5							; EEPROM initialized signature low byte
Eep_Initialized_H:			.DB	0x5A							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		.DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
Eep_Main_Rearm_Start:		.DB	DEFAULT_PGM_MAIN_REARM_START		; EEPROM re-arming main enable
Eep_Pgm_Gov_Setup_Target:	.DB	DEFAULT_PGM_MAIN_GOV_SETUP_TARGET	; EEPROM main governor setup target
_Eep_Pgm_Startup_Rpm:		.DB	0xFF
_Eep_Pgm_Startup_Accel:		.DB	0xFF
_Eep_Pgm_Volt_Comp:			.DB	0xFF	
Eep_Pgm_Comm_Timing:		.DB	DEFAULT_PGM_MAIN_COMM_TIMING		; EEPROM copy of programmed commutation timing
_Eep_Pgm_Damping_Force:		.DB	0xFF							
Eep_Pgm_Gov_Range:			.DB	DEFAULT_PGM_MAIN_GOVERNOR_RANGE	; EEPROM copy of programmed governor range
_Eep_Pgm_Startup_Method:		.DB	0xFF
Eep_Pgm_Ppm_Min_Throttle:	.DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	.DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		.DB	DEFAULT_PGM_MAIN_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		.DB	DEFAULT_PGM_MAIN_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		.DB	DEFAULT_PGM_MAIN_BEACON_DELAY		; EEPROM copy of programmed beacon delay
_Eep_Pgm_Throttle_Rate:		.DB	0xFF							
Eep_Pgm_Demag_Comp:			.DB	DEFAULT_PGM_MAIN_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	.DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
_Eep_Pgm_Ppm_Center_Throttle:	.DB	0xFF							
Eep_Pgm_Main_Spoolup_Time:	.DB	DEFAULT_PGM_MAIN_SPOOLUP_TIME		; EEPROM copy of programmed main spoolup time
Eep_Pgm_Temp_Prot_Enable:	.DB	DEFAULT_PGM_ENABLE_TEMP_PROT		; EEPROM copy of programmed temperature protection enable
Eep_Pgm_Enable_Power_Prot:	.DB	DEFAULT_PGM_ENABLE_POWER_PROT		; EEPROM copy of programmed low rpm power protection enable
Eep_Pgm_Enable_Pwm_Input:	.DB	DEFAULT_PGM_ENABLE_PWM_INPUT		; EEPROM copy of programmed PWM input signal enable
_Eep_Pgm_Pwm_Dither:		.DB	0xFF	
.ENDIF

.IF MODE == 1
_Eep_Pgm_Gov_P_Gain:		.DB	0xFF							
_Eep_Pgm_Gov_I_Gain:		.DB	0xFF							
_Eep_Pgm_Gov_Mode:			.DB 	0xFF							
_Eep_Pgm_Low_Voltage_Lim:	.DB	0xFF							
Eep_Pgm_Motor_Gain:			.DB	DEFAULT_PGM_TAIL_GAIN			; EEPROM copy of programmed tail gain
Eep_Pgm_Motor_Idle:			.DB	DEFAULT_PGM_TAIL_IDLE_SPEED		; EEPROM copy of programmed tail idle speed
Eep_Pgm_Startup_Pwr:		.DB	DEFAULT_PGM_TAIL_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:			.DB	DEFAULT_PGM_TAIL_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction:			.DB	DEFAULT_PGM_TAIL_DIRECTION		; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:			.DB	DEFAULT_PGM_TAIL_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:			.DB	0x5A 						; EEPROM initialized signature low byte
Eep_Initialized_H:			.DB	0xA5							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		.DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
_Eep_Main_Rearm_Start:		.DB	0xFF							
_Eep_Pgm_Gov_Setup_Target:	.DB	0xFF							
_Eep_Pgm_Startup_Rpm:		.DB	0xFF
_Eep_Pgm_Startup_Accel:		.DB	0xFF
_Eep_Pgm_Volt_Comp:			.DB	0xFF	
Eep_Pgm_Comm_Timing:		.DB	DEFAULT_PGM_TAIL_COMM_TIMING		; EEPROM copy of programmed commutation timing
_Eep_Pgm_Damping_Force:		.DB	0xFF
_Eep_Pgm_Gov_Range:			.DB	0xFF	
_Eep_Pgm_Startup_Method:		.DB	0xFF
Eep_Pgm_Ppm_Min_Throttle:	.DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	.DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		.DB	DEFAULT_PGM_TAIL_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		.DB	DEFAULT_PGM_TAIL_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		.DB	DEFAULT_PGM_TAIL_BEACON_DELAY		; EEPROM copy of programmed beacon delay
_Eep_Pgm_Throttle_Rate:		.DB	0xFF
Eep_Pgm_Demag_Comp:			.DB	DEFAULT_PGM_TAIL_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	.DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
Eep_Pgm_Ppm_Center_Throttle:	.DB	DEFAULT_PGM_PPM_CENTER_THROTTLE	; EEPROM copy of programmed center throttle (final value is 4x+1000=1488)
_Eep_Pgm_Main_Spoolup_Time:	.DB	0xFF
Eep_Pgm_Temp_Prot_Enable:	.DB	DEFAULT_PGM_ENABLE_TEMP_PROT		; EEPROM copy of programmed temperature protection enable
Eep_Pgm_Enable_Power_Prot:	.DB	DEFAULT_PGM_ENABLE_POWER_PROT		; EEPROM copy of programmed low rpm power protection enable
Eep_Pgm_Enable_Pwm_Input:	.DB	DEFAULT_PGM_ENABLE_PWM_INPUT		; EEPROM copy of programmed PWM input signal enable
Eep_Pgm_Pwm_Dither:			.DB	DEFAULT_PGM_TAIL_PWM_DITHER		; EEPROM copy of programmed output PWM dither
.ENDIF

.IF MODE == 2
Eep_Pgm_Gov_P_Gain:			.DB	DEFAULT_PGM_MULTI_P_GAIN			; EEPROM copy of programmed closed loop P gain
Eep_Pgm_Gov_I_Gain:			.DB	DEFAULT_PGM_MULTI_I_GAIN			; EEPROM copy of programmed closed loop I gain
Eep_Pgm_Gov_Mode:			.DB	DEFAULT_PGM_MULTI_GOVERNOR_MODE	; EEPROM copy of programmed closed loop mode
_Eep_Pgm_Low_Voltage_Lim:	.DB	0xFF
Eep_Pgm_Motor_Gain:			.DB	DEFAULT_PGM_MULTI_GAIN			; EEPROM copy of programmed tail gain
_Eep_Pgm_Motor_Idle:		.DB	0xFF							; EEPROM copy of programmed tail idle speed
Eep_Pgm_Startup_Pwr:		.DB	DEFAULT_PGM_MULTI_STARTUP_PWR		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:			.DB	DEFAULT_PGM_MULTI_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction:			.DB	DEFAULT_PGM_MULTI_DIRECTION		; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:			.DB	DEFAULT_PGM_MULTI_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:			.DB	0x55							; EEPROM initialized signature low byte
Eep_Initialized_H:			.DB	0xAA							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		.DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
_Eep_Main_Rearm_Start:		.DB	0xFF							
_Eep_Pgm_Gov_Setup_Target:	.DB	0xFF							
_Eep_Pgm_Startup_Rpm:		.DB	0xFF
_Eep_Pgm_Startup_Accel:		.DB	0xFF
_Eep_Pgm_Volt_Comp:			.DB	0xFF	
Eep_Pgm_Comm_Timing:		.DB	DEFAULT_PGM_MULTI_COMM_TIMING		; EEPROM copy of programmed commutation timing
_Eep_Pgm_Damping_Force:		.DB	0xFF
_Eep_Pgm_Gov_Range:			.DB	0xFF	
_Eep_Pgm_Startup_Method:		.DB	0xFF
Eep_Pgm_Ppm_Min_Throttle:	.DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	.DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		.DB	DEFAULT_PGM_MULTI_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		.DB	DEFAULT_PGM_MULTI_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		.DB	DEFAULT_PGM_MULTI_BEACON_DELAY	; EEPROM copy of programmed beacon delay
_Eep_Pgm_Throttle_Rate:		.DB	0xFF
Eep_Pgm_Demag_Comp:			.DB	DEFAULT_PGM_MULTI_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	.DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
Eep_Pgm_Ppm_Center_Throttle:	.DB	DEFAULT_PGM_PPM_CENTER_THROTTLE	; EEPROM copy of programmed center throttle (final value is 4x+1000=1488)
_Eep_Pgm_Main_Spoolup_Time:	.DB	0xFF
Eep_Pgm_Temp_Prot_Enable:	.DB	DEFAULT_PGM_ENABLE_TEMP_PROT		; EEPROM copy of programmed temperature protection enable
Eep_Pgm_Enable_Power_Prot:	.DB	DEFAULT_PGM_ENABLE_POWER_PROT		; EEPROM copy of programmed low rpm power protection enable
Eep_Pgm_Enable_Pwm_Input:	.DB	DEFAULT_PGM_ENABLE_PWM_INPUT		; EEPROM copy of programmed PWM input signal enable
Eep_Pgm_Pwm_Dither:			.DB	DEFAULT_PGM_MULTI_PWM_DITHER		; EEPROM copy of programmed output PWM dither
.ENDIF


Eep_Dummy:				.DB	0xFF							; EEPROM address for safety reason

.ORG 0x60				
Eep_Name:					.DB	"                "				; Name tag (16 Bytes)

;**** **** **** **** ****
.CSEG				; Code segment
.ORG 0

Interrupt_Table_Definition		; ATmega interrupts

;**** **** **** **** ****

; Table definitions
GOV_GAIN_TABLE:   		.DB 	0x02, 0x03, 0x04, 0x06, 0x08, 0x0C, 0x10, 0x18, 0x20, 0x30, 0x40, 0x60, 0x80, 0 ; Padded zero for an even number
STARTUP_POWER_TABLE:  	.DB 	0x04, 0x06, 0x08, 0x0C, 0x10, 0x18, 0x20, 0x30, 0x40, 0x60, 0x80, 0xA0, 0xC0, 0 ; Padded zero for an even number
PWM_DITHER_TABLE:  		.DB 	0x00, 0x07, 0x0F, 0x1F, 0x3F, 0 ; Padded zero for an even number
.IF MODE == 0
  .IF DAMPED_MODE_ENABLE == 1
TX_PGM_PARAMS_MAIN:  	.DB 	13, 13, 4, 3, 6, 13, 5, 3, 3, 2, 2, 0 ; Padded zero for an even number
  .ENDIF
  .IF DAMPED_MODE_ENABLE == 0
TX_PGM_PARAMS_MAIN:  	.DB 	13, 13, 4, 3, 6, 13, 5, 2, 3, 2, 2, 0 ; Padded zero for an even number
  .ENDIF
.ENDIF
.IF MODE == 1
  .IF DAMPED_MODE_ENABLE == 1
TX_PGM_PARAMS_TAIL:  	.DB 	5, 5, 13, 5, 3, 5, 3, 3, 2, 0 ; Padded zero for an even number
  .ENDIF
  .IF DAMPED_MODE_ENABLE == 0
TX_PGM_PARAMS_TAIL:  	.DB 	5, 5, 13, 5, 2, 5, 3, 3, 2, 0 ; Padded zero for an even number
  .ENDIF
.ENDIF
.IF MODE == 2
  .IF DAMPED_MODE_ENABLE == 1
TX_PGM_PARAMS_MULTI:  	.DB 	13, 13, 4, 5, 13, 5, 3, 5, 3, 3, 2, 0 ; Padded zero for an even number
 .ENDIF
  .IF DAMPED_MODE_ENABLE == 0
TX_PGM_PARAMS_MULTI:  	.DB 	13, 13, 4, 5, 13, 5, 2, 5, 3, 3, 2, 0 ; Padded zero for an even number
 .ENDIF
.ENDIF



;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer2 interrupt routine
;
; Assumptions: Z register must be set to desired pwm_nfet_on label
; Requirements: I_Temp variables can NOT be used
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t2_int:	; Used for pwm control
	in	II_Sreg, SREG
	; Check if pwm is on
	sbrc	Flags0, PWM_ON				; Is pwm on?
	rjmp	t2_int_pwm_off

	; Pwm on cycle
	tst	Current_Pwm_Limited
	breq	t2_int_pwm_on_exit

t2_int_pwm_on_execute:
	ijmp							; Jump to pwm on routines. Z should be set to one of the pwm_nfet_on labels

t2_int_pwm_on_exit:
	; Set timer for coming on cycle length
	mov 	YL, Current_Pwm_Limited		; Load current pwm
	com	YL						; com is 255-x
	sec	
	sbrc	Flags2, PGM_PWM_HIGH_FREQ	; Use half the time when pwm frequency is high
	ror	YL
	Set_TCNT2 YL					; Write start point for timer
	; Set other variables
	sts	Pwm_Prev_Edge, YL			; Set timestamp
	sbr	Flags0, (1<<PWM_ON)			; Set pwm on flag
	; Exit interrupt
	out	SREG, II_Sreg
	reti


	; Pwm off cycle
t2_int_pwm_off:
	lds	YL, Current_Pwm_Lim_Dith
	sec	
	sbrc	Flags2, PGM_PWM_HIGH_FREQ	; Use half the time when pwm frequency is high
	ror	YL
	Set_TCNT2 YL					; Load new timer setting
	sts	Pwm_Prev_Edge, YL			; Set timestamp
	; Clear pwm on flag
	cbr	Flags0, (1<<PWM_ON)
	; Set full PWM (on all the time) if current PWM near max. This will give full power, but at the cost of a small "jump" in power
	lds	YL, Current_Pwm_Lim_Dith		; Load current pwm dithered
	cpi	YL, 0xFF					; Full pwm?
	brne	PC+2						; No - branch
	rjmp	t2_int_pwm_off_fullpower_exit	; Yes - exit

.IF DAMPED_MODE_ENABLE == 1
	; Do not execute damped pwm when stopped
	sbrs	Flags1, MOTOR_SPINNING
	rjmp	t2_int_pwm_off_exit_nfets_off

	; If damped operation, set pFETs on in pwm_off
	sbrc	Flags2, PGM_PWMOFF_DAMPED	; Damped operation?
	rjmp	t2_int_pwm_off_damped
.ENDIF

t2_int_pwm_off_exit_nfets_off:
	; Separate exit commands here for minimum delay
	out	SREG, II_Sreg
	All_nFETs_Off 			 		; Switch off all nfets
	reti

t2_int_pwm_off_damped:
.IF PFETON_DELAY < 128
	All_nFETs_Off 					; Switch off all nfets
.IF PFETON_DELAY != 0
	ldi	YL, PFETON_DELAY
	dec	YL
	brne	PC-1
.ENDIF
	Damping_FET_on YL				; Damping fet on
.ENDIF
.IF PFETON_DELAY >= 128				; "Negative", 1's complement
	Damping_FET_on YL				; Damping fet on
	ldi	YL, PFETON_DELAY
	com	YL
	dec	YL
	brne	PC-1
	All_nFETs_Off 					; Switch off all nfets
.ENDIF
t2_int_pwm_off_fullpower_exit:	
	sts	Pwm_Prev_Edge, Zero	; Set timestamp to zero
	out	SREG, II_Sreg
	reti


pwm_nofet:	; Dummy pwm on cycle
	rjmp	t2_int_pwm_on_exit

pwm_afet	:	; Pwm on cycle afet on 
	sbrs	Flags1, MOTOR_SPINNING
	rjmp	t2_int_pwm_on_exit
	sbrc	Flags0, DEMAG_CUT_POWER
	rjmp	t2_int_pwm_on_exit
	AnFET_on	
	rjmp	t2_int_pwm_on_exit

pwm_bfet:		; Pwm on cycle bfet on
	sbrs	Flags1, MOTOR_SPINNING
	rjmp	t2_int_pwm_on_exit
	sbrc	Flags0, DEMAG_CUT_POWER
	rjmp	t2_int_pwm_on_exit
	BnFET_on
	rjmp	t2_int_pwm_on_exit

pwm_cfet:		; Pwm on cycle cfet on
	sbrs	Flags1, MOTOR_SPINNING
	rjmp	t2_int_pwm_on_exit
	sbrc	Flags0, DEMAG_CUT_POWER
	rjmp	t2_int_pwm_on_exit
	CnFET_on
	rjmp	t2_int_pwm_on_exit

pwm_afet_damped:	
	ApFET_off
	sbrs	Flags1, MOTOR_SPINNING
	rjmp	t2_int_pwm_on_exit
	sbrc	Flags0, DEMAG_CUT_POWER
	rjmp	t2_int_pwm_on_exit
.IF NFETON_DELAY != 0
	ldi	YL, NFETON_DELAY					; Set delay
	dec	YL
	brne	PC-1
.ENDIF
	AnFET_on								; Switch nFET
	rjmp	t2_int_pwm_on_exit

pwm_bfet_damped:	
	BpFET_off
	sbrs	Flags1, MOTOR_SPINNING
	rjmp	t2_int_pwm_on_exit
	sbrc	Flags0, DEMAG_CUT_POWER
	rjmp	t2_int_pwm_on_exit
.IF NFETON_DELAY != 0
	ldi	YL, NFETON_DELAY					; Set delay
	dec	YL
	brne	PC-1
.ENDIF
	BnFET_on								; Switch nFET
	rjmp	t2_int_pwm_on_exit

pwm_cfet_damped:	
	CpFET_off
	sbrs	Flags1, MOTOR_SPINNING
	rjmp	t2_int_pwm_on_exit
	sbrc	Flags0, DEMAG_CUT_POWER
	rjmp	t2_int_pwm_on_exit
.IF NFETON_DELAY != 0
	ldi	YL, NFETON_DELAY					; Set delay
	dec	YL
	brne	PC-1
.ENDIF
	CnFET_on								; Switch nFET
	rjmp	t2_int_pwm_on_exit


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 1 output compare A interrupt
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t1oca_int:	
	in	II_Sreg, SREG
	T1oca_Int_Disable YL			; Disable timer1 OCA interrupt
	cbr	Flags0, (1<<OC1A_PENDING) 	; Flag that OC1A value is passed
	; Set up next wait
	lds	YH, Next_Wt_L		
	Read_TCNT1L YL
	add	YH, YL					; Set wait value	
	sts	Ram_Reg, YH			
	lds	YH, Next_Wt_H
	Read_TCNT1H YL
	adc	YH, YL
	Set_OCR1AH YH					; Update high byte first to avoid false output compare
	lds	YL, Ram_Reg		
	Set_OCR1AL YL
	out	SREG, II_Sreg
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer0 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t0_int:	; Happens every 128us
	in	I_Sreg, SREG
	; Disable RCP interrupts
	cbr	Flags2, (1<<RCP_INT_NESTED_ENABLED)	; Set flag default to disabled
	Get_Rcp_Int_Enable_State XL				; Get rcp interrupt state
	cpse	XL, Zero
	sbr	Flags2, (1<<RCP_INT_NESTED_ENABLED)	; Set flag to enabled
	Rcp_Int_Disable XL						; Disable rcp interrupts
	T0_Int_Disable XL						; Disable timer0 interrupts
	sei							; Enable interrupts
	; Check RC pulse timeout counter
	lds	XL, Rcp_Timeout_Cnt			; RC pulse timeout count zero?
	tst	XL
	breq	t0_int_pulses_absent		; Yes - pulses are absent

	; Decrement timeout counter (if PWM)
	sbrc	Flags2, RCP_PPM		
	rjmp	t0_int_skip_start			; If flag is set (PPM) - branch

	lds	XL, Rcp_Timeout_Cnt			; No - decrement
	dec	XL
	sts	Rcp_Timeout_Cnt, XL
	rjmp	t0_int_skip_start

t0_int_pulses_absent:
	; Timeout counter has reached zero, pulses are absent
	ldi	I_Temp1, RCP_MIN			; RCP_MIN as default
	ldi	I_Temp2, RCP_MIN			
	Read_Rcp_Int XL				; Look at value of Rcp_In
	sbrc	XL, Rcp_In				; Is it high?
	ldi	I_Temp1, RCP_MAX			; Yes - set RCP_MAX
	Rcp_Int_First XL				; Set interrupt trig to first again
	Rcp_Clear_Int_Flag XL			; Clear interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	Read_Rcp_Int XL				; Look once more at value of Rcp_In
	sbrc	XL, Rcp_In				; Is it high?
	ldi	I_Temp2, RCP_MAX			; Yes - set RCP_MAX
	
	cp	I_Temp1, I_Temp2
	brne	t0_int_pulses_absent		; Go back if they are not equal

	ldi	XL, RCP_TIMEOUT			; Load timeout count
	sbrc	Flags0, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?

	sts	Rcp_Timeout_Cnt, XL			; Yes - set timeout count to start value

	sbrc	Flags2, RCP_PPM		
	rjmp	t0_int_ppm_timeout_set		; If flag is set (PPM) - branch

	ldi	XL, RCP_TIMEOUT			; For PWM, set timeout count to start value
	sts	Rcp_Timeout_Cnt, XL

t0_int_ppm_timeout_set:
	sts	New_Rcp, I_Temp1			; Store new pulse length
	sbr	Flags2, (1<<RCP_UPDATED)	 	; Set updated flag

t0_int_skip_start:
	sbrc	Flags2, RCP_PPM		
	rjmp	t0_int_rcp_update_start		; If flag is set (PPM) - branch

	; Check RC pulse skip counter
	lds	XL, Rcp_Skip_Cnt			
	tst	XL
	breq	t0_int_skip_end			; If RC pulse skip count is zero - end skipping RC pulse detection
	
	; Decrement skip counter (only if edge counter is zero)
	lds	XL, Rcp_Skip_Cnt			; Decrement
	dec	XL
	sts	Rcp_Skip_Cnt, XL
	rjmp	t0_int_rcp_update_start

t0_int_skip_end:
	; Skip counter has reached zero, start looking for RC pulses again
	sbr	Flags2, (1<<RCP_INT_NESTED_ENABLED)	; Set flag to enabled
	Rcp_Clear_Int_Flag XL			; Clear interrupt flag
	
t0_int_rcp_update_start:
	; Process updated RC pulse
	sbrs	Flags2, RCP_UPDATED			; Is there an updated RC pulse available?
	rjmp	t0_int_current_pwm_done		; No - exit

	lds	XL, New_Rcp				; Load new pulse value
	mov	I_Temp1, XL
	sbrs	Flags0, RCP_MEAS_PWM_FREQ	; If measure RCP pwm frequency flag set - do not clear flag
	cbr	Flags2, (1<<RCP_UPDATED)	 	; Flag that pulse has been evaluated
	; Use a gain of 1.0625x for pwm input if not governor mode
	sbrc	Flags2, RCP_PPM		
	rjmp	t0_int_pwm_min_run			; If flag is set (PPM) - branch

.IF MODE == 0	; Main - do not adjust gain
	rjmp	t0_int_pwm_min_run
.ELSE

.IF MODE == 2	; Multi
	lds	XL, Pgm_Gov_Mode			; Closed loop mode?
	cpi	XL, 4
	brne	t0_int_pwm_min_run			; Yes - branch
.ENDIF

	; Limit the maximum value to avoid wrap when scaled to pwm range
	cpi	I_Temp1, 240				; 240 = (255/1.0625) Needs to be updated according to multiplication factor below
	brcs	t0_int_rcp_update_mult

	ldi	I_Temp1, 240				; Set requested pwm to max

t0_int_rcp_update_mult:	
	; Multiply by 1.0625 (optional adjustment gyro gain)
	mov	XL, I_Temp1
	swap	XL			; After this "0.0625"
	andi	XL, 0x0F
	add	I_Temp1, XL
	; Adjust tail gain
	lds	I_Temp2, Pgm_Motor_Gain		; Is gain 1?
	cpi	I_Temp2, 3
	breq	t0_int_pwm_min_run			; Yes - skip adjustment

	lsr	XL			; After this "0.5"
	lsr	XL			; After this "0.25"
	sbrc	I_Temp2, 0				; (I_Temp2 has Pgm_Motor_Gain)
	rjmp	t0_int_rcp_gain_corr		; Branch if bit 0 in gain is set

	lsr	XL			; After this "0.125"

t0_int_rcp_gain_corr:
	sbrc	I_Temp2, 2				; (I_Temp2 has Pgm_Motor_Gain)
	rjmp	t0_int_rcp_gain_pos			; Branch if bit 2 in gain is set

	sub	XL, I_Temp1				; Apply negative correction
	mov	I_Temp1, XL
	rjmp	t0_int_pwm_min_run

t0_int_rcp_gain_pos:
	add	I_Temp1, XL				; Apply positive correction
	brcc	t0_int_pwm_min_run			; Above max?

	ldi	I_Temp1, 0xFF				; Yes - limit
.ENDIF

t0_int_pwm_min_run: 
.IF MODE == 1	; Tail - limit minimum pwm
	; Limit minimum pwm
	lds	XL, Pwm_Motor_Idle			; Is requested pwm lower than minimum?
	cp	I_Temp1, XL
	brcc	t0_int_pwm_update			; No - branch

	mov	I_Temp1, XL				; Yes - limit pwm to Pwm_Motor_Idle	
.ENDIF

t0_int_pwm_update: 
	; Update requested_pwm
	sts	Requested_Pwm, I_Temp1		; Set requested pwm
.IF MODE >= 1	; Tail or multi
	; Limit pwm during start
	mov	XL, Flags1
	andi	XL, ((1<<STARTUP_PHASE)+(1<<INITIAL_RUN_PHASE))
	breq	t0_int_current_pwm_update		

	lds	XL, Requested_Pwm			; Limit pwm during start
	lds	I_Temp2, Startup_Cnt		; Add an extra power boost during start
	lsr	I_Temp2
	lsr	I_Temp2
	add	XL, I_Temp2
	sts	Requested_Pwm, XL
	brcc	PC+4

	ldi	XL, 0xFF
	sts	Requested_Pwm, XL
t0_int_current_pwm_update: 
.ENDIF
.IF MODE == 0 || MODE == 2	; Main or multi
	lds	I_Temp1, Pgm_Gov_Mode		; Governor mode?
	cpi	I_Temp1, 4
	brne	t0_int_pwm_exit			; Yes - branch
.ENDIF

	lds	XL, Requested_Pwm			; Set equal as default
	sts	Current_Pwm, XL	
t0_int_current_pwm_done:
.IF MODE >= 1	; Tail or multi
	; Set current_pwm_limited
	lds	I_Temp1, Current_Pwm		; Default not limited
	lds	XL, Pwm_Limit				; Check against limit
	cp	I_Temp1, XL			
	brcs	PC+2						; If current pwm below limit - branch
		
	mov	I_Temp1, XL				; Limit pwm

.IF MODE == 2	; Multi
	; Limit pwm for low rpms
	lds	XL, Pwm_Limit_Low_Rpm		; Check against limit
	cp	I_Temp1, XL			
	brcs	PC+2						; If current pwm below limit - branch

	mov	I_Temp1, XL				; Limit pwm
.ENDIF

	mov	Current_Pwm_Limited, I_Temp1
	; Dither
	lds	XL, Pwm_Dither_Decoded		; Load pwm dither
	tst	XL
	brne	PC+2						; If active - branch
	rjmp	t0_int_current_pwm_no_dither

	mov	I_Temp2, I_Temp1
	sub	I_Temp2, XL				; Calculate pwm minus dither value
	brcc	t0_int_current_pwm_full_dither; If pwm more than dither value, then do full dither

	mov	XL, I_Temp1				; Set dither level to current pwm
	ldi	I_Temp2, 0				; Set pwm minus dither

t0_int_current_pwm_full_dither:
	mov	I_Temp4, XL				; Store dither value in I_Temp4
	clc
	rol	XL						; Shift left once
	mov	I_Temp3, XL
	lds	XL, Random				; Load random number
	com	XL						; Invert to create proper DC bias in random code
	and	I_Temp3, XL				; And with double dither value
	add	I_Temp3, I_Temp2			; Add pwm minus dither
	brcs	t0_int_current_pwm_dither_max_excess_power	; If dither cause power above max - branch and increase excess 

	lds	XL, Pwm_Dither_Excess_Power	; Get excess power
	cp	XL, Zero					; Decrement excess power
	breq	PC+2
	dec	XL
	add	I_Temp3, XL				; Add excess power from previous cycles
	sts	Pwm_Dither_Excess_Power, XL
	brcs	t0_int_current_pwm_dither_max_power; If dither cause power above max - branch

	mov	I_Temp1, I_Temp3
	rjmp	t0_int_current_pwm_no_dither

t0_int_current_pwm_dither_max_excess_power:
	lds	XL, Pwm_Dither_Excess_Power
	cp	I_Temp4, XL 				; Limit excess power to one above in order to always reach max power
	brcs	PC+2
	inc	XL
	sts	Pwm_Dither_Excess_Power, XL

t0_int_current_pwm_dither_max_power:
	ldi	I_Temp1, 255				; Set power to max

t0_int_current_pwm_no_dither:
	sts	Current_Pwm_Lim_Dith, I_Temp1
.ENDIF
t0_int_pwm_exit:	
	; Set demag enabled if pwm is above limit
	mov	XL, Current_Pwm_Limited		
	cpi	XL, 0x40					; Set if above 25%
	brcs	PC+2

	sbr	Flags0, (1<<DEMAG_ENABLED)

	; Increment counter and check if high "interrupt" 
	lds	XL, Timer0_Int_Cnt
	inc	XL
	sts	Timer0_Int_Cnt, XL
	breq	t0h_int

	cli							; Disable interrupts
	T0_Int_Enable XL				; Enable timer0 interrupts
	sbrs	Flags2, RCP_INT_NESTED_ENABLED; Restore rcp interrupt state
	rjmp	t0_int_pwm_ret

	Rcp_Int_Enable XL					

t0_int_pwm_ret:	
	out	SREG, I_Sreg
	reti

t0h_int:
	; Every 256th interrupt (happens every 32ms)
	ldi	I_Temp1, GOV_SPOOLRATE		; Load governor spool rate
	; Check RC pulse timeout counter (used here for PPM only)
	lds	I_Temp2, Rcp_Timeout_Cnt		; RC pulse timeout count zero?
	tst	I_Temp2
	breq	t0h_int_rcp_stop_check		; Yes - do not decrement

	; Decrement timeout counter (if PPM)
	sbrs	Flags2, RCP_PPM		
	rjmp	t0h_int_rcp_stop_check		; If flag is not set (PWM) - branch

	dec	I_Temp2					; No flag set (PPM) - decrement
	sts	Rcp_Timeout_Cnt, I_Temp2

t0h_int_rcp_stop_check:
	; Check RC pulse against stop value
	lds	XL, New_Rcp				; Load new pulse value
	cpi	XL, RCP_STOP				; Check if pulse is below stop value
	brcs	t0h_int_rcp_stop
	
	; RC pulse higher than stop value, reset stop counter
	sts	Rcp_Stop_Cnt, Zero			; Reset rcp stop counter
	rjmp	t0h_int_rcp_gov_pwm

t0h_int_rcp_stop:	
	; RC pulse less than stop value
	sts	Auto_Bailout_Armed, Zero		; Disarm bailout
	sts	Spoolup_Limit_Cnt, Zero
	lds	XL, Rcp_Stop_Cnt			; Increment stop counter
	subi	XL, 0xFF					; Subtract minus one
	sts	Rcp_Stop_Cnt, XL
	brcs	t0h_int_rcp_gov_pwm			; Branch if counter has not wrapped

	ldi	XL, 0xFF					; Set stop counter to max
	sts	Rcp_Stop_Cnt, XL		

t0h_int_rcp_gov_pwm:
.IF MODE == 0	; Main
	; Update governor variables
	lds	I_Temp4, Requested_Pwm			; Load requested pwm
	lds	I_Temp2, Pgm_Gov_Mode			; Governor target by arm mode?
	cpi	I_Temp2, 2
	brne	t0h_int_rcp_gov_by_setup			; No - branch

	sbrs	Flags0, GOV_ACTIVE				; Is governor active?
	breq	t0h_int_rcp_gov_by_tx			; No - branch (this ensures soft spoolup by tx)

	ldi	XL, 50
	cp	I_Temp4, XL					; Is requested pwm below 20%? (Requested_Pwm in I_Temp4)
	brcs	t0h_int_rcp_gov_by_tx			; Yes - branch (this enables a soft spooldown)

	lds	XL, Gov_Arm_Target				; Yes - load arm target
	sts	Requested_Pwm, XL

t0h_int_rcp_gov_by_setup:
	cpi	I_Temp2, 3					; Governor target by setup mode? (Pgm_Gov_Mode in I_Temp2)
	brne	t0h_int_rcp_gov_by_tx			; No - branch

	sbrs	Flags0, GOV_ACTIVE				; Is governor active?
	breq	t0h_int_rcp_gov_by_tx			; No - branch (this ensures soft spoolup by tx)

	ldi	XL, 50
	cp	I_Temp4, XL					; Is requested pwm below 20%? (Requested_Pwm in I_Temp4)
	brcs	t0h_int_rcp_gov_by_tx			; Yes - branch (this enables a soft spooldown)

	lds	XL, Pgm_Gov_Setup_Target			; Gov by setup - load setup target
	sts	Requested_Pwm, XL

t0h_int_rcp_gov_by_tx:
	lds	I_Temp2, Governor_Req_Pwm
	cp	I_Temp2, I_Temp4				; Is governor requested pwm equal to requested pwm? (Requested_Pwm in I_Temp4)
	breq	t0h_int_rcp_gov_pwm_done			; Yes - branch

	brcs	t0h_int_rcp_gov_pwm_inc			; No - if lower, then increment

	dec	I_Temp2						; No - if higher, then decrement
	rjmp	t0h_int_rcp_gov_pwm_done

t0h_int_rcp_gov_pwm_inc:
	inc	I_Temp2						; Increment

t0h_int_rcp_gov_pwm_done:
	sts	Governor_Req_Pwm, I_Temp2		; Store governor requested pwm
	dec	I_Temp1						; Decrement spoolrate variable
	brne	t0h_int_rcp_gov_pwm				; If not number of steps processed - go back

	lds	I_Temp2, Spoolup_Limit_Cnt		; Load spoolup count
	inc	I_Temp2						; Increment
	brne	PC+2							; Wrapped?

	dec	I_Temp2						; Yes - decrement

	sts	Spoolup_Limit_Cnt, I_Temp2
	lds	XL, Spoolup_Limit_Skip			; Load skip count
	dec	XL							; Decrement		
	sts	Spoolup_Limit_Skip, XL			; Store skip count
	breq	PC+2
	rjmp	t0h_int_exit					; Jump if skip count is not reached

	ldi	XL, 1						; Reset skip count. Default is fast spoolup
	sts	Spoolup_Limit_Skip, XL			
	ldi	I_Temp1, 5					; Default fast increase

	lds	XL, Main_Spoolup_Time_3x			; No spoolup until 3*N*32ms (Spoolup_Limit_Cnt in I_Temp2)
	cp	I_Temp2, XL		
	brcs	t0h_int_exit

	lds	XL, Main_Spoolup_Time_10x		; Slow spoolup until 10*N*32ms (Spoolup_Limit_Cnt in I_Temp2)
	cp	I_Temp2, XL		
	brcc	t0h_int_rcp_limit_middle_ramp

	ldi	I_Temp1, 1					; Slow initial spoolup
	ldi	XL, 3
	sts	Spoolup_Limit_Skip, XL
	rjmp	t0h_int_rcp_set_limit

t0h_int_rcp_limit_middle_ramp:
	lds	XL, Main_Spoolup_Time_15x		; Faster spoolup until 15*N*32ms (Spoolup_Limit_Cnt in I_Temp2)
	cp	I_Temp2, XL		
	brcc	t0h_int_rcp_set_limit

	ldi	I_Temp1, 1					; Faster middle spoolup
	sts	Spoolup_Limit_Skip, I_Temp1

t0h_int_rcp_set_limit:
	; Do not increment spoolup limit if higher pwm is not requested, unless governor is active
	lds	I_Temp6, Pwm_Limit_Spoolup		; Load pwm limit spoolup
	lds	I_Temp5, Current_Pwm			; Load current pwm
	cp	I_Temp6, I_Temp5
	brcs	t0h_int_rcp_inc_limit			; If Current_Pwm is larger than Pwm_Limit_Spoolup - branch

	lds	XL, Pgm_Gov_Mode				; Governor mode?
	cpi	XL, 4
	breq	t0h_int_rcp_bailout_arm			; No - branch

	sbrc	Flags0, GOV_ACTIVE				; Is governor active?
	rjmp	t0h_int_rcp_inc_limit			; Yes - branch

	sts	Pwm_Limit_Spoolup, I_Temp5		; Set limit to what current pwm is
	inc	I_Temp2						; Check if spoolup limit count is 255
	breq	PC+3							; If it is, then this is a "bailout" ramp

	lds	XL, Main_Spoolup_Time_3x			; Stay in an early part of the spoolup sequence (unless "bailout" ramp)

	sts	Spoolup_Limit_Cnt, XL
	ldi	XL, 1						; Set skip count
	sts	Spoolup_Limit_Skip, XL
	ldi	XL, 60						; Set governor requested speed to ensure that it requests higher speed
	sts	Governor_Req_Pwm, XL
									; 20=Fail on jerk when governor activates
									; 30=Ok
									; 100=Fail on small governor settling overshoot on low headspeeds
									; 200=Fail on governor settling overshoot
	rjmp	t0h_int_exit					; Exit

t0h_int_rcp_inc_limit:
	lds	XL, Pwm_Limit_Spoolup			; Increment spoolup pwm
	add	XL, I_Temp1
	brcc	t0h_int_rcp_no_limit			; If below 255 - branch
	
	ldi	I_Temp2, 0xFF
	sts	Pwm_Limit_Spoolup, I_Temp2
	rjmp	t0h_int_rcp_bailout_arm

t0h_int_rcp_no_limit:
	sts	Pwm_Limit_Spoolup, XL
t0h_int_rcp_bailout_arm:
	lds	XL, Pwm_Limit_Spoolup
	cpi	XL, 0xFF
	brne	t0h_int_exit

	ldi	XL, 0xFF
	sts	Auto_Bailout_Armed, XL			; Arm bailout
	sts	Spoolup_Limit_Cnt, XL

.ENDIF
t0h_int_exit:
	cli							; Disable interrupts
	T0_Int_Enable XL				; Enable timer0 interrupts
	sbrs	Flags2, RCP_INT_NESTED_ENABLED; Restore rcp interrupt state
	rjmp	t0h_int_pwm_ret

	Rcp_Int_Enable XL					

t0h_int_pwm_ret:	
	out	SREG, I_Sreg
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; RC pulse processing interrupt routine
;
; No assumptions
; Can come from int0 or icp
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
rcp_int:	; Used for RC pulse timing
	in	I_Sreg, SREG
	; Get the timer counter values
	Get_Rcp_Capture_Values I_Temp1, I_Temp2
	; Disable RCP interrupts
	cbr	Flags2, (1<<RCP_INT_NESTED_ENABLED)	; Set flag default to disabled
	Get_Rcp_Int_Enable_State XL				; Get rcp interrupt state
	cpse	XL, Zero
	sbr	Flags2, (1<<RCP_INT_NESTED_ENABLED)	; Set flag to enabled
	Rcp_Int_Disable XL						; Disable rcp interrupts
	T0_Int_Disable XL						; Disable timer0 interrupts
	sei							; Enable interrupts
	; Check which edge it is
	sbrc	Flags2, RCP_EDGE_NO			; Is it a first edge trig?
	rjmp rcp_int_second_meas_pwm_freq	; No - branch to second

	Rcp_Int_Second	XL				; Yes - set second edge trig
	sbr	Flags2, (1<<RCP_EDGE_NO)		; Set second edge flag
	; Read RC signal level
	Read_Rcp_Int XL
	; Test RC signal level
	sbrs	XL, Rcp_In				; Is it high?
	rjmp	rcp_int_fail_minimum		; No - jump to fail minimum

	; RC pulse was high, store RC pulse start timestamp
	sts	Rcp_Prev_Edge_L, I_Temp1
	sts	Rcp_Prev_Edge_H, I_Temp2
	rjmp	rcp_int_exit				; Exit

rcp_int_fail_minimum:
	; Prepare for next interrupt
	Rcp_Int_First XL				; Set interrupt trig to first again
	Rcp_Clear_Int_Flag XL			; Clear interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	sbrs	Flags2, RCP_PPM		
	rjmp	PC+2						; If flag is not set (PWM) - branch

	rjmp	rcp_int_set_timeout			; If no flag is set (PPM) - ignore trig as noise

	ldi	I_Temp1, RCP_MIN			; Set RC pulse value to minimum
	Read_Rcp_Int XL				; Test RC signal level again
	sbrc	XL, Rcp_In				; Is it high?
	rjmp	rcp_int_set_timeout			; Yes - set new timeout and exit

	sts	New_Rcp, I_Temp1			; Store new pulse length
	rjmp	rcp_int_limited			; Set new RC pulse, new timeout and exit

rcp_int_second_meas_pwm_freq:
	; Prepare for next interrupt
	Rcp_Int_First XL				; Set first edge trig
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	; Check if pwm frequency shall be measured
	sbrs	Flags0, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp	rcp_int_fall				; No - skip measurements

	; Set second edge trig only during pwm frequency measurement
	Rcp_Int_Second XL				; Set second edge trig
	Rcp_Clear_Int_Flag XL 			; Clear interrupt flag
	sbr	Flags2, (1<<RCP_EDGE_NO)		; Set second edge flag
	; Store edge data to RAM
	sts	Rcp_Edge_L, I_Temp1
	sts	Rcp_Edge_H, I_Temp2
	; Calculate pwm frequency
	lds	I_Temp3, Rcp_PrePrev_Edge_L
	sub	I_Temp1, I_Temp3
	lds	I_Temp4, Rcp_PrePrev_Edge_H
	sbc	I_Temp2, I_Temp4
	clr	I_Temp4
	ldi	XL, 8					; Set default period tolerance requirement (MSB)
	mov	I_Temp7, XL
	mov	I_Temp3, Zero				; (LSB)
	; Check if pulse is too short
	cpi	I_Temp1, low(140)			; If pulse below 70us, not accepted
	cpc	I_Temp2, Zero
	brcc	rcp_int_check_12kHz

	sts	Rcp_Period_Diff_Accepted, Zero	; Set not accepted 
	rjmp	rcp_int_store_data

rcp_int_check_12kHz:
	; Check if pwm frequency is 12kHz
	cpi	I_Temp1, low(200)			; If below 100us, 12kHz pwm is assumed
	cpc	I_Temp2, Zero
	brcc	rcp_int_check_8kHz

	ldi	XL, (1<<RCP_PWM_FREQ_12KHZ)
	mov	I_Temp4, XL
	ldi	XL, 10					; Set period tolerance requirement (LSB)
	mov	I_Temp3, XL
	rjmp	rcp_int_restore_edge_set_msb

rcp_int_check_8kHz:
	; Check if pwm frequency is 8kHz
	cpi	I_Temp1, low(360)			; If below 180us, 8kHz pwm is assumed
	ldi	XL, high(360)
	cpc	I_Temp2, XL
	brcc	rcp_int_check_4kHz

	ldi	XL, (1<<RCP_PWM_FREQ_8KHZ)
	mov	I_Temp4, XL
	ldi	XL, 15					; Set period tolerance requirement (LSB)
	mov	I_Temp3, XL
	rjmp	rcp_int_restore_edge_set_msb

rcp_int_check_4kHz:
	; Check if pwm frequency is 4kHz
	cpi	I_Temp1, low(720)			; If below 360us, 4kHz pwm is assumed
	ldi	XL, high(720)
	cpc	I_Temp2, XL
	brcc	rcp_int_check_2kHz

	ldi	XL, (1<<RCP_PWM_FREQ_4KHZ)
	mov	I_Temp4, XL
	ldi	XL, 30					; Set period tolerance requirement (LSB)
	mov	I_Temp3, XL
	rjmp	rcp_int_restore_edge_set_msb

rcp_int_check_2kHz:
	; Check if pwm frequency is 2kHz
	cpi	I_Temp1, low(1440)			; If below 720us, 2kHz pwm is assumed
	ldi	XL, high(1440)
	cpc	I_Temp2, XL
	brcc	rcp_int_check_1kHz

	ldi	XL, (1<<RCP_PWM_FREQ_2KHZ)
	mov	I_Temp4, XL
	ldi	XL, 60					; Set period tolerance requirement (LSB)
	mov	I_Temp3, XL
	rjmp	rcp_int_restore_edge_set_msb

rcp_int_check_1kHz:
	; Check if pwm frequency is 1kHz
	cpi	I_Temp1, low(2200)			; If below 1100us, 1kHz pwm is assumed
	ldi	XL, high(2200)
	cpc	I_Temp2, XL
	brcc	rcp_int_restore_edge

	ldi	XL, (1<<RCP_PWM_FREQ_1KHZ)
	mov	I_Temp4, XL
	ldi	XL, 120					; Set period tolerance requirement (LSB)
	mov	I_Temp3, XL

rcp_int_restore_edge_set_msb:
	mov	I_Temp7, Zero				; Set period tolerance requirement (MSB)
rcp_int_restore_edge:
	; Calculate difference between this period and previous period
	mov	I_Temp5, I_Temp1
	lds	XL, Rcp_Prev_Period_L
	sub	I_Temp5, XL
	mov	I_Temp6, I_Temp2
	lds	XL, Rcp_Prev_Period_H
	sbc	I_Temp6, XL
	; Make positive
	tst	I_Temp6
	brpl	rcp_int_check_diff

	ldi	XL, 0xFF					; Change sign - invert and subtract minus one
	com	I_Temp5
	com	I_Temp6
	sub	I_Temp5, XL
	sbc	I_Temp6, XL

rcp_int_check_diff:
	; Check difference
	sts	Rcp_Period_Diff_Accepted, Zero	; Set not accepted as default
	cp	I_Temp5, I_Temp3				; Check difference
	cpc	I_Temp6, I_Temp7			
	brcc	rcp_int_store_data

	ldi	XL, 1						; Set accepted
	sts	Rcp_Period_Diff_Accepted, XL		

rcp_int_store_data:
	; Store previous period
	sts	Rcp_Prev_Period_L, I_Temp1
	sts	Rcp_Prev_Period_H, I_Temp2
	; Restore edge data from RAM
	lds	I_Temp1, Rcp_Edge_L
	lds	I_Temp2, Rcp_Edge_H
	; Store pre previous edge
	sts	Rcp_PrePrev_Edge_L, I_Temp1
	sts	Rcp_PrePrev_Edge_H, I_Temp2
	ldi	Temp1, RCP_VALIDATE
	rjmp	rcp_int_limited

rcp_int_fall:
	; RC pulse edge was second, calculate new pulse length
	lds	XL, Rcp_Prev_Edge_L
	sub	I_Temp1, XL
	lds	XL, Rcp_Prev_Edge_H
	sbc	I_Temp2, XL
	sbrc	Flags3, RCP_PWM_FREQ_12KHZ		; Is RC input pwm frequency 12kHz?
	rjmp	rcp_int_pwm_divide_done			; Yes - branch forward

	sbrc	Flags3, RCP_PWM_FREQ_8KHZ		; Is RC input pwm frequency 8kHz?
	rjmp	rcp_int_pwm_divide_done			; Yes - branch forward

	sbrc	Flags3, RCP_PWM_FREQ_4KHZ		; Is RC input pwm frequency 4kHz?
	rjmp	rcp_int_pwm_divide				; Yes - branch forward

	sbrs	Flags2, RCP_PPM_ONESHOT125
	rjmp	rcp_int_fall_not_oneshot

	mov	I_Temp6, I_Temp2				; Oneshot125 - move to I_Temp5/6
	mov	I_Temp5, I_Temp1
	rjmp	rcp_int_fall_check_range

rcp_int_fall_not_oneshot:
	lsr	I_Temp2						; No - 2kHz. Divide by 2
	ror	I_Temp1

	sbrc	Flags3, RCP_PWM_FREQ_2KHZ		; Is RC input pwm frequency 2kHz?
	rjmp	rcp_int_pwm_divide				; Yes - branch forward

	lsr	I_Temp2						; No - 1kHz. Divide by 2 again
	ror	I_Temp1

	sbrc	Flags3, RCP_PWM_FREQ_1KHZ		; Is RC input pwm frequency 1kHz?
	rjmp	rcp_int_pwm_divide				; Yes - branch forward

	mov	I_Temp6, I_Temp2				; No - PPM. Divide by 2 (to bring range to 256) and move to I_Temp5/6
	mov	I_Temp5, I_Temp1
	lsr	I_Temp6
	ror	I_Temp5
rcp_int_fall_check_range:
	; Skip range limitation if pwm frequency measurement
	sbrc	Flags0, RCP_MEAS_PWM_FREQ
	rjmp	rcp_int_ppm_check_full_range 		

	; Check if 2160us or above (in order to ignore false pulses)
	mov	XL, I_Temp5					; Is pulse 2160us or higher?
	subi	XL, 28
	mov	XL, I_Temp6
	sbci	XL, 2
	brcs	PC+2

	rjmp	pca_int_ppm_outside_range		; Yes - ignore pulse

	; Check if below 800us (in order to ignore false pulses)
	tst	I_Temp6
	brne	rcp_int_ppm_check_full_range

	mov	XL, I_Temp5					; Is pulse below 800us?
	subi	XL, 200
	brcc	rcp_int_ppm_check_full_range		; No - branch

pca_int_ppm_outside_range:
	lds	XL, Rcp_Outside_Range_Cnt
	inc	XL
	sts	Rcp_Outside_Range_Cnt, XL
	cpi	XL, 10						; Allow a given number of outside pulses
	brcc	PC+2
	rjmp	rcp_int_set_timeout				; If below limit - ignore pulse

	sts	New_Rcp, Zero					; Set pulse length to zero
	sbr	Flags2, (1<<RCP_UPDATED)	 		; Set updated flag
	rjmp	rcp_int_set_timeout			

rcp_int_ppm_check_full_range:
	; Decrement outside range counter
	lds	XL, Rcp_Outside_Range_Cnt
	tst	XL
	breq	PC+4

	dec	XL
	sts	Rcp_Outside_Range_Cnt, XL

	; Calculate "1000us" plus throttle minimum
	ldi	XL, 0						; Set 1000us as default minimum
	mov	I_Temp7, XL
	sbrc	Flags3, FULL_THROTTLE_RANGE		; Check if full range is chosen
	rjmp	rcp_int_ppm_calculate			; Yes - branch

	lds	I_Temp7, Pgm_Ppm_Min_Throttle		; Min throttle value is in 4us units
.IF MODE >= 1	; Tail or multi
	lds	I_Temp2, Pgm_Direction			; Check if bidirectional operation (store in I_Temp2)
	cpi	I_Temp2, 3
	brne	PC+3							; No - branch

	lds	I_Temp7, Pgm_Ppm_Center_Throttle	; Center throttle value is in 4us units

.ENDIF
rcp_int_ppm_calculate:
	ldi	XL, 250						; Add 1000us to minimum
	add	I_Temp7, XL
	mov	I_Temp8, Zero
	adc	I_Temp8, Zero
	sub	I_Temp5, I_Temp7				; Subtract minimum
	sbc	I_Temp6, I_Temp8
	in	I_Temp1, SREG
	andi	I_Temp1, (1<<SREG_C)	
.IF MODE >= 1	; Tail or multi
	cpi	I_Temp2, 3					; Check if bidirectional operation
	brne	rcp_int_ppm_bidir_dir_set		; No - branch

	tst	I_Temp1
	breq	rcp_int_ppm_bidir_fwd			; If result is positive - branch				

rcp_int_ppm_bidir_rev: 
	sbrc	Flags3, PGM_DIR_REV
	rjmp	rcp_int_ppm_bidir_dir_set		; If same direction - branch

	cli								; Direction change, turn off all fets
	sbr	Flags3, (1<<PGM_DIR_REV)
	rjmp	rcp_int_ppm_bidir_dir_change

rcp_int_ppm_bidir_fwd:
	sbrs	Flags3, PGM_DIR_REV
	rjmp	rcp_int_ppm_bidir_dir_set		; If same direction - branch

	cli								; Direction change, turn off all fets
	cbr	Flags3, (1<<PGM_DIR_REV)
rcp_int_ppm_bidir_dir_change:
	sbrc	Flags0, DIR_CHANGE_BRAKE
	rjmp	rcp_int_ppm_bidir_dir_change_powered_off

	xcall switch_power_off
	sts	Brake_Cnt, Zero

rcp_int_ppm_bidir_dir_change_powered_off:
	sbr	Flags0, (1<<DIR_CHANGE_BRAKE)		; Set brake flag

rcp_int_ppm_bidir_dir_set:
	sei
.ENDIF
	tst	I_Temp1
	breq	rcp_int_ppm_neg_checked			; If result is positive - branch

.IF MODE >= 1	; Tail or multi
	cpi	I_Temp2, 3					; Check if bidirectional operation
	brne	rcp_int_ppm_unidir_neg			; No - branch

	ldi	XL, 0xFF						; Change sign - invert and subtract minus one
	com	I_Temp5
	com	I_Temp6
	sub	I_Temp5, XL
	sbc	I_Temp6, XL
	rjmp	rcp_int_ppm_neg_checked

rcp_int_ppm_unidir_neg:
.ENDIF
	ldi	I_Temp1, RCP_MIN				; Yes - set to minimum
	ldi	I_Temp2, 0
	rjmp	rcp_int_pwm_divide_done

rcp_int_ppm_neg_checked:
.IF MODE >= 1	; Tail or multi
	cpi	I_Temp2, 3					; Check if bidirectional operation
	brne	rcp_int_ppm_bidir_done			; No - branch

	lsl	I_Temp5						; Multiply value by 2
	rol	I_Temp6
	ldi	XL, 10						; Subtract deadband
	sub	I_Temp5, XL					
	sbc	I_Temp6, Zero
	brcc	rcp_int_ppm_bidir_done

	ldi	XL, RCP_MIN
	mov	I_Temp5, XL
	mov	I_Temp6, Zero

rcp_int_ppm_bidir_done:
.ENDIF
	ldi	XL, RCP_MAX					; Check that RC pulse is within legal range (max 255)
	cp	I_Temp5, XL
	cpc	I_Temp6, Zero
	brcs	rcp_int_ppm_max_checked

	ldi	I_Temp1, RCP_MAX
	ldi	I_Temp2, 0
	rjmp	rcp_int_pwm_divide_done

rcp_int_ppm_max_checked:
	lds	I_Temp8, Ppm_Throttle_Gain		; Multiply throttle value by gain
	mul	I_Temp5, I_Temp8
	mov	I_Temp1, Mul_Res_H				; Transfer result
	lsl	Mul_Res_L						; Multiply result by 2 (unity gain is 128)
	rol	I_Temp1
	ldi	I_Temp2, 0
	brcs	rcp_int_ppm_limit_after_mult
	
	rjmp	rcp_int_limited			

rcp_int_ppm_limit_after_mult:
	ldi	I_Temp1, RCP_MAX
	ldi	I_Temp2, 0
	rjmp	rcp_int_limited			

rcp_int_pwm_divide:
	lsr	I_Temp2						; Divide by 2
	ror	I_Temp1

rcp_int_pwm_divide_done:
	sbrs	Flags3, RCP_PWM_FREQ_12KHZ		; Is RC input pwm frequency 12kHz?
	rjmp	rcp_int_check_legal_range	

	tst	I_Temp2						; Yes - check that value is not more than 255
	breq	PC+2

	ldi	I_Temp1, RCP_MAX

	mov	XL, I_Temp1					; Multiply by 1.5				
	lsr	XL
	add	I_Temp1, XL
	adc	I_Temp2, Zero

rcp_int_check_legal_range:
	; Check that RC pulse is within legal range
	cpi	I_Temp1, RCP_MAX
	cpc	I_Temp2, Zero
	brcs	rcp_int_limited

	ldi	I_Temp1, RCP_MAX

rcp_int_limited:
	; RC pulse value accepted
	sts	New_Rcp, I_Temp1			; Store new pulse length
	sbr	Flags2, (1<<RCP_UPDATED)	 	; Set updated flag
	sbrs	Flags0, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp	rcp_int_set_timeout			; No - skip measurements

	ldi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	com	XL
	and	XL, Flags3				; Clear all pwm frequency flags
	or	XL, I_Temp4				; Store pwm frequency value in flags
	mov	Flags3, XL
	cbr	Flags2, (1<<RCP_PPM)		; Default, flag is not set (PWM)	
	tst	I_Temp4					; Check if all flags are cleared
	brne	rcp_int_set_timeout

	sbr	Flags2, (1<<RCP_PPM)		; Flag is set (PPM)	

rcp_int_set_timeout:
	ldi	XL, RCP_TIMEOUT			; Set timeout count to start value
	sts	Rcp_Timeout_Cnt, XL
	sbrs	Flags2, RCP_PPM		
	rjmp	rcp_int_ppm_timeout_set		; If flag is not set (PWM) - branch

	ldi	XL, RCP_TIMEOUT_PPM			; No flag set means PPM. Set timeout count
	sts	Rcp_Timeout_Cnt, XL

rcp_int_ppm_timeout_set:
	sbrc	Flags0, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp rcp_int_exit				; Yes - exit

	sbrc	Flags2, RCP_PPM		
	rjmp	rcp_int_exit				; If flag is set (PPM) - branch

	cbr	Flags2, (1<<RCP_INT_NESTED_ENABLED)	; Set flag to disabled

rcp_int_exit:	; Exit interrupt routine	
	sbrc	Flags2, RCP_PPM			; If flag is set (PPM) - branch
	rjmp	PC+4						

	ldi	XL, RCP_SKIP_RATE			; Load number of skips
	sts	Rcp_Skip_Cnt, XL

	cli							; Disable interrupts
	T0_Int_Enable XL				; Enable timer0 interrupts
	sbrs	Flags2, RCP_INT_NESTED_ENABLED; Restore rcp interrupt state
	rjmp	rcp_int_ret

	Rcp_Int_Enable XL					

rcp_int_ret:	
	out	SREG, I_Sreg
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait xms ~(x*4*250)  (Different entry points)	
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait1ms:	
	ldi	Temp2, 1
	rjmp	waitxms_o

wait3ms:	
	ldi	Temp2, 3
	rjmp	waitxms_o

wait10ms:	
	ldi	Temp2, 10
	rjmp	waitxms_o

wait30ms:	
	ldi	Temp2, 30
	rjmp	waitxms_o

wait100ms:	
	ldi	Temp2, 100
	rjmp	waitxms_o

wait200ms:	
	ldi	Temp2, 200
	rjmp	waitxms_o

waitxms_o:	; Outer loop
	ldi	Temp1, 21
waitxms_m:	; Middle loop
	clr	XH
	dec	XH
	brne	PC-1		; Inner loop
	dec	Temp1
	brne	waitxms_m
	dec	Temp2
	brne	waitxms_o
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Beeper routines (4 different entry points) 
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
beep_f1:	; Entry point 1, load beeper frequency 1 settings
	ldi	Temp3, 58		; Off wait loop length
	ldi	Temp4, 120	; Number of beep pulses
	rjmp	beep

beep_f2:	; Entry point 2, load beeper frequency 2 settings
	ldi	Temp3, 48
	ldi	Temp4, 140
	rjmp	beep

beep_f3:	; Entry point 3, load beeper frequency 3 settings
	ldi	Temp3, 42
	ldi	Temp4, 180
	rjmp	beep

beep_f4:	; Entry point 4, load beeper frequency 4 settings
	ldi	Temp3, 37
	ldi	Temp4, 200
	rjmp	beep

beep:	; Beep loop start
	ldi	Temp2, 2					; Must be an even number (or direction will change)
beep_onoff:
	sbrc	Flags3, PGM_DIR_REV			; Toggle between using A fet and C fet
	cbr	Flags3, (1<<PGM_DIR_REV)
	sbrs	Flags3, PGM_DIR_REV			; Toggle between using A fet and C fet
	sbr	Flags3, (1<<PGM_DIR_REV)
	clr	XH
	BpFET_off			; BpFET off
	dec	XH			; Allow some time after pfet is turned off
	brne	PC-1	
	BnFET_on			; BnFET on (in order to charge the driver of the BpFET)
	dec	XH			; Let the nfet be turned on a while
	brne	PC-1	
	BnFET_off			; BnFET off again
	dec	XH			; Allow some time after nfet is turned off
	brne	PC-1	
	BpFET_on			; BpFET on
	dec	XH			; Allow some time after pfet is turned on
	brne	PC-1	
	; Turn on nfet
	AnFET_on			; AnFET on
	lds	XH, Beep_Strength
	dec	XH			
	brne	PC-1	
	; Turn off nfet
	AnFET_off			; AnFET off
	ldi	XH, 135		; 25µs off
	dec	XH			
	brne	PC-1	
	dec	Temp2
	brne	beep_onoff
	; Copy variable
	mov	Temp1, Temp3
beep_off:		; Fets off loop
	mov	XH, Temp3
	dec	XH			
	brne	PC-1	
	dec	Temp1
	brne	beep_off
	dec	Temp4
	brne	beep
	BpFET_off			; BpFET off
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Division 8bit unsigned by 8bit unsigned
;
; Dividend shall be in Temp1, divisor in Temp2
; Result will be in Temp1, remainder will be in Temp3
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
div_u8_by_u8:	
	sub	Temp3, Temp3		; Clear remainder and carry
	ldi	Temp4, 9			; Initialize loop counter
div_u8_by_u8_1:
	rol	Temp1			; Shift left dividend
	dec	Temp4			; Decrement counter
	brne	div_u8_by_u8_2		; If done
	ret					; Return
div_u8_by_u8_2:	
	rol	Temp3			; Shift dividend into remainder
	sub	Temp3, Temp2		; Remainder = remainder - divisor
	brcc	div_u8_by_u8_3		; If result negative
	add	Temp3, Temp2		; Restore remainder
	clc					; Clear carry to be shifted into result
	rjmp	div_u8_by_u8_1		; Else
div_u8_by_u8_3:	
	sec					; Set carry to be shifted into result
	rjmp	div_u8_by_u8_1


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Division 16bit unsigned by 16bit unsigned
;
; Dividend shall be in Temp2/Temp1, divisor in Temp4/Temp3
; Result will be in Temp2/Temp1
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
div_u16_by_u16:	
	mov	Temp5, Zero
	mov	Temp6, Zero
	ldi	XH, 0
	clc
div_u16_by_u16_div1:
	inc	XH      			; Increment counter for each left shift
	rol	Temp3   			; Shift left the divisor
	rol	Temp4   	
	brcc	div_u16_by_u16_div1	; Repeat until carry flag is set from high-byte
div_u16_by_u16_div2:        
	ror	Temp4   			; Shift right the divisor
	ror	Temp3   
	clc      
 	mov	Temp8, Temp2  		; Make a safe copy of the dividend
 	mov	Temp7, Temp1  		
	sbc	Temp1, Temp3  		; Dividend - shifted divisor = result bit (no factor, only 0 or 1)
	sbc	Temp2, Temp4  		; Subtract high-byte of divisor (all together 16-bit substraction)
	brcc	div_u16_by_u16_div3	; If carry flag is NOT set, result is 1
  	mov	Temp2, Temp8  		; Otherwise result is 0, save copy of divisor to undo subtraction
 	mov	Temp1, Temp7  		
div_u16_by_u16_div3:
	brcc	PC+3     			; Invert carry, so it can be directly copied into result
	clc
	rjmp	PC+2
	sec
	rol	Temp5    			; Shift carry flag into temporary result
	rol	Temp6
	dec	XH
	brne	div_u16_by_u16_div2 ;Now count backwards and repeat until "B" is zero
  	mov	Temp2, Temp6  		; Move result to Temp2/Temp1
 	mov	Temp1, Temp5  		
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
	mov	Temp4, Zero		; Set default sign in Temp4
	tst	Temp2			; Test sign
	brpl	mult_s16_by_u8_positive	

	dec	Temp4			; Set sign to 0xFF
	com	Temp1			; Change sign - invert and subtract minus one
	com	Temp2
	sub	Temp1, Temp4
	sbc	Temp2, Temp4

mult_s16_by_u8_positive:
	cli					; Disable interrupts in order to avoid interference with mul ops in interrupt routines
	mul	Temp1, Temp3		; Multiply LSB with multiplicator
	mov	Temp6, Mul_Res_H	; Place MSB in Temp6
	mov	Temp1, Mul_Res_L	; Place LSB in Temp1 (result)
	mul	Temp2, Temp3		; Multiply MSB with multiplicator
	mov	Temp8, Mul_Res_H	; Place in Temp8/7
	mov	Temp7, Mul_Res_L	
	sei
	add	Temp6, Temp7		; Add up into Temp3/2
	mov	Temp2, Temp6
	adc	Temp8, Zero
	mov	Temp3, Temp8
	ldi	XH, 4
	mov	Temp5, XH			; Set number of divisions
mult_s16_by_u8_div_loop:
	lsr	Temp3			; Rotate right 
	ror	Temp2
	ror	Temp1
	dec	Temp5
	brne	mult_s16_by_u8_div_loop

	tst	Temp4			; Test sign
	breq	mult_s16_by_u8_exit	

	com	Temp1			; Change sign - invert and subtract minus one
	com	Temp2
	sub	Temp1, Temp4
	sbc	Temp2, Temp4

mult_s16_by_u8_exit:
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
.IF MODE == 0	; Main
calc_governor_target:
	lds	Temp1, Pgm_Gov_Mode			; Governor mode?
	cpi	Temp1, 4
	brne	PC+2
	rjmp	calc_governor_target_exit	; No

governor_speed_check:
	; Stop governor for stop RC pulse	
	lds	XH, New_Rcp				; Check RC pulse against stop value
	subi	XH, (RCP_MAX/10)			; Is pulse below stop value?
	brcs	governor_deactivate			; Yes - deactivate

	mov	XH, Flags1
	andi	XH, ((1<<STARTUP_PHASE)+(1<<INITIAL_RUN_PHASE))
	brne	governor_deactivate			; Deactivate if any startup phase set

	; Skip speed check if governor is already active
	sbrc	Flags0, GOV_ACTIVE			; Is governor active?
	rjmp	governor_target_calc

	; Check speed (do not run governor for low speeds)
	ldi	Temp1, 5					; Default high range activation limit value (~62500 eRPM)
	lds	Temp8, Pgm_Gov_Range
	mov	XH, Temp8					; Check if high range (Temp8 has Pgm_Gov_Range)
	dec	XH
	breq	governor_act_lim_set		; If high range - branch

	ldi	Temp1, 10					; Middle range activation limit value (~31250 eRPM)
	dec	XH
	breq	governor_act_lim_set		; If middle range - branch
	
	ldi	Temp1, 18					; Low range activation limit value (~17400 eRPM)

governor_act_lim_set:
	lds	XH, Comm_Period4x_H
	sub	XH, Temp1
	brcs	governor_activate			; If speed above min limit  - run governor

governor_deactivate:
	sbrs	Flags0, GOV_ACTIVE			; Is governor active?
	rjmp	governor_first_deactivate_done; This code is executed continuously. Only execute the code below the first time

	lds	XH, Pwm_Spoolup_Beg
	sts	Pwm_Limit_Spoolup, XH
	ldi	XH, 255
	sts	Spoolup_Limit_Cnt, XH
	ldi	XH, 1
	sts	Spoolup_Limit_Skip, XH			

governor_first_deactivate_done:
	lds	XH, Requested_Pwm			; Set current pwm to requested
	sts	Current_Pwm, XH
	sts	Gov_Target_L, Zero			; Set target to zero
	sts	Gov_Target_H, Zero
	sts	Gov_Integral_L, Zero		; Set integral to zero
	sts	Gov_Integral_H, Zero
	sts	Gov_Integral_X, Zero
	cbr	Flags0, (1<<GOV_ACTIVE)
	rjmp	calc_governor_target_exit

governor_activate:
	sbr	Flags0, (1<<GOV_ACTIVE)

governor_target_calc:
	; Governor calculations
	lds	Temp8, Pgm_Gov_Range
	mov	XH, Temp8				; Check high, middle or low range
	dec	XH
	brne	calc_governor_target_middle

	lds	XH, Governor_Req_Pwm	; Load governor requested pwm
	com	XH					; Calculate 255-pwm (invert pwm) 
	; Calculate comm period target (1 + 2*((255-Requested_Pwm)/256) - 0.25)
	rol	XH					; Msb to carry
	rol	XH					; To bit0
	mov	Temp2, XH				; Now 1 lsb is valid for H
	ror	XH					
	mov	Temp1, XH				; Now 7 msbs are valid for L
	mov	XH, Temp2
	andi	XH, 0x01				; Calculate H byte
	inc	XH					; Add 1
	mov	Temp2, XH
	mov	XH, Temp1
	andi	XH, 0xFE				; Calculate L byte
	rjmp	calc_governor_subtract_025

calc_governor_target_middle:
	mov	XH, Temp8				; Check middle or low range (Temp8 has Pgm_Gov_Range)
	dec	XH
	dec	XH
	brne	calc_governor_target_low

	lds	XH, Governor_Req_Pwm	; Load governor requested pwm
	com	XH					; Calculate 255-pwm (invert pwm) 
	; Calculate comm period target (1 + 4*((255-Requested_Pwm)/256))
	rol	XH					; Msb to carry
	rol	XH					; To bit0
	rol	XH					; To bit1
	mov	Temp2, XH				; Now 2 lsbs are valid for H
	ror	XH					
	mov	Temp1, XH				; Now 6 msbs are valid for L
	mov	XH, Temp2
	andi	XH, 0x03				; Calculate H byte
	inc	XH					; Add 1
	mov	Temp2, XH
	mov	XH, Temp1
	andi	XH, 0xFC				; Calculate L byte
	rjmp	calc_governor_store_target

calc_governor_target_low:
	lds	XH, Governor_Req_Pwm	; Load governor requested pwm
	com	XH					; Calculate 255-pwm (invert pwm) 
	; Calculate comm period target (2 + 8*((255-Requested_Pwm)/256) - 0.25)
	rol	XH					; Msb to carry
	rol	XH					; To bit0
	rol	XH					; To bit1
	rol	XH					; To bit2
	mov	Temp2, XH				; Now 3 lsbs are valid for H
	ror	XH					
	mov	Temp1, XH				; Now 5 msbs are valid for L
	mov	XH, Temp2
	andi	XH, 0x07				; Calculate H byte
	inc	XH					; Add 1
	inc	XH					; Add 1 more
	mov	Temp2, XH
	mov	XH, Temp1
	andi	XH, 0xF8				; Calculate L byte
calc_governor_subtract_025:
	subi	XH, 0x40				; Subtract 0.25
	mov	Temp1, XH
	sbc	Temp2, Zero
calc_governor_store_target:
	; Store governor target
	sts	Gov_Target_L, Temp1
	sts	Gov_Target_H, Temp2
calc_governor_target_exit:
	ret						
.ENDIF
.IF MODE == 1	; Tail
calc_governor_target:
	ret
.ENDIF
.IF MODE == 2	; Multi
calc_governor_target:
	lds	Temp1, Pgm_Gov_Mode			; Closed loop mode?
	cpi	Temp1, 4
	breq	calc_governor_target_exit	; No

governor_target_calc:
	; Stop governor for stop RC pulse	
	lds	XH, New_Rcp				; Check RC pulse against stop value
	subi	XH, RCP_STOP				; Is pulse below stop value?
	brcs	governor_deactivate			; Yes - deactivate

	rjmp	governor_activate			; No - activate

governor_deactivate:
	lds	XH, Requested_Pwm			; Set current pwm to requested
	sts	Current_Pwm, XH
	sts	Gov_Target_L, Zero			; Set target to zero
	sts	Gov_Target_H, Zero
	sts	Gov_Integral_L, Zero		; Set integral to zero
	sts	Gov_Integral_H, Zero
	sts	Gov_Integral_X, Zero
	cbr	Flags0, (1<<GOV_ACTIVE)
	rjmp	calc_governor_target_exit

governor_activate:
	lds	Temp5, Pgm_Gov_Mode			; Store gov mode in Temp5
	sbr	Flags0, (1<<GOV_ACTIVE)
	lds	XH, Requested_Pwm			; Load requested pwm
	sts	Governor_Req_Pwm, XH		; Set governor requested pwm
	; Calculate comm period target 2*(51000/Requested_Pwm)
	ldi	Temp1, 0x38				; Load 51000
	ldi	Temp2, 0xC7
	lds	Temp3, Comm_Period4x_L		; Load comm period
	lds	Temp4, Comm_Period4x_H		
	; Set speed range. Bare Comm_Period4x corresponds to 400k rpm, because it is 500n units
	lsr	Temp4
	ror	Temp3					; 200k eRPM range here
	; Check range
	mov	XH, Temp5
	dec	XH
	breq	governor_activate_range_set	; 200k eRPM? - branch
governor_activate_100k:
	lsr	Temp4
	ror	Temp3					; 100k eRPM range here
	mov	XH, Temp5					; Check range again
	dec	XH
	dec	XH
	breq	governor_activate_range_set	; 100k eRPM? - branch
governor_activate_50k:
	lsr	Temp4
	ror	Temp3					; 50k eRPM range here
governor_activate_range_set:
	xcall div_u16_by_u16
	; Store governor target
	sts	Gov_Target_L, Temp1
	sts	Gov_Target_H, Temp2
calc_governor_target_exit:
	ret						
.ENDIF


; Second governor routine - calculate governor proportional error
calc_governor_prop_error:
.IF MODE <= 1	; Main or tail
	; Load comm period and divide by 2
	lds	Temp2, Comm_Period4x_H
	lsr	Temp2
	lds	Temp1, Comm_Period4x_L
	ror	Temp1
	; Calculate error
	lds	XH, Gov_Target_L
	sub	XH, Temp1
	mov	Temp1, XH
	lds	XH, Gov_Target_H
	sbc	XH, Temp2
	mov	Temp2, XH
.ENDIF
.IF MODE == 2	; Multi
	; Calculate error
	lds	Temp1, Gov_Target_L
	lds	XH, Governor_Req_Pwm
	sub	Temp1, XH
	lds	Temp2, Gov_Target_H
	sbc	Temp2, Zero
.ENDIF
	; Check error and limit
	brcc	governor_check_prop_limit_pos	; Check carry

	cpi	Temp1, 0x80				; Is error too negative?
	ldi	XH, 0xFF
	cpc	Temp2, XH
	brcs	governor_limit_prop_error_neg	; Yes - limit
	rjmp	governor_store_prop_error

governor_check_prop_limit_pos:
	cpi	Temp1, 0x7F				; Is error too positive?
	cpc	Temp2, Zero
	brcc	governor_limit_prop_error_pos	; Yes - limit
	rjmp	governor_store_prop_error

governor_limit_prop_error_pos:
	ldi	Temp1, 0x7F				; Limit to max positive (2's complement)
	ldi	Temp2, 0x00
	rjmp	governor_store_prop_error

governor_limit_prop_error_neg:
	ldi	Temp1, 0x80				; Limit to max negative (2's complement)
	ldi	Temp2, 0xFF

governor_store_prop_error:
	; Store proportional
	sts	Gov_Proportional_L, Temp1
	sts	Gov_Proportional_H, Temp2
calc_governor_prop_error_exit:
	ret						


; Third governor routine - calculate governor integral error
calc_governor_int_error:
	; Add proportional to integral
	lds	Temp1, Gov_Proportional_L
	lds	XH, Gov_Integral_L
	add	Temp1, XH
	lds	Temp2, Gov_Proportional_H
	lds	XH, Gov_Integral_H
	adc	Temp2, XH
	ldi	Temp3, 0							; Sign extend high byte
	lds	Temp4, Gov_Proportional_H
	tst	Temp4
	brpl	PC+2
	dec	Temp3
	lds	XH, Gov_Integral_X
	adc	Temp3, XH
	; Check integral and limit
	brpl	governor_check_int_limit_pos	; Check sign bit

	cpi	Temp3, 0xF0				; Is error too negative?
	brcs	governor_limit_int_error_neg	; Yes - limit
	rjmp	governor_check_pwm

governor_check_int_limit_pos:
	cpi	Temp3, 0x0F				; Is error too positive?
	brcc	governor_limit_int_error_pos	; Yes - limit
	rjmp	governor_check_pwm

governor_limit_int_error_pos:
	ldi	Temp1, 0xFF				; Limit to max positive (2's complement)
	ldi	Temp2, 0xFF
	ldi	Temp3, 0x0F
	rjmp	governor_check_pwm

governor_limit_int_error_neg:
	ldi	Temp1, 0x00				; Limit to max negative (2's complement)
	ldi	Temp2, 0x00
	ldi	Temp3, 0xF0

governor_check_pwm:
	; Check current pwm
	lds	Temp4, Current_Pwm			; Is current pwm at or above pwm limit?
	lds	XH, Pwm_Limit				
	cp	Temp4, XH			
	brcc	governor_int_max_pwm		; Yes - branch

	tst	Temp4					; Is current pwm at zero?
	breq	governor_int_min_pwm		; Yes - branch

	rjmp	governor_store_int_error		; No - store integral error

governor_int_max_pwm:
	lds	XH, Gov_Proportional_H
	tst	XH
	brmi calc_governor_int_error_exit	; Is proportional error negative - branch (high byte is always zero)

	rjmp	governor_store_int_error		; Positive - store integral error

governor_int_min_pwm:
	lds	XH, Gov_Proportional_H
	tst	XH
	brpl	calc_governor_int_error_exit	; Is proportional error positive - branch (high byte is always zero)

governor_store_int_error:
	; Store integral
	sts	Gov_Integral_L, Temp1
	sts	Gov_Integral_H, Temp2
	sts	Gov_Integral_X, Temp3
calc_governor_int_error_exit:
	ret						


; Fourth governor routine - calculate governor proportional correction
calc_governor_prop_correction:
	; Load proportional gain
	lds	Temp3, Pgm_Gov_P_Gain_Decoded; Load proportional gain and store in Temp3
	; Load proportional
	lds	Temp1, Gov_Proportional_L	; Nominal multiply by 2
	lsl	Temp1
	lds	Temp2, Gov_Proportional_H
	rol	Temp2
	; Apply gain
	xcall mult_s16_by_u8_div_16
	; Check error and limit (to low byte)
	tst	Temp2
	brpl	governor_check_prop_corr_limit_pos	; Check sign bit

	cpi	Temp1, 0x80				; Is error too negative?
	ldi	XH, 0xFF
	cpc	Temp2, XH
	brcs	governor_limit_prop_corr_neg	; Yes - limit
	rjmp	governor_apply_prop_corr

governor_check_prop_corr_limit_pos:
	cpi	Temp1, 0x7F				; Is error too positive?
	cpc	Temp2, Zero
	brcc	governor_limit_prop_corr_pos	; Yes - limit
	rjmp	governor_apply_prop_corr

governor_limit_prop_corr_pos:
	ldi	Temp1, 0x7F				; Limit to max positive (2's complement)
	ldi	Temp2, 0x00
	rjmp	governor_apply_prop_corr

governor_limit_prop_corr_neg:
	ldi	Temp1, 0x80				; Limit to max negative (2's complement)
	ldi	Temp2, 0xFF

governor_apply_prop_corr:
	; Test proportional sign
	tst	Temp1
	brmi	governor_corr_neg_prop		; If proportional negative - go to correct negative

	; Subtract positive proportional
	lds	XH, Governor_Req_Pwm
	sub	XH, Temp1
	mov	Temp1, XH
	; Check result
	brcs	governor_corr_prop_min_pwm	; Is result negative?

	cpi	Temp1, 1					; Is result below pwm min?
	brcs	governor_corr_prop_min_pwm	; Yes
	rjmp	governor_store_prop_corr		; No - store proportional correction

governor_corr_prop_min_pwm:
	ldi	Temp1, 1					; Load minimum pwm
	rjmp	governor_store_prop_corr

governor_corr_neg_prop:
	; Add negative proportional
	com	Temp1
	subi	Temp1, 0xFF	; "Add one"
	lds	XH, Governor_Req_Pwm
	add	Temp1, XH
	; Check result
	brcs	governor_corr_prop_max_pwm	; Is result above max?
	rjmp	governor_store_prop_corr		; No - store proportional correction

governor_corr_prop_max_pwm:
	ldi	Temp1, 255				; Load maximum pwm
governor_store_prop_corr:
	; Store proportional pwm
	sts	Gov_Prop_Pwm, Temp1
calc_governor_prop_corr_exit:
	ret


; Fifth governor routine - calculate governor integral correction
calc_governor_int_correction:
	; Load integral gain
	lds	Temp3, Pgm_Gov_I_Gain_Decoded	; Load integral gain and store in Temp3
	; Load integral
	lds	Temp1, Gov_Integral_H
	lds	Temp2, Gov_Integral_X
	; Apply gain
	xcall mult_s16_by_u8_div_16
	; Check integral and limit
	tst	Temp2
	brpl	governor_check_int_corr_limit_pos	; Check sign bit

	cpi	Temp1, 0x01				; Is integral too negative?
	ldi	XH, 0xFF
	cpc	Temp2, XH
	brcs	governor_limit_int_corr_neg	; Yes - limit
	rjmp	governor_apply_int_corr

governor_check_int_corr_limit_pos:
	cpi	Temp1, 0xFF				; Is integral too positive?
	cpc	Temp2, Zero
	brcc	governor_limit_int_corr_pos	; Yes - limit
	rjmp	governor_apply_int_corr

governor_limit_int_corr_pos:
	ldi	Temp1, 0xFF				; Limit to max positive (2's complement)
	ldi	Temp2, 0x00
	rjmp	governor_apply_int_corr

governor_limit_int_corr_neg:
	ldi	Temp1, 0x01				; Limit to max negative (2's complement)
	ldi	Temp2, 0xFF

governor_apply_int_corr:
	; Test integral sign
	tst	Temp2
	brmi	governor_corr_neg_int	; If integral negative - go to correct negative

	; Subtract positive integral
	lds	XH, Gov_Prop_Pwm
	sub	XH, Temp1
	mov	Temp1, XH
	; Check result
	brcs	governor_corr_int_min_pwm	; Is result negative?

	cpi	Temp1, 1					; Is result below pwm min?
	brcs	governor_corr_int_min_pwm	; Yes
	rjmp	governor_store_int_corr		; No - store correction

governor_corr_int_min_pwm:
	ldi	Temp1, 0					; Load minimum pwm
	rjmp	governor_store_int_corr

governor_corr_neg_int:
	; Add negative integral
	com	Temp1
	subi	Temp1, 0xFF	; "Add one"
	lds	XH, Gov_Prop_Pwm
	add	Temp1, XH
	; Check result
	brcs	governor_corr_int_max_pwm	; Is result above max?
	rjmp	governor_store_int_corr		; No - store correction

governor_corr_int_max_pwm:
	ldi	Temp1, 255				; Load maximum pwm
governor_store_int_corr:
	; Store current pwm
	sts	Current_Pwm, Temp1
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
	ldi	Temp1, 0xFF					; Default full power
	cbr	Flags0, (1<<DEMAG_ENABLED)		; Default disabled
	mov	XH, Flags1
	andi	XH, ((1<<STARTUP_PHASE)+(1<<INITIAL_RUN_PHASE))
	brne	set_pwm_limit_low_rpm_exit		; Exit if any startup phase set

	sbr	Flags0, (1<<DEMAG_ENABLED)		; Enable demag
	lds	XH, Comm_Period4x_H
	cpi	XH, 0x0A						; ~31250 eRPM
	brcs	set_pwm_demag_done				; If speed above - branch

	mov	XH, Current_Pwm_Limited
	cpi	XH, 0x40						; Do not disable if pwm above 25%
	brcc	set_pwm_demag_done

	cbr	Flags0, (1<<DEMAG_ENABLED)		; Disable demag

set_pwm_demag_done:
	lds	XH, Pgm_Enable_Power_Prot		; Check if low RPM power protection is enabled
	tst	XH
	breq	set_pwm_limit_low_rpm_exit		; Exit if disabled

	lds	XH, Comm_Period4x_H
	tst	XH
	breq	set_pwm_limit_low_rpm_exit		; Avoid divide by zero

	ldi	Temp1, 255					; Divide 255 by Comm_Period4x_H
	lds	Temp2, Comm_Period4x_H
	xcall div_u8_by_u8
	cli								; Disable interrupts in order to avoid interference with mul ops in interrupt routines
	lds	XH, Low_Rpm_Pwr_Slope			; Multiply by slope
	mul	Temp1, XH
	mov	Temp2, Mul_Res_H				; Transfer result
	mov	Temp1, Mul_Res_L
	sei
	tst	Temp2
	breq	PC+2							; Limit to max
	
	ldi	Temp1, 0xFF				

	lds	XH, Pwm_Spoolup_Beg
	cp	Temp1, XH						; Limit to min
	brcc	set_pwm_limit_low_rpm_exit

	lds	Temp1, Pwm_Spoolup_Beg				

set_pwm_limit_low_rpm_exit:
	sts	Pwm_Limit_Low_Rpm, Temp1				
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
.IF MODE >= 1	; Tail or multi
	; If not supported, then exit
	rjmp	measure_lipo_exit
.ENDIF
.IF MODE == 0	; Main
	; Set commutation to BpFET on
	xcall comm5comm6			
	; Start adc
	Start_Adc XH
	; Wait for ADC reference to settle, and then start again
	xcall wait1ms
	Start_Adc XH
	; Wait for ADC conversion to complete
measure_lipo_wait_adc:
	Get_Adc_Status XH
	sbrc	XH, ADSC
	rjmp	measure_lipo_wait_adc
	; Read ADC result
	Read_Adc_Result Temp1, Temp2
	; Stop ADC
	Stop_Adc XH
	; Switch power off
	xcall switch_power_off		
	; Set limit step
	ldi	Temp3, ADC_LIMIT_L
	sts	Lipo_Adc_Limit_L, Temp3
	tst	Temp3
	brne	PC+2		
	rjmp	measure_lipo_exit		; Exit if disabled

	ldi	Temp4, ADC_LIMIT_H
	sts	Lipo_Adc_Limit_H, Temp4
	mov	Temp6, Temp4			; Divide 3.0V value by 2
	lsr	Temp6
	mov	Temp5, Temp3
	lsr	Temp5	
	add	Temp5, Temp3			; Calculate 1.5*3.0V=4.5V value
	adc	Temp6, Temp4
	mov	Temp3, Temp5			; Copy step
	mov	Temp4, Temp6	
measure_lipo_cell_loop:
	; Check voltage against xS lower limit
	cp	Temp1, Temp3			; Voltage above limit?
	cpc	Temp2, Temp4
	brcs	measure_lipo_adjust		; No - branch

	; Set xS voltage limit
	lds	Temp7, Lipo_Adc_Limit_L		
	ldi	XH, ADC_LIMIT_L
	add	XH, Temp7
	sts	Lipo_Adc_Limit_L, XH
	lds	Temp7, Lipo_Adc_Limit_H		
	ldi	XH, ADC_LIMIT_H
	adc	XH, Temp7
	sts	Lipo_Adc_Limit_H, XH
	; Set (x+1)S lower limit
	add	Temp3, Temp5			; Add step
	adc	Temp4, Temp6
	rjmp	measure_lipo_cell_loop	; Check for one more battery cell

measure_lipo_adjust:
	lds	Temp7, Lipo_Adc_Limit_L
	lds	Temp8, Lipo_Adc_Limit_H
	; Calculate 3.125%
	lds	Temp2, Lipo_Adc_Limit_H
	lsr	Temp2
	lds	Temp1, Lipo_Adc_Limit_L	
	ror	Temp1		; After this 50%
	lsr	Temp2
	ror	Temp1		; After this 25%
	lds	XH, Lipo_Adc_Limit_L	; Set adc reference for voltage compensation
	add	XH, Temp1
	sts	Lipo_Adc_Reference_L, XH
	lds	XH, Lipo_Adc_Limit_H
	adc	XH, Temp2
	sts	Lipo_Adc_Reference_H, XH
	; Divide three times to get to 3.125%
	ldi	Temp3, 3
measure_lipo_divide_loop:
	lsr	Temp2
	ror	Temp1		
	dec	Temp3
	brne	measure_lipo_divide_loop

	; Add the programmed number of 0.1V (or 3.125% increments)
	lds	Temp3, Pgm_Low_Voltage_Lim	; Load programmed limit 
	dec	Temp3
	brne	measure_lipo_limit_on	; Is low voltage limiting on?

	sts	Lipo_Adc_Limit_L, Zero	; No - set limit to zero
	sts	Lipo_Adc_Limit_H, Zero
	rjmp	measure_lipo_exit	

measure_lipo_limit_on:
	dec	Temp3
	breq	measure_lipo_update

measure_lipo_add_loop:
	add	Temp7, Temp1		; Add 3.125%
	adc	Temp8, Temp2
	dec	Temp3
	brne	measure_lipo_add_loop

measure_lipo_update:
	; Set ADC limit
	sts	Lipo_Adc_Limit_L, Temp7
	sts	Lipo_Adc_Limit_H, Temp8
.ENDIF
measure_lipo_exit:
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
	lds	Temp3, Pgm_Low_Voltage_Lim	; Store in Temp3
	; Wait for ADC conversion to complete
	Get_Adc_Status XH
	sbrc	XH, ADSC
	rjmp	check_temp_voltage_and_limit_power
	; Read ADC result
	Read_Adc_Result Temp1, Temp2
	; Stop ADC
	Stop_Adc XH
	lds	XH, Adc_Conversion_Cnt		; Increment conversion counter
	inc	XH
	sts	Adc_Conversion_Cnt, XH
	cpi	XH, TEMP_CHECK_RATE			; Is conversion count equal to temp rate?
	brcs	check_voltage_start			; No - check voltage

	sts	Adc_Conversion_Cnt, Zero		; Yes - temperature check. Reset counter
	lds	XH, Pgm_Enable_Temp_Prot		; Is temp protection enabled?
	tst	XH
	breq	temp_check_exit			; No - branch

	tst	Temp2					; Is temperature ADC reading below 256?
	breq	temp_average_inc_dec		; Yes - proceed

	lds	XH, Current_Average_Temp_Adc	; No - increment average
	cpi	XH, 0xFF
	breq	temp_average_updated		; Already max - no change
	rjmp	temp_average_inc			; Increment 

temp_average_inc_dec:
	lds	XH, Current_Average_Temp_Adc	; Check if current temp ADC is above or below average
	cp	Temp1, XH
	breq	temp_average_updated		; Equal - no change

	brcc	temp_average_inc			; Above - increment average	

	tst	XH						; Below - decrement average if average is not already zero
	breq	temp_average_updated		
temp_average_dec:
	dec	XH						; Decrement average
	rjmp	temp_average_updated

temp_average_inc:
	inc	XH						; Increment average
	breq	temp_average_dec

temp_average_updated:
	lds  Temp1, Pwm_Limit
	sts	Current_Average_Temp_Adc, XH
	cpi	XH, TEMP_LIMIT				; Is temp ADC above first limit?
	brcc	temp_check_set_limit		; Yes - exit

	ldi  Temp1, 192				; No - limit pwm

	cpi	XH, (TEMP_LIMIT-TEMP_LIMIT_STEP)	; Is temp ADC above second limit
	brcc	temp_check_set_limit		; Yes - exit

	ldi  Temp1, 128				; No - limit pwm

	cpi	XH, (TEMP_LIMIT-2*TEMP_LIMIT_STEP)	; Is temp ADC above third limit
	brcc	temp_check_set_limit		; Yes - exit

	ldi  Temp1, 64					; No - limit pwm

	cpi	XH, (TEMP_LIMIT-3*TEMP_LIMIT_STEP)	; Is temp ADC above final limit
	brcc	temp_check_set_limit		; Yes - exit

	ldi  Temp1, 0					; No - limit pwm

temp_check_set_limit:
	sts  Pwm_Limit, Temp1			; Set pwm limit
temp_check_exit:
	Set_Adc_Ip_Volt				; Select adc input for next conversion
	ret

check_voltage_start:
.IF MODE == 0	; Main 
	; Check if low voltage limiting is enabled
	cpi	Temp3, 1					; Is low voltage limit disabled?
	breq	check_voltage_good			; Yes - voltage declared good

	; Check if ADC is saturated
	cpi	Temp1, 0xFF
	ldi	XH, 3
	cpc	Temp2, XH
	brcc	check_voltage_good			; ADC saturated, can not make judgement

	ldi	XH, ADC_LIMIT_L			; Is low voltage limit zero (ESC does not support it)?
	tst	XH
	breq	check_voltage_good			; Yes - voltage declared good

	; Check voltage against limit
	lds	XH, Lipo_Adc_Limit_L
	cp	Temp1, XH
	lds	XH, Lipo_Adc_Limit_H
	cpc	Temp2, XH
	brcc	check_voltage_good			; If voltage above limit - branch

	; Decrease pwm limit
	lds  XH, Pwm_Limit
	tst	XH
	breq	check_voltage_lim			; If limit zero - branch

	dec	XH						; Decrement limit
	sts	Pwm_Limit, XH				
	rjmp	check_voltage_lim

check_voltage_good:
	; Increase pwm limit
	lds  XH, Pwm_Limit
	cpi	XH, 0xFF			
	breq	check_voltage_lim			; If limit max - branch

	inc	XH						; Increment limit
	sts	Pwm_Limit, XH

check_voltage_lim:
	lds	Temp1, Pwm_Limit			; Set limit
	lds	XH, Current_Pwm
	sub	XH, Temp1
	brcc	check_voltage_spoolup_lim	; If current pwm above limit - branch and limit	

	lds	Temp1, Current_Pwm			; Set current pwm (no limiting)

check_voltage_spoolup_lim:
	; Slow spoolup
	lds	XH, Pwm_Limit_Spoolup
	cp	Temp1, XH
	brcs	check_voltage_exit			; If current pwm below limit - branch	

	lds	Temp1, Pwm_Limit_Spoolup
	lds	XH, Pwm_Limit_Spoolup		; Check if spoolup limit is max
	cpi	XH, 0xFF
	breq	check_voltage_exit			; If max - branch
 
	lds	XH, Pwm_Limit_Spoolup		; Set pwm limit to spoolup limit during ramp (to avoid governor integral buildup)
	sts	Pwm_Limit, XH
	
check_voltage_exit:
	mov	Current_Pwm_Limited, Temp1
	sts	Current_Pwm_Lim_Dith, Temp1
.ENDIF
.IF MODE == 1	; Tail
	; Increase pwm limit
	lds  XH, Pwm_Limit
	inc	XH
	breq	check_voltage_lim			; If limit max - branch

	sts	Pwm_Limit, XH				; Increment limit

check_voltage_lim:
.ENDIF
.IF MODE == 2	; Multi
	; Set current pwm limited if closed loop mode
	lds	XH, Pgm_Gov_Mode			; Governor mode?
	cpi	XH, 4
	brne check_voltage_set_pwm_gov	; Yes - branch

	lds  Temp2, Pwm_Limit
	ldi	XH, 16
	add	Temp2, XH
	brcc	PC+2						; If not max - branch

	ldi	Temp2, 255

	sts	Pwm_Limit, Temp2			; Increment limit 
	rjmp	check_voltage_pwm_done

check_voltage_set_pwm_gov:
	; Limit pwm for low rpms
	lds	XH, Pwm_Limit_Low_Rpm		; Check against limit
	cp	Temp1, XH
	brcs	PC+2						; If current pwm below limit - branch

	mov	Temp1, XH					; Limit pwm

	mov  Current_Pwm_Limited, Temp1
	sts	Current_Pwm_Lim_Dith, Temp1
check_voltage_pwm_done:
.ENDIF
	; Set adc mux for next conversion
	lds	XH, Adc_Conversion_Cnt		; Is next conversion for temperature?
	cpi	XH, (TEMP_CHECK_RATE-1)
	brne	check_voltage_ret

	Set_Adc_Ip_Temp				; Select temp sensor for next conversion

check_voltage_ret:
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
	; Adjust startup power
	ldi	Temp1, PWM_START				; Set power
	cli								; Disable interrupts in order to avoid interference with mul ops in interrupt routines
	lds	XH, Pgm_Startup_Pwr_Decoded		; Multiply startup power by programmed value
	mul	Temp1, XH
	mov	Temp1, Mul_Res_H				; Transfer result
	lsl	Mul_Res_L						; Multiply result by 2 (unity gain is 128)
	rol	Temp1
	sei
	lds	XH, Pwm_Limit					; Check against limit
	cp	Temp1, XH	
	brcs	startup_pwm_set_pwm				; If pwm below limit - branch

	lds	Temp1, Pwm_Limit				; Limit pwm

startup_pwm_set_pwm:
	; Set pwm variables
	sts	Requested_Pwm, Temp1			; Update requested pwm
	sts	Current_Pwm, Temp1				; Update current pwm
	mov	Current_Pwm_Limited, Temp1		; Update limited version of current pwm
	sts	Current_Pwm_Lim_Dith, Temp1
	sts	Pwm_Spoolup_Beg, Temp1			; Update spoolup beginning pwm
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
	sts	Comm_Period4x_L, Zero		; Set commutation period registers
	ldi	XH, 0xF0			
	sts	Comm_Period4x_H, XH
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Calculate next commutation timing routine
;
; No assumptions
;
; Called immediately after each commutation
; Also sets up timer 1 to wait advance timing
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
calc_next_comm_timing:			; Entry point for run phase
	; Read commutation time
	cli 						; Disable interrupts while reading timer 1
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	sei
	; Calculate this commutation time
	lds	Temp3, Prev_Comm_L
	lds	Temp4, Prev_Comm_H
	sts	Prev_Comm_L, Temp1		; Store timestamp as previous commutation
	sts	Prev_Comm_H, Temp2
	sub	Temp1, Temp3			; Calculate the new commutation time
	sbc	Temp2, Temp4
	sbrs	Flags1, STARTUP_PHASE	
	rjmp	calc_next_comm_startup_done	

	lds	Temp5, Prev_Prev_Comm_L
	lds	Temp6, Prev_Prev_Comm_H
	sts	Prev_Prev_Comm_L, Temp3
	sts	Prev_Prev_Comm_H, Temp4
	sub	Temp4, Temp6			; Calculate previous commutation time (hi byte only)
	sub	Temp2, Temp4			; Calculate the difference between the two previous commutation times (hi bytes only)
	sts	Comm_Diff, Temp2
	lds	Temp1, Prev_Comm_L		; Reload this commutation time
	lds	Temp2, Prev_Comm_H
	sub	Temp1, Temp5			; Calculate the new commutation time based upon the two last commutations (to reduce sensitivity to offset)
	sbc	Temp2, Temp6
	lds	Temp4, Comm_Period4x_H	; Average with previous and save
	lds	Temp3, Comm_Period4x_L
	lsr	Temp4			
	ror	Temp3
	add	Temp1, Temp3
	adc	Temp2, Temp4
	sts	Comm_Period4x_L, Temp1
	sts	Comm_Period4x_H, Temp2
	rjmp	calc_new_wait_times_setup

calc_next_comm_startup_done:
	; Calculate new commutation time
	lds	Temp3, Comm_Period4x_L	; Comm_Period4x(-l-h) holds the time of 4 commutations
	lds	Temp4, Comm_Period4x_H
	mov	Temp5, Temp3			; Copy variables
	mov	Temp6, Temp4
	ldi	XH, 4				; Divide Comm_Period4x 4 times as default
	mov	Temp7, XH
	ldi	XH, 2				; Divide new commutation time 2 times as default
	mov	Temp8, XH
	cpi	Temp4, 0x04
	brcs	PC+3

	dec	Temp7				; Reduce averaging time constant for low speeds
	dec	Temp8

	cpi	Temp4, 0x08
	brcs	PC+3

	dec	Temp7				; Reduce averaging time constant more for even lower speeds
	dec	Temp8

calc_next_comm_avg_period_div:
	lsr	Temp6				; Divide by 2
	ror	Temp5
	dec	Temp7
	brne calc_next_comm_avg_period_div

	sub	Temp3, Temp5			; Subtract a fraction
	sbc	Temp4, Temp6

	tst	Temp8				; Divide new time
	breq	calc_next_comm_new_period_div_done

calc_next_comm_new_period_div:
	lsr	Temp2				; Divide by 2
	ror	Temp1
	dec	Temp8
	brne	calc_next_comm_new_period_div

calc_next_comm_new_period_div_done:
	add	Temp3, Temp1			; Add the divided new time
	adc	Temp4, Temp2
	sts	Comm_Period4x_L, Temp3	; Store Comm_Period4x_X
	sts	Comm_Period4x_H, Temp4
	brcc	calc_new_wait_times_setup; If period larger than 0xffff - go to slow case

	ldi	XH, 0xFF
	sts	Comm_Period4x_L, XH		; Set commutation period registers to very slow timing (0xffff)
	sts	Comm_Period4x_H, XH

calc_new_wait_times_setup:	
	; Load programmed commutation timing
	sbrs	Flags1, STARTUP_PHASE	; Set dedicated timing during startup
	rjmp	calc_new_wait_per_startup_done

	ldi	XH, 3
	mov	Temp8, XH
	rjmp	calc_new_wait_per_demag_done

calc_new_wait_per_startup_done:
	lds	XH, Pgm_Comm_Timing		; Store in XH
	lds	Temp1, Demag_Detected_Metric; Check demag metric
	cpi	Temp1, 130
	brcs	calc_new_wait_per_demag_done

	inc	XH					; Increase timing

	cpi	Temp1, 160
	brcs	PC+2

	inc	XH					; Increase timing again

	cpi	XH, 6				; Limit timing to max
	brcs	PC+2

	ldi	XH, 5				; Set timing to max

	mov	Temp8, XH				; Store timing in Temp8
calc_new_wait_per_demag_done:
	ldi	XH, (COMM_TIME_RED<<1)	
	mov	Temp7, XH
	sbrs	Flags2, PGM_PWMOFF_DAMPED; More reduction for damped
	rjmp	PC+2

	inc	Temp7				; Increase more

	lds	XH, Comm_Period4x_H		; More reduction for higher rpms
	cpi	XH, 3				; 104k eRPM
	brcc	calc_new_wait_per_low

	inc	Temp7				; Increase
	inc	Temp7

	sbrs	Flags2, PGM_PWMOFF_DAMPED; More reduction for damped
	rjmp	calc_new_wait_per_low

	inc	Temp7				; Increase more

calc_new_wait_per_low:
	cpi	XH, 2				; 156k eRPM
	brcc	calc_new_wait_per_high

	inc	Temp7				; Increase more
	inc	Temp7

	sbrs	Flags2, PGM_PWMOFF_DAMPED; More reduction for damped
	rjmp	calc_new_wait_per_high

	inc	Temp7				; Increase more

calc_new_wait_per_high:
	; Load current commutation timing
	lds	Temp2, Comm_Period4x_H	; Load Comm_Period4x
	lds	Temp1, Comm_Period4x_L	
	ldi	Temp3, 4				; Divide 4 times
divide_wait_times:
	lsr	Temp2				; Divide by 2
	ror	Temp1
	dec	Temp3
	brne	divide_wait_times

	sub	Temp1, Temp7
	sbc	Temp2, Zero
	brcs	load_min_time			; Check that result is still positive

	mov	XH, Temp1
	subi	XH, (COMM_TIME_MIN<<1)
	mov	XH, Temp2				
	sbc	XH, Zero
	brcc	calc_new_wait_times_exit	; Check that result is still above minumum

load_min_time:
	ldi	Temp1, (COMM_TIME_MIN<<1)
	ldi	Temp2, 0

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
	sbrc	Flags0, OC1A_PENDING 
	rjmp	wait_advance_timing

	; Setup next wait time
	lds	XH, Wt_ZC_Timeout_L
	sts	Next_Wt_L, XH
	lds	XH, Wt_ZC_Timeout_H
	sts	Next_Wt_H, XH
	sbr	Flags0, (1<<OC1A_PENDING)
	T1oca_Int_Enable XH				; Enable timer1 OCA interrupt
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
	mov	Temp4, Temp2			; Copy values
	mov	Temp3, Temp1
	mov	Temp6, Temp2
	mov	Temp5, Temp1
	lsr	Temp6				; Divide by 2
	ror	Temp5
	sts	Wt_Zc_Timeout_L, Temp1	; Set 15deg time for zero cross scan timeout
	sts	Wt_Zc_Timeout_H, Temp2
	mov	XH, Temp8				; (Temp8 has Pgm_Comm_Timing)
	cpi	XH, 3				; Is timing normal?
	breq	store_times_decrease	; Yes - branch

	sbrc	XH, 0				; If an odd number - branch
	rjmp	adjust_timing_two_steps

	add	Temp1, Temp5			; Add 7.5deg and store in Temp1/2
	adc	Temp2, Temp6
	mov	Temp3, Temp5			; Store 7.5deg in Temp3/4
	mov	Temp4, Temp6
	rjmp	store_times_up_or_down

adjust_timing_two_steps:
	lsl	Temp1				; Add 15deg and store in Temp1/2
	rol	Temp2
	subi	Temp1, (COMM_TIME_MIN<<1) 
	sbc	Temp2, Zero
	ldi	Temp3, (COMM_TIME_MIN<<1); Store minimum time in Temp3/4
	ldi	Temp4, 0

store_times_up_or_down:
	mov	XH, Temp8				; Is timing higher than normal?
	cpi	XH, 3
	brcs	store_times_decrease	; No - branch

store_times_increase:
	sts	Wt_Comm_L, Temp3		; Now commutation time (~60deg) divided by 4 (~15deg nominal)
	sts	Wt_Comm_H, Temp4
	sts	Wt_Advance_L, Temp1		; New commutation advance time (~15deg nominal)
	sts	Wt_Advance_H, Temp2
	sts	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5deg)
	sts	Wt_Zc_Scan_H, Temp6
	ret

store_times_decrease:
	sts	Wt_Comm_L, Temp1		; Now commutation time (~60deg) divided by 4 (~15deg nominal)
	sts	Wt_Comm_H, Temp2
	sts	Wt_Advance_L, Temp3		; New commutation advance time (~15deg nominal)
	sts	Wt_Advance_H, Temp4
	sts	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5deg)
	sts	Wt_Zc_Scan_H, Temp6
	sbrs	Flags1, STARTUP_PHASE 			
	rjmp	store_times_exit

	lds	XH, Startup_Cnt			
	cpi	XH, 3
	brcs	store_times_exit

	lds	Temp1, Wt_Comm_H		; Compensate commutation wait for comparator offset
	lds	Temp2, Comm_Diff
	asr	Temp2
	add	Temp1, Temp2
	brcs	store_times_exit
	brmi	store_times_exit

	sts	Wt_Comm_L, Zero
	sts	Wt_Comm_H, Temp1 

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
	lds	Temp1, Random
	lsl	Temp1
	brcc	wait_before_zc_scan_rand

	ldi	XH, 0x6B					; Sequence length of 35, when initialized to 1
	eor	Temp1, XH

wait_before_zc_scan_rand:          
	sts	Random, Temp1
wait_before_zc_scan_wait:          
	sbrc	Flags0, OC1A_PENDING 
	rjmp	wait_before_zc_scan_wait

	sbr	Flags0, (1<<OC1A_PENDING)
	T1oca_Int_Enable XH				; Enable timer1 OCA interrupt
	mov	XH, Flags1
	andi	XH, ((1<<STARTUP_PHASE)+(1<<INITIAL_RUN_PHASE))
	breq	wait_before_zc_scan_exit

	lds	Temp3, Comm_Period4x_L		; Set long timeout when starting
	lds	Temp4, Comm_Period4x_H
	lsr	Temp4
	ror	Temp3
	cli							; Disable interrupts while reading timer 1
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	Temp1, Temp3				; Set new output compare value
	adc	Temp2, Temp4
	Set_OCR1AH Temp2				; Update high byte first to avoid false output compare
	Set_OCR1AL Temp1
	sbr	Flags0, (1<<OC1A_PENDING)
	T1oca_Clear_Int_Flag XH			; Clear t1oca interrupt flag if set
	T1oca_Int_Enable XH				; Enable interrupt
	sei

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
	sbr	Flags0, (1<<DEMAG_DETECTED)	; Set demag detected flag as default
	sts	Comparator_Read_Cnt, Zero	; Reset number of comparator reads
	ldi	Temp3, 0					; Desired comparator output
	rjmp	wait_for_comp_out_start

wait_for_comp_out_high:
	sbr	Flags0, (1<<DEMAG_DETECTED)	; Set demag detected flag as default
	sts	Comparator_Read_Cnt, Zero	; Reset number of comparator reads
	ldi	Temp3, (1<<ACO)			; Desired comparator output

wait_for_comp_out_start:
	sbrs	Flags0, DIR_CHANGE_BRAKE		; Is it a direction change?
	rjmp	wait_for_comp_brake_done

	ApFET_off						; Switch off one fet, so that comparator can be used

wait_for_comp_brake_done:
	mov	XH, Flags1				; Clear demag detected flag if start phases
	andi	XH, ((1<<STARTUP_PHASE)+(1<<INITIAL_RUN_PHASE))
	breq	PC+2
		
	cbr	Flags0, (1<<DEMAG_DETECTED)

	sei							; Enable interrupts
	; Set number of comparator readings
	ldi	Temp1, 1					; Number of OK readings required

	lds 	XH, Comm_Period4x_H			; Set number of readings higher for lower speeds
	subi	XH, 0x05
	brcs	comp_wait_on_comp_able

	ldi	Temp1, 2

	subi	XH, 0x05
	brcs	comp_wait_no_of_readings

	ldi	Temp1, 3

	subi	XH, 0x05
	brcs	comp_wait_no_of_readings

	ldi	Temp1, 6

comp_wait_no_of_readings:
	sbrc	Flags1, STARTUP_PHASE 			; Set many samples during startup
	ldi	Temp1, 10

comp_wait_on_comp_able:
	sbrc	Flags0, OC1A_PENDING			; Has zero cross scan timeout elapsed?
	rjmp	comp_wait_on_comp_able_not_timed_out

	lds	XH, Comparator_Read_Cnt			; Check that comparator has been read
	tst	XH
	breq	comp_wait_on_comp_able_not_timed_out	; If not read - branch

	sei								; Enable interrupts
	sbr	Flags1, (1<<COMP_TIMED_OUT)
	ret								; Yes - return

comp_wait_on_comp_able_not_timed_out:
	sei								; Enable interrupts
	nop								; Allocate only just enough time to capture interrupt
	nop
	cli								; Disable interrupts
	lds	Temp2, Comm_Period4x_H			; Reduce required distance to pwm transition for higher speeds
	cpi	Temp2, 0x07
	brcs	PC+2

	ldi	Temp2, 0x07

	ldi	XH, 5
	add	Temp2, XH
	sbrs	Flags0, PWM_ON					; More delay for pwm off
	lsl	Temp2

	sbrc	Flags1, STARTUP_PHASE			; Set a long delay from pwm on/off events during direct startup
	ldi	Temp2, 130
	sbrc	Flags1, INITIAL_RUN_PHASE		
	ldi	Temp2, 65

	Read_TCNT2 XH
	lds	Temp5, Pwm_Prev_Edge
	sub	XH, Temp5
	brcs	comp_wait_on_comp_able			; Re-evaluate pwm cycle if timer has wrapped 
	sbc	XH, Temp2
	brcs	comp_wait_on_comp_able			; Re-evaluate pwm cycle

	lds	XH, Comparator_Read_Cnt			; Increment comparator read count
	inc	XH
	sts	Comparator_Read_Cnt, XH
	Read_Comp_Out XH					; Read comparator output
	sbrc	Flags1, STARTUP_PHASE			
	rjmp	comp_read_done

	ldi	XH, 4						; 1 is stutter, 2 is quite fine, 3 is fine, 10 is fine on DYS SN20A
	dec	XH
	brne	PC-1
	Read_Comp_Out XH					; Another reading reduces comparator noise on some ESCs (for some reason...)				

comp_read_done:
	andi	XH, (1<<ACO)
	cp	XH, Temp3
	breq	comp_read_wrong
	rjmp	comp_read_ok

comp_read_wrong:
	sbrs	Flags1, STARTUP_PHASE 		
	rjmp	comp_read_wrong_not_startup

	inc	Temp1						; Increment number of OK readings required
	cpi	Temp1, 10						; If above initial requirement - go back and restart
	brcs	PC+2
	rjmp	wait_for_comp_out_start

	lds	XH, Startup_Cnt				; For the first commutations - go back and restart
	cpi	XH, 6
	brcc	PC+2
	rjmp	wait_for_comp_out_start

	rjmp	comp_wait_on_comp_able			; If below initial requirement - continue to look for good ones

comp_read_wrong_not_startup:
	sbrs	Flags0, DEMAG_DETECTED
	rjmp	wait_for_comp_out_start			; If comparator output is not correct, and timeout already extended - go back and restart

	cbr	Flags0, (1<<DEMAG_DETECTED)		; Clear demag detected flag
	Read_TCNT1L Temp4					; Assuming interrupts are disabled
	Read_TCNT1H Temp5
	lds	Temp6, Comm_Period4x_L			; Set timeout to zero comm period 4x value
	lds	Temp7, Comm_Period4x_H	
	add	Temp4, Temp6					; Set new output compare value
	adc	Temp5, Temp7
	Set_OCR1AH Temp5					; Update high byte first to avoid false output compare
	Set_OCR1AL Temp4
	sbr	Flags0, (1<<OC1A_PENDING)
	T1oca_Clear_Int_Flag XH				; Clear interrupt flag in case there are pending interrupts
	T1oca_Int_Enable XH					; Enable timer1 OCA interrupt
	rjmp	wait_for_comp_out_start			; If comparator output is not correct - go back and restart

comp_read_ok:
	lds	XH, Startup_Cnt				; Force a timeout for the first commutations			
	cpi	XH, 2
	brcc	PC+2
	rjmp	wait_for_comp_out_start

	sbrc	Flags0, DEMAG_DETECTED			; Do not accept correct comparator output if it is demag
	rjmp	wait_for_comp_out_start

	dec	Temp1						; Decrement readings counter - repeat comparator reading if not zero
	breq	PC+2
	rjmp	comp_wait_on_comp_able

	cbr	Flags1, (1<<COMP_TIMED_OUT)
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
	sbrs	Flags0, DIR_CHANGE_BRAKE			; Is it a direction change?
	rjmp	eval_comp_brake_done

	All_pFETs_off						; Turn off braking fets
.IF NFETON_DELAY != 0
	ldi	XH, NFETON_DELAY		
	dec	XH
	brne	PC-1
.ENDIF
	AnFET_on							; Turn on nfets (for high side driver charging)
	BnFET_on
	CnFET_on
	ldi	XH, 20		
	dec	XH
	brne	PC-1
	All_nFETs_off						; Turn off nfets again
.IF PFETON_DELAY < 128
.IF PFETON_DELAY != 0
	ldi	XH, PFETON_DELAY		
	dec	XH	
	brne	PC-1
.ENDIF
.ENDIF
	All_pFETs_on						; Turn on braking

eval_comp_brake_done:
	mov	XH, Flags1					; Check if startup or intial run				
	andi	XH, ((1<<STARTUP_PHASE)+(1<<INITIAL_RUN_PHASE))
	breq	eval_comp_check_timeout

	lds	XH, Startup_Cnt				; Increment counter
	sbrs	Flags1, INITIAL_RUN_PHASE		; Do not increment beyond startup phase
	inc	XH
	sts	Startup_Cnt, XH
	rjmp	eval_comp_exit					; Do not exit run mode, even if comparator has timed out 

eval_comp_check_timeout:
	sbrs	Flags1, COMP_TIMED_OUT			; Has timeout elapsed?
	rjmp	eval_comp_exit
	sbrc	Flags0, DEMAG_DETECTED			; Do not exit run mode if it is a demag situation
	rjmp eval_comp_exit

	pop	XH							; Routine exit without "ret" command (dummy pops to increment stack pointer)
	pop	XH
	rjmp	run_to_wait_for_power_on			; Yes - exit run mode

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
	lds	Temp3, Wt_Comm_L	; Set wait commutation value
	lds	Temp4, Wt_Comm_H
	cli					; Disable interrupts while reading timer 1
	T1oca_Clear_Int_Flag XH	; Clear t1oca interrupt flag if set
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	Temp1, Temp3		; Set new output compare value
	adc	Temp2, Temp4
	Set_OCR1AH Temp2		; Update high byte first to avoid false output compare
	Set_OCR1AL Temp1
	; Setup next wait time
	lds	XH, Wt_Advance_L
	sts	Next_Wt_L, XH
	lds	XH, Wt_Advance_H
	sts	Next_Wt_H, XH
	sbr	Flags0, (1<<OC1A_PENDING)
	T1oca_Int_Enable XH		; Enable timer1 OCA interrupt
	sei
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
	ldi	Temp1, 0
	sbrs	Flags0, DEMAG_ENABLED
	rjmp	PC+4
	sbrs	Flags0, DEMAG_DETECTED
	rjmp	PC+2

	ldi	Temp1, 1

	cli									; Disable interrupts in order to avoid interference with mul ops in interrupt routines
	lds	Temp2, Demag_Detected_Metric			; Sliding average of 8, 256 when demag and 0 when not. Limited to minimum 120
	ldi	XH, 7							; Multiply by 7
	mul	Temp2, XH							; Multiply 
	mov	Temp3, Mul_Res_H					; Place MSB in Temp3
	mov	Temp2, Mul_Res_L					; Place LSB in Temp2
	sei
	add	Temp3, Temp1						; Add new value for current demag status
	lsr	Temp3							; Divide by 8
	ror	Temp2
	lsr	Temp3
	ror	Temp2
	lsr	Temp3
	ror	Temp2
	sts	Demag_Detected_Metric, Temp2
	cpi	Temp2, 120						; Limit to minimum 120
	brcc	PC+4

	ldi	XH, 120
	sts	Demag_Detected_Metric, XH

	lds	Temp1, Demag_Detected_Metric			; Check demag metric
	lds	XH, Demag_Pwr_Off_Thresh
	cp	Temp1, XH
	brcs	wait_for_comm_wait					; Cut power if many consecutive demags. This will help retain sync during hard accelerations

	sbr	Flags0, (1<<DEMAG_CUT_POWER)			; Turn off motor power
	All_nFETs_off

wait_for_comm_wait:
	sbrc	Flags0, OC1A_PENDING 
	rjmp	wait_for_comm_wait

	; Setup next wait time
	lds	XH, Wt_Zc_Scan_L
	sts	Next_Wt_L, XH
	lds	XH, Wt_Zc_Scan_H
	sts	Next_Wt_H, XH
	sbr	Flags0, (1<<OC1A_PENDING)
	T1oca_Int_Enable XH						; Enable timer1 OCA interrupt
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
	sbrc	Flags0, DIR_CHANGE_BRAKE	; Is it a direction change?
	rjmp	comm_exit
	Set_RPM_Out
	ldi	XH, 2
	sbrc	Flags3, PGM_DIR_REV
	rjmp	comm12_rev

	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	BpFET_off 				; Turn off pfet
	ApFET_on					; Turn on pfet
	sei
	rjmp	comm_exit

comm12_rev:
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	BpFET_off 				; Turn off pfet
	CpFET_on					; Turn on pfet (reverse)
	sei
	rjmp	comm_exit

; Comm phase 2 to comm phase 3
comm2comm3:	
	sbrc	Flags0, DIR_CHANGE_BRAKE	; Is it a direction change?
	rjmp	comm_exit
	Clear_RPM_Out
	ldi	XH, 3
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comm23_nondamp

	; Comm2Comm3 Damped
	sbrc	Flags3, PGM_DIR_REV
	rjmp	comm23_damp_rev
	
	ldi	Temp1, 2				; Damping on BFET
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_bfet_damped)
	ldi	ZH, high(pwm_bfet_damped)
	sts	DampingFET, Temp1
	CnFET_off					; Turn off fets
	CpFET_off						
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm23_nfet_off		; Yes - branch
	BnFET_on					; Pwm on - turn on nfet
	rjmp	comm23_fets_done
comm23_nfet_off:
	BpFET_on					; Pwm off - switch damping fets	
comm23_fets_done:
	sei
	rjmp	comm_exit

	; Comm2Comm3 Damped reverse
comm23_damp_rev:
	ldi	Temp1, 2				; Damping on BFET
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_bfet_damped)	; (reverse)
	ldi	ZH, high(pwm_bfet_damped)
	sts	DampingFET, Temp1
	AnFET_off					; Turn off fets (reverse)
	ApFET_off						
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm23_nfet_off_rev		; Yes - branch
	BnFET_on					; Pwm on - turn on nfet
	rjmp	comm23_fets_done_rev
comm23_nfet_off_rev:
	BpFET_on					; Pwm off - switch damping fets	
comm23_fets_done_rev:
	sei
	rjmp	comm_exit

	; Comm2Comm3 Non-damped
comm23_nondamp:
	sbrc	Flags3, PGM_DIR_REV
	rjmp	comm23_nondamp_rev

	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_bfet)
	ldi	ZH, high(pwm_bfet)
	CnFET_off					; Turn off nfet
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm23_nfet_done
comm23_nfet:
	BnFET_on					; Yes - Turn on nfet
comm23_nfet_done:
	sei
	rjmp	comm_exit

	; Comm2Comm3 Non-damped reverse
comm23_nondamp_rev:
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_bfet)
	ldi	ZH, high(pwm_bfet)
	AnFET_off					; Turn off nfet (reverse)
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm23_nfet_done_rev
	BnFET_on					; Yes - Turn on nfet
comm23_nfet_done_rev:
	sei
	rjmp	comm_exit

; Comm phase 3 to comm phase 4
comm3comm4:	
	sbrc	Flags0, DIR_CHANGE_BRAKE	; Is it a direction change?
	rjmp	comm_exit
	Set_RPM_Out
	ldi	XH, 4
	sbrc	Flags3, PGM_DIR_REV
	rjmp	comm34_rev

	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ApFET_off 				; Turn off pfet
	CpFET_on					; Turn on pfet
	sei
	rjmp	comm_exit

comm34_rev:
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	CpFET_off 				; Turn off pfet (reverse)
	ApFET_on					; Turn on pfet (reverse)
	sei
	rjmp	comm_exit

; Comm phase 4 to comm phase 5
comm4comm5:	
	sbrc	Flags0, DIR_CHANGE_BRAKE	; Is it a direction change?
	rjmp	comm_exit
	Clear_RPM_Out
	ldi	XH, 5
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comm45_nondamp

	; Comm4Comm5 Damped
	sbrc	Flags3, PGM_DIR_REV
	rjmp	comm45_damp_rev

	ldi	Temp1, 1				; Damping on AFET
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_afet_damped)
	ldi	ZH, high(pwm_afet_damped)
	sts	DampingFET, Temp1
	BnFET_off					; Turn off fets
	BpFET_off						
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm45_nfet_off		; Yes - branch
	AnFET_on					; Pwm on - turn on nfet
	rjmp	comm45_fets_done
comm45_nfet_off:
	ApFET_on					; Pwm off - switch damping fets	
comm45_fets_done:
	sei
	rjmp	comm_exit

	; Comm4Comm5 Damped reverse
comm45_damp_rev:
	ldi	Temp1, 4				; Damping on CFET
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_cfet_damped)	; (reverse)
	ldi	ZH, high(pwm_cfet_damped)
	sts	DampingFET, Temp1
	BnFET_off					; Turn off fets
	BpFET_off						
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm45_nfet_off_rev		; Yes - branch
	CnFET_on					; Pwm on - turn on nfet (reverse)
	rjmp	comm45_fets_done_rev
comm45_nfet_off_rev:
	CpFET_on					; Pwm off - switch damping fets (reverse)	
comm45_fets_done_rev:
	sei
	rjmp	comm_exit

	; Comm4Comm5 Non-damped
comm45_nondamp:
	sbrc	Flags3, PGM_DIR_REV
	rjmp	comm45_nondamp_rev

	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_afet)
	ldi	ZH, high(pwm_afet)
	BnFET_off					; Turn off nfet
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm45_nfet_done
	AnFET_on					; Yes - Turn on nfet
comm45_nfet_done:
	sei
	rjmp	comm_exit

	; Comm4Comm5 Non-damped reverse
comm45_nondamp_rev:
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_cfet)		;  (reverse)
	ldi	ZH, high(pwm_cfet)
	BnFET_off					; Turn off nfet
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm45_nfet_done_rev
	CnFET_on					; Yes - Turn on nfet (reverse)
comm45_nfet_done_rev:
	sei
	rjmp	comm_exit

; Comm phase 5 to comm phase 6
comm5comm6:	
	sbrc	Flags0, DIR_CHANGE_BRAKE	; Is it a direction change?
	rjmp	comm_exit
	Set_RPM_Out
	ldi	XH, 6
	sbrc	Flags3, PGM_DIR_REV
	rjmp	comm56_rev

	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	CpFET_off 				; Turn off pfet
	BpFET_on					; Turn on pfet
	sei
	rjmp	comm_exit

comm56_rev:
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ApFET_off 				; Turn off pfet (reverse)
	BpFET_on					; Turn on pfet
	sei
	rjmp	comm_exit

; Comm phase 6 to comm phase 1
comm6comm1:	
	sbrc	Flags0, DIR_CHANGE_BRAKE	; Is it a direction change?
	rjmp	comm_exit
	Clear_RPM_Out
	ldi	XH, 1
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comm61_nondamp

	; Comm6Comm1 Damped
	sbrc	Flags3, PGM_DIR_REV
	rjmp	comm61_damp_rev

	ldi	Temp1, 4				; Damping on CFET
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_cfet_damped)
	ldi	ZH, high(pwm_cfet_damped)
	sts	DampingFET, Temp1
	AnFET_off					; Turn off fets
	ApFET_off						
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm61_nfet_off		; Yes - branch
	CnFET_on					; Pwm on - turn on nfet
	rjmp	comm61_fets_done
comm61_nfet_off:
	CpFET_on					; Pwm off - switch damping fets	
comm61_fets_done:
	sei
	rjmp	comm_exit

	; Comm6Comm1 Damped reverse
comm61_damp_rev:
	ldi	Temp1, 1				; Damping on AFET
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_afet_damped)	; (reverse)
	ldi	ZH, high(pwm_afet_damped)
	sts	DampingFET, Temp1
	CnFET_off					; Turn off fets (reverse)
	CpFET_off						
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm61_nfet_off_rev		; Yes - branch
	AnFET_on					; Pwm on - turn on nfet (reverse)
	rjmp	comm61_fets_done_rev
comm61_nfet_off_rev:
	ApFET_on					; Pwm off - switch damping fets (reverse)	
comm61_fets_done_rev:
	sei
	rjmp	comm_exit

	; Comm6Comm1 Non-damped
comm61_nondamp:
	sbrc	Flags3, PGM_DIR_REV
	rjmp	comm61_nondamp_rev

	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_cfet)
	ldi	ZH, high(pwm_cfet)
	AnFET_off					; Turn off nfet
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm61_nfet_done
	CnFET_on					; Yes - Turn on nfet
comm61_nfet_done:
	sei
	rjmp	comm_exit

	; Comm6Comm1 Non-damped reverse
comm61_nondamp_rev:
	cli						; Disable all interrupts
	sts	Comm_Phase, XH
	ldi	ZL, low(pwm_afet)		; (reverse)
	ldi	ZH, high(pwm_afet)
	CnFET_off					; Turn off nfet (reverse)
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm61_nfet_done_rev
	AnFET_on					; Yes - Turn on nfet (reverse)
comm61_nfet_done_rev:
	sei

comm_exit:
	cbr	Flags0, (1<<DEMAG_CUT_POWER)	; Clear demag power cut flag
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Set comparator phase
;
; No assumptions
;
; Sets up comparator muxes
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
set_comparator_phase:
	sbrs	Flags0, DIR_CHANGE_BRAKE		; Is it a direction change?
	rjmp	set_comparator_phase_brake_done

	Set_Comp_Phase_A XH			
	ret

set_comparator_phase_brake_done:
	lds	Temp1, Comm_Phase				
	sbrc	Temp1, 2
	subi	Temp1, 3
	cpi	Temp1, 1
	brne	set_comp_phase_not1

	sbrc	Flags3, PGM_DIR_REV
	rjmp	set_comp_phase_to_C
set_comp_phase_to_A:
	Set_Comp_Phase_A XH			
	rjmp	set_comp_phase_exit

set_comp_phase_not1:
	cpi	Temp1, 2
	brne	set_comp_phase_3

	Set_Comp_Phase_B XH				
	rjmp	set_comp_phase_exit

set_comp_phase_3:
	sbrc	Flags3, PGM_DIR_REV
	rjmp	set_comp_phase_to_A
set_comp_phase_to_C:
	Set_Comp_Phase_C XH			

set_comp_phase_exit:
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
	ldi	Temp3, low(pwm_nofet)	; Set Z register to pwm_nofet
	ldi	Temp4, high(pwm_nofet)
	movw	ZL, Temp3				; Set Z register in one instruction
	sts	DampingFET, Zero
	All_nFETs_Off				; Turn off all nfets
	All_pFETs_Off				; Turn off all pfets
	cbr	Flags0, (1<<PWM_ON)		; Set pwm cycle to pwm off
	ret			


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Set default parameters
;
; Assumes interrupt is disabled
;
; Sets default programming parameters
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
set_default_parameters:
.IF MODE == 0	; Main
	ldi	XL, low(Pgm_Gov_P_Gain)
	ldi	XH, high(Pgm_Gov_P_Gain)
	ldi	Temp1, DEFAULT_PGM_MAIN_P_GAIN
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_I_GAIN
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_GOVERNOR_MODE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1		
	st	X+, Temp1 	
	ldi	Temp1, DEFAULT_PGM_MAIN_STARTUP_PWR
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_PWM_FREQ
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_DIRECTION
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_RCP_PWM_POL
	st	X+, Temp1

	ldi	XL, low(Pgm_Enable_TX_Program)
	ldi	XH, high(Pgm_Enable_TX_Program)
	ldi	Temp1, DEFAULT_PGM_ENABLE_TX_PROGRAM
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_REARM_START
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_GOV_SETUP_TARGET
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1		
	st	X+, Temp1		
	st	X+, Temp1		
	ldi	Temp1, DEFAULT_PGM_MAIN_COMM_TIMING
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_GOVERNOR_RANGE
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1		
	ldi	Temp1, DEFAULT_PGM_PPM_MIN_THROTTLE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_PPM_MAX_THROTTLE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_BEEP_STRENGTH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_BEACON_STRENGTH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_BEACON_DELAY
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_DEMAG_COMP
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_BEC_VOLTAGE_HIGH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_PPM_CENTER_THROTTLE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_SPOOLUP_TIME
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_ENABLE_TEMP_PROT
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_ENABLE_POWER_PROT
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_ENABLE_PWM_INPUT
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1
.ENDIF
.IF MODE == 1	; Tail
	ldi	XL, low(Pgm_Gov_P_Gain)
	ldi	XH, high(Pgm_Gov_P_Gain)
	ldi	Temp1, 0xFF
	st	X+, Temp1		
	st	X+, Temp1		
	st	X+, Temp1		
	st	X+, Temp1		
	ldi	Temp1, DEFAULT_PGM_TAIL_GAIN
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_IDLE_SPEED
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_STARTUP_PWR
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_PWM_FREQ
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_DIRECTION
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_RCP_PWM_POL
	st	X+, Temp1

	ldi	XL, low(Pgm_Enable_TX_Program)
	ldi	XH, high(Pgm_Enable_TX_Program)
	ldi	Temp1, DEFAULT_PGM_ENABLE_TX_PROGRAM
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1		
	st	X+, Temp1	
	st	X+, Temp1	
	st	X+, Temp1		
	st	X+, Temp1	
	ldi	Temp1, DEFAULT_PGM_TAIL_COMM_TIMING
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1	
	st	X+, Temp1	
	ldi	Temp1, DEFAULT_PGM_PPM_MIN_THROTTLE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_PPM_MAX_THROTTLE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_BEEP_STRENGTH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_BEACON_STRENGTH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_BEACON_DELAY
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_DEMAG_COMP
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_BEC_VOLTAGE_HIGH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_PPM_CENTER_THROTTLE
	st	X+, Temp1
	ldi	Temp1, 0xFF	
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_ENABLE_TEMP_PROT
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_ENABLE_POWER_PROT
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_ENABLE_PWM_INPUT
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_PWM_DITHER
	st	X+, Temp1
.ENDIF
.IF MODE == 2	; Multi
	ldi	XL, low(Pgm_Gov_P_Gain)
	ldi	XH, high(Pgm_Gov_P_Gain)
	ldi	Temp1, DEFAULT_PGM_MULTI_P_GAIN
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_I_GAIN
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_GOVERNOR_MODE
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_GAIN
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1	
	ldi	Temp1, DEFAULT_PGM_MULTI_STARTUP_PWR
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_PWM_FREQ
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_DIRECTION
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_RCP_PWM_POL
	st	X+, Temp1

	ldi	XL, low(Pgm_Enable_TX_Program)
	ldi	XH, high(Pgm_Enable_TX_Program)
	ldi	Temp1, DEFAULT_PGM_ENABLE_TX_PROGRAM
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1		
	st	X+, Temp1		
	st	X+, Temp1	
	st	X+, Temp1		
	st	X+, Temp1		
	ldi	Temp1, DEFAULT_PGM_MULTI_COMM_TIMING
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1	
	st	X+, Temp1	
	ldi	Temp1, DEFAULT_PGM_PPM_MIN_THROTTLE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_PPM_MAX_THROTTLE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_BEEP_STRENGTH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_BEACON_STRENGTH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_BEACON_DELAY
	st	X+, Temp1
	ldi	Temp1, 0xFF
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_DEMAG_COMP
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_BEC_VOLTAGE_HIGH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_PPM_CENTER_THROTTLE
	st	X+, Temp1
	ldi	Temp1, 0xFF	
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_ENABLE_TEMP_PROT
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_ENABLE_POWER_PROT
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_ENABLE_PWM_INPUT
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_PWM_DITHER
	st	X+, Temp1
.ENDIF
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
	lds	Temp3, Pgm_Pwm_Freq			; Load pwm freq and store in Temp3
	cbr	Flags2, (1<<PGM_PWMOFF_DAMPED)
.IF DAMPED_MODE_ENABLE == 1
	cpi	Temp3, 3
	brne	PC+2
	sbr	Flags2, (1<<PGM_PWMOFF_DAMPED)
.ENDIF
	; Load programmed direction
	lds	XH, Pgm_Direction	
.IF MODE >= 1	; Tail or multi
	cpi	XH, 3
	breq	decode_params_dir_set
.ENDIF

	cbr	Flags3, (1<<PGM_DIR_REV)
	sbrc	XH, 1
	sbr	Flags3, (1<<PGM_DIR_REV)
decode_params_dir_set:
	cbr	Flags3, (1<<PGM_RCP_PWM_POL)
	lds	XH, Pgm_Input_Pol	
	sbrc	XH, 1
	sbr	Flags3, (1<<PGM_RCP_PWM_POL)
	cpi	Temp3, 2
	breq	decode_pwm_freq_low

	sbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)
	rjmp	decode_pwm_freq_end

decode_pwm_freq_low:
	cbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)

decode_pwm_freq_end:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Load flash table entry
;
; Assumptions: Z must be loaded with table address, Temp1 must be 
;    set to table entry number, result is delivered in XH
;
; Loads the content of a flash table entry
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
load_flash_table_entry:
	dec	Temp1
	add	ZL, Temp1
	adc	ZH, Zero
	lpm	XH, Z
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
	ldi	ZL, low(GOV_GAIN_TABLE<<1)
	ldi	ZH, high(GOV_GAIN_TABLE<<1)
	lds	Temp1, Pgm_Gov_P_Gain	; Decode governor P gain	
	xcall load_flash_table_entry
	sts	Pgm_Gov_P_Gain_Decoded, XH	
	ldi	ZL, low(GOV_GAIN_TABLE<<1)
	ldi	ZH, high(GOV_GAIN_TABLE<<1)
	lds	Temp1, Pgm_Gov_I_Gain	; Decode governor I gain	
	xcall load_flash_table_entry
	sts	Pgm_Gov_I_Gain_Decoded, XH	
	; Decode startup power
	ldi	ZL, low(STARTUP_POWER_TABLE<<1)
	ldi	ZH, high(STARTUP_POWER_TABLE<<1)
	lds	Temp1, Pgm_Startup_Pwr
	xcall load_flash_table_entry
	sts	Pgm_Startup_Pwr_Decoded, XH	
.IF MODE == 0	; Main
	; Decode spoolup time
	lds	Temp1, Pgm_Main_Spoolup_Time		
	tst	Temp1
	brne	PC+2			; If not zero - branch
	
	inc	Temp1

	cpi	Temp1, 17		; Limit to 17 max
	brcs	PC+2

	ldi	Temp1, 17

	mov	XH, Temp1
	add	XH, Temp1
	add	XH, Temp1		; Now 3x
	sts	Main_Spoolup_Time_3x, XH
	mov	Temp2, XH
	add	XH, Temp2
	add	XH, Temp2
	add	XH, Temp1		; Now 10x
	sts	Main_Spoolup_Time_10x, XH
	add	XH, Temp2
	add	XH, Temp1		
	add	XH, Temp1		; Now 15x
	sts	Main_Spoolup_Time_15x, XH
.ENDIF
	; Decode demag compensation
	lds	XH, Pgm_Demag_Comp
	ldi	Temp1, 255				; Set defaults
	ldi	Temp2, 12
	cpi	XH, 2
	brne	decode_demag_high
	
	ldi	Temp1, 160				; Settings for demag comp low
	ldi	Temp2, 10

decode_demag_high:
	cpi	XH, 3
	brne	decode_demag_done

	ldi	Temp1, 130				; Settings for demag comp high
	ldi	Temp2, 5

decode_demag_done:
	sts	Demag_Pwr_Off_Thresh, Temp1	; Set variables
	sts	Low_Rpm_Pwr_Slope, Temp2
	; Decode pwm dither
	ldi	ZL, low(PWM_DITHER_TABLE<<1)	
	ldi	ZH, high(PWM_DITHER_TABLE<<1)
	lds	Temp1, Pgm_Pwm_Dither
	xcall load_flash_table_entry
	sts	Pwm_Dither_Decoded, XH	
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
.IF HIGH_BEC_VOLTAGE == 1
	Set_BEC_Lo XH			; Set default to low
	lds	Temp1, Pgm_BEC_Voltage_High		
	tst	Temp1				
	breq	set_bec_voltage_exit	

	Set_BEC_Hi XH			; Set to high

set_bec_voltage_exit:
.ENDIF
.IF HIGH_BEC_VOLTAGE == 2
	Set_BEC_0				; Set default to low
	lds	Temp1, Pgm_BEC_Voltage_High		
	cpi	Temp1, 1
	brne set_bec_voltage_2	

	Set_BEC_1				; Set to level 1

set_bec_voltage_2:
	cpi	Temp1, 2
	brne set_bec_voltage_exit	

	Set_BEC_2				; Set to level 2

set_bec_voltage_exit:
.ENDIF
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Find throttle gain
;
; Assumes that interrupts are disabled
; Assumes that the difference between max and min throttle must be more than 520us (a Pgm_Ppm_xxx_Throttle difference of 130)
;
; Finds throttle gain from throttle calibration values
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
find_throttle_gain:
	; Load programmed minimum and maximum throttle
	lds	Temp3, Pgm_Ppm_Min_Throttle
	lds	Temp4, Pgm_Ppm_Max_Throttle
	; Check if full range is chosen
	sbrs	Flags3, FULL_THROTTLE_RANGE
	rjmp	find_throttle_gain_calculate

	ldi	Temp3, 0			
	ldi	Temp4, 255		

find_throttle_gain_calculate:
	; Calculate difference
	mov	XH, Temp4
	sub	XH, Temp3
	mov	Temp5, XH
	; Check that difference is minimum 130
	subi	XH, 130
	brcc	PC+3

	ldi	XH, 130
	mov	Temp5, XH

	; Find gain
	ldi	Temp1, 0
test_throttle_gain:
	inc	Temp1
	mul	Temp5, Temp1		; Temp5 has difference, Temp1 has gain
	mov	XH, Mul_Res_H		
	subi	XH, 128
	brcs	test_throttle_gain
	sts	Ppm_Throttle_Gain, Temp1	; Store gain
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
	sbr	Flags3, (1<<FULL_THROTTLE_RANGE)	; Set range to 1000-2020us
	xcall find_throttle_gain		; Set throttle gain
	xcall wait30ms		
	ldi	Temp3, 0
	ldi	Temp4, 0
	ldi	XH, 16			; Average 16 measurments
	mov	Temp5, XH
average_throttle_meas:
	xcall wait3ms			; Wait for new RC pulse value
	lds	XH, New_Rcp		; Get new RC pulse value
	add	Temp3, XH
	ldi	XH, 0
	adc 	Temp4, XH
	dec	Temp5
	brne	average_throttle_meas

	ldi	XH, 4			; Shift 4 times
average_throttle_div:
	lsr	Temp4   			; Shift right 
	ror	Temp3
	dec	XH   
	brne	average_throttle_div

	mov	Temp7, Temp3		; Copy to Temp7
	cbr	Flags3, (1<<FULL_THROTTLE_RANGE)
	xcall find_throttle_gain		; Set throttle gain
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
	; Disable interrupts explicitly
	cli
	; Check fuse high bits
	ldi	ZL, 0x03
	ldi	ZH, 0x00
	Prepare_Lock_Or_Fuse_Read XH
	lpm	XH, Z
	andi	XH, 0x80
	breq	reset			; If RSTDISBL is programmed, then loop here

	; Disable watchdog
	Disable_Watchdog XH
	; Initialize MCU
	Initialize_MCU XH
	; Initialize stack
	ldi	XH, high(RAMEND)	; Stack = RAMEND
	out	SPH, XH
	ldi	XH, low(RAMEND)
	out 	SPL, XH
	; Switch power off
	xcall switch_power_off
	; PortB initialization
	ldi	XH, INIT_PB		
	out	PORTB, XH
	ldi	XH, DIR_PB
	out	DDRB, XH
	; PortC initialization
	ldi	XH, INIT_PC
	out	PORTC, XH
	ldi	XH, DIR_PC
	out	DDRC, XH
	; PortD initialization
	ldi	XH, INIT_PD
	out	PORTD, XH
	ldi	XH, DIR_PD
	out	DDRD, XH
	; Set default programmed parameters
	xcall set_default_parameters
	; Read all programmed parameters
	xcall read_all_eeprom_parameters
	; Set beep strength
	lds	Temp1, Pgm_Beep_Strength
	sts	Beep_Strength, Temp1
	; Initializing beep
	cli					; Disable interrupts explicitly
	xcall wait200ms	
	xcall beep_f1
	xcall wait30ms
	xcall beep_f2
	xcall wait30ms
	xcall beep_f3
	xcall wait30ms
.IF MODE <= 1	; Main or tail
	; Wait for receiver to initialize
	xcall wait1s
	xcall wait200ms
	xcall wait200ms
	xcall wait100ms
.ENDIF

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; No signal entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
init_no_signal:
	; Disable interrupts explicitly
	cli					
	; Clear registers r0 through r25
	clr	Zero
	ldi	XL, low(0)		; Register number
	ldi	XH, low(0)		
clear_regs:	
	st	X+, Zero			; Clear register and post increment register number
	cpi	XL, 26			; Check register number - last register?
	brne	clear_regs		; If not last register, go back
	; Clear RAM
	ldi	XL, low(SRAM_START)
	ldi	XH, high(SRAM_START)
	ldi	Temp1, SRAM_BYTES
clear_ram:	
	st	X+, Zero
	dec	Temp1
	brne	clear_ram
	; Check if input signal is high for more than 30ms
	ldi	Temp1, 250
input_high_check_1:
	ldi	Temp2, 250
input_high_check_2:
	Read_Rcp_Int XL		; Read RCP input
	sbrs	XL, Rcp_In		; Is it high?
	rjmp	bootloader_done	; No - run normally
	dec	Temp2
	brne	input_high_check_2
	dec	Temp1
	brne	input_high_check_1
	; Jump to bootloader if present
	ldi	ZL, 0x00
.IF THIRDBOOTSTART == 0xe00
	ldi	ZH, 0x1C
.ENDIF
.IF THIRDBOOTSTART == 0x1e00
	ldi	ZH, 0x3C
.ENDIF
	lpm	XH, Z+			; Check for first bytes of SimonK bootloader
	cpi	XH, 0xE4
	brne	SK_bootloader_done
	lpm	XH, Z+
	cpi	XH, 0xE0
	brne	SK_bootloader_done
	lpm	XH, Z+
	cpi	XH, 0xFF
	brne	SK_bootloader_done

	rjmp	jmp_to_bootloader

SK_bootloader_done:
	ldi	ZL, 0x00
	inc	ZH				; BLHeli bootloader is smaller
	inc	ZH
	lpm	XH, Z+			; Check for first bytes of BLHeli bootloader
	cpi	XH, 0xF8
	brne	bootloader_done
	lpm	XH, Z+
	cpi	XH, 0x94
	brne	bootloader_done
	lpm	XH, Z+
	cpi	XH, 0xAA
	brne	bootloader_done

jmp_to_bootloader:
	clr	ZL
	lsr	ZH
	ijmp					; Jump to bootloader
	

bootloader_done:
	; Initialize LFSR
	ldi	XH, 1
	sts	Random, XH
	; Set default programmed parameters
	xcall set_default_parameters
	; Read all programmed parameters
	xcall read_all_eeprom_parameters
	; Decode parameters
	xcall decode_parameters
	; Decode settings
	xcall decode_settings
	; Set BEC voltage
	xcall set_bec_voltage
	; Find throttle gain from stored min and max settings
	xcall find_throttle_gain
	; Set beep strength
	lds	Temp1, Pgm_Beep_Strength
	sts	Beep_Strength, Temp1
	; Switch power off
	xcall switch_power_off
	; Timer0: clk/8 for regular interrupts
	ldi	XH, (1<<CS01)
	Set_Timer0_CS0 XH
	; Timer1: clk/8 for commutation control and RC pulse measurement
	ldi	XH, (1<<CS11)
	Set_Timer1_CS1 XH
	; Timer2: clk/8 for pwm
	ldi	XH, (1<<CS21)
	Set_Timer2_CS2 XH
	; Initialize interrupts and registers
	Initialize_Interrupts XH			; Set all
	Comp_Init XH					; Initialize comparator
	; Initialize ADC interrupt enable bits
	; Initialize comparator
	Initialize_Adc	XH				; Initialize ADC operation
	xcall wait1ms
	sei							; Enable all interrupts

	; Measure number of lipo cells
	xcall Measure_Lipo_Cells			; Measure number of lipo cells
	; Initialize RC pulse
	Rcp_Int_Enable XH	 			; Enable interrupt
	Rcp_Clear_Int_Flag XH			; Clear interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	xcall wait200ms
	; Set initial arm variable
	ldi	XH, 1
	sts	Initial_Arm, XH

	; Measure PWM frequency
measure_pwm_freq_init:	
	sbr	Flags0, (1<<RCP_MEAS_PWM_FREQ)	; Set measure pwm frequency flag
	ldi	Temp4, 3						; Number of attempts before going back to detect input signal
measure_pwm_freq_start:	
	ldi	Temp3, 12						; Number of pulses to measure
measure_pwm_freq_loop:	
	; Check if period diff was accepted
	lds	XH, Rcp_Period_Diff_Accepted
	tst	XH
	brne	measure_pwm_freq_wait

	ldi	Temp3, 12						; Reset number of pulses to measure
	dec	Temp4
	brne	PC+2
	rjmp	init_no_signal

measure_pwm_freq_wait:
	xcall wait30ms						; Wait 30ms for new pulse
	sbrs	Flags2, RCP_UPDATED				; Is there an updated RC pulse available - proceed
	rjmp	init_no_signal					; Go back to detect input signal

	cbr	Flags2, (1<<RCP_UPDATED)	 		; Flag that pulse has been evaluated
	lds	XH, New_Rcp					; Load value
	cpi	XH, RCP_VALIDATE				; Higher than validate level?
	brcs	measure_pwm_freq_start			; No - start over

	mov	XH, Flags3					; Check pwm frequency flags
	andi	XH, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	lds	Temp1, Curr_Rcp_Pwm_Freq			; Store as previous flags for next pulse 
	sts	Prev_Rcp_Pwm_Freq, Temp1
	sts	Curr_Rcp_Pwm_Freq, XH			; Store current flags for next pulse 
	cp	XH, Temp1
	brne	measure_pwm_freq_start			; Go back if new flags not same as previous

	dec	Temp3
	brne	measure_pwm_freq_loop			; Go back if not required number of pulses seen

	; Clear measure pwm frequency flag
	cbr	Flags0, (1<<RCP_MEAS_PWM_FREQ)		
	; Set up RC pulse interrupts after pwm frequency measurement
	Rcp_Int_First XH					; Enable interrupt and set to first edge
	Rcp_Clear_Int_Flag XH				; Clear interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)			; Set first edge flag
	lds	XH, Pgm_Enable_PWM_Input			; Check if PWM input is enabled
	tst	XH
	brne	test_for_oneshot				; If it is - proceed

	sbr	Flags2, (1<<RCP_PPM)			; Set PPM flag		
	mov	XH, Flags3					; Clear pwm frequency flags
	andi	XH, !((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	mov	Flags3, XH

test_for_oneshot:
	; Test whether signal is OnShot125
	cbr	Flags2, (1<<RCP_PPM_ONESHOT125)	; Clear OneShot125 flag
	sts	Rcp_Outside_Range_Cnt, Zero		; Reset out of range counter
	xcall wait100ms					; Wait for new RC pulses
	sbrs	Flags2, RCP_PPM		
	rjmp	validate_rcp_start				; If flag is not set (PWM) - branch

	lds	XH, Rcp_Outside_Range_Cnt		; Check how many pulses were outside normal PPM range (800-2160us)
	cpi	XH, 10						
	brcs	validate_rcp_start

	sbr	Flags2, (1<<RCP_PPM_ONESHOT125)	; Set OneShot125 flag

	; Validate RC pulse
validate_rcp_start:	
	xcall wait3ms						; Wait for next pulse (NB: Uses Temp1/2!) 
	ldi	Temp1, RCP_VALIDATE				; Set validate level as default
	sbrs	Flags2, RCP_PPM		
	rjmp	PC+2							; If flag is not set (PWM) - branch

	ldi	Temp1, 0						; Set level to zero for PPM (any level will be accepted)

	lds	XH, New_Rcp					; Load value
	cp	XH, Temp1						; Higher than validate level?
	brcs	validate_rcp_start				; No - start over

	; Beep arm sequence start signal
	cli								; Disable all interrupts
	xcall beep_f1						; Signal that RC pulse is ready
	xcall beep_f1
	xcall beep_f1
	sei								; Enable all interrupts
	xcall wait200ms	

	; Arming sequence start
	sts	Gov_Arm_Target, Zero	; Clear governor arm target
arming_start:
.IF MODE >= 1	; Tail or multi
	lds	XH, Pgm_Direction		; Check if bidirectional operation
	cpi	XH, 3
	brne	PC+2

	rjmp	program_by_tx_checked	; Disable tx programming if bidirectional operation
.ENDIF

	xcall wait3ms
	lds	XH, Pgm_Enable_TX_Program; Start programming mode entry if enabled
	cpi	XH, 1				; Is TX programming enabled?
	brcc	arming_initial_arm_check	; Yes - proceed

	rjmp	program_by_tx_checked	; No - branch

arming_initial_arm_check:
	lds	XH, Initial_Arm		; Yes - check if it is initial arm sequence
	cpi	XH, 1				; Is it the initial arm sequence?
	brcc	arming_ppm_check		; Yes - proceed

	rjmp program_by_tx_checked	; No - branch

arming_ppm_check:
	sbrc	Flags2, RCP_PPM		
	rjmp	throttle_high_cal_start	; If flag is set (PPM) - branch

	; PWM tx program entry
	lds	XH, New_Rcp			; Load new RC pulse value
	cpi	XH, RCP_MAX			; Is RC pulse max?
	brcc	program_by_tx_entry_pwm	; Yes - proceed

	rjmp	program_by_tx_checked	; No - branch

program_by_tx_entry_pwm:	
	cli						; Disable all interrupts
	xcall beep_f4
	sei						; Enable all interrupts
	xcall wait100ms
	lds	XH, New_Rcp			; Load new RC pulse value
	cpi	XH, RCP_STOP			; Below stop?
	brcc	program_by_tx_entry_pwm	; No - start over

program_by_tx_entry_wait_pwm:	
	cli						; Disable all interrupts
	xcall beep_f1
	xcall wait10ms
	xcall beep_f1
	sei						; Enable all interrupts
	xcall wait100ms
	lds	XH, New_Rcp			; Load new RC pulse value
	cpi	XH, RCP_MAX			; At or above max?
	brcs	program_by_tx_entry_wait_pwm	; No - start over

	rjmp	program_by_tx			; Yes - enter programming mode

	; PPM throttle calibration and tx program entry
throttle_high_cal_start:
.IF MODE <= 1	; Main or tail
	ldi	XH, 8				; Set 3 seconds wait time
.ELSE
	ldi	XH, 3				; Set 1 second wait time
.ENDIF
	mov	Temp8, XH		
throttle_high_cal:			
	sbr	Flags3, (1<<FULL_THROTTLE_RANGE)	; Set range to 1000-2020us
	cli		
	xcall find_throttle_gain		; Set throttle gain
	sei		
	xcall wait100ms			; Wait for new throttle value
	cli						; Disable interrupts (freeze New_Rcp value)
	cbr	Flags3, (1<<FULL_THROTTLE_RANGE)	; Set programmed range
	xcall find_throttle_gain		; Set throttle gain
	lds	Temp7, New_Rcp			; Store new RC pulse value
	lds	XH, New_Rcp			; Load new RC pulse value
	cpi	XH, (RCP_MAX/2)		; Is RC pulse above midstick?
	sei						; Enable interrupts
	brcc	PC+2
	rjmp	arm_target_updated		; No - branch

	xcall wait1ms		
	cli						; Disable all interrupts
	xcall beep_f4
	sei						; Enable all interrupts
	dec	Temp8				
	brne	throttle_high_cal		; Continue to wait

	xcall average_throttle
	mov	XH, Temp7				; Limit to max 250
	subi	XH, 5				; Subtract about 2% and ensure that it is 250 or lower
	sts	Pgm_Ppm_Max_Throttle, XH	; Store
	xcall wait200ms				
	cli					
	xcall store_all_in_eeprom	
	xcall success_beep
	sei					

throttle_low_cal_start:
	ldi	XH, 10				; Set 3 seconds wait time
	mov	Temp8, XH
throttle_low_cal:			
	sbr	Flags3, (1<<FULL_THROTTLE_RANGE)	; Set range to 1000-2020us
	cli		
	xcall find_throttle_gain		; Set throttle gain
	sei		
	xcall wait100ms
	cli						; Disable interrupts (freeze New_Rcp value)
	cbr	Flags3, (1<<FULL_THROTTLE_RANGE)	; Set programmed range
	xcall find_throttle_gain		; Set throttle gain
	lds	Temp7, New_Rcp			; Store new RC pulse value
	lds	XH, New_Rcp			; Load new RC pulse value
	cpi	XH, (RCP_MAX/2)		; Below midstick?
	sei						; Enable interrupts
	brcc	throttle_low_cal_start	; No - start over

	xcall wait1ms		
	cli						; Disable all interrupts
	xcall beep_f1
	xcall wait10ms
	xcall beep_f1
	sei						; Enable all interrupts
	dec	Temp8				
	brne	throttle_low_cal		; Continue to wait

	xcall average_throttle
	mov	XH, Temp7			
	subi	XH, 0xFB				; Add about 2% (subtract negative number)
	sts	Pgm_Ppm_Min_Throttle, XH	; Store
	xcall wait200ms				
	cli					
	xcall store_all_in_eeprom	
	xcall success_beep_inverted
	sei					

program_by_tx_entry_wait_ppm:	
	xcall wait100ms
	cli					
	xcall find_throttle_gain		; Set throttle gain
	sei
	lds	XH, New_Rcp			; Load new RC pulse value
	cpi	XH, RCP_MAX			; At or above max?
	brcs	program_by_tx_entry_wait_ppm	; No - start over

	rjmp	program_by_tx			; Yes - enter programming mode

program_by_tx_checked:
	lds	Temp1, New_Rcp			; Load new RC pulse value
	lds	XH, Gov_Arm_Target		; Is RC pulse larger than arm target?
	cp	Temp1, XH
	brcs	arm_target_updated		; No - do not update

	sts	Gov_Arm_Target, Temp1	; Yes - update arm target

arm_target_updated:
	xcall wait100ms			; Wait for new throttle value
	ldi	Temp1, RCP_STOP		; Default stop value
	lds	XH, Pgm_Direction		; Check if bidirectional operation
	subi	XH, 3
	brne	PC+2					; No - branch

	ldi	Temp1, (RCP_STOP+4)		; Higher stop value for bidirectional

	lds	XH, New_Rcp			; Load new RC pulse value
	cp	XH, Temp1				; Below stop?
	brcs	arm_end_beep			; Yes - proceed

	rjmp	arming_start			; No - start over

arm_end_beep:
	; Beep arm sequence end signal
	cli						; Disable all interrupts
	xcall beep_f4				; Signal that rcpulse is ready
	xcall beep_f4
	xcall beep_f4
	sei						; Enable all interrupts
	xcall wait200ms

	; Clear initial arm variable
	sts	Initial_Arm, Zero

	; Armed and waiting for power on
wait_for_power_on:
	sts	Power_On_Wait_Cnt_L, Zero; Clear wait counter
	sts	Power_On_Wait_Cnt_H, Zero	
wait_for_power_on_loop:
	lds	XH, Power_On_Wait_Cnt_L	; Increment low wait counter
	inc	XH
	sts	Power_On_Wait_Cnt_L, XH
	cpi	XH, 0xFF
	brne	wait_for_power_on_no_beep; Counter wrapping (about 1 sec)?

	lds	XH, Power_On_Wait_Cnt_H	; Increment high wait counter
	inc	XH
	sts	Power_On_Wait_Cnt_H, XH
	lds	XH, Pgm_Beacon_Delay
	ldi	Temp1, 25			; Approximately 1 min
	dec	XH
	breq	beep_delay_set

	ldi	Temp1, 50			; Approximately 2 min
	dec	XH
	breq	beep_delay_set

	ldi	Temp1, 125		; Approximately 5 min
	dec	XH
	breq	beep_delay_set

	ldi	Temp1, 250		; Approximately 10 min
	dec	XH
	breq	beep_delay_set

	sts	Power_On_Wait_Cnt_H, Zero; Reset counter for infinite delay

beep_delay_set:
	lds	XH, Power_On_Wait_Cnt_H
	cp	XH, Temp1				; Check against chosen delay
	brcs	wait_for_power_on_no_beep; Has delay elapsed?

	lds	XH, Power_On_Wait_Cnt_H	; Decrement high wait counter
	dec	XH
	sts	Power_On_Wait_Cnt_H, XH
	ldi	XH, 180				; Set low wait counter
	sts	Power_On_Wait_Cnt_L, XH
	lds	XH, Pgm_Beacon_Strength
	sts	Beep_Strength, XH
	cli						; Disable all interrupts
	xcall beep_f4				; Signal that there is no signal
	sei						; Enable all interrupts
	lds	XH, Pgm_Beep_Strength
	sts	Beep_Strength, XH
	xcall wait100ms				; Wait for new RC pulse to be measured

wait_for_power_on_no_beep:
	xcall wait10ms
	lds	XH, Rcp_Timeout_Cnt				; Load RC pulse timeout counter value
	tst	XH
	brne	wait_for_power_on_ppm_not_missing	; If it is not zero - proceed

	sbrs	Flags2, RCP_PPM		
	rjmp	wait_for_power_on_ppm_not_missing	; If flag is not set (PWM) - branch

	rjmp	init_no_signal					; If ppm and pulses missing - go back to detect input signal

wait_for_power_on_ppm_not_missing:
	ldi	Temp1, RCP_STOP
	sbrc	Flags2, RCP_PPM		
	rjmp	PC+2					; If flag is set (PPM) - branch
	ldi	Temp1, (RCP_STOP+5) 	; Higher than stop (for pwm)
	lds	XH, New_Rcp			; Load new RC pulse value
	cp	XH, Temp1
	brcc	PC+2
	rjmp	wait_for_power_on_loop	; No - start over

.IF MODE >= 1	; Tail or multi
	lds	XH, Pgm_Direction		; Check if bidirectional operation
	subi	XH, 3
	breq	wait_for_power_on_check_timeout	; Do not wait if bidirectional operation
.ENDIF

	xcall wait100ms			; Wait to see if start pulse was only a glitch

wait_for_power_on_check_timeout:
	lds	XH, Rcp_Timeout_Cnt		; Load RC pulse timeout counter value
	tst	XH
	brne	PC+2					; If it is not zero - proceed

	rjmp	init_no_signal			; If it is zero (pulses missing) - go back to detect input signal


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Start entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
init_start:
	cli
	xcall switch_power_off
	sts	Requested_Pwm, Zero		; Set requested pwm to zero
	sts	Governor_Req_Pwm, Zero	; Set governor requested pwm to zero
	sts	Current_Pwm, Zero		; Set current pwm to zero
	mov	Current_Pwm_Limited, Zero; Set limited current pwm to zero
	sts	Current_Pwm_Lim_Dith, Zero
	sts	Pwm_Dither_Excess_Power, Zero
	sei
	lds	XH, Pgm_Motor_Idle		; Set idle pwm to programmed value
	lsl	XH
	sts	Pwm_Motor_Idle, XH					
	sts	Gov_Target_L, Zero		; Set target to zero
	sts	Gov_Target_H, Zero
	sts	Gov_Integral_L, Zero	; Set integral to zero
	sts	Gov_Integral_H, Zero
	sts	Gov_Integral_X, Zero
	sts	Adc_Conversion_Cnt, Zero
	ldi	Flags0, 0				; Clear flags0
	ldi	Flags1, 0				; Clear flags1
	sts	Demag_Detected_Metric, Zero	; Clear demag metric
	;**** **** **** **** ****
	; Motor start beginning
	;**** **** **** **** **** 
	ldi	XH, TEMP_CHECK_RATE					; Make sure a temp reading is done
	sts	Adc_Conversion_Cnt, XH
	Set_Adc_Ip_Temp
	xcall wait1ms
	Start_Adc XH
read_initial_temp:
	Get_Adc_Status XH
	sbrc	XH, ADSC
	rjmp	read_initial_temp
	Read_Adc_Result Temp1, Temp2				; Read initial temperature
	Stop_Adc XH
	tst	Temp2
	breq	PC+2								; Is reading below 256?

	ldi	Temp1, 0xFF						; No - set average temperature value to 255

	sts	Current_Average_Temp_Adc, Temp1		; Set initial average temp ADC reading
	xcall check_temp_voltage_and_limit_power
	ldi	XH, TEMP_CHECK_RATE					; Make sure a temp reading is done next time
	sts	Adc_Conversion_Cnt, XH
	Set_Adc_Ip_Temp
	; Set up start operating conditions
	lds	Temp7, Pgm_Pwm_Freq		; Store setting in Temp7
	ldi	XH, 2				; Set nondamped low frequency pwm mode
	sts	Pgm_Pwm_Freq, XH
	xcall decode_parameters		; (Decode_parameters uses Temp1 and Temp8)
	sts	Pgm_Pwm_Freq, Temp7		; Restore settings
	; Set max allowed power
	cli						; Disable interrupts to avoid that Requested_Pwm is overwritten
	ldi	XH, 0xFF				; Set pwm limit to max
	sts	Pwm_Limit, XH
	xcall set_startup_pwm
	lds	XH, Requested_Pwm
	sts	Pwm_Limit, XH
	sts	Pwm_Limit_Spoolup, XH
	sts	Pwm_Limit_Low_Rpm, XH
	sei
	ldi	XH, 1				; Set low pwm again after calling set_startup_pwm
	sts	Requested_Pwm, XH
	sts	Current_Pwm, XH
	mov	Current_Pwm_Limited, XH
	sts	Current_Pwm_Lim_Dith, XH
	sts	Spoolup_Limit_Skip, XH			
	lds	XH, Auto_Bailout_Armed
	sts	Spoolup_Limit_Cnt, XH
	; Begin startup sequence
	sbr	Flags1, (1<<MOTOR_SPINNING)	; Set motor spinning flag
	sbr	Flags1, (1<<STARTUP_PHASE)	; Set startup phase flag
	sts	Startup_Cnt, Zero			; Reset counter
	xcall comm5comm6				; Initialize commutation
	xcall comm6comm1				
	xcall calc_next_comm_timing		; Set virtual commutation point
	xcall calc_next_comm_timing	
	xcall initialize_timing			; Initialize timing
	xcall calc_next_comm_timing	
	xcall calc_new_wait_times		; Calculate new wait times
	xcall initialize_timing			; Initialize timing
	xcall set_comparator_phase
	xcall wait_before_zc_scan		; Set up comparator timeout
	rjmp	run1



;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Run entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
damped_transition:
	; Transition from nondamped to damped if applicable
	cli
	xcall decode_parameters		; Set programmed parameters
	sei
	sts	Adc_Conversion_Cnt, Zero	; Make sure a voltage reading is done next time
	Set_Adc_Ip_Volt			; Set adc measurement to voltage

; Run 1 = B(p-on) + C(n-pwm) - comparator A evaluated
; Out_cA changes from low to high
run1:
	xcall wait_for_comp_out_high	; Wait zero cross wait and wait for high
	xcall setup_comm_wait		; Setup wait time from zero cross to commutation
	xcall evaluate_comparator_integrity	; Check whether comparator reading has been normal
	xcall calc_governor_target	; Calculate governor target
	xcall wait_for_comm			; Wait from zero cross to commutation
	xcall comm1comm2			; Commutate
	xcall calc_next_comm_timing	; Calculate next timing and start advance timing wait
	xcall wait_advance_timing	; Wait advance timing and start zero cross wait
	xcall calc_new_wait_times
	xcall set_comparator_phase	; Set comparator phase
	xcall wait_before_zc_scan	; Wait zero cross wait and start zero cross timeout

; Run 2 = A(p-on) + C(n-pwm) - comparator B evaluated
; Out_cB changes from high to low
run2:
	xcall wait_for_comp_out_low
	xcall setup_comm_wait	
	xcall evaluate_comparator_integrity
	sbrc	Flags0, GOV_ACTIVE				
	xcall calc_governor_prop_error
	xcall set_pwm_limit_low_rpm
	xcall wait_for_comm
	xcall comm2comm3
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall set_comparator_phase
	xcall wait_before_zc_scan	

; Run 3 = A(p-on) + B(n-pwm) - comparator C evaluated
; Out_cC changes from low to high
run3:
	xcall wait_for_comp_out_high
	xcall setup_comm_wait	
	xcall evaluate_comparator_integrity
	sbrc	Flags0, GOV_ACTIVE				
	xcall calc_governor_int_error
	xcall wait_for_comm
	xcall comm3comm4
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall set_comparator_phase
	xcall wait_before_zc_scan	

; Run 4 = C(p-on) + B(n-pwm) - comparator A evaluated
; Out_cA changes from high to low
run4:
	xcall wait_for_comp_out_low
	xcall setup_comm_wait	
	xcall evaluate_comparator_integrity
	sbrc	Flags0, GOV_ACTIVE				
	xcall calc_governor_prop_correction
	xcall wait_for_comm
	xcall comm4comm5
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall set_comparator_phase
	xcall wait_before_zc_scan	

; Run 5 = C(p-on) + A(n-pwm) - comparator B evaluated
; Out_cB changes from low to high
run5:
	xcall wait_for_comp_out_high
	xcall setup_comm_wait	
	xcall evaluate_comparator_integrity
	sbrc	Flags0, GOV_ACTIVE				
	xcall calc_governor_int_correction
	xcall wait_for_comm
	xcall comm5comm6
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall set_comparator_phase
	xcall wait_before_zc_scan	

; Run 6 = B(p-on) + A(n-pwm) - comparator C evaluated
; Out_cC changes from high to low
run6:
	xcall wait_for_comp_out_low
	Start_Adc XH
	xcall setup_comm_wait	
	xcall evaluate_comparator_integrity
	xcall wait_for_comm
	xcall comm6comm1
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall check_temp_voltage_and_limit_power
	xcall set_comparator_phase
	xcall wait_before_zc_scan	

	; Check if it is startup
	sbrs	Flags1, STARTUP_PHASE
	rjmp	normal_run_checks
	sbrc	Flags0, DIR_CHANGE_BRAKE		; If a direction change - branch
	rjmp	normal_run_checks

	; Set spoolup power variables
	lds	XH, Pwm_Spoolup_Beg
	sts	Pwm_Limit, XH				; Set initial max power
	sts	Pwm_Limit_Spoolup, XH		; Set initial slow spoolup power
	lds	XH, Auto_Bailout_Armed
	sts	Spoolup_Limit_Cnt, XH
	ldi	XH, 1
	sts	Spoolup_Limit_Skip, XH			
	; Check startup counter
	ldi	Temp2, 24					; Set nominal startup parameters
	ldi	Temp3, 12
	lds	XH, Startup_Cnt			; Load counter
	cp	XH, Temp2					; Is counter above requirement?
	brcs	start_check_rcp			; No - proceed

	cbr	Flags1, (1<<STARTUP_PHASE)	; Clear startup phase flag
	sbr	Flags1, (1<<INITIAL_RUN_PHASE); Set initial run phase flag
	sts	Initial_Run_Rot_Cnt, Temp3	; Set initial run rotation count
.IF MODE == 1	; Tail
	ldi	XH, 0xFF
	sts	Pwm_Limit, XH				; Allow full power
	sts	Pwm_Limit_Spoolup, XH	
.ENDIF
.IF MODE == 2	; Multi
	lds	XH, Pwm_Spoolup_Beg
	sts	Pwm_Limit, XH
	sts	Pwm_Limit_Low_Rpm, XH
	ldi	XH, 0xFF
	sts	Pwm_Limit_Spoolup, XH	
.ENDIF
	rjmp	normal_run_checks

start_check_rcp:
	lds	XH, New_Rcp				; Load new pulse value
	cpi	XH, RCP_STOP				; Check if pulse is below stop value
	brcs	PC+2

	rjmp	run1						; Continue to run 

	rjmp	run_to_wait_for_power_on


normal_run_checks:
	; Check if it is initial run phase
	sbrs	Flags1, INITIAL_RUN_PHASE	; If not initial run phase - branch
	rjmp	initial_run_phase_done
	sbrc	Flags0, DIR_CHANGE_BRAKE		; If a direction change - branch
	rjmp	initial_run_phase_done

	; Decrement startup rotation count
	lds	XH, Initial_Run_Rot_Cnt
	dec	XH
	; Check number of nondamped rotations
	brne	normal_run_check_startup_rot	; Branch if counter is not zero

	cbr	Flags1, (1<<INITIAL_RUN_PHASE); Clear initial run phase flag
	rjmp damped_transition			; Do damped transition if counter is zero

normal_run_check_startup_rot:
	sts	Initial_Run_Rot_Cnt, XH		; Not zero - store counter
	lds	XH, New_Rcp				; Load new pulse value
	cpi	XH, RCP_STOP				; Check if pulse is below stop value
	brcs	PC+2

	rjmp	run1						; Continue to run 

	rjmp	run_to_wait_for_power_on


initial_run_phase_done:
.IF MODE == 0	; Main
	; Check if throttle is zeroed
	lds	XH, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	cpi	XH, 1					; Is number of stop RC pulses above limit?
	brcs	run6_check_rcp_stop_count	; If no - branch

	lds	XH, Pwm_Spoolup_Beg			; If yes - set initial max powers
	sts	Pwm_Limit_Spoolup, XH	
	lds	XH, Auto_Bailout_Armed		; And set spoolup parameters
	sts	Spoolup_Limit_Cnt, XH
	ldi	XH, 1
	sts	Spoolup_Limit_Skip, XH			

run6_check_rcp_stop_count:
.ENDIF
	; Exit run loop after a given time
	lds	XH, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	cpi	XH, RCP_STOP_LIMIT			; Is number of stop RC pulses above limit?
	brcc	run_to_wait_for_power_on		; Yes, go back to wait for poweron

run6_check_rcp_timeout:
	sbrs	Flags2, RCP_PPM		
	rjmp	run6_check_speed			; If flag is not set (PWM) - branch

	lds	XH, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	tst	XH
	breq	run_to_wait_for_power_on		; If it is zero - go back to wait for poweron

run6_check_speed:
	ldi	Temp1, 0xF0				; Default minimum speed
	sbrs	Flags0, DIR_CHANGE_BRAKE		; Is it a direction change?
	rjmp	run6_brake_done

	lds	XH, Brake_Cnt				; "Timeout" on braking (in case comparator noise keeps motor "running")
	inc	XH
	sts	Brake_Cnt, XH
	cpi	XH, 150 
	brcc	run_to_wait_for_power_on
	ldi	Temp1, 0x50				; Bidirectional braking termination speed 

run6_brake_done:
	lds	XH, Comm_Period4x_H			; Is Comm_Period4x more than 32ms (~1220 eRPM)?
	cp	XH, Temp1
	brcc	run_to_wait_for_power_on		; Yes - go back to motor start
	rjmp	run1						; Go back to run 1


run_to_wait_for_power_on:	
	sbrs	Flags0, DIR_CHANGE_BRAKE		; Is it a direction change?
	rjmp	run_to_wait_for_power_on_brake_done

	All_pFETs_on
	xcall wait30ms					; Additional braking for motor to stop
	
run_to_wait_for_power_on_brake_done:
	cli
	xcall switch_power_off
	lds	Temp7, Pgm_Pwm_Freq			; Store setting in Temp7
	ldi	XH, 2					; Set low pwm mode (in order to turn off damping)
	sts	Pgm_Pwm_Freq, XH
	xcall decode_parameters			; (Decode_parameters uses Temp1 and Temp8)
	sts	Pgm_Pwm_Freq, Temp7			; Restore settings
	sts	Requested_Pwm, Zero			; Set requested pwm to zero
	sts	Governor_Req_Pwm, Zero		; Set governor requested pwm to zero
	sts	Current_Pwm, Zero			; Set current pwm to zero
	mov	Current_Pwm_Limited, Zero	; Set limited current pwm to zero
	sts	Current_Pwm_Lim_Dith, Zero	
	sts	Pwm_Motor_Idle, Zero		; Set motor idle to zero
	cbr	Flags1, (1<<MOTOR_SPINNING)	; Clear motor spinning flag
	sei
	xcall wait1ms					; Wait for pwm to be stopped
	xcall switch_power_off
.IF MODE == 0	; Main
	sbrs	Flags2, RCP_PPM		
	rjmp	run_to_next_state_main		; If flag is not set (PWM) - branch

	lds	XH, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	tst	XH
	brne	run_to_next_state_main		; If it is not zero - branch

	rjmp	init_no_signal				; If it is zero (pulses missing) - go back to detect input signal

run_to_next_state_main:
	lds	XH, Pgm_Main_Rearm_Start
	cpi	XH, 1					; Is re-armed start enabled?
	brcs	jmp_wait_for_power_on		; No - do like tail and start immediately

	rjmp	validate_rcp_start			; Yes - go back to validate RC pulse

jmp_wait_for_power_on:
	rjmp	wait_for_power_on			; Go back to wait for power on
.ENDIF
.IF MODE >= 1	; Tail or multi
	sbrs	Flags2, RCP_PPM		
	rjmp	jmp_wait_for_power_on		; If flag is not set (PWM) - branch

	lds	XH, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	tst	XH
	brne	jmp_wait_for_power_on		; If it is not zero - go back to wait for poweron

	rjmp	init_no_signal				; If it is zero (pulses missing) - go back to detect input signal

jmp_wait_for_power_on:
	rjmp	wait_for_power_on			; Go back to wait for power on
.ENDIF

;**** **** **** **** **** **** **** **** **** **** **** **** ****

.INCLUDE "BLHeliTxPgm.inc"			; Include source code for programming the ESC with the TX

;**** **** **** **** **** **** **** **** **** **** **** **** ****



.EXIT
