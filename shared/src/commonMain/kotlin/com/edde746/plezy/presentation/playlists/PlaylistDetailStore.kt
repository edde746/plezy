package com.edde746.plezy.presentation.playlists

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.toCardUi
import com.edde746.plezy.presentation.detail.AppendPager
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.launch

/**
 * One row of a playlist: [key] tells repeated entries of the same item apart (the playlist entry's id), [card] its
 * artwork, title and watch state, [subtitle] "S1E2 - Title", "2019 · Director's Cut", "Artist · Album" or the kind,
 * [duration] its length, [square] a track's square artwork.
 */
data class PlaylistRow(val key: String, val card: MediaCardUi, val subtitle: String, val duration: String?, val square: Boolean)

/**
 * A playlist's screen: [rows] once loaded ([loading] before, [error] when the first page failed), the rest loading on
 * behind it ([loadingMore], [moreError] with a retry). A smart playlist is read only; another can be edited
 * ([editable]: reordered by drag or move mode, rows removed) once every page is in and no change is on its way.
 * [editing] is Edit mode (the rows' handles and ✕), [moving] the row move mode carries.
 */
data class PlaylistDetailState(
    val title: String = "",
    val smart: Boolean = false,
    val audio: Boolean = false,
    val rows: List<PlaylistRow> = emptyList(),
    val loading: Boolean = true,
    val error: String? = null,
    val loadingMore: Boolean = false,
    val moreError: String? = null,
    val editable: Boolean = false,
    val editing: Boolean = false,
    val moving: Int? = null,
) {
    /** Play and Shuffle show. */
    val canPlay: Boolean get() = rows.isNotEmpty()

    /** Delete shows: a smart playlist is the server's rules, not deleted here. */
    val canDelete: Boolean get() = !loading && error == null && !smart

    val empty: Boolean get() = !loading && error == null && rows.isEmpty()
}

/**
 * The playlist [playlistId] of [client]'s server: loads 200 entries at a time, all of them in turn, and edits them
 * optimistically: a move or removal shows at once and goes to the server; a refusal puts the order back as it was, an
 * error (the outcome unknown) loads the playlist again. Main thread only.
 *
 * @param fresh the items with the watch state the app knows, now and as it changes.
 * @param play plays the playlist from an item (shuffled, or from its first item when null).
 * @param delete asks, then deletes the playlist, calling back once it is gone.
 * @param openMenu opens an item's menu.
 * @param message shows a message (a snackbar): the text and whether it is an error.
 */
class PlaylistDetailStore(
    private val client: MediaBackend,
    private val playlistId: String,
    private val cardOptions: () -> CardOptions,
    private val fresh: (List<MediaItem>) -> Flow<List<MediaItem>> = { flowOf(it) },
    private val play: (MediaPlaylist, shuffle: Boolean, start: MediaItem?) -> Unit,
    private val delete: (MediaPlaylist, onDeleted: () -> Unit) -> Unit,
    private val openMenu: (MediaItem) -> Unit,
    private val back: () -> Unit,
    private val message: (String, Boolean) -> Unit,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(PlaylistDetailState())
    private val items = MutableStateFlow<List<MediaItem>>(emptyList())
    private val pages = AppendPager({ start -> client.fetchPlaylistPage(playlistId, start, AppendPager.PAGE_SIZE) }, ::paged)
    private var playlist: MediaPlaylist? = null
    private var pending = false
    private var moveOrigin: Pair<Int, List<MediaItem>>? = null
    private var loadJob: Job? = null
    private var moreJob: Job? = null
    private var shown: List<MediaItem> = emptyList()

    val state: StateFlow<PlaylistDetailState> = mutableState.asStateFlow()

    init {
        scope.launch {
            @OptIn(ExperimentalCoroutinesApi::class)
            items.flatMapLatest(fresh).collect { publish(it) }
        }
        load()
    }

    /** Loads the playlist from its first page (again, after an error). */
    fun load() {
        loadJob?.cancel()
        moreJob?.cancel()
        moveOrigin = null
        mutableState.value = mutableState.value.copy(loading = true, error = null, moreError = null, moving = null)
        loadJob = scope.launch {
            val metadata = try {
                playlist ?: client.fetchPlaylistMetadata(playlistId) ?: throw IllegalStateException(T.playlists.errorLoading)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Loading playlist $playlistId failed" }
                mutableState.value = mutableState.value.copy(loading = false, error = T.messages.errorLoading(error = localizedErrorReason(e)))
                return@launch
            }
            playlist = metadata
            pages.loadFirst()
            if (pages.load == SectionLoad.ERROR) {
                mutableState.value = mutableState.value.copy(loading = false, error = pages.error)
                return@launch
            }
            mutableState.value = mutableState.value.copy(
                title = metadata.title,
                smart = metadata.smart,
                audio = metadata.playlistType == AUDIO,
                loading = false,
            )
            loadRest()
        }
    }

    /** The continuation's error row: loads on from where it failed, keeping what loaded. */
    fun retryMore() {
        if (moreJob?.isActive == true) return
        loadRest()
    }

    fun play(shuffle: Boolean) {
        val metadata = playlist ?: return
        if (items.value.isEmpty()) return message(T.playlists.emptyPlaylist, true)
        play(metadata, shuffle, null)
    }

    /** Plays the playlist from the row at [index]. */
    fun playFrom(index: Int) {
        val metadata = playlist ?: return
        val item = items.value.getOrNull(index) ?: return
        play(metadata, false, item)
    }

    /** Opens the item menu of the row at [index]. */
    fun openMenu(index: Int) {
        items.value.getOrNull(index)?.let(openMenu)
    }

    /** Asks, then deletes the playlist and leaves its screen. */
    fun delete() {
        val metadata = playlist ?: return
        if (metadata.smart) return
        delete(metadata, back)
    }

    /** Edit mode on (while [PlaylistDetailState.editable]) or off; off leaves move mode with the order as it was. */
    fun edit(on: Boolean) {
        if (on && !mutableState.value.editable) return
        if (!on) cancelMove()
        mutableState.value = mutableState.value.copy(editing = on)
    }

    /** A drag dropped the row at [from] at [to]. */
    fun move(from: Int, to: Int) {
        if (!canMutate() || moveOrigin != null) return
        val current = items.value
        if (from !in current.indices || to !in current.indices || from == to) return
        val moved = current.toMutableList().apply { add(to, removeAt(from)) }
        setRows(moved)
        persistMove(to, current)
    }

    /** Move mode on the row at [index]: [step] moves it, [confirmMove] saves, [cancelMove] puts it back. */
    fun startMove(index: Int) {
        if (!canMutate() || index !in items.value.indices) return
        moveOrigin = index to items.value
        mutableState.value = mutableState.value.copy(moving = index)
    }

    /** Moves the row in move mode one place up ([delta] -1) or down (1); false at an end. */
    fun step(delta: Int): Boolean {
        val index = mutableState.value.moving ?: return false
        val target = index + delta
        val current = items.value
        if (target !in current.indices) return false
        mutableState.value = mutableState.value.copy(moving = target)
        setRows(current.toMutableList().apply { add(target, removeAt(index)) })
        return true
    }

    /** Saves move mode's order. */
    fun confirmMove() {
        val (origin, before) = moveOrigin ?: return
        val index = mutableState.value.moving ?: return
        moveOrigin = null
        mutableState.value = mutableState.value.copy(moving = null)
        if (index == origin) return
        persistMove(index, before)
    }

    /** Leaves move mode with the order as it was; false when it wasn't on (Back goes on to leave the screen). */
    fun cancelMove(): Boolean {
        val (_, before) = moveOrigin ?: return false
        moveOrigin = null
        mutableState.value = mutableState.value.copy(moving = null)
        setRows(before)
        return true
    }

    /** Removes the row at [index] from the playlist. */
    fun remove(index: Int) {
        if (!canMutate() || moveOrigin != null) return
        val before = items.value
        val item = before.getOrNull(index) ?: return
        setRows(before.toMutableList().apply { removeAt(index) })
        mutate(T.playlists.errorRemoving, before, { client.removeFromPlaylist(playlistId, item) }) {
            // The server's total shrank with the list: without this the rows fall one short and editing locks.
            pages.total -= 1
            message(T.playlists.itemRemoved, false)
        }
    }

    fun close() = scope.cancel()

    private fun persistMove(index: Int, before: List<MediaItem>) {
        val after = items.value
        val item = after[index]
        val previous = if (index == 0) null else after[index - 1]
        mutate(T.playlists.errorReordering, before, { client.movePlaylistItem(playlistId, item, index, previous) }) { }
    }

    /**
     * Sends a change the rows already show: [call]'s refusal puts [before] back, an error loads the playlist again
     * (the server may or may not have applied it); both say [failure].
     */
    private fun mutate(failure: String, before: List<MediaItem>, call: suspend () -> Boolean, onSuccess: () -> Unit) {
        pending = true
        publish()
        scope.launch {
            val accepted = try {
                call()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Changing playlist $playlistId failed" }
                null
            }
            pending = false
            when (accepted) {
                true -> {
                    onSuccess()
                    publish()
                }
                false -> {
                    setRows(before)
                    publish()
                    message(failure, true)
                }
                null -> {
                    load()
                    message(failure, true)
                }
            }
        }
    }

    /** Loads the pages after the first, one after another, until all are in or one fails. */
    private fun loadRest() {
        moreJob = scope.launch {
            while (pages.loadMore()) Unit
        }
    }

    /** The pages moved: their rows, and where the continuation stands. */
    private fun paged() {
        items.value = pages.items
        mutableState.value = mutableState.value.copy(loadingMore = pages.loadingMore, moreError = pages.moreError)
        publish()
    }

    /** [rows] are the playlist's rows now (a move, a removal, one put back). */
    private fun setRows(rows: List<MediaItem>) {
        pages.items = rows
        items.value = rows
    }

    private fun canMutate(): Boolean = playlist?.smart == false && pages.complete && !pending

    private fun publish(fresh: List<MediaItem> = shown) {
        shown = fresh
        val options = cardOptions()
        mutableState.value = mutableState.value.copy(
            rows = fresh.map { it.row(options) },
            editable = canMutate(),
        )
    }

    private fun MediaItem.row(options: CardOptions): PlaylistRow {
        val key = rowKey(this)
        // A row's 60 × 90 poster is an episode's series poster whatever the cards show; a smart playlist's grid follows them.
        val poster = if (playlist?.smart == true) options else options.copy(episodePosterMode = EpisodePosterMode.SERIES_POSTER)
        return PlaylistRow(
            key = key,
            card = toCardUi(client, poster).copy(id = key, title = displayTitle),
            subtitle = playlistSubtitle(this),
            duration = durationMs?.let(::formatDurationTextual),
            square = kind.isMusic,
        )
    }

    private companion object {
        const val TAG = "PlaylistDetailStore"
        const val AUDIO = "audio"
    }
}

/** A row's key: the playlist entry's id (an item can be in a playlist more than once), else the item's. */
fun rowKey(item: MediaItem): String {
    val entry = item.playlistItemId ?: return item.id
    return if (item.backend == BackendKind.PLEX) "p:$entry" else "j:$entry"
}

/** A playlist row's second line: "S1E2 - Title", "2019 · Edition", "Artist · Album", else the kind. */
fun playlistSubtitle(item: MediaItem): String = when (item.kind) {
    MediaKind.EPISODE -> {
        val season = item.parentIndex
        val episode = item.index
        if (season != null && episode != null) {
            "S${season}E$episode" + (item.displaySubtitle?.let { " - $it" } ?: "")
        } else {
            item.displaySubtitle ?: T.discover.tvShow
        }
    }
    MediaKind.MOVIE -> {
        val year = item.year?.toString()
        val edition = item.editionTitle
        if (year != null && edition != null) "$year · $edition" else year ?: T.discover.movie
    }
    MediaKind.TRACK -> listOfNotNull(item.trackArtistTitle, item.albumTitle).filter { it.isNotEmpty() }.joinToString(" · ")
        .ifEmpty { item.kind.id }
    else -> item.kind.id
}
