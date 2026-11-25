package com.edde746.plezy.ui.explore

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.presentation.explore.CatalogSearchBody
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.ui.catalog.CatalogMenuHost
import com.edde746.plezy.ui.catalog.CatalogMenuState
import com.edde746.plezy.ui.catalog.catalogItemOf
import com.edde746.plezy.ui.catalog.rememberCatalogCardActions
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.SearchField
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.focus.FocusInto
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.probe.layoutProbe

/**
 * A catalog source's search ([route]; TV's Explore opens it): its title, the field (focused on arrival) and what it
 * found as a list, or the prompt, the search's failure with Retry or its empty answer. A row opens its title's detail,
 * a long press its menu. Harness names: `catalogSearch.*`.
 */
@Composable
fun CatalogSearchScreen(app: AppSession, route: Route.CatalogSearch, modifier: Modifier = Modifier) {
    val store = remember(app, route) { app.catalogSearch(route) } ?: return
    val state by store.state.collectAsState()
    val actions = rememberCatalogCardActions(app)
    val menu = remember { CatalogMenuState() }
    var message by remember { mutableStateOf<String?>(null) }
    val field = remember { FocusRequester() }
    val open = { items: List<MediaItem>, id: String -> items.catalogItemOf(id)?.let(actions.open) }
    val openMenu = { items: List<MediaItem>, id: String -> items.catalogItemOf(id)?.let { menu.open(it, id) } }
    CatalogMenuHost(menu, actions, onMessage = { message = it }, modifier.fillMaxSize().layoutProbe("catalogSearch", reportsFocus = false)) {
        val results = rememberLazyListState()
        Column(Modifier.fillMaxSize()) {
            ScreenHeader(state.title, onBack = app.navigator::back, scrolled = { results.canScrollBackward })
            SearchField(
                state.query,
                state.title,
                onText = store::setQuery,
                onSubmit = store::submit,
                probe = "catalogSearch.field",
                clearProbe = "catalogSearch.clear",
                modifier = Modifier.padding(horizontal = LocalPlezyDimens.current.screenPadding, vertical = 8.dp),
                fieldModifier = Modifier.focusRequester(field),
            )
            Box(Modifier.fillMaxSize()) {
                when (val body = state.body) {
                    is CatalogSearchBody.Idle -> EmptyState(body.prompt.orEmpty(), icon = PlezyIcons.Search)
                    CatalogSearchBody.Loading -> LoadingState()
                    is CatalogSearchBody.Failed -> ErrorState(body.text, onRetry = store::retry)
                    is CatalogSearchBody.Empty -> EmptyState(body.text, icon = PlezyIcons.Search)
                    is CatalogSearchBody.Results -> LazyColumn(Modifier.fillMaxSize().layoutProbe("catalogSearch.results", reportsFocus = false), state = results) {
                        catalogResults(body.items, open = { items, id -> open(items, id) }, openMenu = { items, id -> openMenu(items, id) })
                        item { Box(Modifier.fillMaxWidth().height(16.dp)) }
                    }
                }
            }
        }
        message?.let { text ->
            TimedToast(text, "catalogSearch.message", onShown = { message = null }, Modifier.align(Alignment.BottomCenter).padding(bottom = LocalPlezyDimens.current.sectionSpacing))
        }
    }
    FocusInto(field, Unit)
}
