# Isolated Apple Dolby Vision host

This host exercises pinned AetherEngine's optional dual-layer VideoToolbox/Metal
path. It is separate from PlezyNG's release player and defaults to compatibility
playback. Enable the FEL switch before loading a source to request reconstruction.

See the [platform buildout guide](../../docs/maintainers/dv-platform-buildout.md#apple-experiment)
for source build, macOS run, iOS/tvOS signing, evidence requirements and the remaining
production integration work. The source lock lives in
[`../dv-engine/adapters.lock.json`](../dv-engine/adapters.lock.json).

No copyrighted test media, private signing material or binary engines are committed
here. An active route label reports an engine decision, not a verified FEL result.
