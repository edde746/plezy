package com.edde746.plezy.presentation.detail

import com.edde746.plezy.format.formatAudioChannels
import com.edde746.plezy.format.formatAudioCodec
import com.edde746.plezy.format.formatByteSize
import com.edde746.plezy.format.formatVideoCodec
import com.edde746.plezy.format.versionResolutionLabel
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaStream
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.model.MediaVersion

/**
 * The quality badges of [item]'s version [versionIndex] (the first when out of range): the resolution ("4K", "1080p"),
 * the dynamic range ("DV", "DV P8" or "HDR") and the audio ("TrueHD Atmos", "EAC3 5.1"). Empty without versions.
 */
fun mediaQualityLabels(item: MediaItem, versionIndex: Int = 0): List<String> {
    val version = selectedVersion(item.mediaVersions, versionIndex) ?: return emptyList()
    return buildList {
        resolution(version)?.let(::add)
        dynamicRange(firstStream(version, MediaStreamKind.VIDEO))?.let(::add)
        audioLabel(selectedAudio(version))?.let(::add)
    }
}

/** The picture half of [mediaQualityLabels] with the video codec: "4K", "HEVC", "DV". */
fun mediaVideoLabels(item: MediaItem, versionIndex: Int = 0): List<String> {
    val version = selectedVersion(item.mediaVersions, versionIndex) ?: return emptyList()
    val video = firstStream(version, MediaStreamKind.VIDEO)
    return buildList {
        resolution(version)?.let(::add)
        (video?.codec ?: version.videoCodec)?.trim()?.takeIf { it.isNotEmpty() }?.let { add(formatVideoCodec(it)) }
        dynamicRange(video)?.let(::add)
    }
}

/** The version's files' total size ("4.2 GB"); null when any part's size is unknown. */
fun mediaSizeLabel(item: MediaItem, versionIndex: Int = 0): String? =
    selectedVersion(item.mediaVersions, versionIndex)?.sizeBytes?.let(::formatByteSize)

private fun selectedVersion(versions: List<MediaVersion>?, index: Int): MediaVersion? =
    versions?.getOrNull(index) ?: versions?.firstOrNull()

private fun resolution(version: MediaVersion): String? =
    versionResolutionLabel(version.videoResolution, version.width, version.height)

private fun dynamicRange(video: MediaStream?): String? = when {
    video == null -> null
    video.dolbyVision -> video.dolbyVisionProfile?.takeIf { it > 0 }?.let { "DV P$it" } ?: "DV"
    video.hdr -> "HDR"
    else -> null
}

private fun firstStream(version: MediaVersion, kind: MediaStreamKind): MediaStream? =
    version.parts.firstNotNullOfOrNull { part -> part.streams.firstOrNull { it.kind == kind } }

/** The selected audio track, else the container's default, else the first. */
private fun selectedAudio(version: MediaVersion): MediaStream? {
    val audio = version.parts.flatMap { part -> part.streams.filter { it.kind == MediaStreamKind.AUDIO } }
    return audio.firstOrNull { it.selected } ?: audio.firstOrNull { it.isDefault } ?: audio.firstOrNull()
}

private fun audioLabel(stream: MediaStream?): String? {
    if (stream == null) return null
    val parts = buildList {
        stream.codec?.trim()?.takeIf { it.isNotEmpty() }?.let { add(audioCodec(it)) }
        val atmos = listOfNotNull(stream.codec, stream.title, stream.displayTitle).any { it.contains("atmos", ignoreCase = true) }
        if (atmos) add("Atmos") else formatAudioChannels(stream.channels)?.let(::add)
    }
    return parts.takeIf { it.isNotEmpty() }?.joinToString(" ")
}

/** The detail's own spellings of Dolby's codecs ("EAC3", not "E-AC3"); others as [formatAudioCodec] names them. */
private fun audioCodec(codec: String): String = when (codec.lowercase()) {
    "eac3", "ec3" -> "EAC3"
    "ac3" -> "AC3"
    else -> formatAudioCodec(codec)
}
