package com.edde746.plezy.playback

import com.edde746.plezy.log.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * The system's media accessibility settings that the track choice follows (`TrackChooser`).
 * @param captions captions whenever there is speech: Apple's Closed Captions + SDH, Android's captions switch.
 * @param audioDescriptions an audio description of the picture: Apple's Audio Descriptions, Android 13+'s Audio
 *   description.
 */
internal data class MediaAccessibilityPreferences(val captions: Boolean = false, val audioDescriptions: Boolean = false)

/**
 * The system's [MediaAccessibilityPreferences] in this process. The platform reports them as it starts
 * ([com.edde746.plezy.app.SystemInputs.report]) and again whenever the system says they changed ([report]); both
 * are off where the system has no such setting (Windows, Linux). A playback follows a change at once, on the file
 * playing too.
 */
object SystemMediaAccessibility {
    private val mutablePreferences = MutableStateFlow(MediaAccessibilityPreferences())
    internal val preferences: StateFlow<MediaAccessibilityPreferences> = mutablePreferences.asStateFlow()

    fun report(captions: Boolean, audioDescriptions: Boolean) {
        val reported = MediaAccessibilityPreferences(captions, audioDescriptions)
        if (reported == mutablePreferences.value) return
        mutablePreferences.value = reported
        Log.i("SystemMediaAccessibility") { "system captions $captions, audio descriptions $audioDescriptions" }
    }
}
