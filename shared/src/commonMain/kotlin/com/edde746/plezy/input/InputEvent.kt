package com.edde746.plezy.input

/** Modifier keys held with a key press. */
data class KeyModifiers(
    val shift: Boolean = false,
    val ctrl: Boolean = false,
    val alt: Boolean = false,
    /** Command on Apple keyboards, the Windows/Super key elsewhere. */
    val meta: Boolean = false,
) {
    /** Ctrl, or Command on Apple keyboards: the modifier shortcuts use. */
    val command: Boolean get() = ctrl || meta

    companion object {
        val NONE = KeyModifiers()
    }
}

/**
 * What a platform forwards to the player store from the player surface (the platform only translates).
 * Pointer events are the ones that land on the video itself; the views' own buttons, sliders and menus handle their
 * clicks and send commands instead.
 */
sealed interface InputEvent {
    /**
     * A key went down. [repeat] marks the platform's auto-repeat while the key is held (Android `repeatCount > 0`,
     * Compose/AWT repeated key-downs); platforms without auto-repeat (tvOS presses) send one [KeyDown] and a [KeyUp].
     * [source] tells a physical keyboard from a remote ([PlayerKeys.navigation]).
     */
    data class KeyDown(
        val key: InputKey,
        val modifiers: KeyModifiers = KeyModifiers.NONE,
        val repeat: Boolean = false,
        val source: KeySource = KeySource.KEYBOARD,
    ) : InputEvent

    /** A key came up: a held D-pad key's scrub (TV) stops moving, a held seek key seeks to where its repeats took it. */
    data class KeyUp(val key: InputKey) : InputEvent

    /**
     * A mouse or pen click on the video (touch screens send [Touch]).
     * @param x where, across the player: 0 at the left edge, 1 at the right.
     * @param clickCount the platform's click count (2 for the second click of a double click). Platforms that don't
     *   count send 1 each time; the store then pairs clicks itself within [PlayerConfig][com.edde746.plezy.presentation.player.PlayerConfig]'s
     *   double-click interval.
     */
    data class Click(val x: Float, val clickCount: Int = 1) : InputEvent

    /**
     * A mouse's or pen's press on the video held still past the platform's long-press time ([held]), then lifted or
     * cancelled (not [held]): the video plays at 2× while it is held, as under a held finger. A held press is no click.
     */
    data class Hold(val held: Boolean) : InputEvent

    /** The mouse moved over the player (hover): the controls show, their timer restarting. */
    data object PointerMove : InputEvent

    /** The mouse left the player window. */
    data object PointerExit : InputEvent

    /** A pointer (a mouse button, a finger, by [pointer] id) went down on the controls: they stay up until it lifts. */
    data class PointerDown(val pointer: Long) : InputEvent

    /** The pointer [pointer] lifted or was cancelled. */
    data class PointerUp(val pointer: Long) : InputEvent

    /**
     * Scroll wheel or trackpad scroll over the player, as the platform reports it: [deltaY] in logical pixels,
     * positive scrolling down (one wheel notch is about 20 to 120). The volume changes by `-deltaY / 20` points.
     */
    data class Wheel(val deltaY: Double) : InputEvent

    /**
     * One finger on the video of a touch screen went down, moved, lifted or was taken by the system ([phase]), the
     * views' raw touches: the store tells taps, double taps, holds, two-finger taps, pinches and edge swipes from them.
     * [pointer] tells the fingers of one touch apart; ([x], [y]) is where the finger is, from the player's top-left
     * corner, and [width] and [height] the player's size, all in the same units (dp on Compose, points on Apple's
     * platforms). Mice and pens send [Click] instead.
     */
    data class Touch(
        val phase: TouchPhase,
        val pointer: Long,
        val x: Float,
        val y: Float,
        val width: Float,
        val height: Float,
    ) : InputEvent

    /**
     * The remote moved focus among the player's controls without a key the store sees (tvOS: the focus engine moves it
     * on a swipe or a press, outside the views that forward presses). It keeps the controls up, as using them does.
     */
    data object FocusMove : InputEvent

    /**
     * Focus went to one of the player's controls ([onControl]: a button, the seek bar, a menu's row) or back to the
     * player itself: Select and the directions are then the control's and its focus navigation's.
     */
    data class ControlFocus(val onControl: Boolean) : InputEvent
}

/** What an [InputEvent.Touch]'s finger did. */
enum class TouchPhase { DOWN, MOVE, UP, CANCEL }
