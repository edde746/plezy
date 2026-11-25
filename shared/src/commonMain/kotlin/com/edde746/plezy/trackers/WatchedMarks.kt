package com.edde746.plezy.trackers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.MediaItem

/**
 * A watched or unwatched mark the user made by hand (or an offline replay, a download sync, a player app's completion),
 * after the media server recorded it: a movie, an episode, a season or a show of [backend]'s.
 */
internal data class WatchedMark(val item: MediaItem, val backend: MediaBackend, val watched: Boolean)

/**
 * Where a video is: milliseconds; [durationMillis] is 0 while unknown, and [creditsStartMillis] is where its credits
 * to the end start when its chapters say (a player app reports none).
 */
data class TrackedPosition(val positionMillis: Long, val durationMillis: Long, val creditsStartMillis: Long? = null)

/**
 * A video's life in one producer of playbacks (the player, a player app's hand-off), as the tracker coordinator
 * follows it. Called on the main thread in this order: started, then any number of playing changes and positions,
 * then stopped. Implementations return at once and never throw, so an observer can never disturb playback.
 */
interface TrackedPlayback {
    /**
     * [item] (a movie or an episode of [backend]'s) opened at [at] (the server's resume offset and the duration),
     * [playing] or paused. It counts as watched past [MediaBackend.watchedThreshold] of its duration. A [live] item
     * is never reported.
     */
    fun onVideoStarted(item: MediaItem, backend: MediaBackend, at: TrackedPosition, playing: Boolean, live: Boolean)

    /** Playback started or stopped moving (paused, backgrounded, resumed). */
    fun onPlayingChanged(playing: Boolean, at: TrackedPosition)

    /** The position moved by at least a second, or jumped (a seek). */
    fun onPosition(at: TrackedPosition)

    /**
     * The video was left: the player closed, reloaded in place or rolled back its start, the next item is about to
     * start, or the video reached its end (then [at] is its duration).
     */
    fun onVideoStopped(at: TrackedPosition)
}
