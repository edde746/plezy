package com.edde746.plezy.presentation.player

import com.edde746.plezy.model.MediaDolbyVisionInfo
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFilePart
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.model.MediaStreamDetails
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.model.MediaVideoRange
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.presentation.livetv.localDay
import com.edde746.plezy.presentation.livetv.localUtcOffsetSeconds
import com.edde746.plezy.presentation.livetv.localizedDate
import com.edde746.plezy.strings.T
import kotlin.time.Instant

/**
 * The file info sheet (the item menu's "File info", the player's file info page): the item's [title], then every
 * version the server reports as its own block, each fact once. Nothing is folded down to the first version, file or
 * stream; a field the server didn't report is left out, and a card without fields is too.
 */
data class FileInfoPage(val title: String, val versions: List<FileInfoVersion>)

/**
 * One version: [heading] ("Version 2 of 3") and the server's [title] for it only when there are several, then its
 * [overview], its [files], its [attachments] and its [delivery].
 */
data class FileInfoVersion(
    val heading: String?,
    val title: String?,
    val overview: FileInfoCard?,
    val files: List<FileInfoFile>,
    val attachments: FileInfoCard?,
    val delivery: FileInfoCard?,
)

/**
 * One file of a version: its [card] ("File", or "File 2 of 3" when the version has several, with the copyable path),
 * then a card per stream in the order video, audio, subtitles, lyrics, images, data; [noStreams] when the server
 * reported none ("The server reported no streams for this file.").
 */
data class FileInfoFile(val card: FileInfoCard?, val streams: List<FileInfoCard>, val noStreams: Boolean)

/**
 * A titled card: [title] (a stream's numbered when its kind has several: "Audio 2"), [subtitle] (a stream's headline,
 * the attachments' count) at its trailing edge, flag [chips], the full-width [path] that copies on a tap or select,
 * and its [fields] in a grid ([FileInfoGrid]).
 */
data class FileInfoCard(
    val kind: FileInfoCardKind,
    val title: String,
    val fields: List<FileInfoField>,
    val subtitle: String? = null,
    val chips: List<String> = emptyList(),
    val path: String? = null,
)

/** What a card describes, which picks its icon. */
enum class FileInfoCardKind { OVERVIEW, FILE, ATTACHMENTS, DELIVERY, VIDEO, AUDIO, SUBTITLES, LYRICS, IMAGES, DATA }

/** A label over its value; identifiers and paths are [monospace]. */
data class FileInfoField(val label: String, val value: String, val monospace: Boolean = false) {
    /** A value too long for half the card takes the whole row. */
    val fullWidth: Boolean get() = value.length > FULL_WIDTH_CHARS

    private companion object {
        const val FULL_WIDTH_CHARS = 42
    }
}

/** The cards' field grid: two columns where both get at least 220 points beside a 16-point gap, else one. */
object FileInfoGrid {
    const val MIN_COLUMN_WIDTH = 220f
    const val COLUMN_GAP = 16f

    fun columns(width: Float): Int = if (width >= MIN_COLUMN_WIDTH * 2 + COLUMN_GAP) 2 else 1

    /** [fields] in rows of [columns], in order; a [FileInfoField.fullWidth] field has a row of its own. */
    fun rows(fields: List<FileInfoField>, columns: Int): List<List<FileInfoField>> {
        val rows = ArrayList<List<FileInfoField>>()
        var row = ArrayList<FileInfoField>()
        for (field in fields) {
            if (row.isNotEmpty() && (field.fullWidth || row.size == columns)) {
                rows += row
                row = ArrayList()
            }
            row += field
            if (field.fullWidth) {
                rows += row
                row = ArrayList()
            }
        }
        if (row.isNotEmpty()) rows += row
        return rows
    }
}

/** Builds the [FileInfoPage] of a [MediaFileInfo]. */
object FileInfoSections {
    /**
     * The page of [info] under the item's [title]; a deletion time reads as the local date and the clock time, on a
     * 24-hour clock when [use24HourClock].
     */
    fun page(info: MediaFileInfo, title: String, use24HourClock: Boolean): FileInfoPage =
        page(info, title, use24HourClock, ::localUtcOffsetSeconds)

    /** [page] in the time zone [utcOffset] gives ([localUtcOffsetSeconds]'s shape). */
    internal fun page(info: MediaFileInfo, title: String, use24HourClock: Boolean, utcOffset: (Long) -> Int): FileInfoPage {
        val count = info.versions.size
        return FileInfoPage(
            title = title,
            versions = info.versions.mapIndexed { index, version ->
                FileInfoVersion(
                    heading = if (count > 1) T.fileInfo.versionCounter((index + 1).toString(), count.toString()) else null,
                    title = if (count > 1) version.title?.takeIf { it.isNotBlank() } else null,
                    overview = card(FileInfoCardKind.OVERVIEW, T.fileInfo.overview, overview(version)),
                    files = version.parts.mapIndexed { partIndex, part -> file(part, partIndex, version.parts.size) },
                    attachments = attachments(version),
                    delivery = card(FileInfoCardKind.DELIVERY, T.fileInfo.delivery, delivery(version, use24HourClock, utcOffset)),
                )
            },
        )
    }

    private fun overview(version: MediaFileVersion): List<FileInfoField?> {
        val text = T.fileInfo
        return listOf(
            field(text.container, version.container?.uppercase()),
            field(text.duration, version.durationFormatted),
            field(text.totalSize, version.totalFileSizeFormatted),
            field(text.overallBitrate, version.bitrateFormatted),
            field(text.resolution, version.resolutionFormatted),
            field(text.aspectRatio, version.aspectRatioFormatted),
            field(text.video, codecSummary(version.videoCodec, version.videoProfile)),
            field(text.frameRate, version.videoFrameRateLabel),
            field(text.audio, codecSummary(version.audioCodec, version.audioProfile)),
            field(text.channels, version.audioChannels?.let { "$it ch" }),
        )
    }

    private fun codecSummary(codec: String?, profile: String?): String? = when {
        codec == null -> null
        profile == null -> codec.uppercase()
        else -> "${codec.uppercase()} · $profile"
    }

    private fun delivery(version: MediaFileVersion, use24HourClock: Boolean, utcOffset: (Long) -> Int): List<FileInfoField?> {
        val text = T.fileInfo
        return listOf(
            field(text.protocol, version.protocol),
            field(text.mediaType, version.videoType),
            field(text.sourceKind, version.sourceType),
            flag(text.directPlay, version.supportsDirectPlay),
            flag(text.directStream, version.supportsDirectStream),
            flag(text.transcoding, version.supportsTranscoding),
            flag(text.optimizedForStreaming, version.optimizedForStreaming),
            flag(text.has64bitOffsets, version.has64bitOffsets),
            flag(text.optimizedVersion, version.isOptimizedVersion),
            field(text.optimizationTarget, version.optimizationTarget),
            field(text.deletedAt, version.deletedAt?.let { dateTime(it, use24HourClock, utcOffset) }),
            field(text.transportTimestamp, version.transportStreamTimestamp),
            field(text.displayOffset, version.displayOffsetPercent?.let { "$it%" }),
            flag(text.remoteSource, version.isRemote),
            flag(text.infiniteStream, version.isInfiniteStream),
            field(text.defaultAudioTrack, version.defaultAudioStreamIndex?.let(::streamIndex)),
            field(text.defaultSubtitleTrack, version.defaultSubtitleStreamIndex?.let(::streamIndex)),
            field(text.versionId, version.id, monospace = true),
            field(text.etag, version.eTag, monospace = true),
        )
    }

    /** `#3`; a negative index is Jellyfin's "start with subtitles off". */
    private fun streamIndex(index: Int): String = if (index < 0) T.fileInfo.subtitlesOff else "#$index"

    private fun dateTime(instant: Instant, use24HourClock: Boolean, utcOffset: (Long) -> Int): String {
        val millis = instant.toEpochMilliseconds()
        val date = localizedDate(localDay(millis, utcOffset), "yMMMMd", T.locale)
        return "$date ${clockTime(instant.epochSeconds, use24HourClock, utcOffset)}"
    }

    private fun attachments(version: MediaFileVersion): FileInfoCard? {
        if (version.attachments.isEmpty()) return null
        return FileInfoCard(
            FileInfoCardKind.ATTACHMENTS,
            T.fileInfo.attachments,
            version.attachments.map { attachment ->
                FileInfoField(attachment.fileName ?: "#${attachment.index ?: 0}", listOfNotNull(attachment.mimeType, attachment.codec).joinToString(" · "))
            },
            subtitle = version.attachments.size.toString(),
        )
    }

    private fun file(part: MediaFilePart, index: Int, count: Int): FileInfoFile {
        val text = T.fileInfo
        val fields = listOfNotNull(
            // Presence first: a missing file is the answer the sheet was opened for.
            flag(text.filePresent, part.exists),
            flag(text.fileReadable, part.accessible),
            field(text.fileName, part.fileName),
            field(text.size, part.fileSizeFormatted),
            field(text.container, part.container?.uppercase()),
            field(text.duration, part.durationFormatted),
            flag(text.optimizedForStreaming, part.optimizedForStreaming),
            flag(text.has64bitOffsets, part.has64bitOffsets),
            flag(text.previewThumbnails, part.hasThumbnail),
            field(text.previewIndex, part.indexes),
            field(text.packetLength, part.packetLength?.toString()),
            field(text.previewFailureCode, part.previewFailureCode?.toString()),
            field(text.previewRetries, part.previewRetryCount?.toString()),
            field(text.streamPath, part.streamKey, monospace = true),
            field(text.fileId, part.id, monospace = true),
        )
        val path = part.filePath?.trim()?.takeIf { it.isNotEmpty() }
        val title = if (count > 1) text.fileCounter((index + 1).toString(), count.toString()) else text.file
        return FileInfoFile(
            card = if (fields.isEmpty() && path == null) null else FileInfoCard(FileInfoCardKind.FILE, title, fields, path = path),
            streams = STREAM_ORDER.flatMap { (kind, cardKind) ->
                val streams = part.streams.filter { it.kind == kind }
                streams.mapNotNull { stream -> streamCard(stream, cardKind, numbered = streams.size > 1) }
            },
            noStreams = part.streams.isEmpty(),
        )
    }

    private fun streamCard(stream: MediaStreamDetails, kind: FileInfoCardKind, numbered: Boolean): FileInfoCard? {
        val fields = streamFields(stream, kind).filterNotNull()
        if (fields.isEmpty()) return null
        val name = groupTitle(kind)
        return FileInfoCard(
            kind,
            if (numbered) "$name ${stream.ordinal}" else name,
            fields,
            subtitle = stream.headline,
            chips = flags(stream),
        )
    }

    private fun groupTitle(kind: FileInfoCardKind): String = when (kind) {
        FileInfoCardKind.VIDEO -> T.fileInfo.video
        FileInfoCardKind.AUDIO -> T.fileInfo.audio
        FileInfoCardKind.SUBTITLES -> T.fileInfo.subtitles
        FileInfoCardKind.LYRICS -> T.fileInfo.lyrics
        FileInfoCardKind.IMAGES -> T.fileInfo.images
        else -> T.fileInfo.dataStreams
    }

    private fun flags(stream: MediaStreamDetails): List<String> {
        val text = T.fileInfo
        return listOfNotNull(
            text.flagDefault.takeIf { stream.isDefault == true },
            text.flagSelected.takeIf { stream.isSelected == true },
            text.flagForced.takeIf { stream.isForced == true },
            text.flagExternal.takeIf { stream.isExternal == true },
            text.flagHearingImpaired.takeIf { stream.isHearingImpaired == true },
            text.flagDub.takeIf { stream.isDub == true },
            text.flagOriginal.takeIf { stream.isOriginal == true },
        )
    }

    /** The identity fields, then the kind's own, then the container's low-level details. */
    private fun streamFields(stream: MediaStreamDetails, kind: FileInfoCardKind): List<FileInfoField?> {
        val text = T.fileInfo
        return buildList {
            add(field(text.codec, stream.codec?.uppercase()))
            add(field(text.profile, stream.profile))
            // Level 0 is both servers' "not applicable" for audio and subtitle streams.
            add(field(text.level, stream.level?.takeIf { it > 0 }?.toString()))
            add(field(text.language, stream.language))
            // A server that can't name the language echoes its code into both.
            add(field(text.languageCode, stream.languageCode?.takeIf { !it.equals(stream.language, ignoreCase = true) }))
            add(field(text.streamTitle, stream.title))
            add(field(text.bitrate, stream.bitrateFormatted))
            when (kind) {
                FileInfoCardKind.VIDEO, FileInfoCardKind.IMAGES -> addAll(videoFields(stream))
                FileInfoCardKind.AUDIO -> addAll(audioFields(stream))
                FileInfoCardKind.SUBTITLES -> addAll(subtitleFields(stream))
                else -> Unit
            }
            add(field(text.codecTag, stream.codecTag))
            add(field(text.timeBase, stream.timeBase))
            add(field(text.streamIdentifier, stream.streamIdentifier))
            add(field(text.streamIndex, stream.index?.toString()))
            add(field(text.comment, stream.comment))
            add(field(text.sidecarFile, stream.filePath, monospace = true))
            add(field(text.streamId, stream.id, monospace = true))
        }
    }

    private fun videoFields(stream: MediaStreamDetails): List<FileInfoField?> {
        val text = T.fileInfo
        val dolbyVision = stream.dolbyVision
        return listOf(
            field(text.resolution, stream.resolutionFormatted),
            field(text.codedResolution, stream.codedResolutionFormatted),
            field(text.aspectRatio, stream.aspectRatio),
            field(text.pixelAspectRatio, stream.pixelAspectRatio),
            field(text.frameRate, stream.frameRateFormatted),
            field(text.rotation, stream.rotation?.let { "$it°" }),
            field(text.dynamicRange, dynamicRange(stream)),
            field(text.bitDepth, stream.bitDepthFormatted),
            field(text.pixelFormat, stream.pixelFormat),
            field(text.colorSpace, stream.colorSpace),
            field(text.colorRange, stream.colorRange),
            field(text.colorPrimaries, stream.colorPrimaries),
            field(text.colorTransfer, stream.colorTransfer),
            field(text.chromaSubsampling, stream.chromaSubsampling),
            field(text.chromaLocation, stream.chromaLocation),
            field(text.scanType, stream.scanType),
            flag(text.interlaced, stream.isInterlaced),
            flag(text.anamorphic, stream.isAnamorphic),
            field(text.referenceFrames, stream.refFrames?.toString()),
        ) + (dolbyVision?.let(::dolbyVisionFields) ?: emptyList()) + listOf(
            flag(text.avcBitstream, stream.isAvc),
            field(text.nalLengthSize, stream.nalLengthSize?.toString()),
            flag(text.scalingMatrix, stream.hasScalingMatrix),
        )
    }

    private fun dolbyVisionFields(info: MediaDolbyVisionInfo): List<FileInfoField?> {
        val text = T.fileInfo
        val layers = listOfNotNull("BL".takeIf { info.blPresent == true }, "EL".takeIf { info.elPresent == true }, "RPU".takeIf { info.rpuPresent == true })
        return listOf(
            field(text.dolbyVision, info.profileFormatted),
            field(text.dolbyVisionLevel, info.level?.toString()),
            field(text.dolbyVisionVersion, info.version),
            field(text.dolbyVisionLayers, layers.takeIf { it.isNotEmpty() }?.joinToString(" + ")),
            field(text.baseLayerCompatibility, info.blCompatibilityId?.toString()),
        )
    }

    /** The range's label; HDR10+ is its own flag, so it is added to the base range rather than replacing it. */
    private fun dynamicRange(stream: MediaStreamDetails): String? {
        val label = stream.videoRange.label
        val hdr10Plus = stream.hasHdr10Plus == true
        return when {
            label == null -> if (hdr10Plus) MediaVideoRange.HDR10_PLUS.label else null
            !hdr10Plus || stream.videoRange == MediaVideoRange.HDR10_PLUS -> label
            else -> "$label + ${MediaVideoRange.HDR10_PLUS.label}"
        }
    }

    private fun audioFields(stream: MediaStreamDetails): List<FileInfoField?> {
        val text = T.fileInfo
        return listOf(
            field(text.channels, stream.channelsFormatted),
            field(text.sampleRate, stream.sampleRateFormatted),
            field(text.bitDepth, stream.bitDepthFormatted),
            field(text.spatialAudio, stream.spatialFormatLabel),
        )
    }

    private fun subtitleFields(stream: MediaStreamDetails): List<FileInfoField?> {
        val text = T.fileInfo
        return listOf(
            flag(text.textBased, stream.isTextSubtitle),
            flag(text.externalDelivery, stream.supportsExternalStream),
            field(text.subtitleFormat, stream.subtitleFormat),
            field(text.provider, stream.providerTitle),
            field(text.matchScore, stream.score?.toString()),
            flag(text.audioDescription, stream.hasDescriptions),
            flag(text.headerCompression, stream.headerCompression),
            flag(text.temporary, stream.isTransient),
            field(text.sourceStream, stream.sourceKey, monospace = true),
            field(text.sidecarPath, stream.externalKey, monospace = true),
        )
    }

    private fun card(kind: FileInfoCardKind, title: String, fields: List<FileInfoField?>): FileInfoCard? =
        fields.filterNotNull().takeIf { it.isNotEmpty() }?.let { FileInfoCard(kind, title, it) }

    /** Null for a value the server didn't report or left blank. */
    private fun field(label: String, value: String?, monospace: Boolean = false): FileInfoField? =
        value?.trim()?.takeIf { it.isNotEmpty() }?.let { FileInfoField(label, it, monospace) }

    private fun flag(label: String, value: Boolean?): FileInfoField? =
        value?.let { FileInfoField(label, if (it) T.common.yes else T.common.no) }

    /** Video first, then audio, subtitles, lyrics, images, data, then anything unknown (drawn as data). */
    private val STREAM_ORDER = listOf(
        MediaStreamKind.VIDEO to FileInfoCardKind.VIDEO,
        MediaStreamKind.AUDIO to FileInfoCardKind.AUDIO,
        MediaStreamKind.SUBTITLE to FileInfoCardKind.SUBTITLES,
        MediaStreamKind.LYRIC to FileInfoCardKind.LYRICS,
        MediaStreamKind.IMAGE to FileInfoCardKind.IMAGES,
        MediaStreamKind.DATA to FileInfoCardKind.DATA,
        MediaStreamKind.UNKNOWN to FileInfoCardKind.DATA,
    )
}
