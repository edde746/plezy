package com.edde746.plezy.model

import com.edde746.plezy.format.formatBitrate
import com.edde746.plezy.format.formatByteSize
import com.edde746.plezy.strings.T
import kotlin.math.abs
import kotlin.math.pow
import kotlin.math.round
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Instant

/**
 * Backend-neutral file-info payload: an item owns one or more versions (Plex `Media`, Jellyfin `MediaSources`), a
 * version owns one or more parts (Plex `Part`; a Jellyfin source always yields exactly one), and a part owns its
 * demuxed streams. Split/stacked files and multi-version libraries surface every entry.
 */
data class MediaFileInfo(
    /** Every version the server reports, in server order. */
    val versions: List<MediaFileVersion> = emptyList(),
)

/**
 * One playable version of an item: Plex `Media`, Jellyfin `MediaSources[]`. The video/audio summary fields are the
 * server's own roll-up of the primary streams, present even when no streams were probed.
 */
data class MediaFileVersion(
    val id: String? = null,
    /** Server-assigned version label (Plex `Media.title`, Jellyfin `MediaSource.Name`). */
    val title: String? = null,
    val container: String? = null,
    /** Overall bitrate in kbps. */
    val bitrateKbps: Int? = null,
    val durationMs: Int? = null,
    val width: Int? = null,
    val height: Int? = null,
    val aspectRatio: Double? = null,
    /** Server resolution label (`1080`, `4k`, `sd`). */
    val videoResolutionLabel: String? = null,
    val videoCodec: String? = null,
    val videoProfile: String? = null,
    /** Server frame-rate label (`24p`, `NTSC`). */
    val videoFrameRateLabel: String? = null,
    val audioCodec: String? = null,
    val audioProfile: String? = null,
    val audioChannels: Int? = null,
    val optimizedForStreaming: Boolean? = null,
    val has64bitOffsets: Boolean? = null,
    /** Jellyfin `Protocol` (`File`, `Http`, …). */
    val protocol: String? = null,
    /** Jellyfin `VideoType` (`VideoFile`, `Dvd`, `BluRay`, `Iso`). */
    val videoType: String? = null,
    val isRemote: Boolean? = null,
    val isInfiniteStream: Boolean? = null,
    val supportsDirectPlay: Boolean? = null,
    val supportsDirectStream: Boolean? = null,
    val supportsTranscoding: Boolean? = null,
    /** Jellyfin content ETag. */
    val eTag: String? = null,
    /** Default stream selection; `-1` on the subtitle index means "start with subtitles off". */
    val defaultAudioStreamIndex: Int? = null,
    val defaultSubtitleStreamIndex: Int? = null,
    /** Jellyfin `MediaSource.Type` (`Default`, `Grouping`, `Placeholder`). */
    val sourceType: String? = null,
    /** Plex `proxyType == 42`: a server-generated optimized copy. */
    val isOptimizedVersion: Boolean? = null,
    /** Plex `target`: the optimization profile that produced this version. */
    val optimizationTarget: String? = null,
    /** Plex `deletedAt`: an optimized version the server lists but has already deleted. */
    val deletedAt: Instant? = null,
    /** Jellyfin `Timestamp`: transport-stream timestamp mode (`None`, `Zero`, `Valid`). */
    val transportStreamTimestamp: String? = null,
    /** Plex `displayOffset`: where this version starts in a multi-part presentation, as a percentage. */
    val displayOffsetPercent: Int? = null,
    val parts: List<MediaFilePart> = emptyList(),
    /** Embedded non-media files, typically fonts an ASS subtitle track needs. */
    val attachments: List<MediaFileAttachment> = emptyList(),
) {
    val duration: Duration? get() = durationMs?.milliseconds

    val bitrateFormatted: String? get() = bitrateKbps?.let(::formatBitrate)

    val durationFormatted: String? get() = formatMediaDuration(durationMs)

    /** `1920x1080` when the server probed dimensions, otherwise its own label. */
    val resolutionFormatted: String?
        get() = if (width != null && height != null) "${width}x$height" else videoResolutionLabel

    val aspectRatioFormatted: String? get() = aspectRatio?.let { toFixed(it, 2) }

    val totalFileSize: Long get() = parts.sumOf { it.fileSize ?: 0L }

    /** Null when no part reports a size. */
    val totalFileSizeFormatted: String?
        get() = totalFileSize.let { if (it == 0L) null else formatByteSize(it) }
}

/** One file backing a version: Plex `Part`, or the Jellyfin source's own file. */
data class MediaFilePart(
    val id: String? = null,
    val filePath: String? = null,
    val fileSize: Long? = null,
    val container: String? = null,
    val durationMs: Int? = null,
    val optimizedForStreaming: Boolean? = null,
    val has64bitOffsets: Boolean? = null,
    /** The server generated preview thumbnails for this part. */
    val hasThumbnail: Boolean? = null,
    /** Which preview-thumbnail index exists (`sd`). */
    val indexes: String? = null,
    /** Packet length for transport-stream containers. */
    val packetLength: Int? = null,
    /** Why the server has no preview thumbnails for this file, and how often it has retried. */
    val previewFailureCode: Int? = null,
    val previewRetryCount: Int? = null,
    /** Whether the file is still on disk and whether the server can read it. */
    val exists: Boolean? = null,
    val accessible: Boolean? = null,
    /** Server-relative streaming path for this file. */
    val streamKey: String? = null,
    val streams: List<MediaStreamDetails> = emptyList(),
) {
    val duration: Duration? get() = durationMs?.milliseconds

    val fileSizeFormatted: String? get() = fileSize?.let { formatByteSize(it) }

    val durationFormatted: String? get() = formatMediaDuration(durationMs)

    /** Trailing segment of a `\`- or `/`-separated path. */
    val fileName: String?
        get() {
            val path = filePath
            if (path.isNullOrEmpty()) return null
            val separator = if ('\\' in path) '\\' else '/'
            return path.split(separator).lastOrNull { it.isNotEmpty() } ?: path
        }

    fun streamsOfKind(kind: MediaStreamKind): List<MediaStreamDetails> = streams.filter { it.kind == kind }
}

/** Embedded attachment (Jellyfin `MediaAttachments`). */
data class MediaFileAttachment(
    val index: Int? = null,
    val fileName: String? = null,
    val mimeType: String? = null,
    val codec: String? = null,
)

/** Colour/HDR classification of a video stream, normalised across backends. */
enum class MediaVideoRange {
    SDR,
    HDR,
    HDR10,
    HDR10_PLUS,
    HLG,
    DOLBY_VISION,
    DOLBY_VISION_HDR10,
    DOLBY_VISION_HLG,
    UNKNOWN;

    /** Untranslated trade name, as on a display's spec sheet; null for [UNKNOWN]. */
    val label: String?
        get() = when (this) {
            SDR -> "SDR"
            HDR -> "HDR"
            HDR10 -> "HDR10"
            HDR10_PLUS -> "HDR10+"
            HLG -> "HLG"
            DOLBY_VISION -> "Dolby Vision"
            DOLBY_VISION_HDR10 -> "Dolby Vision (HDR10)"
            DOLBY_VISION_HLG -> "Dolby Vision (HLG)"
            UNKNOWN -> null
        }
}

/** Dolby Vision descriptor of a video stream. */
data class MediaDolbyVisionInfo(
    val profile: Int? = null,
    val level: Int? = null,
    val version: String? = null,
    val blCompatibilityId: Int? = null,
    val blPresent: Boolean? = null,
    val elPresent: Boolean? = null,
    val rpuPresent: Boolean? = null,
    /** Server summary string (`Dolby Vision Profile 8.1 (HDR10)`). */
    val title: String? = null,
) {
    val isEmpty: Boolean
        get() = profile == null && level == null && version == null && blCompatibilityId == null &&
            blPresent == null && elPresent == null && rpuPresent == null && title == null

    /** `Profile 8.1`; the compatibility id is omitted when null or 0. Falls back to [title] without a profile. */
    val profileFormatted: String?
        get() {
            val p = profile ?: return title
            val compatibility = blCompatibilityId
            val numeric = if (compatibility == null || compatibility == 0) "$p" else "$p.$compatibility"
            return T.fileInfo.dolbyVisionProfile(numeric)
        }
}

/**
 * One demuxed stream of a part. A single class covers every kind; fields that don't apply to a kind stay null.
 */
data class MediaStreamDetails(
    val kind: MediaStreamKind,
    /** 1-based ordinal among streams of the same kind, for display. */
    val ordinal: Int,
    val id: String? = null,
    /** Container stream ordinal. */
    val index: Int? = null,
    val title: String? = null,
    /** Server-rendered summary. */
    val displayTitle: String? = null,
    val codec: String? = null,
    /** FourCC / container codec tag. */
    val codecTag: String? = null,
    val profile: String? = null,
    val level: Int? = null,
    /** Human-readable language. */
    val language: String? = null,
    /** ISO 639 code as the server reports it. */
    val languageCode: String? = null,
    /** Stream bitrate in kbps. */
    val bitrateKbps: Int? = null,
    val isDefault: Boolean? = null,
    val isForced: Boolean? = null,
    val isSelected: Boolean? = null,
    val isExternal: Boolean? = null,
    val isHearingImpaired: Boolean? = null,
    val isDub: Boolean? = null,
    val isOriginal: Boolean? = null,
    // video
    val width: Int? = null,
    val height: Int? = null,
    val codedWidth: Int? = null,
    val codedHeight: Int? = null,
    val frameRate: Double? = null,
    val scanType: String? = null,
    val isInterlaced: Boolean? = null,
    val bitDepth: Int? = null,
    val refFrames: Int? = null,
    val pixelFormat: String? = null,
    val colorSpace: String? = null,
    val colorRange: String? = null,
    val colorPrimaries: String? = null,
    val colorTransfer: String? = null,
    val chromaSubsampling: String? = null,
    val chromaLocation: String? = null,
    /** Display aspect ratio as the server words it (`16:9`, `2.35:1`). */
    val aspectRatio: String? = null,
    val pixelAspectRatio: String? = null,
    val isAnamorphic: Boolean? = null,
    val videoRange: MediaVideoRange = MediaVideoRange.UNKNOWN,
    val hasHdr10Plus: Boolean? = null,
    val dolbyVision: MediaDolbyVisionInfo? = null,
    /** Whether an H.264 stream uses the AVC (not Annex B) layout, with its NAL length prefix size. */
    val isAvc: Boolean? = null,
    val nalLengthSize: Int? = null,
    /** H.264 custom scaling matrices, which some hardware decoders reject. */
    val hasScalingMatrix: Boolean? = null,
    /** Transport-stream PID / program identifier. */
    val streamIdentifier: String? = null,
    /** Free-form stream comment tag. */
    val comment: String? = null,
    /** Clockwise display rotation in degrees. */
    val rotation: Int? = null,
    /** The track carries audio descriptions for the visually impaired. */
    val hasDescriptions: Boolean? = null,
    /** The Matroska track uses header stripping. */
    val headerCompression: Boolean? = null,
    /** On-disk path of a sidecar stream. */
    val filePath: String? = null,
    /** The stream's time base (`1/24000`). */
    val timeBase: String? = null,
    // audio
    val channels: Int? = null,
    val channelLayout: String? = null,
    val sampleRate: Int? = null,
    /** Spatial audio format enum name (`DolbyAtmos`, `DTSX`). */
    val spatialFormat: String? = null,
    // subtitle
    val isTextSubtitle: Boolean? = null,
    /** The server can hand this subtitle over as a sidecar file. */
    val supportsExternalStream: Boolean? = null,
    /** Sidecar subtitle file format. */
    val subtitleFormat: String? = null,
    /** Where a downloaded subtitle came from. */
    val providerTitle: String? = null,
    /** Match score of a downloaded/auto-selected subtitle. */
    val score: Int? = null,
    /** Server-relative path a sidecar subtitle is served from; marks the track external. */
    val externalKey: String? = null,
    /** A subtitle attached to this playback only. */
    val isTransient: Boolean? = null,
    /** The library stream a downloaded subtitle was copied from. */
    val sourceKey: String? = null,
) {
    val bitrateFormatted: String? get() = bitrateKbps?.let(::formatBitrate)

    val resolutionFormatted: String?
        get() = if (width != null && height != null) "${width}x$height" else null

    val codedResolutionFormatted: String?
        get() = if (codedWidth != null && codedHeight != null) "${codedWidth}x$codedHeight" else null

    /** `24 fps` for whole rates, otherwise three decimals (`23.976 fps`). */
    val frameRateFormatted: String?
        get() {
            val rate = frameRate ?: return null
            val rounded = round(rate)
            val text = if (abs(rate - rounded) < 0.0005) toFixed(rounded, 0) else toFixed(rate, 3)
            return "$text fps"
        }

    /** `48 kHz`, `44.1 kHz`. */
    val sampleRateFormatted: String?
        get() {
            val rate = sampleRate ?: return null
            return if (rate % 1000 == 0) "${rate / 1000} kHz" else "${toFixed(rate / 1000.0, 1)} kHz"
        }

    val bitDepthFormatted: String? get() = bitDepth?.let { "$it bit" }

    /** `5.1 (6 ch)`, `5.1`, `6 ch`. */
    val channelsFormatted: String?
        get() {
            val layout = channelLayout
            val count = channels
            return when {
                !layout.isNullOrEmpty() && count != null -> "$layout ($count ch)"
                !layout.isNullOrEmpty() -> layout
                count != null -> "$count ch"
                else -> null
            }
        }

    val isSpatialAudio: Boolean
        get() = !spatialFormat.isNullOrEmpty() && spatialFormat.lowercase() != "none"

    /** `DolbyAtmos` → `Dolby Atmos`. */
    val spatialFormatLabel: String?
        get() = if (!isSpatialAudio) null else spatialFormat!!.replace(CAMEL_BOUNDARY, " ")

    /** Server summary, else title, language, codec (first non-blank, trimmed), else `#ordinal`. */
    val headline: String
        get() = listOf(displayTitle, title, language, codec)
            .firstOrNull { !it.isNullOrBlank() }?.trim() ?: "#$ordinal"
}

private val CAMEL_BOUNDARY = Regex("(?<=[a-z0-9])(?=[A-Z])")

/** `1h 23m 45s` / `23m 45s` / `45s`. */
fun formatMediaDuration(milliseconds: Int?): String? {
    if (milliseconds == null) return null
    val totalSeconds = milliseconds / 1000
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return when {
        hours > 0 -> "${hours}h ${minutes}m ${seconds}s"
        minutes > 0 -> "${minutes}m ${seconds}s"
        else -> "${seconds}s"
    }
}

/** Fixed-point rendering with [decimals] digits, half away from zero. */
private fun toFixed(value: Double, decimals: Int): String {
    val factor = 10.0.pow(decimals)
    val scaled = round(abs(value) * factor).toLong()
    val sign = if (value < 0 && scaled != 0L) "-" else ""
    if (decimals == 0) return "$sign$scaled"
    val divisor = factor.toLong()
    val fraction = (scaled % divisor).toString().padStart(decimals, '0')
    return "$sign${scaled / divisor}.$fraction"
}
