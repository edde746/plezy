package com.edde746.plezy.jellyfin

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.strings.T
import kotlinx.serialization.json.JsonObject

/** Playlists: both dialects treat them as items, with their own item and entry routes. */
internal class JellyfinPlaylists(
    private val core: JellyfinCore,
    private val fetchItem: suspend (String) -> MediaItem?,
) {
    /**
     * No smart playlists exist. On Jellyfin the requested type filters through `MediaTypes`; Emby answers that
     * filter with the whole item index and never types a playlist, so it lists every playlist and the requested type
     * only labels them.
     */
    suspend fun fetchPlaylistsPage(playlistType: String = "video", smart: Boolean? = null, start: Int? = null, size: Int? = null): LibraryPage<MediaPlaylist> {
        val offset = start ?: 0
        if (smart == true) return LibraryPage(emptyList(), 0, offset)
        val pageSize = size ?: PLAYLISTS_PAGE_SIZE
        val requestedType = playlistType.lowercase()
        val mediaType = when (requestedType) {
            "" -> null
            "video" -> "Video"
            "audio" -> "Audio"
            "photo" -> "Photo"
            "book" -> "Book"
            "unknown" -> "Unknown"
            else -> return LibraryPage(emptyList(), 0, offset)
        }
        val labelType = requestedType.ifEmpty { "video" }
        val response = core.get(
            "/Items",
            listOf(
                "userId" to core.userId,
                "IncludeItemTypes" to "Playlist",
                "Recursive" to "true",
                "MediaTypes" to mediaType.takeIf { core.dialect.playlistsFilterByMediaType },
                "StartIndex" to offset.toString(),
                "Limit" to pageSize.toString(),
                // Emby keeps a playlist's timestamp in DateModified and its list route returns only named fields.
                "Fields" to "Overview,DateCreated,DateLastSaved,DateModified,ChildCount,Tags",
            ) + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        return core.pagedItems(response.data, offset, pageSize) { rows -> rows.map { playlist(it, labelType) } }
    }

    /**
     * The playlist, typed by its first entry: a track's playlist is music (`audio`), an empty one video. Emby never
     * types a playlist.
     */
    suspend fun fetchPlaylistMetadata(id: String): MediaPlaylist? {
        val item = fetchItem(id) ?: return null
        val first = fetchPlaylistPage(id, start = 0, size = 1).items.firstOrNull()
        return MediaPlaylist(
            id = item.id,
            backend = core.dialect.backend,
            title = item.title ?: T.playlists.playlist,
            summary = item.summary,
            playlistType = when {
                first?.kind?.isMusic == true -> "audio"
                first?.kind == MediaKind.PHOTO -> "photo"
                else -> "video"
            },
            durationMs = item.durationMs,
            leafCount = item.leafCount,
            thumbPath = item.thumbPath,
            addedAt = item.addedAt,
            updatedAt = item.updatedAt,
            serverId = core.serverId,
            serverName = core.connection.serverName,
        )
    }

    suspend fun fetchPlaylistPage(id: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem> {
        val offset = start ?: 0
        val pageSize = size ?: 100
        val response = core.get(
            "/Playlists/${JellyfinCore.segment(id)}/Items",
            listOf(
                "userId" to core.userId,
                "StartIndex" to offset.toString(),
                "Limit" to pageSize.toString(),
                "Fields" to core.browseFields,
            ) + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        return core.pagedItems(response.data, offset, pageSize, map = core::mapItems)
    }

    /** `MediaType` fixes the playlist's kind server-side: Audio when the first seed is music, else Video. */
    suspend fun createPlaylist(title: String, items: List<MediaItem>): MediaPlaylist? {
        val isMusic = items.firstOrNull()?.kind?.isMusic == true
        val response = core.post(
            "/Playlists",
            listOf(
                "Name" to title,
                "Ids" to items.joinToString(",") { it.id },
                "UserId" to core.userId,
                "MediaType" to if (isMusic) "Audio" else "Video",
            ),
        ).throwIfError()
        val newId = response.obj?.str("Id")?.ifEmpty { null } ?: return null
        return fetchPlaylistMetadata(newId)
    }

    suspend fun addToPlaylist(playlistId: String, items: List<MediaItem>): Boolean {
        if (items.isEmpty()) return true
        core.post(
            "/Playlists/${JellyfinCore.segment(playlistId)}/Items",
            listOf("Ids" to items.joinToString(",") { it.id }, "UserId" to core.userId),
        ).throwIfError()
        return true
    }

    suspend fun deletePlaylist(playlist: MediaPlaylist): Boolean {
        core.delete("/Items/${JellyfinCore.segment(playlist.id)}").throwIfError()
        return true
    }

    /** The move route takes an absolute index, so [afterItem] is unused. */
    suspend fun movePlaylistItem(playlistId: String, item: MediaItem, newIndex: Int, afterItem: MediaItem?): Boolean {
        val entryId = entryId(item, "movePlaylistItem") ?: return false
        core.post("/Playlists/${JellyfinCore.segment(playlistId)}/Items/${JellyfinCore.segment(entryId)}/Move/$newIndex").throwIfError()
        return true
    }

    suspend fun removeFromPlaylist(playlistId: String, item: MediaItem): Boolean {
        val entryId = entryId(item, "removeFromPlaylist") ?: return false
        core.delete("/Playlists/${JellyfinCore.segment(playlistId)}/Items", listOf("entryIds" to entryId)).throwIfError()
        return true
    }

    /** The entry id, or null (logged without the item's title or id) when the item can't address a playlist entry. */
    private fun entryId(item: MediaItem, operation: String): String? {
        if (item.backend.dialect == null) {
            Log.e(TAG) { "Jellyfin $operation failed: item is from another backend" }
            return null
        }
        val entryId = item.playlistItemId
        if (entryId == null) Log.e(TAG) { "Jellyfin $operation failed: missing playlist entry ID" }
        return entryId
    }

    /** [labelType] stands in for `MediaType`, which Emby never sets on a playlist. */
    private fun playlist(json: JsonObject, labelType: String): MediaPlaylist {
        val id = json.str("Id") ?: ""
        val primaryTag = json.obj("ImageTags")?.str("Primary")
        return MediaPlaylist(
            id = id,
            backend = core.dialect.backend,
            title = json.str("Name") ?: T.playlists.playlist,
            summary = json.str("Overview"),
            playlistType = json.str("MediaType")?.lowercase() ?: labelType,
            leafCount = json.int("ChildCount"),
            addedAt = JellyfinTime.isoToEpochSeconds(json.str("DateCreated")),
            updatedAt = JellyfinTime.isoToEpochSeconds(json.str("DateLastSaved") ?: json.str("DateModified")),
            thumbPath = primaryTag?.let { core.absolutizer.absolutize(JellyfinMappers.itemImagePath(id, "Primary", it)) },
            serverId = core.serverId,
            serverName = core.connection.serverName,
        )
    }

    private companion object {
        const val TAG = "JellyfinPlaylists"
        const val PLAYLISTS_PAGE_SIZE = 200
    }
}
