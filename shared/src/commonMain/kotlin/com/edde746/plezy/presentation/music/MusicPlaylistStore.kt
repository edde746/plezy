package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.backend.localizedLoadErrorMessage
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.log.Log
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.drainPages
import com.edde746.plezy.music.MusicPlaybackStatus
import com.edde746.plezy.music.playAudioPlaylist
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.downloads.DownloadButtonIcon
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.downloads.DownloadButtonTint
import com.edde746.plezy.presentation.downloads.DownloadMenuEntry
import com.edde746.plezy.presentation.downloads.detailDownloadVisible
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.playlists.rowKey
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * An audio playlist's screen: its tracks as rows captioned "Artist · Album", each with its artwork, the current one with
 * the equalizer.
 *
 * @param downloads the header's download actions: Download, or with a sync rule Manage and Remove it. None offline,
 *   without downloads (Apple TV) or where sync rules aren't supported; Download only while the playlist has tracks.
 * @param editable the playlist can be edited now: a regular (not smart) playlist of a connected server with no change
 *   on its way. [editing] is Edit mode (the rows' handles and ✕), [moving] the row move mode carries.
 * @param canDelete Delete Playlist is offered: a regular playlist of a connected server.
 */
data class MusicPlaylistUiState(
    val load: LoadState = LoadState.LOADING,
    val header: MusicHeaderUi? = null,
    val rows: List<TrackRowUi> = emptyList(),
    val playingKey: String? = null,
    val playing: Boolean = false,
    val error: String? = null,
    val downloads: List<PlaylistDownloadAction> = emptyList(),
    val editable: Boolean = false,
    val editing: Boolean = false,
    val moving: Int? = null,
    val canDelete: Boolean = false,
)

/** A download action of the playlist's header: what [MusicPlaylistStore.download] takes ([entry]) and its [button]. */
data class PlaylistDownloadAction(val entry: DownloadMenuEntry, val button: DownloadButtonSpec)

/** A playlist track's caption: its artist and album, either missing one left out. */
internal fun playlistTrackSubtitle(track: MediaItem): String? =
    listOfNotNull(track.trackArtistTitle, track.albumTitle).filter { it.isNotEmpty() }.joinToString(" · ").ifEmpty { null }

/**
 * The audio playlist screen's store: Play, Shuffle and a tapped row play the whole playlist through the music session
 * (from that row). Its download actions queue the playlist's tracks (once or kept synced) or manage the sync rule.
 * Edit mode ([edit]) reorders rows (a drag, [move], or move mode: [startMove], [step], [confirmMove], [cancelMove]) and
 * removes them ([remove]), optimistically: a change shows at once and goes to the server; a refusal puts the order back
 * as it was, an error (the outcome unknown) loads the playlist again, both with a message. [delete] asks, deletes the
 * playlist and leaves. [close] when the screen goes.
 *
 * @param delete asks, then deletes the playlist, calling back once it is gone ([com.edde746.plezy.presentation.browse.MediaMenu.delete]).
 */
class MusicPlaylistStore internal constructor(
    private val screens: MusicScreens,
    private val route: Route.MusicPlaylist,
    private val delete: (MediaPlaylist, onDeleted: () -> Unit) -> Unit,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(MusicPlaylistUiState())
    private val backend = screens.backend(route.serverId)
    private var playlist: MediaPlaylist? = null
    private var tracks: List<MediaItem> = emptyList()
    private var loading: Job? = null
    private var pending = false
    private var moveOrigin: Pair<Int, List<MediaItem>>? = null

    val state: StateFlow<MusicPlaylistUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            screens.playback.state.collect { music ->
                mutableState.update { it.copy(playingKey = music.currentTrack?.globalKey, playing = music.status == MusicPlaybackStatus.PLAYING) }
            }
        }
        screens.downloads?.let { downloads ->
            scope.launch { combine(downloads.changes, screens.offline) { _, _ -> }.collect { publishDownloads() } }
        }
        scope.launch { screens.offline.collect { publishEditing() } }
        load()
    }

    fun retry() {
        mutableState.update { it.copy(load = LoadState.LOADING, error = null) }
        load()
    }

    fun play() = play(shuffle = false, start = null)

    fun shuffle() = play(shuffle = true, start = null)

    fun playFrom(index: Int) {
        tracks.getOrNull(index)?.let { play(shuffle = false, start = it) }
    }

    /** The track at [index], for its item menu. */
    fun track(index: Int): MediaItem? = tracks.getOrNull(index)

    /** A download action pressed ([MusicPlaylistUiState.downloads]): its feedback shows as a snackbar. */
    fun download(entry: DownloadMenuEntry) {
        val root = playlistItem() ?: return
        val downloads = screens.downloads ?: return
        val backend = backend ?: return
        scope.launch {
            try {
                downloads.performPlaylist(root, entry, backend) { fetchTracks(backend) }?.let { screens.message(it.message, it.isError) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                screens.message(T.messages.errorLoading(localizedErrorReason(e)), error = true)
            }
        }
    }

    /** Edit mode on or off; off leaves move mode with the order as it was. */
    fun edit(on: Boolean) {
        if (on && !mutableState.value.editable) return
        if (!on) cancelMove()
        mutableState.update { it.copy(editing = on) }
    }

    /** A drag dropped the row at [from] at [to]. */
    fun move(from: Int, to: Int) {
        if (!canMutate() || moveOrigin != null) return
        val current = tracks
        if (from !in current.indices || to !in current.indices || from == to) return
        showTracks(current.toMutableList().apply { add(to, removeAt(from)) })
        persistMove(to, current)
    }

    /** Move mode on the row at [index]: [step] moves it, [confirmMove] saves, [cancelMove] puts it back. */
    fun startMove(index: Int) {
        if (!canMutate() || index !in tracks.indices) return
        moveOrigin = index to tracks
        mutableState.update { it.copy(moving = index) }
    }

    /** Moves the row in move mode one place up ([delta] -1) or down (1); false at an end. */
    fun step(delta: Int): Boolean {
        val index = mutableState.value.moving ?: return false
        val target = index + delta
        if (target !in tracks.indices) return false
        mutableState.update { it.copy(moving = target) }
        showTracks(tracks.toMutableList().apply { add(target, removeAt(index)) })
        return true
    }

    /** Saves move mode's order. */
    fun confirmMove() {
        val (origin, before) = moveOrigin ?: return
        val index = mutableState.value.moving ?: return
        moveOrigin = null
        mutableState.update { it.copy(moving = null) }
        if (index != origin) persistMove(index, before)
    }

    /** Leaves move mode with the order as it was; false when it wasn't on (Back goes on to leave Edit mode, then the screen). */
    fun cancelMove(): Boolean {
        val (_, before) = moveOrigin ?: return false
        moveOrigin = null
        mutableState.update { it.copy(moving = null) }
        showTracks(before)
        return true
    }

    /** Removes the row at [index] from the playlist. */
    fun remove(index: Int) {
        if (!canMutate() || moveOrigin != null) return
        val before = tracks
        val item = before.getOrNull(index) ?: return
        val backend = backend ?: return
        showTracks(before.toMutableList().apply { removeAt(index) })
        mutate(T.playlists.errorRemoving, before, { backend.removeFromPlaylist(route.id, item) }) {
            screens.message(T.playlists.itemRemoved)
        }
    }

    /** Asks, then deletes the playlist and leaves its screen. */
    fun delete() {
        val playlist = playlist ?: return
        if (!mutableState.value.canDelete) return
        delete(playlist) { screens.back() }
    }

    fun close() = scope.cancel()

    private fun persistMove(index: Int, before: List<MediaItem>) {
        val backend = backend ?: return
        val item = tracks[index]
        val previous = if (index == 0) null else tracks[index - 1]
        mutate(T.playlists.errorReordering, before, { backend.movePlaylistItem(route.id, item, index, previous) }) { }
    }

    /**
     * Sends a change the rows already show: [call]'s refusal puts [before] back, an error loads the playlist again (the
     * server may or may not have applied it); both say [failure].
     */
    private fun mutate(failure: String, before: List<MediaItem>, call: suspend () -> Boolean, onSuccess: () -> Unit) {
        pending = true
        publishEditing()
        scope.launch {
            val accepted = try {
                call()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Changing playlist ${route.id} failed" }
                null
            }
            pending = false
            when (accepted) {
                true -> onSuccess()
                false -> showTracks(before)
                null -> load()
            }
            publishEditing()
            if (accepted != true) screens.message(failure, error = true)
        }
    }

    private fun canMutate(): Boolean = playlist?.smart == false && backend != null && !screens.offline.value && !pending

    private fun publishEditing() {
        val editable = canMutate()
        val canDelete = playlist?.smart == false && backend != null && !screens.offline.value
        mutableState.update { it.copy(editable = editable, editing = it.editing && canDelete, canDelete = canDelete) }
    }

    /** [items] as the rows and the header's count and length. */
    private fun showTracks(items: List<MediaItem>) {
        tracks = items
        val total = items.sumOf { it.durationMs ?: 0 }
        mutableState.update { state ->
            state.copy(
                load = if (items.isEmpty()) LoadState.EMPTY else LoadState.CONTENT,
                header = state.header?.copy(meta = trackMeta(items.size, total)),
                rows = trackRows(items, showArtist = true, showTrackNumber = false, subtitle = ::playlistTrackSubtitle).mapIndexed { index, row ->
                    row.copy(key = rowKey(items[index]), artwork = backend.squareArtwork(items[index]))
                },
            )
        }
    }

    private fun trackMeta(count: Int, totalMs: Long): String? =
        bulleted(listOfNotNull(T.music.trackCount(count), formatDurationTextual(totalMs).takeIf { totalMs > 0 }))

    /** The playlist as the downloads keep it: the sync rule's and the Downloads screen's item. */
    private fun playlistItem(): MediaItem? = playlist?.let {
        MediaItem(
            id = it.id,
            backend = it.backend,
            kind = MediaKind.PLAYLIST,
            title = it.title,
            thumbPath = it.thumbPath,
            serverId = it.serverId ?: route.serverId,
            serverName = it.serverName,
        )
    }

    private fun publishDownloads() {
        val downloads = screens.downloads
        val root = playlistItem()
        val actions = if (downloads == null || root == null || backend == null || !detailDownloadVisible(screens.offline.value, downloadsSupported = true)) {
            emptyList()
        } else {
            downloads.playlistActions(root).mapNotNull { entry ->
                when (entry) {
                    DownloadMenuEntry.DOWNLOAD_PLAYLIST -> DownloadButtonSpec(DownloadButtonIcon.DOWNLOAD, T.downloads.downloadNow).takeIf { tracks.isNotEmpty() }
                    DownloadMenuEntry.MANAGE_SYNC -> DownloadButtonSpec(DownloadButtonIcon.SYNC, T.downloads.manageSyncRule, DownloadButtonTint.TEAL)
                    DownloadMenuEntry.REMOVE_SYNC -> DownloadButtonSpec(DownloadButtonIcon.SYNC_DISABLED, T.downloads.removeSyncRule)
                    else -> null
                }?.let { PlaylistDownloadAction(entry, it) }
            }
        }
        mutableState.update { it.copy(downloads = actions) }
    }

    private suspend fun fetchTracks(backend: MediaBackend): List<MediaItem> =
        drainPages(PAGE_SIZE) { start, size -> backend.fetchPlaylistPage(route.id, start, size) }

    private fun play(shuffle: Boolean, start: MediaItem?) {
        val playlist = playlist ?: return
        val backend = backend ?: return
        if (tracks.isEmpty()) return screens.message(T.messages.noItemsAvailable)
        scope.launch {
            val started = screens.playback.playAudioPlaylist(
                backend = backend,
                playlist = playlist,
                shuffle = shuffle,
                startTrack = start,
                preloadedItems = tracks,
                onError = { screens.message(localizedLoadErrorMessage(it, playlist.title), error = true) },
            )
            screens.started(started)
        }
    }

    private fun load() {
        loading?.cancel()
        loading = scope.launch {
            try {
                val backend = backend ?: throw IllegalStateException("No client for ${route.serverId}")
                val (playlist, items) = coroutineScope {
                    val playlist = async { backend.fetchPlaylistMetadata(route.id) }
                    val items = fetchTracks(backend)
                    playlist.await() to items
                }
                playlist ?: throw IllegalStateException("Playlist ${route.id} not found")
                this@MusicPlaylistStore.playlist = playlist
                mutableState.update {
                    it.copy(
                        header = MusicHeaderUi(title = playlist.title, artwork = Artwork.of(backend, playlist.displayImagePath, ImageKind.SQUARE)),
                        error = null,
                    )
                }
                showTracks(items)
                publishEditing()
                publishDownloads()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                mutableState.update { it.copy(load = LoadState.ERROR, error = localizedLoadErrorMessage(e, playlist?.title ?: T.common.mediaKind.playlist)) }
            }
        }
    }

    private companion object {
        const val TAG = "MusicPlaylistStore"
        const val PAGE_SIZE = 200
    }
}
