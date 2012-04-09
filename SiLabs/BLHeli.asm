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
; Or if preferable, the code ESC can also be programmed to accept negative PWM as input signal.
; The code adapts itself to one of the three pwm frequencies
;
; The first lines of the software must be modified according to the chosen environment:
; - $include ("ESC".inc)		; Select ESC pinout
; - TAIL		EQU 0		; Choose main or tail mode
; 
;**** **** **** **** ****
; Revision history:
; - Rev1.0: Initial revision based upon BLHeil for AVR controllers
; - Rev2.0: Changed "Eeprom" initialization, layout and defaults
;           Various changes and improvements to comparator reading. Now using timer1 for time from pwm on/off
;           Beeps are made louder
;           Added programmable low voltage limit
;           Added programmable damped tail mode (only for 1S ESCs)
;           Added programmable motor rotation direction
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

;$include (DP_3A.inc)			; Select DP 3A pinout
;$include (Supermicro_3p5A.inc)	; Select Supermicro 3.5A pinout
$include (XP_3A.inc)			; Select XP 3A pinout
;$include (XP_7A.inc)			; Select XP 7A pinout
;$include (XP_12A.inc)			; Select XP 12A pinout
;$include (Turnigy6A.inc)	  	; Select Turnigy 6A pinout

TAIL 		EQU 	1			; Choose mode. Set to 0 for main motor and 1 for tail motor

;**** **** **** **** ****

TX_PGM		EQU	1			; Set to 0 to disable tx programming (reduces code size)

;**** **** **** **** ****
; TX programming defaults
DEFAULT_PGM_MAIN_P_GAIN 			EQU 4 ; 1=0.38 	2=0.50 	3=0.75 	4=1.00 	5=1.50
DEFAULT_PGM_MAIN_I_GAIN 			EQU 4 ; 1=0.38 	2=0.50 	3=0.75 	4=1.00 	5=1.50
DEFAULT_PGM_MAIN_GOVERNOR_MODE 	EQU 1 ; 1=Tx 		2=Arm 	3=Off
DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	EQU 2 ; 1=2.7V/cell	2=3V/cell	3=3.3V/cell
DEFAULT_PGM_MAIN_STARTUP_PWR 		EQU 3 ; 1=0.50 	2=0.75 	3=1.00 	4=1.25 	5=1.50
DEFAULT_PGM_MAIN_PWM_FREQ 		EQU 2 ; 1=High 	2=Low
DEFAULT_PGM_MAIN_DIRECTION_REV	EQU 1 ; 1=Normal 	2=Reversed
DEFAULT_PGM_MAIN_RCP_PWM_POL 		EQU 1 ; 1=Positive 	2=Negative

DEFAULT_PGM_TAIL_GAIN 			EQU 3 ; 1=0.75 	2=0.88 		3=1.00 	4=1.12 		5=1.25
DEFAULT_PGM_TAIL_IDLE_SPEED 		EQU 3 ; 1=Low 		2=MediumLow 	3=Medium 	4=MediumHigh 	5=High
DEFAULT_PGM_TAIL_STARTUP_PWR 		EQU 3 ; 1=0.50 	2=0.75 		3=1.00 	4=1.25 		5=1.50
IF DAMPED_TAIL_ENABLE == 1
DEFAULT_PGM_TAIL_PWM_FREQ	 	EQU 3 ; 1=High 	2=Low 		3=Damped
ELSE
DEFAULT_PGM_TAIL_PWM_FREQ	 	EQU 1 ; 1=High 	2=Low 		3=Damped
ENDIF
DEFAULT_PGM_TAIL_DIRECTION_REV	EQU 1 ; 1=Normal 	2=Reversed
DEFAULT_PGM_TAIL_RCP_PWM_POL 		EQU 1 ; 1=Positive 	2=Negative

;**** **** **** **** ****
; Constant definitions for main
IF TAIL == 0

GOV_SPOOLRATE		EQU	1	; Number of steps for governor requested pwm per 32ms

RCP_TIMEOUT		EQU	64	; Number of timer2L overflows (about 128us) before considering rc pulse lost
RCP_SKIP_RATE		EQU 	32	; Number of timer2L overflows (about 128us) before reenabling rc pulse detection
RCP_MIN			EQU 	0	; This is minimum RC pulse length
RCP_MAX			EQU 	250	; This is maximum RC pulse length
RCP_VALIDATE		EQU 	2	; Require minimum this pulse length to validate RC pulse
RCP_STOP			EQU 	1	; Stop motor at or below this pulse length
RCP_STOP_LIMIT		EQU 	1	; Stop motor if this many timer2H overflows (~32ms) are below stop limit

PWM_SETTLE		EQU 	50 	; PWM used when in start settling mode
PWM_STEPPER		EQU 	80 	; PWM used when in start stepper mode
PWM_AQUISITION		EQU 	80 	; PWM used when in start aquisition mode
PWM_INITIAL_RUN	EQU 	40 	; PWM used when in initial run mode 

COMM_TIME_RED		EQU 	5	; Fixed reduction (in us) for commutation wait (to account for fixed delays)
COMM_TIME_MIN		EQU 	5	; Minimum time (in us) for commutation wait

STEPPER_STEP_BEG		EQU 	3000	; ~3300 eRPM 
STEPPER_STEP_END		EQU 	1000	; ~10000 eRPM
STEPPER_STEP_DECREMENT	EQU 	5	; Amount to decrease stepper step by per commutation

AQUISITION_ROTATIONS	EQU 	2	; Number of rotations to do in the aquisition phase
DAMPED_RUN_ROTATIONS	EQU 	1	; Number of rotations to do in the damped run phase

; Constant definitions for tail
ELSE

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

STEPPER_STEP_BEG		EQU 	3000	; ~3300 eRPM 
STEPPER_STEP_END		EQU 	1000	; ~10000 eRPM
STEPPER_STEP_DECREMENT	EQU 	30	; Amount to decrease stepper step by per commutation

AQUISITION_ROTATIONS	EQU 	2	; Number of rotations to do in the aquisition phase
DAMPED_RUN_ROTATIONS	EQU 	1	; Number of rotations to do in the damped run phase

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

Requested_Pwm:		DS	1		; Requested pwm (from RC pulse value)
Governor_Req_Pwm:	DS	1		; Governor requested pwm (sets governor target)
Current_Pwm:		DS	1		; Current pwm
Current_Pwm_Limited:DS	1		; Current pwm that is limited (applied to the motor output)
Rcp_Prev_Edge_L:	DS	1		; RC pulse previous edge timer3 timestamp (lo byte)
Rcp_Prev_Edge_H:	DS	1		; RC pulse previous edge timer3 timestamp (hi byte)
Rcp_Timeout_Cnt:	DS	1		; RC pulse timeout counter (decrementing) 
Bit_Access_Int:	DS	1		; Variable at bit accessible address (for interrupts)
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

Flags1:			DS	1		; State flags
RCP_UPDATED		EQU 	0		; New RC pulse length value available
RCP_EDGE_NO		EQU 	1		; RC pulse edge no. 0=rising, 1=falling
RUN_PWM_OFF_DAMPED	EQU	2		; Pwm off damped mode running status
;				EQU 	3
;				EQU 	4
;				EQU 	5
;				EQU 	6
;				EQU 	7

Flags2:			DS	1		; State flags
RCP_PWM_FREQ_1KHZ	EQU 	0		; RC pulse pwm frequency is 1kHz
RCP_PWM_FREQ_2KHZ	EQU 	1		; RC pulse pwm frequency is 2kHz
RCP_PWM_FREQ_4KHZ	EQU 	2		; RC pulse pwm frequency is 4kHz
RCP_PWM_FREQ_8KHZ	EQU 	3		; RC pulse pwm frequency is 8kHz
PGM_PWM_OFF_DAMPED	EQU	4		; Programmed pwm off damped mode. Set when pfets shall be on in pwm_off period
PGM_PWM_HIGH_FREQ	EQU 	5		; Programmed pwm frequency. 0=low, 1=high
PGM_DIRECTION_REV	EQU 	6		; Programmed direction. 0=normal, 1=reversed
PGM_RCP_PWM_POL	EQU	7		; Programmed RC pulse pwm polarity. 0=positive, 1=negative

;**** **** **** **** ****
; RAM definitions
DSEG AT 30h					; Ram data segment 

Startup_Rot_Cnt:	DS	1		; Startup mode rotations counter (decrementing) 

Prev_Comm_L:		DS	1		; Previous commutation timer3 timestamp (lo byte)
Prev_Comm_H:		DS	1		; Previous commutation timer3 timestamp (hi byte)
Comm_Period4x_L:	DS	1		; Timer3 counts between the last 4 commutations (lo byte)
Comm_Period4x_H:	DS	1		; Timer3 counts between the last 4 commutations (hi byte)

Gov_Target_L:		DS	1		; Governor target (lo byte)
Gov_Target_H:		DS	1		; Governor target (hi byte)
Gov_Integral_L:	DS	1		; Governor integral error (lo byte)
Gov_Integral_H:	DS	1		; Governor integral error (hi byte)
Gov_Integral_X:	DS	1		; Governor integral error (ex byte)
Gov_Proportional_L:	DS	1		; Governor proportional error (lo byte)
Gov_Proportional_H:	DS	1		; Governor proportional error (hi byte)
Gov_Prop_Pwm:		DS	1		; Governor calculated new pwm based upon proportional error
Gov_Arm_Target:	DS	1		; Governor arm target value
Gov_Active:		DS	1		; Governor active (enabled and speed above minimum)

Wt_Advance_L:		DS	1		; Timer3 counts for commutation advance timing (lo byte)
Wt_Advance_H:		DS	1		; Timer3 counts for commutation advance timing (hi byte)
Wt_Zc_Scan_L:		DS	1		; Timer3 counts from commutation to zero cross scan (lo byte)
Wt_Zc_Scan_H:		DS	1		; Timer3 counts from commutation to zero cross scan (hi byte)
Wt_Comm_L:		DS	1		; Timer3 counts from zero cross to commutation (lo byte)
Wt_Comm_H:		DS	1		; Timer3 counts from zero cross to commutation (hi byte)
Wt_Stepper_Step_L:	DS	1		; Timer3 counts for stepper step (lo byte)
Wt_Stepper_Step_H:	DS	1		; Timer3 counts for stepper step (hi byte)

Rcp_PrePrev_Edge_L:	DS	1		; RC pulse pre previous edge pca timestamp (lo byte)
Rcp_PrePrev_Edge_H:	DS	1		; RC pulse pre previous edge pca timestamp (hi byte)
Rcp_Edge_L:		DS	1		; RC pulse edge pca timestamp (lo byte)
Rcp_Edge_H:		DS	1		; RC pulse edge pca timestamp (hi byte)
New_Rcp:			DS	1		; New RC pulse value in pca counts
Prev_Rcp_Pwm_Freq:	DS	1		; Previous RC pulse pwm frequency (used during pwm frequency measurement)
Curr_Rcp_Pwm_Freq:	DS	1		; Current RC pulse pwm frequency (used during pwm frequency measurement)
Rcp_Stop_Cnt:		DS	1		; Counter for RC pulses below stop value 

Pwm_Limit:		DS	1		; Maximum allowed pwm 
Pwm_Tail_Idle:		DS	1		; Tail idle speed pwm
Lipo_Cells:		DS	1		; Number of lipo cells 
Lipo_Adc_Limit_L:	DS	1		; Low voltage limit adc minimum (lo byte)
Lipo_Adc_Limit_H:	DS	1		; Low voltage limit adc minimum (hi byte)

Tx_Pgm_Func_No:	DS	1		; Function number when doing programming by tx
Tx_Pgm_Paraval_No:	DS	1		; Parameter value number when doing programming by tx
Tx_Pgm_Beep_No:	DS	1		; Beep number when doing programming by tx

Pgm_Gov_P_Gain:	DS	1		; Programmed governor P gain
Pgm_Gov_I_Gain:	DS	1		; Programmed governor I gain
Pgm_Gov_Mode:		DS	1		; Programmed governor mode
Pgm_Low_Voltage_Lim:DS	1		; Programmed low voltage limit
Pgm_Tail_Gain:		DS	1		; Programmed tail gain
Pgm_Tail_Idle:		DS	1		; Programmed tail idle speed
Pgm_Startup_Pwr:	DS	1		; Programmed startup power

DSEG AT 80h					
Tag_Temporary_Storage:	DS	48	; Temporary storage for tags when updating "Eeprom"

;**** **** **** **** ****
CSEG AT 1A00h			; "Eeprom" segment

EEPROM_FW_MAIN_REVISION	EQU 	2 	; Main revision of the firmware
EEPROM_FW_SUB_REVISION	EQU 	0 	; Sub revision of the firmware
EEPROM_LAYOUT_REVISION	EQU 	7 	; Revision of the EEPROM layout

Eep_FW_Main_Revision:	DB	EEPROM_FW_MAIN_REVISION			; EEPROM firmware main revision number
Eep_FW_Sub_Revision:	DB	EEPROM_FW_SUB_REVISION 			; EEPROM firmware sub revision number
Eep_Layout_Revision:	DB	EEPROM_LAYOUT_REVISION 			; EEPROM layout revision number
Eep_Pgm_Gov_P_Gain:		DB	DEFAULT_PGM_MAIN_P_GAIN 			; EEPROM copy of programmed governor P gain
Eep_Pgm_Gov_I_Gain:		DB	DEFAULT_PGM_MAIN_I_GAIN 			; EEPROM copy of programmed governor I gain
Eep_Pgm_Gov_Mode:		DB	DEFAULT_PGM_MAIN_GOVERNOR_MODE	; EEPROM copy of programmed governor mode
Eep_Pgm_Low_Voltage_Lim:	DB	DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM	; EEPROM copy of programmed low voltage limit
Eep_Pgm_Tail_Gain:		DB	DEFAULT_PGM_TAIL_GAIN 			; EEPROM copy of programmed tail gain
Eep_Pgm_Tail_Idle:		DB	DEFAULT_PGM_TAIL_IDLE_SPEED 		; EEPROM copy of programmed tail idle speed
IF TAIL == 0
Eep_Pgm_Startup_Pwr:	DB	DEFAULT_PGM_MAIN_STARTUP_PWR 		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:		DB	DEFAULT_PGM_MAIN_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction_Rev:	DB	DEFAULT_PGM_MAIN_DIRECTION_REV	; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:		DB	DEFAULT_PGM_MAIN_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:		DB	0A5h							; EEPROM initialized signature low byte
Eep_Initialized_H:		DB	05Ah							; EEPROM initialized signature high byte
ELSE
Eep_Pgm_Startup_Pwr:	DB	DEFAULT_PGM_TAIL_STARTUP_PWR 		; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:		DB	DEFAULT_PGM_TAIL_PWM_FREQ		; EEPROM copy of programmed pwm frequency
Eep_Pgm_Direction_Rev:	DB	DEFAULT_PGM_TAIL_DIRECTION_REV	; EEPROM copy of programmed rotation direction
Eep_Pgm_Input_Pol:		DB	DEFAULT_PGM_TAIL_RCP_PWM_POL		; EEPROM copy of programmed input polarity
Eep_Initialized_L:		DB	05Ah							; EEPROM initialized signature low byte
Eep_Initialized_H:		DB	0A5h							; EEPROM initialized signature high byte
ENDIF

CSEG AT 1A50h
Eep_ESC_MCU:			DB	"#BLHELI#F330#   "	; Project and MCU tag (16 Bytes)

CSEG AT 1A60h
Eep_Name:				DB 	"                "	; Name tag (16 Bytes)

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
	clr	A
	jb	Flags0.PWM_ON, ($+4)		; Is pwm on?
	jmp	@A+DPTR					; No - jump to pwm on routines. DPTR should be set to one of the pwm_nfet_on labels

	; Pwm off cycle. Set timer for coming off cycle length
	mov	TL0, Current_Pwm_Limited		; Load new timer setting
	; Clear pwm on flag
	clr	Flags0.PWM_ON	
	; Set full PWM (on all the time) if current PWM near max. This will give full power, but at the cost of a small "jump" in power
	clr	C
	mov	A, Current_Pwm_Limited		; Load current pwm
	subb	A, #250					; Above full pwm?
	jnc	t0_int_pwm_off_exit			; Yes - exit

	All_nFETs_Off 					; No - switch off all nfets
	; If damped operation, set all pmoses on in pwm_off
	jb	Flags1.RUN_PWM_OFF_DAMPED, ($+5)	; Damped operation?
	ajmp	t0_int_pwm_off_exit				; No - exit	

	; Delay to allow nFETs to go off before pFETs are turned on (only in damped mode)
	mov	A, #PFETON_DELAY
	djnz	ACC, $	
	All_pFETs_On 					; Switch on all pfets
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
	mov	A, #NFETON_DELAY
an_bp:
	ApFET_off
	CpFET_off
	djnz ACC,	an_bp
	BnFET_off 				; Switch nFETs
	AnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_anfet_cpfet_on:	; Pwm on cycle anfet on (bnfet off) and cpfet on (used in damped state 5)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #NFETON_DELAY
an_cp:
	ApFET_off
	BpFET_off
	djnz ACC,	an_cp
	BnFET_off					; Switch nFETs
	AnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_bnfet_cpfet_on:	; Pwm on cycle bnfet on (cnfet off) and cpfet on (used in damped state 4)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #NFETON_DELAY
bn_cp:
	BpFET_off
	ApFET_off
	djnz ACC,	bn_cp
	CnFET_off					; Switch nFETs
	BnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_bnfet_apfet_on:	; Pwm on cycle bnfet on (cnfet off) and apfet on (used in damped state 3)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #NFETON_DELAY
bn_ap:
	BpFET_off
	CpFET_off
	djnz ACC,	bn_ap
	CnFET_off					; Switch nFETs
	BnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_cnfet_apfet_on:	; Pwm on cycle cnfet on (anfet off) and apfet on (used in damped state 2)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #NFETON_DELAY
cn_ap:
	CpFET_off
	BpFET_off
	djnz ACC,	cn_ap
	AnFET_off					; Switch nFETs
	CnFET_on
	ajmp	t0_int_pwm_on_exit

pwm_cnfet_bpfet_on:	; Pwm on cycle cnfet on (anfet off) and bpfet on (used in damped state 1)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	mov	A, #NFETON_DELAY
cn_bp:
	CpFET_off
	ApFET_off
	djnz ACC,	cn_bp
	AnFET_off					; Switch nFETs
	CnFET_on
	ajmp	t0_int_pwm_on_exit

t0_int_pwm_on_exit:
	setb	Flags0.PWM_ON	; Set pwm on flag
	; Set timer for coming on cycle length
	mov 	A, Current_Pwm_Limited		; Load current pwm
	cpl	A						; cpl is 255-x
	mov	TL0, A					; Write start point for timer
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

	; Decrement timeout counter
	dec	Rcp_Timeout_Cnt			; Decrement
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

	mov	Rcp_Timeout_Cnt, #RCP_TIMEOUT	; Set timeout count to start value
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
IF TAIL == 1
	clr	C
	subb	A, #240			; 240 = (255/1.0625) Needs to be updated according to multiplication factor below		
	jc	t2_int_rcp_update_mult

	mov	A, #240			; Set requested pwm to max
	mov	Temp1, A		

ENDIF

t2_int_rcp_update_mult:	
IF TAIL == 1
	; Multiply by 1.0625 (optional adjustment gyro gain)
	swap	A			; After this "0.0625"
	anl	A, #0Fh
	add	A, Temp1
	mov	Temp1, A		
	; Adjust tail gain
	mov	Temp2, Pgm_Tail_Gain	
	cjne	Temp2, #3, ($+5)			; Is gain 1?
	ajmp	t2_int_pwm_min_run			; Yes - skip adjustment

	clr	C
	rrc	A			; After this "0.5"
	clr	C
	rrc	A			; After this "0.25"
	mov	Bit_Access_Int, Pgm_Tail_Gain	
	jb	Bit_Access_Int.0, t2_int_rcp_tail_corr		; Branch if bit 0 in gain is set

	clr	C
	rrc	A			; After this "0.125"

t2_int_rcp_tail_corr:
	jb	Bit_Access_Int.2, t2_int_rcp_tail_gain_pos	; Branch if bit 2 in gain is set

	xch	A, Temp1
	clr	C
	subb	A, Temp1					; Apply negative correction
	mov	Temp1, A
	ajmp	t2_int_pwm_min_run

t2_int_rcp_tail_gain_pos:
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
	subb	A, Pwm_Tail_Idle			; Is requested pwm lower than minimum?
	jnc	t2_int_pwm_update			; No - branch

	mov	A, Pwm_Tail_Idle			; Yes - limit pwm to Pwm_Tail_Idle	
	clr	C
	rlc	A						; Multiply by 2
	mov	Temp1, A

t2_int_pwm_update: 
	; Check if any startup mode flags are set
	mov	A, Flags0
	anl	A, #((1 SHL SETTLE_MODE)+(1 SHL STEPPER_MODE)+(1 SHL AQUISITION_MODE)+(1 SHL INITIAL_RUN_MODE))
	jnz	t2_int_pwm_exit			; Exit if any startup mode set (pwm controlled by set_startup_pwm)

	; Update requested_pwm
	mov	Requested_Pwm, Temp1		; Set requested pwm

	mov	Temp1, Pgm_Gov_Mode			; Governor mode?
	cjne	Temp1, #3, t2_int_pwm_exit	; Yes - branch

	; Update current pwm
	mov	Current_Pwm, Requested_Pwm
IF TAIL==1
	mov	Current_Pwm_Limited, Requested_Pwm
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
IF TAIL == 0
	mov	A, Pgm_Gov_Mode				; Governor target by arm mode?
	cjne	A, #2, t2h_int_rcp_gov_by_tx		; No - branch

	mov	Requested_Pwm, Gov_Arm_Target		; Yes - load arm target

t2h_int_rcp_gov_by_tx:
	clr	C
	mov	A, Governor_Req_Pwm
	subb	A, Requested_Pwm				; Is governor requested pwm equal to requested pwm?
	jz	t2h_int_rcp_exit;				; Yes - branch

	jc	t2h_int_rcp_gov_pwm_inc			; No - if lower then increment

	dec	Governor_Req_Pwm				; No - if higher then decrement
	ajmp	t2h_int_rcp_gov_pwm_exit

t2h_int_rcp_gov_pwm_inc:
	inc	Governor_Req_Pwm				; Increment

t2h_int_rcp_gov_pwm_exit:
	djnz	Temp1, t2h_int_rcp_gov_pwm		; If not number of steps processed - go back
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
	subb	A, #low(2880)				; If below 1440us, 1kHz pwm is assumed
	mov	A, Temp2
	subb	A, #high(2880)
	jnc	pca_int_restore_edge

	clr	A
	setb	ACC.RCP_PWM_FREQ_1KHZ
	mov	Temp4, A

pca_int_restore_edge:
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
	setb	Flags1.RCP_UPDATED		 	; Set updated flag
	jnb	Flags0.RCP_MEAS_PWM_FREQ, ($+5)	; Is measure RCP pwm frequency flag set?
	ajmp pca_int_exit				; Yes - exit

	Rcp_Int_Disable 				; Disable RC pulse interrupt

pca_int_exit:	; Exit interrupt routine	
	mov	Rcp_Skip_Cnt, #RCP_SKIP_RATE	; Load number of skips
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
	cpl	Flags2.PGM_DIRECTION_REV	; Toggle between using A fet and C fet
	clr	A
	BpFET_on			; BpFET on
	djnz	ACC, $		; Allow some time after pfet is turned on
	; Turn on nfet
	AnFET_on			; AnFET on
	mov	A, 64
	djnz	ACC, $		; 11µs on
	; Turn off nfet
	AnFET_off			; AnFET off
	mov	A, 64
	djnz	ACC, $		; 11µs off
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
	cjne	A, #3, governor_speed_check	; Yes
	ajmp	calc_governor_target_exit	; No

governor_speed_check:
	; Check speed (do not run governor for low speeds)
	clr	C
	mov	A, Comm_Period4x_L
	subb	A, #00h
	mov	A, Comm_Period4x_H
	subb	A, #05h
	jc	governor_target_calc		; If speed above min limit (~62500 eRPM) - run governor

	mov	Current_Pwm, Requested_Pwm	; Set current pwm to requested
	clr	A
	mov	Gov_Target_L, A			; Set target to zero
	mov	Gov_Target_H, A
	mov	Gov_Integral_L, A			; Set integral to zero
	mov	Gov_Integral_H, A
	mov	Gov_Integral_X, A
	mov	Gov_Active, A
	ajmp	calc_governor_target_exit

governor_target_calc:
	; Governor calculations
	mov	A, Governor_Req_Pwm		; Load governor requested pwm
	cpl	A					; Calculate 255-pwm (invert pwm) 
	; Calculate comm period target (1 + 2*((255-Requested_Pwm)/256) - 0.25)
	rlc	A					; Msb to carry
	rlc	A					; To bit0
	mov	Temp2, A				; Now 2 lsbs are valid for H
	rrc	A					
	mov	Temp1, A				; Now 6 msbs are valid for L
	mov	A, Temp2
	anl	A, #01h				; Calculate H byte
	inc	A
	mov	Temp2, A
	mov	A, Temp1
	anl	A, #0FEh				; Calculate L byte
	clr	C
	subb	A, #40h				; Subtract 0.25
	mov	Temp1, A
	mov	A, Temp2
	subb	A, #0
	mov	Temp2, A
	; Store governor target
	mov	Gov_Target_L, Temp1
	mov	Gov_Target_H, Temp2
	; Set governor active
	mov	Gov_Active, #1
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
	jnb	ACC.0, ($+5)				; Is lsb 1?
	ajmp	calc_governor_prop_corr_15	; Yes - go to multiply by 1.5	

	clr	C
	mov	A, Pgm_Gov_P_Gain
	subb	A, #4					; Is proportional gain 1?
	jz	governor_limit_prop_corr		; Yes - branch

	mov	A, Temp2					; Gain is 0.5 - divide by 2
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
	mov	A, Pgm_Gov_P_Gain
	clr	C
	subb	A, #5					; Is proportional gain 1.5?
	jz	governor_limit_prop_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	mov	A, Pgm_Gov_P_Gain
	clr	C
	subb	A, #3					; Is proportional gain 0.75?
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
	jnb	ACC.0, ($+5)				; Is lsb 1?
	ajmp	calc_governor_int_corr_15	; Yes - go to multiply by 1.5	

	clr	C
	mov	A, Pgm_Gov_I_Gain
	subb	A, #4					; Is integral gain 1?
	jz	governor_limit_int_corr		; Yes - branch

	mov	A, Temp2					; Gain is 0.5 - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	ajmp	governor_limit_int_corr

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
	mov	A, Pgm_Gov_I_Gain
	clr	C
	subb	A, #5					; Is integral gain 1.5?
	jz	governor_limit_int_corr		; Yes - branch

	mov	A, Temp2					; No - divide by 2
	mov	C, ACC.7
	rrc	A
	mov	Temp2, A
	mov	A, Temp1
	rrc	A
	mov	Temp1, A
	mov	A, Pgm_Gov_I_Gain
	clr	C
	subb	A, #3					; Is integral gain 0.75?
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
	ajmp	governor_apply_int_corr

governor_check_int_corr_limit_pos:
	clr	C
	mov	A, Temp1
	subb	A, #0FFh					; Is integral too positive?
	mov	A, Temp2
	subb	A, #00h
	jnc	governor_limit_int_corr_pos	; Yes - limit
	ajmp	governor_apply_int_corr

governor_limit_int_corr_pos:
	mov	Temp1, #0FFh				; Limit to max positive (2's complement)
	mov	Temp2, #00h
	ajmp	governor_apply_int_corr

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
	ajmp	governor_store_int_corr		; No - store correction

governor_corr_int_min_pwm:
	mov	Temp1, #1					; Load minimum pwm
	ajmp	governor_store_int_corr

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
	ajmp	governor_store_int_corr		; No - store correction

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
IF TAIL == 0
	Start_Adc 
	; Wait for ADC conversion to complete
	Get_Adc_Status 
	jb	AD0BUSY, measure_lipo_cells
	; Read ADC result
	Read_Adc_Result
	; Stop ADC
	Stop_Adc
	; Set 1S
	mov	Lipo_Adc_Limit_L, #ADC_LIMIT_L
	mov	Lipo_Adc_Limit_H, #ADC_LIMIT_H
	mov	Lipo_Cells, #1
	; Check voltage against 2S limit
	clr	C
	mov	A, #ADC_LIMIT_L		; Multiply limit by 2
	rlc	A
	mov	Temp3, A
	mov	A, #ADC_LIMIT_H	
	rlc	A
	mov	Temp4, A
	clr	C
	mov	A, Temp1
	subb	A, Temp3				; Voltage above limit?
	mov	A, Temp2
	subb A, Temp4
	jc	measure_lipo_adjust		; No - branch

	mov	Lipo_Adc_Limit_L, Temp3	; Set 2S
	mov	Lipo_Adc_Limit_H, Temp4
	mov	Lipo_Cells, #2
	; Check voltage against 3S limit
	mov	A, Temp3
	add	A, #ADC_LIMIT_L		; Add limit
	mov	Temp3, A
	mov	A, Temp4
	addc	A, #ADC_LIMIT_H
	mov	Temp4, A
	clr	C
	mov	A, Temp1
	subb	A, Temp3				; Voltage above limit?
	mov	A, Temp2
	subb A, Temp4
	jc	measure_lipo_adjust		; No - branch

	mov	Lipo_Adc_Limit_L, Temp3	; Set 3S
	mov	Lipo_Adc_Limit_H, Temp4
	mov	Lipo_Cells, #3

measure_lipo_adjust:
	mov	Temp3, Lipo_Adc_Limit_L
	mov	Temp4, Lipo_Adc_Limit_H
	; Calculate 9.375%
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
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1	
	rrc	A
	mov	Temp1, A			; After this 12.5%
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp2, A
	mov	A, Temp1	
	rrc	A
	mov	Temp1, A			; After this 6.25%
	clr	C
	mov	A, Temp2
	rrc	A
	mov	Temp6, A
	mov	A, Temp1	
	rrc	A
	mov	Temp5, A			; After this 3.125%
	mov	A, Temp1			; Add 6.25% and 3.125%
	add	A, Temp5	
	mov	Temp1, A
	mov	A, Temp2
	addc	A, Temp6
	mov	Temp2, A
	; Add or subtract
	clr	C
	mov	A, Pgm_Low_Voltage_Lim
	subb	A, #1
	jz	measure_lipo_reduce	
	clr	C
	mov	A, Pgm_Low_Voltage_Lim
	subb	A, #3
	jz	measure_lipo_increase	
	ajmp	measure_lipo_exit

measure_lipo_reduce:
	clr	C
	mov	A, Temp3
	subb	A, Temp1
	mov	Temp3, A
	mov	A, Temp4
	subb	A, Temp2
	mov	Temp4, A
	mov	Lipo_Adc_Limit_L, Temp3
	mov	Lipo_Adc_Limit_H, Temp4
	ajmp	measure_lipo_exit

measure_lipo_increase:
	mov	A, Temp3
	add	A, Temp1
	mov	Temp3, A
	mov	A, Temp4
	addc	A, Temp2
	mov	Temp4, A
	mov	Lipo_Adc_Limit_L, Temp3
	mov	Lipo_Adc_Limit_H, Temp4

measure_lipo_exit:
ENDIF
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
IF TAIL == 0
	Start_Adc 
ENDIF
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Check power supply voltage and limit power
;
; No assumptions
;
; Used to limit main motor power in order to maintain the required voltage
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
check_voltage_and_limit_power:
IF TAIL == 0
	; Wait for ADC conversion to complete
	Get_Adc_Status 
	jb	AD0BUSY, check_voltage_and_limit_power
	; Read ADC result
	Read_Adc_Result
	; Stop ADC
	Stop_Adc
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
	jz	check_voltage_lim	; If limit zero - branch

	dec	Pwm_Limit			; Decrement limit
	ajmp	check_voltage_lim

check_voltage_good:
	; Increase pwm limit
	mov  A, Pwm_Limit
	cpl	A			
	jz	check_voltage_lim	; If limit max - branch

	inc	Pwm_Limit			; Increment limit

check_voltage_lim:
	mov	Temp1, Pwm_Limit	; Set limit
	clr	C
	mov	A, Current_Pwm
	subb	A, Temp1
	jnc	check_voltage_exit	; If current pwm above limit - branch and limit	

	mov	Temp1, Current_Pwm	; Set current pwm (no limiting)

check_voltage_exit:
	mov  Current_Pwm_Limited, Temp1
ENDIF
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
	mov	Temp2, Pgm_Startup_Pwr	
	cjne	Temp2, #3, ($+5)			; Is gain 1?
	ajmp	startup_pwm_set_pwm			; Yes - skip adjustment

	clr	C
	rrc	A			; After this "0.5"
	mov	Bit_Access_Int, Pgm_Startup_Pwr	
	jb	Bit_Access_Int.0, startup_pwm_corr		; Branch if bit 0 in gain is set

	clr	C
	rrc	A			; After this "0.25"

startup_pwm_corr:
	jb	Bit_Access_Int.2, startup_pwm_gain_pos	; Branch if bit 2 in gain is set

	xch	A, Temp1
	clr	C
	subb	A, Temp1					; Apply negative correction
	mov	Temp1, A
	ajmp	startup_pwm_set_pwm

startup_pwm_gain_pos:
	add	A, Temp1					; Apply positive correction
	mov	Temp1, A
	jnc	startup_pwm_set_pwm			; Above max?

	mov	A, #0FFh					; Yes - limit
	mov	Temp1, A

startup_pwm_set_pwm:
	; Set pwm variables
	mov	Requested_Pwm, Temp1		; Update requested pwm
	mov	Current_Pwm, Temp1			; Update current pwm
	mov	Current_Pwm_Limited, Temp1	; Update limited version of current pwm

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
	mov	Wt_Stepper_Step_L, #low(STEPPER_STEP_BEG SHL 1)	; Initialize stepper step time 
	mov	Wt_Stepper_Step_H, #high(STEPPER_STEP_BEG SHL 1)
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
	ajmp	read_timer

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
	jnc	store_times			; Check that result is still above minumum

load_min_time:
	mov	Temp1, #(COMM_TIME_MIN SHL 1)
	clr	A
	mov	Temp2, A

store_times:
	mov	Wt_Comm_L, Temp1		; Now commutation time (~60°) divided by 4 (~15°)
	mov	Wt_Comm_H, Temp2
	mov	Wt_Advance_L, Temp1		; New commutation advance time (15°)
	mov	Wt_Advance_H, Temp2
	clr	C
	mov	A, Temp2
	rrc	A					; Divide by 2
	mov	Temp2, A
	mov	A, Temp1
	rrc	A					
	mov	Temp1, A
	mov	Wt_Zc_Scan_L, Temp1		; Use this value for zero cross scan delay (7.5°)
	mov	Wt_Zc_Scan_H, Temp2
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
pwm_wait_on_low:
	setb	EA						; Enable interrupts
	nop							; Wait for interrupt to be caught
	nop
	clr	EA						; Disable interrupts
	jnb	Flags1.RUN_PWM_OFF_DAMPED, pwm_wait_low		; Is it damped operation?
	jnb	Flags0.PWM_ON, pwm_wait_on_low			; Yes - Go back if not pwm on

pwm_wait_low:						; Wait some cycles after pwm has been switched on (motor wire electrical settling)
	mov	Temp1, #13
	jb	Flags2.PGM_PWM_HIGH_FREQ, ($+5)
	mov	Temp1, #4
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
pwm_wait_on_high:
	setb	EA						; Enable interrupts
	nop							; Wait for interrupt to be caught
	nop
	clr	EA						; Disable interrupts
	jnb	Flags1.RUN_PWM_OFF_DAMPED, pwm_wait_high	; Is it damped operation?
	jnb	Flags0.PWM_ON, pwm_wait_on_high			; Yes - Go back if not pwm on

pwm_wait_high:						; Wait some cycles after pwm has been switched on (motor wire electrical settling)
	mov	Temp1, #13
	jb	Flags2.PGM_PWM_HIGH_FREQ, ($+5)
	mov	Temp1, #4
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
	jnb	Flags1.RUN_PWM_OFF_DAMPED, ($+6)
	mov	DPTR, #pwm_cnfet_apfet_on	
	BpFET_off					; Bp off
	ApFET_on					; Ap on
	Set_Comp_Phase_B 			; Set comparator to phase B
	setb	EA					; Enable all interrupts
	ret

comm2comm3:	
	clr 	EA					; Disable all interrupts
	jnb	Flags1.RUN_PWM_OFF_DAMPED, ($+6)
	mov	DPTR, #pwm_bnfet_apfet_on
	jb	Flags1.RUN_PWM_OFF_DAMPED, ($+6)
	mov	DPTR, #pwm_bfet_on	
	CnFET_off					; Cn off
	jnb	Flags0.PWM_ON, comm23_cp	; Is pwm on?
	BnFET_on					; Yes - Bn on
comm23_cp:
	Set_Comp_Phase_C 			; Set comparator to phase C
	setb	EA					; Enable all interrupts
	ret

comm3comm4:	
	clr 	EA					; Disable all interrupts
	jnb	Flags1.RUN_PWM_OFF_DAMPED, ($+6)
	mov	DPTR, #pwm_bnfet_cpfet_on
	ApFET_off					; Ap off
	CpFET_on					; Cp on
	Set_Comp_Phase_A 			; Set comparator to phase A
	setb	EA					; Enable all interrupts
	ret

comm4comm5:	
	clr 	EA					; Disable all interrupts
	jnb	Flags1.RUN_PWM_OFF_DAMPED, ($+6)
	mov	DPTR, #pwm_anfet_cpfet_on
	jb	Flags1.RUN_PWM_OFF_DAMPED, ($+6)
	mov	DPTR, #pwm_afet_on
	BnFET_off					; Bn off
	jnb	Flags0.PWM_ON, comm45_cp	; Is pwm on?
	AnFET_on					; Yes - An on
comm45_cp:
	Set_Comp_Phase_B 			; Set comparator to phase B
	setb	EA					; Enable all interrupts
	ret

comm5comm6:	
	clr 	EA					; Disable all interrupts
	jnb	Flags1.RUN_PWM_OFF_DAMPED, ($+6)
	mov	DPTR, #pwm_anfet_bpfet_on
	CpFET_off					; Cp off
	BpFET_on					; Bp on
	Set_Comp_Phase_C 			; Set comparator to phase C
	setb	EA					; Enable all interrupts
	ret

comm6comm1:	
	clr 	EA					; Disable all interrupts
	jnb	Flags1.RUN_PWM_OFF_DAMPED, ($+6)
	mov	DPTR, #pwm_cnfet_bpfet_on
	jb	Flags1.RUN_PWM_OFF_DAMPED, ($+6)
	mov	DPTR, #pwm_cfet_on
	AnFET_off					; An off
	jnb	Flags0.PWM_ON, comm61_cp	; Is pwm on?
	CnFET_on					; Yes - Cn on
comm61_cp:
	Set_Comp_Phase_A 			; Set comparator to phase A
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
	subb	A, #low(STEPPER_STEP_END SHL 1)	; Minimum STEPPER_STEP_END
	mov	A, Wt_Stepper_Step_H
	subb	A, #high(STEPPER_STEP_END SHL 1)	
	jnc	decrement_step					; Branch if same or higher than minimum
	ret

decrement_step:
	clr	C
	mov	A, Wt_Stepper_Step_L
	subb	A, #low(STEPPER_STEP_DECREMENT SHL 1)		
	mov	Temp1, A
	mov	A, Wt_Stepper_Step_H
	subb	A, #high(STEPPER_STEP_DECREMENT SHL 1)		
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
IF TAIL == 0
	mov	Pgm_Gov_P_Gain, #DEFAULT_PGM_MAIN_P_GAIN
	mov	Pgm_Gov_I_Gain, #DEFAULT_PGM_MAIN_I_GAIN
	mov	Pgm_Gov_Mode, #DEFAULT_PGM_MAIN_GOVERNOR_MODE
	mov	Pgm_Low_Voltage_Lim, #DEFAULT_PGM_MAIN_LOW_VOLTAGE_LIM
	mov	Pgm_Startup_Pwr, #DEFAULT_PGM_MAIN_STARTUP_PWR
	setb	Flags2.PGM_PWM_HIGH_FREQ
	mov	A, #DEFAULT_PGM_MAIN_PWM_FREQ
	jnb	ACC.1, ($+5)
	clr	Flags2.PGM_PWM_HIGH_FREQ
	clr	Flags2.PGM_DIRECTION_REV
	mov	A, #DEFAULT_PGM_MAIN_DIRECTION_REV
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_DIRECTION_REV
	clr	Flags2.PGM_RCP_PWM_POL
	mov	A, #DEFAULT_PGM_MAIN_RCP_PWM_POL
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_RCP_PWM_POL
ELSE
	mov	Pgm_Tail_Gain, #DEFAULT_PGM_TAIL_GAIN
	mov	Pgm_Tail_Idle, #DEFAULT_PGM_TAIL_IDLE_SPEED
	mov	Pgm_Startup_Pwr, #DEFAULT_PGM_TAIL_STARTUP_PWR
	clr	Flags2.PGM_PWM_HIGH_FREQ
	mov	A, #DEFAULT_PGM_TAIL_PWM_FREQ
	jnb	ACC.0, ($+5)
	setb	Flags2.PGM_PWM_HIGH_FREQ
	clr	Flags2.PGM_PWM_OFF_DAMPED
	clr	C
	mov	A, #DEFAULT_PGM_TAIL_PWM_FREQ
	subb	A, #3
	jc	($+4)
	setb	Flags2.PGM_PWM_OFF_DAMPED
	clr	Flags2.PGM_DIRECTION_REV
	mov	A, #DEFAULT_PGM_TAIL_DIRECTION_REV
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_DIRECTION_REV
	clr	Flags2.PGM_RCP_PWM_POL
	mov	A, #DEFAULT_PGM_TAIL_RCP_PWM_POL
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_RCP_PWM_POL
	mov	Pgm_Gov_Mode, #3
ENDIF
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
	; Switch power off
	call	switch_power_off
	; Set timer clocks
	mov	CKCON, #01h		; Timer0 set for clk/4 (22kHz pwm)
	jb	Flags2.PGM_PWM_HIGH_FREQ, ($+6)
	mov	CKCON, #00h		; Timer0 set for clk/12 (8kHz pwm)
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
	setb	EA				; Enable all interrupts
	; Measure number of lipo cells
	call Measure_Lipo_Cells			; Measure number of lipo cells
	; Initialize rc pulse
	Rcp_Int_Enable		 			; Enable interrupt
	Rcp_Clear_Int_Flag 				; Clear interrupt flag
	clr	Flags1.RCP_EDGE_NO			; Set first edge flag
	call wait200ms

	; Validate RC pulse and measure PWM frequency
	setb	Flags0.RCP_MEAS_PWM_FREQ 		; Set measure pwm frequency flag
validate_rcp_start:	
	mov	Temp3, #5						; Number of pulses to validate
validate_rcp_loop:	
	call wait3ms						; Wait for next pulse (NB: Uses Temp1/2!) 
	jnb	Flags1.RCP_UPDATED, $			; Wait for an updated RC pulse

	mov	A, New_Rcp					; Load value
	clr	C
	subb	A, #RCP_VALIDATE				; Higher than validate level?
	jc	validate_rcp_start				; No - start over
	mov	A, Flags2						; Check pwm frequency flags
	anl	A, #((1 SHL RCP_PWM_FREQ_1KHZ)+(1 SHL RCP_PWM_FREQ_2KHZ)+(1 SHL RCP_PWM_FREQ_4KHZ)+(1 SHL RCP_PWM_FREQ_8KHZ))
	mov	Prev_Rcp_Pwm_Freq, Curr_Rcp_Pwm_Freq		; Store as previous flags for next pulse 
	mov	Curr_Rcp_Pwm_Freq, A					; Store current flags for next pulse 
	cjne	A, Prev_Rcp_Pwm_Freq, validate_rcp_start	; Go back if new flags not same as previous

	djnz	Temp3, validate_rcp_loop					; Go back if not required number of pulses seen

	clr	Flags0.RCP_MEAS_PWM_FREQ 		; Clear measure pwm frequency flag
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
	jmp program_by_tx			; Yes - start programming mode entry
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

	; Armed and waiting for power on
wait_for_power_on:
	call wait3ms
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_STOP 			; Higher than stop?
	jc	wait_for_power_on		; No - start over

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
	mov	Pwm_Tail_Idle, Pgm_Tail_Idle		; Set tail idle pwm to programmed value
	jnb	Flags2.PGM_DIRECTION_REV, ($+5)	; If reverse - Increment tail idle by 1
	mov	Gov_Target_L, A		; Set target to zero
	mov	Gov_Target_H, A
	mov	Gov_Integral_L, A		; Set integral to zero
	mov	Gov_Integral_H, A
	mov	Gov_Integral_X, A
	mov	Gov_Active, A
	mov	Flags0, A				; Clear flags0
	mov	Rcp_Stop_Cnt, A		; Set RC pulse stop count to zero
	call initialize_all_timings	; Initialize timing

;stsk
setb	Flags1.RUN_PWM_OFF_DAMPED	; Set damped operation
call comm1comm2				; Initialize commutation
call comm2comm3				; Initialize commutation
runbrushed:
call wait1ms
clr	C
mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter value
subb	A, #RCP_STOP_LIMIT			; Is number of stop RC pulses above limit?
jc	runbrushed
jmp	run_to_wait_for_power_on		; Yes, go back to wait for poweron

	;**** **** **** **** ****
	; Settle mode beginning
	;**** **** **** **** **** 
	setb	Flags1.RUN_PWM_OFF_DAMPED	; Set damped operation
	setb	Flags0.SETTLE_MODE			; Set motor start settling mode flag
	call set_startup_pwm
	call comm6comm1				; Initialize commutation
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
	call wait10ms					; Settle rotor
	call comm5comm6
	call wait3ms				
	call wait1ms			
	clr	Flags0.SETTLE_MODE			; Clear settling mode flag
	setb	Flags0.STEPPER_MODE			; Set motor start stepper mode flag
	call set_startup_pwm

	;**** **** **** **** ****
	; Stepper mode beginning
	;**** **** **** **** **** 
stepper_rot_beg:
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
	subb	A, #low(STEPPER_STEP_END SHL 1)	; Minimum STEPPER_STEP_END
	mov	A, Wt_Stepper_Step_H
	subb	A, #high(STEPPER_STEP_END SHL 1)
	jc	stepper_rot_exit			; Branch if lower than minimum
	; Wait for step
	call stepper_timer_wait
	jmp	stepper_rot_beg			; Next rotation

stepper_rot_exit:
	; Set aquisition mode
	clr	Flags0.STEPPER_MODE			; Clear motor start stepper mode flag
	setb	Flags0.AQUISITION_MODE		; Set aquisition mode flag
	call set_startup_pwm
	; Set aquisition rotation count
	mov	Startup_Rot_Cnt, #AQUISITION_ROTATIONS
	; Wait for step
	call stepper_timer_wait			; As the last part of stepper mode
	
	;**** **** **** **** ****
	; Aquisition mode beginning
	;**** **** **** **** **** 
aquisition_rot_beg:
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
	jmp	aquisition_rot_beg		; Next rotation

aquisition_rot_exit:
	clr	Flags0.AQUISITION_MODE	; Clear aquisition mode flag
	setb	Flags0.INITIAL_RUN_MODE	; Set initial run mode flag
	call set_startup_pwm
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
	; Check number of aquisition rotations
	jz damped_transition			; Branch if counter is zero

	mov	Startup_Rot_Cnt, A			; No - store counter
	jmp damped_run1				; Continue to run damped



damped_transition:
	jb	Flags2.PGM_PWM_OFF_DAMPED, run1	; If damped tail is programmed - Branch

	; Transition from damped to non-damped
	clr	EA					; Disable interrupts
	clr	Flags1.RUN_PWM_OFF_DAMPED; Clear damped flag
	All_pFETs_Off 				; Turn off all pfets
	BpFET_on					; Bp on
	mov	DPTR, #pwm_cfet_on		; Set DPTR register to desired pwm_nfet_on label		
	setb	EA					; Enable interrupts

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
	call check_voltage_and_limit_power
	call wait_for_comm
	call comm6comm1
	call calc_next_comm_timing
	call wait_advance_timing
	call calc_new_wait_times
	call wait_before_zc_scan	

	clr	Flags0.INITIAL_RUN_MODE		; Clear initial run mode flag

	clr	C
	mov	A, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	subb	A, #RCP_STOP_LIMIT			; Is number of stop RC pulses above limit?
	jnc	run_to_wait_for_power_on		; Yes, go back to wait for poweron

	clr	C
	mov	A, Comm_Period4x_H			; Is Comm_Period4x more than 32ms (~1220 eRPM)?
	subb	A, #0F0h
	jnc	run_to_wait_for_power_on		; Yes - go back to motor start
	jmp	run1						; Go back to run 1

run_to_wait_for_power_on:	
	call switch_power_off
	clr	A
	mov	Requested_Pwm, A		; Set requested pwm to zero
	mov	Governor_Req_Pwm, A		; Set governor requested pwm to zero
	mov	Current_Pwm, A			; Set current pwm to zero
	mov	Current_Pwm_Limited, A	; Set limited current pwm to zero
IF TAIL == 1
	jmp	wait_for_power_on		; Tail - Go back to wait for power on
ELSE
	jmp	validate_rcp_start		; Main - Go back to validate RC pulse
ENDIF



END