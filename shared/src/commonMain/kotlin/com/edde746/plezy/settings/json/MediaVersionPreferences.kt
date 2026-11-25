package com.edde746.plezy.settings.json

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaVersionPreference
import com.edde746.plezy.settings.AppSettings
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * The media-version choices of this device (`media_version_preferences`), one per series or standalone item under
 * `{serverId}:{grandparentId ?? id}`; earlier releases keyed them by `{grandparentId ?? id}` alone, which reads still
 * fall back to and a write retires. At most [LIMIT] are kept, the least recently written first to go. Written only
 * when the user picks a version.
 */
class MediaVersionPreferences(private val settings: DeviceSettingsRepository) {
    /** [item]'s saved choice, or null. */
    suspend fun saved(item: MediaItem): MediaVersionPreference? =
        saved(settings.value(AppSettings.mediaVersionPreferences), key(item), legacyKey(item))

    /** Remembers [preference] for [item]'s series or item. */
    suspend fun save(item: MediaItem, preference: MediaVersionPreference) {
        settings.update(AppSettings.mediaVersionPreferences) { withPreference(it, key(item), legacyKey(item), preference) }
    }

    /** Forgets [item]'s choice, in either key form. */
    suspend fun reset(item: MediaItem) {
        settings.update(AppSettings.mediaVersionPreferences) { JsonObject(it - key(item) - legacyKey(item)) }
    }

    companion object {
        const val LIMIT = 500

        fun key(item: MediaItem): String {
            val id = item.grandparentId ?: item.id
            val serverId = item.serverId?.takeIf { it.isNotEmpty() }
            return if (serverId != null) "$serverId:$id" else id
        }

        fun legacyKey(item: MediaItem): String = item.grandparentId ?: item.id

        internal fun saved(store: JsonObject, key: String, legacyKey: String): MediaVersionPreference? =
            (store[key] ?: store[legacyKey])?.let(MediaVersionPreference::fromJson)

        internal fun withPreference(store: JsonObject, key: String, legacyKey: String, preference: MediaVersionPreference): JsonObject {
            val updated = LinkedHashMap<String, JsonElement>(store)
            updated.remove(legacyKey)
            updated[key] = preference.toJson()
            if (updated.size <= LIMIT) return JsonObject(updated)
            val newest = updated.entries.sortedByDescending { MediaVersionPreference.fromJson(it.value).updatedAt ?: 0L }.take(LIMIT)
            return JsonObject(newest.associate { it.key to it.value })
        }
    }
}
