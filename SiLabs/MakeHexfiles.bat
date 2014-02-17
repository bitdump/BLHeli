@ECHO off
@ECHO ***** Batch file for BlHeli (from 4712)  v.1.1          *****
@ECHO ***** All Messages will be saved to MakeHex_Result.txt *****
@ECHO ***** Start compile with any key  - CTRL-C to abort    *****
Break ON
@pause

rem ***** adapt settings to your enviroment ****
DEL Output\Hex\*.* /Q
RMDIR Output\Hex
DEL Output\*.* /Q
RMDIR Output
MKDIR Output
MKDIR Output\Hex
SET Revision=Rev11_2
SET SilabsPath=C:\SiLabs
SET RaisonancePath=C:\Raisonance

@ECHO ***** Result of Batch file for BlHeli (from 4712) v.1.1       ***** > MakeHex_Result.txt
@ECHO Revision: %Revision% >> MakeHex_Result.txt
@ECHO Path for Silabs IDE: %SilabsPath% >> MakeHex_Result.txt
@ECHO Path for Raisonance IDE: %RaisonancePath% >> MakeHex_Result.txt
@ECHO Start compile >> MakeHex_Result.txt

@ECHO Revision: %Revision%
@ECHO Path for Silabs IDE: %SilabsPath%
@ECHO Path for Raisonance IDE: %RaisonancePath%
@ECHO Start compile .....

rem **** no changes anymore *********************
rem XP_3A_MAIN   	 				1
rem XP_3A_TAIL 		 				2
rem XP_3A_MULTI 					3
rem XP_7A_MAIN 		 				4
rem XP_7A_TAIL 		 				5
rem XP_7A_MULTI 					6
rem XP_7A_Fast_MAIN 				7
rem XP_7A_Fast_TAIL 	 			8
rem XP_7A_Fast_MULTI 				9
rem XP_12A_MAIN 	 				10
rem XP_12A_TAIL 	 				11
rem XP_12A_MULTI 	 				12
rem XP_18A_MAIN 	 				13
rem XP_18A_TAIL 	 				14
rem XP_18A_MULTI 	 				15
rem XP_25A_MAIN 	 				16
rem XP_25A_TAIL 	 				17
rem XP_25A_MULTI 	 				18
rem XP_35A_SW_MAIN 	 				19
rem XP_35A_SW_TAIL 	 				20
rem XP_35A_SW_MULTI 	 			21
rem DP_3A_MAIN	 	 				22
rem DP_3A_TAIL  	 				23
rem DP_3A_MULTI  	 				24
rem Supermicro_3p5A_MAIN 			25
rem Supermicro_3p5A_TAIL 			26  
rem Supermicro_3p5A_MULTI 			27  
rem Turnigy_Plush_6A_MAIN  			28
rem Turnigy_Plush_6A_TAIL  			29  
rem Turnigy_Plush_6A_MULTI  		30 
rem Turnigy_Plush_10A_MAIN  		31
rem Turnigy_Plush_10A_TAIL  		32  
rem Turnigy_Plush_10A_MULTI  		33 
rem Turnigy_Plush_12A_MAIN  		34
rem Turnigy_Plush_12A_TAIL  		35  
rem Turnigy_Plush_12A_MULTI  		36 
rem Turnigy_Plush_18A_MAIN  		37
rem Turnigy_Plush_18A_TAIL  		38 
rem Turnigy_Plush_18A_MULTI  		39 
rem Turnigy_Plush_25A_MAIN  		40
rem Turnigy_Plush_25A_TAIL  		41  
rem Turnigy_Plush_25A_MULTI  		42 
rem Turnigy_Plush_30A_MAIN  		43
rem Turnigy_Plush_30A_TAIL  		44  
rem Turnigy_Plush_30A_MULTI  		45 
rem Turnigy_Plush_40A_MAIN  		46
rem Turnigy_Plush_40A_TAIL  		47  
rem Turnigy_Plush_40A_MULTI  		48 
rem Turnigy_Plush_60A_MAIN  		49
rem Turnigy_Plush_60A_TAIL  		50  
rem Turnigy_Plush_60A_MULTI  		51 
rem Turnigy_Plush_80A_MAIN  		52
rem Turnigy_Plush_80A_TAIL  		53  
rem Turnigy_Plush_80A_MULTI  		54 
rem Turnigy_Plush_Nfet_18A_MAIN  	55
rem Turnigy_Plush_Nfet_18A_TAIL  	56 
rem Turnigy_Plush_Nfet_18A_MULTI  	57 
rem Turnigy_Plush_Nfet_25A_MAIN  	58
rem Turnigy_Plush_Nfet_25A_TAIL  	59  
rem Turnigy_Plush_Nfet_25A_MULTI  	60 
rem Turnigy_Plush_Nfet_30A_MAIN  	61
rem Turnigy_Plush_Nfet_30A_TAIL  	62  
rem Turnigy_Plush_Nfet_30A_MULTI  	63 
rem Turnigy_AE_20A_MAIN  			64
rem Turnigy_AE_20A_TAIL  			65  
rem Turnigy_AE_20A_MULTI  			66 
rem Turnigy_AE_25A_MAIN  			67
rem Turnigy_AE_25A_TAIL  			68  
rem Turnigy_AE_25A_MULTI  			69 
rem Turnigy_AE_30A_MAIN  			70
rem Turnigy_AE_30A_TAIL  			71  
rem Turnigy_AE_30A_MULTI  			72 
rem Turnigy_AE_45A_MAIN  			73
rem Turnigy_AE_45A_TAIL  			74  
rem Turnigy_AE_45A_MULTI  			75
rem Turnigy_KForce_40A_Main 		76   
rem Turnigy_KForce_40A_Tail 		77   
rem Turnigy_KForce_40A_Multi 		78   
rem Turnigy_KForce_70A_HV_Main 		79   
rem Turnigy_KForce_70A_HV_Tail 		80   
rem Turnigy_KForce_70A_HV_Multi 	81    
rem Turnigy_KForce_120A_HV_Main 	82   
rem Turnigy_KForce_120A_HV_Tail 	83   
rem Turnigy_KForce_120A_HV_Multi 	84    
rem Turnigy_KForce_120A_HV_v2_Main 	85  
rem Turnigy_KForce_120A_HV_v2_Tail 	86   
rem Turnigy_KForce_120A_HV_v2_Multi 87    
rem Skywalker_12A_MAIN  			88
rem Skywalker_12A_TAIL  			89  
rem Skywalker_12A_MULTI  			90 
rem Skywalker_20A_MAIN  			91
rem Skywalker_20A_TAIL  			92  
rem Skywalker_20A_MULTI  			93 
rem Skywalker_40A_MAIN  			94
rem Skywalker_40A_TAIL  			95  
rem Skywalker_40A_MULTI  			96 
rem HiModel_Cool_22A_MAIN  			97
rem HiModel_Cool_22A_TAIL  			98  
rem HiModel_Cool_22A_MULTI  		99
rem HiModel_Cool_33A_MAIN  			100
rem HiModel_Cool_33A_TAIL  			101 
rem HiModel_Cool_33A_MULTI  		102
rem HiModel_Cool_41A_MAIN  			103
rem HiModel_Cool_41A_TAIL  			104 
rem HiModel_Cool_41A_MULTI  		105
rem RCTimer_6A_MAIN  				106
rem RCTimer_6A_TAIL  				107
rem RCTimer_6A_MULTI  				108
rem Align_RCE_BL15X_Main			109  
rem Align_RCE_BL15X_Tail 			110  
rem Align_RCE_BL15X_Multi 			111  
rem Align_RCE_BL15P_Main			112  
rem Align_RCE_BL15P_Tail 			113  
rem Align_RCE_BL15P_Multi 			114  
rem Align_RCE_BL35X_Main			115  
rem Align_RCE_BL35X_Tail 			116  
rem Align_RCE_BL35X_Multi 			117  
rem Align_RCE_BL35P_Main			118   
rem Align_RCE_BL35P_Tail 			119  
rem Align_RCE_BL35P_Multi 			120  
rem Gaui_GE_183_18A_Main			121   
rem Gaui_GE_183_18A_Tail			122  
rem Gaui_GE_183_18A_Multi 			123  
rem H_King_10A_MAIN  				124 
rem H_King_10A_TAIL  				125
rem H_King_10A_MULTI  				126
rem H_King_20A_MAIN  				127
rem H_King_20A_TAIL  				128
rem H_King_20A_MULTI  				129
rem H_King_35A_MAIN  				130
rem H_King_35A_TAIL  				131
rem H_King_35A_MULTI  				132
rem H_King_50A_MAIN  				133
rem H_King_50A_TAIL  				134
rem H_King_50A_MULTI  				135
rem Polaris_Thunder_12A_Main		136
rem Polaris_Thunder_12A_Tail 		137  
rem Polaris_Thunder_12A_Multi 		138  
rem Polaris_Thunder_20A_Main		139   
rem Polaris_Thunder_20A_Tail 		140  
rem Polaris_Thunder_20A_Multi 		141  
rem Polaris_Thunder_30A_Main		142   
rem Polaris_Thunder_30A_Tail 		143  
rem Polaris_Thunder_30A_Multi 		144  
rem Polaris_Thunder_40A_Main		145   
rem Polaris_Thunder_40A_Tail 		146  
rem Polaris_Thunder_40A_Multi 		147  
rem Polaris_Thunder_60A_Main		148   
rem Polaris_Thunder_60A_Tail 		149  
rem Polaris_Thunder_60A_Multi 		150  
rem Polaris_Thunder_80A_Main		151   
rem Polaris_Thunder_80A_Tail 		152  
rem Polaris_Thunder_80A_Multi 		153  
rem Polaris_Thunder_100A_Main		154   
rem Polaris_Thunder_100A_Tail 		155  
rem Polaris_Thunder_100A_Multi 		156  
rem Platinum_Pro_30A_Main			157
rem Platinum_Pro_30A_Tail 			158  
rem Platinum_Pro_30A_Multi 			159  
rem EAZY_3Av2_Main					160
rem EAZY_3Av2_Tail					161 
rem EAZY_3Av2_Multi					162 
rem Tarot_30A_Main					163   
rem Tarot_30A_Tail 					164  
rem Tarot_30A_Multi 				165
rem SkyIII_30A_Main				166   
rem SkyIII_30A_Tail 				167  
rem SkyIII_30A_Multi 				168

SET BESCTYPE=XP_3A_MAIN
SET BESC=1
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_3A_TAIL
SET BESC=2
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_3A_MULTI
SET BESC=3
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_7A_MAIN
SET BESC=4
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_7A_TAIL
SET BESC=5
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_7A_MULTI
SET BESC=6
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_7A_Fast_MAIN
SET BESC=7
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_7A_Fast_TAIL
SET BESC=8
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_7A_Fast_MULTI
SET BESC=9
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_12A_MAIN
SET BESC=10
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_12A_TAIL
SET BESC=11
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_12A_MULTI
SET BESC=12
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_18A_MAIN
SET BESC=13
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_18A_TAIL
SET BESC=14
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_18A_MULTI
SET BESC=15
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_25A_MAIN
SET BESC=16
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_25A_TAIL
SET BESC=17
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_25A_MULTI
SET BESC=18
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_35A_SW_MAIN
SET BESC=19
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_35A_SW_TAIL
SET BESC=20
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=XP_35A_SW_MULTI
SET BESC=21
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=DP_3A_MAIN
SET BESC=22
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=DP_3A_TAIL
SET BESC=23
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=DP_3A_MULTI
SET BESC=24
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Supermicro_3p5A_MAIN
SET BESC=25
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Supermicro_3p5A_TAIL
SET BESC=26
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Supermicro_3p5A_MULTI
SET BESC=27
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_6A_MAIN
SET BESC=28
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_6A_TAIL
SET BESC=29
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_6A_MULTI
SET BESC=30
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_10A_MAIN
SET BESC=31
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_10A_TAIL
SET BESC=32
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_10A_MULTI
SET BESC=33
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_12A_MAIN
SET BESC=34
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_12A_TAIL
SET BESC=35
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_12A_MULTI
SET BESC=36
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_18A_MAIN
SET BESC=37
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_18A_TAIL
SET BESC=38
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_18A_MULTI
SET BESC=39
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_25A_MAIN
SET BESC=40
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_25A_TAIL
SET BESC=41
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_25A_MULTI
SET BESC=42
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_30A_MAIN
SET BESC=43
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_30A_TAIL
SET BESC=44
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_30A_MULTI
SET BESC=45
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_40A_MAIN
SET BESC=46
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_40A_TAIL
SET BESC=47
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_40A_MULTI
SET BESC=48
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_60A_MAIN
SET BESC=49
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_60A_TAIL
SET BESC=50
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_60A_MULTI
SET BESC=51
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_80A_MAIN
SET BESC=52
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_80A_TAIL
SET BESC=53
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_80A_MULTI
SET BESC=54
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_Nfet_18A_MAIN
SET BESC=55
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_Nfet_18A_TAIL
SET BESC=56
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_Nfet_18A_MULTI
SET BESC=57
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_Nfet_25A_MAIN
SET BESC=58
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_Nfet_25A_TAIL
SET BESC=59
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_Nfet_25A_MULTI
SET BESC=60
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_Nfet_30A_MAIN
SET BESC=61
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_Nfet_30A_TAIL
SET BESC=62
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_Plush_Nfet_30A_MULTI
SET BESC=63
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_20A_MAIN
SET BESC=64
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_20A_TAIL
SET BESC=65
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_20A_MULTI
SET BESC=66
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_25A_MAIN
SET BESC=67
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_25A_TAIL
SET BESC=68
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_25A_MULTI
SET BESC=69
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_30A_MAIN
SET BESC=70
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_30A_TAIL
SET BESC=71
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_30A_MULTI
SET BESC=72
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_45A_MAIN
SET BESC=73
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_45A_TAIL
SET BESC=74
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_AE_45A_MULTI
SET BESC=75
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_40A_Main 
SET BESC=76
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_40A_Tail
SET BESC=77
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_40A_Multi 
SET BESC=78
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_70A_HV_Main
SET BESC=79
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_70A_HV_TAIL
SET BESC=80
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_70A_HV_MULTI
SET BESC=81
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%
  
SET BESCTYPE=Turnigy_KForce_120A_HV_Main
SET BESC=82
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_120A_HV_TAIL
SET BESC=83
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_120A_HV_MULTI
SET BESC=84
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%
  
SET BESCTYPE=Turnigy_KForce_120A_HV_v2_Main
SET BESC=85
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_120A_HV_v2_TAIL
SET BESC=86
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Turnigy_KForce_120A_HV_v2_MULTI
SET BESC=87
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%
  
SET BESCTYPE=Skywalker_12A_MAIN
SET BESC=88
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
  @ECHO %BESCTYPE%

SET BESCTYPE=Skywalker_12A_TAIL
SET BESC=89
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Skywalker_12A_MULTI
SET BESC=90
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Skywalker_20A_MAIN
SET BESC=91
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
  @ECHO %BESCTYPE%

SET BESCTYPE=Skywalker_20A_TAIL
SET BESC=92
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Skywalker_20A_MULTI
SET BESC=93
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Skywalker_40A_MAIN
SET BESC=94
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Skywalker_40A_TAIL
SET BESC=95
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Skywalker_40A_MULTI
SET BESC=96
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=HiModel_Cool_22A_MAIN
SET BESC=97
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=HiModel_Cool_22A_TAIL
SET BESC=98
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=HiModel_Cool_22A_MULTI
SET BESC=99
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=HiModel_Cool_33A_MAIN
SET BESC=100
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=HiModel_Cool_33A_TAIL
SET BESC=101
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=HiModel_Cool_33A_MULTI
SET BESC=102
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=HiModel_Cool_41A_MAIN
SET BESC=103
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=HiModel_Cool_41A_TAIL
SET BESC=104
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=HiModel_Cool_41A_MULTI
SET BESC=105
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=RCTimer_6A_MAIN
SET BESC=106
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=RCTimer_6A_TAIL
SET BESC=107
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=RCTimer_6A_MULTI
SET BESC=108
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL15X_MAIN
SET BESC=109
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL15X_TAIL
SET BESC=110
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL15X_MULTI
SET BESC=111
@ECHO. >> MakeHex_Result.txt
@ECHO ******108**********************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL15P_MAIN
SET BESC=112
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL15P_TAIL
SET BESC=113
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL15P_MULTI
SET BESC=114
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL35X_MAIN
SET BESC=115
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL35X_TAIL
SET BESC=116
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL35X_MULTI
SET BESC=117
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL35P_MAIN
SET BESC=118
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL35P_TAIL
SET BESC=119
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Align_RCE_BL35P_MULTI
SET BESC=120
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Gaui_GE_183_18A_MAIN
SET BESC=121
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Gaui_GE_183_18A_TAIL
SET BESC=122
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Gaui_GE_183_18A_MULTI
SET BESC=123
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_10A_MAIN
SET BESC=124
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_10A_TAIL
SET BESC=125
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_10A_MULTI
SET BESC=126
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_20A_MAIN
SET BESC=127
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_20A_TAIL
SET BESC=128
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_20A_MULTI
SET BESC=129
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_35A_MAIN
SET BESC=130
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_35A_TAIL
SET BESC=131
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_35A_MULTI
SET BESC=132
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_50A_MAIN
SET BESC=133
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_50A_TAIL
SET BESC=134
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=H_King_50A_MULTI
SET BESC=135
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_12A_MAIN
SET BESC=136
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_12A_TAIL
SET BESC=137
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_12A_MULTI
SET BESC=138
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_20A_MAIN
SET BESC=139
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_20A_TAIL
SET BESC=140
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_20A_MULTI
SET BESC=141
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_30A_MAIN
SET BESC=142
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_30A_TAIL
SET BESC=143
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_30A_MULTI
SET BESC=144
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_40A_MAIN
SET BESC=145
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_40A_TAIL
SET BESC=146
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_40A_MULTI
SET BESC=147
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_60A_MAIN
SET BESC=148
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_60A_TAIL
SET BESC=149
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_60A_MULTI
SET BESC=150
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_80A_MAIN
SET BESC=151
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_80A_TAIL
SET BESC=152
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_80A_MULTI
SET BESC=153
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_100A_MAIN
SET BESC=154
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_100A_TAIL
SET BESC=155
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Polaris_Thunder_100A_MULTI
SET BESC=156
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Platinum_Pro_30A_MAIN
SET BESC=157
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Platinum_Pro_30A_TAIL
SET BESC=158
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Platinum_Pro_30A_MULTI
SET BESC=159
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=EAZY_3Av2_MAIN
SET BESC=160
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=EAZY_3Av2_TAIL
SET BESC=161
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=EAZY_3Av2_MULTI
SET BESC=162
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Tarot_30A_MAIN
SET BESC=163
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Tarot_30A_TAIL
SET BESC=164
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=Tarot_30A_MULTI
SET BESC=165
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=SkyIII_30A_MAIN
SET BESC=166
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=SkyIII_30A_TAIL
SET BESC=167
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

SET BESCTYPE=SkyIII_30A_MULTI
SET BESC=168
@ECHO. >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%  >> MakeHex_Result.txt
@ECHO *****************************************************  >> MakeHex_Result.txt
%RaisonancePath%\Ride\bin\ma51.exe "BLHeli.asm" SET(BESC=%BESC%) OBJECT(Output\%BESCTYPE%_%Revision%.OBJ) DEBUG EP QUIET PIN(%SilabsPath%\MCU\Inc;%RaisonancePath%\Ride\inc;%RaisonancePath%\Ride\inc\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\lx51.exe "Output\%BESCTYPE%_%Revision%.OBJ"  TO(Output\%BESCTYPE%_%Revision%.OMF) RS(256) PL(68) PW(78) OUTPUTSUMMARY LIBPATH(%RaisonancePath%\Ride\lib\51) >> MakeHex_Result.txt 
%RaisonancePath%\Ride\bin\oh51.exe "Output\%BESCTYPE%_%Revision%.OMF" >> MakeHex_Result.txt
copy "Output\%BESCTYPE%_%Revision%.HEX" "Output\Hex\*.*" > nul
del "Output\%BESCTYPE%_%Revision%.HEX" > nul
@ECHO *****************************************************  >> MakeHex_Result.txt
@ECHO %BESCTYPE%

