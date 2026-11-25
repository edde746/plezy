package com.edde746.plezy.desktop

/**
 * Keeps the display awake on a desktop (Windows' execution state, Linux's screen saver inhibition) while
 * [PlatformPlayback.keepDisplayAwake][com.edde746.plezy.app.PlatformPlayback.keepDisplayAwake] says so; released
 * when the app closes.
 */
internal interface DesktopDisplayAwake : AutoCloseable {
    /** Holds the one assertion while [awake], releases it otherwise; a repeat changes nothing. On the event thread. */
    fun keepAwake(awake: Boolean)
}
