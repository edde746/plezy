package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * The catalog search screen: free-text search of one catalog source (TV's Explore toolbar opens it; elsewhere Explore
 * searches inline). It prompts until the first search, then shows the search's state ([CatalogSearch]).
 *
 * @param title the screen's title, which is also the field's hint ("Search Trakt").
 * @param query the field's text.
 */
data class CatalogSearchUiState(val title: String, val query: String, val body: CatalogSearchBody)

/** The catalog search screen's store; call everything on the main thread, [release] ends it. */
class CatalogSearchStore internal constructor(source: CatalogSource, parentScope: CoroutineScope) {
    private val scope = parentScope.childScope()
    private val sourceName = isolate(source.displayName)
    private val search = CatalogSearch(scope, { query -> source.search(query) }, ::publish)
    private val mutableState = MutableStateFlow(build())

    val state: StateFlow<CatalogSearchUiState> = mutableState.asStateFlow()

    fun setQuery(text: String) = search.setText(text)

    /** The keyboard's search action (TV: editing complete); true when focus should move to the results shown. */
    fun submit(): Boolean = search.submit()

    /** Searches the field's text again after [CatalogSearchBody.Failed]. */
    fun retry() {
        search.run()
    }

    fun release() {
        scope.cancel()
    }

    private fun publish() {
        mutableState.value = build()
    }

    private fun build() = CatalogSearchUiState(
        title = T.explore.searchHint(sourceName),
        query = search.text,
        body = search.body(prompt = T.explore.searchPrompt(sourceName)),
    )
}
