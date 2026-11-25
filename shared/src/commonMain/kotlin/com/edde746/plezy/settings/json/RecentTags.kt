package com.edde746.plezy.settings.json

import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.settings.ProfileSettingsRepository
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * The metadata tags a profile applied lately (`metadata_recent_tags`, `{serverId: {fieldId: [tag, …]}}`), for the tag
 * editor's suggestions: per server, so one server's tags don't show on another, and per field (`label`, `genre`, …).
 * Each list is newest first, at most [LIMIT], without two tags differing only in case.
 */
class RecentTags(private val settings: ProfileSettingsRepository) {
    /** [scope]'s recent tags of [fieldId] on [serverId], newest first. */
    suspend fun recentTags(scope: String, serverId: String, fieldId: String): List<String> =
        decode(settings.value(requireScope(scope), ProfileSettings.metadataRecentTags))[serverId]?.get(fieldId).orEmpty()

    /** Records [tags] as just applied to [fieldId] on [serverId]; blank tags are ignored. */
    suspend fun addRecentTags(tags: Iterable<String>, scope: String, serverId: String, fieldId: String) {
        val stored = settings.value(requireScope(scope), ProfileSettings.metadataRecentTags)
        val updated = added(decode(stored), tags, serverId, fieldId) ?: return
        settings.set(scope, ProfileSettings.metadataRecentTags, encode(updated))
    }

    companion object {
        const val LIMIT = 20

        private fun requireScope(scope: String) = scope.also { require(it.isNotBlank()) { "A profile is required" } }

        /** [recent] ahead of [serverTags], each tag once whatever its case, without the item's [existing] tags. */
        fun mergeSuggestions(recent: List<String>, serverTags: List<String>, existing: List<String>): List<String> {
            val seen = existing.mapTo(HashSet()) { it.lowercase() }
            return (recent + serverTags).filter { seen.add(it.lowercase()) }
        }

        /** The stored value's readable part; anything malformed reads as no tags. */
        internal fun decode(stored: JsonObject?): Map<String, Map<String, List<String>>> =
            stored.orEmpty().mapNotNull { (server, fields) ->
                (fields as? JsonObject)?.let { obj ->
                    server to obj.mapNotNull { (field, tags) ->
                        (tags as? JsonArray)?.let { list ->
                            field to list.mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p.isString }?.content }
                        }
                    }.toMap()
                }
            }.toMap()

        internal fun added(
            data: Map<String, Map<String, List<String>>>,
            tags: Iterable<String>,
            serverId: String,
            fieldId: String,
        ): Map<String, Map<String, List<String>>>? {
            val cleaned = tags.map { it.trim() }.filter { it.isNotEmpty() }
            if (cleaned.isEmpty()) return null
            val list = data[serverId]?.get(fieldId).orEmpty().toMutableList()
            for (tag in cleaned.asReversed()) {
                list.removeAll { it.lowercase() == tag.lowercase() }
                list.add(0, tag)
            }
            val fields = data[serverId].orEmpty() + (fieldId to list.take(LIMIT))
            return data + (serverId to fields)
        }

        private fun encode(data: Map<String, Map<String, List<String>>>) = JsonObject(
            data.mapValues { (_, fields) ->
                JsonObject(fields.mapValues { (_, tags) -> JsonArray(tags.map { JsonPrimitive(it) }) }) as JsonElement
            },
        )
    }
}
