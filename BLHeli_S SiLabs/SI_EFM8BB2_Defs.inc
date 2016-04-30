;------------------------------------------------------------------------------
; Copyright 2014 Silicon Laboratories, Inc.
; All rights reserved. This program and the accompanying materials
; are made available under the terms of the Silicon Laboratories End User
; License Agreement which accompanies this distribution, and is available at
; http://developer.silabs.com/legal/version/v11/Silicon_Labs_Software_License_Agreement.txt
; Original content and implementation provided by Silicon Laboratories.
;------------------------------------------------------------------------------
;Supported Devices:
;  EFM8BB21F16G_QFN20
;  EFM8BB21F16G_QSOP24
;  EFM8BB21F16I_QFN20
;  EFM8BB21F16I_QSOP24
;  EFM8BB22F16G_QFN28
;  EFM8BB22F16I_QFN28

;-----------------------------------------------------------------------------
; Register Definitions
;-----------------------------------------------------------------------------
ACC       DATA 0E0H; Accumulator                            
ADC0AC    DATA 0B3H; ADC0 Accumulator Configuration         
ADC0CF    DATA 0BCH; ADC0 Configuration                     
ADC0CN0   DATA 0E8H; ADC0 Control 0                         
ADC0CN1   DATA 0B2H; ADC0 Control 1                         
ADC0GTH   DATA 0C4H; ADC0 Greater-Than High Byte            
ADC0GTL   DATA 0C3H; ADC0 Greater-Than Low Byte             
ADC0H     DATA 0BEH; ADC0 Data Word High Byte               
ADC0L     DATA 0BDH; ADC0 Data Word Low Byte                
ADC0LTH   DATA 0C6H; ADC0 Less-Than High Byte               
ADC0LTL   DATA 0C5H; ADC0 Less-Than Low Byte                
ADC0MX    DATA 0BBH; ADC0 Multiplexer Selection             
ADC0PWR   DATA 0DFH; ADC0 Power Control                     
ADC0TK    DATA 0B9H; ADC0 Burst Mode Track Time             
B         DATA 0F0H; B Register                             
CKCON0    DATA 08EH; Clock Control 0                        
CKCON1    DATA 0A6H; Clock Control 1
CLKSEL    DATA 0A9H; Clock Select                           
CMP0CN0   DATA 09BH; Comparator 0 Control 0                 
CMP0CN1   DATA 099H; Comparator 0 Control 1
CMP0MD    DATA 09DH; Comparator 0 Mode                      
CMP0MX    DATA 09FH; Comparator 0 Multiplexer Selection     
CMP1CN0   DATA 0BFH; Comparator 1 Control 0                 
CMP1CN1   DATA 0ACH; Comparator 1 Control 1                 
CMP1MD    DATA 0ABH; Comparator 1 Mode                      
CMP1MX    DATA 0AAH; Comparator 1 Multiplexer Selection     
CRC0CN0   DATA 0CEH; CRC0 Control 0                         
CRC0CN1   DATA 086H; CRC0 Control 1                         
CRC0CNT   DATA 0D3H; CRC0 Automatic Flash Sector Count      
CRC0DAT   DATA 0DEH; CRC0 Data Output                       
CRC0FLIP  DATA 0CFH; CRC0 Bit Flip                          
CRC0IN    DATA 0DDH; CRC0 Data Input                        
CRC0ST    DATA 0D2H; CRC0 Automatic Flash Sector Start      
DERIVID   DATA 0ADH; Derivative Identification              
DEVICEID  DATA 0B5H; Device Identification                  
DPH       DATA 083H; Data Pointer High                      
DPL       DATA 082H; Data Pointer Low                       
EIE1      DATA 0E6H; Extended Interrupt Enable 1            
EIE2      DATA 0CEH; Extended Interrupt Enable 2            
EIP1      DATA 0F3H; Extended Interrupt Priority 1 Low      
EIP1H     DATA 0F5H; Extended Interrupt Priority 1 High     
EIP2      DATA 0F4H; Extended Interrupt Priority 2          
EIP2H     DATA 0F6H; Extended Interrupt Priority 2 High     
EMI0CN    DATA 0E7H; External Memory Interface Control      
FLKEY     DATA 0B7H; Flash Lock and Key                     
HFO0CAL   DATA 0C7H; High Frequency Oscillator 0 Calibration
HFO1CAL   DATA 0D6H; High Frequency Oscillator 1 Calibration
HFOCN     DATA 0EFH; High Frequency Oscillator Control      
I2C0CN0   DATA 0BAH; I2C0 Control                           
I2C0DIN   DATA 0BCH; I2C0 Received Data                     
I2C0DOUT  DATA 0BBH; I2C0 Transmit Data                     
I2C0FCN0  DATA 0ADH; I2C0 FIFO Control 0                    
I2C0FCN1  DATA 0ABH; I2C0 FIFO Control 1                    
I2C0FCT   DATA 0F5H; I2C0 FIFO Count                        
I2C0SLAD  DATA 0BDH; I2C0 Slave Address                     
I2C0STAT  DATA 0B9H; I2C0 Status                            
IE        DATA 0A8H; Interrupt Enable                       
IP        DATA 0B8H; Interrupt Priority                     
IPH       DATA 0F2H; Interrupt Priority High                
IT01CF    DATA 0E4H; INT0/INT1 Configuration                
LFO0CN    DATA 0B1H; Low Frequency Oscillator Control       
P0        DATA 080H; Port 0 Pin Latch                       
P0MASK    DATA 0FEH; Port 0 Mask                            
P0MAT     DATA 0FDH; Port 0 Match                           
P0MDIN    DATA 0F1H; Port 0 Input Mode                      
P0MDOUT   DATA 0A4H; Port 0 Output Mode                     
P0SKIP    DATA 0D4H; Port 0 Skip                            
P1        DATA 090H; Port 1 Pin Latch                       
P1MASK    DATA 0EEH; Port 1 Mask                            
P1MAT     DATA 0EDH; Port 1 Match                           
P1MDIN    DATA 0F2H; Port 1 Input Mode                      
P1MDOUT   DATA 0A5H; Port 1 Output Mode                     
P1SKIP    DATA 0D5H; Port 1 Skip                            
P2        DATA 0A0H; Port 2 Pin Latch                       
P2MASK    DATA 0FCH; Port 2 Mask                            
P2MAT     DATA 0FBH; Port 2 Match                           
P2MDIN    DATA 0F3H; Port 2 Input Mode                      
P2MDOUT   DATA 0A6H; Port 2 Output Mode                     
P2SKIP    DATA 0CCH; Port 2 Skip                            
P3        DATA 0B0H; Port 3 Pin Latch                       
P3MDIN    DATA 0F4H; Port 3 Input Mode                      
P3MDOUT   DATA 09CH; Port 3 Output Mode                     
PCA0CENT  DATA 09EH; PCA Center Alignment Enable            
PCA0CLR   DATA 09CH; PCA Comparator Clear Control           
PCA0CN0   DATA 0D8H; PCA Control                            
PCA0CPH0  DATA 0FCH; PCA Channel 0 Capture Module High Byte 
PCA0CPH1  DATA 0EAH; PCA Channel 1 Capture Module High Byte 
PCA0CPH2  DATA 0ECH; PCA Channel 2 Capture Module High Byte 
PCA0CPL0  DATA 0FBH; PCA Channel 0 Capture Module Low Byte  
PCA0CPL1  DATA 0E9H; PCA Channel 1 Capture Module Low Byte  
PCA0CPL2  DATA 0EBH; PCA Channel 2 Capture Module Low Byte  
PCA0CPM0  DATA 0DAH; PCA Channel 0 Capture/Compare Mode     
PCA0CPM1  DATA 0DBH; PCA Channel 1 Capture/Compare Mode     
PCA0CPM2  DATA 0DCH; PCA Channel 2 Capture/Compare Mode     
PCA0H     DATA 0FAH; PCA Counter/Timer High Byte            
PCA0L     DATA 0F9H; PCA Counter/Timer Low Byte             
PCA0MD    DATA 0D9H; PCA Mode                               
PCA0POL   DATA 096H; PCA Output Polarity                    
PCA0PWM   DATA 0F7H; PCA PWM Configuration                  
PCON0     DATA 087H; Power Control                          
PCON1     DATA 09AH; Power Control 1                        
PFE0CN    DATA 0C1H; Prefetch Engine Control                
PRTDRV    DATA 0F6H; Port Drive Strength                    
PSCTL     DATA 08FH; Program Store Control                  
PSW       DATA 0D0H; Program Status Word                    
REF0CN    DATA 0D1H; Voltage Reference Control              
REG0CN    DATA 0C9H; Voltage Regulator 0 Control            
REG1CN    DATA 0C6H; Voltage Regulator 1 Control            
REVID     DATA 0B6H; Revision Identifcation                 
RSTSRC    DATA 0EFH; Reset Source                           
SBCON1    DATA 094H; UART1 Baud Rate Generator Control      
SBRLH1    DATA 096H; UART1 Baud Rate Generator High Byte    
SBRLL1    DATA 095H; UART1 Baud Rate Generator Low Byte     
SBUF0     DATA 099H; UART0 Serial Port Data Buffer          
SBUF1     DATA 092H; UART1 Serial Port Data Buffer          
SCON0     DATA 098H; UART0 Serial Port Control              
SCON1     DATA 0C8H; UART1 Serial Port Control              
SFRPAGE   DATA 0A7H; SFR Page                               
SFRPGCN   DATA 0CFH; SFR Page Control                       
SFRSTACK  DATA 0D7H; SFR Page Stack                         
SMB0ADM   DATA 0D6H; SMBus 0 Slave Address Mask             
SMB0ADR   DATA 0D7H; SMBus 0 Slave Address                  
SMB0CF    DATA 0C1H; SMBus 0 Configuration                  
SMB0CN0   DATA 0C0H; SMBus 0 Control                        
SMB0DAT   DATA 0C2H; SMBus 0 Data                           
SMB0FCN0  DATA 0C3H; SMBus 0 FIFO Control 0                 
SMB0FCN1  DATA 0C4H; SMBus 0 FIFO Control 1                 
SMB0FCT   DATA 0EFH; SMBus 0 FIFO Count                     
SMB0RXLN  DATA 0C5H; SMBus 0 Receive Length Counter         
SMB0TC    DATA 0ACH; SMBus 0 Timing and Pin Control         
SMOD1     DATA 093H; UART1 Mode                             
SP        DATA 081H; Stack Pointer                          
SPI0CFG   DATA 0A1H; SPI0 Configuration                     
SPI0CKR   DATA 0A2H; SPI0 Clock Rate                        
SPI0CN0   DATA 0F8H; SPI0 Control                           
SPI0DAT   DATA 0A3H; SPI0 Data                              
SPI0FCN0  DATA 09AH; SPI0 FIFO Control 0                    
SPI0FCN1  DATA 09BH; SPI0 FIFO Control 1                    
SPI0FCT   DATA 0F7H; SPI0 FIFO Count                        
TCON      DATA 088H; Timer 0/1 Control                      
TH0       DATA 08CH; Timer 0 High Byte                      
TH1       DATA 08DH; Timer 1 High Byte                      
TL0       DATA 08AH; Timer 0 Low Byte                       
TL1       DATA 08BH; Timer 1 Low Byte                       
TMOD      DATA 089H; Timer 0/1 Mode                         
TMR2CN0   DATA 0C8H; Timer 2 Control 0                      
TMR2CN1   DATA 0FDH; Timer 2 Control 1                      
TMR2H     DATA 0CDH; Timer 2 High Byte                      
TMR2L     DATA 0CCH; Timer 2 Low Byte                       
TMR2RLH   DATA 0CBH; Timer 2 Reload High Byte               
TMR2RLL   DATA 0CAH; Timer 2 Reload Low Byte                
TMR3CN0   DATA 091H; Timer 3 Control 0                      
TMR3CN1   DATA 0FEH; Timer 3 Control 1                      
TMR3H     DATA 095H; Timer 3 High Byte                      
TMR3L     DATA 094H; Timer 3 Low Byte                       
TMR3RLH   DATA 093H; Timer 3 Reload High Byte               
TMR3RLL   DATA 092H; Timer 3 Reload Low Byte                
TMR4CN0   DATA 098H; Timer 4 Control 0                      
TMR4CN1   DATA 0FFH; Timer 4 Control 1                      
TMR4H     DATA 0A5H; Timer 4 High Byte                      
TMR4L     DATA 0A4H; Timer 4 Low Byte                       
TMR4RLH   DATA 0A3H; Timer 4 Reload High Byte               
TMR4RLL   DATA 0A2H; Timer 4 Reload Low Byte                
UART1FCN0 DATA 09DH; UART1 FIFO Control 0                   
UART1FCN1 DATA 0D8H; UART1 FIFO Control 1                   
UART1FCT  DATA 0FAH; UART1 FIFO Count                       
UART1LIN  DATA 09EH; UART1 LIN Configuration                
VDM0CN    DATA 0FFH; Supply Monitor Control                 
WDTCN     DATA 097H; Watchdog Timer Control                 
XBR0      DATA 0E1H; Port I/O Crossbar 0                    
XBR1      DATA 0E2H; Port I/O Crossbar 1                    
XBR2      DATA 0E3H; Port I/O Crossbar 2                    

;------------------------------------------------------------------------------
; 16-bit Register Definitions (may not work on all compilers)
;------------------------------------------------------------------------------
ADC0GT  DATA 0C3H ; ADC0 Greater-Than Low Byte           
ADC0    DATA 0BDH ; ADC0 Data Word Low Byte              
ADC0LT  DATA 0C5H ; ADC0 Less-Than Low Byte              
DP      DATA 082H ; Data Pointer Low                     
PCA0CP0 DATA 0FBH ; PCA Channel 0 Capture Module Low Byte
PCA0CP1 DATA 0E9H ; PCA Channel 1 Capture Module Low Byte
PCA0CP2 DATA 0EBH ; PCA Channel 2 Capture Module Low Byte
PCA0    DATA 0F9H ; PCA Counter/Timer Low Byte           
SBRL1   DATA 095H ; UART1 Baud Rate Generator Low Byte   
TMR2    DATA 0CCH ; Timer 2 Low Byte                     
TMR2RL  DATA 0CAH ; Timer 2 Reload Low Byte              
TMR3    DATA 094H ; Timer 3 Low Byte                     
TMR3RL  DATA 092H ; Timer 3 Reload Low Byte              
TMR4    DATA 0A4H ; Timer 4 Low Byte                     
TMR4RL  DATA 0A2H ; Timer 4 Reload Low Byte              

;------------------------------------------------------------------------------
; Indirect Register Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Bit Definitions
;------------------------------------------------------------------------------

; ACC 0xE0 (Accumulator)
ACC_ACC0 BIT ACC.0 ; Accumulator Bit 0
ACC_ACC1 BIT ACC.1 ; Accumulator Bit 1
ACC_ACC2 BIT ACC.2 ; Accumulator Bit 2
ACC_ACC3 BIT ACC.3 ; Accumulator Bit 3
ACC_ACC4 BIT ACC.4 ; Accumulator Bit 4
ACC_ACC5 BIT ACC.5 ; Accumulator Bit 5
ACC_ACC6 BIT ACC.6 ; Accumulator Bit 6
ACC_ACC7 BIT ACC.7 ; Accumulator Bit 7

; ADC0CN0 0xE8 (ADC0 Control 0)
ADC0CN0_ADCM0  BIT ADC0CN0.0 ; Start of Conversion Mode Select Bit 0
ADC0CN0_ADCM1  BIT ADC0CN0.1 ; Start of Conversion Mode Select Bit 1
ADC0CN0_ADCM2  BIT ADC0CN0.2 ; Start of Conversion Mode Select Bit 2
ADC0CN0_ADWINT BIT ADC0CN0.3 ; Window Compare Interrupt Flag        
ADC0CN0_ADBUSY BIT ADC0CN0.4 ; ADC Busy                             
ADC0CN0_ADINT  BIT ADC0CN0.5 ; Conversion Complete Interrupt Flag   
ADC0CN0_ADBMEN BIT ADC0CN0.6 ; Burst Mode Enable                    
ADC0CN0_ADEN   BIT ADC0CN0.7 ; ADC Enable                           

; B 0xF0 (B Register)
B_B0 BIT B.0 ; B Register Bit 0
B_B1 BIT B.1 ; B Register Bit 1
B_B2 BIT B.2 ; B Register Bit 2
B_B3 BIT B.3 ; B Register Bit 3
B_B4 BIT B.4 ; B Register Bit 4
B_B5 BIT B.5 ; B Register Bit 5
B_B6 BIT B.6 ; B Register Bit 6
B_B7 BIT B.7 ; B Register Bit 7

; IE 0xA8 (Interrupt Enable)
IE_EX0   BIT IE.0 ; External Interrupt 0 Enable
IE_ET0   BIT IE.1 ; Timer 0 Interrupt Enable   
IE_EX1   BIT IE.2 ; External Interrupt 1 Enable
IE_ET1   BIT IE.3 ; Timer 1 Interrupt Enable   
IE_ES0   BIT IE.4 ; UART0 Interrupt Enable     
IE_ET2   BIT IE.5 ; Timer 2 Interrupt Enable   
IE_ESPI0 BIT IE.6 ; SPI0 Interrupt Enable      
IE_EA    BIT IE.7 ; All Interrupts Enable      

; IP 0xB8 (Interrupt Priority)
IP_PX0   BIT IP.0 ; External Interrupt 0 Priority Control LSB                        
IP_PT0   BIT IP.1 ; Timer 0 Interrupt Priority Control LSB                           
IP_PX1   BIT IP.2 ; External Interrupt 1 Priority Control LSB                        
IP_PT1   BIT IP.3 ; Timer 1 Interrupt Priority Control LSB                           
IP_PS0   BIT IP.4 ; UART0 Interrupt Priority Control LSB                             
IP_PT2   BIT IP.5 ; Timer 2 Interrupt Priority Control LSB                           
IP_PSPI0 BIT IP.6 ; Serial Peripheral Interface (SPI0) Interrupt Priority Control LSB

; P0 0x80 (Port 0 Pin Latch)
P0_B0 BIT P0.0 ; Port 0 Bit 0 Latch
P0_B1 BIT P0.1 ; Port 0 Bit 1 Latch
P0_B2 BIT P0.2 ; Port 0 Bit 2 Latch
P0_B3 BIT P0.3 ; Port 0 Bit 3 Latch
P0_B4 BIT P0.4 ; Port 0 Bit 4 Latch
P0_B5 BIT P0.5 ; Port 0 Bit 5 Latch
P0_B6 BIT P0.6 ; Port 0 Bit 6 Latch
P0_B7 BIT P0.7 ; Port 0 Bit 7 Latch

; P1 0x90 (Port 1 Pin Latch)
P1_B0 BIT P1.0 ; Port 1 Bit 0 Latch
P1_B1 BIT P1.1 ; Port 1 Bit 1 Latch
P1_B2 BIT P1.2 ; Port 1 Bit 2 Latch
P1_B3 BIT P1.3 ; Port 1 Bit 3 Latch
P1_B4 BIT P1.4 ; Port 1 Bit 4 Latch
P1_B5 BIT P1.5 ; Port 1 Bit 5 Latch
P1_B6 BIT P1.6 ; Port 1 Bit 6 Latch
P1_B7 BIT P1.7 ; Port 1 Bit 7 Latch

; P2 0xA0 (Port 2 Pin Latch)
P2_B0 BIT P2.0 ; Port 2 Bit 0 Latch
P2_B1 BIT P2.1 ; Port 2 Bit 1 Latch
P2_B2 BIT P2.2 ; Port 2 Bit 2 Latch
P2_B3 BIT P2.3 ; Port 2 Bit 3 Latch

; P3 0xB0 (Port 3 Pin Latch)
P3_B0 BIT P3.0 ; Port 3 Bit 0 Latch
P3_B1 BIT P3.1 ; Port 3 Bit 1 Latch

; PCA0CN0 0xD8 (PCA Control)
PCA0CN0_CCF0 BIT PCA0CN0.0 ; PCA Module 0 Capture/Compare Flag
PCA0CN0_CCF1 BIT PCA0CN0.1 ; PCA Module 1 Capture/Compare Flag
PCA0CN0_CCF2 BIT PCA0CN0.2 ; PCA Module 2 Capture/Compare Flag
PCA0CN0_CR   BIT PCA0CN0.6 ; PCA Counter/Timer Run Control    
PCA0CN0_CF   BIT PCA0CN0.7 ; PCA Counter/Timer Overflow Flag  

; PSW 0xD0 (Program Status Word)
PSW_PARITY BIT PSW.0 ; Parity Flag               
PSW_F1     BIT PSW.1 ; User Flag 1               
PSW_OV     BIT PSW.2 ; Overflow Flag             
PSW_RS0    BIT PSW.3 ; Register Bank Select Bit 0
PSW_RS1    BIT PSW.4 ; Register Bank Select Bit 1
PSW_F0     BIT PSW.5 ; User Flag 0               
PSW_AC     BIT PSW.6 ; Auxiliary Carry Flag      
PSW_CY     BIT PSW.7 ; Carry Flag                

; SCON0 0x98 (UART0 Serial Port Control)
SCON0_RI    BIT SCON0.0 ; Receive Interrupt Flag             
SCON0_TI    BIT SCON0.1 ; Transmit Interrupt Flag            
SCON0_RB8   BIT SCON0.2 ; Ninth Receive Bit                  
SCON0_TB8   BIT SCON0.3 ; Ninth Transmission Bit             
SCON0_REN   BIT SCON0.4 ; Receive Enable                     
SCON0_MCE   BIT SCON0.5 ; Multiprocessor Communication Enable
SCON0_SMODE BIT SCON0.7 ; Serial Port 0 Operation Mode       

; SCON1 0xC8 (UART1 Serial Port Control)
SCON1_RI   BIT SCON1.0 ; Receive Interrupt Flag   
SCON1_TI   BIT SCON1.1 ; Transmit Interrupt Flag  
SCON1_RBX  BIT SCON1.2 ; Extra Receive Bit        
SCON1_TBX  BIT SCON1.3 ; Extra Transmission Bit   
SCON1_REN  BIT SCON1.4 ; Receive Enable           
SCON1_PERR BIT SCON1.6 ; Parity Error Flag        
SCON1_OVR  BIT SCON1.7 ; Receive FIFO Overrun Flag

; SMB0CN0 0xC0 (SMBus 0 Control)
SMB0CN0_SI      BIT SMB0CN0.0 ; SMBus Interrupt Flag            
SMB0CN0_ACK     BIT SMB0CN0.1 ; SMBus Acknowledge               
SMB0CN0_ARBLOST BIT SMB0CN0.2 ; SMBus Arbitration Lost Indicator
SMB0CN0_ACKRQ   BIT SMB0CN0.3 ; SMBus Acknowledge Request       
SMB0CN0_STO     BIT SMB0CN0.4 ; SMBus Stop Flag                 
SMB0CN0_STA     BIT SMB0CN0.5 ; SMBus Start Flag                
SMB0CN0_TXMODE  BIT SMB0CN0.6 ; SMBus Transmit Mode Indicator   
SMB0CN0_MASTER  BIT SMB0CN0.7 ; SMBus Master/Slave Indicator    

; SPI0CN0 0xF8 (SPI0 Control)
SPI0CN0_SPIEN  BIT SPI0CN0.0 ; SPI0 Enable            
SPI0CN0_TXNF   BIT SPI0CN0.1 ; TX FIFO Not Full       
SPI0CN0_NSSMD0 BIT SPI0CN0.2 ; Slave Select Mode Bit 0
SPI0CN0_NSSMD1 BIT SPI0CN0.3 ; Slave Select Mode Bit 1
SPI0CN0_RXOVRN BIT SPI0CN0.4 ; Receive Overrun Flag   
SPI0CN0_MODF   BIT SPI0CN0.5 ; Mode Fault Flag        
SPI0CN0_WCOL   BIT SPI0CN0.6 ; Write Collision Flag   
SPI0CN0_SPIF   BIT SPI0CN0.7 ; SPI0 Interrupt Flag    

; TCON 0x88 (Timer 0/1 Control)
TCON_IT0 BIT TCON.0 ; Interrupt 0 Type Select
TCON_IE0 BIT TCON.1 ; External Interrupt 0   
TCON_IT1 BIT TCON.2 ; Interrupt 1 Type Select
TCON_IE1 BIT TCON.3 ; External Interrupt 1   
TCON_TR0 BIT TCON.4 ; Timer 0 Run Control    
TCON_TF0 BIT TCON.5 ; Timer 0 Overflow Flag  
TCON_TR1 BIT TCON.6 ; Timer 1 Run Control    
TCON_TF1 BIT TCON.7 ; Timer 1 Overflow Flag  

; TMR2CN0 0xC8 (Timer 2 Control 0)
TMR2CN0_T2XCLK0 BIT TMR2CN0.0 ; Timer 2 External Clock Select Bit 0
TMR2CN0_T2XCLK1 BIT TMR2CN0.1 ; Timer 2 External Clock Select Bit 1
TMR2CN0_TR2     BIT TMR2CN0.2 ; Timer 2 Run Control                
TMR2CN0_T2SPLIT BIT TMR2CN0.3 ; Timer 2 Split Mode Enable          
TMR2CN0_TF2CEN  BIT TMR2CN0.4 ; Timer 2 Capture Enable             
TMR2CN0_TF2LEN  BIT TMR2CN0.5 ; Timer 2 Low Byte Interrupt Enable  
TMR2CN0_TF2L    BIT TMR2CN0.6 ; Timer 2 Low Byte Overflow Flag     
TMR2CN0_TF2H    BIT TMR2CN0.7 ; Timer 2 High Byte Overflow Flag    

; TMR4CN0 0x98 (Timer 4 Control 0)
TMR4CN0_T4XCLK0 BIT TMR4CN0.0 ; Timer 4 External Clock Select Bit 0
TMR4CN0_T4XCLK1 BIT TMR4CN0.1 ; Timer 4 External Clock Select Bit 1
TMR4CN0_TR4     BIT TMR4CN0.2 ; Timer 4 Run Control                
TMR4CN0_T4SPLIT BIT TMR4CN0.3 ; Timer 4 Split Mode Enable          
TMR4CN0_TF4CEN  BIT TMR4CN0.4 ; Timer 4 Capture Enable             
TMR4CN0_TF4LEN  BIT TMR4CN0.5 ; Timer 4 Low Byte Interrupt Enable  
TMR4CN0_TF4L    BIT TMR4CN0.6 ; Timer 4 Low Byte Overflow Flag     
TMR4CN0_TF4H    BIT TMR4CN0.7 ; Timer 4 High Byte Overflow Flag    

; UART1FCN1 0xD8 (UART1 FIFO Control 1)
UART1FCN1_RIE    BIT UART1FCN1.0 ; Receive Interrupt Enable 
UART1FCN1_RXTO0  BIT UART1FCN1.1 ; Receive Timeout Bit 0    
UART1FCN1_RXTO1  BIT UART1FCN1.2 ; Receive Timeout Bit 1    
UART1FCN1_RFRQ   BIT UART1FCN1.3 ; Receive FIFO Request     
UART1FCN1_TIE    BIT UART1FCN1.4 ; Transmit Interrupt Enable
UART1FCN1_TXHOLD BIT UART1FCN1.5 ; Transmit Hold            
UART1FCN1_TXNF   BIT UART1FCN1.6 ; TX FIFO Not Full         
UART1FCN1_TFRQ   BIT UART1FCN1.7 ; Transmit FIFO Request    

;------------------------------------------------------------------------------
; Interrupt Definitions
;------------------------------------------------------------------------------
INT0_IRQn    EQU 0  ; External Interrupt 0      
TIMER0_IRQn  EQU 1  ; Timer 0 Overflow          
INT1_IRQn    EQU 2  ; External Interrupt 1      
TIMER1_IRQn  EQU 3  ; Timer 1 Overflow          
UART0_IRQn   EQU 4  ; UART0                     
TIMER2_IRQn  EQU 5  ; Timer 2 Overflow / Capture
SPI0_IRQn    EQU 6  ; SPI0                      
SMBUS0_IRQn  EQU 7  ; SMBus 0                   
PMATCH_IRQn  EQU 8  ; Port Match                
ADC0WC_IRQn  EQU 9  ; ADC0 Window Compare       
ADC0EOC_IRQn EQU 10 ; ADC0 End of Conversion    
PCA0_IRQn    EQU 11 ; PCA0                      
CMP0_IRQn    EQU 12 ; Comparator 0              
CMP1_IRQn    EQU 13 ; Comparator 1              
TIMER3_IRQn  EQU 14 ; Timer 3 Overflow / Capture
UART1_IRQn   EQU 17 ; UART1                     
I2C0_IRQn    EQU 18 ; I2C0 Slave                
TIMER4_IRQn  EQU 19 ; Timer 4 Overflow / Capture

;------------------------------------------------------------------------------
; SFR Page Definitions
;------------------------------------------------------------------------------
CRC0_PAGE       EQU 000H ; CRC0 Page       
LEGACY_PAGE     EQU 000H ; Legacy SFR Page 
PCA0_PAGE       EQU 000H ; PCA0 Page       
PG2_PAGE        EQU 010H ; Page2           
TIMER2_PAGE     EQU 010H ; Timer 2 Page    
TIMER3_PAGE     EQU 010H ; Timer 3 Page    
TIMER4_PAGE     EQU 010H ; Timer 4 Page    
I2CSLAVE0_PAGE  EQU 020H ; I2C Slave 0 Page
PG3_PAGE        EQU 020H ; Page3           
SMB0_PAGE       EQU 020H ; SMBus 0 Page    
SPI0_PAGE       EQU 020H ; SPI0 Page       
UART0_PAGE      EQU 020H ; UART0 Page      
UART1_PAGE      EQU 020H ; UART1 Page      
