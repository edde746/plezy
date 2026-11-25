package com.edde746.plezy.music

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.playback.report.PlayMethod
import com.edde746.plezy.playback.resolve.StreamHeaders
import com.edde746.plezy.playback.source.PlaybackReportingMode
import com.edde746.plezy.playback.source.PlaybackSourceResolver
import com.edde746.plezy.plex.generateSessionIdentifier
import com.edde746.plezy.strings.T

/** The audio goes out through Apple's audio stack (iOS, iPadOS, macOS, tvOS). */
internal expect val appleAudioOutput: Boolean

/**
 * What the session needs to open and report one track.
 *
 * @param url the stream, or a downloaded copy's local file or `content://` URI.
 * @param headers the request headers for [url] alone.
 * @param playSessionId the server's playback session, echoed in the progress reports.
 * @param playMethod `DirectPlay` or `Transcode`, for the reports.
 * @param reporting where the progress reports go: [PlaybackReportingMode.OFFLINE_QUEUE] to the offline queue,
 *   [PlaybackReportingMode.ONLINE_WITH_OFFLINE_FALLBACK] (a downloaded copy with its server reachable) to the server,
 *   queued offline when it refuses; nowhere when [PlaybackReportingMode.DISABLED].
 * @param reportingBackend the track's server, for [PlaybackReportingMode.ONLINE] and the fallback mode.
 * @param mediaInfo the playing source, whose id goes in the reports.
 */
data class MusicSource(
    val url: String,
    val headers: Map<String, String> = emptyMap(),
    val playSessionId: String? = null,
    val playMethod: String? = null,
    val reporting: PlaybackReportingMode = PlaybackReportingMode.DISABLED,
    val reportingBackend: MediaBackend? = null,
    val mediaInfo: MediaSourceInfo? = null,
)

/** Resolves a track to its [MusicSource]; [offline] plays downloaded copies only. */
fun interface MusicSourceResolver {
    suspend fun resolve(track: MediaItem, offline: Boolean): MusicSource
}

/**
 * Resolves a track through the shared [PlaybackSourceResolver]: the first media version, the video preset at Original
 * (ignored for tracks, and it keeps a downloaded copy ahead of the network), the music quality preset, and fresh
 * session and transcode ids per track, so gapless arming never reuses a live transcode session.
 */
class PlaybackMusicSourceResolver(
    private val resolver: PlaybackSourceResolver,
    private val audioQuality: suspend () -> AudioQualityPreset,
) : MusicSourceResolver {
    override suspend fun resolve(track: MediaItem, offline: Boolean): MusicSource {
        val context = resolver.resolve(
            PlaybackInitializationOptions(
                metadata = track,
                selectedMediaIndex = 0,
                qualityPreset = TranscodeQualityPreset.ORIGINAL,
                audioQualityPreset = audioQuality(),
                sessionIdentifier = generateSessionIdentifier(),
                transcodeSessionId = generateSessionIdentifier(),
            ),
            offlineLibraryMode = offline,
        )
        val result = context.result
        val url = result.videoUrl
            ?: throw PlaybackException(T.music.noAudioUrl(track.title ?: track.id), PlaybackFailureReason.NO_PLAYABLE_SOURCE)
        return MusicSource(
            url = url,
            headers = context.streamHeaders?.let(StreamHeaders::sanitize).orEmpty(),
            playSessionId = result.playSessionId,
            playMethod = PlayMethod.of(result.playMethod, result.isTranscoding),
            reporting = context.reportingMode,
            reportingBackend = context.reportingClient,
            mediaInfo = result.mediaInfo,
        )
    }
}
