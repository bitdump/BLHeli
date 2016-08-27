; BLHeli bootloader for SiLabs MCUs. Based upon AVRootloader (copyright HR)

XTAL					EQU	25000000	

BOOT_START			EQU	1C00h	; Bootloader segment address
BOOT_DELAY			EQU	XTAL/4	; About 250ms (don't set to fast to avoid connection problems)
BOOT_BAUDRATE			EQU	19200	; Only used if no baudrate detection activated, XTAL is than important
BOOT_VERSION			EQU	6		; Version 6 (must be not changed)
BOOT_PAGES			EQU	1		; Number of flash segments for bootloader

UART_LOOP				EQU 	26		; Depends upon timing of putc, getc 
BAUDTIME				EQU 	((XTAL/BOOT_BAUDRATE)/3)-UART_LOOP

SUCCESS				EQU 	030h
ERRORVERIFY			EQU 	0C0h
ERRORCOMMAND			EQU 	0C1h
ERRORCRC				EQU 	0C2h
ERRORPROG				EQU 	0C5h

POLYNOM				EQU 	0A001h		; CRC Polynom

Xl					EQU 	R0			; Temporary X
Xh					EQU 	R1
Paral				EQU 	R2			; Params for UART
Parah				EQU 	R3	
Cmdl					EQU 	R4			; Commands
Cmdh					EQU 	R5	
Cntl					EQU 	R6			; Baudtime
Cnth					EQU 	R7

DSEG AT 20h					
Bit_Reg:				DS	1			; Bit storage register
Byte_Reg:				DS	1			; Byte storage register
Crcl:				DS 	1			; CRC 16Bit
Crch:				DS 	1
Baudl:				DS 	1			; Baudtime
Baudh:				DS 	1
Bit_Cnt:				DS 	1			; Counter in UART loops
Byte_Cntl:			DS 	1			; Generic counter
Byte_Cnth:			DS 	1			
BL_Flash_Key_1:		DS	1			; Flash keys
BL_Flash_Key_2:		DS	1

CSEG AT BOOT_START		; Bootloader start
init:clr	IE_EA
	; Select register bank 0 for main program routines
	clr	PSW.3				; Select register bank 0 for main program routines	
	; Disable the WDT.
	mov	WDTCN, #0DEh			; Disable watchdog
	mov	WDTCN, #0ADh		
	; Initialize stack
	mov	SP, #0c0h				; Stack = 64 upper bytes of RAM
	; Initialize clock
	mov	CLKSEL, #00h			; Set clock divider to 1
	; Initialize VDD monitor
	orl	VDM0CN, #080h    		; Enable the VDD monitor
	mov	Baudl, #38h  			; Wait 100us
	mov	Baudh, #03h
	acall waitf
	; Initialize flash keys
	mov	BL_Flash_Key_1, #0A5h	; First key code
	mov	BL_Flash_Key_2, #0F1h	; Second key code
	; Initialize ports
	orl	RTX_MDIN, #(1 SHL RTX_PIN)		; Set digital
	anl	RTX_MDOUT, #NOT(1 SHL RTX_PIN)	; Disable pushpull
	setb	RTX_PORT.RTX_PIN				; Set data high
	mov	RTX_SKIP, #0FFh
	mov	XBR2, #40h;					; Enable crossbar
	; Set number of connect attempts before exiting bootloader
	mov	Cmdh, #250

	; Identifier scanning
abd:	mov	Xl, #(low(BOOT_DELAY / 6)+1)
	mov	Xh, #(high(BOOT_DELAY / 6)+1)
	mov	Cmdl, #(high((BOOT_DELAY / 6) SHR 8)+1)
	mov	Crcl, #0
	mov	Crch, #0
	mov	DPTR, #BOOT_SIGN
	mov	Parah, #(BOOT_MSG - BOOT_SIGN)
	mov	Baudl, #low(BAUDTIME)
	mov	Baudh, #high(BAUDTIME)

wait_for_low:
	jnb	RTX_PORT.RTX_PIN, ($+5)
	ajmp wait_for_low

	; Identifier (BOOT_SIGN) scanning with timeout and checksum
id1:	jb	RTX_PORT.RTX_PIN, id3	; Look for high
	djnz	Xl, id1				; Subtract 1 from X (BOOT_DELAY)
	djnz	Xh, id1
	djnz	Cmdl, id1 

	ajmp	exit

id3:	jnb	RTX_PORT.RTX_PIN, id4	; Look for low
	djnz	Xl, id3				; Subtract 1 from X (BOOT_DELAY)
	djnz	Xh, id3
	djnz	Cmdl, id3

	ajmp	exit

id4:	acall getx				; Read character
	clr	A			
	movc A, @A+DPTR			; Load BOOT_SIGN character
	inc	DPTR
	clr	C
	subb	A, Paral				; Compare with read character
	jz	id5
	djnz	Cmdh, abd				; Retry if not last connect attempt
	ajmp	exit

id5:
	djnz	Parah, id1

	acall getw				; Read CRC
	jz	($+4)				; Check CRC
	ajmp	abd
	
	; Send info about chip/bootloader (BOOT_MSG + BOOT_INFO)
	mov	Parah, #((BOOT_INFO - BOOT_MSG) + 4)
in1:	clr	A			
	movc A, @A+DPTR			; Load character
	mov	Paral, A
	inc	DPTR
	acall putc
	djnz	Parah, in1


	; Main commandloop
	; 0=Run/restart 
	; 1=Program flash, 2=Erase flash, 3=Read flash
	; 0xFF=Set address, 0xFE=Set buffer, 0xFD=Keep alive 
main:mov	Paral, #SUCCESS
mai1:acall putc
	mov	Crcl, #0				; Reset CRC
	mov	Crch, #0
	acall getw				; Get command
	mov	A, Paral
	mov	Cmdl, A
	mov	A, Parah
	mov	Cmdh, A
	clr	C
	mov	A, Cmdh
	subb	A, #0FEh
	jc	mai2					; Jump if not set address or set buffer	

	acall getw				; Address or number of bytes
	mov	Byte_Cntl, Paral		; Store number of bytes for set buffer
	mov	Byte_Cnth, Parah	
	mov	A, Cmdh
	jnb	ACC.0, mai2			; Jump if set buffer

	mov	DPL, Paral			; Store flash address (for set address)
	mov	DPH, Parah

mai2:acall getw				; Get CRC
	mov	Paral, #ERRORCRC
	jnz	mai1
	clr	C
	mov	A, Cmdh
	subb	A, #0FEh
	jz	setbuf				; If command is set buffer, receive data
	jnc	main

	cjne	Cmdh, #0, mai4			; Jump if command != 0 (and not set buffer)

	; Run application/restart bootloader
	mov	A, Cmdl
	jz	rst
exit:mov	Bit_Access, #0			; Clear variable used by flash lock detect
	mov	Bit_Access_Int, #0FFh	; Set variable to indicate that program execution came from bootloader
	mov	BL_Flash_Key_1, #0		; Set flash keys to invalid values
	mov	BL_Flash_Key_2, #0
	ljmp	0000h
rst:	ajmp	init

	; Set buffer
setbuf:mov Xl, Byte_Cntl			; Set number of bytes 
	mov	Xh, Byte_Cnth
	inc	Xl	
	inc	Xh	
set4:djnz	Xl, set5
	djnz	Xh, set5
	ajmp	set6

set5:acall getc				; Receive data
	mov	A, Paral
	movx	@Xl, A				; Store data in XRAM
	ajmp	set4

set6:inc	Cmdh	
	ajmp	mai2

mai4:clr	C
	mov	A, Cmdh
	subb	A, #3
	jnc	mai5					; Jump if command >= 3

	; Program/erase
	mov	A, Cmdh
	mov	C, ACC.0
	mov	Bit_Reg.0, C	
	mov	Paral, #ERRORPROG
	clr	C
	mov	A, DPL
	subb	A, #low(BOOT_START)
	mov	A, DPH
	subb	A, #high(BOOT_START)
	jnc	mai1					; Jump if in bootloader segment
	jb	Bit_Reg.0, pro3		; Jump if program command

	; Erase flash
	orl	PSCTL, #02h			; Set the PSEE bit
	orl	PSCTL, #01h			; Set the PSWE bit
	mov	FLKEY, BL_Flash_Key_1	; First key code
	mov	FLKEY, BL_Flash_Key_2	; Second key code
	movx	@DPTR, A
	jnb	Bit_Reg.0, pro6		; Jump if erase command

	; Program flash
pro3:mov 	Xl, Byte_Cntl			; Set number of bytes 
	mov	Xh, Byte_Cnth
	inc	Xl	
	inc	Xh	
	orl	PSCTL, #01h			; Set the PSWE bit
	anl	PSCTL, #0FDh			; Clear the PSEE bit
pro4:djnz	Xl, pro5
	djnz	Xh, pro5
	ajmp	pro6

pro5:
	clr	C
	mov	A, DPH				; Check that address is not in bootloader area
	subb	A, #1Ch
	jc	($+5)

	inc	DPTR					; Increment flash address
	ajmp	pro4

	movx	A, @Xl				; Read from XRAM		
	mov	FLKEY, BL_Flash_Key_1	; First key code
	mov	FLKEY, BL_Flash_Key_2	; Second key code
	movx	@DPTR, A				; Write to flash
	inc	DPTR					; Increment flash address
	ajmp	pro4

pro6:anl	PSCTL, #0FCh			; Clear the PSEE and PSWE bits
	ajmp	main					; Successfully done erase or program

	; Read flash
mai5:mov	Paral, #ERRORCOMMAND	; Illegal command
	cjne	Cmdh, #3, mai6			; Jump if not read flash command

rd1:	clr	A
	movc	A, @A+DPTR			; Read from flash
	inc	DPTR					; Increment flash address
	mov	Paral, A
	acall putp
	djnz	Cmdl, rd1 			; Decrement bytes to read	

	acall putw				; CRC
	ajmp	main

mai6:ajmp	mai1




	; Send char with crc
putw:mov	Paral, Crcl
	mov	Parah, Crch
	acall putc
	mov	A, Parah
	mov	Paral, A
putp:mov	A, Paral
	xrl	Crcl, A
	mov	Bit_Cnt, #8
put1:clr	C
	mov	A, Crch
	rrc	A
	mov	Crch, A
	mov	A, Crcl
	rrc	A
	mov	Crcl, A
	jnc	put2

	xrl	Crch, #high(POLYNOM)
	xrl	Crcl, #low(POLYNOM)

put2:djnz	Bit_Cnt, put1


	; Send char
putc:acall waitf
	acall waitf
	mov	Bit_Cnt, #10
	mov	A, Paral
	cpl	A
put3:jb	Bit_Reg.1, ($+5)
	setb	RTX_PORT.RTX_PIN		; Set pin high
	jnb	Bit_Reg.1, ($+5)
	clr	RTX_PORT.RTX_PIN		; Set pin low
	acall waitf							
	clr	C
	rrc	A
	jc	put4		
						
	clr	Bit_Reg.1

put4:djnz	Bit_Cnt, put3

	ret


	; Receive char/word
getw:acall getc
	mov	A, Paral
	mov	Parah, A
getc:jb	RTX_PORT.RTX_PIN, ($+5)	; Wait for high
	ajmp	getc

get1:jnb	RTX_PORT.RTX_PIN, ($+5)	; Wait for low
	ajmp	get1

getx:mov	Bit_Cnt, #8
	mov	Cntl, Baudl
	mov	Cnth, Baudh
	clr	C
	mov	A, Cnth				; Wait half a baud
	rrc	A
	mov	Cnth, A
	mov	A, Cntl
	rrc	A
	mov	Cntl, A
	acall waith
get2:acall waitf				; Wait one baud							
	clr	C
	mov	A, Paral
	rrc	A
	jnb	RTX_PORT.RTX_PIN, ($+5)			
	orl	A, #080h

	mov	Paral, A
	jnb	ACC.7, ($+6) 
	xrl	Crcl, #low(POLYNOM)

	clr	C
	mov	A, Crch
	rrc	A
	mov	Crch, A
	mov	A, Crcl
	rrc	A
	mov	Crcl, A
	jnc	get3				

	xrl	Crch, #high(POLYNOM)
	xrl	Crcl, #low(POLYNOM)

get3:djnz	Bit_Cnt, get2

	mov	A, Crcl 
	xrl	A, Crch 
	xrl	A, Crch 
	mov	Crcl, A
	ret


	; UART delays										
waitf:mov	Cntl, Baudl	
	mov	Cnth, Baudh
waith:inc Cntl
	inc	Cnth
wait1:djnz Cntl, wait1
	djnz Cnth, wait1

	setb	Bit_Reg.1
	ret									


BOOT_SIGN:	DB	"BLHeli"	

BOOT_MSG:		DB	"471d"		; Interface-MCU_BootlaoderRevision

BOOT_INFO:	DB	SIGNATURE_001, SIGNATURE_002, BOOT_VERSION, BOOT_PAGES

