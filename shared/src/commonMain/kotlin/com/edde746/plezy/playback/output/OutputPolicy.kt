package com.edde746.plezy.playback.output

import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.ServerStream
import com.edde746.plezy.playback.VideoInfo
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * One mode of a display.
 * @param id the platform's own handle for it (Android's `Display.Mode.modeId`; whatever the desktop glue indexes its
 *   list by), handed back in [OutputPlan.mode].
 * @param refreshRate in Hz, the rate the mode really runs at (59.94 as 60000/1001, not 59: Windows reports whole hertz,
 *   which [OutputPolicy.windowsRefreshRate] reads).
 */
data class DisplayMode(val id: Int, val width: Int, val height: Int, val refreshRate: Double)

/**
 * The display the player shows on, as the platform detects it (capabilities are reported to shared code).
 * @param modes every mode it offers; empty where the platform can't switch modes.
 * @param current the mode it shows now; null when unknown, and then no mode is picked.
 * @param hdrSupported it can show HDR video.
 * @param hdrEnabled its HDR output is on now. Where HDR has no switch (Android turns it on per surface), the same as
 *   [hdrSupported].
 */
data class DisplayInfo(
    val modes: List<DisplayMode>,
    val current: DisplayMode?,
    val hdrSupported: Boolean,
    val hdrEnabled: Boolean,
)

/**
 * How the platform outputs the current video (shared code decides, the platform switches). Every plan is
 * complete: a null [mode] means the display's own mode from before the playback, and [enableHdr] false its own HDR
 * state, so the platform undoes whatever an earlier plan of the playback changed and touches nothing else.
 *
 * @param frameRate the rate the player presents the video at ([VideoInfo.fps]: the container's rate, doubled where
 *   each field becomes a frame, four fifths of it under inverse telecine); null before the video is known or when it
 *   declares none. A platform that tells the system the rate (tvOS's `AVDisplayCriteria`) does so whatever the
 *   settings.
 * @param mode the mode the app switches the display to itself, or null for the display's own mode. It may be the
 *   display's current mode: Android then pins it, so the system's own refresh policy can't leave it mid-playback.
 *   Android: with the MatchFrameRate setting (or, on a TV, the match resolution setting) on, the mode
 *   [DisplayModeSelector] picks. Windows and macOS: with the match refresh rate setting on and the player
 *   fullscreen, the mode [bestRefreshRate] picks.
 * @param hdr an HDR video (HDR10, HLG, Dolby Vision) goes out as HDR: [hdrOutput] and the video is HDR. False before the
 *   video is known.
 * @param hdrOutput the playback may present HDR at all: the Hdr setting is on and the display supports HDR, whatever
 *   the video. Off, everything goes out as SDR, an HDR video tone-mapped, even where the display's HDR is on (the
 *   engine must not pass HDR through then); on, the engine presents as it does for the display's state.
 * @param enableHdr turn the display's HDR output on (Windows): the match dynamic range setting is on, the player is
 *   fullscreen, the video is HDR and the display supports HDR but has it off.
 * @param switchDelaySeconds how long the platform waits after it switched the display's mode or HDR state, holding
 *   playback, before the video plays on (the display switch delay setting).
 * @param audioPassthrough the AudioPassthrough setting, or its default for the form factor
 *   ([DeviceSettings.audioPassthroughOn]): send the compressed formats the audio route decodes itself (the platform
 *   detects which) without decoding them.
 * @param dolbyVisionConversion what the decoder makes of Dolby Vision Profile 7 (the Dolby Vision conversion setting, or
 *   a development build's player page in its place), from the next decoder the engine opens
 *   ([com.edde746.plezy.playback.PlayerEngine.setDolbyVisionConversion]); on Apple TV also what the TV is asked for.
 */
data class OutputPlan(
    val frameRate: Double?,
    val mode: DisplayMode?,
    val hdr: Boolean,
    val hdrOutput: Boolean,
    val enableHdr: Boolean,
    val switchDelaySeconds: Int,
    val audioPassthrough: Boolean,
    val dolbyVisionConversion: DolbyVisionConversion,
)

/**
 * Picks the display mode and HDR state for a video.
 *
 * Mode: on Android (phones, tablets and TVs) the mode [DisplayModeSelector] picks for the video's presented rate with
 * the MatchFrameRate setting on and, on a TV with the match resolution setting on, for its size; on Windows and macOS
 * the refresh rate [bestRefreshRate] picks at the current resolution, only with the match refresh rate setting on and
 * while the player is fullscreen. Apple TV and iOS offer no modes: their system switches.
 *
 * HDR: an HDR video shows as HDR when the Hdr setting is on and the display supports it. On Windows the match dynamic
 * range setting turns the display's HDR on for it while the player is fullscreen.
 */
object OutputPolicy {
    /** How far (relative) a refresh rate may be from a multiple of the frame rate on a desktop ([bestRefreshRate]). */
    const val DESKTOP_TOLERANCE = 0.005

    /**
     * Relative deviation below which two of [bestRefreshRate]'s matches are equally precise: above the float noise in
     * reported rates, below the 0.1 % NTSC offset.
     */
    private const val PRECISE_DEVIATION = 0.0002

    /**
     * The video a TV or a phone switches its display for before the engine opens [server]'s stream (a direct play the
     * server gives a frame rate or size for), where the display follows the video's rate (the Match frame rate
     * setting) or a TV its resolution; null where nothing switches before the first frame. Switching HDMI once the
     * audio output is open breaks passthrough on a SHIELD's and a receiver's chain, so the mode is asked for first.
     */
    fun preOpenVideo(server: ServerStream?, settings: DeviceSettings, formFactor: FormFactor): VideoInfo? {
        if (server == null || server.transcode) return null
        return switchVideo(server.frameRate, server.width ?: 0, server.height ?: 0, settings, formFactor)
    }

    /**
     * Whether a TV or a phone switches its display for a video before its decoder opens ([preDecoderVideo]): where the
     * display follows the video's rate or a TV its resolution.
     */
    fun switchesBeforeDecoder(settings: DeviceSettings, formFactor: FormFactor): Boolean =
        formFactor != FormFactor.DESKTOP && (settings.matchFrameRate || (settings.matchResolution && formFactor == FormFactor.TV))

    /**
     * The video a TV or a phone switches for while the engine holds the decoder of a file whose server didn't say
     * ([PlaybackOutputHost.holdDecoder]): the rate and size its container [declared], as [preOpenVideo] takes the
     * server's; null where nothing switches.
     */
    fun preDecoderVideo(declared: VideoInfo, settings: DeviceSettings, formFactor: FormFactor): VideoInfo? =
        switchVideo(declared.fps, declared.width, declared.height, settings, formFactor)

    private fun switchVideo(frameRate: Double?, width: Int, height: Int, settings: DeviceSettings, formFactor: FormFactor): VideoInfo? {
        if (formFactor == FormFactor.DESKTOP) return null
        val fps = frameRate?.takeIf { it.isFinite() && it > 0 && settings.matchFrameRate }
        val size = settings.matchResolution && formFactor == FormFactor.TV && width > 0 && height > 0
        if (fps == null && !size) return null
        return VideoInfo(width = width, height = height, codec = null, fps = fps, dynamicRange = DynamicRange.SDR)
    }

    /**
     * The plan for [video] (null before it is known) on [display] (null when unknown) of a [formFactor] device, whose
     * player is [fullscreen] or not (only a desktop's is ever windowed).
     */
    fun plan(video: VideoInfo?, display: DisplayInfo?, settings: DeviceSettings, formFactor: FormFactor, fullscreen: Boolean): OutputPlan {
        val rate = video?.fps?.takeIf { it.isFinite() && it > 0 }
        val videoHdr = video != null && video.dynamicRange != DynamicRange.SDR
        val hdrOutput = settings.hdr && display?.hdrSupported == true
        val current = display?.current
        val mode = when {
            video == null || display == null || current == null -> null
            formFactor == FormFactor.DESKTOP -> rate?.takeIf { fullscreen && settings.matchRefreshRate }?.let { bestRefreshRate(it, current, display.modes) }
            else -> {
                val fps = rate.takeIf { settings.matchFrameRate } ?: 0.0
                val matchResolution = settings.matchResolution && formFactor == FormFactor.TV
                val width = if (matchResolution) video.width else 0
                val height = if (matchResolution) video.height else 0
                DisplayModeSelector.findBestMode(fps, current, display.modes, width, height, matchResolution)?.mode
            }
        }
        return OutputPlan(
            frameRate = rate,
            mode = mode,
            hdr = hdrOutput && videoHdr,
            hdrOutput = hdrOutput,
            enableHdr = formFactor == FormFactor.DESKTOP && fullscreen && settings.matchDynamicRange && videoHdr &&
                display?.hdrSupported == true && !display.hdrEnabled,
            switchDelaySeconds = settings.displaySwitchDelaySeconds,
            audioPassthrough = settings.audioPassthroughOn(formFactor),
            dolbyVisionConversion = settings.dvConversionMode,
        )
    }

    /**
     * A desktop's mode for a video at [fps] on a display in [current] mode: among [modes] of the current resolution, the
     * smallest integer multiple of [fps] within [DESKTOP_TOLERANCE], then the one nearest a multiple, then the faster
     * one; null when none fits, or when the best is the current refresh rate. So 23.976 fps takes a 23.976 Hz mode over
     * 24 Hz on Windows, and 47.95 Hz over 48 Hz on a MacBook Pro. 25 and 30 fps-class content
     * ([DisplayModeSelector.HALF_RATE_FPS]) takes 50/60 Hz over its own 25/30 Hz modes, as Android does, unless they are
     * more precise by [PRECISE_DEVIATION]: 29.97 fps keeps a 29.97 Hz mode over a 60 Hz one.
     */
    fun bestRefreshRate(fps: Double, current: DisplayMode, modes: List<DisplayMode>): DisplayMode? {
        if (fps <= 0) return null
        val sameResolution = modes.filter { it.width == current.width && it.height == current.height }
        val own = lowestMultiple(fps, sameResolution)
        val doubled = if (fps in DisplayModeSelector.HALF_RATE_FPS) lowestMultiple(fps * 2, sameResolution) else null
        val best = if (doubled != null && (own == null || doubled.second - own.second < PRECISE_DEVIATION)) doubled else own
        return best?.first?.takeIf { it.refreshRate != current.refreshRate }
    }

    /** [bestRefreshRate]'s pick among [modes] for [fps] alone, with its deviation from the multiple. */
    private fun lowestMultiple(fps: Double, modes: List<DisplayMode>): Pair<DisplayMode, Double>? {
        var best: DisplayMode? = null
        var bestMultiplier = 0
        var bestDeviation = 0.0
        for (mode in modes) {
            val ratio = mode.refreshRate / fps
            val multiplier = ratio.roundToInt()
            if (multiplier < 1) continue
            val deviation = abs(ratio - multiplier) / multiplier
            if (deviation > DESKTOP_TOLERANCE) continue
            val better = best == null || multiplier < bestMultiplier ||
                (multiplier == bestMultiplier && (deviation < bestDeviation || (deviation == bestDeviation && mode.refreshRate > best.refreshRate)))
            if (better) {
                best = mode
                bestMultiplier = multiplier
                bestDeviation = deviation
            }
        }
        return best?.let { it to bestDeviation }
    }

    /**
     * The rate a Windows mode really runs at: Windows reports whole hertz, and the NTSC family's 1000/1001 rates
     * (23.976, 29.97, 59.94 and multiples such as 47.952 or 119.88) as one below the nominal rate: 23, 29, 59, 47, 119.
     */
    fun windowsRefreshRate(hertz: Int): Double {
        val nominal = hertz + 1
        return if (nominal % 24 == 0 || nominal % 30 == 0) nominal * 1000.0 / 1001 else hertz.toDouble()
    }
}
