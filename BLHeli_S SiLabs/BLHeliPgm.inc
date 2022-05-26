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
; BLHeliTxPgm SiLabs                                      
;                                                         
; EEPROM is not available in SiLabs MCUs                  
; Therefore a segment of the flash is used as "EEPROM"    
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
	; Check initialized signature
	mov	DPTR, #Eep_Initialized_L
	mov	Temp1, #Bit_Access
	call read_eeprom_byte
	mov	A, Bit_Access
	cjne	A, #055h, read_eeprom_store_defaults
	inc	DPTR				; Now Eep_Initialized_H
	call read_eeprom_byte
	mov	A, Bit_Access
	cjne	A, #0AAh, read_eeprom_store_defaults
	jmp	read_eeprom_read


read_eeprom_store_defaults:
	mov	Flash_Key_1, #0A5h
	mov	Flash_Key_2, #0F1h
	call set_default_parameters	
	call erase_and_store_all_in_eeprom	
	mov	Flash_Key_1, #0
	mov	Flash_Key_2, #0
	jmp	read_eeprom_exit

read_eeprom_read:
	; Read eeprom
	mov	DPTR, #_Eep_Pgm_Gov_P_Gain
	mov	Temp1, #_Pgm_Gov_P_Gain	
	mov	Temp4, #10
read_eeprom_block1:
	call read_eeprom_byte
	inc	DPTR				
	inc	Temp1			
	djnz	Temp4, read_eeprom_block1

	mov	DPTR, #Eep_Enable_TX_Program
	mov	Temp1, #Pgm_Enable_TX_Program	
	mov	Temp4, #26	; 26 parameters
read_eeprom_block2:
	call read_eeprom_byte
	inc	DPTR				
	inc	Temp1		
	djnz	Temp4, read_eeprom_block2

	mov	DPTR, #Eep_Dummy 			; Set pointer to uncritical area

read_eeprom_exit:
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Erase flash and store all parameter value in EEPROM routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
erase_and_store_all_in_eeprom:
	clr	IE_EA					; Disable interrupts
	call	read_tags
	call	erase_flash				; Erase flash

	mov	DPTR, #Eep_FW_Main_Revision	; Store firmware main revision
	mov	A, #EEPROM_FW_MAIN_REVISION
	call write_eeprom_byte_from_acc

	inc	DPTR						; Now firmware sub revision
	mov	A, #EEPROM_FW_SUB_REVISION
	call write_eeprom_byte_from_acc

	inc	DPTR						; Now layout revision
	mov	A, #EEPROM_LAYOUT_REVISION
	call write_eeprom_byte_from_acc

	; Write eeprom
	mov	DPTR, #_Eep_Pgm_Gov_P_Gain
	mov	Temp1, #_Pgm_Gov_P_Gain
	mov	Temp4, #10
write_eeprom_block1:
	call write_eeprom_byte
	inc	DPTR						
	inc	Temp1					
	djnz	Temp4, write_eeprom_block1

	mov	DPTR, #Eep_Enable_TX_Program
	mov	Temp1, #Pgm_Enable_TX_Program	
	mov	Temp4, #26	; 26 parameters
write_eeprom_block2:
	call write_eeprom_byte
	inc	DPTR						
	inc	Temp1					
	djnz	Temp4, write_eeprom_block2

	call	write_tags
	call write_eeprom_signature
	mov	DPTR, #Eep_Dummy 			; Set pointer to uncritical area
	ret	



;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Read eeprom byte routine
;
; Gives data in A and in address given by Temp1. Assumes address in DPTR 
; Also assumes address high byte to be zero
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
read_eeprom_byte:
	clr	A
	movc	A, @A+DPTR			; Read from flash
	mov	@Temp1, A
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Write eeprom byte routine
;
; Assumes data in address given by Temp1, or in accumulator. Assumes address in DPTR 
; Also assumes address high byte to be zero
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
write_eeprom_byte:
	mov	A, @Temp1
write_eeprom_byte_from_acc:
	orl	PSCTL, #01h			; Set the PSWE bit
	anl	PSCTL, #0FDh			; Clear the PSEE bit
	mov	Temp8, A
	clr	C
	mov	A, DPH				; Check that address is not in bootloader area
	subb	A, #1Ch
	jc	($+3)

	ret

	mov	A, Temp8
	mov	FLKEY, Flash_Key_1		; First key code
	mov	FLKEY, Flash_Key_2		; Second key code
	movx	@DPTR, A				; Write to flash
	anl	PSCTL, #0FEh			; Clear the PSWE bit
	ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Erase flash routine (erases the flash segment used for "eeprom" variables)
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
erase_flash:	
	orl	PSCTL, #02h			; Set the PSEE bit
	orl	PSCTL, #01h			; Set the PSWE bit
	mov	FLKEY, Flash_Key_1		; First key code
	mov	FLKEY, Flash_Key_2		; Second key code
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
	mov	DPTR, #Eep_Initialized_L
	mov	A, #055h
	call write_eeprom_byte_from_acc

	mov	DPTR, #Eep_Initialized_H
	mov	A, #0AAh
	call write_eeprom_byte_from_acc
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
	mov	Temp2, #Temp_Storage		; Set RAM address
	mov	Temp1, #Bit_Access
	mov	DPTR, #Eep_ESC_Layout		; Set flash address
read_tag:	
	call read_eeprom_byte
	mov	A, Bit_Access
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
	mov	Temp2, #Temp_Storage		; Set RAM address
	mov	DPTR, #Eep_ESC_Layout		; Set flash address
write_tag:	
	mov	A, @Temp2			; Read from RAM
	call write_eeprom_byte_from_acc
	inc	Temp2
	inc	DPTR
	djnz Temp3, write_tag	
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
	clr	IE_EA				; Disable all interrupts
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
	setb	IE_EA				; Enable all interrupts
	ret


;**;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Success beep inverted routine
;
; No assumptions
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
success_beep_inverted:
	clr	IE_EA				; Disable all interrupts
	call beep_f4
	call beep_f3
	call beep_f2
	call beep_f1
	call wait10ms
	call beep_f4
	call beep_f3
	call beep_f2
	call beep_f1
	call wait10ms
	call beep_f4
	call beep_f3
	call beep_f2
	call beep_f1
	setb	IE_EA				; Enable all interrupts
	ret


