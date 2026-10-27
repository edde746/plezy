# PlezyNG Samsung screensaver adapter

Vendored from pub.dev 2.0.0, with its archive digest in `UPSTREAM.json` and
upstream license retained. This version matches PlezyNG's pinned
`wakelock_plus_platform_interface`; newer releases require a newer interface.

Initialize the optional native function pointer to null and return a platform
error when the screensaver API is absent instead of calling a null or
uninitialized pointer. Release the timer/library on plugin destruction and
clear timer state when its callback cancels itself. Native compilation and
screensaver behavior require the Samsung SDK/device qualification.
