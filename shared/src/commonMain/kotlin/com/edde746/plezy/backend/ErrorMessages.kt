package com.edde746.plezy.backend

import com.edde746.plezy.log.Log
import com.edde746.plezy.strings.T

/** [localizedLoadErrorText] for a failed load of [context], logging [error] once. */
fun localizedLoadErrorMessage(error: Throwable, context: String): String {
    Log.e("LoadError", error) { "Error loading $context" }
    return localizedLoadErrorText(error, context)
}

/**
 * What a screen says when loading [context] failed: a timeout, an unreachable server, or a generic retry hint. Never
 * the server's or the exception's own text.
 */
fun localizedLoadErrorText(error: Throwable, context: String): String {
    if (error is MediaServerHttpException) {
        when (error.type) {
            MediaServerHttpErrorType.CONNECTION_TIMEOUT, MediaServerHttpErrorType.RECEIVE_TIMEOUT -> return T.errors.connectionTimeout(context)
            MediaServerHttpErrorType.CONNECTION_ERROR -> return T.errors.connectionFailed
            MediaServerHttpErrorType.CANCELLED, MediaServerHttpErrorType.UNKNOWN -> Unit
        }
    }
    return T.errors.unableToLoad(context)
}

/**
 * Why an action failed, as a clause a message embeds: a playback failure's own text, an exception's display text, then
 * the failure kind or status; never a host or server text.
 */
fun localizedErrorReason(error: Throwable): String {
    if (error is PlaybackException) return error.message.orEmpty()
    if (error is MediaServerException) error.display?.takeIf { it.isNotEmpty() }?.let { return it }
    if (error is MediaServerHttpException) {
        when (error.type) {
            MediaServerHttpErrorType.CONNECTION_TIMEOUT, MediaServerHttpErrorType.RECEIVE_TIMEOUT -> return T.errors.reasonTimedOut
            MediaServerHttpErrorType.CONNECTION_ERROR -> return T.errors.reasonUnreachable
            MediaServerHttpErrorType.CANCELLED -> return T.errors.reasonCancelled
            MediaServerHttpErrorType.UNKNOWN -> Unit
        }
        val status = error.statusCode
        if (status == 401 || status == 403) return T.errors.reasonRefused
        if (status == 404) return T.errors.reasonNotFound
        if (status != null && status >= 500) return T.errors.reasonServerError
    }
    if (error is MediaServerAuthException) return T.errors.reasonRefused
    return T.errors.reasonUnexpected
}
