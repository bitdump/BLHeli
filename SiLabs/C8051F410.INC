;------------------------------------------------------------------------------
; C8051F410.INC
;------------------------------------------------------------------------------
; Copyright 2005 Silicon Laboratories, Inc.
; http://www.silabs.com
;
; Program Description:
;
; Register/bit definitions for the C8051F41x family.
;
;
; FID:            41X000004
; Target:         C8051F410, F411, F412, F413
; Tool chain:     Keil
; Command Line:   None
;
;
; Release 1.0
;    -Initial Revision (GP, PKC)
;    -26 JAN 2006
;

;------------------------------------------------------------------------------
; Byte Registers
;------------------------------------------------------------------------------

P0          DATA     080H              ; Port 0 latch
SP          DATA     081H              ; Stack pointer
DPL         DATA     082H              ; Data pointer low
DPH         DATA     083H              ; Data pointer high
CRC0CN      DATA     084H              ; CRC0 control
CRC0IN      DATA     085H              ; CRC0 input data
CRC0DAT     DATA     086H              ; CRC0 output data
PCON        DATA     087H              ; Power control
TCON        DATA     088H              ; Timer/counter control
TMOD        DATA     089H              ; Timer/counter mode
TL0         DATA     08AH              ; Timer/counter 0 low
TL1         DATA     08BH              ; Timer/counter 1 low
TH0         DATA     08CH              ; Timer/counter 0 high
TH1         DATA     08DH              ; Timer/counter 1 high
CKCON       DATA     08EH              ; Clock control
PSCTL       DATA     08FH              ; Program store R/W control
P1          DATA     090H              ; Port 1 latch
TMR3CN      DATA     091H              ; Timer/counter 3 control
TMR3RLL     DATA     092H              ; Timer/counter 3 reload low
TMR3RLH     DATA     093H              ; Timer/counter 3 reload high
TMR3L       DATA     094H              ; Timer/counter 3 low
TMR3H       DATA     095H              ; Timer/counter 3 high
IDA0L       DATA     096H              ; Current mode DAC0 low
IDA0H       DATA     097H              ; Current mode DAC0 high
SCON0       DATA     098H              ; UART0 control
SBUF0       DATA     099H              ; UART0 data buffer
CPT1CN      DATA     09AH              ; Comparator1 control
CPT0CN      DATA     09BH              ; Comparator0 control
CPT1MD      DATA     09CH              ; Comparator1 mode selection
CPT0MD      DATA     09DH              ; Comparator0 mode selection
CPT1MX      DATA     09EH              ; Comparator1 mux selection
CPT0MX      DATA     09FH              ; Comparator0 mux selection
P2          DATA     0A0H              ; Port 2 latch
SPI0CFG     DATA     0A1H              ; SPI0 configuration
SPI0CKR     DATA     0A2H              ; SPI0 clock rate control
SPI0DAT     DATA     0A3H              ; SPI0 data
P0MDOUT     DATA     0A4H              ; Port 0 output mode configuration
P1MDOUT     DATA     0A5H              ; Port 1 output mode configuration
P2MDOUT     DATA     0A6H              ; Port 2 output mode configuration
IE          DATA     0A8H              ; Interrupt enable
CLKSEL      DATA     0A9H              ; Clock select
EMI0CN      DATA     0AAH              ; External memory interface control
CLKMUL      DATA     0ABH              ; Clock multiplier
RTC0ADR     DATA     0ACH              ; RTC0 address
RTC0DAT     DATA     0ADH              ; RTC0 data
RTC0KEY     DATA     0AEH              ; RTC0 lock and key
ONESHOT     DATA     0AFH              ; Flash oneshot timing
P0ODEN      DATA     0B0H              ; Port0 Hi-Z overdrive mode enable
OSCXCN      DATA     0B1H              ; External oscillator control
OSCICN      DATA     0B2H              ; Internal oscillator control
OSCICL      DATA     0B3H              ; Internal oscillator calibration
IDA1CN      DATA     0B5H              ; Current mode DAC1 control
FLSCL       DATA     0B6H              ; Flash scale
FLKEY       DATA     0B7H              ; Flash lock and key
IP          DATA     0B8H              ; Interrupt priority
IDA0CN      DATA     0B9H              ; Current mode DAC0 control
ADC0TK      DATA     0BAH              ; ADC0 tracking
ADC0MX      DATA     0BBH              ; ADC0 mux
ADC0CF      DATA     0BCH              ; ADC0 configuration
ADC0L       DATA     0BDH              ; ADC0 data low
ADC0H       DATA     0BEH              ; ADC0 data high
P1MASK      DATA     0BFH              ; Port1 mask
SMB0CN      DATA     0C0H              ; SMBus0 control
SMB0CF      DATA     0C1H              ; SMBus0 configuration
SMB0DAT     DATA     0C2H              ; SMBus0 data
ADC0GTL     DATA     0C3H              ; ADC0 window greater than low byte
ADC0GTH     DATA     0C4H              ; ADC0 window greater than high byte
ADC0LTL     DATA     0C5H              ; ADC0 window less than low byte
ADC0LTH     DATA     0C6H              ; ADC0 window less than high byte
P0MASK      DATA     0C7H              ; Port0 mask
TMR2CN      DATA     0C8H              ; Timer/counter 2 control
REG0CN      DATA     0C9H              ; Voltage regulator control
TMR2RLL     DATA     0CAH              ; Timer/counter 2 reload low
TMR2RLH     DATA     0CBH              ; Timer/counter 2 reload high
TMR2L       DATA     0CCH              ; Timer/counter 2 low
TMR2H       DATA     0CDH              ; Timer/counter 2 high
PCA0CPM5    DATA     0CEH              ; PCA0 module 5 mode
P1MAT       DATA     0CFH              ; Port1 match
PSW         DATA     0D0H              ; Program status word
REF0CN      DATA     0D1H              ; Voltage reference control
PCA0CPL5    DATA     0D2H              ; PCA0 module 5 low
PCA0CPH5    DATA     0D3H              ; PCA0 module 5 high
P0SKIP      DATA     0D4H              ; Port 0 skip
P1SKIP      DATA     0D5H              ; Port 1 skip
P2SKIP      DATA     0D6H              ; Port 2 skip
P0MAT       DATA     0D7H              ; Port 0 match
PCA0CN      DATA     0D8H              ; PCA0 control
PCA0MD      DATA     0D9H              ; PCA0 mode
PCA0CPM0    DATA     0DAH              ; PCA0 module 0 mode
PCA0CPM1    DATA     0DBH              ; PCA0 module 1 mode
PCA0CPM2    DATA     0DCH              ; PCA0 module 2 mode
PCA0CPM3    DATA     0DDH              ; PCA0 module 3 mode
PCA0CPM4    DATA     0DEH              ; PCA0 module 4 mode
CRC0FLIP    DATA     0DFH              ; CRC0 bit flip
ACC         DATA     0E0H              ; Accumulator
XBR0        DATA     0E1H              ; Port I/O crossbar control 0
XBR1        DATA     0E2H              ; Port I/O crossbar control 1
PFE0CN      DATA     0E3H              ; Prefetch engine control
IT01CF      DATA     0E4H              ; INT0/INT1 configuration
EIE1        DATA     0E6H              ; Extended interrupt enable 1
EIE2        DATA     0E7H              ; Extended interrupt enable 2
ADC0CN      DATA     0E8H              ; ADC0 control
PCA0CPL1    DATA     0E9H              ; PCA0 module 1 capture low
PCA0CPH1    DATA     0EAH              ; PCA0 module 1 capture high
PCA0CPL2    DATA     0EBH              ; PCA0 module 2 capture low
PCA0CPH2    DATA     0ECH              ; PCA0 module 2 capture high
PCA0CPL3    DATA     0EDH              ; PCA0 module 3 capture low
PCA0CPH3    DATA     0EEH              ; PCA0 module 3 capture high
RSTSRC      DATA     0EFH              ; Reset source configuration/status
B           DATA     0F0H              ; B register
P0MDIN      DATA     0F1H              ; Port 0 input mode configuration
P1MDIN      DATA     0F2H              ; Port 1 input mode configuration
P2MDIN      DATA     0F3H              ; Port 2 input mode configuration
IDA1L       DATA     0F4H              ; Current mode DAC1 data low
IDA1H       DATA     0F5H              ; Current mode DAC1 data high
EIP1        DATA     0F6H              ; Extended interrupt priority 1
EIP2        DATA     0F7H              ; Extended interrupt priority 2
SPI0CN      DATA     0F8H              ; SPI0 control
PCA0L       DATA     0F9H              ; PCA0 counter low
PCA0H       DATA     0FAH              ; PCA0 counter high
PCA0CPL0    DATA     0FBH              ; PCA0 module 0 capture low
PCA0CPH0    DATA     0FCH              ; PCA0 module 0 capture high
PCA0CPL4    DATA     0FDH              ; PCA0 module 4 capture low
PCA0CPH4    DATA     0FEH              ; PCA0 module 4 capture high
VDM0CN      DATA     0FFH              ; VDD monitor control

;------------------------------------------------------------------------------
; Bit Definitions
;------------------------------------------------------------------------------

; TCON 0x88
TF1     BIT     TCON.7                 ; Timer 1 overflow flag
TR1     BIT     TCON.6                 ; Timer 1 on/off control
TF0     BIT     TCON.5                 ; Timer 0 overflow flag
TR0     BIT     TCON.4                 ; Timer 0 on/off control
IE1     BIT     TCON.3                 ; Ext. Interrupt 1 edge flag
IT1     BIT     TCON.2                 ; Ext. Interrupt 1 type
IE0     BIT     TCON.1                 ; Ext. Interrupt 0 edge flag
IT0     BIT     TCON.0                 ; Ext. Interrupt 0 type

; SCON0 0x98
S0MODE BIT     SCON0.7                 ; UART0 mode
                                       ; Bit 6 Unused
MCE0    BIT    SCON0.5                 ; UART0 MCE
REN0    BIT    SCON0.4                 ; UART0 RX enable
TB80    BIT    SCON0.3                 ; UART0 TX bit 8
RB80    BIT    SCON0.2                 ; UART0 RX bit 8
TI0     BIT    SCON0.1                 ; UART0 TX interrupt flag
RI0     BIT    SCON0.0                 ; UART0 RX interrupt flag

; IE 0xA8
EA      BIT    IE.7                    ; Global interrupt enable
ESPI0   BIT    IE.6                    ; SPI0 interrupt enable
ET2     BIT    IE.5                    ; Timer 2 interrupt enable
ES0     BIT    IE.4                    ; UART0 interrupt enable
ET1     BIT    IE.3                    ; Timer 1 interrupt enable
EX1     BIT    IE.2                    ; External interrupt 1 enable
ET0     BIT    IE.1                    ; Timer 0 interrupt enable
EX0     BIT    IE.0                    ; External interrupt 0 enable

; IP 0xB8
                                       ; Bit 7 Unused
PSPI0   BIT    IP.6                    ; SPI0 priority
PT2     BIT    IP.5                    ; Timer 2 priority
PS0     BIT    IP.4                    ; UART0 priority
PT1     BIT    IP.3                    ; Timer 1 priority
PX1     BIT    IP.2                    ; External interrupt 1 priority
PT0     BIT    IP.1                    ; Timer 0 priority
PX0     BIT    IP.0                    ; External interrupt 0 priority

; SMB0CN 0xC0
MASTER  BIT    SMB0CN.7                ; SMBus0 master/slave
TXMODE  BIT    SMB0CN.6                ; SMBus0 transmit mode
STA     BIT    SMB0CN.5                ; SMBus0 start flag
STO     BIT    SMB0CN.4                ; SMBus0 stop flag
ACKRQ   BIT    SMB0CN.3                ; SMBus0 acknowledge request
ARBLOST BIT    SMB0CN.2                ; SMBus0 arbitration lost
ACK     BIT    SMB0CN.1                ; SMBus0 acknowledge flag
SI      BIT    SMB0CN.0                ; SMBus0 interrupt pending flag

; TMR2CN 0xC8
TF2H    BIT    TMR2CN.7                ; Timer 2 high byte overflow flag
TF2L    BIT    TMR2CN.6                ; Timer 2 low byte overflow flag
TF2LEN  BIT    TMR2CN.5                ; Timer 2 low byte interrupt enable
TF2CEN  BIT    TMR2CN.4                ; Timer 2 capture enable
T2SPLIT BIT    TMR2CN.3                ; Timer 2 split mode enable
TR2     BIT    TMR2CN.2                ; Timer 2 on/off control
T2RCLK  BIT    TMR2CN.1                ; Timer 2 RTC capture mode select
T2XCLK  BIT    TMR2CN.0                ; Timer 2 external clock select

; PSW 0xD0
CY      BIT    PSW.7                   ; Carry flag
AC      BIT    PSW.6                   ; Auxiliary carry flag
F0      BIT    PSW.5                   ; User flag 0
RS1     BIT    PSW.4                   ; Register bank select 1
RS0     BIT    PSW.3                   ; Register bank select 0
OV      BIT    PSW.2                   ; Overflow flag
F1      BIT    PSW.1                   ; User flag 1
P       BIT    PSW.0                   ; Accumulator parity flag

; PCA0CN 0xD8
CF      BIT    PCA0CN.7                ; PCA0 counter overflow flag
CR      BIT    PCA0CN.6                ; PCA0 counter run control bit
CCF5    BIT    PCA0CN.5                ; PCA0 module 5 interrupt flag
CCF4    BIT    PCA0CN.4                ; PCA0 module 4 interrupt flag
CCF3    BIT    PCA0CN.3                ; PCA0 module 3 interrupt flag
CCF2    BIT    PCA0CN.2                ; PCA0 module 2 interrupt flag
CCF1    BIT    PCA0CN.1                ; PCA0 module 1 interrupt flag
CCF0    BIT    PCA0CN.0                ; PCA0 module 0 interrupt flag

; ADC0CN 0xE8
AD0EN   BIT    ADC0CN.7                ; ADC0 enable
BURSTEN BIT    ADC0CN.6                ; ADC0 burst mode enable
AD0INT  BIT    ADC0CN.5                ; ADC0 conv. complete interrupt flag
AD0BUSY BIT    ADC0CN.4                ; ADC0 busy flag
AD0WINT BIT    ADC0CN.3                ; ADC0 window compare interrupt flag
AD0LJST BIT    ADC0CN.2                ; ADC0 left justify select
AD0CM1  BIT    ADC0CN.1                ; ADC0 conversion mode select 1
AD0CM0  BIT    ADC0CN.0                ; ADC0 conversion mode select 0

; SPI0CN 0xF8
SPIF    BIT    SPI0CN.7                ; SPI0 interrupt flag
WCOL    BIT    SPI0CN.6                ; SPI0 write collision flag
MODF    BIT    SPI0CN.5                ; SPI0 mode fault flag
RXOVRN  BIT    SPI0CN.4                ; SPI0 RX overrun flag
NSSMD1  BIT    SPI0CN.3                ; SPI0 slave select mode 1
NSSMD0  BIT    SPI0CN.2                ; SPI0 slave select mode 0
TXBMT   BIT    SPI0CN.1                ; SPI0 TX buffer empty flag
SPIEN   BIT    SPI0CN.0                ; SPI0 SPI0 enable


;------------------------------------------------------------------------------
; End Of File
;------------------------------------------------------------------------------