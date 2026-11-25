package com.edde746.plezy.settings.export

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.db.Device_setting
import com.edde746.plezy.data.db.Profile_setting
import com.edde746.plezy.data.testData
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant

class SettingsBackupTest {
    private val data = testData(TestClock())
    private val backup = data.settingsBackup
    private val trackers = listOf("mal", "anilist", "simkl", "trakt", "mdblist")

    @AfterTest
    fun close() = data.close()

    // ---- Storage helpers: rows as Plezy stores them (value_json) ---------------------------------------------------

    private suspend fun seed(vararg rows: Pair<String, String>) =
        data.db.write { rows.forEach { (k, v) -> q.deviceSettingQueries.upsert(Device_setting(k, v)) } }

    private suspend fun seedProfile(scope: String, vararg rows: Pair<String, String>) =
        data.db.write { rows.forEach { (k, v) -> q.deviceSettingQueries.upsertProfileSetting(Profile_setting(scope, k, v)) } }

    private suspend fun stored(key: String): String? = data.db.read { deviceSettingQueries.selectByKey(key).executeAsOneOrNull() }

    private suspend fun storedProfile(scope: String, key: String): String? =
        data.db.read { deviceSettingQueries.selectProfileSetting(scope, key).executeAsOneOrNull() }

    private suspend fun allDevice(): Map<String, String> =
        data.db.read { deviceSettingQueries.selectAll().executeAsList().associate { it.setting_key to it.value_json } }

    private suspend fun clear() = data.db.write {
        q.deviceSettingQueries.selectAll().executeAsList().forEach { q.deviceSettingQueries.delete(it.setting_key) }
        q.deviceSettingQueries.deleteAllProfileSettings()
    }

    private fun str(s: String) = JsonPrimitive(s).toString()

    // ---- File helpers ------------------------------------------------------------------------------------------------

    private suspend fun exportFile(scope: String? = "alice"): JsonObject = Json.parseToJsonElement(
        backup.export(scope, appVersion = "1.2.3", platform = "linux", now = Instant.fromEpochMilliseconds(0)).decodeToString(),
    ).jsonObject

    private suspend fun exported(scope: String? = "alice"): JsonObject = exportFile(scope)["prefs"]!!.jsonObject

    private fun entry(type: String, value: JsonElement) = buildJsonObject {
        put("type", type)
        put("value", value)
    }

    private fun entry(type: String, value: String) = entry(type, JsonPrimitive(value))
    private fun entry(type: String, value: Number) = entry(type, JsonPrimitive(value))
    private fun entry(type: String, value: Boolean) = entry(type, JsonPrimitive(value))
    private fun stringList(vararg values: String) = buildJsonArray { values.forEach { add(JsonPrimitive(it)) } }

    private fun file(prefs: Map<String, JsonElement>, version: JsonElement = JsonPrimitive(1)) = buildJsonObject {
        put("formatVersion", version)
        put("prefs", JsonObject(prefs))
    }

    private suspend fun import(file: JsonElement, scope: String = "alice", beforeWrite: (String) -> Unit = {}) =
        backup.import(file.toString().encodeToByteArray(), scope, beforeWrite)

    private suspend fun import(vararg prefs: Pair<String, JsonElement>, scope: String = "alice") = import(file(mapOf(*prefs)), scope)

    // ---- Export ------------------------------------------------------------------------------------------------------

    @Test
    fun exportWritesTheFileHeaderIndentedTwoSpaces() = runTest {
        seed("enable_hdr" to "true")
        val text = backup.export("alice", "1.2.3", "android", Instant.fromEpochMilliseconds(0)).decodeToString()
        val file = Json.parseToJsonElement(text).jsonObject

        assertEquals(JsonPrimitive(1), file["formatVersion"])
        assertEquals("1.2.3", file["appVersion"]!!.jsonPrimitive.content)
        assertEquals("1970-01-01T00:00:00Z", file["exportedAt"]!!.jsonPrimitive.content)
        assertEquals("android", file["platform"]!!.jsonPrimitive.content)
        assertTrue(text.startsWith("{\n  \"formatVersion\": 1,"), text)
    }

    @Test
    fun exportsScalarAndJsonValuesAndStripsOnlyTheActiveProfilesLibraryScope() = runTest {
        seed(
            "enable_hardware_decoding" to "true",
            "seek_time_small" to "42",
            "volume" to "75.5",
            "subtitle_text_color" to str("#FF00FF"),
        )
        seedProfile("alice", "hidden_libraries" to """["server-a:hidden"]""", "library_order" to """["movies","shows"]""")
        seedProfile("bob", "hidden_libraries" to """["private-hidden"]""", "library_order" to """["private-order"]""")

        val file = exportFile()
        val prefs = file["prefs"]!!.jsonObject

        assertEquals(entry("bool", true), prefs["enable_hardware_decoding"])
        assertEquals(entry("int", 42), prefs["seek_time_small"])
        assertEquals(entry("double", 75.5), prefs["volume"])
        assertEquals(entry("string", "#FF00FF"), prefs["subtitle_text_color"])
        assertEquals(entry("string", """["server-a:hidden"]"""), prefs["hidden_libraries"])
        assertEquals(entry("string", """["movies","shows"]"""), prefs["library_order"])
        assertFalse(file.toString().contains("private-hidden"))
        assertFalse(file.toString().contains("private-order"))
    }

    @Test
    fun exportLeavesOutDeviceDownloadRootsButKeepsDownloadControls() = runTest {
        seed(
            "custom_download_path" to str("/source-device/downloads"),
            "custom_download_path_type" to str("saf"),
            "download_on_wifi_only" to "false",
        )

        val file = exportFile()
        val prefs = file["prefs"]!!.jsonObject

        assertEquals(entry("bool", false), prefs["download_on_wifi_only"])
        assertFalse("custom_download_path" in prefs)
        assertFalse("custom_download_path_type" in prefs)
        assertFalse(file.toString().contains("/source-device/downloads"))
    }

    @Test
    fun aCustomShaderSelectionTravelsAsNoShader() = runTest {
        seed(
            "custom_shader_presets" to """[{"id":"custom_local-only.glsl","name":"Local only","type":"custom","fileName":"local-only.glsl"}]""",
            "global_shader_preset" to str("custom_local-only.glsl"),
        )

        val file = exportFile()
        val prefs = file["prefs"]!!.jsonObject
        assertEquals(entry("string", "none"), prefs["global_shader_preset"])
        assertFalse("custom_shader_presets" in prefs)
        assertFalse(file.toString().contains("local-only.glsl"))

        clear()
        assertEquals(ImportResult(keysImported = 1, keysSkipped = 0), import(file, scope = "bob"))
        assertEquals(str("none"), stored("global_shader_preset"))
        assertNull(stored("custom_shader_presets"))
    }

    @Test
    fun exportFailsClosedForCredentialAccountPathHistoryAndRuntimeKeys() = runTest {
        val canaries = listOf("SEERR-BEARER-CANARY", "ACCOUNT-ID-CANARY", "DEVICE-PATH-CANARY", "RUNTIME-TIME-CANARY")
        seed(
            "enable_trakt_scrobble" to "true",
            "current_user_uuid" to str(canaries[1]),
            "custom_download_path" to str(canaries[2]),
            "custom_download_path_type" to str("saf"),
            "crash_reporting" to "true",
            "custom_relay_url" to str("https://${canaries[2]}.invalid"),
            "update_last_check_time" to str(canaries[3]),
            "watch_together_recent_rooms" to str(canaries[1]),
            "future_runtime_key" to str("unknown"),
        )
        seedProfile(
            "alice",
            "seerr_session" to """{"cookie":"${canaries[0]}","account":"${canaries[1]}"}""",
            "watch_together_recent_rooms" to str(canaries[1]),
        )

        val file = exportFile()

        assertEquals(setOf("enable_trakt_scrobble"), file["prefs"]!!.jsonObject.keys)
        canaries.forEach { assertFalse(file.toString().contains(it), it) }
    }

    @Test
    fun exportWithoutAProfileHasNoLibrarySettings() = runTest {
        seedProfile("alice", "library_order" to """["movies"]""")
        seed("enable_hdr" to "true")

        assertEquals(setOf("enable_hdr"), exported(scope = null).keys)
    }

    @Test
    fun exportNeverCarriesTvosDatabaseRecoveryKeys() = runTest {
        val canary = "PROTECTED-RECOVERY-PAYLOAD-CANARY"
        seed(
            "tvos_db_recovery_manifest_v1" to """{"state":"committed"}""",
            "tvos_db_recovery_identity_v1" to str(canary),
            "tvos_db_recovery_pending_v1" to str(canary),
            "enable_hdr" to "true",
        )

        val file = exportFile()

        assertEquals(setOf("enable_hdr"), file["prefs"]!!.jsonObject.keys)
        assertFalse(file.toString().contains(canary))
    }

    @Test
    fun exportsStringListsAndLeavesOutListsWithOtherElements() = runTest {
        seed(
            "tracker_library_filter_mode_trakt" to str("blacklist"),
            "tracker_library_filter_ids_trakt" to """["srv-1:lib-a","srv-1:lib-b"]""",
            "tracker_library_filter_ids_simkl" to """["ok",7]""",
        )

        val prefs = exported()

        assertEquals(entry("stringList", stringList("srv-1:lib-a", "srv-1:lib-b")), prefs["tracker_library_filter_ids_trakt"])
        assertFalse("tracker_library_filter_ids_simkl" in prefs)
    }

    // ---- Earlier releases' on/off choices ------------------------------------------------------------------------------

    @Test
    fun aStereoDownmixBackupRestoresAsTheStereoChannelLimit() = runTest {
        assertEquals(ImportResult(1, 0), import("audio_downmix" to entry("bool", true)))
        assertEquals(str("stereo"), stored("audio_channel_limit"))
    }

    @Test
    fun anUnmigratedStereoDownmixExportsAsTheStereoChannelLimit() = runTest {
        seed("audio_downmix" to "true")

        assertEquals(buildJsonObject { put("audio_channel_limit", entry("string", "stereo")) }, exported(scope = null))
        assertEquals("true", stored("audio_downmix"))
    }

    @Test
    fun unmigratedSkipChoicesExportAsTheirModesWithoutChangingStorage() = runTest {
        for (introAuto in listOf(true, false)) {
            clear()
            seed("auto_skip_intro" to "$introAuto", "auto_skip_credits" to "${!introAuto}")

            assertEquals(skipModes(introAuto), exported(scope = null))
            assertEquals("$introAuto", stored("auto_skip_intro"))
            assertEquals("${!introAuto}", stored("auto_skip_credits"))
        }
    }

    private fun skipModes(introAuto: Boolean) = buildJsonObject {
        put("skip_intro_mode", entry("string", if (introAuto) "auto" else "button"))
        put("skip_credits_mode", entry("string", if (introAuto) "button" else "auto"))
    }

    @Test
    fun anOldSkipBackupReplacesEitherFormOfTheTargetsChoice() = runTest {
        for (introAuto in listOf(true, false)) {
            for (target in listOf("empty", "legacy", "canonical")) {
                clear()
                seed("seek_time_small" to "45")
                when (target) {
                    "legacy" -> seed("auto_skip_intro" to "${!introAuto}", "auto_skip_credits" to "$introAuto")
                    "canonical" -> seed(
                        "skip_intro_mode" to str(if (introAuto) "off" else "auto"),
                        "skip_credits_mode" to str(if (introAuto) "auto" else "off"),
                    )
                }

                val result = import("auto_skip_intro" to entry("bool", introAuto), "auto_skip_credits" to entry("bool", !introAuto))

                assertEquals(ImportResult(2, 0), result, target)
                assertNull(stored("auto_skip_intro"))
                assertNull(stored("auto_skip_credits"))
                val expected = JsonObject(skipModes(introAuto) + ("seek_time_small" to entry("int", 45)))
                assertEquals(expected, exported(scope = null), target)
            }
        }
    }

    @Test
    fun aCanonicalImportReplacesAnUnmigratedChoice() = runTest {
        seed("auto_skip_intro" to "true", "auto_skip_credits" to "false")
        val canonical = buildJsonObject {
            put("skip_intro_mode", entry("string", "off"))
            put("skip_credits_mode", entry("string", "auto"))
        }

        import(file(canonical))

        assertNull(stored("auto_skip_intro"))
        assertNull(stored("auto_skip_credits"))
        assertEquals(canonical, exported(scope = null))
    }

    @Test
    fun theCanonicalEntryWinsWhateverTheOrder() = runTest {
        val canonical = mapOf("skip_intro_mode" to entry("string", "off"), "skip_credits_mode" to entry("string", "auto"))
        val legacy = mapOf("auto_skip_intro" to entry("bool", true), "auto_skip_credits" to entry("bool", false))
        for (prefs in listOf(canonical + legacy, legacy + canonical)) {
            clear()
            import(file(prefs))
            assertEquals(JsonObject(canonical), exported(scope = null))
        }
    }

    @Test
    fun exportPrefersAStoredModeOverAnUnmigratedChoice() = runTest {
        seed(
            "auto_skip_intro" to "true",
            "skip_intro_mode" to str("off"),
            "auto_skip_credits" to "false",
            "skip_credits_mode" to str("auto"),
        )

        assertEquals(
            buildJsonObject {
                put("skip_intro_mode", entry("string", "off"))
                put("skip_credits_mode", entry("string", "auto"))
            },
            exported(scope = null),
        )
    }

    @Test
    fun settingsTheFileLeavesOutStayAsTheyAre() = runTest {
        seed("auto_skip_intro" to "true", "auto_skip_credits" to "true", "seek_time_small" to "45")

        import("auto_skip_intro" to entry("bool", false))

        assertEquals(str("button"), stored("skip_intro_mode"))
        assertNull(stored("auto_skip_intro"))
        assertEquals("true", stored("auto_skip_credits"))
        assertNull(stored("skip_credits_mode"))
        assertEquals("45", stored("seek_time_small"))
    }

    @Test
    fun invalidOldEntriesNeitherMigrateNorRemoveTheTargetsChoice() = runTest {
        seed("auto_skip_intro" to "false", "skip_credits_mode" to str("off"))

        val result = import("auto_skip_intro" to entry("bool", "true"), "auto_skip_credits" to entry("string", true))

        assertEquals(ImportResult(0, 2), result)
        assertEquals("false", stored("auto_skip_intro"))
        assertNull(stored("skip_intro_mode"))
        assertEquals(str("off"), stored("skip_credits_mode"))
    }

    @Test
    fun anInvalidCanonicalEntryDoesNotFallBackToTheOldEntry() = runTest {
        seed("skip_intro_mode" to str("off"))

        import("auto_skip_intro" to entry("bool", true), "skip_intro_mode" to entry("bool", false))

        assertEquals(str("off"), stored("skip_intro_mode"))
    }

    @Test
    fun aFailedWriteRollsBackBothForms() = runTest {
        for (failAt in listOf("auto_skip_intro", "skip_credits_mode")) {
            clear()
            seed("auto_skip_intro" to "true", "auto_skip_credits" to "false", "seek_time_small" to "45")
            if (failAt == "auto_skip_intro") seed("skip_intro_mode" to str("button"))
            val before = allDevice()
            val exportedBefore = exported(scope = null)
            val prefs = mapOf("skip_intro_mode" to entry("string", "off"), "auto_skip_credits" to entry("bool", true))

            assertFailsWith<IllegalStateException> {
                import(file(prefs)) { key -> check(key != failAt) { "synthetic write failure" } }
            }

            assertEquals(before, allDevice(), failAt)
            assertEquals(exportedBefore, exported(scope = null), failAt)
        }
    }

    // ---- Import ------------------------------------------------------------------------------------------------------

    @Test
    fun importChecksTheVersionAndShapeBeforeWriting() = runTest {
        assertFailsWith<InvalidExportFileException> { import(buildJsonObject { put("prefs", JsonObject(emptyMap())) }) }
        assertFailsWith<InvalidExportFileException> { import(file(emptyMap(), version = JsonPrimitive(2))) }
        assertFailsWith<InvalidExportFileException> { import(file(emptyMap(), version = JsonPrimitive(1.0))) }
        assertFailsWith<InvalidExportFileException> {
            import(buildJsonObject {
                put("formatVersion", 1)
                put("prefs", "invalid")
            })
        }
        assertEquals(emptyMap<String, String>(), allDevice())
    }

    @Test
    fun importRejectsBytesThatAreNotASettingsFile() = runTest {
        assertFailsWith<InvalidExportFileException> { backup.import(byteArrayOf(0xC3.toByte(), 0x28), "alice") }
        assertFailsWith<InvalidExportFileException> { backup.import("{bad".encodeToByteArray(), "alice") }
        assertFailsWith<InvalidExportFileException> { backup.import("[1]".encodeToByteArray(), "alice") }
    }

    @Test
    fun importWithoutAnActiveProfileFailsBeforeReadingTheFile() = runTest {
        assertFailsWith<NoActiveProfileException> { backup.import("{bad".encodeToByteArray(), null) }
        assertFailsWith<NoActiveProfileException> { backup.import(file(emptyMap()).toString().encodeToByteArray(), "") }
    }

    @Test
    fun trackerFilterModesAndIdsRoundTripForEveryService() = runTest {
        for (mode in listOf("blacklist", "whitelist")) {
            clear()
            for (s in trackers) {
                seed("tracker_library_filter_mode_$s" to str(mode), "tracker_library_filter_ids_$s" to """["$s:library-a","$s:library-b"]""")
            }
            val file = exportFile(scope = "source-user")
            val prefs = file["prefs"]!!.jsonObject
            for (s in trackers) {
                assertEquals(entry("string", mode), prefs["tracker_library_filter_mode_$s"])
                assertEquals(entry("stringList", stringList("$s:library-a", "$s:library-b")), prefs["tracker_library_filter_ids_$s"])
            }

            clear()
            assertEquals(ImportResult(trackers.size * 2, 0), import(file, scope = "target-user"))
            for (s in trackers) {
                assertEquals(str(mode), stored("tracker_library_filter_mode_$s"))
                assertEquals("""["$s:library-a","$s:library-b"]""", stored("tracker_library_filter_ids_$s"))
            }
        }
    }

    @Test
    fun anEmptyWhitelistSurvivesTheRoundTrip() = runTest {
        for (s in trackers) seed("tracker_library_filter_mode_$s" to str("whitelist"), "tracker_library_filter_ids_$s" to "[]")
        val file = exportFile(scope = "source-user")
        clear()

        assertEquals(ImportResult(trackers.size * 2, 0), import(file, scope = "target-user"))
        for (s in trackers) {
            assertEquals(str("whitelist"), stored("tracker_library_filter_mode_$s"))
            assertEquals("[]", stored("tracker_library_filter_ids_$s"))
        }
    }

    @Test
    fun trackerKeysOfUnknownServicesAreNeitherExportedNorImported() = runTest {
        seed("tracker_library_filter_mode_future" to str("local-mode"), "tracker_library_filter_ids_future" to """["local-id"]""")

        val prefs = exported()
        assertFalse("tracker_library_filter_mode_future" in prefs)
        assertFalse("tracker_library_filter_ids_future" in prefs)

        val result = import(
            "tracker_library_filter_mode_future" to entry("string", "whitelist"),
            "tracker_library_filter_ids_future" to entry("stringList", stringList("crafted-id")),
        )
        assertEquals(ImportResult(0, 2), result)
        assertEquals(str("local-mode"), stored("tracker_library_filter_mode_future"))
        assertEquals("""["local-id"]""", stored("tracker_library_filter_ids_future"))
    }

    @Test
    fun formatOneStringListsOfHiddenAndOrderedLibrariesImportAsLists() = runTest {
        val result = import(
            "hidden_libraries" to entry("stringList", stringList("server-a:hidden")),
            "library_order" to entry("stringList", stringList("server-b:movies", "server-a:shows")),
            scope = "target-user",
        )

        assertEquals(ImportResult(2, 0), result)
        assertEquals("""["server-a:hidden"]""", storedProfile("target-user", "hidden_libraries"))
        assertEquals("""["server-b:movies","server-a:shows"]""", storedProfile("target-user", "library_order"))
    }

    @Test
    fun importWritesAcceptedValuesRescopesLibrarySettingsAndSkipsUnsafeEntries() = runTest {
        seed(
            "update_last_check_time" to str("local-valid-value"),
            "custom_download_path" to str("/target/device/downloads"),
            "custom_download_path_type" to str("file"),
            "crash_reporting" to "false",
        )

        val result = import(
            "enable_hardware_decoding" to entry("bool", true),
            "default_playback_speed" to entry("double", 1),
            "library_order" to entry("string", """["movies"]"""),
            "library_sort_movies" to entry("string", """{"key":"titleSort"}"""),
            "seerr_session" to entry("string", "SEERR-IMPORT-CANARY"),
            "update_last_check_time" to entry("string", "crafted-invalid"),
            "custom_download_path" to entry("string", "/source/device/downloads"),
            "custom_download_path_type" to entry("string", "saf"),
            "crash_reporting" to entry("bool", true),
            "custom_relay_url" to entry("string", "https://relay.example.test"),
            "watch_together_recent_rooms" to entry("string", "[]"),
            "unknown_future_key" to entry("bool", true),
        )

        assertEquals(ImportResult(4, 8), result)
        assertEquals("true", stored("enable_hardware_decoding"))
        assertEquals("1.0", stored("default_playback_speed"))
        assertEquals("""["movies"]""", storedProfile("alice", "library_order"))
        assertEquals("""{"key":"titleSort"}""", storedProfile("alice", "library_sort_movies"))
        assertNull(stored("seerr_session"))
        assertNull(storedProfile("alice", "seerr_session"))
        assertEquals(str("local-valid-value"), stored("update_last_check_time"))
        assertEquals(str("/target/device/downloads"), stored("custom_download_path"))
        assertEquals(str("file"), stored("custom_download_path_type"))
        assertEquals("false", stored("crash_reporting"))
        assertNull(stored("custom_relay_url"))
        assertNull(storedProfile("alice", "watch_together_recent_rooms"))
        assertNull(stored("unknown_future_key"))
    }

    @Test
    fun libraryTextSettingsStayTextEvenWhenTheyLookLikeJson() = runTest {
        import(
            "library_tab_srv:1" to entry("string", "5"),
            "library_grouping_srv:1" to entry("string", "shows"),
            "library_sort_srv:1" to entry("string", "titleSort"),
        )

        assertEquals(str("5"), storedProfile("alice", "library_tab_srv:1"))
        assertEquals(str("shows"), storedProfile("alice", "library_grouping_srv:1"))
        assertEquals(str("titleSort"), storedProfile("alice", "library_sort_srv:1"))
    }

    @Test
    fun `library values the app cannot read are skipped and keep what was saved`() = runTest {
        seedProfile("alice", "library_order" to """["movies","shows"]""", "hidden_libraries" to """["server-a:hidden"]""")

        val result = import(
            "library_order" to entry("string", "{}"),
            "hidden_libraries" to entry("string", "not json"),
            "library_sort_srv:1" to entry("string", "[1]"),
            "library_tab_srv:1" to entry("string", "5"),
        )

        assertEquals(ImportResult(1, 3), result)
        assertEquals("""["movies","shows"]""", storedProfile("alice", "library_order"))
        assertEquals("""["server-a:hidden"]""", storedProfile("alice", "hidden_libraries"))
        assertNull(storedProfile("alice", "library_sort_srv:1"))
    }

    @Test
    fun anUnknownCustomShaderSelectionIsSkipped() = runTest {
        seed("global_shader_preset" to str("nvscaler"))

        assertEquals(ImportResult(0, 1), import("global_shader_preset" to entry("string", "custom_missing.glsl")))
        assertEquals(str("nvscaler"), stored("global_shader_preset"))
    }

    @Test
    fun shortcutsAreImportedOnlyWhenWellFormedAndFreeOfConflicts() = runTest {
        val good = """{"play_pause":{"key":"00070014","modifiers":["shift"]},"mute_toggle":{"disabled":true}}"""
        assertEquals(ImportResult(1, 0), import("keyboard_hotkeys" to entry("string", good)))
        assertEquals(Json.parseToJsonElement(good), Json.parseToJsonElement(stored("keyboard_hotkeys")!!))

        val conflicting = """{"play_pause":{"key":"00070052","modifiers":[]}}"""
        assertEquals(ImportResult(0, 1), import("keyboard_hotkeys" to entry("string", conflicting)))
        val badKey = """{"play_pause":{"key":"00000000","modifiers":[]}}"""
        assertEquals(ImportResult(0, 1), import("keyboard_hotkeys" to entry("string", badKey)))
        assertEquals(Json.parseToJsonElement(good), Json.parseToJsonElement(stored("keyboard_hotkeys")!!))
    }

    @Test
    fun malformedOrMismatchedEntriesAreSkipped() = runTest {
        val result = import(
            "enable_hdr" to entry("bool", "yes"),
            "seek_time_small" to entry("string", "10"),
            "volume" to buildJsonObject { put("value", 50) },
            "preferred_video_codec" to JsonPrimitive("not-an-entry"),
            "enable_hardware_decoding" to entry("bool", true),
        )

        assertEquals(ImportResult(1, 4), result)
        assertEquals("true", stored("enable_hardware_decoding"))
        assertNull(stored("enable_hdr"))
        assertNull(stored("seek_time_small"))
    }

    @Test
    fun valuesTheSettingsScreensRejectAreSkipped() = runTest {
        val result = import(
            "view_mode" to entry("string", "carousel"),
            "seek_time_small" to entry("int", 5000),
            "subtitle_text_color" to entry("string", "red"),
            "keyboard_hotkeys" to entry("string", "not json"),
            "seek_time_large" to entry("int", 45),
            "subtitle_border_color" to entry("string", "#102030"),
        )

        assertEquals(ImportResult(2, 4), result)
        assertNull(stored("view_mode"))
        assertNull(stored("seek_time_small"))
        assertNull(stored("subtitle_text_color"))
        assertNull(stored("keyboard_hotkeys"))
        assertEquals("45", stored("seek_time_large"))
        assertEquals(str("#102030"), stored("subtitle_border_color"))
    }

    @Test
    fun aJsonSettingImportsAsItsJson() = runTest {
        val hotkeys = """{"play_pause":{"disabled":true}}"""
        assertEquals(ImportResult(1, 0), import("keyboard_hotkeys" to entry("string", hotkeys)))
        assertEquals(hotkeys, stored("keyboard_hotkeys"))
        assertEquals(entry("string", hotkeys), exported()["keyboard_hotkeys"])
    }

    @Test
    fun aLaterFailedWriteRollsBackEveryWrite() = runTest {
        seed("enable_hdr" to "false")
        var writes = 0
        val prefs = mapOf("enable_hdr" to entry("bool", true), "seek_time_small" to entry("int", 15))

        assertFailsWith<IllegalStateException> {
            import(file(prefs)) { check(++writes != 2) { "synthetic write failure" } }
        }

        assertEquals("false", stored("enable_hdr"))
        assertNull(stored("seek_time_small"))
    }

    @Test
    fun valuesMoveBetweenProfilesWithoutTheirScope() = runTest {
        seed("enable_hardware_decoding" to "true")
        seedProfile("alice", "hidden_libraries" to """["server-a:hidden"]""", "library_order" to """["server-b:movies"]""")

        val file = exportFile(scope = "alice")
        assertFalse(file.toString().contains("alice"))
        clear()

        assertEquals(ImportResult(3, 0), import(file, scope = "bob"))
        assertEquals("true", stored("enable_hardware_decoding"))
        assertEquals("""["server-a:hidden"]""", storedProfile("bob", "hidden_libraries"))
        assertEquals("""["server-b:movies"]""", storedProfile("bob", "library_order"))
        assertNull(storedProfile("alice", "hidden_libraries"))
    }

    @Test
    fun importCannotReplaceTvosDatabaseRecoveryKeys() = runTest {
        seed(
            "tvos_db_recovery_manifest_v1" to str("LOCAL-MANIFEST"),
            "tvos_db_recovery_identity_v1" to str("LOCAL-IDENTITY"),
            "tvos_db_recovery_pending_v1" to str("LOCAL-PENDING"),
        )

        val result = import(
            "tvos_db_recovery_manifest_v1" to entry("string", "MALICIOUS-MANIFEST"),
            "tvos_db_recovery_identity_v1" to entry("string", "MALICIOUS-IDENTITY"),
            "tvos_db_recovery_pending_v1" to entry("string", "MALICIOUS-PENDING"),
        )

        assertEquals(ImportResult(0, 3), result)
        assertEquals(str("LOCAL-MANIFEST"), stored("tvos_db_recovery_manifest_v1"))
        assertEquals(str("LOCAL-IDENTITY"), stored("tvos_db_recovery_identity_v1"))
        assertEquals(str("LOCAL-PENDING"), stored("tvos_db_recovery_pending_v1"))
    }

    @Test
    fun aFileFromThisBuildImportsWhatItExported() = runTest {
        seed("enable_hdr" to "true")
        val bytes = backup.export("alice", "1.2.3", "linux", Instant.fromEpochMilliseconds(0))
        seed("enable_hdr" to "false")

        assertEquals(ImportResult(1, 0), backup.import(bytes, "alice"))
        assertEquals("true", stored("enable_hdr"))
    }

    @Test
    fun theDefaultFileNameCarriesTheDate() {
        assertEquals("plezy-settings-20261106.json", SettingsBackup.defaultFileName(2026, 11, 6))
    }

    // ---- Reset All Settings --------------------------------------------------------------------------------------------

    @Test
    fun resetKeepsAnUnmigratedSkipChoiceAsItsMode() = runTest {
        for (introAuto in listOf(true, false)) {
            clear()
            seed("auto_skip_intro" to "$introAuto", "auto_skip_credits" to "${!introAuto}", "seek_time_small" to "45")

            backup.resetAll()

            assertEquals(str(if (introAuto) "auto" else "button"), stored("skip_intro_mode"))
            assertEquals(str(if (introAuto) "button" else "auto"), stored("skip_credits_mode"))
            assertNull(stored("auto_skip_intro"))
            assertNull(stored("auto_skip_credits"))
            assertNull(stored("seek_time_small"))
        }
    }

    @Test
    fun resetKeepsAStoredModeWithoutWritingAnAbsentOne() = runTest {
        seed("skip_intro_mode" to str("off"), "auto_skip_intro" to "true")

        backup.resetAll()

        assertEquals(str("off"), stored("skip_intro_mode"))
        assertNull(stored("auto_skip_intro"))
        assertNull(stored("skip_credits_mode"))
    }

    @Test
    fun resetClearsAnUnmigratedStereoDownmixInsteadOfRestoringIt() = runTest {
        seed("audio_downmix" to "true")

        backup.resetAll()

        assertNull(stored("audio_downmix"))
        assertNull(stored("audio_channel_limit"))
    }

    @Test
    fun resetRemovesResetSettingsAndOldKeysAndKeepsTheRest() = runTest {
        seed(
            "enable_hdr" to "false",
            "media_version_preferences" to "{}",
            "buffer_size" to "64",
            "demuxer_mode" to str("auto"),
            "buffer_size_migrated_to_auto" to "true",
            "use_season_poster" to "true",
            "mpv_config_entries" to "[]",
            "intro_pattern" to str("intro"),
            "crash_reporting" to "false",
            "active_app_profile_id" to str("p1"),
        )
        seedProfile("alice", "library_order" to """["a"]""")

        val removed = backup.resetAll()

        assertEquals(
            setOf("enable_hdr", "media_version_preferences", "buffer_size", "demuxer_mode", "buffer_size_migrated_to_auto", "use_season_poster", "mpv_config_entries"),
            removed.toSet(),
        )
        assertEquals(
            mapOf("intro_pattern" to str("intro"), "crash_reporting" to "false", "active_app_profile_id" to str("p1")),
            allDevice(),
        )
        assertEquals("""["a"]""", storedProfile("alice", "library_order"))
    }

    @Test
    fun theWatchTogetherRelayIsResetButNeverExportedOrImported() = runTest {
        seed("watch_party_relay_url" to str("https://relay.example.test"), "enable_hdr" to "true")

        assertEquals(setOf("enable_hdr"), exported().keys)
        assertFalse(exportFile().toString().contains("relay.example.test"))

        import("watch_party_relay_url" to entry("string", "https://other.example.test"))
        assertEquals(str("https://relay.example.test"), stored("watch_party_relay_url"), "an import leaves the device's relay")

        assertTrue("watch_party_relay_url" in backup.resetAll())
        assertNull(stored("watch_party_relay_url"))
    }
}
