package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.AccountPreferenceKey
import com.edde746.plezy.model.AccountPreferencesCapabilities
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.SubtitlePlaybackMode
import com.edde746.plezy.model.WatchedIndicatorScope
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject

class JellyfinAccountPreferencesTest {
    /** Serves the current user and the DisplayPreferences row, applying POSTs to the served state. */
    private class Account(configuration: String = "{}", customPrefs: String = "{}") {
        var configuration: JsonObject = Json.parseToJsonElement(configuration).jsonObject
        var customPrefs: JsonObject = Json.parseToJsonElement(customPrefs).jsonObject
        val posts = mutableListOf<RecordedRequest>()
        val server = JellyfinTestServer { req ->
            val display = req.path.startsWith("/DisplayPreferences/")
            if (req.method == "POST") {
                posts += req
                val body = Json.parseToJsonElement(req.body).jsonObject
                if (display) this.customPrefs = body["CustomPrefs"]!!.jsonObject else this.configuration = body
                FakeResponse(204, "")
            } else if (display) {
                FakeResponse(body = """{"CustomPrefs":${this.customPrefs}}""")
            } else {
                FakeResponse(body = """{"Configuration":${this.configuration}}""")
            }
        }
        val core = server.core()
        fun prefs(dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN) = JellyfinAccountPreferences(server.core(dialect))
    }

    private suspend fun postedFor(patch: AccountPreferencesPatch, configuration: String = "{}", dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN): JsonObject {
        val account = Account(configuration)
        account.prefs(dialect).updateAccountPreferences(patch)
        return Json.parseToJsonElement(account.posts.single().body).jsonObject
    }

    @Test
    fun readMapsAllTenFieldsAndTreatsEmptyLanguageAsAbsent() = runTest {
        val account = Account(
            """{"AudioLanguagePreference":"jpn","PlayDefaultAudioTrack":false,"SubtitleLanguagePreference":"","SubtitleMode":"Smart",
               "RememberAudioSelections":1,"RememberSubtitleSelections":"false","EnableNextEpisodeAutoPlay":"1","DisplayMissingEpisodes":0,
               "HidePlayedInLatest":true,"DisplayCollectionsView":"0"}""",
            """{"enableRewatchingInNextUp":"true"}""",
        )
        val source = JellyfinAccountPreferences(account.core)
        val prefs = source.fetchAccountPreferences()
        assertSame(AccountPreferencesCapabilities.JELLYFIN, source.capabilities)
        assertEquals("jpn", prefs.preferredAudioLanguage)
        assertEquals(true, prefs.selectAudioByLanguage)
        assertNull(prefs.preferredSubtitleLanguage)
        assertEquals(SubtitlePlaybackMode.SMART, prefs.subtitlePlaybackMode)
        assertEquals(true, prefs.rememberAudioSelections)
        assertEquals(false, prefs.rememberSubtitleSelections)
        assertEquals(true, prefs.autoPlayNextEpisode)
        assertEquals(false, prefs.displayMissingEpisodes)
        assertEquals(true, prefs.hidePlayedInLatest)
        assertEquals(false, prefs.displayCollectionsView)
        assertEquals(true, prefs.rewatchingInNextUp)
        assertTrue(account.core.rewatchingInNextUp)
        val display = account.server.single("/DisplayPreferences/usersettings")
        assertEquals(mapOf("userId" to "user-1", "client" to "Plezy"), display.query)
    }

    @Test
    fun readLeavesOmittedFieldsUnset() = runTest {
        val prefs = Account().prefs().fetchAccountPreferences()
        for (key in AccountPreferencesCapabilities.JELLYFIN.supportedKeys) assertNull(prefs[key], key.name)
    }

    @Test
    fun nonSuccessReadThrowsWithStatus() = runTest {
        val server = JellyfinTestServer { FakeResponse(503, """{"Error":"read failed"}""") }
        val error = assertFailsWith<MediaServerHttpException> { JellyfinAccountPreferences(server.core()).fetchAccountPreferences() }
        assertEquals(503, error.statusCode)
    }

    @Test
    fun writeMergesOnePatchIntoFullConfiguration() = runTest {
        val posted = postedFor(
            AccountPreferencesPatch.of(AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE, "ja"),
            """{"SubtitleLanguagePreference":"eng","DisplayMissingEpisodes":true,"OrderedViews":["movies","shows"],"CastReceiverId":"receiver-1","LatestItemsExcludes":["library-hidden"]}""",
        )
        assertEquals(
            Json.parseToJsonElement(
                """{"SubtitleLanguagePreference":"jpn","DisplayMissingEpisodes":true,"OrderedViews":["movies","shows"],"CastReceiverId":"receiver-1","LatestItemsExcludes":["library-hidden"]}""",
            ),
            posted,
        )
    }

    @Test
    fun languageWritesClearWidenOrKeepVerbatim() = runTest {
        assertEquals("\"\"", postedFor(AccountPreferencesPatch.of(AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE, null), """{"AudioLanguagePreference":"eng"}""")["AudioLanguagePreference"].toString())
        assertEquals("\"deu\"", postedFor(AccountPreferencesPatch.of(AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE, "de"))["AudioLanguagePreference"].toString())
        assertEquals("\"x-custom\"", postedFor(AccountPreferencesPatch.of(AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE, "x-custom"))["SubtitleLanguagePreference"].toString())
    }

    @Test
    fun audioByLanguageIsInverseOfPlayDefaultAudioTrackOnBothDialects() = runTest {
        for (dialect in MediaBrowserDialect.entries) {
            for (byLanguage in listOf(true, false)) {
                val read = Account("""{"PlayDefaultAudioTrack":${!byLanguage}}""").prefs(dialect).fetchAccountPreferences()
                assertEquals(byLanguage, read.selectAudioByLanguage)
                assertEquals(byLanguage, read.autoSelectAudio)
                val posted = postedFor(AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, byLanguage), dialect = dialect)
                assertEquals((!byLanguage).toString(), posted["PlayDefaultAudioTrack"].toString())
            }
        }
    }

    @Test
    fun writesEverySubtitleModeWithServerSpelling() = runTest {
        val expected = mapOf(
            SubtitlePlaybackMode.NONE to "None",
            SubtitlePlaybackMode.DEFAULT_MODE to "Default",
            SubtitlePlaybackMode.ALWAYS to "Always",
            SubtitlePlaybackMode.ONLY_FORCED to "OnlyForced",
            SubtitlePlaybackMode.SMART to "Smart",
        )
        for ((mode, spelling) in expected) {
            assertEquals("\"$spelling\"", postedFor(AccountPreferencesPatch.of(AccountPreferenceKey.SUBTITLE_MODE, mode))["SubtitleMode"].toString())
        }
    }

    @Test
    fun configurationWritesReturnAuthoritativeServerValuesOnBothDialects() = runTest {
        for (dialect in MediaBrowserDialect.entries) {
            val server = JellyfinTestServer { req ->
                when {
                    req.method == "POST" -> FakeResponse(204, "")
                    req.path.startsWith("/DisplayPreferences/") -> FakeResponse(body = """{"CustomPrefs":{}}""")
                    else -> FakeResponse(body = """{"Configuration":{"PlayDefaultAudioTrack":false}}""")
                }
            }
            val updated = JellyfinAccountPreferences(server.core(dialect))
                .updateAccountPreferences(AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, false))
            val userPath = if (dialect == MediaBrowserDialect.JELLYFIN) "/Users/Me" else "/Users/user-1"
            assertTrue(server.requests.filter { it.method == "GET" && !it.path.startsWith("/DisplayPreferences/") }.all { it.path == userPath })
            assertEquals("/Users/user-1/Configuration", server.requests.single { it.method == "POST" }.path)
            assertEquals(true, updated.selectAudioByLanguage)
        }
    }

    @Test
    fun nonSuccessWriteThrowsWithStatus() = runTest {
        val server = JellyfinTestServer { req -> if (req.method == "GET") FakeResponse(body = """{"Configuration":{"PlayDefaultAudioTrack":true}}""") else FakeResponse(500, """{"Error":"write failed"}""") }
        val error = assertFailsWith<MediaServerHttpException> {
            JellyfinAccountPreferences(server.core()).updateAccountPreferences(AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, false))
        }
        assertEquals(500, error.statusCode)
    }

    @Test
    fun writeRefusesToPostWhenConfigurationIsMissing() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = "{}") }
        assertFailsWith<IllegalStateException> {
            JellyfinAccountPreferences(server.core()).updateAccountPreferences(AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, false))
        }
        assertFalse(server.requests.any { it.method == "POST" })
    }

    @Test
    fun unsupportedKeysThrowWithoutRequests() = runTest {
        val jellyfin = Account()
        assertFailsWith<UnsupportedOperationException> {
            jellyfin.prefs().updateAccountPreferences(AccountPreferencesPatch.of(AccountPreferenceKey.WATCHED_INDICATOR, WatchedIndicatorScope.NONE))
        }
        val emby = Account()
        val embyPrefs = emby.prefs(MediaBrowserDialect.EMBY)
        assertSame(AccountPreferencesCapabilities.EMBY, embyPrefs.capabilities)
        for (key in listOf(AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS, AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS, AccountPreferenceKey.REWATCHING_IN_NEXT_UP)) {
            assertFailsWith<UnsupportedOperationException> { embyPrefs.updateAccountPreferences(AccountPreferencesPatch.of(key, true)) }
        }
        assertEquals(emptyList(), jellyfin.server.requests + emby.server.requests)
    }

    @Test
    fun rewatchingIsStoredInDisplayPreferencesKeepingOtherKeys() = runTest {
        val account = Account("""{"AudioLanguagePreference":"jpn"}""", """{"someOtherClientKey":"keep-me"}""")
        val result = JellyfinAccountPreferences(account.core)
            .updateAccountPreferences(AccountPreferencesPatch.of(AccountPreferenceKey.REWATCHING_IN_NEXT_UP, true))
        val post = account.posts.single()
        assertEquals("/DisplayPreferences/usersettings", post.path)
        assertEquals(mapOf("userId" to "user-1", "client" to "Plezy"), post.query)
        assertEquals(
            Json.parseToJsonElement("""{"CustomPrefs":{"someOtherClientKey":"keep-me","enableRewatchingInNextUp":"true"}}"""),
            Json.parseToJsonElement(post.body),
        )
        assertEquals(true, result.rewatchingInNextUp)
        assertEquals("jpn", result.preferredAudioLanguage)
        assertTrue(account.core.rewatchingInNextUp)
    }

    @Test
    fun onePatchTouchingBothStoresWritesEachOnce() = runTest {
        val account = Account()
        account.prefs().updateAccountPreferences(
            AccountPreferencesPatch(mapOf(AccountPreferenceKey.REWATCHING_IN_NEXT_UP to true, AccountPreferenceKey.HIDE_PLAYED_IN_LATEST to false)),
        )
        assertEquals(listOf("/DisplayPreferences/usersettings", "/Users/user-1/Configuration"), account.posts.map { it.path })
    }

    @Test
    fun displayPreferencesMergeRejectsNonObject() {
        assertFailsWith<IllegalStateException> { JellyfinAccountPreferences.mergeRewatchingInNextUp(Json.parseToJsonElement("[]"), true) }
        assertNull(JellyfinAccountPreferences.readRewatchingInNextUp(Json.parseToJsonElement("""{"CustomPrefs":{}}""")))
    }

    @Test
    fun checkCurrentAbortsBeforeTheWrite() = runTest {
        val account = Account()
        assertFailsWith<IllegalStateException> {
            account.prefs().updateAccountPreferences(AccountPreferencesPatch.of(AccountPreferenceKey.HIDE_PLAYED_IN_LATEST, true)) { error("stale") }
        }
        assertEquals(emptyList(), account.posts)
    }
}
