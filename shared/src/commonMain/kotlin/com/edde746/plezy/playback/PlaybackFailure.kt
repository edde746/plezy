package com.edde746.plezy.playback

import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.log.Redactor
import com.edde746.plezy.strings.T

/**
 * Why the current video can't play: what the playback session surfaces and the player store words. No variant holds a
 * URL: the session builds [Engine] errors with [withoutSecrets].
 */
sealed interface PlaybackFailure {
    /** The engine couldn't open or keep playing the video; [EngineError.httpStatus] when an HTTP answer said why. */
    data class Engine(val error: EngineError) : PlaybackFailure

    /** The media server wouldn't start the playback ([PlaybackFailureReason]); [message] is the text the player shows. */
    data class Server(val reason: PlaybackFailureReason, val message: String) : PlaybackFailure

    /**
     * The server answered HTTP 500 for the file (Plex: a bandwidth or transcode limit likely refused the session);
     * [transcodeOffered] the error offers to play it transcoded ([PlayerSession.forceTranscode]): a Plex server that
     * can transcode, not live, not transcoding at a capped preset already.
     */
    data class ServerLimit(val transcodeOffered: Boolean) : PlaybackFailure
}

/** The failure as the player words it (its error card's message). */
internal val PlaybackFailure.displayText: String
    get() = when (this) {
        // The engine's own text is English (mpv's): it goes to the log, the player says what it means.
        is PlaybackFailure.Engine -> error.httpStatus?.let(::httpText) ?: when (error.kind) {
            EngineErrorKind.OPEN -> T.player.error.cantOpen
            EngineErrorKind.FORMAT -> T.player.error.unsupportedFormat
            EngineErrorKind.DECODE -> T.player.error.cantDecode
            EngineErrorKind.OTHER -> T.player.error.engineFailed
            EngineErrorKind.AUDIO_OUTPUT -> T.messages.audioOutputFailed
            EngineErrorKind.CUT_SHORT -> T.player.error.cutShort
        }
        is PlaybackFailure.Server -> message
        is PlaybackFailure.ServerLimit -> T.messages.serverLimitBody
    }

private fun httpText(status: Int): String = when (status) {
    403, 410 -> T.player.error.expired
    404 -> T.player.error.notFound
    else -> T.player.error.http(status.toString())
}

/**
 * The error with its message fit to keep in the session's state, which logs and reports print (the player shows its
 * [EngineError.kind] instead): URLs (stream links carry API keys) and key-shaped tokens are cut out ([Redactor]).
 */
internal fun EngineError.withoutSecrets(): EngineError {
    // Prose punctuation right after a URL stays: "Failed to open <url>: 403" keeps its colon.
    val text = URL.replace(message) { match -> match.value.substring(match.value.trimEnd { it in TRAILING_PUNCTUATION }.length) }
        .let(Redactor::redact)
        .replace(SPACE_BEFORE_PUNCTUATION, "$1")
        .replace(SPACES, " ")
        .trim()
        .trimStart(':', ',', ';', '.')
        .trimEnd(':', ',', ';')
        .trim()
    return copy(message = text)
}

// An apostrophe inside a URL is part of it (`Night's.Journey.mkv`), a closing one is not ([Redactor]'s rule). The
// second branch is a peer-to-peer link.
private val URL = Regex("""\b[A-Za-z][A-Za-z0-9+.\-]*://[^\s"<>]*|\bmagnet:\?[^\s"'<>]*""", RegexOption.IGNORE_CASE)
private const val TRAILING_PUNCTUATION = ").,;:!?]}'"
private val SPACE_BEFORE_PUNCTUATION = Regex("""\s+([:,;.!?])""")
private val SPACES = Regex("""\s{2,}""")
