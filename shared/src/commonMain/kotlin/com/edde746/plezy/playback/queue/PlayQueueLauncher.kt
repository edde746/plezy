package com.edde746.plezy.playback.queue

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.jellyfin.EmptyPlayQueueException
import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.jellyfin.JellyfinSequentialLauncher
import com.edde746.plezy.jellyfin.LocalQueueLaunch
import com.edde746.plezy.model.LocalPlayQueue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.buildFolderUri
import com.edde746.plezy.plex.createPlayQueue
import com.edde746.plezy.plex.createShowPlayQueue
import com.edde746.plezy.plex.getPlayQueue
import com.edde746.plezy.servers.OnlineServers
import com.edde746.plezy.servers.PlaybackStateStore
import com.edde746.plezy.servers.PlayQueueWindowFetcher
import com.edde746.plezy.servers.ServerPlayQueue
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope

/**
 * Starts playback of a whole list: a collection, a playlist, a folder, a shuffled show or season, a shuffled library.
 * Each launch builds the queue on the item's server, publishes it to [playbackState] and hands its first (or chosen)
 * item to [play]; the returned [PlayQueueLaunch] carries the loading dialog's title, its cancellation and the result.
 *
 * Plex builds the queue on the server (`/playQueues`), published with a fetcher of 50-item windows around the playing
 * entry. Jellyfin and Emby have no server queue: [mediaBrowserQueues] fetches the items and builds the queue here.
 *
 * A shuffled launch with `shuffle_starts_from_beginning` on ([shuffleStartsFromBeginning]) plays its first item from
 * the start, without resolving its watch state again ([play]'s `resolveWatchState` false): an external player reads the
 * item's resume offset itself. For a server queue only the launched item loses its offset, the queue keeps it; a local
 * queue holds the launched item itself, so it holds the stripped copy.
 */
class PlayQueueLauncher(
    private val scope: CoroutineScope,
    private val servers: OnlineServers,
    private val playbackState: PlaybackStateStore,
    private val shuffleStartsFromBeginning: suspend () -> Boolean,
    private val play: suspend (item: MediaItem, resolveWatchState: Boolean) -> Unit,
    private val mediaBrowserQueues: (MediaBackend) -> JellyfinSequentialLauncher? = { (it as? JellyfinClient)?.let(::JellyfinSequentialLauncher) },
) {
    /**
     * Plays a collection, shuffled or in order; [startItem] starts an in-order launch at that item instead of the
     * first. Plex: the server queue of `/library/collections/{id}`, with the collection's library.
     */
    fun launchCollection(collection: MediaItem, shuffle: Boolean, startItem: MediaItem? = null): PlayQueueLaunch {
        val title = titleFor(shuffle)
        if (collection.kind != MediaKind.COLLECTION) return failed(title, IllegalArgumentException("Item must be either a collection or playlist"))
        if (collection.backend.usesMediaBrowserApi) {
            return launchLocal(title, collection.serverId, collection.id) { it.buildCollectionQueue(collection, shuffle, startItem) }
        }
        return launchPlex(title, collection.serverId, fallback = true) { client ->
            val selectedKey = selectedKey(shuffle, startItem)
            val created = client.createPlayQueue(
                uri = client.buildFolderUri("/library/collections/${collection.id}"),
                type = VIDEO,
                key = selectedKey,
                shuffle = shuffle.flag,
                librarySectionId = collection.libraryId,
                librarySectionTitle = collection.libraryTitle,
            )
            val queue = client.refetchIfEmpty(created, collection.libraryId, collection.libraryTitle)
            publishAndPlay(
                client, queue, collection.id, shuffle, collection.libraryId, collection.libraryTitle,
                selected = if (selectedKey != null) queue.selectedItem else null,
            )
        }
    }

    /** Plays a playlist, shuffled or in order; [startItem] starts an in-order launch at that item instead of the first. */
    fun launchPlaylist(playlist: MediaPlaylist, shuffle: Boolean, startItem: MediaItem? = null): PlayQueueLaunch {
        val title = titleFor(shuffle)
        if (playlist.backend.usesMediaBrowserApi) {
            return launchLocal(title, playlist.serverId, playlist.id) { it.buildPlaylistQueue(playlist, shuffle, startItem) }
        }
        return launchPlex(title, playlist.serverId, fallback = true) { client ->
            val selectedKey = selectedKey(shuffle, startItem)
            val created = client.createPlayQueue(playlistId = playlist.id.toInt(), type = VIDEO, key = selectedKey, shuffle = shuffle.flag)
            val queue = client.refetchIfEmpty(created, null, null)
            publishAndPlay(client, queue, playlist.id, shuffle, null, null, selected = if (selectedKey != null) queue.selectedItem else null)
        }
    }

    /**
     * Plays a show's episodes shuffled; a season shuffles its whole show. The item played gets the show's server and
     * library.
     */
    fun launchShuffledShow(metadata: MediaItem): PlayQueueLaunch {
        val title = T.common.shuffle
        if (metadata.kind != MediaKind.SHOW && metadata.kind != MediaKind.SEASON) {
            return failed(title, IllegalArgumentException("Shuffle play only works for shows and seasons"))
        }
        if (metadata.backend.usesMediaBrowserApi) {
            val seriesId = if (metadata.kind == MediaKind.SHOW) metadata.id else metadata.parentId
            return launchLocal(title, metadata.serverId, seriesId.orEmpty()) { it.buildShuffledShowQueue(metadata) }
        }
        return launchPlex(title, metadata.serverId, fallback = true) { client ->
            val showKey = if (metadata.kind == MediaKind.SHOW) metadata.id else metadata.parentId ?: throw IllegalStateException("Season is missing parentRatingKey")
            val queue = client.createShowPlayQueue(
                showRatingKey = showKey,
                shuffle = 1,
                librarySectionId = metadata.libraryId,
                librarySectionTitle = metadata.libraryTitle,
            )
            publishAndPlay(
                client, queue, showKey, shuffle = true, metadata.libraryId, metadata.libraryTitle,
                stampServer = metadata.serverId ?: client.serverId.value, stampServerName = metadata.serverName,
            )
        }
    }

    /** Plays a folder row of a library's folder view, shuffled or in order. Plex: the server queue of its folder key. */
    fun launchFolder(folder: MediaItem, shuffle: Boolean): PlayQueueLaunch {
        val title = titleFor(shuffle)
        if (folder.backend.usesMediaBrowserApi) {
            return launchLocal(title, folder.serverId, folder.id) { it.buildFolderQueue(folder, shuffle) }
        }
        val folderKey = folder.backendFolderKey ?: return failed(title, IllegalArgumentException("Folder is missing its backend folder key"))
        return launchPlex(title, folder.serverId, fallback = true) { client ->
            val created = client.createPlayQueue(
                uri = client.buildFolderUri(folderKey),
                type = VIDEO,
                shuffle = shuffle.flag,
                librarySectionId = folder.libraryId,
                librarySectionTitle = folder.libraryTitle,
            )
            val queue = client.refetchIfEmpty(created, folder.libraryId, folder.libraryTitle)
            publishAndPlay(client, queue, folderKey, shuffle, folder.libraryId, folder.libraryTitle)
        }
    }

    /**
     * Plays the videos of [library] shuffled, through its own server only: a section id means nothing on another one.
     * Plex queues the whole section (the server expands shows to their episodes); Jellyfin and Emby draw
     * [JellyfinSequentialLauncher.LIBRARY_SHUFFLE_QUEUE_SIZE] random videos.
     */
    fun launchShuffledLibrary(library: MediaLibrary): PlayQueueLaunch {
        val title = T.common.shuffle
        if (library.backend.usesMediaBrowserApi) {
            return launchLocal(title, library.serverId, library.id) { it.buildShuffledLibraryQueue(library) }
        }
        return launchPlex(title, library.serverId, fallback = false) { client ->
            val created = client.createPlayQueue(
                uri = client.buildFolderUri("/library/sections/${library.id}/all"),
                type = VIDEO,
                shuffle = 1,
                librarySectionId = library.id,
                librarySectionTitle = library.title,
            )
            val queue = client.refetchIfEmpty(created, library.id, library.title)
            publishAndPlay(client, queue, library.id, shuffle = true, library.id, library.title)
        }
    }

    /**
     * A Plex launch through the client of [serverId]; with [fallback], the first online Plex server's when that one
     * isn't there. No Plex server at all fails the launch with "No client available".
     */
    private fun launchPlex(title: String, serverId: String?, fallback: Boolean, work: suspend PlayQueueLaunch.(PlexClient) -> PlayQueueResult) =
        PlayQueueLaunch(title, scope) {
            val own = ServerId.tryParse(serverId)?.let(servers::client) as? PlexClient
            val client = own ?: servers.onlineClients.values.takeIf { fallback }?.firstNotNullOfOrNull { it as? PlexClient }
            if (client == null) PlayQueueResult.Error(IllegalStateException("No Plex client for server $serverId"), T.errors.noClientAvailable) else work(client)
        }

    /** Creation can answer a queue without its items: it is read again by id, kept when that one has items. */
    private suspend fun PlexClient.refetchIfEmpty(queue: ServerPlayQueue, libraryId: String?, libraryTitle: String?): ServerPlayQueue {
        if (!queue.items.isNullOrEmpty()) return queue
        val fetched = getPlayQueue(queue.id, librarySectionId = libraryId, librarySectionTitle = libraryTitle)
        return if (fetched != null && !fetched.items.isNullOrEmpty()) fetched else queue
    }

    /**
     * Publishes the server [queue] (with its window fetcher) under [contextKey], then plays [selected] or its first item.
     * [stampServer] puts that server, [stampServerName] and the queue's library on the item played.
     */
    private suspend fun PlayQueueLaunch.publishAndPlay(
        client: PlexClient,
        queue: ServerPlayQueue?,
        contextKey: String,
        shuffle: Boolean,
        libraryId: String?,
        libraryTitle: String?,
        selected: MediaItem? = null,
        stampServer: String? = null,
        stampServerName: String? = null,
    ): PlayQueueResult {
        val items = queue?.items
        if (items.isNullOrEmpty()) return PlayQueueResult.Empty
        finishLoading()
        playbackState.setPlayQueueWindowFetcher(client.playQueueWindows(libraryId, libraryTitle))
        playbackState.setPlaybackFromPlayQueue(queue, contextKey)
        var item = selected ?: items.first()
        if (stampServer != null) {
            item = item.copy(
                serverId = stampServer,
                serverName = stampServerName ?: item.serverName,
                libraryId = item.libraryId ?: libraryId,
                libraryTitle = item.libraryTitle ?: libraryTitle,
            )
        }
        val fromStart = shuffle && (item.viewOffsetMs ?: 0) > 0 && shuffleStartsFromBeginning()
        if (fromStart) item = item.copy(viewOffsetMs = 0)
        play(item, !fromStart)
        return PlayQueueResult.Success
    }

    /**
     * A Jellyfin or Emby launch: [build] fetches the items of [serverId]'s client and builds the local queue, published
     * under [contextKey] (the list's own id, a shuffled show's series id).
     */
    private fun launchLocal(title: String, serverId: String?, contextKey: String, build: suspend (JellyfinSequentialLauncher) -> LocalQueueLaunch) =
        PlayQueueLaunch(title, scope) {
            val id = ServerId.tryParse(serverId) ?: throw IllegalArgumentException("Item is missing serverId")
            val queues = servers.client(id)?.let(mediaBrowserQueues)
            if (queues == null) {
                PlayQueueResult.Error(IllegalStateException("No client for server $serverId"), T.errors.noClientAvailable)
            } else {
                val built = try {
                    build(queues)
                } catch (e: EmptyPlayQueueException) {
                    null
                }
                if (built == null) PlayQueueResult.Empty else playLocalQueue(built.queue, contextKey)
            }
        }

    /**
     * Publishes the client-side [queue] and plays its current item, as it is: the items were fetched in this launch, so
     * their watch state is fresh. A current index outside the queue fails the launch.
     */
    private suspend fun PlayQueueLaunch.playLocalQueue(queue: LocalPlayQueue, contextKey: String): PlayQueueResult {
        if (queue.items.isEmpty()) return PlayQueueResult.Empty
        val index = queue.currentIndex ?: 0
        if (index !in queue.items.indices) throw IndexOutOfBoundsException("currentIndex $index outside a queue of ${queue.items.size}")
        finishLoading()
        var item = queue.items[index]
        var published = queue
        if (queue.shuffled && (item.viewOffsetMs ?: 0) > 0 && shuffleStartsFromBeginning()) {
            item = item.copy(viewOffsetMs = 0)
            published = queue.copy(items = queue.items.toMutableList().also { it[index] = item })
        }
        playbackState.setPlaybackFromLocalQueue(published, contextKey)
        play(item, false)
        return PlayQueueResult.Success
    }

    private fun failed(title: String, error: Exception) = PlayQueueLaunch(title, scope) { throw error }

    private fun titleFor(shuffle: Boolean) = if (shuffle) T.common.shuffle else T.common.play

    private fun selectedKey(shuffle: Boolean, startItem: MediaItem?) = if (!shuffle && startItem != null) "/library/metadata/${startItem.id}" else null

    private val Boolean.flag: Int get() = if (this) 1 else 0

    private val ServerPlayQueue.selectedItem: MediaItem?
        get() = selectedItemId?.let { id -> items?.firstOrNull { it.playQueueItemId == id } }
}

private const val VIDEO = "video"

/** Windows of 50 entries around the playing one of a Plex queue, read with the queue's library. */
internal fun PlexClient.playQueueWindows(libraryId: String?, libraryTitle: String?) = PlayQueueWindowFetcher { id, center, window ->
    getPlayQueue(id, center = center, window = window, librarySectionId = libraryId, librarySectionTitle = libraryTitle)
}
