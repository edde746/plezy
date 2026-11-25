package com.edde746.plezy.image

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.settings.VisualEffects
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** What a piece of artwork is drawn as, which decides the box the server is asked for and how it fills it. */
enum class ImageKind {
    /** A 2:3 poster. */
    POSTER,

    /** A background, authored 16:9 and drawn cropped into heroes of every shape. */
    ART,

    /** A 16:9 episode still or channel logo. */
    THUMB,

    /** A clear logo, drawn whole inside its box. */
    LOGO,

    /** A hero's large clear logo. */
    HERO_LOGO,

    /** A small square-ish person picture. */
    AVATAR,

    /** 1:1 artwork filling a grid cell: albums, artists, tracks, cast. */
    SQUARE,
    ;

    /**
     * The server sizes the image to cover the box asked for rather than fit inside it. Logos fit: they are drawn whole,
     * and covering their box overshoots the long side. Backgrounds fit too: their box is already the 16:9 frame that
     * covers the slot, so covering it again with artwork of another shape only fetches pixels that are never drawn.
     */
    val coversBox: Boolean get() = this != LOGO && this != HERO_LOGO && this != ART
}

/** A size in device pixels. */
data class PixelSize(val width: Int, val height: Int)

/**
 * What the device tells the artwork budgets ([ArtworkDisplay.of]): the display's size in pixels (null where unknown),
 * whether the process is 64-bit, the system's low-RAM flag and the total memory (null off Android).
 */
data class ArtworkDevice(
    val displayWidth: Int? = null,
    val displayHeight: Int? = null,
    val is64Bit: Boolean = true,
    val lowRamDevice: Boolean = false,
    val totalMemoryBytes: Long? = null,
) {
    /**
     * Low-end hardware, which takes the reduced visual effects tier unless the user picks otherwise: a 32-bit process
     * (cheap TV boxes and sticks run 32-bit userspace), the low-RAM flag, or at most about 2.2 GiB of memory.
     */
    val lowEndHardware: Boolean
        get() = !is64Bit || lowRamDevice || (totalMemoryBytes != null && totalMemoryBytes <= LOW_MEMORY_BYTES)

    private companion object {
        /** Above what 2 GB boxes report, below 3 GB Shield-class devices (about 2.8 GiB). */
        const val LOW_MEMORY_BYTES = 2252L shl 20
    }
}

/**
 * The display artwork is fetched for: [pixelRatio] device pixels per logical pixel, [reduced] the reduced visual
 * effects tier, [budget] the factor that scales the 1080p size caps to the display (1 to 2, 1 on the reduced tier).
 * [pixels] turns a slot measured in logical pixels into the transcode size a server is asked for.
 */
data class ArtworkDisplay(val pixelRatio: Double = 1.0, val reduced: Boolean = false, val budget: Double = 1.0) {
    /**
     * The density [kind] is fetched at: [pixelRatio] times a supersample of up to 1.5 that tapers to none at 3 device
     * pixels per logical pixel, past which the eye no longer resolves the extra detail. Backgrounds never supersample
     * (they are the largest decodes and sit under scrims), and neither does the reduced tier.
     */
    fun fetchRatio(kind: ImageKind): Double {
        if (reduced || kind == ImageKind.ART) return pixelRatio
        return pixelRatio * (SUPERSAMPLE_DENSITY_TARGET / pixelRatio).coerceIn(1.0, MAX_SUPERSAMPLE)
    }

    /**
     * The size to ask the server for when [kind] fills a [width]×[height] slot (logical pixels; an unbounded side
     * counts as 300 wide or 450 high) at [ratio] device pixels per logical pixel: a poster at 2:3 inside it, a thumb no
     * wider than 16:9, a square or avatar at its shorter side, a logo at the slot, and a background at the 16:9 frame
     * that covers the slot, 10 % over (on the reduced tier exactly, at most 1280×720). Bucketed by [rounded].
     */
    fun pixels(kind: ImageKind, width: Double, height: Double, ratio: Double = fetchRatio(kind)): PixelSize {
        val targetWidth = if (width.isFinite()) width * ratio else 300 * ratio
        val targetHeight = if (height.isFinite()) height * ratio else 450 * ratio
        return when (kind) {
            ImageKind.ART -> {
                val frameWidth = max(targetWidth, targetHeight * ART_ASPECT)
                val frameHeight = max(targetHeight, targetWidth / ART_ASPECT)
                if (reduced) {
                    rounded(min(frameWidth, REDUCED_ART_WIDTH), min(frameHeight, REDUCED_ART_HEIGHT))
                } else {
                    rounded(frameWidth * ART_OVERSHOOT, frameHeight * ART_OVERSHOOT)
                }
            }
            ImageKind.LOGO, ImageKind.HERO_LOGO -> rounded(targetWidth, targetHeight)
            ImageKind.THUMB -> rounded(min(targetWidth, targetHeight * (16.0 / 9.0)), targetHeight)
            ImageKind.AVATAR, ImageKind.SQUARE -> min(targetWidth, targetHeight).let { rounded(it, it) }
            ImageKind.POSTER -> {
                val posterWidth = min(targetWidth, targetHeight * (2.0 / 3.0))
                rounded(posterWidth, posterWidth * 1.5)
            }
        }
    }

    /**
     * [width]×[height] rounded up to the next multiple of 40 wide and 60 high, so a small resize asks for the same
     * image again, and clamped between 160×240 and 1920×1080 times [budget].
     */
    fun rounded(width: Double, height: Double): PixelSize = PixelSize(
        bucketUp(width, WIDTH_BUCKET).coerceIn(MIN_WIDTH, (MAX_WIDTH * budget).roundToInt()),
        bucketUp(height, HEIGHT_BUCKET).coerceIn(MIN_HEIGHT, (MAX_HEIGHT * budget).roundToInt()),
    )

    companion object {
        /**
         * The display for a UI drawing at [reportedPixelRatio]: raised to the display's width over 1920 (up to 3) where
         * the platform reports less than the display's real density (compositor scaling on Linux), and to at least 2 on
         * a [tv]. [visualEffects] picks the tier ([ArtworkDevice.lowEndHardware] decides Auto); off the reduced tier the
         * budget is the display's shorter side over 1080, between 1 and 2, at most 1.5 below about 2.5 GiB of memory.
         */
        fun of(reportedPixelRatio: Double, tv: Boolean, visualEffects: VisualEffects, device: ArtworkDevice): ArtworkDisplay {
            val reduced = when (visualEffects) {
                VisualEffects.AUTO -> device.lowEndHardware
                VisualEffects.FULL -> false
                VisualEffects.REDUCED -> true
            }
            var ratio = reportedPixelRatio
            device.displayWidth?.let { ratio = max(ratio, (it / 1920.0).coerceIn(1.0, 3.0)) }
            if (tv) ratio = max(ratio, TV_MIN_PIXEL_RATIO)
            return ArtworkDisplay(ratio, reduced, if (reduced) 1.0 else budget(device))
        }

        private fun budget(device: ArtworkDevice): Double {
            val width = device.displayWidth ?: return 1.0
            val height = device.displayHeight ?: return 1.0
            val shortestSide = min(width, height)
            if (shortestSide <= 0) return 1.0
            var factor = min(shortestSide / 1080.0, 2.0)
            val memory = device.totalMemoryBytes
            if (memory != null && memory < FULL_BUDGET_MEMORY_BYTES) factor = min(factor, 1.5)
            return max(factor, 1.0)
        }

        /** [value] up to the next multiple of [factor]; floating-point noise just over a multiple stays on it. */
        private fun bucketUp(value: Double, factor: Int): Int = ceil(value / factor - 1e-9).toInt() * factor

        private const val WIDTH_BUCKET = 40
        private const val HEIGHT_BUCKET = 60
        private const val MIN_WIDTH = 160
        private const val MIN_HEIGHT = 240
        private const val MAX_WIDTH = 1920
        private const val MAX_HEIGHT = 1080
        private const val REDUCED_ART_WIDTH = 1280.0
        private const val REDUCED_ART_HEIGHT = 720.0
        private const val ART_ASPECT = 16.0 / 9.0
        private const val ART_OVERSHOOT = 1.1
        private const val MAX_SUPERSAMPLE = 1.5
        private const val SUPERSAMPLE_DENSITY_TARGET = 3.0
        private const val TV_MIN_PIXEL_RATIO = 2.0

        /** Below what 3 GB Shield-class devices report, above the reduced tier's threshold. */
        private const val FULL_BUDGET_MEMORY_BYTES = 2560L shl 20
    }
}

/**
 * The URL that fetches [path] at [size] for [kind] ([ImageKind.coversBox]). A server path goes through [backend]'s
 * transcoder ([MediaBackend.thumbnailUrl]), always sized (an unsized original behind a small slot is a decode spike),
 * except one already a transcode. An absolute URL goes to a Jellyfin or Emby [backend]'s image route, which sizes its
 * own server's images and leaves another origin's alone; to another [backend]'s image proxy
 * ([MediaBackend.externalImageUrl]); or stays as it is without a backend. A server path without a backend has no URL:
 * `""`, as for an empty path.
 */
fun sizedImageUrl(backend: MediaBackend?, path: String?, kind: ImageKind, size: PixelSize): String {
    if (path.isNullOrEmpty()) return ""
    if (path.startsWith("http://") || path.startsWith("https://")) {
        if (backend == null) return path
        if (backend.backend.usesMediaBrowserApi) return backend.thumbnailUrl(path, size.width, size.height, kind.coversBox)
        return backend.externalImageUrl(path, size.width, size.height, kind.coversBox)
    }
    if (backend == null) return ""
    if ("/photo/:/transcode" in path) return backend.thumbnailUrl(path)
    return backend.thumbnailUrl(path, size.width, size.height, kind.coversBox)
}

/**
 * Artwork a UI draws at the size it measures: a server's image [path] drawn as [kind] ([of]), asked for at the slot's
 * size on the display ([url]), or an address used as it is ([fixed]: a downloaded file, an image its host already sized).
 * Equal for the same image of the same server, whatever size it is drawn at; [key] names it across sizes.
 */
class Artwork private constructor(val path: String, val kind: ImageKind, private val backend: MediaBackend?) {
    /** The image whatever size it is drawn at: its server and path, or the fixed address. */
    val key: String get() = backend?.let { "${it.serverId.value}:$path" } ?: path

    /** The URL for a [width]×[height] slot in logical pixels on [display] ([ArtworkDisplay.pixels], [sizedImageUrl]). */
    fun url(width: Double, height: Double, display: ArtworkDisplay): String =
        if (backend == null) path else sizedImageUrl(backend, path, kind, display.pixels(kind, width, height))

    override fun equals(other: Any?): Boolean =
        other is Artwork && other.path == path && other.kind == kind && other.backend === backend

    override fun hashCode(): Int = (path.hashCode() * 31 + kind.hashCode()) * 31 + (backend?.hashCode() ?: 0)

    override fun toString(): String = "Artwork($kind, $key)"

    companion object {
        /** [backend]'s image [path] drawn as [kind]; null without a backend or a path. */
        fun of(backend: MediaBackend?, path: String?, kind: ImageKind): Artwork? =
            if (backend == null || path.isNullOrEmpty()) null else Artwork(path, kind, backend)

        /** [url] as it is, whatever size it is drawn at; null when null or empty. */
        fun fixed(url: String?): Artwork? = url?.takeIf { it.isNotEmpty() }?.let { Artwork(it, ImageKind.POSTER, null) }
    }
}
