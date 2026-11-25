package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.BifScrubPreviewSource
import com.edde746.plezy.backend.DownloadArtworkSpec
import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.DownloadSubtitleSpec
import com.edde746.plezy.backend.DownloadTranscode
import com.edde746.plezy.backend.ExternalPlaybackTarget
import com.edde746.plezy.backend.MediaServerAuthException
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.backend.PlaybackSubtitleSidecar
import com.edde746.plezy.backend.ScrubPreviewSource
import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.backend.TranscodeFallbackReason
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.buildArtworkSpecs
import com.edde746.plezy.backend.classifyPlaybackFailure
import com.edde746.plezy.backend.net.retryTransientMediaServerCall
import com.edde746.plezy.format.isTextSubtitleCodec
import com.edde746.plezy.format.subtitleExtension
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaMarker
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.model.cleanSubtitleTitle
import com.edde746.plezy.model.cleanTrackMetadataValue
import com.edde746.plezy.model.findSourceAudioTrackForIntent
import com.edde746.plezy.model.findSourceTrackForIntent
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Playback on a MediaBrowser server: version choice, `PlaybackInfo` negotiation, stream and subtitle URLs, chapters
 * and skip segments, scrub previews, session reports, downloads, file info and image URLs. Every URL a player or
 * downloader opens carries the token in its query, so [streamHeaders] is empty.
 */
internal class JellyfinPlayback(
    private val core: JellyfinCore,
    /** Always the network (the user asked for fresh data). */
    private val fetchItem: suspend (String) -> MediaItem?,
    /** A fresh cached detail row when one exists, else the network: playback start re-requests what detail just fetched. */
    private val fetchItemFreshCacheFirst: suspend (String) -> MediaItem?,
    /** The cached detail row only, never the network (offline). */
    private val cachedItem: suspend (String) -> MediaItem?,
    /** Downloads a trickplay sheet into the image cache ahead of the scrub; null leaves prefetching off. */
    private val warmImage: ((String) -> Unit)? = null,
) {
    private val connection get() = core.connection
    private val capabilities get() = ServerCapabilities.forBackend(core.dialect.backend)

    val streamHeaders: Map<String, String> = emptyMap()

    // Item lookups.

    /** The item's playback bundle (see [JellyfinPlaybackBundle.fromItem]); null when it is missing or has no sources. */
    suspend fun fetchPlaybackBundle(itemId: String, sourceIndex: Int = 0, sourceId: String? = null, preferredSignature: String? = null): JellyfinPlaybackBundle? {
        val raw = fetchItemFreshCacheFirst(itemId)?.raw ?: return null
        return JellyfinPlaybackBundle.fromItem(raw, sourceIndex, sourceId, preferredSignature)
    }

    suspend fun fetchCachedMediaSourceInfo(itemId: String, mediaIndex: Int = 0, mediaSourceId: String? = null, preferredVersionSignature: String? = null): MediaSourceInfo? {
        val raw = cachedItem(itemId)?.raw ?: return null
        val bundle = JellyfinPlaybackBundle.fromItem(raw, mediaIndex, mediaSourceId, preferredVersionSignature) ?: return null
        return JellyfinMediaInfo.mediaSourceInfo(bundle.selectedSource, bundle.chapters, bundle.trickplay, bundle.selectedSourceIndex)
    }

    // Chapters and skip segments.

    /**
     * Chapters come from the item; Jellyfin also has native skip segments (`/MediaSegments/{id}`), which are
     * best-effort so older servers and Emby fall back to chapter names.
     */
    suspend fun fetchPlaybackExtras(
        itemId: String,
        introPattern: String? = null,
        creditsPattern: String? = null,
        forceChapterFallback: Boolean = false,
        forceRefresh: Boolean = false,
    ): PlaybackExtras {
        val item = if (forceRefresh) fetchItem(itemId) else fetchItemFreshCacheFirst(itemId)
        val markers = if (item == null) emptyList() else fetchSegmentMarkers(itemId)
        return JellyfinMediaInfo.playbackExtras(item?.raw, itemId, introPattern, creditsPattern, forceChapterFallback, markers)
    }

    suspend fun fetchPlaybackExtrasFromCacheOnly(
        itemId: String,
        introPattern: String? = null,
        creditsPattern: String? = null,
        forceChapterFallback: Boolean = false,
    ): PlaybackExtras? {
        val item = cachedItem(itemId) ?: return null
        val markers = JellyfinMediaInfo.segmentMarkers(core.store?.get(core.cacheServerId, segmentsEndpoint(itemId)))
        val extras = JellyfinMediaInfo.playbackExtras(item.raw, itemId, introPattern, creditsPattern, forceChapterFallback, markers)
        return if (extras.chapters.isEmpty() && extras.markers.isEmpty()) null else extras
    }

    /**
     * Jellyfin's segments, cached under `/MediaSegments/{id}` (served offline and after a failed request). Emby answers
     * the route with 404, so it is never asked. A failure means no native markers, never a failed load.
     */
    private suspend fun fetchSegmentMarkers(itemId: String): List<MediaMarker> {
        if (!core.dialect.supportsMediaSegments) return emptyList()
        val endpoint = segmentsEndpoint(itemId)
        val store = core.store
        if (core.offlineMode) return JellyfinMediaInfo.segmentMarkers(store?.get(core.cacheServerId, endpoint))
        return try {
            val response = core.get(endpoint)
            if (response.status == 404) return emptyList()
            response.throwIfError()
            (response.data as? JsonObject)?.let { store?.put(core.cacheServerId, endpoint, it) }
            JellyfinMediaInfo.segmentMarkers(response.data)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            val cached = store?.get(core.cacheServerId, endpoint)
            if (cached != null) return JellyfinMediaInfo.segmentMarkers(cached)
            Log.d(TAG, e) { "Media segments unavailable" }
            emptyList()
        }
    }

    // Scrub previews.

    /**
     * Jellyfin: sprite sheets from the source's trickplay manifest. Emby has neither the field nor the tile route; it
     * serves a Roku BIF at `/Videos/{id}/index.bif` (`Width` is required; 320 is what its extraction task makes). A
     * server whose extraction never ran answers a header-only BIF, which leaves the source unavailable.
     */
    suspend fun createScrubPreviewSource(item: MediaItem, mediaSource: MediaSourceInfo): ScrubPreviewSource? {
        if (!capabilities.scrubThumbnails) return null
        if (core.dialect == MediaBrowserDialect.EMBY) {
            return BifScrubPreviewSource.load(mediaSource.videoAspectRatio) { maxBytes ->
                core.getBytes("/Videos/${JellyfinCore.segment(item.id)}/index.bif?Width=320", timeoutMillis = 30_000, maxBytes = maxBytes)
                    .takeIf { it.isNotEmpty() }
            }
        }
        val manifest = mediaSource.trickplayByWidth?.takeIf { it.isNotEmpty() } ?: return null
        val c = connection
        return JellyfinTrickplay.create(manifest, warm = warmImage) { width, sheet ->
            JellyfinUrls.trickplayTile(c.baseUrl, c.accessToken, c.dialect.tokenQueryParam, c.deviceId, item.id, width, sheet, mediaSource.mediaSourceId)
        }
    }

    // Playback start.

    /**
     * Always negotiates (`PlaybackInfo`) so the server resolves external audio and subtitle streams. A capped preset
     * plays the returned `TranscodingUrl`; original quality, a direct-play decision and a failed negotiation play the
     * static stream of the source the negotiation settled on.
     */
    suspend fun getPlaybackInitialization(options: PlaybackInitializationOptions): PlaybackInitializationResult {
        val metadata = options.metadata
        val bundle = try {
            // An immediate connection error is asked again; the deadline only backstops the HTTP layer's own budgets.
            retryTransientMediaServerCall(
                operation = "Jellyfin playback item",
                deadline = MediaServerTimeouts.CONNECT + MediaServerTimeouts.RESPONSE + MediaServerTimeouts.RECEIVE,
            ) { _ ->
                fetchPlaybackBundle(metadata.id, options.selectedMediaIndex, options.selectedMediaSourceId, options.preferredVersionSignature)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            throw classifyPlaybackFailure(e)
        }
        if (bundle == null) throw PlaybackException(T.messages.playbackNoMediaSources, PlaybackFailureReason.NO_PLAYABLE_SOURCE)

        var mediaInfo = JellyfinMediaInfo.mediaSourceInfo(bundle.selectedSource, bundle.chapters, bundle.trickplay, bundle.selectedSourceIndex)
        var effectiveSourceId = bundle.selectedSourceId
        var effectiveContainer = bundle.container
        var videoUrl: String? = null
        var playSessionId: String? = null
        var playMethod = "DirectPlay"
        var isTranscoding = false
        var fallbackReason: TranscodeFallbackReason? = null

        // Tracks negotiate with the audio profile and their own preset; the video preset doesn't apply to them.
        val isTrack = metadata.kind == MediaKind.TRACK
        val preset = options.qualityPreset
        val audioPreset = options.audioQualityPreset ?: AudioQualityPreset.ORIGINAL
        val wantsOriginal = if (isTrack) audioPreset.isOriginal else preset.isOriginal
        val requestedAudioStreamId = if (options.selectedAudioStreamId == null) {
            options.preferredAudioTrack?.let { findSourceAudioTrackForIntent(it, mediaInfo.audioTracks)?.id }
        } else {
            validAudioStreamId(options.selectedAudioStreamId, mediaInfo)
        }
        val requestedSubtitleStreamId = subtitleStreamIdFor(options.preferredSubtitleTrack, mediaInfo)
        // A real external text file stays a file the client fetches, even on a transcode; anything else selected is
        // burned in. The server matches its subtitle profiles on format only, so this is decided per request from the
        // effective selection (explicit, else the server default): reading only the explicit one burned a defaulted
        // file and fetched it too. Text only: a bitmap file can't be delivered externally and is burned regardless.
        val effectiveSubtitleStreamId = if (requestedSubtitleStreamId == -1) null else requestedSubtitleStreamId ?: mediaInfo.defaultSubtitleStreamIndex
        val requestedSubtitleIsExternalFile = effectiveSubtitleStreamId != null && mediaInfo.subtitleTracks.any {
            it.id == effectiveSubtitleStreamId && it.isExternalFile && isTextSubtitleCodec(it.codec)
        }
        val maxStreamingBitrate: Long? = when {
            wantsOriginal -> null
            isTrack -> audioPreset.bitrateKbps!! * 1000L
            else -> (preset.videoBitrateKbps ?: 100_000) * 1000L
        }
        val resumeOffsetMs = metadata.viewOffsetMs
        val startTimeTicks = if (!wantsOriginal && resumeOffsetMs != null && resumeOffsetMs > 0) JellyfinTime.msToTicks(resumeOffsetMs) else null

        var negotiation: JsonObject? = null
        var chosenSource: JsonObject? = null
        try {
            negotiation = getPlaybackInfo(
                metadata.id,
                maxStreamingBitrate = maxStreamingBitrate,
                mediaSourceId = bundle.selectedSourceId,
                startTimeTicks = startTimeTicks,
                audioStreamIndex = requestedAudioStreamId,
                subtitleStreamIndex = requestedSubtitleStreamId,
                audioProfile = isTrack,
                burnSubtitles = !wantsOriginal && !requestedSubtitleIsExternalFile,
            )
            chosenSource = selectNegotiatedSource(negotiation.array("MediaSources"), bundle.selectedSourceId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (!canUseStaticStreamFallback(e)) throw classifyPlaybackFailure(e)
            Log.w(TAG, e) { "Playback negotiation unavailable; using the static stream" }
        }

        val chosen = chosenSource
        if (chosen == null) {
            fallbackReason = TranscodeFallbackReason.DECISION_FAILED
            Log.w(TAG) { "Playback negotiation returned no usable source; using the static stream" }
        } else {
            chosen.str("Id")?.let { effectiveSourceId = it }
            chosen.str("Container")?.let { effectiveContainer = it }
            if (chosen["MediaStreams"] is JsonArray) {
                mediaInfo = JellyfinMediaInfo.mediaSourceInfo(chosen, bundle.chapters, bundle.trickplay, bundle.selectedSourceIndex)
            }
            val transcodingUrl = chosen.str("TranscodingUrl")
            if (!wantsOriginal && !transcodingUrl.isNullOrEmpty()) {
                // Server-relative and already carrying container, codecs, MediaSourceId and PlaySessionId; only the
                // token is added.
                val urlSessionId = JellyfinImageAbsolutizer.queryParams(transcodingUrl)["PlaySessionId"]
                playSessionId = urlSessionId?.ifEmpty { null } ?: negotiation?.str("PlaySessionId")
                videoUrl = core.withApiKey(transcodingUrl)
                playMethod = "Transcode"
                isTranscoding = true
            } else if (!wantsOriginal && chosen.bool("SupportsDirectPlay") != true) {
                // A file that already fits the cap direct-plays without a TranscodingUrl: that is the capped request
                // succeeding. Only a declined direct play is a refusal.
                fallbackReason = TranscodeFallbackReason.DIRECT_PLAY_ONLY
            }
        }

        mediaInfo = withSelectedAudioStream(mediaInfo, resolveAudioStreamId(requestedAudioStreamId, mediaInfo))
        // Against the negotiated info: with nothing asked for, the server's (possibly updated) default is what burns.
        val negotiatedSubtitleStreamId = if (requestedSubtitleStreamId == -1) null else requestedSubtitleStreamId ?: mediaInfo.defaultSubtitleStreamIndex
        val burnedSourceStreamId = if (isTranscoding && !requestedSubtitleIsExternalFile) negotiatedSubtitleStreamId else null
        // Tracks have no subtitles to assemble: lyrics go through fetchLyrics.
        val sidecars = if (isTrack) emptyList() else buildSubtitleSidecars(metadata.id, effectiveSourceId, mediaInfo, isTranscoding, burnedSourceStreamId)
        mediaInfo = withSidecarBackedSubtitleIdentity(mediaInfo, sidecars)
        // A blank MediaSourceId makes the stream endpoint pick its own first source, another file when the item has
        // versions: pin the one the negotiation settled on, as every official client does.
        val pinnedSourceId = effectiveSourceId?.trim()?.ifEmpty { null }
        val url = videoUrl ?: directStreamUrl(metadata.id, isTrack, effectiveContainer, pinnedSourceId)

        return PlaybackInitializationResult(
            availableVersions = bundle.availableVersions,
            videoUrl = url,
            mediaInfo = mediaInfo,
            subtitleSidecars = sidecars,
            isTranscoding = isTranscoding,
            fallbackReason = fallbackReason,
            activeAudioStreamId = requestedAudioStreamId,
            playSessionId = playSessionId,
            playMethod = playMethod,
            selectedMediaIndex = bundle.selectedSourceIndex,
            selectedMediaSourceId = pinnedSourceId,
        )
    }

    /**
     * An OS player gets `stream.{container}`: the extension is its only payload hint (ISO is unplayable without it).
     * Direct play, so only real external subtitle files ride along. [position] is unused: a MediaBrowser item is never
     * stacked across files.
     */
    @Suppress("UNUSED_PARAMETER")
    suspend fun resolveExternalPlayback(item: MediaItem, mediaIndex: Int = 0, mediaSourceId: String? = null, position: Duration? = null): ExternalPlaybackTarget? {
        val isTrack = item.kind == MediaKind.TRACK
        val bundle = fetchPlaybackBundle(item.id, mediaIndex, mediaSourceId)
            ?: return ExternalPlaybackTarget(directStreamUrl(item.id, isTrack, containerExtension = true))
        val url = directStreamUrl(item.id, isTrack, bundle.container, bundle.pinnedSourceId, containerExtension = true)
        if (isTrack) return ExternalPlaybackTarget(url)
        val mediaInfo = JellyfinMediaInfo.mediaSourceInfo(bundle.selectedSource, mediaIndex = bundle.selectedSourceIndex)
        return ExternalPlaybackTarget(url, buildSubtitleSidecars(item.id, bundle.selectedSourceId, mediaInfo).map { it.track })
    }

    /**
     * `POST /Items/{id}/PlaybackInfo`: the negotiation fields go out stringified in the query and typed in the body,
     * with the [JellyfinDeviceProfile]. [maxStreamingBitrate] null leaves high-bitrate originals uncapped. A cold
     * tuner open ([isLiveTv] with [autoOpenLiveStream]) gets the tune transport budget. The answer must be an object
     * with a `MediaSources` list (possibly empty), else a [MediaServerHttpException] that carries none of the body.
     */
    suspend fun getPlaybackInfo(
        itemId: String,
        maxStreamingBitrate: Long? = 100_000_000,
        mediaSourceId: String? = null,
        liveStreamId: String? = null,
        startTimeTicks: Long? = null,
        audioStreamIndex: Int? = null,
        subtitleStreamIndex: Int? = null,
        autoOpenLiveStream: Boolean? = null,
        enableDirectPlay: Boolean? = null,
        enableDirectStream: Boolean? = null,
        enableTranscoding: Boolean? = null,
        allowVideoStreamCopy: Boolean? = null,
        allowAudioStreamCopy: Boolean? = null,
        isLiveTv: Boolean = false,
        audioProfile: Boolean = false,
        /** Withholds `External` subtitle delivery so the server burns the selected subtitle into a transcode. */
        burnSubtitles: Boolean = false,
        /** The profile to negotiate with instead of the playback one ([JellyfinDeviceProfile.download]). */
        deviceProfile: JsonObject? = null,
    ): JsonObject {
        val negotiation = listOfNotNull(
            maxStreamingBitrate?.let { "MaxStreamingBitrate" to JsonPrimitive(it) },
            mediaSourceId?.let { "MediaSourceId" to JsonPrimitive(it) },
            liveStreamId?.let { "LiveStreamId" to JsonPrimitive(it) },
            startTimeTicks?.let { "StartTimeTicks" to JsonPrimitive(it) },
            audioStreamIndex?.let { "AudioStreamIndex" to JsonPrimitive(it) },
            subtitleStreamIndex?.let { "SubtitleStreamIndex" to JsonPrimitive(it) },
            autoOpenLiveStream?.let { "AutoOpenLiveStream" to JsonPrimitive(it) },
            enableDirectPlay?.let { "EnableDirectPlay" to JsonPrimitive(it) },
            enableDirectStream?.let { "EnableDirectStream" to JsonPrimitive(it) },
            enableTranscoding?.let { "EnableTranscoding" to JsonPrimitive(it) },
            allowVideoStreamCopy?.let { "AllowVideoStreamCopy" to JsonPrimitive(it) },
            allowAudioStreamCopy?.let { "AllowAudioStreamCopy" to JsonPrimitive(it) },
        )
        val body = buildJsonObject {
            put("UserId", core.userId)
            negotiation.forEach { (key, value) -> put(key, value) }
            put("DeviceProfile", deviceProfile ?: JellyfinDeviceProfile.build(core.dialect, core.codecs, maxStreamingBitrate, isLiveTv, audioProfile, burnSubtitles))
        }
        val response = core.post(
            "/Items/${JellyfinCore.segment(itemId)}/PlaybackInfo",
            query = listOf("userId" to core.userId) + negotiation.map { (key, value) -> key to value.content },
            body = body,
            timeoutMillis = if (isLiveTv && autoOpenLiveStream == true) MediaServerTimeouts.TUNE_TRANSPORT.inWholeMilliseconds else null,
        ).throwIfError()
        val data = response.obj
        if (data == null || data["MediaSources"] !is JsonArray) {
            throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "Malformed Jellyfin PlaybackInfo response", statusCode = response.status)
        }
        return data
    }

    // Session reports.

    suspend fun reportPlaybackStarted(
        itemId: String,
        position: Duration,
        duration: Duration? = null,
        playSessionId: String? = null,
        playMethod: String? = null,
        liveStreamId: String? = null,
        mediaSourceId: String? = null,
        audioStreamIndex: Int? = null,
        subtitleStreamIndex: Int? = null,
    ) = postPlayingState("/Sessions/Playing", itemId, position, false, playSessionId, playMethod, liveStreamId, mediaSourceId, audioStreamIndex, subtitleStreamIndex)

    /** The server keeps the resume point and, when the user enabled it, the remembered stream indexes from these. */
    suspend fun reportPlaybackProgress(
        itemId: String,
        position: Duration,
        duration: Duration,
        isPaused: Boolean = false,
        playSessionId: String? = null,
        playMethod: String? = null,
        liveStreamId: String? = null,
        mediaSourceId: String? = null,
        audioStreamIndex: Int? = null,
        subtitleStreamIndex: Int? = null,
    ) = postPlayingState("/Sessions/Playing/Progress", itemId, position, isPaused, playSessionId, playMethod, liveStreamId, mediaSourceId, audioStreamIndex, subtitleStreamIndex)

    /**
     * The final position becomes the resume point. The stream indexes ride along too: a pick made inside the last
     * progress interval would otherwise never reach the server. A withheld index leaves its key out, since a present
     * null would overwrite the remembered choice.
     */
    @Suppress("UNUSED_PARAMETER")
    suspend fun reportPlaybackStopped(
        itemId: String,
        position: Duration,
        duration: Duration? = null,
        playSessionId: String? = null,
        liveStreamId: String? = null,
        mediaSourceId: String? = null,
        audioStreamIndex: Int? = null,
        subtitleStreamIndex: Int? = null,
        report: PlaybackReportMetadata = PlaybackReportMetadata.live(),
    ) {
        val body = buildJsonObject {
            put("ItemId", itemId)
            mediaSourceId?.let { put("MediaSourceId", it) }
            audioStreamIndex?.let { put("AudioStreamIndex", it) }
            subtitleStreamIndex?.let { put("SubtitleStreamIndex", it) }
            put("PositionTicks", JellyfinTime.msToTicks(position.inWholeMilliseconds))
            put("Failed", false)
            resolvePlaySessionId(playSessionId, itemId)?.let { put("PlaySessionId", it) }
            liveStreamId?.let { put("LiveStreamId", it) }
        }
        core.post("/Sessions/Playing/Stopped", body = body).throwIfError()
    }

    /**
     * The `PlaybackStartInfo`/`PlaybackProgressInfo` shape the SDK sends; the session tracker drops events without
     * `PlayMethod`.
     */
    private suspend fun postPlayingState(
        path: String,
        itemId: String,
        position: Duration,
        isPaused: Boolean,
        playSessionId: String?,
        playMethod: String?,
        liveStreamId: String?,
        mediaSourceId: String?,
        audioStreamIndex: Int?,
        subtitleStreamIndex: Int?,
    ) {
        val body = buildJsonObject {
            put("ItemId", itemId)
            mediaSourceId?.let { put("MediaSourceId", it) }
            audioStreamIndex?.let { put("AudioStreamIndex", it) }
            subtitleStreamIndex?.let { put("SubtitleStreamIndex", it) }
            put("PositionTicks", JellyfinTime.msToTicks(position.inWholeMilliseconds))
            put("CanSeek", true)
            put("IsPaused", isPaused)
            put("IsMuted", false)
            put("PlayMethod", playMethod ?: "DirectPlay")
            put("RepeatMode", "RepeatNone")
            put("PlaybackOrder", "Default")
            resolvePlaySessionId(playSessionId, itemId)?.let { put("PlaySessionId", it) }
            liveStreamId?.let { put("LiveStreamId", it) }
        }
        core.post(path, body = body).throwIfError()
    }

    /**
     * Emby rejects a session report without a PlaySessionId (400). Callers that never negotiated one (the offline
     * progress replay) get one derived from the item, so a replay's started/progress/stopped land on one session row.
     */
    private fun resolvePlaySessionId(playSessionId: String?, itemId: String): String? = when {
        playSessionId != null -> playSessionId
        core.dialect.requiresPlaySessionId -> "plezy-replay-$itemId"
        else -> null
    }

    // Downloads, file info and images.

    /**
     * The static stream of the selected source (byte for byte). Subtitle files come from `PlaybackInfo`, which is
     * enrichment only: a failure other than an auth refusal or cancellation still downloads, marked unresolved.
     */
    suspend fun resolveDownload(item: MediaItem, mediaIndex: Int = 0, mediaSourceId: String? = null): DownloadResolution {
        val bundle = fetchPlaybackBundle(item.id, mediaIndex, mediaSourceId)
        val selectedSourceId = bundle?.selectedSourceId
        val requested = mediaSourceId?.trim()?.ifEmpty { null }
        if (requested != null && selectedSourceId?.lowercase() != requested.lowercase()) {
            throw IllegalStateException("Requested Jellyfin download source is no longer available")
        }
        val isTrack = item.kind == MediaKind.TRACK
        val videoUrl = directStreamUrl(item.id, isTrack, bundle?.container, bundle?.pinnedSourceId)
        if (isTrack) return DownloadResolution(videoUrl, selectedSourceId)

        val unresolved = DownloadResolution(videoUrl, selectedSourceId, externalSubtitlesResolved = false)
        val playbackInfo = try {
            getPlaybackInfo(item.id, mediaSourceId = selectedSourceId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (!canUseStaticStreamFallback(e)) throw e
            Log.w(TAG, e) { "Download subtitle enrichment unavailable; using the static stream" }
            return unresolved
        }
        val source = selectDownloadSource(playbackInfo.array("MediaSources")!!, selectedSourceId, mediaIndex)
        val streams = source?.array("MediaStreams")
        val rawSourceId = source?.get("Id")
        if (source == null || streams == null || (rawSourceId != null && rawSourceId !is JsonNull && (rawSourceId as? JsonPrimitive)?.isString != true)) {
            Log.w(TAG) { "Download subtitle enrichment returned no usable source; using the static stream" }
            return unresolved
        }
        val subtitleSourceId = source.str("Id") ?: item.id
        val subtitles = streams.filterIsInstance<JsonObject>().mapNotNull { raw ->
            if (raw.str("Type") != "Subtitle") return@mapNotNull null
            val fields = JellyfinStreamFields.parse(raw)
            if (!fields.isExternalFile) return@mapNotNull null
            val index = raw.int("Index") ?: return@mapNotNull null
            val codec = fields.codec?.lowercase()
            // The endpoint keys off the format (`srt`), not the codec name the server reports (`subrip`).
            val path = fields.deliveryUrl?.ifEmpty { null }
                ?: "/Videos/${JellyfinCore.segment(item.id)}/${JellyfinCore.segment(subtitleSourceId)}/Subtitles/$index/${JellyfinCore.segment("Stream.${subtitleExtension(codec)}")}"
            DownloadSubtitleSpec(index, core.withApiKey(path), codec, fields.language, fields.languageCode, fields.isForced, fields.displayTitle)
        }
        return DownloadResolution(videoUrl, selectedSourceId, subtitles)
    }

    /**
     * A movie or episode transcoded for download: `PlaybackInfo` with [JellyfinDeviceProfile.download] (no direct play,
     * the preset's bitrate and picture box) hands back a progressive `stream.ts` transcode URL carrying the audio track the
     * server defaults to for the user. A subtitle the server would burn in (an image track it defaults to) is taken off
     * the URL: image subtitles stay out of a download. Each subtitle the server delivers as a file, a real one or an
     * embedded text track it extracts, is saved beside the video.
     */
    suspend fun resolveTranscodedDownload(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, quality: TranscodeQualityPreset): DownloadResolution {
        require(!quality.isOriginal) { "The original isn't transcoded" }
        require(item.kind == MediaKind.MOVIE || item.kind == MediaKind.EPISODE) { "Only videos are transcoded for download" }
        check(core.dialect == MediaBrowserDialect.JELLYFIN) { "Only Jellyfin transcodes downloads" }
        val bundle = fetchPlaybackBundle(item.id, mediaIndex, mediaSourceId) ?: throw IllegalStateException("The Jellyfin item has no media sources")
        val selectedSourceId = bundle.selectedSourceId
        val requested = mediaSourceId?.trim()?.ifEmpty { null }
        if (requested != null && selectedSourceId?.lowercase() != requested.lowercase()) {
            throw IllegalStateException("Requested Jellyfin download source is no longer available")
        }
        val bitrate = checkNotNull(quality.videoBitrateKbps) * 1000L
        val (maxWidth, maxHeight) = checkNotNull(quality.videoResolution).split('x').map(String::toInt)
        val info = getPlaybackInfo(
            item.id,
            maxStreamingBitrate = bitrate,
            mediaSourceId = selectedSourceId,
            enableDirectPlay = false,
            enableDirectStream = false,
            deviceProfile = JellyfinDeviceProfile.download(bitrate, maxWidth, maxHeight),
        )
        val source = selectNegotiatedSource(info.array("MediaSources"), selectedSourceId)
            ?: throw IllegalStateException("Jellyfin returned no source to transcode")
        val transcodingUrl = source.str("TranscodingUrl")?.ifEmpty { null } ?: throw IllegalStateException("Jellyfin declined to transcode the download")
        val url = BURNED_SUBTITLE_PARAMS.fold(core.withApiKey(transcodingUrl)) { acc, name -> JellyfinImageAbsolutizer.removeQueryParam(acc, name) }
        val query = JellyfinImageAbsolutizer.queryParams(url)
        val streamBitrate = listOf("VideoBitrate", "AudioBitrate").sumOf { query[it]?.toLongOrNull() ?: 0L }.takeIf { it > 0 } ?: bitrate
        val durationMs = item.durationMs?.takeIf { it > 0 } ?: JellyfinTime.ticksToMs(source.long("RunTimeTicks"))?.takeIf { it > 0 }
        val subtitleSourceId = source.str("Id") ?: item.id
        val subtitles = source.array("MediaStreams").orEmpty().filterIsInstance<JsonObject>().mapNotNull { raw ->
            if (raw.str("Type") != "Subtitle") return@mapNotNull null
            val fields = JellyfinStreamFields.parse(raw)
            val index = raw.int("Index") ?: return@mapNotNull null
            val deliveryUrl = fields.deliveryUrl?.ifEmpty { null }
            val codec = when {
                fields.isExternalFile -> fields.codec?.lowercase()
                // An embedded text track comes as the format the server converts it to (`Stream.srt`).
                fields.usesExternalDelivery && deliveryUrl != null && isTextSubtitleCodec(fields.codec) -> deliveryUrl.substringBefore('?').substringAfterLast('.').lowercase()
                else -> return@mapNotNull null
            }
            val path = deliveryUrl
                ?: "/Videos/${JellyfinCore.segment(item.id)}/${JellyfinCore.segment(subtitleSourceId)}/Subtitles/$index/${JellyfinCore.segment("Stream.${subtitleExtension(codec)}")}"
            DownloadSubtitleSpec(index, core.withApiKey(path), codec, fields.language, fields.languageCode, fields.isForced, fields.displayTitle)
        }
        return DownloadResolution(
            url,
            selectedSourceId,
            subtitles,
            transcode = DownloadTranscode(quality, durationMs?.let { streamBitrate * it / 8000 }, durationMs),
        )
    }

    /**
     * Kills the encode feeding [downloadUrl] by its play session (`DELETE /Videos/ActiveEncodings`), so a cancelled or
     * paused download stops costing the server at once. Best effort: a failure is logged.
     */
    suspend fun stopDownloadTranscode(downloadUrl: String) {
        val playSessionId = JellyfinImageAbsolutizer.queryParams(downloadUrl)["PlaySessionId"]?.ifEmpty { null } ?: return
        try {
            val route = JellyfinLiveTvRoutes.activeEncodings(core.connection.deviceId, playSessionId)
            core.delete(route.path, route.query).throwIfError()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to stop a download's transcode" }
        }
    }

    /** Artwork paths are already absolute (the mappers absolutize) and carry no token. */
    fun resolveDownloadArtwork(item: MediaItem): List<DownloadArtworkSpec> = buildArtworkSpecs(item) { it }

    /** From the item's `MediaSources`; list rows omit them, so those fetch the item. */
    suspend fun getFileInfo(item: MediaItem): MediaFileInfo? {
        val json = item.raw?.takeIf { it["MediaSources"] is JsonArray } ?: fetchItem(item.id)?.raw ?: return null
        return JellyfinMediaInfo.fileInfo(json)
    }

    /**
     * [path] joined to the server with `maxWidth`/`maxHeight` added where it has no size of its own, and no token: item
     * images need none. A URL on an origin none of the connection's URLs has isn't this server's image: it stays as it
     * is. [cover] has no effect: the max bounds already fit the long side inside the box, so the server never overshoots.
     */
    @Suppress("UNUSED_PARAMETER")
    fun thumbnailUrl(path: String?, width: Int? = null, height: Int? = null, cover: Boolean = true): String {
        if (path.isNullOrEmpty()) return ""
        val c = connection
        var url = JellyfinImageAbsolutizer.joinUrl(c.baseUrl, path)
        val origin = JellyfinCore.origin(url)
        if (c.baseUrls.none { JellyfinCore.origin(it) == origin }) return url
        val keys = JellyfinImageAbsolutizer.queryParams(url).keys.map { it.lowercase() }.toSet()
        if (width != null && "maxwidth" !in keys && "width" !in keys) url = JellyfinImageAbsolutizer.setQueryParam(url, "maxWidth", "$width")
        if (height != null && "maxheight" !in keys && "height" !in keys) url = JellyfinImageAbsolutizer.setQueryParam(url, "maxHeight", "$height")
        return url
    }

    /** MediaBrowser has no image proxy for off-server URLs, so they pass through. */
    @Suppress("UNUSED_PARAMETER")
    fun externalImageUrl(url: String, width: Int? = null, height: Int? = null, cover: Boolean = true): String = url

    // Helpers.

    private fun directStreamUrl(itemId: String, isTrack: Boolean, container: String? = null, mediaSourceId: String? = null, containerExtension: Boolean = false): String {
        val c = connection
        return JellyfinUrls.directStream(
            c.baseUrl, c.accessToken, c.dialect.tokenQueryParam, c.deviceId, itemId,
            mediaSegment = if (isTrack) "Audio" else "Videos",
            container = container,
            mediaSourceId = mediaSourceId,
            containerExtension = containerExtension,
        )
    }

    private fun validAudioStreamId(explicit: Int?, mediaInfo: MediaSourceInfo): Int? =
        explicit?.takeIf { id -> mediaInfo.audioTracks.any { it.id == id } }

    /** Off → -1; a track → the row of this source serving it (or its picked row), null when none does. */
    private fun subtitleStreamIdFor(preferred: SubtitlePreference?, mediaInfo: MediaSourceInfo): Int? = when (preferred) {
        null -> null
        SubtitlePreference.Off -> -1
        is SubtitlePreference.Track -> findSourceTrackForIntent(preferred, mediaInfo.subtitleTracks)?.id
    }

    /** The explicit valid id, else the server default, else the selected row. */
    private fun resolveAudioStreamId(explicit: Int?, mediaInfo: MediaSourceInfo): Int? =
        validAudioStreamId(explicit, mediaInfo) ?: mediaInfo.defaultAudioStreamIndex ?: mediaInfo.audioTracks.firstOrNull { it.selected }?.id

    private fun withSelectedAudioStream(mediaInfo: MediaSourceInfo, selected: Int?): MediaSourceInfo {
        if (selected == null || mediaInfo.audioTracks.none { it.id == selected }) return mediaInfo
        return mediaInfo.copy(audioTracks = mediaInfo.audioTracks.map { it.withSelected(it.id == selected) })
    }

    /**
     * Only rows this open actually fetches keep their sidecar identity. The profile offers text `External`, so the
     * server hands a delivery URL even for streams embedded in a direct-played container; the player reads those from
     * the container, and a leftover URL would make track matching wait for a sidecar that never loads. A real file
     * (`IsExternal`) keeps it either way: it is never in the container.
     */
    private fun withSidecarBackedSubtitleIdentity(mediaInfo: MediaSourceInfo, sidecars: List<PlaybackSubtitleSidecar>): MediaSourceInfo {
        if (mediaInfo.subtitleTracks.isEmpty()) return mediaInfo
        val fetched = sidecars.mapNotNullTo(HashSet()) { it.sourceStreamId }
        return mediaInfo.copy(subtitleTracks = mediaInfo.subtitleTracks.map { if (it.isExternalFile || it.id in fetched) it else it.withoutSidecarIdentity() })
    }

    /**
     * The subtitle files this open fetches: never the burned row (it is in the picture), never a bitmap on a
     * transcode (burned whatever is asked); a real external file always; an embedded text row only on a transcode,
     * where the server extracts it, so a secondary track still renders. Direct play leaves embedded rows to the
     * player. Files preload with the media (selectable as secondary without a reopen); extracted rows stay lazy
     * since extraction can stall behind the transcoder.
     */
    private fun buildSubtitleSidecars(
        itemId: String,
        mediaSourceId: String?,
        mediaInfo: MediaSourceInfo,
        isTranscoding: Boolean = false,
        burnedSourceStreamId: Int? = null,
    ): List<PlaybackSubtitleSidecar> = mediaInfo.subtitleTracks.mapNotNull { track ->
        if (burnedSourceStreamId != null && track.id == burnedSourceStreamId) return@mapNotNull null
        if (isTranscoding && !isTextSubtitleCodec(track.codec)) return@mapNotNull null
        if (!track.isExternalFile && !isTranscoding) return@mapNotNull null
        val codec = track.codec
        val path = track.key ?: if (mediaSourceId == null || codec.isNullOrEmpty()) {
            return@mapNotNull null
        } else {
            // The endpoint keys off the format: `subrip` is served as `Stream.srt`.
            "/Videos/${JellyfinCore.segment(itemId)}/${JellyfinCore.segment(mediaSourceId)}/Subtitles/${track.index ?: track.id}/Stream.${subtitleExtension(codec)}"
        }
        PlaybackSubtitleSidecar(
            sourceStreamId = track.id,
            preload = track.isExternalFile,
            track = SubtitleSidecar(
                url = core.withApiKey(path),
                title = cleanSubtitleTitle(track.displayTitle ?: track.title, track.codec) ?: cleanTrackMetadataValue(track.language),
                language = cleanTrackMetadataValue(track.languageCode),
                codec = track.codec,
                forced = track.forced,
                isDefault = track.selected,
            ),
        )
    }

    /** The negotiated source with the requested id (case-insensitive), else the first; a non-object entry is malformed. */
    private fun selectNegotiatedSource(sources: JsonArray?, selectedSourceId: String?): JsonObject? {
        if (sources.isNullOrEmpty()) return null
        val requested = selectedSourceId?.trim()?.ifEmpty { null }
        if (requested != null) {
            for (source in sources) {
                require(source is JsonObject) { "Malformed Jellyfin PlaybackInfo media source" }
                if (source.str("Id")?.lowercase() == requested.lowercase()) return source
            }
            return null
        }
        val first = sources.first()
        require(first is JsonObject) { "Malformed Jellyfin PlaybackInfo media source" }
        val id = first["Id"]
        require(id == null || id is JsonNull || (id as? JsonPrimitive)?.isString == true) { "Malformed Jellyfin PlaybackInfo media source id" }
        return first
    }

    private fun selectDownloadSource(sources: JsonArray, selectedSourceId: String?, mediaIndex: Int): JsonObject? {
        if (sources.isEmpty()) return null
        val requested = selectedSourceId?.trim()?.ifEmpty { null }
        if (requested != null) return sources.filterIsInstance<JsonObject>().firstOrNull { it.str("Id")?.lowercase() == requested.lowercase() }
        return (if (mediaIndex in sources.indices) sources[mediaIndex] else sources.first()) as? JsonObject
    }

    private companion object {
        const val TAG = "JellyfinPlayback"

        /** The transcode URL's parameters that burn a subtitle into the picture. */
        val BURNED_SUBTITLE_PARAMS = listOf("SubtitleStreamIndex", "SubtitleMethod", "SubtitleCodec")

        fun segmentsEndpoint(itemId: String) = "/MediaSegments/${JellyfinCore.segment(itemId)}"

        /**
         * Whether a failed negotiation may fall back to the static stream: not for a refused token or account (that
         * must surface) and not for a cancellation.
         */
        fun canUseStaticStreamFallback(error: Throwable): Boolean = when (error) {
            is MediaServerAuthException -> false
            is MediaServerHttpException -> !error.isCancellation && error.statusCode != 401 && error.statusCode != 403
            else -> true
        }
    }
}
