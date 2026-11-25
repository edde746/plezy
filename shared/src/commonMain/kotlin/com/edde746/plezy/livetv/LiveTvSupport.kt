package com.edde746.plezy.livetv

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.RecordingConflictException
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.model.MediaSubtitleTrack
import kotlin.time.Instant

/**
 * A server's Live TV: channels, guide, favourites and tuning, the same operations on Plex, Jellyfin and Emby. Every
 * backend has one ([MediaBackend.liveTv]); whether the server has Live TV configured is [isAvailable]. Recording
 * administration is the separate [dvr], What's On the separate [whatsOn].
 *
 * Plex serves one lineup per DVR (`/livetv/dvrs`); Jellyfin and Emby one flat channel list. [fetchChannels] takes the
 * DVR's [lineup] to scope Plex to that DVR's EPG provider and ignores it elsewhere.
 *
 * Failures follow [MediaBackend]'s contract: requests throw, cancellation propagates.
 */
interface LiveTvSupport {
    /** Recording rules and DVR administration; null when the backend has none. */
    val dvr: LiveTvDvrSupport?

    /** The What's On hubs (Plex only); null elsewhere. */
    val whatsOn: LiveTvWhatsOn?

    /** Whether the server has Live TV configured. Never throws: a failure is false. */
    suspend fun isAvailable(): Boolean

    suspend fun fetchChannels(lineup: String? = null): List<LiveTvChannel>

    /** The airings overlapping [from]..[to], each stamped with its server. */
    suspend fun fetchSchedule(from: Instant? = null, to: Instant? = null): List<LiveTvProgram>

    /**
     * Tunes [channelKey] (Plex needs the [dvrKey]) and negotiates its stream under [quality]: the only way playback
     * starts a channel, for the first tune and for every zap. The tune waits at most the tune timeout; a tuner that
     * answers later is released. Null when the channel can't be started.
     */
    suspend fun startPlayback(
        channelKey: String,
        dvrKey: String? = null,
        quality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
    ): LiveTvPlaybackSession?

    /** The source stamped on this server's favourites: `server://{machineId}/{provider}` (Plex), `server://{serverId}/jellyfin`. */
    suspend fun buildFavoriteChannelSource(lineup: String? = null): String

    /** The store the favourites live in, so a store shared by several servers is read and written once. */
    val favoriteStoreKey: String

    val favoritePersistenceMode: FavoriteChannelPersistenceMode

    /**
     * The whole favourites list (empty when none are stored); an unreadable store throws. [migrate] adopts favourites
     * an earlier release kept under an older key. [checkCurrent] throws when the caller's load was superseded.
     */
    suspend fun fetchFavoriteChannels(migrate: Boolean = true, checkCurrent: (() -> Unit)? = null): List<FavoriteChannel>

    /**
     * Saves [channels] in their order: Plex replaces the account's list on plex.tv; Jellyfin and Emby flag each
     * channel favourite on the server and keep the order locally, persisting only what the server confirmed.
     */
    suspend fun setFavoriteChannels(channels: List<FavoriteChannel>, checkCurrent: (() -> Unit)? = null)
}

/** The recording side of Live TV, in Plex's shapes (Jellyfin and Emby adapt their timers to them). */
interface LiveTvDvrSupport {
    /** Plex's DVRs; Jellyfin and Emby have none (their one Live TV entry is synthesized). */
    suspend fun fetchDvrs(): List<LiveTvDvr>

    suspend fun reloadGuide(dvrId: String)

    suspend fun getSubscriptionTemplate(guid: String): List<SubscriptionTemplate>

    suspend fun fetchRecordingRules(includeGrabs: Boolean = true, includeStorage: Boolean = true): List<MediaSubscription>

    /**
     * The created rule, or null when the server answers without one. A duplicate throws
     * [RecordingConflictException].
     */
    suspend fun createRecordingRule(request: MediaSubscriptionCreateRequest): MediaSubscription?

    suspend fun updateRecordingRule(subscriptionId: String, prefs: Map<String, Any?>, checkCurrent: (() -> Unit)? = null): MediaSubscription?

    suspend fun deleteRecordingRule(subscriptionId: String)

    /** Whether [processRecordingRules] does anything (Plex's "re-evaluate rules"); the UI hides it otherwise. */
    val supportsRuleProcessing: Boolean

    /** Throws [UnsupportedOperationException] unless [supportsRuleProcessing]. */
    suspend fun processRecordingRules()

    suspend fun fetchScheduledRecordings(): List<MediaGrabOperation>

    suspend fun cancelGrab(operationId: String)

    suspend fun fetchSubscriptionMapping(providerId: String, ratingKeys: List<String>, includeStorage: Boolean = true): List<MediaSubscription>
}

/** Plex's What's On: the EPG providers' discover hubs. */
interface LiveTvWhatsOn {
    suspend fun fetchHubs(count: Int = 12): List<LiveTvHub>
}

/** [MediaBackend.liveTv]'s DVR adapter when the backend's capabilities allow recording; null otherwise. */
val MediaBackend.liveTvDvr: LiveTvDvrSupport? get() = if (capabilities.liveTvDvr) liveTv.dvr else null

/** The program a live session tuned into (Plex); [NONE] for Jellyfin and Emby, which tune the channel only. */
data class LiveProgramInfo(
    /** The program's ratingKey, for heartbeats. */
    val id: String? = null,
    val durationMs: Long? = null,
    /** The program's start, epoch seconds. */
    val beginsAt: Long? = null,
) {
    companion object {
        val NONE = LiveProgramInfo()
    }
}

/**
 * What a heartbeat learned: [captureBuffer] is the tuner's seekable history (the frame for time-shift offsets and the
 * timeline's range); [playbackStream] the transcode feeding the player, whose `startedAt` is the epoch of stream
 * position zero. Either may be null.
 */
data class LiveTimelineUpdate(val captureBuffer: CaptureBuffer? = null, val playbackStream: CaptureBuffer? = null) {
    val isEmpty: Boolean get() = captureBuffer == null && playbackStream == null
}

enum class LiveTimelineState(val wire: String) { PLAYING("playing"), PAUSED("paused"), STOPPED("stopped") }

/**
 * One tuned channel, from [LiveTvSupport.startPlayback]. Sessions are immutable handles: whatever changes the stream
 * returns a URL or a new session for the player to adopt. A session belongs to the client that made it; once that
 * client closes, [recover] and heartbeats fail.
 */
interface LiveTvPlaybackSession {
    val program: LiveProgramInfo

    /** What a TV app does with this session in the background. */
    val backgroundPolicy: LiveTvBackgroundPolicy

    /** The seekable history at tune time; heartbeats report fresher ones. Null without time-shift. */
    val captureBuffer: CaptureBuffer?

    /**
     * Subtitle streams the server can burn into the stream (Plex's DVB bitmap subtitles). In-band captions ride the
     * video and stay player-selectable, so they are never listed. Empty on Jellyfin and Emby.
     */
    val subtitleTracks: List<MediaSubtitleTrack>

    /** Whether [streamUrlAt] takes an offset. */
    val canTimeShift: Boolean

    /**
     * The playable URL [offsetSeconds] past the capture buffer's origin (null: the live edge), with [subtitleTrack]
     * (one of [subtitleTracks]) burned in. Null on failure, for an offset without time-shift, or when the server
     * refuses the subtitle selection.
     */
    suspend fun streamUrlAt(offsetSeconds: Long? = null, subtitleTrack: MediaSubtitleTrack? = null): String?

    /** A heartbeat. [positionMs] is playback time since the stream (re)started; [durationMs] the program's. */
    suspend fun reportTimeline(state: LiveTimelineState, positionMs: Long, durationMs: Long): LiveTimelineUpdate?

    /**
     * Releases a session nothing adopted (a superseded zap, a start abandoned, a failed recovery): Plex reports it
     * stopped, Jellyfin and Emby close the live stream without a stop report. Never throws.
     */
    suspend fun discard()

    /**
     * A session to continue after the stream died: Plex re-tunes with the fallback flags; Jellyfin and Emby renegotiate
     * a forced transcode when a direct session must drop [directStream] (closing its live stream), else return this
     * session. Null on failure.
     */
    suspend fun recover(directStream: Boolean, directStreamAudio: Boolean): LiveTvPlaybackSession?
}

enum class LiveTvBackgroundPolicy {
    /** Keep the tuned session (and its capture buffer) while a TV app is in the background. */
    RETAIN_SESSION,

    /** Stop the session in the background and leave the player on return. */
    STOP_AND_EXIT,
}

enum class FavoriteChannelPersistenceMode {
    /** One write replaces the account's whole list (Plex). */
    SHARED_FULL_LIST,

    /** A write carries only this server's favourites (Jellyfin, Emby). */
    SERVER_SLICE,
}
