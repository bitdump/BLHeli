; PAGE DEFINITIONS
ACTIVE_PAGE          EQU 000H
DEBUG_PAGE           EQU 001H

; SFR ADDRESSES BEGIN
ADC0AC               DATA 0B3H ; ACTIVE
ADC0CF               DATA 0BCH ; ACTIVE
ADC0CN0              DATA 0E8H ; ACTIVE
ADC0CN1              DATA 0B2H ; ACTIVE
ADC0GTH              DATA 0C4H ; ACTIVE
ADC0GTL              DATA 0C3H ; ACTIVE
ADC0H                DATA 0BEH ; ACTIVE
ADC0L                DATA 0BDH ; ACTIVE
ADC0LTH              DATA 0C6H ; ACTIVE
ADC0LTL              DATA 0C5H ; ACTIVE
ADC0MX               DATA 0BBH ; ACTIVE
ADC0PWR              DATA 0DFH ; ACTIVE
ADC0TK               DATA 0B9H ; ACTIVE
ACC                  DATA 0E0H ;
B                    DATA 0F0H ;
DPH                  DATA 083H ;
DPL                  DATA 082H ;
PCON                 DATA 087H ;
PSW                  DATA 0D0H ;
SP                   DATA 081H ;
CRC0AUTO             DATA 0D2H ; ACTIVE
CRC0CN               DATA 0CEH ; ACTIVE
CRC0CNT              DATA 0D3H ; ACTIVE
CRC0DAT              DATA 0DEH ; ACTIVE
CRC0FLIP             DATA 0CFH ; ACTIVE
CRC0IN               DATA 0DDH ; ACTIVE
CPT0CN               DATA 09BH ; ACTIVE
CPT0MD               DATA 09DH ; ACTIVE
CPT0MX               DATA 09FH ; ACTIVE
CPT1CN               DATA 0BFH ; ACTIVE
CPT1MD               DATA 0ABH ; ACTIVE
CPT1MX               DATA 0AAH ; ACTIVE
DERIVID              DATA 0ADH ; ACTIVE
DEVICEID             DATA 0B5H ; ACTIVE
FLSCL                DATA 09AH ; ACTIVE
REVID                DATA 0B6H ; ACTIVE
FLKEY                DATA 0B7H ;
PSCTL                DATA 08FH ;
EIE1                 DATA 0E6H ;
EIP1                 DATA 0F3H ; ACTIVE
IE                   DATA 0A8H ;
IP                   DATA 0B8H ;
IT01CF               DATA 0E4H ; ACTIVE
CKCON                DATA 08EH ; ACTIVE
CLKSEL               DATA 0A9H ;
OSCLCN               DATA 0B1H ; ACTIVE
OSCICL               DATA 0C7H ; ACTIVE
PCA0CENT             DATA 09EH ; ACTIVE
PCA0CLR              DATA 09CH ; ACTIVE
PCA0CN               DATA 0D8H ; ACTIVE
PCA0CPH0             DATA 0FCH ; ACTIVE
PCA0CPH1             DATA 0EAH ; ACTIVE
PCA0CPH2             DATA 0ECH ; ACTIVE
PCA0CPL0             DATA 0FBH ; ACTIVE
PCA0CPL1             DATA 0E9H ; ACTIVE
PCA0CPL2             DATA 0EBH ; ACTIVE
PCA0CPM0             DATA 0DAH ; ACTIVE
PCA0CPM1             DATA 0DBH ; ACTIVE
PCA0CPM2             DATA 0DCH ; ACTIVE
PCA0H                DATA 0FAH ; ACTIVE
PCA0L                DATA 0F9H ; ACTIVE
PCA0MD               DATA 0D9H ; ACTIVE
PCA0POL              DATA 096H ; ACTIVE
PCA0PWM              DATA 0F7H ; ACTIVE
P0                   DATA 080H ;
P0MASK               DATA 0FEH ; ACTIVE
P0MAT                DATA 0FDH ; ACTIVE
P0MDIN               DATA 0F1H ; ACTIVE
P0MDOUT              DATA 0A4H ; ACTIVE
P0SKIP               DATA 0D4H ; ACTIVE
P1                   DATA 090H ; ACTIVE
P1MASK               DATA 0EEH ; ACTIVE
P1MAT                DATA 0EDH ; ACTIVE
P1MDIN               DATA 0F2H ; ACTIVE
P1MDOUT              DATA 0A5H ; ACTIVE
P1SKIP               DATA 0D5H ; ACTIVE
P2                   DATA 0A0H ;
P2MDOUT              DATA 0A6H ; ACTIVE
PRTDRV               DATA 0F6H ; ACTIVE
XBR0                 DATA 0E1H ; ACTIVE
XBR1                 DATA 0E2H ; ACTIVE
XBR2                 DATA 0E3H ; ACTIVE
RSTSRC               DATA 0EFH ; ACTIVE
SMB0ADM              DATA 0D6H ; ACTIVE
SMB0ADR              DATA 0D7H ; ACTIVE
SMB0CF               DATA 0C1H ; ACTIVE
SMB0CN               DATA 0C0H ; ACTIVE
SMB0DAT              DATA 0C2H ; ACTIVE
SMB0TC               DATA 0ACH ; ACTIVE
SPI0CFG              DATA 0A1H ; ACTIVE
SPI0CKR              DATA 0A2H ; ACTIVE
SPI0CN               DATA 0F8H ; ACTIVE
SPI0DAT              DATA 0A3H ; ACTIVE
TCON                 DATA 088H ; ACTIVE
TH0                  DATA 08CH ; ACTIVE
TH1                  DATA 08DH ; ACTIVE
TL0                  DATA 08AH ; ACTIVE
TL1                  DATA 08BH ; ACTIVE
TMOD                 DATA 089H ; ACTIVE
TMR2CN               DATA 0C8H ;
TMR2H                DATA 0CDH ; ACTIVE
TMR2L                DATA 0CCH ; ACTIVE
TMR2RLH              DATA 0CBH ; ACTIVE
TMR2RLL              DATA 0CAH ; ACTIVE
TMR3CN               DATA 091H ; ACTIVE
TMR3H                DATA 095H ; ACTIVE
TMR3L                DATA 094H ; ACTIVE
TMR3RLH              DATA 093H ; ACTIVE
TMR3RLL              DATA 092H ; ACTIVE
SBUF0                DATA 099H ; ACTIVE
SCON0                DATA 098H ;
REF0CN               DATA 0D1H ; ACTIVE
REG0CN               DATA 0C9H ; ACTIVE
VDM0CN               DATA 0FFH ; ACTIVE
WDTCN                DATA 097H ;
; SFR ADDRESSES END

; BIT DEFINITIONS

; ADC0CN0 0xE8
AD0EN                BIT  ADC0CN0.7   ;
BURSTEN              BIT  ADC0CN0.6   ;
AD0INT               BIT  ADC0CN0.5   ;
AD0BUSY              BIT  ADC0CN0.4   ;
AD0WINT              BIT  ADC0CN0.3   ;
ADC0M2               BIT  ADC0CN0.2   ;
ADC0M1               BIT  ADC0CN0.1   ;
ADC0M0               BIT  ADC0CN0.0   ;

; IE 0xA8
EA                   BIT  IE.7        ; Global Interrupt Enable
ESPI0                BIT  IE.6        ; Serial Peripheral Interface Enable
ET2                  BIT  IE.5        ; Timer 2 Interrupt Enable
ES0                  BIT  IE.4        ; Serial Port Interrupt Enable
ET1                  BIT  IE.3        ; Timer 1 Interrupt Enable
EX1                  BIT  IE.2        ; External Interrupt Enable
ET0                  BIT  IE.1        ; Timer 0 Interrupt Enable
EX0                  BIT  IE.0        ; External Interrupt 0 Enable

; IP 0xB8
                                      ; bit 7 UNUSED
PSPI0                BIT  IP.6        ; Serial Peripheral Interface Priority
PT2                  BIT  IP.5        ; Timer 2 Priority
PS0                  BIT  IP.4        ; Serial Port Priority
PT1                  BIT  IP.3        ; Timer 1 Priority
PX1                  BIT  IP.2        ; External Interrupt 1 Priority
PT0                  BIT  IP.1        ; Timer 0 Priority
PX0                  BIT  IP.0        ; External Interrupt 0 Priority

; PCA0CN 0xD8
CF                   BIT  PCA0CN.7    ; PCA 0 Counter Overflow Flag
CR                   BIT  PCA0CN.6    ; PCA 0 Counter Run Control Bit
                                      ; bit 5 UNUSED
                                      ; bit 4 UNUSED
                                      ; bit 3 UNUSED
CCF2                 BIT  PCA0CN.2    ; PCA 0 Module 2 Interrupt Flag
CCF1                 BIT  PCA0CN.1    ; PCA 0 Module 1 Interrupt Flag
CCF0                 BIT  PCA0CN.0    ; PCA 0 Module 0 Interrupt Flag

; PSW 0xD0
CY                   BIT  PSW.7       ; Carry Flag
AC                   BIT  PSW.6       ; Auxiliary Carry Flag
F0                   BIT  PSW.5       ; User Flag 0
RS1                  BIT  PSW.4       ; Register Bank Select 1
RS0                  BIT  PSW.3       ; Register Bank Select 0
OV                   BIT  PSW.2       ; Overflow Flag
F1                   BIT  PSW.1       ; User Flag 1
P                    BIT  PSW.0       ; Accumulator Parity Flag

; SCON0 0x98
S0MODE               BIT  SCON0.7     ; Serial Mode Control Bit 0
                                      ; bit 6 UNUSED
MCE0                 BIT  SCON0.5     ; Multiprocessor Communication Enable
REN0                 BIT  SCON0.4     ; Receive Enable
TB80                 BIT  SCON0.3     ; Transmit Bit 8
RB80                 BIT  SCON0.2     ; Receive Bit 8
TI0                  BIT  SCON0.1     ; Transmit Interrupt Flag
RI0                  BIT  SCON0.0     ; Receive Interrupt Flag

; SMB0CN 0xC0
MASTER0              BIT  SMB0CN.7    ; SMBus Master/Slave Indicator
TXMODE0              BIT  SMB0CN.6    ; SMBus Transmit Mode Indicator
STA0                 BIT  SMB0CN.5    ; SMBus Start Flag
STO0                 BIT  SMB0CN.4    ; SMBus Stop Flag
ACKRQ0               BIT  SMB0CN.3    ; SMBus Acknowledge Request
ARBLOST0             BIT  SMB0CN.2    ; SMBus Arbitration Lost Indicator
ACK0                 BIT  SMB0CN.1    ; SMBus Acknowledge
SI0                  BIT  SMB0CN.0    ; SMBus Interrupt

; SPI0CN 0xF8
SPIF                 BIT  SPI0CN.7    ; SPI 0 Interrupt Flag
WCOL                 BIT  SPI0CN.6    ; SPI 0 Write Collision Flag
MODF                 BIT  SPI0CN.5    ; SPI 0 Mode Fault Flag
RXOVRN               BIT  SPI0CN.4    ; SPI 0 RX Overrun Flag
NSSMD1               BIT  SPI0CN.3    ; SPI 0 NSS Mode Bit 1
NSSMD0               BIT  SPI0CN.2    ; SPI 0 NSS Mode Bit 0
TXBMT                BIT  SPI0CN.1    ; SPI 0 Transmit Buffer Empty Flag
SPIEN                BIT  SPI0CN.0    ; SPI 0 SPI Enable

; TCON 0x88
TF1                  BIT  TCON.7      ; Timer 1 Overflow Flag
TR1                  BIT  TCON.6      ; Timer 1 On/Off Control
TF0                  BIT  TCON.5      ; Timer 0 Overflow Flag
TR0                  BIT  TCON.4      ; Timer 0 On/Off Control
IE1                  BIT  TCON.3      ; Ext. Interrupt 1 Edge Flag
IT1                  BIT  TCON.2      ; Ext. Interrupt 1 Type
IE0                  BIT  TCON.1      ; Ext. Interrupt 0 Edge Flag
IT0                  BIT  TCON.0      ; Ext. Interrupt 0 Type

; TMR2CN 0xC8
TF2H                 BIT  TMR2CN.7    ; T2 High-Byte Overflow Flag
TF2L                 BIT  TMR2CN.6    ; T2 Low-Byte Overflow Flag
TF2LEN               BIT  TMR2CN.5    ; T2 Low Byte Interrupt Enable
TF2CEN               BIT  TMR2CN.4    ; T2 Input Capture Enable
T2SPLIT              BIT  TMR2CN.3    ; T2 Split-Mode Enable
TR2                  BIT  TMR2CN.2    ; Timer 2 On/Off Control
                                      ; bit 1 UNUSED
T2XCLK               BIT  TMR2CN.0    ; T2 External Clock Select
