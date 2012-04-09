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
; BLHeliTxPgm Atmel
;                                                         
;**** **** **** **** ****



;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Read eeprom byte routine
;
; Assumes data in Temp1 and address in X 
; Also assumes address high byte to be zero
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
read_eeprom_byte:
	; Wait for completion of previous write
	Check_Eeprom_Ready
	rjmp read_eeprom_byte

	; Set up address in address register
	Set_Eeprom_Address Temp2, Temp3
	; Start eeprom read
	sbi  EECR, EERE
	in 	Temp1, EEDR			
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Write eeprom byte routine
;
; Assumes data in Temp1 and address in Temp2/Temp3 
; Also assumes address high byte to be zero
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
write_eeprom_byte:
	; Wait for completion of previous write
	Check_Eeprom_Ready
	rjmp write_eeprom_byte   

	; Set up address in address register
	out 	EEDR, Temp1		
	Set_Eeprom_Address Temp2, Temp3
	; Set write enables and start writing
	cli				; Disable interrupts	
	Start_Eeprom_Write
	sei				; Enable interrupts
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Clear eeprom signature routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
clear_eeprom_signature:	
	ldi	Temp2, low(Eep_Initialized_L)
	ldi	Temp3, high(Eep_Initialized_L)
	ldi	Temp1, 0xFF
	rcall write_eeprom_byte

	ldi	Temp2, low(Eep_Initialized_H)
	ldi	Temp3, high(Eep_Initialized_H)
	ldi	Temp1, 0xFF
	rcall write_eeprom_byte
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Write eeprom signature routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
write_eeprom_signature:	
.if TAIL == 0
	ldi	Temp2, low(Eep_Initialized_L)
	ldi	Temp3, high(Eep_Initialized_L)
	ldi	Temp1, 0xA5
	rcall write_eeprom_byte

	ldi	Temp2, low(Eep_Initialized_H)
	ldi	Temp3, high(Eep_Initialized_H)
	ldi	Temp1, 0x5A
	rcall write_eeprom_byte
.else
	ldi	Temp2, low(Eep_Initialized_L)
	ldi	Temp3, high(Eep_Initialized_L)
	ldi	Temp1, 0x5A
	rcall write_eeprom_byte

	ldi	Temp2, low(Eep_Initialized_H)
	ldi	Temp3, high(Eep_Initialized_H)
	ldi	Temp1, 0xA5
	rcall write_eeprom_byte
.endif
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Read eeprom perameters routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
read_eeprom_parameters:	
.if TAIL == 0
	; Check initialized signature
	ldi	Temp2, low(Eep_Initialized_L)
	ldi	Temp3, high(Eep_Initialized_L)
	rcall read_eeprom_byte
	cpi	Temp1, 0xA5
	brne	read_eeprom_store_defaults

	ldi	Temp2, low(Eep_Initialized_H)
	ldi	Temp3, high(Eep_Initialized_H)
	rcall read_eeprom_byte
	cpi	Temp1, 0x5A
	brne	read_eeprom_store_defaults

	; Read eeprom
	ldi	Temp2, low(Eep_Pgm_Gov_P_Gain)
	ldi	Temp3, high(Eep_Pgm_Gov_P_Gain)
	rcall read_eeprom_byte
	sts	Pgm_Gov_P_Gain, Temp1

	ldi	Temp2, low(Eep_Pgm_Gov_I_Gain)
	ldi	Temp3, high(Eep_Pgm_Gov_I_Gain)
	rcall read_eeprom_byte
	sts	Pgm_Gov_I_Gain, Temp1

	ldi	Temp2, low(Eep_Pgm_Gov_Mode)
	ldi	Temp3, high(Eep_Pgm_Gov_Mode)
	rcall read_eeprom_byte
	sts	Pgm_Gov_Mode, Temp1

	ldi	Temp2, low(Eep_Pgm_Startup_Pwr)
	ldi	Temp3, high(Eep_Pgm_Startup_Pwr)
	rcall read_eeprom_byte
	sts	Pgm_Startup_Pwr, Temp1

	ldi	Temp2, low(Eep_Pgm_Pwm_Freq)
	ldi	Temp3, high(Eep_Pgm_Pwm_Freq)
	rcall read_eeprom_byte
	sbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)
	sbrc	Temp1, 1
	cbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)

	ldi	Temp2, low(Eep_Pgm_Input_Pol)
	ldi	Temp3, high(Eep_Pgm_Input_Pol)
	rcall read_eeprom_byte
	cbr	Flags2, (1<<PGM_RCP_PWM_POL)
	sbrc	Temp1, 1
	sbr	Flags2, (1<<PGM_RCP_PWM_POL)
.else
	; Check initialized signature
	ldi	Temp2, low(Eep_Initialized_L)
	ldi	Temp3, high(Eep_Initialized_L)
	rcall read_eeprom_byte
	cpi	Temp1, 0x5A
	brne	read_eeprom_store_defaults

	ldi	Temp2, low(Eep_Initialized_H)
	ldi	Temp3, high(Eep_Initialized_H)
	rcall read_eeprom_byte
	cpi	Temp1, 0xA5
	brne	read_eeprom_store_defaults

	; Read eeprom
	ldi	Temp2, low(Eep_Pgm_Tail_Gain)
	ldi	Temp3, high(Eep_Pgm_Tail_Gain)
	rcall read_eeprom_byte
	sts	Pgm_Tail_Gain, Temp1

	ldi	Temp2, low(Eep_Pgm_Tail_Idle)
	ldi	Temp3, high(Eep_Pgm_Tail_Idle)
	rcall read_eeprom_byte
	sts	Pgm_Tail_Idle, Temp1

	ldi	Temp2, low(Eep_Pgm_Startup_Pwr)
	ldi	Temp3, high(Eep_Pgm_Startup_Pwr)
	rcall read_eeprom_byte
	sts	Pgm_Startup_Pwr, Temp1

	ldi	Temp2, low(Eep_Pgm_Pwm_Freq)
	ldi	Temp3, high(Eep_Pgm_Pwm_Freq)
	rcall read_eeprom_byte
	sbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)
	sbrc	Temp1, 1
	cbr	Flags2, (1<<PGM_PWM_HIGH_FREQ)

	ldi	Temp2, low(Eep_Pgm_Input_Pol)
	ldi	Temp3, high(Eep_Pgm_Input_Pol)
	rcall read_eeprom_byte
	cbr	Flags2, (1<<PGM_RCP_PWM_POL)
	sbrc	Temp1, 1
	sbr	Flags2, (1<<PGM_RCP_PWM_POL)

	ldi	Temp1, 3
	sts	Pgm_Gov_Mode, Temp1
.endif
	rjmp	read_eeprom_exit

read_eeprom_store_defaults:
	rcall set_default_parameters	
	rcall store_eeprom_defaults	
read_eeprom_exit:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Store default parameter value in EEPROM routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
store_eeprom_defaults:
	rcall clear_eeprom_signature
.if TAIL == 0
	ldi	Temp1, 1
	sts	Tx_Pgm_Func_No, Temp1
	lds	Temp1, Pgm_Gov_P_Gain
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	ldi	Temp1, 2
	sts	Tx_Pgm_Func_No, Temp1
	lds	Temp1, Pgm_Gov_I_Gain
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	ldi	Temp1, 3
	sts	Tx_Pgm_Func_No, Temp1
	lds	Temp1, Pgm_Gov_Mode
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	ldi	Temp1, 4
	sts	Tx_Pgm_Func_No, Temp1
	lds	Temp1, Pgm_Startup_Pwr
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	ldi	Temp1, 5
	sts	Tx_Pgm_Func_No, Temp1
	ldi	Temp1, 1
	sbrs	Flags2, PGM_PWM_HIGH_FREQ
	ldi	Temp1, 2
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	ldi	Temp1, 6
	sts	Tx_Pgm_Func_No, Temp1
	ldi	Temp1, 1
	sbrc	Flags2, PGM_RCP_PWM_POL
	ldi	Temp1, 2
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	rcall write_eeprom_signature
.else
	ldi	Temp1, 1
	sts	Tx_Pgm_Func_No, Temp1
	lds	Temp1, Pgm_Tail_Gain
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	ldi	Temp1, 2
	sts	Tx_Pgm_Func_No, Temp1
	lds	Temp1, Pgm_Tail_Idle
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	ldi	Temp1, 3
	sts	Tx_Pgm_Func_No, Temp1
	lds	Temp1, Pgm_Startup_Pwr
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	ldi	Temp1, 4
	sts	Tx_Pgm_Func_No, Temp1
	ldi	Temp1, 1
	sbrs	Flags2, PGM_PWM_HIGH_FREQ
	ldi	Temp1, 2
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	ldi	Temp1, 5
	sts	Tx_Pgm_Func_No, Temp1
	ldi	Temp1, 1
	sbrc	Flags2, PGM_RCP_PWM_POL
	ldi	Temp1, 2
	sts	Tx_Pgm_Paraval_No, Temp1
	rcall store_in_eeprom

	rcall write_eeprom_signature
.endif
	ret	


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Store new parameter value in EEPROM routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
store_in_eeprom:	
	lds	Temp4, Tx_Pgm_Func_No	; Function no
	lds	Temp1, Tx_Pgm_Paraval_No	; Parameter value no
.if TAIL == 0
	cpi	Temp4, 1
	breq	store_main_func_1
	cpi	Temp4, 2
	breq	store_main_func_2
	cpi	Temp4, 3
	breq	store_main_func_3
	cpi	Temp4, 4
	breq	store_main_func_4
	cpi	Temp4, 5
	breq	store_main_func_5
	cpi	Temp4, 6
	breq	store_main_func_6

store_main_func_1:
	ldi	Temp2, low(Eep_Pgm_Gov_P_Gain)
	ldi	Temp3, high(Eep_Pgm_Gov_P_Gain)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit

store_main_func_2:
	ldi	Temp2, low(Eep_Pgm_Gov_I_Gain)
	ldi	Temp3, high(Eep_Pgm_Gov_I_Gain)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit

store_main_func_3:
	ldi	Temp2, low(Eep_Pgm_Gov_Mode)
	ldi	Temp3, high(Eep_Pgm_Gov_Mode)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit

store_main_func_4:
	ldi	Temp2, low(Eep_Pgm_Startup_Pwr)
	ldi	Temp3, high(Eep_Pgm_Startup_Pwr)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit

store_main_func_5:
	ldi	Temp2, low(Eep_Pgm_Pwm_Freq)
	ldi	Temp3, high(Eep_Pgm_Pwm_Freq)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit

store_main_func_6:
	ldi	Temp2, low(Eep_Pgm_Input_Pol)
	ldi	Temp3, high(Eep_Pgm_Input_Pol)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit
.else
	cpi	Temp4, 1
	breq	store_tail_func_1
	cpi	Temp4, 2
	breq	store_tail_func_2
	cpi	Temp4, 3
	breq	store_tail_func_3
	cpi	Temp4, 4
	breq	store_tail_func_4
	cpi	Temp4, 5
	breq	store_tail_func_5

store_tail_func_1:
	ldi	Temp2, low(Eep_Pgm_Tail_Gain)
	ldi	Temp3, high(Eep_Pgm_Tail_Gain)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit

store_tail_func_2:
	ldi	Temp2, low(Eep_Pgm_Tail_Idle)
	ldi	Temp3, high(Eep_Pgm_Tail_Idle)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit

store_tail_func_3:
	ldi	Temp2, low(Eep_Pgm_Startup_Pwr)
	ldi	Temp3, high(Eep_Pgm_Startup_Pwr)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit

store_tail_func_4:
	ldi	Temp2, low(Eep_Pgm_Pwm_Freq)
	ldi	Temp3, high(Eep_Pgm_Pwm_Freq)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit

store_tail_func_5:
	ldi	Temp2, low(Eep_Pgm_Input_Pol)
	ldi	Temp3, high(Eep_Pgm_Input_Pol)
	rcall write_eeprom_byte
	rjmp	store_in_eeprom_exit
.endif

store_in_eeprom_exit:
	ret


;**;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait 1 second routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait1s:
	ldi	Temp1, 5
	mov	Temp5, Temp1
wait1s_loop:
	rcall wait200ms
	dec	Temp5
	brne	wait1s_loop
	ret


;**;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Success beep routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
success_beep:
	cli						; Disable all interrupts
	rcall beep_f1
	rcall beep_f2
	rcall beep_f3
	rcall beep_f4
	rcall wait10ms
	rcall beep_f1
	rcall beep_f2
	rcall beep_f3
	rcall beep_f4
	rcall wait10ms
	rcall beep_f1
	rcall beep_f2
	rcall beep_f3
	rcall beep_f4
	sei						; Enable all interrupts
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Function and parameter value beep routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
function_paraval_beep:
	lds	Temp5, Tx_Pgm_Func_No	; Function no
	lds	Temp6, Tx_Pgm_Paraval_No	; Parameter value no
	cli						; Disable all interrupts
function_beep:
	rcall beep_f1				
	rcall beep_f1
	rcall beep_f1
	rcall wait10ms
	dec	Temp5
	brne	function_beep
paraval_beep:
	rcall beep_f4
	rcall wait10ms
	dec	Temp6
	brne	paraval_beep
	sei						; Enable all interrupts
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Program by TX routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
program_by_tx:	
	; Start programming mode entry sequence by waiting for low RC pulse
	cli						; Disable all interrupts
	rcall beep_f4
	sei						; Enable all interrupts
	rcall wait100ms
	lds	Temp1, New_Rcp			; Load new RC pulse value
	cpi	Temp1, RCP_STOP		; Below stop?
	brsh	program_by_tx			; No - start over

	; Continue programming mode entry sequence by waiting for high RC pulse
wait_for_rc_pulse_max:
	cli						; Disable all interrupts
	rcall beep_f1
	rcall wait10ms
	rcall beep_f1
	sei						; Enable all interrupts
	rcall wait100ms
	lds	Temp1, New_Rcp			; Load new RC pulse value
	cpi	Temp1, RCP_MAX			; Above max?
	brlo	wait_for_rc_pulse_max	; No - start over

	; Programming mode entry beeps
	rcall success_beep
	rcall wait1s
	rcall wait1s

	; Start at function 1, parameter value 1
	ldi	Temp1, 1
	sts	Tx_Pgm_Func_No, Temp1
paraval_no_entry:
	ldi	Temp1, 1
	sts	Tx_Pgm_Paraval_No, Temp1
beep_no_entry:
	ldi	Temp1, 0
	sts	Tx_Pgm_Beep_No, Temp1
func_paraval:
	rcall function_paraval_beep
	ldi	Temp1, 5				; Wait is 5x 200ms
	mov	Temp5, Temp1
func_paraval_wait:
	rcall wait200ms
	lds	Temp1, New_Rcp			; Load new rc pulse value
	cpi	Temp1, RCP_STOP		; Below stop?
	brsh	func_paraval_cont_wait	; No - branch

	rcall clear_eeprom_signature	; Clear signature
	rcall store_in_eeprom		; Yes - store new value in EEPROM
	rcall write_eeprom_signature	; Write signature
	rcall success_beep			; Beep success
	Enable_Watchdog Temp1		; Generate hardware reset from watchdog
	rcall wait1s

func_paraval_cont_wait:
	dec	Temp5
	brne	func_paraval_wait
	lds	Temp1, Tx_Pgm_Beep_No	; Load and check number of beeps
	inc	Temp1
	sts	Tx_Pgm_Beep_No, Temp1
	cpi	Temp1, 3				; Three beeps done?
	brsh	paraval_next			; Yes - Next parameter value

	rjmp	func_paraval			; No - go back

paraval_next:					
	rcall wait1s
	lds	Temp1, Tx_Pgm_Paraval_No	; Parameter value no
	inc	Temp1
	sts	Tx_Pgm_Paraval_No, Temp1
	ldi	Temp2, 5				; Default 5 parameter values
.if TAIL == 0
	lds	Temp1, Tx_Pgm_Func_No
	cpi	Temp1, 3				; Function 3?
	brne paraval_end_a			; No - branch
	ldi	Temp2, 3				; Yes - set max parameter values
paraval_end_a:
	lds	Temp1, Tx_Pgm_Func_No
	cpi	Temp1, 5				; Function below 5?
	brlo paraval_end_b			; Yes - branch
	ldi	Temp2, 2				; No - set max parameter values
paraval_end_b:
.else
	lds	Temp1, Tx_Pgm_Func_No
	cpi	Temp1, 4				; Function below 4?
	brlo paraval_end_a			; Yes - branch
	ldi	Temp2, 2				; No - set max parameter values
paraval_end_a:
.endif
	inc	Temp2
	lds	Temp1, Tx_Pgm_Paraval_No	
	cp	Temp1, Temp2
	brsh function_next			; Last parameter value?
	rjmp	beep_no_entry			; No - go back

function_next:					; Yes - Next function value
	rcall wait1s
	rcall wait1s
	lds	Temp1, Tx_Pgm_Func_No	; Function value no
	inc	Temp1
	sts	Tx_Pgm_Func_No, Temp1
.if TAIL == 0
	cpi	Temp1, 7				; Main has 6 functions
.else
	cpi	Temp1, 6				; Tail has 5 functions
.endif
	brsh program_by_tx_exit		; Last function value?
	rjmp	paraval_no_entry		; No - go back

program_by_tx_exit:
	Enable_Watchdog Temp1		; Generate hardware reset from watchdog
	rcall wait1s

