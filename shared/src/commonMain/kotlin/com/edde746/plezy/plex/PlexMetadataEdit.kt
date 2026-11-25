package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull

private const val TAG = "PlexMetadataEdit"

/** A candidate of a manual match search (`/library/metadata/{id}/matches`). */
data class PlexMatchResult(
    val guid: String,
    val name: String,
    val year: Int? = null,
    val score: Int? = null,
    val thumb: String? = null,
    val summary: String? = null,
    val type: String? = null,
    val matched: Boolean = false,
) {
    companion object {
        fun fromJson(json: JsonObject) = PlexMatchResult(
            guid = json["guid"].scalarString().orEmpty(),
            name = json["name"].scalarString().orEmpty(),
            year = json["year"].flexInt(),
            score = json["score"].flexInt(),
            thumb = json["thumb"].scalarString(),
            summary = json["summary"].scalarString(),
            type = json["type"].scalarString(),
            matched = json["matched"].flexBool(),
        )
    }
}

/** The per-item preferences `includePreferences=1` embeds: setting id → value as sent back to `/prefs`. */
object PlexMetadataPreferences {
    /**
     * `Metadata[0].Preferences.Setting` or `Metadata[0].Setting`. Strings stay, numbers become their text, booleans
     * `1`/`0`; other values and blank ids are dropped.
     */
    fun fromMediaContainer(container: JsonObject?): Map<String, String> {
        val metadata = container?.get("Metadata").firstObject() ?: return emptyMap()
        val settings = metadata["Preferences"].firstObject()?.get("Setting")?.objectList()?.takeIf { it.isNotEmpty() }
            ?: metadata["Setting"].objectList()
        val values = linkedMapOf<String, String>()
        for (setting in settings) {
            val id = setting["id"].stringOrNull()?.trim()?.takeIf { it.isNotEmpty() } ?: continue
            val value = preferenceValue(setting["value"]) ?: continue
            values[id] = value
        }
        return values
    }

    private fun preferenceValue(value: Any?): String? {
        val p = value as? JsonPrimitive ?: return null
        if (p.isString) return p.content
        p.booleanOrNull?.let { return if (it) "1" else "0" }
        return p.content.takeIf { it.toDoubleOrNull() != null }
    }
}

/** A tag field's edit: the tags it should hold and the ones it held. */
data class PlexTagChange(val current: List<String>, val original: List<String>)

private fun mutationSucceeded(response: MediaServerResponse): Boolean {
    throwIfHttpError(response)
    return response.statusCode == 200
}

/** The item as the server has it now (never the cache); null on 404 or without a row. */
suspend fun PlexClient.fetchEditableItem(id: String): MediaItem? {
    val response = try {
        getWithFailover("/library/metadata/$id")
    } catch (e: MediaServerHttpException) {
        if (e.statusCode == 404) return null
        throw e
    }
    val container = response.data.mediaContainer()
    val metadata = container?.get("Metadata").firstObject() ?: return null
    return mediaItemFromJson(
        metadata,
        plexLibrarySectionIdFromJson(metadata) ?: plexLibrarySectionIdFromJson(container),
        plexLibrarySectionTitleFromJson(metadata) ?: plexLibrarySectionTitleFromJson(container),
    )
}

/**
 * `PUT /library/sections/{sectionId}/all?type=&id=`: each given scalar sends `{f}.value` and `{f}.locked=1`; each tag
 * field sends every current tag as `{f}[i].tag.tag`, the removed ones as `{f}[].tag.tag-` (comma-joined) and
 * `{f}.locked=1`. Plex splits removals on commas without escape, so a field removing a tag that contains one removes
 * each tag in its own follow-up request restating the kept tags. Success invalidates the item's cache.
 */
suspend fun PlexClient.updateMetadata(
    sectionId: Int,
    ratingKey: String,
    typeNumber: Int,
    title: String? = null,
    titleSort: String? = null,
    originalTitle: String? = null,
    originallyAvailableAt: String? = null,
    contentRating: String? = null,
    studio: String? = null,
    tagline: String? = null,
    summary: String? = null,
    tagChanges: Map<String, PlexTagChange>? = null,
): Boolean {
    val path = "/library/sections/$sectionId/all"
    val query = linkedMapOf<String, Any?>("type" to typeNumber, "id" to ratingKey)
    val deferred = mutableListOf<Triple<String, List<String>, List<String>>>()
    fun field(name: String, value: String?) {
        if (value == null) return
        query["$name.value"] = value
        query["$name.locked"] = "1"
    }
    field("title", title)
    field("titleSort", titleSort)
    field("originalTitle", originalTitle)
    field("originallyAvailableAt", originallyAvailableAt)
    field("contentRating", contentRating)
    field("studio", studio)
    field("tagline", tagline)
    field("summary", summary)
    tagChanges?.forEach { (name, change) ->
        change.current.forEachIndexed { index, tag -> query["$name[$index].tag.tag"] = tag }
        val removed = change.original.filter { it !in change.current }
        when {
            removed.any { ',' in it } -> deferred += Triple(name, change.current, removed)
            removed.isNotEmpty() -> query["$name[].tag.tag-"] = removed.joinToString(",")
        }
        query["$name.locked"] = "1"
    }

    if (!mutationSucceeded(http.put(path, query))) return false
    for ((name, current, removed) in deferred) {
        for (tag in removed) {
            val removal = buildMap<String, Any?> {
                put("type", typeNumber)
                put("id", ratingKey)
                current.forEachIndexed { index, kept -> put("$name[$index].tag.tag", kept) }
                put("$name[].tag.tag-", tag)
                put("$name.locked", "1")
            }
            if (!mutationSucceeded(http.put(path, removal))) return false
        }
    }
    invalidateEditedItem(ratingKey)
    return true
}

/** `GET /library/metadata/{id}/matches?manual=1`, sending only non-empty filters; a failed request throws. */
suspend fun PlexClient.findMatches(ratingKey: String, title: String? = null, year: String? = null, agent: String? = null, language: String? = null): List<PlexMatchResult> {
    val query = buildMap<String, Any?> {
        put("manual", 1)
        if (!title.isNullOrEmpty()) put("title", title)
        if (!year.isNullOrEmpty()) put("year", year)
        if (!agent.isNullOrEmpty()) put("agent", agent)
        if (!language.isNullOrEmpty()) put("language", language)
    }
    return getWithFailover("/library/metadata/$ratingKey/matches", query).data.mediaContainer()?.get("SearchResult")
        .objectList().map(PlexMatchResult::fromJson)
}

suspend fun PlexClient.applyMatch(ratingKey: String, guid: String, name: String? = null, year: String? = null): Boolean {
    val query = buildMap<String, Any?> {
        put("guid", guid)
        if (!name.isNullOrEmpty()) put("name", name)
        if (!year.isNullOrEmpty()) put("year", year)
    }
    return mutationSucceeded(http.put("/library/metadata/$ratingKey/match", query)).also { if (it) invalidateEditedItem(ratingKey) }
}

suspend fun PlexClient.unmatchItem(ratingKey: String): Boolean =
    mutationSucceeded(http.put("/library/metadata/$ratingKey/unmatch")).also { if (it) invalidateEditedItem(ratingKey) }

/** The artwork choices of [element] (`posters`, `arts`, `clearLogos`, `squareArts`); empty on failure. */
suspend fun PlexClient.getAvailableArtwork(ratingKey: String, element: String): List<JsonObject> = try {
    getWithFailover("/library/metadata/$ratingKey/$element").data.mediaContainer()?.get("Metadata").objectList()
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to get available artwork" }
    emptyList()
}

suspend fun PlexClient.setArtworkFromUrl(ratingKey: String, element: String, url: String): Boolean =
    mutationSucceeded(http.put("/library/metadata/$ratingKey/${artworkTarget(element)}", mapOf("url" to url)))
        .also { if (it) invalidateEditedItem(ratingKey) }

suspend fun PlexClient.uploadArtwork(ratingKey: String, element: String, bytes: ByteArray): Boolean =
    mutationSucceeded(
        http.put(
            "/library/metadata/$ratingKey/${artworkTarget(element)}",
            headers = mapOf("Content-Type" to "application/octet-stream", "Content-Length" to bytes.size.toString()),
            body = bytes,
        ),
    ).also { if (it) invalidateEditedItem(ratingKey) }

suspend fun PlexClient.getMetadataPrefs(ratingKey: String): Map<String, String> =
    PlexMetadataPreferences.fromMediaContainer(
        getWithFailover("/library/metadata/$ratingKey", mapOf("includePreferences" to 1)).data.mediaContainer(),
    )

suspend fun PlexClient.updateMetadataPrefs(ratingKey: String, prefs: Map<String, String>): Boolean =
    mutationSucceeded(http.put("/library/metadata/$ratingKey/prefs", prefs)).also { if (it) invalidateEditedItem(ratingKey) }

/** `posters` → `poster`: the singular path sets the element. */
private fun artworkTarget(element: String): String = element.removeSuffix("s")

private suspend fun PlexClient.invalidateEditedItem(ratingKey: String) {
    try {
        cache.deleteForItem(cacheServerId, ratingKey)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Plex metadata edit cache invalidation failed" }
    }
}
