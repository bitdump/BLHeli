@ECHO off
@ECHO ***** Batch file for BlHeli_S (from 4712)  v.2         *****
@ECHO ***** All Messages will be saved to MakeHex_Result.txt *****
@ECHO ***** Start compile with any key  - CTRL-C to abort    *****
Break ON
@pause
DEL MakeHex_Result.txt /Q

rem ***** Adapt settings to your enviroment ****
DEL Output\Hex\*.* /Q
RMDIR Output\Hex
DEL Output\*.* /Q
RMDIR Output
MKDIR Output
MKDIR Output\Hex
SET Revision=REV16_7
SET KeilPath=C:\SiliconLabs\SimplicityStudio\v4\developer\toolchains\keil_8051\9.53\BIN

@ECHO Revision: %Revision% >> MakeHex_Result.txt
@ECHO Path for Keil toolchain: %KeilPath% >> MakeHex_Result.txt
@ECHO Start compile ..... >> MakeHex_Result.txt


SET ESCNO=1
SET ESC=A_L_
SET MCU_48MHZ=0
call:compile
SET ESC=A_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=B_L_
SET MCU_48MHZ=0
call:compile
SET ESC=B_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=C_L_
SET MCU_48MHZ=0
call:compile
SET ESC=C_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=D_L_
SET MCU_48MHZ=0
call:compile
SET ESC=D_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=E_L_
SET MCU_48MHZ=0
call:compile
SET ESC=E_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=F_L_
SET MCU_48MHZ=0
call:compile
SET ESC=F_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=G_L_
SET MCU_48MHZ=0
call:compile
SET ESC=G_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=H_L_
SET MCU_48MHZ=0
call:compile
SET ESC=H_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=I_L_
SET MCU_48MHZ=0
call:compile
SET ESC=I_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=J_L_
SET MCU_48MHZ=0
call:compile
SET ESC=J_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=K_L_
SET MCU_48MHZ=0
call:compile
SET ESC=K_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=L_L_
SET MCU_48MHZ=0
call:compile
SET ESC=L_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=M_L_
SET MCU_48MHZ=0
call:compile
SET ESC=M_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=N_L_
SET MCU_48MHZ=0
call:compile
SET ESC=N_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=O_L_
SET MCU_48MHZ=0
call:compile
SET ESC=O_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=P_L_
SET MCU_48MHZ=0
call:compile
SET ESC=P_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=Q_L_
SET MCU_48MHZ=0
call:compile
SET ESC=Q_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=R_L_
SET MCU_48MHZ=0
call:compile
SET ESC=R_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=S_L_
SET MCU_48MHZ=0
call:compile
SET ESC=S_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=T_L_
SET MCU_48MHZ=0
call:compile
SET ESC=T_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=U_L_
SET MCU_48MHZ=0
call:compile
SET ESC=U_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=V_L_
SET MCU_48MHZ=0
call:compile
SET ESC=V_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1

SET ESC=W_L_
SET MCU_48MHZ=0
call:compile
SET ESC=W_H_
SET MCU_48MHZ=1
call:compile
SET /A ESCNO+=1


goto :end


:compile
SET FETON_DELAY=0
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=5
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=10
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=15
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=20
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=25
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=30
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=40
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=50
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=70
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
SET /A FETON_DELAY=90
SET ESCNAME=%ESC%%FETON_DELAY%
call :compile_code
goto :eof


:compile_code
@ECHO compiling %ESCNAME%  
@ECHO. >> MakeHex_Result.txt
@ECHO ********************************************************************  >> MakeHex_Result.txt
@ECHO %ESCNAME%  >> MakeHex_Result.txt
@ECHO ********************************************************************  >> MakeHex_Result.txt
%KeilPath%\AX51.exe "BLHeli_S.asm" DEFINE(ESCNO=%ESCNO%) DEFINE(MCU_48MHZ=%MCU_48MHZ%) DEFINE(FETON_DELAY=%FETON_DELAY%) OBJECT(Output\%ESCNAME%_%Revision%.OBJ) DEBUG MACRO NOMOD51 COND SYMBOLS PAGEWIDTH(120) PAGELENGTH(65) >> MakeHex_Result.txt
%KeilPath%\LX51.exe "Output\%ESCNAME%_%Revision%.OBJ" TO "Output\%ESCNAME%_%Revision%.OMF" PAGEWIDTH (120) PAGELENGTH (65) >> MakeHex_Result.txt
%KeilPath%\Ohx51 "Output\%ESCNAME%_%Revision%.OMF" "HEXFILE (Output\%ESCNAME%_%Revision%.HEX)" "H386" >> MakeHex_Result.txt
copy "Output\%ESCNAME%_%Revision%.HEX" "Output\Hex\%ESCNAME%_%Revision%.HEX" > nul
del "Output\%ESCNAME%_%Revision%.HEX" > nul
@ECHO. >> MakeHex_Result.txt
goto :eof

:end

@pause
exit
