import Foundation
import Libmpv

/// Audio-only mpv core for music playback.
///
/// Reuses [MpvPlayerCoreBase]'s context/event/property machinery (all of it
/// instance-scoped) but never touches a render surface: video decoding is
/// disabled outright, embedded cover art must not surface as a video track
/// (`audio-display=no`), and none of the display-criteria/EDR/PiP paths apply.
/// Lives alongside — and independently of — the video core, so it can be
/// created and destroyed repeatedly regardless of the video plugin's state.
class MpvAudioPlayerCore: MpvPlayerCoreBase {

  private var isDisposed = false

  func initialize() -> Bool {
    guard !isInitialized else {
      print("[MpvAudioPlayerCore] Already initialized")
      return true
    }

    let created = createMpvContext { [self] in
      guard let mpv else { return }
      checkError(mpv_set_option_string(mpv, "vid", "no"))
      // Critical: without this, embedded cover art is exposed as a video
      // track and mpv would try to present it.
      checkError(mpv_set_option_string(mpv, "audio-display", "no"))
      checkError(mpv_set_option_string(mpv, "force-window", "no"))
      // Gapless track transitions when the next playlist entry matches the
      // current audio format (the Dart side arms it via `loadfile append`).
      checkError(mpv_set_option_string(mpv, "gapless-audio", "weak"))
      // Match the video core: hold the final track at EOF (eof-reached flips
      // true) instead of unloading, so Dart's completed handling still works.
      checkError(mpv_set_option_string(mpv, "keep-open", "yes"))
    }
    guard created else { return false }

    isInitialized = true
    print("[MpvAudioPlayerCore] Initialized successfully")
    return true
  }

  func dispose() {
    // Guard double-dispose: the plugin calls dispose() then drops the strong
    // ref, which fires deinit → dispose() again (same pattern as the video
    // cores).
    guard !isDisposed else { return }
    isDisposed = true

    disposeSharedState(destroySynchronously: false)
    isInitialized = false
    print("[MpvAudioPlayerCore] Disposed")
  }

  deinit {
    dispose()
  }
}
