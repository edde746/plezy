package com.edde746.plezy.presentation.player

import com.edde746.plezy.strings.T
import kotlinx.coroutines.delay

/**
 * How a request to start picture in picture went, as a platform reports it: started, or failed with one of
 * [PictureInPictureError]'s codes (another code, or none, is an unknown failure with the platform's own [message]).
 */
sealed interface PictureInPictureResult {
    data object Entered : PictureInPictureResult

    data class Failed(val code: String?, val message: String? = null) : PictureInPictureResult
}

/** The failure codes the platforms report ([PictureInPictureResult.Failed.code]). */
enum class PictureInPictureError(val code: String) {
    /** Android before 8.0. */
    ANDROID_VERSION("android_version"),

    /** iOS before 15. */
    IOS_VERSION("ios_version"),

    /** A Mac without the picture-in-picture framework. */
    MACOS_VERSION("macos_version"),

    /** Android: the user turned picture in picture off for the app (the system's app-ops switch). */
    PERMISSION_DISABLED("permission_disabled"),
    NOT_SUPPORTED("not_supported"),

    /** iOS: the video's layer never became ready for the window. */
    PREPARE_FAILED("pip_prepare_failed"),
    VO_SWITCH_FAILED("vo_switch_failed"),
    FAILED("failed"),
    ;

    fun failed(message: String? = null) = PictureInPictureResult.Failed(code, message)
}

/**
 * A platform's picture in picture for the player (Android, iOS, the Mac): whether the device has it, whether the
 * player is in its window, and starting and leaving it. Main thread.
 */
interface PictureInPictureHost {
    /** The device has picture in picture (Android: 8.0+, no TV, the system feature; iOS: AVKit's support). */
    val supported: Boolean

    /** The player shows in the picture-in-picture window. */
    val active: Boolean

    /** Starts picture in picture with the window shaped [width]×[height] (null: 16:9) and reports how it went. */
    suspend fun enter(width: Int?, height: Int?): PictureInPictureResult

    /** Leaves picture in picture: the video goes back to the player. */
    fun exit()
}

/** The video's size as the engine and the screen have it, for the window's shape ([PictureInPictureRules.videoSize]). */
data class PictureInPictureVideo(
    /** The display size, after the aspect ratio (mpv's `dwidth`/`dheight`). */
    val displayWidth: Int? = null,
    val displayHeight: Int? = null,
    /** The decoded size (mpv's `width`/`height`). */
    val width: Int? = null,
    val height: Int? = null,
    /** The player's video area on screen. */
    val viewportWidth: Int? = null,
    val viewportHeight: Int? = null,
)

/** Picture in picture's rules, shared by every platform that has it. */
object PictureInPictureRules {
    /** The system's limits on the window's shape (Android): 1:2.39 to 2.39:1. */
    const val MAX_ASPECT = 2.39f

    /** The wait between showing the whole picture and asking for the window: one frame for the change to draw. */
    const val PREPARE_DELAY_MILLIS = 50L

    /** iOS: how often and how many times a start reads again whether the layer is ready for the window. */
    const val READY_RETRY_MILLIS = 50L
    const val READY_RETRIES = 40

    /** iOS: how long a start waits for AVKit to say it started before it gives up. */
    const val START_TIMEOUT_MILLIS = 3_000L

    /** Android has picture in picture: API 26+, not a TV, and the system feature. */
    fun androidSupported(sdk: Int, television: Boolean, hasFeature: Boolean): Boolean = sdk >= 26 && !television && hasFeature

    /**
     * What a failed start says: each known code its message, another code the platform's message (or "Unknown") as an
     * unknown error, a failure without a code the generic one; [result] null (the platform gave no answer) unknown.
     */
    fun message(result: PictureInPictureResult.Failed?): String {
        if (result == null) return T.videoControls.pipErrors.unknown(T.common.unknown)
        val code = result.code ?: return T.videoControls.pipFailed
        val error = PictureInPictureError.entries.firstOrNull { it.code == code }
        val errors = T.videoControls.pipErrors
        return when (error) {
            PictureInPictureError.ANDROID_VERSION -> errors.androidVersion
            PictureInPictureError.IOS_VERSION -> errors.iosVersion
            PictureInPictureError.MACOS_VERSION, PictureInPictureError.NOT_SUPPORTED -> errors.notSupported
            PictureInPictureError.PERMISSION_DISABLED -> errors.permissionDisabled
            PictureInPictureError.PREPARE_FAILED -> errors.prepareFailed
            PictureInPictureError.VO_SWITCH_FAILED -> errors.voSwitchFailed
            PictureInPictureError.FAILED -> errors.failed
            null -> errors.unknown(result.message ?: T.common.unknown)
        }
    }

    /**
     * The window's shape for a [width]×[height] video: 16:9 without a size, else the video's own within the system's
     * limits ([MAX_ASPECT]), as a numerator and denominator.
     */
    fun aspectRatio(width: Int?, height: Int?): Pair<Int, Int> {
        if (width == null || height == null || width <= 0 || height <= 0) return 16 to 9
        val ratio = width.toFloat() / height.toFloat()
        return when {
            ratio < 1f / MAX_ASPECT -> 100 to 239
            ratio > MAX_ASPECT -> 239 to 100
            else -> width to height
        }
    }

    /** The video's size for the window: the display size, else the decoded size, else the player's area; null without any. */
    fun videoSize(video: PictureInPictureVideo): Pair<Int, Int>? = with(video) {
        pair(displayWidth, displayHeight) ?: pair(width, height) ?: pair(viewportWidth, viewportHeight)
    }

    private fun pair(width: Int?, height: Int?): Pair<Int, Int>? = if (width != null && height != null) width to height else null

    /**
     * Picture in picture starts by itself as the app leaves (Home, the app switcher): where [autoPipOn]
     * (`AppSettings.autoPipOn`) and while the playback plays; never while it is paused or has ended.
     */
    fun autoEnterReady(autoPipOn: Boolean, playing: Boolean): Boolean = autoPipOn && playing

    /**
     * The player's picture-in-picture button: leaves picture in picture when it is up; where the device has none, says
     * so; otherwise shows the whole picture ([prepare]), waits a frame ([PREPARE_DELAY_MILLIS]) and starts it in the
     * shape of the [video] ([videoSize]). A failed start takes the picture back as it was ([restore]) and reports why
     * ([report]).
     */
    suspend fun toggle(
        host: PictureInPictureHost,
        video: suspend () -> PictureInPictureVideo,
        prepare: () -> Unit,
        restore: () -> Unit,
        report: (String) -> Unit,
    ) {
        if (!host.supported) {
            report(T.videoControls.pipErrors.notSupported)
            return
        }
        if (host.active) {
            host.exit()
            return
        }
        prepare()
        delay(PREPARE_DELAY_MILLIS)
        val size = videoSize(video())
        val result = host.enter(size?.first, size?.second)
        if (result is PictureInPictureResult.Failed) {
            restore()
            report(message(result))
        }
    }
}
