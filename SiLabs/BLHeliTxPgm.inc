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
; BLHeliTxPgm SiLabs                                      
;                                                         
; EEPROM is not available in SiLabs MCUs                  
; Therefore a segment of the flash is used as "EEPROM"    
;                                                         
;**** **** **** **** ****



;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Read eeprom byte routine
;
; Assumes data in Temp1 and address in DPTR 
; Also assumes address high byte to be zero
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
read_eeprom_byte:
	clr	A
	movc	A, @A+DPTR			; Read from flash
	mov	Temp1, A				; Load read value
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Write eeprom byte routine
;
; Assumes data in Temp1 and address in DPTR 
; Also assumes address high byte to be zero
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
write_eeprom_byte:
	orl	PSCTL, #01h			; Set the PSWE bit
	anl	PSCTL, #0FDh			; Clear the PSEE bit
	mov	FLKEY, #0A5h			; First key code
	mov	FLKEY, #0F1h			; Second key code
	mov	A, Temp1				; Load value to be written
	movx	@DPTR, A				; Write to flash
	anl	PSCTL, #0FEh			; Clear the PSWE bit
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Clear eeprom signature routine (erases the flash segment used for "eeprom" variables)
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
clear_eeprom_signature:	
	; Erase flash
	orl	PSCTL, #02h			; Set the PSEE bit
	orl	PSCTL, #01h			; Set the PSWE bit
	mov	FLKEY, #0A5h			; First key code
	mov	FLKEY, #0F1h			; Second key code
	mov	DPTR, #Eep_Initialized_L	
	movx	@DPTR, A
	anl	PSCTL, #0FCh			; Clear the PSEE and PSWE bits
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Write eeprom signature routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
write_eeprom_signature:	
IF TAIL == 0
	mov	DPTR, #Eep_Initialized_L
	mov	Temp1, #0A5h
	call write_eeprom_byte

	mov	DPTR, #Eep_Initialized_H
	mov	Temp1, #05Ah
	call write_eeprom_byte
ELSE
	mov	DPTR, #Eep_Initialized_L
	mov	Temp1, #05Ah
	call write_eeprom_byte

	mov	DPTR, #Eep_Initialized_H
	mov	Temp1, #0A5h
	call write_eeprom_byte
ENDIF
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Read eeprom perameters routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
read_eeprom_parameters:	
IF TAIL == 0
	; Check initialized signature
	mov	DPTR, #Eep_Initialized_L
	call read_eeprom_byte
	clr	C
	mov	A, Temp1
	subb	A, #0A5h
	jnz	read_eeprom_store_defaults

	mov	DPTR, #Eep_Initialized_H
	call read_eeprom_byte
	clr	C
	mov	A, Temp1
	subb	A, #05Ah
	jnz	read_eeprom_store_defaults

	; Read eeprom
	mov	DPTR, #Eep_Pgm_Gov_P_Gain
	call read_eeprom_byte
	mov	Pgm_Gov_P_Gain, Temp1

	mov	DPTR, #Eep_Pgm_Gov_I_Gain
	call read_eeprom_byte
	mov	Pgm_Gov_I_Gain, Temp1

	mov	DPTR, #Eep_Pgm_Gov_Mode
	call read_eeprom_byte
	mov	Pgm_Gov_Mode, Temp1

	mov	DPTR, #Eep_Pgm_Low_Voltage_Lim
	call read_eeprom_byte
	mov	Pgm_Low_Voltage_Lim, Temp1

	mov	DPTR, #Eep_Pgm_Startup_Pwr
	call read_eeprom_byte
	mov	Pgm_Startup_Pwr, Temp1

	mov	DPTR, #Eep_Pgm_Pwm_Freq
	call read_eeprom_byte
	setb	Flags2.PGM_PWM_HIGH_FREQ
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	clr	Flags2.PGM_PWM_HIGH_FREQ

	mov	DPTR, #Eep_Pgm_Direction_Rev
	call read_eeprom_byte
	clr	Flags2.PGM_DIRECTION_REV
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_DIRECTION_REV

	mov	DPTR, #Eep_Pgm_Input_Pol
	call read_eeprom_byte
	clr	Flags2.PGM_RCP_PWM_POL
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_RCP_PWM_POL
ELSE
	; Check initialized signature
	mov	DPTR, #Eep_Initialized_L
	call read_eeprom_byte
	clr	C
	mov	A, Temp1
	subb	A, #05Ah
	jnz	read_eeprom_store_defaults

	mov	DPTR, #Eep_Initialized_H
	call read_eeprom_byte
	clr	C
	mov	A, Temp1
	subb	A, #0A5h
	jnz	read_eeprom_store_defaults

	; Read eeprom
	mov	DPTR, #Eep_Pgm_Tail_Gain
	call read_eeprom_byte
	mov	Pgm_Tail_Gain, Temp1

	mov	DPTR, #Eep_Pgm_Tail_Idle
	call read_eeprom_byte
	mov	Pgm_Tail_Idle, Temp1

	mov	DPTR, #Eep_Pgm_Startup_Pwr
	call read_eeprom_byte
	mov	Pgm_Startup_Pwr, Temp1

	mov	DPTR, #Eep_Pgm_Pwm_Freq
	call read_eeprom_byte
	clr	Flags2.PGM_PWM_HIGH_FREQ
	mov	A, Temp1
	jnb	ACC.0, ($+5)
	setb	Flags2.PGM_PWM_HIGH_FREQ
	clr	Flags2.PGM_PWM_OFF_DAMPED
	clr	C
	mov	A, Temp1
	subb	A, #3
	jc	($+4)
	setb	Flags2.PGM_PWM_OFF_DAMPED

	mov	DPTR, #Eep_Pgm_Direction_Rev
	call read_eeprom_byte
	clr	Flags2.PGM_DIRECTION_REV
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_DIRECTION_REV

	mov	DPTR, #Eep_Pgm_Input_Pol
	call read_eeprom_byte
	clr	Flags2.PGM_RCP_PWM_POL
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_RCP_PWM_POL

	mov	Pgm_Gov_Mode, #3
ENDIF
	jmp	read_eeprom_exit

read_eeprom_store_defaults:
	call set_default_parameters	
	call store_all_in_eeprom	
read_eeprom_exit:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Read all tags from flash and store in temporary storage
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
read_tags:
	mov	Temp3, #48				; Number of tags
	mov	Temp2, #Tag_Temporary_Storage	; Set RAM address
	mov	DPTR, #Eep_ESC_Layout		; Set flash address
read_tag:	
	call read_eeprom_byte
	mov	A, Temp1
	mov	@Temp2, A			; Write to RAM
	inc	Temp2
	inc	DPTR
	djnz Temp3, read_tag	
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Write all tags from temporary storage and store in flash
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
write_tags:
	mov	Temp3, #48				; Number of tags
	mov	Temp2, #Tag_Temporary_Storage	; Set RAM address
	mov	DPTR, #Eep_ESC_Layout		; Set flash address
write_tag:	
	mov	A, @Temp2			; Read from RAM
	mov	Temp1, A
	call write_eeprom_byte
	inc	Temp2
	inc	DPTR
	djnz Temp3, write_tag	
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Store all parameter value in EEPROM routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
store_all_in_eeprom:
	clr	EA						; Disable interrupts
	call	read_tags
	call	clear_eeprom_signature		; Erase flash

	mov	DPTR, #Eep_FW_Main_Revision	; Store firmware main revision
	mov	Temp1, #EEPROM_FW_MAIN_REVISION
	call write_eeprom_byte

	mov	DPTR, #Eep_FW_Sub_Revision	; Store firmware sub revision
	mov	Temp1, #EEPROM_FW_SUB_REVISION
	call write_eeprom_byte

	mov	DPTR, #Eep_Layout_Revision	; Store EEPROM layout revision
	mov	Temp1, #EEPROM_LAYOUT_REVISION
	call write_eeprom_byte

IF TAIL == 0
	mov	DPTR, #Eep_Pgm_Gov_P_Gain
	mov	Temp1, Pgm_Gov_P_Gain
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Gov_I_Gain
	mov	Temp1, Pgm_Gov_I_Gain
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Gov_Mode
	mov	Temp1, Pgm_Gov_Mode
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Low_Voltage_Lim
	mov	Temp1, Pgm_Low_Voltage_Lim
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Startup_Pwr
	mov	Temp1, Pgm_Startup_Pwr
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Pwm_Freq
	mov	Temp1, #1
	jb	Flags2.PGM_PWM_HIGH_FREQ, ($+5)
	mov	Temp1, #2
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Direction_Rev
	mov	Temp1, #1
	jnb	Flags2.PGM_DIRECTION_REV, ($+5)
	mov	Temp1, #2
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Input_Pol
	mov	Temp1, #1
	jnb	Flags2.PGM_RCP_PWM_POL, ($+5)
	mov	Temp1, #2
	call write_eeprom_byte
ELSE
	mov	DPTR, #Eep_Pgm_Tail_Gain
	mov	Temp1, Pgm_Tail_Gain
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Tail_Idle
	mov	Temp1, Pgm_Tail_Idle
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Startup_Pwr
	mov	Temp1, Pgm_Startup_Pwr
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Pwm_Freq
	mov	Temp1, #1
	jb	Flags2.PGM_PWM_HIGH_FREQ, ($+5)
	mov	Temp1, #2
	jnb	Flags2.PGM_PWM_OFF_DAMPED, ($+5)
	mov	Temp1, #3
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Direction_Rev
	mov	Temp1, #1
	jnb	Flags2.PGM_DIRECTION_REV, ($+5)
	mov	Temp1, #2
	call write_eeprom_byte

	mov	DPTR, #Eep_Pgm_Input_Pol
	mov	Temp1, #1
	jnb	Flags2.PGM_RCP_PWM_POL, ($+5)
	mov	Temp1, #2
	call write_eeprom_byte
ENDIF
	call	write_tags
	call write_eeprom_signature
	ret	


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Store new parameter value in ram routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
store_in_ram:	
	mov	Temp4, Tx_Pgm_Func_No	; Function no
	mov	Temp1, Tx_Pgm_Paraval_No	; Parameter value no
IF TAIL == 0
	mov	A, Temp4
	clr	C
	subb	A, #1
	jz	store_main_func_1
	mov	A, Temp4
	clr	C
	subb	A, #2
	jz	store_main_func_2
	mov	A, Temp4
	clr	C
	subb	A, #3
	jz	store_main_func_3
	mov	A, Temp4
	clr	C
	subb	A, #4
	jz	store_main_func_4
	mov	A, Temp4
	clr	C
	subb	A, #5
	jz	store_main_func_5
	mov	A, Temp4
	clr	C
	subb	A, #6
	jz	store_main_func_6
	mov	A, Temp4
	clr	C
	subb	A, #7
	jz	store_main_func_7
	mov	A, Temp4
	clr	C
	subb	A, #8
	jz	store_main_func_8

store_main_func_1:
	mov	Pgm_Gov_P_Gain, Temp1
	jmp	store_in_ram_exit

store_main_func_2:
	mov	Pgm_Gov_I_Gain, Temp1
	jmp	store_in_ram_exit

store_main_func_3:
	mov	Pgm_Gov_Mode, Temp1
	jmp	store_in_ram_exit

store_main_func_4:
	mov	Pgm_Low_Voltage_Lim, Temp1
	jmp	store_in_ram_exit

store_main_func_5:
	mov	Pgm_Startup_Pwr, Temp1
	jmp	store_in_ram_exit

store_main_func_6:
	setb	Flags2.PGM_PWM_HIGH_FREQ
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	clr	Flags2.PGM_PWM_HIGH_FREQ
	jmp	store_in_ram_exit

store_main_func_7:
	clr	Flags2.PGM_DIRECTION_REV
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_DIRECTION_REV
	jmp	store_in_ram_exit

store_main_func_8:
	clr	Flags2.PGM_RCP_PWM_POL
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_RCP_PWM_POL
	jmp	store_in_ram_exit
ELSE
	mov	A, Temp4
	clr	C
	subb	A, #1
	jz	store_tail_func_1
	mov	A, Temp4
	clr	C
	subb	A, #2
	jz	store_tail_func_2
	mov	A, Temp4
	clr	C
	subb	A, #3
	jz	store_tail_func_3
	mov	A, Temp4
	clr	C
	subb	A, #4
	jz	store_tail_func_4
	mov	A, Temp4
	clr	C
	subb	A, #5
	jz	store_tail_func_5
	mov	A, Temp4
	clr	C
	subb	A, #6
	jz	store_tail_func_6

store_tail_func_1:
	mov	Pgm_Tail_Gain, Temp1
	jmp	store_in_ram_exit

store_tail_func_2:
	mov	Pgm_Tail_Idle, Temp1
	jmp	store_in_ram_exit

store_tail_func_3:
	mov	Pgm_Startup_Pwr, Temp1
	jmp	store_in_ram_exit

store_tail_func_4:
	clr	Flags2.PGM_PWM_HIGH_FREQ
	mov	A, Temp1
	jnb	ACC.0, ($+5)
	setb	Flags2.PGM_PWM_HIGH_FREQ
	clr	Flags2.PGM_PWM_OFF_DAMPED
	clr	C
	mov	A, Temp1
	subb	A, #3
	jc	($+4)
	setb	Flags2.PGM_PWM_OFF_DAMPED
	jmp	store_in_ram_exit

store_tail_func_5:
	clr	Flags2.PGM_DIRECTION_REV
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_DIRECTION_REV
	jmp	store_in_ram_exit

store_tail_func_6:
	clr	Flags2.PGM_RCP_PWM_POL
	mov	A, Temp1
	jnb	ACC.1, ($+5)
	setb	Flags2.PGM_RCP_PWM_POL
	jmp	store_in_ram_exit
ENDIF

store_in_ram_exit:
	ret


;**;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Wait 1 second routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
wait1s:
	mov	Temp5, #5
wait1s_loop:
	call wait200ms
	djnz	Temp5, wait1s_loop
	ret


;**;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Success beep routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
success_beep:
	clr	EA					; Disable all interrupts
	call beep_f1
	call beep_f2
	call beep_f3
	call beep_f4
	call wait10ms
	call beep_f1
	call beep_f2
	call beep_f3
	call beep_f4
	call wait10ms
	call beep_f1
	call beep_f2
	call beep_f3
	call beep_f4
	setb	EA					; Enable all interrupts
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Function and parameter value beep routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
function_paraval_beep:
	mov	Temp5, Tx_Pgm_Func_No	; Function no
	mov	Temp6, Tx_Pgm_Paraval_No	; Parameter value no
	clr	EA					; Disable all interrupts
function_beep:
	call beep_f1				
	call beep_f1
	call beep_f1
	call wait10ms
	djnz	Temp5, function_beep
paraval_beep:
	call beep_f4
	call wait10ms
	djnz	Temp6, paraval_beep
	setb	EA					; Enable all interrupts
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
	clr	EA					; Disable all interrupts
	call beep_f4
	setb	EA					; Enable all interrupts
	call wait100ms
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_STOP			; Below stop?
	jnc	program_by_tx			; No - start over

	; Continue programming mode entry sequence by waiting for high RC pulse
wait_for_rc_pulse_max:
	clr	EA					; Disable all interrupts
	call beep_f1
	call wait10ms
	call beep_f1
	setb	EA					; Enable all interrupts
	call wait100ms
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_MAX			; Above max?
	jc	wait_for_rc_pulse_max	; No - start over

	; Programming mode entry beeps
	call success_beep
	call wait1s
	call wait1s

	; Start at function 1, parameter value 1
	mov	Tx_Pgm_Func_No, #1
paraval_no_entry:
	mov	Tx_Pgm_Paraval_No, #1
beep_no_entry:
	mov	Tx_Pgm_Beep_No, #0
func_paraval:
	call function_paraval_beep
	mov	Temp5, #5				; Wait is 5x 200ms
func_paraval_wait:
	call wait200ms
	clr	C
	mov	A, New_Rcp			; Load new RC pulse value
	subb	A, #RCP_STOP			; Below stop?
	jnc	func_paraval_cont_wait	; No - branch

	call	store_in_ram			; Yes - store new value in RAM
	call	store_all_in_eeprom		; Store all values in EEPROM
	call success_beep			; Beep success
	clr	EA					; Disable all interrupts
	orl	RSTSRC, #10h			; Generate hardware reset
	call wait1s

func_paraval_cont_wait:
	djnz	Temp5, func_paraval_wait
	inc	Tx_Pgm_Beep_No			; Check number of beeps
	clr	C
	mov	A, Tx_Pgm_Beep_No		
	subb	A, #3				; Three beeps done?
	jnc	paraval_next			; Yes - Next parameter value

	jmp	func_paraval			; No - go back

paraval_next:					
	call wait1s
	inc	Tx_Pgm_Paraval_No		; Parameter value no
	mov	Temp1, #5				; Default 5 parameter values
IF TAIL == 0
	clr	C
	mov	A, Tx_Pgm_Func_No		
	subb	A, #3				; Function 3?
	jnz	paraval_end_a			; No - branch
	mov	Temp1, #3				; Yes - set max parameter values
paraval_end_a:
	clr	C
	mov	A, Tx_Pgm_Func_No		
	subb	A, #4				; Function 4?
	jnz	paraval_end_b			; No - branch
	mov	Temp1, #3				; Yes - set max parameter values
paraval_end_b:
	clr	C
	mov	A, Tx_Pgm_Func_No		
	subb	A, #5				; Function below 5?
	jc 	paraval_end_c			; Yes - branch
	mov	Temp1, #2				; No - set max parameter values
paraval_end_c:
ELSE
	clr	C
	mov	A, Tx_Pgm_Func_No		
	subb	A, #4				; Function below 4?
	jc 	paraval_end_a			; Yes - branch
	mov	Temp1, #3				; No - set max parameter values
paraval_end_a:
	clr	C
	mov	A, Tx_Pgm_Func_No		
	subb	A, #(4+DAMPED_TAIL_ENABLE)	; Function below 5 (damped tail enabled)?
	jc 	paraval_end_b			; Yes - branch
	mov	Temp1, #2				; No - set max parameter values
paraval_end_b:
ENDIF
	inc	Temp1
	clr	C
	mov	A, Tx_Pgm_Paraval_No		
	subb	A, Temp1				
	jnc 	function_next			; Last parameter value?
	jmp	beep_no_entry			; No - go back

function_next:					; Yes - Next function value
	call wait1s
	call wait1s
	inc	Tx_Pgm_Func_No			; Function value no
IF TAIL == 0
	clr	C
	mov	A, Tx_Pgm_Func_No		
	subb	A, #9				; Main has 8 functions	
ELSE
	clr	C
	mov	A, Tx_Pgm_Func_No		
	subb	A, #7				; Tail has 6 functions	
ENDIF
	jnc 	program_by_tx_exit		; Last function value?
	jmp	paraval_no_entry		; No - go back

program_by_tx_exit:
	clr	EA					; Disable all interrupts
	orl	RSTSRC, #10h			; Generate hardware reset
	call wait1s

