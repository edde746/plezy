package com.edde746.plezy.app

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.playlistRoute

/**
 * `--dev-playlist <server>:<playlist>` ([DevLaunch.playlist]): the playlist [playlist] of the signed-in server [server],
 * whose screen the session opens.
 *
 * @param server as [DevPlay]'s: a backend's name (the first signed-in server of that kind) or a server's id.
 * @param playlist the playlist's id, or else its title (any case), among the server's video and audio playlists.
 */
data class DevPlaylist(val server: String, val playlist: String) {
    /**
     * The screen of [playlist] on the server [server] names among [clients] (the signed-in servers): an audio playlist's
     * music page, another's playlist screen ([playlistRoute]).
     *
     * @throws IllegalStateException when no client is that server, or it has no such playlist, with the message to show.
     */
    suspend fun resolve(clients: List<MediaBackend>): Route {
        val serverId = DevPlay(server, playlist).pickServer(clients.map { it.serverId to it.backend })
        val client = clients.firstOrNull { it.serverId == serverId }
            ?: error("--dev-playlist: no signed-in server is '$server' (signed in: ${clients.joinToString { "${it.backend.id} ${it.serverId}" }.ifEmpty { "none" }})")
        val playlists = listOf("video", "audio").flatMap { client.fetchPlaylistsPage(playlistType = it).items }
        val found = playlists.firstOrNull { it.id == playlist } ?: playlists.firstOrNull { it.title.equals(playlist, ignoreCase = true) }
            ?: error("--dev-playlist: ${client.serverId} has no playlist '$playlist' (it has: ${playlists.joinToString { it.title }.ifEmpty { "none" }})")
        return playlistRoute(client.serverId, found.id, found.playlistType)
    }

    companion object {
        /** `<server>:<playlist>`, split at the first `:`; both parts needed. */
        fun parse(spec: String): DevPlaylist {
            val colon = spec.indexOf(':')
            require(colon > 0 && colon < spec.length - 1) { "needs <server>:<playlist> (plex|jellyfin|emby or a server id, then a playlist id or title), got '$spec'" }
            return DevPlaylist(spec.substring(0, colon), spec.substring(colon + 1))
        }
    }
}
