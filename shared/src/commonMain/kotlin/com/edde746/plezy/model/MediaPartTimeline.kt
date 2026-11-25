package com.edde746.plezy.model

import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** One file's span on the timeline of an item stacked across several files. */
data class MediaPartSpan(
    /** Backend part id ([MediaPart.id]). */
    val partId: String,
    /** Where this file begins on the item's timeline. */
    val start: Duration,
    val duration: Duration,
) {
    val end: Duration get() = start + duration
}

/**
 * The timeline of an item stacked across several files (Plex's `Movie - Part 1.mkv`, `Movie - Part 2.mkv`) and which
 * of them is open.
 *
 * Everything above the player speaks item time: resume offsets, progress reports, markers, chapters and the seek bar
 * all cover the whole item. Only the open file is part-relative, and the player translates at its own boundary.
 * Reaching the end of a file that is not the last, or seeking outside it, opens the file that holds the target
 * instead.
 */
class MediaPartTimeline private constructor(val parts: List<MediaPartSpan>, val currentIndex: Int) {
    val current: MediaPartSpan get() = parts[currentIndex]

    /** The whole item: every file back to back. */
    val duration: Duration get() = parts.last().end

    val hasNext: Boolean get() = currentIndex < parts.size - 1

    /** The file holding [position]. Positions before the item belong to the first file and positions past its end to the last. */
    fun indexAt(position: Duration): Int {
        for (i in 0 until parts.size - 1) {
            if (position < parts[i].end) return i
        }
        return parts.size - 1
    }

    /** Whether the open file plays [position] without another file opening. */
    fun covers(position: Duration): Boolean = indexAt(position) == currentIndex

    companion object {
        /**
         * The timeline of one version's [parts] with [currentIndex] open. Null for a single-file version, for an index
         * out of range, and when any part lacks a duration: without every boundary, item time cannot be mapped onto
         * the files.
         */
        fun fromParts(parts: List<MediaPart>, currentIndex: Int = 0): MediaPartTimeline? {
            if (parts.size < 2 || currentIndex !in parts.indices) return null
            val spans = ArrayList<MediaPartSpan>(parts.size)
            var start = Duration.ZERO
            for (part in parts) {
                val durationMs = part.durationMs
                if (durationMs == null || durationMs <= 0) return null
                val duration = durationMs.milliseconds
                spans += MediaPartSpan(partId = part.id, start = start, duration = duration)
                start += duration
            }
            return MediaPartTimeline(spans, currentIndex)
        }
    }
}
