package com.edde746.plezy.presentation.browse

import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** A message an action leaves for the viewer (a snackbar); [isError] ones read as errors. */
data class MenuMessage(val text: String, val isError: Boolean = false)

/**
 * The question or sheet a menu action has open ([MediaMenu.prompt]), which the UIs draw and answer through
 * [MediaMenu]: one at a time, closed (null) once answered.
 */
sealed interface MenuPrompt {
    /** A confirmation: [warning] a danger block under [message]; [destructive] confirms in the error colour. */
    data class Confirm(
        val title: String,
        val message: String,
        val confirmLabel: String,
        val warning: String? = null,
        val destructive: Boolean = true,
    ) : MenuPrompt

    /** A choice between [options] ([MediaMenu.choose]). */
    data class Options(val title: String, val options: List<MenuOption>) : MenuPrompt

    /** A name to type ([MediaMenu.submit]): [label] over the field, [hint] in it. */
    data class TextInput(val title: String, val label: String, val hint: String) : MenuPrompt

    /** A playlist or collection to add to, or a new one ([ContainerPicker]). */
    data class Picker(val picker: ContainerPicker) : MenuPrompt

    /**
     * The file info sheet of the item named [title] ([com.edde746.plezy.presentation.player.FileInfoSections.page]
     * builds it from [info], as the player's file info page does); [MediaMenu.closePrompt] closes it.
     */
    data class FileInfo(val title: String, val info: MediaFileInfo) : MenuPrompt

    /**
     * Work in progress behind a spinner that Back doesn't close; [title] and a Cancel button ([MediaMenu.closePrompt])
     * when [cancellable] (a play queue loading).
     */
    data class Busy(val title: String? = null, val cancellable: Boolean = false) : MenuPrompt

    /**
     * An item's `plezy://` [link] to share, as a QR code and text with Copy; [kind] picks the hint ([MediaMenu.closePrompt]
     * closes it). [asProfile] is the "Open as {profile}" switch where the account has several profiles: on, the dialog
     * shows its link, which names the active profile.
     */
    data class Link(val link: String, val kind: MediaKind, val asProfile: LinkAsProfile? = null) : MenuPrompt
}

/** A [MenuPrompt.Link]'s "Open as {profile}" switch: its [label], and the [link] it shows when on. */
data class LinkAsProfile(val label: String, val link: String)

/**
 * One option of a [MenuPrompt.Options]; [detail] a line under its label (what picking it does); [logo] a catalog
 * source's mark drawn before it (a watchlist source chooser, which opens at the entry that asked where menus anchor);
 * [selected] the choice in effect, checked; [heading] the heading of the group it starts, where the options come in
 * groups (a View all's Sort By under its directions).
 */
data class MenuOption(
    val label: String,
    val icon: MenuIcon? = null,
    val detail: String? = null,
    val logo: CatalogSourceId? = null,
    val selected: Boolean = false,
    val heading: String? = null,
)

/** One row of a [ContainerPicker]: a playlist or collection, [enabled] unless it can't take items (a smart playlist). */
data class PickerRow(val id: String, val title: String, val subtitle: String?, val icon: MenuIcon, val enabled: Boolean = true)

/**
 * What a [ContainerPicker] shows: "Create new" first, then [rows] (those matching [filter]); [showFilter] once ten
 * or more are loaded; a spinner while [loading] or more pages remain ([hasMore]); [error] a row that retries; [empty]
 * the line when nothing matches and nothing is left to load.
 */
data class PickerState(
    val title: String,
    val searchHint: String,
    val rows: List<PickerRow> = emptyList(),
    val filter: String = "",
    val showFilter: Boolean = false,
    val loading: Boolean = false,
    val hasMore: Boolean = true,
    val error: String? = null,
    val emptyMessage: String,
) {
    val empty: Boolean get() = rows.isEmpty() && !loading && !hasMore && error == null
}

/** What a [ContainerPicker] answered. */
sealed interface PickerResult {
    data class Existing(val id: String) : PickerResult

    data object CreateNew : PickerResult
}

/**
 * The playlist or collection picker: loads [loadPage] 100 at a time ([loadMore] when the list nears its end), filters
 * by title (case-insensitive, loading on while a filter is set so matches further down are found), and answers the
 * row picked, "Create new", or nothing (cancelled). Main thread only.
 */
class ContainerPicker internal constructor(
    title: String,
    searchHint: String,
    emptyMessage: String,
    private val loadPage: suspend (start: Int, size: Int) -> LibraryPage<PickerRow>,
    private val scope: CoroutineScope,
) {
    private val all = mutableListOf<PickerRow>()
    private var total: Int? = null
    private var job: Job? = null
    private val answer = CompletableDeferred<PickerResult?>()
    private val mutableState = MutableStateFlow(PickerState(title, searchHint, emptyMessage = emptyMessage))

    val state: StateFlow<PickerState> = mutableState.asStateFlow()

    init {
        loadMore()
    }

    /** Loads the next page, unless one is loading or none is left. */
    fun loadMore() {
        if (job?.isActive == true || !hasMore()) return
        job = scope.launch {
            publish(loading = true, error = null)
            try {
                while (hasMore()) {
                    val page = loadPage(all.size, PAGE_SIZE)
                    all += page.items
                    total = page.totalCount
                    publish(loading = true, error = null)
                    if (mutableState.value.filter.isEmpty() || page.items.isEmpty()) break
                }
                publish(loading = false, error = null)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Loading the picker's page at ${all.size} failed" }
                publish(loading = false, error = T.messages.errorLoading(error = localizedErrorReason(e)))
            }
        }
    }

    /** The error row: loads again from where it failed. */
    fun retry() = loadMore()

    /** Filters the rows by [text]; a filter keeps loading pages until every match is in. */
    fun filter(text: String) {
        mutableState.value = mutableState.value.copy(filter = text)
        publish(loading = job?.isActive == true, error = mutableState.value.error)
        if (text.isNotEmpty()) loadMore()
    }

    fun pick(id: String) {
        if (all.none { it.id == id && it.enabled }) return
        finish(PickerResult.Existing(id))
    }

    fun createNew() = finish(PickerResult.CreateNew)

    fun cancel() = finish(null)

    internal suspend fun await(): PickerResult? = answer.await()

    private fun finish(result: PickerResult?) {
        job?.cancel()
        answer.complete(result)
    }

    private fun hasMore(): Boolean = total.let { it == null || all.size < it }

    private fun publish(loading: Boolean, error: String?) {
        val current = mutableState.value
        val query = current.filter.lowercase()
        mutableState.value = current.copy(
            rows = if (query.isEmpty()) all.toList() else all.filter { query in it.title.lowercase() },
            showFilter = all.size >= FILTER_THRESHOLD,
            loading = loading,
            hasMore = hasMore(),
            error = error,
        )
    }

    private companion object {
        const val TAG = "ContainerPicker"
        const val PAGE_SIZE = 100
        const val FILTER_THRESHOLD = 10
    }
}
