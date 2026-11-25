package com.edde746.plezy.plex

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaAudioTrack
import com.edde746.plezy.model.MediaDolbyVisionInfo
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFilePart
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaStreamDetails
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.MediaVideoRange
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlin.time.Duration
import kotlin.time.Instant

private const val TAG = "PlexPlaybackMapper"

/** `Media.proxyType` of a server-generated optimized version. */
private const val OPTIMIZED_PROXY_TYPE = 42

/** What playback of one item opens: the chosen part's URL, its source description, and every version to pick from. */
data class PlexVideoPlaybackData(
    val videoUrl: String?,
    val mediaInfo: MediaSourceInfo?,
    val availableVersions: List<MediaVersion>,
    val selectedMediaIndex: Int = 0,
    val selectedPartIndex: Int = 0,
) {
    val hasValidVideoUrl: Boolean get() = !videoUrl.isNullOrEmpty()
}

/**
 * The playback data of a `/library/metadata/{id}` row, the version and part chosen by [resolvePlexPlaybackSelection].
 * The URL is [baseUrl] + the part's `key`, with [token] appended. Without a usable part the URL and source are null.
 */
fun parsePlexVideoPlaybackDataFromJson(
    metadataJson: JsonObject?,
    baseUrl: String,
    token: String?,
    mediaIndex: Int = 0,
    selectedMediaSourceId: String? = null,
    preferredVersionSignature: String? = null,
    onVersionFallback: ((requestedIndex: Int, fallbackIndex: Int) -> Unit)? = null,
    position: Duration? = null,
): PlexVideoPlaybackData {
    val empty = PlexVideoPlaybackData(videoUrl = null, mediaInfo = null, availableVersions = emptyList())
    if (metadataJson == null) return empty
    val selection = resolvePlexPlaybackSelection(
        metadataJson,
        mediaIndex = mediaIndex,
        mediaSourceId = selectedMediaSourceId,
        preferredVersionSignature = preferredVersionSignature,
        onVersionFallback = onVersionFallback,
        position = position,
    ) ?: return empty
    val partKey = selection.media[selection.mediaIndex]["Part"].objectList().getOrNull(selection.partIndex)?.get("key").scalarString()
    val videoUrl = partKey?.let { withPlexToken("$baseUrl$it", token) }
    return PlexVideoPlaybackData(
        videoUrl = videoUrl,
        mediaInfo = videoUrl?.let { plexMediaSourceInfoForSelection(metadataJson, selection, videoUrl = it) },
        availableVersions = selection.versions,
        selectedMediaIndex = selection.mediaIndex,
        selectedPartIndex = selection.partIndex,
    )
}

/** A part's streams as playback reads them: the first video stream, every audio and subtitle track. */
internal class PlexPlaybackStreams(
    val videoStream: JsonObject?,
    val audioTracks: List<MediaAudioTrack>,
    val subtitleTracks: List<MediaSubtitleTrack>,
)

/** Reads `Part.Stream[]`; an audio or subtitle stream without a numeric id cannot be selected and is skipped. */
internal fun plexPlaybackStreams(streams: JsonElement?): PlexPlaybackStreams {
    var videoStream: JsonObject? = null
    val audio = ArrayList<MediaAudioTrack>()
    val subtitles = ArrayList<MediaSubtitleTrack>()
    for (stream in streams.objectList()) {
        val type = stream["streamType"].flexInt()
        if (type == PLEX_STREAM_VIDEO) {
            if (videoStream == null) videoStream = stream
            continue
        }
        if (type != PLEX_STREAM_AUDIO && type != PLEX_STREAM_SUBTITLE) continue
        val id = stream["id"].flexInt()
        if (id == null) {
            Log.d(TAG) { "Skipping a Plex stream without a numeric id" }
            continue
        }
        if (type == PLEX_STREAM_AUDIO) {
            audio += MediaAudioTrack(
                id = id,
                index = stream["index"].flexInt(),
                codec = stream["codec"].stringOrNull(),
                language = stream["language"].stringOrNull(),
                languageCode = stream["languageCode"].stringOrNull(),
                title = stream["title"].stringOrNull(),
                displayTitle = stream["displayTitle"].stringOrNull(),
                channels = stream["channels"].flexInt(),
                selected = stream["selected"].flexBool(),
                isDefault = stream["default"].flexBool(),
            )
        } else {
            subtitles += MediaSubtitleTrack(
                id = id,
                index = stream["index"].flexInt(),
                codec = stream["codec"].stringOrNull(),
                language = stream["language"].stringOrNull(),
                languageCode = stream["languageCode"].stringOrNull(),
                title = stream["title"].stringOrNull(),
                displayTitle = stream["displayTitle"].stringOrNull(),
                selected = stream["selected"].flexBool(),
                forced = stream["forced"].flexBool(),
                key = stream["key"].stringOrNull(),
            )
        }
    }
    return PlexPlaybackStreams(videoStream, audio, subtitles)
}

/**
 * The file-info payload of a `/library/metadata/{id}` row: every `Media` (version), `Part` (file) and stream. Streams
 * are descriptive here, so one without a usable id is kept. Null without `Media`.
 */
fun parsePlexFileInfoFromJson(metadataJson: JsonObject?): MediaFileInfo? {
    val media = metadataJson?.get("Media").objectList()
    if (media.isEmpty()) return null
    return MediaFileInfo(versions = media.map(::plexFileVersion))
}

private fun plexFileVersion(media: JsonObject): MediaFileVersion {
    val proxyType = media["proxyType"]
    return MediaFileVersion(
        id = media["id"].scalarString(),
        title = media.plexString("title"),
        container = media.plexString("container"),
        bitrateKbps = media["bitrate"].flexInt(),
        durationMs = media["duration"].flexInt(),
        width = media["width"].flexInt(),
        height = media["height"].flexInt(),
        aspectRatio = media["aspectRatio"].flexDouble(),
        videoResolutionLabel = media.plexString("videoResolution"),
        videoCodec = media.plexString("videoCodec"),
        videoProfile = media.plexString("videoProfile"),
        videoFrameRateLabel = media.plexString("videoFrameRate"),
        audioCodec = media.plexString("audioCodec"),
        audioProfile = media.plexString("audioProfile"),
        audioChannels = media["audioChannels"].flexInt(),
        optimizedForStreaming = media["optimizedForStreaming"].flexBoolOrNull(),
        has64bitOffsets = media["has64bitOffsets"].flexBoolOrNull(),
        isOptimizedVersion = if (proxyType.scalarString() == null) null else proxyType.flexInt() == OPTIMIZED_PROXY_TYPE,
        optimizationTarget = media.plexString("target"),
        deletedAt = media["deletedAt"].flexLong()?.let { Instant.fromEpochSeconds(it) },
        displayOffsetPercent = media["displayOffset"].flexInt(),
        parts = media["Part"].objectList().map(::plexFilePart),
    )
}

private fun plexFilePart(part: JsonObject): MediaFilePart = MediaFilePart(
    id = part["id"].scalarString(),
    filePath = part.plexString("file"),
    fileSize = part["size"].flexLong(),
    container = part.plexString("container"),
    durationMs = part["duration"].flexInt(),
    optimizedForStreaming = part["optimizedForStreaming"].flexBoolOrNull(),
    has64bitOffsets = part["has64bitOffsets"].flexBoolOrNull(),
    hasThumbnail = part["hasThumbnail"].flexBoolOrNull(),
    indexes = part.plexString("indexes"),
    packetLength = part["packetLength"].flexInt(),
    previewFailureCode = part["failureBIFResultCode"].flexInt(),
    previewRetryCount = part["failureBIFRetryCount"].flexInt(),
    exists = part["exists"].flexBoolOrNull(),
    accessible = part["accessible"].flexBoolOrNull(),
    streamKey = part.plexString("key"),
    streams = plexStreamDetailsList(part["Stream"]),
)

private fun plexStreamDetailsList(streams: JsonElement?): List<MediaStreamDetails> {
    val ordinals = HashMap<MediaStreamKind, Int>()
    return streams.objectList().map { stream ->
        val kind = plexStreamKind(stream)
        val ordinal = (ordinals[kind] ?: 0) + 1
        ordinals[kind] = ordinal
        plexStreamDetails(stream, kind, ordinal)
    }
}

/** Plex stream types 1–4; type 4 is lyrics. */
private fun plexStreamKind(stream: JsonObject): MediaStreamKind = when (stream["streamType"].flexInt()) {
    PLEX_STREAM_VIDEO -> MediaStreamKind.VIDEO
    PLEX_STREAM_AUDIO -> MediaStreamKind.AUDIO
    PLEX_STREAM_SUBTITLE -> MediaStreamKind.SUBTITLE
    PLEX_STREAM_LYRICS -> MediaStreamKind.LYRIC
    else -> MediaStreamKind.UNKNOWN
}

private fun plexStreamDetails(s: JsonObject, kind: MediaStreamKind, ordinal: Int): MediaStreamDetails {
    val dolbyVision = plexDolbyVision(s)
    return MediaStreamDetails(
        kind = kind,
        ordinal = ordinal,
        id = s["id"].scalarString(),
        index = s["index"].flexInt(),
        title = s["title"].trimmedText(),
        displayTitle = s["extendedDisplayTitle"].trimmedText() ?: s["displayTitle"].trimmedText(),
        codec = s["codec"].trimmedText(),
        codecTag = s["codecID"].trimmedText(),
        profile = s["profile"].trimmedText(),
        level = s["level"].flexInt(),
        language = s["language"].trimmedText(),
        languageCode = s["languageCode"].trimmedText() ?: s["languageTag"].trimmedText(),
        // Plex reports stream bitrates in kbps already.
        bitrateKbps = s["bitrate"].flexInt(),
        isDefault = s["default"].flexBoolOrNull(),
        isForced = s["forced"].flexBoolOrNull(),
        isSelected = s["selected"].flexBoolOrNull(),
        // Plex marks a sidecar subtitle by its `/library/streams/…` key, not a flag.
        isExternal = if (kind == MediaStreamKind.SUBTITLE) !s["key"].stringOrNull().isNullOrEmpty() else null,
        isHearingImpaired = s["hearingImpaired"].flexBoolOrNull(),
        isDub = s["dub"].flexBoolOrNull(),
        isOriginal = s["original"].flexBoolOrNull(),
        width = s["width"].flexInt(),
        height = s["height"].flexInt(),
        codedWidth = s["codedWidth"].flexInt(),
        codedHeight = s["codedHeight"].flexInt(),
        frameRate = s["frameRate"].flexDouble(),
        scanType = s["scanType"].trimmedText(),
        isInterlaced = s["scanType"].trimmedText()?.let { it.lowercase() != "progressive" },
        bitDepth = s["bitDepth"].flexInt(),
        refFrames = s["refFrames"].flexInt(),
        colorSpace = s["colorSpace"].trimmedText(),
        colorRange = s["colorRange"].trimmedText(),
        colorPrimaries = s["colorPrimaries"].trimmedText(),
        colorTransfer = s["colorTrc"].trimmedText(),
        chromaSubsampling = s["chromaSubsampling"].trimmedText(),
        chromaLocation = s["chromaLocation"].trimmedText(),
        pixelAspectRatio = s["pixelAspectRatio"].trimmedText(),
        isAnamorphic = s["anamorphic"].flexBoolOrNull(),
        videoRange = if (kind == MediaStreamKind.VIDEO) plexVideoRange(s, dolbyVision) else MediaVideoRange.UNKNOWN,
        dolbyVision = dolbyVision,
        hasScalingMatrix = s["hasScalingMatrix"].flexBoolOrNull(),
        streamIdentifier = s["streamIdentifier"].trimmedText(),
        channels = s["channels"].flexInt(),
        channelLayout = s["audioChannelLayout"].trimmedText(),
        sampleRate = s["samplingRate"].flexInt(),
        subtitleFormat = s["format"].trimmedText(),
        providerTitle = s["providerTitle"].trimmedText(),
        score = s["score"].flexInt(),
        externalKey = s["key"].trimmedText(),
        isTransient = s["transient"].flexBoolOrNull(),
        sourceKey = s["sourceKey"].trimmedText(),
        comment = s["comment"].trimmedText(),
        hasDescriptions = s["descriptions"].flexBoolOrNull(),
        headerCompression = s["headerCompression"].flexBoolOrNull(),
    )
}

private fun plexDolbyVision(s: JsonObject): MediaDolbyVisionInfo? {
    if (!s["DOVIPresent"].flexBool()) return null
    return MediaDolbyVisionInfo(
        profile = s["DOVIProfile"].flexInt(),
        level = s["DOVILevel"].flexInt(),
        version = s["DOVIVersion"].trimmedText(),
        blCompatibilityId = s["DOVIBLCompatID"].flexInt(),
        blPresent = s["DOVIBLPresent"].flexBoolOrNull(),
        elPresent = s["DOVIELPresent"].flexBoolOrNull(),
        rpuPresent = s["DOVIRPUPresent"].flexBoolOrNull(),
    )
}

/**
 * Plex sends no dynamic-range field: the Dolby Vision block decides first (base-layer compatibility 4 HLG; profile 7
 * or compatibility 1/6 HDR10), else the transfer characteristics.
 */
private fun plexVideoRange(s: JsonObject, dolbyVision: MediaDolbyVisionInfo?): MediaVideoRange {
    if (dolbyVision != null) {
        val compatibility = dolbyVision.blCompatibilityId
        if (compatibility == 4) return MediaVideoRange.DOLBY_VISION_HLG
        if (dolbyVision.profile == 7 || compatibility == 1 || compatibility == 6) return MediaVideoRange.DOLBY_VISION_HDR10
        return MediaVideoRange.DOLBY_VISION
    }
    return when (s["colorTrc"].trimmedText()?.lowercase()) {
        "smpte2084" -> MediaVideoRange.HDR10
        "arib-std-b67" -> MediaVideoRange.HLG
        null -> MediaVideoRange.UNKNOWN
        else -> MediaVideoRange.SDR
    }
}
