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
; Hardware definition file "H". 
; RC X  X  X  MA MB CC MC    X  Ap Bp Cp X  Ac Bc Cc 
;
;**** **** **** **** ****



;*********************
; Device SiLabs EFM8BB1x/2x
;*********************
IF MCU_48MHZ == 0
$include (SI_EFM8BB1_Defs.inc)
ELSE
$include (SI_EFM8BB2_Defs.inc)
ENDIF


;**** **** **** **** ****
; Uses internal calibrated oscillator set to 24/48Mhz
;**** **** **** **** ****

;**** **** **** **** ****
; Constant definitions
;**** **** **** **** ****
IF MCU_48MHZ == 0
CSEG AT 1A40h
IF FETON_DELAY == 0
Eep_ESC_Layout:		DB	"#H_L_00#        "	; ESC layout tag
ELSEIF FETON_DELAY == 5
Eep_ESC_Layout:		DB	"#H_L_05#        "
ELSEIF FETON_DELAY == 10
Eep_ESC_Layout:		DB	"#H_L_10#        "
ELSEIF FETON_DELAY == 15
Eep_ESC_Layout:		DB	"#H_L_15#        "
ELSEIF FETON_DELAY == 20
Eep_ESC_Layout:		DB	"#H_L_20#        "
ELSEIF FETON_DELAY == 25
Eep_ESC_Layout:		DB	"#H_L_25#        "
ELSEIF FETON_DELAY == 30
Eep_ESC_Layout:		DB	"#H_L_30#        "
ELSEIF FETON_DELAY == 40
Eep_ESC_Layout:		DB	"#H_L_40#        "
ELSEIF FETON_DELAY == 50
Eep_ESC_Layout:		DB	"#H_L_50#        "
ELSEIF FETON_DELAY == 70
Eep_ESC_Layout:		DB	"#H_L_70#        "
ELSEIF FETON_DELAY == 90
Eep_ESC_Layout:		DB	"#H_L_90#        "
ENDIF
CSEG AT 1A50h
Eep_ESC_MCU:			DB	"#BLHELI$EFM8B10#"	; Project and MCU tag (16 Bytes)

ELSE

CSEG AT 1A40h
IF FETON_DELAY == 0
Eep_ESC_Layout:		DB	"#H_H_00#        "	; ESC layout tag
ELSEIF FETON_DELAY == 5
Eep_ESC_Layout:		DB	"#H_H_05#        "
ELSEIF FETON_DELAY == 10
Eep_ESC_Layout:		DB	"#H_H_10#        "
ELSEIF FETON_DELAY == 15
Eep_ESC_Layout:		DB	"#H_H_15#        "
ELSEIF FETON_DELAY == 20
Eep_ESC_Layout:		DB	"#H_H_20#        "
ELSEIF FETON_DELAY == 25
Eep_ESC_Layout:		DB	"#H_H_25#        "
ELSEIF FETON_DELAY == 30
Eep_ESC_Layout:		DB	"#H_H_30#        "
ELSEIF FETON_DELAY == 40
Eep_ESC_Layout:		DB	"#H_H_40#        "
ELSEIF FETON_DELAY == 50
Eep_ESC_Layout:		DB	"#H_H_50#        "
ELSEIF FETON_DELAY == 70
Eep_ESC_Layout:		DB	"#H_H_70#        "
ELSEIF FETON_DELAY == 90
Eep_ESC_Layout:		DB	"#H_H_90#        "
ENDIF
CSEG AT 1A50h
Eep_ESC_MCU:			DB	"#BLHELI$EFM8B21#"	; Project and MCU tag (16 Bytes)
ENDIF

TEMP_LIMIT			EQU 	49	; Temperature measurement ADC value for which main motor power is limited at 80degC (low byte, assuming high byte is 1)
TEMP_LIMIT_STEP		EQU	9	; Temperature measurement ADC value increment for another 10degC

;**** **** **** **** ****
; Bootloader definitions
;**** **** **** **** ****
RTX_PORT		  		EQU 	P0		; Receive/Transmit port
RTX_MDOUT				EQU	P0MDOUT	; Set to 1 for PUSHPULL				
RTX_MDIN				EQU	P0MDIN	; Set to 1 for DIGITAL				
RTX_SKIP				EQU	P0SKIP	; Set to 1 for SKIP				
RTX_PIN				EQU 	7		; RTX pin

SIGNATURE_001			EQU	0E8h		; Device signature
IF MCU_48MHZ == 0
SIGNATURE_002			EQU	0B1h
ELSE
SIGNATURE_002			EQU	0B2h
ENDIF


;*********************
; PORT 0 definitions *
;*********************  
Rcp_In		EQU	7	;i
;			EQU	6	;i
;  			EQU	5	;i
;			EQU	4	;i 
Mux_A		EQU	3	;i
Mux_B		EQU	2	;i
Comp_Com		EQU	1	;i
Mux_C		EQU	0	;i

P0_DIGITAL	EQU	NOT((1 SHL Mux_A)+(1 SHL Mux_B)+(1 SHL Mux_C)+(1 SHL Comp_Com))
P0_INIT		EQU	0FFh
P0_PUSHPULL	EQU	0
P0_SKIP		EQU	0FFh

Get_Rcp_Capture_Values MACRO
	anl	TCON, #0EFh				; Disable timer0
	mov	Temp1, TL0				; Get timer0 values
	mov	Temp2, TH0
IF MCU_48MHZ == 1
	mov	Temp3, Timer0_X
	jnb	TCON_TF0, ($+4)			; Check if interrupt is pending
	inc	Temp3					; If it is pending, then timer has already wrapped
ENDIF
	mov	TL0, #0					; Reset timer0
	mov	TH0, #0
IF MCU_48MHZ == 1
	mov	Timer0_X, #0
ENDIF
	orl	TCON, #10h				; Enable timer0 again
IF MCU_48MHZ == 1
	mov	A, Clock_Set_At_48MHz
	jnz	Get_Rcp_End
	clr	C
	mov	A, Temp1
	rlc	A
	mov	Temp1, A
	mov	A, Temp2
	rlc	A
	mov	Temp2, A
	mov	A, Temp3
	rlc	A
	mov	Temp3, A
Get_Rcp_End:
ENDIF
ENDM
Decode_Dshot_2Msb MACRO
	movx	A, @DPTR
	mov	Temp6, A
	clr	C
	subb	A, Temp5					; Subtract previous timestamp
	clr	C
	subb	A, Temp1
	jc	t1_int_msb_fail			; Check that bit is longer than minimum

	subb	A, Temp1					; Check if bit is zero or one
	mov	A, Temp4					; Shift bit into data byte
	rlc	A
	mov	Temp4, A
	inc	DPL						; Next bit
	movx	A, @DPTR
	mov	Temp5, A
	clr	C
	subb	A, Temp6
	clr	C
	subb	A, Temp1
	jc	t1_int_msb_fail

	subb	A, Temp1
	mov	A, Temp4
	rlc	A
	mov	Temp4, A
	inc	DPL
ENDM
Decode_Dshot_2Lsb MACRO
	movx	A, @DPTR
	mov	Temp6, A
	clr	C
	subb	A, Temp5					; Subtract previous timestamp
	clr	C
	subb	A, Temp1
	jc	t1_int_lsb_fail			; Check that bit is longer than minimum

	subb	A, Temp1					; Check if bit is zero or one
	mov	A, Temp3					; Shift bit into data byte
	rlc	A
	mov	Temp3, A
	inc	DPL						; Next bit
	movx	A, @DPTR
	mov	Temp5, A
	clr	C
	subb	A, Temp6
	clr	C
	subb	A, Temp1
	jc	t1_int_lsb_fail

	subb	A, Temp1
	mov	A, Temp3
	rlc	A
	mov	Temp3, A
	inc	DPL
ENDM
Initialize_PCA MACRO
	mov	PCA0CN0, #40h				; PCA enabled
	mov	PCA0MD, #08h				; PCA clock is system clock
IF FETON_DELAY == 0
IF MCU_48MHZ == 0
	mov	PCA0PWM, #82h				; PCA ARSEL set and 10bits pwm
ELSE
	mov	PCA0PWM, #83h				; PCA ARSEL set and 11bits pwm
ENDIF
	mov	PCA0CENT, #00h				; Edge aligned pwm
ELSE
IF MCU_48MHZ == 0
	mov	PCA0PWM, #81h				; PCA ARSEL set and 9bits pwm
ELSE
	mov	PCA0PWM, #82h				; PCA ARSEL set and 10bits pwm
ENDIF
	mov	PCA0CENT, #03h				; Center aligned pwm
ENDIF
ENDM
Set_Pwm_Polarity MACRO
IF FETON_DELAY == 0
	mov	PCA0POL, #00h				; Pwm noninverted
ELSE
	mov	PCA0POL, #01h				; Damping inverted, pwm noninverted
ENDIF
ENDM
Enable_Power_Pwm_Module MACRO
IF FETON_DELAY == 0
	mov	PCA0CPM0, #4Ah				; Enable comparator of module, enable match, set pwm mode
ELSE
	mov	PCA0CPM1, #42h				; Enable comparator of module, set pwm mode
ENDIF
ENDM
Enable_Damp_Pwm_Module MACRO
IF FETON_DELAY == 0
	mov	PCA0CPM1, #00h				; Disable
ELSE
	mov	PCA0CPM0, #42h				; Enable comparator of module, set pwm mode
ENDIF
ENDM
Set_Power_Pwm_Regs MACRO
IF FETON_DELAY == 0
	mov	PCA0CPL0, Power_Pwm_Reg_L
	mov	PCA0CPH0, Power_Pwm_Reg_H
ELSE
	clr	C
	mov	A, Power_Pwm_Reg_H
	rrc	A
	mov	Temp1, A
	mov	A, Power_Pwm_Reg_L
	rrc	A
	mov	PCA0CPL1, A
	mov	PCA0CPH1, Temp1
ENDIF
ENDM		
Set_Damp_Pwm_Regs MACRO
IF FETON_DELAY == 0
	mov	PCA0CPL1, Damp_Pwm_Reg_L
	mov	PCA0CPH1, Damp_Pwm_Reg_H
ELSE
	clr	C
	mov	A, Damp_Pwm_Reg_H
	rrc	A
	mov	Temp1, A
	mov	A, Damp_Pwm_Reg_L
	rrc	A
	mov	PCA0CPL0, A
	mov	PCA0CPH0, Temp1
ENDIF
ENDM		
Clear_COVF_Interrupt MACRO
	anl	PCA0PWM, #0DFh
ENDM
Clear_CCF_Interrupt MACRO	; CCF interrupt is only used for FETON_DELAY == 0
	anl	PCA0CN0, #0FEh
ENDM
Enable_COVF_Interrupt MACRO
	orl	PCA0PWM, #40h
ENDM
Enable_CCF_Interrupt MACRO
	orl	PCA0CPM0,#01h
ENDM
Disable_COVF_Interrupt MACRO
	anl	PCA0PWM, #0BFh
ENDM
Disable_CCF_Interrupt MACRO
	anl	PCA0CPM0,#0FEh
ENDM


;*********************
; PORT 1 definitions *
;*********************
;			EQU	7	;i
ApwmFET		EQU	6	;o
BpwmFET		EQU	5	;o
CpwmFET		EQU	4	;o
;			EQU	3	;i
AcomFET		EQU	2	;o 
BcomFET		EQU	1	;o
CcomFET		EQU	0	;o

P1_DIGITAL	EQU	(1 SHL ApwmFET)+(1 SHL BpwmFET)+(1 SHL CpwmFET)+(1 SHL AcomFET)+(1 SHL BcomFET)+(1 SHL CcomFET)
P1_INIT		EQU 	00h		
P1_PUSHPULL	EQU	(1 SHL ApwmFET)+(1 SHL BpwmFET)+(1 SHL CpwmFET)+(1 SHL AcomFET)+(1 SHL BcomFET)+(1 SHL CcomFET)
P1_SKIP		EQU	7Fh

ApwmFET_on MACRO
	setb	P1.ApwmFET
IF FETON_DELAY == 0
	setb	P1.AcomFET
ENDIF
ENDM
ApwmFET_off MACRO
IF FETON_DELAY != 0
	clr	P1.ApwmFET
ELSE
	clr	P1.AcomFET
ENDIF
ENDM
BpwmFET_on MACRO
	setb	P1.BpwmFET
IF FETON_DELAY == 0
	setb	P1.BcomFET
ENDIF
ENDM
BpwmFET_off MACRO
IF FETON_DELAY != 0
	clr	P1.BpwmFET
ELSE
	clr	P1.BcomFET
ENDIF
ENDM
CpwmFET_on MACRO
	setb	P1.CpwmFET
IF FETON_DELAY == 0
	setb	P1.CcomFET
ENDIF
ENDM
CpwmFET_off MACRO
IF FETON_DELAY != 0
	clr	P1.CpwmFET
ELSE
	clr	P1.CcomFET
ENDIF
ENDM
All_pwmFETs_Off MACRO
IF FETON_DELAY != 0
	clr	P1.ApwmFET
	clr	P1.BpwmFET
	clr	P1.CpwmFET
ELSE
	clr	P1.AcomFET
	clr	P1.BcomFET
	clr	P1.CcomFET
ENDIF
ENDM

AcomFET_on MACRO
IF FETON_DELAY == 0
	clr	P1.ApwmFET
ENDIF
	setb	P1.AcomFET
ENDM
AcomFET_off MACRO
	clr	P1.AcomFET
ENDM
BcomFET_on MACRO
IF FETON_DELAY == 0
	clr	P1.BpwmFET
ENDIF
	setb	P1.BcomFET
ENDM
BcomFET_off MACRO
	clr	P1.BcomFET
ENDM
CcomFET_on MACRO
IF FETON_DELAY == 0
	clr	P1.CpwmFET
ENDIF
	setb	P1.CcomFET
ENDM
CcomFET_off MACRO
	clr	P1.CcomFET
ENDM
All_comFETs_Off MACRO
	clr	P1.AcomFET
	clr	P1.BcomFET
	clr	P1.CcomFET
ENDM

Set_Pwm_A MACRO
IF FETON_DELAY == 0
	setb	P1.AcomFET
	mov	P1SKIP, #3Fh
ELSE
	mov	P1SKIP, #3Bh
ENDIF
ENDM
Set_Pwm_B MACRO
IF FETON_DELAY == 0
	setb	P1.BcomFET
	mov	P1SKIP, #5Fh
ELSE
	mov	P1SKIP, #5Dh
ENDIF
ENDM
Set_Pwm_C MACRO
IF FETON_DELAY == 0
	setb	P1.CcomFET
	mov	P1SKIP, #6Fh
ELSE
	mov	P1SKIP, #6Eh
ENDIF
ENDM
Set_Pwms_Off MACRO
	mov	P1SKIP, #7Fh
ENDM

Set_Comp_Phase_A MACRO
	mov	CMP0MX, #31h	; Set comparator multiplexer to phase A
ENDM
Set_Comp_Phase_B MACRO
	mov	CMP0MX, #21h	; Set comparator multiplexer to phase B
ENDM
Set_Comp_Phase_C MACRO
	mov	CMP0MX, #01h	; Set comparator multiplexer to phase C
ENDM
Read_Comp_Out MACRO
	mov	A, CMP0CN0	; Read comparator output
ENDM


;*********************
; PORT 2 definitions *
;*********************
DebugPin		EQU	0	;o

P2_PUSHPULL	EQU	(1 SHL DebugPin)


;**********************
; MCU specific macros *
;**********************
Interrupt_Table_Definition MACRO
CSEG AT 0				; Code segment start
	jmp reset
CSEG AT 03h			; Int0 interrupt	
	jmp	int0_int	
IF MCU_48MHZ == 1
CSEG AT 0Bh			; Timer0 overflow interrupt
	jmp	t0_int
ENDIF
CSEG AT 13h			; Int1 interrupt
	jmp	int1_int
CSEG AT 1Bh			; Timer1 overflow interrupt
	jmp	t1_int
CSEG AT 2Bh			; Timer2 overflow interrupt
	jmp	t2_int	
CSEG AT 5Bh			; Pca interrupt
	jmp	pca_int
CSEG AT 73h			; Timer3 overflow/compare interrupt
	jmp	t3_int	
ENDM

Initialize_Xbar MACRO
	mov	XBR2, #40h	; Xbar enabled			
	mov	XBR1, #02h	; CEX0 and CEX1 routed to pins		
ENDM

Initialize_Comparator MACRO
	mov	CMP0CN0, #80h	; Comparator enabled, no hysteresis
	mov	CMP0MD, #00h	; Comparator response time 100ns
ENDM
Initialize_Adc MACRO
	mov	REF0CN, #0Ch	; Set vdd (3.3V) as reference. Enable temp sensor and bias
IF MCU_48MHZ == 0
	mov	ADC0CF, #59h	; ADC clock 2MHz, PGA gain 1
ELSE
	mov	ADC0CF, #0B9h	; ADC clock 2MHz, PGA gain 1
ENDIF
	mov	ADC0MX, #10h	; Select temp sensor input
	mov	ADC0CN0, #80h	; ADC enabled 
	mov	ADC0CN1, #01h	; Common mode buffer enabled
ENDM
Start_Adc MACRO
	mov	ADC0CN0, #90h	; ADC start
ENDM
Read_Adc_Result MACRO
	mov	Temp1, ADC0L
	mov	Temp2, ADC0H
ENDM
Stop_Adc MACRO
ENDM
Set_RPM_Out MACRO
ENDM
Clear_RPM_Out MACRO
ENDM
Set_MCU_Clk_24MHz MACRO
	mov	CLKSEL, #13h		; Set clock to 24MHz
	mov	SFRPAGE, #10h
	mov	PFE0CN, #00h		; Set flash timing for 24MHz
	mov	SFRPAGE, #00h
	mov	Clock_Set_At_48MHz, #0
ENDM
Set_MCU_Clk_48MHz MACRO
	mov	SFRPAGE, #10h
	mov	PFE0CN, #30h		; Set flash timing for 48MHz
	mov	SFRPAGE, #00h
	mov	CLKSEL, #03h		; Set clock to 48MHz
	mov	Clock_Set_At_48MHz, #1
ENDM
Set_LED_0 MACRO
ENDM
Clear_LED_0 MACRO
ENDM
Set_LED_1 MACRO
ENDM
Clear_LED_1 MACRO
ENDM
Set_LED_2 MACRO
ENDM
Clear_LED_2 MACRO
ENDM
Set_LED_3 MACRO
ENDM
Clear_LED_3 MACRO
ENDM
