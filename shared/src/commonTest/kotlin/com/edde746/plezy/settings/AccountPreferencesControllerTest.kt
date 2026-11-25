package com.edde746.plezy.settings

import com.edde746.plezy.model.AccountPreferenceKey
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesCapabilities
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.AccountPreferencesSource
import com.edde746.plezy.model.AccountRef
import com.edde746.plezy.model.BackendKind
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

/** The active profile's account preferences as playback reads and writes them. */
class AccountPreferencesControllerTest {
    /** An account's server: [stored] what it holds, every read and write counted; [gate] holds the next read. */
    private class Server(var stored: AccountPreferences, override val capabilities: AccountPreferencesCapabilities = AccountPreferencesCapabilities.JELLYFIN) :
        AccountPreferencesSource {
        var reads = 0
        val writes = mutableListOf<AccountPreferencesPatch>()
        var gate: CompletableDeferred<Unit>? = null

        override suspend fun read(): AccountPreferences {
            reads++
            gate?.await()
            return stored
        }

        override suspend fun write(patch: AccountPreferencesPatch, checkCurrent: (() -> Unit)?): AccountPreferences {
            writes += patch
            var next = stored
            for (key in patch.keys) {
                next = when (key) {
                    AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS -> next.copy(rememberAudioSelections = patch[key] as Boolean)
                    AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS -> next.copy(rememberSubtitleSelections = patch[key] as Boolean)
                    else -> error("unexpected $key")
                }
            }
            stored = next
            return next
        }
    }

    private fun account(id: String, server: Server, backend: BackendKind = BackendKind.JELLYFIN) =
        PreferencesAccount(AccountRef.mediaBrowser(backend, "srv/$id"), server)

    @Test
    fun theProfilesPlaybackAccountIsWhatPlaybackSeesAndASwitchForgetsItAtOnce() = runTest {
        val first = account("anna", Server(AccountPreferences(preferredSubtitleLanguage = "fre")))
        val second = Server(AccountPreferences(preferredSubtitleLanguage = "ger"))
        var playing = first
        val controller = AccountPreferencesController { playing }
        controller.bind()
        assertEquals("fre", controller.activePreferences.value?.preferredSubtitleLanguage)

        playing = account("ben", second)
        second.gate = CompletableDeferred()
        launch { controller.bind() }
        runCurrent()
        assertNull(controller.activePreferences.value, "never the previous user's while the next one's load")
        second.gate?.complete(Unit)
        runCurrent()
        assertEquals("ger", controller.activePreferences.value?.preferredSubtitleLanguage)
    }

    @Test
    fun anOfflinePlaybackWaitsAtMostTwoSecondsForThePreferences() = runTest {
        val server = Server(AccountPreferences(preferredAudioLanguage = "jpn")).apply { gate = CompletableDeferred() }
        val controller = AccountPreferencesController { account("anna", server) }
        // The server never answers.
        backgroundScope.launch { controller.bind() }
        var waited = false
        launch {
            controller.awaitActive()
            waited = true
        }
        advanceTimeBy(1999.milliseconds)
        runCurrent()
        assertFalse(waited)
        advanceTimeBy(2.milliseconds)
        runCurrent()
        assertTrue(waited, "plays on without them")
        assertNull(controller.activePreferences.value)
    }

    @Test
    fun aPickTurnsTheAccountsMemoryOnOnceAndAnAccountWithoutTheFlagIsNeverAsked() = runTest {
        val server = Server(AccountPreferences(rememberAudioSelections = false, rememberSubtitleSelections = true))
        val jellyfin = account("anna", server)
        val controller = AccountPreferencesController { jellyfin }
        controller.bind()

        assertTrue(controller.ensureRemembersTrackSelections(jellyfin, AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS))
        assertEquals(listOf(AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS), server.writes.single().keys.toList())
        assertEquals(true, controller.activePreferences.value?.rememberAudioSelections, "playback sees the write")
        assertTrue(controller.ensureRemembersTrackSelections(jellyfin, AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS))
        assertTrue(controller.ensureRemembersTrackSelections(jellyfin, AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS))
        assertEquals(1, server.writes.size, "a flag already on is answered from the cache")
        assertEquals(1, server.reads)

        val emby = Server(AccountPreferences(), AccountPreferencesCapabilities.EMBY)
        assertFalse(controller.ensureRemembersTrackSelections(account("carl", emby, BackendKind.EMBY), AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS))
        assertEquals(0, emby.reads)
        assertEquals(emptyList(), emby.writes)
    }
}
