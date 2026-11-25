package com.edde746.plezy.playback.tracks

import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.PlayerSettingScope
import com.edde746.plezy.settings.ScopedPlayerPrefs
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class PlayerSyncOffsetsTest {
    private val data = testData()
    private val settings = data.deviceSettings
    private val writes = mutableListOf<Pair<SyncOffsetKind, Double>>()
    private val offsets = PlayerSyncOffsets(settings) { kind, seconds -> writes += kind to seconds }

    @AfterTest
    fun close() = data.close()

    private fun episode(id: String, series: String = "show-1") =
        MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.EPISODE, grandparentId = series, serverId = "server-a")

    @Test
    fun `a do not save offset stays with the episode it was set on`() = runTest {
        settings.set(AppSettings.syncOffsetScope, PlayerSettingScope.OFF)
        offsets.applyFor(episode("ep-1"))
        assertTrue(writes.isEmpty(), "a new player already applies no delay")

        // The viewer nudges the subtitles; the player keeps its delay across the next episode's swap.
        writes += SyncOffsetKind.SUBTITLE to 0.5
        offsets.recordApplied(SyncOffsetKind.SUBTITLE, 500)
        offsets.applyFor(episode("ep-2"))

        assertEquals(SyncOffsetKind.SUBTITLE to 0.0, writes.last())
    }

    @Test
    fun `a per show offset carries to the next episode without a rewrite and clears for another title`() = runTest {
        settings.set(AppSettings.syncOffsetScope, PlayerSettingScope.TITLE)
        ScopedPlayerPrefs.write(settings, ScopedPlayerPrefs.subtitleSyncOffset, episode("ep-1"), -400, at = 1)

        offsets.applyFor(episode("ep-1"))
        assertEquals(listOf(SyncOffsetKind.SUBTITLE to -0.4), writes)

        offsets.applyFor(episode("ep-2"))
        assertEquals(1, writes.size, "the player already applies this show's offset")

        offsets.applyFor(MediaItem(id = "movie-1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, serverId = "server-a"))
        assertEquals(SyncOffsetKind.SUBTITLE to 0.0, writes.last())
    }
}
