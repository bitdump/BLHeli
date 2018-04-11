Posted here in the "Rev32.41 hex files" directory, is BLHeli_32 test code Rev32.41 (interpret as Rev32.4.1)

The code has the following new fuctionality
- Added a sine modulation mode option
  This mode is a hybrid between sine operation and tapezoidal block commutation.
  It can make motors run slightly smoother and slightly more effective.
- Added autonomous telemetry option
  When selected, telemetry frames will be sent every 32ms, regardless of requests from the input signal.
- Added bidirectional soft mode option
  In this mode, bidirectional operation works just like regular operation.
  The "old" bidirectional mode (intended for copter 3D operation) is now called bidirectional 3D.

Some fixes:
- Frequent CRC errors on telemetry frames shall now be fixed.
- The occasional undesired rotations when stopping in bidirectional mode is fixed.

You can find BLHeliSuite32 as usual here:
https://www.mediafire.com/folder/dx6kfaasyo24l/BLHeliSuite