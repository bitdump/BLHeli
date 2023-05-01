# BLHeli_32 info page  

## BLHeli_32 MCUs 
BLHeli_32 supports a variety of MCUs, in order to maximize performance and also to handle the current chip shortage.  
Unfortunately there is inaccurate and misleading information relating to this circulating in various media.

So to clarify:  
All BLHeli_32 MCUs (F0, F3, F4, G0 etc) support the "ByRPM" feature, with Rev32.9 code.  
All BLHeli_32 MCUs (F0, F3, F4, G0 etc) support "any" pwm frequency range.  
The supported range is determined by the hardware manufacturer, based upon choice of fets, driver capacitors etc.

## BLHeli_32 downloads  

You can find BLHeliSuite32 here:
https://github.com/bitdump/BLHeli/releases

Or here:
https://drive.google.com/drive/folders/1Y1bUMnRRolmMD_lezL0FYd3aMBrNzCig   
or here:   
https://www.mediafire.com/folder/dx6kfaasyo24l/BLHeliSuite   
And the Android APP on Google Play:   
https://play.google.com/store/apps/details?id=org.blheli.BLHeli_32  
For users in regions where Google is not available, you can download the ".apk" file in the  
"BLHeli_32 Android APP" folder to your phone or tablet and open it. This will install the APP.  

## BLHeli_32 manual

You can find the manual in the link above: BLHeli_32 manual ARM Rev32.x.pdf

## Test code

Rev32.8.9 testcode is published in the folder "Loaded startup testcode".
This testcode has optimizations for starting motors that are loaded, like is often the case for thrusters or cars.

Rev32.9.3 testcode is published in the folder "Dshot extended telemetry testcode".
- Added support for extended dshot telemetry   
  Temp, volt, curr data now available over bidirectional dshot signal   
- Reduced ESC and motor stresses during stall conditions   
  Timeout before shutting off power is reduced   
- Added protection against unintentional spoolups   
  Input signal is qualified for 200ms before starting, and during the first 5s of running, signal timeout is only 40ms (vs generally 320ms)   
  Input signal loss does not lead to new detection of signal type (unless input line is held high more than 2 seconds so bootloader is entered)   
  So when changing input signal type, the ESC must be power cycled for it to take effect   
- Some small changes to make thrust vs rpm more linear   
  Primarily for static or quasi-static load conditions   
- Some smaller fixes   

## Discussion threads

For more information, check out these threads:  
https://www.rcgroups.com/forums/showthread.php?2864611 (for BLHeli_32)  
https://www.rcgroups.com/forums/showthread.php?3143134 (for the BLHeli_32 Android APP)  
