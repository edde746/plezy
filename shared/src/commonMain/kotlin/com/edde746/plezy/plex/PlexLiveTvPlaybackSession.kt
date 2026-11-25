package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.net.MediaServerHttpClient
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.format.isImageSubtitleCodec
import com.edde746.plezy.livetv.CaptureBuffer
import com.edde746.plezy.livetv.LiveProgramInfo
import com.edde746.plezy.livetv.LiveTimelineState
import com.edde746.plezy.livetv.LiveTimelineUpdate
import com.edde746.plezy.livetv.LiveTvBackgroundPolicy
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.servers.OperationTimeoutException
import com.edde746.plezy.servers.timeoutReleasingLate
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.serialization.json.JsonObject

private const val TAG = "PlexLiveTvSession"

/** What a tune yields: the server session to stream from and report against, and the program it caught. */
internal class PlexTune(
    val program: LiveProgramInfo,
    /** The tuned session's metadata key: the transcode's `path` and the timeline's `key`. */
    val sessionPath: String,
    /** The `X-Plex-Session-Identifier` the tune was made under. */
    val sessionIdentifier: String,
    val captureBuffer: CaptureBuffer?,
    val partId: Int?,
    val subtitleTracks: List<MediaSubtitleTrack>,
)

/**
 * A tuned Plex DVR channel. The stream is the universal transcoder's HLS output of the tuned session, always a remux
 * (`directStream=1`) unless a fallback dropped it, with [quality] as a ceiling. Every URL it builds reuses one
 * transcode session id, so the server keeps its capture buffer across time-shift rebuilds.
 */
internal class PlexLiveTvPlaybackSession private constructor(
    private val client: PlexClient,
    private val scope: CoroutineScope,
    private val dvrKey: String,
    private val channelKey: String,
    private val tune: PlexTune,
    private val quality: TranscodeQualityPreset,
    private val directStream: Boolean,
    private val directStreamAudio: Boolean,
) : LiveTvPlaybackSession {
    private val transcodeSessionId = generateSessionIdentifier()

    /** The subtitle stream already selected on the part, so rebuilds for the same track skip the selection. */
    private var confirmedBurnStreamId: Int? = null

    override val program: LiveProgramInfo get() = tune.program
    override val backgroundPolicy: LiveTvBackgroundPolicy get() = LiveTvBackgroundPolicy.RETAIN_SESSION
    override val captureBuffer: CaptureBuffer? get() = tune.captureBuffer
    override val subtitleTracks: List<MediaSubtitleTrack> get() = tune.subtitleTracks
    override val canTimeShift: Boolean get() = captureBuffer != null

    override suspend fun streamUrlAt(offsetSeconds: Long?, subtitleTrack: MediaSubtitleTrack?): String? {
        if (offsetSeconds != null && !canTimeShift) return null
        if (subtitleTrack != null && !confirmBurnSelection(subtitleTrack)) return null
        val path = client.liveStreamPath(liveStreamParams(offsetSeconds, burnSubtitle = subtitleTrack != null)) ?: return null
        return client.absoluteUrl(path)
    }

    /**
     * Points the tuned part's subtitle selection at [track]: the transcoder burns the part's selected stream and
     * ignores a `subtitleStreamID` beside `subtitles=burn`. False when the selection can't be confirmed, since a burn
     * would then weld whatever the server had stored into the picture.
     */
    private suspend fun confirmBurnSelection(track: MediaSubtitleTrack): Boolean {
        if (confirmedBurnStreamId == track.id) return true
        val partId = tune.partId
        if (partId == null) {
            Log.w(TAG) { "Live subtitle burn requested but the tune exposed no part id" }
            return false
        }
        val selected = try {
            client.selectStreams(partId, subtitleStreamId = track.id)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to select live subtitle stream ${track.id} on part $partId for burn-in" }
            return false
        }
        if (!selected) {
            Log.w(TAG) { "Server refused to select live subtitle stream ${track.id} on part $partId for burn-in" }
            return false
        }
        confirmedBurnStreamId = track.id
        return true
    }

    /**
     * The decision and start parameters. A preset is a ceiling, not a re-encode request: every preset asks for a remux,
     * and a capped one adds the bitrate limitation and the resolution/quality caps so the server copies a channel that
     * fits and encodes only one that doesn't. `subtitles=none` keeps Plex from burning broadcast captions; `burn` burns
     * the part's selected bitmap stream.
     */
    private fun liveStreamParams(offsetSeconds: Long?, burnSubtitle: Boolean): Map<String, String> {
        val config = client.config
        val isOriginal = quality.isOriginal
        val videoTarget = if (isOriginal) {
            PlexTranscode.liveVideoTarget(acceptsHevc = "hevc" in client.environment.transcodeVideoCodecIds())
        } else {
            PlexTranscode.VOD_TS_VIDEO_TARGET
        }
        return buildMap {
            put("hasMDE", "1")
            put("path", tune.sessionPath)
            put("mediaIndex", "0")
            put("partIndex", "0")
            put("protocol", "hls")
            put("fastSeek", "1")
            // A tuned session is reachable only through the transcoder's HLS output: no re-encode means a remux.
            put("directPlay", "0")
            put("directStream", if (directStream) "1" else "0")
            put("subtitleSize", "100")
            put("audioBoost", "100")
            put("location", "lan")
            put("addDebugOverlay", "0")
            put("autoAdjustQuality", "0")
            quality.videoResolution?.let { put("videoResolution", it) }
            quality.videoQuality?.let { put("videoQuality", it.toString()) }
            put("directStreamAudio", if (directStreamAudio) "1" else "0")
            put("mediaBufferSize", "157286")
            put("session", transcodeSessionId)
            put("subtitles", if (burnSubtitle) "burn" else "none")
            put("copyts", "0")
            put("Accept-Language", "en")
            put("X-Plex-Session-Identifier", tune.sessionIdentifier)
            put(
                "X-Plex-Client-Profile-Extra",
                PlexTranscode.clientProfileExtra(videoTarget, maxVideoBitrateKbps = if (isOriginal) null else quality.videoBitrateKbps),
            )
            put("X-Plex-Incomplete-Segments", "1")
            put("X-Plex-Product", config.product)
            put("X-Plex-Version", config.version)
            put("X-Plex-Client-Identifier", config.clientIdentifier)
            put("X-Plex-Platform", PlexTranscode.PLATFORM)
            put("X-Plex-Client-Profile-Name", "Generic")
            offsetSeconds?.let { put("offset", it.toString()) }
            config.token?.let { put("X-Plex-Token", it) }
        }
    }

    /** Plex rejects a timeline whose time passes its duration (short synthetic programs), so the duration grows to it. */
    override suspend fun reportTimeline(state: LiveTimelineState, positionMs: Long, durationMs: Long): LiveTimelineUpdate? =
        client.updateLiveTimeline(
            ratingKey = program.id ?: channelKey,
            sessionPath = tune.sessionPath,
            sessionIdentifier = tune.sessionIdentifier,
            state = state,
            timeMs = positionMs,
            durationMs = maxOf(durationMs, positionMs),
        )

    /** A stopped timeline releases the tuner instead of leaving it to the server's idle expiry. */
    override suspend fun discard() {
        try {
            reportTimeline(LiveTimelineState.STOPPED, positionMs = 0, durationMs = program.durationMs ?: 0)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "Failed to stop a discarded Plex live session" }
        }
    }

    /** Re-tunes for a fresh capture session with the fallback flags; the quality ceiling carries over. */
    override suspend fun recover(directStream: Boolean, directStreamAudio: Boolean): LiveTvPlaybackSession? =
        start(client, scope, dvrKey, channelKey, quality, directStream, directStreamAudio)

    companion object {
        /**
         * Tunes [channelKey] on [dvrKey]. The caller waits [MediaServerTimeouts.TUNE]; the tune runs on in [scope], and
         * one that answers later is discarded rather than left holding a tuner. Null when the tune fails or is late.
         */
        suspend fun start(
            client: PlexClient,
            scope: CoroutineScope,
            dvrKey: String,
            channelKey: String,
            quality: TranscodeQualityPreset,
            directStream: Boolean,
            directStreamAudio: Boolean,
        ): PlexLiveTvPlaybackSession? {
            fun session(tune: PlexTune?) =
                tune?.let { PlexLiveTvPlaybackSession(client, scope, dvrKey, channelKey, it, quality, directStream, directStreamAudio) }
            val tune = try {
                timeoutReleasingLate(
                    MediaServerTimeouts.TUNE,
                    operation = "Plex tune",
                    scope = scope,
                    releaseLate = { late -> session(late)?.discard() },
                ) { client.tuneChannel(dvrKey, channelKey) }
            } catch (e: OperationTimeoutException) {
                Log.w(TAG, e) { "Tune channel: no answer in time" }
                return null
            }
            return session(tune)
        }
    }
}

/**
 * `POST /livetv/dvrs/{dvr}/channels/{channel}/tune` under a fresh session identifier. Null when the server refuses
 * (status ≥ 400, a container `status` other than 0/200, no metadata or session key) or the request fails.
 */
private suspend fun PlexClient.tuneChannel(dvrKey: String, channelKey: String): PlexTune? = try {
    val sessionIdentifier = generateSessionIdentifier()
    parseTune(postTuneWithRetry("/livetv/dvrs/$dvrKey/channels/$channelKey/tune", sessionIdentifier), sessionIdentifier)
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to tune channel" }
    null
}

/**
 * Retries once on a connection error: the request most likely never reached the server (a dead pooled socket). A
 * timeout is never replayed: the server may already be tuning, and a second tune can claim a second tuner.
 */
private suspend fun PlexClient.postTuneWithRetry(path: String, sessionIdentifier: String): MediaServerResponse {
    val query = mapOf("X-Plex-Session-Identifier" to sessionIdentifier)
    return try {
        http.post(path, query, timeout = MediaServerTimeouts.TUNE_TRANSPORT, allowEndpointFailover = false)
    } catch (e: MediaServerHttpException) {
        if (e.type != MediaServerHttpErrorType.CONNECTION_ERROR) throw e
        Log.w(TAG, e) { "Tune channel: connection failed, retrying once" }
        http.post(path, query, timeout = MediaServerTimeouts.TUNE_TRANSPORT, allowEndpointFailover = false)
    }
}

/**
 * The tuned program is `MediaSubscription[0].MediaGrabOperation[0].Metadata`, else the container's `Metadata`; its
 * start is the subscription timeline's first airing, else its own `Media`. The capture buffer is the container's (or
 * the metadata's) `TranscodeSession`.
 */
private fun parseTune(response: MediaServerResponse, sessionIdentifier: String): PlexTune? {
    if (response.statusCode >= 400) {
        Log.w(TAG) { "Tune channel returned status ${response.statusCode}" }
        return null
    }
    val container = response.data.mediaContainer() ?: return null
    val status = container["status"].flexInt()
    if (status != null && status != 0 && status != 200) {
        Log.w(TAG) { "Tune channel error: ${container["message"].scalarString()} (status $status)" }
        return null
    }
    val subscription = container["MediaSubscription"].firstObject()
    val timelineBeginsAt = subscription?.get("Timeline").firstObject()?.get("Metadata").firstObject()
        ?.get("Media").firstObject()?.get("beginsAt").flexLong()
    val metadata = subscription?.get("MediaGrabOperation").firstObject()?.get("Metadata").firstObject()
        ?: container["Metadata"].firstObject()
    if (metadata == null) {
        Log.w(TAG) { "Tune channel failed: ${container["message"].scalarString() ?: "no metadata"} (keys ${container.keys})" }
        return null
    }
    val sessionPath = metadata["key"].stringOrNull()
    if (sessionPath == null) {
        Log.w(TAG) { "Tune channel: no session path in metadata key" }
        return null
    }
    val captureBuffer = (container["TranscodeSession"].firstObject() ?: metadata["TranscodeSession"].firstObject())
        ?.let(CaptureBuffer::fromTranscodeSession)
    val media = metadata["Media"].firstObject()
    val part = media?.get("Part").firstObject()
    return PlexTune(
        program = LiveProgramInfo(
            id = metadata["ratingKey"].scalarString(),
            durationMs = metadata["duration"].flexLong(),
            beginsAt = timelineBeginsAt ?: media?.get("beginsAt").flexLong(),
        ),
        sessionPath = sessionPath,
        sessionIdentifier = sessionIdentifier,
        captureBuffer = captureBuffer,
        partId = part?.get("id").flexInt(),
        subtitleTracks = part?.let(::liveBurnableSubtitleTracks).orEmpty(),
    )
}

/**
 * The part's subtitle streams the live path can deliver: embedded bitmap streams only. `subtitles=none` drops them from
 * the HLS output, so a burn is their only delivery; captions ride the copied video and stay player-selectable, and a
 * sidecar can't be burned.
 */
private fun liveBurnableSubtitleTracks(part: JsonObject): List<MediaSubtitleTrack> =
    plexPlaybackStreams(part["Stream"]).subtitleTracks.filter { !it.isExternal && isImageSubtitleCodec(it.codec) }

/**
 * Runs the transcode decision for [params] and returns the start path (without the token). The decision goes out on
 * its own request layer so none of the client's default `X-Plex-*` headers ride along: everything is in the query.
 * Null when the decision isn't 200 or the request fails.
 */
private suspend fun PlexClient.liveStreamPath(params: Map<String, String>): String? {
    val decision = MediaServerHttpClient(httpClient, baseUrl = config.baseUrl, defaultHeaders = mapOf("Accept-Language" to "en"))
    return try {
        val response = decision.get(PlexTranscode.decisionEndpoint(PlexTranscode.VIDEO_START_ENDPOINT), params)
        if (response.statusCode != 200) {
            Log.w(TAG) { "Live transcode decision returned ${response.statusCode}" }
            null
        } else {
            PlexTranscode.startPath(params)
        }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.e(TAG, e) { "Failed to build live stream path" }
        null
    } finally {
        decision.close()
    }
}

/**
 * `POST /:/timeline` for a live session, without endpoint failover: failing over closes the client the session holds
 * and the server then expires the tuner; the next heartbeat retries the same endpoint instead. The response's
 * `CaptureBuffer.TranscodeSession` is the capture window and its top-level `TranscodeSession` the playback transcode;
 * a lone top-level session is the capture window. Null when the server answers anything but 200 or carries neither.
 */
private suspend fun PlexClient.updateLiveTimeline(
    ratingKey: String,
    sessionPath: String,
    sessionIdentifier: String,
    state: LiveTimelineState,
    timeMs: Long,
    durationMs: Long,
): LiveTimelineUpdate? {
    val response = http.post(
        "/:/timeline",
        mapOf(
            "ratingKey" to ratingKey,
            "key" to sessionPath,
            "state" to state.wire,
            "hasMDE" to "1",
            "time" to timeMs,
            "duration" to durationMs,
            "playbackTime" to timeMs,
            "X-Plex-Session-Identifier" to sessionIdentifier,
        ),
        allowEndpointFailover = false,
    )
    if (response.statusCode != 200) {
        Log.e(TAG) { "Live timeline returned ${response.statusCode}" }
        return null
    }
    val container = response.data.mediaContainer() ?: response.data as? JsonObject ?: return null
    val capture = container["CaptureBuffer"].firstObject()?.get("TranscodeSession").firstObject()?.let(CaptureBuffer::fromTranscodeSession)
    val topLevel = container["TranscodeSession"].firstObject()?.let(CaptureBuffer::fromTranscodeSession)
    val update = if (capture == null) LiveTimelineUpdate(captureBuffer = topLevel) else LiveTimelineUpdate(captureBuffer = capture, playbackStream = topLevel)
    return update.takeUnless { it.isEmpty }
}
