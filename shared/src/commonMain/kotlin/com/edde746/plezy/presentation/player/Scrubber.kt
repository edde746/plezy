package com.edde746.plezy.presentation.player

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * The seek bar's preview while the user drags it (a pointer, a remote's touch surface).
 *
 * Where the drag may [follow] the video ([dragTo]), the video seeks along with the preview, at most every
 * [SEEK_INTERVAL]: the first move at once, the last one of each interval as it ends ([seek]). The preview commits
 * ([commitNow]: the drag released, Select) with [commit], told whether the video already went there (the last seek
 * along the drag was to that very place); [cancel] gives the video back where the scrub started when it went
 * elsewhere meanwhile, and [end] drops the preview as it is.
 */
internal class Scrubber(
    private val scope: CoroutineScope,
    private val seek: (Double) -> Unit,
    private val commit: (target: Double, alreadyThere: Boolean) -> Unit,
) {
    /** The preview, in seconds; null when not scrubbing. */
    var preview: Double? = null
        private set

    /** Where the scrub started. */
    var origin = 0.0
        private set

    val active: Boolean get() = preview != null

    /** The last seek along the drag, since the scrub started; null before the first. */
    private var lastSeek: Double? = null

    /** The interval since the last seek along the drag; [trailing] goes as it ends. */
    private var interval: Job? = null
    private var trailing: Double? = null

    /** Moves the preview to [seconds]; the first move starts a scrub at [from]. [follow]: the video seeks along. */
    fun dragTo(seconds: Double, from: Double, follow: Boolean) {
        if (preview == null) origin = from
        preview = seconds
        if (!follow) return
        if (interval?.isActive == true) trailing = seconds else seekAlong(seconds)
    }

    private fun seekAlong(seconds: Double) {
        lastSeek = seconds
        seek(seconds)
        interval = scope.launch {
            delay(SEEK_INTERVAL)
            interval = null
            trailing?.let {
                trailing = null
                if (preview != null) seekAlong(it)
            }
        }
    }

    fun commitNow() {
        val target = preview ?: return
        val alreadyThere = lastSeek == target
        end()
        commit(target, alreadyThere)
    }

    /** Drops the preview; the video, if it seeked along, goes back to where the scrub started. */
    fun cancel() {
        val seeked = lastSeek != null
        val from = origin
        if (preview == null) return
        end()
        if (seeked) seek(from)
    }

    /** Drops the preview as it is, without seeking. */
    fun end() {
        preview = null
        lastSeek = null
        trailing = null
        interval?.cancel()
        interval = null
    }

    companion object {
        /** The video follows a drag at most this often. */
        val SEEK_INTERVAL: Duration = 200.milliseconds
    }
}
