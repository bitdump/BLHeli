$NOMOD51
;**** **** **** **** ****
;
; BLHeli program for controlling brushless motors in multirotors
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
; This software was initially designed for use with Eflite mCP X, but is now adapted to copters/planes in general
;
; The software was inspired by and started from from Bernard Konze's BLMC: http://home.versanet.de/~bkonze/blc_6a/blc_6a.htm
; And also Simon Kirby's TGY: https://github.com/sim-/tgy
;
; This file is best viewed with tab width set to 5
;
; The code is designed for multirotor applications, running damped light mode
;
; The input signal can be Normal (1-2ms), OneShot125 (125-250us), OneShot42 (41.7-83.3us) or Multishot (5-25us) at rates as high as allowed by the format.
; Three Dshot signal rates are also supported, Dshot150, Dshot300 and Dshot600. A 48MHz MCU is required for Dshot600.
; The code autodetects normal, OneShot125, Oneshot42, Multishot or Dshot.
;
; The first lines of the software must be modified according to the chosen environment:
; ESCNO EQU "ESC"
; MCU_48MHZ EQU "N"
; FETON_DELAY EQU "N"
; 
;**** **** **** **** **** **** **** **** **** **** **** **** **** **** **** 
; Revision history:
; - Rev16.0 Started. Built upon rev 14.5 of base code
;           Using hardware pwm for very smooth throttle response, silent running and support of very high rpms
;           Implemented reverse bidirectional mode
;           Implemented separate throttle gains fwd and rev in bidirectional mode
;           Implemented support for Oneshot42 and Multishot
; - Rev16.1 Made low rpm power limiting programmable through the startup power parameter
; - Rev16.2 Fixed bug that prevented temperature protection
;           Improved robustness to very high input signal rates
;           Beeps can be turned off by programming beep strength to 1
;           Throttle cal difference is checked to be above required minimum before storing. Throttle cal max is not stored until successful min throttle cal
; - Rev16.3 Implemented programmable temperature protection
;           Improved protection of bootloader and generally reduced risk of flash corruption
;           Some small changes for improved sync hold
; - Rev16.4 Fixed bug where bootloader operation could be blocked by a defective "eeprom" signature
; - Rev16.5 Added support for DShot150, DShot300 and DShot600
; - Rev16.6 Fixed signal detection issue of multishot at 32kHz
;           Improved bidirectional mode for high input signal rates
; - Rev16.7 Addition of Dshot commands for beeps and temporary reverse direction (largely by brycedjohnson)
; - Rev16.71	Add Reversed Dshot 300/600			(by JazzMac)	
;				Add Dshot tlm400/800, tlm always after a reversed dshot, no command to start/stop tlm
;				Rremove other protocols
;				Stop support BB1(24Mhz)
; - Rev16.72	Change timming to tlm375/750
;				Modify delay between dshot/tlm to 30us to meet spec.        
;				Fix dshot decoder INT0 wrapped issue.
; - Rev16.73	Lose dshot decoder timming
;				Arm check: more correct packet needed, bouble check zero throttol
; - Rev16.74	Remove PCA int, update new PWM value into PCA reload registers instantly
;				For FETON_DELAY=0, also update damp PCA channel
; - Rev16.75	Rearrange commutatioin logic	 
; - Rev16.76	Add PWM 48k mode
;					PWM 24khz: 10bit
;					PWM 48khz:  9bit
; - Rev16.77	Preset a damping off to secure non-overlaping of PWM and comp-PWM	
;				Align PWM to commutation rising edge
;				Stop support deadtime=0
; - Rev16.78	a. Reset PCA at the beginning of each commutation phase
;				a11. add delta-sigma and 96khz	
; 				e. modify damping and commutation logic	
; 				f.	support L/BB1 ESC, only 48Khz with pwm 8bit/delta-sigma 3bit	
;					support dshot150/tlm 188
;				g.	Add rpm stabilizer
;					fix delta-sigma bit overwrite
;				i.	move dshot process to main loop
; - Rev16.79	cancel move dshot process to main loop
; - Rev16.8		Add back move dshot process to main loop/ improve commutation timing
;**** **** **** **** **** **** **** **** **** **** **** **** **** **** **** 
;
; Minimum 8K Bytes of In-System Self-Programmable Flash
; Minimum 512 Bytes Internal SRAM
;
;**** **** **** **** ****
; Master clock is internal 24MHz oscillator (or 48MHz, for which the times below are halved)
; Although 24/48 are used in the code, the exact clock frequencies are 24.5MHz or 49.0 MHz
; Timer 0 (41.67ns counts) always counts up and is used for
; - RC pulse measurement
; - dshot tlm bit-bang
; Timer 1 (41.67ns counts) always counts up and is used for
; - DShot frame sync detection
; Timer 2 (500ns counts) always counts up and is used for
; - RC pulse timeout counts and commutation times
; Timer 3 (500ns counts) always counts up and is used for
; - Commutation timeouts
; PCA0 (41.67ns counts) always counts up and is used for
; - Hardware PWM generation
;
;**** **** **** **** ****
; Interrupt handling
; The C8051 does not disable interrupts when entering an interrupt routine.
; Also some interrupt flags need to be cleared by software
; The code disables interrupts in some interrupt routines
; - Interrupts are disabled during beeps, to avoid audible interference from interrupts
;
;**** **** **** **** ****
; Motor control:
; - Brushless motor control with 6 states for each electrical 360 degrees
; - An advance timing of 0deg has zero cross 30deg after one commutation and 30deg before the next
; - Timing advance in this implementation is set to 15deg nominally
; - Motor pwm is always damped light (aka complementary pwm, regenerative braking)
; Motor sequence starting from zero crossing:
; - Timer wait: Wt_Comm			15deg	; Time to wait from zero cross to actual commutation
; - Timer wait: Wt_Advance		15deg	; Time to wait for timing advance. Nominal commutation point is after this
; - Timer wait: Wt_Zc_Scan		7.5deg	; Time to wait before looking for zero cross
; - Scan for zero cross			22.5deg	; Nominal, with some motor variations
;
; Motor startup:
; There is a startup phase and an initial run phase, before normal bemf commutation run begins.
;
;**** **** **** **** ****
; List of enumerated supported ESCs
A_			EQU 1	; X  X  RC X  MC MB MA CC    X  X  Cc Cp Bc Bp Ac Ap
B_			EQU 2	; X  X  RC X  MC MB MA CC    X  X  Ap Ac Bp Bc Cp Cc
C_			EQU 3	;;Ac Ap MC MB MA CC X  RC    X  X  X  X  Cc Cp Bc Bp
D_			EQU 4	; X  X  RC X  CC MA MC MB    X  X  Cc Cp Bc Bp Ac Ap	Com fets inverted
E_			EQU 5	; L1 L0 RC X  MC MB MA CC    X  L2 Cc Cp Bc Bp Ac Ap	A with LEDs
F_			EQU 6	; X  X  RC X  MA MB MC CC    X  X  Cc Cp Bc Bp Ac Ap
G_			EQU 7	; X  X  RC X  CC MA MC MB    X  X  Cc Cp Bc Bp Ac Ap	Like D, but noninverted com fets
H_			EQU 8	; RC X  X  X  MA MB CC MC    X  Ap Bp Cp X  Ac Bc Cc
I_			EQU 9	; X  X  RC X  MC MB MA CC    X  X  Ac Bc Cc Ap Bp Cp
J_			EQU 10	; L2 L1 L0 RC CC MB MC MA    X  X  Cc Bc Ac Cp Bp Ap	LEDs
K_			EQU 11	; X  X  MC X  MB CC MA RC    X  X  Ap Bp Cp Cc Bc Ac	Com fets inverted
L_			EQU 12	; X  X  RC X  CC MA MB MC    X  X  Ac Bc Cc Ap Bp Cp
M_			EQU 13	; MA MC CC MB RC L0 X  X     X  Cc Bc Ac Cp Bp Ap X		LED
N_			EQU 14	; X  X  RC X  MC MB MA CC    X  X  Cp Cc Bp Bc Ap Ac
O_			EQU 15	; X  X  RC X  CC MA MC MB    X  X  Cc Cp Bc Bp Ac Ap	Like D, but low side pwm
P_			EQU 16	; X  X  RC MA CC MB MC X     X  Cc Bc Ac Cp Bp Ap X
Q_			EQU 17	;;Cp Bp Ap L1 L0 X  RC X     X  MA MB MC CC Cc Bc Ac	LEDs
R_			EQU 18	; X  X  RC X  MC MB MA CC    X  X  Ac Bc Cc Ap Bp Cp
S_          EQU 19  ; X  X  RC X  CC MA MC MB    X  X  Cc Cp Bc Bp Ac Ap	Like O, but com fets inverted
T_			EQU 20	; RC X  MA X  MB CC MC X     X  X  Cp Bp Ap Ac Bc Cc
U_			EQU 21	; MA MC CC MB RC L0 L1 L2    X  Cc Bc Ac Cp Bp Ap X		Like M, but with 3 LEDs
V_			EQU 22	; Cc X  RC X  MC CC MB MA    X  Ap Ac Bp X  X  Bc Cp
W_			EQU 23  ; RC MC MB X  CC MA X X      X  Ap Bp Cp X  X  X  X     Tristate gate driver


;**** **** **** **** ****
; Select the port mapping to use (or unselect all for use with external batch compile file)
;ESCNO EQU A_
;ESCNO EQU B_
;ESCNO EQU C_
;ESCNO EQU D_
;ESCNO EQU E_
;ESCNO EQU F_
;ESCNO EQU G_
;ESCNO EQU H_
;ESCNO EQU I_
;ESCNO EQU J_
;ESCNO EQU K_
;ESCNO EQU L_
;ESCNO EQU M_
;ESCNO EQU N_
;ESCNO EQU O_
;ESCNO EQU P_
;ESCNO EQU Q_
;ESCNO EQU R_
;ESCNO EQU S_
;ESCNO EQU T_
;ESCNO EQU U_
;ESCNO EQU V_
;ESCNO EQU W_

;**** **** **** **** ****
; Select the MCU type (or unselect for use with external batch compile file)
;MCU_48MHZ EQU	0

;**** **** **** **** ****
; Select the fet deadtime (or unselect for use with external batch compile file)
;FETON_DELAY EQU 15	; 20.4ns per step

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF MCU_48MHZ == 0
	IF	PWM == 24
		PWM_BITS				EQU	9		;; 24khz
		PWM_DELTA_SIGMA_BITS	EQU	2 
		DS_MASK					EQU 07h
		PWM_BOOST_MASK			EQU 0feh		
	ELSE
		PWM_BITS				EQU	8		;; 48khz
		PWM_DELTA_SIGMA_BITS	EQU	3 
		DS_MASK					EQU 0fh	
		PWM_BOOST_MASK			EQU 0ffh
	ENDIF
ELSE
	IF 		PWM == 24
		PWM_BITS				EQU	10		;; 24khz
		PWM_DELTA_SIGMA_BITS	EQU	1 
		DS_MASK					EQU 03h
		PWM_BOOST_MASK			EQU 0fch
	ELSEIF	PWM == 48
		PWM_BITS				EQU	9		;; 48khz
		PWM_DELTA_SIGMA_BITS	EQU	2 
		DS_MASK					EQU 07h
		PWM_BOOST_MASK			EQU 0feh
	ELSE
		PWM_BITS				EQU	8		;; 96khz
		PWM_DELTA_SIGMA_BITS	EQU	3 
		DS_MASK					EQU 0fh	
		PWM_BOOST_MASK			EQU 0ffh
	ENDIF
ENDIF

PWM_BOOST_NUMBER			EQU	1		;; 1: not boost  2:1step   3:2steps
PWM_BOOST_DOUBLE			EQU	0		;; 0: diffx1    1: diffx2	
SIMULATE_BB1				EQU	0
CUMMU_150					EQU	0
DEBUG						EQU 0

IF (MCU_48MHZ == 0) AND (SIMULATE_BB1 == 0)
$include (SI_EFM8BB1_Defs.inc)
ELSE
$include (SI_EFM8BB2_Defs.inc)
ENDIF

IF (MCU_48MHZ == 0)
	DSHOT_TLM_DELAY			EQU	100h-(5000*24/4/1000)		;; 10us (30us in total) delay for tlm to start											
	DSTLM750_BIT_TIME_1		EQU	100h-( 150*49/4/1000)		;; 
	DSTLM750_BIT_TIME_2		EQU	100h-(1700*49/4/1000)
	DSTLM750_BIT_TIME_3		EQU	100h-(3100*49/4/1000)		;; 150/1700/2900 1.0/2.5/3.75us dshot600/tlm750 update tl0

	DSTLM375_BIT_TIME_1		EQU	100h-(1900*49/4/1000)		;; 
	DSTLM375_BIT_TIME_2		EQU	100h-(4700*49/4/1000)
	DSTLM375_BIT_TIME_3		EQU	100h-(7200*49/4/1000)		;;  1700/4200/6650 2.5/5.2/7.9us dshot300/tlm375 update tl0	
	_FETON_DELAY_			EQU (FETON_DELAY SHR 1)
ELSE
	DSHOT_TLM_DELAY			EQU	100h-(16500*49/4/1000)		;; test   13  10us (30us in total) delay for tlm to start											
	DSTLM750_BIT_TIME_1		EQU	100h-( 150*49/4/1000)		;; 
	DSTLM750_BIT_TIME_2		EQU	100h-(1700*49/4/1000)
	DSTLM750_BIT_TIME_3		EQU	100h-(2900*49/4/1000)		;; 150/1700/2900 1.0/2.5/3.75us dshot600/tlm750 update tl0

	DSTLM375_BIT_TIME_1		EQU	100h-(1700*49/4/1000)		;; 100 / 3900 / 6500
	DSTLM375_BIT_TIME_2		EQU	100h-(4400*49/4/1000)
	DSTLM375_BIT_TIME_3		EQU	100h-(7000*49/4/1000)		;;  1700/4200/6650 2.5/5.2/7.9us dshot300/tlm375 update tl0	
	_FETON_DELAY_			EQU FETON_DELAY
ENDIF
;**** **** **** **** ****
; ESC selection statements
IF ESCNO == A_
$include (A.inc)	; Select pinout A
ENDIF

IF ESCNO == B_
$include (B.inc)	; Select pinout B
ENDIF

IF ESCNO == C_
$include (C.inc)	; Select pinout C
ENDIF

IF ESCNO == D_
$include (D.inc)	; Select pinout D
ENDIF

IF ESCNO == E_
$include (E.inc)	; Select pinout E
ENDIF

IF ESCNO == F_
$include (F.inc)	; Select pinout F
ENDIF

IF ESCNO == G_
$include (G.inc)	; Select pinout G
ENDIF

IF ESCNO == H_
$include (H.inc)	; Select pinout H
ENDIF

IF ESCNO == I_
$include (I.inc)	; Select pinout I
ENDIF

IF ESCNO == J_
$include (J.inc)	; Select pinout J
ENDIF

IF ESCNO == K_
$include (K.inc)	; Select pinout K
ENDIF

IF ESCNO == L_
$include (L.inc)	; Select pinout L
ENDIF

IF ESCNO == M_
$include (M.inc)	; Select pinout M
ENDIF

IF ESCNO == N_
$include (N.inc)	; Select pinout N
ENDIF

IF ESCNO == O_
$include (O.inc)	; Select pinout O
ENDIF

IF ESCNO == P_
$include (P.inc)	; Select pinout P
ENDIF

IF ESCNO == Q_
$include (Q.inc)	; Select pinout Q
ENDIF

IF ESCNO == R_
$include (R.inc)	; Select pinout R
ENDIF

IF ESCNO == S_
$include (S.inc)        ; Select pinout S
ENDIF

IF ESCNO == T_
$include (T.inc)        ; Select pinout T
ENDIF

IF ESCNO == U_
$include (U.inc)        ; Select pinout U
ENDIF

IF ESCNO == V_
$include (V.inc)        ; Select pinout V
ENDIF

IF ESCNO == W_
$include (W.inc)        ; Select pinout W
ENDIF

;**** **** **** **** ****
; Programming defaults
;
DEFAULT_PGM_STARTUP_PWR 				EQU 9 	; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50
DEFAULT_PGM_COMM_TIMING				EQU 3 	; 1=Low 		2=MediumLow 	3=Medium 		4=MediumHigh 	5=High
DEFAULT_PGM_DEMAG_COMP 				EQU 2 	; 1=Disabled	2=Low		3=High
DEFAULT_PGM_DIRECTION				EQU 1 	; 1=Normal 	2=Reversed	3=Bidir		4=Bidir rev
DEFAULT_PGM_BEEP_STRENGTH			EQU 40	; Beep strength
DEFAULT_PGM_BEACON_STRENGTH			EQU 80	; Beacon strength
DEFAULT_PGM_BEACON_DELAY				EQU 4 	; 1=1m		2=2m			3=5m			4=10m		5=Infinite

; COMMON
DEFAULT_PGM_ENABLE_TX_PROGRAM 		EQU 1 	; 1=Enabled 	0=Disabled
DEFAULT_PGM_MIN_THROTTLE				EQU 37	; 4*37+1000=1148
DEFAULT_PGM_MAX_THROTTLE				EQU 208	; 4*208+1000=1832
DEFAULT_PGM_CENTER_THROTTLE			EQU 122	; 4*122+1000=1488 (used in bidirectional mode)
DEFAULT_PGM_ENABLE_TEMP_PROT	 		EQU 7 	; 0=Disabled	1=80C	2=90C	3=100C	4=110C	5=120C	6=130C	7=140C
DEFAULT_PGM_ENABLE_POWER_PROT 		EQU 1 	; 1=Enabled 	0=Disabled
DEFAULT_PGM_BRAKE_ON_STOP	 		EQU 0 	; 1=Enabled 	0=Disabled
DEFAULT_PGM_LED_CONTROL	 			EQU 0 	; Byte for LED control. 2bits per LED, 0=Off, 1=On

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
DSEG AT 20h									; Variables segment 
Bit_Access:					DS	1			; MUST BE AT THIS ADDRESS. Variable at bit accessible address (for non interrupt routines)
Bit_Access_Int:				DS	1			; Variable at bit accessible address (for interrupts)

Flags0:						DS	1    		; State flags. Reset upon init_start
T3_PENDING					EQU 	0		; Timer 3 pending flag
DEMAG_DETECTED				EQU 	1		; Set when excessive demag time is detected
COMP_TIMED_OUT				EQU 	2		; Set when comparator reading timed out
PWM_BOOST_SET				BIT 	Flags0.3
PWM_DS_BIT					BIT 	Flags0.4
;							EQU 	5	
;							EQU 	6	
;							EQU 	7	

Flags1:						DS	1    		; State flags. Reset upon init_start 
STARTUP_PHASE				EQU 	0		; Set when in startup phase
INITIAL_RUN_PHASE			EQU		1		; Set when in initial run phase, before synchronized run is achieved
MOTOR_STARTED				EQU 	2		; Set when motor is started
DIR_CHANGE_BRAKE			EQU 	3		; Set when braking before direction change
HIGH_RPM					EQU 	4		; Set when motor rpm is high (Comm_Period4x_H less than 2)
;							EQU 	6	
;							EQU 	7	

Flags2:						DS	1				; State flags. NOT reset upon init_start
RCP_UPDATED					EQU 	0			; New RC pulse length value available
RCP_ONESHOT125				EQU 	1			; RC pulse input is OneShot125 (125-250us)
RCP_ONESHOT42				EQU 	2			; RC pulse input is OneShot42 (41.67-83us)
RCP_MULTISHOT				EQU 	3			; RC pulse input is Multishot (5-25us)
RCP_DSHOT					EQU 	4			; RC pulse input is digital shot
RCP_DIR_REV					EQU 	5			; RC pulse direction in bidirectional mode
RCP_FULL_RANGE				EQU 	6			; When set full input signal range is used (1000-2000us) and stored calibration values are ignored
RCP_DSHOT_LEVEL				BIT 	Flags2.7
	

Flags3:						DS	1				; State flags. NOT reset upon init_start
PGM_DIR_REV					EQU 	0			; Programmed direction. 0=normal, 1=reversed
PGM_BIDIR_REV				EQU 	1			; Programmed bidirectional direction. 0=normal, 1=reversed
PGM_BIDIR					EQU 	2			; Programmed bidirectional operation. 0=normal, 1=bidirectional
DSHOT_TLM_EN				BIT 	Flags3.3	;
DSHOT_NEW					BIT 	Flags3.4
DSHOT_TLM_BUF_SEL			BIT 	Flags3.5
DSHOT_TLM_BUF_SEL_D			BIT 	Flags3.6	; buffer switch delayed

DShot_TempL:				DS	1				; dshot rpm telemetry data packet low
DShot_TempH:				DS	1				; dshot rpm telemetry data packet high
DShot_Csum:					DS	1
DShot_Temp1L:				DS	1				; dshot rpm telemetry data packet low
DShot_Temp1H:				DS	1				; dshot rpm telemetry data packet high
Comm_Period4x_L:			DS	1		; Timer 3 counts between the last 4 commutations (lo byte)
Comm_Period4x_H:			DS	1		; Timer 3 counts between the last 4 commutations (hi byte)

;**** **** **** **** ****
; RAM definitions
DSEG AT 30h								; Ram data segment, direct addressing
Rcp_Outside_Range_Cnt:		DS	1			; RC pulse outside range counter (incrementing) 
Rcp_Timeout_Cntd:			DS	1			; RC pulse timeout counter (decrementing) 

Initial_Arm:				DS	1		; Variable that is set during the first arm sequence after power on

;Min_Throttle_L:				DS	1		; Minimum throttle scaled (lo byte)
;Min_Throttle_H:				DS	1		; Minimum throttle scaled (hi byte)
;Center_Throttle_L:			DS	1		; Center throttle scaled (lo byte)
;Center_Throttle_H:			DS	1		; Center throttle scaled (hi byte)
;Max_Throttle_L:				DS	1		; Maximum throttle scaled (lo byte)
;Max_Throttle_H:				DS	1		; Maximum throttle scaled (hi byte)

Power_On_Wait_Cnt_L: 		DS	1		; Power on wait counter (lo byte)
Power_On_Wait_Cnt_H: 		DS	1		; Power on wait counter (hi byte)

Startup_Cnt:				DS	1		; Startup phase commutations counter (incrementing)
Startup_Zc_Timeout_Cntd:	DS	1		; Startup zero cross timeout counter (decrementing)
Initial_Run_Rot_Cntd:		DS	1		; Initial run rotations counter (decrementing)
Stall_Cnt:					DS	1		; Counts start/run attempts that resulted in stall. Reset upon a proper stop
Demag_Detected_Metric:		DS	1		; Metric used to gauge demag event frequency
Demag_Pwr_Off_Thresh:		DS	1		; Metric threshold above which power is cut
Low_Rpm_Pwr_Slope:			DS	1		; Sets the slope of power increase for low rpms

Timer0_X:					DS	1		; Timer 0 extended byte
Timer2_X:					DS	1		; Timer 2 extended byte
Prev_Comm_L:				DS	1		; Previous commutation timer 3 timestamp (lo byte)
Prev_Comm_H:				DS	1		; Previous commutation timer 3 timestamp (hi byte)
Prev_Comm_X:				DS	1		; Previous commutation timer 3 timestamp (ext byte)
Prev_Prev_Comm_L:			DS	1		; Pre-previous commutation timer 3 timestamp (lo byte)
Prev_Prev_Comm_H:			DS	1		; Pre-previous commutation timer 3 timestamp (hi byte)
Comparator_Read_Cnt: 		DS	1		; Number of comparator reads done

Wt_Adv_Start_L:				DS	1		; Timer 3 start point for commutation advance timing (lo byte)
Wt_Adv_Start_H:				DS	1		; Timer 3 start point for commutation advance timing (hi byte)
Wt_Zc_Scan_Start_L:			DS	1		; Timer 3 start point from commutation to zero cross scan (lo byte)
Wt_Zc_Scan_Start_H:			DS	1		; Timer 3 start point from commutation to zero cross scan (hi byte)
Wt_Zc_Tout_Start_L:			DS	1		; Timer 3 start point for zero cross scan timeout (lo byte)
Wt_Zc_Tout_Start_H:			DS	1		; Timer 3 start point for zero cross scan timeout (hi byte)
Wt_Comm_Start_L:			DS	1		; Timer 3 start point from zero cross to commutation (lo byte)
Wt_Comm_Start_H:			DS	1		; Timer 3 start point from zero cross to commutation (hi byte)

Dshot_Cmd:					DS	1		; Dshot command
Dshot_Cmd_Cnt:				DS  1		; Dshot command count

New_Rcp:					DS	1		; New RC pulse value in pca counts
Rcp_Stop_Cnt:				DS	1		; Counter for RC pulses below stop value

Power_Pwm_Reg_L:			DS	1		; Power pwm register setting (lo byte)
Power_Pwm_Reg_H:			DS	1		; Power pwm register setting (hi byte). 0x3F is minimum power
Damp_Pwm_Reg_L:				DS	1		; Damping pwm register setting (lo byte)
Damp_Pwm_Reg_H:				DS	1		; Damping pwm register setting (hi byte)
Power_Pwm_DS:				DS	1		; delta sigam throttle
Power_Pwm_DS_Error:			DS	1		; delta sigam throttle
Power_Pwm_Boost_L:			DS	1		; Power pwm register setting (lo byte)
Power_Pwm_Boost_H:			DS	1		; Power pwm register setting (hi byte). 0x3F is minimum power
Damp_Pwm_Boost_L:			DS	1		; Power pwm register setting (lo byte)
Damp_Pwm_Boost_H:			DS	1		; Power pwm register setting (hi byte). 0x3F is minimum power
Pwm_Boost_Count:			DS	1

Pwm_Limit:					DS	1		; Maximum allowed pwm 
Pwm_Limit_By_Rpm:			DS	1		; Maximum allowed pwm for low or high rpms
Pwm_Limit_Beg:				DS	1		; Initial pwm limit

Adc_Conversion_Cnt:			DS	1		; Adc conversion counter

Current_Average_Temp:		DS	1		; Current average temperature (lo byte ADC reading, assuming hi byte is 1)

;Throttle_Gain:				DS	1		; Gain to be applied to RCP value
;Throttle_Gain_M:			DS	1		; Gain to be applied to RCP value (multiplier 0=1x, 1=2x, 2=4x etc))
;Throttle_Gain_BD_Rev:		DS	1		; Gain to be applied to RCP value for reverse direction in bidirectional mode
;Throttle_Gain_BD_Rev_M:		DS	1		; Gain to be applied to RCP value for reverse direction in bidirectional mode (multiplier 0=1x, 1=2x, 2=4x etc)
Beep_Strength:				DS	1		; Strength of beeps

Skip_T2_Int:				DS	1		; Set for 48MHz MCUs when timer 2 interrupt shall be ignored
Clock_Set_At_48MHz:			DS	1		; Variable set if 48MHz MCUs run at 48MHz

Flash_Key_1:				DS	1		; Flash key one
Flash_Key_2:				DS	1		; Flash key two

Temp_Prot_Limit:			DS	1		; Temperature protection limit

DShot_Pwm_Thr:				DS	1		; DShot pulse width threshold value
DShot_Pwm_Thr_max:			DS	1		; DShot pulse width threshold value
DShot_Timer_Preset:			DS	1		; DShot timer preset for frame sync detection
DShot_Frame_Start_L:		DS	1		; DShot frame start timestamp (lo byte)
DShot_Frame_Start_H:		DS	1		; DShot frame start timestamp (hi byte)
DShot_Frame_Length_Thr1:	DS	1		; DShot frame length criteria (in units of 4 timer 2 ticks)
DShot_Frame_Length_Thr2:	DS	1		; DShot frame length criteria (in units of 4 timer 2 ticks)
DShot_Packet_L:				DS	1		; DShot frame length criteria (in units of 4 timer 2 ticks)
DShot_Packet_H:				DS	1		; DShot frame length criteria (in units of 4 timer 2 ticks)
DShot_Tlm_Buf_Base:			DS	1		; DShot frame length criteria (in units of 4 timer 2 ticks)

Dshot_Tlm_Bit_Time1:		DS	1
Dshot_Tlm_Bit_Time2:		DS	1
Dshot_Tlm_Bit_Time3:		DS	1
DShot_Temp1C:				DS	1
DShot_Temp1P:				DS	1
DShot_Tlm_Main_Count:		DS	1

DSHOT_PACKET_SIZE			EQU	16

DSHOT600_FRAME_LENGTH		EQU	(1000*49*DSHOT_PACKET_SIZE/12/600)		;; 											
DSHOT300_FRAME_LENGTH		EQU	(1000*49*DSHOT_PACKET_SIZE/12/300)		;; 											
DSHOT_CMD_REPEAT			EQU 6
						
; Indirect addressing data segment. The variables below must be in this sequence
ISEG AT 080h					
_Pgm_Gov_P_Gain:			DS	1		; Programmed governor P gain
_Pgm_Gov_I_Gain:			DS	1		; Programmed governor I gain
_Pgm_Gov_Mode:				DS	1		; Programmed governor mode
_Pgm_Low_Voltage_Lim:		DS	1		; Programmed low voltage limit
_Pgm_Motor_Gain:			DS	1		; Programmed motor gain
_Pgm_Motor_Idle:			DS	1		; Programmed motor idle speed
Pgm_Startup_Pwr:			DS	1		; Programmed startup power
_Pgm_Pwm_Freq:				DS	1		; Programmed pwm frequency
Pgm_Direction:				DS	1		; Programmed rotation direction
Pgm_Input_Pol:				DS	1		; Programmed input pwm polarity
Initialized_L_Dummy:		DS	1		; Place holder
Initialized_H_Dummy:		DS	1		; Place holder
Pgm_Enable_TX_Program:		DS 	1		; Programmed enable/disable value for TX programming
_Pgm_Main_Rearm_Start:		DS 	1		; Programmed enable/disable re-arming main every start 
_Pgm_Gov_Setup_Target:		DS 	1		; Programmed main governor setup target
_Pgm_Startup_Rpm:			DS	1		; Programmed startup rpm (unused - place holder)
_Pgm_Startup_Accel:			DS	1		; Programmed startup acceleration (unused - place holder)
_Pgm_Volt_Comp:			DS	1		; Place holder
Pgm_Comm_Timing:			DS	1		; Programmed commutation timing
_Pgm_Damping_Force:			DS	1		; Programmed damping force (unused - place holder)
_Pgm_Gov_Range:			DS	1		; Programmed governor range
_Pgm_Startup_Method:		DS	1		; Programmed startup method (unused - place holder)
Pgm_Min_Throttle:			DS	1		; Programmed throttle minimum
Pgm_Max_Throttle:			DS	1		; Programmed throttle maximum
Pgm_Beep_Strength:			DS	1		; Programmed beep strength
Pgm_Beacon_Strength:		DS	1		; Programmed beacon strength
Pgm_Beacon_Delay:			DS	1		; Programmed beacon delay
_Pgm_Throttle_Rate:			DS	1		; Programmed throttle rate (unused - place holder)
Pgm_Demag_Comp:			DS	1		; Programmed demag compensation
_Pgm_BEC_Voltage_High:		DS	1		; Programmed BEC voltage
Pgm_Center_Throttle:		DS	1		; Programmed throttle center (in bidirectional mode)
_Pgm_Main_Spoolup_Time:		DS	1		; Programmed main spoolup time
Pgm_Enable_Temp_Prot:		DS	1		; Programmed temperature protection enable
Pgm_Enable_Power_Prot:		DS	1		; Programmed low rpm power protection enable
_Pgm_Enable_Pwm_Input:		DS	1		; Programmed PWM input signal enable
_Pgm_Pwm_Dither:			DS	1		; Programmed output PWM dither
Pgm_Brake_On_Stop:			DS	1		; Programmed braking when throttle is zero
Pgm_LED_Control:			DS	1		; Programmed LED control

; The sequence of the variables below is no longer of importance
Pgm_Startup_Pwr_Decoded:	DS	1		; Programmed startup power decoded

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Indirect addressing data segment
ISEG AT 0B0h				
	Stack:					DS	32
	
ISEG AT 0D0h					
	Temp_Storage:			DS	24		; Temporary storage
	Temp_Storage1:			DS	24		; Temporary storage

	
;**** **** **** **** ****
CSEG AT 1A00h            ; "Eeprom" segment
EEPROM_FW_MAIN_REVISION		EQU	16		; Main revision of the firmware
EEPROM_FW_SUB_REVISION		EQU	80		; Sub revision of the firmware
EEPROM_LAYOUT_REVISION		EQU	33		; Revision of the EEPROM layout

Eep_FW_Main_Revision:		DB	EEPROM_FW_MAIN_REVISION			; EEPROM firmware main revision number
Eep_FW_Sub_Revision:		DB	EEPROM_FW_SUB_REVISION			; EEPROM firmware sub revision number
Eep_Layout_Revision:		DB	EEPROM_LAYOUT_REVISION			; EEPROM layout revision number

_Eep_Pgm_Gov_P_Gain:		DB	0FFh	
_Eep_Pgm_Gov_I_Gain:		DB	0FFh	
_Eep_Pgm_Gov_Mode:			DB	0FFh	
_Eep_Pgm_Low_Voltage_Lim:	DB	0FFh							
_Eep_Pgm_Motor_Gain:		DB	0FFh	
_Eep_Pgm_Motor_Idle:		DB	0FFh						
Eep_Pgm_Startup_Pwr:		DB	DEFAULT_PGM_STARTUP_PWR			; EEPROM copy of programmed startup power
_Eep_Pgm_Pwm_Freq:			DB	0FFh	
Eep_Pgm_Direction:			DB	DEFAULT_PGM_DIRECTION			; EEPROM copy of programmed rotation direction
_Eep_Pgm_Input_Pol:			DB	0FFh
Eep_Initialized_L:			DB	055h							; EEPROM initialized signature low byte
Eep_Initialized_H:			DB	0AAh							; EEPROM initialized signature high byte
Eep_Enable_TX_Program:		DB	DEFAULT_PGM_ENABLE_TX_PROGRAM		; EEPROM TX programming enable
_Eep_Main_Rearm_Start:		DB	0FFh							
_Eep_Pgm_Gov_Setup_Target:	DB	0FFh							
_Eep_Pgm_Startup_Rpm:		DB	0FFh
_Eep_Pgm_Startup_Accel:		DB	0FFh
_Eep_Pgm_Volt_Comp:			DB	0FFh	
Eep_Pgm_Comm_Timing:		DB	DEFAULT_PGM_COMM_TIMING			; EEPROM copy of programmed commutation timing
_Eep_Pgm_Damping_Force:		DB	0FFh
_Eep_Pgm_Gov_Range:			DB	0FFh	
_Eep_Pgm_Startup_Method:		DB	0FFh
Eep_Pgm_Min_Throttle:		DB	DEFAULT_PGM_MIN_THROTTLE			; EEPROM copy of programmed minimum throttle
Eep_Pgm_Max_Throttle:		DB	DEFAULT_PGM_MAX_THROTTLE			; EEPROM copy of programmed minimum throttle
Eep_Pgm_Beep_Strength:		DB	DEFAULT_PGM_BEEP_STRENGTH		; EEPROM copy of programmed beep strength
Eep_Pgm_Beacon_Strength:		DB	DEFAULT_PGM_BEACON_STRENGTH		; EEPROM copy of programmed beacon strength
Eep_Pgm_Beacon_Delay:		DB	DEFAULT_PGM_BEACON_DELAY			; EEPROM copy of programmed beacon delay
_Eep_Pgm_Throttle_Rate:		DB	0FFh
Eep_Pgm_Demag_Comp:			DB	DEFAULT_PGM_DEMAG_COMP			; EEPROM copy of programmed demag compensation
_Eep_Pgm_BEC_Voltage_High:	DB	0FFh	
Eep_Pgm_Center_Throttle:		DB	DEFAULT_PGM_CENTER_THROTTLE		; EEPROM copy of programmed center throttle
_Eep_Pgm_Main_Spoolup_Time:	DB	0FFh
Eep_Pgm_Temp_Prot_Enable:	DB	DEFAULT_PGM_ENABLE_TEMP_PROT		; EEPROM copy of programmed temperature protection enable
Eep_Pgm_Enable_Power_Prot:	DB	DEFAULT_PGM_ENABLE_POWER_PROT		; EEPROM copy of programmed low rpm power protection enable
_Eep_Pgm_Enable_Pwm_Input:	DB	0FFh	
_Eep_Pgm_Pwm_Dither:		DB	0FFh	
Eep_Pgm_Brake_On_Stop:		DB	DEFAULT_PGM_BRAKE_ON_STOP		; EEPROM copy of programmed braking when throttle is zero
Eep_Pgm_LED_Control:		DB	DEFAULT_PGM_LED_CONTROL			; EEPROM copy of programmed LED control

Eep_Dummy:				DB	0FFh							; EEPROM address for safety reason

CSEG AT 1A60h
Eep_Name:					DB	"                "				; Name tag (16 Bytes)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Interrupt_Table_Definition		; SiLabs interrupts

IF MCU_48MHZ == 0
CSEG AT 0Bh						; Timer0 overflow interrupt
	jmp		t0_int
ENDIF

;;;  MACRO declaration ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_Rcp_INPUT	MACRO
	mov		RTX_MDOUT, #P0_PUSHPULL
	setb	RTX_PORT.Rcp_In			;; set to open-drain 
ENDM
	
SET_Rcp_OUTPUT	MACRO		
	setb	RTX_PORT.Rcp_In			;; output high for default
	mov		RTX_MDOUT, #(1 SHL Rcp_In) OR P0_PUSHPULL
ENDM
	
Rcp_OUTPUT_LOW	MACRO
	clr		RTX_PORT.Rcp_In
ENDM
	
Rcp_OUTPUT_HIGH	MACRO
	setb	RTX_PORT.Rcp_In
ENDM

Read_Timer2 Macro byteL, byteH
	clr		TMR2CN0_TR2					; pause timer2
		mov		byteL, TMR2L	
		mov		byteH, TMR2H
	setb	TMR2CN0_TR2					; resume timer2
ENDM

DELAY_A		MACRO delay
	push	PSW
	push	ACC
		mov		A,#delay
		djnz	ACC,$
	pop		ACC
	pop		PSW
ENDM

MOVb MACRO bit1, bit2
	mov		C, bit2
	mov		bit1,C
ENDM

MOVt MACRO add
	clr	IE_EA					; DPTR used in interrupts
	  push	DPH
	  push	DPL	  
		mov	DPTR, add			; Read from flash
		movc	A, @A+DPTR
	  pop 	DPL
	  pop 	DPH
	setb	IE_EA
ENDM

MOVw MACRO  byteL, byteH, valL, valH
	mov		byteL, valL
	mov		byteH, valH
ENDM

IF_SET_CALL	MACRO bit, routine
LOCAL	L_0
	jnb		bit, L_0
	call	routine
L_0:	
ENDM

IF_CLR_CALL	MACRO bit, routine
LOCAL	L_0
	jb		bit, L_0
	call	routine
L_0:	
ENDM

IF_SET_JUMP MACRO bit, lab
LOCAL L0
	jnb		bit, L0
	jmp		lab
L0:
ENDM

IF_CLR_JUMP MACRO bit, lab
LOCAL L0
	jb		bit, L0
	jmp		lab
L0:
ENDM

IF_ZE_JUMP MACRO byte, lab
LOCAL L0
	mov		A, byte
	jnz		L0
	jmp		lab
L0:
ENDM

IF_ZE  MACRO byte, lab
	mov		A, byte
	jz		lab
ENDM

IF_NZ  MACRO byte, lab
	mov		A, byte
	jnz		lab
ENDM

IF_NZ_JUMP MACRO byte, lab
LOCAL L0
	mov		A, byte
	jz		L0
	jmp		lab
L0:
ENDM

IF_C_SET_JUMP MACRO lab
LOCAL L0
	jnc		L0
	jmp		lab
L0:
ENDM

IF_C_CLR_JUMP MACRO lab
LOCAL L0
	jc		L0
	jmp		lab
L0:
ENDM

IF_LT MACRO  byte1, byte2, lab
	clr		C
	mov		A, byte1
	subb	A, byte2
	jc		lab
ENDM

IF_GE MACRO  byte1, byte2, lab
	clr		C
	mov		A, byte1
	subb	A, byte2
	jnc		lab
ENDM

SWITCH_SET_CALL MACRO bit, routine, exit
LOCAL	L_0
	jnb		bit, L_0
	call	routine
	jmp		exit
L_0:
ENDM

SWITCH_CLR_CALL MACRO bit, routine, exit
LOCAL	L_0
	jb		bit, L_0
	call	routine
	jmp		exit
L_0:
ENDM

SWITCH_CALL MACRO bit, routine1,routine2,exit
LOCAL	L_0
	jb		bit, L_0
	call	routine1
	jmp		exit
L_0:
	call	routine2
ENDM

IF_EQ_CALL MACRO byte1, byte2 routine
LOCAL	L_0
	cjne	byte1, byte2, L_0
	call	routine
L_0:
ENDM

IF_NE_CALL MACRO byte1, byte2, routine
LOCAL	L_0
LOCAL	L_1
	cjne	byte1, byte2, L_0
	jmp		L_1
L_0:	
	call	routine
L_1:
ENDM

SET_VALUE MACRO bit, byte, val0, val1
LOCAL L_0
	mov		byte, val0
	jnb		bit, L_0
	mov		byte, val1
L_0:
ENDM

IF_1_SET MACRO bit, byte, val
LOCAL L_0
	jnb		bit, L_0
	mov		byte, val
L_0:
ENDM

IF_0_SET MACRO bit, byte, val
LOCAL L_0
	jb		bit, L_0
	mov		byte, val
L_0:
ENDM

Decrement_To_0 MACRO byte
LOCAL L0
	mov		A, byte
	jz		L0
	dec		byte
L0:
ENDM

Increment_To_FFh MACRO byte
LOCAL L0
	inc		byte
	mov		A, byte
	jnz		L0
	dec		byte
L0:
ENDM
	
PUSH_R0 MACRO	val
	mov		@R0, val
	inc		R0
ENDM

DSHOT_RLL_ADD_TIME MACRO
LOCAL L0
	mov		A, Dshot_Tlm_Bit_Time2
	cjne	A, B, L0	
	mov		A, Dshot_Tlm_Bit_Time3
L0:
ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CSEG AT 0a0h            ; Code segment after interrupt vectors 
;**** **** **** **** ****

; Table definitions
;;; test					 1	  2	   3	4	 5	  6	   7	8	 9	 10   11    12	  13
;;STARTUP_POWER_TABLE:	DB  04h, 06h, 08h, 0Ch, 10h, 18h, 20h, 30h, 40h, 60h, 80h, 0A0h, 0C0h
STARTUP_POWER_TABLE:	DB  10h, 18h, 20h, 28h, 30h, 38h, 40h, 50h, 60h, 80h, 0A0h, 0D0h, 0FFh
;;STARTUP_POWER_TABLE:	DB  10h, 20h, 30h, 40h, 50h, 60h, 70h, 80h, 98h, 0B0h, 0C8h, 0E0h, 0F8h


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; lsb in the bottom, msb in the top						;;;;;;;;;;;;;;;;;;
;;;;; R0: t0 interrupt time buffer index					;;;;;;;;;;;;;;;;;;
;;;;; input  A: jump index (already x2)						;;;;;;;;;;;;;;;;;;
;;;;; input  B: time remains previously						;;;;;;;;;;;;;;;;;;
;;;;; return B: time left to be added for next transition	;;;;;;;;;;;;;;;;;;
dshot_rll_encode:
	clr		IE_EA
		push	DPL
			mov		DPTR, #dshot_rll_encode_jump_table
			jmp		@A+DPTR
dshot_rll_encode_jump_table:
	ajmp	dshot_rll_encode_0_11001
	ajmp	dshot_rll_encode_1_11011
	ajmp	dshot_rll_encode_2_10010
	ajmp	dshot_rll_encode_3_10011
	ajmp	dshot_rll_encode_4_11101
	ajmp	dshot_rll_encode_5_10101
	ajmp	dshot_rll_encode_6_10110
	ajmp	dshot_rll_encode_7_10111
	ajmp	dshot_rll_encode_8_11010
	ajmp	dshot_rll_encode_9_01001
	ajmp	dshot_rll_encode_A_01010
	ajmp	dshot_rll_encode_B_01011
	ajmp	dshot_rll_encode_C_11110
	ajmp	dshot_rll_encode_D_01101
	ajmp	dshot_rll_encode_E_01110
	ajmp	dshot_rll_encode_F_01111
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dshot_rll_encode_0_11001:				;; 1= transision
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time3
	PUSH_R0		Dshot_Tlm_Bit_Time1
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_1_11011:			
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time2
	PUSH_R0		Dshot_Tlm_Bit_Time1
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_2_10010:	
		pop		DPL
	setb	IE_EA
	
	DSHOT_RLL_ADD_TIME
	PUSH_R0	A
	PUSH_R0		Dshot_Tlm_Bit_Time3
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_3_10011:
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time3
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_4_11101:
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time2
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time1
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_5_10101:
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time2
	PUSH_R0		Dshot_Tlm_Bit_Time2
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_6_10110:
		pop		DPL
	setb	IE_EA
	
	DSHOT_RLL_ADD_TIME
	PUSH_R0	A
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time2
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_7_10111:
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time2
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_8_11010:
		pop		DPL
	setb	IE_EA
	
	DSHOT_RLL_ADD_TIME
	PUSH_R0	A
	PUSH_R0		Dshot_Tlm_Bit_Time2
	PUSH_R0		Dshot_Tlm_Bit_Time1
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_9_01001:
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time3
	mov		B,	Dshot_Tlm_Bit_Time2
ret
dshot_rll_encode_A_01010:
		pop		DPL
	setb	IE_EA
	
	DSHOT_RLL_ADD_TIME
	PUSH_R0	A
	PUSH_R0		Dshot_Tlm_Bit_Time2
	mov		B,	Dshot_Tlm_Bit_Time2
ret
dshot_rll_encode_B_01011:
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time2
	mov		B,	Dshot_Tlm_Bit_Time2
ret
dshot_rll_encode_C_11110:
		pop		DPL
	setb	IE_EA
	
	DSHOT_RLL_ADD_TIME
	PUSH_R0	A
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time1
	mov		B,	Dshot_Tlm_Bit_Time1
ret
dshot_rll_encode_D_01101:
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time2
	PUSH_R0		Dshot_Tlm_Bit_Time1
	mov		B,	Dshot_Tlm_Bit_Time2
ret
dshot_rll_encode_E_01110:
		pop		DPL
	setb	IE_EA
	
	DSHOT_RLL_ADD_TIME
	PUSH_R0	A
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time1	
	mov		B,	Dshot_Tlm_Bit_Time2
ret
dshot_rll_encode_F_01111:
		pop		DPL
	setb	IE_EA
	
	PUSH_R0		B
	PUSH_R0		Dshot_Tlm_Bit_Time1
	PUSH_R0		Dshot_Tlm_Bit_Time1	
	PUSH_R0		Dshot_Tlm_Bit_Time1
	mov		B,	Dshot_Tlm_Bit_Time2
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dshot_gcr_encode:
dshot_gcr_7:
	mov		A, DShot_Temp1H
	mov		C, DShot_Temp1L.7
	rlc		A
	mov		DShot_Temp1L, A	
	
	mov		DShot_Temp1H,#0fh
jmp	dshot_gcr_end
dshot_gcr_6:
	mov		A, DShot_Temp1H
	mov		C, DShot_Temp1L.7
	rlc		A
	mov		C, DShot_Temp1L.6
	rlc		A
	mov		DShot_Temp1L, A	
	
	mov		DShot_Temp1H,#0dh	
jmp	dshot_gcr_end	
dshot_gcr_5:
	mov		A, DShot_Temp1H
	mov		C, DShot_Temp1L.7
	rlc		A
	mov		C, DShot_Temp1L.6
	rlc		A
	mov		C, DShot_Temp1L.5
	rlc		A
	mov		DShot_Temp1L, A
	
	mov		DShot_Temp1H,#0bh
jmp	dshot_gcr_end	
dshot_gcr_4:
	mov		A, DShot_Temp1L
	anl		A,#0f0h
	clr		DShot_Temp1H.4
	orl		A, DShot_Temp1H
	swap	A
	mov		DShot_Temp1L, A
	
	mov		DShot_Temp1H,#09h
jmp	dshot_gcr_end	
dshot_gcr_3:
	mov		A, DShot_Temp1L
	mov		C, DShot_Temp1H.0
	rrc		A
	mov		C, DShot_Temp1H.1
	rrc		A
	mov		C, DShot_Temp1H.2
	rrc		A
	mov		DShot_Temp1L, A
	
	mov		DShot_Temp1H,#07h	
jmp	dshot_gcr_end	
dshot_gcr_2:
	mov		A, DShot_Temp1L
	mov		C, DShot_Temp1H.0
	rrc		A
	mov		C, DShot_Temp1H.1
	rrc		A
	mov		DShot_Temp1L, A
	
	mov		DShot_Temp1H,#05h			
jmp	dshot_gcr_end	
dshot_gcr_1:
	mov		A, DShot_Temp1L
	mov		C, DShot_Temp1H.0	
	rrc		A
	mov		DShot_Temp1L, A
	
	mov		DShot_Temp1H,#03h
jmp	dshot_gcr_end		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dshot_make_packet_tlm_encode:	
;;; 16bit to 12bit gcr encode		;;;;;;;;;;;;;;	
	jb		DShot_Temp1H.7, dshot_gcr_7
	jb		DShot_Temp1H.6, dshot_gcr_6
	jb		DShot_Temp1H.5, dshot_gcr_5
	jb		DShot_Temp1H.4, dshot_gcr_4
	jb		DShot_Temp1H.3, dshot_gcr_3
	jb		DShot_Temp1H.2, dshot_gcr_2
	jb		DShot_Temp1H.1, dshot_gcr_1
	mov		A, DShot_Temp1L
dshot_gcr_end:
	;;; checksum
	swap	A
	xrl		A, DShot_Temp1L
	xrl		A, DShot_Temp1H
	cpl		A								;; A= checksum
	mov		DShot_Temp1C, A
ret	
	
dshot_make_packet_tlm4:
;;;	16bit to 20bit RLL encode, push transition time to buffer for timer0
	clr		DSHOT_TLM_BUF_SEL_D
	SET_VALUE	DSHOT_TLM_BUF_SEL, R0, #Temp_Storage1+1, #Temp_Storage+1 
	
	mov		B, Dshot_Tlm_Bit_Time1			;; final one bit time 
	mov		A, DShot_Temp1C
	rl		A
	anl		A, #1eh							;; A*=2 for rll encode jump table
	call	dshot_rll_encode
	
	mov		DShot_Temp1C, B
	mov		DShot_Temp1P, R0
ret

dshot_make_packet_tlm3:
	mov		B, DShot_Temp1C
	mov		R0, DShot_Temp1P
	
	mov		A, DShot_Temp1L
	rl		A
	anl		A, #1eh
	call	dshot_rll_encode
	
	mov		DShot_Temp1C, B
	mov		DShot_Temp1P, R0
ret	

dshot_make_packet_tlm2:
	mov		B, DShot_Temp1C
	mov		R0, DShot_Temp1P
	
	mov		A, DShot_Temp1L
	swap	A
	rl		A
	anl		A, #1eh
	call	dshot_rll_encode
	
	mov		DShot_Temp1C, B
	mov		DShot_Temp1P, R0
ret	

dshot_make_packet_tlm1:	
	mov		B, DShot_Temp1C
	mov		R0, DShot_Temp1P
	
	mov		A, DShot_Temp1H
	rl		A
	anl		A, #1eh
	call	dshot_rll_encode	
    
	PUSH_R0	B
	
	mov		A, R0
	SET_VALUE	DSHOT_TLM_BUF_SEL, R0, #Temp_Storage1, #Temp_Storage 
	mov		@R0, A
	
	clr		IE_EA
		jb		DSHOT_TLM_EN, dshot_make_packet_0
		cpl		DSHOT_TLM_BUF_SEL
	setb	IE_EA
ret		
		
		dshot_make_packet_0:
		setb	DSHOT_TLM_BUF_SEL_D	
	setb	IE_EA
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dshot_make_packet_tlm5:
	mov		A, Comm_Period4x_H					;; if dshot_tlm_time=0000h, then reset to ffffh
	cjne	A, #0f0h, t1_int_dshot_tlm_time_1	;; if dshot_tlm_time=f000h, then reset to ffffh
	mov		A, Comm_Period4x_L
	jnz		t1_int_dshot_tlm_time_1
	
	mov		DShot_Temp1L, #0ffh
	mov		DShot_Temp1H, #0ffh
	call	dshot_make_packet_tlm_encode		;; prepare ptr and buffer
ret
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  t1_int_dshot_tlm_time_1:
	mov		A, Comm_Period4x_L					;; H:L *= 3/4 (1/2 + 1/4)
	mov		C, Comm_Period4x_H.0
	rrc		A
	mov		DShot_Temp1L, A
	mov		C, Comm_Period4x_H.1
	rrc		A
	add		A, DShot_Temp1L
	mov		DShot_Temp1L, A
	
	mov		A, Comm_Period4x_H
	rr		A
	clr		ACC.7
	mov		DShot_Temp1H, A
	rr		A
	clr		ACC.7	
	addc	A, DShot_Temp1H	
	mov		DShot_Temp1H, A
	
	call	dshot_make_packet_tlm_encode				;; prepare ptr and buffer
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IF	DEBUG == 1	
test_bit_1:
	Rcp_OUTPUT_LOW
	DELAY_A	15
	Rcp_OUTPUT_HIGH
	DELAY_A	5
	ret
test_bit_0:
	Rcp_OUTPUT_LOW
	DELAY_A	5
	Rcp_OUTPUT_HIGH
	DELAY_A	15
	ret
test_pulse:
	push	PSW
	push	ACC
	push	B

	clr		IE_EX0
	clr		TCON_TR0
	
	Set_Rcp_OUTPUT
	DELAY_A	2
	
	mov 	B,#8
test_pulse_0:
	SWITCH_SET_CALL	ACC.7, test_bit_1, test_pulse_next
	call	test_bit_0
	
test_pulse_next:	
	rl		A
	djnz	B, test_pulse_0
	
	Set_Rcp_INPUT
	DELAY_A	5
	
	setb	TCON_TR0
	mov		TL0, #0
	mov		TH0, #0
	
	clr		TCON_IE0
	setb	IE_EX0

	pop		B
	pop		ACC
	pop		PSW
ret
ENDIF
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 0 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
t0_int:
	jb		DSHOT_TLM_EN, t0_dshot_tlm
reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
t0_dshot_tlm:
  push	PSW
  push	ACC
	mov	 PSW, #11h				;; using bank 3

to_dshot_tlm_start:
	dec		R0
	mov		A, R0
	cjne	A, DShot_Tlm_Buf_Base, to_dshot_tlm_exit
to_dshot_tlm_finish:			;; if last bit stays at low, then exit t0 again, wait one bit time for tx return to high
	jb		RTX_PORT.Rcp_In, to_dshot_tlm_end
	Rcp_OUTPUT_HIGH
	
	mov		TL0, Dshot_Tlm_Bit_Time1
	inc		R0					
  pop ACC
  pop PSW
reti		

to_dshot_tlm_end:	
		SET_Rcp_INPUT					
		
		clr		DSHOT_TLM_EN	
		mov		CKCON0, #0Ch
		mov		TMOD, #0AAh				;; timer0/1 gated by INT0/1
		clr		IE_ET0
		clr		TCON_IE0
		clr		TCON_IE1

		mov		TL0, #0
		mov		TH0, #0
		mov		DPL, #0		 			; Set pointer to start
		setb	IE_EX0					; Enable int0 interrupts
		setb	IE_EX1					; Enable int1 interrupts
  pop	ACC
  pop	PSW
reti

to_dshot_tlm_exit:
	cpl		RTX_PORT.Rcp_In
	mov		TL0, @R0
  pop	ACC
  pop	PSW
reti
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 2 interrupt routine
;
; No assumptions
; Requirements: Temp variables can NOT be used since PSW.x is not set
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t2_int:	; Happens every 32ms
  push	PSW			; Preserve registers through interrupt
  push	ACC
	clr	TMR2CN0_TF2H				; Clear interrupt flag
	inc	Timer2_X
	
IF MCU_48MHZ == 1
	mov	A, Clock_Set_At_48MHz
	jz 	t2_int_start

	; Check skip variable
	mov	A, Skip_T2_Int
	jz	t2_int_start				; Execute this interrupt

	mov	Skip_T2_Int, #0
	jmp	t2_int_exit

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	t2_int_start:
	mov	Skip_T2_Int, #1			; Skip next interrupt
ENDIF

	; Update RC pulse timeout counter 
	Decrement_To_0  Rcp_Timeout_Cntd

	; Check RC pulse against stop value
	clr	C
	mov	A, New_Rcp				; Load new pulse value
	jz	t2_int_rcp_stop			; Check if pulse is below stop value

	; RC pulse higher than stop value, reset stop counter
	mov	Rcp_Stop_Cnt, #0			; Reset rcp stop counter
	jmp	t2_int_exit

t2_int_rcp_stop:
	Increment_To_FFh  Rcp_Stop_Cnt

t2_int_exit:
  pop	ACC			; Restore preserved registers
  pop	PSW
reti
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 3 interrupt routine
;
; No assumptions
; Requirements: Temp variables can NOT be used since PSW.x is not set
;               ACC can not be used, as it is not pushed to stack
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t3_int:	; Used for commutation timing
	clr 	IE_EA			; Disable all interrupts
	anl	EIE1, #7Fh		; Disable timer 3 interrupts
	mov	TMR3RLL, #0FAh		; Set a short delay before next interrupt
	mov	TMR3RLH, #0FFh
	clr	Flags0.T3_PENDING 	; Flag that timer has wrapped
	anl	TMR3CN0, #07Fh		; Timer 3 interrupt flag cleared
	setb	IE_EA			; Enable all interrupts
reti
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 1 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; add from 16.72 to fix int0 wrapped issue
Decode_Dshot_Bit MACRO bit
LOCAL L0
	movx	A, @DPTR
	push	ACC
		clr	C
		subb	A, B					;; Subtract previous timestamp
	pop		B
	;add		A, R0						;; add previous compensation value
	clr		C
	subb	A, DShot_Pwm_Thr			; Check if bit is zero or one
	;mov		R0, #0
	jc		L0
	setb	bit
	;subb	A, DShot_Pwm_Thr_max
	;jc		L0
	;mov		R0, A					;; remark this line, no timing compensation
  L0:
	inc	DPL								
ENDM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
t1_int_dshot_decode:
	mov		DPL, #0							; Set pointer
	mov		DShot_TempL, #0
	mov		DShot_TempH, #0
	mov		DShot_Csum,#0
	mov		R0, #0							;; previous pulse width remained
	mov		B, #0							;; previous timestamp

	Decode_Dshot_Bit DShot_TempH.3
	Decode_Dshot_Bit DShot_TempH.2
	Decode_Dshot_Bit DShot_TempH.1
	Decode_Dshot_Bit DShot_TempH.0
	
	Decode_Dshot_Bit DShot_TempL.7
	Decode_Dshot_Bit DShot_TempL.6	
	Decode_Dshot_Bit DShot_TempL.5
	Decode_Dshot_Bit DShot_TempL.4
	Decode_Dshot_Bit DShot_TempL.3
	Decode_Dshot_Bit DShot_TempL.2
	Decode_Dshot_Bit DShot_TempL.1
	Decode_Dshot_Bit DShot_TempL.0
	
	Decode_Dshot_Bit DShot_Csum.3
	Decode_Dshot_Bit DShot_Csum.2	
	Decode_Dshot_Bit DShot_Csum.1
	Decode_Dshot_Bit DShot_Csum.0

	mov		A, DShot_TempL				;; 4bit xor checksum
	swap	A
	xrl		A, DShot_TempL
	xrl		A, DShot_TempH
	
	jnb		RCP_DSHOT_LEVEL, t1_int_xor_not_inverted
		cpl		A
	t1_int_xor_not_inverted:
	
	xrl		A, DShot_Csum
	anl		A, #0Fh	
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
t1_int_outside_range:
	mov		DPTR, #0		 	; Set pointer to start
	setb	IE_EX0			; Enable int0 interrupts
	setb	IE_EX1			; Enable int1 interrupts

	Increment_To_FFh  Rcp_Outside_Range_Cnt

	IF_LT  Rcp_Outside_Range_Cnt, #50, t1_int_set_timeout

	mov		New_Rcp, #0						; Set pulse length to zero
	pop		B								; Restore preserved registers
	pop		ACC
	pop		PSW
reti	

  t1_int_set_timeout:
	mov		Rcp_Timeout_Cntd, #10			; Set timeout count
	pop		B								; Restore preserved registers
	pop		ACC
	pop		PSW
reti	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
t1_int:
	clr 	IE_EA
		clr	IE_EX0				; Disable int0 interrupts
		clr	TCON_TR1			; Stop timer 1
		push	PSW
		push	ACC
		push	B				; Will be pop'ed by int0 exit
		mov	 PSW, #10h				;; using bank 2
		clr	TMR2CN0_TR2			; Timer 2 disabled
			mov	Temp1, TMR2L	; Read timer value
			mov	Temp2, TMR2H
		setb	TMR2CN0_TR2		; Timer 2 enabled
	setb	IE_EA
	; Reset timer 0
	mov	TL0, #0
	; Check frame time length
	clr	C
	mov	A, Temp1
	subb	A, DShot_Frame_Start_L
	mov	Temp1, A
	mov	A, Temp2
	subb	A, DShot_Frame_Start_H
	mov	Temp2, A
	
	mov		A, Temp2
	jnz		t1_int_outside_range			; Frame too long
	mov		A, Temp1
	subb	A, DShot_Frame_Length_Thr1
	jc		t1_int_outside_range			; Frame too short
	subb	A, DShot_Frame_Length_Thr2
	jnc		t1_int_outside_range			; Frame too long
	
	; Check that correct number of pulses is received
	mov		A, DPL							; Read current pointer
	cjne	A, #16, t1_int_outside_range
	
	;; Decode transmitted data
	call	t1_int_dshot_decode	
	jnz		t1_int_outside_range			;; XOR check: A!=0, fail
	
	MOVw	DShot_Packet_L,DShot_Packet_H, DShot_TempL,DShot_TempH
	setb	DSHOT_NEW
	
	jb		RCP_DSHOT_LEVEL, t1_int_do_dshot_tlm 
	;;; no dshot telemetry, initial to receive next dshot packet
	mov		DPTR, #0		 		; Set pointer to start
	setb	IE_EX0					; Enable int0 interrupts
	setb	IE_EX1					; Enable int1 interrupts
	
	pop	B							; Restore preserved registers
	pop	ACC
	pop	PSW
reti

t1_int_do_dshot_tlm:	
	jnb		DSHOT_TLM_BUF_SEL_D, t1_int_do_dshot_tlm_0
		cpl		DSHOT_TLM_BUF_SEL
		clr		DSHOT_TLM_BUF_SEL_D		
	t1_int_do_dshot_tlm_0: 
	 
	SET_VALUE	DSHOT_TLM_BUF_SEL, DShot_Tlm_Buf_Base, #Temp_Storage, #Temp_Storage1 
	SET_VALUE	DSHOT_TLM_BUF_SEL, R0, #Temp_Storage, #Temp_Storage1 
	mov		A, @R0
	
	clr		TCON_TF0
	mov		TL0, #DSHOT_TLM_DELAY			;; dshot tlm will be done in t0 with a delay time
	mov		CKCON0, #09h					;; time0 use sysck/12
	mov		TMOD,	#0A2h					;; timer0 free runs not gated by INT0
	
	setb	DSHOT_TLM_EN
	setb	IE_ET0
	SET_Rcp_OUTPUT
	
	mov		PSW, #11h				;; using bank 3
	mov		R0, A

	pop	B							; Restore preserved registers
	pop	ACC
	pop	PSW
reti
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_BOOST		equ 63 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DS_startup_boost:
	inc		A
	movc	A, @A+PC
	ret							;; stall_cnt
	DB	0						;;	0 
	DB	START_BOOST*2			;;	1
	DB	START_BOOST*3			;;	2
	DB	START_BOOST*4			;;	3
	DB	START_BOOST*4			;;	4
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dshot_command_process:
	;push	PSW
	;push	ACC
	;push	B				
	;mov	 	PSW, #01h			;; using bank 1

	clr		DSHOT_NEW
	clr		IE_EA
		; Subtract 96 (still 12 bits)
		mov		Temp2, DShot_Packet_L
		mov		A, DShot_Packet_L
		clr	C
		subb	A, #96
		mov		Temp3, A
		mov		A, DShot_Packet_H
	setb	IE_EA
	
	subb	A, #0
	mov		Temp4, A
	jnc 	t1_normal_range

	mov		Temp4, #0
	mov		Temp3, #0
	mov		A, Temp2  				; Check for 0 or dshot command
	jz		t1_normal_range
	
	clr		C						; We are in the special dshot range
	rrc		A 						; Divide by 2		
	jnc 	t1_normal_range			; Check for tlm bit set (if not telemetry, skip command)		
		
	cjne	A, Dshot_Cmd, t1_dshot_set_cmd
	inc 	Dshot_Cmd_Cnt	
	jmp 	t1_normal_range

	t1_dshot_set_cmd:
	mov		Dshot_Cmd, A
	mov		Dshot_Cmd_Cnt, #0

t1_normal_range:	
	; Check for bidirectional operation (0=stop, 96-2095->fwd, 2096-4095->rev)
	jnb	Flags3.PGM_BIDIR, t1_int_not_bidir			; If not bidirectional operation - branch

	; Subtract 2000 (still 12 bits)
	clr	C
	mov	A, Temp3
	subb	A, #0D0h
	mov	Temp1, A
	mov	A, Temp4
	subb	A, #07h
	mov	Temp2, A
	jc	t1_int_bidir_fwd							; If result is negative - branch

	mov	A, Temp1
	mov	Temp3, A
	mov	A, Temp2
	mov	Temp4, A
	jb	Flags2.RCP_DIR_REV, t1_int_bidir_rev_chk	; If same direction - branch

	setb	Flags2.RCP_DIR_REV
	ajmp	t1_int_bidir_rev_chk

t1_int_bidir_fwd:
	jnb	Flags2.RCP_DIR_REV, t1_int_bidir_rev_chk	; If same direction - branch

	clr	Flags2.RCP_DIR_REV

t1_int_bidir_rev_chk:
	jb	Flags3.PGM_BIDIR_REV, ($+5)

	cpl	Flags2.RCP_DIR_REV

	clr	C							; Multiply throttle value by 2
	mov	A, Temp3
	rlc	A
	mov	Temp3, A
	mov	A, Temp4
	rlc	A
	mov	Temp4, A
t1_int_not_bidir:
	; Generate 4/256
	mov	A, Temp4
	add	A, Temp4
	addc	A, Temp4
	addc	A, Temp4
	mov	Temp2, A
	; Align to 11 bits
	clr	C
	mov	A, Temp4
	rrc	A
	mov	Temp4, A
	mov	A, Temp3
	rrc	A
	mov	Temp3, A
	; Scale from 2000 to 2048
	mov	A, Temp3
	add	A, Temp2	; Holds 4/128
	mov	Temp3, A
	mov	A, Temp4
	addc	A, #0
	mov	Temp4, A
	jnb	ACC.3, ($+7)

	mov	Temp3, #0FFh
	mov	Temp4, #0FFh

	; Boost pwm during direct start
	mov	A, Flags1
	anl	A, #((1 SHL STARTUP_PHASE)+(1 SHL INITIAL_RUN_PHASE))
	jz	t1_int_startup_boosted

	jb	Flags1.MOTOR_STARTED, t1_int_startup_boosted	; Do not boost when changing direction in bidirectional mode

	mov	A, Pwm_Limit_Beg								; Set 25% of max startup power as minimum power
	rlc	A
	mov	Temp2, A
	mov	A, Temp4
	jnz	t1_int_startup_boost_stall

	clr	C
	mov	A, Temp2
	subb	A, Temp3
	jc	t1_int_startup_boost_stall

	mov	A, Temp2
	mov	Temp3, A

t1_int_startup_boost_stall:
	mov		A, Stall_Cnt							; Add an extra power boost during start
	anl		A, #03h
	call	DS_startup_boost											
	;swap	A
	;rlc	A
	
	add	A, Temp3
	mov	Temp3, A
	mov	A, Temp4
	addc	A, #0
	mov	Temp4, A

t1_int_startup_boosted:
	; Set 8bit value
	clr	C
	mov	A, Temp3
	rlc	A
	swap	A
	anl	A, #0Fh
	mov	Temp1, A
	mov	A, Temp4
	rlc	A
	swap	A
	anl	A, #0F0h
	orl	A, Temp1
	mov	Temp1, A
	jnz	t1_int_zero_rcp_checked	; New_Rcp (Temp1) is only zero if all 11 bits are zero

	mov	A, Temp3
	jz	t1_int_zero_rcp_checked

	mov	Temp1, #1

t1_int_zero_rcp_checked:
	Decrement_To_0  Rcp_Outside_Range_Cnt

;;;jmp	t1_int_pulse_ready	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
t1_int_pulse_ready:
	setb	Flags2.RCP_UPDATED		 				; Set updated flag
	mov		New_Rcp, Temp1							; Store new pulse length
	
	IF_ZE	New_Rcp, t1_int_check_new_pulse_value 
		mov	Rcp_Stop_Cnt, #0						; Rcp !=0 : Reset rcp stop counter
	t1_int_check_new_pulse_value:
	
	;; Set pwm limit
	mov	Temp5, Pwm_Limit							; Limit to the smallest
	IF_LT  Pwm_Limit, Pwm_Limit_By_Rpm, t1_int_check_limit 
		mov	Temp5, Pwm_Limit_By_Rpm					; Store limit in Temp5
	t1_int_check_limit:
	
	;; Check limit > New_Rcp, set pwm registers directly
	IF_GE  Temp5, New_Rcp, t1_int_set_pwm_registers

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; New_Rcp too high, limit to preset value
	;; Multiply limit: x8
	mov		A, Temp5							
	mov		B, #8
	mul		AB
	mov		Temp3, A
	mov		Temp4, B
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   t1_int_set_pwm_registers:
	mov		Power_Pwm_DS, Temp3
	anl		Power_Pwm_DS, #DS_MASK				;; ds 1b: 03h 2b:07h 3b:0fh

	IF		PWM_BITS == 10							;; shift to 10bit throttle/pwm duty
		mov		A, Temp4							;; invert then store to temp1/2
		rrc		A
		cpl		A
		anl		A, #03h
		mov		Temp2, A
		mov		A, Temp3
		rrc		A
		cpl		A
		mov		Temp1, A
	ELSEIF	PWM_BITS == 9	
		mov		A, Temp4							;; shift to 9bit throttle/pwm duty
		rrc		A
		rrc		A
		mov		PSW_F0, c
		mov		c, ACC.7
		cpl		A
		anl		A, #01h
		mov		Temp2, A
		mov		A, Temp3
		rrc		A
		mov		c, PSW_F0
		rrc		A
		cpl		A
		mov		Temp1, A
	ELSE	
		mov		B, Temp4							;; shift to 8bit throttle/pwm duty
		mov		Temp2, #0
		mov		A, Temp3
		mov		c, B.0
		rrc		A
		mov		c, B.1
		rrc		A
		mov		c, B.2
		rrc		A
		cpl		A
		mov		Temp1, A	
	ENDIF

	clr		C
	mov		A, Temp1
	subb	A, #_FETON_DELAY_						;; Skew damping fet timing
	mov		Temp3, A
	mov		A, Temp2
	subb	A, #0	
	mov		Temp4, A
	
	jnc		t1_int_set_pwm_damp_set
		MOVw	Temp3,Temp4, #0,#0					;; not enough non-overlap, set damping off
	t1_int_set_pwm_damp_set:
	
IF	PWM_BOOST_NUMBER != 1
	clr		C										; temp2/1-powerH/L
	mov		A, Temp1								; add delta to boost
	subb	A, Power_Pwm_Reg_L
	mov		B, A
	mov		A, Temp2
	subb	A, Power_Pwm_Reg_H
	mov		A, B
	
	IF	PWM_BOOST_DOUBLE == 1
		rl		A
	ENDIF
	
	jnc		t1_int_set_pwm_registers_0
	
	add		A, Temp1				;;; delta is negative
	mov		Power_Pwm_Boost_L, A
	mov		A, #(NOT PWM_BOOST_MASK)
	addc	A, Temp2
	mov		Power_Pwm_Boost_H, A	;; extra msb will be 1, still ok
	anl		A, #PWM_BOOST_MASK
	jnz		t1_int_set_pwm_registers_1				; if overflow, set boost to 00h
	MOVw	Power_Pwm_Boost_L,Power_Pwm_Boost_H, #0,#0
	jmp		t1_int_set_pwm_registers_1

   t1_int_set_pwm_registers_0:
	add		A, Temp1				;;; delta is positive
	mov		Power_Pwm_Boost_L, A
	mov		A, #0
	addc	A, Temp2
	mov		Power_Pwm_Boost_H, A
	anl		A, #PWM_BOOST_MASK
	jz		t1_int_set_pwm_registers_1				; if overflow, set boost to ffh
	MOVw	Power_Pwm_Boost_L,Power_Pwm_Boost_H, #0ffh,#(NOT PWM_BOOST_MASK)

  t1_int_set_pwm_registers_1:
	clr		C
	mov		A, Power_Pwm_Boost_L
	subb	A, #_FETON_DELAY_						;; Skew damping fet timing
	mov		Damp_Pwm_Boost_L, A
	mov		A, Power_Pwm_Boost_H
	subb	A, #0	
	mov		Damp_Pwm_Boost_H, A
	jnc		t1_int_set_pwm_registers_2
		MOVw	Damp_Pwm_Boost_L, Damp_Pwm_Boost_H, #0,#0		;; not enough non-overlap, set damping off
   t1_int_set_pwm_registers_2:
   
   	mov		A, Pwm_Boost_Count
	mov		Pwm_Boost_Count, #PWM_BOOST_NUMBER	
	jnz		t1_int_set_pwm_registers_3
	mov		Pwm_Boost_Count, #PWM_BOOST_NUMBER-1			;Pwm_Boost_Count: 1= no boost  2=boost one phase
  t1_int_set_pwm_registers_3:
ENDIF

	MOVw	Power_Pwm_Reg_L,Power_Pwm_Reg_H,	Temp1,Temp2
	MOVw	Damp_Pwm_Reg_L,Damp_Pwm_Reg_H,		Temp3,Temp4
	
	mov		Rcp_Timeout_Cntd, #10							;; Set timeout count	

	;pop	B							; Restore preserved registers
	;pop	ACC
	;pop	PSW	
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Int0 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
int0_int:	; Used for RC pulse timing
	;push PSW
	push ACC
		mov		A, TL0						; Read pwm for DShot immediately
		movx	@DPTR, A					; Store pwm
		inc		DPL
		mov		TL1, DShot_Timer_Preset		; Reset sync timer				
	pop	ACC
	;pop	PSW
reti
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Int1 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
int1_int:	; Used for RC pulse timing
	clr		IE_EX1							; Disable int1 interrupts
	mov		TL1, DShot_Timer_Preset			; Reset sync timer
	setb	TCON_TR1						; Start timer 1
	clr		TMR2CN0_TR2						; Timer 2 disabled
		mov		DShot_Frame_Start_L, TMR2L	; Read timer value
		mov		DShot_Frame_Start_H, TMR2H
	setb	TMR2CN0_TR2						; Timer 2 enabled
reti

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; PCA interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;;; PCA int removed from 16.74
pca_int:	
	anl	EIE1, #0EFh					; Disable pca interrupts
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
		
		mov		A, Temp1
		push	ACC
		mov		A, Temp2
		push	ACC
			IF_SET_CALL		DSHOT_NEW, dshot_command_process
		pop		ACC
		mov		Temp2, A
		pop		ACC
		mov		Temp1, A
		
	djnz	Temp1, waitxms_m
	djnz	Temp2, waitxms_o
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
	; Set pwm limit
	mov	Temp1, #0FFh					; Default full power
	jb	Flags1.STARTUP_PHASE, set_pwm_limit_low_rpm_exit	; Exit if startup phase set

	mov	Temp2, #Pgm_Enable_Power_Prot		; Check if low RPM power protection is enabled
	mov	A, @Temp2
	jz	set_pwm_limit_low_rpm_exit		; Exit if disabled

	mov	A, Comm_Period4x_H
	jz	set_pwm_limit_low_rpm_exit		; Avoid divide by zero

	mov	A, #255						; Divide 255 by Comm_Period4x_H
	mov	B, Comm_Period4x_H
	div	AB
	mov	B, Low_Rpm_Pwr_Slope			; Multiply by slope
	jnb	Flags1.INITIAL_RUN_PHASE, ($+6)	; More protection for initial run phase 
	mov	B, #5
	mul	AB
	mov	Temp1, A						; Set new limit				
	xch	A, B
	jz	($+4)						; Limit to max
	
	mov	Temp1, #0FFh				

	clr	C
	mov	A, Temp1						; Limit to min
	subb	A, Pwm_Limit_Beg
	jnc	set_pwm_limit_low_rpm_exit

	mov	Temp1, Pwm_Limit_Beg

set_pwm_limit_low_rpm_exit:
	mov	Pwm_Limit_By_Rpm, Temp1				
	ret
	
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Set pwm limit high rpm
;
; No assumptions
;
; Sets power limit for high rpms
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
set_pwm_limit_high_rpm:
IF MCU_48MHZ == 1
	set_pwm_limit_high_rpm_0:
	clr	C
	mov	A, Comm_Period4x_L
	subb	A, #0a0h	;;0A0h					; Limit Comm_Period to 160, which is 500k erpm
	mov	A, Comm_Period4x_H						; 350k= e4h  340k= ebh	330k= f2h	320k= fah
	subb	A, #00h								; 345k= e7h  335k= eeh	325k= f6h	315k= fdh
ELSE
	set_pwm_limit_high_rpm_1:
	clr	C
	mov	A, Comm_Period4x_L
	subb	A, #033h		;;0E4h				; Limit Comm_Period to 228, which is 350k erpm
	mov	A, Comm_Period4x_H						; 260k=  133h	270k= 128h  280k= 11dh	290k= 113h	300k= 10ah
	subb	A, #01h			;;00h				; 265k=  12dh	275k= 122h  285k= 118h	295k= 10fh	305k= 106h
ENDIF
	mov	A, Pwm_Limit_By_Rpm
	jnc	set_pwm_limit_high_rpm_inc_limit
	
	dec	A
	jmp		set_pwm_limit_high_rpm_store
	
set_pwm_limit_high_rpm_inc_limit:
	inc	A
set_pwm_limit_high_rpm_store:
	jz	($+4)

	mov	Pwm_Limit_By_Rpm, A
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
	inc	Adc_Conversion_Cnt			; Increment conversion counter
	clr	C
	mov	A, Adc_Conversion_Cnt		; Is conversion count equal to temp rate?
	subb	A, #8
	jc	check_voltage_start			; No - check voltage

	; Wait for ADC conversion to complete
	jnb	ADC0CN0_ADINT, check_temp_voltage_and_limit_power
	; Read ADC result
	Read_Adc_Result
	; Stop ADC
	Stop_Adc

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
	subb	A, Temp_Prot_Limit			; Is temperature below first limit?
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #192			; No - limit pwm

	clr	C
	subb	A, #(TEMP_LIMIT_STEP/2)		; Is temperature below second limit
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #128			; No - limit pwm

	clr	C
	subb	A, #(TEMP_LIMIT_STEP/2)		; Is temperature below third limit
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #64				; No - limit pwm

	clr	C
	subb	A, #(TEMP_LIMIT_STEP/2)		; Is temperature below final limit
	jc	temp_check_exit			; Yes - exit

	mov  Pwm_Limit, #0				; No - limit pwm

temp_check_exit:
	ret

check_voltage_start:
	; Increase pwm limit
	mov  A, Pwm_Limit
	add	A, #16			
	jnc	($+4)					; If not max - branch

	mov	A, #255

	mov	Pwm_Limit, A				; Increment limit 
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
	mov	A, #50						; Set power
	mov	Temp2, #Pgm_Startup_Pwr_Decoded
	mov	B, @Temp2
	mul	AB
	xch	A, B
	mov	C, B.7						; Multiply result by 2 (unity gain is 128)
	rlc	A
	mov	Pwm_Limit_Beg, A				; Set initial pwm limit
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
	mov		Comm_Period4x_L, #00h				; Set commutation period registers
	mov		Comm_Period4x_H, #0F0h

	call	dshot_make_packet_tlm	
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
calc_next_comm_timing:		; Entry point for run phase
	; Read commutation time
	clr	IE_EA
	clr	TMR2CN0_TR2		; Timer 2 disabled
	mov	Temp1, TMR2L		; Load timer value
	mov	Temp2, TMR2H	
	mov	Temp3, Timer2_X
	jnb	TMR2CN0_TF2H, ($+4)	; Check if interrupt is pending
	inc	Temp3			; If it is pending, then timer has already wrapped
	setb	TMR2CN0_TR2		; Timer 2 enabled
	setb	IE_EA
IF MCU_48MHZ == 1
	clr	C
	mov	A, Temp3
	rrc	A
	mov	Temp3, A
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
ENDIF
	; Calculate this commutation time
	mov	Temp4, Prev_Comm_L
	mov	Temp5, Prev_Comm_H
	mov	Prev_Comm_L, Temp1		; Store timestamp as previous commutation
	mov	Prev_Comm_H, Temp2
	clr	C
	mov	A, Temp1
	subb	A, Temp4				; Calculate the new commutation time
	mov	Temp1, A
	mov	A, Temp2
	subb	A, Temp5
	jb	Flags1.STARTUP_PHASE, calc_next_comm_startup

IF MCU_48MHZ == 1
	anl	A, #7Fh
ENDIF
	mov	Temp2, A
	
	IF_SET_JUMP  Flags1.HIGH_RPM, calc_next_comm_timing_fast	
	jmp		calc_next_comm_normal

calc_next_comm_startup:
	mov	Temp6, Prev_Comm_X
	mov	Prev_Comm_X, Temp3			; Store extended timestamp as previous commutation
	mov	Temp2, A
	mov	A, Temp3
	subb	A, Temp6				; Calculate the new extended commutation time
IF MCU_48MHZ == 1
	anl	A, #7Fh
ENDIF
	mov	Temp3, A
	jz	calc_next_comm_startup_no_X

	mov	Temp1, #0FFh
	mov	Temp2, #0FFh
	jmp	calc_next_comm_startup_average

calc_next_comm_startup_no_X:
	mov	Temp7, Prev_Prev_Comm_L
	mov	Temp8, Prev_Prev_Comm_H
	mov	Prev_Prev_Comm_L, Temp4
	mov	Prev_Prev_Comm_H, Temp5
	mov	Temp1, Prev_Comm_L		; Reload this commutation time	
	mov	Temp2, Prev_Comm_H
	clr	C
	mov	A, Temp1
	subb	A, Temp7				; Calculate the new commutation time based upon the two last commutations (to reduce sensitivity to offset)
	mov	Temp1, A
	mov	A, Temp2
	subb	A, Temp8
	mov	Temp2, A

calc_next_comm_startup_average:
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
	jnc	($+8)

	mov	Comm_Period4x_L, #0FFh
	mov	Comm_Period4x_H, #0FFh

	jmp	calc_new_wait_times_setup

calc_next_comm_normal:
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
	jc	calc_next_comm_avg_period_div

	dec	Temp7				; Reduce averaging time constant for low speeds
	dec	Temp8

	clr	C
	mov	A, Temp4
	subb	A, #08h
	jc	calc_next_comm_avg_period_div

	jb	Flags1.INITIAL_RUN_PHASE, calc_next_comm_avg_period_div	; Do not average very fast during initial run

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

	mov	Temp4, #0FFh
	mov	Comm_Period4x_L, Temp4	; Set commutation period registers to very slow timing (0xffff)
	mov	Comm_Period4x_H, Temp4

calc_new_wait_times_setup:	
	; Set high rpm bit (if above 156k erpm)
	clr	C
	mov	A, Temp4
	subb	A, #2
	jnc	($+4)

	setb	Flags1.HIGH_RPM 		; Set high rpm bit
	
	; Load programmed commutation timing
	jnb	Flags1.STARTUP_PHASE, calc_new_wait_per_startup_done	; Set dedicated timing during startup

	mov		Temp8, #3
	jmp		calc_new_wait_per_demag_done

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
	; Set timing reduction
	mov	Temp7, #2
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
	mov	Temp3, A
	mov	A, Temp2				
	subb	A, #0
	mov	Temp4, A
	jc	load_min_time			; Check that result is still positive

	clr	C
	mov	A, Temp3
	subb	A, #1
	mov	A, Temp4			
	subb	A, #0
	jc	load_min_time	; Check that result is still above minumum
ret

  load_min_time:
	mov	Temp3, #1
	clr	A
	mov	Temp4, A 
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Fast calculation (Comm_Period4x_H less than 2)
calc_next_comm_timing_fast:			
	; Calculate new commutation time
	mov	Temp3, Comm_Period4x_L	; Comm_Period4x(-l-h) holds the time of 4 commutations
	mov	Temp4, Comm_Period4x_H
	mov	A, Temp4				; Divide by 2 4 times
	swap	A
	mov	Temp7, A
	mov	A, Temp3
	swap A
	anl	A, #0Fh
	orl	A, Temp7
	mov	Temp5, A
	clr	C
	mov	A, Temp3				; Subtract a fraction
	subb	A, Temp5
	mov	Temp3, A
	mov	A, Temp4				
	subb	A, #0
	mov	Temp4, A
	clr	C
	mov	A, Temp1
	rrc	A					; Divide by 2 2 times
	clr	C
	rrc	A
	mov	Temp1, A
	mov	A, Temp3				; Add the divided new time
	add	A, Temp1
	mov	Temp3, A
	mov	A, Temp4
	addc	A, #0
	mov	Temp4, A
	mov	Comm_Period4x_L, Temp3	; Store Comm_Period4x_X
	mov	Comm_Period4x_H, Temp4
	clr	C
	mov	A, Temp4				; If erpm below 156k - go to normal case
	subb	A, #2
	jc	($+4)

	clr	Flags1.HIGH_RPM 		; Clear high rpm bit

	; Set timing reduction
	mov	Temp1, #2
	mov	A, Temp4				; Divide by 2 4 times
	swap	A
	mov	Temp7, A
	mov	Temp4, #0
	mov	A, Temp3
	swap A
	anl	A, #0Fh
	orl	A, Temp7
	mov	Temp3, A
	clr	C
	mov	A, Temp3
	subb	A, Temp1
	mov	Temp3, A
	jc	load_min_time_fast		; Check that result is still positive

	clr	C
	subb	A, #1
	jnc	calc_new_wait_times_fast_done	; Check that result is still above minumum

load_min_time_fast:
	mov	Temp3, #1

calc_new_wait_times_fast_done:	
	mov	Temp1, #Pgm_Comm_Timing	; Load timing setting
	mov	A, @Temp1				
	mov	Temp8, A				; Store in Temp8
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	wait_advance_timing_:
	jnb	Flags0.T3_PENDING, ($+5)
	ajmp	wait_advance_timing_

	; Setup next wait time
	mov	TMR3RLL, Wt_ZC_Tout_Start_L
	mov	TMR3RLH, Wt_ZC_Tout_Start_H
	setb	Flags0.T3_PENDING
	orl	EIE1, #80h	; Enable timer 3 interrupts	
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
	clr	C
	clr	A
	subb	A, Temp3			; Negate
	mov	Temp1, A	
	clr	A
	subb	A, Temp4				
	mov	Temp2, A	
IF MCU_48MHZ == 1
	clr	C
	mov	A, Temp1				; Multiply by 2
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A
ENDIF
	jb	Flags1.HIGH_RPM, calc_new_wait_times_fast	; Branch if high rpm

	mov	A, Temp1				; Copy values
	mov	Temp3, A
	mov	A, Temp2
	mov	Temp4, A
	setb	C					; Negative numbers - set carry
	mov	A, Temp2				
	rrc	A					; Divide by 2
	mov	Temp6, A
	mov	A, Temp1
	rrc	A
	mov	Temp5, A
	mov	Wt_Zc_Tout_Start_L, Temp1; Set 15deg time for zero cross scan timeout
	mov	Wt_Zc_Tout_Start_H, Temp2
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
	add	A, #1
	mov	Temp1, A
	mov	A, Temp2
	addc	A, #0
	mov	Temp2, A
	mov	Temp3, #-1				; Store minimum time in Temp3/4
	mov	Temp4, #0FFh

store_times_up_or_down:
	clr	C
	mov	A, Temp8				
	subb	A, #3					; Is timing higher than normal?
	jc	store_times_decrease		; No - branch

store_times_increase:
	mov	Wt_Comm_Start_L, Temp3		; Now commutation time (~60deg) divided by 4 (~15deg nominal)
	mov	Wt_Comm_Start_H, Temp4
	mov	Wt_Adv_Start_L, Temp1		; New commutation advance time (~15deg nominal)
	mov	Wt_Adv_Start_H, Temp2
	mov	Wt_Zc_Scan_Start_L, Temp5	; Use this value for zero cross scan delay (7.5deg)
	mov	Wt_Zc_Scan_Start_H, Temp6
	jmp	wait_before_zc_scan

store_times_decrease:
	mov	Wt_Comm_Start_L, Temp1		; Now commutation time (~60deg) divided by 4 (~15deg nominal)
	mov	Wt_Comm_Start_H, Temp2
	mov	Wt_Adv_Start_L, Temp3		; New commutation advance time (~15deg nominal)
	mov	Wt_Adv_Start_H, Temp4
	mov	Wt_Zc_Scan_Start_L, Temp5	; Use this value for zero cross scan delay (7.5deg)
	mov	Wt_Zc_Scan_Start_H, Temp6
	jnb	Flags1.STARTUP_PHASE, store_times_exit

	mov	Wt_Comm_Start_L, #0F0h		; Set very short delays for all but advance time during startup, in order to widen zero cross capture range
	mov	Wt_Comm_Start_H, #0FFh
	mov	Wt_Zc_Scan_Start_L, #0F0h
	mov	Wt_Zc_Scan_Start_H, #0FFh
	mov	Wt_Zc_Tout_Start_L, #0F0h
	mov	Wt_Zc_Tout_Start_H, #0FFh

store_times_exit:
	jmp	wait_before_zc_scan

calc_new_wait_times_fast:	
	mov	A, Temp1				; Copy values
	mov	Temp3, A
	setb	C					; Negative numbers - set carry
	mov	A, Temp1				; Divide by 2
	rrc	A
	mov	Temp5, A
	mov	Wt_Zc_Tout_Start_L, Temp1; Set 15deg time for zero cross scan timeout
	clr	C
	mov	A, Temp8				; (Temp8 has Pgm_Comm_Timing)
	subb	A, #3				; Is timing normal?
	jz	store_times_decrease_fast; Yes - branch

	mov	A, Temp8				
	jb	ACC.0, adjust_timing_two_steps_fast	; If an odd number - branch

	mov	A, Temp1				; Add 7.5deg and store in Temp1
	add	A, Temp5
	mov	Temp1, A
	mov	A, Temp5				; Store 7.5deg in Temp3
	mov	Temp3, A
	ajmp	store_times_up_or_down_fast

adjust_timing_two_steps_fast:
	mov	A, Temp1				; Add 15deg and store in Temp1
	add	A, Temp1
	add	A, #1
	mov	Temp1, A
	mov	Temp3, #-1			; Store minimum time in Temp3

store_times_up_or_down_fast:
	clr	C
	mov	A, Temp8				
	subb	A, #3				; Is timing higher than normal?
	jc	store_times_decrease_fast; No - branch

store_times_increase_fast:
	mov	Wt_Comm_Start_L, Temp3		; Now commutation time (~60deg) divided by 4 (~15deg nominal)
	mov	Wt_Adv_Start_L, Temp1		; New commutation advance time (~15deg nominal)
	mov	Wt_Zc_Scan_Start_L, Temp5	; Use this value for zero cross scan delay (7.5deg)
	jmp	wait_before_zc_scan

store_times_decrease_fast:
	mov	Wt_Comm_Start_L, Temp1		; Now commutation time (~60deg) divided by 4 (~15deg nominal)
	mov	Wt_Adv_Start_L, Temp3		; New commutation advance time (~15deg nominal)
	mov	Wt_Zc_Scan_Start_L, Temp5	; Use this value for zero cross scan delay (7.5deg)

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
	wait_before_zc_scan_:
		jnb	Flags0.T3_PENDING, ($+5)
	ajmp	wait_before_zc_scan_

	mov	Startup_Zc_Timeout_Cntd, #2
setup_zc_scan_timeout:
	setb	Flags0.T3_PENDING
	orl	EIE1, #80h			; Enable timer 3 interrupts
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
IF MCU_48MHZ == 0
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
ENDIF
	jnb	Flags1.STARTUP_PHASE, setup_zc_scan_timeout_startup_done

	mov	A, Temp2
	add	A, #40h				; Increase timeout somewhat to avoid false wind up
	mov	Temp2, A

setup_zc_scan_timeout_startup_done:
	clr	IE_EA
	anl	EIE1, #7Fh			; Disable timer 3 interrupts
	mov	TMR3CN0, #00h			; Timer 3 disabled and interrupt flag cleared
	clr	C
	clr	A
	subb	A, Temp1				; Set timeout
	mov	TMR3L, A
	clr	A
	subb	A, Temp2		
	mov	TMR3H, A
	mov	TMR3CN0, #04h			; Timer 3 enabled and interrupt flag cleared
	setb	Flags0.T3_PENDING
	orl	EIE1, #80h			; Enable timer 3 interrupts
	setb	IE_EA

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
	jnb	Flags1.DIR_CHANGE_BRAKE, ($+6)
	mov	Bit_Access, #40h		
	ajmp	wait_for_comp_out_start

wait_for_comp_out_high:
	setb	Flags0.DEMAG_DETECTED		; Set demag detected flag as default
	mov	Comparator_Read_Cnt, #0		; Reset number of comparator reads
	mov	Bit_Access, #40h			; Desired comparator output
	jnb	Flags1.DIR_CHANGE_BRAKE, ($+6)
	mov	Bit_Access, #00h		

wait_for_comp_out_start:
	; Set number of comparator readings
	mov	Temp1, #1					; Number of OK readings required
	mov	Temp2, #1					; Max number of readings required
	jb	Flags1.HIGH_RPM, comp_check_timeout		; Branch if high rpm

	mov	A, Flags1					; Clear demag detected flag if start phases
	anl	A, #((1 SHL STARTUP_PHASE)+(1 SHL INITIAL_RUN_PHASE))
	jz	($+4)
		
	clr	Flags0.DEMAG_DETECTED

	mov	Temp2, #20 				; Too low value (~<15) causes rough running at pwm harmonics. Too high a value (~>35) causes the RCT4215 630 to run rough on full throttle
	mov 	A, Comm_Period4x_H			; Set number of readings higher for lower speeds
	clr	C
	rrc	A
	jnz	($+3)
	inc	A
	mov	Temp1, A
	clr	C						
	subb	A, #20
	jc	($+4)

	mov	Temp1, #20
	
	jnb	Flags1.STARTUP_PHASE, comp_scale_samples

	mov	Temp1, #27				; Set many samples during startup, approximately one pwm period
	mov	Temp2, #27

comp_scale_samples:
IF MCU_48MHZ == 1
	clr	C
	mov	A, Temp1
	rlc	A
	mov	Temp1, A
	clr	C
	mov	A, Temp2
	rlc	A
	mov	Temp2, A
ENDIF
comp_check_timeout:
	jb	Flags0.T3_PENDING, comp_check_timeout_not_timed_out		; Has zero cross scan timeout elapsed?

	mov	A, Comparator_Read_Cnt			; Check that comparator has been read
	jz	comp_check_timeout_not_timed_out	; If not read - branch

	jnb	Flags1.STARTUP_PHASE, comp_check_timeout_timeout_extended	; Extend timeout during startup

	djnz	Startup_Zc_Timeout_Cntd, comp_check_timeout_extend_timeout

comp_check_timeout_timeout_extended:
	setb	Flags0.COMP_TIMED_OUT
	ajmp	setup_comm_wait

comp_check_timeout_extend_timeout:
	call	setup_zc_scan_timeout
comp_check_timeout_not_timed_out:
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
	subb	A, Temp2					; If above initial requirement - do not increment further
	jc	($+3)
	dec	Temp1

	ajmp	comp_check_timeout			; Continue to look for good ones

comp_read_wrong_not_startup:
	jb	Flags0.DEMAG_DETECTED, comp_read_wrong_extend_timeout

	inc	Temp1					; Increment number of OK readings required
	clr	C
	mov	A, Temp1
	subb	A, Temp2					
	jc	($+4)
	ajmp	wait_for_comp_out_start		; If above initial requirement - go back and restart

	ajmp	comp_check_timeout			; Otherwise - take another reading

comp_read_wrong_extend_timeout:
	clr	Flags0.DEMAG_DETECTED		; Clear demag detected flag
	anl	EIE1, #7Fh				; Disable timer 3 interrupts
	mov	TMR3CN0, #00h				; Timer 3 disabled and interrupt flag cleared
	jnb	Flags1.HIGH_RPM, comp_read_wrong_low_rpm	; Branch if not high rpm

	mov	TMR3L, #00h				; Set timeout to ~1ms
IF MCU_48MHZ == 1
	mov	TMR3H, #0F0h
ELSE
	mov	TMR3H, #0F8h
ENDIF
comp_read_wrong_timeout_set:
	mov	TMR3CN0, #04h				; Timer 3 enabled and interrupt flag cleared
	setb	Flags0.T3_PENDING
	orl	EIE1, #80h				; Enable timer 3 interrupts
	ljmp	wait_for_comp_out_start		; If comparator output is not correct - go back and restart

comp_read_wrong_low_rpm:
	mov	A, Comm_Period4x_H			; Set timeout to ~4x comm period 4x value
	mov	Temp7, #0FFh				; Default to long
IF MCU_48MHZ == 1
	clr	C
	rlc	A
	jc	comp_read_wrong_load_timeout

ENDIF
	clr	C
	rlc	A
	jc	comp_read_wrong_load_timeout

	clr	C
	rlc	A
	jc	comp_read_wrong_load_timeout

	mov	Temp7, A

comp_read_wrong_load_timeout:
	clr	C
	clr	A
	subb	A, Temp7
	mov	TMR3L, #0
	mov	TMR3H, A
	ajmp	comp_read_wrong_timeout_set

comp_read_ok:
	clr	C
	mov	A, Startup_Cnt				; Force a timeout for the first commutation
	subb	A, #1
	jnc	($+4)
	ajmp	wait_for_comp_out_start

	jnb	Flags0.DEMAG_DETECTED, ($+5)	; Do not accept correct comparator output if it is demag
	ajmp	wait_for_comp_out_start

	djnz	Temp1, comp_read_ok_jmp		; Decrement readings counter - repeat comparator reading if not zero
	ajmp	($+4)

comp_read_ok_jmp:
	ajmp	comp_check_timeout

	clr	Flags0.COMP_TIMED_OUT


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
	clr	IE_EA
		anl	EIE1, #7Fh				; Disable timer 3 interrupts
		mov	TMR3CN0, #00h			; Timer 3 disabled and interrupt flag cleared
		mov	TMR3L, Wt_Comm_Start_L
		mov	TMR3H, Wt_Comm_Start_H
		mov	TMR3CN0, #04h			; Timer 3 enabled and interrupt flag cleared
		; Setup next wait time
		mov	TMR3RLL, Wt_Adv_Start_L
		mov	TMR3RLH, Wt_Adv_Start_H
		setb	Flags0.T3_PENDING
		orl	EIE1, #80h				; Enable timer 3 interrupts
	setb	IE_EA					; Enable interrupts again

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
	mov	A, Flags1
	anl	A, #((1 SHL STARTUP_PHASE)+(1 SHL INITIAL_RUN_PHASE))
	jz	eval_comp_check_timeout

	jb	Flags1.INITIAL_RUN_PHASE, ($+5)	; Do not increment beyond startup phase
	inc	Startup_Cnt					; Increment counter
	jmp	eval_comp_exit

eval_comp_check_timeout:
	jnb	Flags0.COMP_TIMED_OUT, eval_comp_exit	; Has timeout elapsed?
	jb	Flags1.DIR_CHANGE_BRAKE, eval_comp_exit	; Do not exit run mode if it is braking
	jb	Flags0.DEMAG_DETECTED, eval_comp_exit	; Do not exit run mode if it is a demag situation
	dec	SP								; Routine exit without "ret" command
	dec	SP
	ljmp	run_to_wait_for_power_on_fail			; Yes - exit run mode

eval_comp_exit:
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

	All_pwmFETs_off
	Set_Pwms_Off

wait_for_comm_wait:

	;;; test	
	call		main_dshot_process

	wait_for_comm_wait_:
		jnb Flags0.T3_PENDING, ($+5)			
	ajmp	wait_for_comm_wait_

	; Setup next wait time
	mov	TMR3RLL, Wt_Zc_Scan_Start_L
	mov	TMR3RLH, Wt_Zc_Scan_Start_H
	setb	Flags0.T3_PENDING
	orl	EIE1, #80h			; Enable timer 3 interrupts
ret

main_dshot_process:
	jnb		DSHOT_NEW, main_dshot_process1_0
		call	dshot_command_process
		mov		A, Comm_Period4x_H
		anl		A, #0f8h
		jnz		main_dshot_process1_0
  ret
  main_dshot_process1_0:
	
	;;; test
	jnb		RCP_DSHOT_LEVEL, main_dshot_process1_exit
	jb		DSHOT_TLM_EN, main_dshot_process1_exit
	djnz	DShot_Tlm_Main_Count, main_dshot_process1_5
		mov		DShot_Tlm_Main_Count, #5
		call	dshot_make_packet_tlm1
  main_dshot_process1_exit:
  ret	
  
  main_dshot_process1_5:
	mov		A, DShot_Tlm_Main_Count
	cjne	A, #5-1, main_dshot_process1_4
		call	dshot_make_packet_tlm5
  ret
  
  main_dshot_process1_4:
	cjne	A, #4-1, main_dshot_process1_3
		call	dshot_make_packet_tlm4
  ret  
  
   main_dshot_process1_3:
	cjne	A, #3-1, main_dshot_process1_2
		call	dshot_make_packet_tlm3
  ret  
  
   main_dshot_process1_2:
		call	dshot_make_packet_tlm2
ret  
  
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Commutation routines
;
; No assumptions
;
; Performs commutation switching 
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Update_Dual_PCA:
	mov		A, Power_Pwm_Reg_L
	mov		ACC.0,c

  mov	PCA0CN0, #00h				; PCA disabled	
	IF	PWM_BITS == 8
			MOVw	PCA0L, PCA0H, Damp_Pwm_Reg_L, #0
			Set_Power_Pwm_Regs	A, A			
			Set_Damp_Pwm_Regs	Damp_Pwm_Reg_L,Damp_Pwm_Reg_L
	ELSE
		MOVw	PCA0L, PCA0H, Damp_Pwm_Reg_L,Damp_Pwm_Reg_H
		anl		PCA0PWM,#7fh
			Set_Power_Pwm_Regs	A,Power_Pwm_Reg_H		
			Set_Damp_Pwm_Regs	Damp_Pwm_Reg_L,Damp_Pwm_Reg_H		
		orl		PCA0PWM,#80h
			Set_Power_Pwm_Regs	A,Power_Pwm_Reg_H
			Set_Damp_Pwm_Regs	Damp_Pwm_Reg_L,Damp_Pwm_Reg_H
	ENDIF	
  mov	PCA0CN0, #40h				; PCA enabled	
ret
Update_Dual_PCA_BOOST:
	mov		A, Power_Pwm_Boost_L
	mov		ACC.0,c
	
  mov	PCA0CN0, #00h				; PCA disabled		
	IF	PWM_BITS == 8
		MOVw	PCA0L, PCA0H, Damp_Pwm_Boost_L, #0
			Set_Power_Pwm_Regs	A,A
			Set_Damp_Pwm_Regs	Damp_Pwm_Boost_L,Damp_Pwm_Boost_L
	ELSE
		MOVw	PCA0L, PCA0H, Damp_Pwm_Boost_L,Damp_Pwm_Boost_H
		anl		PCA0PWM,#7fh
			Set_Power_Pwm_Regs	A,Power_Pwm_Boost_H
			Set_Damp_Pwm_Regs	Damp_Pwm_Boost_L,Damp_Pwm_Boost_H			
		orl		PCA0PWM,#80h
			Set_Power_Pwm_Regs	A,Power_Pwm_Boost_H
			Set_Damp_Pwm_Regs	Damp_Pwm_Boost_L,Damp_Pwm_Boost_H
	ENDIF	
  mov	PCA0CN0, #40h				; PCA enabled	
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Delta_Sigma_Power:
	setb	PWM_BOOST_SET						;; set boost enable
	djnz	Pwm_Boost_Count, ds_Power_Boost
	inc		Pwm_Boost_Count
	clr		PWM_BOOST_SET						;; no boost
	ds_Power_Boost:

	mov		A, Power_Pwm_DS_Error
	orl		A, Power_Pwm_DS
	
	IF		PWM_DELTA_SIGMA_BITS == 1
		call	DS_lookup_1bit
	ELSEIF	PWM_DELTA_SIGMA_BITS == 2
		call	DS_lookup_2bit
	ELSE
		call	DS_lookup_3bit		
	ENDIF
	
	mov		Power_Pwm_DS_Error, A
	anl		Power_Pwm_DS_Error, #0feh
	mov		C, ACC.0

	SWITCH_CALL  PWM_BOOST_SET, Update_Dual_PCA,Update_Dual_PCA_BOOST,ds_power_switch_exit
		ds_power_switch_exit:
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Comm phase 1 to comm phase 2
comm1comm2:	
	Set_RPM_Out
	jb	Flags3.PGM_DIR_REV, comm12_rev

	clr 	IE_EA				; Disable all interrupts
		BcomFET_off 				; Turn off comfet
		CcomFET_off 				; Turn off comfet
		Set_Pwm_C					; To reapply power after a demag cut
		AcomFET_on					; Turn on comfet
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_B 			; Set comparator phase
  ret
  comm12_rev:	
	clr 	IE_EA				; Disable all interrupts
		AcomFET_off 				; Turn off comfet
		BcomFET_off 				; Turn off comfet
		Set_Pwm_A					; To reapply power after a demag cut
		CcomFET_on					; Turn on comfet (reverse)
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_B 			; Set comparator phase
ret

; Comm phase 2 to comm phase 3
comm2comm3:	
	Clear_RPM_Out
	jb	Flags3.PGM_DIR_REV, comm23_rev

	clr 	IE_EA				; Disable all interrupts
		BcomFET_off					; Turn off pwmfet
		CcomFET_off					; Turn off pwmfet
		Set_Pwm_B					; To reapply power after a demag cut
		AcomFET_on
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_C 			; Set comparator phase
  ret
  comm23_rev:
	clr 	IE_EA				; Disable all interrupts
		AcomFET_off					; Turn off pwmfet
		BcomFET_off					; Turn off pwmfet
		Set_Pwm_B					; To reapply power after a demag cut
		CcomFET_on
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_A 			; Set comparator phase (reverse)
ret

; Comm phase 3 to comm phase 4
comm3comm4:	
	Set_RPM_Out
	jb	Flags3.PGM_DIR_REV, comm34_rev

	clr 	IE_EA				; Disable all interrupts
		AcomFET_off 				; Turn off comfet
		BcomFET_off 				; Turn off comfet
		Set_Pwm_B					; To reapply power after a demag cut
		CcomFET_on					; Turn on comfet
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_A 			; Set comparator phase
  ret
  comm34_rev:	
	clr 	IE_EA				; Disable all interrupts
		BcomFET_off 				; Turn off comfet (reverse)
		CcomFET_off 				; Turn off comfet (reverse)
		Set_Pwm_B					; To reapply power after a demag cut
		AcomFET_on					; Turn on comfet (reverse)
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_C 			; Set comparator phase (reverse)
ret

; Comm phase 4 to comm phase 5
comm4comm5:	
	Clear_RPM_Out
	jb	Flags3.PGM_DIR_REV, comm45_rev

	clr 	IE_EA				; Disable all interrupts
		AcomFET_off
		BcomFET_off
		Set_Pwm_A					; To reapply power after a demag cut
		CcomFET_on
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_B 			; Set comparator phase
  ret
  comm45_rev:
	clr 	IE_EA				; Disable all interrupts
		BcomFET_off					; Turn off pwmfet
		CcomFET_off					; Turn off pwmfet
		Set_Pwm_C
		AcomFET_on					; To reapply power after a demag cut
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_B 			; Set comparator phase
ret

; Comm phase 5 to comm phase 6
comm5comm6:	
	Set_RPM_Out
	jb	Flags3.PGM_DIR_REV, comm56_rev

	clr 	IE_EA				; Disable all interrupts
		AcomFET_off 				; Turn off comfet
		CcomFET_off 				; Turn off comfet
		Set_Pwm_A					; To reapply power after a demag cut
		BcomFET_on					; Turn on comfet
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_C 			; Set comparator phase
  ret
  comm56_rev:
	clr 	IE_EA				; Disable all interrupts
		AcomFET_off 				; Turn off comfet (reverse)
		CcomFET_off 				; Turn off comfet (reverse)
		Set_Pwm_C					; To reapply power after a demag cut
		BcomFET_on					; Turn on comfet
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_A 			; Set comparator phase (reverse)
ret

; Comm phase 6 to comm phase 1
comm6comm1:	
	Clear_RPM_Out
	jb	Flags3.PGM_DIR_REV, comm61_rev

	clr 	IE_EA				; Disable all interrupts
		AcomFET_off					; Turn off pwmfet
		CcomFET_off					; Turn off pwmfet
		Set_Pwm_C
		BcomFET_on					; To reapply power after a demag cut
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_A 			; Set comparator phase
  ret
  comm61_rev:
	clr 	IE_EA				; Disable all interrupts
		AcomFET_off					; Turn off pwmfet (reverse)
		CcomFET_off					; Turn off pwmfet (reverse)
		Set_Pwm_A
		BcomFET_on					; To reapply power after a demag cut
	setb	IE_EA
	call	Delta_Sigma_Power
	
	Set_Comp_Phase_C 			; Set comparator phase (reverse)
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Comm_23_DampOn MACRO
IF CUMMU_150 == 1
		mov		A, #(FETON_DELAY)
		djnz	ACC,$					;; comm_fet_damp_delay
		jb	Flags3.PGM_DIR_REV, comm23_d_on_rev
		CcomFET_on
	ret
	comm23_d_on_rev:
		AcomFET_on
	ret
ENDIF
ENDM
Comm_23_DampOff MACRO
IF CUMMU_150 == 1
		jb	Flags3.PGM_DIR_REV, comm23_d_off_rev
		CcomFET_off
	ret
	comm23_d_off_rev:
		AcomFET_off
	ret
ENDIF
ENDM
Comm_45_DampOn MACRO
IF CUMMU_150 == 1
		mov		A, #(FETON_DELAY)
		djnz	ACC,$					;; comm_fet_damp_delay
		jb	Flags3.PGM_DIR_REV, comm45_d_on_rev
		BcomFET_on
	ret
	comm45_d_on_rev:
		BcomFET_on
	ret
ENDIF
ENDM
Comm_45_DampOff MACRO
IF CUMMU_150 == 1
		jb	Flags3.PGM_DIR_REV, comm45_d_off_rev
		BcomFET_off
	ret
	comm45_d_off_rev:
		BcomFET_off
	ret
ENDIF
ENDM
Comm_61_DampOn MACRO
IF CUMMU_150 == 1
		mov		A, #(FETON_DELAY)
		djnz	ACC,$					;; comm_fet_damp_delay
		jb	Flags3.PGM_DIR_REV, comm61_d_on_rev
		AcomFET_on
	ret
	comm61_d_on_rev:
		CcomFET_on
	ret
ENDIF
ENDM
Comm_61_DampOff MACRO
IF CUMMU_150 == 1	
		jb	Flags3.PGM_DIR_REV, comm61_d_off_rev
		AcomFET_off
	ret
	comm61_d_off_rev:
		CcomFET_off
	ret
ENDIF
ENDM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	mov	A, Beep_Strength
	djnz	ACC, beep_start
	ret

beep_start:
	mov	Temp2, #2
beep_onoff:
	clr	A
	BcomFET_off		; BcomFET off
	djnz	ACC, $		; Allow some time after comfet is turned off
	BpwmFET_on		; BpwmFET on (in order to charge the driver of the BcomFET)
	djnz	ACC, $		; Let the pwmfet be turned on a while
	BpwmFET_off		; BpwmFET off again
	djnz	ACC, $		; Allow some time after pwmfet is turned off
	BcomFET_on		; BcomFET on
	djnz	ACC, $		; Allow some time after comfet is turned on
	; Turn on pwmfet
	mov	A, Temp2
	jb	ACC.0, beep_apwmfet_on
	ApwmFET_on		; ApwmFET on
beep_apwmfet_on:
	jnb	ACC.0, beep_cpwmfet_on
	CpwmFET_on		; CpwmFET on
beep_cpwmfet_on:
	mov	A, Beep_Strength
	djnz	ACC, $		
	; Turn off pwmfet
	mov	A, Temp2
	jb	ACC.0, beep_apwmfet_off
	ApwmFET_off		; ApwmFET off
beep_apwmfet_off:
	jnb	ACC.0, beep_cpwmfet_off
	CpwmFET_off		; CpwmFET off
beep_cpwmfet_off:
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
	BcomFET_off		; BcomFET off
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
	All_pwmFETs_Off		; Turn off all pwm fets
	All_comFETs_Off		; Turn off all commutation fets
	Set_Pwms_Off
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
	mov	Temp1, #_Pgm_Gov_P_Gain
	mov	@Temp1, #0FFh	; Governor P gain
	inc	Temp1
	mov	@Temp1, #0FFh	; Governor I gain
	inc	Temp1
	mov	@Temp1, #0FFh	; Governor mode
	inc	Temp1
	mov	@Temp1, #0FFh	; Low voltage limit
	inc	Temp1
	mov	@Temp1, #0FFh	; Multi gain
	inc	Temp1
	mov	@Temp1, #0FFh	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_STARTUP_PWR
	inc	Temp1
	mov	@Temp1, #0FFh	; Pwm freq
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_DIRECTION

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
	mov	@Temp1, #DEFAULT_PGM_COMM_TIMING
	inc	Temp1
	mov	@Temp1, #0FFh	; Damping force	
	inc	Temp1
	mov	@Temp1, #0FFh	; Governor range
	inc	Temp1
	mov	@Temp1, #0FFh	; Startup method	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MIN_THROTTLE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_MAX_THROTTLE
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_BEEP_STRENGTH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_BEACON_STRENGTH
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_BEACON_DELAY
	inc	Temp1
	mov	@Temp1, #0FFh	; Throttle rate	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_DEMAG_COMP
	inc	Temp1
	mov	@Temp1, #0FFh	; Bec voltage high
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_CENTER_THROTTLE
	inc	Temp1
	mov	@Temp1, #0FFh	
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_TEMP_PROT
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_ENABLE_POWER_PROT
	inc	Temp1
	mov	@Temp1, #0FFh	; Enable pwm input
	inc	Temp1
	mov	@Temp1, #0FFh	; Pwm dither
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_BRAKE_ON_STOP
	inc	Temp1
	mov	@Temp1, #DEFAULT_PGM_LED_CONTROL
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
	; Load programmed direction
	mov	Temp1, #Pgm_Direction	
	mov	A, @Temp1				
	clr	C
	subb	A, #3
	setb	Flags3.PGM_BIDIR
	jnc	($+4)

	clr	Flags3.PGM_BIDIR

	clr	Flags3.PGM_DIR_REV
	mov	A, @Temp1				
	jnb	ACC.1, ($+5)
	setb	Flags3.PGM_DIR_REV
	mov	C, Flags3.PGM_DIR_REV
	mov	Flags3.PGM_BIDIR_REV, C
	; Decode startup power
	mov	Temp1, #Pgm_Startup_Pwr		
	mov	A, @Temp1				
	dec	A	
	
	MOVt	#STARTUP_POWER_TABLE

	mov	Temp1, #Pgm_Startup_Pwr_Decoded
	mov	@Temp1, A	
	; Decode low rpm power slope
	mov	Temp1, #Pgm_Startup_Pwr
	mov	A, @Temp1
	mov	Low_Rpm_Pwr_Slope, A
	clr	C
	subb	A, #2
	jnc	($+5)
	mov	Low_Rpm_Pwr_Slope, #2
	; Decode demag compensation
	mov	Temp1, #Pgm_Demag_Comp		
	mov	A, @Temp1				
	mov	Demag_Pwr_Off_Thresh, #255	; Set default

	cjne	A, #2, decode_demag_high

	mov	Demag_Pwr_Off_Thresh, #160	; Settings for demag comp low

decode_demag_high:
	cjne	A, #3, decode_demag_done

	mov	Demag_Pwr_Off_Thresh, #130	; Settings for demag comp high

decode_demag_done:
	; Decode temperature protection limit
	mov	Temp1, #Pgm_Enable_Temp_Prot
	mov	A, @Temp1
	mov	Temp1, A
	jz	decode_temp_done

	mov	A, #(TEMP_LIMIT-TEMP_LIMIT_STEP)
decode_temp_step:
	add	A, #TEMP_LIMIT_STEP
	djnz	Temp1, decode_temp_step

decode_temp_done:
	mov		Temp_Prot_Limit, A
	call	switch_power_off
	ret

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; LED control
;
; No assumptions
;
; Controls LEDs
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
led_control:
	mov	Temp1, #Pgm_LED_Control
	mov	A, @Temp1
	mov	Temp2, A
	anl	A, #03h
	Set_LED_0
	jnz	led_0_done
	Clear_LED_0
led_0_done:
	mov	A, Temp2
	anl	A, #0Ch
	Set_LED_1
	jnz	led_1_done
	Clear_LED_1
led_1_done:
	mov	A, Temp2
	anl	A, #030h
	Set_LED_2
	jnz	led_2_done
	Clear_LED_2
led_2_done:
	mov	A, Temp2
	anl	A, #0C0h
	Set_LED_3
	jnz	led_3_done
	Clear_LED_3
led_3_done:
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pgm_start_dshot600_timming:
	; Setup timers for DShot600/tlm750
	mov		DShot_Timer_Preset, #128									; Load DShot sync timer preset (for DShot600)
	mov		DShot_Pwm_Thr, #32										; Load DShot qualification pwm threshold (for DShot600)								; Load DShot qualification pwm threshold min (for DShot600)
	;SET_VALUE RCP_DSHOT_LEVEL, DShot_Pwm_Thr_max, #30, #27			;; 72c: 26,23 failed
	mov		DShot_Frame_Length_Thr1, #DSHOT600_FRAME_LENGTH			; Load DShot frame length criteria
	mov		DShot_Frame_Length_Thr2, #DSHOT600_FRAME_LENGTH*3/DSHOT_PACKET_SIZE		; Load DShot frame length criteria
	
	mov		Dshot_Tlm_Bit_Time1, #DSTLM750_BIT_TIME_1
	mov		Dshot_Tlm_Bit_Time2, #DSTLM750_BIT_TIME_2
	mov		Dshot_Tlm_Bit_Time3, #DSTLM750_BIT_TIME_3
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pgm_start_dshot300_timming:
	; Setup timers for DShot300/tlm375 at 49Mhz	
	mov		DShot_Timer_Preset, #0									; Load DShot sync timer preset (for DShot300)
	mov		DShot_Pwm_Thr, #64										; Load DShot qualification pwm threshold (for DShot300)
	;SET_VALUE RCP_DSHOT_LEVEL, DShot_Pwm_Thr_max, #60, #54			; Load DShot qualification pwm threshold min (for DShot300)
	mov		DShot_Frame_Length_Thr1, #DSHOT300_FRAME_LENGTH			; Load DShot frame length criteria
	mov		DShot_Frame_Length_Thr2, #DSHOT300_FRAME_LENGTH*3/DSHOT_PACKET_SIZE		; Load DShot frame length criteria

	mov		Dshot_Tlm_Bit_Time1, #DSTLM375_BIT_TIME_1
	mov		Dshot_Tlm_Bit_Time2, #DSTLM375_BIT_TIME_2
	mov		Dshot_Tlm_Bit_Time3, #DSTLM375_BIT_TIME_3
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;; check rcp level return C:	0: low for normal dshot 
;;								1: high for inverted dshot
check_rcp_level:
	mov		A,#30				;; must repeat the same level 20 times
	jb		RTX_PORT.Rcp_In, check_rcp_level_read1
  check_rcp_level_read0:
	DELAY_A	10
	jb		RTX_PORT.Rcp_In, check_rcp_level
	djnz	ACC, check_rcp_level_read0
	clr		C
  ret
  check_rcp_level_read1:
	DELAY_A	10
	jnb		RTX_PORT.Rcp_In, check_rcp_level
	djnz	ACC, check_rcp_level_read1	
	setb	C
  ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dshot_make_packet_tlm:
	jnb		RCP_DSHOT_LEVEL, dshot_make_packet_tlm_0

	call	dshot_make_packet_tlm5
	call	dshot_make_packet_tlm4
	call	dshot_make_packet_tlm3
	call	dshot_make_packet_tlm2
	call	dshot_make_packet_tlm1
	
	call	dshot_make_packet_tlm5
	call	dshot_make_packet_tlm4
	call	dshot_make_packet_tlm3
	call	dshot_make_packet_tlm2
	call	dshot_make_packet_tlm1
	
	mov		DShot_Tlm_Main_Count, #5
dshot_make_packet_tlm_0:	
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Initialize_PCA_ MACRO
	mov		PCA0CN0, #40h					; PCA enabled
	mov		PCA0MD, #08h					; PCA clock is system clock

	IF		PWM_BITS == 10
				mov	PCA0PWM, #82h			; PCA ARSEL set and 10bits pwm
	ELSEIF	PWM_BITS == 9	
				mov	PCA0PWM, #81h			; PCA ARSEL set and 9bits pwm
	ELSE	
				mov	PCA0PWM, #80h			; PCA ARSEL set and 8bits pwm
	ENDIF
	mov		PCA0CENT, #03h					; Center aligned pwm
 
	IF		PWM_DELTA_SIGMA_BITS == 1
		mov		Power_Pwm_DS_Error,#0000$10$00b	;; reset ds error=0
	ELSEIF PWM_DELTA_SIGMA_BITS == 2
		mov		Power_Pwm_DS_Error,#00$100$000b	;; reset ds error=0
	ELSE
		mov		Power_Pwm_DS_Error,#1000$0000b	;; reset ds error=0
	ENDIF	

	mov		Pwm_Boost_Count, #1					;; initial to no boost
		
	MOVw	Damp_Pwm_Boost_L, Damp_Pwm_Boost_H,	#00h,#00h		;; set damp = off	
	MOVw	Power_Pwm_Boost_L,Power_Pwm_Boost_H, #0ffh,#0ffh	;; set pwm = off
ENDM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pgm_start:
	; Initialize flash keys to invalid values
		MOVw	Flash_Key_1,Flash_Key_2, #0,#0
	; Disable the WDT.
		mov	WDTCN, #0DEh			; Disable watchdog
		mov	WDTCN, #0ADh		
	; Initialize stack
		mov	SP, #Stack-1			; 16 bytes of indirect RAM
	; Initialize VDD monitor
		orl	VDM0CN, #080h    		; Enable the VDD monitor
		mov 	RSTSRC, #06h   		; Set missing clock and VDD monitor as a reset source if not 1S capable
	; Set clock frequency
		mov	CLKSEL, #00h 			; 24.5Mhz, clock divider to 1
	; Switch power off
		call	switch_power_off
	; Ports initialization
	mov	P0, #P0_INIT
	mov	P0MDIN, #P0_DIGITAL
	mov	P0MDOUT, #P0_PUSHPULL
	mov	P0, #P0_INIT
	mov	P0SKIP, #P0_SKIP				
	mov	P1, #P1_INIT
	mov	P1MDIN, #P1_DIGITAL
	mov	P1MDOUT, #P1_PUSHPULL
	mov	P1, #P1_INIT
	mov	P1SKIP, #P1_SKIP				
	mov	P2MDOUT, #P2_PUSHPULL				
	
	Initialize_Xbar
	call	switch_power_off
	
	; Clear RAM
	clr	A						; Clear accumulator
	mov	Temp1, #0				; Clear Temp1
	clear_ram:	
		mov	@Temp1, A			; Clear RAM
	djnz Temp1, clear_ram		; Is A not zero? - jump
	
	call	set_default_parameters
	call	read_all_eeprom_parameters
	mov		Temp1, #Pgm_Beep_Strength
	mov		Beep_Strength, @Temp1
	
	mov	Initial_Arm, #1			; Set initial arm variable
	; Initializing beep
	clr	IE_EA					; Disable interrupts explicitly
	call wait200ms	
	call beep_f1
	call wait30ms
	call beep_f2
	call wait30ms
	call beep_f3
	call wait30ms
	call led_control

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; No signal entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
init_no_signal:
	clr		IE_EA
	; Initialize flash keys to invalid values
		MOVw	Flash_Key_1,Flash_Key_2, #0,#0
	; Check if input signal is high for more than 15ms
	mov		Temp1, #250
	input_high_check_1:
		mov		Temp2, #250
		input_high_check_2:
			jnb		RTX_PORT.RTX_PIN, bootloader_done	; Look for low
		djnz	Temp2, input_high_check_2
	djnz	Temp1, input_high_check_1

	IF	(MCU_48MHZ == 1) OR (SIMULATE_BB1 == 1)
		Set_MCU_Clk_24MHz
	ENDIF
	
	ljmp	1C00h			; Jump to bootloader
	
bootloader_done:
	IF	MCU_48MHZ == 1
		Set_MCU_Clk_48MHz
	ENDIF

	call	decode_settings
	mov		Temp1, #Pgm_Beep_Strength
	mov		Beep_Strength, @Temp1
	call	switch_power_off
	; Setup timers for pwm input
	mov		TMR2CN0, #04h				; Timer 2 enabled
	mov		TMR3CN0, #04h				; Timer 3 enabled
	Initialize_PCA_						; Initialize PCA
	Set_Pwm_Polarity					; Set pwm polarity
	Enable_Power_Pwm_Module				; Enable power pwm module
	Enable_Damp_Pwm_Module				; Enable damping pwm module
	
	Initialize_Comparator				; Initialize comparator
	Initialize_Adc						; Initialize ADC operation
	clr		DSHOT_NEW
	
	call	wait1ms
	
	mov		Stall_Cnt, #0				; Reset stall count
	clr		Flags2.RCP_UPDATED			; Clear updated flag
	call 	wait200ms
		
	setb	Flags2.RCP_DSHOT
	call	check_rcp_level
		mov		RCP_DSHOT_LEVEL, C
	SET_VALUE  RCP_DSHOT_LEVEL,IT01CF, #(80h+(RTX_PIN SHL 4)+(RTX_PIN)), #((RTX_PIN SHL 4)+08h+(RTX_PIN))
	clr		DSHOT_TLM_EN
	clr		DSHOT_NEW
	clr		DSHOT_TLM_BUF_SEL
	clr		DSHOT_TLM_BUF_SEL_D
	mov		DShot_Tlm_Main_Count, #5
	
	mov		TCON, 	#51h							; Timer 0/1 run and INT0 edge triggered
	mov		CKCON0, #0Ch							; Timer 0/1 clock is system clock (for DShot300)
	mov		TMOD, 	#0AAh							; Timer 0/1 set to 8bits auto reload and gated by INT0
	mov		TH0, 	#0								; Auto reload value zero
	mov		TH1, 	#0
	mov		CKCON0, #0Ch											; Timer 0/1 clock is system clock (for DShot300)

	mov		EIE1,	#80h 							; Enable timer 3
	mov		IP,		#03h							; t0 and int0 both high priority
	mov		IE,		#28h							; Enable t1/2
	
	call	pgm_start_dshot300_timming
	call 	initialize_timing

	setb	IE_EA
		mov		Rcp_Outside_Range_Cnt, #10			; Set out of range counter
		call 	wait100ms							; Wait for new RC pulse
		MOVw	Dshot_Cmd, Dshot_Cmd_Cnt, #0, #0	
		
	IF_LT	Rcp_Outside_Range_Cnt, #10, validate_rcp_start
	
	call	pgm_start_dshot600_timming
		mov		Rcp_Outside_Range_Cnt, #10			; Set out of range counter
		call 	wait100ms							; Wait for new RC pulse
		MOVw	Dshot_Cmd, Dshot_Cmd_Cnt, #0, #0
	IF_LT	Rcp_Outside_Range_Cnt, #10, validate_rcp_start
	
	jmp		init_no_signal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
validate_rcp_start:
	; Validate RC pulse
	call wait3ms						; Wait for new RC pulse
	
	IF_CLR_JUMP  Flags2.RCP_UPDATED, init_no_signal
		;jb	Flags2.RCP_UPDATED, ($+6)		; Is there an updated RC pulse available - proceed
		;ljmp	init_no_signal				; Go back to detect input signal
	;IF_NZ_JUMP  New_Rcp, init_no_signal
	
	; Beep arm sequence start signal
	clr 	IE_EA							; Disable all interrupts
		call	beep_f1						; Signal that RC pulse is ready
		call	beep_f1
		call	beep_f1
	setb	IE_EA							; Enable all interrupts
	call wait200ms	

;;;;;; 	Arming sequence start		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
arming_start:
	; Initialize flash keys to invalid values
	MOVw	Flash_Key_1,Flash_Key_2, #0,#0
	call wait100ms				; Wait for new throttle value
	
	IF_NZ_JUMP  New_Rcp, arming_start
		;clr	C
		;mov	A, New_Rcp			; Load new RC pulse value
		;subb	A, #1				; Below stop?
		;jc	arm_end_beep			; Yes - proceed
		;jmp	arming_start			; No - start over

arm_end_beep:
	; Beep arm sequence end signal
	clr 	IE_EA					; Disable all interrupts
		call	beep_f4				; Signal that rcpulse is ready
		call	beep_f4
		call	beep_f4
	setb	IE_EA					; Enable all interrupts
	call wait200ms

	mov		Initial_Arm, #0
	; Armed and waiting for power on
wait_for_power_on:

	call 	initialize_timing
	
	clr	A
	mov	Power_On_Wait_Cnt_L, A	; Clear wait counter
	mov	Power_On_Wait_Cnt_H, A	
wait_for_power_on_loop:
	inc	Power_On_Wait_Cnt_L		; Increment low wait counter
	mov	A, Power_On_Wait_Cnt_L
	cpl	A
	jnz	wait_for_power_on_no_beep; Counter wrapping (about 3 sec)

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

	call	switch_power_off		; Switch power off in case braking is set
	call	wait1ms
	dec	Power_On_Wait_Cnt_H		; Decrement high wait counter
	mov	Power_On_Wait_Cnt_L, #0	; Set low wait counter
	mov	Temp1, #Pgm_Beacon_Strength
	mov	Beep_Strength, @Temp1
	clr 	IE_EA				; Disable all interrupts
	call beep_f4				; Signal that there is no signal
	setb	IE_EA				; Enable all interrupts
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
	call wait100ms				; Wait for new RC pulse to be measured

wait_for_power_on_no_beep:
	call wait10ms
	mov	A, Rcp_Timeout_Cntd			; Load RC pulse timeout counter value
	jnz	wait_for_power_on_not_missing	; If it is not zero - proceed

	jmp	init_no_signal				; If pulses missing - go back to detect input signal

wait_for_power_on_not_missing:

	IF_SET_CALL		DSHOT_NEW, dshot_command_process

	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #1		 		; Higher than stop
	jnc	wait_for_power_on_nonzero	; Yes - proceed

	clr	C
	mov	A, Dshot_Cmd
	subb	A, #1		 		; 1 or higher
	jnc	check_dshot_cmd		; Check Dshot command

	ljmp	wait_for_power_on_loop	; If not Dshot command - start over

wait_for_power_on_nonzero:
	lcall wait100ms			; Wait to see if start pulse was only a glitch
	mov	A, Rcp_Timeout_Cntd		; Load RC pulse timeout counter value
	jnz	($+5)				; If it is not zero - proceed
	ljmp	init_no_signal			; If it is zero (pulses missing) - go back to detect input signal

	mov 	Dshot_Cmd, #0
	mov 	Dshot_Cmd_Cnt, #0
	ljmp init_start

check_dshot_cmd:
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #1
	jnz 	dshot_beep_2

	clr 	IE_EA
		call	switch_power_off		; Switch power off in case braking is set
		mov	Temp1, #Pgm_Beacon_Strength
		mov	Beep_Strength, @Temp1
		call beep_f1
		mov	Temp1, #Pgm_Beep_Strength
		mov	Beep_Strength, @Temp1
	setb	IE_EA	
	call wait100ms	
	jmp 	clear_dshot_cmd

dshot_beep_2:	
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #2
	jnz 	dshot_beep_3

	clr 	IE_EA
	call	switch_power_off		; Switch power off in case braking is set
	mov	Temp1, #Pgm_Beacon_Strength
	mov	Beep_Strength, @Temp1
	call beep_f2
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
	setb	IE_EA	
	call wait100ms	
	jmp 	clear_dshot_cmd

dshot_beep_3:		
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #3
	jnz 	dshot_beep_4

	clr 	IE_EA
	call	switch_power_off		; Switch power off in case braking is set
	mov	Temp1, #Pgm_Beacon_Strength
	mov	Beep_Strength, @Temp1
	call beep_f3
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
	setb	IE_EA	
	call wait100ms	
	jmp 	clear_dshot_cmd

dshot_beep_4:
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #4
	jnz 	dshot_beep_5

	clr 	IE_EA
	call	switch_power_off		; Switch power off in case braking is set
	mov	Temp1, #Pgm_Beacon_Strength
	mov	Beep_Strength, @Temp1
	call beep_f4
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
	setb	IE_EA	
	call wait100ms		
	jmp 	clear_dshot_cmd

dshot_beep_5:
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #5
	jnz 	dshot_direction_1

	clr 	IE_EA
	call	switch_power_off		; Switch power off in case braking is set
	mov	Temp1, #Pgm_Beacon_Strength
	mov	Beep_Strength, @Temp1
	call beep_f4
	mov	Temp1, #Pgm_Beep_Strength
	mov	Beep_Strength, @Temp1
	setb	IE_EA	
	call wait100ms	
	jmp 	clear_dshot_cmd

dshot_direction_1:
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #7
	jnz 	dshot_direction_2

	clr 	C
	mov 	A, Dshot_Cmd_Cnt
	subb A, #DSHOT_CMD_REPEAT 					; Needs to receive it 6 times in a row
	jnc 	($+4) 					; Same as "jc dont_clear_dshot_cmd"
	ajmp wait_for_power_on_not_missing

	mov	A, #1
	jnb	Flags3.PGM_BIDIR, ($+5)
	mov	A, #3
	mov	Temp1, #Pgm_Direction
	mov	@Temp1, A
	clr 	Flags3.PGM_DIR_REV
	clr 	Flags3.PGM_BIDIR_REV
	jmp 	clear_dshot_cmd

dshot_direction_2:
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #8
	jnz 	dshot_direction_bidir_off

	clr 	C
	mov 	A, Dshot_Cmd_Cnt
	subb A, #DSHOT_CMD_REPEAT 					; Needs to receive it 6 times in a row
	jnc 	($+4) 					; Same as "jc dont_clear_dshot_cmd"
	ajmp wait_for_power_on_not_missing

	mov	A, #2
	jnb	Flags3.PGM_BIDIR, ($+5)
	mov	A, #4
	mov	Temp1, #Pgm_Direction
	mov	@Temp1, A
	setb Flags3.PGM_DIR_REV
	setb Flags3.PGM_BIDIR_REV
	jmp 	clear_dshot_cmd

dshot_direction_bidir_off:
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #9
	jnz 	dshot_direction_bidir_on

	clr 	C
	mov 	A, Dshot_Cmd_Cnt
	subb A, #DSHOT_CMD_REPEAT 					; Needs to receive it 6 times in a row
	jnc 	($+4) 					; Same as "jc dont_clear_dshot_cmd"
	ajmp wait_for_power_on_not_missing

	jnb	Flags3.PGM_BIDIR, dshot_direction_bidir_on

	clr	C
	mov	Temp1, #Pgm_Direction
	mov	A, @Temp1
	subb	A, #2
	mov	@Temp1, A
	clr 	Flags3.PGM_BIDIR
	jmp 	clear_dshot_cmd

dshot_direction_bidir_on:
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #10
	jnz 	dshot_direction_normal

	clr 	C
	mov 	A, Dshot_Cmd_Cnt
	subb A, #DSHOT_CMD_REPEAT 					; Needs to receive it 6 times in a row
	jnc 	($+4) 					; Same as "jc dont_clear_dshot_cmd"
	ajmp wait_for_power_on_not_missing

	jb	Flags3.PGM_BIDIR, dshot_direction_normal

	mov	Temp1, #Pgm_Direction
	mov	A, @Temp1
	add	A, #2
	mov	@Temp1, A
	setb	Flags3.PGM_BIDIR
	jmp 	clear_dshot_cmd

dshot_direction_normal: 
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #20
	jnz 	dshot_direction_reverse

	clr 	C
	mov 	A, Dshot_Cmd_Cnt
	subb A, #DSHOT_CMD_REPEAT 					; Needs to receive it 6 times in a row
	jnc 	($+4) 					; Same as "jc dont_clear_dshot_cmd"
	ajmp wait_for_power_on_not_missing

	mov		A, #0
	MOVt	#Eep_Pgm_Direction		; Read from flash

	mov	Temp1, #Pgm_Direction
	mov	@Temp1, A
	rrc	A						; Lsb to carry
	clr 	Flags3.PGM_DIR_REV
	clr 	Flags3.PGM_BIDIR_REV
	jc	($+4)
	setb	Flags3.PGM_DIR_REV
	jc	($+4)
	setb	Flags3.PGM_BIDIR_REV
	jmp 	clear_dshot_cmd

dshot_direction_reverse: 			; Temporary reverse
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #21
	jnz 	dshot_save_settings

	clr 	C
	mov 	A, Dshot_Cmd_Cnt
	subb A, #DSHOT_CMD_REPEAT 					; Needs to receive it 6 times in a row
	jc 	dont_clear_dshot_cmd
	
	mov		A, #0
	MOVt	#Eep_Pgm_Direction	
	
	mov	Temp1, A
	cjne	Temp1, #1, ($+5)
	mov	A, #2
	cjne	Temp1, #2, ($+5)
	mov	A, #1
	cjne	Temp1, #3, ($+5)
	mov	A, #4
	cjne	Temp1, #4, ($+5)
	mov	A, #3
	mov	Temp1, #Pgm_Direction
	mov	@Temp1, A
	rrc	A						; Lsb to carry
	clr 	Flags3.PGM_DIR_REV
	clr 	Flags3.PGM_BIDIR_REV
	jc	($+4)
	setb	Flags3.PGM_DIR_REV
	jc	($+4)
	setb	Flags3.PGM_BIDIR_REV
	jmp 	clear_dshot_cmd

dshot_save_settings:
	clr	C
	mov 	A, Dshot_Cmd
	subb A, #12
	jnz 	clear_dshot_cmd

	mov	Flash_Key_1, #0A5h			; Initialize flash keys to valid values
	mov	Flash_Key_2, #0F1h
	clr 	C
	mov 	A, Dshot_Cmd_Cnt
	subb A, #DSHOT_CMD_REPEAT 					; Needs to receive it 6 times in a row
	jc 	dont_clear_dshot_cmd

	call erase_and_store_all_in_eeprom
	setb	IE_EA
	
clear_dshot_cmd:
	mov 	Dshot_Cmd, #0
	mov 	Dshot_Cmd_Cnt, #0

dont_clear_dshot_cmd:
	mov	Flash_Key_1, #0			; Initialize flash keys to invalid values
	mov	Flash_Key_2, #0
	jmp 	wait_for_power_on_not_missing

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Start entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
init_start:
	call switch_power_off
	mov	Adc_Conversion_Cnt, #0
	mov	Flags0, #0				; Clear flags0
	mov	Flags1, #0				; Clear flags1
	mov	Demag_Detected_Metric, #0	; Clear demag metric
	;**** **** **** **** ****
	; Motor start beginning
	;**** **** **** **** **** 
	mov	Adc_Conversion_Cnt, #8				; Make sure a temp reading is done
	call wait1ms
	call start_adc_conversion
read_initial_temp:
	jnb	ADC0CN0_ADINT, read_initial_temp
	Read_Adc_Result						; Read initial temperature
	mov	A, Temp2
	jnz	($+3)							; Is reading below 256?

	mov	Temp1, A							; Yes - set average temperature value to zero

	mov	Current_Average_Temp, Temp1			; Set initial average temperature
	call check_temp_voltage_and_limit_power
	mov	Adc_Conversion_Cnt, #8				; Make sure a temp reading is done next time
	; Set up start operating conditions
	clr	IE_EA				; Disable interrupts
		call set_startup_pwm
		mov	Pwm_Limit, Pwm_Limit_Beg
		mov	Pwm_Limit_By_Rpm, Pwm_Limit_Beg
	setb	IE_EA
	; Begin startup sequence
	jnb	Flags3.PGM_BIDIR, init_start_bidir_done	; Check if bidirectional operation

	clr	Flags3.PGM_DIR_REV			; Set spinning direction. Default fwd
	jnb	Flags2.RCP_DIR_REV, ($+5)	; Check force direction
	setb	Flags3.PGM_DIR_REV			; Set spinning direction

init_start_bidir_done:
	setb	Flags1.STARTUP_PHASE		; Set startup phase flag
	mov		Startup_Cnt, #0				; Reset counter
	
	IF_SET_CALL		DSHOT_NEW, dshot_command_process	
	
	call 	comm5comm6					; Initialize commutation
	call 	comm6comm1				
	call 	initialize_timing			; Initialize timing
	call 	calc_next_comm_timing		; Calculate next timing and wait advance timing wait
	call 	wait_advance_timing			; Calculate next timing and wait advance timing wait
	call	calc_new_wait_times

	call 	initialize_timing			; Initialize timing
	call 	calc_next_comm_timing		; Calculate next timing and wait advance timing wait
	call 	wait_advance_timing			; Calculate next timing and wait advance timing wait
	call	calc_new_wait_times

	call	initialize_timing			; Initialize timing

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Run entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****

; Run 1 = B(p-on) + C(n-pwm) - comparator A evaluated
; Out_cA changes from low to high
run1:
	call wait_for_comp_out_high	; Wait for high
;		setup_comm_wait		; Setup wait time from zero cross to commutation
;		evaluate_comparator_integrity	; Check whether comparator reading has been normal

	Comm_61_DampOn
	call wait_for_comm			; Wait from zero cross to commutation
	call comm1comm2			; Commutate	
	call calc_next_comm_timing	; Calculate next timing and wait advance timing wait
	call wait_advance_timing	; Calculate next timing and wait advance timing wait
	call calc_new_wait_times
	
;		wait_advance_timing		; Wait advance timing and start zero cross wait
;		calc_new_wait_times
;		wait_before_zc_scan		; Wait zero cross wait and start zero cross timeout

; Run 2 = A(p-on) + C(n-pwm) - comparator B evaluated
; Out_cB changes from high to low
run2:
	call wait_for_comp_out_low
;		setup_comm_wait
;		evaluate_comparator_integrity
	jb	Flags1.HIGH_RPM, ($+6)	; Skip if high rpm
	lcall set_pwm_limit_low_rpm
	jnb	Flags1.HIGH_RPM, ($+6)	; Do if high rpm
	lcall set_pwm_limit_high_rpm
	call wait_for_comm
	call comm2comm3
	Comm_23_DampOn
		call calc_next_comm_timing	; Calculate next timing and wait advance timing wait
		call wait_advance_timing	; Calculate next timing and wait advance timing wait
	Comm_23_DampOff
	call calc_new_wait_times
;		wait_advance_timing
;		calc_new_wait_times
;		wait_before_zc_scan

; Run 3 = A(p-on) + B(n-pwm) - comparator C evaluated
; Out_cC changes from low to high
run3:
	call wait_for_comp_out_high
;		setup_comm_wait
;		evaluate_comparator_integrity

	Comm_23_DampOn
	call wait_for_comm	
	call comm3comm4
	call calc_next_comm_timing	; Calculate next timing and wait advance timing wait
	call wait_advance_timing	; Calculate next timing and wait advance timing wait
	call calc_new_wait_times
;		wait_advance_timing
;		calc_new_wait_times
;		wait_before_zc_scan

; Run 4 = C(p-on) + B(n-pwm) - comparator A evaluated
; Out_cA changes from high to low
run4:
	call wait_for_comp_out_low
;		setup_comm_wait
;		evaluate_comparator_integrity
	call wait_for_comm
	call comm4comm5
	Comm_45_DampOn
		call calc_next_comm_timing	; Calculate next timing and wait advance timing wait
		call wait_advance_timing	; Calculate next timing and wait advance timing wait
	Comm_45_DampOff
	call calc_new_wait_times
;		wait_advance_timing
;		calc_new_wait_times
;		wait_before_zc_scan

; Run 5 = C(p-on) + A(n-pwm) - comparator B evaluated
; Out_cB changes from low to high
run5:
	call wait_for_comp_out_high
;		setup_comm_wait
;		evaluate_comparator_integrity

	Comm_45_DampOn
	call wait_for_comm	
	call comm5comm6
	call calc_next_comm_timing	; Calculate next timing and wait advance timing wait
	call wait_advance_timing	; Calculate next timing and wait advance timing wait
	call calc_new_wait_times
;		wait_advance_timing
;		calc_new_wait_times
;		wait_before_zc_scan

; Run 6 = B(p-on) + A(n-pwm) - comparator C evaluated
; Out_cC changes from high to low
run6:
	call start_adc_conversion
	call wait_for_comp_out_low
;		setup_comm_wait
;		evaluate_comparator_integrity
	call wait_for_comm
	call comm6comm1
	Comm_61_DampOn
		call check_temp_voltage_and_limit_power
		call calc_next_comm_timing	; Calculate next timing and wait advance timing wait
		call wait_advance_timing	; Calculate next timing and wait advance timing wait
	Comm_61_DampOff
	call calc_new_wait_times
;		wait_advance_timing
;		calc_new_wait_times
;		wait_before_zc_scan

	; Check if it is direct startup
	jnb	Flags1.STARTUP_PHASE, normal_run_checks

	; Set spoolup power variables
	mov	Pwm_Limit, Pwm_Limit_Beg		; Set initial max power
	; Check startup counter
	mov	Temp2, #24				; Set nominal startup parameters
	mov	Temp3, #12	;12	;;; test
	clr	C
	mov	A, Startup_Cnt				; Load counter
	subb	A, Temp2					; Is counter above requirement?
	jc	direct_start_check_rcp		; No - proceed

	clr	Flags1.STARTUP_PHASE		; Clear startup phase flag
	setb	Flags1.INITIAL_RUN_PHASE		; Set initial run phase flag
	mov	Initial_Run_Rot_Cntd, Temp3	; Set initial run rotation count
	mov	Pwm_Limit, Pwm_Limit_Beg
	mov	Pwm_Limit_By_Rpm, Pwm_Limit_Beg
	jmp	normal_run_checks

direct_start_check_rcp:
	clr	C
	mov	A, New_Rcp					; Load new pulse value
	subb	A, #1					; Check if pulse is below stop value
	jc	($+5)

	ljmp	run1					; Continue to run 

	jmp	run_to_wait_for_power_on


normal_run_checks:
	; Check if it is initial run phase
	jnb	Flags1.INITIAL_RUN_PHASE, initial_run_phase_done	; If not initial run phase - branch
	jb	Flags1.DIR_CHANGE_BRAKE, initial_run_phase_done	; If a direction change - branch

	; Decrement startup rotaton count
	mov	A, Initial_Run_Rot_Cntd
	dec	A
	; Check number of initial rotations
	jnz 	initial_run_check_startup_rot	; Branch if counter is not zero

	clr	Flags1.INITIAL_RUN_PHASE		; Clear initial run phase flag
	setb	Flags1.MOTOR_STARTED		; Set motor started
	jmp run1						; Continue with normal run

initial_run_check_startup_rot:
	mov	Initial_Run_Rot_Cntd, A		; Not zero - store counter

	jb	Flags3.PGM_BIDIR, initial_run_continue_run	; Check if bidirectional operation

	clr	C
	mov	A, New_Rcp				; Load new pulse value
	subb	A, #1					; Check if pulse is below stop value
	jc	($+5)

initial_run_continue_run:
	ljmp	run1						; Continue to run 

	jmp	run_to_wait_for_power_on

initial_run_phase_done:
	; Reset stall count
	mov	Stall_Cnt, #0
	; Exit run loop after a given time
	jb	Flags3.PGM_BIDIR, run6_check_timeout	; Check if bidirectional operation

	mov	Temp1, #250
	mov	Temp2, #Pgm_Brake_On_Stop
	mov	A, @Temp2
	jz	($+4)

	mov	Temp1, #3					; About 100ms before stopping when brake is set

	clr	C
	mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter low byte value
	subb	A, Temp1					; Is number of stop RC pulses above limit?
	jnc	run_to_wait_for_power_on		; Yes, go back to wait for poweron

run6_check_timeout:
	mov	A, Rcp_Timeout_Cntd			; Load RC pulse timeout counter value
	jz	run_to_wait_for_power_on		; If it is zero - go back to wait for poweron

run6_check_dir:
	jnb	Flags3.PGM_BIDIR, run6_check_speed		; Check if bidirectional operation

	jb	Flags3.PGM_DIR_REV, run6_check_dir_rev		; Check if actual rotation direction
	jb	Flags2.RCP_DIR_REV, run6_check_dir_change	; Matches force direction
	jmp	run6_check_speed

run6_check_dir_rev:
	jnb	Flags2.RCP_DIR_REV, run6_check_dir_change
	jmp	run6_check_speed

run6_check_dir_change:
	jb	Flags1.DIR_CHANGE_BRAKE, run6_check_speed

	setb	Flags1.DIR_CHANGE_BRAKE		; Set brake flag
	mov	Pwm_Limit, Pwm_Limit_Beg		; Set max power while braking
	jmp	run4						; Go back to run 4, thereby changing force direction

run6_check_speed:
	mov	Temp1, #0F0h				; Default minimum speed
	jnb	Flags1.DIR_CHANGE_BRAKE, run6_brake_done; Is it a direction change?

	mov	Pwm_Limit, Pwm_Limit_Beg 	; Set max power while braking
	mov	Temp1, #20h 				; Bidirectional braking termination speed

run6_brake_done:
	clr	C
	mov	A, Comm_Period4x_H			; Is Comm_Period4x more than 32ms (~1220 eRPM)?
	subb	A, Temp1
	jnc	($+5)					; Yes - stop or turn direction 
	ljmp	run1						; No - go back to run 1

	jnb	Flags1.DIR_CHANGE_BRAKE, run_to_wait_for_power_on	; If it is not a direction change - stop

	clr	Flags1.DIR_CHANGE_BRAKE		; Clear brake flag
	clr	Flags3.PGM_DIR_REV			; Set spinning direction. Default fwd
	jnb	Flags2.RCP_DIR_REV, ($+5)	; Check force direction
	setb	Flags3.PGM_DIR_REV			; Set spinning direction
	setb	Flags1.INITIAL_RUN_PHASE
	mov	Initial_Run_Rot_Cntd, #18
	mov	Pwm_Limit, Pwm_Limit_Beg		; Set initial max power
	jmp	run1						; Go back to run 1 

run_to_wait_for_power_on_fail:	
	inc	Stall_Cnt					; Increment stall count
	mov	A, New_Rcp				; Check if RCP is zero, then it is a normal stop			
	jz	run_to_wait_for_power_on
	ajmp	run_to_wait_for_power_on_stall_done

run_to_wait_for_power_on:	
	mov	Stall_Cnt, #0

run_to_wait_for_power_on_stall_done:
	clr	IE_EA
	call switch_power_off
	mov	Flags1, #0				; Clear flags1

	setb	IE_EA
	call	wait100ms					; Wait for pwm to be stopped
	call switch_power_off
	mov	Flags0, #0				; Clear flags0
	mov	Temp1, #Pgm_Brake_On_Stop
	mov	A, @Temp1
	jz	run_to_wait_for_power_on_brake_done

	AcomFET_on
	BcomFET_on
	CcomFET_on

run_to_wait_for_power_on_brake_done:
	clr	C
	mov	A, Stall_Cnt
	subb	A, #4
	jc	jmp_wait_for_power_on
	jmp	init_no_signal

jmp_wait_for_power_on:
	jmp	wait_for_power_on			; Go back to wait for power on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DS_lookup_1bit:
	movc	A, @A+PC
	ret					;; error: 01=-1, 10=0, 11=1
	DB	1,2,3 			;; dummy
						; error	input
	DB	0000$01$01b		;;	01	00
	DB	0000$11$00b		;;	01	01
	DB	0000$10$00b		;;	01	10
	DB	0000$01$00b		;;	01	11
	
	DB	0000$10$01b		;;	10	00
	DB	0000$01$01b		;;	10	01
	DB	0000$11$00b		;;	10	10
	DB	0000$10$00b		;;	10	11
	
	DB	0000$11$01b		;;	11	00
	DB	0000$10$01b		;;	11	01
	DB	0000$01$01b		;;	11	10
	DB	0000$11$00b		;;	11	11
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
DS_lookup_2bit:
	movc	A, @A+PC
	ret					;; error: 001=-3, 010=-2, 011=-1, 100=0, 101=1, 110=2, 111=3
	DB	1,2,3,4,5,6,7	;; dummy
						; error		input
	DB	00$001$001b		;;	001(-3)	000 0	001=-3, 010=-2, 011=-1, 100=0, 101=1, 110=2, 111=3
	DB	00$111$000b		;;	001(-3)	001 1
	DB	00$110$000b		;;	001(-3)	010 2
	DB	00$101$000b		;;	001(-3)	011 3
	DB	00$100$000b		;;	001(-3)	100 4
	DB	00$011$000b		;;	001(-3)	101 5
	DB	00$010$000b		;;	001(-3)	110 6
	DB	00$001$000b		;;	001(-3)	111 7

	DB	00$010$001b		;;	010(-2)	000 0	001=-3, 010=-2, 011=-1, 100=0, 101=1, 110=2, 111=3
	DB	00$001$001b		;;	010(-2)	001 1
	DB	00$111$000b		;;	010(-2)	010 2
	DB	00$110$000b		;;	010(-2)	011 3
	DB	00$101$000b		;;	010(-2)	100 4
	DB	00$100$000b		;;	010(-2)	101 5
	DB	00$011$000b		;;	010(-2)	110 6
	DB	00$010$000b		;;	010(-2)	111 7	

	DB	00$011$001b		;;	011(-1)	000 0	001=-3, 010=-2, 011=-1, 100=0, 101=1, 110=2, 111=3
	DB	00$010$001b		;;	011(-1)	001 1
	DB	00$001$001b		;;	011(-1)	010 2
	DB	00$111$000b		;;	011(-1)	011 3
	DB	00$110$000b		;;	011(-1)	100 4
	DB	00$101$000b		;;	011(-1)	101 5
	DB	00$100$000b		;;	011(-1)	110 6
	DB	00$011$000b		;;	011(-1)	111 7		
	       
	DB	00$100$001b		;;	100(0)	000 0	001=-3, 010=-2, 011=-1, 100=0, 101=1, 110=2, 111=3
	DB	00$011$001b		;;	100(0)	001 1
	DB	00$010$001b		;;	100(0)	010 2
	DB	00$001$001b		;;	100(0)	011 3
	DB	00$111$000b		;;	100(0)	100 4
	DB	00$110$000b		;;	100(0)	101 5
	DB	00$101$000b		;;	100(0)	110 6
	DB	00$100$000b		;;	100(0)	111 7		

	DB	00$101$001b		;;	101(1)	000 0	001=-3, 010=-2, 011=-1, 100=0, 101=1, 110=2, 111=3
	DB	00$100$001b		;;	101(1)	001 1
	DB	00$011$001b		;;	101(1)	010 2
	DB	00$010$001b		;;	101(1)	011 3
	DB	00$001$001b		;;	101(1)	100 4
	DB	00$111$000b		;;	101(1)	101 5
	DB	00$110$000b		;;	101(1)	110 6
	DB	00$101$000b		;;	101(1)	111 7		
		
	DB	00$110$001b		;;	110(2)	000 0	001=-3, 010=-2, 011=-1, 100=0, 101=1, 110=2, 111=3
	DB	00$101$001b		;;	110(2)	001 1
	DB	00$100$001b		;;	110(2)	010 2
	DB	00$011$001b		;;	110(2)	011 3
	DB	00$010$001b		;;	110(2)	100 4
	DB	00$001$001b		;;	110(2)	101 5
	DB	00$111$000b		;;	110(2)	110 6
	DB	00$110$000b		;;	110(2)	111 7		

	DB	00$111$001b		;;	111(3)	000 0	001=-3, 010=-2, 011=-1, 100=0, 101=1, 110=2, 111=3
	DB	00$110$001b		;;	111(3)	001 1
	DB	00$101$001b		;;	111(3)	010 2
	DB	00$100$001b		;;	111(3)	011 3
	DB	00$011$001b		;;	111(3)	100 4
	DB	00$010$001b		;;	111(3)	101 5
	DB	00$001$001b		;;	111(3)	110 6
	DB	00$111$000b		;;	111(3)	111 7		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
DS_lookup_3bit:
	movc	A, @A+PC
	ret					
	DB	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15	;; dummy
						;;
						; error		input	error
	DB	0001$0001b		;;0001(-7)	0000 0	0001= -7
	DB	1111$0000b		;;0001(-7)	0001 1	0010= -6
	DB	1110$0000b		;;0001(-7)	0010 2	0011= -5
	DB	1101$0000b		;;0001(-7)	0011 3	0100= -4
	DB	1100$0000b		;;0001(-7)	0100 4	0101= -3
	DB	1011$0000b		;;0001(-7)	0101 5	0110= -2
	DB	1010$0000b		;;0001(-7)	0110 6	0111= -1
	DB	1001$0000b		;;0001(-7)	0111 7	1000=  0
	DB	1000$0000b		;;0001(-7)	1000 8	1001=  1
	DB	0111$0000b		;;0001(-7)	1001 9	1010=  2
	DB	0110$0000b		;;0001(-7)	1010 10	1011=  3
	DB	0101$0000b		;;0001(-7)	1011 11	1100=  4
	DB	0100$0000b		;;0001(-7)	1100 12	1101=  5
	DB	0011$0000b		;;0001(-7)	1101 13	1110=  6
	DB	0010$0000b		;;0001(-7)	1110 14	1111=  7
	DB	0001$0000b		;;0001(-7)	1111 15	
	
	DB	0010$0001b		;;0010(-6)	0000 0	0001= -7
	DB	0001$0001b		;;0010(-6)	0001 1	0010= -6
	DB	1111$0000b		;;0010(-6)	0010 2	0011= -5
	DB	1110$0000b		;;0010(-6)	0011 3	0100= -4
	DB	1101$0000b		;;0010(-6)	0100 4	0101= -3
	DB	1100$0000b		;;0010(-6)	0101 5	0110= -2
	DB	1011$0000b		;;0010(-6)	0110 6	0111= -1
	DB	1010$0000b		;;0010(-6)	0111 7	1000=  0
	DB	1001$0000b		;;0010(-6)	1000 8	1001=  1
	DB	1000$0000b		;;0010(-6)	1001 9	1010=  2
	DB	0111$0000b		;;0010(-6)	1010 10	1011=  3
	DB	0110$0000b		;;0010(-6)	1011 11	1100=  4
	DB	0101$0000b		;;0010(-6)	1100 12	1101=  5
	DB	0100$0000b		;;0010(-6)	1101 13	1110=  6
	DB	0011$0000b		;;0010(-6)	1110 14	1111=  7
	DB	0010$0000b		;;0010(-6)	1111 15	

	DB	0011$0001b		;;0011(-5)	0000 0	0001= -7
	DB	0010$0001b		;;0011(-5)	0001 1	0010= -6
	DB	0001$0001b		;;0011(-5)	0010 2	0011= -5
	DB	1111$0000b		;;0011(-5)	0011 3	0100= -4
	DB	1110$0000b		;;0011(-5)	0100 4	0101= -3
	DB	1101$0000b		;;0011(-5)	0101 5	0110= -2
	DB	1100$0000b		;;0011(-5)	0110 6	0111= -1
	DB	1011$0000b		;;0011(-5)	0111 7	1000=  0
	DB	1010$0000b		;;0011(-5)	1000 8	1001=  1
	DB	1001$0000b		;;0011(-5)	1001 9	1010=  2
	DB	1000$0000b		;;0011(-5)	1010 10	1011=  3
	DB	0111$0000b		;;0011(-5)	1011 11	1100=  4
	DB	0110$0000b		;;0011(-5)	1100 12	1101=  5
	DB	0101$0000b		;;0011(-5)	1101 13	1110=  6
	DB	0100$0000b		;;0011(-5)	1110 14	1111=  7
	DB	0011$0000b		;;0011(-5)	1111 15		
	
	DB	0100$0001b		;;0100(-4)	0000 0	0001= -7
	DB	0011$0001b		;;0100(-4)	0001 1	0010= -6
	DB	0010$0001b		;;0100(-4)	0010 2	0011= -5
	DB	0001$0001b		;;0100(-4)	0011 3	0100= -4
	DB	1111$0000b		;;0100(-4)	0100 4	0101= -3
	DB	1110$0000b		;;0100(-4)	0101 5	0110= -2
	DB	1101$0000b		;;0100(-4)	0110 6	0111= -1
	DB	1100$0000b		;;0100(-4)	0111 7	1000=  0
	DB	1011$0000b		;;0100(-4)	1000 8	1001=  1
	DB	1010$0000b		;;0100(-4)	1001 9	1010=  2
	DB	1001$0000b		;;0100(-4)	1010 10	1011=  3
	DB	1000$0000b		;;0100(-4)	1011 11	1100=  4
	DB	0111$0000b		;;0100(-4)	1100 12	1101=  5
	DB	0110$0000b		;;0100(-4)	1101 13	1110=  6
	DB	0101$0000b		;;0100(-4)	1110 14	1111=  7
	DB	0100$0000b		;;0100(-4)	1111 15			
	
	DB	0101$0001b		;;0101(-3)	0000 0	0001= -7
	DB	0100$0001b		;;0101(-3)	0001 1	0010= -6
	DB	0011$0001b		;;0101(-3)	0010 2	0011= -5
	DB	0010$0001b		;;0101(-3)	0011 3	0100= -4
	DB	0001$0001b		;;0101(-3)	0100 4	0101= -3
	DB	1111$0000b		;;0101(-3)	0101 5	0110= -2
	DB	1110$0000b		;;0101(-3)	0110 6	0111= -1
	DB	1101$0000b		;;0101(-3)	0111 7	1000=  0
	DB	1100$0000b		;;0101(-3)	1000 8	1001=  1
	DB	1011$0000b		;;0101(-3)	1001 9	1010=  2
	DB	1010$0000b		;;0101(-3)	1010 10	1011=  3
	DB	1001$0000b		;;0101(-3)	1011 11	1100=  4
	DB	1000$0000b		;;0101(-3)	1100 12	1101=  5
	DB	0111$0000b		;;0101(-3)	1101 13	1110=  6
	DB	0110$0000b		;;0101(-3)	1110 14	1111=  7
	DB	0101$0000b		;;0101(-3)	1111 15		
	
	DB	0110$0001b		;;0110(-2)	0000 0	0001= -7
	DB	0101$0001b		;;0110(-2)	0001 1	0010= -6
	DB	0100$0001b		;;0110(-2)	0010 2	0011= -5
	DB	0011$0001b		;;0110(-2)	0011 3	0100= -4
	DB	0010$0001b		;;0110(-2)	0100 4	0101= -3
	DB	0001$0001b		;;0110(-2)	0101 5	0110= -2
	DB	1111$0000b		;;0110(-2)	0110 6	0111= -1
	DB	1110$0000b		;;0110(-2)	0111 7	1000=  0
	DB	1101$0000b		;;0110(-2)	1000 8	1001=  1
	DB	1100$0000b		;;0110(-2)	1001 9	1010=  2
	DB	1011$0000b		;;0110(-2)	1010 10	1011=  3
	DB	1010$0000b		;;0110(-2)	1011 11	1100=  4
	DB	1001$0000b		;;0110(-2)	1100 12	1101=  5
	DB	1000$0000b		;;0110(-2)	1101 13	1110=  6
	DB	0111$0000b		;;0110(-2)	1110 14	1111=  7
	DB	0110$0000b		;;0110(-2)	1111 15		
	
	DB	0111$0001b		;;0111(-1)	0000 0	0001= -7
	DB	0110$0001b		;;0111(-1)	0001 1	0010= -6
	DB	0101$0001b		;;0111(-1)	0010 2	0011= -5
	DB	0100$0001b		;;0111(-1)	0011 3	0100= -4
	DB	0011$0001b		;;0111(-1)	0100 4	0101= -3
	DB	0010$0001b		;;0111(-1)	0101 5	0110= -2
	DB	0001$0001b		;;0111(-1)	0110 6	0111= -1
	DB	1111$0000b		;;0111(-1)	0111 7	1000=  0
	DB	1110$0000b		;;0111(-1)	1000 8	1001=  1
	DB	1101$0000b		;;0111(-1)	1001 9	1010=  2
	DB	1100$0000b		;;0111(-1)	1010 10	1011=  3
	DB	1011$0000b		;;0111(-1)	1011 11	1100=  4
	DB	1010$0000b		;;0111(-1)	1100 12	1101=  5
	DB	1001$0000b		;;0111(-1)	1101 13	1110=  6
	DB	1000$0000b		;;0111(-1)	1110 14	1111=  7
	DB	0111$0000b		;;0111(-1)	1111 15		

	DB	1000$0001b		;;1000( 0)	0000 0	0001= -7
	DB	0111$0001b		;;1000( 0)	0001 1	0010= -6
	DB	0110$0001b		;;1000( 0)	0010 2	0011= -5
	DB	0101$0001b		;;1000( 0)	0011 3	0100= -4
	DB	0100$0001b		;;1000( 0)	0100 4	0101= -3
	DB	0011$0001b		;;1000( 0)	0101 5	0110= -2
	DB	0010$0001b		;;1000( 0)	0110 6	0111= -1
	DB	0001$0001b		;;1000( 0)	0111 7	1000=  0
	DB	1111$0000b		;;1000( 0)	1000 8	1001=  1
	DB	1110$0000b		;;1000( 0)	1001 9	1010=  2
	DB	1101$0000b		;;1000( 0)	1010 10	1011=  3
	DB	1100$0000b		;;1000( 0)	1011 11	1100=  4
	DB	1011$0000b		;;1000( 0)	1100 12	1101=  5
	DB	1010$0000b		;;1000( 0)	1101 13	1110=  6
	DB	1001$0000b		;;1000( 0)	1110 14	1111=  7
	DB	1000$0000b		;;1000( 0)	1111 15		

	DB	1001$0001b		;;1001( 1)	0000 0	0001= -7
	DB	1000$0001b		;;1001( 1)	0001 1	0010= -6
	DB	0111$0001b		;;1001( 1)	0010 2	0011= -5
	DB	0110$0001b		;;1001( 1)	0011 3	0100= -4
	DB	0101$0001b		;;1001( 1)	0100 4	0101= -3
	DB	0100$0001b		;;1001( 1)	0101 5	0110= -2
	DB	0011$0001b		;;1001( 1)	0110 6	0111= -1
	DB	0010$0001b		;;1001( 1)	0111 7	1000=  0
	DB	0001$0001b		;;1001( 1)	1000 8	1001=  1
	DB	1111$0000b		;;1001( 1)	1001 9	1010=  2
	DB	1110$0000b		;;1001( 1)	1010 10	1011=  3
	DB	1101$0000b		;;1001( 1)	1011 11	1100=  4
	DB	1100$0000b		;;1001( 1)	1100 12	1101=  5
	DB	1011$0000b		;;1001( 1)	1101 13	1110=  6
	DB	1010$0000b		;;1001( 1)	1110 14	1111=  7
	DB	1001$0000b		;;1001( 1)	1111 15		

	DB	1010$0001b		;;1010( 2)	0000 0	0001= -7
	DB	1001$0001b		;;1010( 2)	0001 1	0010= -6
	DB	1000$0001b		;;1010( 2)	0010 2	0011= -5
	DB	0111$0001b		;;1010( 2)	0011 3	0100= -4
	DB	0110$0001b		;;1010( 2)	0100 4	0101= -3
	DB	0101$0001b		;;1010( 2)	0101 5	0110= -2
	DB	0100$0001b		;;1010( 2)	0110 6	0111= -1
	DB	0011$0001b		;;1010( 2)	0111 7	1000=  0
	DB	0010$0001b		;;1010( 2)	1000 8	1001=  1
	DB	0001$0001b		;;1010( 2)	1001 9	1010=  2
	DB	1111$0000b		;;1010( 2)	1010 10	1011=  3
	DB	1110$0000b		;;1010( 2)	1011 11	1100=  4
	DB	1101$0000b		;;1010( 2)	1100 12	1101=  5
	DB	1100$0000b		;;1010( 2)	1101 13	1110=  6
	DB	1011$0000b		;;1010( 2)	1110 14	1111=  7
	DB	1010$0000b		;;1010( 2)	1111 15	

	DB	1011$0001b		;;1011( 3)	0000 0	0001= -7
	DB	1010$0001b		;;1011( 3)	0001 1	0010= -6
	DB	1001$0001b		;;1011( 3)	0010 2	0011= -5
	DB	1000$0001b		;;1011( 3)	0011 3	0100= -4
	DB	0111$0001b		;;1011( 3)	0100 4	0101= -3
	DB	0110$0001b		;;1011( 3)	0101 5	0110= -2
	DB	0101$0001b		;;1011( 3)	0110 6	0111= -1
	DB	0100$0001b		;;1011( 3)	0111 7	1000=  0
	DB	0011$0001b		;;1011( 3)	1000 8	1001=  1
	DB	0010$0001b		;;1011( 3)	1001 9	1010=  2
	DB	0001$0001b		;;1011( 3)	1010 10	1011=  3
	DB	1111$0000b		;;1011( 3)	1011 11	1100=  4
	DB	1110$0000b		;;1011( 3)	1100 12	1101=  5
	DB	1101$0000b		;;1011( 3)	1101 13	1110=  6
	DB	1100$0000b		;;1011( 3)	1110 14	1111=  7
	DB	1011$0000b		;;1011( 3)	1111 15	
 
	DB	1100$0001b		;;1100( 4)	0000 0	0001= -7
	DB	1011$0001b		;;1100( 4)	0001 1	0010= -6
	DB	1010$0001b		;;1100( 4)	0010 2	0011= -5
	DB	1001$0001b		;;1100( 4)	0011 3	0100= -4
	DB	1000$0001b		;;1100( 4)	0100 4	0101= -3
	DB	0111$0001b		;;1100( 4)	0101 5	0110= -2
	DB	0110$0001b		;;1100( 4)	0110 6	0111= -1
	DB	0101$0001b		;;1100( 4)	0111 7	1000=  0
	DB	0100$0001b		;;1100( 4)	1000 8	1001=  1
	DB	0011$0001b		;;1100( 4)	1001 9	1010=  2
	DB	0010$0001b		;;1100( 4)	1010 10	1011=  3
	DB	0001$0001b		;;1100( 4)	1011 11	1100=  4
	DB	1111$0000b		;;1100( 4)	1100 12	1101=  5
	DB	1110$0000b		;;1100( 4)	1101 13	1110=  6
	DB	1101$0000b		;;1100( 4)	1110 14	1111=  7
	DB	1100$0000b		;;1100( 4)	1111 15	
 
	DB	1101$0001b		;;1101( 5)	0000 0	0001= -7
	DB	1100$0001b		;;1101( 5)	0001 1	0010= -6
	DB	1011$0001b		;;1101( 5)	0010 2	0011= -5
	DB	1010$0001b		;;1101( 5)	0011 3	0100= -4
	DB	1001$0001b		;;1101( 5)	0100 4	0101= -3
	DB	1000$0001b		;;1101( 5)	0101 5	0110= -2
	DB	0111$0001b		;;1101( 5)	0110 6	0111= -1
	DB	0110$0001b		;;1101( 5)	0111 7	1000=  0
	DB	0101$0001b		;;1101( 5)	1000 8	1001=  1
	DB	0100$0001b		;;1101( 5)	1001 9	1010=  2
	DB	0011$0001b		;;1101( 5)	1010 10	1011=  3
	DB	0010$0001b		;;1101( 5)	1011 11	1100=  4
	DB	0001$0001b		;;1101( 5)	1100 12	1101=  5
	DB	1111$0000b		;;1101( 5)	1101 13	1110=  6
	DB	1110$0000b		;;1101( 5)	1110 14	1111=  7
	DB	1101$0000b		;;1101( 5)	1111 15	
   
	DB	1110$0001b		;;1110( 6)	0000 0	0001= -7
	DB	1101$0001b		;;1110( 6)	0001 1	0010= -6
	DB	1100$0001b		;;1110( 6)	0010 2	0011= -5
	DB	1011$0001b		;;1110( 6)	0011 3	0100= -4
	DB	1010$0001b		;;1110( 6)	0100 4	0101= -3
	DB	1001$0001b		;;1110( 6)	0101 5	0110= -2
	DB	1000$0001b		;;1110( 6)	0110 6	0111= -1
	DB	0111$0001b		;;1110( 6)	0111 7	1000=  0
	DB	0110$0001b		;;1110( 6)	1000 8	1001=  1
	DB	0101$0001b		;;1110( 6)	1001 9	1010=  2
	DB	0100$0001b		;;1110( 6)	1010 10	1011=  3
	DB	0011$0001b		;;1110( 6)	1011 11	1100=  4
	DB	0010$0001b		;;1110( 6)	1100 12	1101=  5
	DB	0001$0001b		;;1110( 6)	1101 13	1110=  6
	DB	1111$0000b		;;1110( 6)	1110 14	1111=  7
	DB	1110$0000b		;;1110( 6)	1111 15		
       
	DB	1111$0001b		;;1111( 7)	0000 0	0001= -7
	DB	1110$0001b		;;1111( 7)	0001 1	0010= -6
	DB	1101$0001b		;;1111( 7)	0010 2	0011= -5
	DB	1100$0001b		;;1111( 7)	0011 3	0100= -4
	DB	1011$0001b		;;1111( 7)	0100 4	0101= -3
	DB	1010$0001b		;;1111( 7)	0101 5	0110= -2
	DB	1001$0001b		;;1111( 7)	0110 6	0111= -1
	DB	1000$0001b		;;1111( 7)	0111 7	1000=  0
	DB	0111$0001b		;;1111( 7)	1000 8	1001=  1
	DB	0110$0001b		;;1111( 7)	1001 9	1010=  2
	DB	0101$0001b		;;1111( 7)	1010 10	1011=  3
	DB	0100$0001b		;;1111( 7)	1011 11	1100=  4
	DB	0011$0001b		;;1111( 7)	1100 12	1101=  5
	DB	0010$0001b		;;1111( 7)	1101 13	1110=  6
	DB	0001$0001b		;;1111( 7)	1110 14	1111=  7
	DB	1111$0000b		;;1111( 7)	1111 15	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
$include (BLHeliPgm.inc)				; Include source code for programming the ESC	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CSEG AT		19FDh
reset:
ljmp	pgm_start	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CSEG	AT		1C00h
$include (BLHeliBootLoad.inc)			; Include source code for bootloader
END
