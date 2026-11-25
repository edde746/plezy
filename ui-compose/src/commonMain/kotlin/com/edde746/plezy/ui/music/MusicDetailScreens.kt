package com.edde746.plezy.ui.music

import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.gestures.BringIntoViewSpec
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.rememberReorderState
import com.edde746.plezy.ui.components.reorderDrag
import com.edde746.plezy.ui.components.reorderItem
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.MediaMenu
import com.edde746.plezy.presentation.browse.RowAction as OnRow
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.music.AlbumRow
import com.edde746.plezy.presentation.music.AlbumStore
import com.edde746.plezy.presentation.music.ArtistStore
import com.edde746.plezy.presentation.music.MusicPlaylistStore
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.GroupHeader
import com.edde746.plezy.ui.components.RowInset
import com.edde746.plezy.ui.components.SectionTitle
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.PosterCard
import com.edde746.plezy.ui.components.mediaGridCells
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.RowAction
import com.edde746.plezy.ui.cast.CastButton
import com.edde746.plezy.ui.cast.castInTopBar
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.downloads.DetailDownloadButton
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.playlists.EditHandles
import com.edde746.plezy.ui.playlists.EditRowGap
import com.edde746.plezy.ui.playlists.editRowFrame
import com.edde746.plezy.ui.playlists.FollowMovingRow

/** The room a list keeps past its last row. */
@Composable
private fun bottomPadding() = LocalPlezyDimens.current.sectionSpacing * 2

/** A music screen's header: Back, and on phones the cast button at its end ([castInTopBar]), out of the actions' row. */
@Composable
private fun MusicScreenHeader(onBack: () -> Unit, scrolled: () -> Boolean) {
    ScreenHeader("", onBack = onBack, scrolled = scrolled) { if (castInTopBar) CastButton() }
}

/** A track list's side padding: the screen's, less the rows' own inset, so their text lines up with the header's. */
@Composable
private fun trackListPadding() = (LocalPlezyDimens.current.screenPadding - RowInset).coerceAtLeast(0.dp)

/**
 * An artist: the circular portrait, name, genres and bio with Play, Shuffle and Instant Mix, over the discography as
 * titled square grids (one untitled grid for one group); a card's long press opens its album's item [menu].
 */
@Composable
fun ArtistScreen(store: ArtistStore, menu: MediaMenu, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    val appearance = LocalAppearance.current
    val gap = LocalPlezyDimens.current.gutter
    val side = (LocalPlezyDimens.current.screenPadding - 3.dp).coerceAtLeast(8.dp)
    Column(modifier.fillMaxSize().layoutProbe("music.artist", reportsFocus = false)) {
        val grid = rememberLazyGridState()
        MusicScreenHeader(onBack, scrolled = { grid.canScrollBackward })
        val header = state.header
        when {
            state.load == LoadState.LOADING -> LoadingState()
            header == null -> MusicLoadFailed(state.load, state.error, store::retry)
            else -> Box(Modifier.weight(1f).fillMaxWidth()) {
                LazyVerticalGrid(
                    mediaGridCells(CardShape.SQUARE, appearance),
                    state = grid,
                    contentPadding = PaddingValues(start = side, end = side, bottom = bottomPadding()),
                    horizontalArrangement = Arrangement.spacedBy(gap),
                    verticalArrangement = Arrangement.spacedBy(gap),
                ) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        MusicDetailHeader(header, PlaceholderKind.ARTIST, compactArtwork = 140, onArtist = null, actions = {
                            MusicActions(store::play, store::shuffle, if (state.instantMix) store::instantMix else null)
                        })
                    }
                    when (state.load) {
                        LoadState.ERROR -> item(span = { GridItemSpan(maxLineSpan) }) { ErrorState(state.error.orEmpty(), onRetry = store::retry) }
                        LoadState.LOADING -> {}
                        LoadState.EMPTY -> item(span = { GridItemSpan(maxLineSpan) }) { EmptyState(T.messages.noItemsAvailable, icon = PlezyIcons.Album) }
                        LoadState.CONTENT -> state.sections.forEachIndexed { index, section ->
                            section.title?.let { title ->
                                item(key = "section$index", span = { GridItemSpan(maxLineSpan) }) {
                                    SectionTitle(title, Modifier.padding(start = 3.dp, top = 8.dp).layoutProbe("music.section.$index"))
                                }
                            }
                            itemsIndexed(section.cards, key = { _, card -> card.id }) { cardIndex, card ->
                                PosterCard(
                                    card,
                                    onClick = { store.open(card.id) },
                                    modifier = Modifier.fillMaxWidth().layoutProbe("music.card.$index.$cardIndex"),
                                    shape = CardShape.SQUARE,
                                    onLongClick = { store.card(card.id)?.let { menu.open(it, store.menuPlace) } },
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * An album: the cover, title, artist (opens the artist) and "year · N tracks · length" with Play, Shuffle, Instant
 * Mix and ⋮ (the album's item [menu]), over the track rows with a "Disc N" group header per disc on a multi-disc album.
 */
@Composable
fun AlbumScreen(store: AlbumStore, menu: MediaMenu, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    Column(modifier.fillMaxSize().layoutProbe("music.album", reportsFocus = false)) {
        val list = rememberLazyListState()
        MusicScreenHeader(onBack, scrolled = { list.canScrollBackward })
        val header = state.header
        when {
            state.load == LoadState.LOADING -> LoadingState()
            header == null -> MusicLoadFailed(state.load, state.error, store::retry)
            else -> LazyColumn(Modifier.weight(1f).fillMaxWidth(), state = list, contentPadding = PaddingValues(start = trackListPadding(), end = trackListPadding(), bottom = bottomPadding())) {
                item {
                    MusicDetailHeader(
                        header,
                        PlaceholderKind.ALBUM,
                        compactArtwork = 200,
                        onArtist = if (header.artistLinked) store::openArtist else null,
                        actions = {
                            MusicActions(
                                store::play,
                                store::shuffle,
                                if (state.instantMix) store::instantMix else null,
                                more = RowAction(PlezyIcons.MoreVert, T.common.options, "music.album.more") {
                                    // Without what the row shows: Play, Instant Mix (on the row or in its fold), the download.
                                    val onRow = setOfNotNull(
                                        OnRow.PLAY,
                                        OnRow.INSTANT_MIX.takeIf { state.instantMix },
                                        OnRow.DOWNLOAD.takeIf { state.download != null },
                                    )
                                    store.item?.let { menu.open(it, store.menuPlace, onRow = onRow) }
                                },
                            ) {
                                state.download?.let { DetailDownloadButton(it, store::download, Modifier.layoutProbe("music.album.download")) }

                            }
                        },
                    )
                    Spacer(Modifier.height(8.dp))
                }
                itemsIndexed(state.rows, key = { _, row -> if (row is AlbumRow.Track) row.row.key else "disc${(row as AlbumRow.DiscHeader).disc}" }) { index, row ->
                    when (row) {
                        is AlbumRow.DiscHeader -> GroupHeader(row.label)
                        is AlbumRow.Track -> TrackRow(
                            row.row,
                            current = row.row.globalKey == state.playingKey,
                            playing = state.playing,
                            onClick = { store.playFrom(row.row.index) },
                            onMenu = { store.track(row.row.index)?.let { menu.open(it, store.menuPlace) } },
                        )
                    }
                }
                if (state.load == LoadState.ERROR) item { ErrorState(state.error.orEmpty(), onRetry = store::retry) }
            }
        }
    }
}

/**
 * An audio playlist: its cover and "N tracks · length" with Play, Shuffle, Edit and Delete Playlist (the last ones
 * folded into ⋮ where the width runs out; Delete asks first), over its tracks ("Artist · Album", each with its artwork),
 * each with its item [menu]. Edit mode (Done in the top bar, or Back, leaves it) edits the playlist as the video
 * playlist screen does: a row's handle drags it to a new place (pointer) or, selected, starts move mode (Up and Down move
 * it, Select saves, Back puts it back), its ✕ removes it; Down from Done goes to the first row's handle. Taking focus,
 * a row never leaves the header (artwork, title and actions) cut in half ([WholeHeaderSpec]). Harness names:
 * `music.playlist`, `music.playlist.<edit|delete|done>`, `music.track.<i>[.handle|.remove]`.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MusicPlaylistScreen(store: MusicPlaylistStore, menu: MediaMenu, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by store.state.collectAsState()
    SystemBackHandler(enabled = state.editing) { if (!store.cancelMove()) store.edit(false) }
    // Under a remote or a keyboard, Edit hands focus to Done (Edit leaves the row); leaving Edit mode hands it to Play.
    val doneFocus = remember { FocusRequester() }
    val handles = remember { EditHandles() }
    var leftEdit by remember { mutableIntStateOf(0) }
    var wasEditing by remember { mutableStateOf(false) }
    LaunchedEffect(state.editing) {
        if (state.editing) doneFocus.requestFocus() else if (wasEditing) leftEdit++
        wasEditing = state.editing
    }
    Column(modifier.fillMaxSize().layoutProbe("music.playlist", reportsFocus = false)) {
        val list = rememberLazyListState()
        // As [MusicScreenHeader], with Done before the phone's cast button in Edit mode.
        val cast = castInTopBar
        ScreenHeader(
            "",
            onBack = { if (state.editing) store.edit(false) else onBack() },
            scrolled = { list.canScrollBackward },
            actions = if (state.editing || cast) {
                {
                    if (state.editing) PlezyButton(T.common.doneEditing, { store.edit(false) }, handles.downFrom(Modifier.focusRequester(doneFocus)).layoutProbe("music.playlist.done"), style = ButtonStyle.PRIMARY, icon = PlezyIcons.Check)
                    if (cast) CastButton()
                }
            } else {
                null
            },
        )
        val header = state.header
        val reorder = rememberReorderState(0.dp)
        // Resolved by key against the rows as they are at the drop.
        val rows by rememberUpdatedState(state.rows)
        val drop = { key: String, to: Int ->
            val from = rows.indexOfFirst { it.key == key }
            if (from >= 0) store.move(from, to)
        }
        // Move mode keeps the moving row in view as it goes (the header is the list's first item).
        FollowMovingRow(list, remember(state.rows) { state.rows.map { it.key } }, state.moving, before = 1)
        val platformScroll = LocalBringIntoViewSpec.current
        val scroll = remember(platformScroll, list) { WholeHeaderSpec(platformScroll, list) }
        when {
            state.load == LoadState.LOADING -> LoadingState()
            header == null -> MusicLoadFailed(state.load, state.error, store::retry)
            else -> CompositionLocalProvider(LocalBringIntoViewSpec provides scroll) {
                LazyColumn(Modifier.weight(1f).fillMaxWidth(), state = list, contentPadding = PaddingValues(start = trackListPadding(), end = trackListPadding(), bottom = bottomPadding())) {
                    item {
                        MusicDetailHeader(header, PlaceholderKind.PLAYLIST, compactArtwork = 200, onArtist = null, actions = {
                            MusicActions(
                                store::play,
                                store::shuffle,
                                null,
                                focusKey = leftEdit,
                                actions = listOfNotNull(
                                    // Kept in place, dimmed, in Edit mode: nothing slides under a second tap.
                                    RowAction(PlezyIcons.Edit, T.common.edit, "music.playlist.edit", enabled = state.editable && !state.editing) { store.edit(true) }.takeIf { state.canDelete },
                                    RowAction(PlezyIcons.Delete, T.playlists.delete, "music.playlist.delete", enabled = !state.editing, onClick = store::delete).takeIf { state.canDelete },
                                ),
                            ) {
                                state.downloads.forEach { action ->
                                    DetailDownloadButton(action.button, { store.download(action.entry) }, Modifier.layoutProbe("music.playlist.${action.entry.id}"))
                                }
                            }
                        })
                        Spacer(Modifier.height(8.dp))
                    }
                    itemsIndexed(state.rows, key = { _, row -> row.key }) { index, row ->
                        val track = @Composable { rowModifier: Modifier ->
                            TrackRow(
                                row,
                                current = row.globalKey == state.playingKey,
                                playing = state.playing,
                                onClick = { store.playFrom(row.index) },
                                modifier = rowModifier,
                                onMenu = if (state.editing) null else ({ store.track(row.index)?.let { menu.open(it) } }),
                            )
                        }
                        if (!state.editing) {
                            track(Modifier)
                        } else {
                            MusicEditRow(
                                index = index,
                                label = row.title,
                                editable = state.editable,
                                moving = state.moving == index,
                                store = store,
                                handles = handles,
                                modifier = Modifier
                                    .then(if (reorder.dragging == null) Modifier.animateItem() else Modifier)
                                    .reorderItem(reorder, row.key, index),
                                handle = if (state.editable) Modifier.reorderDrag(reorder, row.key, index, state.rows.size, drop) else Modifier,
                                row = { track(Modifier.weight(1f)) },
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * The music playlist list's scrolling for focus, over [platform]'s: where that would leave the header (the list's first
 * item: artwork, title, actions) partly in view, the list goes instead to its top, the header whole, when what takes
 * focus shows whole there, else to just past the header. Focus inside the header keeps [platform]'s scrolling.
 */
@OptIn(ExperimentalFoundationApi::class)
private class WholeHeaderSpec(private val platform: BringIntoViewSpec, private val list: LazyListState) : BringIntoViewSpec {
    /** The header's height, as last laid out. */
    private var header = 0f

    override fun calculateScrollDistance(offset: Float, size: Float, containerSize: Float): Float {
        val distance = platform.calculateScrollDistance(offset, size, containerSize)
        val items = list.layoutInfo.visibleItemsInfo
        items.firstOrNull { it.index == 0 }?.let { header = it.size.toFloat() }
        // How far down the list the view starts, from the header or the first row, whichever is laid out.
        val top = items.firstOrNull { it.index == 0 }?.let { -it.offset.toFloat() }
            ?: items.firstOrNull { it.index == 1 }?.takeIf { header > 0f }?.let { header - it.offset }
            ?: return distance
        val target = top + distance
        if (target <= 0f || target >= header || top + offset < header) return distance
        return if (top + offset + size <= containerSize) -top else header - top
    }
}

/**
 * A playlist track in Edit mode: its drag handle (swap arrows in move mode), the track [row], then ✕. Move mode tints
 * the row and turns Up and Down into moves, Select into the save; the handle takes focus as it starts, so the keys move
 * the row however move mode began (a click included). While a change is on its way ([editable] false) the handle and ✕
 * wait.
 */
@Composable
private fun MusicEditRow(
    index: Int,
    label: String,
    editable: Boolean,
    moving: Boolean,
    store: MusicPlaylistStore,
    handles: EditHandles,
    modifier: Modifier,
    handle: Modifier,
    row: @Composable RowScope.() -> Unit,
) {
    val handleFocus = remember { FocusRequester() }
    handles.Register(index, handleFocus)
    Row(
        modifier.fillMaxWidth().editRowFrame(editing = true, moving),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(EditRowGap),
    ) {
        PlezyIconButton(
            if (moving) PlezyIcons.SwapVert else PlezyIcons.DragIndicator,
            T.libraries.dragToReorderNamed(label),
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
                .layoutProbe("music.track.$index.handle"),
            style = IconButtonStyle.PLAIN,
            enabled = editable || moving,
        )
        row()
        // Beside the row rather than inside it, so Right from the row reaches it.
        PlezyIconButton(PlezyIcons.Close, T.playlists.removeItem, { store.remove(index) }, Modifier.layoutProbe("music.track.$index.remove"), style = IconButtonStyle.PLAIN, enabled = editable)
    }
}

/** A music screen with nothing to show: its failure with Retry, or "No items available". */
@Composable
private fun MusicLoadFailed(load: LoadState, error: String?, onRetry: () -> Unit) {
    if (load == LoadState.ERROR) ErrorState(error.orEmpty(), onRetry = onRetry) else EmptyState(T.messages.noItemsAvailable, icon = PlezyIcons.Album)
}
