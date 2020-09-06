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
; Common definitions for EFM8BB1x/2x based ESCs
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
$include (S.inc)	; Select pinout S
ENDIF

IF ESCNO == T_
$include (T.inc)	; Select pinout T
ENDIF

IF ESCNO == U_
$include (U.inc)	; Select pinout U
ENDIF

IF ESCNO == V_
$include (V.inc)	; Select pinout V
ENDIF

IF ESCNO == W_
$include (W.inc)	; Select pinout W
ENDIF


;**** **** **** **** ****
; Constant definitions
;**** **** **** **** ****
ESC_LETTER	EQU	40h + ESCNO

IF MCU_48MHZ == 0
MCU_MHZ_LETTER	EQU	"L"
ELSE
MCU_MHZ_LETTER	EQU	"H"
ENDIF

CSEG AT 1A40h
IF FETON_DELAY == 0
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_00#        "	; ESC layout tag
ELSEIF FETON_DELAY == 5
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_05#        "
ELSEIF FETON_DELAY == 10
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_10#        "
ELSEIF FETON_DELAY == 15
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_15#        "
ELSEIF FETON_DELAY == 20
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_20#        "
ELSEIF FETON_DELAY == 25
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_25#        "
ELSEIF FETON_DELAY == 30
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_30#        "
ELSEIF FETON_DELAY == 40
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_40#        "
ELSEIF FETON_DELAY == 50
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_50#        "
ELSEIF FETON_DELAY == 70
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_70#        "
ELSEIF FETON_DELAY == 90
Eep_ESC_Layout:		DB	"#",ESC_LETTER,"_",MCU_MHZ_LETTER,"_90#        "
ENDIF

IF MCU_48MHZ == 0
CSEG AT 1A50h
Eep_ESC_MCU:			DB	"#BLHELI$EFM8B10#"	; Project and MCU tag (16 Bytes)
ELSE
CSEG AT 1A50h
Eep_ESC_MCU:			DB	"#BLHELI$EFM8B21#"	; Project and MCU tag (16 Bytes)
ENDIF

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

Enable_Power_Pwm_Module MACRO
IF FETON_DELAY == 0
	mov	PCA0_POWER_MODULE, #4Ah		; Enable comparator of module, enable match, set pwm mode
ELSE
	mov	PCA0_POWER_MODULE, #42h		; Enable comparator of module, set pwm mode
ENDIF
ENDM

Enable_Damp_Pwm_Module MACRO
IF FETON_DELAY == 0
	mov	PCA0_DAMP_MODULE, #00h		; Disable
ELSE
	mov	PCA0_DAMP_MODULE, #42h		; Enable comparator of module, set pwm mode
ENDIF
ENDM

Set_Power_Pwm_Regs MACRO
IF FETON_DELAY == 0
	mov	PCA0_POWER_L, Power_Pwm_Reg_L
	mov	PCA0_POWER_H, Power_Pwm_Reg_H
ELSE
	clr	C
	mov	A, Power_Pwm_Reg_H
	rrc	A
	mov	Temp1, A
	mov	A, Power_Pwm_Reg_L
	rrc	A
	mov	PCA0_POWER_L, A
	mov	PCA0_POWER_H, Temp1
ENDIF
ENDM

Set_Damp_Pwm_Regs MACRO
IF FETON_DELAY == 0
	mov	PCA0_DAMP_L, Damp_Pwm_Reg_L
	mov	PCA0_DAMP_H, Damp_Pwm_Reg_H
ELSE
	clr	C
	mov	A, Damp_Pwm_Reg_H
	rrc	A
	mov	Temp1, A
	mov	A, Damp_Pwm_Reg_L
	rrc	A
	mov	PCA0_DAMP_L, A
	mov	PCA0_DAMP_H, Temp1
ENDIF
ENDM

Clear_COVF_Interrupt MACRO
	anl	PCA0PWM, #0DFh
ENDM
Enable_COVF_Interrupt MACRO
	orl	PCA0PWM, #40h
ENDM
Disable_COVF_Interrupt MACRO
	anl	PCA0PWM, #0BFh
ENDM

; CCF interrupt is only used for FETON_DELAY == 0
Clear_CCF_Interrupt MACRO
	anl	PCA0CN0, #0FEh
ENDM
Enable_CCF_Interrupt MACRO
	orl	PCA0CPM0,#01h
ENDM
Disable_CCF_Interrupt MACRO
	anl	PCA0CPM0,#0FEh
ENDM

Set_MCU_Clk_24MHz MACRO
	mov	CLKSEL, #13h			; Set clock to 24MHz
	mov	SFRPAGE, #10h
	mov	PFE0CN, #00h			; Set flash timing for 24MHz
	mov	SFRPAGE, #00h
	mov	Clock_Set_At_48MHz, #0
ENDM

Set_MCU_Clk_48MHz MACRO
	mov	SFRPAGE, #10h
	mov	PFE0CN, #30h			; Set flash timing for 48MHz
	mov	SFRPAGE, #00h
	mov	CLKSEL, #03h			; Set clock to 48MHz
	mov	Clock_Set_At_48MHz, #1
ENDM
