package com.edde746.plezy.presentation.explore

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.presentation.browse.MenuOption
import com.edde746.plezy.presentation.home.HubDetailStore
import com.edde746.plezy.presentation.home.viewAllSortChoices
import com.edde746.plezy.presentation.home.viewAllSortPick
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException

/**
 * An Explore shelf's View All grid: [title] is the shelf's; its items in [sort]'s order ([descending]), the shelf's own
 * order while [sort] is null. [sortOptions] are a hub's default sorts (Title, Release Year, Date Added, Rating).
 */
data class ExploreRowUiState(
    val title: String,
    val body: ExploreRowBody,
    val sortOptions: List<MediaSort> = HubDetailStore.defaultSorts(),
    val sort: MediaSort? = null,
    val descending: Boolean = false,
) {
    /** The Sort menu's choices; [ExploreRowStore.pickSort] takes one's index. */
    val sortChoices: List<MenuOption> get() = viewAllSortChoices(sortOptions, sort, descending)
}

/** What the View All grid shows. */
sealed interface ExploreRowBody {
    /** [items]: the shelf's items, then every item once loaded; [loading] while the rest is on its way. */
    data class Items(val items: List<MediaItem>, val loading: Boolean) : ExploreRowBody

    /** [text]: the items couldn't be loaded; [ExploreRowStore.retry] tries again. */
    data class Failed(val text: String) : ExploreRowBody

    /** [text]: the shelf has nothing. */
    data class Empty(val text: String) : ExploreRowBody
}

/**
 * The View All grid of an Explore shelf ([row]): the shelf's own items at once, every item once [loadAll]
 * ([ExploreStore.loadAll]) answers, sorted client-side as a hub's View All is ([setSort]). Call everything on the main
 * thread; [release] ends it.
 */
class ExploreRowStore internal constructor(
    private val row: ExploreRow,
    private val loadAll: suspend (ExploreRow) -> List<MediaItem>,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private var items: List<MediaItem> = row.hub.items
    private var body: ExploreRowBody = ExploreRowBody.Items(items, loading = true)
    private val mutableState = MutableStateFlow(ExploreRowUiState(row.hub.title, body))
    private var job: Job? = null

    val state: StateFlow<ExploreRowUiState> = mutableState.asStateFlow()

    init {
        load()
    }

    /** Loads every item again after [ExploreRowBody.Failed]. */
    fun retry() = load()

    /** Orders by [sort] ([descending]), or by the shelf's order with null. */
    fun setSort(sort: MediaSort?, descending: Boolean) {
        mutableState.value = mutableState.value.copy(sort = sort, descending = sort != null && descending)
        publish(body)
    }

    /** Applies the Sort menu's choice at [index] ([ExploreRowUiState.sortChoices]). */
    fun pickSort(index: Int) {
        val state = mutableState.value
        val (sort, descending) = viewAllSortPick(state.sortOptions, state.sort, state.descending, index)
        setSort(sort, descending)
    }

    fun release() {
        scope.cancel()
    }

    private fun load() {
        if (job?.isActive == true) return
        publish(ExploreRowBody.Items(items, loading = true))
        job = scope.launch {
            val body = try {
                items = loadAll(row)
                if (items.isEmpty()) ExploreRowBody.Empty(T.hubDetail.noItemsFound) else ExploreRowBody.Items(items, loading = false)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "View All failed for ${row.hub.id}" }
                ExploreRowBody.Failed(T.errors.unableToLoad(isolate(row.hub.title)))
            }
            publish(body)
        }
    }

    private fun publish(body: ExploreRowBody) {
        this.body = body
        val current = mutableState.value
        val shown = if (body is ExploreRowBody.Items) body.copy(items = HubDetailStore.sorted(body.items, current.sort, current.descending)) else body
        mutableState.value = current.copy(body = shown)
    }

    private companion object {
        const val TAG = "ExploreRow"
    }
}
