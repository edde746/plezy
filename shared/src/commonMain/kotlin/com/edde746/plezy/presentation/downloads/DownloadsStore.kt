package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.downloads.BackgroundWorkStatus
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.downloads.deleteDownloadsFolder
import com.edde746.plezy.downloads.setDownloadsFolderWatched
import com.edde746.plezy.model.MediaFilterValue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.settings.LibraryPrefs
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.launch

/** A row of the Music tab's albums grouping: an album's header, or one of its tracks (in disc and track order). */
sealed interface MusicRow {
    data class Album(val album: MediaItem, val artworkPath: String?) : MusicRow

    /** [tracks] is the album's downloaded tracks, which a press plays from [index]. */
    data class Track(val tracks: List<MediaItem>, val index: Int) : MusicRow {
        val item: MediaItem get() = tracks[index]
        val isFirst: Boolean get() = index == 0
        val isLast: Boolean get() = index == tracks.lastIndex
    }
}

/** What a content tab shows. */
sealed interface DownloadsContent {
    /** A grid of cards: shows, seasons, episodes ([episodes]: the episode grid's cell), movies, or folders. */
    data class Grid(val items: List<MediaItem>, val episodes: Boolean = false) : DownloadsContent

    /** The library grouping's sections of cards. */
    data class Sections(val sections: List<DownloadsLibrarySection>) : DownloadsContent

    /** The Music tab's albums with their tracks. */
    data class Albums(val rows: List<MusicRow>) : DownloadsContent

    /** The Music tab's flat track list, without track numbers (they're album-relative). */
    data class Tracks(val tracks: List<MediaItem>) : DownloadsContent

    /**
     * Nothing to show: with filters on, "no items match" and a Reset filters action ([filtered]); otherwise "no
     * downloads" and its description.
     */
    data class Empty(val filtered: Boolean) : DownloadsContent {
        val title: String get() = if (filtered) T.libraries.noItemsMatchFilters else T.downloads.noDownloads
        val description: String? get() = if (filtered) null else T.downloads.noDownloadsDescription
        val actionLabel: String? get() = if (filtered) T.libraries.resetFilters else null
    }
}

/** A content tab: its options and what it shows. */
data class DownloadsTabState(val tab: DownloadsTab, val options: DownloadsOptionsState, val content: DownloadsContent)

/**
 * The Downloads screen.
 *
 * @param tree the Manage tab's flattened tree (empty: `noDownloadsTree`); built while Manage is selected.
 * @param tab the selected content tab's state; null on Manage.
 * @param retryFailed whether the app bar offers "Retry failed" (the profile owns a failed download).
 * @param banner the background-restriction banner, while something downloads and the verdict isn't healthy.
 * @param libraryFilterValues the Library filter's choices: each library holding downloads ([libraryFilterValues]).
 * @param message feedback to show once ([DownloadsStore.messageShown]).
 */
data class DownloadsUiState(
    val selected: DownloadsTab = DownloadsTab.MANAGE,
    val tree: List<DownloadTreeRow> = emptyList(),
    val tab: DownloadsTabState? = null,
    val retryFailed: Boolean = false,
    val banner: BackgroundWarningBanner? = null,
    val libraryFilterValues: List<MediaFilterValue> = emptyList(),
    val message: DownloadFeedback? = null,
) {
    val title: String get() = T.downloads.title
    val emptyTree: String get() = T.downloads.noDownloadsTree
    val retryFailedLabel: String get() = T.downloads.retryFailed
    val syncRulesLabel: String get() = T.downloads.activeSyncRules
    val optionsLabel: String get() = T.downloads.options
}

/**
 * The Downloads screen's store: four tabs (Manage, TV Shows, Movies, Music), the Manage tree with its per-row actions,
 * the content tabs' groupings, filters and sorts ([options]), collection folders and library sections, Retry failed,
 * the background-restriction banner, and the empty states.
 *
 * Deleting asks first ([dialogs]) and shows progress when slow ([deletion]); resuming and retrying need the item's
 * server ([clientFor], null while it isn't reachable).
 *
 * Its [state] is the downloads' from the start: a screen opened after downloads changed lists them in its first frame.
 *
 * Main thread only; [release] when the screen goes.
 */
class DownloadsStore(
    private val controller: DownloadsController,
    prefs: LibraryPrefs,
    private val warning: BackgroundDownloadWarning,
    private val diagnostics: StateFlow<BackgroundWorkStatus>,
    private val watchActions: WatchActions,
    private val offline: StateFlow<Boolean>,
    private val clientFor: (serverId: String) -> MediaBackend?,
    private val serverNameOf: (serverId: String) -> String?,
    val dialogs: DownloadDialogs,
    val deletion: SmartDeletion,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()

    /** The content tabs' options. */
    val options: Map<DownloadsTab, DownloadsTabOptions> =
        DownloadsTab.entries.filter { it.sectionId != null }.associateWith { DownloadsTabOptions(it, prefs, scope) }

    private var selected = DownloadsTab.MANAGE
    private var expanded = emptySet<String>()
    private var message: DownloadFeedback? = null

    private val mutableState = MutableStateFlow(DownloadsUiState())
    val state: StateFlow<DownloadsUiState> = mutableState.asStateFlow()

    init {
        publish()
        scope.launch {
            combine(controller.changes, diagnostics) { _, _ -> }.collect { publish() }
        }
        scope.launch {
            merge(*options.values.map { it.state }.toTypedArray()).collect { publish() }
        }
    }

    fun select(tab: DownloadsTab) {
        selected = tab
        publish()
    }

    /** Opens or closes a container row of the tree. */
    fun toggle(key: String) {
        expanded = if (key in expanded) expanded - key else expanded + key
        publish()
    }

    /** Runs [action] on [node]; deleting asks first. */
    fun perform(node: DownloadTreeNode, action: DownloadRowAction) {
        scope.launch {
            if (action.confirms && !confirmDelete(node.title)) return@launch
            when (action) {
                DownloadRowAction.PAUSE -> controller.pauseDownload(node.key)
                DownloadRowAction.RESUME -> resume(node.key)
                DownloadRowAction.CANCEL -> controller.cancelDownload(node.key)
                DownloadRowAction.RETRY -> clientOf(node.key)?.let { controller.retryDownload(node.key, it) }
                DownloadRowAction.DELETE -> deletion.deleteWithProgress(node.key)
                DownloadRowAction.PAUSE_ALL -> node.leafKeys { it.status == DownloadedMediaStatus.DOWNLOADING || it.status == DownloadedMediaStatus.QUEUED }
                    .forEach { controller.pauseDownload(it) }
                DownloadRowAction.RESUME_ALL -> node.leafKeys { it.status == DownloadedMediaStatus.PAUSED }.forEach { resume(it) }
                DownloadRowAction.RETRY_ALL -> controller.retryDownloads(node.leafKeys { it.status == DownloadedMediaStatus.FAILED }, ::clientOf)
                // Through the container's own key, so the whole show, season or album goes in one pass.
                DownloadRowAction.DELETE_ALL -> resolveDownloadContainerGlobalKey(node, controller.metadata)
                    ?.let { deletion.deleteWithProgress(it) }
                    ?: node.leafKeys().forEach { deletion.deleteWithProgress(it) }
            }
        }
    }

    /** The app bar's Retry failed: every failed download of the profile. */
    fun retryFailed() {
        scope.launch { controller.retryDownloads(controller.failedDownloadKeys, ::clientOf) }
    }

    /** The banner's action. */
    fun showBackgroundDetails() = warning.showDetails()

    /** A collection folder's menu entry. */
    fun performFolder(folder: MediaItem, entry: DownloadMenuEntry) {
        scope.launch {
            val feedback = when (entry) {
                DownloadMenuEntry.MARK_WATCHED, DownloadMenuEntry.MARK_UNWATCHED ->
                    setDownloadsFolderWatched(controller, watchActions, folder, entry == DownloadMenuEntry.MARK_WATCHED, offline.value)
                DownloadMenuEntry.DELETE_FOLDER_DOWNLOADS -> {
                    dialogs.confirm(
                        DownloadDialog.Confirm(
                            T.downloads.deleteCollectionDownloads,
                            T.downloads.deleteCollectionDownloadsConfirm(title = folder.displayTitle),
                            T.common.delete,
                            destructive = true,
                        ),
                    ) ?: return@launch
                    deleteDownloadsFolder(controller, folder)
                }
                else -> return@launch
            }
            show(feedback)
        }
    }

    /** The downloaded titles of a collection folder, for its screen. */
    fun folderItems(folder: MediaItem): List<MediaItem> = controller.downloadedCollectionItems(folder.globalKey)

    /** [item] as its card ([downloadCard]): its stored poster, a folder's title count. */
    fun card(item: MediaItem): MediaCardUi {
        val stored = ServerId.tryParse(item.serverId)?.let { controller.getArtworkLocalPath(it, item.posterThumb()) }
        return downloadCard(item, stored ?: controller.getArtworkPath(item.globalKey), folderCount = if (item.isDownloadsFolder) folderItems(item).size else null)
    }

    /** A music album header's or track's stored artwork (a local file). */
    fun artworkOf(item: MediaItem): String? =
        ServerId.tryParse(item.serverId)?.let { controller.getArtworkLocalPath(it, item.parentThumbPath ?: item.thumbPath) }
            ?: controller.getArtworkPath(item.globalKey)

    fun messageShown() {
        message = null
        publish()
    }

    fun release() = scope.cancel()

    private suspend fun resume(globalKey: String) {
        clientOf(globalKey)?.let { controller.resumeDownload(globalKey, it) }
    }

    private fun clientOf(globalKey: String): MediaBackend? = clientFor(parseGlobalKey(globalKey)?.first?.value ?: globalKey)

    private suspend fun confirmDelete(title: String): Boolean = dialogs.confirm(
        DownloadDialog.Confirm(T.downloads.deleteDownload, T.downloads.deleteConfirm(title = title), T.common.delete, destructive = true),
    ) != null

    private fun show(feedback: DownloadFeedback) {
        message = feedback
        publish()
    }

    /** Builds the selected tab only: a running download's every tick publishes. */
    private fun publish() {
        val downloads = controller.downloads
        val pending = downloads.values.any { it.status == DownloadedMediaStatus.DOWNLOADING || it.status == DownloadedMediaStatus.QUEUED }
        val tabOptions = options[selected]
        mutableState.value = DownloadsUiState(
            selected = selected,
            tree = if (tabOptions == null) flattenDownloadTree(buildDownloadTree(downloads, controller.metadata), expanded) else emptyList(),
            tab = tabOptions?.let { DownloadsTabState(selected, it.state.value, content(selected, it)) },
            retryFailed = controller.hasFailedDownloads,
            banner = warning.banner(diagnostics.value, pending),
            libraryFilterValues = libraryFilterValues(controller.downloadedLibraries) { serverNameOf(it) ?: it },
            message = message,
        )
    }

    private fun content(tab: DownloadsTab, tabOptions: DownloadsTabOptions): DownloadsContent {
        val grouping = tabOptions.state.value.grouping
        val filtered = tabOptions.state.value.hasActiveFilters
        fun applied(items: List<MediaItem>) = tabOptions.apply(items, controller::downloadSortExtras)
        fun orEmpty(content: DownloadsContent, isEmpty: Boolean) = if (isEmpty) DownloadsContent.Empty(filtered) else content

        if (tab == DownloadsTab.MUSIC) {
            return when (grouping) {
                DownloadsGrouping.TRACKS -> applied(controller.downloadedTracks).let { orEmpty(DownloadsContent.Tracks(it), it.isEmpty()) }
                DownloadsGrouping.LIBRARY -> bucketDownloadsByLibrary(applied(controller.downloadedAlbums), serverNameOf).let { orEmpty(DownloadsContent.Sections(it), it.isEmpty()) }
                else -> {
                    val albums = applied(controller.downloadedAlbums)
                    val rows = buildList {
                        for (album in albums) {
                            val tracks = controller.getDownloadedTracksForAlbum(album.globalKey)
                            if (tracks.isEmpty()) continue
                            add(MusicRow.Album(album, controller.getArtworkPath(album.globalKey)))
                            tracks.indices.forEach { add(MusicRow.Track(tracks, it)) }
                        }
                    }
                    orEmpty(DownloadsContent.Albums(rows), rows.isEmpty())
                }
            }
        }

        val raw = when {
            tab == DownloadsTab.MOVIES -> controller.downloadedMovies
            grouping == DownloadsGrouping.SEASONS -> controller.downloadedSeasons
            grouping == DownloadsGrouping.EPISODES -> controller.downloadedEpisodes
            else -> controller.downloadedShows
        }
        val items = applied(raw)
        return when (grouping) {
            DownloadsGrouping.LIBRARY -> bucketDownloadsByLibrary(items, serverNameOf).let { orEmpty(DownloadsContent.Sections(it), it.isEmpty()) }
            DownloadsGrouping.COLLECTIONS -> tabOptions.sortFolders(items, controller.groupDownloadsByCollection(items))
                .let { orEmpty(DownloadsContent.Grid(it), it.isEmpty()) }
            else -> orEmpty(DownloadsContent.Grid(items, episodes = grouping == DownloadsGrouping.EPISODES), items.isEmpty())
        }
    }
}

/** Whether [item] is a Downloads collection folder (its press opens the folder's downloads). */
val MediaItem.isDownloadsFolder: Boolean get() = kind == MediaKind.COLLECTION
