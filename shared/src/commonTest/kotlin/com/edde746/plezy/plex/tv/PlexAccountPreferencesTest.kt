package com.edde746.plezy.plex.tv

import com.edde746.plezy.model.AccountPreferenceKey
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.ForcedSubtitlePreference
import com.edde746.plezy.model.MediaReviewsVisibility
import com.edde746.plezy.model.SubtitleAccessibilityPreference
import com.edde746.plezy.model.SubtitlePlaybackMode
import com.edde746.plezy.model.WatchedIndicatorScope
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal const val PROFILE_PAYLOAD = """{"autoSelectAudio":true,"defaultAudioLanguage":"de","defaultSubtitleLanguage":"sv",
"autoSelectSubtitle":1,"defaultSubtitleAccessibility":2,"defaultSubtitleForced":1,"watchedIndicator":3,"mediaReviewsVisibility":2}"""

internal fun AccountPreferences.snapshot(): List<Any?> = listOf(
    preferredAudioLanguage,
    selectAudioByLanguage,
    preferredSubtitleLanguage,
    subtitlePlaybackMode,
    watchedIndicator,
    mediaReviewsVisibility,
    subtitleAccessibility,
    forcedSubtitles,
)

class PlexAccountPreferencesTest {
    private fun profile(text: String) = PlexAccountPreferences.fromProfileJson(Json.parseToJsonElement(text).jsonObject)

    @Test
    fun `maps all eight profile keys and accepts the profile envelope`() {
        val bare = profile(PROFILE_PAYLOAD)

        assertEquals(
            listOf(
                "de",
                true,
                "sv",
                SubtitlePlaybackMode.SMART,
                WatchedIndicatorScope.SHOWS,
                MediaReviewsVisibility.CRITICS_ONLY,
                SubtitleAccessibilityPreference.ONLY_SDH,
                ForcedSubtitlePreference.PREFER_FORCED,
            ),
            bare.snapshot(),
        )
        assertEquals(bare.snapshot(), profile("""{"profile":$PROFILE_PAYLOAD}""").snapshot())
    }

    @Test
    fun `read tolerates drifted scalars without discarding the profile`() {
        val preferences = profile("""{"autoSelectAudio":"1","autoSelectSubtitle":1,"watchedIndicator":99,"mediaReviewsVisibility":"1"}""")

        assertEquals(true, preferences.selectAudioByLanguage)
        assertEquals(SubtitlePlaybackMode.SMART, preferences.subtitlePlaybackMode)
        assertNull(preferences.watchedIndicator)
        assertEquals(MediaReviewsVisibility.USERS_ONLY, preferences.mediaReviewsVisibility)
    }

    @Test
    fun `language fields take the first entry of array or CSV drift 1488`() {
        val array = profile("""{"defaultAudioLanguage":["en","sv"],"defaultSubtitleLanguage":["sv","en"]}""")
        val csv = profile("""{"defaultAudioLanguage":"en,sv","defaultSubtitleLanguage":"sv,en"}""")
        val absent = profile("""{"defaultAudioLanguage":null}""")

        for (preferences in listOf(array, csv)) {
            assertEquals("en", preferences.defaultAudioLanguage)
            assertEquals("sv", preferences.defaultSubtitleLanguage)
        }
        assertNull(absent.defaultAudioLanguage)
        assertNull(absent.defaultSubtitleLanguage)
    }

    @Test
    fun `a patch becomes the Plex query with ISO 639 1 languages and numeric enums`() {
        val patch = AccountPreferencesPatch(
            mapOf(
                AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE to null,
                AccountPreferenceKey.AUTO_SELECT_AUDIO to true,
                AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE to "deu",
                AccountPreferenceKey.SUBTITLE_MODE to SubtitlePlaybackMode.SMART,
                AccountPreferenceKey.WATCHED_INDICATOR to WatchedIndicatorScope.MOVIES,
                AccountPreferenceKey.MEDIA_REVIEWS_VISIBILITY to MediaReviewsVisibility.NOBODY,
                AccountPreferenceKey.SUBTITLE_ACCESSIBILITY to SubtitleAccessibilityPreference.ONLY_SDH,
                AccountPreferenceKey.FORCED_SUBTITLES to ForcedSubtitlePreference.PREFER_FORCED,
            ),
        )

        assertEquals(
            mapOf(
                "defaultAudioLanguage" to "",
                "autoSelectAudio" to "1",
                "defaultSubtitleLanguage" to "de",
                "autoSelectSubtitle" to "1",
                "watchedIndicator" to "2",
                "mediaReviewsVisibility" to "3",
                "defaultSubtitleAccessibility" to "2",
                "defaultSubtitleForced" to "1",
            ),
            PlexAccountPreferences.queryParametersFor(patch),
        )
    }

    @Test
    fun `disabling automatic audio also sends manual subtitle selection`() {
        assertEquals(
            mapOf("autoSelectAudio" to "0", "autoSelectSubtitle" to "0"),
            PlexAccountPreferences.queryParametersFor(AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, false)),
        )
    }

    @Test
    fun `only forced subtitle mode cannot be represented by Plex`() {
        val patch = AccountPreferencesPatch.of(AccountPreferenceKey.SUBTITLE_MODE, SubtitlePlaybackMode.ONLY_FORCED)

        val error = assertFailsWith<IllegalArgumentException> { PlexAccountPreferences.queryParametersFor(patch) }

        assertTrue("subtitleMode" in error.message.orEmpty())
    }

    @Test
    fun `keys Plex does not store are rejected`() {
        assertFailsWith<IllegalArgumentException> {
            PlexAccountPreferences.queryParametersFor(AccountPreferencesPatch.of(AccountPreferenceKey.HIDE_PLAYED_IN_LATEST, true))
        }
    }

    @Test
    fun `source reads the profile from the clients API bare or enveloped`() = runTest {
        var envelope = false
        val (auth, http) = authWith { jsonResponse(if (envelope) """{"profile":$PROFILE_PAYLOAD}""" else PROFILE_PAYLOAD) }
        val source = PlexAccountPreferencesSource(auth, "account-token")

        val bare = source.read()
        envelope = true
        val wrapped = source.read()

        assertEquals(bare.snapshot(), wrapped.snapshot())
        assertEquals("de", bare.preferredAudioLanguage)
        for (request in http.requests) {
            assertEquals(HttpMethod.Get, request.method)
            assertEquals("clients.plex.tv", request.url.host)
            assertEquals("/api/v2/user/profile", request.url.encodedPath)
            assertEquals("account-token", request.headers["X-Plex-Token"])
        }
    }

    @Test
    fun `write sends query parameters with an empty body and re reads an empty response`() = runTest {
        val (auth, http) = authWith { request ->
            if (request.method == HttpMethod.Put) respond("", HttpStatusCode.NoContent) else jsonResponse(PROFILE_PAYLOAD)
        }
        val source = PlexAccountPreferencesSource(auth, "account-token")
        val patch = AccountPreferencesPatch(
            mapOf(
                AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE to null,
                AccountPreferenceKey.AUTO_SELECT_AUDIO to true,
                AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE to "deu",
            ),
        )

        val preferences = source.write(patch)

        assertEquals(2, http.requests.size)
        val put = http.requests.first()
        assertEquals(HttpMethod.Put, put.method)
        assertEquals("clients.plex.tv", put.url.host)
        assertEquals("/api/v2/user/profile", put.url.encodedPath)
        assertEquals(
            mapOf("defaultAudioLanguage" to "", "autoSelectAudio" to "1", "defaultSubtitleLanguage" to "de"),
            put.url.parameters.names().associateWith { put.url.parameters[it] },
        )
        assertEquals(0L, put.body.contentLength ?: 0L)
        assertNull(put.body.contentType)
        assertNull(put.headers[HttpHeaders.ContentType])
        assertEquals(HttpMethod.Get, http.requests.last().method)
        assertEquals("de", preferences.preferredAudioLanguage)
    }

    @Test
    fun `write uses a non empty answer without reading again`() = runTest {
        val (auth, http) = authWith { jsonResponse("""{"autoSelectAudio":false,"autoSelectSubtitle":0}""") }

        val preferences = PlexAccountPreferencesSource(auth, "account-token")
            .write(AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, false))

        assertEquals(1, http.requests.size)
        assertEquals(false, preferences.selectAudioByLanguage)
        assertEquals(SubtitlePlaybackMode.NONE, preferences.subtitlePlaybackMode)
    }

    @Test
    fun `write validates the patch and checks it is current before sending`() = runTest {
        val (auth, http) = authWith { jsonResponse(PROFILE_PAYLOAD) }
        val source = PlexAccountPreferencesSource(auth, "account-token")

        assertFailsWith<UnsupportedOperationException> {
            source.write(AccountPreferencesPatch.of(AccountPreferenceKey.HIDE_PLAYED_IN_LATEST, true))
        }
        assertFailsWith<IllegalStateException> {
            source.write(AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, true)) { throw IllegalStateException("stale") }
        }
        assertEquals(0, http.requests.size)
    }
}
