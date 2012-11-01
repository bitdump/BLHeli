;---------------------------------------------------------------------------
;  
;  
;
;
;  FILE NAME   : C8051F310.INC
;  TARGET MCUs : C8051F310, 'F311
;  DESCRIPTION : Register/bit definitions for the C8051F31x product family.
;
;  REVISION 1.3
;     -- added ESPI0 and PSPI0
;  REVISION 1.2
;     -- added VDM0CN (0xff)   
;
;  REVISION 1.1
;     -- changed TARGET MCUs to 'F310, 'F311
;     -- SPICFG --> SPI0CFG
;     -- SPICKR --> SPI0CKR
;     -- SPIDAT --> SPI0DAT
;     -- removed CLKMUL (0xb9)
;     -- AMUX0N --> AMX0N
;     -- AMUX0P --> AMX0P
;
;---------------------------------------------------------------------------

; BYTE Registers 
P0       DATA  080H     ; PORT 0                                                   
SP       DATA  081H     ; STACK POINTER                                            
DPL      DATA  082H     ; DATA POINTER - LOW BYTE                                  
DPH      DATA  083H     ; DATA POINTER - HIGH BYTE                                 
PCON     DATA  087H     ; POWER CONTROL                                            
TCON     DATA  088H     ; TIMER CONTROL                                            
TMOD     DATA  089H     ; TIMER MODE                                               
TL0      DATA  08AH     ; TIMER 0 - LOW BYTE                                       
TL1      DATA  08BH     ; TIMER 1 - LOW BYTE                                       
TH0      DATA  08CH     ; TIMER 0 - HIGH BYTE                                      
TH1      DATA  08DH     ; TIMER 1 - HIGH BYTE                                      
CKCON    DATA  08EH     ; CLOCK CONTROL                                            
PSCTL    DATA  08FH     ; PROGRAM STORE R/W CONTROL                                
P1       DATA  090H     ; PORT 1                                                   
TMR3CN   DATA  091H     ; TIMER 3 CONTROL                                          
TMR3RLL  DATA  092H     ; TIMER 3 RELOAD LOW                                       
TMR3RLH  DATA  093H     ; TIMER 3 RELOAD HIGH                                      
TMR3L    DATA  094H     ; TIMER 3 LOW BYTE                                         
TMR3H    DATA  095H     ; TIMER 3 HIGH BYTE                                        
SCON0    DATA  098H     ; SERIAL PORT 0 CONTROL                                    
SBUF0    DATA  099H     ; SERIAL PORT 0 BUFFER                                     
CPT1CN   DATA  09AH     ; COMPARATOR 1 CONTROL                                     
CPT0CN   DATA  09BH     ; COMPARATOR 0 CONTROL                                     
CPT1MD   DATA  09CH     ; COMPARATOR 1 MODE                                        
CPT0MD   DATA  09DH     ; COMPARATOR 0 MODE                                        
CPT1MX   DATA  09EH     ; COMPARATOR 1 MUX                                         
CPT0MX   DATA  09FH     ; COMPARATOR 0 MUX                                         
P2       DATA  0A0H     ; PORT 2                                                   
SPI0CFG  DATA  0A1H     ; SPI0 CONFIGURATION                                        
SPI0CKR  DATA  0A2H     ; SPI0 CLOCK CONFIGURATION                                  
SPI0DAT  DATA  0A3H     ; SPI0 DATA                                         
P0MDOUT  DATA  0A4H     ; PORT 0 OUTPUT MODE                                       
P1MDOUT  DATA  0A5H     ; PORT 1 OUTPUT MODE                                       
P2MDOUT  DATA  0A6H     ; PORT 2 OUTPUT MODE                                       
P3MDOUT  DATA  0A7H     ; PORT 3 OUTPUT MODE                                       
IE       DATA  0A8H     ; INTERRUPT ENABLE                                         
CLKSEL   DATA  0A9H     ; CLOCK SOURCE SELECT                                      
EMI0CN   DATA  0AAH     ; EXTERNAL MEMORY INTERFACE CONTROL                        
P3       DATA  0B0H     ; PORT 3                                                   
OSCXCN   DATA  0B1H     ; EXTERNAL OSCILLATOR CONTROL                              
OSCICN   DATA  0B2H     ; INTERNAL OSCILLATOR CONTROL                              
OSCICL   DATA  0B3H     ; INTERNAL OSCILLATOR CALIBRATION                          
FLACL    DATA  0B5H     ; FLASH ACCESS LIMIT
FLSCL    DATA  0B6H     ; FLASH SCALE                                              
FLKEY    DATA  0B7H     ; FLASH LOCK & KEY                                         
IP       DATA  0B8H     ; INTERRUPT PRIORITY   
AMX0N    DATA  0BAH     ; ADC0 MUX NEGATIVE CHANNEL SELECTION                      
AMX0P    DATA  0BBH     ; ADC0 MUX POSITIVE CHANNEL SELECTION                      
ADC0CF   DATA  0BCH     ; ADC0 CONFIGURATION                                       
ADC0L    DATA  0BDH     ; ADC0 DATA LOW                                            
ADC0H    DATA  0BEH     ; ADC0 DATA HIGH                                           
SMB0CN   DATA  0C0H     ; SMBUS CONTROL                                            
SMB0CF   DATA  0C1H     ; SMBUS CONFIGURATION                                      
SMB0DAT  DATA  0C2H     ; SMBUS DATA                                             
ADC0GTL  DATA  0C3H     ; ADC0 GREATER-THAN LOW                                    
ADC0GTH  DATA  0C4H     ; ADC0 GREATER-THAN HIGH                                   
ADC0LTL  DATA  0C5H     ; ADC0 LESS-THAN LOW                                       
ADC0LTH  DATA  0C6H     ; ADC0 LESS-THAN HIGH                                      
TMR2CN   DATA  0C8H     ; TIMER 2 CONTROL                                                
TMR2RLL  DATA  0CAH     ; TIMER 2 RELOAD LOW                                       
TMR2RLH  DATA  0CBH     ; TIMER 2 RELOAD HIGH                                      
TMR2L    DATA  0CCH     ; TIMER 2 LOW BYTE                                         
TMR2H    DATA  0CDH     ; TIMER 2 HIGH BYTE                                        
PSW      DATA  0D0H     ; PROGRAM STATUS WORD                                      
REF0CN   DATA  0D1H     ; VOLTAGE REFERENCE 0 CONTROL                              
P0SKIP   DATA  0D4H     ; PORT 0 CROSSBAR SKIP                                     
P1SKIP   DATA  0D5H     ; PORT 1 CROSSBAR SKIP                                     
P2SKIP   DATA  0D6H     ; PORT 2 CROSSBAR SKIP     
PCA0CN   DATA  0D8H     ; PCA0 CONTROL                                             
PCA0MD   DATA  0D9H     ; PCA0 MODE                                                
PCA0CPM0 DATA  0DAH     ; PCA0 MODULE 0 MODE                                       
PCA0CPM1 DATA  0DBH     ; PCA0 MODULE 1 MODE                                       
PCA0CPM2 DATA  0DCH     ; PCA0 MODULE 2 MODE     
PCA0CPM3 DATA  0DDH     ; PCA0 MODULE 3 MODE                                       
PCA0CPM4 DATA  0DEH     ; PCA0 MODULE 4 MODE                                    
ACC      DATA  0E0H     ; ACCUMULATOR                                              
XBR0     DATA  0E1H     ; DIGITAL CROSSBAR CONFIGURATION REGISTER 0                
XBR1     DATA  0E2H     ; DIGITAL CROSSBAR CONFIGURATION REGISTER 1                
IT01CF   DATA  0E4H     ; INT0/INT1 CONFIGURATION                                  
EIE1     DATA  0E6H     ; EXTERNAL INTERRUPT ENABLE 1                     
ADC0CN   DATA  0E8H     ; ADC 0 CONTROL                                            
PCA0CPL1 DATA  0E9H     ; PCA0 MODULE 1 CAPTURE/COMPARE REGISTER LOW BYTE          
PCA0CPH1 DATA  0EAH     ; PCA0 MODULE 1 CAPTURE/COMPARE REGISTER HIGH BYTE         
PCA0CPL2 DATA  0EBH     ; PCA0 MODULE 2 CAPTURE/COMPARE REGISTER LOW BYTE          
PCA0CPH2 DATA  0ECH     ; PCA0 MODULE 2 CAPTURE/COMPARE REGISTER HIGH BYTE         
PCA0CPL3 DATA  0EDH     ; PCA0 MODULE 3 CAPTURE/COMPARE REGISTER LOW BYTE          
PCA0CPH3 DATA  0EEH     ; PCA0 MODULE 3 CAPTURE/COMPARE REGISTER HIGH BYTE         
RSTSRC   DATA  0EFH     ; RESET SOURCE                                             
B        DATA  0F0H     ; B REGISTER                                               
P0MDIN   DATA  0F1H     ; PORT 0 INPUT MODE REGISTER                               
P1MDIN   DATA  0F2H     ; PORT 1 INPUT MODE REGISTER                               
P2MDIN   DATA  0F3H     ; PORT 2 INPUT MODE REGISTER                               
P3MDIN   DATA  0F4H     ; PORT 3 INPUT MODE REGISTER                               
EIP1     DATA  0F6H     ; EXTERNAL INTERRUPT PRIORITY 1
SPI0CN   DATA  0F8H     ; SPI0 CONTROL                                             
PCA0L    DATA  0F9H     ; PCA0 COUNTER REGISTER LOW BYTE                           
PCA0H    DATA  0FAH     ; PCA0 COUNTER REGISTER HIGH BYTE                          
PCA0CPL0 DATA  0FBH     ; PCA MODULE 0 CAPTURE/COMPARE REGISTER LOW BYTE           
PCA0CPH0 DATA  0FCH     ; PCA MODULE 0 CAPTURE/COMPARE REGISTER HIGH BYTE          
PCA0CPL4 DATA  0FDH     ; PCA MODULE 4 CAPTURE/COMPARE REGISTER LOW BYTE           
PCA0CPH4 DATA  0FEH     ; PCA MODULE 4 CAPTURE/COMPARE REGISTER HIGH BYTE      
VDM0CN    DATA  0FFH ; VDD MONITOR CONTROL

;------------------------------------------------------------------------------
;BIT DEFINITIONS
;
; TCON 88H
IT0      BIT   TCON.0   ; EXT. INTERRUPT 0 TYPE
IE0      BIT   TCON.1   ; EXT. INTERRUPT 0 EDGE FLAG
IT1      BIT   TCON.2   ; EXT. INTERRUPT 1 TYPE
IE1      BIT   TCON.3   ; EXT. INTERRUPT 1 EDGE FLAG
TR0      BIT   TCON.4   ; TIMER 0 ON/OFF CONTROL
TF0      BIT   TCON.5   ; TIMER 0 OVERFLOW FLAG
TR1      BIT   TCON.6   ; TIMER 1 ON/OFF CONTROL
TF1      BIT   TCON.7   ; TIMER 1 OVERFLOW FLAG

; SCON0  0x98 
RI0      BIT   SCON0.0  ; RECEIVE INTERRUPT FLAG                                
TI0      BIT   SCON0.1  ; TRANSMIT INTERRUPT FLAG                               
RB80     BIT   SCON0.2  ; RECEIVE BIT 8                                         
TB80     BIT   SCON0.3  ; TRANSMIT BIT 8                                        
REN0     BIT   SCON0.4  ; RECEIVE ENABLE                                        
MCE0     BIT   SCON0.5  ; MULTIPROCESSOR COMMUNICATION ENABLE                   
S0MODE   BIT   SCON0.7  ; SERIAL MODE CONTROL BIT 0                             

; IE  0xA8 
EX0      BIT   IE.0     ; EXTERNAL INTERRUPT 0 ENABLE                           
ET0      BIT   IE.1     ; TIMER 0 INTERRUPT ENABLE                              
EX1      BIT   IE.2     ; EXTERNAL INTERRUPT 1 ENABLE                           
ET1      BIT   IE.3     ; TIMER 1 INTERRUPT ENABLE                              
ES0      BIT   IE.4     ; UART0 INTERRUPT ENABLE                                
ET2      BIT   IE.5     ; TIMER 2 INTERRUPT ENABLE                              
ESPI0    BIT   IE.6     ; SPI0 INTERRUPT ENABLE
EA       BIT   IE.7     ; GLOBAL INTERRUPT ENABLE                               

; IP  0xB8 
PX0      BIT   IP.0     ; EXTERNAL INTERRUPT 0 PRIORITY                         
PT0      BIT   IP.1     ; TIMER 0 PRIORITY                                      
PX1      BIT   IP.2     ; EXTERNAL INTERRUPT 1 PRIORITY                         
PT1      BIT   IP.3     ; TIMER 1 PRIORITY                                      
PS0      BIT   IP.4     ; UART0 PRIORITY                                        
PT2      BIT   IP.5     ; TIMER 2 PRIORITY                                      
PSPI0    BIT   IP.6     ; SPI0 INTERRUPT PRIORITY

; SMB0CN 0xC0 
SI       BIT   SMB0CN.0 ; SMBUS0 INTERRUPT FLAG                                 
ACK      BIT   SMB0CN.1 ; ACKNOWLEDGE FLAG                                      
ARBLOST  BIT   SMB0CN.2 ; ARBITRATION LOST INDICATOR                            
ACKRQ    BIT   SMB0CN.3 ; ACKNOWLEDGE REQUEST                                   
STO      BIT   SMB0CN.4 ; STOP FLAG                                             
STA      BIT   SMB0CN.5 ; START FLAG                                            
TXMODE   BIT   SMB0CN.6 ; TRANSMIT MODE INDICATOR                               
MASTER   BIT   SMB0CN.7 ; MASTER/SLAVE INDICATOR                                

; TMR2CN 0xC8 
T2XCLK   BIT   TMR2CN.0 ; TIMER 2 EXTERNAL CLOCK SELECT                         
TR2      BIT   TMR2CN.2 ; TIMER 2 ON/OFF CONTROL                                
T2SPLIT  BIT   TMR2CN.3 ; TIMER 2 SPLIT MODE ENABLE                             
TF2LEN   BIT   TMR2CN.5 ; TIMER 2 LOW BYTE INTERRUPT ENABLE                     
TF2L     BIT   TMR2CN.6 ; TIMER 2 LOW BYTE OVERFLOW FLAG                        
TF2H     BIT   TMR2CN.7 ; TIMER 2 HIGH BYTE OVERFLOW FLAG                       

; PSW 0xD0 
P        BIT   PSW.0    ; ACCUMULATOR PARITY FLAG                               
F1       BIT   PSW.1    ; USER FLAG 1                                           
OV       BIT   PSW.2    ; OVERFLOW FLAG                                         
RS0      BIT   PSW.3    ; REGISTER BANK SELECT 0                                
RS1      BIT   PSW.4    ; REGISTER BANK SELECT 1                                
F0       BIT   PSW.5    ; USER FLAG 0                                           
AC       BIT   PSW.6    ; AUXILIARY CARRY FLAG                                  
CY       BIT   PSW.7    ; CARRY FLAG                                            

; PCA0CN 0xD8H 
CCF0     BIT   PCA0CN.0 ; PCA0 MODULE 0 CAPTURE/COMPARE FLAG                    
CCF1     BIT   PCA0CN.1 ; PCA0 MODULE 1 CAPTURE/COMPARE FLAG                    
CCF2     BIT   PCA0CN.2 ; PCA0 MODULE 2 CAPTURE/COMPARE FLAG                    
CCF3     BIT   PCA0CN.3 ; PCA0 MODULE 3 CAPTURE/COMPARE FLAG                    
CCF4     BIT   PCA0CN.4 ; PCA0 MODULE 4 CAPTURE/COMPARE FLAG                    
CR       BIT   PCA0CN.6 ; PCA0 COUNTER RUN CONTROL                              
CF       BIT   PCA0CN.7 ; PCA0 COUNTER OVERFLOW FLAG                            

; ADC0CN 0xE8H 
AD0CM0   BIT   ADC0CN.0 ; ADC0 CONVERSION MODE SELECT 0                         
AD0CM1   BIT   ADC0CN.1 ; ADC0 CONVERSION MODE SELECT 1                         
AD0CM2   BIT   ADC0CN.2 ; ADC0 CONVERSION MODE SELECT 2                         
AD0WINT  BIT   ADC0CN.3 ; ADC0 WINDOW COMPARE INTERRUPT FLAG                    
AD0BUSY  BIT   ADC0CN.4 ; ADC0 BUSY FLAG                                        
AD0INT   BIT   ADC0CN.5 ; ADC0 CONVERISION COMPLETE INTERRUPT FLAG              
AD0TM    BIT   ADC0CN.6 ; ADC0 TRACK MODE                                       
AD0EN    BIT   ADC0CN.7 ; ADC0 ENABLE                                           

; SPI0CN 0xF8H 
SPIF     BIT   SPI0CN.7 ; SPI 0 INTERRUPT FLAG                                  
WCOL     BIT   SPI0CN.6 ; SPI 0 WRITE COLLISION FLAG                            
MODF     BIT   SPI0CN.5 ; SPI 0 MODE FAULT FLAG                                 
RXOVRN   BIT   SPI0CN.4 ; SPI 0 RX OVERRUN FLAG                                 
NSSMD1   BIT   SPI0CN.3 ; SPI 0 SLAVE SELECT MODE 1                             
NSSMD0   BIT   SPI0CN.2 ; SPI 0 SLAVE SELECT MODE 0                             
TXBMT    BIT   SPI0CN.1 ; SPI 0 TRANSMIT BUFFER EMPTY                           
SPIEN    BIT   SPI0CN.0 ; SPI 0 SPI ENABLE                                      