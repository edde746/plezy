package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.TranscodeQualityPreset

/** The highest rung of live TV's fallback ladder before it gives up. */
const val MAX_LIVE_FALLBACK_LEVEL = 2

/** What failed a playback, as far as the engine or the session's watchdogs tell ([resolvePlaybackFailureAction]). */
enum class FailureCause {
    /** The audio device stopped taking audio. */
    AUDIO_OUTPUT,

    /** mpv gave a stream up as it opened ([com.edde746.plezy.playback.mpv.OpenFailureLog]). */
    STREAM_INIT,

    /** The open made no progress for its deadline ([OpenOutcome]). */
    OPEN_TIMED_OUT,

    /** The engine's error carried HTTP 404. */
    SERVER_HTTP_404,

    /** The engine's error carried HTTP 500. */
    SERVER_HTTP_500,

    /** The server answered the open with 503 for the watchdog's whole patience ([Http503Watchdog]). */
    SERVER_HTTP_503,
}

/** What the player does about one playback error ([resolvePlaybackFailureAction]). */
enum class PlaybackFailureAction {
    /** HTTP 403: the server refuses this account or connection. */
    PLAYBACK_NOT_ALLOWED,

    /** HTTP 500: a bandwidth or transcode limit refused the session. */
    SERVER_LIMIT,

    /** HTTP 404: the server can't read the file behind the item. */
    MEDIA_UNREADABLE,

    /** HTTP 503 through the whole open. */
    SERVER_BUSY,

    /** A live retry owns the player and its error. */
    IGNORE,

    /** Climb a rung of live TV's fallback ladder. */
    LIVE_RETRY,

    /** Live TV's ladder is spent and its last retry failed. */
    LIVE_INTERRUPTED,

    /** The error as it is. */
    FATAL,
}

/**
 * What [cause] and the HTTP statuses latched on this open ([fatalHttpStatuses]: 403, 404, 500 seen in the engine's log)
 * mean. An audio output failure comes first: nothing about the stream helps a dead output. On demand, 403 outranks the
 * rest (until the server lets this account stream, what it says about the file is moot); 500 is the server's limit,
 * live too; 404 the file unreadable; the 503 watchdog's cause the server busy. Live TV rides 403, 404 and 503 out on its
 * ladder ([MAX_LIVE_FALLBACK_LEVEL] rungs; a running retry owns the error), since a segment that rolled off or a
 * transcode restarting answers that way mid-stream. Everything else is [PlaybackFailureAction.FATAL].
 */
fun resolvePlaybackFailureAction(
    cause: FailureCause?,
    fatalHttpStatuses: Set<Int>,
    live: Boolean,
    liveRetrying: Boolean = false,
    liveFallbackLevel: Int = 0,
    liveRetryFailed: Boolean = false,
): PlaybackFailureAction {
    if (cause == FailureCause.AUDIO_OUTPUT) return PlaybackFailureAction.FATAL
    if (!live && 403 in fatalHttpStatuses) return PlaybackFailureAction.PLAYBACK_NOT_ALLOWED
    if (cause == FailureCause.SERVER_HTTP_500 || 500 in fatalHttpStatuses) return PlaybackFailureAction.SERVER_LIMIT
    if (!live && (cause == FailureCause.SERVER_HTTP_404 || 404 in fatalHttpStatuses)) return PlaybackFailureAction.MEDIA_UNREADABLE
    if (!live && cause == FailureCause.SERVER_HTTP_503) return PlaybackFailureAction.SERVER_BUSY
    if (live) {
        if (liveRetrying) return PlaybackFailureAction.IGNORE
        if (liveFallbackLevel < MAX_LIVE_FALLBACK_LEVEL) return PlaybackFailureAction.LIVE_RETRY
        if (liveRetryFailed) return PlaybackFailureAction.LIVE_INTERRUPTED
    }
    return PlaybackFailureAction.FATAL
}

/**
 * Whether the server-limit error offers to play the item transcoded instead: an on-demand Plex open at Original on a
 * server that transcodes, once per item ([fallbackAlreadyUsed]). The refused request is never retried as it was; the
 * offer asks for a transcode with direct play withheld and no cap of ours, so the server picks what its limit admits.
 */
fun offersServerLimitTranscode(
    live: Boolean,
    plexBacked: Boolean,
    serverSupportsTranscoding: Boolean,
    requestedPreset: TranscodeQualityPreset,
    fallbackAlreadyUsed: Boolean,
): Boolean {
    if (live || !plexBacked || !serverSupportsTranscoding) return false
    return requestedPreset.isOriginal && !fallbackAlreadyUsed
}

/** The statuses an open latches from the engine's log for [resolvePlaybackFailureAction]. */
val FATAL_PLAYBACK_HTTP_STATUSES: Set<Int> = setOf(403, 404, 500)
