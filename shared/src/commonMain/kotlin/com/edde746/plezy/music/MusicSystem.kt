package com.edde746.plezy.music

/**
 * What the vehicle's car service says (Android Automotive OS): [supported] the car service answered for this display,
 * [requiresDistractionOptimization] the vehicle restricts the UI (driving), [pending] it has no verdict yet (a null
 * verdict stays pending, never read as restricted).
 */
data class CarRestrictionState(val supported: Boolean, val requiresDistractionOptimization: Boolean, val pending: Boolean)

/** The car service's restriction feed (Android Automotive only). Callbacks may come on any thread. */
interface CarRestrictionsSource {
    /** Answers once with the current state, or null when the car service can't answer (missing, dying, not bound). */
    fun currentState(callback: (CarRestrictionState?) -> Unit)

    /** Pushes every later change; null clears the listener. */
    fun setListener(listener: ((CarRestrictionState) -> Unit)?)
}

/** A hardware media key: a HID remote's or a keyboard's transport key. */
enum class MusicKey { PLAY, PAUSE, PLAY_PAUSE, NEXT, PREVIOUS, STOP, FAST_FORWARD, REWIND }

enum class KeyPhase { DOWN, REPEAT, UP }

/**
 * The OS glue the music session needs beyond [com.edde746.plezy.presentation.player.MediaControlsHost], implemented
 * by each platform; the defaults are the platforms without it.
 */
interface MusicSystem {
    /** Android Automotive's car service; null on every other device. */
    val car: CarRestrictionsSource? get() = null

    /**
     * Android: installs [handler] as the app's foreground handler of hardware media keys (null removes it). The handler
     * answers whether it consumed the key; an unconsumed key goes on as before.
     */
    fun setHardwareKeyHandler(handler: ((MusicKey, KeyPhase) -> Boolean)?) {}
}
