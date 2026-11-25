package com.edde746.plezy.trackers.client

import com.edde746.plezy.trackers.HistoryItem
import com.edde746.plezy.trackers.TrackerContext
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonObjectBuilder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The history body Trakt (`/sync/history`), Simkl (`/sync/history`) and MDBList (`/sync/watched`) share, removals
 * included: `movies` by their ids, episodes under their show's ids as `shows[].seasons[].episodes[]` by number. [ids]
 * names an item on the service, `null` (or no ids) when it can't, which leaves the item out, as is an episode without
 * numbers. Episodes of one show fold into one entry, and an item named twice goes once. With [dated], items carry
 * their `watched_at`; [show] adds the service's own fields to each show entry.
 *
 * `null` when no item is left.
 */
internal fun historyBody(
    items: List<HistoryItem>,
    dated: Boolean,
    show: JsonObjectBuilder.() -> Unit = {},
    ids: (TrackerContext) -> JsonObject?,
): JsonObject? {
    val movies = LinkedHashMap<JsonObject, JsonObject>()
    // Show ids → season → episode number → the episode's item, in first-seen order.
    val shows = LinkedHashMap<JsonObject, LinkedHashMap<Int, LinkedHashMap<Int, JsonObject>>>()
    for ((context, watchedAt) in items) {
        val itemIds = ids(context)?.takeIf { it.isNotEmpty() } ?: continue
        val date = watchedAt?.takeIf { dated }?.toString()
        if (context.isMovie) {
            movies.getOrPut(itemIds) {
                buildJsonObject {
                    put("ids", itemIds)
                    if (date != null) put("watched_at", date)
                }
            }
            continue
        }
        val season = context.season ?: continue
        val number = context.episode ?: continue
        shows.getOrPut(itemIds) { LinkedHashMap() }.getOrPut(season) { LinkedHashMap() }.getOrPut(number) {
            buildJsonObject {
                put("number", number)
                if (date != null) put("watched_at", date)
            }
        }
    }
    if (movies.isEmpty() && shows.isEmpty()) return null
    return buildJsonObject {
        if (movies.isNotEmpty()) put("movies", JsonArray(movies.values.toList()))
        if (shows.isNotEmpty()) put("shows", buildJsonArray {
            for ((showIds, seasons) in shows) add(buildJsonObject {
                put("ids", showIds)
                show()
                put("seasons", buildJsonArray {
                    for ((number, episodes) in seasons) add(buildJsonObject {
                        put("number", number)
                        put("episodes", JsonArray(episodes.values.toList()))
                    })
                })
            })
        })
    }
}

/**
 * The [items] a write's answer lists under `not_found` (Trakt and Simkl echo the ids they were sent): a movie by any of
 * its [ids], an episode by its show's with its season and number, or every episode of a show listed without seasons.
 */
internal fun notFound(answer: JsonObject, items: List<HistoryItem>, ids: (TrackerContext) -> JsonObject?): List<HistoryItem> {
    val notFound = answer["not_found"].obj ?: return emptyList()
    val movies = notFound["movies"].objects
    val shows = notFound["shows"].objects
    if (movies.isEmpty() && shows.isEmpty()) return emptyList()
    return items.filter { (context) ->
        val itemIds = ids(context) ?: return@filter false
        if (context.isMovie) return@filter movies.any { sharesId(it["ids"].obj, itemIds) }
        shows.any { show ->
            if (!sharesId(show["ids"].obj, itemIds)) return@any false
            val seasons = show["seasons"].arr ?: return@any true
            seasons.objects.any { season ->
                season["number"].flexibleInt == context.season && season["episodes"].objects.any { it["number"].flexibleInt == context.episode }
            }
        }
    }
}

/** Both entries carry one id scheme with the same value (a number or a string): they name the same title. */
private fun sharesId(listed: JsonObject?, sent: JsonObject): Boolean =
    listed != null && sent.any { (key, value) -> idValue(value)?.let { it == idValue(listed[key]) } == true }

private fun idValue(value: JsonElement?): String? = (value as? JsonPrimitive)?.takeUnless { it is JsonNull }?.content
