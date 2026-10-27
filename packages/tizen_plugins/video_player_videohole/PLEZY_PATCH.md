# PlezyNG Samsung media adapter

Vendored from the pub.dev 0.6.2 archive recorded in `UPSTREAM.json`. The
upstream license, native sources, third-party notices and wrapper libraries
are retained. Examples and upstream development-only files are omitted.

Local fixes:

- Await shared platform initialization so native failures reach the caller.
- Always release the creation barrier when platform initialization/creation
  fails; otherwise disposing a failed open can hang forever.
- Make disposal idempotent and always unregister the lifecycle observer,
  including native-dispose failures; never dispose an unallocated player ID.
- Stop the geometry frame callback after unmount; keep the controller listener
  until disposal so deactivate/reactivate does not silently lose it.
- Remove source and license URL logging from native code.

`test/mpv/player_tizen_test.dart` exercises failure/retry, repeated disposal,
surface unmounting and playback lifecycle through the real Dart controller
with a fake platform. SDK compilation and Samsung hardware tests are still
required; the retained upstream wrapper libraries are not newly built here.
