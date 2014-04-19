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
;#define MULTISTAR_15A_MAIN			; Inverted input
;#define MULTISTAR_15A_TAIL
;#define MULTISTAR_15A_MULTI
;#define MULTISTAR_20A_MAIN			; Inverted input
;#define MULTISTAR_20A_TAIL
;#define MULTISTAR_20A_MULTI
;#define MULTISTAR_30A_MAIN			; Inverted input
;#define MULTISTAR_30A_TAIL
;#define MULTISTAR_30A_MULTI
;#define MULTISTAR_45A_MAIN			; Inverted input
;#define MULTISTAR_45A_TAIL
;#define MULTISTAR_45A_MULTI
;#define MYSTERY_30A_MAIN			
;#define MYSTERY_30A_TAIL
;#define MYSTERY_30A_MULTI
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
;#define AFRO_30A_MAIN				; ICP1 as input		
;#define AFRO_30A_TAIL
;#define AFRO_30A_MULTI



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
.EQU	DEFAULT_PGM_MAIN_P_GAIN 			= 7 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
.EQU	DEFAULT_PGM_MAIN_I_GAIN 			= 7 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
.EQU	DEFAULT_PGM_MAIN_GOVERNOR_MODE 	= 1 	; 1=Tx 		2=Arm 		3=Setup		4=Off
.EQU	DEFAULT_PGM_MAIN_GOVERNOR_RANGE 	= 1 	; 1=High		2=Middle		3=Low
.EQU	DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	= 4 	; 1=Off		2=3.0V/c		3=3.1V/c		4=3.2V/c		5=3.3V/c	6=3.4V/c
.EQU	DEFAULT_PGM_MAIN_COMM_TIMING		= 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
.EQU	DEFAULT_PGM_MAIN_THROTTLE_RATE	= 13	; 1=2		2=3			3=4			4=6 			5=8	 	6=12 	7=16	  8=24  9=32  10=48  11=64  12=128 13=255
.EQU	DEFAULT_PGM_MAIN_DAMPING_FORCE	= 1 	; 1=VeryLow 	2=Low 		3=MediumLow 	4=MediumHigh 	5=High	6=Highest
.EQU	DEFAULT_PGM_MAIN_PWM_FREQ 		= 2 	; 1=High 		2=Low		3=DampedLight
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
.EQU	DEFAULT_PGM_TAIL_THROTTLE_RATE	= 13	; 1=2		2=3			3=4			4=6 			5=8	 	6=12 	7=16	  8=24  9=32  10=48  11=64  12=128 13=255
.EQU	DEFAULT_PGM_TAIL_DAMPING_FORCE	= 5 	; 1=VeryLow 	2=Low 		3=MediumLow 	4=MediumHigh 	5=High	6=Highest
.IF DAMPED_MODE_ENABLE == 1
.EQU	DEFAULT_PGM_TAIL_PWM_FREQ	 	= 4 	; 1=High 		2=Low 		3=DampedLight  4=Damped 	
.ELSE
.EQU	DEFAULT_PGM_TAIL_PWM_FREQ	 	= 3 	; 1=High 		2=Low		3=DampedLight
.ENDIF
.EQU	DEFAULT_PGM_TAIL_DEMAG_COMP 		= 1 	; 1=Disabled	2=Low		3=High
.EQU	DEFAULT_PGM_TAIL_DIRECTION		= 1 	; 1=Normal 	2=Reversed	3=Bidirectional
.EQU	DEFAULT_PGM_TAIL_RCP_PWM_POL 		= 1 	; 1=Positive 	2=Negative
.EQU	DEFAULT_PGM_TAIL_BEEP_STRENGTH	= 250; Beep strength
.EQU	DEFAULT_PGM_TAIL_BEACON_STRENGTH	= 250; Beacon strength
.EQU	DEFAULT_PGM_TAIL_BEACON_DELAY		= 4 	; 1=1m		2=2m			3=5m			4=10m		5=Infinite
; Multi
.EQU	DEFAULT_PGM_MULTI_P_GAIN 		= 9 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
.EQU	DEFAULT_PGM_MULTI_I_GAIN 		= 9 	; 1=0.13		2=0.17		3=0.25		4=0.38 		5=0.50 	6=0.75 	7=1.00 8=1.5 9=2.0 10=3.0 11=4.0 12=6.0 13=8.0
.EQU	DEFAULT_PGM_MULTI_GOVERNOR_MODE 	= 4 	; 1=HiRange	2=MidRange	3=LoRange		4=Off
.EQU	DEFAULT_PGM_MULTI_GAIN 			= 3 	; 1=0.75 		2=0.88 		3=1.00 		4=1.12 		5=1.25
.EQU	DEFAULT_PGM_MULTI_LOW_VOLTAGE_LIM	= 1 	; 1=Off		2=3.0V/c		3=3.1V/c		4=3.2V/c		5=3.3V/c	6=3.4V/c
.EQU	DEFAULT_PGM_MULTI_COMM_TIMING		= 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
.EQU	DEFAULT_PGM_MULTI_THROTTLE_RATE	= 13	; 1=2		2=3			3=4			4=6 			5=8	 	6=12 	7=16	  8=24  9=32  10=48  11=64  12=128 13=255
.EQU	DEFAULT_PGM_MULTI_DAMPING_FORCE	= 6 	; 1=VeryLow 	2=Low 		3=MediumLow 	4=MediumHigh 	5=High	6=Highest
.IF DAMPED_MODE_ENABLE == 1
.EQU	DEFAULT_PGM_MULTI_PWM_FREQ	 	= 1 	; 1=High 		2=Low 		3=DampedLight  4=Damped 	
.ELSE
.EQU	DEFAULT_PGM_MULTI_PWM_FREQ	 	= 1 	; 1=High 		2=Low		3=DampedLight
.ENDIF
.EQU	DEFAULT_PGM_MULTI_DEMAG_COMP 		= 2 	; 1=Disabled	2=Low		3=High
.EQU	DEFAULT_PGM_MULTI_DIRECTION		= 1 	; 1=Normal 	2=Reversed	3=Bidirectional
.EQU	DEFAULT_PGM_MULTI_RCP_PWM_POL 	= 1 	; 1=Positive 	2=Negative
.EQU	DEFAULT_PGM_MULTI_BEEP_STRENGTH	= 40	; Beep strength
.EQU	DEFAULT_PGM_MULTI_BEACON_STRENGTH	= 80	; Beacon strength
.EQU	DEFAULT_PGM_MULTI_BEACON_DELAY	= 4 	; 1=1m		2=2m			3=5m			4=10m		5=Infinite
; Common
.EQU	DEFAULT_PGM_ENABLE_TX_PROGRAM 	= 1 	; 1=Enabled 	0=Disabled
.EQU	DEFAULT_PGM_PPM_MIN_THROTTLE		= 37	; 4*37+1000=1148
.EQU	DEFAULT_PGM_PPM_MAX_THROTTLE		= 208; 4*208+1000=1832
.EQU	DEFAULT_PGM_PPM_CENTER_THROTTLE	= 122; 4*122+1000=1488 (used in bidirectional mode)
.EQU	DEFAULT_PGM_BEC_VOLTAGE_HIGH		= 0	; 0=Low		1= High

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
.EQU	RCP_STOP_LIMIT		= 	250	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

.EQU	PWM_START			= 	50 	; PWM used as max power during start

.EQU	COMM_TIME_RED		= 	8	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
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

.EQU	COMM_TIME_RED		= 	8	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
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
.EQU	RCP_STOP_LIMIT		= 	250	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

.EQU	PWM_START			= 	50 	; PWM used as max power during start

.EQU	COMM_TIME_RED		= 	10	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
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
.EQU	DEMAG_DETECTED			= 	3		; Set when excessive demag time is detected
.EQU	DEMAG_CUT_POWER		= 	4		; Set when demag compensation cuts power
.EQU	GOV_ACTIVE			= 	5		; Set when governor is active
;.EQU					= 	6
;.EQU					= 	7

.DEF	Flags1				=	R23    	; State flags. Reset upon init_start 
.EQU	MOTOR_SPINNING			=	0		; Set when in motor is spinning
.EQU	STARTUP_PHASE			= 	1		; Set when in startup phase
.EQU	INITIAL_RUN_PHASE		=	2		; Set when in initial run phase, before synchronized run is achieved
.EQU	CURR_PWMOFF_DAMPED		=	3		; Currently running pwm off cycle is damped
.EQU	CURR_PWMOFF_COMP_ABLE	=	4		; Currently running pwm off cycle is usable for comparator
.EQU	ADC_READ_TEMP			= 	5		; Set when ADC input shall be set to read temperature
;.EQU					= 	6
;.EQU					= 	7


.DEF	Flags2				=	R24		; State flags. NOT reset upon init_start
.EQU	RCP_UPDATED			= 	0		; New RC pulse length value available
.EQU	RCP_EDGE_NO			= 	1		; RC pulse edge no. 0=rising, 1=falling
.EQU	PGM_PWMOFF_DAMPED		=	2		; Programmed pwm off damped mode. Set when fully damped or damped light mode is selected
.EQU	PGM_PWMOFF_DAMPED_FULL	=	3		; Programmed pwm off fully damped mode. Set when all pfets shall be on in pwm_off period
.EQU	PGM_PWMOFF_DAMPED_LIGHT	=	4		; Programmed pwm off damped light mode. Set when only 2 pfets shall be on in pwm_off period
.EQU	PGM_PWM_HIGH_FREQ		=	5		; Progremmed pwm high frequency
.EQU	RCP_INT_NESTED_ENABLED	= 	6		; Set when RC pulse interrupt is enabled around nested interrupts
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
Timer0_Int_Cnt:			.BYTE	1		; Timer0 interrupt counter

Requested_Pwm:				.BYTE	1		; Requested pwm (from RC pulse value)
Governor_Req_Pwm:			.BYTE	1		; Governor requested pwm (sets governor target)
Current_Pwm:				.BYTE	1		; Current pwm
Rcp_Prev_Edge_L:			.BYTE	1		; RC pulse previous edge timer3 timestamp (lo byte)
Rcp_Prev_Edge_H:			.BYTE	1		; RC pulse previous edge timer3 timestamp (hi byte)
Rcp_Timeout_Cnt:			.BYTE	1		; RC pulse timeout counter (decrementing) 
Rcp_Skip_Cnt:				.BYTE	1		; RC pulse skip counter (decrementing) 
Rcp_Edge_Cnt:				.BYTE	1		; RC pulse edge counter 

Initial_Arm:				.BYTE	1		; Variable that is set during the first arm sequence after power on

Power_On_Wait_Cnt_L: 		.BYTE	1		; Power on wait counter (lo byte)
Power_On_Wait_Cnt_H: 		.BYTE	1		; Power on wait counter (hi byte)

Startup_Rot_Cnt:			.BYTE	1		; Startup phase rotations counter
Startup_Ok_Cnt:			.BYTE	1		; Startup phase ok comparator waits counter (incrementing)
Demag_Consecutive_Cnt:		.BYTE	1		; Counter used to count consecutive demag events

Prev_Comm_L:				.BYTE	1		; Previous commutation timer3 timestamp (lo byte)
Prev_Comm_H:				.BYTE	1		; Previous commutation timer3 timestamp (hi byte)
Comm_Period4x_L:			.BYTE	1		; Timer3 counts between the last 4 commutations (lo byte)
Comm_Period4x_H:			.BYTE	1		; Timer3 counts between the last 4 commutations (hi byte)
Comm_Phase:				.BYTE	1		; Current commutation phase
Comp_Wait_Reads: 			.BYTE	1		; Comparator wait comparator reads

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
Wt_Comm_L:				.BYTE	1		; Timer3 counts from zero cross to commutation (lo byte)
Wt_Comm_H:				.BYTE	1		; Timer3 counts from zero cross to commutation (hi byte)

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
Pwm_Spoolup_Beg:			.BYTE	1		; Pwm to begin main spoolup with
Pwm_Motor_Idle:			.BYTE	1		; Motor idle speed pwm
Pwm_On_Cnt:				.BYTE	1		; Pwm on event counter (used to increase pwm off time for low pwm)
Pwm_Off_Cnt:				.BYTE	1		; Pwm off event counter (used to run some pwm cycles without damping)
Pwm_Prev_Edge:				.BYTE	1		; Timestamp from timer 2 when pwm toggles on or off

Spoolup_Limit_Cnt:			.BYTE	1		; Interrupt count for spoolup limit
Spoolup_Limit_Skip:			.BYTE	1		; Interrupt skips for spoolup limit increment (1=no skips, 2=skip one etc)

Damping_Period:			.BYTE	1		; Damping on/off period
Damping_On:				.BYTE	1		; Damping on part of damping period

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
Pgm_Startup_Rpm:			.BYTE	1		; Programmed startup rpm
Pgm_Startup_Accel:			.BYTE	1		; Programmed startup acceleration
Pgm_Volt_Comp_Dummy:		.BYTE	1		; Place holder
Pgm_Comm_Timing:			.BYTE	1		; Programmed commutation timing
Pgm_Damping_Force:			.BYTE	1		; Programmed damping force
Pgm_Gov_Range:				.BYTE	1		; Programmed governor range
Pgm_Startup_Method:			.BYTE	1		; Programmed startup method
Pgm_Ppm_Min_Throttle:		.BYTE	1		; Programmed throttle minimum
Pgm_Ppm_Max_Throttle:		.BYTE	1		; Programmed throttle maximum
Pgm_Beep_Strength:			.BYTE	1		; Programmed beep strength
Pgm_Beacon_Strength:		.BYTE	1		; Programmed beacon strength
Pgm_Beacon_Delay:			.BYTE	1		; Programmed beacon delay
Pgm_Throttle_Rate:			.BYTE	1		; Programmed throttle rate
Pgm_Demag_Comp:			.BYTE	1		; Programmed demag compensation
Pgm_BEC_Voltage_High:		.BYTE	1		; Programmed BEC voltage
Pgm_Ppm_Center_Throttle:		.BYTE	1		; Programmed throttle center (in bidirectional mode)

; The sequence of the variables below is no longer of importance
Pgm_Gov_P_Gain_Decoded:		.BYTE	1		; Programmed governor decoded P gain
Pgm_Gov_I_Gain_Decoded:		.BYTE	1		; Programmed governor decoded I gain
Pgm_Throttle_Rate_Decoded:	.BYTE	1		; Programmed throttle rate decoded
Pgm_Startup_Pwr_Decoded:		.BYTE	1		; Programmed startup power decoded
Pgm_Demag_Comp_Power_Decoded:	.BYTE	1		; Programmed demag compensation power cut decoded


.EQU	SRAM_BYTES	= 255		; Bytes used in SRAM. Used for number of bytes to reset

;**** **** **** **** ****
.ESEG				; Eeprom segment
.ORG 0				

.EQU	EEPROM_FW_MAIN_REVISION		=	11		; Main revision of the firmware
.EQU	EEPROM_FW_SUB_REVISION		=	2		; Sub revision of the firmware
.EQU	EEPROM_LAYOUT_REVISION		=	17		; Revision of the EEPROM layout

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
Eep_Pgm_Damping_Force:		.DB	DEFAULT_PGM_MAIN_DAMPING_FORCE	; EEPROM copy of programmed damping force
Eep_Pgm_Gov_Range:			.DB	DEFAULT_PGM_MAIN_GOVERNOR_RANGE	; EEPROM copy of programmed governor range
_Eep_Pgm_Startup_Method:		.DB	0xFF
Eep_Pgm_Ppm_Min_Throttle:	.DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	.DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		.DB	DEFAULT_PGM_MAIN_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		.DB	DEFAULT_PGM_MAIN_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		.DB	DEFAULT_PGM_MAIN_BEACON_DELAY		; EEPROM copy of programmed beacon delay
Eep_Pgm_Throttle_Rate:		.DB	DEFAULT_PGM_MAIN_THROTTLE_RATE	; EEPROM copy of programmed throttle rate
Eep_Pgm_Demag_Comp:			.DB	DEFAULT_PGM_MAIN_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	.DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
_Eep_Pgm_Ppm_Center_Throttle:	.DB	0xFF							; EEPROM copy of programmed center throttle (final value is 4x+1000=1488)
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
Eep_Pgm_Damping_Force:		.DB	DEFAULT_PGM_TAIL_DAMPING_FORCE	; EEPROM copy of programmed damping force
_Eep_Pgm_Gov_Range:			.DB	0xFF	
_Eep_Pgm_Startup_Method:		.DB	0xFF
Eep_Pgm_Ppm_Min_Throttle:	.DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	.DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		.DB	DEFAULT_PGM_TAIL_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		.DB	DEFAULT_PGM_TAIL_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		.DB	DEFAULT_PGM_TAIL_BEACON_DELAY		; EEPROM copy of programmed beacon delay
Eep_Pgm_Throttle_Rate:		.DB	DEFAULT_PGM_TAIL_THROTTLE_RATE	; EEPROM copy of programmed throttle rate
Eep_Pgm_Demag_Comp:			.DB	DEFAULT_PGM_TAIL_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	.DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
Eep_Pgm_Ppm_Center_Throttle:	.DB	DEFAULT_PGM_PPM_CENTER_THROTTLE	; EEPROM copy of programmed center throttle (final value is 4x+1000=1488)
.ENDIF

.IF MODE == 2
Eep_Pgm_Gov_P_Gain:			.DB	DEFAULT_PGM_MULTI_P_GAIN			; EEPROM copy of programmed closed loop P gain
Eep_Pgm_Gov_I_Gain:			.DB	DEFAULT_PGM_MULTI_I_GAIN			; EEPROM copy of programmed closed loop I gain
Eep_Pgm_Gov_Mode:			.DB	DEFAULT_PGM_MULTI_GOVERNOR_MODE	; EEPROM copy of programmed closed loop mode
Eep_Pgm_Low_Voltage_Lim:		.DB	DEFAULT_PGM_MULTI_LOW_VOLTAGE_LIM	; EEPROM copy of programmed low voltage limit
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
Eep_Pgm_Damping_Force:		.DB	DEFAULT_PGM_MULTI_DAMPING_FORCE	; EEPROM copy of programmed damping force
_Eep_Pgm_Gov_Range:			.DB	0xFF	
_Eep_Pgm_Startup_Method:		.DB	0xFF
Eep_Pgm_Ppm_Min_Throttle:	.DB	DEFAULT_PGM_PPM_MIN_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1148)
Eep_Pgm_Ppm_Max_Throttle:	.DB	DEFAULT_PGM_PPM_MAX_THROTTLE		; EEPROM copy of programmed minimum throttle (final value is 4x+1000=1832)
Eep_Pgm_Beep_Strength:		.DB	DEFAULT_PGM_MULTI_BEEP_STRENGTH	; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		.DB	DEFAULT_PGM_MULTI_BEACON_STRENGTH	; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		.DB	DEFAULT_PGM_MULTI_BEACON_DELAY	; EEPROM copy of programmed beacon delay
Eep_Pgm_Throttle_Rate:		.DB	DEFAULT_PGM_MULTI_THROTTLE_RATE	; EEPROM copy of programmed throttle rate
Eep_Pgm_Demag_Comp:			.DB	DEFAULT_PGM_MULTI_DEMAG_COMP		; EEPROM copy of programmed demag compensation
Eep_Pgm_BEC_Voltage_High:	.DB	DEFAULT_PGM_BEC_VOLTAGE_HIGH		; EEPROM copy of programmed BEC voltage
Eep_Pgm_Ppm_Center_Throttle:	.DB	DEFAULT_PGM_PPM_CENTER_THROTTLE	; EEPROM copy of programmed center throttle (final value is 4x+1000=1488)
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
THROTTLE_RATE_TABLE:  	.DB 	0x02, 0x03, 0x04, 0x06, 0x08, 0x0C, 0x10, 0x18, 0x20, 0x30, 0x40, 0x80, 0xFF, 0 ; Padded zero for an even number
STARTUP_POWER_TABLE:  	.DB 	0x04, 0x06, 0x08, 0x0C, 0x10, 0x18, 0x20, 0x30, 0x40, 0x60, 0x80, 0xA0, 0xC0, 0 ; Padded zero for an even number
DEMAG_POWER_TABLE:  	.DB 	0, 2, 1, 0 ; Padded zero for an even number
.IF MODE == 0
TX_PGM_PARAMS_MAIN:  	.DB 	13, 13, 4, 3, 6, 13, 5, 13, 6, 3, 5, 2, 2, 0 ; Padded zero for an even number
.ENDIF
.IF MODE == 1
  .IF DAMPED_MODE_ENABLE == 1
TX_PGM_PARAMS_TAIL:  	.DB 	5, 5, 13, 5, 13, 6, 4, 5, 3, 2
  .ENDIF
  .IF DAMPED_MODE_ENABLE == 0
TX_PGM_PARAMS_TAIL:  	.DB 	5, 5, 13, 5, 13, 6, 3, 5, 3, 2
  .ENDIF
.ENDIF
.IF MODE == 2
  .IF DAMPED_MODE_ENABLE == 1
TX_PGM_PARAMS_MULTI:  	.DB 	13, 13, 4, 5, 6, 13, 5, 13, 6, 4, 5, 3, 2, 0 ; Padded zero for an even number
  .ENDIF
  .IF DAMPED_MODE_ENABLE == 0
TX_PGM_PARAMS_MULTI:  	.DB 	13, 13, 4, 5, 6, 13, 5, 13, 6, 3, 5, 3, 2, 0 ; Padded zero for an even number
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

	; Do not execute pwm when stopped
	sbrs	Flags1, MOTOR_SPINNING
	rjmp	t2_int_pwm_on_stopped
	; Do not execute pwm on during demag recovery
	sbrc	Flags0, DEMAG_CUT_POWER
	rjmp	t2_int_pwm_on_stopped
	; Pwm on cycle. 
	sbrs	Current_Pwm_Limited, 7		; Jump for low pwm (<50%)
	rjmp	t2_int_pwm_on_low_pwm

t2_int_pwm_on_execute:
	ijmp							; Jump to pwm on routines. Z should be set to one of the pwm_nfet_on labels

t2_int_pwm_on_low_pwm:

.IF (MODE == 0) || (MODE == 2); Main or multi
	rjmp	t2_int_pwm_on_execute
.ENDIF
.IF MODE == 1				; Tail
	; Skip pwm on cycles for very low pwm
	lds	YL, Pwm_On_Cnt				; Increment event counter
	inc	YL
	sts	Pwm_On_Cnt, YL
	ldi	YL, 5					; Only skip for very low pwm
	sub	YL, Current_Pwm_Limited		; Check skipping shall be done (for low pwm only)
	brcs	t2_int_pwm_on_execute

	lds	YH, Pwm_On_Cnt				; Check if on cycle is to be skipped
	sub	YL, YH
	brcs	t2_int_pwm_on_execute

	ldi	YL, 120					; Write start point for timer
	sec	
	sbrc	Flags2, PGM_PWM_HIGH_FREQ	
	ror	YL
.IF CLK_8M == 1
	sec	
	ror	YL
.ENDIF
	Set_TCNT2 YL					
	mov	YL, Current_Pwm_Limited
	tst	YL
	brne	t2_int_pwm_on_low_pwm_not_zero

	ldi	YL, 0					; Write start point for timer (long time for zero pwm)
	sbrc	Flags2, PGM_PWM_HIGH_FREQ	
	ldi	YL, 0x80
.IF CLK_8M == 1
	ldi	YL, 0xC0
.ENDIF
	Set_TCNT2 YL					

t2_int_pwm_on_low_pwm_not_zero:
	rjmp	t2_int_pwm_on_exit_no_timer_update
.ENDIF

t2_int_pwm_on_stopped:
	rjmp	t2_int_pwm_on_exit


t2_int_pwm_off:
	sbrs	Flags1, STARTUP_PHASE
	rjmp	t2_int_pwm_off_start_checked
	All_nFETs_Off YL				; Switch off all nfets early during start, for a smooth start
t2_int_pwm_off_start_checked:
	; Pwm off cycle
	mov	YL, Current_Pwm_Limited
	sec	
	sbrc	Flags2, PGM_PWM_HIGH_FREQ	; Use half the time when pwm frequency is high
	ror	YL
.IF CLK_8M == 1
	sec	
	ror	YL
.ENDIF
	Set_TCNT2 YL					; Load new timer setting
	sts	Pwm_Prev_Edge, YL			; Set timestamp
	; Clear pwm on flag
	cbr	Flags0, (1<<PWM_ON)
	; Set full PWM (on all the time) if current PWM near max. This will give full power, but at the cost of a small "jump" in power
	mov	YL, Current_Pwm_Limited		; Load current pwm
	cpi	YL, 0xFF					; Full pwm?
	brne	PC+2						; No - branch
	rjmp	t2_int_pwm_off_fullpower_exit	; Yes - exit

	lds	YL, Pwm_Off_Cnt			; Increment event counter
	inc	YL
	sts	Pwm_Off_Cnt, YL
	; Do not execute pwm when stopped
	sbrs	Flags1, MOTOR_SPINNING
	rjmp	t2_int_pwm_off_stopped

	; If damped operation, set pFETs on in pwm_off
	sbrc	Flags2, PGM_PWMOFF_DAMPED	; Damped operation?
	rjmp	t2_int_pwm_off_damped

	; Separate exit commands here for minimum delay
	All_nFETs_Off YL		 		; Switch off all nfets
	out	SREG, II_Sreg
	reti

t2_int_pwm_off_stopped:
	All_nFETs_Off YL				; Switch off all nfets
	rjmp	t2_int_pwm_off_exit

t2_int_pwm_off_damped:
	sbr	Flags1, (1<<CURR_PWMOFF_DAMPED)	; Set damped status
	cbr	Flags1, (1<<CURR_PWMOFF_COMP_ABLE)	; Set comparator unusable status
	lds	YL, Damping_On
	tst	YL
	breq	t2_int_pwm_off_do_damped		; Highest damping - apply damping always

	lds	YL, Pwm_Off_Cnt			; Is damped on number reached?
	dec	YL
	lds	YH, Damping_On
	sub	YL, YH
	brcs	t2_int_pwm_off_do_damped		; No - apply damping

	cbr	Flags1, (1<<CURR_PWMOFF_DAMPED)	; Set non damped status
	sbr	Flags1, (1<<CURR_PWMOFF_COMP_ABLE)	; Set comparator usable status
	lds	YL, Pwm_Off_Cnt					
	lds	YH, Damping_Period			; Is damped period number reached?
	sub	YL, YH
	brcc	t2_int_pwm_off_clr_cnt		; Yes - Proceed

	rjmp	t2_int_pwm_off_exit			; No - Branch

t2_int_pwm_off_clr_cnt:
	sts	Pwm_Off_Cnt, Zero			; Yes - clear counter
	rjmp	t2_int_pwm_off_exit			; Not damped cycle - exit	

t2_int_pwm_off_do_damped:
	; Delay to allow nFETs to go off before pFETs are turned on (only in full damped mode)
	sbrc	Flags2, PGM_PWMOFF_DAMPED_LIGHT	; If damped light operation - branch
	rjmp	t2_int_pwm_off_damped_light

	All_nFETs_Off YL				; Switch off all nfets
	ldi	YL, PFETON_DELAY
	dec	YL
	brne	PC-1
	All_pFETs_On YL				; Switch on all pfets
	rjmp	t2_int_pwm_off_exit

t2_int_pwm_off_damped_light:
.IF DAMPED_MODE_ENABLE == 1
	sbr	Flags1, (1<<CURR_PWMOFF_COMP_ABLE)	; Set comparator usable status always for damped light mode on fully damped capable escs
.ENDIF
	All_nFETs_Off YL				; Switch off all nfets
	lds	YL, Comm_Phase				; Turn on pfets according to commutation phase
	sbrc	YL, 2
	rjmp	t2_int_pwm_off_comm_4_5_6
	sbrc	YL, 1
	rjmp	t2_int_pwm_off_comm_2_3

.IF DAMPED_MODE_ENABLE == 0
	ApFET_On			; Comm phase 1 - turn on A
.ELSE
	ldi	YL, PFETON_DELAY
	dec	YL
	brne	PC-1
	CpFET_On			; Comm phase 1 - turn on C
.ENDIF
	rjmp	t2_int_pwm_off_exit

t2_int_pwm_off_comm_2_3:
	sbrc	YL, 0
	rjmp	t2_int_pwm_off_comm_3
.IF DAMPED_MODE_ENABLE == 0
	BpFET_On			; Comm phase 2 - turn on B
.ELSE
	ldi	YL, PFETON_DELAY
	dec	YL
	brne	PC-1
	CpFET_On			; Comm phase 2 - turn on C
.ENDIF
	rjmp	t2_int_pwm_off_exit

t2_int_pwm_off_comm_3:
.IF DAMPED_MODE_ENABLE == 0
	CpFET_On			; Comm phase 3 - turn on C
.ELSE
	ldi	YL, PFETON_DELAY
	dec	YL
	brne	PC-1
	BpFET_On			; Comm phase 3 - turn on B
.ENDIF
	rjmp	t2_int_pwm_off_exit

t2_int_pwm_off_comm_4_5_6:
	sbrc	YL, 1
	rjmp	t2_int_pwm_off_comm_6
	sbrc	YL, 0
	rjmp	t2_int_pwm_off_comm_5

.IF DAMPED_MODE_ENABLE == 0
	ApFET_On			; Comm phase 4 - turn on A
.ELSE
	ldi	YL, PFETON_DELAY
	dec	YL
	brne	PC-1
	BpFET_On			; Comm phase 4 - turn on B
.ENDIF
	rjmp	t2_int_pwm_off_exit

t2_int_pwm_off_comm_5:
.IF DAMPED_MODE_ENABLE == 0
	BpFET_On			; Comm phase 5 - turn on B
.ELSE
	ldi	YL, PFETON_DELAY
	dec	YL
	brne	PC-1
	ApFET_On			; Comm phase 5 - turn on A
.ENDIF
	rjmp	t2_int_pwm_off_exit

t2_int_pwm_off_comm_6:
.IF DAMPED_MODE_ENABLE == 0
	CpFET_On			; Comm phase 6 - turn on C
.ELSE
	ldi	YL, PFETON_DELAY
	dec	YL
	brne	PC-1
	ApFET_On			; Comm phase 6 - turn on A
.ENDIF

t2_int_pwm_off_exit:	; Exit from pwm off cycle
	All_nFETs_Off YL	; Switch off all nfets
	out	SREG, II_Sreg
	reti

t2_int_pwm_off_fullpower_exit:	; Exit from pwm off cycle, leaving power on
	out	SREG, II_Sreg
	reti



pwm_nofet_on:	; Dummy pwm on cycle
	rjmp	t2_int_pwm_on_exit

pwm_afet_on:	; Pwm on cycle afet on (bfet off)
	AnFET_on	
	BnFET_off
	rjmp	t2_int_pwm_on_exit

pwm_bfet_on:	; Pwm on cycle bfet on (cfet off)
	BnFET_on
	CnFET_off
	rjmp	t2_int_pwm_on_exit

pwm_cfet_on:	; Pwm on cycle cfet on (afet off)
	CnFET_on
	AnFET_off
	rjmp	t2_int_pwm_on_exit

pwm_anfet_bpfet_on_fast:	; Pwm on cycle anfet on (bnfet off) and bpfet on (used in damped state 6)
	ApFET_off
	AnFET_on								; Switch nFETs
	CpFET_off
	BnFET_off 							
	rjmp	t2_int_pwm_on_exit
pwm_anfet_bpfet_on_safe:	; Pwm on cycle anfet on (bnfet off) and bpfet on (used in damped state 6)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ApFET_off
	CpFET_off
	ldi	YL, PFETON_DELAY					; Set full delay
	dec	YL
	brne	PC-1
	AnFET_on								; Switch nFETs
	BnFET_off 							
	rjmp	t2_int_pwm_on_exit

pwm_anfet_cpfet_on_fast:	; Pwm on cycle anfet on (bnfet off) and cpfet on (used in damped state 5)
	ApFET_off
	AnFET_on								; Switch nFETs
	BpFET_off
	BnFET_off								
	rjmp	t2_int_pwm_on_exit
pwm_anfet_cpfet_on_safe:	; Pwm on cycle anfet on (bnfet off) and cpfet on (used in damped state 5)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ApFET_off
	BpFET_off
	ldi	YL, PFETON_DELAY					; Set full delay
	dec	YL
	brne	PC-1
	AnFET_on								; Switch nFETs
	BnFET_off								
	rjmp	t2_int_pwm_on_exit

pwm_bnfet_cpfet_on_fast:	; Pwm on cycle bnfet on (cnfet off) and cpfet on (used in damped state 4)
	BpFET_off
	BnFET_on								; Switch nFETs
	ApFET_off
	CnFET_off								
	rjmp	t2_int_pwm_on_exit
pwm_bnfet_cpfet_on_safe:	; Pwm on cycle bnfet on (cnfet off) and cpfet on (used in damped state 4)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	BpFET_off
	ApFET_off
	ldi	YL, PFETON_DELAY					; Set full delay
	dec	YL
	brne	PC-1
	BnFET_on								; Switch nFETs
	CnFET_off								
	rjmp	t2_int_pwm_on_exit

pwm_bnfet_apfet_on_fast:	; Pwm on cycle bnfet on (cnfet off) and apfet on (used in damped state 3)
	BpFET_off
	BnFET_on								; Switch nFETs
	CpFET_off
	CnFET_off								
	rjmp	t2_int_pwm_on_exit
pwm_bnfet_apfet_on_safe:	; Pwm on cycle bnfet on (cnfet off) and apfet on (used in damped state 3)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	BpFET_off
	CpFET_off
	ldi	YL, PFETON_DELAY					; Set full delay
	dec	YL
	brne	PC-1
	BnFET_on								; Switch nFETs
	CnFET_off								
	rjmp	t2_int_pwm_on_exit

pwm_cnfet_apfet_on_fast:	; Pwm on cycle cnfet on (anfet off) and apfet on (used in damped state 2)
	CpFET_off
	CnFET_on								; Switch nFETs
	BpFET_off
	AnFET_off								
	rjmp	t2_int_pwm_on_exit
pwm_cnfet_apfet_on_safe:	; Pwm on cycle cnfet on (anfet off) and apfet on (used in damped state 2)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	CpFET_off
	BpFET_off
	ldi	YL, PFETON_DELAY					; Set full delay
	dec	YL
	brne	PC-1
	CnFET_on								; Switch nFETs
	AnFET_off								
	rjmp	t2_int_pwm_on_exit

pwm_cnfet_bpfet_on_fast:	; Pwm on cycle cnfet on (anfet off) and bpfet on (used in damped state 1)
	CpFET_off
	CnFET_on								; Switch nFETs
	ApFET_off
	AnFET_off								
	rjmp	t2_int_pwm_on_exit
pwm_cnfet_bpfet_on_safe:	; Pwm on cycle cnfet on (anfet off) and bpfet on (used in damped state 1)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	CpFET_off
	ApFET_off
	ldi	YL, PFETON_DELAY					; Set full delay
	dec	YL
	brne	PC-1
	CnFET_on								; Switch nFETs
	AnFET_off								
	rjmp	t2_int_pwm_on_exit

t2_int_pwm_on_exit:
	; Set timer for coming on cycle length
	mov 	YL, Current_Pwm_Limited		; Load current pwm
	com	YL						; com is 255-x
	sec	
	sbrc	Flags2, PGM_PWM_HIGH_FREQ	; Use half the time when pwm frequency is high
	ror	YL
.IF CLK_8M == 1
	sec	
	ror	YL
.ENDIF
	Set_TCNT2 YL					; Write start point for timer
	; Set other variables
	sts	Pwm_Prev_Edge, YL			; Set timestamp
	sts	Pwm_On_Cnt, Zero			; Reset pwm on event counter
	sbr	Flags0, (1<<PWM_ON)			; Set pwm on flag
t2_int_pwm_on_exit_no_timer_update:
	; Exit interrupt
	out	SREG, II_Sreg
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 1 output compare A interrupt
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t1oca_int:	
	in	II_Sreg, SREG
	T1oca_Clear_Int_Flag YL			; Clear interrupt flag if set
	cbr	Flags0, (1<<OC1A_PENDING) 	; Flag that OC1A value is passed
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
	mov	XL, Flags3				; Check pwm frequency flags
	andi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	breq	t0_int_skip_start			; If no flag is set (PPM) - branch

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

	mov	XL, Flags3				; Check pwm frequency flags
	andi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	breq	t0_int_ppm_timeout_set		; If no flag is set (PPM) - branch

	ldi	XL, RCP_TIMEOUT			; For PWM, set timeout count to start value
	sts	Rcp_Timeout_Cnt, XL

t0_int_ppm_timeout_set:
	sts	New_Rcp, I_Temp1			; Store new pulse length
	sbr	Flags2, (1<<RCP_UPDATED)	 	; Set updated flag

t0_int_skip_start:
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
	mov	XL, Flags3				; Check pwm frequency flags
	andi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	breq	t0_int_rcp_update_start		; If no flag is set (PPM) - branch

	; Skip counter has reached zero, start looking for RC pulses again
	sbr	Flags2, (1<<RCP_INT_NESTED_ENABLED)	; Set flag to enabled
	Rcp_Clear_Int_Flag XL			; Clear interrupt flag
	
t0_int_rcp_update_start:
	; Process updated RC pulse
	sbrs	Flags2, RCP_UPDATED			; Is there an updated RC pulse available?
	rjmp	t0_int_pwm_exit			; No - exit

	lds	XL, New_Rcp				; Load new pulse value
	mov	I_Temp1, XL
	cbr	Flags2, (1<<RCP_UPDATED)	 	; Flag that pulse has been evaluated
	; Use a gain of 1.0625x for pwm input if not governor mode
	mov	XL, Flags3				; Check pwm frequency flags
	andi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	breq	t0_int_pwm_min_run			; If no flag is set (PPM) - branch

.IF MODE == 0	; Main - do not adjust gain
	rjmp	t0_int_pwm_min_run
.ENDIF

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
	; Limit pwm during start
	sbrs	Flags1, STARTUP_PHASE
	rjmp	t0_int_current_pwm_update

	lds	XL, Requested_Pwm			; Limit pwm during start
	lds	I_Temp2, Pwm_Limit
	cp	XL, I_Temp2
	brcs	t0_int_current_pwm_update

	sts	Requested_Pwm, I_Temp2

t0_int_current_pwm_update: 
.IF MODE == 0 || MODE == 2	; Main or multi
	lds	I_Temp1, Pgm_Gov_Mode		; Governor mode?
	cpi	I_Temp1, 4
	brne	t0_int_pwm_exit			; Yes - branch
.ENDIF

	; Update current pwm, with limited throttle change rate
	lds	XL, Requested_Pwm			; Is requested pwm larger than current pwm?
	lds	I_Temp1, Current_Pwm
	sub	XL, I_Temp1
	brcs	t0_int_set_current_pwm		; No - proceed

	lds	I_Temp1, Pgm_Throttle_Rate_Decoded		
	sbc	XL, I_Temp1				; Is difference larger than throttle change rate?
	brcs	t0_int_set_current_pwm		; No - proceed

	lds	XL, Current_Pwm			; Increase current pwm by throttle change rate
	add	XL, I_Temp1
	sts	Current_Pwm, XL
	brcc	t0_int_current_pwm_done		; Is result above max?

	ldi	XL, 0xFF					; Yes - limit
	sts	Current_Pwm, XL
	rjmp	t0_int_current_pwm_done

t0_int_set_current_pwm:
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

	mov	Current_Pwm_Limited, I_Temp1
.ENDIF
t0_int_pwm_exit:	
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
	mov	XL, Flags3				; Check pwm frequency flags
	andi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	brne	t0h_int_rcp_stop_check		; If a flag is set (PWM) - branch

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
	rjmp	t0h_int_rcp_exit				; Jump if skip count is not reached

	ldi	XL, 1						; Reset skip count. Default is fast spoolup
	sts	Spoolup_Limit_Skip, XL			
	ldi	I_Temp1, 5					; Default fast increase

	cpi	I_Temp2, (3*MAIN_SPOOLUP_TIME)	; No spoolup until "30"*32ms (Spoolup_Limit_Cnt in I_Temp2)
	brcs	t0h_int_rcp_exit

	cpi	I_Temp2, (10*MAIN_SPOOLUP_TIME)	; Slow spoolup until "100"*32ms (Spoolup_Limit_Cnt in I_Temp2)
	brcc	t0h_int_rcp_limit_middle_ramp

	ldi	I_Temp1, 1					; Slow initial spoolup
	ldi	XL, 3
	sts	Spoolup_Limit_Skip, XL
	rjmp	t0h_int_rcp_set_limit

t0h_int_rcp_limit_middle_ramp:
	cpi	I_Temp2, (15*MAIN_SPOOLUP_TIME)	; Faster spoolup until "150"*32ms
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
	breq	PC+4							; If it is, then this is a "bailout" ramp

	ldi	XL, (3*MAIN_SPOOLUP_TIME)		; Stay in an early part of the spoolup sequence (unless "bailout" ramp)
	sts	Spoolup_Limit_Cnt, XL

	ldi	XL, 1						; Set skip count
	sts	Spoolup_Limit_Skip, XL
	ldi	XL, 60						; Set governor requested speed to ensure that it requests higher speed
	sts	Governor_Req_Pwm, XL
									; 20=Fail on jerk when governor activates
									; 30=Ok
									; 100=Fail on small governor settling overshoot on low headspeeds
									; 200=Fail on governor settling overshoot
	rjmp	t0h_int_rcp_exit				; Exit

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
	brne	t0h_int_rcp_exit

	ldi	XL, 0xFF
	sts	Auto_Bailout_Armed, XL			; Arm bailout
	sts	Spoolup_Limit_Cnt, XL

.ENDIF
.IF MODE == 2	; Multi
	lds	XL, Pwm_Limit_Spoolup			; Increment spoolup pwm, for a 0.8 seconds spoolup
	subi	XL, 0xF6						; Subtract -10
	brcs	t0h_int_rcp_no_limit			; If below 255 - branch

	ldi	I_Temp2, 0xFF
	sts	Pwm_Limit_Spoolup, I_Temp2
	rjmp	t0h_int_rcp_exit

t0h_int_rcp_no_limit:
	sts	Pwm_Limit_Spoolup, XL
.ENDIF

t0h_int_rcp_exit:
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
; RC pulse interrupt routine
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
	mov	XL, Flags3				; Check pwm frequency flags
	andi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	brne	PC+2			
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
	ldi	XL, 250					; Set default period tolerance requirement
	mov	I_Temp3, XL
	; Check if pwm frequency is 12kHz
	cpi	I_Temp1, low(200)			; If below 100us, 12kHz pwm is assumed
	ldi	XL, high(200)
	cpc	I_Temp2, XL
	brcc	rcp_int_check_8kHz

	ldi	XL, (1<<RCP_PWM_FREQ_12KHZ)
	mov	I_Temp4, XL
	ldi	XL, 10					; Set period tolerance requirement
	mov	I_Temp3, XL
	rjmp	rcp_int_restore_edge

rcp_int_check_8kHz:
	; Check if pwm frequency is 8kHz
	cpi	I_Temp1, low(360)			; If below 180us, 8kHz pwm is assumed
	ldi	XL, high(360)
	cpc	I_Temp2, XL
	brcc	rcp_int_check_4kHz

	ldi	XL, (1<<RCP_PWM_FREQ_8KHZ)
	mov	I_Temp4, XL
	ldi	XL, 15					; Set period tolerance requirement
	mov	I_Temp3, XL
	rjmp	rcp_int_restore_edge

rcp_int_check_4kHz:
	; Check if pwm frequency is 4kHz
	cpi	I_Temp1, low(720)			; If below 360us, 4kHz pwm is assumed
	ldi	XL, high(720)
	cpc	I_Temp2, XL
	brcc	rcp_int_check_2kHz

	ldi	XL, (1<<RCP_PWM_FREQ_4KHZ)
	mov	I_Temp4, XL
	ldi	XL, 30					; Set period tolerance requirement
	mov	I_Temp3, XL
	rjmp	rcp_int_restore_edge

rcp_int_check_2kHz:
	; Check if pwm frequency is 2kHz
	cpi	I_Temp1, low(1440)			; If below 720us, 2kHz pwm is assumed
	ldi	XL, high(1440)
	cpc	I_Temp2, XL
	brcc	rcp_int_check_1kHz

	ldi	XL, (1<<RCP_PWM_FREQ_2KHZ)
	mov	I_Temp4, XL
	ldi	XL, 60					; Set period tolerance requirement
	mov	I_Temp3, XL
	rjmp	rcp_int_restore_edge

rcp_int_check_1kHz:
	; Check if pwm frequency is 1kHz
	cpi	I_Temp1, low(2200)			; If below 1100us, 1kHz pwm is assumed
	ldi	XL, high(2200)
	cpc	I_Temp2, XL
	brcc	rcp_int_restore_edge

	ldi	XL, (1<<RCP_PWM_FREQ_1KHZ)
	mov	I_Temp4, XL
	ldi	XL, 120					; Set period tolerance requirement
	mov	I_Temp3, XL

rcp_int_restore_edge:
	; Calculate difference between this period and previous period
	mov	I_Temp5, I_Temp1
	lds	I_Temp7, Rcp_Prev_Period_L
	sub	I_Temp5, I_Temp7
	mov	I_Temp6, I_Temp2
	lds	I_Temp8, Rcp_Prev_Period_H
	sbc	I_Temp6, I_Temp8
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
	tst	I_Temp6						; Check if high byte is zero
	brne	rcp_int_store_data				

	cp	I_Temp5, I_Temp3				; Check difference
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

rcp_int_fall:
	; RC pulse edge was second, calculate new pulse length
	lds	I_Temp7, Rcp_Prev_Edge_L
	sub	I_Temp1, I_Temp7
	lds	I_Temp8, Rcp_Prev_Edge_H
	sbc	I_Temp2, I_Temp8
	sbrc	Flags3, RCP_PWM_FREQ_12KHZ		; Is RC input pwm frequency 12kHz?
	rjmp	rcp_int_pwm_divide_done			; Yes - branch forward

	sbrc	Flags3, RCP_PWM_FREQ_8KHZ		; Is RC input pwm frequency 8kHz?
	rjmp	rcp_int_pwm_divide_done			; Yes - branch forward

	sbrc	Flags3, RCP_PWM_FREQ_4KHZ		; Is RC input pwm frequency 4kHz?
	rjmp	rcp_int_pwm_divide				; Yes - branch forward

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
	; Skip range limitation if pwm frequency measurement
	sbrc	Flags0, RCP_MEAS_PWM_FREQ
	rjmp	rcp_int_ppm_check_full_range 		

	; Check if 2160us or above (in order to ignore false pulses)
	mov	XL, I_Temp5					; Is pulse 2160us or higher?
	subi	XL, 28
	mov	XL, I_Temp6
	sbci	XL, 2
	brcs	PC+2

	rjmp	rcp_int_set_timeout				; Yes - ignore pulse

	; Check if below 800us (in order to ignore false pulses)
	tst	I_Temp6
	brne	rcp_int_ppm_check_full_range

	mov	XL, I_Temp5					; Is pulse below 800us?
	subi	XL, 200
	brcc	rcp_int_ppm_check_full_range		; No - branch

	rjmp	rcp_int_set_timeout				; Yes - ignore pulse

rcp_int_ppm_check_full_range:
	; Calculate "1000us" plus throttle minimum
	ldi	XL, 0						; Set 1000us as default minimum
	mov	I_Temp7, XL
	sbrc	Flags3, FULL_THROTTLE_RANGE		; Check if full range is chosen
	rjmp	rcp_int_ppm_calculate			; Yes - branch

	lds	I_Temp7, Pgm_Ppm_Min_Throttle		; Min throttle value is in 4us units
.IF MODE >= 1	; Tail or multi
	lds	XL, Pgm_Direction				; Check if bidirectional operation
	cpi	XL, 3
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
	lds	XL, Pgm_Direction				; Check if bidirectional operation
	cpi	XL, 3
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
	All_nFETs_Off
	All_pFETs_Off
	sei

rcp_int_ppm_bidir_dir_set:
.ENDIF
	tst	I_Temp1
	breq	rcp_int_ppm_neg_checked			; If result is positive - branch

.IF MODE >= 1	; Tail or multi
	lds	XL, Pgm_Direction				; Check if bidirectional operation
	cpi	XL, 3
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
	lds	XL, Pgm_Direction				; Check if bidirectional operation
	cpi	XL, 3
	brne	rcp_int_ppm_bidir_done			; No - branch

	lsl	I_Temp5						; Multiply value by 2
	rol	I_Temp6
	ldi	XL, 5						; Subtract deadband
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

rcp_int_set_timeout:
	ldi	XL, RCP_TIMEOUT			; Set timeout count to start value
	sts	Rcp_Timeout_Cnt, XL
	mov	XL, Flags3				; Check pwm frequency flags
	andi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	brne	rcp_int_ppm_timeout_set		; If a flag is set (PWM) - branch

	ldi	XL, RCP_TIMEOUT_PPM			; No flag set means PPM. Set timeout count
	sts	Rcp_Timeout_Cnt, XL

rcp_int_ppm_timeout_set:
	sbrc	Flags0, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp rcp_int_exit				; Yes - exit

	mov	XL, Flags3				; Check pwm frequency flags
	andi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	breq	rcp_int_exit				; If no flag is set (PPM) - branch

	cbr	Flags2, (1<<RCP_INT_NESTED_ENABLED)	; Set flag to disabled

rcp_int_exit:	; Exit interrupt routine	
	ldi	XL, RCP_SKIP_RATE			; Load number of skips
	sts	Rcp_Skip_Cnt, XL
	mov	XL, Flags3				; Check pwm frequency flags
	andi	XL, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	brne	PC+4						; If a flag is set (PWM) - branch

	ldi	XL, 10					; Load number of skips
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
.IF CLK_8M == 1
	ldi	Temp1, 10
.ENDIF
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
	rjmp	beep_init

beep_f2:	; Entry point 2, load beeper frequency 2 settings
	ldi	Temp3, 48
	ldi	Temp4, 140
	rjmp	beep_init

beep_f3:	; Entry point 3, load beeper frequency 3 settings
	ldi	Temp3, 42
	ldi	Temp4, 180
	rjmp	beep_init

beep_f4:	; Entry point 4, load beeper frequency 4 settings
	ldi	Temp3, 37
	ldi	Temp4, 200
	rjmp	beep_init

beep_init:
.IF CLK_8M == 1
	subi	Temp3, 28
.ENDIF
beep:	; Beep loop start
	mov	Temp5, Current_Pwm_Limited	; Store value
	ldi	XH, 1					; Set to a nonzero value
	mov	Current_Pwm_Limited, XH
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
	; Exit if governor is inactive
	sbrs	Flags0, GOV_ACTIVE		
	rjmp	calc_governor_prop_error_exit

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
	; Exit if governor is inactive
	sbrs	Flags0, GOV_ACTIVE		
	rjmp	calc_governor_int_error_exit

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
	; Exit if governor is inactive
	sbrs	Flags0, GOV_ACTIVE		
	rjmp	calc_governor_prop_corr_exit

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
	; Exit if governor is inactive
	sbrs	Flags0, GOV_ACTIVE		
	rjmp	calc_governor_int_corr_exit

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
; Measure lipo cells
;
; No assumptions
;
; Measure voltage and calculate lipo cells
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
measure_lipo_cells:
.IF MODE == 1	; Tail
	; If tail, then exit
	rjmp	measure_lipo_exit
.ENDIF
measure_lipo_start:
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
	brcc	temp_check_exit			; Yes - exit

	ldi  Temp1, 192				; No - limit pwm

	cpi	XH, (TEMP_LIMIT-TEMP_LIMIT_STEP)	; Is temp ADC above second limit
	brcc	temp_check_exit			; Yes - exit

	ldi  Temp1, 128				; No - limit pwm

	cpi	XH, (TEMP_LIMIT-2*TEMP_LIMIT_STEP)	; Is temp ADC above third limit
	brcc	temp_check_exit			; Yes - exit

	ldi  Temp1, 64					; No - limit pwm

	cpi	XH, (TEMP_LIMIT-3*TEMP_LIMIT_STEP)	; Is temp ADC above final limit
	brcc	temp_check_exit			; Yes - exit

	ldi  Temp1, 0					; No - limit pwm

temp_check_exit:
	sts  Pwm_Limit, Temp1			; Set pwm limit
	Set_Adc_Ip_Volt				; Select adc input for next conversion
	ret

check_voltage_start:
.IF (MODE == 0) || (MODE == 2)	; Main or multi
	; Check if low voltage limiting is enabled
	cpi	Temp3, 1					; Is low voltage limit disabled?
	breq	check_voltage_good			; Yes - voltage declared good

	; Check if ADC is saturated
	cpi	Temp1, 0xFF
	ldi	XH, 3
	cpc	Temp2, XH
	brcc	check_voltage_good			; ADC saturated, can not make judgement

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
	sts	Pwm_Spoolup_Beg, Temp1			; Update spoolup beginning pwm
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
	sts	Comm_Period4x_L, Zero		; Set commutation period registers
	ldi	XH, 0x08
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
calc_next_comm_timing:		; Entry point for run phase
	lds	Temp3, Wt_Advance_L	; Set up advance timing wait 
	lds	Temp4, Wt_Advance_H
	cli 					; Disable interrupts while reading timer 1
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	Temp3, Temp1		; Set new output compare value
	adc	Temp4, Temp2
	Set_OCR1AH Temp4		; Update high byte first to avoid false output compare
	Set_OCR1AL Temp3
	sei					; Enable interrupts
	sbr	Flags0, (1<<OC1A_PENDING)	; Set timer output compare pending flag
	; Calculate this commutation time
	lds	Temp3, Prev_Comm_L
	lds	Temp4, Prev_Comm_H
	sts	Prev_Comm_L, Temp1		; Store timestamp as previous commutation
	sts	Prev_Comm_H, Temp2
	sub	Temp1, Temp3			; Calculate the new commutation time
	sbc	Temp2, Temp4
	; Calculate next zero cross scan timeout 
	lds	Temp3, Comm_Period4x_L	; Comm_Period4x(-l-h-x) holds the time of 4 commutations
	lds	Temp4, Comm_Period4x_H
	mov	Temp6, Temp4
	mov	Temp5, Temp3
	lsr	Temp6				; Divide by 2
	ror	Temp5
	lsr	Temp6				; Divide by 2 again
	ror	Temp5
	sub	Temp3, Temp5			; Subtract a quarter
	sbc	Temp4, Temp6

	add	Temp3, Temp1			; Add the new time
	adc	Temp4, Temp2
	sts	Comm_Period4x_L, Temp3	; Store Comm_Period4x_X
	sts	Comm_Period4x_H, Temp4
	brcs	calc_next_comm_slow		; If period larger than 0xffff - go to slow case

	ret

calc_next_comm_slow:
	ldi	XH, 0xFF
	sts	Comm_Period4x_L, XH		; Set commutation period registers to very slow timing (0xffff)
	sts	Comm_Period4x_H, XH
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Setup zero cross scan wait
;
; No assumptions
;
; Sets up timer 1 to wait the zero cross scan wait time
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
setup_zc_scan_wait:
	lds	Temp3, Wt_Zc_Scan_L	; Set wait to zero cross scan value
	lds	Temp4, Wt_Zc_Scan_H
	cli					; Disable interrupts while reading timer 1
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	Temp1, Temp3		; Set new output compare value
	adc	Temp2, Temp4
	Set_OCR1AH Temp2		; Update high byte first to avoid false output compare
	Set_OCR1AL Temp1
	sei					; Enable interrupts
	sbr	Flags0, (1<<OC1A_PENDING)
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait advance timing routine
;
; No assumptions
;
; Waits for the advance timing to elapse, waits one zero cross
; wait and sets up the next zero cross wait
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait_advance_timing:	
	ldi	XH, 1				; Default one zero cross scan wait	(prevents squealing that can happen if two are used when demag comp is off)				
	mov	Temp8, XH
	lds	XH, Pgm_Demag_Comp		; Load programmed demag compensation
	dec	XH
	breq	wait_advance_timing_wait

	ldi	XH, 2				; Do two zero cross scan waits when demag comp is on (gives more correct blind advance)						
	mov	Temp8, XH

wait_advance_timing_wait:
	sbrc	Flags0, OC1A_PENDING 
	rjmp	wait_advance_timing_wait

	xcall setup_zc_scan_wait		; Setup wait time
	dec	Temp8
	brne	wait_advance_timing_wait

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
	lds	Temp8, Pgm_Comm_Timing	; Store in Temp8
	ldi	XH, (COMM_TIME_RED<<1)	
	mov	Temp7, XH
.IF MODE == 2
	lds	Temp1, Comm_Period4x_H	; Higher reduction for higher speed in MULTI mode
	cpi	Temp1, 4				; A COMM_TIME_RED of 6 gives good acceleration performance on pancake motor at high voltage
	brcs	calc_new_wait_red_set	; A COMM_TIME_RED of 10 gives good high speed performance for a small motor

	ldi	Temp1, 4

calc_new_wait_red_set:
	lsl	Temp1
	sub	Temp7, Temp1
.ENDIF
	sbrs	Flags1, STARTUP_PHASE	; Set timing for start
	rjmp	calc_new_wait_dir_start_set	

	ldi	XH, 3				; Set medium timing
	mov	Temp8, XH
	mov	Temp7, Zero			; Set no comm time reduction

calc_new_wait_dir_start_set:
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
	brcc	adjust_timing			; Check that result is still above minumum

load_min_time:
	ldi	Temp1, (COMM_TIME_MIN<<1)
	ldi	Temp2, 0

adjust_timing:
	mov	Temp4, Temp2			; Copy values
	mov	Temp3, Temp1
	mov	Temp6, Temp2
	mov	Temp5, Temp1
	lsr	Temp6				; Divide by 2
	ror	Temp5
	mov	XH, Temp8				; (Temp8 has Pgm_Comm_Timing)
	cpi	XH, 3				; Is timing normal?
	breq	store_times_decrease	; Yes - branch

	sbrc	XH, 0				; If an odd number - branch
	rjmp	adjust_timing_two_steps

	add	Temp1, Temp5			; Add 7.5° and store in Temp1/2
	adc	Temp2, Temp6
	mov	Temp3, Temp5			; Store 7.5° in Temp3/4
	mov	Temp4, Temp6
	rjmp	store_times_up_or_down

adjust_timing_two_steps:
	lsl	Temp1				; Add 15° and store in Temp1/2
	rol	Temp2
	ldi	Temp3, (COMM_TIME_MIN<<1); Store minimum time in Temp3/4
	ldi	Temp4, 0

store_times_up_or_down:
	mov	XH, Temp8				; Is timing higher than normal?
	cpi	XH, 3
	brcs	store_times_decrease	; No - branch

store_times_increase:
	sts	Wt_Comm_L, Temp3		; Now commutation time (~60°) divided by 4 (~15° nominal)
	sts	Wt_Comm_H, Temp4
	sts	Wt_Advance_L, Temp1		; New commutation advance time (~15° nominal)
	sts	Wt_Advance_H, Temp2
	sts	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5°)
	sts	Wt_Zc_Scan_H, Temp6
	ret

store_times_decrease:
	sts	Wt_Comm_L, Temp1		; Now commutation time (~60°) divided by 4 (~15° nominal)
	sts	Wt_Comm_H, Temp2
	sts	Wt_Advance_L, Temp3		; New commutation advance time (~15° nominal)
	sts	Wt_Advance_H, Temp4
	sts	Wt_Zc_Scan_L, Temp5		; Use this value for zero cross scan delay (7.5°)
	sts	Wt_Zc_Scan_H, Temp6
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait before zero cross scan routine
;
; No assumptions
;
; Waits for the zero cross scan wait time to elapse
; Also sets up timer 3 to wait the zero cross scan timeout time
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait_before_zc_scan:	
	sbrc	Flags0, OC1A_PENDING 
	rjmp	wait_before_zc_scan

	lds	Temp3, Comm_Period4x_L	; Set wait to zero comm period 4x value
	lds	Temp4, Comm_Period4x_H
	cli					; Disable interrupts while reading timer 1
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	Temp1, Temp3		; Set new output compare value
	adc	Temp2, Temp4
	Set_OCR1AH Temp2		; Update high byte first to avoid false output compare
	Set_OCR1AL Temp1
	sei					; Enable interrupts
	sbr	Flags0, (1<<OC1A_PENDING)
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
	sts	Comp_Wait_Reads, Zero
	ldi	Temp3, 0					; Desired comparator output
	rjmp	wait_for_comp_out_start

wait_for_comp_out_high:
	sts	Comp_Wait_Reads, Zero
	ldi	Temp3, (1<<ACO)			; Desired comparator output

wait_for_comp_out_start:
	sei							; Enable interrupts
	lds	XH, Comp_Wait_Reads
	inc	XH
	sts	Comp_Wait_Reads, XH
	sbrs	Flags0, OC1A_PENDING		; Has zero cross scan timeout elapsed?
	ret							; Yes - return

	; Select number of comparator readings based upon current rotation speed
	lds 	XH, Comm_Period4x_H		; Load rotation period
	lsr	XH					; Divide by 4
	lsr	XH
	mov	Temp1, XH
	inc	Temp1					; Add one to be sure it is always larger than zero
	breq	comp_wait_on_comp_able		; If minimum number of readings - jump directly to reading
	; For damped mode, do fewer comparator readings (since comparator info is primarily only available in the pwm on period)
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comp_wait_set_max_readings

	lsr	XH						; Divide by 4 again
	lsr	XH
	mov	Temp1, XH
	inc	Temp1					; Add one to be sure it is always larger than zero

comp_wait_set_max_readings:
	cpi	Temp1, 10					; Limit to a max of 10
	brcs	PC+2

	ldi	Temp1, 10

	sbrs	Flags2, PGM_PWM_HIGH_FREQ	; Jump if pwm frequency is low
	rjmp	comp_wait_on_comp_able

	cpi	Temp1, 4					; Limit to a max of 4
	brcs	PC+2

	ldi	Temp1, 4

comp_wait_on_comp_able:
	sbrc	Flags0, OC1A_PENDING			; Has zero cross scan timeout elapsed?
	rjmp	comp_still_wait_on_comp_able
	sei								; Enable interrupts
	ret								; Yes - return

comp_still_wait_on_comp_able:
	ldi	Temp2, COMP_PWM_HIGH_ON_DELAY		; Wait time after pwm has been switched on (motor wire electrical settling)
	sbrs	Flags2, PGM_PWM_HIGH_FREQ
	ldi	Temp2, COMP_PWM_LOW_ON_DELAY
	sei								; Enable interrupts
	nop								; Allocate only just enough time to capture interrupt
	nop
	cli								; Disable interrupts
	sbrc	Flags0, PWM_ON					; If pwm on - proceed
	rjmp	pwm_wait_startup	

	ldi	Temp2, COMP_PWM_HIGH_OFF_DELAY	; Wait time after pwm has been switched off (motor wire electrical settling)
	sbrs	Flags2, PGM_PWM_HIGH_FREQ
	ldi	Temp2, COMP_PWM_LOW_OFF_DELAY	
	sbrs	Flags1, CURR_PWMOFF_COMP_ABLE		; If comparator is not usable in pwm off - go back
	rjmp	comp_wait_on_comp_able	

pwm_wait_startup:						
	sbrs	Flags1, STARTUP_PHASE			; Set a long delay from pwm on/off events during startup
	rjmp	pwm_wait	

	ldi	Temp2, 120

pwm_wait:						
.IF CLK_8M == 1
	lsr	Temp2
.ENDIF
	Read_TCNT2 XH
	lds	Temp4, Pwm_Prev_Edge
	sub	XH, Temp4
	sbc	XH, Temp2
.IF (MODE == 1) && (DAMPED_MODE_ENABLE == 1)	; Assume same pwm cycle for fast tail escs
	sbrc	Flags1, STARTUP_PHASE
	rjmp	PC+2
	brcs	pwm_wait
	brcs	comp_wait_on_comp_able			; Re-evaluate pwm cycle during start
.ELSE
	brcs	comp_wait_on_comp_able			; Re-evaluate pwm cycle for slower escs
.ENDIF

comp_read:
	Read_Comp_Out XH					; Read comparator output
	andi	XH, (1<<ACO)
	cp	XH, Temp3
	brne	PC+2							; If comparator output is correct - proceed

	rjmp	wait_for_comp_out_start			; If comparator output is not correct - go back and restart

	dec	Temp1						; Decrement readings counter - repeat comparator reading if not zero
	brne	comp_wait_on_comp_able

	sei								; Enable interrupts
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
	cbr	Flags0, (1<<DEMAG_DETECTED)		; Clear demag detected flag
	; Check if demag compensation is enabled
	lds	XH, Pgm_Demag_Comp				; Load programmed demag compensation
	dec	XH
	breq	eval_comp_no_demag

	; Check if a demag situation has occurred
	lds	XH, Comp_Wait_Reads				; Check if there were no waits (there shall be some). If none a demag situation has occurred
	dec	XH
	brne	eval_comp_no_demag

	sbrc	Flags1, STARTUP_PHASE			; Do not set demag flag during start
	rjmp	eval_comp_no_demag	

	sbr	Flags0, (1<<DEMAG_DETECTED)		; Set demag detected flag

eval_comp_no_demag:
	sbrs	Flags1, STARTUP_PHASE
	rjmp	eval_comp_check_timeout

	lds	XH, Startup_Ok_Cnt				; Increment ok counter
	inc	XH
	sts	Startup_Ok_Cnt, XH
	sbrc	Flags0, OC1A_PENDING
	rjmp	eval_comp_exit

	sts	Startup_Ok_Cnt, Zero			; Reset ok counter
	rjmp	eval_comp_exit

eval_comp_check_timeout:
	sbrc	Flags0, OC1A_PENDING			; Has timeout elapsed?
	rjmp	eval_comp_exit
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
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	Temp1, Temp3		; Set new output compare value
	adc	Temp2, Temp4
	Set_OCR1AH Temp2		; Update high byte first to avoid false output compare
	Set_OCR1AL Temp1
	sei					; Enable interrupts
	sbr	Flags0, (1<<OC1A_PENDING)
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
	; Increment or reset consecutive count
	lds	XH, Demag_Consecutive_Cnt
	inc	XH
	sts	Demag_Consecutive_Cnt, XH
	sbrs	Flags0, DEMAG_DETECTED
	sts	Demag_Consecutive_Cnt, Zero

	; Check if a demag situation has occurred
	sbrs	Flags0, DEMAG_DETECTED				; Demag detected?
	rjmp	wait_for_comm_wait

	; Load programmed demag compensation
	lds	Temp3, Pgm_Demag_Comp_Power_Decoded	; Yes - load programmed demag compensation power decoded
	; Check for power off
	cpi	Temp3, 1
	brne	wait_for_comm_blind

	sbr	Flags0, (1<<DEMAG_CUT_POWER)			; Turn off motor power
	All_nFETs_off XH

	; Wait a blind wait
wait_for_comm_blind:
	xcall setup_zc_scan_wait					; Setup a zero cross scan wait (7.5 deg)
wait_demag_default_zc:	
	sbrc	Flags0, OC1A_PENDING 
	rjmp	wait_demag_default_zc

	; Check for power off
	lds	Temp3, Pgm_Demag_Comp_Power_Decoded	; Reload, since Temp3 is overwritten in setup_zc_scan_wait
	cpi	Temp3, 2
	brne	wait_for_comm_setup

	sbr	Flags0, (1<<DEMAG_CUT_POWER)			; Turn off motor power
	All_nFETs_off XH

wait_for_comm_setup:
	xcall	setup_comm_wait				; Setup commutation wait
wait_for_comm_wait:
	sbrc	Flags0, OC1A_PENDING 
	rjmp	wait_for_comm_wait

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
	cli						; Disable all interrupts
	BpFET_off					; Bp off
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comm12_nondamp
comm12_damp:
.IF DAMPED_MODE_ENABLE == 0
	ldi	ZL, low(pwm_cnfet_apfet_on_fast)
	ldi	ZH, high(pwm_cnfet_apfet_on_fast)
	sbrc	Flags2, PGM_PWMOFF_DAMPED_LIGHT
	rjmp	comm12_nondamp
.ENDIF
.IF DAMPED_MODE_ENABLE == 1
	ldi	ZL, low(pwm_cnfet_apfet_on_safe)
	ldi	ZH, high(pwm_cnfet_apfet_on_safe)
.ENDIF
	sbrs	Flags1, CURR_PWMOFF_DAMPED	; If pwm off not damped - branch
	rjmp	comm12_nondamp		
	CpFET_off				
	ldi	XH, NFETON_DELAY		; Delay
	dec	XH
	brne	PC-1
comm12_nondamp:
.IF HIGH_DRIVER_PRECHG_TIME != 0	; Precharge high side gate driver
	AnFET_on				
	ldi	XH, HIGH_DRIVER_PRECHG_TIME
	dec	XH
	brne	PC-1
	AnFET_off				
	ldi	XH, PFETON_DELAY
	dec	XH
	brne	PC-1
.ENDIF
	ApFET_on					; Ap on
	ldi	XH, 2
	sts	Comm_Phase, XH
	rjmp	comm_exit

comm2comm3:	
	cli						; Disable all interrupts
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comm23_nondamp
comm23_damp:
.IF DAMPED_MODE_ENABLE == 0
	ldi	ZL, low(pwm_bnfet_apfet_on_fast)
	ldi	ZH, high(pwm_bnfet_apfet_on_fast)
.ENDIF
.IF DAMPED_MODE_ENABLE == 1
	ldi	ZL, low(pwm_bnfet_apfet_on_safe)
	ldi	ZH, high(pwm_bnfet_apfet_on_safe)
.ENDIF
	sbrs	Flags1, CURR_PWMOFF_DAMPED	; If pwm off not damped - branch
	rjmp	comm23_nfet		
	BpFET_off				
	CpFET_off				
	ldi	XH, NFETON_DELAY		; Delay
	dec	XH
	brne	PC-1
	rjmp	comm23_nfet
comm23_nondamp:
	ldi	ZL, low(pwm_bfet_on)
	ldi	ZH, high(pwm_bfet_on)
comm23_nfet:
	CnFET_off					; Cn off
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm23_cp
	BnFET_on					; Yes - Bn on
comm23_cp:
	ldi	XH, 3
	sts	Comm_Phase, XH
	rjmp	comm_exit

comm3comm4:	
	cli						; Disable all interrupts
	ApFET_off					; Ap off
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comm34_nondamp
comm34_damp:
.IF DAMPED_MODE_ENABLE == 0
	ldi	ZL, low(pwm_bnfet_cpfet_on_fast)
	ldi	ZH, high(pwm_bnfet_cpfet_on_fast)
	sbrc	Flags2, PGM_PWMOFF_DAMPED_LIGHT
	rjmp	comm34_nondamp
.ENDIF
.IF DAMPED_MODE_ENABLE == 1
	ldi	ZL, low(pwm_bnfet_cpfet_on_safe)
	ldi	ZH, high(pwm_bnfet_cpfet_on_safe)
.ENDIF
	sbrs	Flags1, CURR_PWMOFF_DAMPED	; If pwm off not damped - branch
	rjmp	comm34_nondamp		
	BpFET_off				
	ldi	XH, NFETON_DELAY		; Delay
	dec	XH
	brne	PC-1
comm34_nondamp:
.IF HIGH_DRIVER_PRECHG_TIME != 0	; Precharge high side gate driver
	CnFET_on				
	ldi	XH, HIGH_DRIVER_PRECHG_TIME
	dec	XH
	brne	PC-1
	CnFET_off				
	ldi	XH, PFETON_DELAY
	dec	XH
	brne	PC-1
.ENDIF
	CpFET_on					; Cp on
	ldi	XH, 4
	sts	Comm_Phase, XH
	rjmp	comm_exit

comm4comm5:	
	cli						; Disable all interrupts
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comm45_nondamp
comm45_damp:
.IF DAMPED_MODE_ENABLE == 0
	ldi	ZL, low(pwm_anfet_cpfet_on_fast)
	ldi	ZH, high(pwm_anfet_cpfet_on_fast)
.ENDIF
.IF DAMPED_MODE_ENABLE == 1
	ldi	ZL, low(pwm_anfet_cpfet_on_safe)
	ldi	ZH, high(pwm_anfet_cpfet_on_safe)
.ENDIF
	sbrs	Flags1, CURR_PWMOFF_DAMPED	; If pwm off not damped - branch
	rjmp	comm45_nfet		
	ApFET_off				
	BpFET_off				
	ldi	XH, NFETON_DELAY		; Delay
	dec	XH
	brne	PC-1
	rjmp	comm45_nfet
comm45_nondamp:
	ldi	ZL, low(pwm_afet_on)
	ldi	ZH, high(pwm_afet_on)
comm45_nfet:
	BnFET_off					; Bn off
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm45_cp
	AnFET_on					; Yes - An on
comm45_cp:
	ldi	XH, 5
	sts	Comm_Phase, XH
	rjmp	comm_exit

comm5comm6:	
	cli						; Disable all interrupts
	CpFET_off					; Cp off
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comm56_nondamp
comm56_damp:
.IF DAMPED_MODE_ENABLE == 0
	ldi	ZL, low(pwm_anfet_bpfet_on_fast)
	ldi	ZH, high(pwm_anfet_bpfet_on_fast)
	sbrc	Flags2, PGM_PWMOFF_DAMPED_LIGHT
	rjmp	comm56_nondamp
.ENDIF
.IF DAMPED_MODE_ENABLE == 1
	ldi	ZL, low(pwm_anfet_bpfet_on_safe)
	ldi	ZH, high(pwm_anfet_bpfet_on_safe)
.ENDIF
	sbrs	Flags1, CURR_PWMOFF_DAMPED	; If pwm off not damped - branch
	rjmp	comm56_nondamp		
	ApFET_off				
	ldi	XH, NFETON_DELAY		; Delay
	dec	XH
	brne	PC-1
comm56_nondamp:
.IF HIGH_DRIVER_PRECHG_TIME != 0	; Precharge high side gate driver
	BnFET_on				
	ldi	XH, HIGH_DRIVER_PRECHG_TIME
	dec	XH
	brne	PC-1
	BnFET_off				
	ldi	XH, PFETON_DELAY
	dec	XH
	brne	PC-1
.ENDIF
	BpFET_on					; Bp on
	ldi	XH, 6
	sts	Comm_Phase, XH
	rjmp	comm_exit

comm6comm1:	
	cli						; Disable all interrupts
	sbrs	Flags2, PGM_PWMOFF_DAMPED
	rjmp	comm61_nondamp
comm61_damp:
.IF DAMPED_MODE_ENABLE == 0
	ldi	ZL, low(pwm_cnfet_bpfet_on_fast)
	ldi	ZH, high(pwm_cnfet_bpfet_on_fast)
.ENDIF
.IF DAMPED_MODE_ENABLE == 1
	ldi	ZL, low(pwm_cnfet_bpfet_on_safe)
	ldi	ZH, high(pwm_cnfet_bpfet_on_safe)
.ENDIF
	sbrs	Flags1, CURR_PWMOFF_DAMPED	; If pwm off not damped - branch
	rjmp	comm61_nfet		
	ApFET_off				
	CpFET_off				
	ldi	XH, NFETON_DELAY		; Delay
	dec	XH
	brne	PC-1
	rjmp	comm61_nfet
comm61_nondamp:
	ldi	ZL, low(pwm_cfet_on)
	ldi	ZH, high(pwm_cfet_on)
comm61_nfet:
	AnFET_off					; An off
	sbrs	Flags0, PWM_ON			; Is pwm on?
	rjmp	comm61_cp
	CnFET_on					; Yes - Cn on
comm61_cp:
	ldi	XH, 1
	sts	Comm_Phase, XH

comm_exit:
	sei						; Enable all interrupts
	lds	XH, Pgm_Demag_Comp		; Check demag comp setting
	cpi	XH, 2				; Check whether power shall be kept off upon consecutive demgs			
	brcs	comm_restore_power		; Less than value - branch

	lds	XH, Demag_Consecutive_Cnt; Check consecutive demags
	cpi	XH, 3
	brcc	comm_return			; Do not reapply power if many consecutive demags. This will help retain sync during hard accelerations

comm_restore_power:
	cbr	Flags0, (1<<DEMAG_CUT_POWER)	; Clear demag power cut flag

comm_return:
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
	ldi	Temp3, low(pwm_nofet_on)	; Set Z register to desired pwm_nfet_on label
	ldi	Temp4, high(pwm_nofet_on)
	movw	ZL, Temp3				; Set Z register in one instruction
	All_nFETs_Off XH			; Turn off all nfets
	All_pFETs_Off XH			; Turn off all pfets
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
	ldi	Temp1, DEFAULT_PGM_MAIN_DAMPING_FORCE
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
	ldi	Temp1, DEFAULT_PGM_MAIN_THROTTLE_RATE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MAIN_DEMAG_COMP
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_BEC_VOLTAGE_HIGH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_PPM_CENTER_THROTTLE
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
	ldi	Temp1, 0xFF
	st	X+, Temp1	
	st	X+, Temp1		
	st	X+, Temp1	
	ldi	Temp1, DEFAULT_PGM_TAIL_COMM_TIMING
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_DAMPING_FORCE
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
	ldi	Temp1, DEFAULT_PGM_TAIL_THROTTLE_RATE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_TAIL_DEMAG_COMP
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_BEC_VOLTAGE_HIGH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_PPM_CENTER_THROTTLE
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
	ldi	Temp1, DEFAULT_PGM_MULTI_LOW_VOLTAGE_LIM
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
	ldi	Temp1, 0xFF
	st	X+, Temp1	
	st	X+, Temp1		
	st	X+, Temp1		
	ldi	Temp1, DEFAULT_PGM_MULTI_COMM_TIMING
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_DAMPING_FORCE
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
	ldi	Temp1, DEFAULT_PGM_MULTI_THROTTLE_RATE
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_MULTI_DEMAG_COMP
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_BEC_VOLTAGE_HIGH
	st	X+, Temp1
	ldi	Temp1, DEFAULT_PGM_PPM_CENTER_THROTTLE
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
	; Load programmed damping force
	lds	Temp3, Pgm_Damping_Force		; Load damping force and store in Temp3
	; Decode damping
	ldi	Temp1, 9					; Set default
	ldi	Temp2, 1
	cpi	Temp3, 2
	brne	decode_damping_3			; Look for 2

	ldi	Temp1, 5
	ldi	Temp2, 1

decode_damping_3:
	cpi	Temp3, 3
	brne	decode_damping_4			; Look for 3

	ldi	Temp1, 5
	ldi	Temp2, 2

decode_damping_4:
	cpi	Temp3, 4
	brne	decode_damping_5			; Look for 4

	ldi	Temp1, 5
	ldi	Temp2, 3

decode_damping_5:
	cpi	Temp3, 5
	brne	decode_damping_6			; Look for 5

	ldi	Temp1, 9
	ldi	Temp2, 7

decode_damping_6:
	cpi	Temp3, 6
	brne	decode_damping_done			; Look for 6

	ldi	Temp1, 0
	ldi	Temp2, 0

decode_damping_done:
	sts	Damping_Period, Temp1
	sts	Damping_On, Temp2
	; Load programmed pwm frequency
	lds	Temp3, Pgm_Pwm_Freq			; Load pwm freq and store in Temp3
.IF MODE == 0	; Main
	cbr	Flags2, (1<<PGM_PWMOFF_DAMPED_LIGHT)
	cpi	Temp3, 3
	brne	PC+2
	sbr	Flags2, (1<<PGM_PWMOFF_DAMPED_LIGHT)
	cbr	Flags2, (1<<PGM_PWMOFF_DAMPED_FULL)
.ENDIF
.IF MODE >= 1	; Tail or multi
	cbr	Flags2, (1<<PGM_PWMOFF_DAMPED_LIGHT)
	cpi	Temp3, 3
	brne	PC+2
	sbr	Flags2, (1<<PGM_PWMOFF_DAMPED_LIGHT)
	cbr	Flags2, (1<<PGM_PWMOFF_DAMPED_FULL)
	cpi	Temp3, 4
	brne	PC+2
	sbr	Flags2, (1<<PGM_PWMOFF_DAMPED_FULL)
.ENDIF
	cbr	Flags2, (1<<PGM_PWMOFF_DAMPED)	; Set damped flag if fully damped or damped light is set
	ldi	XH, ((1<<PGM_PWMOFF_DAMPED_FULL)+(1<<PGM_PWMOFF_DAMPED_LIGHT))
	and	XH, Flags2					; Check if any damped mode is set
	breq	PC+2
	sbr	Flags2, (1<<PGM_PWMOFF_DAMPED)
	cbr	Flags1, (1<<CURR_PWMOFF_DAMPED)	; Set non damped status as start
	tst	XH
	breq	PC+2
	sbr	Flags1, (1<<CURR_PWMOFF_DAMPED)	; Set non damped status as start if damped
	sbr	Flags1, (1<<CURR_PWMOFF_COMP_ABLE)	; Set comparator usable status
	tst	XH
	breq	PC+2
	cbr	Flags1, (1<<CURR_PWMOFF_COMP_ABLE)	; Set comparator not usable status if damped
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
	mov	XH, Temp3			
	cpi	XH, 2
	breq	decode_pwm_freq_low

	sbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)
	rjmp	decode_pwm_freq_end

decode_pwm_freq_low:
	cbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)

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
	ldi	ZL, low(GOV_GAIN_TABLE<<1)
	ldi	ZH, high(GOV_GAIN_TABLE<<1)
	lds	Temp1, Pgm_Gov_P_Gain	; Decode governor P gain	
	dec	Temp1
	add	ZL, Temp1
	adc	ZH, Zero
	lpm	XH, Z
	sts	Pgm_Gov_P_Gain_Decoded, XH	
	lds	Temp1, Pgm_Gov_I_Gain	; Decode governor I gain	
	dec	Temp1
	add	ZL, Temp1
	adc	ZH, Zero
	lpm	XH, Z
	sts	Pgm_Gov_I_Gain_Decoded, XH	
	xcall switch_power_off		; Reset Z register
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
	ldi	ZL, low(THROTTLE_RATE_TABLE<<1)
	ldi	ZH, high(THROTTLE_RATE_TABLE<<1)
	lds	Temp1, Pgm_Throttle_Rate
	dec	Temp1
	add	ZL, Temp1
	adc	ZH, Zero
	lpm	XH, Z
	sts	Pgm_Throttle_Rate_Decoded, XH	
	xcall switch_power_off		; Reset Z register
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
	ldi	ZL, low(STARTUP_POWER_TABLE<<1)
	ldi	ZH, high(STARTUP_POWER_TABLE<<1)
	lds	Temp1, Pgm_Startup_Pwr
	dec	Temp1
	add	ZL, Temp1
	adc	ZH, Zero
	lpm	XH, Z
	sts	Pgm_Startup_Pwr_Decoded, XH	
	xcall switch_power_off		; Reset Z register
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
	ldi	ZL, low(DEMAG_POWER_TABLE<<1)
	ldi	ZH, high(DEMAG_POWER_TABLE<<1)
	lds	Temp1, Pgm_Demag_Comp
	dec	Temp1
	add	ZL, Temp1
	adc	ZH, Zero
	lpm	XH, Z
	sts	Pgm_Demag_Comp_Power_Decoded, XH	
	xcall switch_power_off		; Reset Z register
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
.IF DUAL_BEC_VOLTAGE == 1
	Set_BEC_Lo XH			; Set default to low
	lds	Temp1, Pgm_BEC_Voltage_High		
	tst	Temp1				
	breq	set_bec_voltage_exit	

	Set_BEC_Hi XH			; Set to high

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
	; Check lock bits
	ldi	ZL, 0x01
	ldi	ZH, 0x00
	Prepare_Lock_Or_Fuse_Read XH
	lpm	XH, Z
	andi	XH, 0x0F			; Check only for BLB02 BLB01 LB2 LB1
	breq	reset			; If lock bits byte is not 0x0F, then loop here

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
	; Set default programmed parameters
	xcall set_default_parameters
	; Read all programmed parameters
	xcall read_all_eeprom_parameters
	; Decode parameters
	xcall decode_parameters
	; Decode governor gains
	xcall decode_governor_gains
	; Decode throttle rate
	xcall decode_throttle_rate
	; Decode startup power
	xcall decode_startup_power
	; Decode demag compensation
	xcall decode_demag_comp
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
	; Initializing beep
	cli					; Disable interrupts explicitly
	xcall wait200ms	
	xcall beep_f1
	xcall wait30ms
	xcall beep_f2
	xcall wait30ms
	xcall beep_f3
	xcall wait30ms
	; Wait for receiver to initialize
	xcall wait1s
	xcall wait200ms
	xcall wait200ms
	xcall wait100ms
	; Initialize interrupts and registers
	Initialize_Interrupts XH			; Set all interrupt enable bits
	; Initialize comparator
	Comp_Init XH					; Initialize comparator
	; Initialize ADC
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
measure_pwm_freq_start:	
	ldi	Temp3, 5						; Number of pulses to measure
measure_pwm_freq_loop:	
	; Check if period diff was accepted
	lds	XH, Rcp_Period_Diff_Accepted
	tst	XH
	brne	PC+2

	ldi	Temp3, 5						; Reset number of pulses to measure

	xcall wait3ms						; Wait for next pulse (NB: Uses Temp1/2!) 
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
	xcall wait100ms					; Wait for new RC pulse

	; Validate RC pulse
validate_rcp_start:	
	xcall wait3ms						; Wait for next pulse (NB: Uses Temp1/2!) 
	ldi	Temp1, RCP_VALIDATE				; Set validate level as default
	mov	XH, Flags3					; Check pwm frequency flags
	andi	XH, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	brne	PC+2							; If a flag is set (PWM) - branch

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
	mov	XH, Flags3			; Check pwm frequency flags
	andi	XH, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	breq	throttle_high_cal_start	; If no flag is set (PPM) - branch

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
	ldi	XH, 8				; Set 3 seconds wait time
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
	lds	XH, New_Rcp			; Load new RC pulse value
	cpi	XH, RCP_STOP			; Below stop?
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

	mov	XH, Flags3					; Check pwm frequency flags
	andi	XH, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	brne	wait_for_power_on_ppm_not_missing	; If a flag is set (PWM) - branch
	rjmp	measure_pwm_freq_init			; If ppm and pulses missing - go back to measure pwm frequency

wait_for_power_on_ppm_not_missing:
	lds	XH, New_Rcp			; Load new RC pulse value
	cpi	XH, (RCP_STOP+5) 		; Higher than stop (plus some hysteresis)?
	brcc	PC+2
	rjmp	wait_for_power_on_loop	; No - start over

.IF MODE >= 1	; Tail or multi
	lds	XH, Pgm_Direction		; Check if bidirectional operation
	subi	XH, 3
	breq	PC+2					; Do not wait if bidirectional operation
.ENDIF

	xcall wait100ms			; Wait to see if start pulse was only a glitch

	lds	XH, Rcp_Timeout_Cnt		; Load RC pulse timeout counter value
	tst	XH
	brne	PC+2					; If it is not zero - proceed

	rjmp	measure_pwm_freq_init	; If it is zero (pulses missing) - go back to measure pwm frequency


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
	sei
	lds	XH, Pgm_Motor_Idle
	sts	Pwm_Motor_Idle, XH		; Set idle pwm to programmed value			
	sts	Gov_Target_L, Zero		; Set target to zero
	sts	Gov_Target_H, Zero
	sts	Gov_Integral_L, Zero	; Set integral to zero
	sts	Gov_Integral_H, Zero
	sts	Gov_Integral_X, Zero
	sts	Adc_Conversion_Cnt, Zero
	ldi	Flags0, 0				; Clear flags0
	ldi	Flags1, 0				; Clear flags1
	sts	Demag_Consecutive_Cnt, Zero
	xcall initialize_all_timings	; Initialize timing
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
	sei
	ldi	XH, 1				; Set low pwm again after calling set_startup_pwm
	mov	Current_Pwm_Limited, XH
	sts	Spoolup_Limit_Skip, XH			
	lds	XH, Auto_Bailout_Armed
	sts	Spoolup_Limit_Cnt, XH
	; Begin startup sequence
	sbr	Flags1, (1<<MOTOR_SPINNING)	; Set motor spinning flag
	sbr	Flags1, (1<<STARTUP_PHASE)	; Set startup phase flag
	sts	Startup_Ok_Cnt, Zero		; Reset ok counter
	xcall comm5comm6				; Initialize commutation
	xcall comm6comm1				
	xcall calc_next_comm_timing		; Set virtual commutation point
	xcall initialize_all_timings		; Initialize timing
	xcall calc_new_wait_times		; Calculate new wait times
	rjmp	run1



;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Run entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
damped_transition:
	; Transition from nondamped to damped if applicable
	xcall decode_parameters		; Set programmed parameters
	xcall comm6comm1
	sts	Adc_Conversion_Cnt, Zero	; Make sure a voltage reading is done next time
	Set_Adc_Ip_Volt			; Set adc measurement to voltage

; Run 1 = B(p-on) + C(n-pwm) - comparator A evaluated
; Out_cA changes from low to high
run1:
	Set_Comp_Phase_A XH			; Set comparator to phase A
	xcall wait_for_comp_out_high	; Wait zero cross wait and wait for high
	xcall evaluate_comparator_integrity	; Check whether comparator reading has been normal
	xcall setup_comm_wait		; Setup wait time from zero cross to commutation
	xcall calc_governor_target	; Calculate governor target
	xcall wait_for_comm			; Wait from zero cross to commutation
	xcall comm1comm2			; Commutate
	xcall calc_next_comm_timing	; Calculate next timing and start advance timing wait
	xcall wait_advance_timing	; Wait advance timing and start zero cross wait
	xcall calc_new_wait_times
	xcall wait_before_zc_scan	; Wait zero cross wait and start zero cross timeout

; Run 2 = A(p-on) + C(n-pwm) - comparator B evaluated
; Out_cB changes from high to low
run2:
	Set_Comp_Phase_B XH			
	xcall wait_for_comp_out_low
	xcall evaluate_comparator_integrity
	xcall setup_comm_wait	
	xcall calc_governor_prop_error
	xcall wait_for_comm
	xcall comm2comm3
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall wait_before_zc_scan	

; Run 3 = A(p-on) + B(n-pwm) - comparator C evaluated
; Out_cC changes from low to high
run3:
	Set_Comp_Phase_C XH		
	xcall wait_for_comp_out_high
	xcall evaluate_comparator_integrity
	xcall setup_comm_wait	
	xcall calc_governor_int_error
	xcall wait_for_comm
	xcall comm3comm4
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall wait_before_zc_scan	

; Run 4 = C(p-on) + B(n-pwm) - comparator A evaluated
; Out_cA changes from high to low
run4:
	Set_Comp_Phase_A XH		
	xcall wait_for_comp_out_low
	xcall evaluate_comparator_integrity
	xcall setup_comm_wait	
	xcall calc_governor_prop_correction
	xcall wait_for_comm
	xcall comm4comm5
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall wait_before_zc_scan	

; Run 5 = C(p-on) + A(n-pwm) - comparator B evaluated
; Out_cB changes from low to high
run5:
	Set_Comp_Phase_B XH			
	xcall wait_for_comp_out_high
	xcall evaluate_comparator_integrity
	xcall setup_comm_wait	
	xcall calc_governor_int_correction
	xcall wait_for_comm
	xcall comm5comm6
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall wait_before_zc_scan	

; Run 6 = B(p-on) + A(n-pwm) - comparator C evaluated
; Out_cC changes from high to low
run6:
	Set_Comp_Phase_C XH			
	xcall wait_for_comp_out_low
	Start_Adc XH
	xcall evaluate_comparator_integrity
	xcall setup_comm_wait	
	xcall wait_for_comm
	xcall comm6comm1
	xcall calc_next_comm_timing
	xcall wait_advance_timing
	xcall calc_new_wait_times
	xcall check_temp_voltage_and_limit_power
	xcall wait_before_zc_scan	

	; Check if it is startup
	sbrs	Flags1, STARTUP_PHASE
	rjmp	normal_run_checks

	; Set spoolup power variables
	lds	XH, Pwm_Spoolup_Beg
	sts	Pwm_Limit, XH				; Set initial max power
	sts	Pwm_Limit_Spoolup, XH		; Set initial slow spoolup power
	lds	XH, Auto_Bailout_Armed
	sts	Spoolup_Limit_Cnt, XH
	ldi	XH, 1
	sts	Spoolup_Limit_Skip, XH			
	; Check startup ok counter
	ldi	Temp2, 100				; Set nominal startup parameters
	ldi	Temp3, 20
.IF MODE >= 1	; Tail or multi
	lds	XH, Pgm_Direction			; Check if bidirectional operation
	cpi	XH, 3
	brne	start_params_set			; No - branch

	ldi	Temp2, 30					; Set faster startup parameters for bidirectional operation
	ldi	Temp3, 5

start_params_set:
.ENDIF
	lds	XH, Startup_Ok_Cnt			; Load ok counter
	cp	XH, Temp2					; Is counter above requirement?
	brcs	start_check_rcp			; No - proceed

	cbr	Flags1, (1<<STARTUP_PHASE)	; Clear startup phase flag
	sbr	Flags1, (1<<INITIAL_RUN_PHASE)	; Set initial run phase flag
	sts	Startup_Rot_Cnt, Temp3		; Set startup rotation count
.IF MODE == 1	; Tail
	ldi	XH, 0xFF
	sts	Pwm_Limit, XH				; Allow full power
	sts	Pwm_Limit_Spoolup, XH	
.ENDIF
.IF MODE == 2	; Multi
	lds	Temp1, Pgm_Direction		; Check if bidirectional operation
	cpi	XH, 3
	brne	start_pwm_lim_set

	ldi	XH, 0xFF
	sts	Pwm_Limit, XH				; Allow full power in bidirectional operation
	sts	Pwm_Limit_Spoolup, XH	

start_pwm_lim_set:
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

	; Decrement startup rotaton count
	lds	XH, Startup_Rot_Cnt
	dec	XH
	; Check number of nondamped rotations
	brne	normal_run_check_startup_rot	; Branch if counter is not zero

	cbr	Flags1, (1<<INITIAL_RUN_PHASE); Clear initial run phase flag
	rjmp damped_transition			; Do damped transition if counter is zero

normal_run_check_startup_rot:
	sts	Startup_Rot_Cnt, XH			; Not zero - store counter
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
	mov	XH, Flags3				; Check pwm frequency flags
	andi	XH, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	brne	run6_check_speed			; If a flag is set (PWM) - branch

	lds	XH, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	tst	XH
	breq	run_to_wait_for_power_on		; If it is zero - go back to wait for poweron

run6_check_speed:
	lds	XH, Comm_Period4x_H			; Is Comm_Period4x more than 32ms (~1220 eRPM)?
.IF CLK_8M == 0
	cpi	XH, 0xF0
.ELSE
	cpi	XH, 0x70
.ENDIF
	brcc	run_to_wait_for_power_on		; Yes - go back to motor start
	rjmp	run1						; Go back to run 1


run_to_wait_for_power_on:	
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
	sts	Pwm_Motor_Idle, Zero		; Set motor idle to zero
	cbr	Flags1, (1<<MOTOR_SPINNING)	; Clear motor spinning flag
	sei
	xcall wait1ms					; Wait for pwm to be stopped
	xcall switch_power_off
.IF MODE == 0	; Main
	mov	XH, Flags3				; Check pwm frequency flags
	andi	XH, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	brne	run_to_next_state_main		; If a flag is set (PWM) - branch

	lds	XH, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	tst	XH
	brne	run_to_next_state_main		; If it is not zero - branch

	rjmp	measure_pwm_freq_init		; If it is zero (pulses missing) - go back to measure pwm frequency

run_to_next_state_main:
	lds	XH, Pgm_Main_Rearm_Start
	cpi	XH, 1					; Is re-armed start enabled?
	brcs	jmp_wait_for_power_on		; No - do like tail and start immediately

	rjmp	validate_rcp_start			; Yes - go back to validate RC pulse

jmp_wait_for_power_on:
	rjmp	wait_for_power_on			; Go back to wait for power on
.ENDIF
.IF MODE >= 1	; Tail or multi
	mov	XH, Flags3				; Check pwm frequency flags
	andi	XH, ((1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)+(1<<RCP_PWM_FREQ_12KHZ))
	brne	jmp_wait_for_power_on		; If a flag is set (PWM) - branch

	lds	XH, Rcp_Timeout_Cnt			; Load RC pulse timeout counter value
	tst	XH
	brne	jmp_wait_for_power_on		; If it is not zero - go back to wait for poweron

	rjmp	measure_pwm_freq_init		; If it is zero (pulses missing) - go back to measure pwm frequency

jmp_wait_for_power_on:
	rjmp	wait_for_power_on			; Go back to wait for power on
.ENDIF

;**** **** **** **** **** **** **** **** **** **** **** **** ****

.INCLUDE "BLHeliTxPgm.inc"			; Include source code for programming the ESC with the TX

;**** **** **** **** **** **** **** **** **** **** **** **** ****





.EXIT
