package com.edde746.plezy.model

import com.edde746.plezy.format.formatBitrate
import com.edde746.plezy.format.formatVideoCodec
import com.edde746.plezy.format.versionResolutionLabel
import com.edde746.plezy.strings.T
import kotlin.math.roundToInt

/** Bits per second as kbps (rounded), null when unknown or not positive. */
fun bitrateKbpsFromBps(bps: Long?): Int? = if (bps == null || bps <= 0) null else (bps / 1000.0).roundToInt()

/** One version of an item: a Plex `Media`, a MediaBrowser `MediaSources` entry. */
data class MediaVersion(
    val id: String,
    val width: Int? = null,
    val height: Int? = null,
    /** The server's resolution name: "1080", "4k", "sd". */
    val videoResolution: String? = null,
    val videoCodec: String? = null,
    /** kbps. */
    val bitrate: Int? = null,
    val container: String? = null,
    val parts: List<MediaPart> = emptyList(),
    /** The version's own name (a Jellyfin source name, a Plex edition). */
    val name: String? = null,
) {
    val isPlayable: Boolean get() = parts.isEmpty() || parts.any { it.isPlayable }

    /** The parts' total size; null without parts or when any part's size is unknown. */
    val sizeBytes: Long?
        get() = if (parts.isEmpty()) null else parts.sumOf { part -> part.sizeBytes?.takeIf { it > 0 } ?: return null }

    /** The frame height: reported, else the named tier (sd 480, hd 720, 4k 2160, 8k 4320), else a numeric name. */
    val resolutionHeight: Int?
        get() {
            if (height != null && height > 0) return height
            return when (val named = (videoResolution ?: "").trim().lowercase()) {
                "" -> null
                "sd" -> 480
                "hd" -> 720
                "4k" -> 2160
                "8k" -> 4320
                else -> named.toIntOrNull()
            }
        }

    /**
     * `1080p HEVC MKV (8.5 Mbps)`, prefixed `"{name} · "` when named (the name alone without technical data). A name that
     * is or starts with the resolution (`720p`, `720p Remux`) says it once: `720p · H.264 MP4 (1.2 Mbps)`.
     */
    val displayLabel: String
        get() {
            val resolution = versionResolutionLabel(videoResolution, width, height)
            val namesResolution = resolution != null && name?.startsWith(resolution, ignoreCase = true) == true
            val labelParts = buildList {
                if (resolution != null && !namesResolution) add(resolution)
                if (!videoCodec.isNullOrEmpty()) add(formatVideoCodec(videoCodec))
                if (!container.isNullOrEmpty()) add(container.uppercase())
            }
            var label = if (labelParts.isNotEmpty()) labelParts.joinToString(" ") else T.common.unknown
            val hasBitrate = bitrate != null && bitrate > 0
            if (hasBitrate) label += " (${formatBitrate(bitrate!!)})"
            if (!name.isNullOrEmpty()) return if (labelParts.isEmpty() && !hasBitrate) name else "$name · $label"
            return label
        }

    /** `"{resolution}:{codec}:{container}"` lower-cased: matches the same version across sibling episodes. */
    val signature: String get() = "${videoResolution ?: ""}:${videoCodec ?: ""}:${container ?: ""}".lowercase()

    private val resolutionPart get() = (videoResolution ?: "").lowercase()
    private val codecPart get() = (videoCodec ?: "").lowercase()

    companion object {
        /**
         * The index of the version best matching any of [acceptedSignatures]. Tiers apply across every accepted signature
         * before the next: exact signature, then resolution and codec, then resolution. Within a tier the accepted set's
         * order decides, then the versions' order. Signatures without exactly three fields are skipped.
         */
        fun findMatchingIndex(versions: List<MediaVersion>, acceptedSignatures: Collection<String>): Int? {
            if (versions.isEmpty() || acceptedSignatures.isEmpty()) return null
            val accepted = acceptedSignatures.mapNotNull { signature ->
                val fields = signature.split(':')
                if (fields.size != 3) null else Triple(signature, fields[0], fields[1])
            }
            for ((signature) in accepted) {
                versions.indexOfFirst { it.signature == signature }.takeIf { it >= 0 }?.let { return it }
            }
            for ((_, resolution, codec) in accepted) {
                versions.indexOfFirst { it.resolutionPart == resolution && it.codecPart == codec }.takeIf { it >= 0 }?.let { return it }
            }
            for ((_, resolution) in accepted) {
                versions.indexOfFirst { it.resolutionPart == resolution }.takeIf { it >= 0 }?.let { return it }
            }
            return null
        }
    }
}

/** One file of a version. Plex stacks a version over several; MediaBrowser always has one. */
data class MediaPart(
    val id: String,
    /** The backend-relative path that streams the file. */
    val streamPath: String? = null,
    /** The file's path on the server. */
    val file: String? = null,
    val sizeBytes: Long? = null,
    val container: String? = null,
    val durationMs: Long? = null,
    /** Plex sets these two only when asked to check files. */
    val accessible: Boolean? = null,
    val exists: Boolean? = null,
    /** Not persisted with the item. */
    val streams: List<MediaStream> = emptyList(),
) {
    val isPlayable: Boolean get() = accessible != false && exists != false

    companion object
}

enum class MediaStreamKind { VIDEO, AUDIO, SUBTITLE, IMAGE, DATA, LYRIC, UNKNOWN }

/** A stream inside a part. */
data class MediaStream(
    val id: String,
    val kind: MediaStreamKind,
    val index: Int? = null,
    val codec: String? = null,
    val language: String? = null,
    val languageCode: String? = null,
    val title: String? = null,
    val displayTitle: String? = null,
    val selected: Boolean = false,
    val isDefault: Boolean = false,
    val channels: Int? = null,
    val frameRate: Double? = null,
    val hdr: Boolean = false,
    val dolbyVision: Boolean = false,
    val dolbyVisionProfile: Int? = null,
    val forced: Boolean = false,
    /** A subtitle file beside the video. */
    val sidecarPath: String? = null,
) {
    val isExternal: Boolean get() = !sidecarPath.isNullOrEmpty()
}

/** A cast or crew credit. */
data class MediaRole(val id: String? = null, val tag: String, val role: String? = null, val thumbPath: String? = null) {
    companion object
}

/** An attributed score normalized to 0–10. */
data class MediaRatingSource(val source: String, val value: Double, val votes: Int? = null) {
    companion object {
        /** [value] on a 0–[scale] scale as 0–10; null when missing, NaN, not positive, past [scale], or without votes. */
        fun fromScale(source: String, value: Double?, scale: Double, votes: Long? = null): MediaRatingSource? {
            if (value == null || value.isNaN() || value <= 0 || value > scale) return null
            if (votes != null && votes <= 0) return null
            return MediaRatingSource(source, value * 10 / scale, votes?.toInt())
        }
    }
}
