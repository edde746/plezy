package com.edde746.plezy.crash

import com.edde746.plezy.log.Log
import kotlin.concurrent.Volatile
import kotlin.time.Clock
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/**
 * Records what the process held when the OS asked it to release memory (Android's trim-memory and low-memory calls,
 * iOS's memory warning): one `memory.pressure` warning breadcrumb, also logged, so the low-memory exit or watchdog
 * termination that may follow says what was resident. The OS sends warnings in bursts, so at most one is recorded per
 * [INTERVAL]; the next one counts the warnings folded into it as `suppressed`. Main thread only. Each platform reports
 * its warnings here: Android's application, iOS's and tvOS's memory warning, macOS's memory pressure source.
 */
class MemoryPressure(private val now: () -> Instant) {
    /** On the system clock; Swift sees no Kotlin default arguments. */
    constructor() : this({ Clock.System.now() })

    private var last: Instant? = null
    private var suppressed = 0

    /**
     * The OS asked the process to release memory. [before] is what it held (`rssMb`, `maxRssMb`, the image cache,
     * [playbackData]); [release] frees what the app can and returns the numbers after it (keys ending in `After`).
     * [release] runs every time; the breadcrumb, returned too, only when this warning isn't folded into the next one.
     */
    fun onPressure(before: Map<String, Any>, release: () -> Map<String, Any>): Breadcrumb? {
        val at = now()
        val previous = last
        // A wall clock set back doesn't silence the breadcrumbs until it catches up again.
        if (previous != null && at >= previous && at - previous < INTERVAL) {
            suppressed++
            release()
            return null
        }
        last = at
        val data = LinkedHashMap(before)
        data.putAll(release())
        if (suppressed > 0) data["suppressed"] = suppressed
        suppressed = 0
        val breadcrumb = Breadcrumb(CATEGORY, "Memory pressure", data, warning = true)
        CrashCapture.breadcrumb(breadcrumb)
        Log.i(TAG) { "Memory pressure: " + data.entries.joinToString(" ") { (key, value) -> "$key=$value" } }
        return breadcrumb
    }

    companion object {
        const val CATEGORY = "memory.pressure"
        val INTERVAL = 30.seconds
        private const val TAG = "memory"

        /** The open video playback's [playbackData], which the app session sets while its player is open. */
        @Volatile
        var playback: (() -> Map<String, Any>)? = null

        /** [playback]'s data, or no video session. */
        fun currentPlayback(): Map<String, Any> = playback?.invoke() ?: playbackData(false, null, 0, 0)

        /**
         * The image memory cache's part of a breadcrumb: its size in whole megabytes and its images; [after] the
         * release, as `imageCacheMbAfter` and `imageCacheImagesAfter`. Neither image loader (Coil, Nuke) counts the
         * images on screen apart from the cache, so there is no `liveImages`.
         */
        fun imageCacheData(bytes: Long, images: Int, after: Boolean): Map<String, Any> {
            val suffix = if (after) "After" else ""
            return mapOf("imageCacheMb$suffix" to (bytes shr 20), "imageCacheImages$suffix" to images)
        }

        /**
         * The playback's part of a breadcrumb: whether a video session is open and, once its player is built, whether
         * it plays and how far it has buffered ahead of the playhead ([bufferedMs] behind it after a seek counts as 0).
         */
        fun playbackData(videoSession: Boolean, playing: Boolean?, positionMs: Long, bufferedMs: Long): Map<String, Any> = buildMap {
            put("videoSession", videoSession)
            if (playing != null) {
                put("playbackActive", playing)
                put("bufferAheadMs", maxOf(0L, bufferedMs - positionMs))
            }
        }
    }
}
