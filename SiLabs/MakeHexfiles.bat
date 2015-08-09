@ECHO off
@ECHO ***** Batch file for BlHeli (from 4712)  v.2           *****
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
SET Revision=REV14_0
SET SilabsPath=C:\SiLabs
SET RaisonancePath=C:\Raisonance

@ECHO Revision: %Revision% >> MakeHex_Result.txt
@ECHO Path for Silabs IDE: %SilabsPath% >> MakeHex_Result.txt
@ECHO Path for Raisonance IDE: %RaisonancePath% >> MakeHex_Result.txt
@ECHO Start compile ..... >> MakeHex_Result.txt

SET BESCNO=0
SET BESCNAME=XP_3A
call:compile
SET BESCNAME=XP_7A
call:compile
SET BESCNAME=XP_7A_FAST
call:compile
SET BESCNAME=XP_12A
call:compile
SET BESCNAME=XP_18A
call:compile
SET BESCNAME=XP_25A
call:compile
SET BESCNAME=XP_35A_SW
call:compile
SET BESCNAME=DP_3A
call:compile
SET BESCNAME=SUPERMICRO_3P5A
call:compile
SET BESCNAME=TURNIGY_PLUSH_6A
call:compile
SET BESCNAME=TURNIGY_PLUSH_10A
call:compile
SET BESCNAME=TURNIGY_PLUSH_12A
call:compile
SET BESCNAME=TURNIGY_PLUSH_18A
call:compile
SET BESCNAME=TURNIGY_PLUSH_25A
call:compile
SET BESCNAME=TURNIGY_PLUSH_30A
call:compile
SET BESCNAME=TURNIGY_PLUSH_40A
call:compile
SET BESCNAME=TURNIGY_PLUSH_60A
call:compile
SET BESCNAME=TURNIGY_PLUSH_80A
call:compile
SET BESCNAME=TURNIGY_PLUSH_NFET_18A
call:compile
SET BESCNAME=TURNIGY_PLUSH_NFET_25A
call:compile
SET BESCNAME=TURNIGY_PLUSH_NFET_30A
call:compile
SET BESCNAME=TURNIGY_AE_20A
call:compile
SET BESCNAME=TURNIGY_AE_25A
call:compile
SET BESCNAME=TURNIGY_AE_30A
call:compile
SET BESCNAME=TURNIGY_AE_45A
call:compile
SET BESCNAME=TURNIGY_KFORCE_40A
call:compile
SET BESCNAME=TURNIGY_KFORCE_70A_HV
call:compile
SET BESCNAME=TURNIGY_KFORCE_120A_HV
call:compile
SET BESCNAME=TURNIGY_KFORCE_120A_HV_V2
call:compile
SET BESCNAME=SKYWALKER_20A
call:compile
SET BESCNAME=SKYWALKER_40A
call:compile
SET BESCNAME=HIMODEL_COOL_22A
call:compile
SET BESCNAME=HIMODEL_COOL_33A
call:compile
SET BESCNAME=HIMODEL_COOL_41A
call:compile
SET BESCNAME=RCTIMER_6A
call:compile
SET BESCNAME=ALIGN_RCE_BL15X
call:compile
SET BESCNAME=ALIGN_RCE_BL15P
call:compile
SET BESCNAME=ALIGN_RCE_BL35X
call:compile
SET BESCNAME=ALIGN_RCE_BL35P
call:compile
SET BESCNAME=GAUI_GE_183_18A
call:compile
SET BESCNAME=H_KING_10A
call:compile
SET BESCNAME=H_KING_20A
call:compile
SET BESCNAME=H_KING_35A
call:compile
SET BESCNAME=H_KING_50A
call:compile
SET BESCNAME=POLARIS_THUNDER_12A
call:compile
SET BESCNAME=POLARIS_THUNDER_20A
call:compile
SET BESCNAME=POLARIS_THUNDER_30A
call:compile
SET BESCNAME=POLARIS_THUNDER_40A
call:compile
SET BESCNAME=POLARIS_THUNDER_60A
call:compile
SET BESCNAME=POLARIS_THUNDER_80A
call:compile
SET BESCNAME=POLARIS_THUNDER_100A
call:compile
SET BESCNAME=PLATINUM_PRO_30A
call:compile
SET BESCNAME=PLATINUM_PRO_150A
call:compile
SET BESCNAME=PLATINUM_50AV3
call:compile
SET BESCNAME=EAZY_3AV2
call:compile
SET BESCNAME=TAROT_30A
call:compile
SET BESCNAME=SKYIII_30A
call:compile
SET BESCNAME=EMAX_20A
call:compile
SET BESCNAME=EMAX_40A
call:compile
SET BESCNAME=XROTOR_10A
call:compile
SET BESCNAME=XROTOR_20A
call:compile
SET BESCNAME=XROTOR_40A
call:compile
SET BESCNAME=MDRX62H
call:compile
SET BESCNAME=ROTORGEEKS_20A
call:compile
SET BESCNAME=FLYCOLOR_FAIRY_6A
call:compile
SET BESCNAME=FLYCOLOR_FAIRY_30A
call:compile
SET BESCNAME=FVT_LITTLEBEE_20A
call:compile

goto :end


:compile
SET BESC="%BESCNAME%_MAIN"
SET /A BESCNO+=1
call :compile2
SET BESC="%BESCNAME%_TAIL"
SET /A BESCNO+=1
call:compile2
SET BESC="%BESCNAME%_MULTI"
SET /A BESCNO+=1
call:compile2
goto :eof

:compile2
@ECHO compiling %BESC%  
@ECHO. >> MakeHex_Result.txt
@ECHO ********************************************************************  >> MakeHex_Result.txt
@ECHO %BESCNAME%  >> MakeHex_Result.txt
@ECHO ********************************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESCNO=%BESCNO%) OBJECT(Output\%BESCNAME%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCNAME%_%Revision%.OBJ"  TO(Output\%BESCNAME%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCNAME%_%Revision%.OMF" >> MakeHex_Result.txt 
copy "Output\%BESCNAME%_%Revision%.HEX" "Output\Hex\%BESC%_%Revision%.HEX" > nul
del "Output\%BESCNAME%_%Revision%.HEX" > nul
@ECHO. >> MakeHex_Result.txt
goto :eof

:end

@pause
exit