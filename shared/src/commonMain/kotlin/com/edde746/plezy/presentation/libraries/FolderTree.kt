package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.presentation.browse.placeholderKind
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.backend.localizedLoadErrorText
import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.formatContentRating
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.formatRating
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/** One row of the folder tree: a folder (or a show, a season, …) to expand, or an item to open. */
data class FolderRowUi(
    /** The item's global key. */
    val id: String,
    val depth: Int,
    val title: String,
    /** A plain folder: the chevron, the folder icon, and Play and Shuffle. */
    val folder: Boolean,
    val expandable: Boolean,
    val expanded: Boolean,
    /** Its children are loading: a spinner in place of the chevron. */
    val loading: Boolean,
    /** "S1 E4" for an episode, else the item's subtitle. */
    val subtitle: String?,
    /** "PG-13 · 2019 · 2h 10m · ★7.5". */
    val metadata: String?,
    val thumb: Artwork?,
    /** What the thumbnail shows without artwork. */
    val placeholder: PlaceholderKind,
    /** The thumbnail is 16:9 (an episode's under the episode-thumbnail setting). */
    val wide: Boolean,
    val watched: Boolean,
    /** An unwatched episode's thumbnail blurs (hide spoilers). */
    val blurred: Boolean,
)

data class FolderTreeUiState(val load: LoadState, val rows: List<FolderRowUi>, val error: String?)

/**
 * Browse by folders: the library's root folders, each expanding in place into its children, page by page as they
 * arrive. Expanded folders and their children are kept; a failed expansion drops its partial pages and says so in an
 * error snackbar ([LibraryTabContext.notifyError]).
 */
class FolderTree internal constructor(
    private val context: LibraryTabContext,
    private val scope: CoroutineScope,
    private val onChanged: () -> Unit,
) {
    private val library = context.library
    private var root: List<MediaItem> = emptyList()
    private val children = HashMap<String, List<MediaItem>>()
    private val expanded = LinkedHashSet<String>()
    private val loading = HashMap<String, Job>()
    private var load = LoadState.LOADING
    private var error: String? = null

    var state: FolderTreeUiState = FolderTreeUiState(LoadState.LOADING, emptyList(), null)
        private set

    /** Loads the root listing (again); true once it landed. */
    suspend fun loadRoot(): Boolean {
        val client = context.client
        if (client == null) {
            load = LoadState.ERROR
            error = T.errors.noClientAvailable
            publish()
            return false
        }
        return try {
            val items = client.fetchLibraryFolders(library.id) { page ->
                root = page
                if (load == LoadState.LOADING) load = LoadState.CONTENT
                publish()
            }
            root = items
            load = if (items.isEmpty()) LoadState.EMPTY else LoadState.CONTENT
            error = null
            publish()
            true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Folders of ${library.globalKey} failed" }
            if (root.isEmpty()) {
                load = LoadState.ERROR
                error = localizedLoadErrorText(e, T.libraries.content)
            }
            publish()
            false
        }
    }

    /** Expands or collapses the row [id]; expanding loads its children unless they are kept. */
    fun toggle(id: String) {
        val item = item(id) ?: return
        if (id in expanded) {
            expanded -= id
            publish()
            return
        }
        expanded += id
        if (id in children || id in loading) return publish()
        loadChildren(id, item)
    }

    /**
     * The item [itemId] of this library was deleted: the listing that held it is fetched again, the root's for a root
     * item, else its folder's (its kept children dropped first).
     */
    fun onDeleted(itemId: String) {
        if (root.any { it.id == itemId }) {
            scope.launch { loadRoot() }
            return
        }
        val folderId = children.entries.firstOrNull { (_, list) -> list.any { it.id == itemId } }?.key ?: return
        val folder = item(folderId) ?: return
        loading.remove(folderId)?.cancel()
        children -= folderId
        loadChildren(folderId, folder)
    }

    private fun loadChildren(id: String, item: MediaItem) {
        val client = context.client ?: return
        loading[id] = scope.launch {
            try {
                val list = client.fetchFolderChildren(item, library.id, library.title) { page ->
                    children[id] = page
                    publish()
                }
                children[id] = list
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Children of $id failed" }
                children -= id
                expanded -= id
                context.notifyError(localizedLoadErrorText(e, item.displayTitle))
            } finally {
                // A load a newer one replaced (a deletion's refetch) leaves the newer one's entry.
                if (loading[id] === coroutineContext[Job]) loading -= id
                publish()
            }
        }
        publish()
    }

    /** Whether tapping [item] expands it rather than opening it. */
    fun isExpandable(item: MediaItem): Boolean {
        if (item.kind == MediaKind.FOLDER) return true
        if (library.backend == BackendKind.PLEX) return false
        if (item.kind == MediaKind.SHOW || item.kind == MediaKind.SEASON) return true
        return library.kind == MediaKind.ARTIST && (item.kind == MediaKind.ARTIST || item.kind == MediaKind.ALBUM)
    }

    /** Whether a plain folder offers Play and Shuffle: always on Plex, outside music libraries on Jellyfin and Emby. */
    val canPlayFolders: Boolean get() = library.backend == BackendKind.PLEX || library.kind != MediaKind.ARTIST

    fun item(id: String): MediaItem? = find(root, id)

    private fun find(items: List<MediaItem>, id: String): MediaItem? {
        for (item in items) {
            if (item.globalKey == id) return item
            children[item.globalKey]?.let { list -> find(list, id)?.let { return it } }
        }
        return null
    }

    fun close() {
        loading.values.forEach { it.cancel() }
        loading.clear()
    }

    /** The card settings changed: the rows are made anew under them. */
    fun refreshRows() = publish()

    private fun publish() {
        val rows = mutableListOf<FolderRowUi>()
        val options = context.cardOptions()
        fun add(items: List<MediaItem>, depth: Int) {
            for (item in items) {
                val id = item.globalKey
                val open = id in expanded
                rows += row(item, depth, open, id in loading, options.episodePosterMode, options.hideSpoilers)
                if (open) children[id]?.let { add(it, depth + 1) }
            }
        }
        add(root, 0)
        state = FolderTreeUiState(load, rows, error)
        onChanged()
    }

    /** [item] as a tree row, titled by its own title (a season "Season 1" under its show, not the show's name). */
    private fun row(item: MediaItem, depth: Int, open: Boolean, busy: Boolean, mode: EpisodePosterMode, hideSpoilers: Boolean): FolderRowUi {
        val episode = item.kind == MediaKind.EPISODE
        val wide = episode && mode == EpisodePosterMode.EPISODE_THUMBNAIL
        val thumb = if (episode && !wide) item.grandparentThumbPath ?: item.thumbPath else item.thumbPath
        val title = item.title?.trim()?.takeIf { it.isNotEmpty() } ?: item.displayTitle
        return FolderRowUi(
            id = item.globalKey,
            depth = depth,
            title = title,
            folder = item.kind == MediaKind.FOLDER,
            expandable = isExpandable(item),
            expanded = open,
            loading = busy,
            subtitle = if (episode && item.parentIndex != null && item.index != null) {
                "S${item.parentIndex} E${item.index}"
            } else {
                item.displaySubtitle?.trim()?.takeIf { it.isNotEmpty() && it != title }
            },
            metadata = listOfNotNull(
                item.contentRating?.let(::formatContentRating),
                item.year?.toString(),
                item.durationMs?.let(::formatDurationTextual),
                item.rating?.let { "★${formatRating(it)}" },
            ).joinToString(" · ").ifEmpty { null },
            thumb = if (item.kind == MediaKind.FOLDER) null else Artwork.of(context.client, thumb, if (wide) ImageKind.THUMB else ImageKind.POSTER),
            placeholder = placeholderKind(item.kind),
            wide = wide,
            watched = item.isWatched,
            blurred = hideSpoilers && wide && item.shouldHideSpoiler,
        )
    }

    private companion object {
        const val TAG = "FolderTree"
    }
}
