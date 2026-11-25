package com.edde746.plezy.plex

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.BifScrubPreviewSource
import com.edde746.plezy.backend.DownloadArtworkSpec
import com.edde746.plezy.backend.DownloadPartResolution
import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.DownloadSubtitleSpec
import com.edde746.plezy.backend.ExternalPlaybackTarget
import com.edde746.plezy.backend.PLAYBACK_METADATA_CACHE_FRESHNESS
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.PlaybackSubtitleSidecar
import com.edde746.plezy.backend.ScrubPreviewSource
import com.edde746.plezy.backend.StackedScrubPreviewSource
import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.backend.TranscodeFallbackReason
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.buildArtworkSpecs
import com.edde746.plezy.backend.classifyPlaybackFailure
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.backend.net.fetchWithCacheFallback
import com.edde746.plezy.backend.net.fetchWithCacheFirst
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.format.isTranscodableSubtitleCodec
import com.edde746.plezy.format.subtitleExtension
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.findSourceAudioTrackForIntent
import com.edde746.plezy.model.findSourceTrackForIntent
import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.playback.ChapterMarkerClassifier
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

private const val TAG = "PlexPlayback"

private const val MALFORMED_PLAYBACK_METADATA = "Malformed Plex playback metadata"

private val PLAYBACK_METADATA_QUERY = mapOf("includeMarkers" to 1, "includeChapters" to 1, "checkFiles" to 1, "includeStreams" to 1)

/** Plex's `streamType` of a lyrics sidecar. */
private const val LYRICS_STREAM_TYPE = 4

/** A subtitle an external provider (OpenSubtitles…) offers through the server's subtitle search. */
data class PlexSubtitleSearchResult(
    val id: Int,
    val key: String,
    val codec: String? = null,
    val language: String? = null,
    val languageCode: String? = null,
    val score: Double? = null,
    val providerTitle: String? = null,
    val title: String? = null,
    val displayTitle: String? = null,
    val hearingImpaired: Boolean = false,
    val perfectMatch: Boolean = false,
    val downloaded: Boolean = false,
    val forced: Boolean = false,
) {
    companion object {
        fun fromJson(json: JsonObject) = PlexSubtitleSearchResult(
            id = json["id"].flexInt() ?: 0,
            key = json["key"].scalarString() ?: "",
            codec = json["codec"].scalarString(),
            language = json["language"].scalarString(),
            languageCode = json["languageCode"].scalarString(),
            score = json["score"].flexDouble(),
            providerTitle = json["providerTitle"].scalarString(),
            title = json["title"].scalarString(),
            displayTitle = json["displayTitle"].scalarString(),
            hearingImpaired = json["hearingImpaired"].flexBool(),
            perfectMatch = json["perfectMatch"].flexBool(),
            downloaded = json["downloaded"].flexBool(),
            forced = json["forced"].flexBool(),
        )
    }
}

/** A transcode's start path (relative, without the token) and the decision that produced it. */
data class PlexTranscodeStart(val startPath: String?, val outcome: TranscodeDecisionOutcome)

private data class DecisionResult(val startPath: String?, val outcome: TranscodeDecisionOutcome, val containerHonored: Boolean)

private fun JsonObject?.firstMetadata(): JsonObject? = mediaContainer()?.get("Metadata").firstObject()

// Playback metadata.

/**
 * The playback data of [ratingKey]. A fresh (5 min) cached row with stream detail answers without a request unless
 * [forceRefresh] (pollers waiting for a server-side change need it); otherwise the full playback query, falling back to
 * the cached row when the request fails. A malformed envelope throws; a valid row without a playable part yields data
 * without a URL. [position] (item time) picks the file of a version stacked over several.
 */
suspend fun PlexClient.getVideoPlaybackData(
    ratingKey: String,
    mediaIndex: Int = 0,
    selectedMediaSourceId: String? = null,
    preferredVersionSignature: String? = null,
    position: Duration? = null,
    forceRefresh: Boolean = false,
): PlexVideoPlaybackData {
    val cacheKey = "/library/metadata/$ratingKey"
    fun parse(metadata: JsonObject?) = parsePlexVideoPlaybackDataFromJson(
        metadata,
        baseUrl = config.baseUrl,
        token = config.token,
        mediaIndex = mediaIndex,
        selectedMediaSourceId = selectedMediaSourceId,
        preferredVersionSignature = preferredVersionSignature,
        onVersionFallback = { requested, fallback ->
            Log.w(TAG) { "Version $requested inaccessible/missing — falling back to version $fallback" }
        },
        position = position,
    )
    if (!forceRefresh) {
        val fresh = cache.store.getIfFresh(cacheServerId, cacheKey, PLAYBACK_METADATA_CACHE_FRESHNESS)
        if (fresh != null) {
            try {
                val metadata = validatedPlaybackMetadata(fresh)
                if (metadata != null && plexMetadataHasStreamDetail(metadata)) return parse(metadata)
            } catch (_: IllegalArgumentException) {
                // A malformed cached row: the network read below overwrites it.
            }
        }
    }
    val data = fetchWithCacheFallback(
        cache = cache.store,
        cacheServerId = cacheServerId,
        cacheKey = cacheKey,
        offline = isOfflineMode,
        networkCall = { http.get(cacheKey, PLAYBACK_METADATA_QUERY) },
        parseCache = { it },
        parseResponse = { response -> responseObject(response.data) },
    )
    return parse(validatedPlaybackMetadata(data))
}

private fun responseObject(data: JsonElement?): JsonObject? = when (data) {
    null, JsonNull -> null
    is JsonObject -> data
    else -> throw IllegalArgumentException(MALFORMED_PLAYBACK_METADATA)
}

/**
 * The first `Metadata` entry of a playback body. The container must be an object and `Metadata` a list; `Media` and
 * `Part` may be one object or a list holding objects. Empty `Metadata` is null.
 */
private fun validatedPlaybackMetadata(data: JsonObject?): JsonObject? {
    if (data == null) return null
    val container = data["MediaContainer"] as? JsonObject ?: throw IllegalArgumentException(MALFORMED_PLAYBACK_METADATA)
    val metadata = playbackObjects(container["Metadata"], allowSingleton = false)
    val selected = metadata.firstOrNull() ?: return null
    for (media in playbackObjects(selected["Media"])) playbackObjects(media["Part"])
    return selected
}

private fun playbackObjects(value: JsonElement?, allowSingleton: Boolean = true): List<JsonObject> {
    if (value == null || value is JsonNull) return emptyList()
    if (allowSingleton && value is JsonObject) return listOf(value)
    if (value is JsonArray) {
        if (value.isEmpty()) return emptyList()
        val objects = value.filterIsInstance<JsonObject>()
        if (objects.isNotEmpty()) return objects
    }
    throw IllegalArgumentException(MALFORMED_PLAYBACK_METADATA)
}

/**
 * Whether every part of the row carries the keys `includeStreams=1` and `checkFiles=1` add. A fully probed part may
 * report `Stream: []`; a row without media needs nothing more.
 */
private fun plexMetadataHasStreamDetail(metadata: JsonObject?): Boolean =
    metadata?.get("Media").objectList().all { media ->
        media["Part"].objectList().all { "Stream" in it && "exists" in it && "accessible" in it }
    }

// Playback initialization.

internal suspend fun PlexClient.getPlaybackInitializationImpl(options: PlaybackInitializationOptions): PlaybackInitializationResult {
    try {
        val data = getVideoPlaybackData(
            options.metadata.id,
            mediaIndex = options.selectedMediaIndex,
            selectedMediaSourceId = options.selectedMediaSourceId,
            preferredVersionSignature = options.preferredVersionSignature,
            position = options.startPosition,
        )
        if (!data.hasValidVideoUrl) throw PlaybackException(T.messages.fileInfoNotAvailable, PlaybackFailureReason.NO_PLAYABLE_SOURCE)
        val mediaInfo = data.mediaInfo
        val carriedAudio = if (options.selectedAudioStreamId == null) options.preferredAudioTrack else null
        val carriedAudioStreamId = if (carriedAudio == null || mediaInfo == null) {
            null
        } else {
            findSourceAudioTrackForIntent(carriedAudio, mediaInfo.audioTracks)?.id
        }

        // Tracks follow the music preset; the video preset is ignored for audio.
        val isTrack = options.metadata.kind == MediaKind.TRACK
        val audioPreset = options.audioQualityPreset ?: AudioQualityPreset.ORIGINAL
        val sourceCodecRefused = !isTrack && sourceCodecRefused(data)
        val wantTranscode = if (isTrack) {
            !audioPreset.isOriginal
        } else {
            sourceCodecRefused || options.forceTranscode || presetNeedsTranscode(options.qualityPreset, data)
        }
        val sessionIdentifier = options.sessionIdentifier
        val transcodeSessionId = options.transcodeSessionId
        if (wantTranscode && sessionIdentifier != null && transcodeSessionId != null) {
            if (isTrack) {
                val result = buildMusicTranscodeStartPath(
                    ratingKey = options.metadata.id,
                    mediaIndex = data.selectedMediaIndex,
                    partIndex = data.selectedPartIndex,
                    preset = audioPreset,
                    sessionIdentifier = sessionIdentifier,
                    transcodeSessionId = transcodeSessionId,
                )
                if (result.outcome == TranscodeDecisionOutcome.TRANSCODE_OK && result.startPath != null) {
                    return PlaybackInitializationResult(
                        availableVersions = data.availableVersions,
                        videoUrl = withPlexToken(config.baseUrl + result.startPath, config.token),
                        mediaInfo = mediaInfo,
                        isTranscoding = true,
                        playMethod = "Transcode",
                        playSessionId = sessionIdentifier,
                        selectedMediaIndex = data.selectedMediaIndex,
                    )
                }
                return transcodeFallbackResult(data, result.outcome, options)
            }

            val resolvedAudioId = if (carriedAudio == null) resolveAudioStreamId(options.selectedAudioStreamId, mediaInfo) else carriedAudioStreamId
            val requestedSubtitle = resolveTranscodeSubtitleTrack(mediaInfo, options.preferredSubtitleTrack)
            val result = buildTranscodeStartPath(
                ratingKey = options.metadata.id,
                mediaIndex = data.selectedMediaIndex,
                partIndex = data.selectedPartIndex,
                preset = options.qualityPreset,
                sessionIdentifier = sessionIdentifier,
                transcodeSessionId = transcodeSessionId,
                audioStreamId = resolvedAudioId,
                selectedSubtitleTrack = requestedSubtitle,
                partId = mediaInfo?.partId,
                withholdDirectPlay = sourceCodecRefused || options.forceTranscode,
            )
            // A transcode that cannot carry the requested embedded subtitle (a codec the burn path refuses went out as
            // `subtitles=none`) is not what was asked for: direct play delivers the track instead.
            val burnUndeliverable = requestsSubtitleBurn(requestedSubtitle) && burnableSubtitle(requestedSubtitle) == null
            if (!burnUndeliverable && result.outcome == TranscodeDecisionOutcome.TRANSCODE_OK && result.startPath != null) {
                return PlaybackInitializationResult(
                    availableVersions = data.availableVersions,
                    videoUrl = withPlexToken(config.baseUrl + result.startPath, config.token),
                    mediaInfo = mediaInfo,
                    subtitleSidecars = transcodeSidecarSubtitles(mediaInfo),
                    isTranscoding = true,
                    activeAudioStreamId = resolvedAudioId,
                    playMethod = "Transcode",
                    playSessionId = sessionIdentifier,
                    selectedMediaIndex = data.selectedMediaIndex,
                )
            }
            if (options.forceTranscode) throw forcedTranscodeUnavailable(result.outcome)
            return transcodeFallbackResult(data, result.outcome, options, activeAudioStreamId = carriedAudioStreamId)
        }
        if (options.forceTranscode && !isTrack) throw forcedTranscodeUnavailable(null)

        return PlaybackInitializationResult(
            availableVersions = data.availableVersions,
            videoUrl = trackStreamUrl(data.videoUrl, options),
            mediaInfo = mediaInfo,
            subtitleSidecars = externalSubtitles(mediaInfo),
            activeAudioStreamId = carriedAudioStreamId,
            playMethod = "DirectPlay",
            playSessionId = sessionIdentifier,
            selectedMediaIndex = data.selectedMediaIndex,
        )
    } catch (e: PlaybackException) {
        throw e
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        throw classifyPlaybackFailure(e)
    }
}

private fun selectedVersion(data: PlexVideoPlaybackData): MediaVersion? = data.availableVersions.getOrNull(data.selectedMediaIndex)

/**
 * Whether [preset] asks for less than the selected version delivers. A version that fits under the cap plays the file
 * itself (PMS answers "Direct play OK" whatever cap the request carries, so the client decides); the
 * `directPlayCoveredQuality` setting off makes every non-original preset transcode.
 */
private fun PlexClient.presetNeedsTranscode(preset: TranscodeQualityPreset, data: PlexVideoPlaybackData): Boolean {
    if (preset.isOriginal) return false
    if (!environment.directPlayCoveredQuality()) return true
    val version = selectedVersion(data)
    if (!preset.coversSource(version?.bitrate, version?.resolutionHeight)) return true
    Log.i(TAG) { "Preset ${preset.name} covers the source (${version?.bitrate} kbps, ${version?.resolutionHeight}p); playing the file directly" }
    return false
}

/** Whether the user refused the selected version's video codec: it transcodes at every preset, Original included. */
private fun PlexClient.sourceCodecRefused(data: PlexVideoPlaybackData): Boolean {
    val codec = selectedVersion(data)?.videoCodec ?: return false
    if (!environment.isVideoCodecRefused(codec)) return false
    Log.i(TAG) { "Source codec $codec is refused in settings; transcoding" }
    return true
}

/** A forced transcode the server would not start: the file it already refused is no answer. */
private fun forcedTranscodeUnavailable(outcome: TranscodeDecisionOutcome?): PlaybackException {
    Log.w(TAG) { "Forced transcode unavailable (${outcome?.name ?: "no transcode session"}); not falling back to the file" }
    return PlaybackException(T.messages.serverLimitBody, PlaybackFailureReason.NO_PLAYABLE_SOURCE)
}

private fun PlexClient.transcodeFallbackResult(
    data: PlexVideoPlaybackData,
    outcome: TranscodeDecisionOutcome,
    options: PlaybackInitializationOptions,
    activeAudioStreamId: Int? = null,
): PlaybackInitializationResult {
    val reason = if (outcome == TranscodeDecisionOutcome.DIRECT_PLAY_ONLY) {
        TranscodeFallbackReason.DIRECT_PLAY_ONLY
    } else {
        TranscodeFallbackReason.DECISION_FAILED
    }
    Log.w(TAG) { "Transcode decision fell back to direct play: ${reason.name}" }
    return PlaybackInitializationResult(
        availableVersions = data.availableVersions,
        videoUrl = trackStreamUrl(data.videoUrl, options),
        mediaInfo = data.mediaInfo,
        subtitleSidecars = externalSubtitles(data.mediaInfo),
        fallbackReason = reason,
        activeAudioStreamId = activeAudioStreamId,
        playMethod = "DirectPlay",
        playSessionId = options.sessionIdentifier,
        selectedMediaIndex = data.selectedMediaIndex,
    )
}

/**
 * [url] naming the playback session in its query when it streams a track. Tracks get no session header: gapless
 * playback opens the next track with the playing one's headers, which would name the wrong session.
 */
private fun trackStreamUrl(url: String?, options: PlaybackInitializationOptions): String? {
    val session = options.sessionIdentifier
    if (url == null || session == null || options.metadata.kind != MediaKind.TRACK) return url
    val separator = if ('?' in url) '&' else '?'
    return "$url${separator}X-Plex-Session-Identifier=${UriComponent.encode(session)}"
}

/** The audio stream sent to the transcoder: [explicit], else the selected track, else the first, else none. */
private fun resolveAudioStreamId(explicit: Int?, info: MediaSourceInfo?): Int? {
    if (explicit != null) return explicit
    val tracks = info?.audioTracks.orEmpty()
    return (tracks.firstOrNull { it.selected } ?: tracks.firstOrNull())?.id
}

private fun selectedSubtitleTrack(info: MediaSourceInfo): MediaSubtitleTrack? = info.subtitleTracks.firstOrNull { it.selected }

/** The subtitle a transcode should carry: no preference keeps the server's selection, Off none, a track its match. */
private fun resolveTranscodeSubtitleTrack(info: MediaSourceInfo?, preferred: SubtitlePreference?): MediaSubtitleTrack? {
    if (info == null) return null
    return when (preferred) {
        null -> selectedSubtitleTrack(info)
        SubtitlePreference.Off -> null
        is SubtitlePreference.Track -> findSourceTrackForIntent(preferred, info.subtitleTracks) ?: selectedSubtitleTrack(info)
    }
}

/** The embedded stream a transcode burns in: a keyless track in a codec the transcoder can deliver; else null. */
private fun burnableSubtitle(track: MediaSubtitleTrack?): MediaSubtitleTrack? {
    if (track == null || !track.key.isNullOrEmpty()) return null
    return if (isTranscodableSubtitleCodec(track.codec)) track else null
}

/** Whether [track] is one a transcode would have to burn, whatever its codec. */
private fun requestsSubtitleBurn(track: MediaSubtitleTrack?): Boolean = track != null && track.key.isNullOrEmpty()

/** The tokened URL of an external subtitle file; null for an embedded track or without a token. */
fun PlexClient.buildExternalSubtitleUrl(track: MediaSubtitleTrack): String? {
    val key = track.key
    if (!track.isExternal || key.isNullOrEmpty()) return null
    val token = config.token ?: return null
    return "${config.baseUrl}$key.${subtitleExtension(track.codec)}?encoding=utf-8&X-Plex-Token=$token"
}

/** A sidecar file's URL: needs only the stream key (Plex answers 501 for an embedded stream); the token when known. */
private fun PlexClient.sidecarSubtitleUrl(track: MediaSubtitleTrack): String? {
    val key = track.key
    if (key.isNullOrEmpty()) return null
    val url = "${config.baseUrl}$key.${subtitleExtension(track.codec)}?encoding=utf-8"
    return config.token?.let { "$url&X-Plex-Token=$it" } ?: url
}

private fun sidecar(track: MediaSubtitleTrack, url: String) = PlaybackSubtitleSidecar(
    sourceStreamId = track.id,
    track = SubtitleSidecar(
        url = url,
        title = track.displayTitle ?: track.title ?: track.language ?: T.videoControls.subtitleTrack(track.id.toString()),
        language = track.languageCode,
        codec = track.codec,
        forced = track.forced,
        isDefault = track.selected,
    ),
    // Preloaded so the tracks not selected stay selectable as secondary subtitles without a reopen.
    preload = true,
)

/** A transcode's sidecars: only real external files. Embedded streams are burned, never demuxed from the source. */
private fun PlexClient.transcodeSidecarSubtitles(info: MediaSourceInfo?): List<PlaybackSubtitleSidecar> =
    info?.subtitleTracks.orEmpty().mapNotNull { track -> sidecarSubtitleUrl(track)?.let { sidecar(track, it) } }

/** Direct play's sidecars: every external subtitle file. */
private fun PlexClient.externalSubtitles(info: MediaSourceInfo?): List<PlaybackSubtitleSidecar> =
    info?.subtitleTracks.orEmpty().filter { it.isExternal }.mapNotNull { track ->
        val url = buildExternalSubtitleUrl(track)
        if (url == null) Log.w(TAG) { "Could not build URL for external subtitle ${track.id}" }
        url?.let { sidecar(track, it) }
    }

// Transcode.

/**
 * The video transcode for one playback: selects a burn target on the part, asks the decision for the fMP4 target and,
 * when the server ignored that container, once more for the MPEG-TS/H.264 one. A server honouring neither, or any
 * failure, is [TranscodeDecisionOutcome.FAILED] without a path: playback falls back to direct play rather than open a
 * stream it never negotiated. [withholdDirectPlay] asks for a transcode even at Original (refused codec, or a file the
 * server refused).
 */
suspend fun PlexClient.buildTranscodeStartPath(
    ratingKey: String,
    mediaIndex: Int,
    partIndex: Int = 0,
    preset: TranscodeQualityPreset,
    sessionIdentifier: String,
    transcodeSessionId: String,
    audioStreamId: Int? = null,
    selectedSubtitleTrack: MediaSubtitleTrack? = null,
    partId: Int? = null,
    withholdDirectPlay: Boolean = false,
): PlexTranscodeStart = try {
    selectSubtitleStreamForBurn(partId, selectedSubtitleTrack)
    fun params(useTsFallbackTarget: Boolean) = PlexTranscode.videoParams(
        config = config,
        ratingKey = ratingKey,
        mediaIndex = mediaIndex,
        partIndex = partIndex,
        isOriginal = preset.isOriginal,
        maxVideoBitrateKbps = preset.videoBitrateKbps,
        videoResolution = preset.videoResolution,
        videoQuality = preset.videoQuality,
        sessionIdentifier = sessionIdentifier,
        transcodeSessionId = transcodeSessionId,
        transcodeVideoCodecIds = environment.transcodeVideoCodecIds(),
        audioStreamId = audioStreamId,
        burnSubtitle = burnableSubtitle(selectedSubtitleTrack) != null,
        useTsFallbackTarget = useTsFallbackTarget,
        withholdDirectPlay = withholdDirectPlay,
    )
    val primary = runTranscodeDecision(PlexTranscode.VIDEO_START_ENDPOINT, params(false), preset.isOriginal, PlexTranscode.VOD_CONTAINER)
    if (primary.containerHonored) {
        PlexTranscodeStart(primary.startPath, primary.outcome)
    } else {
        Log.i(TAG) { "Retrying transcode decision with the TS fallback profile" }
        val fallback = runTranscodeDecision(PlexTranscode.VIDEO_START_ENDPOINT, params(true), preset.isOriginal, PlexTranscode.VOD_TS_CONTAINER)
        if (fallback.containerHonored) {
            PlexTranscodeStart(fallback.startPath, fallback.outcome)
        } else {
            Log.w(TAG) { "Transcode decision honoured neither requested container; falling back to direct play" }
            PlexTranscodeStart(null, TranscodeDecisionOutcome.FAILED)
        }
    }
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to build transcode start path" }
    PlexTranscodeStart(null, TranscodeDecisionOutcome.FAILED)
}

/**
 * Points the part's subtitle selection at [track] before a burn: the transcoder burns the part's selected stream and
 * ignores a `subtitleStreamID` beside `subtitles=burn`. A no-op unless [track] is a burnable embedded stream; throws
 * when the selection can't be made, so the transcode fails over to direct play instead of burning the wrong stream.
 */
suspend fun PlexClient.selectSubtitleStreamForBurn(partId: Int?, track: MediaSubtitleTrack?) {
    val target = burnableSubtitle(track) ?: return
    checkNotNull(partId) { "Cannot burn subtitle stream ${target.id}: no part id to select it on" }
    check(selectStreams(partId, subtitleStreamId = target.id)) {
        "Server refused to select subtitle stream ${target.id} on part $partId for burn-in"
    }
}

/** The music transcode (HTTP MP3 at the preset's bitrate): the same decision/start handshake, no container gate. */
suspend fun PlexClient.buildMusicTranscodeStartPath(
    ratingKey: String,
    mediaIndex: Int,
    partIndex: Int = 0,
    preset: AudioQualityPreset,
    sessionIdentifier: String,
    transcodeSessionId: String,
): PlexTranscodeStart = try {
    val params = PlexTranscode.musicParams(config, ratingKey, mediaIndex, partIndex, preset.bitrateKbps, sessionIdentifier, transcodeSessionId)
    val result = runTranscodeDecision(PlexTranscode.MUSIC_START_ENDPOINT, params, preset.isOriginal, requiredContainer = null)
    PlexTranscodeStart(result.startPath, result.outcome)
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to build music transcode start path" }
    PlexTranscodeStart(null, TranscodeDecisionOutcome.FAILED)
}

/**
 * GETs the decision beside [startEndpoint] with the start params and reads it. With [requiredContainer], a converting
 * decision must echo that container for its selected media, else `containerHonored` is false.
 */
private suspend fun PlexClient.runTranscodeDecision(
    startEndpoint: String,
    params: Map<String, String>,
    isOriginal: Boolean,
    requiredContainer: String?,
): DecisionResult {
    val response = http.get(
        PlexTranscode.decisionEndpoint(startEndpoint),
        params,
        mapOf("Accept-Language" to "en", "Accept" to "application/json"),
        allowEndpointFailover = false,
    )
    val body = (response.data ?: response.text)?.toString() ?: "<empty>"
    Log.i(TAG) { "Transcode decision [${response.statusCode}] body: ${if (body.length > 2000) body.take(2000) + "…" else body}" }
    if (response.statusCode != 200) {
        Log.w(TAG) { "Transcode decision returned ${response.statusCode}" }
        return DecisionResult(null, TranscodeDecisionOutcome.FAILED, containerHonored = true)
    }
    val outcome = PlexTranscode.parseDecisionOutcome(response.data, isOriginal)
    if (outcome == TranscodeDecisionOutcome.FAILED) return DecisionResult(null, outcome, containerHonored = true)
    var honored = true
    if (requiredContainer != null && outcome == TranscodeDecisionOutcome.TRANSCODE_OK) {
        val selected = PlexTranscode.decisionSelectedContainer(response.data)
        honored = selected == requiredContainer
        if (!honored) Log.w(TAG) { "Transcode decision did not honour container=$requiredContainer (got ${selected ?: "none"})" }
    }
    return DecisionResult(PlexTranscode.startPath(params, startEndpoint), outcome, honored)
}

/** Keeps a paused transcode alive beside the paused timelines. Best effort: a failure is logged and swallowed. */
suspend fun PlexClient.pingTranscodeSession(transcodeSessionId: String) {
    try {
        http.get(PlexTranscode.VIDEO_PING_ENDPOINT, mapOf("session" to transcodeSessionId))
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "Transcode keepalive ping failed" }
    }
}

// Streams and subtitles.

/**
 * Selects the audio and/or subtitle stream on every part of [partId]'s media (`PUT /library/parts/{id}`). Nothing to
 * select is true without a request; an HTTP error throws; else whether the server answered 200.
 */
suspend fun PlexClient.selectStreams(partId: Int, audioStreamId: Int? = null, subtitleStreamId: Int? = null): Boolean {
    if (audioStreamId == null && subtitleStreamId == null) return true
    val query = buildMap<String, Any?> {
        audioStreamId?.let { put("audioStreamID", it) }
        subtitleStreamId?.let { put("subtitleStreamID", it) }
        put("allParts", 1)
    }
    val response = http.put("/library/parts/$partId", query)
    throwIfHttpError(response)
    return response.statusCode == 200
}

/** Searches the server's subtitle providers for [ratingKey] in [language] (ISO 639-1). An HTTP error throws. */
suspend fun PlexClient.searchSubtitles(
    ratingKey: String,
    language: String,
    title: String? = null,
    hearingImpaired: Int = 0,
    forced: Int = 0,
): List<PlexSubtitleSearchResult> {
    val query = buildMap<String, Any?> {
        put("language", language)
        if (!title.isNullOrEmpty()) put("title", title)
        put("hearingImpaired", hearingImpaired)
        put("forced", forced)
    }
    val response = http.get("/library/metadata/$ratingKey/subtitles", query)
    throwIfHttpError(response)
    return response.data.mediaContainer()?.get("Stream").objectList().map(PlexSubtitleSearchResult::fromJson)
}

/**
 * Asks the server to download a found subtitle onto [ratingKey]. The server works asynchronously: the stream appears
 * later. An HTTP error throws.
 */
suspend fun PlexClient.downloadSubtitle(
    ratingKey: String,
    key: String,
    codec: String,
    language: String,
    hearingImpaired: Boolean,
    forced: Boolean,
    providerTitle: String,
): Boolean {
    val response = http.put(
        "/library/metadata/$ratingKey/subtitles",
        mapOf(
            "key" to key,
            "codec" to codec,
            "language" to language,
            "hearingImpaired" to if (hearingImpaired) 1 else 0,
            "forced" to if (forced) 1 else 0,
            "providerTitle" to providerTitle,
        ),
    )
    throwIfHttpError(response)
    return response.statusCode == 200
}

// Extras and cached sources.

/**
 * Chapters and markers from the shared `/library/metadata/{id}` row: cache-first with a lean request on a miss,
 * network-first with [forceRefresh]. Credits markers go when the show or movie has credits detection off. Any failure
 * is empty extras.
 */
internal suspend fun PlexClient.fetchPlaybackExtrasImpl(
    itemId: String,
    introPattern: String?,
    creditsPattern: String?,
    forceChapterFallback: Boolean,
    forceRefresh: Boolean,
): PlaybackExtras = try {
    val context = captureRequestContext()
    val cacheKey = "/library/metadata/$itemId"
    val networkCall: suspend () -> MediaServerResponse = {
        http.get(cacheKey, mapOf("includeChapters" to 1, "includeMarkers" to 1), context.headers)
    }
    val data = if (forceRefresh) {
        fetchWithCacheFallback(cache.store, context.cacheServerId, cacheKey, isOfflineMode, networkCall, { it }, { it.data as? JsonObject })
    } else {
        fetchWithCacheFirst(cache.store, context.cacheServerId, cacheKey, isOfflineMode, networkCall, { it }, { it.data as? JsonObject })
    }
    val metadata = data.firstMetadata()
    val extras = plexPlaybackExtrasFromCacheJson(
        metadata,
        ChapterMarkerClassifier.bundled,
        introPattern,
        creditsPattern,
        forceChapterFallback,
    )
    plexApplyCreditsDetectionPreference(extras, metadata) { ratingKey -> fetchSharedMetadataRow(ratingKey, context) }
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.w(TAG, e) { "Failed to get playback extras" }
    PlaybackExtras(chapters = emptyList(), markers = emptyList())
}

/** The shared metadata row of [ratingKey], cache-first; a miss fetches the detail screen's query shape. */
private suspend fun PlexClient.fetchSharedMetadataRow(ratingKey: String, context: PlexClient.RequestContext): JsonObject? {
    val cacheKey = "/library/metadata/$ratingKey"
    val data = fetchWithCacheFirst(
        cache.store,
        context.cacheServerId,
        cacheKey,
        isOfflineMode,
        networkCall = { http.get(cacheKey, PLAYBACK_METADATA_QUERY, context.headers) },
        parseCache = { it },
        parseResponse = { it.data as? JsonObject },
    )
    return data.firstMetadata()
}

internal suspend fun PlexClient.fetchPlaybackExtrasFromCacheOnlyImpl(
    itemId: String,
    introPattern: String?,
    creditsPattern: String?,
    forceChapterFallback: Boolean,
): PlaybackExtras? {
    val metadata = cache.store.get(cacheServerId, "/library/metadata/$itemId").firstMetadata() ?: return null
    return plexPlaybackExtrasFromCacheJson(metadata, ChapterMarkerClassifier.bundled, introPattern, creditsPattern, forceChapterFallback)
}

internal suspend fun PlexClient.fetchCachedMediaSourceInfoImpl(
    itemId: String,
    mediaIndex: Int,
    mediaSourceId: String?,
    preferredVersionSignature: String?,
): MediaSourceInfo? {
    val metadata = cache.store.get(cacheServerId, "/library/metadata/$itemId").firstMetadata() ?: return null
    return plexMediaSourceInfoFromCacheJson(metadata, mediaIndex, mediaSourceId, preferredVersionSignature)
}

// Scrub previews.

/**
 * Seek-bar previews from Plex's BIF index, when the server offers them. A stacked version previews every file; null
 * when no file's index loads.
 */
internal suspend fun PlexClient.createScrubPreviewSourceImpl(item: MediaItem, mediaSource: MediaSourceInfo): ScrubPreviewSource? {
    if (!capabilities.scrubThumbnails) return null
    val timeline = mediaSource.partTimeline
        ?: return loadBifPreview(mediaSource.partId, mediaSource.videoAspectRatio)
    val sources = coroutineScope {
        timeline.parts.map { part -> async { loadBifPreview(part.partId.toIntOrNull(), mediaSource.videoAspectRatio) } }.awaitAll()
    }
    if (sources.all { it == null }) return null
    return StackedScrubPreviewSource(timeline, sources)
}

private suspend fun PlexClient.loadBifPreview(partId: Int?, aspectRatio: Double?): ScrubPreviewSource? {
    if (partId == null) return null
    val source = BifScrubPreviewSource.load(aspectRatio) { maxBytes -> downloadBifFile(partId, maxBytes) }
    if (source.isAvailable) return source
    Log.w(TAG) { "BIF thumbnails unavailable for part $partId" }
    source.dispose()
    return null
}

/** The part's BIF index (`/library/parts/{id}/indexes/sd`), failing past [maxBytes]; null for an empty body. */
suspend fun PlexClient.downloadBifFile(partId: Int, maxBytes: Long): ByteArray? {
    val bytes = http.getBytes("${http.baseUrl}/library/parts/$partId/indexes/sd", timeout = 30.seconds, maxBytes = maxBytes)
    return bytes.takeIf { it.isNotEmpty() }
}

// External players and downloads.

internal suspend fun PlexClient.resolveExternalPlaybackImpl(
    item: MediaItem,
    mediaIndex: Int,
    mediaSourceId: String?,
    position: Duration?,
): ExternalPlaybackTarget? {
    val data = getVideoPlaybackData(item.id, mediaIndex = mediaIndex, position = position)
    val url = data.videoUrl?.takeIf { it.isNotEmpty() } ?: return null
    return ExternalPlaybackTarget(
        url = url,
        subtitles = externalSubtitles(data.mediaInfo).map { it.track },
        partTimeline = data.mediaInfo?.partTimeline,
    )
}

/**
 * What to download for [item]. A requested source that is no longer the selected one throws; so does a stacked version
 * with any file gone, rather than a copy that stops short.
 */
internal suspend fun PlexClient.resolveDownloadImpl(item: MediaItem, mediaIndex: Int, mediaSourceId: String?): DownloadResolution {
    val data = getVideoPlaybackData(item.id, mediaIndex = mediaIndex, selectedMediaSourceId = mediaSourceId)
    val info = data.mediaInfo
    val requested = mediaSourceId?.trim()
    check(requested.isNullOrEmpty() || info?.mediaSourceId == requested) { "Requested Plex download source is no longer available" }
    val timeline = info?.partTimeline
    check(timeline == null || timeline.currentIndex == 0) { "Part 1 of the Plex download source is unavailable" }
    val additionalParts = timeline?.parts.orEmpty().drop(1).mapIndexed { offset, part ->
        val index = offset + 1
        val partData = getVideoPlaybackData(
            item.id,
            mediaIndex = data.selectedMediaIndex,
            selectedMediaSourceId = info?.mediaSourceId,
            position = part.start,
        )
        val url = partData.videoUrl
        check(url != null && partData.mediaInfo?.partTimeline?.currentIndex == index) { "Part ${index + 1} of the Plex download source is unavailable" }
        DownloadPartResolution(url, downloadSubtitleSpecs(partData.mediaInfo))
    }
    return DownloadResolution(
        videoUrl = data.videoUrl,
        mediaSourceId = info?.mediaSourceId,
        externalSubtitles = downloadSubtitleSpecs(info),
        additionalParts = additionalParts,
    )
}

private fun PlexClient.downloadSubtitleSpecs(info: MediaSourceInfo?): List<DownloadSubtitleSpec> =
    info?.subtitleTracks.orEmpty().mapNotNull { track ->
        if (!track.isExternal || track.key == null) return@mapNotNull null
        val url = buildExternalSubtitleUrl(track) ?: return@mapNotNull null
        DownloadSubtitleSpec(
            id = track.id,
            url = url,
            codec = track.codec,
            language = track.language,
            languageCode = track.languageCode,
            forced = track.forced,
            displayTitle = track.displayTitle,
        )
    }

internal fun PlexClient.resolveDownloadArtworkImpl(item: MediaItem): List<DownloadArtworkSpec> =
    buildArtworkSpecs(item) { path -> if (path.startsWith("http://") || path.startsWith("https://")) path else absoluteUrl(path) }

// Music.

/** A station play queue seeded from [itemId], as a track list of at most [limit]. Failures propagate. */
@OptIn(ExperimentalUuidApi::class)
internal suspend fun PlexClient.fetchInstantMixImpl(itemId: String, limit: Int): List<MediaItem> {
    val stationUri = "${buildMetadataUri(itemId)}/station/${Uuid.random()}?type=${PlexMetadataType.TRACK}"
    val queue = createPlayQueue(uri = stationUri, type = "audio")
    return queue.items.orEmpty().take(limit)
}

/**
 * The track's lyrics: its lyric stream (`streamType` 4, LRC preferred) read as `Lyrics > Line > Span`. A cached row
 * without stream detail is re-read online first. Lyrics are decorative: any failure is null.
 */
internal suspend fun PlexClient.fetchLyricsImpl(track: MediaItem): Lyrics? = try {
    val context = captureRequestContext()
    val cacheKey = "/library/metadata/${track.id}"
    var metadata = fetchWithCacheFirst(
        cache.store,
        context.cacheServerId,
        cacheKey,
        isOfflineMode,
        networkCall = { http.get(cacheKey, PLAYBACK_METADATA_QUERY, context.headers) },
        parseCache = { it },
        parseResponse = { it.data as? JsonObject },
    ).firstMetadata()
    var streamKey = lyricStreamKey(metadata)
    if (streamKey == null && !hasStreamMetadata(metadata) && !isOfflineMode) {
        metadata = getWithFailover(cacheKey, mapOf("checkFiles" to 1, "includeStreams" to 1)).firstMetadata()
        streamKey = lyricStreamKey(metadata)
    }
    if (streamKey == null) {
        null
    } else {
        val response = getWithFailover(streamKey, mapOf("format" to "xml"), mapOf("Accept" to "application/xml"))
        parsePlexLyricsResponse(response.data ?: response.text?.let(::JsonPrimitive))
    }
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.w(TAG, e) { "Failed to fetch lyrics for ${track.id}" }
    null
}

private fun lyricStreams(metadata: JsonObject?): Sequence<JsonObject> = metadata?.get("Media").objectList().asSequence()
    .flatMap { it["Part"].objectList() }
    .flatMap { it["Stream"].objectList() }

/** The key of the row's lyric stream, `lrc` before any other format. */
private fun lyricStreamKey(metadata: JsonObject?): String? {
    var fallback: String? = null
    for (stream in lyricStreams(metadata)) {
        if (stream["streamType"].flexInt() != LYRICS_STREAM_TYPE) continue
        val key = stream["key"].scalarString()?.takeIf { it.isNotEmpty() } ?: continue
        if ((stream["format"] ?: stream["codec"]).scalarString()?.lowercase() == "lrc") return key
        if (fallback == null) fallback = key
    }
    return fallback
}

private fun hasStreamMetadata(metadata: JsonObject?): Boolean =
    metadata?.get("Media").objectList().any { media -> media["Part"].objectList().any { "Stream" in it } }
