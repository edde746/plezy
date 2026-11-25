package com.edde746.plezy.ui.playlists

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.layout.hubShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.playlists.PlaylistDetailStore
import com.edde746.plezy.presentation.playlists.PlaylistRow
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.cast.CastButton
import com.edde746.plezy.ui.cast.castInTopBar
import com.edde746.plezy.ui.components.FoldingActionRow
import com.edde746.plezy.ui.components.RowAction
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.MoreFooter
import com.edde746.plezy.ui.components.gridTop
import com.edde746.plezy.ui.components.CardArtwork
import com.edde746.plezy.ui.components.RowInset
import com.edde746.plezy.ui.components.rowArtworkWidth
import com.edde746.plezy.ui.components.aspectRatio
import com.edde746.plezy.ui.detail.EpisodeListRow
import com.edde746.plezy.ui.components.MediaGrid
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.components.rememberReorderState
import com.edde746.plezy.ui.components.reorderDrag
import com.edde746.plezy.ui.components.reorderItem
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * A playlist ([Route.PlaylistDetail]): its title ("Smart playlist" under a smart one's), under it its [FoldingActionRow]
 * (the Play pill, the cast button (on phones it sits at the header's end instead, across from Back: [castInTopBar]),
 * Shuffle, Edit and Delete, the last ones folded into ⋮ `playlist.more` where the width runs out), then its entries. A
 * smart playlist is a read-only grid whose cards play the playlist from themselves. Another is a list of rows: the row
 * plays from itself; a long press, a right click or the Menu key opens the item's menu. Edit mode (Done in the top
 * bar, before the phone's cast button, or Back, leaves it), as on the music playlist page: a row's handle drags it to a
 * new place (pointer) or, selected, starts move mode (Up and Down move it, Select saves, Back puts it back), its ✕
 * removes it. Under a keyboard or remote focus starts on Play (on the first entry where there is no Play); from a row
 * Left goes to its handle, Right to its ✕, and in Edit mode Down from Done goes to the first row's handle. Harness
 * names: `playlist`, `playlist.actions`, `playlist.<play|shuffle|edit|delete|done|more|retry>`,
 * `playlist.row.<i>[.handle|.remove]`.
 */
@Composable
fun PlaylistDetailScreen(app: AppSession, route: Route.PlaylistDetail, modifier: Modifier = Modifier) {
    val store = remember(app, route) { app.playlistDetail(route) } ?: return
    PlaylistPage(store, onBack = { app.navigator.back() }, modifier)
}

/** [PlaylistDetailScreen] over its [store]: [onBack] leaves. */
@Composable
internal fun PlaylistPage(store: PlaylistDetailStore, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    val appearance = LocalAppearance.current
    val dimens = LocalPlezyDimens.current
    val memory = rememberFocusMemory()
    val touch = LocalInputModeManager.current.inputMode == InputMode.Touch
    SystemBackHandler(enabled = state.editing || state.moving != null) { if (!store.cancelMove()) store.edit(false) }
    // Under a remote or a keyboard, Edit hands focus to Done (Edit leaves the row); leaving Edit mode hands it to Play.
    val doneFocus = remember { FocusRequester() }
    val handles = remember { EditHandles() }
    val playFocus = remember { FocusRequester() }
    var wasEditing by remember { mutableStateOf(false) }
    LaunchedEffect(state.editing) {
        if (state.editing) doneFocus.requestFocus() else if (wasEditing && state.canPlay) playFocus.requestFocus()
        wasEditing = state.editing
    }
    Column(modifier.fillMaxSize().padding(top = statusBarOverlap).layoutProbe("playlist", reportsFocus = false)) {
        val list = rememberLazyListState()
        val grid = rememberLazyGridState()
        ScreenHeader(
            state.title,
            subtitle = if (state.smart) T.playlists.smartPlaylist else null,
            onBack = {
                when {
                    store.cancelMove() -> Unit
                    state.editing -> store.edit(false)
                    else -> onBack()
                }
            },
            contentTitle = true,
            scrolled = { if (state.smart) grid.canScrollBackward else list.canScrollBackward },
            actions = if (state.editing || (castInTopBar && state.canPlay)) {
                {
                    if (state.editing) PlezyButton(T.common.doneEditing, { store.edit(false) }, handles.downFrom(Modifier.focusRequester(doneFocus)).layoutProbe("playlist.done"), style = ButtonStyle.PRIMARY, icon = PlezyIcons.Check)
                    if (castInTopBar && state.canPlay) CastButton()
                }
            } else {
                null
            },
        )
        if (state.canPlay || state.canDelete) {
            val fold = listOfNotNull(
                RowAction(PlezyIcons.Shuffle, T.common.shuffle, "playlist.shuffle") { store.play(shuffle = true) }.takeIf { state.canPlay },
                // Kept in place, dimmed, in Edit mode: nothing slides under a second tap.
                RowAction(PlezyIcons.Edit, T.common.edit, "playlist.edit", enabled = state.editable && !state.editing) { store.edit(true) }.takeIf { state.canDelete },
                RowAction(PlezyIcons.Delete, T.playlists.delete, "playlist.delete", enabled = !state.editing, onClick = store::delete).takeIf { state.canDelete },
            )
            FoldingActionRow("playlist.actions", fold, "playlist.more", Modifier.padding(start = dimens.screenPadding, end = dimens.screenPadding, bottom = 8.dp)) {
                if (state.canPlay) {
                    PlezyButton(T.common.play, { store.play(shuffle = false) }, Modifier.focusRequester(playFocus).rememberFocus(memory, PLAY_KEY).layoutProbe("playlist.play"), style = ButtonStyle.PRIMARY, icon = PlezyIcons.PlayArrow)
                    if (!castInTopBar) CastButton()
                }
            }
        }
        Box(Modifier.fillMaxSize()) {
            when {
                state.error != null -> ErrorState(state.error.orEmpty(), onRetry = store::load)
                state.loading -> LoadingState()
                state.empty -> EmptyState(T.playlists.emptyPlaylist)
                state.smart -> {
                    val rows = state.rows
                    val shape = remember(rows, state.audio, appearance.episodeThumbnails) {
                        if (state.audio) CardShape.SQUARE else hubShape(rows.map { it.card.shape }, appearance.episodeThumbnails)
                    }
                    MediaGrid(
                        rows.size,
                        { rows.getOrNull(it)?.card },
                        shape,
                        PaddingValues(start = dimens.screenPadding, end = dimens.screenPadding, top = dimens.gridTop, bottom = dimens.sectionSpacing),
                        state = grid,
                        onClick = { card -> store.playFrom(rows.indexOfFirst { it.card.id == card.id }) },
                        cardModifier = { _, card -> Modifier.rememberFocus(memory, card.id) },
                        onLongClick = { card -> store.openMenu(rows.indexOfFirst { it.card.id == card.id }) },
                        loadingMore = state.loadingMore,
                        moreError = state.moreError,
                        onRetryMore = store::retryMore,
                    )
                }
                else -> PlaylistRows(state.rows, state.editing, state.editable, state.moving, store, memory, state.loadingMore, state.moreError, handles, list)
            }
        }
    }
    val first = if (state.canPlay) PLAY_KEY else state.rows.firstOrNull()?.key
    RestoreFocus(memory, ready = first != null, fallback = first?.takeIf { !touch })
}

/** The focus memory's key of a playlist's Play. */
private const val PLAY_KEY = "playlist.play"

/**
 * The move handles of a playlist's composed Edit-mode rows, by index: Down from Done ([downFrom]) goes to the first
 * one's rather than by geometry to the ✕ under Done, one OK from removing an item; with none composed, focus finds its
 * own way.
 */
internal class EditHandles {
    private val composed = mutableStateMapOf<Int, FocusRequester>()

    /** [modifier] (Done's, before its focus target) with Down going to the first composed handle. */
    fun downFrom(modifier: Modifier): Modifier = modifier.focusProperties { down = composed.minByOrNull { it.key }?.value ?: FocusRequester.Default }

    /** Registers the handle ([requester]) of the row at [index] while it is composed. */
    @Composable
    fun Register(index: Int, requester: FocusRequester) {
        DisposableEffect(index, requester) {
            composed[index] = requester
            onDispose { if (composed[index] === requester) composed.remove(index) }
        }
    }
}

/**
 * Move mode's [list]: the list stays where it is while the moving row's new place is wholly in view, else it brings the
 * row before it to the top (the moving one where it is the first); once Back puts the row back, the same for its old
 * place. Set on the very measure that lays out each new order ([keys]): left to the list, which keeps its place by its
 * first row's key, a step or the order Back restores could carry the moving row, its handle focused, off the top.
 * [before]: the list's items ahead of the rows (a header).
 */
@Composable
internal fun FollowMovingRow(list: LazyListState, keys: List<String>, moving: Int?, before: Int = 0) {
    val last = remember { MovingRow(keys) }
    SideEffect {
        val reordered = last.keys != keys
        last.keys = keys
        fun follow(row: Int) {
            val item = row + before
            val layout = list.layoutInfo
            val shown = layout.visibleItemsInfo.filter { it.offset >= layout.viewportStartOffset && it.offset + it.size <= layout.viewportEndOffset }
            if (shown.isNotEmpty() && item in shown.first().index..shown.last().index) {
                list.requestScrollToItem(list.firstVisibleItemIndex, list.firstVisibleItemScrollOffset)
            } else {
                list.requestScrollToItem((item - 1).coerceAtLeast(0))
            }
        }
        if (moving != null) {
            if (reordered || last.key != keys.getOrNull(moving)) follow(moving)
            last.key = keys.getOrNull(moving)
        } else if (reordered && last.key != null) {
            // The first new order after move mode: Back's (after a save, the next change, whose list follows the row too).
            keys.indexOf(last.key).takeIf { it >= 0 }?.let(::follow)
            last.key = null
        }
    }
}

/** [FollowMovingRow]'s memory: the order it last saw, and the row move mode moves (or last moved). */
private class MovingRow(var keys: List<String>) {
    var key: String? = null
}

@Composable
internal fun PlaylistRows(
    rows: List<PlaylistRow>,
    editing: Boolean,
    editable: Boolean,
    moving: Int?,
    store: PlaylistDetailStore,
    memory: FocusMemory,
    loadingMore: Boolean,
    moreError: String?,
    handles: EditHandles,
    list: LazyListState = rememberLazyListState(),
) {
    val reorder = rememberReorderState(0.dp)
    // Resolved by key against the rows as they are at the drop.
    val current by rememberUpdatedState(rows)
    val drop = { key: String, to: Int ->
        val from = current.indexOfFirst { it.key == key }
        if (from >= 0) store.move(from, to)
    }
    // Move mode keeps the moving row in view as it goes.
    FollowMovingRow(list, remember(rows) { rows.map { it.key } }, moving)
    val side = (LocalPlezyDimens.current.screenPadding - RowInset).coerceAtLeast(0.dp)
    LazyColumn(Modifier.fillMaxSize(), state = list, contentPadding = PaddingValues(start = side, end = side, bottom = LocalPlezyDimens.current.sectionSpacing)) {
        itemsIndexed(rows, key = { _, row -> row.key }) { index, row ->
            PlaylistRowItem(
                row = row,
                index = index,
                editing = editing,
                editable = editable,
                moving = moving == index,
                store = store,
                handles = handles,
                focus = Modifier.rememberFocus(memory, row.key),
                modifier = Modifier
                    .then(if (reorder.dragging == null) Modifier.animateItem() else Modifier)
                    .reorderItem(reorder, row.key, index),
                handle = if (editable) Modifier.reorderDrag(reorder, row.key, index, rows.size, drop) else Modifier,
            )
        }
        if (loadingMore || moreError != null) item(key = "more") { MoreFooter(moreError, store::retryMore) }
    }
}

/**
 * One entry, as an episode's row ([EpisodeListRow]): in Edit mode ([editing]) the drag handle (swap arrows in move
 * mode) before it, then its artwork (a poster, a thumbnail, a square for a track, which stays beside the text at a
 * large font scale), its title, its subtitle and length on one line, and in Edit mode ✕ at its end. Move mode tints the
 * whole row, handle to ✕ ([editRowFrame]), and turns Up and Down into moves, Select into the save; the handle takes focus as
 * it starts, so the keys move the row however move mode began (a click included). While a change is on its way
 * ([editable] false) the handle and ✕ wait; in Edit mode the row has no menu.
 */
@Composable
private fun PlaylistRowItem(
    row: PlaylistRow,
    index: Int,
    editing: Boolean,
    editable: Boolean,
    moving: Boolean,
    store: PlaylistDetailStore,
    handles: EditHandles,
    modifier: Modifier,
    focus: Modifier,
    handle: Modifier,
) {
    val handleFocus = remember { FocusRequester() }
    val shape = if (row.square) CardShape.SQUARE else row.card.shape
    Row(modifier.fillMaxWidth().editRowFrame(editing, moving), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(EditRowGap)) {
        if (editing) {
            handles.Register(index, handleFocus)
            PlezyIconButton(
                if (moving) PlezyIcons.SwapVert else PlezyIcons.DragIndicator,
                T.libraries.dragToReorderNamed(row.card.title),
                {
                    if (moving) {
                        store.confirmMove()
                    } else {
                        store.startMove(index)
                        handleFocus.requestFocus()
                    }
                },
                handle
                    .focusRequester(handleFocus)
                    .onPreviewKeyEvent { event ->
                        if (!moving || event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                        when (event.key) {
                            Key.DirectionUp -> store.step(-1).let { true }
                            Key.DirectionDown -> store.step(1).let { true }
                            else -> false
                        }
                    }
                    .layoutProbe("playlist.row.$index.handle"),
                style = IconButtonStyle.PLAIN,
                enabled = editable || moving,
            )
        }
        EpisodeListRow(
            title = row.card.title,
            infoLine = listOfNotNull(row.subtitle.ifEmpty { null }, row.duration).joinToString("  ·  ").ifEmpty { null },
            overview = null,
            onClick = { store.playFrom(index) },
            modifier = Modifier.weight(1f).then(focus).then(if (editing) Modifier else Modifier.menuGestures { store.openMenu(index) }).layoutProbe("playlist.row.$index"),
            keepsArtworkBeside = row.square,
            onLongClick = if (editing) null else ({ store.openMenu(index) }),
        ) {
            CardArtwork(row.card, Modifier.width(rowArtworkWidth(shape)).aspectRatio(shape.aspectRatio), MaterialTheme.shapes.small)
        }
        // Beside the row rather than inside it, so Right from the row reaches it.
        if (editing) {
            PlezyIconButton(
                PlezyIcons.Close,
                T.playlists.removeItem,
                { store.remove(index) },
                Modifier.layoutProbe("playlist.row.$index.remove"),
                style = IconButtonStyle.PLAIN,
                enabled = editable,
            )
        }
    }
}

/**
 * The gap between an Edit-mode row's handle and the row (both playlist pages): the handle's focus circle keeps clear of
 * the row's focus fill and its artwork.
 */
internal val EditRowGap = 12.dp

/**
 * An Edit-mode row's frame (both playlist pages): move mode's tint on the moving row, the whole row from handle to ✕,
 * with the row inset inside it so the handle's focus circle stays within the tint. Outside Edit mode, none.
 */
@Composable
internal fun Modifier.editRowFrame(editing: Boolean, moving: Boolean): Modifier =
    if (!editing) this else (if (moving) background(PlezyColors.HoverTint, RoundedCornerShape(12.dp)) else this).padding(horizontal = 4.dp)
