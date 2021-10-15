# BLHeli_32 info page  

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

Rev32.8.2 testcode is published in the folder "Rev32.8.2 testcode"
Note that the testcode requires BLHeliSuite32 Rev32.8.1.1 or higher. 
- This code has a greatly reduced noise level in the Dshot real time erpm data.
  Which will improve the performance of Betaflight dynamic filtering, 
  as well as provide more accurate data in applications where the data is used directly.
- The code also has a tweak to the relaxed stall protection mode.
  Now there is no boost on startup for this mode. So if you are flying with really low throttle
  and the motors stop e.g. due to reverse flow, then they will just gently start up again on the low throttle.
- A new setting for damag compensation is added, called "Very High".
  Motor manufacturers tend to push demag times up, and this setting can handle very long demag times.
  But, it handles long demag times by reducing power. So for motors with long demag times, full power can be reduced.
- A new setting for low rpm power protect is added, called "On Adaptive".
  This setting is intended for large low kV motors running on a fairly low battery voltage.
  But it can be used, and is indeed suitable for any motor kV and battery voltage.
  In this mode, the code calculates the kV*voltage and adjusts the low rpm power protection accordingly.
- A new setting for pwm frequency high is added, called "By RPM".
  In this mode, motor pwm frequency is adjusted in a way that it stays away from problematic motor commutation frequencies.

The Rev32.8.2 testcode is now published as a pre-release here: https://github.com/bitdump/BLHeli/releases
You can download the hex file you need.

Feedback on this testcode will be greatly appreciated, the RCG BLHeli_32 thread below is well suited for it.
Feedback closes the loop of the process of continued improvement :).

Rev32.8.9 testcode is published in the folder "Loaded startup testcode"
This testcode has optimizations for starting motors that are loaded, like is often the case for thrusters or cars.

## Discussion threads

For more information, check out these threads:  
https://www.rcgroups.com/forums/showthread.php?2864611 (for BLHeli_32)  
https://www.rcgroups.com/forums/showthread.php?3143134 (for the BLHeli_32 Android APP)  
