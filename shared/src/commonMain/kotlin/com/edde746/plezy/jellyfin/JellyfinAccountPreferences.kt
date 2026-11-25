package com.edde746.plezy.jellyfin

import com.edde746.plezy.lang.LanguageTags
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.AccountPreferenceKey
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesCapabilities
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.SubtitlePlaybackMode
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull

/**
 * Account preferences span two server stores: `UserConfiguration` for the language, subtitle and library fields, and
 * the account's `DisplayPreferences` row for [AccountPreferenceKey.REWATCHING_IN_NEXT_UP], which has no
 * configuration field on either dialect. [checkCurrent] runs between steps and throws to abandon a stale write.
 */
internal class JellyfinAccountPreferences(private val core: JellyfinCore) {
    val capabilities: AccountPreferencesCapabilities
        get() = if (core.dialect == MediaBrowserDialect.EMBY) AccountPreferencesCapabilities.EMBY else AccountPreferencesCapabilities.JELLYFIN

    private val displayPreferencesPath = MediaBrowserPaths.displayPreferences(DISPLAY_PREFERENCES_ID)
    private val displayPreferencesQuery get() = listOf("userId" to core.userId, "client" to DISPLAY_PREFERENCES_CLIENT)

    /** Also caches the rewatching switch on the core for Next Up requests. */
    suspend fun fetchAccountPreferences(checkCurrent: (() -> Unit)? = null): AccountPreferences {
        val (user, display) = coroutineScope {
            val user = async { core.get(core.paths.currentUser) }
            val display = async { core.get(displayPreferencesPath, displayPreferencesQuery) }
            user.await().throwIfError() to display.await().throwIfError()
        }
        val rewatching = readRewatchingInNextUp(display.data)
        checkCurrent?.invoke()
        core.rewatchingInNextUp = rewatching ?: false
        return fromConfiguration(configuration(user.data) ?: JsonObject(emptyMap()), rewatching)
    }

    /** The rewatching switch alone, for Next Up before the preferences page opens; a failure leaves it off. */
    suspend fun loadRewatchingInNextUp() {
        try {
            val display = core.get(displayPreferencesPath, displayPreferencesQuery).throwIfError()
            core.rewatchingInNextUp = readRewatchingInNextUp(display.data) ?: false
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Next Up rewatching switch unavailable" }
        }
    }

    /**
     * Validates against [capabilities] before any request. Configuration fields merge into the full server object
     * (the POST replaces it); the result is a fresh read, so fields this patch did not touch are returned too.
     */
    suspend fun updateAccountPreferences(patch: AccountPreferencesPatch, checkCurrent: (() -> Unit)? = null): AccountPreferences {
        capabilities.validate(patch)
        checkCurrent?.invoke()
        val configurationPatch = AccountPreferencesPatch(patch.values - AccountPreferenceKey.REWATCHING_IN_NEXT_UP)
        if (AccountPreferenceKey.REWATCHING_IN_NEXT_UP in patch) {
            writeRewatchingInNextUp(patch.boolAt(AccountPreferenceKey.REWATCHING_IN_NEXT_UP)!!, checkCurrent)
        }
        if (configurationPatch.isEmpty) return fetchAccountPreferences(checkCurrent)

        val read = core.get(core.paths.currentUser).throwIfError()
        val configuration = configuration(read.data)
            ?: throw IllegalStateException("MediaBrowser current-user response omitted Configuration")
        val merged = mergePatch(configuration, configurationPatch)
        checkCurrent?.invoke()
        core.post(core.paths.userConfiguration, body = merged).throwIfError()
        checkCurrent?.invoke()
        return fetchAccountPreferences(checkCurrent)
    }

    /** Read-modify-write: the POST replaces the row, so everything already in `CustomPrefs` travels back. */
    private suspend fun writeRewatchingInNextUp(value: Boolean, checkCurrent: (() -> Unit)?) {
        val read = core.get(displayPreferencesPath, displayPreferencesQuery).throwIfError()
        val merged = mergeRewatchingInNextUp(read.data, value)
        checkCurrent?.invoke()
        core.post(displayPreferencesPath, displayPreferencesQuery, merged).throwIfError()
        checkCurrent?.invoke()
        core.rewatchingInNextUp = value
    }

    companion object {
        private const val TAG = "JellyfinAccountPreferences"

        /** The id jellyfin-web and jellyfin-androidtv use for user-level settings. */
        const val DISPLAY_PREFERENCES_ID = "usersettings"

        /**
         * Plezy's own client namespace, never `emby`: a POST replaces the whole row and resets any scalar the body
         * omits, which would wipe the first-party clients' settings. The row has no device component, so the value
         * follows the account across devices.
         */
        const val DISPLAY_PREFERENCES_CLIENT = "Plezy"

        /** jellyfin-web's own key for the same switch. Values are the strings `true`/`false`. */
        const val REWATCHING_IN_NEXT_UP_KEY = "enableRewatchingInNextUp"

        /** The `Configuration` object; null when absent. A non-object user or configuration is a contract breach. */
        fun configuration(userDto: JsonElement?): JsonObject? {
            val user = userDto as? JsonObject ?: throw IllegalStateException("MediaBrowser current-user response is not an object")
            return when (val configuration = user["Configuration"]) {
                null, JsonNull -> null
                is JsonObject -> configuration
                else -> throw IllegalStateException("MediaBrowser user Configuration is not an object")
            }
        }

        fun fromConfiguration(configuration: JsonObject, rewatchingInNextUp: Boolean?) = AccountPreferences(
            preferredAudioLanguage = configuration.str("AudioLanguagePreference")?.ifEmpty { null },
            // PlayDefaultAudioTrack true plays the file's default track whatever its language: the inverse.
            selectAudioByLanguage = flexibleBool(configuration["PlayDefaultAudioTrack"])?.not(),
            preferredSubtitleLanguage = configuration.str("SubtitleLanguagePreference")?.ifEmpty { null },
            subtitlePlaybackMode = SubtitlePlaybackMode.fromServerValue((configuration["SubtitleMode"] as? JsonPrimitive)?.content),
            rememberAudioSelections = flexibleBool(configuration["RememberAudioSelections"]),
            rememberSubtitleSelections = flexibleBool(configuration["RememberSubtitleSelections"]),
            autoPlayNextEpisode = flexibleBool(configuration["EnableNextEpisodeAutoPlay"]),
            displayMissingEpisodes = flexibleBool(configuration["DisplayMissingEpisodes"]),
            hidePlayedInLatest = flexibleBool(configuration["HidePlayedInLatest"]),
            displayCollectionsView = flexibleBool(configuration["DisplayCollectionsView"]),
            rewatchingInNextUp = rewatchingInNextUp,
        )

        /** [configuration] with [patch] applied; a cleared language is written as `''`, a two-letter one widened to ISO 639-2. */
        fun mergePatch(configuration: JsonObject, patch: AccountPreferencesPatch): JsonObject {
            val merged = configuration.toMutableMap()
            for ((key, value) in patch.values) {
                val (field, json) = when (key) {
                    AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE -> "AudioLanguagePreference" to JsonPrimitive(serverLanguage(value as String?))
                    AccountPreferenceKey.AUTO_SELECT_AUDIO -> "PlayDefaultAudioTrack" to JsonPrimitive(!(value as Boolean))
                    AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE -> "SubtitleLanguagePreference" to JsonPrimitive(serverLanguage(value as String?))
                    AccountPreferenceKey.SUBTITLE_MODE -> "SubtitleMode" to JsonPrimitive(serverSubtitleMode(value as SubtitlePlaybackMode))
                    AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS -> "RememberAudioSelections" to JsonPrimitive(value as Boolean)
                    AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS -> "RememberSubtitleSelections" to JsonPrimitive(value as Boolean)
                    AccountPreferenceKey.AUTO_PLAY_NEXT_EPISODE -> "EnableNextEpisodeAutoPlay" to JsonPrimitive(value as Boolean)
                    AccountPreferenceKey.DISPLAY_MISSING_EPISODES -> "DisplayMissingEpisodes" to JsonPrimitive(value as Boolean)
                    AccountPreferenceKey.HIDE_PLAYED_IN_LATEST -> "HidePlayedInLatest" to JsonPrimitive(value as Boolean)
                    AccountPreferenceKey.DISPLAY_COLLECTIONS_VIEW -> "DisplayCollectionsView" to JsonPrimitive(value as Boolean)
                    AccountPreferenceKey.REWATCHING_IN_NEXT_UP ->
                        throw IllegalArgumentException("${key.name} is not a UserConfiguration field")
                    AccountPreferenceKey.WATCHED_INDICATOR, AccountPreferenceKey.MEDIA_REVIEWS_VISIBILITY,
                    AccountPreferenceKey.SUBTITLE_ACCESSIBILITY, AccountPreferenceKey.FORCED_SUBTITLES,
                    -> throw IllegalArgumentException("Unsupported MediaBrowser account preference ${key.name}")
                }
                merged[field] = json
            }
            return JsonObject(merged)
        }

        /** The switch from a `DisplayPreferences` DTO; null when never set (the server's default, off). */
        fun readRewatchingInNextUp(dto: JsonElement?): Boolean? =
            ((dto as? JsonObject)?.get("CustomPrefs") as? JsonObject)?.get(REWATCHING_IN_NEXT_UP_KEY)?.let(::flexibleBool)

        /** [dto] with the switch set, every other key and scalar kept: the write replaces the row. */
        fun mergeRewatchingInNextUp(dto: JsonElement?, value: Boolean): JsonObject {
            val obj = dto as? JsonObject ?: throw IllegalStateException("MediaBrowser DisplayPreferences response is not an object")
            val customPrefs = (obj["CustomPrefs"] as? JsonObject).orEmpty() + (REWATCHING_IN_NEXT_UP_KEY to JsonPrimitive(value.toString()))
            return JsonObject(obj + ("CustomPrefs" to JsonObject(customPrefs)))
        }

        private fun serverLanguage(value: String?): String =
            if (value.isNullOrEmpty()) "" else LanguageTags.terminologic(value) ?: value

        private fun serverSubtitleMode(mode: SubtitlePlaybackMode): String = when (mode) {
            SubtitlePlaybackMode.NONE -> "None"
            SubtitlePlaybackMode.DEFAULT_MODE -> "Default"
            SubtitlePlaybackMode.ALWAYS -> "Always"
            SubtitlePlaybackMode.ONLY_FORCED -> "OnlyForced"
            SubtitlePlaybackMode.SMART -> "Smart"
        }

        /** Servers and older clients store these flags as booleans, numbers or strings. */
        private fun flexibleBool(value: JsonElement?): Boolean? {
            val p = value as? JsonPrimitive ?: return null
            if (!p.isString) return p.booleanOrNull ?: p.doubleOrNull?.let { it != 0.0 }
            return when (p.content.trim().lowercase()) {
                "true", "1" -> true
                "false", "0" -> false
                else -> null
            }
        }
    }
}
