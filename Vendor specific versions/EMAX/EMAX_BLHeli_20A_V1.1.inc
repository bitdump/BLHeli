;---------------------------------------------------------------------------
; 
; 
;
;
; FILE NAME: C8051F330.INC
; TARGET MCUs: C8051F330, F331
; DESCRIPTION: Register/bit definitions for the C8051F330 product family.
;
; REVISION 1.0
;
;---------------------------------------------------------------------------

;REGISTER DEFINITIONS
;
P0             DATA 080H    ; PORT 0 LATCH
SP             DATA 081H    ; STACK POINTER
DPL            DATA 082H    ; DATA POINTER LOW
DPH            DATA 083H    ; DATA POINTER HIGH
PCON           DATA 087H    ; POWER CONTROL
TCON           DATA 088H    ; TIMER/COUNTER CONTROL
TMOD           DATA 089H    ; TIMER/COUNTER MODE
TL0            DATA 08AH    ; TIMER/COUNTER 0 LOW
TL1            DATA 08BH    ; TIMER/COUNTER 1 LOW
TH0            DATA 08CH    ; TIMER/COUNTER 0 HIGH
TH1            DATA 08DH    ; TIMER/COUNTER 1 HIGH
CKCON          DATA 08EH    ; CLOCK CONTROL
PSCTL          DATA 08FH    ; PROGRAM STORE R/W CONTROL
P1             DATA 090H    ; PORT 1 LATCH
TMR3CN         DATA 091H    ; TIMER/COUNTER 3 CONTROL
TMR3RLL        DATA 092H    ; TIMER/COUNTER 3 RELOAD LOW
TMR3RLH        DATA 093H    ; TIMER/COUNTER 3 RELOAD HIGH
TMR3L          DATA 094H    ; TIMER/COUNTER 3 LOW
TMR3H          DATA 095H    ; TIMER/COUNTER 3 HIGH
IDA0L          DATA 096H    ; CURRENT MODE DAC0 LOW
IDA0H          DATA 097H    ; CURRENT MODE DAC0 HIGH
SCON0          DATA 098H    ; UART0 CONTROL
SBUF0          DATA 099H    ; UART0 DATA BUFFER
CPT0CN         DATA 09BH    ; COMPARATOR0 CONTROL
CPT0MD         DATA 09DH    ; COMPARATOR0 MODE SELECTION
CPT0MX         DATA 09FH    ; COMPARATOR0 MUX SELECTION
P2             DATA 0A0H    ; PORT 2 LATCH
SPI0CFG        DATA 0A1H    ; SPI CONFIGURATION
SPI0CKR        DATA 0A2H    ; SPI CLOCK RATE CONTROL
SPI0DAT        DATA 0A3H    ; SPI DATA
P0MDOUT        DATA 0A4H    ; PORT 0 OUTPUT MODE CONFIGURATION
P1MDOUT        DATA 0A5H    ; PORT 1 OUTPUT MODE CONFIGURATION
P2MDOUT        DATA 0A6H    ; PORT 2 OUTPUT MODE CONFIGURATION
IE             DATA 0A8H    ; INTERRUPT ENABLE
CLKSEL         DATA 0A9H    ; CLOCK SELECT
EMI0CN         DATA 0AAH    ; EXTERNAL MEMORY INTERFACE CONTROL
OSCXCN         DATA 0B1H    ; EXTERNAL OSCILLATOR CONTROL
OSCICN         DATA 0B2H    ; INTERNAL OSCILLATOR CONTROL
OSCICL         DATA 0B3H    ; INTERNAL OSCILLATOR CALIBRATION
FLSCL          DATA 0B6H    ; FLASH SCALE
FLKEY          DATA 0B7H    ; FLASH LOCK AND KEY
IP             DATA 0B8H    ; INTERRUPT PRIORITY
IDA0CN         DATA 0B9H    ; CURRENT MODE DAC0 CONTROL
AMX0N          DATA 0BAH    ; AMUX0 NEGATIVE CHANNEL SELECT
AMX0P          DATA 0BBH    ; AMUX0 POSITIVE CHANNEL SELECT
ADC0CF         DATA 0BCH    ; ADC0 CONFIGURATION
ADC0L          DATA 0BDH    ; ADC0 LOW
ADC0H          DATA 0BEH    ; ADC0 HIGH
SMB0CN         DATA 0C0H    ; SMBUS CONTROL
SMB0CF         DATA 0C1H    ; SMBUS CONFIGURATION
SMB0DAT        DATA 0C2H    ; SMBUS DATA
ADC0GTL        DATA 0C3H    ; ADC0 GREATER-THAN COMPARE LOW
ADC0GTH        DATA 0C4H    ; ADC0 GREATER-THAN COMPARE HIGH
ADC0LTL        DATA 0C5H    ; ADC0 LESS-THAN COMPARE WORD LOW
ADC0LTH        DATA 0C6H    ; ADC0 LESS-THAN COMPARE WORD HIGH
TMR2CN         DATA 0C8H    ; TIMER/COUNTER 2 CONTROL
TMR2RLL        DATA 0CAH    ; TIMER/COUNTER 2 RELOAD LOW
TMR2RLH        DATA 0CBH    ; TIMER/COUNTER 2 RELOAD HIGH
TMR2L          DATA 0CCH    ; TIMER/COUNTER 2 LOW
TMR2H          DATA 0CDH    ; TIMER/COUNTER 2 HIGH
PSW            DATA 0D0H    ; PROGRAM STATUS WORD
REF0CN         DATA 0D1H    ; VOLTAGE REFERENCE CONTROL
P0SKIP         DATA 0D4H    ; PORT 0 SKIP
P1SKIP         DATA 0D5H    ; PORT 1 SKIP
PCA0CN         DATA 0D8H    ; PCA CONTROL
PCA0MD         DATA 0D9H    ; PCA MODE
PCA0CPM0       DATA 0DAH    ; PCA MODULE 0 MODE REGISTER
PCA0CPM1       DATA 0DBH    ; PCA MODULE 1 MODE REGISTER
PCA0CPM2       DATA 0DCH    ; PCA MODULE 2 MODE REGISTER
ACC            DATA 0E0H    ; ACCUMULATOR
XBR0           DATA 0E1H    ; PORT I/O CROSSBAR CONTROL 0
XBR1           DATA 0E2H    ; PORT I/O CROSSBAR CONTROL 1
OSCLCN         DATA 0E3H    ; LOW-FREQUENCY OSCILLATOR CONTROL
IT01CF         DATA 0E4H    ; INT0/INT1 CONFIGURATION
EIE1           DATA 0E6H    ; EXTENDED INTERRUPT ENABLE 1
ADC0CN         DATA 0E8H    ; ADC0 CONTROL
PCA0CPL1       DATA 0E9H    ; PCA CAPTURE 1 LOW
PCA0CPH1       DATA 0EAH    ; PCA CAPTURE 1 HIGH
PCA0CPL2       DATA 0EBH    ; PCA CAPTURE 2 LOW
PCA0CPH2       DATA 0ECH    ; PCA CAPTURE 2 HIGH
RSTSRC         DATA 0EFH    ; RESET SOURCE CONFIGURATION/STATUS
B              DATA 0F0H    ; B REGISTER
P0MDIN         DATA 0F1H    ; PORT 0 INPUT MODE CONFIGURATION
P1MDIN         DATA 0F2H    ; PORT 1 INPUT MODE CONFIGURATION
EIP1           DATA 0F6H    ; EXTENDED INTERRUPT PRIORITY 1
SPI0CN         DATA 0F8H    ; SPI CONTROL
PCA0L          DATA 0F9H    ; PCA COUNTER LOW
PCA0H          DATA 0FAH    ; PCA COUNTER HIGH
PCA0CPL0       DATA 0FBH    ; PCA CAPTURE 0 LOW
PCA0CPH0       DATA 0FCH    ; PCA CAPTURE 0 HIGH
VDM0CN         DATA 0FFH    ; VDD MONITOR CONTROL

;
;------------------------------------------------------------------------------
;BIT DEFINITIONS
;
; TCON 088H
TF1            BIT 08FH     ; TIMER 1 OVERFLOW FLAG
TR1            BIT 08EH     ; TIMER 1 ON/OFF CONTROL
TF0            BIT 08DH     ; TIMER 0 OVERFLOW FLAG
TR0            BIT 08CH     ; TIMER 0 ON/OFF CONTROL
IE1            BIT 08BH     ; EXT. INTERRUPT 1 EDGE FLAG
IT1            BIT 08AH     ; EXT. INTERRUPT 1 TYPE
IE0            BIT 089H     ; EXT. INTERRUPT 0 EDGE FLAG
IT0            BIT 088H     ; EXT. INTERRUPT 0 TYPE

; SCON0 098H
S0MODE         BIT 09FH     ; UART 0 MODE
MCE0           BIT 09DH     ; UART 0 MCE
REN0           BIT 09CH     ; UART 0 RX ENABLE
TB80           BIT 09BH     ; UART 0 TX BIT 8
RB80           BIT 09AH     ; UART 0 RX BIT 8
TI0            BIT 099H     ; UART 0 TX INTERRUPT FLAG
RI0            BIT 098H     ; UART 0 RX INTERRUPT FLAG

; IE 0A8H
EA             BIT 0AFH     ; GLOBAL INTERRUPT ENABLE
ESPI0          BIT 0AEH     ; SPI0 INTERRUPT ENABLE
ET2            BIT 0ADH     ; TIMER 2 INTERRUPT ENABLE
ES0            BIT 0ACH     ; UART0 INTERRUPT ENABLE
ET1            BIT 0ABH     ; TIMER 1 INTERRUPT ENABLE
EX1            BIT 0AAH     ; EXTERNAL INTERRUPT 1 ENABLE
ET0            BIT 0A9H     ; TIMER 0 INTERRUPT ENABLE
EX0            BIT 0A8H     ; EXTERNAL INTERRUPT 0 ENABLE

; IP 0B8H
PSPI0          BIT 0BEH     ; SPI0 PRIORITY
PT2            BIT 0BDH     ; TIMER 2 PRIORITY
PS0            BIT 0BCH     ; UART0 PRIORITY
PT1            BIT 0BBH     ; TIMER 1 PRIORITY
PX1            BIT 0BAH     ; EXTERNAL INTERRUPT 1 PRIORITY
PT0            BIT 0B9H     ; TIMER 0 PRIORITY
PX0            BIT 0B8H     ; EXTERNAL INTERRUPT 0 PRIORITY

; SMB0CN 0C0H
MASTER         BIT 0C7H     ; SMBUS 0 MASTER/SLAVE
TXMODE         BIT 0C6H     ; SMBUS 0 TRANSMIT MODE
STA            BIT 0C5H     ; SMBUS 0 START FLAG
STO            BIT 0C4H     ; SMBUS 0 STOP FLAG
ACKRQ          BIT 0C3H     ; SMBUS 0 ACKNOWLEDGE REQUEST
ARBLOST        BIT 0C2H     ; SMBUS 0 ARBITRATION LOST
ACK            BIT 0C1H     ; SMBUS 0 ACKNOWLEDGE FLAG
SI             BIT 0C0H     ; SMBUS 0 INTERRUPT PENDING FLAG

; TMR2CN 0C8H
TF2H           BIT 0CFH     ; TIMER 2 HIGH BYTE OVERFLOW FLAG
TF2L           BIT 0CEH     ; TIMER 2 LOW BYTE OVERFLOW FLAG
TF2LEN         BIT 0CDH     ; TIMER 2 LOW BYTE INTERRUPT ENABLE
TF2CEN         BIT 0CCH     ; TIMER 2 LFO CAPTURE ENABLE
T2SPLIT        BIT 0CBH     ; TIMER 2 SPLIT MODE ENABLE
TR2            BIT 0CAH     ; TIMER 2 ON/OFF CONTROL
T2XCLK         BIT 0C8H     ; TIMER 2 EXTERNAL CLOCK SELECT

; PSW 0D0H
CY             BIT 0D7H     ; CARRY FLAG
AC             BIT 0D6H     ; AUXILIARY CARRY FLAG
F0             BIT 0D5H     ; USER FLAG 0
RS1            BIT 0D4H     ; REGISTER BANK SELECT 1
RS0            BIT 0D3H     ; REGISTER BANK SELECT 0
OV             BIT 0D2H     ; OVERFLOW FLAG
F1             BIT 0D1H     ; USER FLAG 1
P              BIT 0D0H     ; ACCUMULATOR PARITY FLAG

; PCA0CN 0D8H
CF             BIT 0DFH     ; PCA 0 COUNTER OVERFLOW FLAG
CR             BIT 0DEH     ; PCA 0 COUNTER RUN CONTROL BIT
CCF2           BIT 0DAH     ; PCA 0 MODULE 2 INTERRUPT FLAG
CCF1           BIT 0D9H     ; PCA 0 MODULE 1 INTERRUPT FLAG
CCF0           BIT 0D8H     ; PCA 0 MODULE 0 INTERRUPT FLAG
                            ; ADC 0 WINDOW INTERRUPT FLAG
; ADC0CN 0E8H
AD0EN          BIT 0EFH     ; ADC 0 ENABLE
AD0TM          BIT 0EEH     ; ADC 0 TRACK MODE
AD0INT         BIT 0EDH     ; ADC 0 EOC INTERRUPT FLAG
AD0BUSY        BIT 0ECH     ; ADC 0 BUSY FLAG
AD0WINT        BIT 0EBH     ; ADC 0 WINDOW INTERRUPT FLAG
AD0CM2         BIT 0EAH     ; ADC 0 CONVERT START MODE BIT 2
AD0CM1         BIT 0E9H     ; ADC 0 CONVERT START MODE BIT 1
AD0CM0         BIT 0E8H     ; ADC 0 CONVERT START MODE BIT 0

; SPI0CN 0F8H
SPIF           BIT 0FFH     ; SPI 0 INTERRUPT FLAG
WCOL           BIT 0FEH     ; SPI 0 WRITE COLLISION FLAG
MODF           BIT 0FDH     ; SPI 0 MODE FAULT FLAG
RXOVRN         BIT 0FCH     ; SPI 0 RX OVERRUN FLAG
NSSMD1         BIT 0FBH     ; SPI 0 SLAVE SELECT MODE 1
NSSMD0         BIT 0FAH     ; SPI 0 SLAVE SELECT MODE 0
TXBMT          BIT 0F9H     ; SPI 0 TX BUFFER EMPTY FLAG
SPIEN          BIT 0F8H     ; SPI 0 SPI ENABLE


;**** **** **** **** ****
; Uses internal calibrated oscillator set to 24Mhz
;**** **** **** **** ****

;**** **** **** **** ****
; Constant definitions
;**** **** **** **** ****
CSEG AT 1A40h
Eep_ESC_Layout:		DB	"#XP18A#         "	; ESC layout tag
CSEG AT 1A50h
Eep_ESC_MCU:			DB	"#BLHELI#F330#   "	; Project and MCU tag (16 Bytes)

PORT3_EXIST			EQU	0	; Set to 1 if MCU has port3
COMP1_USED			EQU	0	; Set to 1 if MCU has comparator 1 and it is being used
DUAL_BEC_VOLTAGE		EQU	0	; Set to 1 if dual BEC voltage is supported
DAMPED_MODE_ENABLE		EQU	1	; Damped mode disabled
NFETON_DELAY			EQU	1	; Wait delay from pfets off to nfets on
PFETON_DELAY			EQU	1	; Wait delay from nfets off to pfets on
COMP_PWM_HIGH_ON_DELAY	EQU	15	; Wait delay from pwm on until comparator can be read (for high pwm frequency)
COMP_PWM_HIGH_OFF_DELAY	EQU	20	; Wait delay from pwm off until comparator can be read (for high pwm frequency)
COMP_PWM_LOW_ON_DELAY	EQU	5	; Wait delay from pwm on until comparator can be read (for low pwm frequency)
COMP_PWM_LOW_OFF_DELAY	EQU	7	; Wait delay from pwm off until comparator can be read (for low pwm frequency)
ADC_LIMIT_L			EQU 	80	;改一节电池低压基值	2.8V		2013.05.31
;ADC_LIMIT_L			EQU 	85	; Power supply measurement ADC value for which main motor power is limited (low byte)
ADC_LIMIT_H			EQU	0	; Power supply measurement ADC value for which main motor power is limited (2 MSBs)
TEMP_LIMIT			EQU 	74	; 2013.8.20 温度140改120  Temperature measurement ADC value for which main motor power is limited (low byte, assuming high byte is 1)
TEMP_LIMIT_STEP		EQU	5	; Temperature measurement ADC value increment for which main motor power is further limited
MAIN_SPOOLUP_TIME		EQU	10	; Main motor spoolup time

;**** **** **** **** ****
; ESC specific defaults
;**** **** **** **** ****
DEFAULT_PGM_MAIN_STARTUP_PWR 		EQU 10 	; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50
DEFAULT_PGM_TAIL_STARTUP_PWR 		EQU 10 	; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50
DEFAULT_PGM_MULTI_STARTUP_PWR 	EQU 10 	; 1=0.031 2=0.047 3=0.063 4=0.094 5=0.125 6=0.188	7=0.25  8=0.38  9=0.50  10=0.75 11=1.00 12=1.25 13=1.50
DEFAULT_PGM_MAIN_STARTUP_METHOD	EQU 2 	; 1=Stepped	2=Direct
DEFAULT_PGM_TAIL_STARTUP_METHOD	EQU 2 	; 1=Stepped	2=Direct
DEFAULT_PGM_MULTI_STARTUP_METHOD	EQU 2 	; 1=Stepped	2=Direct


;*********************
; PORT 0 definitions *
;*********************  
Rcp_In		EQU	7	;i
Adc_Ip		EQU	6	;i
Mux_A		EQU	5	;i
;			EQU	4	;i
Mux_B		EQU	3	;i
Comp_Com		EQU	2	;i
Mux_C		EQU	1	;i
Vref			EQU	0	;i

P0_DIGITAL	EQU	NOT((1 SHL Mux_A)+(1 SHL Mux_B)+(1 SHL Mux_C)+(1 SHL Comp_Com)+(1 SHL Adc_Ip)+(1 SHL Vref))
P0_INIT		EQU	0FFh
P0_PUSHPULL	EQU	0
P0_SKIP		EQU	NOT(1 SHL Rcp_In) AND 0FFh

MACRO Read_Rcp_Int
	mov	A, P0
	jnb	Flags3.PGM_RCP_PWM_POL, ($+4)	; Is pwm polarity negative?
	cpl	A						; Yes - invert
ENDM
MACRO Rcp_Int_Enable
	orl	PCA0CPM0, #01h				; Interrupt enabled
ENDM
MACRO Rcp_Int_Disable
	anl	PCA0CPM0, #0FEh			; Interrupt disabled
ENDM
MACRO Rcp_Int_First
	anl	PCA0CPM0, #0CFh			
	jb	Flags3.PGM_RCP_PWM_POL, ($+6)	; Is pwm polarity positive?
	orl	PCA0CPM0, #20h				; Capture rising edge
	jnb	Flags3.PGM_RCP_PWM_POL, ($+6)	; Is pwm polarity negative?
	orl	PCA0CPM0, #10h				; Capture falling edge
ENDM
MACRO Rcp_Int_Second
	anl	PCA0CPM0, #0CFh			
	jb	Flags3.PGM_RCP_PWM_POL, ($+6)	; Is pwm polarity positive?
	orl	PCA0CPM0, #10h				; Capture falling edge
	jnb	Flags3.PGM_RCP_PWM_POL, ($+6)	; Is pwm polarity negative?
	orl	PCA0CPM0, #20h				; Capture rising edge
ENDM
MACRO Rcp_Clear_Int_Flag
	clr 	CCF0						; Clear interrupt flag
ENDM		


;*********************
; PORT 1 definitions *
;*********************
DriverEn		EQU	7	;o	At least on some escs. Others are hardwired
;			EQU	6	;i
AnFET		EQU	2	;o	"nFETs" are really the high side drivers
BnFET		EQU	1	;o
CnFET		EQU	0	;o
ApFET		EQU	5	;o	"pFETs" are really the low side drivers
BpFET		EQU	4	;o
CpFET		EQU	3	;o

P1_DIGITAL	EQU	(1 SHL AnFET)+(1 SHL BnFET)+(1 SHL CnFET)+(1 SHL ApFET)+(1 SHL BpFET)+(1 SHL CpFET)+(1 SHL DriverEn)
P1_INIT		EQU 	080h	
P1_PUSHPULL	EQU	(1 SHL AnFET)+(1 SHL BnFET)+(1 SHL CnFET)+(1 SHL ApFET)+(1 SHL BpFET)+(1 SHL CpFET)+(1 SHL DriverEn)
P1_SKIP		EQU	0

MACRO AnFET_on
	mov	A, Current_Pwm_Limited
	jz	($+12)
	jb	Flags3.PGM_DIR_REV, ($+5)
	setb	P1.AnFET
	jnb	Flags3.PGM_DIR_REV, ($+5)
	setb	P1.CnFET
ENDM
MACRO AnFET_off
	jb	Flags3.PGM_DIR_REV, ($+5)
	clr	P1.AnFET
	jnb	Flags3.PGM_DIR_REV, ($+5)
	clr	P1.CnFET
ENDM
MACRO BnFET_on
	mov	A, Current_Pwm_Limited
	jz	($+4)
	setb	P1.BnFET
ENDM
MACRO BnFET_off
	clr	P1.BnFET
ENDM
MACRO CnFET_on
	mov	A, Current_Pwm_Limited
	jz	($+12)
	jb	Flags3.PGM_DIR_REV, ($+5)
	setb	P1.CnFET
	jnb	Flags3.PGM_DIR_REV, ($+5)
	setb	P1.AnFET
ENDM
MACRO CnFET_off
	jb	Flags3.PGM_DIR_REV, ($+5)
	clr	P1.CnFET
	jnb	Flags3.PGM_DIR_REV, ($+5)
	clr	P1.AnFET
ENDM
MACRO All_nFETs_Off
	clr	P1.AnFET
	clr	P1.BnFET
	clr	P1.CnFET
ENDM
MACRO All_nFETs_On
	setb	P1.AnFET
	setb	P1.BnFET
	setb	P1.CnFET
ENDM
MACRO A_B_nFETs_On
	setb	P1.AnFET
	setb	P1.BnFET
ENDM

MACRO ApFET_on
	jb	Flags3.PGM_DIR_REV, ($+5)
	setb	P1.ApFET
	jnb	Flags3.PGM_DIR_REV, ($+5)
	setb	P1.CpFET
ENDM
MACRO ApFET_off
	jb	Flags3.PGM_DIR_REV, ($+5)
	clr	P1.ApFET
	jnb	Flags3.PGM_DIR_REV, ($+5)
	clr	P1.CpFET
ENDM
MACRO BpFET_on
	setb	P1.BpFET
ENDM
MACRO BpFET_off
	clr	P1.BpFET
ENDM
MACRO CpFET_on
	jb	Flags3.PGM_DIR_REV, ($+5)
	setb	P1.CpFET
	jnb	Flags3.PGM_DIR_REV, ($+5)
	setb	P1.ApFET
ENDM
MACRO CpFET_off
	jb	Flags3.PGM_DIR_REV, ($+5)
	clr	P1.CpFET
	jnb	Flags3.PGM_DIR_REV, ($+5)
	clr	P1.ApFET
ENDM
MACRO All_pFETs_Off
	clr	P1.ApFET
	clr	P1.BpFET
	clr	P1.CpFET
ENDM
;MACRO All_pFETs_On
;	setb	P1.ApFET
;	setb	P1.BpFET
;	setb	P1.CpFET
;ENDM

MACRO Set_Comp_Phase_A
	jb	Flags3.PGM_DIR_REV, ($+6)
	mov	CPT0MX, #21h	; Set comparator multiplexer to phase A
	jnb	Flags3.PGM_DIR_REV, ($+6)
	mov	CPT0MX, #01h
ENDM
MACRO Set_Comp_Phase_B
	mov	CPT0MX, #11h	; Set comparator multiplexer to phase B
ENDM
MACRO Set_Comp_Phase_C
	jb	Flags3.PGM_DIR_REV, ($+6)
	mov	CPT0MX, #01h	; Set comparator multiplexer to phase C
	jnb	Flags3.PGM_DIR_REV, ($+6)
	mov	CPT0MX, #21h
ENDM
MACRO Read_Comp_Out
	mov	A, CPT0CN		; Read comparator output
	cpl A
ENDM


;*********************
; PORT 2 definitions *
;*********************
DebugPin		EQU	0	;o

P2_PUSHPULL	EQU	(1 SHL DebugPin)


;**********************
; MCU specific macros *
;**********************
MACRO Interrupt_Table_Definition
CSEG AT 0				; Code segment start
	jmp reset
CSEG AT 0Bh			; Timer0 interrupt	
	jmp	t0_int	
CSEG AT 2Bh			; Timer2 interrupt	
	jmp	t2_int	
CSEG AT 5Bh			; PCA interrupt	
	jmp	pca_int	
CSEG AT 73h			; Timer3 interrupt	
	jmp	t3_int	
ENDM

MACRO Initialize_Adc
	mov	REF0CN, #0Eh	; Set vdd (3.3V) as reference. Enable temp sensor and bias
	mov	ADC0CF, #58h	; ADC clock 2MHz
	mov	AMX0P, #Adc_Ip	; Select positive input
	mov	AMX0N, #11h	; Select negative input as ground
	mov	ADC0CN, #80h	; ADC enabled
ENDM
MACRO Set_Adc_Ip_Volt
	mov	AMX0P, #Adc_Ip	; Select positive input			选择电压检测，P0.6为电压正输入
ENDM
MACRO Set_Adc_Ip_Temp
	mov	AMX0P, #10h	; Select temp sensor input
ENDM
MACRO Start_Adc
	mov	ADC0CN, #90h	; ADC start
ENDM
MACRO Get_Adc_Status
	mov	A, ADC0CN		
ENDM
MACRO Read_Adc_Result
	mov	Temp1, ADC0L
	mov	Temp2, ADC0H
ENDM
MACRO Stop_Adc
ENDM
