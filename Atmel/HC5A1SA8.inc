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



;*********************
; Device Atmega8
;*********************
.include "m8def.inc"

.equ	ICP  = 0					; Choose input pin. Set to 0 for INT0 (pin32) and 1 for ICP1 (pin12)

;**** **** **** **** ****
; Fuses must be set to internal calibrated oscillator = 8Mhz
;**** **** **** **** ****

;**** **** **** **** ****
; Constant definitions
;**** **** **** **** ****
.equ ADC_LIMIT_L	= 45		; Power supply measurement ADC value for which main motor power is limited (low byte)
.equ ADC_LIMIT_H	= 0		; Power supply measurement ADC value for which main motor power is limited (2 MSBs)

;*********************
; PORT D definitions *
;*********************  
.equ BpFET		= 7	;o
.equ	Comp_Com		= 6	;i Comparator common input (AIN0)
.equ	CpFET		= 5	;o
.equ	ApFET		= 4	;o
.equ	AnFET		= 3	;o
.equ	Rcp_In		= 2	;i RC pulse input
.equ BnFET      	= 1	;o
.equ CnFET      	= 0	;o

.equ	INIT_PD		= 0
.equ	DIR_PD		= (1<<AnFET)+(1<<BnFET)+(1<<CnFET)+(1<<ApFET)+(1<<BpFET)+(1<<CpFET)

.MACRO Read_Rcp_Int
	in	@0, PIND
	sbrc Flags2, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	com	@0					; Yes - invert
.ENDMACRO
.MACRO Read_Rcp_Icp_Int
	in	@0, PINB
	sbrc Flags2, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	com	@0					; Yes - invert
.ENDMACRO

.MACRO Rcp_Int_Enable
	ldi @0, (1<<INT0)	; Enable ext0int
	out	GICR, @0
.ENDMACRO
.MACRO Rcp_Int_Disable
	ldi @0, 0			; Disable ext0int
	out	GICR, @0
.ENDMACRO
.MACRO Rcp_Int_First
	sbrs	Flags2, PGM_RCP_PWM_POL	; Is pwm polarity positive?
	ldi @0, (1<<ISC01)+(1<<ISC00)	; Yes - set next int0 to rising
	sbrc Flags2, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	ldi @0, (1<<ISC01)			; Yes - set next int0 to falling
	out	MCUCR, @0		
.ENDMACRO
.MACRO Rcp_Int_Second
	sbrs	Flags2, PGM_RCP_PWM_POL	; Is pwm polarity positive?
	ldi @0, (1<<ISC01)			; Yes - set next int0 to falling
	sbrc Flags2, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	ldi @0, (1<<ISC01)+(1<<ISC00)	; Yes - set next int0 to rising
	out	MCUCR, @0		
.ENDMACRO
.MACRO Clear_Int_Flag
	clr 	@0
	sbr @0, (1<<INTF0)	; Clear ext0int flag
	out	GIFR, @0		
.ENDMACRO

.MACRO Rcp_Icp_Int_Enable
	in	@0, TIMSK
	sbr @0, (1<<TICIE1)	; Enable icp1int
	out	TIMSK, @0
.ENDMACRO
.MACRO Rcp_Icp_Int_Disable
	in	@0, TIMSK
	cbr @0, (1<<TICIE1)	; Disable icp1int
	out	TIMSK, @0
.ENDMACRO

.MACRO Rcp_Icp_Int_First
	in	@0, TCCR1B
	sbrs	Flags2, PGM_RCP_PWM_POL	; Is pwm polarity positive?
	sbr @0, (1<<ICES1)			; Yes - set icp1int to trig on rising edge
	sbrc Flags2, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	cbr @0, (1<<ICES1)			; Yes - set icp1int to trig on falling edge
	out	TCCR1B, @0		
.ENDMACRO
.MACRO Rcp_Icp_Int_Second
	in	@0, TCCR1B
	sbrs	Flags2, PGM_RCP_PWM_POL	; Is pwm polarity positive?
	cbr @0, (1<<ICES1)			; Yes - set icp1int to trig on falling edge
	sbrc Flags2, PGM_RCP_PWM_POL	; Is pwm polarity negative?
	sbr @0, (1<<ICES1)			; Yes - set icp1int to trig on rising edge
	out	TCCR1B, @0		
.ENDMACRO
.MACRO Clear_Icp_Int_Flag
	clr 	@0
	sbr @0, (1<<ICF1)	; Clear icp1int flag
	out	TIFR, @0		
.ENDMACRO

.MACRO AnFET_on
	sbi	PORTD,3
.ENDMACRO
.MACRO AnFET_off
	cbi	PORTD,3
.ENDMACRO
.MACRO BnFET_on
	sbi	PORTD,1
.ENDMACRO
.MACRO BnFET_off
	cbi	PORTD,1
.ENDMACRO
.MACRO CnFET_on
	sbi	PORTD,0
.ENDMACRO
.MACRO CnFET_off
	cbi	PORTD,0
.ENDMACRO
.MACRO All_nFETs_Off
	in	@0, PORTD
	cbr	@0, (1<<AnFET)+(1<<BnFET)+(1<<CnFET)
	out	PORTD, @0
.ENDMACRO

.MACRO ApFET_on
	sbi	PORTD,4
.ENDMACRO
.MACRO ApFET_off
	cbi	PORTD,4
.ENDMACRO
.MACRO BpFET_on
	sbi	PORTD,7
.ENDMACRO
.MACRO BpFET_off
	cbi	PORTD,7
.ENDMACRO
.MACRO CpFET_on
	sbi	PORTD,5
.ENDMACRO
.MACRO CpFET_off
	cbi	PORTD,5
.ENDMACRO
.MACRO All_pFETs_Off
	in	@0, PORTD
	cbr	@0, (1<<ApFET)+(1<<BpFET)+(1<<CpFET)
	out	PORTD, @0
.ENDMACRO
.MACRO All_pFETs_On
	in	@0, PORTD
	sbr	@0, (1<<ApFET)+(1<<BpFET)+(1<<CpFET)
	out	PORTD, @0
.ENDMACRO


;*********************
; PORT C definitions *
;*********************
;.equ    	  		= 7	; ADC7
;.equ    	  		= 6	; ADC6
;.equ    	  		= 5	; ADC5
.equ	Mux_A		= 4	; Phase A input
.equ Mux_B 		= 3	; Phase B input
.equ	Mux_C		= 2	; Phase C input
;.equ 	 		= 1 	; ADC1
;.equ 			= 0 	; ADC0

.equ	INIT_PC		= 0
.equ	DIR_PC		= 0

.MACRO Comp_Init
   	in  @0, SFIOR		; Set Analog Comparator Multiplexer Enable
   	sbr  @0, (1<<ACME) 	
   	out  SFIOR, @0
   	cbi  ADCSRA, ADEN  	; Disable ADC
.ENDMACRO
.MACRO Set_Comp_Phase_A
   	ldi  @0, Mux_A  	; Set comparator multiplexer to phase A
   	out  ADMUX, @0
.ENDMACRO
.MACRO Set_Comp_Phase_B
   	ldi  @0, Mux_B  	; Set comparator multiplexer to phase B
   	out  ADMUX, @0
.ENDMACRO
.MACRO Set_Comp_Phase_C
   	ldi  @0, Mux_C  	; Set comparator multiplexer to phase C
   	out  ADMUX, @0
.ENDMACRO
.MACRO Read_Comp_Out
	in	@0, ACSR		; Read comparator output
.ENDMACRO


;*********************
; PORT B definitions *
;*********************
;.equ			= 7
;.equ			= 6
;.equ			= 5 	(sck stk200 interface) 
.equ	DebugPin		= 4	;(miso stk200 interface)
;.equ			= 3	(mosi stk200 interface) 
;.equ			= 2
;.equ			= 1
.equ	Rcp_Icp_In	= 0

.equ	INIT_PB		= 0
.equ	DIR_PB		= (1<<DebugPin)


;**********************
; MCU specific macros *
;**********************
.MACRO Disable_Watchdog
	cli					; Disable interrupts
	wdr					; Reset watchdog timer
	in @0, WDTCR			; Write logical one to WDCE and WDE
	ori @0, (1<<WDCE)|(1<<WDE)
	out WDTCR, @0
	ldi @0, (0<<WDE)		; Turn off WDT
	out WDTCR, @0
.ENDMACRO
.MACRO Enable_Watchdog
	ldi @0, (1<<WDE)		; Turn on WDT
	sts WDTCR, @0
.ENDMACRO

.MACRO Initialize_MCU
.ENDMACRO

.MACRO Interrupt_Table_Definition
	rjmp reset
	rjmp ext_int0	; ext_int0 
	nop			; ext_int1
	nop 			; t2oc_int
	rjmp t2ovfl_int; t2ovfl_int
	rjmp icp1_int	; icp1_int	
	rjmp t1oca_int	; t1oca_int
	nop			; t1ocb_int
	rjmp t1ovfl_int; t1ovfl_int
	rjmp t0ovfl_int; t0ovfl_int
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

.MACRO Initialize_Interrupts
	ldi	Temp1, (1<<TOIE0)+(1<<TOIE1)+(1<<OCIE1A)+(1<<TOIE2)
	out	TIFR, Temp1	; Clear interrupts
	out	TIMSK, Temp1	; Enable interrupts
.ENDMACRO

.MACRO Initialize_Adc
  	in  	Temp1, ADCSRA	; Set ADCSRA register (1MHz clock)
  	sbr  Temp1, (1<<ADPS1) 	
  	sbr  Temp1, (1<<ADPS0) 	
   	out  ADCSRA, Temp1
.ENDMACRO
.MACRO Start_Adc
	ldi	Temp1, (1<<REFS1)+(1<<REFS0)+(1<<MUX2)+(1<<MUX1)+(1<<MUX0)
	out	ADMUX, Temp1	; Set ADMUX register (2.56V reference, left adj result, input 7)
  	in  	@0, ADCSRA	
  	sbr  @0, (1<<ADEN) 	; Enable ADC	
  	sbr  @0, (1<<ADSC) 	; Start ADC conversion	
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
  	cbr  @0, (1<<ADEN) 	; Disable ADC	
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
.MACRO Read_ICR1L
	in	@0, ICR1L
.ENDMACRO
.MACRO Read_ICR1H
	in	@0, ICR1H
.ENDMACRO
.MACRO Set_OCR1AL
	out	OCR1AL, @0
.ENDMACRO
.MACRO Set_OCR1AH
	out	OCR1AH, @0
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
