package com.edde746.plezy.settings

import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.playback.AudioChannels
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class SettingsMigrationsTest {
    private val data = testData()
    private val settings = data.deviceSettings

    @AfterTest
    fun close() = data.close()

    private suspend fun upgrade(vararg stored: Pair<String, String>) {
        for ((key, json) in stored) data.store(key, json)
        data.db.write { SettingsMigrations.applyLegacyMigrations(this) }
    }

    // ---- Legacy toggles replaced by enums ---------------------------------------------------------------------------

    @Test
    fun theAutoSkipTogglesMigrateOnToAutoAndOffToButton() = runTest {
        upgrade("auto_skip_intro" to "true", "auto_skip_credits" to "false")

        assertEquals(SkipMode.AUTO, settings.value(AppSettings.skipIntroMode))
        assertEquals(SkipMode.BUTTON, settings.value(AppSettings.skipCreditsMode))
        assertNull(data.storedJson("auto_skip_intro"), "migrated once, then forgotten")
        assertNull(data.storedJson("auto_skip_credits"))

        settings.set(AppSettings.skipIntroMode, SkipMode.OFF)
        assertEquals(SkipMode.OFF, settings.value(AppSettings.skipIntroMode))
    }

    @Test
    fun storedModesWinOverCoexistingLegacyToggles() = runTest {
        upgrade(
            "auto_skip_intro" to "true",
            "skip_intro_mode" to "\"off\"",
            "auto_skip_credits" to "false",
            "skip_credits_mode" to "\"auto\"",
        )

        assertEquals(SkipMode.OFF, settings.value(AppSettings.skipIntroMode))
        assertEquals(SkipMode.AUTO, settings.value(AppSettings.skipCreditsMode))
        assertNull(data.storedJson("auto_skip_intro"))
        assertNull(data.storedJson("auto_skip_credits"))
    }

    @Test
    fun theDownmixToggleMigratesToTheChannelLimit() = runTest {
        upgrade("audio_downmix" to "true")
        assertEquals(AudioChannels.STEREO, settings.value(AppSettings.audioChannelLimit))
        assertEquals("\"stereo\"", data.storedJson("audio_channel_limit"))
        assertNull(data.storedJson("audio_downmix"), "migrated once, then forgotten")
    }

    @Test
    fun anOffDownmixToggleMigratesToOriginal() = runTest {
        upgrade("audio_downmix" to "false")
        assertEquals(AudioChannels.ORIGINAL, settings.value(AppSettings.audioChannelLimit))
        assertNull(data.storedJson("audio_downmix"))
    }

    @Test
    fun theDeinterlaceToggleMigratesToTheMode() = runTest {
        upgrade("deinterlace" to "true")
        assertEquals(DeinterlaceMode.VIDEO, settings.value(AppSettings.deinterlaceMode))
        assertNull(data.storedJson("deinterlace"), "migrated once, then forgotten")
    }

    @Test
    fun anOffDeinterlaceToggleMigratesToOff() = runTest {
        upgrade("deinterlace" to "false")
        assertEquals("\"off\"", data.storedJson("deinterlace_mode"))
        assertNull(data.storedJson("deinterlace"))
    }

    // ---- Other shapes of earlier releases --------------------------------------------------------------------------

    @Test
    fun libraryDensityStoredAsANameBecomesItsNumber() = runTest {
        upgrade("library_density" to "\"compact\"")
        assertEquals("2", data.storedJson("library_density"))

        upgrade("library_density" to "\"comfortable\"")
        assertEquals(4, settings.value(AppSettings.libraryDensity))

        upgrade("library_density" to "\"cozy\"")
        assertEquals(3, settings.value(AppSettings.libraryDensity))
    }

    @Test
    fun libraryDensityIsClampedToItsRange() = runTest {
        data.store("library_density", "9")
        assertEquals(5, settings.value(AppSettings.libraryDensity))
        settings.set(AppSettings.libraryDensity, 0)
        assertEquals("1", data.storedJson("library_density"))
    }

    @Test
    fun theSeasonPosterToggleBecomesTheEpisodePosterMode() = runTest {
        upgrade("use_season_poster" to "true")
        assertEquals(EpisodePosterMode.SEASON_POSTER, settings.value(AppSettings.episodePosterMode))
        assertNull(data.storedJson("use_season_poster"))
    }

    @Test
    fun anOffSeasonPosterToggleBecomesTheSeriesPoster() = runTest {
        upgrade("use_season_poster" to "false")
        assertEquals("\"seriesPoster\"", data.storedJson("episode_poster_mode"))
    }

    @Test
    fun anEpisodePosterModeStoredWinsOverTheToggle() = runTest {
        upgrade("use_season_poster" to "true", "episode_poster_mode" to "\"episodeThumbnail\"")
        assertEquals(EpisodePosterMode.EPISODE_THUMBNAIL, settings.value(AppSettings.episodePosterMode))
    }

    @Test
    fun mpvConfigEntriesBecomeConfigLinesWithDisabledOnesCommented() = runTest {
        upgrade(
            "mpv_config_entries" to
                """"[{\"key\":\"hwdec\",\"value\":\"auto\",\"isEnabled\":true},{\"key\":\"sub-font\",\"value\":\"Arial\",\"isEnabled\":false},{\"key\":\"\",\"value\":\"x\"}]"""",
        )
        assertEquals("hwdec=auto\n#sub-font=Arial", settings.value(AppSettings.mpvConfigText))
    }

    @Test
    fun storedMpvConfigTextWinsOverItsEntries() = runTest {
        upgrade("mpv_config_text" to "\"volume=50\"", "mpv_config_entries" to """[{"key":"hwdec","value":"auto"}]""")
        assertEquals("volume=50", settings.value(AppSettings.mpvConfigText))
    }

    @Test
    fun mpvPresetsOfEntriesGainTheirText() = runTest {
        upgrade(
            "mpv_config_presets" to
                """[{"name":"Old","entries":[{"key":"deband","value":"yes","isEnabled":true}],"createdAt":"2025-01-02T03:04:05.000"},""" +
                """{"name":"New","text":"hwdec=no","createdAt":"2025-02-02T03:04:05.000"}]""",
        )
        assertEquals(
            listOf(
                MpvPreset("Old", "deband=yes", "2025-01-02T03:04:05.000"),
                MpvPreset("New", "hwdec=no", "2025-02-02T03:04:05.000"),
            ),
            settings.value(AppSettings.mpvConfigPresets),
        )
    }

    // ---- At every start ---------------------------------------------------------------------------------------------

    @Test
    fun aKeyedScopeChosenBeforeTheResetDropsItsStaleGlobalValueOnce() = runTest {
        data.store("playback_speed_scope", "\"library\"")
        data.store("default_playback_speed", "1.5")
        data.store("shader_preset_scope", "\"off\"")
        data.store("global_shader_preset", "\"nvscaler\"")

        SettingsMigrations.applyStartupMigrations(data)

        assertEquals(1.0, settings.value(AppSettings.defaultPlaybackSpeed))
        assertEquals("nvscaler", settings.value(AppSettings.globalShaderPreset), "Don't save applies the global value to every playback")

        // A later fallback write (an item without a library) survives the next start.
        settings.set(AppSettings.defaultPlaybackSpeed, 1.25)
        SettingsMigrations.applyStartupMigrations(data)
        assertEquals(1.25, settings.value(AppSettings.defaultPlaybackSpeed))
    }

    @Test
    fun startCanonicalizesAValidRelayAndRemovesAnInvalidOne() = runTest {
        data.store("watch_party_relay_url", "\"  http://Relay.Example.Test:8080/prefix// \"")
        SettingsMigrations.applyStartupMigrations(data)
        assertEquals("http://relay.example.test:8080/prefix", settings.value(AppSettings.watchPartyRelayUrl))

        data.store("watch_party_relay_url", "\"https://relay.example.test/path?wrong=route\"")
        SettingsMigrations.applyStartupMigrations(data)
        assertNull(data.storedJson("watch_party_relay_url"))
    }

    @Test
    fun startRemovesTheFormerRelayAndRecentRoomsWithoutAdoptingThem() = runTest {
        data.store("custom_relay_url", "\"https://relay.example.test/legacy\"")
        data.store("watch_together_recent_rooms", "\"[]\"")

        SettingsMigrations.applyStartupMigrations(data)

        assertNull(data.storedJson("custom_relay_url"))
        assertNull(data.storedJson("watch_together_recent_rooms"))
        assertNull(settings.value(AppSettings.watchPartyRelayUrl))
    }

    @Test
    fun settingsUnderAPlexHomeProfilesFullIdMoveToItsHomeUsersScope() = runTest {
        val fullId = "plex-home-plex.e443d57860076fc3-379704d0c6601309"
        val uuid = "379704d0c6601309"
        data.storeProfile(fullId, "selected_library_key", "\"lib-1\"")
        data.storeProfile(fullId, "hidden_libraries", """["a","b"]""")

        SettingsMigrations.applyStartupMigrations(data)

        assertEquals("\"lib-1\"", data.storedProfileJson(uuid, "selected_library_key"))
        assertEquals("""["a","b"]""", data.storedProfileJson(uuid, "hidden_libraries"))
        assertNull(data.storedProfileJson(fullId, "selected_library_key"))
    }

    @Test
    fun theFullIdValueWinsOverAStaleUuidScopedValue() = runTest {
        data.storeProfile("379704d0c6601309", "selected_library_key", "\"stale\"")
        data.storeProfile("plex-home-plex.e443d57860076fc3-379704d0c6601309", "selected_library_key", "\"fresh\"")

        SettingsMigrations.applyStartupMigrations(data)

        assertEquals("\"fresh\"", data.storedProfileJson("379704d0c6601309", "selected_library_key"))
    }

    @Test
    fun localProfileScopesAndUnparseablePlexHomeScopesStay() = runTest {
        data.storeProfile("local-1", "selected_library_key", "\"keep\"")
        data.storeProfile("plex-home-acct-not-a-uuid", "key", "\"keep-too\"")

        SettingsMigrations.applyStartupMigrations(data)

        assertEquals("\"keep\"", data.storedProfileJson("local-1", "selected_library_key"))
        assertEquals("\"keep-too\"", data.storedProfileJson("plex-home-acct-not-a-uuid", "key"))
    }
}
