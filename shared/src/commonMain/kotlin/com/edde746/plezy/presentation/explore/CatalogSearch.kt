package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration.Companion.milliseconds

/** Where a catalog search stands, the first that holds. */
sealed interface CatalogSearchBody {
    /** Nothing searched yet; [prompt] says what the field searches, or is null where nothing shows (Explore's field). */
    data class Idle(val prompt: String?) : CatalogSearchBody

    data object Loading : CatalogSearchBody

    /** [text]: the search failed; the next query, or a retry, tries again. */
    data class Failed(val text: String) : CatalogSearchBody

    /** [text]: the source has nothing for the last query. */
    data class Empty(val text: String) : CatalogSearchBody

    /** [items]: the source's answer for the last query, as catalog stand-ins ([CatalogItem.toMediaItem]). */
    data class Results(val items: List<MediaItem>) : CatalogSearchBody
}

/**
 * Debounced free-text search of a catalog source, shared by Explore's inline field and the catalog search screen.
 * Each change of the text arms a [DEBOUNCE] wait before the query runs; a search for text the field no longer holds
 * is dropped, and going back to the query already shown cancels the wait instead of searching again. Main thread only.
 */
internal class CatalogSearch(
    private val scope: CoroutineScope,
    private val search: suspend (String) -> List<CatalogItem>,
    private val changed: () -> Unit,
) {
    /** The field's text as typed. */
    var text = ""
        private set
    private var results: List<MediaItem> = emptyList()
    private var searching = false
    private var searched = false
    private var failed = false
    private var lastSearchedQuery = ""
    private var inFlightQuery: String? = null
    private var debounceJob: Job? = null
    private var searchJob: Job? = null

    /** Bumped whenever a running search stops counting; a search that finds it changed drops its answer. */
    private var generation = 0

    /** The trimmed text: what a search runs with. */
    val query: String get() = text.trim()

    fun body(prompt: String?): CatalogSearchBody = when {
        searching -> CatalogSearchBody.Loading
        !searched -> CatalogSearchBody.Idle(prompt)
        failed -> CatalogSearchBody.Failed(T.explore.searchFailed)
        results.isEmpty() -> CatalogSearchBody.Empty(T.explore.searchEmpty(isolate(lastSearchedQuery)))
        else -> CatalogSearchBody.Results(results)
    }

    fun setText(value: String) {
        if (value == text) return
        text = value
        val query = query
        if (query.isEmpty()) {
            debounceJob?.cancel()
            dropInFlight()
            results = emptyList()
            searched = false
            searching = false
            failed = false
            lastSearchedQuery = ""
        } else if (query == lastSearchedQuery) {
            // Back to what is shown: neither the armed search nor one for the text in between may land.
            debounceJob?.cancel()
            if (inFlightQuery != query) dropInFlight()
            if (searching && inFlightQuery == null) searching = false
        } else {
            if (inFlightQuery != null && inFlightQuery != query) dropInFlight()
            debounceJob?.cancel()
            debounceJob = scope.launch {
                delay(DEBOUNCE)
                run(query)
            }
        }
        changed()
    }

    /** Runs [query] now, without the wait (a refresh, a source switch, a retry); the search's job, null for no query. */
    fun run(query: String = this.query): Job? {
        if (query.isEmpty()) return null
        debounceJob?.cancel()
        searchJob?.cancel()
        val ticket = ++generation
        inFlightQuery = query
        searching = true
        searched = true
        failed = false
        changed()
        return scope.launch {
            val found = try {
                search(query)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Catalog search failed" }
                null
            }
            if (ticket != generation) return@launch
            inFlightQuery = null
            results = found.orEmpty().map { it.toMediaItem() }
            failed = found == null
            searching = false
            lastSearchedQuery = query
            changed()
        }.also { searchJob = it }
    }

    /**
     * The keyboard's search action: true when the results for the text are already shown (the screen moves focus to
     * them); otherwise the waiting search runs now, unless one for the text is already running.
     */
    fun submit(): Boolean {
        val query = query
        if (query.isEmpty()) return false
        if (results.isNotEmpty() && !searching && query == lastSearchedQuery) return true
        if (debounceJob?.isActive == true || !searching) run(query)
        return false
    }

    private fun dropInFlight() {
        generation++
        searchJob?.cancel()
        inFlightQuery = null
    }

    companion object {
        val DEBOUNCE = 500.milliseconds
        private const val TAG = "CatalogSearch"
    }
}
