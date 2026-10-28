# Apple MusicKit setup

Status: an iOS-only catalog search and playback pilot is implemented in the existing Links flow. It is disabled by default and falls back to the existing Apple Music handoff until the native target is configured and qualified.

## Apple configuration

1. Enable MusicKit for PlezyNG's iOS App ID in the Apple Developer account, use a matching signing profile in Xcode, and complete Apple's current MusicKit setup for the app.
2. Keep `NSAppleMusicUsageDescription` in the iOS app's Info.plist. The app uses it to explain that users can search selected catalog results and play them in Apple's native player.
3. Build with `--dart-define=ENABLE_APPLE_MUSICKIT=true` after the App ID and signing configuration are ready.
4. On the device, the user grants MusicKit access. Catalog playback is enabled only if Apple's current subscription capability allows it.

The native bridge searches the Apple Music catalog, shows selectable track results inside the existing music Links screen, and plays the chosen catalog song through `ApplicationMusicPlayer`. It never extracts or imports protected audio. Before launching the selected Apple Music track, PlezyNG stops an active PlezyNG music session so two app audio owners do not compete.

## Boundaries

- The pilot is iOS-only. Other platforms keep their existing Apple Music website/app handoff.
- Apple's catalog/account is the authority for subscription, storefront, track availability and playback rights.
- MusicKit playback has a native Apple player/session owner. It is not written into Plex/Jellyfin/Emby progress, tracker history, offline downloads or the local file library.
- The user can stop playback from the Apple Music row while the Links screen remains open. Apple MusicKit also exposes native system media controls.
- This feature does not use affiliate links or imply a revenue share. Apple's Performance Partners program is a separate commercial handoff opportunity.
- Keep the feature flag disabled until a signed iOS build has passed authorization, subscription, playback, audio interruption, background, profile-switch and account-revocation checks on a real device.

## Evidence and qualification

Apple documents MusicKit authorization, its purpose string, subscription capability checks, catalog search, and both native player types. A build flag is not Apple approval or device qualification. The current code has not been built or tested on an Apple device in this work branch. See the [source register](SOURCES.md#s34) for the official references.
