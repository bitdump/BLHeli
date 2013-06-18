;------------------------------------------------------------------------------
; C8051F390_defs.inc
;------------------------------------------------------------------------------
; Copyright 2011 Silicon Laboratories, Inc.
; http:; www.silabs.com
;
; Program Description:
;
; Register/bit definitions for the C8051F39x/37x family.
;
;
; Target:         C8051F39x, C8051F37x
; Tool chain:     Generic
; Command Line:   None
;
; Release 0.1
;    -28 NOV 2011 (BD)
;    -Initial revision (beta)


;-----------------------------------------------------------------------------
; Byte Registers
;-----------------------------------------------------------------------------

ACC         DATA 0E0H                  ; Accumulator
ADC0CF      DATA 0BCH                  ; ADC0 Configuration
ADC0CN      DATA 0E8H                  ; ADC0 Control
ADC0GTH     DATA 0C4H                  ; ADC0 Greater-Than Compare High
ADC0GTL     DATA 0C3H                  ; ADC0 Greater-Than Compare Low
ADC0H       DATA 0BEH                  ; ADC0 High
ADC0L       DATA 0BDH                  ; ADC0 Low
ADC0LTH     DATA 0C6H                  ; ADC0 Less-Than Compare Word High
ADC0LTL     DATA 0C5H                  ; ADC0 Less-Than Compare Word Low
AMX0N       DATA 0BAH                  ; AMUX0 Negative Channel Select
AMX0P       DATA 0BBH                  ; AMUX0 Positive Channel Select
B           DATA 0F0H                  ; B Register
CKCON       DATA 08EH                  ; Clock Control
CKCON1      DATA 0F4H                  ; Clock Control 1
CLKSEL      DATA 0A9H                  ; Clock Select
CPT0CN      DATA 09BH                  ; Comparator0 Control
CPT0MD      DATA 09DH                  ; Comparator0 Mode Selection
CPT0MX      DATA 09FH                  ; Comparator0 MUX Selection
CRC0AUTO    DATA 0DDH                  ; 
CRC0CN      DATA 0DFH                  ; 
CRC0CNT     DATA 0DEH                  ; 
CRC0DAT     DATA 09EH                  ; 
CRC0FLIP    DATA 09AH                  ; 
CRC0IN      DATA 09CH                  ; 
DERIVID     DATA 0ABH                  ; Derivative ID
DPH         DATA 083H                  ; Data Pointer High
DPL         DATA 082H                  ; Data Pointer Low
EIE1        DATA 0E6H                  ; Extended Interrupt Enable 1
EIE2        DATA 0AFH                  ; Extended Interrupt Enable 2
EIP1        DATA 0F6H                  ; Extended Interrupt Priority 1
EIP1H       DATA 085H                  ; Extended Interrupt Priority High 1
EIP2        DATA 0BFH                  ; Extended Interrupt Priority 2
EIP2H       DATA 086H                  ; Extended Interrupt Priority High 2
EMI0CN      DATA 0AAH                  ; External Memory Interface Control
FLKEY       DATA 0B7H                  ; Flash Lock and Key 
FLSCL       DATA 0B6H                  ; Flash Scale
IDA0CN      DATA 0B9H                  ; IDAC0 Control
IDA0H       DATA 097H                  ; IDAC0 High Byte
IDA0L       DATA 096H                  ; IDAC0 Low Byte
IDA1CN      DATA 0B9H                  ; IDAC1 Control
IDA1H       DATA 097H                  ; IDAC1 High Byte
IDA1L       DATA 096H                  ; IDAC1 Low Byte
IE          DATA 0A8H                  ; Interrupt Enable
IP          DATA 0B8H                  ; Interrupt Priority
IPH         DATA 084H                  ; Interrupt Priority High
IT01CF      DATA 0E4H                  ; INT0/INT1 Configuration
OSCICL      DATA 0B3H                  ; Internal Oscillator Calibration
OSCICN      DATA 0B2H                  ; Internal Oscillator Control
OSCLCN      DATA 0E3H                  ; Internal Low-Frequency Osc Control
OSCXCN      DATA 0B1H                  ; External Oscillator Control
P0          DATA 080H                  ; Port 0 Latch
P0MASK      DATA 0FEH                  ; Port 0 Mask Register
P0MAT       DATA 0FDH                  ; Port 0 Match Register
P0MDIN      DATA 0F1H                  ; Port 0 Input Mode Configuration
P0MDOUT     DATA 0A4H                  ; Port 0 Output Mode Configuration
P0SKIP      DATA 0D4H                  ; Port 0 Skip
P1          DATA 090H                  ; Port 1 Latch
P1MASK      DATA 0EEH                  ; Port 1 Mask Register
P1MAT       DATA 0EDH                  ; Port 1 Match Register
P1MDIN      DATA 0F2H                  ; Port 1 Input Mode Configuration
P1MDOUT     DATA 0A5H                  ; Port 1 Output Mode Configuration
P1SKIP      DATA 0D5H                  ; Port 1 Skip
P2          DATA 0A0H                  ; Port 2 Latch
P2MDIN      DATA 0F3H                  ; Port 2 Input Mode Configuration
P2MDOUT     DATA 0A6H                  ; Port 2 Output Mode Configuration
P2SKIP      DATA 0D6H                  ; Port 2 Skip 
PCA0CLR     DATA 0CEH                  ; PCA Comparator Clear Control
PCA0CN      DATA 0D8H                  ; PCA Control
PCA0CPH0    DATA 0FCH                  ; PCA Capture 0 High
PCA0CPH1    DATA 0EAH                  ; PCA Capture 1 High
PCA0CPH2    DATA 0ECH                  ; PCA Capture 2 High
PCA0CPL0    DATA 0FBH                  ; PCA Capture 0 Low
PCA0CPL1    DATA 0E9H                  ; PCA Capture 1 Low
PCA0CPL2    DATA 0EBH                  ; PCA Capture 2 Low
PCA0CPM0    DATA 0DAH                  ; PCA Module 0 Mode Register
PCA0CPM1    DATA 0DBH                  ; PCA Module 1 Mode Register
PCA0CPM2    DATA 0DCH                  ; PCA Module 2 Mode Register
PCA0H       DATA 0FAH                  ; PCA Counter High
PCA0L       DATA 0F9H                  ; PCA Counter Low
PCA0MD      DATA 0D9H                  ; PCA Mode 
PCA0PWM     DATA 0F7H                  ; PCA0 PWM Control
PCON        DATA 087H                  ; Power Control
PFE0CN      DATA 0B5H                  ; Prefetch Engine Control
PSCTL       DATA 08FH                  ; Program Store R/W Control
PSW         DATA 0D0H                  ; Program Status Word
REF0CN      DATA 0D1H                  ; Voltage Reference Control
REG0CN      DATA 0C9H                  ; Voltage Regulator Control
REVISION    DATA 0ACH                  ; Revision
RSTSRC      DATA 0EFH                  ; Reset Source Configuration/Status
SBUF0       DATA 099H                  ; UART0 Data Buffer
SCON0       DATA 098H                  ; UART0 Control
SFRPAGE     DATA 0A7H                  ; SFR Page Select
SFRPGCN     DATA 0CFH                  ; SFR Page Control
SFRSTACK    DATA 0D3H                  ; SFR Page Stack
SMB0ADM     DATA 0E7H                  ; SMBus0 Slave Address Mask
SMB0ADR     DATA 0D7H                  ; SMBus0 Slave Address   
SMB0CF      DATA 0C1H                  ; SMBus0 Configuration
SMB0CN      DATA 0C0H                  ; SMBus0 Control
SMB0DAT     DATA 0C2H                  ; SMBus0 Data
SMB1ADM     DATA 0E7H                  ; SMBus1 Slave Address Mask
SMB1ADR     DATA 0D7H                  ; SMBus1 Slave Address   
SMB1CF      DATA 0C1H                  ; SMBus1 Configuration
SMB1CN      DATA 0C0H                  ; SMBus1 Control
SMB1DAT     DATA 0C2H                  ; SMBus1 Data
SMBTC       DATA 0C7H                  ; SMBus Timing Control
SN0         DATA 0ABH                  ; Serial Number 0
SN1         DATA 0ACH                  ; Serial Number 1
SN2         DATA 0ADH                  ; Serial Number 2
SN3         DATA 0AEH                  ; Serial Number 3
SP          DATA 081H                  ; Stack Pointer
SPI0CFG     DATA 0A1H                  ; SPI Configuration
SPI0CKR     DATA 0A2H                  ; SPI Clock Rate Control
SPI0CN      DATA 0F8H                  ; SPI Control
SPI0DAT     DATA 0A3H                  ; SPI Data
TCON        DATA 088H                  ; Timer/Counter Control
TH0         DATA 08CH                  ; Timer/Counter 0 High
TH1         DATA 08DH                  ; Timer/Counter 1 High
TL0         DATA 08AH                  ; Timer/Counter 0 Low
TL1         DATA 08BH                  ; Timer/Counter 1 Low
TMOD        DATA 089H                  ; Timer/Counter Mode
TMR2CN      DATA 0C8H                  ; Timer/Counter 2 Control
TMR2H       DATA 0CDH                  ; Timer/Counter 2 High
TMR2L       DATA 0CCH                  ; Timer/Counter 2 Low
TMR2RLH     DATA 0CBH                  ; Timer/Counter 2 Reload High
TMR2RLL     DATA 0CAH                  ; Timer/Counter 2 Reload Low
TMR3CN      DATA 091H                  ; Timer/Counter 3 Control
TMR3H       DATA 095H                  ; Timer/Counter 3 High
TMR3L       DATA 094H                  ; Timer/Counter 3 Low
TMR3RLH     DATA 093H                  ; Timer/Counter 3 Reload High
TMR3RLL     DATA 092H                  ; Timer/Counter 3 Reload Low
TMR4CN      DATA 091H                  ; Timer/Counter 4 Control
TMR4H       DATA 095H                  ; Timer/Counter 4 High
TMR4L       DATA 094H                  ; Timer/Counter 4 Low
TMR4RLH     DATA 093H                  ; Timer/Counter 4 Reload High
TMR4RLL     DATA 092H                  ; Timer/Counter 4 Reload Low
TMR5CN      DATA 0C8H                  ; Timer/Counter 5 Control
TMR5H       DATA 0CDH                  ; Timer/Counter 5 High
TMR5L       DATA 0CCH                  ; Timer/Counter 5 Low
TMR5RLH     DATA 0CBH                  ; Timer/Counter 5 Reload High
TMR5RLL     DATA 0CAH                  ; Timer/Counter 5 Reload Low
TS0CN       DATA 0D2H                  ; Temperature Sensor Control
TS0DATL     DATA 0D2H                  ; Temperature Sensor Data Low
TS0DATH     DATA 0D3H                  ; Temperature Sensor Data High
VDM0CN      DATA 0FFH                  ; VDD Monitor Control
XBR0        DATA 0E1H                  ; Port I/O Crossbar Control 0
XBR1        DATA 0E2H                  ; Port I/O Crossbar Control 1

; -----------------------------------------------------------------------------
;  Bit Definitions
; -----------------------------------------------------------------------------

; TCON 088H
TF1         BIT 08FH                   ; Timer 1 Overflow Flag
TR1         BIT 08EH                   ; Timer 1 On/Off Control
TF0         BIT 08DH                   ; Timer 0 Overflow Flag
TR0         BIT 08CH                   ; Timer 0 On/Off Control
IE1         BIT 08BH                   ; Ext. Interrupt 1 Edge Flag
IT1         BIT 08AH                   ; Ext. Interrupt 1 Type
IE0         BIT 089H                   ; Ext. Interrupt 0 Edge Flag
IT0         BIT 088H                   ; Ext. Interrupt 0 Type

; SCON0 098H
S0MODE      BIT 09FH                   ; UART0 Mode
                                       ; Bit6 UNUSED
MCE0        BIT 09DH                   ; UART0 MCE
REN0        BIT 09CH                   ; UART0 RX Enable
TB80        BIT 09BH                   ; UART0 TX Bit 8
RB80        BIT 09AH                   ; UART0 RX Bit 8
TI0         BIT 099H                   ; UART0 TX Interrupt Flag
RI0         BIT 098H                   ; UART0 RX Interrupt Flag

; IE 0A8H
EA          BIT 0AFH                   ; Global Interrupt Enable
ESPI0       BIT 0AEH                   ; SPI0 Interrupt Enable
ET2         BIT 0ADH                   ; Timer 2 Interrupt Enable
ES0         BIT 0ACH                   ; UART0 Interrupt Enable
ET1         BIT 0ABH                   ; Timer 1 Interrupt Enable
EX1         BIT 0AAH                   ; External Interrupt 1 Enable
ET0         BIT 0A9H                   ; Timer 0 Interrupt Enable
EX0         BIT 0A8H                   ; External Interrupt 0 Enable

; IP 0B8H
                                       ; Bit7 UNUSED
PSPI0       BIT 0BEH                   ; SPI0 Priority
PT2         BIT 0BDH                   ; Timer 2 Priority
PS0         BIT 0BCH                   ; UART0 Priority
PT1         BIT 0BBH                   ; Timer 1 Priority
PX1         BIT 0BAH                   ; External Interrupt 1 Priority
PT0         BIT 0B9H                   ; Timer 0 Priority
PX0         BIT 0B8H                   ; External Interrupt 0 Priority

; SMB0CN 0C0H
MASTER0     BIT 0C7H                   ; SMBus0 Master/Slave
TXMODE0     BIT 0C6H                   ; SMBus0 Transmit Mode
STA0        BIT 0C5H                   ; SMBus0 Start Flag
STO0        BIT 0C4H                   ; SMBus0 Stop Flag
ACKRQ0      BIT 0C3H                   ; SMBus0 Acknowledge Request
ARBLOST0    BIT 0C2H                   ; SMBus0 Arbitration Lost
ACK0        BIT 0C1H                   ; SMBus0 Acknowledge Flag
SI0         BIT 0C0H                   ; SMBus0 Interrupt Pending Flag

; SMB1CN 0C0H
MASTER1     BIT 0C7H                   ; SMBus1 Master/Slave
TXMODE1     BIT 0C6H                   ; SMBus1 Transmit Mode
STA1        BIT 0C5H                   ; SMBus1 Start Flag
STO1        BIT 0C4H                   ; SMBus1 Stop Flag
ACKRQ1      BIT 0C3H                   ; SMBus1 Acknowledge Request
ARBLOST1    BIT 0C2H                   ; SMBus1 Arbitration Lost
ACK1        BIT 0C1H                   ; SMBus1 Acknowledge Flag
SI1         BIT 0C0H                   ; SMBus1 Interrupt Pending Flag


; TMR2CN 0C8H
TF2H        BIT 0CFH                   ; Timer 2 High Byte Overflow Flag
TF2L        BIT 0CEH                   ; Timer 2 Low Byte Overflow Flag
TF2LEN      BIT 0CDH                   ; Timer 2 Low Byte Interrupt Enable
TF2CEN      BIT 0CCH                   ; Timer 2 Lfo Capture Enable
T2SPLIT     BIT 0CBH                   ; Timer 2 Split Mode Enable
TR2         BIT 0CAH                   ; Timer 2 On/Off Control
                                       ; Bit6 UNUSED
T2XCLK      BIT 0C8H                   ; Timer 2 External Clock Select

; TMR5CN 0C8H
TF5H        BIT 0CFH                   ; Timer 5 High Byte Overflow Flag
TF5L        BIT 0CEH                   ; Timer 5 Low Byte Overflow Flag
TF5LEN      BIT 0CDH                   ; Timer 5 Low Byte Interrupt Enable
                                       ; Bit4 UNUSED
T5SPLIT     BIT 0CBH                   ; Timer 5 Split Mode Enable
TR5         BIT 0CAH                   ; Timer 5 On/Off Control
                                       ; Bit1 UNUSED
T5XCLK      BIT 0C8H                   ; Timer 5 External Clock Select

; PSW 0D0H
CY          BIT 0D7H                   ; Carry Flag
AC          BIT 0D6H                   ; Auxiliary Carry Flag
F0          BIT 0D5H                   ; User Flag 0
RS1         BIT 0D4H                   ; Register Bank Select 1
RS0         BIT 0D3H                   ; Register Bank Select 0
OV          BIT 0D2H                   ; Overflow Flag
F1          BIT 0D1H                   ; User Flag 1
P           BIT 0D0H                   ; Accumulator Parity Flag

; PCA0CN 0D8H
CF          BIT 0DFH                   ; PCA0 Counter Overflow Flag
CR          BIT 0DEH                   ; PCA0 Counter Run Control Bit
                                       ; Bit5 UNUSED
                                       ; Bit4 UNUSED
                                       ; Bit3 UNUSED
CCF2        BIT 0DAH                   ; PCA0 Module 2 Interrupt Flag
CCF1        BIT 0D9H                   ; PCA0 Module 1 Interrupt Flag
CCF0        BIT 0D8H                   ; PCA0 Module 0 Interrupt Flag

; ADC0CN 0E8H
AD0EN       BIT 0EFH                   ; ADC0 Enable
AD0TM       BIT 0EEH                   ; ADC0 Track Mode
AD0INT      BIT 0EDH                   ; ADC0 EOC Interrupt Flag
AD0BUSY     BIT 0ECH                   ; ADC0 Busy Flag
AD0WINT     BIT 0EBH                   ; ADC0 Window Interrupt Flag
AD0CM2      BIT 0EAH                   ; ADC0 Convert Start Mode Bit 2
AD0CM1      BIT 0E9H                   ; ADC0 Convert Start Mode Bit 1
AD0CM0      BIT 0E8H                   ; ADC0 Convert Start Mode Bit 0

; SPI0CN 0F8H
SPIF        BIT 0FFH                   ; SPI0 Interrupt Flag
WCOL        BIT 0FEH                   ; SPI0 Write Collision Flag
MODF        BIT 0FDH                   ; SPI0 Mode Fault Flag
RXOVRN      BIT 0FCH                   ; SPI0 RX Overrun Flag
NSSMD1      BIT 0FBH                   ; SPI0 Slave Select Mode 1
NSSMD0      BIT 0FAH                   ; SPI0 Slave Select Mode 0
TXBMT       BIT 0F9H                   ; SPI0 TX Buffer Empty Flag
SPIEN       BIT 0F8H                   ; SPI0 SPI0 Enable

; -----------------------------------------------------------------------------
;  End Of File
; -----------------------------------------------------------------------------