package com.edde746.plezy.backend

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaPartTimeline
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.strings.T
import kotlinx.serialization.SerializationException
import kotlin.time.Duration
import kotlin.time.Instant

/** A transcode's video cap; [ORIGINAL] plays the file as it is. */
enum class TranscodeQualityPreset(val videoBitrateKbps: Int?, val videoResolution: String?, val videoQuality: Int?) {
    ORIGINAL(null, null, null),
    P240_320(320, "420x240", 30),
    P320_720(720, "576x320", 40),
    P480_1_5MBPS(1500, "720x480", 60),
    P720_2MBPS(2000, "1280x720", 60),
    P720_3MBPS(3000, "1280x720", 75),
    P720_4MBPS(4000, "1280x720", 100),
    P1080_8MBPS(8000, "1920x1080", 60),
    P1080_10MBPS(10000, "1920x1080", 75),
    P1080_12MBPS(12000, "1920x1080", 90),
    P1080_20MBPS(20000, "1920x1080", 100),
    ;

    val isOriginal: Boolean get() = this == ORIGINAL

    val resolutionHeight: Int? get() = videoResolution?.split('x')?.takeIf { it.size == 2 }?.get(1)?.toIntOrNull()

    /** The source fits under this cap already (so transcoding to it gains nothing). */
    fun coversSource(bitrateKbps: Int?, heightPx: Int?): Boolean {
        val capKbps = videoBitrateKbps ?: return false
        val capHeight = resolutionHeight ?: return false
        if (bitrateKbps == null || bitrateKbps <= 0 || heightPx == null || heightPx <= 0) return false
        return bitrateKbps <= capKbps && heightPx <= capHeight
    }

    companion object {
        /** Original first, then the caps from best to worst. */
        val displayOrder: List<TranscodeQualityPreset> = listOf(ORIGINAL) + entries.filter { !it.isOriginal }.reversed()

        /**
         * The saved default a playback without a per-play pick starts at: [ORIGINAL] on a backend that can't
         * transcode, whatever is saved; else [cellularDefault] on a cellular-only connection when it is set; else
         * [generalDefault].
         */
        fun resolveStartupDefault(
            serverSupportsTranscoding: Boolean,
            onCellularOnly: Boolean,
            cellularDefault: TranscodeQualityPreset?,
            generalDefault: TranscodeQualityPreset,
        ): TranscodeQualityPreset = when {
            !serverSupportsTranscoding -> ORIGINAL
            onCellularOnly && cellularDefault != null -> cellularDefault
            else -> generalDefault
        }
    }
}

/** A music transcode's bitrate cap. */
enum class AudioQualityPreset(val bitrateKbps: Int?) {
    ORIGINAL(null),
    HIGH(320),
    MEDIUM(192),
    LOW(128),
    ;

    val isOriginal: Boolean get() = this == ORIGINAL
}

/** The audio track the user prefers, as the player last had it. */
data class AudioTrackPreference(val language: String? = null, val title: String? = null, val codec: String? = null, val channels: Int? = null)

/** The subtitle the user prefers: explicitly none, or a track described by its semantics. */
sealed interface SubtitlePreference {
    data object Off : SubtitlePreference

    data class Track(
        val language: String? = null,
        val forced: Boolean = false,
        val title: String? = null,
        val codec: String? = null,
        val isExternal: Boolean = false,
        /** The source row picked in this same item and source; null once the preference crossed to another item. */
        val sourceStreamId: Int? = null,
    ) : SubtitlePreference
}

/** A subtitle file the player loads beside the video. */
data class SubtitleSidecar(
    val url: String,
    val title: String? = null,
    val language: String? = null,
    val codec: String? = null,
    val forced: Boolean = false,
    val isDefault: Boolean = false,
)

data class PlaybackInitializationOptions(
    val metadata: MediaItem,
    val selectedMediaIndex: Int,
    val selectedMediaSourceId: String? = null,
    val preferredVersionSignature: String? = null,
    val qualityPreset: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
    val audioQualityPreset: AudioQualityPreset? = null,
    val selectedAudioStreamId: Int? = null,
    val preferredAudioTrack: AudioTrackPreference? = null,
    val preferredSubtitleTrack: SubtitlePreference? = null,
    val sessionIdentifier: String? = null,
    val transcodeSessionId: String? = null,
    val startPosition: Duration? = null,
    val forceTranscode: Boolean = false,
)

/** An external subtitle of the source, with the server stream it came from. */
data class PlaybackSubtitleSidecar(val sourceStreamId: Int?, val track: SubtitleSidecar, val preload: Boolean = false)

/** Why a transcode request fell back to direct play. */
enum class TranscodeFallbackReason { DIRECT_PLAY_ONLY, DECISION_FAILED }

data class PlaybackInitializationResult(
    val availableVersions: List<MediaVersion>,
    val videoUrl: String? = null,
    val mediaInfo: MediaSourceInfo? = null,
    val subtitleSidecars: List<PlaybackSubtitleSidecar> = emptyList(),
    /** A downloaded copy plays; clients never set it, offline substitution does. */
    val isOffline: Boolean = false,
    val isTranscoding: Boolean = false,
    val fallbackReason: TranscodeFallbackReason? = null,
    val activeAudioStreamId: Int? = null,
    val playSessionId: String? = null,
    val playMethod: String? = null,
    val selectedMediaIndex: Int = 0,
    val selectedMediaSourceId: String? = null,
    /** The quality the server transcoded a downloaded copy ([isOffline]) to; [TranscodeQualityPreset.ORIGINAL] otherwise. */
    val downloadedQuality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
) {
    val selectedVersion: MediaVersion? get() = availableVersions.getOrNull(selectedMediaIndex)
    val externalSubtitles: List<SubtitleSidecar> get() = subtitleSidecars.map { it.track }
}

enum class PlaybackFailureReason {
    AUTHENTICATION_REQUIRED,
    PLAYBACK_NOT_ALLOWED,
    SERVER_UNAVAILABLE,
    CANCELLED,
    INVALID_PLAYBACK_DATA,
    NO_PLAYABLE_SOURCE,
    UNKNOWN,
}

/** Playback can't start; [message] is the localized text the player shows. */
class PlaybackException(message: String, val reason: PlaybackFailureReason = PlaybackFailureReason.UNKNOWN) : Exception(message)

/**
 * A failure to start playback as the player shows it: 403 not allowed; a refused sign-in or 401 sign in again; a
 * cancellation; a transient failure or 5xx server unavailable; a malformed answer invalid data; else failed.
 */
fun classifyPlaybackFailure(error: Throwable): PlaybackException {
    if (error is MediaServerHttpException && error.statusCode == 403) {
        return PlaybackException(T.messages.playbackNotAllowedBody, PlaybackFailureReason.PLAYBACK_NOT_ALLOWED)
    }
    if (error is MediaServerAuthException || (error is MediaServerHttpException && error.statusCode == 401)) {
        return PlaybackException(T.messages.playbackAuthenticationRequired, PlaybackFailureReason.AUTHENTICATION_REQUIRED)
    }
    if (error is MediaServerHttpException) {
        if (error.isCancellation) return PlaybackException(T.messages.playbackCancelled, PlaybackFailureReason.CANCELLED)
        val status = error.statusCode
        if (error.isTransient || (status != null && status >= 500)) {
            return PlaybackException(T.messages.playbackServerUnavailable, PlaybackFailureReason.SERVER_UNAVAILABLE)
        }
        if (error.type == MediaServerHttpErrorType.UNKNOWN && status != null && status < 400) {
            return PlaybackException(T.messages.playbackDataInvalid, PlaybackFailureReason.INVALID_PLAYBACK_DATA)
        }
    }
    if (error is SerializationException || error is IllegalArgumentException || error is ClassCastException) {
        return PlaybackException(T.messages.playbackDataInvalid, PlaybackFailureReason.INVALID_PLAYBACK_DATA)
    }
    return PlaybackException(T.messages.playbackFailed)
}

/** What an OS-level player is handed: a self-contained URL (token in the query) and the subtitle files. */
data class ExternalPlaybackTarget(val url: String, val subtitles: List<SubtitleSidecar> = emptyList(), val partTimeline: MediaPartTimeline? = null)

enum class PlaybackReportOrigin { LIVE, OFFLINE_REPLAY }

/** Semantics of a stopped report: live, or replayed from the offline queue with when it happened. */
data class PlaybackReportMetadata(
    val origin: PlaybackReportOrigin = PlaybackReportOrigin.LIVE,
    val recordedAt: Instant? = null,
    val willContinue: Boolean? = null,
) {
    val isOfflineReplay: Boolean get() = origin == PlaybackReportOrigin.OFFLINE_REPLAY

    companion object {
        fun live(willContinue: Boolean? = null) = PlaybackReportMetadata(PlaybackReportOrigin.LIVE, willContinue = willContinue)

        fun offlineReplay(recordedAt: Instant, willContinue: Boolean = false) =
            PlaybackReportMetadata(PlaybackReportOrigin.OFFLINE_REPLAY, recordedAt, willContinue)
    }
}

/** One frame of a seek-bar preview: encoded image bytes, or a tile of a sprite sheet at [sheetUrl]. */
sealed interface ScrubFrame {
    val aspectRatio: Double

    class Bytes(val bytes: ByteArray, override val aspectRatio: Double = 16.0 / 9) : ScrubFrame

    data class SheetTile(
        val sheetUrl: String,
        val tileColumn: Int,
        val tileRow: Int,
        val sheetColumns: Int,
        val sheetRows: Int,
        val tileWidth: Int,
        val tileHeight: Int,
    ) : ScrubFrame {
        override val aspectRatio: Double get() = tileWidth.toDouble() / tileHeight
    }
}

/** Seek-bar thumbnails of one video. */
interface ScrubPreviewSource {
    val isAvailable: Boolean

    fun frameAt(time: Duration): ScrubFrame?

    fun dispose()
}

/** A subtitle file to save beside a download. */
data class DownloadSubtitleSpec(
    val id: Int,
    val url: String,
    val codec: String? = null,
    val language: String? = null,
    val languageCode: String? = null,
    val forced: Boolean = false,
    val displayTitle: String? = null,
)

/** An artwork file to save with a download; [localKey] deduplicates blobs items share. */
data class DownloadArtworkSpec(val localKey: String, val url: String)

/** A further file of a version stacked over several. */
data class DownloadPartResolution(val url: String, val externalSubtitles: List<DownloadSubtitleSpec> = emptyList())

/**
 * What to download for an item. [externalSubtitlesResolved] false: the subtitle lookup failed and is retried later,
 * the download itself proceeds. [transcode]: the server transcodes the file as it sends it.
 */
data class DownloadResolution(
    val videoUrl: String?,
    val mediaSourceId: String? = null,
    val externalSubtitles: List<DownloadSubtitleSpec> = emptyList(),
    val externalSubtitlesResolved: Boolean = true,
    val additionalParts: List<DownloadPartResolution> = emptyList(),
    val transcode: DownloadTranscode? = null,
)

/**
 * A download the server transcodes to [quality] while it sends it: one stream with no length announced and no byte
 * ranges, so a broken transfer starts over. [expectedBytes] is what the transcode's bitrate cap gives over
 * [durationMs] (an upper bound, null while either is unknown); [durationMs] is the runtime the finished file must cover.
 */
data class DownloadTranscode(val quality: TranscodeQualityPreset, val expectedBytes: Long?, val durationMs: Long?)
