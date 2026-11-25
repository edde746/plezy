package com.edde746.plezy.model

/**
 * Whether a position counts as watched: [positionMs] / [durationMs] reaches [threshold] (0–1). The exact boundary
 * and positions past the end count; an unknown or zero duration never does. The one decision every path shares
 * (online progress, player-app returns, offline queueing).
 */
fun isWatchedProgress(positionMs: Long, durationMs: Long, threshold: Double): Boolean {
    if (durationMs <= 0) return false
    return positionMs.toDouble() / durationMs >= threshold
}
