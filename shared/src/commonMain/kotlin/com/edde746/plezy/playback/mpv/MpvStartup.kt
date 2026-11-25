package com.edde746.plezy.playback.mpv

import com.edde746.plezy.data.settings.DeviceSettings

/**
 * What a video engine's mpv takes from this device's settings as it starts, one table for every engine. The engine
 * sets [properties] and the stored audio output ([preferredAudioDevice]) once mpv runs, before the user's mpv.conf
 * (`MpvUserConfig`), so a line there wins; then [volumeMax] and the opening [volume], which the app keeps.
 */
object MpvStartup {
    /**
     * The settings' properties, in their order: `msg-level` ([msgLevel]) and, on a [desktop], `screenshot-directory`,
     * the user's Pictures.
     */
    fun properties(settings: DeviceSettings, desktop: Boolean): List<Pair<String, String>> = buildList {
        add("msg-level" to msgLevel(settings.debugLogging))
        if (desktop) add("screenshot-directory" to SCREENSHOT_DIRECTORY)
    }

    /** `msg-level`: everything at debug with debug logging on (FFmpeg's video decoders only from warnings), else errors. */
    fun msgLevel(debugLogging: Boolean): String = if (debugLogging) "all=debug,ffmpeg/video=warn" else "all=error"

    /** The level the engine asks mpv's log messages at (`mpv_request_log_messages`): verbose with debug logging on. */
    fun logLevel(debugLogging: Boolean): String = if (debugLogging) "v" else "warn"

    /** Where mpv's `screenshot` command saves on the desktops: the user's Pictures. */
    const val SCREENSHOT_DIRECTORY = "~/Pictures"

    /**
     * The stored audio output ([DeviceSettings.audioOutputDevice]) when mpv's `audio-device-list` ([deviceList], its
     * JSON) has an entry of that name; null for `auto` and for a device not there now (unplugged: the system's choice
     * plays).
     */
    fun preferredAudioDevice(settings: DeviceSettings, deviceList: String?): String? {
        val stored = settings.audioOutputDevice.takeIf { it.isNotEmpty() && it != AUTO } ?: return null
        return stored.takeIf { MpvState.audioDevices(deviceList).any { device -> device.name == it } }
    }

    /** mpv's `volume-max`: the `max_volume` setting. */
    fun volumeMax(settings: DeviceSettings): Double = settings.maxVolume.toDouble()

    /** The volume the player opens at: the last one the viewer chose, within [volumeMax]. */
    fun volume(settings: DeviceSettings): Double = settings.volume.coerceIn(0.0, volumeMax(settings))

    private const val AUTO = "auto"
}
