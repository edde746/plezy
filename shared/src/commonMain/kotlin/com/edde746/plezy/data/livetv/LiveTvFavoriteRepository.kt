package com.edde746.plezy.data.livetv

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.db.Live_tv_favorite
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** A favourite Live TV channel: the channel [id] on its [source], with what the picker shows of it. */
data class FavoriteChannel(
    val source: String,
    val id: String,
    val title: String? = null,
    val thumb: String? = null,
    /** The virtual channel number. */
    val vcn: String? = null,
)

/** A Jellyfin or Emby connection's favourite Live TV channels, in the user's order. */
class LiveTvFavoriteRepository internal constructor(private val db: Db) {
    /** The favourites of [connectionId] (`"{machineId}/{userId}"`), in order. */
    suspend fun favorites(connectionId: String): List<FavoriteChannel> =
        db.read { liveTvFavoriteQueries.selectForConnection(connectionId).executeAsList() }.map { it.toModel() }

    /**
     * Replaces the favourites of [connectionId] with [channels], in their order. A channel listed twice (same source
     * and id) keeps its first place.
     */
    suspend fun replace(connectionId: String, channels: List<FavoriteChannel>) {
        db.write {
            q.liveTvFavoriteQueries.deleteForConnection(connectionId)
            channels.distinctBy { it.source to it.id }.forEachIndexed { position, channel ->
                q.liveTvFavoriteQueries.insertRow(
                    Live_tv_favorite(
                        connection_id = connectionId,
                        position = position.toLong(),
                        source = channel.source,
                        channel_id = channel.id,
                        title = channel.title,
                        thumb = channel.thumb,
                        vcn = channel.vcn,
                    ),
                )
            }
        }
    }

    /** Drops every connection's favourites (a full sign-out). */
    suspend fun clearAll() {
        db.write { q.liveTvFavoriteQueries.deleteAll() }
    }
}

/**
 * The favourite channels in [json], the list Plezy's earlier releases stored per connection: an array of objects
 * `{"source", "id", "title"?, "thumb"?, "vcn"?}`. An empty string is no favourites; a missing source or id reads as
 * empty, and an `id`-less entry falls back to `key`. Throws [IllegalArgumentException] (a
 * [kotlinx.serialization.SerializationException] for text that isn't JSON) when it isn't such a list.
 */
fun parseFavoriteChannelList(json: String): List<FavoriteChannel> {
    if (json.isEmpty()) return emptyList()
    val array = Json.parseToJsonElement(json) as? JsonArray ?: throw IllegalArgumentException("Invalid favorite channel list")
    return array.map { entry ->
        val channel = entry as? JsonObject ?: throw IllegalArgumentException("Invalid favorite channel list")
        FavoriteChannel(
            source = channel.text("source") ?: "",
            id = channel.text("id") ?: channel.text("key") ?: "",
            title = channel.text("title"),
            thumb = channel.text("thumb"),
            vcn = channel.text("vcn"),
        )
    }
}

/** The string field [name]; null when absent or null. Any other value throws. */
private fun JsonObject.text(name: String): String? = when (val value = get(name)) {
    null, JsonNull -> null
    is JsonPrimitive -> if (value.isString) value.content else throw IllegalArgumentException("Favorite channel '$name' isn't a string")
    else -> throw IllegalArgumentException("Favorite channel '$name' isn't a string")
}

private fun Live_tv_favorite.toModel() = FavoriteChannel(source = source, id = channel_id, title = title, thumb = thumb, vcn = vcn)
