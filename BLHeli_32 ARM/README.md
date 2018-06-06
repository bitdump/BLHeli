Posted here in the "Rev32.42 hex files" directory, is BLHeli_32 test code Rev32.42 (interpret as Rev32.4.2)

The code has the following new fuctionality
- Added a sine modulation mode option
  This mode is a hybrid between sine operation and trapezoidal block commutation.
  It can make motors run slightly smoother and slightly more effective.
- Added bidirectional soft mode option
  In this mode, bidirectional operation works just like regular operation.
  The "old" bidirectional mode (intended for copter 3D operation) is now called bidirectional 3D.
- Added autonomous telemetry option
  When selected, telemetry frames will be sent every 32ms, regardless of requests from the input signal.
- Activated hardware noise filter on the signal input
  This can help filter out noise in very noisy environments or situations

Some fixes:
- Frequent CRC errors on telemetry frames shall now be fixed.
- The occasional undesired rotations when stopping in bidirectional mode is fixed.

You can find BLHeliSuite32 as usual here:
https://www.mediafire.com/folder/dx6kfaasyo24l/BLHeliSuite