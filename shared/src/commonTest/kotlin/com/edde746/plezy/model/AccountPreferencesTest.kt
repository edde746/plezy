package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AccountPreferencesTest {
    @Test
    fun languagesAreExposedAsIso6391WhenConvertible() {
        val prefs = AccountPreferences(preferredAudioLanguage = " DEU ", preferredSubtitleLanguage = "ger")
        assertEquals("de", prefs.preferredAudioLanguageCode1)
        assertEquals("de", prefs.preferredSubtitleLanguageCode1)
        assertEquals("de", prefs[AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE])
        assertEquals(" DEU ", prefs.defaultAudioLanguage)
        assertEquals("xx-unknown", AccountPreferences(preferredAudioLanguage = "xx-unknown").preferredAudioLanguageCode1)
        assertNull(AccountPreferences(preferredAudioLanguage = "").preferredAudioLanguageCode1)
    }

    @Test
    fun autoSelectAudioDefaultsToTrue() {
        assertTrue(AccountPreferences.EMPTY.autoSelectAudio)
        assertFalse(AccountPreferences(selectAudioByLanguage = false).autoSelectAudio)
    }

    @Test
    fun appliedByServer() {
        val applied = AccountPreferenceKey.entries.filter { it.appliedByServer }.toSet()
        assertEquals(
            setOf(
                AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE,
                AccountPreferenceKey.AUTO_SELECT_AUDIO,
                AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE,
                AccountPreferenceKey.SUBTITLE_MODE,
                AccountPreferenceKey.DISPLAY_MISSING_EPISODES,
                AccountPreferenceKey.HIDE_PLAYED_IN_LATEST,
                AccountPreferenceKey.DISPLAY_COLLECTIONS_VIEW,
            ),
            applied,
        )
    }

    @Test
    fun plexIntValuesRoundTrip() {
        assertEquals(WatchedIndicatorScope.SHOWS, WatchedIndicatorScope.fromPlexValue(3))
        assertEquals(MediaReviewsVisibility.NOBODY, MediaReviewsVisibility.fromPlexValue(3))
        assertEquals(SubtitleAccessibilityPreference.ONLY_SDH, SubtitleAccessibilityPreference.fromPlexValue(2))
        assertEquals(ForcedSubtitlePreference.PREFER_FORCED, ForcedSubtitlePreference.fromPlexValue(1))
        assertNull(WatchedIndicatorScope.fromPlexValue(9))
        assertNull(WatchedIndicatorScope.fromPlexValue(null))
    }

    @Test
    fun patchValidatesValueTypePerKey() {
        assertFailsWith<IllegalArgumentException> { AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, null) }
        assertFailsWith<IllegalArgumentException> { AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, "true") }
        assertFailsWith<IllegalArgumentException> { AccountPreferencesPatch.of(AccountPreferenceKey.SUBTITLE_MODE, "always") }
        assertFailsWith<IllegalArgumentException> {
            AccountPreferencesPatch.of(AccountPreferenceKey.WATCHED_INDICATOR, MediaReviewsVisibility.NOBODY)
        }
        val cleared = AccountPreferencesPatch.of(AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE, null)
        assertTrue(AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE in cleared)
        assertNull(cleared.languageAt(AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE))
    }

    @Test
    fun mergeLaterWins() {
        val merged = AccountPreferencesPatch(
            mapOf(AccountPreferenceKey.AUTO_SELECT_AUDIO to true, AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE to "en"),
        ).merge(AccountPreferencesPatch.of(AccountPreferenceKey.AUTO_SELECT_AUDIO, false))
        assertEquals(false, merged.boolAt(AccountPreferenceKey.AUTO_SELECT_AUDIO))
        assertEquals("en", merged.languageAt(AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE))
    }

    @Test
    fun capabilitySets() {
        val caps = AccountPreferencesCapabilities
        assertTrue(caps.JELLYFIN.supports(AccountPreferenceKey.REWATCHING_IN_NEXT_UP))
        assertTrue(caps.JELLYFIN.supports(AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS))
        assertFalse(caps.JELLYFIN.supports(AccountPreferenceKey.AUTO_PLAY_NEXT_EPISODE))
        assertEquals(
            caps.JELLYFIN.supportedKeys - setOf(
                AccountPreferenceKey.REWATCHING_IN_NEXT_UP,
                AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS,
                AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS,
            ),
            caps.EMBY.supportedKeys,
        )
        assertEquals(5, caps.EMBY.subtitleModes.size)
        assertEquals(
            setOf(SubtitlePlaybackMode.NONE, SubtitlePlaybackMode.SMART, SubtitlePlaybackMode.ALWAYS),
            caps.PLEX.subtitleModes,
        )
        assertTrue(caps.PLEX.supports(AccountPreferenceKey.WATCHED_INDICATOR))
        assertTrue(caps.UNSUPPORTED.isEmpty)
    }

    @Test
    fun validateRejectsUnsupportedKeysAndModes() {
        val caps = AccountPreferencesCapabilities
        assertFailsWith<UnsupportedOperationException> {
            caps.PLEX.validate(AccountPreferencesPatch.of(AccountPreferenceKey.HIDE_PLAYED_IN_LATEST, true))
        }
        assertFailsWith<IllegalArgumentException> {
            caps.PLEX.validate(AccountPreferencesPatch.of(AccountPreferenceKey.SUBTITLE_MODE, SubtitlePlaybackMode.ONLY_FORCED))
        }
        caps.JELLYFIN.validate(AccountPreferencesPatch.of(AccountPreferenceKey.SUBTITLE_MODE, SubtitlePlaybackMode.ONLY_FORCED))
    }

    @Test
    fun subtitlePlaybackModeFromServerValue() {
        assertEquals(SubtitlePlaybackMode.ONLY_FORCED, SubtitlePlaybackMode.fromServerValue(" OnlyForced "))
        assertEquals(SubtitlePlaybackMode.DEFAULT_MODE, SubtitlePlaybackMode.fromServerValue("Default"))
        assertEquals(SubtitlePlaybackMode.SMART, SubtitlePlaybackMode.fromServerValue("smart"))
        assertNull(SubtitlePlaybackMode.fromServerValue("sometimes"))
        assertNull(SubtitlePlaybackMode.fromServerValue(null))
    }
}

class AccountRefTest {
    @Test
    fun keyAppendsHomeUserOnlyWhenPresent() {
        assertEquals("plex.acc", AccountRef.plex("plex.acc").key)
        assertEquals("plex.acc", AccountRef.plex("plex.acc", "").key)
        assertEquals("plex.acc/~home/u1", AccountRef.plex("plex.acc", "u1").key)
        assertEquals("m/u", AccountRef.mediaBrowser(BackendKind.EMBY, "m/u").key)
    }

    @Test
    fun equalityAndToString() {
        assertEquals(AccountRef.plex("p", "h"), AccountRef.plex("p", "h"))
        assertTrue(AccountRef.mediaBrowser(BackendKind.JELLYFIN, "m/u") != AccountRef.mediaBrowser(BackendKind.EMBY, "m/u"))
        assertNull(AccountRef.mediaBrowser(BackendKind.JELLYFIN, "m/u").plexHomeUserUuid)
        assertEquals("AccountRef(plex, p/~home/h)", AccountRef.plex("p", "h").toString())
    }
}
