package com.edde746.plezy.playback.tracks

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.settings.ScopedPlayerPrefs

enum class SyncOffsetKind { AUDIO, SUBTITLE }

/**
 * The audio and subtitle sync offsets one player applies, in milliseconds; one per player, starting at none, as a new
 * player applies no delay. The player keeps its delays across an in-place item swap, so this record, not the stored
 * preference, is what an item change compares against. [setDelay] writes a delay to the player in seconds (mpv
 * `audio-delay` / `sub-delay`).
 */
class PlayerSyncOffsets(
    private val settings: DeviceSettingsRepository,
    private val setDelay: suspend (kind: SyncOffsetKind, seconds: Double) -> Unit,
) {
    private val appliedMs = IntArray(SyncOffsetKind.entries.size)

    /**
     * Makes the player apply [item]'s offsets as their scope resolves them. Every item starts from its own value, so a
     * change made under "Don't save" stays with the item it was made on; an offset already applied is not rewritten.
     */
    suspend fun applyFor(item: MediaItem) {
        apply(SyncOffsetKind.AUDIO, ScopedPlayerPrefs.resolve(settings, ScopedPlayerPrefs.audioSyncOffset, item))
        apply(SyncOffsetKind.SUBTITLE, ScopedPlayerPrefs.resolve(settings, ScopedPlayerPrefs.subtitleSyncOffset, item))
    }

    private suspend fun apply(kind: SyncOffsetKind, offsetMs: Int) {
        if (offsetMs == appliedMs[kind.ordinal]) return
        setDelay(kind, offsetMs / 1000.0)
        recordApplied(kind, offsetMs)
    }

    /** Records an offset the caller already wrote to the player. */
    fun recordApplied(kind: SyncOffsetKind, offsetMs: Int) {
        appliedMs[kind.ordinal] = offsetMs
    }
}
