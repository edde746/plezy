package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.lang.LanguageNames
import com.edde746.plezy.lang.LanguageTags
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.AccountPreferenceKey
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesCapabilities
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.ForcedSubtitlePreference
import com.edde746.plezy.model.MediaReviewsVisibility
import com.edde746.plezy.model.SubtitleAccessibilityPreference
import com.edde746.plezy.model.SubtitlePlaybackMode
import com.edde746.plezy.model.WatchedIndicatorScope
import com.edde746.plezy.settings.PreferencesAccount
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/**
 * Settings → Account preferences: the options each account stores on its server or plex.tv, for the
 * active profile's accounts. No account: an empty state. Several (and no [accountKey]): the list, each
 * opening its own page. One, or [accountKey]: that account's options, the rows its backend stores.
 *
 * Reads and writes go through the session's one cache ([SettingsSession.accountPreferences]), so playback takes a
 * change to its account at once; a retry reads past it. Writes show at once and revert when the server refuses them
 * ("Could not save changes. Try again."); a change made while one is being written is ignored. A reload (retry, the
 * account list changing) drops what an earlier read or write answers.
 */
internal class AccountPreferencesPage(
    settings: DeviceSettingsRepository,
    private val session: SettingsSession,
    private val accountKey: String?,
    parentScope: CoroutineScope,
) : RowPageStore(settings, parentScope, { T.accountPreferences.sectionTitle }) {
    private var accounts: List<AccountPreferenceAccount>? = null
    private var shown: AccountPreferenceAccount? = null
    private var preferences: AccountPreferences? = null
    private var failure: SettingsEmptyState? = null
    private var pending: Pair<AccountPreferenceKey, Any?>? = null
    private var generation = 0
    private var job: Job? = null

    init {
        follow(session.activeProfile) { reloadAccounts() }
        start(emptyList())
    }

    override val loading: Boolean
        get() = accounts == null || (shown != null && shown?.source != null && preferences == null && failure == null)

    override fun title(): String = if (accountKey != null) shown?.target?.label ?: T.accountPreferences.sectionTitle else T.accountPreferences.sectionTitle

    override fun header(): String? = when {
        accounts == null -> null
        shown != null -> T.accountPreferences.storedOnAccount.takeIf { preferences != null }
        accounts.orEmpty().size > 1 -> T.accountPreferences.pickAccount
        else -> null
    }

    override fun empty(): SettingsEmptyState? = when {
        accounts?.isEmpty() == true -> SettingsEmptyState(T.accountPreferences.noAccounts, T.accountPreferences.noAccountsHint, SettingIcon.MANAGE_ACCOUNTS)
        shown != null -> failure
        else -> null
    }

    override fun resumed() = reloadAccounts()

    override fun activate(id: String) {
        if (id == SettingsEmptyState.RETRY_ID) {
            check(failure != null) { "Nothing to retry" }
            load(forceRefresh = true)
            return
        }
        super.activate(id)
    }

    override fun build(rows: Rows): List<SettingsGroup> {
        val list = accounts ?: return emptyList()
        val account = shown
        if (account == null) {
            return listOf(
                SettingsGroup(
                    "accounts",
                    null,
                    list.map { rows.page(it.target.ref.key, it.target.label, it.target.subtitle, SettingIcon.MANAGE_ACCOUNTS, SettingsPageId.ACCOUNT_PREFERENCES, it.target.ref.key) },
                ),
            )
        }
        val source = account.source ?: return emptyList()
        val loaded = preferences ?: return emptyList()
        return body(rows, source.capabilities, loaded)
    }

    private fun body(rows: Rows, capabilities: AccountPreferencesCapabilities, loaded: AccountPreferences): List<SettingsGroup> {
        fun <V> current(key: AccountPreferenceKey): V? {
            val write = pending
            @Suppress("UNCHECKED_CAST")
            return (if (write != null && write.first == key) write.second else loaded[key]) as V?
        }
        val notSet = T.accountPreferences.notSet
        fun <V> choiceRow(key: AccountPreferenceKey, title: String, icon: SettingIcon, options: List<Choice<V?>>): SettingChoiceRow? {
            if (!capabilities.supports(key)) return null
            return rows.choice(key.name, title, options, current<V>(key), icon, unselectedLabel = notSet) { save(key, it) }
        }
        fun toggleRow(key: AccountPreferenceKey, title: String, subtitle: String?, icon: SettingIcon, unset: Boolean = false): SettingToggleRow? {
            if (!capabilities.supports(key)) return null
            return rows.toggle(key.name, current<Boolean>(key) ?: unset, title, subtitle, icon) { save(key, it) }
        }
        val languages = listOf(Choice<String?>(null, NO_PREFERENCE, T.accountPreferences.noPreference)) + languages().map { Choice<String?>(it.first, it.first, it.second) }
        val audio = listOfNotNull(
            choiceRow(AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE, T.accountPreferences.preferredAudioLanguage, SettingIcon.AUDIO, languages),
            toggleRow(
                AccountPreferenceKey.AUTO_SELECT_AUDIO, T.accountPreferences.autoSelectAudio, T.accountPreferences.autoSelectAudioDescription,
                SettingIcon.AUDIO, unset = loaded.autoSelectAudio,
            ),
            choiceRow(AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE, T.accountPreferences.preferredSubtitleLanguage, SettingIcon.SUBTITLES, languages),
            choiceRow(
                AccountPreferenceKey.SUBTITLE_MODE, T.accountPreferences.subtitleMode, SettingIcon.SUBTITLES,
                SUBTITLE_MODES.filter { it in capabilities.subtitleModes }.map { Choice<SubtitlePlaybackMode?>(it, it.name, subtitleModeLabel(it), subtitleModeDescription(it)) },
            ),
            choiceRow(
                AccountPreferenceKey.SUBTITLE_ACCESSIBILITY, T.accountPreferences.subtitleAccessibility, SettingIcon.SUBTITLES,
                SubtitleAccessibilityPreference.entries.map { Choice<SubtitleAccessibilityPreference?>(it, it.name, accessibilityLabel(it)) },
            ),
            choiceRow(
                AccountPreferenceKey.FORCED_SUBTITLES, T.accountPreferences.forcedSubtitles, SettingIcon.SUBTITLES,
                ForcedSubtitlePreference.entries.map { Choice<ForcedSubtitlePreference?>(it, it.name, forcedLabel(it)) },
            ),
        )
        val library = listOfNotNull(
            toggleRow(AccountPreferenceKey.DISPLAY_MISSING_EPISODES, T.accountPreferences.displayMissingEpisodes, T.accountPreferences.displayMissingEpisodesDescription, SettingIcon.VIEW_LIST),
            toggleRow(AccountPreferenceKey.HIDE_PLAYED_IN_LATEST, T.accountPreferences.hidePlayedInLatest, T.accountPreferences.hidePlayedInLatestDescription, SettingIcon.VISIBILITY),
            toggleRow(AccountPreferenceKey.DISPLAY_COLLECTIONS_VIEW, T.accountPreferences.displayCollectionsView, T.accountPreferences.displayCollectionsViewDescription, SettingIcon.LAYERS),
            toggleRow(AccountPreferenceKey.REWATCHING_IN_NEXT_UP, T.accountPreferences.rewatchingInNextUp, T.accountPreferences.rewatchingInNextUpDescription, SettingIcon.REPLAY),
        )
        val personal = listOfNotNull(
            choiceRow(
                AccountPreferenceKey.WATCHED_INDICATOR, T.accountPreferences.watchedIndicator, SettingIcon.CHECK_CIRCLE,
                WatchedIndicatorScope.entries.map { Choice<WatchedIndicatorScope?>(it, it.name, watchedLabel(it)) },
            ),
            choiceRow(
                AccountPreferenceKey.MEDIA_REVIEWS_VISIBILITY, T.accountPreferences.mediaReviewsVisibility, SettingIcon.ARTICLE,
                MediaReviewsVisibility.entries.map { Choice<MediaReviewsVisibility?>(it, it.name, reviewsLabel(it)) },
            ),
        )
        return listOf(
            SettingsGroup("audio_subtitles", T.accountPreferences.groups.audioAndSubtitles, audio),
            SettingsGroup("library", T.accountPreferences.groups.libraryDisplay, library),
            SettingsGroup("personal", T.accountPreferences.groups.personalMedia, personal),
        )
    }

    /** Lists the accounts again and shows the one this page edits, reading its options when it changed. */
    private fun reloadAccounts() {
        scope.launch {
            val list = try {
                session.accountPreferenceAccounts()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "listing the accounts with preferences failed" }
                emptyList()
            }
            accounts = list
            val next = if (accountKey != null) list.firstOrNull { it.target.ref.key == accountKey } else list.singleOrNull()
            val changed = next?.target?.ref != shown?.target?.ref || next?.source !== shown?.source
            shown = next
            if (changed) load() else publish()
        }
    }

    /** Reads the shown account's options; an older read's or write's answer is dropped. */
    private fun load(forceRefresh: Boolean = false) {
        val account = shown
        val run = ++generation
        job?.cancel()
        preferences = null
        pending = null
        failure = null
        if (account == null) {
            publish()
            return
        }
        val source = account.source
        if (source == null) {
            failure = SettingsEmptyState(T.accountPreferences.unavailable, null, SettingIcon.CLOUD_OFF, T.common.retry)
            publish()
            return
        }
        publish()
        job = scope.launch {
            try {
                val read = session.accountPreferences.load(PreferencesAccount(account.target.ref, source), forceRefresh)
                if (run == generation) preferences = read
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "reading ${account.target.ref}'s preferences failed" }
                if (run == generation) failure = SettingsEmptyState(T.accountPreferences.loadFailed, null, SettingIcon.SYNC_PROBLEM, T.common.retry)
            }
            if (run == generation) publish()
        }
    }

    /** Writes [key] = [value], shown at once; ignored while another write runs; reverted when it fails. */
    private fun save(key: AccountPreferenceKey, value: Any?) {
        val account = shown ?: return
        val source = account.source ?: return
        if (pending != null || preferences == null) return
        val patch = AccountPreferencesPatch.of(key, value)
        pending = key to value
        publish()
        val run = generation
        job = scope.launch {
            try {
                val written = session.accountPreferences.update(PreferencesAccount(account.target.ref, source), patch) {
                    check(run == generation) { "The account changed during the write" }
                }
                if (run != generation) return@launch
                preferences = written
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (run != generation) return@launch
                Log.w(TAG, e) { "writing ${key.name} failed" }
                message(T.settings.saveFailed, error = true)
            }
            pending = null
            publish()
        }
    }

    companion object {
        /** The language choices' "No preference" option. */
        const val NO_PREFERENCE = "none"

        private val SUBTITLE_MODES = listOf(
            SubtitlePlaybackMode.NONE, SubtitlePlaybackMode.DEFAULT_MODE, SubtitlePlaybackMode.ALWAYS,
            SubtitlePlaybackMode.ONLY_FORCED, SubtitlePlaybackMode.SMART,
        )

        /** Every language with a two-letter code, named in the interface language, alphabetically. */
        private fun languages(): List<Pair<String, String>> =
            LanguageTags.preferenceCodes
                .mapNotNull { LanguageTags.canonical(it)?.takeIf { code -> code.length == 2 } }
                .distinct()
                .map { it to (LanguageNames.displayName(it, T.locale) ?: it) }
                .sortedBy { it.second.lowercase() }

        private fun subtitleModeLabel(mode: SubtitlePlaybackMode) = when (mode) {
            SubtitlePlaybackMode.NONE -> T.accountPreferences.subtitleModes.none
            SubtitlePlaybackMode.DEFAULT_MODE -> T.accountPreferences.subtitleModes.defaultMode
            SubtitlePlaybackMode.ALWAYS -> T.accountPreferences.subtitleModes.always
            SubtitlePlaybackMode.ONLY_FORCED -> T.accountPreferences.subtitleModes.onlyForced
            SubtitlePlaybackMode.SMART -> T.accountPreferences.subtitleModes.smart
        }

        private fun subtitleModeDescription(mode: SubtitlePlaybackMode) = when (mode) {
            SubtitlePlaybackMode.NONE -> T.accountPreferences.subtitleModes.noneDescription
            SubtitlePlaybackMode.DEFAULT_MODE -> T.accountPreferences.subtitleModes.defaultModeDescription
            SubtitlePlaybackMode.ALWAYS -> T.accountPreferences.subtitleModes.alwaysDescription
            SubtitlePlaybackMode.ONLY_FORCED -> T.accountPreferences.subtitleModes.onlyForcedDescription
            SubtitlePlaybackMode.SMART -> T.accountPreferences.subtitleModes.smartDescription
        }

        private fun accessibilityLabel(value: SubtitleAccessibilityPreference) = when (value) {
            SubtitleAccessibilityPreference.PREFER_NON_SDH -> T.accountPreferences.subtitleAccessibilityOptions.preferNonSdh
            SubtitleAccessibilityPreference.PREFER_SDH -> T.accountPreferences.subtitleAccessibilityOptions.preferSdh
            SubtitleAccessibilityPreference.ONLY_SDH -> T.accountPreferences.subtitleAccessibilityOptions.onlySdh
            SubtitleAccessibilityPreference.ONLY_NON_SDH -> T.accountPreferences.subtitleAccessibilityOptions.onlyNonSdh
        }

        private fun forcedLabel(value: ForcedSubtitlePreference) = when (value) {
            ForcedSubtitlePreference.PREFER_NON_FORCED -> T.accountPreferences.forcedSubtitleOptions.preferNonForced
            ForcedSubtitlePreference.PREFER_FORCED -> T.accountPreferences.forcedSubtitleOptions.preferForced
            ForcedSubtitlePreference.ONLY_FORCED -> T.accountPreferences.forcedSubtitleOptions.onlyForced
            ForcedSubtitlePreference.ONLY_NON_FORCED -> T.accountPreferences.forcedSubtitleOptions.onlyNonForced
        }

        private fun watchedLabel(value: WatchedIndicatorScope) = when (value) {
            WatchedIndicatorScope.NONE -> T.accountPreferences.watchedIndicatorOptions.none
            WatchedIndicatorScope.MOVIES_AND_SHOWS -> T.accountPreferences.watchedIndicatorOptions.moviesAndShows
            WatchedIndicatorScope.MOVIES -> T.accountPreferences.watchedIndicatorOptions.movies
            WatchedIndicatorScope.SHOWS -> T.accountPreferences.watchedIndicatorOptions.shows
        }

        private fun reviewsLabel(value: MediaReviewsVisibility) = when (value) {
            MediaReviewsVisibility.USERS_AND_CRITICS -> T.accountPreferences.mediaReviewsOptions.usersAndCritics
            MediaReviewsVisibility.USERS_ONLY -> T.accountPreferences.mediaReviewsOptions.usersOnly
            MediaReviewsVisibility.CRITICS_ONLY -> T.accountPreferences.mediaReviewsOptions.criticsOnly
            MediaReviewsVisibility.NOBODY -> T.accountPreferences.mediaReviewsOptions.nobody
        }
    }
}
