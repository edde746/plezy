package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.presentation.downloads.DetailDownload
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.downloads.DownloadMenuEntry
import com.edde746.plezy.presentation.downloads.downloadButtonSpec
import com.edde746.plezy.presentation.downloads.listDownloadMenuEntries
import kotlinx.coroutines.flow.StateFlow

/**
 * What the music screens read of the downloads: offline, an album's and an artist's downloaded tracks, the album's
 * Download button and a playlist's download actions. Absent where the device has no downloads (Apple TV).
 */
interface MusicDownloads {
    /** Ticks on every downloads change (the button's state, newly completed tracks). */
    val changes: StateFlow<Long>

    /** The stored metadata of a downloaded item ([MediaItem.globalKey]), or null. */
    fun item(globalKey: String): MediaItem?

    /** [albumGlobalKey]'s completed tracks, in disc and track order. */
    fun albumTracks(albumGlobalKey: String): List<MediaItem>

    /** The completed tracks of [artistId] on [serverId]. */
    fun artistTracks(serverId: String, artistId: String): List<MediaItem>

    /** [item]'s stored artwork (a local file), or null. */
    fun artwork(item: MediaItem): String?

    /** The album Download button's state. */
    fun buttonSpec(item: MediaItem): DownloadButtonSpec

    /** A press of the Download button: queues, deletes (after asking), resumes…; the feedback to show, if any. */
    suspend fun press(item: MediaItem, client: MediaBackend): DownloadFeedback?

    /**
     * The download actions of [playlist] (a [com.edde746.plezy.model.MediaKind.PLAYLIST] item): Download, or with a
     * sync rule Manage and Remove it; none where sync rules aren't supported.
     */
    fun playlistActions(playlist: MediaItem): List<DownloadMenuEntry>

    /**
     * One of [playlistActions] pressed: Download asks what to download (all or unwatched, once or kept synced) and
     * queues [tracks]' result; the feedback to show, if any.
     */
    suspend fun performPlaylist(playlist: MediaItem, action: DownloadMenuEntry, client: MediaBackend, tracks: suspend () -> List<MediaItem>): DownloadFeedback?
}

/** [MusicDownloads] over the app's downloads [controller] and its detail button's flow [detail]. */
class ControllerMusicDownloads(private val controller: DownloadsController, private val detail: DetailDownload) : MusicDownloads {
    override val changes: StateFlow<Long> get() = controller.changes

    override fun item(globalKey: String): MediaItem? = controller.getMetadata(globalKey)

    override fun albumTracks(albumGlobalKey: String): List<MediaItem> = controller.getDownloadedTracksForAlbum(albumGlobalKey)

    override fun artistTracks(serverId: String, artistId: String): List<MediaItem> =
        controller.downloadedTracks.filter { it.serverId == serverId && it.grandparentId == artistId }

    override fun artwork(item: MediaItem): String? =
        ServerId.tryParse(item.serverId)?.let { controller.getArtworkLocalPath(it, item.thumbPath) }
            ?: controller.getArtworkPath(item.globalKey)

    override fun buttonSpec(item: MediaItem): DownloadButtonSpec = downloadButtonSpec(controller, item)

    override suspend fun press(item: MediaItem, client: MediaBackend): DownloadFeedback? = detail.press(item, client)

    override fun playlistActions(playlist: MediaItem): List<DownloadMenuEntry> = listDownloadMenuEntries(controller, playlist, playlist = true)

    override suspend fun performPlaylist(
        playlist: MediaItem,
        action: DownloadMenuEntry,
        client: MediaBackend,
        tracks: suspend () -> List<MediaItem>,
    ): DownloadFeedback? = detail.perform(playlist, action, client, tracks)
}

/** The global key of [id] on [serverId], as [MediaItem.globalKey] makes it. */
internal fun musicGlobalKey(serverId: String, id: String): String = ServerId.tryParse(serverId)?.let { buildGlobalKey(it, id) } ?: id
