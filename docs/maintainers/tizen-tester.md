# PlezyNG Samsung TV tester handoff

This is a **prebuilt experimental ARM TPK for Tizen 6–9**. You do not need
Flutter or a compiler. It contains the application, Flutter runtime, media
plugins, SQLite and SMB. It has been compiled and development-signed, but has
not been installed or played media on a Samsung TV.

Check the TV's actual Tizen version, model and firmware. The original 2021–2025
models span Tizen 6–9, but OS upgrades can change this. This build does not claim
support for 2026/Tizen 10 or TVs older than Tizen 6. Samsung's GCC 14.2 transition
requires a separate compatible build. x64 packages are for emulators, not TVs.

## Files

| File | Purpose |
| --- | --- |
| `PlezyNG-tizen-arm-tester.tpk` | Complete application; re-sign for your TV before installation. |
| `.tpk.sha256` and `.tpk.json` | Download digest, source revision, ABI and qualification status. |
| `package.py` and `toolchain.json` | Keep together; Python 3.11+ helper for inspection, re-signing and installation. |
| `pubspec-tizen.lock` | Exact resolved Dart dependencies for this build. |
| `*-native-sources.tar.gz` | Corresponding SQLite/SMB source and patches. |

The development signature is not a Samsung TV authorization. No private key,
Samsung login or device identity is included. Preserve your own Samsung author
certificate for updates: changing author identity may require an uninstall,
which deletes local app data.

## Option A: Apps2Samsung local package

[Apps2Samsung](https://github.com/Apps2Samsung/Apps2Samsung) supports custom local
native TPK files and manages Samsung signing/device certificates. Install it
from that project's official instructions, prepare Developer Mode and pair
the TV, then choose this local `.tpk` in its custom-package install flow. Let
the installer re-sign for the selected TV. Its exact screens vary by version.
This route is a candidate for testing; PlezyNG has not yet been installed
through it on hardware. There is no enabled PlezyNG community-catalogue entry.

Before handing the file to any installer, verify its SHA-256 against the supplied
checksum. On Linux: `sha256sum -c PlezyNG-tizen-arm-tester.tpk.sha256`; on macOS:
`shasum -a 256 -c PlezyNG-tizen-arm-tester.tpk.sha256`; on PowerShell:
`Get-FileHash .\PlezyNG-tizen-arm-tester.tpk -Algorithm SHA256` and compare the
result with the checksum file.

## Option B: Samsung SDK and the included helper

1. Follow Samsung's [TV connection guide](https://developer.samsung.com/smarttv/develop/getting-started/using-sdk/tv-device.html)
   to enable Developer Mode with the tester computer's IP and restart the TV.
   The computer and TV must be reachable on the local network.
2. Install Samsung's SDK tools with TV extension, Certificate Manager and Device
   Manager. Follow [Creating Certificates](https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/creating-certificates.html)
   to create a **Samsung TV** author/distributor profile with the TV's DUID.
   Complete any Device Manager “Permit to install applications” step required
   by that SDK/device. A generic Tizen/emulator profile is insufficient.
3. Add the SDK CLI (`tools/ide/bin`) and SDB (`tools`) to PATH. Confirm `tizen
   version`, `sdb devices` and `tizen security-profiles list`. Select an explicit
   Device Manager target and profile. Authenticate locally; do not share keys,
   passwords or DUIDs with the PlezyNG maintainers.
4. Extract the entire handoff into one directory. Use the supplied checksum
   value in the command below. On Windows, `py -3` can replace `python3`.

```sh
python3 package.py inspect PlezyNG-tizen-arm-tester.tpk --arch arm

python3 package.py resign PlezyNG-tizen-arm-tester.tpk --arch arm \
  --sha256 SHA256_FROM_THE_SUPPLIED_CHECKSUM_FILE \
  --security-profile YourSamsungTVProfile --output signed

python3 package.py install signed/PlezyNG-tizen-arm-signed.tpk --arch arm \
  --target YourDeviceManagerTarget --launch
```

These are shell examples; enter each as one line in PowerShell. `resign` changes
only signatures and checks that every application payload file is identical.
It refuses an existing signed output; choose a new directory for another attempt.
Re-signing was exercised with a second local development profile. Your Samsung
profile's certificate chain and DUID acceptance can only be tested on the TV.

## First device pass

Start with a small known-good H.264/AAC, 1080p-or-lower, stereo title and a media
server that permits transcoding. Plex uses conservative HLS transcoding even
at Original quality on this port. Jellyfin/Emby can directly play compatible
MP4/M4V or use HLS transcoding. HDR, surround passthrough, HEVC/AV1 and 4K are
not qualified. Books/PDFs and desktop-only MPV features are unavailable.

Record pass/fail and the exact error for each step:

| Check | Result |
| --- | --- |
| Install and launch; application ID `org.snapetech.plezyng` | |
| D-pad focus, Select, Back and text entry | |
| Log in to the intended server; token persists after app restart | |
| Browse library and start the test title; video aligns under controls | |
| Pause/resume, seek forward/back, stop/reopen and end of playback | |
| Audio/video sync; SRT/VTT subtitle on/off or server burn-in | |
| 20-minute playback and a second title | |
| Background/standby then resume; Wi-Fi interruption then recovery | |
| Optional SMB read, music queue and stored library state | |
| Update using the same Samsung author certificate | |

Report the source commit and TPK SHA-256, TV model, actual Tizen version,
firmware, installer/version, server type/version, test media codec/resolution
and results. Include the install/launch error or a short redacted log excerpt.
Exclude authentication tokens, private media URLs, certificate files and DUIDs.

Certificate/DUID errors need a Samsung TV profile and installation permission.
Wrong-architecture or loader errors need the model/OS and exact message; do not
try x64 packages on the TV. If playback is blank, first confirm the server
transcode starts and repeat with the simple H.264/AAC fixture. Hardware findings
determine the support matrix; a compiled build alone does not.
