package com.edde746.plezy.plex.tv

import com.edde746.plezy.lang.LanguageTags
import com.edde746.plezy.model.AccountPreferenceKey
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.ForcedSubtitlePreference
import com.edde746.plezy.model.MediaReviewsVisibility
import com.edde746.plezy.model.SubtitleAccessibilityPreference
import com.edde746.plezy.model.SubtitlePlaybackMode
import com.edde746.plezy.model.WatchedIndicatorScope
import com.edde746.plezy.plex.flexBoolOrNull
import com.edde746.plezy.plex.flexInt
import com.edde746.plezy.plex.stringOrNull
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * The account preferences plex.tv stores in `/api/v2/user/profile`. The account API drifts, so each field reads on its
 * own: an unexpected value leaves that field null instead of discarding the profile.
 */
object PlexAccountPreferences {
    /** The preferences of a bare profile object or of the `{"profile": {...}}` envelope `/user` answers. */
    fun fromProfileJson(json: JsonObject): AccountPreferences {
        val profile = json["profile"] as? JsonObject ?: json
        return AccountPreferences(
            preferredAudioLanguage = profileLanguage(profile["defaultAudioLanguage"]),
            selectAudioByLanguage = profile["autoSelectAudio"].flexBoolOrNull(),
            preferredSubtitleLanguage = profileLanguage(profile["defaultSubtitleLanguage"]),
            subtitlePlaybackMode = when (profile["autoSelectSubtitle"].flexInt()) {
                0 -> SubtitlePlaybackMode.NONE
                1 -> SubtitlePlaybackMode.SMART
                2 -> SubtitlePlaybackMode.ALWAYS
                else -> null
            },
            watchedIndicator = WatchedIndicatorScope.fromPlexValue(profile["watchedIndicator"].flexInt()),
            mediaReviewsVisibility = MediaReviewsVisibility.fromPlexValue(profile["mediaReviewsVisibility"].flexInt()),
            subtitleAccessibility =
                SubtitleAccessibilityPreference.fromPlexValue(profile["defaultSubtitleAccessibility"].flexInt()),
            forcedSubtitles = ForcedSubtitlePreference.fromPlexValue(profile["defaultSubtitleForced"].flexInt()),
        )
    }

    /**
     * [patch] as the query plex.tv takes on `PUT /user/profile`: languages as ISO 639-1 (none: empty), booleans as
     * `1`/`0`, the rest as Plex's numbers. Turning automatic audio selection off also sends manual subtitle selection
     * (`autoSelectSubtitle=0`), as Plex Web does, so the two stored settings stay consistent. A key Plex doesn't store,
     * or a subtitle mode it can't represent, throws [IllegalArgumentException].
     */
    fun queryParametersFor(patch: AccountPreferencesPatch): Map<String, String> {
        val parameters = LinkedHashMap<String, String>()
        for ((key, value) in patch.values) {
            when (key) {
                AccountPreferenceKey.PREFERRED_AUDIO_LANGUAGE -> parameters["defaultAudioLanguage"] = languageQueryValue(value as String?)
                AccountPreferenceKey.AUTO_SELECT_AUDIO -> parameters["autoSelectAudio"] = if (value as Boolean) "1" else "0"
                AccountPreferenceKey.PREFERRED_SUBTITLE_LANGUAGE ->
                    parameters["defaultSubtitleLanguage"] = languageQueryValue(value as String?)
                AccountPreferenceKey.SUBTITLE_MODE -> parameters["autoSelectSubtitle"] = when (value as SubtitlePlaybackMode) {
                    SubtitlePlaybackMode.NONE -> "0"
                    SubtitlePlaybackMode.SMART -> "1"
                    SubtitlePlaybackMode.ALWAYS -> "2"
                    SubtitlePlaybackMode.DEFAULT_MODE, SubtitlePlaybackMode.ONLY_FORCED ->
                        throw IllegalArgumentException("subtitleMode $value cannot be represented by Plex autoSelectSubtitle")
                }
                AccountPreferenceKey.WATCHED_INDICATOR ->
                    parameters["watchedIndicator"] = (value as WatchedIndicatorScope).plexValue.toString()
                AccountPreferenceKey.MEDIA_REVIEWS_VISIBILITY ->
                    parameters["mediaReviewsVisibility"] = (value as MediaReviewsVisibility).plexValue.toString()
                AccountPreferenceKey.SUBTITLE_ACCESSIBILITY ->
                    parameters["defaultSubtitleAccessibility"] = (value as SubtitleAccessibilityPreference).plexValue.toString()
                AccountPreferenceKey.FORCED_SUBTITLES ->
                    parameters["defaultSubtitleForced"] = (value as ForcedSubtitlePreference).plexValue.toString()
                AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS,
                AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS,
                AccountPreferenceKey.AUTO_PLAY_NEXT_EPISODE,
                AccountPreferenceKey.DISPLAY_MISSING_EPISODES,
                AccountPreferenceKey.HIDE_PLAYED_IN_LATEST,
                AccountPreferenceKey.DISPLAY_COLLECTIONS_VIEW,
                AccountPreferenceKey.REWATCHING_IN_NEXT_UP,
                -> throw IllegalArgumentException("${key.name} is not supported by Plex account preferences")
            }
        }
        if (patch[AccountPreferenceKey.AUTO_SELECT_AUDIO] == false) parameters["autoSelectSubtitle"] = "0"
        return parameters
    }

    /** The first language of a single code, a list or a comma-separated list (plex.tv has sent all three). */
    private fun profileLanguage(value: JsonElement?): String? {
        val strings = when (value) {
            is JsonArray -> value.mapNotNull { it.stringOrNull() }
            else -> listOfNotNull(value.stringOrNull())
        }
        return strings.flatMap { it.split(',') }.map { it.trim() }.firstOrNull { it.isNotEmpty() }
    }

    /** Empty for no language; otherwise its ISO 639-1 code when it has one, else as given. */
    private fun languageQueryValue(value: String?): String {
        if (value.isNullOrEmpty()) return ""
        val canonical = LanguageTags.canonical(value.trim().lowercase().split('-', '_').first())
        return if (canonical != null && canonical.length == 2) canonical else value
    }
}
