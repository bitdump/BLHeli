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
; This software is intended for AVR 8bit controllers in a micro heli environment.
;
; The software was inspired by and started from from Bernard Konze's BLMC: http://home.versanet.de/~b-konze/blc_6a/blc_6a.htm
; And also Simon Kirby's TGY: https://github.com/sim-/tgy
;
; This file is best viewed with tab width set to 5
;
; The input signal can be positive 1kHz, 2kHz, 4kHz or 8kHz PWM (taken from the "resistor tap" on mCPx)
; The code adapts itself to one of the three pwm frequencies
;
; The first lines of the software must be modified according to the chosen environment:
; - .include "ESC".inc		; Select ESC pinout
; - .equ	TAIL	= 0			; Choose main or tail mode
; - .equ	ICP  = 0			; Choose INT0 or ICP1 as input pin (ESC boards are wired for INT0). Feigao does not support ICP1
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
;
;**** **** **** **** ****
; 4/8K Bytes of In-System Self-Programmable Flash
; 256/512 Bytes EEPROM
; 512/1K Bytes Internal SRAM
;
;**** **** **** **** ****
; Timer 0 (1us counts) always counts up and is used for
; - RC pulse timeout and skip counts
; Timer 1 (1us counts) always counts up and is used for
; - RC pulse measurement (via external interrupt 0 or input capture pin)
; - Commutation timing (via output compare register A interrupt)
; Timer 2 (125ns counts) always counts up and is used for
; - PWM generation
;
;**** **** **** **** ****
; Interrupt handling
; The Atmega8 disables all interrupts when entering an interrupt routine,
; and enables them again when exiting. Thereby disabling nested interrupts.
; - Interrupts are disabled during beeps, to avoid interference from interrupts
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

;.include "WalkeraWST10LT.inc"		; Select Walkera LT pinout (INT0 or ICP1 input)
;.include "Feigao6.inc"			; Select Feigao 6A pinout (INT0 input only!!!)
;.include "HC5A1SA8.inc"			; Select HobbyCity 5A 1S pinout with Atmega8 (INT0 or ICP1 input)
;.include "HC5A1SA48V.inc"		; Select HobbyCity 5A 1S pinout with Atmega48V (INT0 input only!!!)
;.include "tail.inc"			; Set to tail ESC
; include "main.inc"			; Set to main ESC

;.equ	ICP  = 1					; Choose input pin. Set to 0 for INT0 (pin32) and 1 for ICP1 (pin12)

;**** **** **** **** ****

.equ	TX_PGM	= 1				; Set to 0 to disable tx programming (reduces code size)

;**** **** **** **** ****
; Constant definitions for main
.if TAIL == 0

.equ GOV_SPOOLRATE	= 2		; Number of steps for governor requested pwm per 65ms

.equ	RCP_TIMEOUT	= 32		; Number of timer0 overflows (about 256us) before considering rc pulse lost
.equ	RCP_SKIP_RATE	= 16		; Number of timer0 overflows (about 256us) before reenabling rc pulse detection
.equ	RCP_MIN		= 0		; This is minimum RC pulse length
.equ	RCP_MAX		= 250	; This is maximum RC pulse length
.equ	RCP_VALIDATE	= 2		; Require minimum this pulse length to validate RC pulse
.equ	RCP_STOP		= 1		; Stop motor at or below this pulse length
.equ	RCP_STOP_LIMIT	= 1		; Stop motor if this many timer1 overflows (~65ms) are below stop limit

.equ	PWM_SETTLE		= 50 	; PWM used when in start settling mode
.equ	PWM_STEPPER		= 80 	; PWM used when in start stepper mode
.equ	PWM_AQUISITION		= 80 	; PWM used when in start aquisition mode
.equ	PWM_INITIAL_RUN	= 40 	; PWM used when in initial run mode 

.equ	COMM_TIME_RED		= 5		; Fixed reduction (in us) for commutation wait (to account for fixed delays)
.equ	COMM_TIME_MIN		= 5		; Minimum time (in us) for commutation wait

.equ	STEPPER_STEP_BEG		= 3000	; ~3300 eRPM 
.equ	STEPPER_STEP_END		= 1000	; ~10000 eRPM
.equ	STEPPER_STEP_DECREMENT	= 5		; Amount to decrease stepper step by per commutation

.equ	AQUISITION_ROTATIONS	= 2		; Number of rotations to do in the aquisition phase
.equ	DAMPED_RUN_ROTATIONS	= 1		; Number of rotations to do in the damped run phase

; Constant definitions for tail
.else

.equ GOV_SPOOLRATE	= 1		; Number of steps for governor requested pwm per 65ms

.equ	RCP_TIMEOUT	= 12		; Number of timer0 overflows (about 256us) before considering rc pulse lost
.equ	RCP_SKIP_RATE	= 3		; Number of timer0 overflows (about 256us) before reenabling rc pulse detection
.equ	RCP_MIN		= 0		; This is minimum RC pulse length
.equ	RCP_MAX		= 250	; This is maximum RC pulse length
.equ	RCP_VALIDATE	= 2		; Require minimum this pulse length to validate RC pulse
.equ	RCP_STOP		= 1		; Stop motor at or below this pulse length
.equ	RCP_STOP_LIMIT	= 50		; Stop motor if this many timer1 overflows (~65ms) are below stop limit

.equ	PWM_SETTLE		= 50 	; PWM used when in start settling mode
.equ	PWM_STEPPER		= 120 	; PWM used when in start stepper mode
.equ	PWM_AQUISITION		= 80 	; PWM used when in start aquisition mode
.equ	PWM_INITIAL_RUN	= 40 	; PWM used when in initial run mode 

.equ	COMM_TIME_RED		= 5		; Fixed reduction (in us) for commutation wait (to account for fixed delays)
.equ	COMM_TIME_MIN		= 5		; Minimum time (in us) for commutation wait

.equ	STEPPER_STEP_BEG		= 3000	; ~3300 eRPM 
.equ	STEPPER_STEP_END		= 1000	; ~10000 eRPM
.equ	STEPPER_STEP_DECREMENT	= 30		; Amount to decrease stepper step by per commutation

.equ	AQUISITION_ROTATIONS	= 2		; Number of rotations to do in the aquisition phase
.equ	DAMPED_RUN_ROTATIONS	= 1		; Number of rotations to do in the damped run phase

.endif

;**** **** **** **** ****
; Register definitions
.def	Zero				= r0		; Register variable initialized to 0, always at 0
.def	I_Sreg			= r1		; Status register saved in interrupts
.def	Requested_Pwm		= r2		; Requested pwm (from RC pulse value)
.def	Governor_Req_Pwm	= r3		; Governor requested pwm (sets governor target)
.def	Current_Pwm		= r4		; Current pwm
.def	Current_Pwm_Limited	= r5		; Current pwm that is limited (applied to the motor output)
.def	Pwm_Timer_Second	= r6 	; Second timer wait for pwm timer (if exceeding 256)
.def	Rcp_Prev_Edge_L	= r7		; RC pulse previous edge timer1 timestamp (lo byte)
.def	Rcp_Prev_Edge_H	= r8		; RC pulse previous edge timer1 timestamp (hi byte)
;.def Temp5	 		= r9		; (Used by Temp5)
;.def Temp6			= r10	; (Used by Temp6)
;.def I_Temp4			= r11	; (Used by I_Temp4)
;.def I_Temp5			= r12	; (Used by I_Temp5)
.def	Rcp_Timeout_Cnt	= r13	; RC pulse timeout counter (decrementing) 
.def	Rcp_Skip_Cnt		= r14	; RC pulse skip counter (decrementing) 
.def	Rcp_Edge_Cnt		= r15	; RC pulse edge counter 

.def	Temp1			= r16	; Main temporary
.def	Temp2			= r17	; Main temporary
.def	Temp3			= r18	; Main temporary
.def	Temp4			= r19	; Main temporary
.def	Temp5			= r9		; Aux temporary (limited operations)
.def	Temp6			= r10	; Aux temporary (limited operations)

.def	I_Temp1			= r20	; Interrupt temporary
.def	I_Temp2			= r21	; Interrupt temporary 
.def	I_Temp3			= r22	; Interrupt temporary
.def	I_Temp4			= r11	; Interrupt temporary (limited operations)
.def	I_Temp5			= r12	; Interrupt temporary (limited operations)

.def	Flags0	= r23	; State flags 
.equ	OCA_PENDING		= 0	; If set, timer1 output compare interrunpt A is pending 
;.equ				= 1
;.equ				= 2
;.equ				= 3
.equ	SETTLE_MODE		= 4	; Set when in motor start settling mode
.equ	STEPPER_MODE		= 5	; Set when in motor start stepper motor mode
.equ	AQUISITION_MODE	= 6	; Set when in motor start aquisition mode
.equ	INITIAL_RUN_MODE	= 7	; Set when in initial rotations of run mode 

.def	Flags1	= r24	; State flags
.equ	COMP_STORED		= 0	; If set, comparator output was high in the last PWM cycle (evaluated in the PWM on period)
.equ	PWM_ON			= 1	; Set in on part of pwm cycle
.equ	PWM_OFF_DAMPED		= 2	; Set when pfets shall be on in pwm_off period
.equ	RCP_MEAS_PWM_FREQ	= 3	; Measure RC pulse pwm frequency
;.equ				= 4 
;.equ				= 5	
;.equ				= 6 
;.equ				= 7	

.def	Flags2	= r25	; State flags
.equ	RCP_UPDATED		= 0	; New RC pulse length value available
.equ	RCP_EDGE_NO		= 1	; RC pulse edge no. 0=first, 1=second
.equ	RCP_PWM_FREQ_1KHZ	= 2	; RC pulse pwm frequency is 1kHz
.equ	RCP_PWM_FREQ_2KHZ	= 3	; RC pulse pwm frequency is 2kHz
.equ	RCP_PWM_FREQ_4KHZ	= 4	; RC pulse pwm frequency is 4kHz
.equ	RCP_PWM_FREQ_8KHZ	= 5	; RC pulse pwm frequency is 8kHz
.equ	PGM_PWM_HIGH_FREQ	= 6	; Programmed pwm frequency. 0=low, 1=high
.equ	PGM_RCP_PWM_POL	= 7	; Programmed RC pulse pwm polarity. 0=positive, 1=negative

; Here the general temporary register XYZ are placed (r26-r31)

; X: General temporary
; Y: General temporary
; Z: Interrupt-accessed address of current PWM FET ON routine (eg: pwm_afet_on)


;**** **** **** **** ****
; RAM definitions
.dseg				; Data segment
.org SRAM_START

Startup_Rot_Cnt:	.byte	1	; Startup mode rotations counter (decrementing) 

Prev_Comm_L:		.byte	1	; Previous commutation timer1 timestamp (lo byte)
Prev_Comm_H:		.byte	1	; Previous commutation timer1 timestamp (hi byte)
Comm_Period4x_L:	.byte	1	; Timer1 counts between the last 4 commutations (lo byte)
Comm_Period4x_H:	.byte	1	; Timer1 counts between the last 4 commutations (hi byte)

Gov_Target_L:		.byte	1	; Governor target (lo byte)
Gov_Target_H:		.byte	1	; Governor target (hi byte)
Gov_Integral_L:	.byte	1	; Governor integral error (lo byte)
Gov_Integral_H:	.byte	1	; Governor integral error (hi byte)
Gov_Integral_X:	.byte	1	; Governor integral error (ex byte)
Gov_Proportional_L:	.byte	1	; Governor proportional error (lo byte)
Gov_Proportional_H:	.byte	1	; Governor proportional error (hi byte)
Gov_Prop_Pwm:		.byte	1	; Governor calculated new pwm based upon proportional error
Gov_Arm_Target:	.byte	1	; Governor arm target value
Gov_Active:		.byte	1	; Governor active (enabled and speed above minimum)

Wt_Advance_L:		.byte	1	; Timer1 counts for commutation advance timing (lo byte)
Wt_Advance_H:		.byte	1	; Timer1 counts for commutation advance timing (hi byte)
Wt_Zc_Scan_L:		.byte	1	; Timer1 counts from commutation to zero cross scan (lo byte)
Wt_Zc_Scan_H:		.byte	1	; Timer1 counts from commutation to zero cross scan (hi byte)
Wt_Comm_L:		.byte	1	; Timer1 counts from zero cross to commutation (lo byte)
Wt_Comm_H:		.byte	1	; Timer1 counts from zero cross to commutation (hi byte)
Wt_Stepper_Step_L:	.byte	1	; Timer1 counts for stepper step (lo byte)
Wt_Stepper_Step_H:	.byte	1	; Timer1 counts for stepper step (hi byte)

Rcp_PrePrev_Edge_L:	.byte	1	; RC pulse pre previous edge timer1 timestamp (lo byte)
Rcp_PrePrev_Edge_H:	.byte	1	; RC pulse pre previous edge timer1 timestamp (hi byte)
Rcp_Edge_L:		.byte	1	; RC pulse edge timer1 timestamp (lo byte)
Rcp_Edge_H:		.byte	1	; RC pulse edge timer1 timestamp (hi byte)
New_Rcp:			.byte	1	; New RC pulse value in timer1 counts
Prev_Rcp:			.byte	1	; Previous RC pulse value in timer1 counts
Prev_Rcp_Pwm_Freq:	.byte	1	; Previous RC pulse pwm frequency (used during pwm frequency measurement)
Rcp_Stop_Cnt:		.byte	1	; Counter for RC pulses below stop value 

Pwm_Limit:		.byte	1	; Maximum allowed pwm 
Lipo_Cells:		.byte	1	; Number of lipo cells 
Lipo_Adc_Limit_L:	.byte	1	; Low voltage limit adc minimum (lo byte)
Lipo_Adc_Limit_H:	.byte	1	; Low voltage limit adc minimum (hi byte)

Tx_Pgm_Func_No:	.byte	1	; Function number when doing programming by tx
Tx_Pgm_Paraval_No:	.byte	1	; Parameter value number when doing programming by tx
Tx_Pgm_Beep_No:	.byte	1	; Beep number when doing programming by tx

Pgm_Gov_P_Gain:	.byte	1	; Programmed governor P gain
Pgm_Gov_I_Gain:	.byte	1	; Programmed governor I gain
Pgm_Gov_Mode:		.byte	1	; Programmed governor mode
Pgm_Tail_Gain:		.byte	1	; Programmed tail gain
Pgm_Tail_Idle:		.byte	1	; Programmed tail idle speed
Pgm_Startup_Pwr:	.byte	1	; Programmed startup power
Pgm_Pwm_Freq:		.byte	1	; Programmed pwm frequency

.equ	SRAM_BYTES	= 100		; Bytes available in SRAM. Used for number of bytes to reset


;**** **** **** **** ****
.eseg				; Eeprom segment
.org 0				
Eep_Pgm_Gov_P_Gain:		.byte	1	; EEPROM copy of programmed governor P gain
Eep_Pgm_Gov_I_Gain:		.byte	1	; EEPROM copy of programmed governor I gain
Eep_Pgm_Gov_Mode:		.byte	1	; EEPROM copy of programmed governor mode
Eep_Pgm_Tail_Gain:		.byte	1	; EEPROM copy of programmed tail gain
Eep_Pgm_Tail_Idle:		.byte	1	; EEPROM copy of programmed tail idle speed
Eep_Pgm_Startup_Pwr:	.byte	1	; EEPROM copy of programmed startup power
Eep_Pgm_Pwm_Freq:		.byte	1	; EEPROM copy of programmed pwm frequency
Eep_Pgm_Input_Pol:		.byte	1	; EEPROM copy of programmed input polarity
Eep_Initialized_L:		.byte	1	; EEPROM initialized signature low byte
Eep_Initialized_H:		.byte	1	; EEPROM initialized signature high byte

;**** **** **** **** ****
.cseg				; Code segment
.org 0
	Interrupt_Table_Definition	; ATmega interrupts
	
;**** **** **** **** ****

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; External interrupt 0 routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
ext_int0:
.if ICP == 0
	in	I_Sreg, SREG
	; Get timer1 values
	Read_TCNT1L I_Temp1
	Read_TCNT1H I_Temp2
	; Check which edge it is
	sbrc	Flags2, RCP_EDGE_NO			; Was it a first edge trig?
	rjmp rcpint_second_meas_pwm_freq	; No - branch to second

	Rcp_Int_Second I_Temp3			; Yes - set second edge trig
	sbr	Flags2, (1<<RCP_EDGE_NO)		; Set second edge flag
	; Read RC signal level
	Read_Rcp_Int I_Temp5
	; Test RC signal level
	sbrs	I_Temp5, Rcp_In			; Is it high?
	rjmp	rcpint_fail_minimum			; No - jump to fail minimum

	; RC pulse was high, store RC pulse start timestamp
	mov	Rcp_Prev_Edge_L, I_Temp1
	mov	Rcp_Prev_Edge_H, I_Temp2
	rjmp	rcpint_exit				; Exit

rcpint_fail_minimum:
	; Prepare for next interrupt
	Rcp_Int_First I_Temp3			; Set interrupt trig to first again
	Clear_Int_Flag I_Temp3			; Clear interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	ldi	I_Temp1, RCP_MIN			; Set RC pulse value to minimum
	ldi	I_Temp2, RCP_MIN
	Read_Rcp_Int I_Temp5			; Test RC signal level again
	sbrc	I_Temp5, Rcp_In			; Is it high?
	rjmp	rcpint_set_timeout			; Yes - set new timeout and exit

	sts	Prev_Rcp, I_Temp2 			; Store previous pulse length
	sts	New_Rcp, I_Temp1			; Store new pulse length
	rjmp	rcpint_set_timeout			; Set new timeout and exit

rcpint_second_meas_pwm_freq:
	; Prepare for next interrupt
	Rcp_Int_First I_Temp3			; Set first edge trig
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	; Check if pwm frequency shall be measured
	sbrs	Flags1, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp	rcpint_fall				; No - skip measurements

	; Set second edge trig only during pwm frequency measurement
	Rcp_Int_Second I_Temp3			; Set second edge trig
	Clear_Int_Flag I_Temp3			; Clear interrupt flag
	sbr	Flags2, (1<<RCP_EDGE_NO)		; Set second edge flag
	; Store edge data to RAM
	sts	Rcp_Edge_L, I_Temp1
	sts	Rcp_Edge_H, I_Temp2
	; Calculate pwm frequency
	lds	I_Temp3, Rcp_PrePrev_Edge_L
	lds	I_Temp4, Rcp_PrePrev_Edge_H
	sub	I_Temp1, I_Temp3	
	sbc	I_Temp2, I_Temp4
	mov	I_Temp4, Zero
	; Check if pwm frequency is 8kHz
	cpi	I_Temp1, low(180)			; If below 180us, 8kHz pwm is assumed
	ldi	I_Temp3, high(180)
	cpc	I_Temp2, I_Temp3
	brcc	rcpint_check_4kHz

	clr	I_Temp3
	sbr	I_Temp3, (1<<RCP_PWM_FREQ_8KHZ)
	mov	I_Temp4, I_Temp3
	rjmp	rcpint_restore_edge

rcpint_check_4kHz:
	; Check if pwm frequency is 4kHz
	cpi	I_Temp1, low(360)			; If below 360us, 4kHz pwm is assumed
	ldi	I_Temp3, high(360)
	cpc	I_Temp2, I_Temp3
	brcc	rcpint_check_2kHz

	clr	I_Temp3
	sbr	I_Temp3, (1<<RCP_PWM_FREQ_4KHZ)
	mov	I_Temp4, I_Temp3
	rjmp	rcpint_restore_edge

rcpint_check_2kHz:
	; Check if pwm frequency is 2kHz
	cpi	I_Temp1, low(720)			; If below 720us, 2kHz pwm is assumed
	ldi	I_Temp3, high(720)
	cpc	I_Temp2, I_Temp3
	brcc	rcpint_check_1kHz

	clr	I_Temp3
	sbr	I_Temp3, (1<<RCP_PWM_FREQ_2KHZ)
	mov	I_Temp4, I_Temp3
	rjmp	rcpint_restore_edge

rcpint_check_1kHz:
	; Check if pwm frequency is 1kHz
	cpi	I_Temp1, low(1440)			; If below 1440us, 1kHz pwm is assumed
	ldi	I_Temp3, high(1440)
	cpc	I_Temp2, I_Temp3
	brcc	rcpint_restore_edge

	clr	I_Temp3
	sbr	I_Temp3, (1<<RCP_PWM_FREQ_1KHZ)
	mov	I_Temp4, I_Temp3

rcpint_restore_edge:
	; Restore edge data from RAM
	lds	I_Temp1, Rcp_Edge_L
	lds	I_Temp2, Rcp_Edge_H
	; Store pre previous edge
	sts	Rcp_PrePrev_Edge_L, I_Temp1
	sts	Rcp_PrePrev_Edge_H, I_Temp2

rcpint_fall:
	; RC pulse edge was second, calculate new pulse length
	sub	I_Temp1, Rcp_Prev_Edge_L	
	sbc	I_Temp2, Rcp_Prev_Edge_H
	sbrc	Flags2, RCP_PWM_FREQ_8KHZ	; Is RC input pwm frequency 8kHz?
	rjmp	rcpint_pwm_mult			; Yes - branch forward

	sbrc	Flags2, RCP_PWM_FREQ_4KHZ	; Is RC input pwm frequency 4kHz?
	rjmp	rcpint_pwm_divide_done		; Yes - branch forward

	lsr	I_Temp2					; No - 2kHz. Divide by 2 again
	ror	I_Temp1

	sbrc	Flags2, RCP_PWM_FREQ_2KHZ	; Is RC input pwm frequency 2kHz?
	rjmp	rcpint_pwm_divide_done		; Yes - branch forward

	lsr	I_Temp2					; No - 1kHz. Divide by 2 again
	ror	I_Temp1
	rjmp	rcpint_pwm_divide_done		; Yes - branch forward

rcpint_pwm_mult:
	lsl	I_Temp1
	rol	I_Temp2

rcpint_pwm_divide_done:
	; Check that RC pulse is within legal range
	cpi	I_Temp1, RCP_MAX
	cpc	I_Temp2, Zero
	brcs	rcpint_limited

	ldi	I_Temp1, RCP_MAX

rcpint_limited:
	lds	I_Temp2, New_Rcp 			; Load pulse length to be used as previous
	; RC pulse value accepted
	sts	Prev_Rcp, I_Temp2 			; Store previous pulse length
	sts	New_Rcp, I_Temp1			; Store new pulse length
	sbrs	Flags1, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp	rcpint_set_timeout			; No - skip measurements

	ldi	I_Temp3, (1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)
	com	I_Temp3
	and	Flags2, I_Temp3			; Clear all pwm frequency flags
	or	Flags2, I_Temp4			; Store pwm frequency value in flags

rcpint_set_timeout:
	ldi	I_Temp1, RCP_TIMEOUT		; Set timeout count to start value
	mov	Rcp_Timeout_Cnt, I_Temp1
	sbr	Flags2, (1<<RCP_UPDATED) 	; Set updated flag
	sbrc	Flags1, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp rcpint_exit				; Yes - exit

	Rcp_Int_Disable I_Temp2			; Disable RC pulse interrupt

rcpint_exit:	; Exit interrupt routine	
	ldi	I_Temp2, RCP_SKIP_RATE		; Load number of skips
	mov	Rcp_Skip_Cnt, I_Temp2		
	out	SREG, I_Sreg
.endif
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Input capture pin1 interrupt routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
icp1_int:
.if ICP == 1
	in	I_Sreg, SREG
	; Get timer1 ICP values
	Read_ICR1L I_Temp1
	Read_ICR1H I_Temp2
	; Check which edge it is
	sbrc	Flags2, RCP_EDGE_NO				; Was it a first edge trig?
	rjmp rcpint_icp_second_meas_pwm_freq	; No - branch to second

	Rcp_Icp_Int_Second I_Temp3		; Yes - set second edge trig
	sbr	Flags2, (1<<RCP_EDGE_NO)		; Set second edge flag
	; Read ICP RC signal level
	Read_Rcp_Icp_Int I_Temp5			
	; Test RC signal level
	sbrs	I_Temp5, Rcp_Icp_In			; Is it high?
	rjmp	rcpint_icp_fail_minimum		; No - jump to fail minimum

	; RC pulse was high, store RC pulse start timestamp
	mov	Rcp_Prev_Edge_L, I_Temp1
	mov	Rcp_Prev_Edge_H, I_Temp2
	rjmp	rcpint_icp_exit			; Exit

rcpint_icp_fail_minimum:
	; Prepare for next interrupt
	Rcp_Icp_Int_First I_Temp3		; Set interrupt trig to first again
	Clear_Icp_Int_Flag I_Temp3		; Clear icp interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	ldi	I_Temp1, RCP_MIN			; Set RC pulse value to minimum
	ldi	I_Temp2, RCP_MIN
	Read_Rcp_Icp_Int I_Temp5			; Test RC signal level again
	sbrc	I_Temp5, Rcp_Icp_In			; Is it high?
	rjmp	rcpint_icp_set_timeout		; Yes - set new timeout and exit

	sts	Prev_Rcp, I_Temp2 			; Store previous pulse length
	sts	New_Rcp, I_Temp1			; Store new pulse length
	rjmp	rcpint_icp_set_timeout		; Set new timeout and exit

rcpint_icp_second_meas_pwm_freq:
	; Prepare for next interrupt
	Rcp_Icp_Int_First I_Temp3		; Set first edge trig
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	; Check if pwm frequency shall be measured
	sbrs	Flags1, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp	rcpint_icp_fall			; No - skip measurements

	; Set second edge trig only during pwm frequency measurement
	Rcp_Icp_Int_Second I_Temp3		; Set second edge trig
	Clear_Icp_Int_Flag I_Temp3		; Clear icp interrupt flag
	sbr	Flags2, (1<<RCP_EDGE_NO)		; Set second edge flag
	; Store edge data to RAM
	sts	Rcp_Edge_L, I_Temp1
	sts	Rcp_Edge_H, I_Temp2
	; Calculate pwm frequency
	lds	I_Temp3, Rcp_PrePrev_Edge_L
	lds	I_Temp4, Rcp_PrePrev_Edge_H
	sub	I_Temp1, I_Temp3	
	sbc	I_Temp2, I_Temp4
	mov	I_Temp4, Zero
	; Check if pwm frequency is 8kHz
	cpi	I_Temp1, low(180)			; If below 180us, 8kHz pwm is assumed
	ldi	I_Temp3, high(180)
	cpc	I_Temp2, I_Temp3
	brcc	rcpint_icp_check_4kHz

	clr	I_Temp3
	sbr	I_Temp3, (1<<RCP_PWM_FREQ_8KHZ)
	mov	I_Temp4, I_Temp3
	rjmp	rcpint_icp_restore_edge

rcpint_icp_check_4kHz:
	; Check if pwm frequency is 4kHz
	cpi	I_Temp1, low(360)			; If below 360us, 4kHz pwm is assumed
	ldi	I_Temp3, high(360)
	cpc	I_Temp2, I_Temp3
	brcc	rcpint_icp_check_2kHz

	clr	I_Temp3
	sbr	I_Temp3, (1<<RCP_PWM_FREQ_4KHZ)
	mov	I_Temp4, I_Temp3
	rjmp	rcpint_icp_restore_edge

rcpint_icp_check_2kHz:
	; Check if pwm frequency is 2kHz
	cpi	I_Temp1, low(720)			; If below 720us, 2kHz pwm is assumed
	ldi	I_Temp3, high(720)
	cpc	I_Temp2, I_Temp3
	brcc	rcpint_icp_check_1kHz

	clr	I_Temp3
	sbr	I_Temp3, (1<<RCP_PWM_FREQ_2KHZ)
	mov	I_Temp4, I_Temp3
	rjmp	rcpint_icp_restore_edge

rcpint_icp_check_1kHz:
	; Check if pwm frequency is 1kHz
	cpi	I_Temp1, low(1440)			; If below 1440us, 1kHz pwm is assumed
	ldi	I_Temp3, high(1440)
	cpc	I_Temp2, I_Temp3
	brcc	rcpint_icp_restore_edge

	clr	I_Temp3
	sbr	I_Temp3, (1<<RCP_PWM_FREQ_1KHZ)
	mov	I_Temp4, I_Temp3

rcpint_icp_restore_edge:
	; Restore edge data from RAM
	lds	I_Temp1, Rcp_Edge_L
	lds	I_Temp2, Rcp_Edge_H
	; Store pre previous edge
	sts	Rcp_PrePrev_Edge_L, I_Temp1
	sts	Rcp_PrePrev_Edge_H, I_Temp2

rcpint_icp_fall:
	; RC pulse edge was second, calculate new pulse length
	sub	I_Temp1, Rcp_Prev_Edge_L	
	sbc	I_Temp2, Rcp_Prev_Edge_H
	sbrc	Flags2, RCP_PWM_FREQ_8KHZ	; Is RC input pwm frequency 8kHz?
	rjmp	rcpint_icp_pwm_mult			; Yes - branch forward

	sbrc	Flags2, RCP_PWM_FREQ_4KHZ	; Is RC input pwm frequency 4kHz?
	rjmp	rcpint_icp_pwm_divide_done	; Yes - branch forward

	lsr	I_Temp2					; No - 2kHz. Divide by 2 again
	ror	I_Temp1

	sbrc	Flags2, RCP_PWM_FREQ_2KHZ	; Is RC input pwm frequency 2kHz?
	rjmp	rcpint_icp_pwm_divide_done	; Yes - branch forward

	lsr	I_Temp2					; No - 1kHz. Divide by 2 again
	ror	I_Temp1
	rjmp	rcpint_icp_pwm_divide_done	

rcpint_icp_pwm_mult:
	lsl	I_Temp1					; Multiply by 2
	rol	I_Temp2

rcpint_icp_pwm_divide_done:
	; Check that RC pulse is within legal range
	cpi	I_Temp1, RCP_MAX
	cpc	I_Temp2, Zero
	brcs	rcpint_icp_limited

	ldi	I_Temp1, RCP_MAX

rcpint_icp_limited:
	lds	I_Temp2, New_Rcp 			; Load pulse length to be used as previous
	; RC pulse value accepted
	sts	Prev_Rcp, I_Temp2 			; Store previous pulse length
	sts	New_Rcp, I_Temp1			; Store new pulse length
	sbrs	Flags1, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp	rcpint_icp_set_timeout		; No - skip measurements

	ldi	I_Temp3, (1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)
	com	I_Temp3
	and	Flags2, I_Temp3			; Clear all pwm frequency flags
	or	Flags2, I_Temp4			; Store pwm frequency value in flags

rcpint_icp_set_timeout:
	ldi	I_Temp1, RCP_TIMEOUT		; Set timeout count to start value
	mov	Rcp_Timeout_Cnt, I_Temp1
	sbr	Flags2, (1<<RCP_UPDATED) 	; Set updated flag
	sbrc	Flags1, RCP_MEAS_PWM_FREQ	; Is measure RCP pwm frequency flag set?
	rjmp rcpint_icp_exit			; Yes - exit

	Rcp_Icp_Int_Disable I_Temp2		; Disable RC pulse interrupt

rcpint_icp_exit:	; Exit interrupt routine	
	ldi	I_Temp2, RCP_SKIP_RATE		; Load number of skips
	mov	Rcp_Skip_Cnt, I_Temp2		
	out	SREG, I_Sreg
.endif
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 0 overflow interrupt
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t0ovfl_int:	; Happens every 256탎	
	in	I_Sreg, SREG
	; Check RC pulse timeout counter
	tst	Rcp_Timeout_Cnt			; RC pulse timeout count zero?
	breq t0ovfl_pulses_absent		; Yes - pulses are absent

	; Decrement timeout counter
	dec	Rcp_Timeout_Cnt			; Decrement
	rjmp	t0ovfl_skip_start

t0ovfl_pulses_absent:
	; Timeout counter has reached zero, pulses are absent
	ldi	I_Temp1, RCP_MIN			; RCP_MIN as default
	ldi	I_Temp2, RCP_MIN			
.if ICP == 0
	Read_Rcp_Int I_Temp3			; Look at value of Rcp_In
	sbrc	I_Temp3, Rcp_In			; Is it high?
	ldi	I_Temp1, RCP_MAX			; Yes - set RCP_MAX
	Rcp_Int_First I_Temp3			; Set interrupt trig to first again
	Clear_Int_Flag I_Temp3			; Clear interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	Read_Rcp_Int I_Temp3			; Look once more at value of Rcp_In
	sbrc	I_Temp3, Rcp_In			; Is it high?
	ldi	I_Temp2, RCP_MAX			; Yes - set RCP_MAX
	cp	I_Temp1, I_Temp2			; Compare the two readings of Rcp_In
	brne t0ovfl_pulses_absent		; Go back if they are not equal
.else
	Read_Rcp_Icp_Int I_Temp3			; Look at value of Rcp_Icp_In
	sbrc	I_Temp3, Rcp_Icp_In			; Is it high?
	ldi	I_Temp1, RCP_MAX			; Yes - set RCP_MAX
	Rcp_Icp_Int_First I_Temp3		; Set interrupt trig to first again
	Clear_Icp_Int_Flag I_Temp3		; Clear icp interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)		; Set first edge flag
	Read_Rcp_Icp_Int I_Temp3			; Look once more at value of Rcp_In
	sbrc	I_Temp3, Rcp_Icp_In			; Is it high?
	ldi	I_Temp2, RCP_MAX			; Yes - set RCP_MAX
	cp	I_Temp1, I_Temp2			; Compare the two readings of Rcp_In
	brne t0ovfl_pulses_absent		; Go back if they are not equal
.endif
	ldi	I_Temp2, RCP_TIMEOUT		; Set timeout count to start value
	mov	Rcp_Timeout_Cnt, I_Temp2
	sts	Prev_Rcp, I_Temp1 			; Store previous pulse length
	sts	New_Rcp, I_Temp1			; Store new pulse length
	sbr	Flags2, (1<<RCP_UPDATED) 	; Set updated flag

t0ovfl_skip_start:
	; Check RC pulse skip counter
	tst	Rcp_Skip_Cnt				; RC pulse skip count zero?
	breq t0ovfl_skip_end			; Yes - end skipping RC pulse detection
	
	; Decrement skip counter (only if edge counter is zero)
	dec	Rcp_Skip_Cnt				; Decrement
	rjmp	t0ovfl_rcp_update_start

t0ovfl_skip_end:
	; Skip counter has reached zero, start looking for RC pulses again
.if ICP == 0
	Rcp_Int_Enable I_Temp2			; Enable RC pulse interrupt
	Clear_Int_Flag I_Temp2			; Clear interrupt flag
.else
	Rcp_Icp_Int_Enable I_Temp2		; Enable ICP RC pulse interrupt
	Clear_Icp_Int_Flag I_Temp2		; Clear icp interrupt flag
.endif
	
t0ovfl_rcp_update_start:
	; Process updated RC pulse
	sbrs	Flags2, RCP_UPDATED 		; Is there an updated RC pulse available?
	rjmp	t0ovfl_pwm_exit			; No - exit

	lds	I_Temp2, Prev_Rcp			; Load previous pulse value
	lds	I_Temp1, New_Rcp			; Load new pulse value
	sbrc	Flags2, RCP_PWM_FREQ_8KHZ	; Is RC input pwm frequency 8kHz?
	add	I_Temp1, I_Temp2			; Yes - add the two pulse values
	sbrc	Flags2, RCP_PWM_FREQ_8KHZ	; Is RC input pwm frequency 8kHz?
	ror	I_Temp1					; Yes - divide by 2 to compensate for the add
	cbr	Flags2, (1<<RCP_UPDATED) 	; Flag that pulse has been evaluated
	; Limit the maximum value to avoid wrap when scaled to pwm range
.if TAIL == 1
	cpi	I_Temp1, 240		; 240 = (255/1.0625) Needs to be updated according to multiplication factor below
	brlo	t0ovfl_rcp_update_mult

	ldi	I_Temp1, 240		; Set requested pwm to max

.endif
t0ovfl_rcp_update_mult:	
.if TAIL == 1
	; Multiply by 1.0625 (optional adjustment gyro gain)
	mov	I_Temp2, I_Temp1		
	swap	I_Temp2		; After this "0.0625"
	andi	I_Temp2, 0x0f
	add	I_Temp1, I_Temp2
	; Adjust tail gain
	lds	I_Temp3, Pgm_Tail_Gain	
	cpi	I_Temp3, 3			; Is gain 1?
	breq	t0ovfl_pwm_min_run		; Yes - skip adjustment

	mov	I_Temp2, I_Temp1		
	lsr	I_Temp2		; After this "0.5"
	lsr	I_Temp2		; After this "0.25"
	sbrc	I_Temp3, 0			; Is bit 0 in gain set?
	rjmp	t0ovfl_rcp_tail_corr	; Yes - two gain correction steps

	lsr	I_Temp2		; After this "0.125"

t0ovfl_rcp_tail_corr:
	sbrc	I_Temp3, 2			; Is bit 2 in gain set?
	rjmp	t0ovfl_rcp_tail_gain_pos	; Yes - positive correction

	sub	I_Temp1, I_Temp2		; Apply negative correction
	rjmp	t0ovfl_pwm_min_run

t0ovfl_rcp_tail_gain_pos:
	add	I_Temp1, I_Temp2		; Apply positive correction
	brcc	t0ovfl_pwm_min_run		; Above max?

	ldi	I_Temp1, 0xff			; Yes - limit
.endif

t0ovfl_pwm_min_run: 
	; Limit minimum pwm
	lds	I_Temp2, Pgm_Tail_Idle	; Is requested pwm lower than minimum?
	cp	I_Temp1, I_Temp2		
	brcc	t0ovfl_pwm_update		; No - branch

	lds	I_Temp1, Pgm_Tail_Idle	; Yes - limit pwm to Pgm_Tail_Idle	

t0ovfl_pwm_update: 
	; Check if any startup mode flags are set
	mov	I_Temp2, Flags0
	andi	I_Temp2, (1<<SETTLE_MODE)+(1<<STEPPER_MODE)+(1<<AQUISITION_MODE)+(1<<INITIAL_RUN_MODE)
	tst	I_Temp2				; Any startup mode set?
	brne	t0ovfl_pwm_exit		; Yes - exit (pwm controlled by set_startup_pwm)

	; Update requested_pwm
	mov	Requested_Pwm, I_Temp1	; Set requested pwm

	lds	I_Temp1, Pgm_Gov_Mode	; Governor mode?
	cpi	I_Temp1, 3
	brcs	t0ovfl_pwm_exit		; Yes - branch

	; Update current pwm
	mov	Current_Pwm, Requested_Pwm

t0ovfl_pwm_exit:	
	out	SREG, I_Sreg
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 1 output compare A interrupt
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t1oca_int:	
	in	I_Sreg, SREG
	cbr	Flags0, (1<<OCA_PENDING) 	; Flag that OCA value is passed
	out	SREG, I_Sreg
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 1 overflow interrupt
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t1ovfl_int:	; Happens every 65536탎	
	in	I_Sreg, SREG
	ldi	I_Temp2, GOV_SPOOLRATE	; Load governor spool rate
	; Check RC pulse against stop value
	lds	I_Temp1, New_Rcp		; Load new pulse value
	subi	I_Temp1, RCP_STOP		; Check if pulse is below stop value
	brcs	t1ovfl_rcp_stop

	; RC pulse higher than stop value, reset stop counter
	sts	Rcp_Stop_Cnt, Zero	; Reset rcp stop counter
	rjmp	t1ovfl_rcp_gov_pwm

t1ovfl_rcp_stop:	
	; RC pulse less than stop value, increment stop counter
	lds	I_Temp1, Rcp_Stop_Cnt	; Load rcp stop counter
	cpi	I_Temp1, 255			; Check if counter is max
	breq	t1ovfl_rcp_gov_pwm		; Branch if counter is equal to max

	lds	I_Temp1, Rcp_Stop_Cnt	; Increment stop counter 
	inc	I_Temp1
	sts	Rcp_Stop_Cnt, I_Temp1

t1ovfl_rcp_gov_pwm:
.if TAIL == 0
	lds	I_Temp3, Pgm_Gov_Mode		; Governor target by arm mode?
	cpi	I_Temp3, 2
	brne	t1ovfl_rcp_gov_by_tx		; No - branch

	lds	Requested_Pwm, Gov_Arm_Target	; Yes - load arm target

t1ovfl_rcp_gov_by_tx:
	cp	Governor_Req_Pwm, Requested_Pwm	; Is governor requested pwm equal to requested pwm?
	breq	t1ovfl_rcp_exit;				; Yes - branch

	brlo	t1ovfl_rcp_gov_pwm_inc			; No - if lower then increment

	dec	Governor_Req_Pwm				; No - if higher then decrement
	rjmp	t1ovfl_rcp_gov_pwm_exit

t1ovfl_rcp_gov_pwm_inc:
	inc	Governor_Req_Pwm				; Increment

t1ovfl_rcp_gov_pwm_exit:
	dec	I_Temp2						; Number of steps processed
	brne	t1ovfl_rcp_gov_pwm				; No - go back
.endif

t1ovfl_rcp_exit:
	out	SREG, I_Sreg
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Timer 2 overflow interrupt
;
; Assumptions: Z register must be set to desired pwm_nfet_on label
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
t2ovfl_int:		
	in	I_Sreg, SREG			; Store flags
	; Check if second timer is zero
	cp	Pwm_Timer_Second, Zero	; Is second timer zero?
	breq	t2ovfl_int_execute		; Yes - execute pwm on/off

	Set_TCNT2 Pwm_Timer_Second	; No - set counter to second timer	
	clr	Pwm_Timer_Second		; Set second to zero
	out	SREG, I_Sreg			; Exit
	reti

t2ovfl_int_execute:
	sbrs	Flags1, PWM_ON			; Is pwm on?
	ijmp						; No - jump to pwm on routines. Z should be set to one of the pwm_nfet_on labels

	; Pwm off cycle. Set timer2 for coming off cycle length
	mov	I_Temp1, Current_Pwm_Limited	; Load new timer setting
	sec							; Set carry
	sbrs	Flags2, PGM_PWM_HIGH_FREQ	; High pwm frequency?
	lsl	I_Temp1					; No - multiply by 2
	brcs	t2ovfl_int_off_no_second		; More than 256? - branch

	mov	Pwm_Timer_Second, I_Temp1	; Set second timer
	ldi	I_Temp1, 0				; Set next timer wait to max

t2ovfl_int_off_no_second:
	; Write start point for timer2
	Set_TCNT2 I_Temp1		
	; Read comparator output at the end of pwm on
	Read_Comp_Out I_Temp2
	; Clear pwm on flag
	cbr	Flags1, (1<<PWM_ON)		
	; Set full PWM (on all the time) if current PWM near max. This will give full power, but at the cost of a small "jump" in power
	mov 	I_Temp3, Current_Pwm_Limited	; Load current pwm
	cpi 	I_Temp3, 250				; Above full pwm?
	brsh	t2ovfl_pwm_off_exit			; Yes - exit
	All_nFETs_Off I_Temp1			; No - switch off all nfets

	; If damped operation, set all pmoses on in pwm_off
	sbrs	Flags1, PWM_OFF_DAMPED	; Damped operation?
	rjmp	t2ovfl_pwm_off_exit		; No - exit	

	; Delay to allow nFETs to go off before pFETs are turned on (only in damped mode)
	ldi	I_Temp1, 2
all_pfets_on_delay:
	dec	I_Temp1
	brne	all_pfets_on_delay
	All_pFETs_On I_Temp1		; Switch on all pfets
	; Test comparator output at the end of pwm on (COMP_STORED is only used in damped operation)
	sbr	Flags1, (1<<COMP_STORED)	; Set comparator to high 
	sbrs	I_Temp2, ACO			; Comparator output high?
	cbr	Flags1, (1<<COMP_STORED)	; No - clear comp_out

t2ovfl_pwm_off_exit:	; Exit from pwm off cycle
	out	SREG, I_Sreg
	reti

pwm_nofet_on:	; Dummy pwm on cycle
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

pwm_afet_on:	; Pwm on cycle afet on (bfet off)
	BnFET_off
	AnFET_on
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

pwm_bfet_on:	; Pwm on cycle bfet on (cfet off)
	CnFET_off
	BnFET_on
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

pwm_cfet_on:	; Pwm on cycle cfet on (afet off)
	AnFET_off
	CnFET_on
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

pwm_anfet_bpfet_on:	; Pwm on cycle anfet on (bnfet off) and bpfet on (used in damped state 6)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ldi	I_Temp1, 15
an_bp:
	ApFET_off
	CpFET_off
	dec	I_Temp1
	brne	an_bp
	BnFET_off 				; Switch nFETs
	AnFET_on
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

pwm_anfet_cpfet_on:	; Pwm on cycle anfet on (bnfet off) and cpfet on (used in damped state 5)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ldi	I_Temp1, 15
an_cp:
	ApFET_off
	BpFET_off
	dec	I_Temp1
	brne	an_cp
	BnFET_off					; Switch nFETs
	AnFET_on
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

pwm_bnfet_cpfet_on:	; Pwm on cycle bnfet on (cnfet off) and cpfet on (used in damped state 4)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ldi	I_Temp1, 15
bn_cp:
	BpFET_off
	ApFET_off
	dec	I_Temp1
	brne	bn_cp
	CnFET_off					; Switch nFETs
	BnFET_on
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

pwm_bnfet_apfet_on:	; Pwm on cycle bnfet on (cnfet off) and apfet on (used in damped state 3)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ldi	I_Temp1, 15
bn_ap:
	BpFET_off
	CpFET_off
	dec	I_Temp1
	brne	bn_ap
	CnFET_off					; Switch nFETs
	BnFET_on
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

pwm_cnfet_apfet_on:	; Pwm on cycle cnfet on (anfet off) and apfet on (used in damped state 2)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ldi	I_Temp1, 15
cn_ap:
	CpFET_off
	BpFET_off
	dec	I_Temp1
	brne	cn_ap
	AnFET_off					; Switch nFETs
	CnFET_on
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

pwm_cnfet_bpfet_on:	; Pwm on cycle cnfet on (anfet off) and bpfet on (used in damped state 1)
	; Delay from pFETs are turned off (only in damped mode) until nFET is turned on (pFETs are slow)
	ldi	I_Temp1, 15
cn_bp:
	CpFET_off
	ApFET_off
	dec	I_Temp1
	brne	cn_bp
	AnFET_off					; Switch nFETs
	CnFET_on
	sbr	Flags1, (1<<PWM_ON)		; Set pwm on flag
	rjmp	t2ovfl_pwm_on_exit

t2ovfl_pwm_on_exit:
	; Set timer2 for coming on cycle length
	mov 	I_Temp1, Current_Pwm_Limited	; Load current pwm
	com	I_Temp1					; com is 255-x
	sec							; Set carry
	sbrs	Flags2, PGM_PWM_HIGH_FREQ	; High pwm frequency?
	lsl	I_Temp1					; No - multiply by 2
	brcs	t2ovfl_int_on_no_second		; More than 256? - branch

	mov	Pwm_Timer_Second, I_Temp1	; Set second timer
	ldi	I_Temp1, 0				; Set next timer wait to max

	t2ovfl_int_on_no_second:
	Set_TCNT2 I_Temp1				; Write start point for timer2
	out	SREG, I_Sreg
	reti


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait 1us
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait1us:	
	nop		; Assuming rcall is used for entry (rcall is 3 cycles, ret is 4 cycles plus 1 nop is 8 cycles)
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait xms ~(x*4*250)  (Different entry points)	
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait1ms:	
	ldi	Temp3, 1
	rjmp	waitxms_o

wait3ms:	
	ldi	Temp3, 3
	rjmp	waitxms_o

wait10ms:	
	ldi	Temp3, 10
	rjmp	waitxms_o

wait30ms:	
	ldi	Temp3, 30
	rjmp	waitxms_o

wait100ms:	
	ldi	Temp3, 100
	rjmp	waitxms_o

wait200ms:	
	ldi	Temp3, 200
	rjmp	waitxms_o

waitxms_o:	; Outer loop
	ldi	Temp2, 4
waitxms_m: 	; Middle loop	
	ldi	Temp1, 192	; 250탎
waitxms_i: 	; Inner loop	
	rcall wait1us
	dec	Temp1	
	brne	waitxms_i
	dec	Temp2
	brne	waitxms_m
	dec	Temp3
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
	ldi	Temp4, 21		; Off wait loop length
	ldi	Temp3, 80		; Number of beep pulses
	rjmp	beep

beep_f2:	; Entry point 2, load beeper frequency 2 settings
	ldi	Temp4, 18
	ldi	Temp3, 100
	rjmp	beep

beep_f3:	; Entry point 3, load beeper frequency 3 settings
	ldi	Temp4, 15
	ldi	Temp3, 120
	rjmp	beep

beep_f4:	; Entry point 4, load beeper frequency 4 settings
	ldi	Temp4, 12
	ldi	Temp3, 140
	rjmp	beep

beep:	; Beep loop start
	BpFET_on			; BpFET on
	ldi	Temp1, 150	; Allow some time after pfet is turned on
beep_wait_pfet_on:
	dec	Temp1
	brne	beep_wait_pfet_on
	ldi	Temp1, 12		; 15탎 on
	AnFET_on			; AnFET on
beep_on_i:	; Fets on loop
	rcall wait1us
	dec	Temp1	
	brne	beep_on_i
	AnFET_off			; AnFET off
	ldi	Temp2, 64		
beep_off_o:	; Fets off, outer loop
	mov	Temp1, Temp4	; Set off time
beep_off_i:	; Inner loop
	rcall wait1us
	dec	Temp1
	brne	beep_off_i
	dec	Temp2
	brne	beep_off_o
	dec	Temp3
	brne	beep
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
	lds	Temp1, Pgm_Gov_Mode		; Governor mode?
	cpi	Temp1, 3
	brcs	governor_speed_check	; Yes - branch
	rjmp	calc_governor_target_exit

governor_speed_check:
	; Load comm period
	lds	Temp1, Comm_Period4x_L
	lds	Temp2, Comm_Period4x_H
	; Check speed (do not run governor for low speeds)
	ldi	Temp3, 0x02				; Is speed below min limit (~62500 eRPM)?
	cpi	Temp1, 0x80				
	cpc	Temp2, Temp3				
	brcs	governor_target_calc		; No - calculate governor target

	mov	Current_Pwm, Requested_Pwm	; Set current pwm to requested
	sts	Gov_Target_L, Zero			; Set target to zero
	sts	Gov_Target_H, Zero
	sts	Gov_Integral_L, Zero		; Set integral to zero
	sts	Gov_Integral_H, Zero
	sts	Gov_Integral_X, Zero
	sts	Gov_Active, Zero
	rjmp	calc_governor_target_exit

governor_target_calc:
	; Governor calculations
	mov	Temp3, Governor_Req_Pwm	; Load governor requested pwm
	com	Temp3				; Calculate 255-pwm (invert pwm) 
	; Calculate comm period target (1 + 2*((255-Requested_Pwm)/256) - 0.25)
	rol	Temp3				; Msb to carry
	rol	Temp3				; To bit0
	mov	Temp4, Temp3			; Now 2 lsbs are valid for H
	ror	Temp3				; Now 6 msbs are valid for L
	andi	Temp4, 0x01			; Calculate H byte
	inc	Temp4
	andi	Temp3, 0xfe			; Calculate L byte
	subi	Temp3, 0x40			; Subtract 0.25
	sbc	Temp4, Zero
	; Store governor target
	sts	Gov_Target_L, Temp3
	sts	Gov_Target_H, Temp4
	; Set governor active
	ldi	Temp1, 1
	sts	Gov_Active, Temp1
calc_governor_target_exit:
	ret						


; Second governor routine - calculate governor proportional error
calc_governor_prop_error:
	; Exit if governor is inactive
	lds	Temp1, Gov_Active
	cp	Temp1, Zero
	breq	calc_governor_prop_error_exit

	; Load governor target
	lds	Temp1, Gov_Target_L
	lds	Temp2, Gov_Target_H
	; Load comm period
	lds	Temp3, Comm_Period4x_L
	lds	Temp4, Comm_Period4x_H
	; Calculate error
	sub	Temp1, Temp3
	sbc	Temp2, Temp4
	; Check error and limit (to low byte)
	ldi	Temp3, 0xff				; Is error too negative?
	cpi	Temp1, 0x80				
	cpc	Temp2, Temp3
	brlt	governor_limit_prop_error_neg	; Yes - limit

	ldi	Temp3, 0x00				; Is error too positive?
	cpi	Temp1, 0x7f				
	cpc	Temp2, Temp3
	brge	governor_limit_prop_error_pos	; Yes - limit
	rjmp	governor_store_prop_error

governor_limit_prop_error_pos:
	ldi	Temp1, 0x7f				; Limit to max positive (2's complement)
	ldi	Temp2, 0x00
	rjmp	governor_store_prop_error

governor_limit_prop_error_neg:
	ldi	Temp1, 0x80				; Limit to max negative (2's complement)
	ldi	Temp2, 0xff

governor_store_prop_error:
	; Store proportional
	sts	Gov_Proportional_L, Temp1
	sts	Gov_Proportional_H, Temp2
calc_governor_prop_error_exit:
	ret						


; Third governor routine - calculate governor integral error
calc_governor_int_error:
	; Exit if governor is inactive
	lds	Temp1, Gov_Active
	cp	Temp1, Zero
	breq	calc_governor_int_error_exit

	; Load integral
	lds	Temp3, Gov_Integral_L
	lds	Temp4, Gov_Integral_H
	lds	Temp5, Gov_Integral_X
	; Load proportional
	lds	Temp1, Gov_Proportional_L
	lds	Temp2, Gov_Proportional_H
	; Add to integral
	add	Temp3, Temp1
	adc	Temp4, Temp2
	adc	Temp5, Temp2

	; Check integral and limit
	ldi	Temp2, 0xf0				; Is error too negative?
	cp	Temp5, Temp2
	brlt	governor_limit_int_error_neg	; Yes - limit

	ldi	Temp2, 0x0f				; Is error too positive?
	cp	Temp5, Temp2
	brge	governor_limit_int_error_pos	; Yes - limit
	rjmp	governor_check_pwm

governor_limit_int_error_pos:
	ldi	Temp3, 0xff				; Limit to max positive (2's complement)
	ldi	Temp4, 0xff
	ldi	Temp2, 0x0f
	mov	Temp5, Temp2
	rjmp	governor_check_pwm

governor_limit_int_error_neg:
	ldi	Temp3, 0x00				; Limit to max negative (2's complement)
	ldi	Temp4, 0x00
	ldi	Temp2, 0xf0
	mov	Temp5, Temp2

governor_check_pwm:
	; Check current pwm
	lds	Temp2, Pwm_Limit
	cp	Current_Pwm, Temp2			; Is current pwm above pwm limit?
	mov	Temp2, Current_Pwm			; Load current pwm before continuing
	brsh	governor_int_max_pwm		; Yes

	cpi	Temp2, 1					; Is current below pwm min?
	brlo	governor_int_min_pwm		; Yes
	rjmp	governor_store_int_error		; No - store integral error

governor_int_max_pwm:
	tst	Temp1					; Is proportional error positive? (high byte is always zero)
	brmi	calc_governor_int_error_exit	; No - exit (do not integrate further)
	rjmp	governor_store_int_error		; Yes - store integral error

governor_int_min_pwm:
	tst	Temp1					; Is proportional error positive? (high byte is always zero)
	brpl	calc_governor_int_error_exit	; Yes - exit (do not integrate further)

governor_store_int_error:
	; Store integral
	sts	Gov_Integral_L, Temp3
	sts	Gov_Integral_H, Temp4
	sts	Gov_Integral_X, Temp5
calc_governor_int_error_exit:
	ret						


; Fourth governor routine - calculate governor proportional correction
calc_governor_prop_correction:
	; Exit if governor is inactive
	lds	Temp1, Gov_Active
	cp	Temp1, Zero
	breq	calc_governor_prop_corr_exit

	; Load proportional
	lds	Temp1, Gov_Proportional_L	; Only low byte required (high byte is always zero)
	; Apply proportional gain
	clr	Temp2					; Sign extend high byte
	sbrc	Temp1, 7
	com	Temp2
	lsl	Temp1					; Nominal multiply by 2
	rol	Temp2
	lds	Temp4, Pgm_Gov_P_Gain		; Load proportional gain
	sbrc	Temp4, 0					; Is lsb 1?
	rjmp	calc_governor_prop_corr_15	; Yes - go to multiply by 1.5	

	cpi	Temp4, 4					; Is proportional gain 1?
	breq	governor_limit_prop_corr		; Yes - branch

	asr	Temp2					; Gain is 0.5 - divide by 2
	ror	Temp1
	rjmp	governor_limit_prop_corr

calc_governor_prop_corr_15:
	mov	Temp6, Temp2				; Load a copy
	mov	Temp5, Temp1
	asr	Temp6					; Divide by 2
	ror	Temp5
	add	Temp1, Temp5				; Add a half
	adc	Temp2, Temp6
	cpi	Temp4, 5					; Is proportional gain 1.5?
	breq	governor_limit_prop_corr		; Yes - branch

	asr	Temp2					; No - divide by 2
	ror	Temp1
	cpi	Temp4, 3					; Is proportional gain 0.75?
	breq	governor_limit_prop_corr		; Yes - branch

	asr	Temp2					; No - divide by 2
	ror	Temp1

governor_limit_prop_corr:	; Check error and limit (to low byte)
	ldi	Temp3, 0xff				; Is error too negative?
	cpi	Temp1, 0x80	 			
	cpc	Temp2, Temp3
	brlt	governor_limit_prop_corr_neg	; Yes - limit

	ldi	Temp3, 0x00				; Is error too positive?
	cpi	Temp1, 0x7f				
	cpc	Temp2, Temp3
	brge	governor_limit_prop_corr_pos	; Yes - limit
	rjmp	governor_apply_prop_corr

governor_limit_prop_corr_pos:
	ldi	Temp1, 0x7f				; Limit to max positive (2's complement)
	ldi	Temp2, 0x00
	rjmp	governor_apply_prop_corr

governor_limit_prop_corr_neg:
	ldi	Temp1, 0x80				; Limit to max negative (2's complement)
	ldi	Temp2, 0xff

governor_apply_prop_corr:
	; Load requested pwm
	mov	Temp3, Governor_Req_Pwm
	; Test proportional sign
	tst	Temp1					; Is proportional negative?
	brmi	governor_corr_neg_prop		; Yes - go to correct negative

	; Subtract positive proportional
	sub	Temp3, Temp1
	; Check result
	brcs	governor_corr_prop_min_pwm	; Is result negative?

	cpi	Temp3, 1					; Is result below pwm min?
	brlo	governor_corr_prop_min_pwm	; Yes
	rjmp	governor_store_prop_corr		; No - store proportional correction

governor_corr_prop_min_pwm:
	ldi	Temp3, 1					; Load minimum pwm
	rjmp	governor_store_prop_corr

governor_corr_neg_prop:
	; Add negative proportional
	neg	Temp1
	add	Temp3, Temp1
	; Check result
	brcs	governor_corr_prop_max_pwm	; Is result above max?
	rjmp	governor_store_prop_corr		; No - store proportional correction

governor_corr_prop_max_pwm:
	ldi	Temp3, 255				; Load maximum pwm
governor_store_prop_corr:
	; Store proportional pwm
	sts	Gov_Prop_Pwm, Temp3
calc_governor_prop_corr_exit:
	ret


; Fifth governor routine - calculate governor integral correction
calc_governor_int_correction:
	; Exit if governor is inactive
	lds	Temp1, Gov_Active
	cp	Temp1, Zero
	breq	calc_governor_int_corr_exit

	; Load integral
	lds	Temp2, Gov_Integral_H
	lds	Temp3, Gov_Integral_X
	; Apply integrator gain
	lds	Temp4, Pgm_Gov_I_Gain		; Load integral gain
	sbrc	Temp4, 0					; Is lsb 1?
	rjmp	calc_governor_int_corr_15	; Yes - go to multiply by 1.5	

	cpi	Temp4, 4					; Is integral gain 1?
	breq	governor_limit_int_corr		; Yes - branch

	asr	Temp3					; Gain is 0.5 - divide by 2
	ror	Temp2
	rjmp	governor_limit_int_corr

calc_governor_int_corr_15:
	mov	Temp6, Temp3				; Load a copy
	mov	Temp5, Temp2
	asr	Temp6					; Divide by 2
	ror	Temp5
	add	Temp2, Temp5				; Add a half
	adc	Temp3, Temp6
	cpi	Temp4, 5					; Is integral gain 1.5?
	breq	governor_limit_int_corr		; Yes - branch

	asr	Temp3					; No - divide by 2
	ror	Temp2
	cpi	Temp4, 3					; Is integral gain 0.75?
	breq	governor_limit_int_corr		; Yes - branch

	asr	Temp3					; No - divide by 2
	ror	Temp2

governor_limit_int_corr:
	; Check integral and limit
	ldi	Temp1, 0xff				; Is integral too negative?
	cpi	Temp2, 0x00				
	cpc	Temp3, Temp1
	brlt	governor_limit_int_corr_neg	; Yes - limit

	ldi	Temp1, 0x00				; Is integral too positive?
	cpi	Temp2, 0xff				
	cpc	Temp3, Temp1
	brge	governor_limit_int_corr_pos	; Yes - limit
	rjmp	governor_apply_int_corr

governor_limit_int_corr_pos:
	ldi	Temp2, 0xff				; Limit to max positive (2's complement)
	ldi	Temp3, 0x00
	rjmp	governor_apply_int_corr

governor_limit_int_corr_neg:
	ldi	Temp2, 0x00				; Limit to max negative (2's complement)
	ldi	Temp3, 0xff

governor_apply_int_corr:
	; Load proportional pwm
	lds	Temp1, Gov_Prop_Pwm
	; Test integral sign
	tst	Temp3					; Is integral negative?
	brmi	governor_corr_neg_int		; Yes - go to correct negative

	; Subtract positive integral
	sub	Temp1, Temp2
	; Check result
	brcs	governor_corr_int_min_pwm	; Is result negative?
	cpi	Temp1, 1					; Is result below pwm min?
	brlo	governor_corr_int_min_pwm	; Yes
	rjmp	governor_store_int_corr		; No - store correction

governor_corr_int_min_pwm:
	ldi	Temp1, 1					; Load minimum pwm
	rjmp	governor_store_int_corr

governor_corr_neg_int:
	; Add negative integral
	com	Temp2			; Invert
	inc	Temp2			; Add one
	add	Temp1, Temp2
	; Check result
	brcs	governor_corr_int_max_pwm	; Is result above max?
	rjmp	governor_store_int_corr		; No - store correction

governor_corr_int_max_pwm:
	ldi	Temp1, 255				; Load maximum pwm
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
.if TAIL == 0
	Start_Adc Temp1
	; Wait for ADC conversion to complete
	Get_Adc_Status Temp3
	sbrc	Temp3, ADSC
	rjmp measure_lipo_cells
	; Read ADC result
	Read_Adc_Result Temp1, Temp2
	; Stop ADC
	Stop_Adc Temp3
	; Set 1S
	ldi	Temp3, ADC_LIMIT_L
	sts	Lipo_Adc_Limit_L, Temp3
	ldi	Temp3, ADC_LIMIT_H
	sts	Lipo_Adc_Limit_H, Temp3
	ldi	Temp3, 1
	sts	Lipo_Cells, Temp3
	; Check voltage against 2S limit
	ldi	Temp3, ADC_LIMIT_L		; Load limit
	ldi	Temp4, ADC_LIMIT_H
	lsl	Temp3				; Multiply limit by 2
	rol	Temp4
	cp	Temp1, Temp3			; Voltage above limit?
	cpc	Temp2, Temp4
	brcs measure_lipo_exit		; No - exit

	sts	Lipo_Adc_Limit_L, Temp3	; Set 2S
	sts	Lipo_Adc_Limit_H, Temp4
	ldi	Temp3, 2				
	sts	Lipo_Cells, Temp3
	; Check voltage against 3S limit
	ldi	Temp3, ADC_LIMIT_L		; Load limit
	ldi	Temp4, ADC_LIMIT_H
	mov	Temp5, Temp3			; Make a copy
	mov	Temp6, Temp4			
	lsl	Temp3				; Multiply limit by 2
	rol	Temp4
	add	Temp3, Temp5			; Add limit 
	adc	Temp4, Temp6
	cp	Temp1, Temp3			; Voltage above limit?
	cpc	Temp2, Temp4
	brcs measure_lipo_exit		; No - exit

	sts	Lipo_Adc_Limit_L, Temp3	; Set 3S
	sts	Lipo_Adc_Limit_H, Temp4
	ldi	Temp3, 3				
	sts	Lipo_Cells, Temp3

measure_lipo_exit:
.endif
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
.if TAIL == 0
	Start_Adc Temp1
.endif
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
.if TAIL == 0
	; Wait for ADC conversion to complete
	Get_Adc_Status Temp3
	sbrc	Temp3, ADSC
	rjmp check_voltage_and_limit_power
	; Read ADC result
	Read_Adc_Result Temp1, Temp2
	; Stop ADC
	Stop_Adc Temp3
	; Check if ADC is saturated
	cpi	Temp1, 0xff
	ldi	Temp3, 0x03
	cpc	Temp2, Temp3
	brcc check_voltage_good		; ADC saturated, can not make judgement

	; Check voltage against limit
	lds	Temp3, Lipo_Adc_Limit_L	; Load limit
	lds	Temp4, Lipo_Adc_Limit_H
	cp	Temp1, Temp3			; Voltage below limit?
	cpc	Temp2, Temp4
	brcc check_voltage_good		; No - branch

	; Decrease pwm limit
	lds  Temp1, Pwm_Limit
	tst	Temp1			; Limit above zero?
	breq	check_voltage_lim	; No - branch

	dec	Temp1			; Yes - decrement limit
	sts  Pwm_Limit, Temp1
	rjmp	check_voltage_lim

check_voltage_good:
	; Increase pwm limit
	lds  Temp1, Pwm_Limit
	cpi	Temp1, 0xff		; Limit below max?
	breq	check_voltage_lim	; No - branch

	inc	Temp1			; Yes - increment limit
	sts  Pwm_Limit, Temp1

check_voltage_lim:
	cp	Current_Pwm, Temp1	; Current pwm above limit?
	brsh check_voltage_exit	; Yes - branch and limit

	mov	Temp1, Current_Pwm	; No - set current pwm

check_voltage_exit:
	mov  Current_Pwm_Limited, Temp1
.else
	mov  Current_Pwm_Limited, Current_Pwm	; Direct transfer for tail
.endif
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
	sbrc	Flags0, SETTLE_MODE		; Is it motor start settle mode?
	ldi	Temp1, PWM_SETTLE		; Yes - set settle power
	sbrc	Flags0, STEPPER_MODE	; Is it motor start stepper mode?
	ldi	Temp1, PWM_STEPPER		; Yes - set stepper power
	sbrc	Flags0, AQUISITION_MODE	; Is it motor start aquisition mode?
	ldi	Temp1, PWM_AQUISITION	; Yes - set aquisition power
	sbrc	Flags0, INITIAL_RUN_MODE	; Is it initial run mode?
	ldi	Temp1, PWM_INITIAL_RUN	; Yes - set initial run power

	; Update pwm variables if any startup mode flag is set
	mov	Temp2, Flags0
	andi	Temp2, (1<<SETTLE_MODE)+(1<<STEPPER_MODE)+(1<<AQUISITION_MODE)+(1<<INITIAL_RUN_MODE)
	tst	Temp2				; Any startup mode set?
	breq	startup_pwm_exit		; No - exit

	; Adjust startup power
	lds	Temp3, Pgm_Startup_Pwr	
	cpi	Temp3, 3				; Is gain 1?
	breq	startup_pwm_set_pwm		; Yes - skip adjustment

	mov	Temp2, Temp1		
	lsr	Temp2		; After this "0.5"
	sbrc	Temp3, 0				; Is bit 0 in gain set?
	rjmp	startup_pwm_corr		; Yes - two gain correction steps

	lsr	Temp2		; After this "0.25"

startup_pwm_corr:
	sbrc	Temp3, 2				; Is bit 2 in gain set?
	rjmp	startup_pwm_gain_pos	; Yes - positive correction

	sub	Temp1, Temp2			; Apply negative correction
	rjmp	startup_pwm_set_pwm

startup_pwm_gain_pos:
	add	Temp1, Temp2			; Apply positive correction
	brcc	startup_pwm_set_pwm		; Above max?

	ldi	Temp1, 0xff			; Yes - limit

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
	ldi	YL, low(STEPPER_STEP_BEG)
	ldi	YH, high(STEPPER_STEP_BEG)
	sts	Wt_Stepper_Step_L, YL 	; Initialize stepper step time 
	sts	Wt_Stepper_Step_H, YH
	ldi	Temp3, 0xff			; Initialization value ~8.2ms
	ldi	Temp4, 0x1f
	sts	Wt_Comm_L, Temp3		; Initialize wait from zero cross to commutation
	sts	Wt_Comm_H, Temp4
	sts	Wt_Advance_L, Temp3		; Initialize wait for timing advance
	sts	Wt_Advance_H, Temp4
	lsr	Temp4				; Divide by 2
	ror	Temp3
	sts	Wt_Zc_Scan_L, Temp3		; Initialize wait before zero cross scan
	sts	Wt_Zc_Scan_H, Temp4
	ldi	Temp2, 0xff			; Set commutation period registers to very slow timing
	sts	Comm_Period4x_H, Temp2
	ldi	Temp1, 0xff
	sts	Comm_Period4x_L, Temp1
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
	lds	YL, Wt_Stepper_Step_L	; Set up stepper step wait 
	lds	YH, Wt_Stepper_Step_H
	rjmp	read_timer

calc_next_comm_timing:		; Entry point for run mode
	lds	YL, Wt_Advance_L		; Set up advance timing wait 
	lds	YH, Wt_Advance_H
read_timer:
	cli 						; Disable interrupts while reading timer 1
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	YL, Temp1				; Set new output compare value
	adc	YH, Temp2
	Set_OCR1AH YH				; Update high byte first to avoid false output compare
	Set_OCR1AL YL
	sei						; Enable interrupts
	sbr	Flags0, (1<<OCA_PENDING)	; Set timer output compare pending flag
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
	movw	YL, Temp3				; Copy timing to Y
	lsr	YH					; Divide by 2
	ror	YL
	lsr	YH					; Divide by 2 again
	ror	YL
	sub	Temp3, YL				; Subtract a quarter
	sbc	Temp4, YH
	add	Temp3, Temp1			; Add the new time
	adc	Temp4, Temp2
	sts	Comm_Period4x_L, Temp3	; Store Comm_Period4x_X
	sts	Comm_Period4x_H, Temp4
	brcs	calc_next_comm_slow		; Yes - go to slow case
	ret

calc_next_comm_slow:
	ldi	Temp2, 0xff			; Set commutation period registers to very slow timing (0xffff)
	sts	Comm_Period4x_H, Temp2
	ldi	Temp1, 0xff
	sts	Comm_Period4x_L, Temp1
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
	sbrc	Flags0, OCA_PENDING 
	rjmp	wait_advance_timing

	lds	YL, Wt_Zc_Scan_L	; Set wait to zero cross scan value
	lds	YH, Wt_Zc_Scan_H
	cli					; Disable interrupts while reading timer 1
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	Temp1, YL			; Set new output compare value
	adc	Temp2, YH
	Set_OCR1AH Temp2		; Update high byte first to avoid false output compare
	Set_OCR1AL Temp1
	sei					; Enable interrupts
	sbr	Flags0, (1<<OCA_PENDING)
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
	lds	Temp1, Comm_Period4x_L 	; Load Comm_Period4x
	lds	Temp2, Comm_Period4x_H
	lsr	Temp2				; Divide by 2
	ror	Temp1
	lsr	Temp2				; Divide by 2 again
	ror	Temp1
	lsr	Temp2				; Divide by 2 again (prior to this it is average commutation time)
	ror	Temp1
	lsr	Temp2				; Divide by 2 again
	ror	Temp1
	subi	Temp1, COMM_TIME_RED
	sbc	Temp2, Zero			
	brcs	load_min_time			; Check that result is still positive
	cpi	Temp1, COMM_TIME_MIN
	cpc	Temp2, Zero			
	brcc	store_times			; Check that result is still above minumum

load_min_time:
	ldi	Temp1, COMM_TIME_MIN
	clr	Temp2

store_times:
	sts	Wt_Comm_L, Temp1		; Now commutation time (~60�) divided by 4 (~15�)
	sts	Wt_Comm_H, Temp2
	sts	Wt_Advance_L, Temp1		; New commutation advance time (15�)
	sts	Wt_Advance_H, Temp2
	lsr	Temp2				; Divide by 2
	ror	Temp1
	sts	Wt_Zc_Scan_L, Temp1		; Use this value for zero cross scan delay (7.5�)
	sts	Wt_Zc_Scan_H, Temp2
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
	sbrc	Flags0, OCA_PENDING 
	rjmp	wait_before_zc_scan

	lds	YL, Comm_Period4x_L	; Set wait to zero comm period 4x value
	lds	YH, Comm_Period4x_H
	cli					; Disable interrupts while reading timer 1
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	Temp1, YL			; Set new output compare value
	adc	Temp2, YH
	Set_OCR1AH Temp2		; Update high byte first to avoid false output compare
	Set_OCR1AL Temp1
	sei					; Enable interrupts
	sbr	Flags0, (1<<OCA_PENDING)
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
	sei						; Enable interrupts
	sbrs	Flags0, OCA_PENDING		; Has zero cross scan timeout elapsed?
	ret						; Yes - return
	sbrc	Flags1, PWM_OFF_DAMPED	; Is it damped operation?
	rjmp use_stored_comp_out_low	; Yes - use stored comparator output
	rjmp	read_comp_out_low		; No - read comparator output

use_stored_comp_out_low:
	sbrc	Flags1, COMP_STORED		; Is comparator low?
	rjmp	wait_for_comp_out_low	; No - loop, while high
	sei						; Enable interrupts
	ret

read_comp_out_low:
	ldi	Temp1, 6				; Load number of wait cycles
	; Select number of comparator readings based upon current pwm
	mov 	Temp3, Current_Pwm_Limited	; Load current pwm
	com	Temp3					; Invert
	swap	Temp3					; Swap nibbles (bits7:4 go to bits3:0)
	lsr	Temp3					; Shift right (original bits7:5 will now be in bits2:0)
	andi	Temp3, 0x07				; Take 3 lsbs (that were originally msbs)
	inc	Temp3					; Add 1 to ensure always 1 or higher
	cli							; Disable interrupts

pwm_wait_low:						; Wait some cycles after pwm has been switched on (motor wire electrical settling)
	dec	Temp1
	brne	pwm_wait_low

comp_read_low:
	Read_Comp_Out Temp2			; Read comparator output
	sbrc	Temp2, ACO			; Is comparator output low?
	rjmp	wait_for_comp_out_low	; No - go back
	dec	Temp3				; Decrement readings counter
	brne	comp_read_low			; Repeat comparator reading if not zero
	sei						; Enable interrupts
	ret						; Yes - return

wait_for_comp_out_high:
	sei						; Enable interrupts
	sbrs	Flags0, OCA_PENDING		; Has zero cross scan timeout elapsed?
	ret						; Yes - return
	sbrc	Flags1, PWM_OFF_DAMPED	; Is it damped operation?
	rjmp use_stored_comp_out_high	; Yes - use stored comparator output
	rjmp	read_comp_out_high		; No - read comparator output

use_stored_comp_out_high:
	sbrs	Flags1, COMP_STORED		; Is comparator high?
	rjmp	wait_for_comp_out_high	; No - loop, while low
	sei						; Enable interrupts
	ret						; Yes - return

read_comp_out_high:
	ldi	Temp1, 6				; Load number of wait cycles
	; Select number of comparator readings based upon current pwm
	mov 	Temp3, Current_Pwm_Limited	; Load current pwm
	com	Temp3					; Invert
	swap	Temp3					; Swap nibbles (bits7:4 go to bits3:0)
	lsr	Temp3					; Shift right (original bits7:5 will now be in bits2:0)
	andi	Temp3, 0x07				; Take 3 lsbs (that were originally msbs)
	inc	Temp3					; Add 1 to ensure always 1 or higher
	cli							; Disable interrupts

pwm_wait_high:						; Wait some cycles after pwm has been switched on (motor wire electrical settling)
	dec	Temp1
	brne	pwm_wait_high

comp_read_high:
	Read_Comp_Out Temp2			; Read comparator output
	sbrs	Temp2, ACO			; Is comparator output high?
	rjmp	wait_for_comp_out_high	; No - go back
	dec	Temp3				; Decrement readings counter
	brne	comp_read_high			; Repeat comparator reading if not zero
	sei						; Enable interrupts
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
	lds	YL, Wt_Comm_L		; Set wait commutation value
	lds	YH, Wt_Comm_H
	cli					; Disable interrupts while reading timer 1
	Read_TCNT1L Temp1
	Read_TCNT1H Temp2
	add	Temp1, YL			; Set new output compare value
	adc	Temp2, YH
	Set_OCR1AH Temp2		; Update high byte first to avoid false output compare
	Set_OCR1AL Temp1
	sei					; Enable interrupts
	sbr	Flags0, (1<<OCA_PENDING)
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
	sbrc	Flags0, OCA_PENDING
	rjmp	wait_for_comm
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
comm1comm2damped:	
	cli					; Disable interrupts
	ldi	XL, low(pwm_cnfet_apfet_on)
	ldi	XH, high(pwm_cnfet_apfet_on)
	movw	ZL, XL			; Atomic set (read by ISR)
	BpFET_off				; Yes - Bp off
	ApFET_on				; Ap on
	Set_Comp_Phase_B Temp1	; Set comparator to phase B
	sei					; Enable interrupts
	ret

comm2comm3damped:	
	cli						; Disable interrupts
	ldi	XL, low(pwm_bnfet_apfet_on)
	ldi	XH, high(pwm_bnfet_apfet_on)
	movw	ZL, XL				; Atomic set (read by ISR)
	CnFET_off					; Cn off
	sbrc	Flags1, PWM_ON			; Is pwm on?
	BnFET_on					; Yes Bn on
	Set_Comp_Phase_C Temp1		; Set comparator to phase C
	sei						; Enable interrupts
	ret

comm3comm4damped:	
	cli					; Disable interrupts
	ldi	XL, low(pwm_bnfet_cpfet_on)
	ldi	XH, high(pwm_bnfet_cpfet_on)
	movw	ZL, XL			; Atomic set (read by ISR)
	ApFET_off				; Yes - Ap off
	CpFET_on				; Cp on
	Set_Comp_Phase_A Temp1	; Set comparator to phase A
	sei					; Enable interrupts
	ret

comm4comm5damped:	
	cli						; Disable interrupts
	ldi	XL, low(pwm_anfet_cpfet_on)
	ldi	XH, high(pwm_anfet_cpfet_on)
	movw	ZL, XL				; Atomic set (read by ISR)
	BnFET_off					; Bn off
	sbrc	Flags1, PWM_ON			; Is pwm on?
	AnFET_on					; Yes An on
	Set_Comp_Phase_B Temp1		; Set comparator to phase B
	sei						; Enable interrupts
	ret

comm5comm6damped:	
	cli					; Disable interrupts
	ldi	XL, low(pwm_anfet_bpfet_on)
	ldi	XH, high(pwm_anfet_bpfet_on)
	movw	ZL, XL			; Atomic set (read by ISR)
	CpFET_off				; Yes - Cp off
	BpFET_on				; Bp on
	Set_Comp_Phase_C Temp1	; Set comparator to phase C
	sei					; Enable interrupts
	ret

comm6comm1damped:	
	cli						; Disable interrupts
	ldi	XL, low(pwm_cnfet_bpfet_on)
	ldi	XH, high(pwm_cnfet_bpfet_on)
	movw	ZL, XL				; Atomic set (read by ISR)
	AnFET_off					; An off
	sbrc	Flags1, PWM_ON			; Is pwm on?
	CnFET_on					; Yes Cn on
	Set_Comp_Phase_A Temp1		; Set comparator to phase A
	sei						; Enable interrupts
	ret

comm1comm2:	
	cli					; Disable interrupts
	BpFET_off				; Bp off
	ApFET_on				; Ap on
	Set_Comp_Phase_B Temp1	; Set comparator to phase B
	sei					; Enable interrupts
	ret

comm2comm3:	
	cli						; Disable interrupts
	ldi	XL, low(pwm_bfet_on)	; Set Z register to desired pwm_nfet_on label	
	ldi	XH, high(pwm_bfet_on)
	movw	ZL, XL				; Atomic set (read by ISR)
	CnFET_off					; Cn off
	sbrc	Flags1, PWM_ON			; Is pwm on?
	BnFET_on					; Yes Bn on
	Set_Comp_Phase_C Temp1		; Set comparator to phase C
	sei						; Enable interrupts
	ret

comm3comm4:	
	cli					; Disable interrupts
	ApFET_off				; Ap off
	CpFET_on				; Cp on
	Set_Comp_Phase_A Temp1	; Set comparator to phase A
	sei					; Enable interrupts
	ret

comm4comm5:	
	cli						; Disable interrupts
	ldi	XL, low(pwm_afet_on)	; Set Z register to desired pwm_nfet_on label
	ldi	XH, high(pwm_afet_on)
	movw	ZL, XL				; Atomic set (read by ISR)
	BnFET_off					; Bn off
	sbrc	Flags1, PWM_ON			; Is pwm on?
	AnFET_on					; Yes An on
	Set_Comp_Phase_B Temp1		; Set comparator to phase B
	sei						; Enable interrupts
	ret

comm5comm6:	
	cli					; Disable interrupts
	CpFET_off				; Cp off
	BpFET_on				; Bp on
	Set_Comp_Phase_C Temp1	; Set comparator to phase C
	sei					; Enable interrupts
	ret

comm6comm1:	
	cli						; Disable interrupts
	ldi	XL, low(pwm_cfet_on)	; Set Z register to desired pwm_nfet_on label
	ldi	XH, high(pwm_cfet_on)
	movw	ZL, XL				; Atomic set (read by ISR)
	AnFET_off					; An off
	sbrc	Flags1, PWM_ON			; Is pwm on?
	CnFET_on					; Yes Cn on
	Set_Comp_Phase_A Temp1		; Set comparator to phase A
	sei						; Enable interrupts
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
	ldi	XL, low(pwm_nofet_on)	; Set Z register to desired pwm_nfet_on label
	ldi	XH, high(pwm_nofet_on)
	movw	ZL, XL				; Atomic set (read by ISR)
	All_nFETs_Off Temp1			; Turn off all nfets
	All_pFETs_Off Temp1			; Turn off all pfets
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
	lds	Temp1, Wt_Stepper_Step_L
	lds	Temp2, Wt_Stepper_Step_H
	cpi	Temp1, low(STEPPER_STEP_END)		; Minimum STEPPER_STEP_END
	ldi	Temp3, high(STEPPER_STEP_END)	
	cpc	Temp2, Temp3			
	brsh	decrement_step					; Branch if same or higher than minimum
	ret

decrement_step:
	lds	Temp1, Wt_Stepper_Step_L
	lds	Temp2, Wt_Stepper_Step_H
	subi	Temp1, low(STEPPER_STEP_DECREMENT)		
	sbci	Temp2, high(STEPPER_STEP_DECREMENT)
	sts	Wt_Stepper_Step_L, Temp1		
	sts	Wt_Stepper_Step_H, Temp2
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
	sbrc Flags0, OCA_PENDING		; Timer pending?
	rjmp	stepper_timer_wait		; Yes, go back
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
.if TAIL == 0
	ldi	Temp1, 4
	sts	Pgm_Gov_P_Gain, Temp1
	ldi	Temp1, 4
	sts	Pgm_Gov_I_Gain, Temp1
	ldi	Temp1, 1
	sts	Pgm_Gov_Mode, Temp1
	ldi	Temp1, 3
	sts	Pgm_Startup_Pwr, Temp1
	sbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)
	cbr	Flags2, (1<<PGM_RCP_PWM_POL)
.else
	ldi	Temp1, 3
	sts	Pgm_Tail_Gain, Temp1
	ldi	Temp1, 3
	sts	Pgm_Tail_Idle, Temp1
	ldi	Temp1, 3
	sts	Pgm_Startup_Pwr, Temp1
	sbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)
	cbr	Flags2, (1<<PGM_RCP_PWM_POL)
	ldi	Temp1, 3
	sts	Pgm_Gov_Mode, Temp1
.endif
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

.if TX_PGM == 1
.include "BLHeliTxPgm.inc"		; Include source code for programming the ESC with the TX
.endif

;**** **** **** **** ****
reset:
	; Disable watchdog
	Disable_Watchdog Temp1
	; Initialize MCU
	Initialize_MCU Temp1
	; Initialize stack
	ldi	Temp1, high(RAMEND)	; Stack = RAMEND
	out	SPH, Temp1
	ldi	Temp1, low(RAMEND)
	out 	SPL, Temp1
	; Switch power off
	rcall switch_power_off
	; PortB initialization
	ldi	Temp1, INIT_PB		
	out	PORTB, Temp1
	ldi	Temp1, DIR_PB
	out	DDRB, Temp1
	; PortC initialization
	ldi	Temp1, INIT_PC
	out	PORTC, Temp1
	ldi	Temp1, DIR_PC
	out	DDRC, Temp1
	; PortD initialization
	ldi	Temp1, INIT_PD
	out	PORTD, Temp1
	ldi	Temp1, DIR_PD
	out	DDRD, Temp1
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
	; Switch power off
	rcall switch_power_off
	; Timer0: clk/8 for beep control, waiting and RC pulse timeouts
	ldi	Temp1, (1<<CS01)
	Set_Timer0_CS0 Temp1
	; Timer1: clk/8 for commutation control and RC pulse measurement
	ldi	Temp1, (1<<CS11)
	Set_Timer1_CS1 Temp1
	; Timer2: clk/1 for pwm
	ldi	Temp1, (1<<CS20)
	Set_Timer2_CS2 Temp1
	; Set default programmed parameters
	rcall set_default_parameters
.if TX_PGM == 1
	; Read programmed parameters
	rcall read_eeprom_parameters
.endif
	; Initializing beep
	rcall wait200ms	
	rcall beep_f1
	rcall wait30ms
	rcall beep_f2
	rcall wait30ms
	rcall beep_f3
	rcall wait30ms
	; Initialize interrupts and registers
	Initialize_Interrupts				; Set all interrupt enable bits
	; Initialize ADC
	Initialize_Adc						; Initialize ADC operation
	sei								; Enable all interrupts
	; Measure number of lipo cells
	rcall Measure_Lipo_Cells				; Measure number of lipo cells
	; Initialize rc pulse
.if ICP == 0
	Rcp_Int_First Temp1					; Set interrupt to first edge
	Rcp_Int_Enable Temp1				; Enable interrupt
	Clear_Int_Flag Temp1				; Clear interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)			; Set first edge flag
.else
	Rcp_Icp_Int_First Temp1				; Set interrupt to first edge
	Rcp_Icp_Int_Enable Temp1				; Enable ICP interrupt
	Clear_Icp_Int_Flag Temp1				; Clear interrupt flag
	cbr	Flags2, (1<<RCP_EDGE_NO)			; Set first edge flag
.endif
	rcall wait200ms

	; Wait for zero throttle 
wait_for_zero_throttle:
	rcall wait3ms						; Wait for next pulse (NB: Uses Temp1/2/3!) 
	lds	Temp1, New_Rcp					; Load value
	cpi	Temp1, RCP_STOP				; Below stop?
	brsh	wait_for_zero_throttle			; No - start over
	rcall wait200ms

	; Validate RC pulse and measure PWM frequency
	sbr	Flags1, (1<<RCP_MEAS_PWM_FREQ) 	; Set measure pwm frequency flag
validate_rcp_start:	
	ldi	Temp2, 5						; Number of pulses to validate
	mov	Temp5, Temp2
validate_rcp_loop:	
	rcall wait3ms						; Wait for next pulse (NB: Uses Temp1/2/3!) 
validate_rcp_wait_updated:	
	sbrs	Flags2, RCP_UPDATED 			; Is there an updated RC pulse available?
	rjmp	validate_rcp_wait_updated		; No - wait for it

	lds	Temp1, New_Rcp					; Yes - load value
	cpi	Temp1, RCP_VALIDATE				; Higher than validate level?
	brlo	validate_rcp_start				; No - start over
	mov	Temp3, Flags2					; Check pwm frequency flags
	andi	Temp3, (1<<RCP_PWM_FREQ_1KHZ)+(1<<RCP_PWM_FREQ_2KHZ)+(1<<RCP_PWM_FREQ_4KHZ)+(1<<RCP_PWM_FREQ_8KHZ)
	lds	Temp4, Prev_Rcp_Pwm_Freq			; Load previous flags
	sts	Prev_Rcp_Pwm_Freq, Temp3			; Store previous flags for next pulse 
	cp	Temp3, Temp4					; New flags same as previous?
	brne	validate_rcp_start				; No - start over

	dec	Temp5						; Required number of pulses seen?
	brne	validate_rcp_loop				; No - find more

	cbr	Flags1, (1<<RCP_MEAS_PWM_FREQ) 	; Clear measure pwm frequency flag
	; Set up RC pulse interrupts after pwm frequency measurement
.if ICP == 0
	Rcp_Int_First Temp1					; Set interrupt trig to first again
	Clear_Int_Flag Temp1				; Clear interrupt flag
.else
	Rcp_Icp_Int_First Temp1				; Set interrupt trig to first again
	Clear_Icp_Int_Flag Temp1				; Clear icp interrupt flag
.endif
	cbr	Flags2, (1<<RCP_EDGE_NO)			; Set first edge flag

	; Beep arm sequence start signal
	cli								; Disable all interrupts
	rcall beep_f1						; Signal that RC pulse is ready
	rcall beep_f1
	rcall beep_f1
	sei								; Enable all interrupts
	rcall wait200ms

	; Arming sequence start
	sts	Gov_Arm_Target, Zero	; Clear governor arm target
arming_start:
	rcall wait3ms
	lds	Temp1, New_Rcp			; Load new RC pulse value
	cpi	Temp1, RCP_MAX			; Is RC pulse max?
	brlo	program_by_tx_checked	; No - branch

.if TX_PGM == 1
	rjmp program_by_tx			; Yes - start programming mode entry
.endif

program_by_tx_checked:
	lds	Temp2, Gov_Arm_Target	; Load governor arm target
	cp	Temp1, Temp2			; Is RC pulse larger than arm target?
	brlo	arm_target_updated		; No - do not update

	sts	Gov_Arm_Target, Temp1	; Yes - update arm target

arm_target_updated:
	cpi	Temp1, RCP_STOP		; Below stop?
	brsh	arming_start			; No - start over

	; Beep arm sequence end signal
	cli						; Disable all interrupts
	rcall beep_f4				; Signal that rcpulse is ready
	rcall beep_f4
	rcall beep_f4
	sei						; Enable all interrupts
	rcall wait200ms

	; Armed and waiting for power on
wait_for_power_on:
	rcall wait3ms
	lds	Temp1, New_Rcp			; Load value
	cpi	Temp1, RCP_STOP 		; Higher than stop?
	brlo	wait_for_power_on		; No - start over

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Start entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
init_start:
	rcall switch_power_off
	clr	Requested_Pwm			; Set requested pwm to zero
	clr	Governor_Req_Pwm		; Set governor requested pwm to zero
	clr	Current_Pwm			; Set current pwm to zero
	clr	Current_Pwm_Limited		; Set limited current pwm to zero
	ldi	Temp1, 0xff			; Set pwm limit to max
	sts	Pwm_Limit, Temp1
	sts	Gov_Target_L, Zero		; Set target to zero
	sts	Gov_Target_H, Zero
	sts	Gov_Integral_L, Zero	; Set integral to zero
	sts	Gov_Integral_H, Zero
	sts	Gov_Integral_X, Zero
	sts	Gov_Active, Zero
	clr	Flags0				; Clear flags0
	clr	Flags1				; Clear flags1
	sts	Rcp_Stop_Cnt, Zero		; Set RC pulse stop count to zero
	Comp_Init Temp1			; Initialize comparator
	rcall initialize_all_timings	; Initialize timing

	;**** **** **** **** ****
	; Settle mode beginning
	;**** **** **** **** **** 
	sbr	Flags1, (1<<PWM_OFF_DAMPED)	; Set damped operation
	sbr	Flags0, (1<<SETTLE_MODE)		; Set motor start settling mode flag
	rcall set_startup_pwm
	rcall comm6comm1damped		; Initialize commutation
	rcall wait1ms
	rcall comm1comm2damped
	rcall wait1ms
	rcall wait1ms
	rcall comm2comm3damped
	rcall wait3ms			
	rcall comm3comm4damped
	rcall wait3ms			
	rcall wait3ms			
	rcall comm4comm5damped
	rcall wait10ms				; Settle rotor
	rcall comm5comm6damped
	rcall wait3ms				
	rcall wait1ms			
	cbr	Flags0, (1<<SETTLE_MODE)		; Clear settling mode flag
	sbr	Flags0, (1<<STEPPER_MODE)	; Set motor start stepper mode flag
	rcall set_startup_pwm

	;**** **** **** **** ****
	; Stepper mode beginning
	;**** **** **** **** **** 
stepper_rot_beg:
	rcall comm6comm1damped			; Commutate
	rcall calc_next_comm_timing_start	; Update timing and set timer
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm1comm2damped			
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm2comm3damped			
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm3comm4damped			
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm4comm5damped			
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm5comm6damped			
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step	
	; Check stepper step versus end criteria
	lds	Temp1, Wt_Stepper_Step_L
	lds	Temp2, Wt_Stepper_Step_H
	cpi	Temp1, low(STEPPER_STEP_END)	; Minimum STEPPER_STEP_END
	ldi	Temp3, high(STEPPER_STEP_END)	
	cpc	Temp2, Temp3			
	brlo	stepper_rot_exit			; Branch if lower than minimum
	; Wait for step
	rcall stepper_timer_wait
	rjmp	stepper_rot_beg			; Next rotation

stepper_rot_exit:
	; Set aquisition mode
	cbr	Flags0, (1<<STEPPER_MODE)	; Clear motor start stepper mode flag
	sbr	Flags0, (1<<AQUISITION_MODE)	; Set aquisition mode flag
	rcall set_startup_pwm
	; Set aquisition rotation count
	ldi	Temp1, AQUISITION_ROTATIONS
	sts	Startup_Rot_Cnt, Temp1
	; Wait for step
	rcall stepper_timer_wait		; As the last part of stepper mode
	
	;**** **** **** **** ****
	; Aquisition mode beginning
	;**** **** **** **** **** 
aquisition_rot_beg:
	rcall comm6comm1damped			; Commutate
	rcall calc_next_comm_timing_start	; Update timing and set timer
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm1comm2damped
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm2comm3damped
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm3comm4damped
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm4comm5damped
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	rcall stepper_timer_wait

	rcall comm5comm6damped
	rcall calc_next_comm_timing_start	
	rcall calc_new_wait_times
	rcall decrement_stepper_step
	; Decrement startup rotation count
	lds	Temp1, Startup_Rot_Cnt
	dec	Temp1
	; Check number of aquisition rotations
	breq aquisition_rot_exit			; Branch if counter is zero
	
	; Store counter
	sts	Startup_Rot_Cnt, Temp1
	; Wait for step
	rcall stepper_timer_wait
	rjmp	aquisition_rot_beg			; Next rotation

aquisition_rot_exit:
	cbr	Flags0, (1<<AQUISITION_MODE)	; Clear aquisition mode flag
	sbr	Flags0, (1<<INITIAL_RUN_MODE)	; Set initial run mode flag
	rcall set_startup_pwm
	rcall stepper_timer_wait		; As the last part of aquisition mode

	rcall comm6comm1damped
	rcall calc_next_comm_timing	
	rcall wait_advance_timing	; Wait advance timing and start zero cross wait
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	; Wait zero cross wait and start zero cross timeout


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Run entry point
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
	; Set damped run rotation count
	ldi	Temp1, DAMPED_RUN_ROTATIONS
	sts	Startup_Rot_Cnt, Temp1

; Damped run 1 = B(p-on) + C(n-choppered) - comparator A evaluated
; Out_cA changes from high to low
damped_run1:
	rcall wait_for_comp_out_low	; Wait zero cross wait and wait for low
	sbrs	Flags0, OCA_PENDING		; Has timeout elapsed?
	rjmp	run_to_wait_for_power_on	; Yes - exit run mode

	rcall setup_comm_wait		; Setup wait time from zero cross to commutation
	rcall wait_for_comm			; Wait from zero cross to commutation
	rcall comm1comm2damped		; Commutate
	rcall calc_next_comm_timing	; Calculate next timing and start advance timing wait
	rcall wait_advance_timing	; Wait advance timing and start zero cross wait
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	; Wait zero cross wait and start zero cross timeout

; Damped run 2 = A(p-on) + C(n-choppered) - comparator B evaluated
; Out_cB changes from low to high
damped_run2:
	rcall wait_for_comp_out_high
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait		
	rcall wait_for_comm
	rcall comm2comm3damped
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

; Damped run 3 = A(p-on) + B(n-choppered) - comparator C evaluated
; Out_cC changes from high to low
damped_run3:
	rcall wait_for_comp_out_low
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait		
	rcall wait_for_comm
	rcall comm3comm4damped
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

; Damped run 4 = C(p-on) + B(n-choppered) - comparator A evaluated
; Out_cA changes from low to high
damped_run4:
	rcall wait_for_comp_out_high
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait		
	rcall wait_for_comm
	rcall comm4comm5damped
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

; Damped run 5 = C(p-on) + A(n-choppered) - comparator B evaluated
; Out_cB changes from high to low
damped_run5:
	rcall wait_for_comp_out_low
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait		
	rcall wait_for_comm
	rcall comm5comm6damped
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

; Damped run 6 = B(p-on) + A(n-choppered) - comparator C evaluated
; Out_cC changes from low to high
damped_run6:
	rcall wait_for_comp_out_high
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait		
	rcall wait_for_comm
	rcall comm6comm1damped
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

	; Decrement startup rotaton count
	lds	Temp1, Startup_Rot_Cnt
	dec	Temp1
	; Check number of aquisition rotations
	breq non_damped_run				; Branch if counter is zero

	sts	Startup_Rot_Cnt, Temp1		; No - store counter
	rjmp damped_run1				; Continue to run damped

non_damped_run:
	; Transition from damped to non-damped
	cli						; Disable interrupts
	cbr	Flags1, (1<<PWM_OFF_DAMPED)	; Clear damped flag
	All_pFETs_Off Temp1			; Turn off all pfets
	BpFET_on					; Bp on
	ldi	XL, low(pwm_cfet_on)	; Set Z register to desired pwm_nfet_on label
	ldi	XH, high(pwm_cfet_on)
	movw	ZL, XL				; Atomic set (read by ISR)
	sei						; Enable interrupts

; Run 1 = B(p-on) + C(n-choppered) - comparator A evaluated
; Out_cA changes from high to low
run1:
	rcall wait_for_comp_out_low	; Wait zero cross wait and wait for low
	sbrs	Flags0, OCA_PENDING		; Has timeout elapsed?
	rjmp	run_to_wait_for_power_on	; Yes - exit run mode

	rcall setup_comm_wait		; Setup wait time from zero cross to commutation
	rcall calc_governor_target	; Calculate governor target
	rcall wait_for_comm			; Wait from zero cross to commutation
	rcall comm1comm2			; Commutate
	rcall calc_next_comm_timing	; Calculate next timing and start advance timing wait
	rcall wait_advance_timing	; Wait advance timing and start zero cross wait
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	; Wait zero cross wait and start zero cross timeout

; Run 2 = A(p-on) + C(n-choppered) - comparator B evaluated
; Out_cB changes from low to high
run2:
	rcall wait_for_comp_out_high
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait	
	rcall calc_governor_prop_error
	rcall wait_for_comm
	rcall comm2comm3
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

; Run 3 = A(p-on) + B(n-choppered) - comparator C evaluated
; Out_cC changes from high to low
run3:
	rcall wait_for_comp_out_low
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait	
	rcall calc_governor_int_error
	rcall wait_for_comm
	rcall comm3comm4
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

; Run 4 = C(p-on) + B(n-choppered) - comparator A evaluated
; Out_cA changes from low to high
run4:
	rcall wait_for_comp_out_high
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait	
	rcall calc_governor_prop_correction
	rcall wait_for_comm
	rcall comm4comm5
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

; Run 5 = C(p-on) + A(n-choppered) - comparator B evaluated
; Out_cB changes from high to low
run5:
	rcall wait_for_comp_out_low
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait	
	rcall calc_governor_int_correction
	rcall wait_for_comm
	rcall comm5comm6
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

; Run 6 = B(p-on) + A(n-choppered) - comparator C evaluated
; Out_cC changes from low to high
run6:
	rcall wait_for_comp_out_high
	rcall start_adc_conversion
	sbrs	Flags0, OCA_PENDING
	rjmp	run_to_wait_for_power_on

	rcall setup_comm_wait	
	rcall check_voltage_and_limit_power
	rcall wait_for_comm
	rcall comm6comm1
	rcall calc_next_comm_timing
	rcall wait_advance_timing
	rcall calc_new_wait_times
	rcall wait_before_zc_scan	

	cbr	Flags0, (1<<INITIAL_RUN_MODE)	; Clear initial run mode flag

	lds	Temp1, Rcp_Stop_Cnt			; Load stop RC pulse counter value
	cpi	Temp1, RCP_STOP_LIMIT		; Is number of stop RC pulses above limit?
	brcc	run_to_wait_for_power_on		; Yes, go back to wait for poweron

	lds	Temp1, Comm_Period4x_H
	sbrc	Temp1, 7					; Is Comm_Period4x more than 32ms (~1220 eRPM)?
	brne	run_to_wait_for_power_on		; Yes - go back to motor start
	rjmp	run1						; Go back to run 1

run_to_wait_for_power_on:	
	rcall switch_power_off
	clr	Requested_Pwm			; Set requested pwm to zero
	clr	Governor_Req_Pwm		; Set governor requested pwm to zero
	clr	Current_Pwm			; Set current pwm to zero
	clr	Current_Pwm_Limited		; Set limited current pwm to zero
.if TAIL == 1
	rjmp	wait_for_power_on		; Tail - Go back to wait for power on
.else
	rjmp	validate_rcp_start		; Main - Go back to validate RC pulse
.endif

.exit
