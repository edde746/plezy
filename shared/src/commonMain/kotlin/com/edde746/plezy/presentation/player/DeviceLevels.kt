package com.edde746.plezy.presentation.player

/**
 * The screen's brightness and the system's media volume, which swipes up and down the video's edges change on a touch
 * screen. Levels are 0 to 1. Called on the main thread.
 */
interface DeviceLevels {
    /** Reads the brightness the screen shows now, then calls [result] with it (null when it can't be read). */
    fun readBrightness(result: (Double?) -> Unit)

    /** Reads the system's media volume, then calls [result] with it (null when it can't be read). */
    fun readVolume(result: (Double?) -> Unit)

    /** Sets the brightness of the screen while the player shows. */
    fun setBrightness(level: Double)

    /** Sets the system's media volume, without the system's own volume panel: the player shows its own level. */
    fun setVolume(level: Double)

    /** The player closed: the brightness it set is gone, and the screen's own is back. */
    fun restoreBrightness()
}
