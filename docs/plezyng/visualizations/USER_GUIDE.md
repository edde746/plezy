# Using the visualizer library

Open Now Playing, enable the visualizer, then choose the library button. The six original scenes remain available on their existing platforms. Native preset playback is an optional, currently unqualified Linux integration; it needs the patched mpv/projectM dependencies described in `native/visualizer/README.md`. Existing shipped binaries have not been replaced by this PR.

## Get presets

The Downloads section offers the authored CC0 MilkRust sample pack. Installation verifies the pinned archive and its contents before making the directory active. Cancel stops installation even if the transfer has finished and verification is still running. Retry starts a fresh transfer. When a future app catalog pins a newer version, Download update keeps previous complete versions available in Installed presets.

Use Import .milk or .milk2 for loose files, or Import .rmpack for a packaged collection with its integrity index, provenance and license notices. Files stay on the device and work offline. A `.milk2` import is stored for future engine support; this renderer cannot play it. Historical collections with unresolved redistribution status have source links rather than app-hosted downloads.

## Choose and organize

Choose Browse installed presets, search by title/author/pack/tag, and select a classic `.milk` entry. If the native dependency or playback audio is unavailable, the browser shows the reason and still offers metadata and notices. The details button shows author, license and content notice. Visual fidelity has not yet been measured for these entries.

Favorites and display choices belong to the active profile. Filter a list, save it under a playlist name, and use its reorder menu to move entries up or down. Selecting a preset uses the visible playable list for previous/next and shuffle. Playlists can be imported/exported as bounded JSON containing library-relative references. They do not include preset artwork; missing references require separately installing or importing the corresponding pack.

## Playback controls

The options menu provides Original scenes, preset lock, shuffle, automatic-change interval, transition duration, lower resolution, reload and fullscreen. Lock prevents timed changes. In fullscreen, left/right changes the preset, Escape or Exit fullscreen closes the view, and music continues. Fullscreen reuses the same renderer.

Native rendering pauses with music, backgrounding, a hidden view, or reduced motion. Presets may contain rapid flashes or intense movement. When a preset fails or fresh audio is unavailable, the original scene appears with the status reason; Reload retries with a new worker after an engine failure.

Remove a pack or loose import in the library manager. Removing a pinned pack removes its installed versions; playlist references can remain and are skipped when their files are missing. Downloading or importing files does not alter the six original scenes.

## Current limits

The Linux integration uses native pixel-buffer readback at up to 1280×720 and about 30 FPS; performance and driver behavior have not been qualified. Native hosts for other platforms, a complete custom MilkRust renderer, full shader/`.milk2` fidelity, signed remote catalog updates, broader cleared community packs, previews and physical-device validation remain open. The implementation status document records the complete remaining gates.
