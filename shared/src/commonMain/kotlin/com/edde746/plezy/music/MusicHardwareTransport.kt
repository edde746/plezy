package com.edde746.plezy.music

/** What a transport key or button asks of the music session. */
enum class MusicTransport { PLAY, PAUSE, TOGGLE, NEXT, PREVIOUS, STOP, SKIP_FORWARD, SKIP_BACKWARD }

/**
 * Foreground hardware media keys (HID remotes, keyboards with media keys) for the live music session, installed with
 * [MusicSystem.setHardwareKeyHandler] (Android; the other platforms route media keys through their OS media controls).
 * While [hasActiveSession], every transport key is consumed for its whole down, repeat and up burst, so a press can
 * neither leak to Android's fallback media-button dispatch nor act on a focused item; it acts on the first down only.
 */
class MusicHardwareTransport(
    private val system: MusicSystem,
    private val hasActiveSession: () -> Boolean,
    private val perform: (MusicTransport) -> Unit,
) {
    private var registered = false

    fun register() {
        if (registered) return
        registered = true
        system.setHardwareKeyHandler(::handle)
    }

    /** Removes the handler; later calls do nothing. */
    fun unregister() {
        if (!registered) return
        registered = false
        system.setHardwareKeyHandler(null)
    }

    internal fun handle(key: MusicKey, phase: KeyPhase): Boolean {
        if (!hasActiveSession()) return false
        if (phase == KeyPhase.DOWN) perform(key.transport)
        return true
    }

    private val MusicKey.transport: MusicTransport
        get() = when (this) {
            MusicKey.PLAY -> MusicTransport.PLAY
            MusicKey.PAUSE -> MusicTransport.PAUSE
            MusicKey.PLAY_PAUSE -> MusicTransport.TOGGLE
            MusicKey.NEXT -> MusicTransport.NEXT
            MusicKey.PREVIOUS -> MusicTransport.PREVIOUS
            MusicKey.STOP -> MusicTransport.STOP
            MusicKey.FAST_FORWARD -> MusicTransport.SKIP_FORWARD
            MusicKey.REWIND -> MusicTransport.SKIP_BACKWARD
        }
}
