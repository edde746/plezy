package com.edde746.plezy.app

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.session.PlayRequest

/**
 * `--dev-play <server>:<item>` ([DevLaunch.play]): the item [item] of the signed-in server [server].
 *
 * @param server a backend's name (`plex`, `jellyfin`, `emby`: the first signed-in server of that kind) or a server's
 *   id.
 * @param item the item's id (Plex's and Emby's numeric ids, Jellyfin's 32 hex digits), or else a title, searched
 *   for on the server.
 */
data class DevPlay(val server: String, val item: String) {
    /**
     * The play of [item] on the server [server] names among [clients] (the signed-in servers): the item fetched by its
     * id, or the search's first movie, episode or clip titled [item] (any case), else its first one.
     *
     * @throws IllegalStateException when no client is that server, or it has no such item, with the message to show.
     */
    suspend fun resolve(clients: List<MediaBackend>): PlayRequest.Item {
        val client = pickServer(clients.map { it.serverId to it.backend })?.let { id -> clients.first { it.serverId == id } }
            ?: error("--dev-play: no signed-in server is '$server' (signed in: ${clients.joinToString { "${it.backend.id} ${it.serverId}" }.ifEmpty { "none" }})")
        val found = if (looksLikeId(item)) {
            client.fetchItem(item) ?: error("--dev-play: ${client.serverId} has no item $item")
        } else {
            pickTitle(client.searchItems(item)) ?: error("--dev-play: ${client.serverId} has no movie or episode titled '$item'")
        }
        return PlayRequest.Item(client.serverId, found.id, item = found)
    }

    /** The server [server] names among [servers] (each one's id and kind): its id, or the first of its kind; else null. */
    internal fun pickServer(servers: List<Pair<ServerId, BackendKind>>): ServerId? {
        val kind = BackendKind.entries.firstOrNull { it.id == server }
        return if (kind != null) servers.firstOrNull { it.second == kind }?.first else servers.firstOrNull { it.first.value == server }?.first
    }

    /** The search result [item] means: the first playable one titled [item] in any case, else the first playable one. */
    internal fun pickTitle(results: List<MediaItem>): MediaItem? {
        val playable = results.filter { it.kind in PLAYABLE }
        return playable.firstOrNull { it.title.equals(item, ignoreCase = true) } ?: playable.firstOrNull()
    }

    companion object {
        /** `<server>:<item>`, split at the first `:`; both parts needed. */
        fun parse(spec: String): DevPlay {
            val colon = spec.indexOf(':')
            require(colon > 0 && colon < spec.length - 1) { "needs <server>:<item> (plex|jellyfin|emby or a server id, then an item id or title), got '$spec'" }
            return DevPlay(spec.substring(0, colon), spec.substring(colon + 1))
        }

        /** Whether [item] is an item id rather than a title: all digits (Plex, Emby) or 32 hex digits (Jellyfin). */
        internal fun looksLikeId(item: String): Boolean =
            item.all { it.isDigit() } || (item.length == 32 && item.all { it.isDigit() || it.lowercaseChar() in 'a'..'f' })

        private val PLAYABLE = setOf(MediaKind.MOVIE, MediaKind.EPISODE, MediaKind.CLIP)
    }
}
