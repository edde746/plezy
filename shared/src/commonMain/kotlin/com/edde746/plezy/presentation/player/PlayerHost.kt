package com.edde746.plezy.presentation.player

/**
 * What the player store asks of the platform around it. Implemented by the Compose screen or the SwiftUI view;
 * called on the main thread.
 */
interface PlayerHost {
    /** Leave the player (Back with nothing left to close, Stop, the close button). */
    fun close()

    /**
     * Enter or leave fullscreen. Desktop windows only; the store never asks elsewhere. A change the user makes
     * outside the player (the window's own button, the OS) comes back through `PlayerStore.onFullscreenChanged`.
     */
    fun setFullscreen(fullscreen: Boolean)

    /** The brightness and the system's volume the swipes change on a touch screen; null where nothing changes them. */
    val levels: DeviceLevels? get() = null

    /** The player's window can stay above the others (Windows, Linux): the controls offer always on top. */
    val keepsOnTop: Boolean get() = false

    /**
     * Keep the player's window above the others, or let it go; asked only where [keepsOnTop], as the player opens
     * (the setting kept from the last time) and as the viewer toggles it.
     */
    fun setAlwaysOnTop(onTop: Boolean) = Unit

    /**
     * Video may play now: false in a car whose driving restrictions forbid it ([com.edde746.plezy.music.automotivePlaybackAllowed]),
     * when a play is refused and Play/Pause pauses.
     */
    val playbackAllowed: Boolean get() = true
}
