package com.edde746.plezy.backend

import io.ktor.client.network.sockets.ConnectTimeoutException
import io.ktor.client.network.sockets.SocketTimeoutException
import io.ktor.client.plugins.HttpRequestTimeoutException
import io.ktor.http.Url
import kotlinx.io.IOException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.serialization.json.JsonElement

/**
 * A failure talking to a media server. [message] is English for logs; [display] (when set) is the localized text a
 * screen shows.
 */
sealed class MediaServerException(message: String, val display: String? = null, cause: Throwable? = null) : Exception(message, cause)

/** A URL the user typed or a server reported that can't be used; [cause] is the failure that disqualified it, if any. */
class MediaServerUrlException(message: String, display: String? = null, cause: Throwable? = null) : MediaServerException(message, display, cause)

/** Sign-in failed or a token was refused. */
open class MediaServerAuthException(message: String, val statusCode: Int? = null, display: String? = null) :
    MediaServerException(message, display)

/** The plex.tv PIN expired before the user signed in. */
class MediaServerPinExpiredException(display: String? = null) : MediaServerAuthException("PIN expired before sign-in", display = display)

/** The DVR refused a recording that clashes with another. */
class RecordingConflictException(message: String, display: String? = null) : MediaServerException(message, display)

/** The client sent no delete: the server doesn't allow media deletion now (Plex's Allow media deletion switch is off). */
class MediaDeletionRefusedException : MediaServerException("Media deletion is turned off on this server")

/** The server ended the playback session ([code], with its [reason]). */
class PlaybackSessionTerminatedException(val code: Int, val reason: String? = null) :
    MediaServerException("Server terminated playback session (code $code)${reason?.let { ": $it" } ?: ""}")

enum class MediaServerHttpErrorType { CONNECTION_TIMEOUT, RECEIVE_TIMEOUT, CONNECTION_ERROR, CANCELLED, UNKNOWN }

/**
 * Every HTTP-level failure: a status the caller rejected ([statusCode]), a timeout, a connection or decode failure.
 * The query string never reaches [toString] (it carries tokens).
 */
class MediaServerHttpException(
    val type: MediaServerHttpErrorType,
    message: String = "",
    val statusCode: Int? = null,
    val responseData: JsonElement? = null,
    val requestUri: Url? = null,
    display: String? = null,
    cause: Throwable? = null,
) : MediaServerException(message, display, cause) {
    /** Timeouts and connection failures: worth a retry, and a reason to serve cached data. */
    val isTransient: Boolean
        get() = type == MediaServerHttpErrorType.CONNECTION_TIMEOUT ||
            type == MediaServerHttpErrorType.CONNECTION_ERROR ||
            type == MediaServerHttpErrorType.RECEIVE_TIMEOUT

    val isCancellation: Boolean get() = type == MediaServerHttpErrorType.CANCELLED

    override fun toString(): String {
        val parts = mutableListOf(type.name.lowercase().snakeToCamel())
        if (statusCode != null) parts += "HTTP $statusCode"
        if (!message.isNullOrEmpty()) parts += message!!
        requestUri?.let { parts += "${it.host}${it.encodedPath}" }
        return "MediaServerHttpException(${parts.joinToString(": ")})"
    }

    companion object {
        /**
         * [error] as an HTTP exception: itself when it is one; timeouts as connection timeouts; I/O failures as
         * connection errors; anything else unknown.
         */
        fun from(error: Throwable, uri: Url? = null): MediaServerHttpException = when (error) {
            is MediaServerHttpException -> error
            is TimeoutCancellationException, is HttpRequestTimeoutException, is ConnectTimeoutException ->
                MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.message.orEmpty(), requestUri = uri, cause = error)
            is SocketTimeoutException ->
                MediaServerHttpException(MediaServerHttpErrorType.RECEIVE_TIMEOUT, error.message.orEmpty(), requestUri = uri, cause = error)
            is IOException ->
                MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, error.message.orEmpty(), requestUri = uri, cause = error)
            else -> MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, error.toString(), requestUri = uri, cause = error)
        }
    }
}

private fun String.snakeToCamel(): String =
    split('_').mapIndexed { i, part -> if (i == 0) part else part.replaceFirstChar { it.uppercase() } }.joinToString("")
