@ECHO on
rem ***** Batch file for BlHeli (from 4712) ****

rem ***** adapt settings to your enviroment ****
DEL Output\Hex\*.* /Q
RMDIR Output\Hex
DEL Output\*.* /Q
RMDIR Output
MKDIR Output
MKDIR Output\Hex
SET Revision=Rev4_1
SET SilabsPath=C:\SiLabs
SET RaisonancePath=C:\Raisonance
rem**** no changes anymore *********************

rem DP_3A_MAIN	 	 1
rem DP_3A_TAIL  	 2
rem Supermicro_3p5A_MAIN 3
rem Supermicro_3p5A_TAIL 4   
rem Turnigy6A_MAIN 	 5
rem Turnigy6A_TAIL 	 6   
rem XP_3A_MAIN 		 7
rem XP_3A_TAIL 		 8
rem XP_7A_MAIN 		 9
rem XP_7A_TAIL 		 10
rem XP_12A_MAIN 	 11
rem XP_12A_TAIL 	 12

SET BESCTYPE=DP_3A_MAIN
SET BESC=1
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"

SET BESCTYPE=DP_3A_TAIL
SET BESC=2
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"

SET BESCTYPE=Supermicro_3p5A_MAIN
SET BESC=3
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"

SET BESCTYPE=Supermicro_3p5A_TAIL
SET BESC=4
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"

SET BESCTYPE=Turnigy6A_MAIN
SET BESC=5
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"

SET BESCTYPE=Turnigy6A_TAIL
SET BESC=6
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"


SET BESCTYPE=XP_3A_MAIN
SET BESC=7
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"


SET BESCTYPE=XP_3A_TAIL
SET BESC=8
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"

SET BESCTYPE=XP_7A_MAIN
SET BESC=9
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"

SET BESCTYPE=XP_7A_TAIL
SET BESC=10
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"

SET BESCTYPE=XP_12A_MAIN
SET BESC=11
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"

SET BESCTYPE=XP_12A_TAIL
SET BESC=12
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) 

%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF"
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*"
del "Output\%BESCTYPE%_%Revision%.HEX"


@Echo OFF
SET SilabsPath=
SET RaisonancePath=
SET BESCTYPE=
SET BESC=