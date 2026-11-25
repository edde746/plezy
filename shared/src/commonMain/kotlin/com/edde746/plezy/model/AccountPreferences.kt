package com.edde746.plezy.model

import com.edde746.plezy.lang.LanguageTags

/** Backend-neutral subtitle playback modes used by server-side user profiles. */
enum class SubtitlePlaybackMode {
    NONE,
    DEFAULT_MODE,
    ALWAYS,
    ONLY_FORCED,
    SMART,
    ;

    companion object {
        fun fromServerValue(value: Any?): SubtitlePlaybackMode? = when (value?.toString()?.trim()?.lowercase()) {
            "none" -> NONE
            "default" -> DEFAULT_MODE
            "always" -> ALWAYS
            "onlyforced" -> ONLY_FORCED
            "smart" -> SMART
            else -> null
        }
    }
}

/**
 * Backend-neutral subset of a server-stored user profile used for auto-track selection. Language strings are
 * server-shaped (Plex may return 639-2/B like `fre`, Jellyfin 639-2/T like `fra`).
 */
interface MediaServerUserProfile {
    /** Whether the player should auto-pick an audio track by language; false keeps the file's default track. */
    val autoSelectAudio: Boolean

    val defaultAudioLanguage: String?

    val defaultSubtitleLanguage: String?

    /** Server-side subtitle mode when the backend leaves auto-selection to the client (MediaBrowser). */
    val subtitleMode: SubtitlePlaybackMode? get() = null
}

/** Value shape of an [AccountPreferenceKey]. */
enum class AccountPreferenceValueKind {
    BOOLEAN,

    /** ISO 639-1 or a backend-specific language code, or null for "no preference". */
    LANGUAGE_CODE,
    SUBTITLE_MODE,
    WATCHED_INDICATOR,
    MEDIA_REVIEWS_VISIBILITY,
    SUBTITLE_ACCESSIBILITY,
    FORCED_SUBTITLES,
}

/**
 * One account-scoped preference, stored on the media server or plex.tv, never on the device. Each backend supports a
 * subset; see [AccountPreferencesCapabilities].
 */
enum class AccountPreferenceKey(val valueKind: AccountPreferenceValueKind) {
    PREFERRED_AUDIO_LANGUAGE(AccountPreferenceValueKind.LANGUAGE_CODE),

    /** Plex `autoSelectAudio`; the inverse of MediaBrowser `PlayDefaultAudioTrack`. */
    AUTO_SELECT_AUDIO(AccountPreferenceValueKind.BOOLEAN),
    PREFERRED_SUBTITLE_LANGUAGE(AccountPreferenceValueKind.LANGUAGE_CODE),
    SUBTITLE_MODE(AccountPreferenceValueKind.SUBTITLE_MODE),
    REMEMBER_AUDIO_SELECTIONS(AccountPreferenceValueKind.BOOLEAN),
    REMEMBER_SUBTITLE_SELECTIONS(AccountPreferenceValueKind.BOOLEAN),

    /** MediaBrowser only; Plex keeps its twin in a per-device blob that is never written. */
    AUTO_PLAY_NEXT_EPISODE(AccountPreferenceValueKind.BOOLEAN),
    DISPLAY_MISSING_EPISODES(AccountPreferenceValueKind.BOOLEAN),
    HIDE_PLAYED_IN_LATEST(AccountPreferenceValueKind.BOOLEAN),
    DISPLAY_COLLECTIONS_VIEW(AccountPreferenceValueKind.BOOLEAN),
    WATCHED_INDICATOR(AccountPreferenceValueKind.WATCHED_INDICATOR),
    MEDIA_REVIEWS_VISIBILITY(AccountPreferenceValueKind.MEDIA_REVIEWS_VISIBILITY),
    SUBTITLE_ACCESSIBILITY(AccountPreferenceValueKind.SUBTITLE_ACCESSIBILITY),
    FORCED_SUBTITLES(AccountPreferenceValueKind.FORCED_SUBTITLES),

    /**
     * Keep a finished series in Next Up while rewatching. Jellyfin only; stored in the account's display-preferences
     * custom prefs and sent per request as `EnableRewatching`.
     */
    REWATCHING_IN_NEXT_UP(AccountPreferenceValueKind.BOOLEAN),
    ;

    /** Whether the server applies this preference itself; false means the client must honour it. */
    val appliedByServer: Boolean
        get() = when (this) {
            PREFERRED_AUDIO_LANGUAGE, AUTO_SELECT_AUDIO, PREFERRED_SUBTITLE_LANGUAGE, SUBTITLE_MODE,
            DISPLAY_MISSING_EPISODES, HIDE_PLAYED_IN_LATEST, DISPLAY_COLLECTIONS_VIEW,
            -> true
            REMEMBER_AUDIO_SELECTIONS, REMEMBER_SUBTITLE_SELECTIONS, AUTO_PLAY_NEXT_EPISODE, WATCHED_INDICATOR,
            MEDIA_REVIEWS_VISIBILITY, SUBTITLE_ACCESSIBILITY, FORCED_SUBTITLES, REWATCHING_IN_NEXT_UP,
            -> false
        }
}

/** Which item types get a watched badge (Plex `watchedIndicator`). */
enum class WatchedIndicatorScope(val plexValue: Int) {
    NONE(0),
    MOVIES_AND_SHOWS(1),
    MOVIES(2),
    SHOWS(3),
    ;

    companion object {
        fun fromPlexValue(value: Int?): WatchedIndicatorScope? = value?.let { v -> entries.firstOrNull { it.plexValue == v } }
    }
}

/** Whose ratings and reviews to surface (Plex `mediaReviewsVisibility`). */
enum class MediaReviewsVisibility(val plexValue: Int) {
    USERS_AND_CRITICS(0),
    USERS_ONLY(1),
    CRITICS_ONLY(2),
    NOBODY(3),
    ;

    companion object {
        fun fromPlexValue(value: Int?): MediaReviewsVisibility? = value?.let { v -> entries.firstOrNull { it.plexValue == v } }
    }
}

/** SDH preference for subtitle searches (Plex `defaultSubtitleAccessibility`). */
enum class SubtitleAccessibilityPreference(val plexValue: Int) {
    PREFER_NON_SDH(0),
    PREFER_SDH(1),
    ONLY_SDH(2),
    ONLY_NON_SDH(3),
    ;

    companion object {
        fun fromPlexValue(value: Int?): SubtitleAccessibilityPreference? =
            value?.let { v -> entries.firstOrNull { it.plexValue == v } }
    }
}

/** Forced-subtitle preference for subtitle searches (Plex `defaultSubtitleForced`). */
enum class ForcedSubtitlePreference(val plexValue: Int) {
    PREFER_NON_FORCED(0),
    PREFER_FORCED(1),
    ONLY_FORCED(2),
    ONLY_NON_FORCED(3),
    ;

    companion object {
        fun fromPlexValue(value: Int?): ForcedSubtitlePreference? = value?.let { v -> entries.firstOrNull { it.plexValue == v } }
    }
}

/**
 * A read snapshot of one account's server-stored preferences. Null means unset or unsupported (consult
 * [AccountPreferencesCapabilities]). Language fields keep the server's own spelling; the UI reads the `*Code1`
 * accessors.
 */
data class AccountPreferences(
    val preferredAudioLanguage: String? = null,
    val selectAudioByLanguage: Boolean? = null,
    val preferredSubtitleLanguage: String? = null,
    val subtitlePlaybackMode: SubtitlePlaybackMode? = null,
    val rememberAudioSelections: Boolean? = null,
    val rememberSubtitleSelections: Boolean? = null,
    val autoPlayNextEpisode: Boolean? = null,
    val displayMissingEpisodes: Boolean? = null,
    val hidePlayedInLatest: Boolean? = null,
    val displayCollectionsView: Boolean? = null,
    val watchedIndicator: WatchedIndicatorScope? = null,
    val mediaReviewsVisibility: MediaReviewsVisibility? = null,
    val subtitleAccessibility: SubtitleAccessibilityPreference? = null,
    val forcedSubtitles: ForcedSubtitlePreference? = null,
    val rewatchingInNextUp: Boolean? = null,
) : MediaServerUserProfile {
    /** Preferred audio language narrowed to ISO 639-1 for pickers. */
    val preferredAudioLanguageCode1: String? get() = code1(preferredAudioLanguage)

    /** Preferred subtitle language narrowed to ISO 639-1 for pickers. */
    val preferredSubtitleLanguageCode1: String? get() = code1(preferredSubtitleLanguage)

    /** Typed read of a single key, for generic UI rows. */
    operator fun get(key: AccountPreferenceKey): Any? = when (key) {
        AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE -> preferredAudioLanguageCode1
        AccountPreferenceKey.AUTO_SELECT_AUDIO -> selectAudioByLanguage
        AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE -> preferredSubtitleLanguageCode1
        AccountPreferenceKey.SUBTITLE_MODE -> subtitlePlaybackMode
        AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS -> rememberAudioSelections
        AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS -> rememberSubtitleSelections
        AccountPreferenceKey.AUTO_PLAY_NEXT_EPISODE -> autoPlayNextEpisode
        AccountPreferenceKey.DISPLAY_MISSING_EPISODES -> displayMissingEpisodes
        AccountPreferenceKey.HIDE_PLAYED_IN_LATEST -> hidePlayedInLatest
        AccountPreferenceKey.DISPLAY_COLLECTIONS_VIEW -> displayCollectionsView
        AccountPreferenceKey.WATCHED_INDICATOR -> watchedIndicator
        AccountPreferenceKey.MEDIA_REVIEWS_VISIBILITY -> mediaReviewsVisibility
        AccountPreferenceKey.SUBTITLE_ACCESSIBILITY -> subtitleAccessibility
        AccountPreferenceKey.FORCED_SUBTITLES -> forcedSubtitles
        AccountPreferenceKey.REWATCHING_IN_NEXT_UP -> rewatchingInNextUp
    }

    /**
     * Defaults to true, Plex's own `autoSelectAudio` default, when unset. MediaBrowser servers always serialize
     * `PlayDefaultAudioTrack`, so the fallback never stands in for their inverse default.
     */
    override val autoSelectAudio: Boolean get() = selectAudioByLanguage ?: true

    override val defaultAudioLanguage: String? get() = preferredAudioLanguage

    override val defaultSubtitleLanguage: String? get() = preferredSubtitleLanguage

    override val subtitleMode: SubtitlePlaybackMode? get() = subtitlePlaybackMode

    companion object {
        val EMPTY: AccountPreferences = AccountPreferences()

        /** ISO 639-1 code of [raw]'s language subtag, or [raw] unchanged when it has none. */
        private fun code1(raw: String?): String? {
            if (raw.isNullOrEmpty()) return null
            val primary = raw.trim().lowercase().split('-', '_').first()
            val canonical = LanguageTags.canonical(primary)?.takeIf { it.length == 2 } ?: return raw
            return if (LanguageTags.terminologic(canonical) != null) canonical else raw
        }
    }
}

/**
 * A sparse set of changes to one account. Values are type-checked per key on construction
 * ([IllegalArgumentException] on mismatch). A language key may hold null (clear the preference).
 */
class AccountPreferencesPatch(values: Map<AccountPreferenceKey, Any?>) {
    val values: Map<AccountPreferenceKey, Any?> = values.mapValues { (key, value) -> checked(key, value) }

    val keys: Set<AccountPreferenceKey> get() = values.keys

    val isEmpty: Boolean get() = values.isEmpty()

    val isNotEmpty: Boolean get() = values.isNotEmpty()

    operator fun contains(key: AccountPreferenceKey): Boolean = values.containsKey(key)

    /** Value for [key], or null when unset or explicitly cleared; gate on [contains] first. */
    operator fun get(key: AccountPreferenceKey): Any? = values[key]

    fun boolAt(key: AccountPreferenceKey): Boolean? = values[key] as Boolean?

    fun languageAt(key: AccountPreferenceKey): String? = values[key] as String?

    /** [other]'s values win on overlapping keys. */
    fun merge(other: AccountPreferencesPatch): AccountPreferencesPatch = AccountPreferencesPatch(values + other.values)

    override fun equals(other: Any?): Boolean = other is AccountPreferencesPatch && other.values == values

    override fun hashCode(): Int = values.hashCode()

    override fun toString(): String = "AccountPreferencesPatch(${values.keys.joinToString(",") { it.name }})"

    companion object {
        fun of(key: AccountPreferenceKey, value: Any?): AccountPreferencesPatch = AccountPreferencesPatch(mapOf(key to value))

        private fun checked(key: AccountPreferenceKey, value: Any?): Any? {
            val ok = when (key.valueKind) {
                AccountPreferenceValueKind.BOOLEAN -> value is Boolean
                AccountPreferenceValueKind.LANGUAGE_CODE -> value == null || value is String
                AccountPreferenceValueKind.SUBTITLE_MODE -> value is SubtitlePlaybackMode
                AccountPreferenceValueKind.WATCHED_INDICATOR -> value is WatchedIndicatorScope
                AccountPreferenceValueKind.MEDIA_REVIEWS_VISIBILITY -> value is MediaReviewsVisibility
                AccountPreferenceValueKind.SUBTITLE_ACCESSIBILITY -> value is SubtitleAccessibilityPreference
                AccountPreferenceValueKind.FORCED_SUBTITLES -> value is ForcedSubtitlePreference
            }
            require(ok) { "Invalid value for account preference ${key.name}" }
            return value
        }
    }
}

/** What one backend stores, so the UI hides rows it cannot write and callers tell "unset" from "unsupported". */
data class AccountPreferencesCapabilities(
    val supportedKeys: Set<AccountPreferenceKey>,
    /** Subtitle modes this backend can store; empty when [AccountPreferenceKey.SUBTITLE_MODE] is unsupported. */
    val subtitleModes: Set<SubtitlePlaybackMode>,
) {
    fun supports(key: AccountPreferenceKey): Boolean = key in supportedKeys

    val isEmpty: Boolean get() = supportedKeys.isEmpty()

    /**
     * Throws [UnsupportedOperationException] for a key this backend cannot store and [IllegalArgumentException] for
     * a subtitle mode it cannot store.
     */
    fun validate(patch: AccountPreferencesPatch) {
        for (key in patch.keys) {
            if (!supports(key)) throw UnsupportedOperationException("Unsupported account preference ${key.name}")
            require(key != AccountPreferenceKey.SUBTITLE_MODE || patch[key] in subtitleModes) {
                "Unsupported subtitle mode for this account"
            }
        }
    }

    companion object {
        private val MEDIA_BROWSER_SUBTITLE_MODES = setOf(
            SubtitlePlaybackMode.DEFAULT_MODE,
            SubtitlePlaybackMode.ALWAYS,
            SubtitlePlaybackMode.ONLY_FORCED,
            SubtitlePlaybackMode.NONE,
            SubtitlePlaybackMode.SMART,
        )

        /**
         * Jellyfin user configuration plus [AccountPreferenceKey.REWATCHING_IN_NEXT_UP] in display-preferences
         * custom prefs. [AccountPreferenceKey.AUTO_PLAY_NEXT_EPISODE] is read and round-tripped but not editable:
         * the client owns that decision locally.
         */
        val JELLYFIN = AccountPreferencesCapabilities(
            supportedKeys = setOf(
                AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE,
                AccountPreferenceKey.AUTO_SELECT_AUDIO,
                AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE,
                AccountPreferenceKey.SUBTITLE_MODE,
                AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS,
                AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS,
                AccountPreferenceKey.DISPLAY_MISSING_EPISODES,
                AccountPreferenceKey.HIDE_PLAYED_IN_LATEST,
                AccountPreferenceKey.DISPLAY_COLLECTIONS_VIEW,
                AccountPreferenceKey.REWATCHING_IN_NEXT_UP,
            ),
            subtitleModes = MEDIA_BROWSER_SUBTITLE_MODES,
        )

        /** Emby: Jellyfin's set minus rewatching (no `EnableRewatching`) and the remember flags (effect unverified). */
        val EMBY = AccountPreferencesCapabilities(
            supportedKeys = setOf(
                AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE,
                AccountPreferenceKey.AUTO_SELECT_AUDIO,
                AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE,
                AccountPreferenceKey.SUBTITLE_MODE,
                AccountPreferenceKey.DISPLAY_MISSING_EPISODES,
                AccountPreferenceKey.HIDE_PLAYED_IN_LATEST,
                AccountPreferenceKey.DISPLAY_COLLECTIONS_VIEW,
            ),
            subtitleModes = MEDIA_BROWSER_SUBTITLE_MODES,
        )

        /** plex.tv user profile. `autoSelectSubtitle` has three states: manual, with foreign audio, always. */
        val PLEX = AccountPreferencesCapabilities(
            supportedKeys = setOf(
                AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE,
                AccountPreferenceKey.AUTO_SELECT_AUDIO,
                AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE,
                AccountPreferenceKey.SUBTITLE_MODE,
                AccountPreferenceKey.WATCHED_INDICATOR,
                AccountPreferenceKey.MEDIA_REVIEWS_VISIBILITY,
                AccountPreferenceKey.SUBTITLE_ACCESSIBILITY,
                AccountPreferenceKey.FORCED_SUBTITLES,
            ),
            subtitleModes = setOf(SubtitlePlaybackMode.NONE, SubtitlePlaybackMode.SMART, SubtitlePlaybackMode.ALWAYS),
        )

        val UNSUPPORTED = AccountPreferencesCapabilities(supportedKeys = emptySet(), subtitleModes = emptySet())
    }
}
