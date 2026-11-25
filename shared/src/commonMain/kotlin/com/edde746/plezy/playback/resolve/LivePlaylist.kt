package com.edde746.plezy.playback.resolve

/** How a live HLS stream opens in its playlist. */
object LivePlaylist {
    /** lavf's `live_start_index` default (−3): a live HLS file opens this many segments before its playlist's end. */
    const val JOIN_SEGMENTS = 3
}
