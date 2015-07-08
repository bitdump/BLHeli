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
; BLHeliTxPgm Atmel                                      
;                                                         
;**** **** **** **** ****


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Read all eeprom parameters routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
read_all_eeprom_parameters:	
.IF MODE == 0	; Main
	; Check initialized signature
	ldi	ZL, low(Eep_Initialized_L)
	ldi	ZH, high(Eep_Initialized_L)
	xcall read_eeprom_byte
	cpi	Temp1, 0xA5
	breq	PC+2
	rjmp	read_eeprom_store_defaults

	ldi	ZL, low(Eep_Initialized_H)
	ldi	ZH, high(Eep_Initialized_H)
	xcall read_eeprom_byte
	cpi	Temp1, 0x5A
	breq	PC+2
	rjmp	read_eeprom_store_defaults

.ENDIF
.IF MODE == 1	; Tail
	; Check initialized signature
	ldi	ZL, low(Eep_Initialized_L)
	ldi	ZH, high(Eep_Initialized_L)
	xcall read_eeprom_byte
	cpi	Temp1, 0x5A
	breq	PC+2
	rjmp	read_eeprom_store_defaults

	ldi	ZL, low(Eep_Initialized_H)
	ldi	ZH, high(Eep_Initialized_H)
	xcall read_eeprom_byte
	cpi	Temp1, 0xA5
	breq	PC+2
	rjmp	read_eeprom_store_defaults

.ENDIF
.IF MODE == 2	; Multi
	; Check initialized signature
	ldi	ZL, low(Eep_Initialized_L)
	ldi	ZH, high(Eep_Initialized_L)
	xcall read_eeprom_byte
	cpi	Temp1, 0x55
	breq	PC+2
	rjmp	read_eeprom_store_defaults

	ldi	ZL, low(Eep_Initialized_H)
	ldi	ZH, high(Eep_Initialized_H)
	xcall read_eeprom_byte
	cpi	Temp1, 0xAA
	breq	PC+2
	rjmp	read_eeprom_store_defaults

.ENDIF
	; Read eeprom
	ldi	Temp4, 10	; 10 parameters
	ldi	XL, low(Pgm_Gov_P_Gain)
	ldi	XH, high(Pgm_Gov_P_Gain)
.IF MODE == 0 || MODE ==2
	ldi	ZL, low(Eep_Pgm_Gov_P_Gain)
	ldi	ZH, high(Eep_Pgm_Gov_P_Gain)
.ENDIF
.IF MODE == 1
	ldi	ZL, low(_Eep_Pgm_Gov_P_Gain)
	ldi	ZH, high(_Eep_Pgm_Gov_P_Gain)
.ENDIF
read_eeprom_block1:
	xcall read_eeprom_byte
	st	X+, Temp1
	adiw	Z, 1
	dec	Temp4
	brne	read_eeprom_block1

	ldi	Temp4, 24	; 24 parameters 
	ldi	XL, low(Pgm_Enable_TX_Program)
	ldi	XH, high(Pgm_Enable_TX_Program)
	ldi	ZL, low(Eep_Enable_TX_Program)
	ldi	ZH, high(Eep_Enable_TX_Program)
read_eeprom_block2:
	xcall read_eeprom_byte
	st	X+, Temp1
	adiw	Z, 1
	dec	Temp4
	brne	read_eeprom_block2

	rjmp	read_eeprom_exit

read_eeprom_store_defaults:
	xcall set_default_parameters	
	xcall store_all_in_eeprom	
read_eeprom_exit:
	ldi	ZL, low(Eep_Dummy)			; Set pointer to uncritical area
	ldi	ZH, high(Eep_Dummy)
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Read eeprom byte routine
;
; Assumes data in Temp1 and address in Z 
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
read_eeprom_byte:
	; Wait for completion of previous write
	Check_Eeprom_Ready
	rjmp read_eeprom_byte

	; Set up address in address register
	Set_Eeprom_Address ZL, ZH
	; Start eeprom read
	sbi  EECR, EERE
	in 	Temp1, EEDR			
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Store all parameter values in EEPROM routine
;
; Assumes interrupts to be off
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
store_all_in_eeprom:
	; Clear initialized signature
	xcall clear_eeprom_signature
	; Write eeprom
	ldi	Temp4, 10	; 10 parameters
	ldi	XL, low(Pgm_Gov_P_Gain)
	ldi	XH, high(Pgm_Gov_P_Gain)
.IF MODE == 0 || MODE ==2
	ldi	ZL, low(Eep_Pgm_Gov_P_Gain)
	ldi	ZH, high(Eep_Pgm_Gov_P_Gain)
.ENDIF
.IF MODE == 1
	ldi	ZL, low(_Eep_Pgm_Gov_P_Gain)
	ldi	ZH, high(_Eep_Pgm_Gov_P_Gain)
.ENDIF
write_eeprom_block1:
	ld	Temp1, X+
	xcall write_eeprom_byte
	adiw	Z, 1
	dec	Temp4
	brne	write_eeprom_block1

	ldi	Temp4, 24	; 24 parameters 
	ldi	XL, low(Pgm_Enable_TX_Program)
	ldi	XH, high(Pgm_Enable_TX_Program)
	ldi	ZL, low(Eep_Enable_TX_Program)
	ldi	ZH, high(Eep_Enable_TX_Program)
write_eeprom_block2:
	ld	Temp1, X+
	xcall write_eeprom_byte
	adiw	Z, 1
	dec	Temp4
	brne	write_eeprom_block2

	; Write initialized signature
	xcall write_eeprom_signature
	ret	


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Write eeprom byte routine
;
; Assumes data in Temp1 and address in Z 
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
write_eeprom_byte:
	; Wait for completion of previous write
	Check_Eeprom_Ready
	rjmp write_eeprom_byte   

	; Set up address in address register
	out 	EEDR, Temp1		
	Set_Eeprom_Address ZL, ZH
	; Set write enables and start writing
	Start_Eeprom_Write
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Clear eeprom signature routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
clear_eeprom_signature:	
	ldi	ZL, low(Eep_Initialized_L)
	ldi	ZH, high(Eep_Initialized_L)
	ldi	Temp1, 0xFF
	xcall write_eeprom_byte

	ldi	ZL, low(Eep_Initialized_H)
	ldi	ZH, high(Eep_Initialized_H)
	ldi	Temp1, 0xFF
	xcall write_eeprom_byte
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Write eeprom signature routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
write_eeprom_signature:	
.IF MODE == 0	; Main
	ldi	ZL, low(Eep_Initialized_L)
	ldi	ZH, high(Eep_Initialized_L)
	ldi	Temp1, 0xA5
	xcall write_eeprom_byte

	ldi	ZL, low(Eep_Initialized_H)
	ldi	ZH, high(Eep_Initialized_H)
	ldi	Temp1, 0x5A
	xcall write_eeprom_byte
.ENDIF
.IF MODE == 1	; Tail
	ldi	ZL, low(Eep_Initialized_L)
	ldi	ZH, high(Eep_Initialized_L)
	ldi	Temp1, 0x5A
	xcall write_eeprom_byte

	ldi	ZL, low(Eep_Initialized_H)
	ldi	ZH, high(Eep_Initialized_H)
	ldi	Temp1, 0xA5
	xcall write_eeprom_byte
.ENDIF
.IF MODE == 2	; Multi
	ldi	ZL, low(Eep_Initialized_L)
	ldi	ZH, high(Eep_Initialized_L)
	ldi	Temp1, 0x55
	xcall write_eeprom_byte

	ldi	ZL, low(Eep_Initialized_H)
	ldi	ZH, high(Eep_Initialized_H)
	ldi	Temp1, 0xAA
	xcall write_eeprom_byte
.ENDIF
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Store new parameter value in ram routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
store_new_value_in_ram:	
	lds	Temp4, Tx_Pgm_Func_No	; Function no
	lds	Temp1, Tx_Pgm_Paraval_No	; Parameter value no
.IF MODE == 0
	cpi	Temp4, 1
	brne	PC+3
	sts	Pgm_Gov_P_Gain, Temp1

	cpi	Temp4, 2
	brne	PC+3
	sts	Pgm_Gov_I_Gain, Temp1

	cpi	Temp4, 3
	brne	PC+3
	sts	Pgm_Gov_Mode, Temp1

	cpi	Temp4, 4
	brne	PC+3
	sts	Pgm_Gov_Range, Temp1

	cpi	Temp4, 5
	brne	PC+3
	sts	Pgm_Low_Voltage_Lim, Temp1

	cpi	Temp4, 6
	brne	PC+3
	sts	Pgm_Startup_Pwr, Temp1

	cpi	Temp4, 7
	brne	PC+3
	sts	Pgm_Comm_Timing, Temp1

	cpi	Temp4, 8
	brne	PC+3
	sts	Pgm_Pwm_Freq, Temp1

	cpi	Temp4, 9
	brne	PC+3
	sts	Pgm_Demag_Comp, Temp1

	cpi	Temp4, 10
	brne	PC+3
	sts	Pgm_Direction, Temp1

	cpi	Temp4, 11
	brne	PC+3
	sts	Pgm_Input_Pol, Temp1
.ENDIF
.IF MODE == 1
	cpi	Temp4, 1
	brne	PC+3
	sts	Pgm_Motor_Gain, Temp1

	cpi	Temp4, 2
	brne	PC+3
	sts	Pgm_Motor_Idle, Temp1

	cpi	Temp4, 3
	brne	PC+3
	sts	Pgm_Startup_Pwr, Temp1

	cpi	Temp4, 4
	brne	PC+3
	sts	Pgm_Comm_Timing, Temp1

	cpi	Temp4, 5
	brne	PC+3
	sts	Pgm_Pwm_Freq, Temp1

	cpi	Temp4, 6
	brne	PC+3
	sts	Pgm_Pwm_Dither, Temp1

	cpi	Temp4, 7
	brne	PC+3
	sts	Pgm_Demag_Comp, Temp1

	cpi	Temp4, 8
	brne	PC+3
	sts	Pgm_Direction, Temp1

	cpi	Temp4, 9
	brne	PC+3
	sts	Pgm_Input_Pol, Temp1
.ENDIF
.IF MODE == 2
	cpi	Temp4, 1
	brne	PC+3
	sts	Pgm_Gov_P_Gain, Temp1

	cpi	Temp4, 2
	brne	PC+3
	sts	Pgm_Gov_I_Gain, Temp1

	cpi	Temp4, 3
	brne	PC+3
	sts	Pgm_Gov_Mode, Temp1

	cpi	Temp4, 4
	brne	PC+3
	sts	Pgm_Motor_Gain, Temp1

	cpi	Temp4, 5
	brne	PC+3
	sts	Pgm_Startup_Pwr, Temp1

	cpi	Temp4, 6
	brne	PC+3
	sts	Pgm_Comm_Timing, Temp1

	cpi	Temp4, 7
	brne	PC+3
	sts	Pgm_Pwm_Freq, Temp1

	cpi	Temp4, 8
	brne	PC+3
	sts	Pgm_Pwm_Dither, Temp1

	cpi	Temp4, 9
	brne	PC+3
	sts	Pgm_Demag_Comp, Temp1

	cpi	Temp4, 10
	brne	PC+3
	sts	Pgm_Direction, Temp1

	cpi	Temp4, 11
	brne	PC+3
	sts	Pgm_Input_Pol, Temp1
.ENDIF
	ret


;**;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait 1 second routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait1s:
	ldi	Temp3, 5
wait1s_loop:
	xcall wait200ms
	dec	Temp3
	brne	wait1s_loop
	ret


;**;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Success beep routine
;
; Assumes interrupts to be off
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
success_beep:
	xcall beep_f1
	xcall beep_f2
	xcall beep_f3
	xcall beep_f4
	xcall wait10ms
	xcall beep_f1
	xcall beep_f2
	xcall beep_f3
	xcall beep_f4
	xcall wait10ms
	xcall beep_f1
	xcall beep_f2
	xcall beep_f3
	xcall beep_f4
	ret


;**;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Success beep inverted routine
;
; Assumes interrupts to be off
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
success_beep_inverted:
	xcall beep_f4
	xcall beep_f3
	xcall beep_f2
	xcall beep_f1
	xcall wait10ms
	xcall beep_f4
	xcall beep_f3
	xcall beep_f2
	xcall beep_f1
	xcall wait10ms
	xcall beep_f4
	xcall beep_f3
	xcall beep_f2
	xcall beep_f1
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Function and parameter value beep routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
function_paraval_beep:
	lds	Temp7, Tx_Pgm_Func_No	; Function no
	lds	Temp8, Tx_Pgm_Paraval_No	; Parameter value no
function_beep:
	xcall beep_f1				
	xcall beep_f1
	xcall beep_f1
	xcall wait10ms
	dec	Temp7
	brne	function_beep
paraval_beep:
	xcall beep_f4
	xcall wait10ms
	dec	Temp8
	brne	paraval_beep
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Program by TX routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
program_by_tx:	
	; Programming mode entry beeps
	cli					
	xcall success_beep
	sei					
	xcall wait1s
	xcall wait1s
	; Start at function 1, parameter value 1
	ldi	XH, 1
	sts	Tx_Pgm_Func_No, XH
paraval_no_entry:
	ldi	XH, 1
	sts	Tx_Pgm_Paraval_No, XH
beep_no_entry:
	sts	Tx_Pgm_Beep_No, Zero
func_paraval:
	cli
	xcall function_paraval_beep
	sei
	ldi	XH, 5				; Wait is 5x 200ms
	mov	Temp5, XH			
func_paraval_wait:
	lds	Temp6, New_Rcp			; Load RC pulse
	xcall wait200ms
	lds	XH, New_Rcp			
	cp	Temp6, XH				; Is RC pulse stable? (Avoid issues from 3in1 interference)
	brne	func_paraval_wait		; No - branch
	cpi	XH, RCP_STOP			; Below stop?
	brcs	func_paraval_store		; Yes - branch

	cpi	XH, RCP_MAX			; Below max?
	brcs	function_next			; Yes - branch

	rjmp	func_paraval_cont_wait	; No - branch

func_paraval_store:
	xcall store_new_value_in_ram	; Yes - store new value in RAM
	cli						; Disable all interrupts
	xcall store_all_in_eeprom	; Store all values in EEPROM
	xcall success_beep			; Beep success
	Enable_Watchdog XH			; Generate hardware reset from watchdog
	xcall wait1s

func_paraval_cont_wait:
	dec	Temp5
	brne	func_paraval_wait
	lds	XH, Tx_Pgm_Beep_No		; Check number of beeps
	inc	XH
	sts	Tx_Pgm_Beep_No, XH
	cpi	XH, 3				; Three beeps done?
	brcc	paraval_next			; Yes - Next parameter value

	rjmp	func_paraval			; No - go back

paraval_next:					
	xcall wait1s
	lds	XH, Tx_Pgm_Paraval_No	; Parameter value no
	inc	XH
	sts	Tx_Pgm_Paraval_No, XH
	cli					
.IF MODE == 0
	lds	XH, Tx_Pgm_Func_No		; Decode number of parameters
	dec	XH	
	ldi	ZL, low(TX_PGM_PARAMS_MAIN<<1)
	ldi	ZH, high(TX_PGM_PARAMS_MAIN<<1)
	add	ZL, XH
	adc	ZH, Zero
	lpm	Temp1, Z
.ENDIF
.IF MODE == 1
	lds	XH, Tx_Pgm_Func_No		; Decode number of parameters
	dec	XH	
	ldi	ZL, low(TX_PGM_PARAMS_TAIL<<1)
	ldi	ZH, high(TX_PGM_PARAMS_TAIL<<1)
	add	ZL, XH
	adc	ZH, Zero
	lpm	Temp1, Z
.ENDIF
.IF MODE == 2
	lds	XH, Tx_Pgm_Func_No		; Decode number of parameters
	dec	XH	
	ldi	ZL, low(TX_PGM_PARAMS_MULTI<<1)
	ldi	ZH, high(TX_PGM_PARAMS_MULTI<<1)
	add	ZL, XH
	adc	ZH, Zero
	lpm	Temp1, Z
.ENDIF
	sei					
	inc	Temp1
	lds	XH, Tx_Pgm_Paraval_No		
	cp	XH, Temp1				
	brcc	function_next			; Last parameter value?
	rjmp	beep_no_entry			; No - go back

function_next:					; Yes - Next function value
	xcall wait1s
	xcall wait1s
	lds	XH, Tx_Pgm_Func_No		; Function value no
	inc	XH
	sts	Tx_Pgm_Func_No, XH
.IF MODE == 0
	lds	XH, Tx_Pgm_Func_No		
	cpi	XH, 12				; Main has 11 functions	
.ENDIF
.IF MODE == 1
	lds	XH, Tx_Pgm_Func_No		
	cpi	XH, 10				; Tail has 9 functions	
.ENDIF
.IF MODE == 2
	lds	XH, Tx_Pgm_Func_No		
	cpi	XH, 12				; Multi has 11 functions	
.ENDIF
	brcc	program_by_tx_exit		; Last function value?
	rjmp	paraval_no_entry		; No - go back

program_by_tx_exit:
	xcall set_default_parameters	; Load all defaults
	cli						; Disable all interrupts
	xcall store_all_in_eeprom	; Erase flash and program
	Enable_Watchdog XH			; Generate hardware reset from watchdog
	xcall wait1s

