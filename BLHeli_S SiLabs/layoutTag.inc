;**** **** **** **** ****
;
; BLHeli program for controlling brushless motors in helicopters and multirotors
;
; Copyright 2011, 2019 Steffen Skaug, Jazz Maverick, James Kingdon
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
; Create the layout and MCU tags used by the configurator for display and validation
;
; Inputs:
;   FETON_DELAY   - integer, dead time delay value. Converted to 3 decimal digits
;   ESCNO         - integer for variant type, 1 through 23, converted to 'A' through 'W'
;   MCU_48MHZ     - integer, flag for high or low speed, converted to 'H' or 'L'
;   USE_EXTENDED_LAYOUT - integer, flag to add extra info to the layout tag.
;                         If used, this will cause the configurator to treat the hex files
;                         as different to the non-extended layout and will require the user
;                         to select the ignore mistatched mcu or layout check box when flashing.
;   PWM           - integer, pwm frequency in kHz, e.g. 48, converted to 2 digits. Used for
;                   extended layout
;
; Outputs:
;   Defines the 16 byte DB tags for Eep_ESC_Layout and Eep_ESC_MCU
;   Eep_ESC_Layout will be at 1A40h, Eep_ESC_MCU at 1A50h
;
;   Layout tag format: #<escno>_<speed>_<DT>#
;   eg
;     Eep_ESC_Layout:		DB	"#G_H_90#        "
;
;
;   MCU tag format: #<project>$<MCU>#
;   eg
;     Eep_ESC_MCU:			DB	"#BLHELI$EFM8B10#"
;
; Assumptions
;   Inputs must be set and with reasonable values
;
;**** **** **** **** ****

; convert FETON_DELAY to three ascii characters
DT_hundreds EQU FETON_DELAY/100
DT_tens EQU (FETON_DELAY-DT_hundreds*100)/10
DT_units EQU FETON_DELAY-(DT_hundreds*100+DT_tens*10)
DT_Char1 EQU 0x30+DT_hundreds
DT_Char2 EQU 0x30+DT_tens
DT_Char3 EQU 0x30+DT_units

; convet ESCNO to a single character, 1 -> 'A', 23 -> 'W'
ESCNO_ASCII EQU ESCNO + 0x40 ; 'A' is 0x41, less 1 because ESCNO is 1 based

; set the speed character, 'L' or 'H'
IF MCU_48MHZ == 0
   SPEED_CHAR EQU 'L'
ELSE
   SPEED_CHAR EQU 'H'
ENDIF

; convert PWM to ascii
; since we currently only support 24 and 48 we can just use an IF for now.
IF PWM == 24
   PWM_Char1 EQU '2'
   PWM_Char2 EQU '4'
ELSE
   PWM_Char1 EQU '4'
   PWM_Char2 EQU '8'
ENDIF


; define the layout tag from the above parts

CSEG AT 1A40h

IF USE_EXTENDED_LAYOUT == 1

   ; if DT starts with '0' then skip it and output a 2 digit DT
   IF DT_Char1 == 0x30     
      ; use 2 digit DT
      Eep_ESC_Layout:		DB	'#',ESCNO_ASCII,'_',SPEED_CHAR,'_',DT_Char2,DT_Char3,'_', \
                              PWM_Char1,PWM_Char2,"#     "
   ELSE
      ; use 3 digit DT, note 1 less trailing space to keep length = 16 bytes
      Eep_ESC_Layout:		DB	'#',ESCNO_ASCII,'_',SPEED_CHAR,'_',DT_Char1,DT_Char2,DT_Char3,'_', \
                              PWM_Char1,PWM_Char2,"#    "
   ENDIF

ELSE 
; write a standard (non-extended) layout target

   ; if DT starts with '0' then skip it and output a 2 digit DT
   IF DT_Char1 == 0x30     
      ; use 2 digit DT
      Eep_ESC_Layout:		DB	'#',ESCNO_ASCII,'_',SPEED_CHAR,'_',DT_Char2,DT_Char3,"#        "
   ELSE
      ; use 3 digit DT, note 1 less trailing space to keep length = 16 bytes
      Eep_ESC_Layout:		DB	'#',ESCNO_ASCII,'_',SPEED_CHAR,'_',DT_Char1,DT_Char2,DT_Char3,"#       "
   ENDIF

ENDIF

; define the MCU tag

CSEG AT 1A50h
IF MCU_48MHZ == 0
	Eep_ESC_MCU:			DB	"#BLHELI$EFM8B10#"	; Project and MCU tag (16 Bytes)
ELSE
	Eep_ESC_MCU:			DB	"#BLHELI$EFM8B21#"	; Project and MCU tag (16 Bytes)
ENDIF
