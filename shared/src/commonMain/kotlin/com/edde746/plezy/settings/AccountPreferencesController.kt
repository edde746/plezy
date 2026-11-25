package com.edde746.plezy.settings

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.AccountPreferenceKey
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.AccountPreferencesSource
import com.edde746.plezy.model.AccountRef
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** One account whose preferences are stored on its server or plex.tv, and the way to read and write them. */
class PreferencesAccount(val ref: AccountRef, val source: AccountPreferencesSource)

/**
 * The account preferences of the active profile's accounts, kept in memory only (the server stores them), and the
 * ones playback applies as its track defaults: the profile's playback account's ([activePreferences]), never another
 * user's. [bind] (on every profile change) forgets them all and loads the new playback account's, which
 * [playbackAccount] names (null: none, or a Plex Home user whose own token isn't minted yet).
 *
 * Main thread only.
 */
class AccountPreferencesController(
    private val playbackAccount: suspend () -> PreferencesAccount?,
) {
    private val cache = mutableMapOf<AccountRef, AccountPreferences>()
    private var active: AccountRef? = null
    private var generation = 0

    private val mutableActive = MutableStateFlow<AccountPreferences?>(null)

    /** The playback account's preferences; null until they load, and from a profile switch until the next ones do. */
    val activePreferences: StateFlow<AccountPreferences?> = mutableActive.asStateFlow()

    /**
     * The profile changed (or its accounts did): every cached preference is dropped at once, so one user's never answer
     * for another's, then the new playback account's load. A load that fails leaves them unknown (logged).
     */
    suspend fun bind() {
        val bound = ++generation
        cache.clear()
        active = null
        mutableActive.value = null
        val account = playbackAccount() ?: return
        if (bound != generation) return
        active = account.ref
        try {
            load(account)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Couldn't load the account preferences of ${account.ref}" }
        }
    }

    /** Waits up to [timeout] for [activePreferences]: a playback that can't ask the server yet. */
    suspend fun awaitActive(timeout: Duration = ACTIVE_WAIT) {
        withTimeoutOrNull(timeout) { activePreferences.first { it != null } }
    }

    /**
     * [account]'s preferences: the cached ones, else (or with [forceRefresh]) read from the server. Throws the read's
     * failure.
     */
    suspend fun load(account: PreferencesAccount, forceRefresh: Boolean = false): AccountPreferences {
        if (!forceRefresh) cache[account.ref]?.let { return it }
        val bound = generation
        val preferences = account.source.read()
        if (bound == generation) store(account.ref, preferences)
        return preferences
    }

    /**
     * Writes [patch] to [account] and keeps what the server answered; playback sees it at once. [checkCurrent] throws
     * to abort a write that went stale ([AccountPreferencesSource.write]).
     */
    suspend fun update(account: PreferencesAccount, patch: AccountPreferencesPatch, checkCurrent: (() -> Unit)? = null): AccountPreferences {
        val bound = generation
        val updated = account.source.write(patch, checkCurrent)
        if (bound == generation) store(account.ref, updated)
        return updated
    }

    /**
     * Makes [account]'s server remember the track picks playback reports for [key] (remember audio or subtitle
     * selections): the viewer keeps track selections on this device, and the server applies reported picks only with
     * the account's flag on, so a flag that's off is turned on. True when the server will remember; false, without a
     * request, where the account can't store the flag (Emby). A flag already on answers from the cache: each account is
     * written once per key. Failures are thrown: the caller decides whether the pick counts for this playback only.
     */
    suspend fun ensureRemembersTrackSelections(account: PreferencesAccount, key: AccountPreferenceKey): Boolean {
        require(key == AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS || key == AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS) {
            "Not a track-selection memory flag: $key"
        }
        if (!account.source.capabilities.supports(key)) return false
        if (load(account)[key] == true) return true
        Log.i(TAG) { "Turning $key on for ${account.ref}: the device's track-selection memory needs it" }
        return update(account, AccountPreferencesPatch.of(key, true))[key] == true
    }

    private fun store(ref: AccountRef, preferences: AccountPreferences) {
        cache[ref] = preferences
        if (ref == active) mutableActive.value = preferences
    }

    companion object {
        /** How long an offline playback waits for the account preferences before choosing tracks without them. */
        val ACTIVE_WAIT: Duration = 2.seconds

        private const val TAG = "AccountPreferences"
    }
}
