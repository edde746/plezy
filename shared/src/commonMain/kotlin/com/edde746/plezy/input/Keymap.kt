package com.edde746.plezy.input

/** Which keymap a platform uses. */
enum class InputProfile {
    /** Windows, Linux and macOS: keyboard and mouse. */
    DESKTOP,

    /** Android TV, Fire TV and tvOS: D-pad remote. */
    TV,

    /** Phones and tablets: touch, plus a hardware keyboard when one is attached. */
    TOUCH,
}

/** The step sizes keymaps use. */
data class InputSteps(
    /** One subtitle- or audio-delay step. */
    val delaySeconds: Double = 0.1,
)

/** The player state a keymap decides by. */
data class InputContext(
    val controlsVisible: Boolean = false,
    val menuOpen: Boolean = false,
    val errorShown: Boolean = false,
    /** What a click on the video does with a mouse: the profile's setting. */
    val videoClick: VideoClickAction = VideoClickAction.PAUSE,
    /** A live playback: nothing changes its speed. */
    val live: Boolean = false,
    /** The viewer may control playback (false: a Watch Together guest the host hasn't let). */
    val canControl: Boolean = true,
)

/**
 * Turns pointer input on the video into [PlayerCommand]s for one [InputProfile] (keys go through the store's key
 * handling and [Hotkeys]). A null result leaves the input to the platform.
 */
interface Keymap {
    /** A single click or tap on the video at [x] (0 = left edge, 1 = right edge). */
    fun click(x: Float, context: InputContext): PlayerCommand?

    /** A double click or double tap: a second [click] within the interval runs this instead, the first having acted. */
    fun doubleClick(x: Float, context: InputContext): PlayerCommand?

    companion object {
        fun forProfile(profile: InputProfile): Keymap = when (profile) {
            InputProfile.DESKTOP -> DesktopKeymap()
            InputProfile.TV -> TvKeymap
            InputProfile.TOUCH -> TouchKeymap
        }
    }
}
