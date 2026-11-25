package com.edde746.plezy.presentation.detail

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.net.UriComponent
import kotlinx.coroutines.CancellationException

/**
 * A `plezy://play` link to an item: by its server and id ([serverItemLink]), or by catalogue identity for a movie or
 * show ([linkForItem]), which any server holding the title opens.
 */
data class ItemLink(val params: List<Pair<String, String>>) {
    /** The link naming [profile] (a profile id, Plex Home UUID or name), which the app switches to first. */
    fun asProfile(profile: String?): String =
        "plezy://play?" + UriComponent.encodeQuery(if (profile == null) params else params + ("profile" to profile))

    override fun toString(): String = asProfile(null)
}

/** The link that plays [item] from its own server; null for an item that is not a movie, show or episode of a server. */
fun serverItemLink(item: MediaItem): ItemLink? {
    val serverId = ServerId.tryParse(item.serverId) ?: return null
    if (item.id.isBlank()) return null
    return when (item.kind) {
        MediaKind.MOVIE, MediaKind.SHOW, MediaKind.EPISODE -> ItemLink(listOf("server" to serverId.value, "id" to item.id))
        else -> null
    }
}

/**
 * The link to share for [item]: a movie or show by one catalogue id (movies TMDB, then IMDb, then TVDB; shows TVDB,
 * then TMDB, then IMDb) and its Plex GUID hash when it has one, so the link survives the item moving servers; else, or
 * when the ids cannot be fetched, [serverItemLink]. Null when [item] cannot be linked.
 */
suspend fun linkForItem(client: MediaBackend, item: MediaItem): ItemLink? {
    val itemLink = serverItemLink(item) ?: return null
    val kind = item.kind
    if (kind != MediaKind.MOVIE && kind != MediaKind.SHOW) return itemLink
    val ids = try {
        client.fetchExternalIds(item.id)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "external ids unavailable for ${item.id}" }
        ExternalIds()
    }
    val catalog = catalogParam(kind, ids)
    val plexHash = plexHashOf(kind, item.guid)
    if (catalog == null && plexHash == null) return itemLink
    return ItemLink(listOfNotNull("type" to kind.id, catalog, plexHash?.let { "plex" to it }))
}

private fun catalogParam(kind: MediaKind, ids: ExternalIds): Pair<String, String>? {
    val tmdb = ids.tmdb?.takeIf { it > 0 }?.let { "tmdb" to it.toString() }
    val tvdb = ids.tvdb?.takeIf { it > 0 }?.let { "tvdb" to it.toString() }
    val imdb = ids.imdb?.trim()?.lowercase()?.takeIf { IMDB_ID.matches(it) }?.let { "imdb" to it }
    return if (kind == MediaKind.MOVIE) tmdb ?: imdb ?: tvdb else tvdb ?: tmdb ?: imdb
}

private fun plexHashOf(kind: MediaKind, guid: String?): String? {
    val prefix = "plex://${kind.id}/"
    if (guid == null || !guid.startsWith(prefix)) return null
    return guid.removePrefix(prefix).takeIf { PLEX_HASH.matches(it) }
}

private val IMDB_ID = Regex("^tt\\d+$")
private val PLEX_HASH = Regex("^[0-9a-zA-Z]+$")
private const val TAG = "ItemLink"
