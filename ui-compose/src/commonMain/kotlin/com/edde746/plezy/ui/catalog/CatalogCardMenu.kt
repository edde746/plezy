package com.edde746.plezy.ui.catalog

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.catalogItem
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.presentation.catalog.CatalogDetailHost
import com.edde746.plezy.presentation.catalog.CatalogItemMenu
import com.edde746.plezy.presentation.catalog.CatalogMenuAction
import com.edde746.plezy.presentation.catalog.CatalogMenuEntry
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.use24HourClock
import com.edde746.plezy.ui.icons.PlezyIcons
import kotlinx.coroutines.launch

/**
 * What a catalog card does (Explore's shelves, catalog search, a View All grid, More like this): [open] its detail
 * screen; its menu's entries ([menuEntries]) and what one does ([runMenu]: the message to show when it failed).
 */
class CatalogCardActions(
    val open: (CatalogItem) -> Unit,
    val menuEntries: suspend (CatalogItem) -> List<CatalogMenuEntry>,
    val runMenu: suspend (CatalogItem, CatalogMenuAction) -> String?,
)

/** [app]'s catalog card actions: the detail screen opens on [app]'s stack, the menu is [CatalogItemMenu]'s. */
@Composable
fun rememberCatalogCardActions(app: AppSession): CatalogCardActions {
    val host = rememberCatalogDetailHost(app)
    val scope = rememberCoroutineScope()
    return remember(app, host) {
        val menu = CatalogItemMenu(app.catalogSources, host, scope)
        CatalogCardActions(
            open = { app.navigator.navigate(Route.CatalogDetail(it)) },
            menuEntries = menu::entries,
            runMenu = menu::run,
        )
    }
}

/**
 * The catalog screens' [CatalogDetailHost] on Android and desktop: both have a browser, so links and the provider's
 * trailer open in it ([com.edde746.plezy.app.AppPlatform.openUrl]); a library copy's own trailer plays in [app]'s player.
 * Times read on the platform's 12/24-hour clock as it is when the detail is built.
 */
@Composable
fun rememberCatalogDetailHost(app: AppSession): CatalogDetailHost {
    val platform = LocalPlezyPlatform.current
    val clock24 by rememberUpdatedState(use24HourClock())
    return remember(platform, app) {
        object : CatalogDetailHost {
            override val hasBrowser = true

            override val use24HourClock get() = clock24

            override suspend fun youTubeAppInstalled() = false

            override fun openUrl(url: String) = platform.openUrl(url)

            override fun playTrailer(trailer: MediaItem) = app.playLibraryTrailer(trailer)
        }
    }
}

/**
 * Which catalog card's menu is open, and where each card is: on desktop the menu opens at its card, elsewhere it is a
 * sheet. Give each card [cardModifier] and its [open] on a long press, a right click or the Menu key.
 */
@Stable
class CatalogMenuState {
    private val cards = HashMap<String, LayoutCoordinates>()
    internal var shown by mutableStateOf<ShownMenu?>(null)

    fun cardModifier(cardId: String): Modifier = Modifier.onGloballyPositioned { cards[cardId] = it }

    /** Opens [item]'s menu, at its card [cardId]. */
    fun open(item: CatalogItem, cardId: String) {
        shown = ShownMenu(item, cardId)
    }

    /** [cardId]'s bounds in [root]'s, while both are on screen. */
    internal fun bounds(cardId: String, root: LayoutCoordinates?): Rect? {
        val card = cards[cardId]?.takeIf { it.isAttached } ?: return null
        return root?.takeIf { it.isAttached }?.localBoundingBoxOf(card)
    }

    internal class ShownMenu(val item: CatalogItem, val cardId: String)
}

/** The catalog item a card of [items] stands for, by the card's id. */
internal fun List<MediaItem>.catalogItemOf(cardId: String): CatalogItem? = firstOrNull { it.id == cardId }?.catalogItem

/**
 * [content] with the open catalog card's menu ([state]) over it: View details, Watch trailer, Open on <site>, Add to or
 * Remove from Watchlist ([CatalogItemMenu]); a dropdown at the card, a side panel on TV ([ItemMenu]). An entry's
 * failure goes to [onMessage]. Harness names: `catalog.menu.<i>`.
 */
@Composable
fun CatalogMenuHost(state: CatalogMenuState, actions: CatalogCardActions, onMessage: (String) -> Unit, modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit) {
    var root by remember { mutableStateOf<LayoutCoordinates?>(null) }
    // Outside the open menu: an entry's work (a watchlist change) outlives the menu it was picked in.
    val scope = rememberCoroutineScope()
    Box(modifier.onGloballyPositioned { root = it }) {
        content()
        val shown = state.shown ?: return@Box
        var entries by remember(shown) { mutableStateOf<List<CatalogMenuEntry>?>(null) }
        LaunchedEffect(shown) { entries = actions.menuEntries(shown.item) }
        val anchor = state.bounds(shown.cardId, root) ?: Rect.Zero
        val density = LocalDensity.current
        Box(
            Modifier
                .offset { IntOffset(anchor.left.toInt(), anchor.top.toInt()) }
                .size(with(density) { anchor.width.toDp() }, with(density) { anchor.height.toDp() }),
        ) {
            ItemMenu(
                expanded = entries != null,
                onDismiss = { state.shown = null },
                entries = entries.orEmpty().map { entry ->
                    ItemMenuEntry(entry.label, icon = entry.action.icon) {
                        val action = entry.action
                        if (action == CatalogMenuAction.ViewDetails) {
                            actions.open(shown.item)
                        } else {
                            scope.launch { actions.runMenu(shown.item, action)?.let(onMessage) }
                        }
                    }
                },
                probe = "catalog.menu",
                title = shown.item.title,
                media = true,
                contentTitle = true,
            )
        }
    }
}

private val CatalogMenuAction.icon
    get() = when (this) {
        CatalogMenuAction.ViewDetails -> PlezyIcons.Info
        is CatalogMenuAction.Trailer -> PlezyIcons.Trailer
        is CatalogMenuAction.Link -> PlezyIcons.OpenInNew
        is CatalogMenuAction.Watchlist -> if (add) PlezyIcons.BookmarkBorder else PlezyIcons.Bookmark
    }
