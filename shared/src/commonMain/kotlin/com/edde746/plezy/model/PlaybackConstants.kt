package com.edde746.plezy.model

/** The slowest playback rate every in-app player supports. The video zoom's bounds are the player's `VideoLayout`'s. */
const val MINIMUM_PLAYBACK_RATE: Double = 0.25

/** The fastest playback rate every in-app player supports. */
const val MAXIMUM_PLAYBACK_RATE: Double = 8.0

/**
 * A play queue kept on the client, for Jellyfin, Emby and any backend without server-side queues. Plex's server play
 * queues never become one.
 */
data class LocalPlayQueue(val items: List<MediaItem>, val currentIndex: Int? = null, val shuffled: Boolean = false)
