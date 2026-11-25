package com.edde746.plezy.presentation.player

import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.input.Hotkeys
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.CustomShader
import com.edde746.plezy.playback.Downmix
import com.edde746.plezy.playback.ShaderPreset
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.flow.Flow

/**
 * The player's options that outlive a playback: the picture's fit and zoom and the shader preset, kept per library or
 * title as their scopes say ([picture], `ScopedPlayerPrefs.boxFitMode`, `videoZoom`, `shaderPreset`), the imported
 * shaders, loudness normalization and the audio channels, kept as this device's settings (`customShaderPresets`,
 * `audioNormalization`, `audioChannelLimit`). The sleep timer stays with the player; the audio output stays with the
 * playback. With them, whether swipes up and down
 * the edges change the brightness and the volume and a pinch zooms (`AppSettings.gestureBrightnessSwipe`,
 * `GestureVolumeSwipe`, `GesturePinchToZoom`), which Settings sets, the brightness a swipe last settled on for the
 * next playback to open at (`AppSettings.rememberBrightnessLevel`, `rememberedBrightnessLevel`), the keys'
 * settings: the seek steps (`seek_time_small`, `seek_time_large`), the remote's navigation of the player
 * (`video_player_navigation_enabled`) and the keyboard shortcuts (`keyboard_hotkeys`); and Plezy's settings the player
 * reads and keeps: the rotation lock (`rotation_locked`), always on top (`player_always_on_top`), the volume's top
 * (`max_volume`) and the language subtitles are searched in (`subtitle_search_language`); the playback info
 * (`show_performance_overlay`, the player's toggle and Settings', and `auto_hide_performance_overlay`, which Settings sets);
 * ambient lighting (`AppSettings.ambientLighting`), on at the start of the next playback where it was on; HDR output
 * (`AppSettings.enableHdr`, the player's switch), the audio output picked last (`audio_output_device`) and the sleep
 * timer's configured minutes (`sleep_timer_duration`).
 */
interface PlayerPreferences {
    /** The stored choices, now and whenever they change. */
    val choices: Flow<PlayerChoices>

    /** [item]'s picture options: each as its configured scope keeps it for [item], else its global setting. */
    suspend fun picture(item: MediaItem?): PictureChoices

    /** Keeps [fit] for [item] in the fit's configured scope; [setVideoZoom] and [setShaderPreset] the same way. */
    fun setVideoFit(item: MediaItem?, fit: VideoFit)
    fun setVideoZoom(item: MediaItem?, zoom: Double)
    fun setShaderPreset(item: MediaItem?, id: String)

    /** Keeps the imported [shader] and makes it [item]'s preset ([setShaderPreset]), in that order. */
    fun addCustomShader(item: MediaItem?, shader: CustomShader)

    /** Forgets the imported [shader]; the global preset goes [ShaderPreset.Off] if it was this one (a scope naming it runs none). */
    fun removeCustomShader(shader: CustomShader)

    fun setAudioNormalization(enabled: Boolean)
    fun setAudioChannels(channels: AudioChannels)

    /** Keeps the rotation lock; the platforms' players follow the setting. */
    fun setRotationLocked(locked: Boolean)

    /** Keeps always on top for the players to come. */
    fun setAlwaysOnTop(enabled: Boolean)

    /** Keeps the language (ISO 639-1) the subtitle search looks in. */
    fun setSubtitleSearchLanguage(language: String)

    fun setShowPlaybackInfo(enabled: Boolean)
    fun setAmbientLighting(enabled: Boolean)
    /** Keeps [level], the brightness a swipe settled on, for the next playback ([PlayerChoices.rememberedBrightness]). */
    fun setRememberedBrightness(level: Double)

    /** Keeps the volume the viewer chose (`volume`), which the next playback opens at. */
    fun setVolume(percent: Double)

    /** Keeps HDR output on or off (`AppSettings.enableHdr`) once the engine took it. */
    fun setHdr(enabled: Boolean)

    /** Keeps the audio output the engine plays to ([AudioDevice.name][com.edde746.plezy.playback.AudioDevice.name]) for the players to come. */
    fun setAudioOutputDevice(name: String)
}

/** A title's picture options ([PlayerPreferences.picture]). */
data class PictureChoices(
    val fit: VideoFit = VideoFit.CONTAIN,
    val zoom: Double = 1.0,
    /** [ShaderPreset.id]. */
    val shaderPreset: String = ShaderPreset.Off.id,
)

data class PlayerChoices(
    val customShaders: List<CustomShader> = emptyList(),
    val audioNormalization: Boolean = false,
    val audioChannels: AudioChannels = AudioChannels.ORIGINAL,
    /** HDR output (`AppSettings.enableHdr`). */
    val hdr: Boolean = true,
    /** The audio output picked last (`audio_output_device`), "auto" for the system's. */
    val audioOutputDevice: String = "auto",
    /** The user's mpv.conf has an `audio-device` line, which the player opens on instead of [audioOutputDevice]. */
    val configAudioDevice: Boolean = false,
    /** The sleep timer's configured minutes (`sleep_timer_duration`). */
    val sleepTimerMinutes: Int = 30,
    /** What Dolby Vision Profile 7 becomes (`AppSettings.dvConversionMode`): the engine's as it starts. */
    val dolbyVisionConversion: DolbyVisionConversion = DolbyVisionConversion.AUTO,
    val brightnessSwipe: Boolean = true,
    val volumeSwipe: Boolean = true,
    val pinchToZoom: Boolean = true,
    val rotationLocked: Boolean = true,
    val alwaysOnTop: Boolean = false,
    /** The volume's top, in percent (100 to 300). */
    val maxVolume: Int = 100,
    /** ISO 639-1; null while none was searched in. */
    val subtitleSearchLanguage: String? = null,
    /** How a channel limit folds the audio (the Center Boost and Normalize Downmix settings). */
    val downmix: Downmix = Downmix(),
    /** The playback info shows over the video. */
    val showPlaybackInfo: Boolean = false,
    /** The playback info fades out with the controls. */
    val autoHidePlaybackInfo: Boolean = true,
    val ambientLighting: Boolean = false,
    /** Playback opens at [rememberedBrightness] while brightness swipes are on. */
    val rememberBrightness: Boolean = false,
    /** The brightness a swipe last settled on, 0 to 1; -1 while never set. */
    val rememberedBrightness: Double = -1.0,
    /** The small seek step in seconds: arrows, the seek shortcuts, a remote's fast forward and rewind. */
    val seekSeconds: Int = 10,
    /** The large seek step in seconds: Shift + arrows. */
    val longSeekSeconds: Int = 30,
    /**
     * The D-pad drives the player (seeks with the controls down, keeps paused controls up): the setting, null while
     * unset (on for TV, off elsewhere).
     */
    val playerNavigation: Boolean? = null,
    val hotkeys: Hotkeys = Hotkeys.DEFAULT,
)
