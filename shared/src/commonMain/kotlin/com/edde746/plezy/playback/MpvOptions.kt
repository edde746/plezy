package com.edde746.plezy.playback

/**
 * mpv's `volume-max`: 100 is unity gain, the rest up to this amplifies ([PlayerEngine.setVolume]'s range). The player's
 * controls go up to the `max_volume` setting (`PlayerChoices.maxVolume`).
 */
const val VOLUME_MAX = 130.0

/** How often an engine reads [EngineState.stats] while they are wanted ([PlayerEngine.setStatsWanted]). */
const val STATS_INTERVAL_MS = 500L

/**
 * mpv's `screenshot-directory` on the desktop and the Mac (Windows, Linux, macOS): the player's screenshots go to the
 * user's pictures, not mpv's working directory. Phones and TVs keep their engine's own place (iPhone and iPad: the
 * app's Documents).
 */
const val DESKTOP_SCREENSHOT_DIRECTORY = "~/Pictures"

/**
 * The mpv options every engine sets, on every platform, before its own and before `mpv_initialize`.
 * libmpv's own `[libmpv]` profile (mpv's `etc/builtin.conf`) already turns off config files, the terminal, mpv's input
 * bindings and the OSC everywhere; platform options (`vo`, `ao`, `hwdec-*`, `gpu-*`, HDR, subtitle fonts) stay in each
 * engine.
 *
 * mpv's other builtin scripts are all off: the app uses none, and each is a Lua state and thread of its own in every
 * player.
 * ytdl_hook hooks every load, with nothing to resolve in a resolved stream URL; auto_profiles, at its default `auto`,
 * hooks the load and exits for want of a conditional profile, so a file opening meanwhile logs "client removed during
 * hook handling". Their options exist only in a libmpv with Lua (Android's, Windows', Linux's and macOS's, not iOS' or
 * tvOS'), `load-scripts` only in one with some scripting: the Apple engine skips the options its libmpv doesn't know.
 */
val COMMON_MPV_OPTIONS: Map<String, String> = linkedMapOf(
    // Pause on the last frame at the end instead of unloading, so the end is a state and a seek after it works.
    "keep-open" to "yes",
    "volume-max" to VOLUME_MAX.toString(),
    // The app keeps the display awake by the player's rule (PlatformPlayback.keepDisplayAwake), not mpv's.
    "stop-screensaver" to "no",
    "ytdl" to "no",
    "load-stats-overlay" to "no",
    "load-console" to "no",
    "load-auto-profiles" to "no",
    "load-select" to "no",
    "load-positioning" to "no",
    "load-commands" to "no",
    "load-context-menu" to "no",
    // Nor scripts from a config directory (the Apple engine has one, for its subtitle font).
    "load-scripts" to "no",
)
