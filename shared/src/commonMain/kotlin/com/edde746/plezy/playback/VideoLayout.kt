package com.edde746.plezy.playback

import com.edde746.plezy.settings.AppSettings
import kotlinx.serialization.Serializable
import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.round
import kotlin.math.roundToInt

/**
 * How the picture fills the player; this device keeps the last one chosen, per library or title as its scope says
 * (`ScopedPlayerPrefs.boxFitMode`).
 */
@Serializable
enum class VideoFit {
    /** The whole picture, with bars where its shape differs from the player's (letterbox). */
    CONTAIN,

    /** The player filled, the picture cropped where it runs past the player's edges. */
    COVER,

    /** The player filled, the picture stretched to the player's shape. */
    FILL,
}

/**
 * How the picture shows in the player: its [fit] and the viewer's [zoom] on top of it, a factor (1.0 for none) kept in
 * whole percent from [MIN_ZOOM] to [MAX_ZOOM] ([normalizeZoom]). The player store sends it to the engine
 * ([PlayerEngine.setVideoLayout]); [DEFAULT] while the player shows in a picture-in-picture window.
 */
data class VideoLayout(val fit: VideoFit = VideoFit.CONTAIN, val zoom: Double = 1.0) {
    /** The picture runs past the player's edges: cropped to fill it ([VideoFit.COVER]), or zoomed in. */
    val overflows: Boolean get() = fit == VideoFit.COVER || zoom > 1.0 + EPSILON

    /** mpv's `video-zoom`: [zoom] as a power of two, 0 at 1.0. */
    val videoZoom: Double get() = if (abs(zoom - 1.0) < EPSILON) 0.0 else ln(zoom) / ln(2.0)

    /**
     * The mpv properties of this layout where mpv scales the picture itself, as `name` to value:
     * - `panscan` 1 crops the picture to fill the surface ([VideoFit.COVER]), 0 fits it;
     * - `video-aspect-override` gives the picture the surface's shape ([VideoFit.FILL], from [surfaceAspect], the
     *   surface's width over its height: the engine follows its surface's size), `no` keeps the picture's own; a fill
     *   before the surface's size is known keeps the picture's own too;
     * - `video-zoom`, [videoZoom], on top of either;
     * - `sub-ass-force-margins` keeps styled subtitles on the surface while the picture runs past it ([overflows]).
     */
    fun properties(surfaceAspect: Double?): Map<String, String> = linkedMapOf(
        "panscan" to if (fit == VideoFit.COVER) "1" else "0",
        "video-aspect-override" to (surfaceAspect?.takeIf { fit == VideoFit.FILL && it.isFinite() && it > 0.0 }?.let(::number) ?: "no"),
        "video-zoom" to number(videoZoom),
        "sub-ass-force-margins" to if (overflows) "yes" else "no",
    )

    companion object {
        val DEFAULT = VideoLayout()

        const val MIN_ZOOM = 0.5
        const val MAX_ZOOM = 2.0

        /** Zooming in or out by key moves the zoom by this. */
        const val ZOOM_STEP = 0.01

        /** The zoom menu's entries. */
        val ZOOM_PRESETS: List<Double> = listOf(0.5, 0.75, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.75, 2.0)

        /** [zoom] within [MIN_ZOOM]–[MAX_ZOOM], to the whole percent; exactly 1.0 at 100 %. */
        fun normalizeZoom(zoom: Double): Double {
            if (!zoom.isFinite()) return 1.0
            val percent = (zoom.coerceIn(MIN_ZOOM, MAX_ZOOM) * 100).roundToInt()
            return if (percent == 100) 1.0 else percent / 100.0
        }

        /** [zoom] in whole percent, as the menus and messages show it. */
        fun percent(zoom: Double): Int = (zoom * 100).roundToInt()

        private const val EPSILON = 1e-4

        /** To 4 decimals, so the values read as written. */
        private fun number(value: Double): String {
            val rounded = round(value * 10_000) / 10_000
            return if (rounded == round(rounded)) rounded.toLong().toString() else rounded.toString()
        }
    }
}
