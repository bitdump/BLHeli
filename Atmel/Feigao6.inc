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
.equ ADC_LIMIT_L	= 211	; Power supply measurement ADC value for which main motor power is limited (low byte)
.equ ADC_LIMIT_H	= 0		; Power supply measurement ADC value for which main motor power is limited (2 MSBs)

;*********************
; PORT D definitions *
;*********************  
;.equ			= 7	;i
.equ	Comp_Com		= 6	;i Comparator common input (AIN0)
.equ	ApFET		= 5	;o
.equ	CpFET		= 4	;o
.equ	BpFET		= 3	;o
.equ	Rcp_In		= 2	;i RC pulse input
;.equ       		= 1	;i
;.equ       		= 0	;i

.equ	INIT_PD		= 0
.equ	DIR_PD		= (1<<ApFET)+(1<<BpFET)+(1<<CpFET)

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

.MACRO ApFET_on
	sbi	PORTD,5
.ENDMACRO
.MACRO ApFET_off
	cbi	PORTD,5
.ENDMACRO
.MACRO CpFET_on
	sbi	PORTD,4
.ENDMACRO
.MACRO CpFET_off
	cbi	PORTD,4
.ENDMACRO
.MACRO BpFET_on
	sbi	PORTD,3
.ENDMACRO
.MACRO BpFET_off
	cbi	PORTD,3
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
.equ	Mux_A		= 5	; Phase A input
.equ	Mux_C		= 4	; Phase C input
;.equ    	  		= 3	; ADC3
.equ Mux_B 		= 2	; Phase B input
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
.equ	AnFET		= 2
.equ	CnFET		= 1
.equ	BnFET		= 0

.equ	INIT_PB		= 0
.equ	DIR_PB		= (1<<DebugPin)+(1<<AnFET)+(1<<BnFET)+(1<<CnFET)

.MACRO AnFET_on
	sbi	PORTB,2
.ENDMACRO
.MACRO AnFET_off
	cbi	PORTB,2
.ENDMACRO
.MACRO CnFET_on
	sbi	PORTB,1
.ENDMACRO
.MACRO CnFET_off
	cbi	PORTB,1
.ENDMACRO
.MACRO BnFET_on
	sbi	PORTB,0
.ENDMACRO
.MACRO BnFET_off
	cbi	PORTB,0
.ENDMACRO
.MACRO All_nFETs_Off
	in	@0, PORTB
	cbr	@0, (1<<AnFET)+(1<<BnFET)+(1<<CnFET)
	out	PORTB, @0
.ENDMACRO

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
	nop			; icp1_int	
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
	ldi	Temp1, (1<<REFS1)+(1<<REFS0)
	out	ADMUX, Temp1	; Set ADMUX register (2.56V reference, left adj result, input 0)
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
