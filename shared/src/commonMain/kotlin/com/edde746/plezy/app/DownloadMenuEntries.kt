package com.edde746.plezy.app

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.queue.fetchAllCollectionItems
import com.edde746.plezy.playback.queue.fetchAllPlaylistItems
import com.edde746.plezy.presentation.browse.MenuEntry
import com.edde746.plezy.presentation.browse.MenuEntryProvider
import com.edde746.plezy.presentation.browse.MenuIcon
import com.edde746.plezy.presentation.browse.MenuMessage
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.browse.MenuSlot
import com.edde746.plezy.presentation.browse.MenuTarget
import com.edde746.plezy.presentation.downloads.DetailDownload
import com.edde746.plezy.presentation.downloads.DownloadMenuEntry
import com.edde746.plezy.presentation.downloads.itemDownloadMenuEntries
import com.edde746.plezy.presentation.downloads.listDownloadMenuEntries

/**
 * The downloads' entries in the item menus: Download, or Manage / Remove sync rule and Delete download, for an item
 * ([MenuSlot.DOWNLOADS]) or a collection or a video or audio playlist ([MenuSlot.LIST_DOWNLOADS], downloading its
 * items). Each runs through [detail], whose questions the downloads' overlays draw. Without the server's client
 * (offline) the downloaded files and sync rules are still managed; only a new download needs it.
 */
internal class DownloadMenuEntries(
    private val controller: DownloadsController,
    private val detail: DetailDownload,
    private val client: (ServerId) -> MediaBackend?,
    override val slot: MenuSlot,
) : MenuEntryProvider {
    override fun entries(target: MenuTarget, place: MenuPlace): List<MenuEntry> {
        val list = target.isList
        if (list != (slot == MenuSlot.LIST_DOWNLOADS)) return emptyList()
        val entries = when (target) {
            is MenuTarget.Playlist -> if (target.playlist.playlistType in DOWNLOADABLE_PLAYLISTS) {
                listDownloadMenuEntries(controller, target.playlist.asItem(), playlist = true)
            } else {
                emptyList()
            }
            is MenuTarget.Item -> if (list) {
                listDownloadMenuEntries(controller, target.item, playlist = false)
            } else {
                itemDownloadMenuEntries(controller, target.item)
            }
        }
        val connected = target.client() != null
        return entries.filter { connected || it !in NEEDS_CLIENT }.map { MenuEntry(it.id, it.label, it.icon, it.destructive) }
    }

    override suspend fun perform(target: MenuTarget, place: MenuPlace, entryId: String): MenuMessage? {
        val entry = DownloadMenuEntry.entries.first { it.id == entryId }
        val client = target.client()
        val feedback = when (target) {
            is MenuTarget.Playlist -> detail.perform(target.playlist.asItem(), entry, client) {
                checkNotNull(client).fetchAllPlaylistItems(target.playlist.id)
            }
            is MenuTarget.Item -> detail.perform(target.item, entry, client) {
                checkNotNull(client).fetchAllCollectionItems(target.item.id, target.item.libraryId, target.item.libraryTitle)
            }
        }
        return feedback?.let { MenuMessage(it.message, it.isError) }
    }

    private val MenuTarget.isList: Boolean
        get() = this is MenuTarget.Playlist || (this is MenuTarget.Item && item.kind == MediaKind.COLLECTION)

    private fun MenuTarget.client(): MediaBackend? = ServerId.tryParse(serverId)?.let(client)

    private val DownloadMenuEntry.icon: MenuIcon
        get() = when (this) {
            DownloadMenuEntry.MANAGE_SYNC -> MenuIcon.SYNC
            DownloadMenuEntry.REMOVE_SYNC -> MenuIcon.SYNC_DISABLED
            DownloadMenuEntry.DELETE_DOWNLOAD, DownloadMenuEntry.DELETE_FOLDER_DOWNLOADS -> MenuIcon.DELETE
            DownloadMenuEntry.MARK_WATCHED -> MenuIcon.WATCHED
            DownloadMenuEntry.MARK_UNWATCHED -> MenuIcon.UNWATCHED
            DownloadMenuEntry.DOWNLOAD, DownloadMenuEntry.DOWNLOAD_COLLECTION, DownloadMenuEntry.DOWNLOAD_PLAYLIST -> MenuIcon.DOWNLOAD
        }
}

/** A playlist as the downloads key it: its sync rule and download folder are the playlist item's. */
private fun MediaPlaylist.asItem() = MediaItem(
    id = id,
    backend = backend,
    kind = MediaKind.PLAYLIST,
    title = title,
    summary = summary,
    thumbPath = displayImagePath,
    serverId = serverId,
    serverName = serverName,
)

/** The playlist types whose items download (a photo playlist's don't). */
private val DOWNLOADABLE_PLAYLISTS = setOf("video", "audio")

/** The entries that start a download, which fetches from the server: offered only while its client is there. */
private val NEEDS_CLIENT = setOf(DownloadMenuEntry.DOWNLOAD, DownloadMenuEntry.DOWNLOAD_COLLECTION, DownloadMenuEntry.DOWNLOAD_PLAYLIST)
