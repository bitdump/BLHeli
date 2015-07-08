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
; Hobbyking UBEC 20A hardware definition file
;
; Notes: 
; - On 2S low voltage limiting does not work fully according to spec, as ADC reference drops with sensed voltage
; - High side is slow to go on (10s of us) but fast to go off
;
;**** **** **** **** ****


;*********************
; Device Atmega8A
;*********************
.INCLUDE "m8Adef.inc"

;**** **** **** **** ****
; Fuses must be set to external oscillator = 16Mhz
;**** **** **** **** ****

;**** **** **** **** ****
; Constant definitions
;**** **** **** **** ****
.ESEG				; EEprom segment
.ORG 0x40
Eep_ESC_Layout:		.DB	"#HK_UBEC_20A#   "	; ESC layout tag
.ORG 0x50
Eep_ESC_MCU:			.DB	"#BLHELI#Am8A#   "	; Project and MCU tag (16 Bytes)

.EQU	HIGH_BEC_VOLTAGE		=	0	; Set to 1 or more if high BEC voltage is supported
.EQU	DAMPED_MODE_ENABLE		=	1	; Set to 1 if fully damped mode is supported
.EQU	NFETON_DELAY			=	7	; Wait delay from pfets off to nfets on
.EQU	PFETON_DELAY			=	250	; Wait delay from nfets off to pfets on
.EQU	ADC_LIMIT_L			= 	116	; 51k/220k divider. Power supply measurement ADC value for which motor power is limited (low byte)
.EQU	ADC_LIMIT_H			=	0	; 51k/220k divider. Power supply measurement ADC value for which motor power is limited (2 MSBs)
.EQU	TEMP_LIMIT			= 	122	; 820/3k3NTC. Temperature measurement ADC value for which main motor power is limited
.EQU	TEMP_LIMIT_STEP		=	11	; 820/3k3NTC. Temperature measurement ADC value increment for which main motor power is further limited

;**** **** **** **** ****
; ESC specific defaults
;**** **** **** **** ****
.EQU	DEFAULT_PGM_MAIN_SPOOLUP_TIME		= 10	; Main motor spoolup time
.EQU	DEFAULT_PGM_MAIN_STARTUP_PWR 		= 10	; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50
.EQU	DEFAULT_PGM_TAIL_STARTUP_PWR 		= 10	; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50
.EQU	DEFAULT_PGM_MULTI_STARTUP_PWR 	= 10	; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50


;*********************
; PORT D definitions *
;*********************  
;.EQU			= 7	;i 
;.EQU			= 6	;i
.EQU	AnFET		= 5	;o
.EQU	ApFET		= 4	;o
;.EQU			= 3	;i
.EQU	Rcp_In		= 2	;i 
;.EQU			= 1	;i
;.EQU			= 0	;i

.equ	INIT_PD		= (1<<ApFET)
.equ	DIR_PD		= (1<<AnFET)+(1<<ApFET)


.MACRO Get_Rcp_Capture_Values
	in	@0, TCNT1L
	in	@1, TCNT1H
.ENDMACRO
.MACRO Read_Rcp_Int
	in	@0, PIND
	sbrc Flags3, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	com	@0					; Yes - invert
.ENDMACRO
.MACRO Get_Rcp_Int_Enable_State
	in 	@0, GICR				; Get int0 enable state (giving 0 is off, anything else is on)
	andi	@0, (1<<INT0)
.ENDMACRO
.MACRO Rcp_Int_Enable
	ldi	@0, (1<<INT0)			; Enable int0
	out	GICR, @0
.ENDMACRO
.MACRO Rcp_Int_Disable
	ldi	@0, 0				; Disable int0
	out	GICR, @0
.ENDMACRO
.MACRO Rcp_Int_First
	sbrs	Flags3, PGM_RCP_PWM_POL	; Is pwm polarity positive?
	ldi	@0, (1<<ISC01)+(1<<ISC00); Yes - set next int0 to rising
	sbrc Flags3, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	ldi	@0, (1<<ISC01)			; Yes - set next int0 to falling
	out	MCUCR, @0		
.ENDMACRO
.MACRO Rcp_Int_Second
	sbrs	Flags3, PGM_RCP_PWM_POL	; Is pwm polarity positive?
	ldi	@0, (1<<ISC01)			; Yes - set next int0 to falling
	sbrc Flags3, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	ldi	@0, (1<<ISC01)+(1<<ISC00); Yes - set next int0 to rising
	out	MCUCR, @0		
.ENDMACRO
.MACRO Rcp_Clear_Int_Flag
	clr 	@0
	sbr	@0, (1<<INTF0)			; Clear ext0int flag
	out	GIFR, @0		
.ENDMACRO		

.MACRO T0_Int_Disable
	in	@0, TIMSK				; Disable timer0 interrupts
	cbr	@0, (1<<TOIE0)	
	out	TIMSK, @0
.ENDMACRO
.MACRO T0_Int_Enable
	in	@0, TIMSK				; Enable timer0 interrupts
	sbr	@0, (1<<TOIE0)	
	out	TIMSK, @0
.ENDMACRO
.MACRO T1oca_Clear_Int_Flag
	ldi	@0, (1<<OCF1A)			; Clear oc1a flag
	out	TIFR, @0
.ENDMACRO		
.MACRO T1oca_Int_Disable
	in	@0, TIMSK				; Disable oc1a interrupts
	cbr	@0, (1<<OCIE1A)	
	out	TIMSK, @0
.ENDMACRO		
.MACRO T1oca_Int_Enable
	in	@0, TIMSK				; Enable oc1a interrupts
	sbr	@0, (1<<OCIE1A)	
	out	TIMSK, @0
.ENDMACRO		


;*********************
; PORT C definitions *
;*********************
.EQU	Mux_B		= 7	; i
.EQU	Mux_A		= 6	; i
.EQU	BpFET		= 5	; i
.EQU	BnFET		= 4	; i
.EQU	CpFET		= 3	; i
.EQU	Volt_Ip		= 2	; i 
.EQU	Temp_Ip		= 1	; i
.EQU	Mux_C		= 0	; i 

.equ	INIT_PC		= (1<<BpFET)+(1<<CpFET)
.equ	DIR_PC		= (1<<BnFET)+(1<<BpFET)+(1<<CpFET)


.MACRO AnFET_on
	sbi	PORTD, AnFET
.ENDMACRO
.MACRO AnFET_off
	cbi	PORTD, AnFET
.ENDMACRO
.MACRO BnFET_on
	sbi	PORTC, BnFET
.ENDMACRO
.MACRO BnFET_off
	cbi	PORTC, BnFET
.ENDMACRO
.MACRO CnFET_on
	sbi	PORTB, CnFET
.ENDMACRO
.MACRO CnFET_off
	cbi	PORTB, CnFET
.ENDMACRO
.MACRO All_nFETs_Off
	cbi	PORTD, AnFET
	cbi	PORTC, BnFET
	cbi	PORTB, CnFET
.ENDMACRO

.MACRO ApFET_on
	cbi	PORTD, ApFET
.ENDMACRO
.MACRO ApFET_off
	sbi	PORTD, ApFET
.ENDMACRO
.MACRO BpFET_on
	cbi	PORTC, BpFET
.ENDMACRO
.MACRO BpFET_off
	sbi	PORTC, BpFET
.ENDMACRO
.MACRO CpFET_on
	cbi	PORTC, CpFET
.ENDMACRO
.MACRO CpFET_off
	sbi	PORTC, CpFET
.ENDMACRO
.MACRO All_pFETs_On
	cbi	PORTD, ApFET
	cbi	PORTC, BpFET
	cbi	PORTC, CpFET
.ENDMACRO
.MACRO All_pFETs_Off
	sbi	PORTD, ApFET
	sbi	PORTC, BpFET
	sbi	PORTC, CpFET
.ENDMACRO
.MACRO Damping_FET_On	
	lds	@0, DampingFET	
	sbrc	@0, 0
	cbi	PORTD, ApFET		
	sbrc	@0, 1
	cbi	PORTC, BpFET		
	sbrc	@0, 2
	cbi	PORTC, CpFET		
.ENDM

.MACRO Comp_Init
   	in	@0, SFIOR			; Set Analog Comparator Multiplexer Enable
   	sbr  @0, (1<<ACME) 	
   	out  SFIOR, @0
.ENDMACRO
.MACRO Set_Comp_Phase_A
   	ldi  @0, Mux_A 		; Set comparator multiplexer to phase A
  	out  ADMUX, @0
.ENDMACRO
.MACRO Set_Comp_Phase_B
   	ldi  @0, Mux_B  		; Set comparator multiplexer to phase B
  	out  ADMUX, @0
.ENDMACRO
.MACRO Set_Comp_Phase_C
   	ldi  @0, Mux_C  		; Set comparator multiplexer to phase C
  	out  ADMUX, @0
.ENDMACRO
.MACRO Read_Comp_Out
	in	@0, ACSR			; Read comparator output
.ENDMACRO


;*********************
; PORT B definitions *
;*********************
;.EQU			= 7	; i
;.EQU			= 6	; i
;.EQU			= 5	; i
.EQU	DebugPin		= 4	; o
;.EQU			= 3	; i
;.EQU			= 2	; i
;.EQU			= 1	; i
.EQU	CnFET		= 0	; o

.EQU	INIT_PB		= 0x00
.EQU	DIR_PB		= (1<<CnFET)+(1<<DebugPin)



;**********************
; MCU specific macros *
;**********************
.MACRO Interrupt_Table_Definition
	rjmp reset
	rjmp rcp_int	; ext_int0 
	nop			; ext_int1
	nop 			; t2oc_int
	rjmp t2_int	; t2ovfl_int
	nop			; icp1_int	
	rjmp t1oca_int	; t1oca_int
	nop			; t1ocb_int
	nop			; t1ovfl_int
	rjmp t0_int	; t0ovfl_int
	nop			; spi_int
	nop			; urxc
	nop			; udre
	nop			; utxc
;	nop			; adc_int
;	nop			; eep_int
;	nop			; aci_int
;	nop			; wire2_int
;	nop			; spmc_int
.ENDMACRO

.MACRO Disable_Watchdog
	cli					; Disable interrupts
	wdr					; Reset watchdog timer
	in	@0, WDTCR			; Write logical one to WDCE and WDE
	ori	@0, (1<<WDCE)|(1<<WDE)
	out	WDTCR, @0
	ldi	@0, (0<<WDE)		; Turn off WDT
	out	WDTCR, @0
.ENDMACRO
.MACRO Enable_Watchdog
	ldi	@0, (1<<WDE)		; Turn on WDT
	out	WDTCR, @0
.ENDMACRO

.MACRO Initialize_MCU
.ENDMACRO

.MACRO Initialize_Interrupts 
	ldi	@0, (1<<TOIE0)+(1<<OCIE1A)+(1<<TOIE2)
	out	TIFR, @0			; Clear interrupts
	out	TIMSK, @0			; Enable interrupts
.ENDMACRO

.MACRO Initialize_Adc
  	in  	@0, ADCSRA		; Set ADCSRA register (1MHz clock)
  	sbr  @0, (1<<ADPS2) 	
   	out  ADCSRA, @0
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
	ldi	@0, Temp_Ip
	out	ADMUX, @0			; Set ADMUX register (5V reference, selected input)
 	in  	@0, ADCSRA	
  	sbr  @0, (1<<ADEN) 		; Enable ADC	
  	sbr  @0, (1<<ADSC) 		; Start ADC conversion	
   	out  ADCSRA, @0
.ENDMACRO
.MACRO Get_Adc_Status
  	in  	@0, ADCSRA	
.ENDMACRO
.MACRO Read_Adc_Result
  	in  	@0, ADCL	
  	in  	@1, ADCH	
.ENDMACRO
.MACRO Stop_Adc
  	in  	@0, ADCSRA	
  	cbr  @0, (1<<ADEN) 		; Disable ADC	
   	out  ADCSRA, @0
.ENDMACRO

.MACRO Set_Timer0_CS0
	out	TCCR0, @0
.ENDMACRO
.MACRO Set_Timer1_CS1
	out	TCCR1B, @0
.ENDMACRO
.MACRO Set_Timer2_CS2
	out	TCCR2, @0
.ENDMACRO

.MACRO Read_TCNT1L
	in	@0, TCNT1L
.ENDMACRO
.MACRO Read_TCNT1H
	in	@0, TCNT1H
.ENDMACRO
.MACRO Set_OCR1AL
	out	OCR1AL, @0
.ENDMACRO
.MACRO Set_OCR1AH
	out	OCR1AH, @0
.ENDMACRO

.MACRO Read_TCNT2
	in	@0, TCNT2
.ENDMACRO
.MACRO Set_TCNT2
	out	TCNT2, @0
.ENDMACRO

.MACRO Check_Eeprom_Ready
	sbic	EECR, EEWE
.ENDMACRO
.MACRO Set_Eeprom_Address
	out  EEARL, @0
	out  EEARH, @1
.ENDMACRO
.MACRO Start_Eeprom_Write
	sbi  EECR, EEMWE
	sbi  EECR, EEWE
.ENDMACRO

.MACRO Prepare_Lock_Or_Fuse_Read
	ldi	@0, ((1<<BLBSET)+(1<<SPMEN))
	out	SPMCR, @0
.ENDMACRO

.MACRO xcall
	rcall @0
.ENDMACRO

.MACRO Set_RPM_Out
.ENDMACRO
.MACRO Clear_RPM_Out
.ENDMACRO
