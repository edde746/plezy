package com.edde746.plezy.playback

import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.settings.DeinterlaceMode

/**
 * Each platform's hardware decoder: the mpv `hwdec` value the Hardware decoding setting turns on ([PlaybackOptions]).
 * The platform names its own ([com.edde746.plezy.app.PlatformPlayback.hardwareDecoder]).
 */
enum class HardwareDecoder(val hwdec: String) {
    /**
     * MediaCodec. The video plane (the fork's `vo=mediacodec`) takes MediaCodec buffers only, so `-copy` is reached only
     * under the GL vo; it stays because it is the one hardware path below API 26.
     */
    ANDROID("mediacodec,mediacodec-copy"),

    /** mpv's own probe on the d3d11 context, which settles on d3d11va. */
    WINDOWS("auto"),

    /** mpv's own probe on the video plane's EGL context, whose Wayland display gives VAAPI its zero-copy GL interop. */
    LINUX("auto"),

    /** VideoToolbox, on iPhones, iPads, Apple TVs and Macs. */
    APPLE("videotoolbox"),

    /** The iOS and tvOS simulators have no VideoToolbox hardware decoder: they decode in software either way. */
    APPLE_SIMULATOR("no"),
}

/**
 * The mpv options of one file that follow this device's settings, decided here for every platform. The
 * playback session reads the settings as each file loads and hands these to the engine with it
 * ([LoadRequest.options]); the engine applies them to that file only. A setting changed while a file plays applies
 * from the next file (the next episode, a retry, another stream), never to the file playing.
 *
 * @param hwdec mpv's `hwdec`: the platform's [HardwareDecoder] with the Hardware decoding setting on, [SOFTWARE] with it
 *   off.
 * @param demuxerMaxBytes mpv's `demuxer-max-bytes`, how far ahead of the position the stream is read: the Read-ahead
 *   cache setting in MiB, or mpv's own [DEFAULT_CACHE_MEGABYTES] while the setting is Automatic.
 * @param demuxerMaxBackBytes mpv's `demuxer-max-back-bytes`, how much already played stays for seeking back: a third of
 *   [demuxerMaxBytes], mpv's own proportion (150 MiB ahead, 50 MiB back).
 * @param deinterlace the Deinterlacing setting: mpv's `deinterlace` ([com.edde746.plezy.playback.mpv.MpvLoad]
 *   plays a live file's film mode as plain deinterlacing).
 */
data class PlaybackOptions(
    val hwdec: String,
    val demuxerMaxBytes: Long,
    val demuxerMaxBackBytes: Long,
    val deinterlace: DeinterlaceMode = DeinterlaceMode.OFF,
) {
    companion object {
        /** mpv's `hwdec` for software decoding. */
        const val SOFTWARE = "no"

        /** The read-ahead cache while the setting is Automatic: mpv's default `demuxer-max-bytes`. */
        const val DEFAULT_CACHE_MEGABYTES = 150

        private const val MEBIBYTE = 1024L * 1024

        /** The options a file plays with under [settings] on a platform whose hardware decoder is [decoder]. */
        fun of(settings: DeviceSettings, decoder: HardwareDecoder): PlaybackOptions {
            val ahead = (settings.cacheSizeMegabytes ?: DEFAULT_CACHE_MEGABYTES) * MEBIBYTE
            return PlaybackOptions(
                hwdec = if (settings.hardwareDecoding) decoder.hwdec else SOFTWARE,
                demuxerMaxBytes = ahead,
                demuxerMaxBackBytes = ahead / 3,
                deinterlace = settings.deinterlace,
            )
        }
    }
}
