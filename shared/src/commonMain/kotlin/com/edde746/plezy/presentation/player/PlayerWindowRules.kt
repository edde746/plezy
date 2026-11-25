package com.edde746.plezy.presentation.player

/** What the player asks the platform to allow for the screen's orientation. */
enum class OrientationRequest {
    /** Landscape either way round, as the device is held. */
    LANDSCAPE,

    /** Every orientation the app allows outside the player (the app's default). */
    ALL,
}

/**
 * The player's orientation rules on a handheld (phones and tablets alike). The player asks for landscape while the
 * rotation lock (`rotation_locked`, on by default) is on, and gives the app's default (every orientation) back while it
 * is off and as the player closes. A TV or a car owns its display's rotation: nothing is asked there, not even the
 * default, since asking for every orientation lets the system pick the 180° rotation it withholds from apps that ask
 * for none, and a TV box that doesn't pin its rotation then shows the app upside down.
 */
object PlayerOrientationRules {
    /** What the player asks for while it shows, or null where the platform owns the orientation. */
    fun whilePlaying(rotationLocked: Boolean, platformOwnsOrientation: Boolean): OrientationRequest? = when {
        platformOwnsOrientation -> null
        rotationLocked -> OrientationRequest.LANDSCAPE
        else -> OrientationRequest.ALL
    }

    /** What the player asks for as it closes, or null where the platform owns the orientation. */
    fun onExit(platformOwnsOrientation: Boolean): OrientationRequest? =
        if (platformOwnsOrientation) null else OrientationRequest.ALL
}

/**
 * Keeps the player immersive across the system bars coming back while the activity stays resumed (folding or
 * unfolding, a display switch): while a player owns it, a re-show of the bars hides them again ([hideBars]).
 *
 * One owner at a time. A successor player acquires before its predecessor releases, so [release] only clears a
 * matching owner; the owner releases before it shows the bars itself, so that re-show isn't answered.
 */
class ImmersiveModeGuard(private val hideBars: () -> Unit) {
    private var owner: Any? = null

    fun acquire(owner: Any) {
        this.owner = owner
    }

    fun release(owner: Any) {
        if (this.owner === owner) this.owner = null
    }

    /** The system shows or hides its bars: shown while a player owns immersive mode, they are hidden again. */
    fun onSystemBarsChanged(visible: Boolean) {
        if (visible && owner != null) hideBars()
    }
}
