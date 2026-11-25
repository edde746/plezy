package com.edde746.plezy.jellyfin

import com.edde746.plezy.format.resolutionLabelFromDimensions
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaAudioTrack
import com.edde746.plezy.model.MediaChapter
import com.edde746.plezy.model.MediaDolbyVisionInfo
import com.edde746.plezy.model.MediaFileAttachment
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFilePart
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.model.MediaMarker
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaStreamDetails
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.MediaVideoRange
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.TrickplayInfo
import com.edde746.plezy.model.bitrateKbpsFromBps
import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.playback.ChapterMarkerClassifier
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull

/**
 * What playback reads off one item detail fetch: the chosen `MediaSources` entry, every source as a version, and the
 * item-level `Chapters` and `Trickplay` (MediaBrowser keeps both outside the source).
 */
internal data class JellyfinPlaybackBundle(
    val availableVersions: List<MediaVersion>,
    val selectedSource: JsonObject,
    val chapters: JsonArray,
    val container: String?,
    val selectedSourceId: String?,
    val selectedSourceIndex: Int,
    val trickplay: JsonElement?,
) {
    /**
     * The source id to pin in stream and download URLs; null when the server named none. Never invented: the server
     * compares it ordinally and then parses it as a GUID, so a made-up id turns a working request into a 400/500.
     */
    val pinnedSourceId: String? get() = selectedSourceId?.trim()?.ifEmpty { null }

    companion object {
        /**
         * The bundle of an item DTO; null without a usable `MediaSources` entry. [sourceId] wins (plugins may reorder
         * merged sources between requests), then [preferredSignature] (a saved version preference), then
         * [sourceIndex]; out of range falls back to 0.
         */
        fun fromItem(raw: JsonObject, sourceIndex: Int = 0, sourceId: String? = null, preferredSignature: String? = null): JellyfinPlaybackBundle? {
            val sources = raw.array("MediaSources")?.takeIf { it.isNotEmpty() } ?: return null
            val versions = JellyfinMediaInfo.sourcesToVersions(sources)
            var index = sourceIndex
            val requested = sourceId?.trim()?.ifEmpty { null }
            val byId = if (requested == null) -1 else sources.indexOfFirst { (it as? JsonObject)?.str("Id") == requested }
            if (byId >= 0) {
                index = byId
            } else if (!preferredSignature.isNullOrEmpty()) {
                MediaVersion.findMatchingIndex(versions, setOf(preferredSignature))?.let { index = it }
            }
            if (index !in sources.indices) index = 0
            val source = sources[index] as? JsonObject ?: return null
            return JellyfinPlaybackBundle(
                availableVersions = versions,
                selectedSource = source,
                chapters = raw.array("Chapters") ?: JsonArray(emptyList()),
                container = source.str("Container"),
                selectedSourceId = source.str("Id"),
                selectedSourceIndex = index,
                trickplay = raw["Trickplay"],
            )
        }
    }
}

/** MediaBrowser source, chapter, segment and file-info JSON → neutral playback model. Pure. */
internal object JellyfinMediaInfo {
    private const val TAG = "JellyfinMediaInfo"

    /**
     * A `MediaSources` entry as the player's track and chapter model. [chapters] and [trickplay] are the item's own
     * (the source has neither). The server's default indexes decide the selected rows: a null subtitle index means
     * "no subtitle" (the user's SubtitleMode None), so the container's default/forced flags never select one.
     * No partId: track choices persist through progress reports, not a part endpoint.
     */
    fun mediaSourceInfo(source: JsonObject, chapters: JsonArray? = null, trickplay: JsonElement? = null, mediaIndex: Int? = null): MediaSourceInfo {
        var videoStream: JsonObject? = null
        val audio = mutableListOf<MediaAudioTrack>()
        val subtitles = mutableListOf<MediaSubtitleTrack>()
        for (s in source.objects("MediaStreams")) {
            when (s.str("Type")?.lowercase()) {
                "video" -> if (videoStream == null) videoStream = s
                "audio" -> {
                    val f = JellyfinStreamFields.parse(s, fallbackIndex = audio.size + 1)
                    audio += MediaAudioTrack(
                        id = f.index, index = f.index, codec = f.codec, language = f.language, languageCode = f.languageCode,
                        title = f.title, displayTitle = f.displayTitle, channels = f.channels, selected = f.isDefault,
                        isDefault = f.isDefault, external = f.isExternal,
                    )
                }
                "subtitle" -> {
                    val f = JellyfinStreamFields.parse(s, fallbackIndex = subtitles.size + 1)
                    subtitles += MediaSubtitleTrack(
                        id = f.index, index = f.index, codec = f.codec, language = f.language, languageCode = f.languageCode,
                        title = f.title, displayTitle = f.displayTitle, selected = f.isDefault, forced = f.isForced,
                        key = if (f.isExternal) f.deliveryUrl else null, external = f.isExternalFile,
                        usesExternalDelivery = f.usesExternalDelivery,
                    )
                }
            }
        }
        val defaultAudio = source["DefaultAudioStreamIndex"].flexibleLong()?.toInt()
        val defaultSubtitle = source["DefaultSubtitleStreamIndex"].flexibleLong()?.toInt()
        val mappedChapters = mutableListOf<MediaChapter>()
        chapters?.forEachIndexed { i, entry ->
            if (entry !is JsonObject) return@forEachIndexed
            val start = JellyfinTime.ticksToMs(entry["StartPositionTicks"].flexibleLong()) ?: 0L
            mappedChapters += MediaChapter(id = i, index = i, startTimeOffset = start, title = entry.str("Name"))
        }
        MediaChapter.backfillEndOffsets(mappedChapters)
        val mediaSourceId = source.str("Id")
        val width = videoStream?.get("Width").flexibleLong()
        val height = videoStream?.get("Height").flexibleLong()
        return MediaSourceInfo(
            videoUrl = "",
            audioTracks = if (defaultAudio == null) audio else audio.map { it.withSelected(it.index == defaultAudio) },
            subtitleTracks = subtitles.map { it.withSelected(defaultSubtitle != null && it.index == defaultSubtitle) },
            chapters = mappedChapters,
            displayCriteria = jellyfinDisplayCriteria(source, videoStream),
            mediaSourceId = mediaSourceId,
            mediaIndex = mediaIndex,
            defaultAudioStreamIndex = defaultAudio,
            defaultSubtitleStreamIndex = defaultSubtitle,
            trickplayByWidth = trickplayManifest(trickplay, mediaSourceId),
            // The Emby BIF tooltip's aspect; Jellyfin's tiles carry their own.
            videoAspectRatio = if (width != null && height != null && height > 0) width.toDouble() / height else null,
        )
    }

    /**
     * One version per source for the version picker: id = source `Id` (else its position), stream path = the source
     * id, each source's own length. `Name` only when the names differ: a single source's name is the item title.
     */
    fun sourcesToVersions(sources: List<JsonElement>): List<MediaVersion> {
        val useName = sources.mapNotNull { (it as? JsonObject)?.str("Name")?.ifEmpty { null } }.toSet().size > 1
        return sources.mapIndexedNotNull { i, element ->
            val source = element as? JsonObject ?: return@mapIndexedNotNull null
            val sourceId = source.str("Id").orEmpty()
            JellyfinMappers.sourceToVersion(
                source,
                versionId = sourceId.ifEmpty { "$i" },
                partId = "$i",
                streamPath = sourceId,
                includePartDuration = true,
                name = if (useName) source.str("Name") else null,
            )
        }
    }

    /**
     * Chapters of an item DTO (thumbnails `/Items/{id}/Images/Chapter/{i}?tag=…` when tagged, ends back-filled to the
     * runtime) with intro/credits [markers] filled in from chapter names where the server sent none.
     */
    fun playbackExtras(
        raw: JsonObject?,
        itemId: String,
        introPattern: String? = null,
        creditsPattern: String? = null,
        forceChapterFallback: Boolean = false,
        markers: List<MediaMarker> = emptyList(),
    ): PlaybackExtras {
        val mapped = mutableListOf<MediaChapter>()
        raw?.array("Chapters")?.forEachIndexed { i, entry ->
            if (entry !is JsonObject) return@forEachIndexed
            val start = JellyfinTime.ticksToMs(entry["StartPositionTicks"].flexibleLong()) ?: 0L
            val tag = entry.str("ImageTag")?.ifEmpty { null }
            val thumb = tag?.let { "/Items/${UriComponent.encode(itemId)}/Images/Chapter/$i?tag=${UriComponent.encode(it)}" }
            mapped += MediaChapter(id = i, index = i, startTimeOffset = start, title = (entry["Name"] as? JsonPrimitive)?.content, thumb = thumb)
        }
        MediaChapter.backfillEndOffsets(mapped, runtimeMs = JellyfinTime.ticksToMs(raw?.get("RunTimeTicks").flexibleLong()))
        return PlaybackExtras.withChapterFallback(
            chapters = mapped,
            markers = markers,
            classifier = ChapterMarkerClassifier.bundled,
            introPattern = introPattern,
            creditsPattern = creditsPattern,
            forceChapterFallback = forceChapterFallback,
        )
    }

    /** `/MediaSegments/{id}` items: Intro → intro, Outro/Credits → credits; other types and empty spans are dropped. */
    fun segmentMarkers(raw: JsonElement?): List<MediaMarker> {
        val items = (raw as? JsonObject)?.get("Items") ?: raw
        if (items !is JsonArray) return emptyList()
        return items.mapIndexedNotNull { i, entry ->
            if (entry !is JsonObject) return@mapIndexedNotNull null
            val type = when ((entry["Type"] as? JsonPrimitive)?.content?.lowercase()) {
                "intro" -> MediaMarker.INTRO
                "outro", "credits" -> MediaMarker.CREDITS
                else -> return@mapIndexedNotNull null
            }
            val start = JellyfinTime.ticksToMs(entry["StartTicks"].flexibleLong()) ?: return@mapIndexedNotNull null
            val end = JellyfinTime.ticksToMs(entry["EndTicks"].flexibleLong()) ?: return@mapIndexedNotNull null
            if (end <= start) null else MediaMarker(id = i, type = type, startTimeOffset = start, endTimeOffset = end)
        }
    }

    /**
     * `BaseItemDto.Trickplay` by tile width. Two shapes exist: flat `{width: info}` (the OpenAPI one) and nested
     * `{sourceId: {width: info}}`. Nested needs the selected source's entry, or, without a source id, exactly one
     * candidate: another version's tiles would show the wrong picture. Null when missing, ambiguous or empty.
     */
    private fun trickplayManifest(raw: JsonElement?, sourceId: String?): Map<Int, TrickplayInfo>? {
        if (raw !is JsonObject || raw.isEmpty()) return null
        val byWidth: JsonObject = if (raw.values.any { it is JsonObject && "Width" in it && "Height" in it }) {
            raw
        } else if (sourceId != null) {
            raw[sourceId] as? JsonObject ?: return null
        } else {
            raw.values.filterIsInstance<JsonObject>().singleOrNull() ?: return null
        }
        val result = mutableMapOf<Int, TrickplayInfo>()
        for ((key, value) in byWidth) {
            if (value !is JsonObject) continue
            val width = key.toIntOrNull() ?: value["Width"].flexibleLong()?.toInt() ?: continue
            val height = value["Height"].flexibleLong()?.toInt() ?: continue
            val tileWidth = value["TileWidth"].flexibleLong()?.toInt() ?: continue
            val tileHeight = value["TileHeight"].flexibleLong()?.toInt() ?: continue
            val count = value["ThumbnailCount"].flexibleLong()?.toInt() ?: continue
            val interval = value["Interval"].flexibleLong()?.toInt() ?: continue
            if (listOf(width, height, tileWidth, tileHeight, count, interval).any { it <= 0 }) continue
            result[width] = TrickplayInfo(width, height, tileWidth, tileHeight, count, interval, value["Bandwidth"].flexibleLong()?.toInt() ?: 0)
        }
        return result.ifEmpty { null }
    }

    /**
     * Every `MediaSources` entry for the file-info sheet; a source is one file, so each version has one part. A
     * malformed source, stream or attachment is skipped so it doesn't cost the user the rest.
     */
    fun fileInfo(item: JsonObject): MediaFileInfo? {
        val sources = item.array("MediaSources")?.takeIf { it.isNotEmpty() } ?: return null
        val versions = sources.filterIsInstance<JsonObject>().mapNotNull { source ->
            try {
                fileVersion(source)
            } catch (e: Exception) {
                Log.w(TAG, e) { "Skipping malformed media source" }
                null
            }
        }
        return if (versions.isEmpty()) null else MediaFileInfo(versions)
    }

    private fun fileVersion(source: JsonObject): MediaFileVersion {
        val ordinals = mutableMapOf<MediaStreamKind, Int>()
        val streams = source.objects("MediaStreams").mapNotNull { s ->
            try {
                val kind = streamKind(s)
                val ordinal = (ordinals[kind] ?: 0) + 1
                ordinals[kind] = ordinal
                streamDetails(s, kind, ordinal)
            } catch (e: Exception) {
                Log.w(TAG, e) { "Skipping malformed stream metadata" }
                null
            }
        }
        val video = streams.firstOrNull { it.kind == MediaStreamKind.VIDEO }
        val audio = streams.firstOrNull { it.kind == MediaStreamKind.AUDIO }
        val width = video?.width
        val height = video?.height
        val durationMs = JellyfinTime.ticksToMs(source["RunTimeTicks"].flexibleLong())?.toInt()
        return MediaFileVersion(
            id = text(source["Id"]),
            title = text(source["Name"]),
            container = text(source["Container"]),
            bitrateKbps = bitrateKbpsFromBps(source["Bitrate"].flexibleLong()),
            durationMs = durationMs,
            width = width,
            height = height,
            aspectRatio = aspectRatio(video?.aspectRatio, width, height),
            videoResolutionLabel = resolutionLabelFromDimensions(width, height),
            videoCodec = video?.codec,
            videoProfile = video?.profile,
            videoFrameRateLabel = video?.frameRateFormatted,
            audioCodec = audio?.codec,
            audioProfile = audio?.profile,
            audioChannels = audio?.channels,
            protocol = text(source["Protocol"]),
            videoType = text(source["VideoType"]),
            sourceType = text(source["Type"]),
            isRemote = bool(source["IsRemote"]),
            isInfiniteStream = bool(source["IsInfiniteStream"]),
            supportsDirectPlay = bool(source["SupportsDirectPlay"]),
            supportsDirectStream = bool(source["SupportsDirectStream"]),
            supportsTranscoding = bool(source["SupportsTranscoding"]),
            eTag = text(source["ETag"]),
            transportStreamTimestamp = text(source["Timestamp"]),
            defaultAudioStreamIndex = source["DefaultAudioStreamIndex"].flexibleLong()?.toInt(),
            defaultSubtitleStreamIndex = source["DefaultSubtitleStreamIndex"].flexibleLong()?.toInt(),
            parts = listOf(
                MediaFilePart(
                    id = text(source["Id"]),
                    filePath = text(source["Path"]),
                    fileSize = source["Size"].flexibleLong(),
                    container = text(source["Container"]),
                    durationMs = durationMs,
                    streams = streams,
                ),
            ),
            attachments = source.objects("MediaAttachments").map { a ->
                // Live servers fill `CodecTag`; `Codec` is in the DTO but usually null.
                MediaFileAttachment(a["Index"].flexibleLong()?.toInt(), text(a["FileName"]), text(a["MimeType"]), text(a["Codec"]) ?: text(a["CodecTag"]))
            },
        )
    }

    private fun streamKind(s: JsonObject): MediaStreamKind = when (s.str("Type")?.lowercase()) {
        "video" -> MediaStreamKind.VIDEO
        "audio" -> MediaStreamKind.AUDIO
        "subtitle" -> MediaStreamKind.SUBTITLE
        "embeddedimage" -> MediaStreamKind.IMAGE
        "lyric" -> MediaStreamKind.LYRIC
        "data" -> MediaStreamKind.DATA
        else -> MediaStreamKind.UNKNOWN
    }

    private fun streamDetails(s: JsonObject, kind: MediaStreamKind, ordinal: Int): MediaStreamDetails {
        val interlaced = bool(s["IsInterlaced"])
        fun int(key: String) = s[key].flexibleLong()?.toInt()
        return MediaStreamDetails(
            kind = kind,
            ordinal = ordinal,
            index = int("Index"),
            title = text(s["Title"]),
            displayTitle = text(s["DisplayTitle"]),
            codec = text(s["Codec"]),
            codecTag = text(s["CodecTag"]),
            profile = text(s["Profile"]),
            level = int("Level"),
            language = text(s["DisplayLanguage"]) ?: text(s["Language"]),
            languageCode = text(s["Language"]),
            bitrateKbps = bitrateKbpsFromBps(s["BitRate"].flexibleLong()),
            isDefault = bool(s["IsDefault"]),
            isForced = bool(s["IsForced"]),
            isExternal = bool(s["IsExternal"]),
            isHearingImpaired = bool(s["IsHearingImpaired"]),
            width = int("Width"),
            height = int("Height"),
            frameRate = double(s["RealFrameRate"]) ?: double(s["AverageFrameRate"]),
            scanType = interlaced?.let { if (it) "interlaced" else "progressive" },
            isInterlaced = interlaced,
            bitDepth = int("BitDepth"),
            refFrames = int("RefFrames"),
            pixelFormat = text(s["PixelFormat"]),
            colorSpace = text(s["ColorSpace"]),
            colorRange = text(s["ColorRange"]),
            colorPrimaries = text(s["ColorPrimaries"]),
            colorTransfer = text(s["ColorTransfer"]),
            aspectRatio = text(s["AspectRatio"]),
            isAnamorphic = bool(s["IsAnamorphic"]),
            videoRange = if (kind == MediaStreamKind.VIDEO) videoRange(s) else MediaVideoRange.UNKNOWN,
            hasHdr10Plus = bool(s["Hdr10PlusPresentFlag"]),
            dolbyVision = dolbyVision(s),
            isAvc = bool(s["IsAVC"]),
            nalLengthSize = int("NalLengthSize"),
            channels = int("Channels"),
            channelLayout = text(s["ChannelLayout"]),
            sampleRate = int("SampleRate"),
            spatialFormat = text(s["AudioSpatialFormat"]),
            isTextSubtitle = bool(s["IsTextSubtitleStream"]),
            supportsExternalStream = bool(s["SupportsExternalStream"]),
            score = int("Score"),
            timeBase = text(s["TimeBase"]),
            externalKey = text(s["DeliveryUrl"]),
            comment = text(s["Comment"]),
            rotation = int("Rotation"),
            filePath = text(s["Path"]),
        )
    }

    private fun dolbyVision(s: JsonObject): MediaDolbyVisionInfo? {
        val major = s["DvVersionMajor"].flexibleLong()
        val minor = s["DvVersionMinor"].flexibleLong()
        val info = MediaDolbyVisionInfo(
            profile = s["DvProfile"].flexibleLong()?.toInt(),
            level = s["DvLevel"].flexibleLong()?.toInt(),
            version = major?.let { "$it.${minor ?: 0}" },
            blCompatibilityId = s["DvBlSignalCompatibilityId"].flexibleLong()?.toInt(),
            blPresent = bool(s["BlPresentFlag"]),
            elPresent = bool(s["ElPresentFlag"]),
            rpuPresent = bool(s["RpuPresentFlag"]),
            title = text(s["VideoDoViTitle"]),
        )
        return if (info.isEmpty) null else info
    }

    private fun videoRange(s: JsonObject): MediaVideoRange {
        val type = text(s["VideoRangeType"])?.lowercase()
        if (type != null && type != "unknown") {
            if (type.startsWith("dovi")) {
                return when {
                    "hlg" in type -> MediaVideoRange.DOLBY_VISION_HLG
                    "hdr10" in type -> MediaVideoRange.DOLBY_VISION_HDR10
                    else -> MediaVideoRange.DOLBY_VISION
                }
            }
            return when (type) {
                "sdr" -> MediaVideoRange.SDR
                "hdr10" -> MediaVideoRange.HDR10
                "hdr10plus" -> MediaVideoRange.HDR10_PLUS
                "hlg" -> MediaVideoRange.HLG
                else -> MediaVideoRange.HDR
            }
        }
        return when (text(s["VideoRange"])?.lowercase()) {
            "sdr" -> MediaVideoRange.SDR
            "hdr" -> MediaVideoRange.HDR
            else -> MediaVideoRange.UNKNOWN
        }
    }

    /** The declared display ratio (`2.35:1`), else the probed dimensions. */
    private fun aspectRatio(declared: String?, width: Int?, height: Int?): Double? {
        if (declared != null && ':' in declared) {
            val parts = declared.split(':')
            val numerator = parts[0].trim().toDoubleOrNull()
            val denominator = parts[1].trim().toDoubleOrNull()
            if (numerator != null && denominator != null && denominator != 0.0) return numerator / denominator
        }
        return if (width != null && height != null && height != 0) width.toDouble() / height else null
    }

    /** Trimmed, empty as null; a server may send a number where a string is documented. */
    private fun text(e: JsonElement?): String? = (e as? JsonPrimitive)?.takeIf { it !is JsonNull }?.content?.trim()?.ifEmpty { null }

    private fun bool(e: JsonElement?): Boolean? {
        val p = e as? JsonPrimitive ?: return null
        p.booleanOrNull?.let { return it }
        return when (p.content.lowercase()) {
            "1" -> true
            "0" -> false
            else -> null
        }
    }

    private fun double(e: JsonElement?): Double? = (e as? JsonPrimitive)?.content?.toDoubleOrNull()
}
