package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.detail.InfoRowUi
import com.edde746.plezy.presentation.detail.PersonStore
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * An actor's titles on one server ([Route.Person]) as a folder screen: their name with Back, then their photo
 * (a circle) beside the character they played and the title count, their facts (born, died, birthplace) and their
 * biography (four lines, then More), over the grid of their titles, loaded in pages ([PagedGridScreen]); a title's
 * long press (a right click, the remote's Menu) opens its item menu. Focus starts on the first title; Up from the first
 * row reaches the biography's More where it has one, else Back; Back leaves. Harness name `person`.
 */
@Composable
fun PersonScreen(app: AppSession, route: Route.Person, modifier: Modifier = Modifier) {
    val store = remember(app, route) { app.person(route) } ?: return
    PersonPage(
        store,
        onBack = { app.navigator.back() },
        onOpen = app.navigator::navigate,
        onMenu = { item -> app.mediaActions.menu.open(item, MenuPlace()) },
        modifier,
    )
}

/** [PersonScreen] over its [store]: [onBack] leaves, [onOpen] opens a title's screen, [onMenu] its menu. */
@Composable
internal fun PersonPage(store: PersonStore, onBack: () -> Unit, onOpen: (Route) -> Unit, onMenu: (MediaItem) -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    val memory = rememberFocusMemory()
    val grid = rememberLazyGridState()
    PagedGridScreen(
        state.name,
        state.grid,
        state.settled,
        state.grid.items.firstOrNull()?.shape ?: CardShape.POSTER,
        T.discover.noContentAvailable,
        memory,
        grid,
        onBack = onBack,
        onEnsureLoaded = store::ensureLoaded,
        onRetry = store::retry,
        onOpen = { card -> store.routeFor(card.id)?.let(onOpen) },
        modifier = modifier.layoutProbe("person", reportsFocus = false),
        onMenu = { card -> store.item(card.id)?.let(onMenu) },
    ) {
        item(key = "header", span = { GridItemSpan(maxLineSpan) }) {
            PersonHeader(state.image, state.characterName, state.titleCount, state.facts, state.biography, memory)
        }
    }
    RestoreFocus(memory, ready = state.grid.items.isNotEmpty(), fallback = firstCardKey(state.grid))
}

/**
 * A person page's header over their titles: their photo (a circle) beside [subtitle] (the character they played, what
 * they are known for) and the title count, then their facts and their biography (four lines, then More). On TV the
 * facts sit beside the photo, so the whole header still shows above the focused first row of titles.
 */
@Composable
internal fun PersonHeader(image: Artwork?, subtitle: String?, titleCount: String?, facts: List<InfoRowUi>, biography: String?, memory: FocusMemory) {
    val tv = LocalAppearance.current.tv
    Column(Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp), verticalAlignment = Alignment.CenterVertically) {
            PersonPhoto(image, Modifier.size(80.dp))
            Column(Modifier.weight(1f)) {
                subtitle?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, maxLines = 1, overflow = TextOverflow.Ellipsis) }
                titleCount?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, maxLines = 1) }
            }
            // Plain text here: the grid's Up goes past it to the biography or Back.
            if (tv && facts.isNotEmpty()) Information(facts, Modifier.weight(2f), focusStop = false)
        }
        if (!tv && facts.isNotEmpty()) Information(facts, focusStop = false)
        biography?.let {
            Overview(it, memory, up = null, Modifier.widthIn(max = 800.dp), lines = 4)
        }
    }
}
