package com.edde746.plezy.ui.detail

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.detail.CollectionUiState
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.BusyOverlay
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.CyclingBackdrop
import com.edde746.plezy.ui.components.FoldingActionRow
import com.edde746.plezy.ui.components.RowAction
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.aspectRatio
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.fadeStops
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.focus.tvRow
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.icons.watchedIcon
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.navigation.NavigationBackdrop
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.launch
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.presentation.detail.CollectionStore

/**
 * A collection's items ([Route.CollectionDetail]) as a folder screen: its backdrop faded behind the top where
 * it has one, its title with Back ([ScreenHeader][com.edde746.plezy.ui.components.ScreenHeader]), then its poster
 * (square for music) beside the meta line ("12 items  ·  1999–2021  ·  PG-13") and the summary (three lines, then
 * More), Play and Shuffle under them (once it has items; the queue's loading dialog with Cancel while it builds), and
 * the grid of its items, loaded in pages ([PagedGridScreen]). Opened from a downloads folder ([CollectionUiState.offline])
 * Mark as watched or unwatched and Delete downloads (asked first; the screen goes back once deleted) take Play's and
 * Shuffle's place. Its messages (an empty or failed play) show as toasts. Focus starts on the first item; Up from the
 * first row reaches the actions. Back from an item (keyboard, remote) scrolls to the top and focuses the first action;
 * Back again leaves. Harness names `collection`, `collection.<play|shuffle|watched|deleteDownloads>`.
 */
@Composable
fun CollectionScreen(app: AppSession, route: Route.CollectionDetail, modifier: Modifier = Modifier) {
    val store = remember(app, route) { app.collection(route) } ?: return
    val state by store.state.collectAsState()
    LeaveWhenGone(state.gone, route, app.navigator)
    CollectionPage(
        store,
        onBack = { app.navigator.back() },
        onOpen = app.navigator::navigate,
        // Inside the collection, an item's menu offers Remove from collection.
        onMenu = { item -> app.mediaActions.menu.open(item, MenuPlace(collectionId = route.collectionId)) },
        modifier,
    )
}

/** [CollectionScreen] over its [store]: [onBack] leaves, [onOpen] opens an item's screen, [onMenu] its menu. */
@Composable
internal fun CollectionPage(store: CollectionStore, onBack: () -> Unit, onOpen: (Route) -> Unit, onMenu: (MediaItem) -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    val memory = rememberFocusMemory()
    val grid = rememberLazyGridState()
    val scope = rememberCoroutineScope()
    var gridFocus by remember { mutableStateOf(false) }
    var headerFocus by remember { mutableStateOf(false) }
    val actions = state.canPlay || state.offline != null
    SystemBackHandler(enabled = gridFocus && !headerFocus && actions) {
        scope.launch {
            grid.animateScrollToItem(0)
            memory.focus(PLAY_KEY) || memory.focus(DELETE_KEY)
        }
    }
    val shape = if (state.square) CardShape.SQUARE else CardShape.POSTER
    Box(modifier.fillMaxSize().layoutProbe("collection", reportsFocus = false)) {
        if (state.settled && state.backdrops.isNotEmpty()) FolderBackdrop(store, state.backdrops)
        PagedGridScreen(
            state.title,
            state.grid,
            state.settled,
            shape,
            T.collections.empty,
            memory,
            grid,
            onBack = onBack,
            onEnsureLoaded = store::ensureLoaded,
            onRetry = store::retry,
            onOpen = { card -> store.routeFor(card.id)?.let(onOpen) },
            modifier = Modifier.onFocusChanged { gridFocus = it.hasFocus },
            onMenu = { card -> store.item(card.id)?.let(onMenu) },
        ) {
            item(key = "header", span = { GridItemSpan(maxLineSpan) }) {
                CollectionHeader(state, shape, memory, Modifier.onFocusChanged { headerFocus = it.hasFocus }) {
                    CollectionActions(state, store::play, store::shuffle, store::toggleWatched, store::deleteDownloads, memory)
                }
            }
        }
        state.message?.let { TimedToast(it, "collection.toast", onShown = store::messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = 24.dp)) }
    }
    state.launching?.let { BusyOverlay(it, store::cancelLaunch, "collection.launching") }
    if (state.offline?.confirmingDelete == true) {
        ConfirmDialog(
            T.downloads.deleteCollectionDownloads,
            T.downloads.deleteCollectionDownloadsConfirm(title = state.title),
            T.common.delete,
            onConfirm = { store.confirmDelete(true) },
            onCancel = { store.confirmDelete(false) },
            probe = "settings.confirm",
            confirmProbe = "settings.confirm.ok",
        )
    }
    RestoreFocus(memory, ready = state.grid.items.isNotEmpty(), fallback = firstCardKey(state.grid))
}

private const val DELETE_KEY = "delete"

/**
 * The backdrop behind the top of the screen, as Home's: the collection's backgrounds in turn ([CyclingBackdrop], [key]
 * the collection), dimmed over the page and fading into it toward the bottom and the start, reaching under the side
 * navigation ([NavigationBackdrop]).
 */
@Composable
private fun FolderBackdrop(key: Any, backdrops: List<Artwork>) {
    val page = PlezyColors.Background
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    NavigationBackdrop(Modifier.fillMaxWidth().fillMaxHeight(0.7f)) {
        CyclingBackdrop(key, backdrops, Modifier.matchParentSize().graphicsLayer { alpha = BACKDROP_ALPHA }, fill = Color.Transparent)
        Box(
            Modifier.matchParentSize().drawWithCache {
                val down = Brush.verticalGradient(*fadeStops(page, 0.3f, 1f, from = 0f, to = 1f))
                val stops = fadeStops(page, 0f, BACKDROP_FADE, from = 1f, to = 0f)
                val across = if (rtl) Brush.horizontalGradient(*stops, startX = size.width, endX = 0f) else Brush.horizontalGradient(*stops, startX = 0f, endX = size.width)
                onDrawBehind {
                    drawRect(across)
                    drawRect(down)
                }
            },
        )
    }
}

/** How much of the picture shows through the backdrop's dimming, and how far across from the start it fades. */
private const val BACKDROP_ALPHA = 0.3f
private const val BACKDROP_FADE = 0.6f

/** The poster beside the meta line and the summary, with [actions] under both. */
@Composable
private fun CollectionHeader(state: CollectionUiState, shape: CardShape, memory: FocusMemory, modifier: Modifier, actions: @Composable () -> Unit) {
    val dimens = LocalPlezyDimens.current
    Column(modifier.fillMaxWidth().padding(top = 4.dp, bottom = 12.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Box(
                Modifier
                    .width(dimens.cardWidth(shape))
                    .aspectRatio(shape.aspectRatio)
                    .clip(MaterialTheme.shapes.medium)
                    .background(PlezyColors.SurfaceHigh),
            ) {
                RemoteImage(
                    state.poster,
                    contentDescription = null,
                    modifier = Modifier.matchParentSize(),
                    error = { ArtworkPlaceholder(PlaceholderKind.COLLECTION) },
                )
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                state.metaLine?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted) }
                state.summary?.let { Overview(it, memory, up = null, Modifier.widthIn(max = 720.dp)) }
            }
        }
        if (state.canPlay || state.offline != null) actions()
    }
}

/**
 * The collection's [FoldingActionRow]: Play and a round Shuffle; a downloads folder's watched toggle (once it has items)
 * and its deletion in their place; the round one folds into ⋮ (`collection.more`) where the width runs out. A D-pad's
 * move into the row lands on its first action. Harness name `collection.actions`.
 */
@Composable
private fun CollectionActions(
    state: CollectionUiState,
    play: () -> Unit,
    shuffle: () -> Unit,
    toggleWatched: () -> Unit,
    deleteDownloads: () -> Unit,
    memory: FocusMemory,
) {
    val offline = state.offline
    val fold = if (offline != null) {
        listOf(RowAction(PlezyIcons.Delete, T.downloads.deleteCollectionDownloads, "collection.deleteDownloads", Modifier.rememberFocus(memory, DELETE_KEY), onClick = deleteDownloads))
    } else {
        listOf(RowAction(PlezyIcons.Shuffle, T.common.shuffle, "collection.shuffle", Modifier.rememberFocus(memory, "shuffle"), onClick = shuffle))
    }
    FoldingActionRow("collection.actions", fold, "collection.more", Modifier.tvRow { memory.focus(PLAY_KEY) || memory.focus(DELETE_KEY) }) {
        if (offline == null) {
            PlezyButton(T.common.play, play, Modifier.rememberFocus(memory, PLAY_KEY).layoutProbe("collection.play"), style = ButtonStyle.PRIMARY, icon = PlezyIcons.PlayArrow)
        } else if (state.grid.items.isNotEmpty()) {
            PlezyButton(
                if (offline.allWatched) T.mediaMenu.markAsUnwatched else T.mediaMenu.markAsWatched,
                toggleWatched,
                Modifier.rememberFocus(memory, PLAY_KEY).layoutProbe("collection.watched"),
                icon = watchedIcon(offline.allWatched),
            )
        }
    }
}

