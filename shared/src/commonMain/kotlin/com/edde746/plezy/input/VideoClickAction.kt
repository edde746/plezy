package com.edde746.plezy.input

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * What a single click on the video does with a mouse ([DesktopKeymap]; a user setting). A
 * double click toggles fullscreen either way, and the keys and the play button still pause. Touch screens and remotes
 * don't follow it: a tap always shows or hides the controls, and a remote has no clicks.
 */
@Serializable
enum class VideoClickAction {
    /** Pauses, or plays when paused. */
    @SerialName("pause")
    PAUSE,

    /** Hides the controls when they show and shows them when they don't, as a tap does; never pauses. */
    @SerialName("controls")
    CONTROLS,
    ;

    companion object {
        /** The action of the click-toggles-playback setting: on pauses, off shows the controls. */
        fun of(clickTogglesPlayback: Boolean): VideoClickAction = if (clickTogglesPlayback) PAUSE else CONTROLS
    }
}
