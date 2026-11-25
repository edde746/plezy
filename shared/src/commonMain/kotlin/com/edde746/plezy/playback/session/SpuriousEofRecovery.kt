package com.edde746.plezy.playback.session

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/** How an in-place reload of the video ended. */
enum class ReloadOutcome {
    /** Refused before anything changed (live, closed, another transition running). */
    REJECTED,

    /** A newer attempt took over; its outcome is what shows. */
    SUPERSEDED,

    /** The replacement opened. */
    OPENED,

    /** It failed before the replacement opened: the previous file and its state are back. */
    FAILED,
}

/**
 * An end of file of an online on-demand file, with what tells a real end from a stream that died ([SpuriousEofRecovery]).
 * Positions in the item's time; [partEndMillis] when the open file is one of a stacked item's (it ends at its own span).
 */
data class EofReport(
    val positionMillis: Long,
    val playerDurationMillis: Long,
    val metadataDurationMillis: Long?,
    val partEndMillis: Long? = null,
    val transcoding: Boolean,
    val transportFault: Boolean,
    val fileSizeBytes: Long?,
    val fileFormat: String?,
    /** The server ended the session (an admin's stop) and no viewer action resumed it since. */
    val serverStopped: Boolean,
) {
    /**
     * The transport holds the media itself at a known size, so FFmpeg's HTTP layer would have logged an early end: a
     * sized file whose format isn't a manifest (`hls`, `dash`: their segments fail elsewhere).
     */
    val byteAddressedMedia: Boolean
        get() {
            val bytes = fileSizeBytes ?: return false
            val format = fileFormat ?: return false
            return bytes > 0 && format.split(',').none { it in MANIFEST_FORMATS }
        }

    private companion object {
        val MANIFEST_FORMATS = setOf("hls", "dash")
    }
}

/**
 * Recovery from an end of file that is a network stream dying mid-file: mpv reports that as a clean end. An end short
 * of the duration ([classifyEofSignal]) is the stream dying, unless the file is a sized direct-play one without a
 * transport fault in all of it ([EofReport.byteAddressedMedia]): FFmpeg would have logged a connection that ended short,
 * so that is the container's own end (a remux whose main tracks end before its dubs) and completes as usual.
 *
 * A dying stream reloads in place at the position ([reload]: a fresh resolve, tracks kept, nothing shown) up to
 * [MAX_ATTEMPTS] times; [PROGRESS_RESET_MILLIS] of playback past the recovery point, or another item ([resetBudget]),
 * gives the budget back. Spent or failed, playback parks ([parked]; [onParked] tells the viewer, nothing exits): the
 * viewer's play or seek, or the server coming back, [retry] without spending the budget. A session the server stopped
 * parks at once: rebuilding it would open a session behind the admin's stop. The caller lets live, local and in-reload
 * ends go to their own handling first.
 */
class SpuriousEofRecovery(
    private val scope: CoroutineScope,
    private val reload: suspend (resumeAtSeconds: Double) -> ReloadOutcome,
    private val onParked: () -> Unit,
) {
    private var attempts = 0
    private var baselineMillis: Long? = null

    var parked: Boolean = false
        private set

    /** A fresh stream opened: no longer parked. */
    fun clearPark() {
        parked = false
    }

    /** Another item: a fresh budget. */
    fun resetBudget() {
        attempts = 0
        baselineMillis = null
    }

    fun onPositionAdvanced(positionMillis: Long) {
        val baseline = baselineMillis ?: return
        if (positionMillis >= baseline + PROGRESS_RESET_MILLIS) resetBudget()
    }

    /** True when [eof] was a dying stream and is handled here (recovering, or parked); false: the video ended. */
    fun interceptEof(eof: EofReport): Boolean {
        if (parked) return true
        val signal = if (eof.partEndMillis != null) {
            classifyEofSignal(eof.positionMillis, 0, eof.partEndMillis)
        } else {
            classifyEofSignal(eof.positionMillis, eof.playerDurationMillis, eof.metadataDurationMillis)
        }
        if (signal != EofSignal.SPURIOUS) return false
        if (!eof.transportFault && !eof.transcoding && eof.byteAddressedMedia) {
            Log.i(TAG) { "end at ${eof.positionMillis} ms short of the duration with no transport fault on a sized ${eof.fileFormat} file: its own end" }
            return false
        }
        if (eof.serverStopped) {
            Log.i(TAG) { "end at ${eof.positionMillis} ms after the server stopped the session: parked" }
            park()
            return true
        }
        Log.w(TAG) { "the stream died at ${eof.positionMillis} ms (transport fault ${eof.transportFault}, transcoding ${eof.transcoding}): recovery ${attempts + 1}/$MAX_ATTEMPTS" }
        if (attempts >= MAX_ATTEMPTS) {
            park()
            return true
        }
        attempts++
        baselineMillis = eof.positionMillis
        scope.launch { if (reload(eof.positionMillis / 1000.0) == ReloadOutcome.FAILED) park() }
        return true
    }

    /** Rebuilds the parked stream at [resumeAtSeconds]: the viewer's play or seek, or the server back online. */
    fun retry(resumeAtSeconds: Double) {
        parked = false
        scope.launch { if (reload(resumeAtSeconds) == ReloadOutcome.FAILED) park() }
    }

    private fun park() {
        parked = true
        onParked()
    }

    companion object {
        const val MAX_ATTEMPTS = 2
        const val PROGRESS_RESET_MILLIS = 30_000L
        private const val TAG = "eof-recovery"
    }
}
