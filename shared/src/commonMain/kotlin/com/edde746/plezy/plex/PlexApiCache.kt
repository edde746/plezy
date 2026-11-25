package com.edde746.plezy.plex

import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.publicPlexServerIdFromCacheScope
import kotlinx.serialization.json.JsonElement
import com.edde746.plezy.model.buildGlobalKey
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlin.time.Clock

/**
 * Plex's view of the [ApiCacheStore]: an item's metadata lives at `/library/metadata/{ratingKey}` (rating keys may be
 * alphanumeric), its children at `…/children`. A row cached under a profile-private scope maps back to the public
 * server id.
 */
class PlexApiCache(override val store: ApiCacheStore, private val clock: Clock = Clock.System) : BackendCache {
    override suspend fun getMetadata(cacheServerId: String, itemId: String): MediaItem? =
        store.get(cacheServerId, metadataEndpoint(itemId))?.let { decode(cacheServerId, it) }

    /** Pins the metadata row; a missing row stays missing. */
    override suspend fun pinForOffline(cacheServerId: String, itemId: String) {
        store.pin(cacheServerId, metadataEndpoint(itemId))
    }

    /** Removes the item's metadata and children rows. */
    override suspend fun deleteForItem(cacheServerId: String, itemId: String) {
        store.delete(cacheServerId, metadataEndpoint(itemId))
        store.delete(cacheServerId, "${metadataEndpoint(itemId)}/children")
    }

    /**
     * Copies the item's metadata row from [sourceCacheServerId] to [destinationCacheServerId] and pins it there; false
     * when the source has no row. With [stripProfileState] (moving into the ownerless transfer namespace at logout) the
     * profile-private watch fields are removed at every depth.
     */
    suspend fun copyPinnedMetadata(
        sourceCacheServerId: String,
        destinationCacheServerId: String,
        ratingKey: String,
        stripProfileState: Boolean = false,
    ): Boolean {
        val endpoint = metadataEndpoint(ratingKey)
        val cached = store.get(sourceCacheServerId, endpoint) ?: return false
        store.put(destinationCacheServerId, endpoint, if (stripProfileState) withoutProfileState(cached) else cached)
        store.pin(destinationCacheServerId, endpoint)
        return true
    }

    /**
     * Watched: `viewCount` at least 1, `viewOffset` [viewOffsetMs] or 0, `lastViewedAt` [lastViewedAt] or now (epoch
     * seconds). Unwatched: `viewCount` 0, `viewOffset` [viewOffsetMs] or 0, `lastViewedAt` only when given.
     * [viewedLeafCount] is written when given. No cached row: nothing is written.
     */
    override suspend fun applyWatchState(
        cacheServerId: String,
        itemId: String,
        isWatched: Boolean,
        viewOffsetMs: Long?,
        lastViewedAt: Long?,
        viewedLeafCount: Int?,
    ) {
        val endpoint = metadataEndpoint(itemId)
        val cached = store.get(cacheServerId, endpoint) ?: return
        val container = cached.mediaContainer() ?: return
        val metadata = container["Metadata"] as? JsonArray ?: return
        val first = metadata.firstOrNull() as? JsonObject ?: return
        val patched = first.toMutableMap()
        if (isWatched) {
            patched["viewCount"] = JsonPrimitive(maxOf(first["viewCount"].flexInt() ?: 0, 1))
            patched["viewOffset"] = JsonPrimitive(viewOffsetMs ?: 0)
            patched["lastViewedAt"] = JsonPrimitive(lastViewedAt ?: clock.now().epochSeconds)
        } else {
            patched["viewCount"] = JsonPrimitive(0)
            patched["viewOffset"] = JsonPrimitive(viewOffsetMs ?: 0)
            if (lastViewedAt != null) patched["lastViewedAt"] = JsonPrimitive(lastViewedAt)
        }
        if (viewedLeafCount != null) patched["viewedLeafCount"] = JsonPrimitive(viewedLeafCount)
        val newContainer = JsonObject(container + ("Metadata" to JsonArray(listOf(JsonObject(patched)) + metadata.drop(1))))
        store.put(cacheServerId, endpoint, JsonObject(cached + ("MediaContainer" to newContainer)))
    }

    override suspend fun getAllPinnedMetadata(cacheServerIds: Set<String>?): Map<String, MediaItem> {
        val result = LinkedHashMap<String, MediaItem>()
        for (row in store.pinnedRows()) {
            if (cacheServerIds != null && row.cacheServerId !in cacheServerIds) continue
            val ratingKey = pinnedRatingKey(row.endpoint) ?: continue
            try {
                val item = decode(row.cacheServerId, Json.parseToJsonElement(row.data).jsonObject) ?: continue
                result[buildGlobalKey(publicServerId(row.cacheServerId), ratingKey)] = item
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Skipping a malformed pinned row ${row.key}" }
            }
        }
        return result
    }

    private fun decode(cacheServerId: String, cached: JsonObject): MediaItem? {
        val json = PlexCacheParser.extractFirstMetadata(cached) ?: return null
        val container = cached.mediaContainer()
        val item = PlexMappers.mediaItem(json, publicServerId(cacheServerId))
        return item.withPlexLibrary(
            plexLibrarySectionIdFromJson(json) ?: plexLibrarySectionIdFromJson(container),
            plexLibrarySectionTitleFromJson(json) ?: plexLibrarySectionTitleFromJson(container),
        )
    }

    private companion object {
        const val TAG = "PlexApiCache"
        val METADATA_KEY = Regex("/library/metadata/([^/]+)$")

        fun metadataEndpoint(ratingKey: String) = "/library/metadata/$ratingKey"

        fun pinnedRatingKey(endpoint: String): String? = METADATA_KEY.find(endpoint)?.groupValues?.get(1)

        fun publicServerId(cacheServerId: String): ServerId = publicPlexServerIdFromCacheScope(cacheServerId) ?: ServerId(cacheServerId)
    }
}

/** Fields of one profile's relation to a Plex item; Plex may nest them at any depth. */
private val PROFILE_PRIVATE_FIELDS = setOf("lastRatedAt", "lastViewedAt", "skipCount", "userRating", "viewCount", "viewOffset", "viewedLeafCount")

/** Plex metadata [json] without the fields of one profile's relation to the item, at any depth. */
internal fun withoutProfileState(json: JsonObject): JsonObject = scrub(json) as JsonObject

private fun scrub(value: JsonElement): JsonElement = when (value) {
    is JsonObject -> JsonObject(value.filterKeys { it !in PROFILE_PRIVATE_FIELDS }.mapValues { scrub(it.value) })
    is JsonArray -> JsonArray(value.map(::scrub))
    else -> value
}

/** The item with [librarySectionId]/[librarySectionTitle] filling a library it doesn't name itself. */
internal fun MediaItem.withPlexLibrary(librarySectionId: Int?, librarySectionTitle: String?): MediaItem {
    val id = libraryId ?: librarySectionId?.toString()
    val title = libraryTitle ?: librarySectionTitle
    return if (id == libraryId && title == libraryTitle) this else copy(libraryId = id, libraryTitle = title)
}
