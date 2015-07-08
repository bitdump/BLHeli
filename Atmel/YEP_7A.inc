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
; YEP 7A hardware definition file
;
;**** **** **** **** ****


;*********************
; Device Atmega168PA
;*********************
.INCLUDE "m168PAdef.inc"

;**** **** **** **** ****
; Fuses must be set to external oscillator = 16Mhz
;**** **** **** **** ****

;**** **** **** **** ****
; Constant definitions
;**** **** **** **** ****
.ESEG				; EEprom segment
.ORG 0x40
Eep_ESC_Layout:		.DB	"#YEP_7A#        "	; ESC layout tag
.ORG 0x50
Eep_ESC_MCU:			.DB	"#BLHELI#Am168PA#"	; Project and MCU tag (16 Bytes)

.EQU	HIGH_BEC_VOLTAGE		=	0	; Set to 1 or more if high BEC voltage is supported
.EQU	DAMPED_MODE_ENABLE		=	0	; Set to 1 if fully damped mode is supported
.EQU	NFETON_DELAY			=	65	; Wait delay from pfets off to nfets on
.EQU	PFETON_DELAY			=	5	; Wait delay from nfets off to pfets on
.EQU	ADC_LIMIT_L			= 	231	; 2k/22k divider. Power supply measurement ADC value for which motor power is limited (low byte)
.EQU	ADC_LIMIT_H			=	0	; 2k/22k divider. Power supply measurement ADC value for which motor power is limited (2 MSBs)
.EQU	TEMP_LIMIT			= 	0	; No temp sensor. Temperature measurement ADC value for which main motor power is limited
.EQU	TEMP_LIMIT_STEP		=	0	; No temp sensor. Temperature measurement ADC value increment for which main motor power is further limited

;**** **** **** **** ****
; ESC specific defaults
;**** **** **** **** ****
.EQU	DEFAULT_PGM_MAIN_SPOOLUP_TIME		= 7	; Main motor spoolup time
.EQU	DEFAULT_PGM_MAIN_STARTUP_PWR 		= 11 ; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50
.EQU	DEFAULT_PGM_TAIL_STARTUP_PWR 		= 11 ; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50
.EQU	DEFAULT_PGM_MULTI_STARTUP_PWR 	= 11	; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50
.EQU	DEFAULT_PGM_MAIN_STARTUP_METHOD	= 2 	; 1=Stepped	2=Direct
.EQU	DEFAULT_PGM_TAIL_STARTUP_METHOD	= 2 	; 1=Stepped	2=Direct
.EQU	DEFAULT_PGM_MULTI_STARTUP_METHOD	= 2 	; 1=Stepped	2=Direct


;*********************
; PORT D definitions *
;*********************  
;.EQU			= 7	;i 
;.EQU			= 6	;i
;.EQU			= 5	;i
;.EQU			= 4	;i
;.EQU			= 3	;i
.EQU	Rcp_In		= 2	;i 
;.EQU			= 1	;i
;.EQU			= 0	;i

.equ	INIT_PD		= 0x00
.equ	DIR_PD		= 0x00


.MACRO Get_Rcp_Capture_Values
	lds	@0, TCNT1L
	lds	@1, TCNT1H
.ENDMACRO
.MACRO Read_Rcp_Int
	in	@0, PIND
	sbrc Flags3, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	com	@0					; Yes - invert
.ENDMACRO
.MACRO Get_Rcp_Int_Enable_State
	in 	@0, EIMSK				; Get int0 enable state (giving 0 is off, anything else is on)
	andi	@0, (1<<INT0)
.ENDMACRO
.MACRO Rcp_Int_Enable
	ldi	@0, (1<<INT0)			; Enable int0
	out	EIMSK, @0
.ENDMACRO
.MACRO Rcp_Int_Disable
	ldi	@0, 0				; Disable int0
	out	EIMSK, @0
.ENDMACRO
.MACRO Rcp_Int_First
	sbrs	Flags3, PGM_RCP_PWM_POL	; Is pwm polarity positive?
	ldi	@0, (1<<ISC01)+(1<<ISC00); Yes - set next int0 to rising
	sbrc Flags3, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	ldi	@0, (1<<ISC01)			; Yes - set next int0 to falling
	sts	EICRA, @0		
.ENDMACRO
.MACRO Rcp_Int_Second
	sbrs	Flags3, PGM_RCP_PWM_POL	; Is pwm polarity positive?
	ldi	@0, (1<<ISC01)			; Yes - set next int0 to falling
	sbrc Flags3, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	ldi	@0, (1<<ISC01)+(1<<ISC00); Yes - set next int0 to rising
	sts	EICRA, @0		
.ENDMACRO
.MACRO Rcp_Clear_Int_Flag
	clr 	@0
	sbr	@0, (1<<INTF0)			; Clear ext0int flag
	out	EIFR, @0		
.ENDMACRO		

.MACRO T0_Int_Disable
	lds	@0, TIMSK0			; Disable timer0 interrupts
	cbr	@0, (1<<TOIE0)	
	sts	TIMSK0, @0
.ENDMACRO
.MACRO T0_Int_Enable
	lds	@0, TIMSK0			; Enable timer0 interrupts
	sbr	@0, (1<<TOIE0)	
	sts	TIMSK0, @0
.ENDMACRO
.MACRO T1oca_Clear_Int_Flag
	ldi	@0, (1<<OCF1A)			; Clear oc1a flag
	out	TIFR1, @0
.ENDMACRO		
.MACRO T1oca_Int_Disable
	lds	@0, TIMSK1			; Disable oc1a interrupts
	cbr	@0, (1<<OCIE1A)	
	sts	TIMSK1, @0
.ENDMACRO		
.MACRO T1oca_Int_Enable
	lds	@0, TIMSK1			; Enable oc1a interrupts
	sbr	@0, (1<<OCIE1A)	
	sts	TIMSK1, @0
.ENDMACRO		


;*********************
; PORT C definitions *
;*********************
;.EQU			= 7	; i
;.EQU			= 6	; i
.EQU	Mux_A		= 5	; i
.EQU	Mux_B		= 4	; i
.EQU	Mux_C		= 3	; i
;.EQU			= 2	; i 
;.EQU			= 1	; i
.EQU Volt_Ip		= 0	; i 

.equ	INIT_PC		= 0x00
.equ	DIR_PC		= 0x00


.MACRO AnFET_on
	sbi	PORTB, AnFET
.ENDMACRO
.MACRO AnFET_off
	cbi	PORTB, AnFET
.ENDMACRO
.MACRO BnFET_on
	sbi	PORTB, BnFET
.ENDMACRO
.MACRO BnFET_off
	cbi	PORTB, BnFET
.ENDMACRO
.MACRO CnFET_on
	sbi	PORTB, CnFET
.ENDMACRO
.MACRO CnFET_off
	cbi	PORTB, CnFET
.ENDMACRO
.MACRO All_nFETs_Off
	cbi	PORTB, AnFET
	cbi	PORTB, BnFET
	cbi	PORTB, CnFET
.ENDMACRO

.MACRO ApFET_on
	sbi	PORTB, ApFET
.ENDMACRO
.MACRO ApFET_off
	cbi	PORTB, ApFET
.ENDMACRO
.MACRO BpFET_on
	sbi	PORTB, BpFET
.ENDMACRO
.MACRO BpFET_off
	cbi	PORTB, BpFET
.ENDMACRO
.MACRO CpFET_on
	sbi	PORTB, CpFET
.ENDMACRO
.MACRO CpFET_off
	cbi	PORTB, CpFET
.ENDMACRO
.MACRO All_pFETs_On
	sbi	PORTB, ApFET
	sbi	PORTB, BpFET
	sbi	PORTB, CpFET
.ENDMACRO
.MACRO All_pFETs_Off
	cbi	PORTB, ApFET
	cbi	PORTB, BpFET
	cbi	PORTB, CpFET
.ENDMACRO
.MACRO Damping_FET_On	
	lds	@0, DampingFET	
	sbrc	@0, 0
	sbi	PORTB, ApFET		
	sbrc	@0, 1
	sbi	PORTB, BpFET		
	sbrc	@0, 2
	sbi	PORTB, CpFET		
.ENDM

.MACRO Comp_Init
  	lds  @0, ADCSRB		; Set Analog Comparator Multiplexer Enable
   	sbr  @0, (1<<ACME) 	
   	sts  ADCSRB, @0
.ENDMACRO
.MACRO Set_Comp_Phase_A
   	ldi  @0, Mux_A 		; Set comparator multiplexer to phase A
	ori  @0, (1<<REFS1)+(1<<REFS0)		
  	sts  ADMUX, @0
.ENDMACRO
.MACRO Set_Comp_Phase_B
   	ldi  @0, Mux_B  		; Set comparator multiplexer to phase B
	ori  @0, (1<<REFS1)+(1<<REFS0)		
  	sts  ADMUX, @0
.ENDMACRO
.MACRO Set_Comp_Phase_C
   	ldi  @0, Mux_C  		; Set comparator multiplexer to phase C
	ori  @0, (1<<REFS1)+(1<<REFS0)		
  	sts  ADMUX, @0
.ENDMACRO
.MACRO Read_Comp_Out
	in	@0, ACSR			; Read comparator output
.ENDMACRO


;*********************
; PORT B definitions *
;*********************
;.EQU			= 7	; i
;.EQU			= 6	; i
.EQU CnFET		= 5	; o
.EQU	BnFET		= 4	; o
.EQU	AnFET		= 3	; o
.EQU	ApFET		= 2	; o
.EQU	CpFET		= 1	; o
.EQU	BpFET		= 0	; o

.EQU	INIT_PB		= 0
.EQU	DIR_PB		= (1<<AnFET)+(1<<BnFET)+(1<<CnFET)+(1<<ApFET)+(1<<BpFET)+(1<<CpFET)



;**********************
; MCU specific macros *
;**********************
.MACRO Interrupt_Table_Definition
	jmp reset
	rjmp rcp_int	; ext_int0 
	nop
	nop			; ext_int1
	nop
	nop 			; pci0_int
	nop
	nop 			; pci1_int
	nop
	nop 			; pci2_int
	nop
	nop 			; wdt_int
	nop
	nop 			; t2oca_int
	nop
	nop 			; t2ocb_int
	nop
	rjmp t2_int	; t2ovfl_int
	nop
	nop			; icp1_int	
	nop
	rjmp t1oca_int	; t1oca_int
	nop
	nop			; t1ocb_int
	nop
	nop			; t1ovfl_int
	nop
	nop			; t0oca_int
	nop
	nop			; t0ocb_int
	nop
	rjmp t0_int	; t0ovfl_int
	nop
	nop			; spi_int
	nop
	nop			; urxc
	nop
	nop			; udre
	nop
	nop			; utxc
	nop
;	nop			; adc_int
;	nop			; eep_int
;	nop			; aci_int
;	nop			; wire2_int
;	nop			; spmc_int
.ENDMACRO

.MACRO Disable_Watchdog
	cli					; Disable interrupts
	wdr					; Reset watchdog timer
	in @0, MCUSR			; Clear WDRF in MCUSR
	andi @0, (0xFF & (0<<WDRF))
	out MCUSR, @0
	lds @0, WDTCSR			; Write logical one to WDCE and WDE
	ori @0, (1<<WDCE) | (1<<WDE)
	sts WDTCSR, @0
	ldi @0, (0<<WDE)		; Turn off WDT
	sts WDTCSR, @0
.ENDMACRO
.MACRO Enable_Watchdog
	ldi @0, (1<<WDE)		; Turn on WDT
	sts WDTCSR, @0
.ENDMACRO

.MACRO Initialize_MCU
.ENDMACRO

.MACRO Initialize_Interrupts 
	ldi	@0, (1<<TOIE0)
	out	TIFR0, @0			; Clear interrupts
	sts	TIMSK0, @0		; Enable interrupts
	ldi	@0, (1<<OCIE1A)
	out	TIFR1, @0			; Clear interrupts
	sts	TIMSK1, @0		; Enable interrupts
	ldi	@0, (1<<TOIE2)
	out	TIFR2, @0			; Clear interrupts
	sts	TIMSK2, @0		; Enable interrupts
.ENDMACRO

.MACRO Initialize_Adc
  	lds  @0, ADCSRA		; Set ADCSRA register (1MHz clock)
  	sbr  @0, (1<<ADPS2) 	
   	sts  ADCSRA, @0
.ENDMACRO

.MACRO Set_Adc_Ip_Volt
	cbr	Flags1, (1<<ADC_READ_TEMP)
.ENDMACRO
.MACRO Set_Adc_Ip_Temp
	sbr	Flags1, (1<<ADC_READ_TEMP)
.ENDMACRO
.MACRO Start_Adc
	sbrs	Flags1, ADC_READ_TEMP
	ldi	@0, Volt_Ip
	sbrc	Flags1, ADC_READ_TEMP
	ldi	@0, Volt_Ip
	ori  @0, (1<<REFS1)+(1<<REFS0)		
	sts	ADMUX, @0			; Set ADMUX register (1.1V reference, selected input)
 	lds 	@0, ADCSRA	
  	sbr  @0, (1<<ADEN) 		; Enable ADC	
  	sbr  @0, (1<<ADSC) 		; Start ADC conversion	
   	sts  ADCSRA, @0
.ENDMACRO
.MACRO Get_Adc_Status
  	lds 	@0, ADCSRA	
.ENDMACRO
.MACRO Read_Adc_Result
  	lds	@0, ADCL	
  	lds 	@1, ADCH	
.ENDMACRO
.MACRO Stop_Adc
  	lds 	@0, ADCSRA	
  	cbr  @0, (1<<ADEN) 		; Disable ADC	
   	sts  ADCSRA, @0
.ENDMACRO

.MACRO Set_Timer0_CS0
	out	TCCR0B, @0
.ENDMACRO
.MACRO Set_Timer1_CS1
	sts	TCCR1B, @0
.ENDMACRO
.MACRO Set_Timer2_CS2
	sts	TCCR2B, @0
.ENDMACRO

.MACRO Read_TCNT1L
	lds	@0, TCNT1L
.ENDMACRO
.MACRO Read_TCNT1H
	lds	@0, TCNT1H
.ENDMACRO
.MACRO Set_OCR1AL
	sts	OCR1AL, @0
.ENDMACRO
.MACRO Set_OCR1AH
	sts	OCR1AH, @0
.ENDMACRO

.MACRO Read_TCNT2
	lds	@0, TCNT2
.ENDMACRO
.MACRO Set_TCNT2
	sts	TCNT2, @0
.ENDMACRO

.MACRO Check_Eeprom_Ready
	sbic	EECR, EEPE
.ENDMACRO
.MACRO Set_Eeprom_Address
	out  EEARL, @0
	out  EEARH, @1
.ENDMACRO
.MACRO Start_Eeprom_Write
	sbi  EECR, EEMPE
	sbi  EECR, EEPE
.ENDMACRO

.MACRO Prepare_Lock_Or_Fuse_Read
	ldi	@0, ((1<<BLBSET)+(1<<SELFPRGEN))
	out	SPMCSR, @0
.ENDMACRO

.MACRO xcall
	call	@0
.ENDMACRO

.MACRO Set_RPM_Out
.ENDMACRO
.MACRO Clear_RPM_Out
.ENDMACRO
