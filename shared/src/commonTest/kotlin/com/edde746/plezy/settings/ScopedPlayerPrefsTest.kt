package com.edde746.plezy.settings

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ScopedPlayerPrefsTest {
    private val clock = TestClock()
    private val data = testData(clock)
    private val settings = data.deviceSettings
    private val speed = ScopedPlayerPrefs.playbackSpeed

    @AfterTest
    fun close() = data.close()

    private fun episode(series: String = "show-1", id: String = "ep-1", library: String? = "lib-1") = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        grandparentId = series,
        libraryId = library,
        serverId = "server-a",
    )

    private fun movie(id: String = "movie-1", library: String? = "lib-1", serverId: String? = "server-a") =
        MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.MOVIE, libraryId = library, serverId = serverId)

    private suspend fun <T> write(pref: ScopedPlayerPref<T>, item: MediaItem?, value: T) =
        ScopedPlayerPrefs.write(settings, pref, item, value, ++clock.now)

    private suspend fun <T> resolve(pref: ScopedPlayerPref<T>, item: MediaItem?): T = ScopedPlayerPrefs.resolve(settings, pref, item)

    private suspend fun storedEntries(): JsonObject = settings.value(AppSettings.scopedPlayerPrefValues)

    @Test
    fun theGlobalScopeWritesTheGlobalSettingAndReadsItBack() = runTest {
        write(speed, movie(), 1.5)

        assertEquals(1.5, settings.value(AppSettings.defaultPlaybackSpeed))
        assertEquals(1.5, resolve(speed, movie(id = "other")))
        assertTrue(storedEntries().isEmpty())
    }

    @Test
    fun zoomStaysTheSessionsUntilAScopeIsChosen() = runTest {
        write(ScopedPlayerPrefs.videoZoom, episode(), 1.3)

        assertEquals(1.0, resolve(ScopedPlayerPrefs.videoZoom, episode(id = "ep-2")))
        assertNull(data.storedJson("default_video_zoom"))
        assertTrue(storedEntries().isEmpty())
    }

    @Test
    fun episodesOfOneShowShareATitleValueAndOtherTitlesFallBackToGlobal() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        write(speed, episode(id = "ep-1"), 1.25)

        assertEquals(1.25, resolve(speed, episode(id = "ep-2")))
        assertEquals(1.0, resolve(speed, episode(series = "show-2")))
        assertEquals(1.0, resolve(speed, movie()))
        assertEquals(1.0, settings.value(AppSettings.defaultPlaybackSpeed), "the global value stays untouched")
    }

    @Test
    fun aMovieKeysByItsOwnId() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        write(speed, movie(id = "movie-1"), 2.0)

        assertEquals(2.0, resolve(speed, movie(id = "movie-1")))
        assertEquals(1.0, resolve(speed, movie(id = "movie-2")))
    }

    @Test
    fun theSameRatingKeyOnAnotherServerIsAnotherTitle() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        write(speed, movie(id = "movie-1"), 2.0)

        assertEquals(1.0, resolve(speed, movie(id = "movie-1", serverId = "server-b")))
    }

    @Test
    fun anItemWithoutAServerWritesTheGlobalSetting() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        write(speed, movie(serverId = null), 1.75)

        assertEquals(1.75, settings.value(AppSettings.defaultPlaybackSpeed))
        assertTrue(storedEntries().isEmpty())
    }

    @Test
    fun itemsOfOneLibraryShareAPresetAndOtherLibrariesFallBackToGlobal() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.shaderPresetScope, PlayerSettingScope.LIBRARY)
        settings.set(AppSettings.globalShaderPreset, "nvscaler")
        write(ScopedPlayerPrefs.shaderPreset, episode(library = "anime"), "anime4k_fast_modeA")

        assertEquals("anime4k_fast_modeA", resolve(ScopedPlayerPrefs.shaderPreset, movie(id = "other", library = "anime")))
        assertEquals("nvscaler", resolve(ScopedPlayerPrefs.shaderPreset, movie(library = "live-action")))
        assertEquals("nvscaler", settings.value(AppSettings.globalShaderPreset))
    }

    @Test
    fun anItemWithoutALibraryWritesTheGlobalSetting() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.shaderPresetScope, PlayerSettingScope.LIBRARY)
        val download = MediaItem(id = "ep-1", backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE, serverId = "server-a")
        write(ScopedPlayerPrefs.shaderPreset, download, "nvscaler")

        assertEquals("nvscaler", settings.value(AppSettings.globalShaderPreset))
        assertTrue(storedEntries().isEmpty())
    }

    @Test
    fun offWritesNothingAndResolvesTheStoredGlobal() = runTest {
        settings.set(AppSettings.defaultPlaybackSpeed, 1.5)
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.OFF)

        write(speed, movie(), 3.0)

        assertEquals(1.5, settings.value(AppSettings.defaultPlaybackSpeed))
        assertTrue(storedEntries().isEmpty())
        assertEquals(1.5, resolve(speed, movie()))
    }

    @Test
    fun entriesOfAnotherScopeAreInertAndComeBackWithIt() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        write(speed, movie(), 2.0)

        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.LIBRARY)
        assertEquals(1.0, resolve(speed, movie()))

        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        assertEquals(2.0, resolve(speed, movie()))
    }

    @Test
    fun aSpeedSavedEverywhereDoesNotFollowIntoLibrariesWithoutTheirOwn() = runTest {
        val tvEpisode = episode(library = "tv-shows")
        val film = movie(library = "movies")
        write(speed, tvEpisode, 1.5)

        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.LIBRARY)
        write(speed, tvEpisode, 1.5)

        assertEquals(1.5, resolve(speed, tvEpisode))
        assertEquals(1.0, resolve(speed, film))
    }

    @Test
    fun dontSaveKeepsTheGlobalValueUntilAKeyedScopeIsEntered() = runTest {
        write(speed, movie(), 1.5)

        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.OFF)
        assertEquals(1.5, resolve(speed, movie()))

        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        assertEquals(1.0, resolve(speed, movie()))
    }

    @Test
    fun bothSyncOffsetsResetWithTheirSharedScope() = runTest {
        write(ScopedPlayerPrefs.audioSyncOffset, episode(), 150)
        write(ScopedPlayerPrefs.subtitleSyncOffset, episode(), -400)

        ScopedPlayerPrefs.setScope(settings, AppSettings.syncOffsetScope, PlayerSettingScope.LIBRARY)

        assertEquals(0, resolve(ScopedPlayerPrefs.audioSyncOffset, episode()))
        assertEquals(0, resolve(ScopedPlayerPrefs.subtitleSyncOffset, episode()))
    }

    @Test
    fun audioAndSubtitleOffsetsShareAScopeButStoreApart() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.syncOffsetScope, PlayerSettingScope.TITLE)
        write(ScopedPlayerPrefs.audioSyncOffset, episode(), 150)
        write(ScopedPlayerPrefs.subtitleSyncOffset, episode(), -400)

        assertEquals(150, resolve(ScopedPlayerPrefs.audioSyncOffset, episode(id = "ep-2")))
        assertEquals(-400, resolve(ScopedPlayerPrefs.subtitleSyncOffset, episode(id = "ep-2")))
        assertEquals(0, settings.value(AppSettings.audioSyncOffset))
        assertEquals(0, settings.value(AppSettings.subtitleSyncOffset))
    }

    @Test
    fun aCorruptEntryFallsBackToTheGlobalSetting() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        settings.set(
            AppSettings.scopedPlayerPrefValues,
            buildJsonObject {
                putJsonObject("playback_speed") {
                    putJsonObject("title:server-a:movie-1") {
                        put("v", "not-a-number")
                        put("t", 1)
                    }
                }
            },
        )

        assertEquals(1.0, resolve(speed, movie(id = "movie-1")))
    }

    @Test
    fun aStoredSpeedOutsideItsRangeIsClamped() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        settings.set(
            AppSettings.scopedPlayerPrefValues,
            buildJsonObject { putJsonObject("playback_speed") { putJsonObject("title:server-a:movie-1") { put("v", 20) } } },
        )

        assertEquals(8.0, resolve(speed, movie(id = "movie-1")))
    }

    @Test
    fun anEntryIsStoredAsItsValueAndWriteTimeUnderItsOptionAndScopeKey() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        write(speed, movie(), 1.25)

        assertEquals("""{"playback_speed":{"title:server-a:movie-1":{"v":1.25,"t":${clock.now}}}}""", data.storedJson("scoped_player_pref_values"))
        assertEquals(1.25, resolve(speed, movie()))
    }

    @Test
    fun theOldestEntriesGoPastThePerOptionCap() = runTest {
        ScopedPlayerPrefs.setScope(settings, AppSettings.playbackSpeedScope, PlayerSettingScope.TITLE)
        val seeded = JsonObject(
            (0 until ScopedPlayerPrefs.MAX_ENTRIES_PER_PROPERTY).associate { i ->
                "title:server-a:movie-$i" to JsonObject(mapOf("v" to JsonPrimitive(2.0), "t" to JsonPrimitive(i)))
            },
        )
        settings.set(AppSettings.scopedPlayerPrefValues, JsonObject(mapOf("playback_speed" to seeded)))

        write(speed, movie(id = "movie-new"), 3.0)

        val entries = storedEntries()["playback_speed"] as JsonObject
        assertEquals(ScopedPlayerPrefs.MAX_ENTRIES_PER_PROPERTY, entries.size)
        assertTrue("title:server-a:movie-new" in entries)
        assertFalse("title:server-a:movie-0" in entries, "the oldest seeded entry (t 0) went")
        assertEquals(3.0, resolve(speed, movie(id = "movie-new")))
    }
}
