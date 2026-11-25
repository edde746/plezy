package com.edde746.plezy.ui.search

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.SearchHit
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.rankSearchHits
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.search.SearchDeps
import com.edde746.plezy.presentation.search.SearchFilter
import com.edde746.plezy.presentation.search.SearchStore
import com.edde746.plezy.servers.SearchAggregationResult
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.emptyFlow
import kotlin.test.Test
import kotlin.test.assertEquals

/** Picking a kind chip over scrolled results shows that kind's results from the top. */
@OptIn(ExperimentalTestApi::class)
class SearchFiltersTest {
    private val server = ServerId("a")
    private val items = (1..30).map { item("m$it", "Maestro Movie $it", MediaKind.MOVIE) } +
        (1..5).map { item("s$it", "Maestro Show $it", MediaKind.SHOW) }

    private fun item(id: String, title: String, kind: MediaKind) =
        MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = kind, title = title, serverId = "a", libraryId = "1")

    @Test
    fun `picking a filter shows its results from the top`() = runComposeUiTest {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val store = SearchStore(
            SearchDeps(
                search = { query, _ ->
                    SearchAggregationResult(rankSearchHits(items.map { SearchHit.Media(it) }, query, 100), items, emptyList(), setOf(server), emptySet(), emptySet())
                },
                hiddenLibrariesReady = {},
                hiddenLibraryKeys = { emptySet() },
                hiddenLibraryChanges = emptyFlow(),
                client = { null },
                serverCount = { 1 },
                libraryLabel = { null },
                cardOptions = { CardOptions() },
                open = {},
                menu = {},
                watchStates = emptyFlow(),
                fetchItem = { _, _ -> null },
            ),
            scope,
        )
        val list = LazyListState()
        try {
            setContent {
                val state by store.state.collectAsState()
                PlezyTheme {
                    AdaptiveLayout(FormFactor.DESKTOP) {
                        val memory = rememberFocusMemory()
                        Column(Modifier.size(800.dp, 600.dp)) {
                            SearchFilters(state, store, memory, list, PaddingValues(8.dp))
                            Box(Modifier.size(800.dp, 500.dp)) { SearchBody(state, store, memory, list, signInAgain = {}) {} }
                        }
                    }
                }
            }
            store.setQuery("Maestro")
            store.submit()
            // Under All, the movies and the shows each under their heading.
            waitUntil(timeoutMillis = 5_000) { list.layoutInfo.totalItemsCount == items.size + 2 }
            runOnIdle { list.requestScrollToItem(20) }
            waitForIdle()

            onNodeWithText(SearchFilter.Kind(MediaKind.MOVIE).label).performClick()
            waitForIdle()
            assertEquals(30, list.layoutInfo.totalItemsCount)
            assertEquals(0 to 0, list.firstVisibleItemIndex to list.firstVisibleItemScrollOffset)
        } finally {
            scope.cancel()
        }
    }
}
