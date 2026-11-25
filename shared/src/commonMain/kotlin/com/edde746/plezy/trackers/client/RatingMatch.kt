package com.edde746.plezy.trackers.client

import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The `/sync/ratings` helpers Trakt and MDBList share, and the id matching Simkl reuses: each service answers a whole
 * list of the user's ratings, which is scanned for the item. Scores are 1–10 on all three, the app's own scale.
 */
internal object RatingMatch {
    /** The `/sync/ratings/<list>` name for [kind]. */
    fun listName(kind: RatingKind): String = when (kind) {
        RatingKind.MOVIE -> "movies"
        RatingKind.SHOW -> "shows"
        RatingKind.SEASON -> "seasons"
        RatingKind.EPISODE -> "episodes"
    }

    /**
     * Whether a ratings [entry] is about [target], whose ids are [localIds]. Season and episode rows may carry their
     * show inline (`season.show` / `episode.show`) instead of as a sibling `show`; the inline form wins.
     */
    fun entryMatches(target: RatingTarget, entry: JsonObject, localIds: JsonObject): Boolean {
        val show = entry["show"]
        return when (target.kind) {
            RatingKind.MOVIE -> idsMatch(nestedIds(entry["movie"]), localIds)
            RatingKind.SHOW -> idsMatch(nestedIds(show), localIds)
            RatingKind.SEASON ->
                idsMatch(nestedIds(entry["season"].obj?.get("show") ?: show), localIds) &&
                    entry["season"].obj?.get("number").flexibleInt.let { it != null && it == target.season }
            RatingKind.EPISODE -> {
                val episode = entry["episode"].obj
                idsMatch(nestedIds(episode?.get("show") ?: show), localIds) &&
                    episode?.get("number").flexibleInt.let { it != null && it == target.episode } &&
                    episode?.get("season").flexibleInt.let { it != null && it == target.season }
            }
        }
    }

    /**
     * The `/sync/ratings` (add) or `/sync/ratings/remove` body for [target] under [ids]; no [rating] makes a removal.
     * Seasons and episodes nest under their show.
     */
    fun body(target: RatingTarget, ids: JsonObject, rating: Int? = null): JsonObject {
        fun item(extra: Map<String, JsonElement> = emptyMap()) = JsonObject(buildMap {
            put("ids", ids)
            putAll(extra)
            if (rating != null) put("rating", JsonPrimitive(rating))
        })
        return when (target.kind) {
            RatingKind.MOVIE -> buildJsonObject { put("movies", JsonArray(listOf(item()))) }
            RatingKind.SHOW -> buildJsonObject { put("shows", JsonArray(listOf(item()))) }
            RatingKind.SEASON -> buildJsonObject {
                put("shows", buildJsonArray {
                    add(buildJsonObject {
                        put("ids", ids)
                        put("seasons", buildJsonArray {
                            add(buildJsonObject {
                                putIfNotNull("number", target.season)
                                putIfNotNull("rating", rating)
                            })
                        })
                    })
                })
            }
            RatingKind.EPISODE -> buildJsonObject {
                put("shows", buildJsonArray {
                    add(buildJsonObject {
                        put("ids", ids)
                        put("seasons", buildJsonArray {
                            add(buildJsonObject {
                                putIfNotNull("number", target.season)
                                put("episodes", buildJsonArray {
                                    add(buildJsonObject {
                                        putIfNotNull("number", target.episode)
                                        putIfNotNull("rating", rating)
                                    })
                                })
                            })
                        })
                    })
                })
            }
        }
    }

    /** The `ids` object of a rating entry's media node (`movie`, `show`). */
    fun nestedIds(value: JsonElement?): JsonObject? = value.obj?.get("ids").obj

    /** Whether any local id equals the remote one of the same name, as a string or as a number. */
    fun idsMatch(remote: JsonObject?, local: JsonObject): Boolean {
        if (remote == null) return false
        for ((key, localValue) in local) {
            val remoteValue = remote[key] ?: continue
            val localString = localValue.string
            if (localString != null && (remoteValue as? JsonPrimitive)?.content == localString) return true
            val localNumber = localValue.flexibleLong
            if (localNumber != null && remoteValue.flexibleLong == localNumber) return true
        }
        return false
    }

    /** A remote score as the app's 1–10, or `null` for none (0 or absent). */
    fun score(value: JsonElement?): Int? = value.flexibleInt?.takeIf { it > 0 }?.coerceIn(1, 10)
}
