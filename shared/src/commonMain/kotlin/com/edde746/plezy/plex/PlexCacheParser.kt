package com.edde746.plezy.plex

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject

/** Reading cached Plex response bodies. */
object PlexCacheParser {
    /**
     * `MediaContainer.Metadata` of a cached body; null without a container object or without the field. A `Metadata`
     * that is not a list is a corrupt row and throws.
     */
    fun extractMetadataList(cached: JsonObject?): JsonArray? {
        val metadata = cached.mediaContainer()?.get("Metadata") ?: return null
        if (metadata is JsonNull) return null
        return metadata as? JsonArray ?: throw IllegalArgumentException("Cached MediaContainer.Metadata is not a list")
    }

    /** The first `Metadata` entry, null when there is none; a non-object entry throws. */
    fun extractFirstMetadata(cached: JsonObject?): JsonObject? {
        val first = extractMetadataList(cached)?.firstOrNull() ?: return null
        return first as? JsonObject ?: throw IllegalArgumentException("Cached metadata entry is not an object")
    }
}
