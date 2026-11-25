package com.edde746.plezy.playback.session

import com.edde746.plezy.log.Log
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineErrorKind

/**
 * A development build's simulated server failure (the player's debug page, [PlayerSession.simulateHttpError]): the
 * warning FFmpeg logs for a real one and the error the player then reports, `HTTP <status>`.
 */
object SimulatedHttpError {
    fun of(status: Int): EngineError {
        Log.w("ffmpeg") { "https: HTTP error $status Simulated" }
        return EngineError("HTTP $status", status, EngineErrorKind.OPEN)
    }

    /** The failure a real response with [status] names; null for a status no rule singles out. */
    fun cause(status: Int): FailureCause? = when (status) {
        500 -> FailureCause.SERVER_HTTP_500
        404 -> FailureCause.SERVER_HTTP_404
        503 -> FailureCause.SERVER_HTTP_503
        else -> null
    }
}
