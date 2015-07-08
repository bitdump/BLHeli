@ECHO off
@ECHO ***** Batch file for BlHeli (from 4712)  v.2           *****
@ECHO ***** All Messages will be saved to MakeHex_Result.txt *****
@ECHO ***** Start compile with any key  - CTRL-C to abort    *****
Break ON
@pause
DEL MakeHex_Result.txt /Q

rem ***** Adapt settings to your enviroment ****
DEL Output\Hex\*.* /Q
DEL Output\Eep\*.* /Q
RMDIR Output\Hex
RMDIR Output\Eep
DEL Output\*.* /Q
RMDIR Output
MKDIR Output
MKDIR Output\Hex
MKDIR Output\Eep
SET Revision=REV14_0
SET AtmelPath=C:\Atmel\avrassembler
rem SET AtmelPath="C:\Dev\Atmel\AVR Tools\AvrAssembler2"

@ECHO Revision: %Revision% >> MakeHex_Result.txt
@ECHO Path for Atmel assembler: %AtmelPath% >> MakeHex_Result.txt
@ECHO Start compile ..... >> MakeHex_Result.txt

SET NAME=BLUESERIES_12A
call:compile
SET NAME=BLUESERIES_20A
call:compile
SET NAME=BLUESERIES_30A
call :compile
SET NAME=BLUESERIES_40A
call :compile
SET NAME=BLUESERIES_60A
call :compile
SET NAME=BLUESERIES_70A
call :compile
SET NAME=HK_UBEC_6A
call :compile
SET NAME=HK_UBEC_10A
call :compile
SET NAME=HK_UBEC_20A
call :compile
SET NAME=HK_UBEC_30A
call :compile
SET NAME=HK_UBEC_40A
call :compile
SET NAME=SUPERSIMPLE_18A
call :compile
SET NAME=SUPERSIMPLE_20A
call :compile
SET NAME=SUPERSIMPLE_30A
call :compile
SET NAME=SUPERSIMPLE_40A
call :compile
SET NAME=MULTISTAR_10Av2
call :compile
SET NAME=MULTISTAR_15A
call :compile
SET NAME=MULTISTAR_20A
call :compile
SET NAME=MULTISTAR_20A_NFET
call :compile
SET NAME=MULTISTAR_20Av2
call :compile
SET NAME=MULTISTAR_30A
call :compile
SET NAME=MULTISTAR_45A
call :compile
SET NAME=MYSTERY_12A
call :compile
SET NAME=MYSTERY_30A
call :compile
SET NAME=MYSTERY_40A
call :compile
SET NAME=SUNRISE_HIMULTI_20A
call :compile
SET NAME=SUNRISE_HIMULTI_30A
call :compile
SET NAME=SUNRISE_HIMULTI_40A
call :compile
SET NAME=RCTIMER_40A
call :compile
SET NAME=RCTIMER_NFS_30A
call :compile
SET NAME=YEP_7A
call :compile
SET NAME=AFRO_12A
call :compile
SET NAME=AFRO_20A
call :compile
SET NAME=AFRO_20A_HV
call :compile
SET NAME=AFRO_30A
call :compile
SET NAME=SUNRISE_BLHELI_SLIM_20A
call :compile
SET NAME=SUNRISE_BLHELI_SLIM_30A
call :compile
SET NAME=DYS_SN20A
call :compile

goto :end


:compile
SET BESC=%NAME%_MAIN
call :compile2
SET BESC=%NAME%_TAIL
call:compile2
SET BESC=%NAME%_MULTI
call:compile2
goto :eof

:compile2
@ECHO compiling %BESC%  
@ECHO. >> MakeHex_Result.txt
@ECHO ********************************************************************  >> MakeHex_Result.txt
@ECHO %BESC%  >> MakeHex_Result.txt
@ECHO ********************************************************************  >> MakeHex_Result.txt
%AtmelPath%\avrasm2.exe -D %BESC% -fI -o "Output\Hex\%BESC%_%Revision%.HEX" BLHeli.asm -e "Output\Eep\%BESC%_%Revision%.EEP" >> MakeHex_Result.txt
@ECHO. >> MakeHex_Result.txt
goto :eof

:end

@pause
exit