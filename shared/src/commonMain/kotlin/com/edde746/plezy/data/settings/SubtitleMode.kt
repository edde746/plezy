package com.edde746.plezy.data.settings

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * When subtitles turn on by themselves (the profile's [ProfileSetting.ShowSubtitles]; `TrackChooser`).
 * The system's closed captions setting, where the system has one, turns [ALWAYS] on too.
 */
@Serializable
enum class SubtitleMode {
    /** Full subtitles for audio in a language the profile doesn't read subtitles in; otherwise only forced ones. */
    @SerialName("followAudio")
    FOLLOW_AUDIO,

    /** Full subtitles in the spoken language too, SDH first; forced ones only when there are no others. */
    @SerialName("always")
    ALWAYS,
}
