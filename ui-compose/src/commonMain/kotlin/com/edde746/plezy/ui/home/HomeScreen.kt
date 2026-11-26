package com.edde746.plezy.ui.home

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyListState
import com.edde746.plezy.ui.components.ScrollRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.layout.LazyLayoutCacheWindow
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.CanvasDrawScope
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import coil3.Bitmap
import coil3.compose.AsyncImage
import coil3.compose.AsyncImagePainter
import coil3.compose.LocalPlatformContext
import coil3.request.ImageRequest
import coil3.request.transformations
import coil3.size.pxOrElse
import coil3.transform.Transformation
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.home.HomeUiState
import com.edde746.plezy.presentation.home.LibraryShortcutUi
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.NavigationKind
import com.edde746.plezy.ui.adaptive.WidthClass
import com.edde746.plezy.ui.components.CyclingBackdrop
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.HubRow
import com.edde746.plezy.ui.components.LoadingShelf
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.SheetOption
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.fadeStops
import com.edde746.plezy.ui.components.isDown
import com.edde746.plezy.ui.components.playKey
import com.edde746.plezy.ui.components.rememberShelfNavigation
import com.edde746.plezy.ui.components.shelfSpacing
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.StayInViewSpec
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.LocalArtworkDisplay
import com.edde746.plezy.ui.image.SizedArtwork
import com.edde746.plezy.ui.image.toCoilBitmap
import com.edde746.plezy.ui.image.toComposeBitmap
import com.edde746.plezy.ui.navigation.ScrollEdgeScrim
import com.edde746.plezy.ui.navigation.clipToNavigation
import com.edde746.plezy.ui.navigation.extendStart
import com.edde746.plezy.ui.navigation.navigationInset
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.libraries.libraryIcon
import com.edde746.plezy.ui.probe.HOME_CONTENT_MARK
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.probe.perfMark
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.watch.WatchTogetherShortcut
import kotlin.math.max
import kotlin.math.roundToInt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import coil3.size.Size as ImageSize
import com.edde746.plezy.ui.components.TouchPullToRefresh

/**
 * Home over [app]'s store ([HomeContent]), with Home's shortcuts ([HomeShortcuts]), the copy picker of a merged
 * Continue Watching card and the user menu's dialogs. Ctrl+R refreshes Home wherever focus is in it.
 */
@Composable
fun HomeScreen(app: AppSession, modifier: Modifier = Modifier) {
    val store = remember(app) { app.home(Route.Home) } ?: return
    val state by store.state.collectAsState()
    val refreshing by store.refreshing.collectAsState()
    val actions = remember(app, store) {
        HomeActions(
            open = { hub, card -> store.open(hub.id, card.id) },
            menu = { hub, card -> store.menu(hub.id, card.id) },
            viewAll = { hub -> store.openHub(hub.id) },
            refresh = store::refresh,
            retry = store::retry,
            messageShown = store::messageShown,
            openLibrary = store::openLibrary,
        )
    }
    Box(
        modifier.fillMaxSize().onPreviewKeyEvent { event ->
            val refresh = event.type == KeyEventType.KeyDown && event.isCtrlPressed && event.key == Key.R
            if (refresh) actions.refresh()
            refresh
        },
    ) {
        HomeContent(state, actions, refreshing = refreshing) { memory, below, shortcutsModifier ->
            HomeShortcuts(app, state.libraries, state.shortcutsSettled, actions, memory, below, shortcutsModifier)
        }
        CopyPickerSheet(app)
        UserMenuOverlays(app)
    }
}

/**
 * Home, the same on every device: Continue Watching first (its cards play at once, as does the
 * remote's Play key on them), then Home's [shortcuts], then the servers' hubs as shelves ([HubRow]: View All in the
 * heading, or as a card at the row's end where a remote or the keyboard moves focus). Nothing sits above the first
 * shelf: Home has no header row, and its list scrolls up under the status bar on a phone, where the screens' scroll
 * edge ([ScrollEdgeScrim]) shows once it has left its top. Loading shelves while Continue Watching or the hubs are on
 * their way; the error with Retry or the empty state
 * under the shortcuts, which stay usable in every state. On TV and wide windows the backdrop of the focused card (its
 * latest copy, else the first shelf's first card: [backdropCard]) fades in behind the top of the page ([Backdrop]). A
 * pull from the top refreshes Home on a touch screen.
 *
 * Focus: on TV the first card of the first shelf (Continue Watching's, else the first hub's) takes focus once content
 * is there, on every launch: until a key has reached Home, focus already in it is no one's choice (Android gives the
 * window's first element focus as it opens: the shortcuts, on a launch with Home's data kept) and goes to that card.
 * Until the user moves it, focus Home placed follows a new first card (Continue Watching arriving after the
 * hubs), and the list goes back to its top ([KeepAtTop]). Focus a key took elsewhere (the shortcuts, the navigation)
 * stays there, and a Home under another screen or tab takes none until it is on view again ([RestoreFocus]). Off TV
 * nothing is focused in touch mode; once keys are in use focus lands on that same first card. Up from the first hub
 * goes to the shortcuts, Down from the shortcuts to the first hub's first card.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun HomeContent(
    state: HomeUiState,
    actions: HomeActions,
    modifier: Modifier = Modifier,
    refreshing: Boolean = false,
    shortcuts: @Composable (memory: FocusMemory, below: String?, modifier: Modifier) -> Unit = { _, _, _ -> },
) {
    val appearance = LocalAppearance.current
    val dimens = LocalPlezyDimens.current
    val layout = LocalWindowLayout.current
    val memory = rememberFocusMemory()
    // The shelf below the screen (half a screen ahead) is composed and measured while the list rests, not in the frames
    // of the scroll that brings it in; the one scrolled off above stays composed for the way back.
    val list = rememberLazyListState(remember { LazyLayoutCacheWindow(aheadFraction = 0.5f, behindFraction = 0.5f) })
    val showsBackdrop = layout.formFactor == FormFactor.TV || layout.widthClass == WidthClass.EXPANDED
    // The focused card's id, not a copy of it: the backdrop shows its latest copy ([backdropCard]).
    var focusedCard by remember { mutableStateOf<String?>(null) }
    // Whether a key has reached Home since it opened (kept while a screen pushed over it shows).
    var keyed by rememberSaveable { mutableStateOf(false) }
    val continueWatching = state.continueWatching
    val hubs = state.hubs
    val shelves = listOfNotNull(continueWatching) + hubs
    val currentShelves by rememberUpdatedState(shelves)
    val firstCard = shelves.firstOrNull()?.let(::firstKey)
    val loading = state.load == LoadState.LOADING
    Box(
        modifier
            .fillMaxSize()
            .perfMark(HOME_CONTENT_MARK, "", ready = state.load != LoadState.LOADING)
            .onPreviewKeyEvent {
                keyed = true
                false
            },
    ) {
        if (showsBackdrop) Backdrop { backdropCard(currentShelves, focusedCard) }
        val navigation = rememberShelfNavigation(list)
        val platformScroll = LocalBringIntoViewSpec.current
        val stayInView = remember(platformScroll) { StayInViewSpec(platformScroll) }
        val keys = buildList {
            if (continueWatching != null || loading) add(CONTINUE_WATCHING)
            add(SHORTCUTS)
            hubs.forEach { add(it.id) }
        }
        KeepAtTop(list, keys.first(), memory, firstCard) { key -> keys.indexOf(key).takeIf { it >= 0 } }
        val cardModifier = @Composable { hub: HubUi, card: MediaCardUi ->
            Modifier
                .rememberFocus(memory, cardKey(hub, card))
                .onFocusChanged { if (it.hasFocus) focusedCard = card.id }
                .then(if (hub.continueWatching) Modifier.playKey { actions.open(hub, card) } else Modifier)
        }
        val shelf = @Composable { hub: HubUi, index: Int ->
            CompositionLocalProvider(LocalBringIntoViewSpec provides platformScroll) {
                HubRow(
                    hub,
                    appearance,
                    navigation.item(index),
                    cardModifier = { cardModifier(hub, it) },
                    seeAllModifier = Modifier.rememberFocus(memory, "seeAll:${hub.id}"),
                    onCardClick = { actions.open(hub, it) },
                    onCardLongClick = { actions.menu(hub, it) },
                    onViewAll = { actions.viewAll(hub) },
                )
            }
        }
        // Focus moving to a shelf or the shortcuts wholly in view scrolls the list nowhere (a TV's pivot would push
        // Continue Watching half off the top for the chips under it); one partly out of view comes in as the platform
        // scrolls it. The rows inside keep the platform's own scrolling.
        CompositionLocalProvider(LocalBringIntoViewSpec provides stayInView) {
            TouchPullToRefresh(refreshing, actions.refresh, Modifier.fillMaxSize()) {
                LazyColumn(
                    state = list,
                    modifier = Modifier.fillMaxSize().then(navigation.modifier).layoutProbe("home.list", reportsFocus = false),
                    contentPadding = PaddingValues(top = (if (dimens.focusGrows) 24.dp else 12.dp) + statusBarOverlap, bottom = dimens.sectionSpacing),
                    verticalArrangement = Arrangement.spacedBy(dimens.shelfSpacing),
                ) {
                    when {
                        continueWatching != null -> item(key = CONTINUE_WATCHING, contentType = SHELF) { shelf(continueWatching, 0) }
                        loading -> item(key = CONTINUE_WATCHING, contentType = LOADING) { LoadingShelf(T.discover.continueWatching, shape = state.loadingShape) }
                    }
                    item(key = SHORTCUTS, contentType = SHORTCUTS) {
                        // Down from the row: the first hub's first card, not the card under the chip.
                        CompositionLocalProvider(LocalBringIntoViewSpec provides platformScroll) {
                            shortcuts(memory, hubs.firstOrNull()?.let(::firstKey), navigation.item(keys.indexOf(SHORTCUTS)))
                        }
                    }
                    when (state.load) {
                        LoadState.ERROR -> item(key = STATE) {
                            ErrorState(state.error.orEmpty(), Modifier.fillParentMaxHeight(0.7f), onRetry = actions.retry)
                        }
                        LoadState.EMPTY -> item(key = STATE) {
                            EmptyState(T.discover.addMediaToLibraries, Modifier.fillParentMaxHeight(0.7f), title = T.discover.noContentAvailable)
                        }
                        else -> {
                            itemsIndexed(hubs, key = { _, hub -> hub.id }, contentType = { _, _ -> SHELF }) { index, hub ->
                                shelf(hub, keys.size - hubs.size + index)
                            }
                            if (state.hubsLoading) items(LOADING_SHELVES, contentType = { LOADING }) { LoadingShelf("") }
                        }
                    }
                }
            }
        }
        // The screens' scroll edge behind the status bar, on a phone, where Home reaches up under it.
        if (statusBarOverlap > 0.dp) ScrollEdgeScrim({ list.canScrollBackward }, statusBarOverlap)
        state.message?.let { TimedToast(it, "home.message", actions.messageShown, Modifier.align(Alignment.BottomCenter)) }
    }
    // In touch mode (a phone, or after a tap or a click) Home places no focus, as Android focuses nothing while the user
    // touches the screen; a key press leaves touch mode and focus comes to the first card.
    val touch = LocalInputModeManager.current.inputMode == InputMode.Touch
    val fallback = firstCard?.takeIf { appearance.tv || !touch }
    RestoreFocus(memory, ready = fallback != null, fallback = fallback, remembered = { !appearance.tv || keyed })
}

/** What Home's cards, rows and shortcuts do. */
internal class HomeActions(
    val open: (HubUi, MediaCardUi) -> Unit,
    val menu: (HubUi, MediaCardUi) -> Unit,
    val viewAll: (HubUi) -> Unit,
    val refresh: () -> Unit,
    val retry: () -> Unit,
    val messageShown: () -> Unit,
    val openLibrary: (globalKey: String) -> Unit,
)

private fun cardKey(hub: HubUi, card: MediaCardUi) = "${hub.id}/${card.id}"

/** The focus key of [hub]'s first card; null while it has none. */
private fun firstKey(hub: HubUi): String? = hub.items.firstOrNull()?.let { cardKey(hub, it) }

/**
 * The card whose backdrop Home shows: the latest copy among [shelves] of the card focus last rested on ([focused], its
 * id), so a refresh's changes to it show and an item gone from every shelf gives way; else the first card of the first
 * shelf that has one.
 */
private fun backdropCard(shelves: List<HubUi>, focused: String?): MediaCardUi? =
    focused?.let { id -> shelves.firstNotNullOfOrNull { hub -> hub.items.firstOrNull { it.id == id } } }
        ?: shelves.firstNotNullOfOrNull { it.items.firstOrNull() }

/**
 * Keeps [state]'s list at its top when a shelf arrives before its first one ([firstKey] changes) while the list is at
 * its top: a lazy list keeps its first visible item where it is, so Continue Watching arriving after the hubs would
 * come in above, out of sight. Focus Home placed on its first card itself ([FocusMemory.placedFocus]) follows to the
 * new [firstCard] ([RestoreFocus] moves it) and the list goes back to its top; focus the user moved stays in view, the
 * list scrolling to its shelf ([indexOf] gives a key's place in the list).
 */
@Composable
private fun KeepAtTop(state: LazyListState, firstKey: Any?, focus: FocusMemory, firstCard: String?, indexOf: (Any) -> Int?) {
    val shown = remember(state) { FirstKey(firstKey, firstCard) }
    // After the composition that changed the items and before their measure: the state still describes the list as
    // it was laid out.
    SideEffect {
        val focused = focus.focusedKey
        val placed = focus.placedFocus.let { it != null && it == shown.card }
        val atTop = state.firstVisibleItemIndex == 0 && state.firstVisibleItemScrollOffset == 0
        if (placed && firstCard != null && firstCard != focused) {
            state.requestScrollToItem(0)
        } else if (firstKey != shown.key && atTop) {
            if (focused == null || placed) {
                state.requestScrollToItem(0)
            } else {
                shown.key?.let(indexOf)?.let { state.requestScrollToItem(it) }
            }
        }
        shown.key = firstKey
        shown.card = firstCard
    }
}

private class FirstKey(var key: Any?, var card: String?)

/**
 * The backgrounds of the card that has focus ([card], read only here so focus moves don't recompose Home) in turn
 * ([CyclingBackdrop]), in colour and faint, fading into the background towards the bottom and the start so the shelves
 * stay readable: its backgrounds, else its artwork unless blurred ([backdropArt]); a card with neither shows none, the
 * last one fading out. The first card's comes as soon as Home has it; later it follows focus once focus rests on a card
 * ([BACKDROP_SETTLE_MS]: a D-pad held down doesn't load every image) and fades in over the last one once loaded, with
 * no empty frame between them. It runs under the side navigation to the window's edge ([navigationInset]). Each image
 * comes baked with its dim and fades ([BackdropArtwork]) at half the area's resolution: one opaque image costs a
 * low-end TV's GPU about nothing as the shelves scroll over it. Harness name `home.backdrop`, whose state is the key of
 * the shown card's first picture.
 */
@Composable
internal fun Backdrop(card: () -> MediaCardUi?) {
    var shown by remember { mutableStateOf<MediaCardUi?>(null) }
    LaunchedEffect(Unit) {
        snapshotFlow(card).collectLatest {
            if (shown != null) delay(BACKDROP_SETTLE_MS)
            shown = it
        }
    }
    val art = shown?.let(::backdropArt).orEmpty()
    val background = MaterialTheme.colorScheme.background
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val context = LocalPlatformContext.current
    val display = LocalArtworkDisplay.current
    val density = LocalDensity.current.density
    var area by remember { mutableStateOf(IntSize.Zero) }
    Box(
        Modifier
            .extendStart(navigationInset)
            .fillMaxWidth()
            .fillMaxHeight(0.7f)
            .onSizeChanged { area = it }
            .layoutProbe("home.backdrop", reportsFocus = false)
            .testTag("home.backdrop")
            .semantics { stateDescription = art.firstOrNull()?.key.orEmpty() },
    ) {
        if (area != IntSize.Zero) {
            CyclingBackdrop(shown?.id, art, Modifier.fillMaxSize(), fill = Color.Transparent) { artwork, layer, onResult ->
                val request = remember(artwork, area, background, rtl) {
                    ImageRequest.Builder(context)
                        .data(SizedArtwork(artwork, display, density))
                        .size(area.width / BACKDROP_SCALE, area.height / BACKDROP_SCALE)
                        .transformations(BackdropArtwork(background, rtl))
                        .build()
                }
                AsyncImage(
                    request,
                    contentDescription = null,
                    modifier = layer,
                    contentScale = ContentScale.FillBounds,
                    onState = {
                        if (it is AsyncImagePainter.State.Success) onResult(artwork, true)
                        if (it is AsyncImagePainter.State.Error) onResult(artwork, false)
                    },
                )
            }
        }
    }
}

/** What the backdrop shows for [card]: its backgrounds, else its own artwork unless blurred (a spoiler), else nothing. */
private fun backdropArt(card: MediaCardUi): List<Artwork> =
    card.backdrops.ifEmpty { listOfNotNull(card.artwork?.takeUnless { card.blurred }) }

/**
 * The backdrop as one opaque image of the requested size: the artwork at [BACKDROP_ALPHA] over [background], cropped
 * to fill it from its top end (left in [rtl]), fading into [background] towards the bottom (from 30 % of the height)
 * and towards the start (across [BACKDROP_FADE] of the width).
 */
private class BackdropArtwork(private val background: Color, private val rtl: Boolean) : Transformation() {
    override val cacheKey = "backdrop(${background.toArgb()},$rtl)"

    override suspend fun transform(input: Bitmap, size: ImageSize): Bitmap {
        val width = size.width.pxOrElse { input.width }
        val height = size.height.pxOrElse { input.height }
        val artwork = input.toComposeBitmap()
        val baked = ImageBitmap(width, height, hasAlpha = false)
        val area = Size(width.toFloat(), height.toFloat())
        CanvasDrawScope().draw(Density(1f), LayoutDirection.Ltr, Canvas(baked), area) {
            drawRect(background)
            val scale = max(area.width / artwork.width, area.height / artwork.height)
            val drawn = IntSize((artwork.width * scale).roundToInt(), (artwork.height * scale).roundToInt())
            drawImage(artwork, dstOffset = IntOffset(if (rtl) 0 else width - drawn.width, 0), dstSize = drawn, alpha = BACKDROP_ALPHA)
            val fadeTop = area.height * 0.3f
            drawRect(
                Brush.verticalGradient(*fadeStops(background, 1f, 0f, from = 1f), startY = fadeTop, endY = area.height),
                topLeft = Offset(0f, fadeTop),
                size = Size(area.width, area.height - fadeTop),
            )
            val fade = area.width * BACKDROP_FADE
            val across = fadeStops(background, 0f, 1f, from = 1f)
            if (rtl) {
                drawRect(Brush.horizontalGradient(*across, startX = area.width, endX = area.width - fade), topLeft = Offset(area.width - fade, 0f), size = Size(fade, area.height))
            } else {
                drawRect(Brush.horizontalGradient(*across, startX = 0f, endX = fade), size = Size(fade, area.height))
            }
        }
        return baked.toCoilBitmap()
    }
}

/**
 * Home's shortcuts ([ShortcutRow]) in [homeShortcutOrder]'s order. Each chip is part of Home's focus [memory], so coming
 * back from the screen one opened finds focus on it; Up or Down into the row lands on Live TV, else the first library,
 * else Watch Together. The row shows whole, once [settled] ([HomeUiState.shortcutsSettled], at most [SHORTCUTS_WAIT_MS]
 * after Home opens), its height kept until then: chips arriving one by one (Live TV before the others, the libraries)
 * would push the row's chips along.
 * Harness names: `home.refresh`, `home.liveTv`, `home.watchTogether`, `home.downloads`, `home.serverTasks`,
 * `home.userMenu`, `home.library.<index>`.
 */
@Composable
private fun HomeShortcuts(
    app: AppSession,
    libraries: List<LibraryShortcutUi>,
    settled: Boolean,
    actions: HomeActions,
    memory: FocusMemory,
    below: String?,
    modifier: Modifier,
) {
    val shell by app.shell.state.collectAsState()
    val layout = LocalWindowLayout.current
    var shown by remember { mutableStateOf(settled) }
    if (!shown) {
        LaunchedEffect(settled) {
            if (!settled) delay(SHORTCUTS_WAIT_MS)
            shown = true
        }
        Spacer(modifier.fillMaxWidth().height(LocalPlezyDimens.current.chipHeight))
        return
    }
    val first = when {
        shell.liveTv -> "liveTv"
        libraries.isNotEmpty() -> "library:${libraries.first().globalKey}"
        else -> "watchTogether"
    }
    val order = homeShortcutOrder(
        tv = layout.formFactor == FormFactor.TV,
        liveTv = shell.liveTv,
        downloads = app.downloads != null,
        bar = layout.navigation == NavigationKind.BAR,
    )
    ShortcutRow(memory, shortcutKey(first), below, modifier) {
        for (shortcut in order) when (shortcut) {
            HomeShortcut.LIVE_TV -> item(key = "liveTv") {
                PlezyChip(T.navigation.liveTv, false, app.shell::openLiveTv, Modifier.rememberFocus(memory, shortcutKey("liveTv")).layoutProbe("home.liveTv"), leadingIcon = PlezyIcons.LiveTv)
            }
            HomeShortcut.LIBRARIES -> libraryChips(libraries, memory, actions.openLibrary)
            HomeShortcut.WATCH_TOGETHER -> item(key = "watchTogether") { WatchTogetherShortcut(app, Modifier.rememberFocus(memory, shortcutKey("watchTogether"))) }
            HomeShortcut.DOWNLOADS -> item(key = "downloads") {
                PlezyChip(
                    T.navigation.downloads,
                    false,
                    { app.shell.openAtRoot(TopLevelDestination.DOWNLOADS) },
                    Modifier.rememberFocus(memory, shortcutKey("downloads")).layoutProbe("home.downloads"),
                    leadingIcon = PlezyIcons.Download,
                )
            }
            HomeShortcut.SERVER_TASKS -> item(key = "serverTasks") { ServerTasksAction(app, Modifier.rememberFocus(memory, shortcutKey("serverTasks"))) }
            HomeShortcut.REFRESH -> item(key = "refresh") {
                PlezyChip(T.common.refresh, false, actions.refresh, Modifier.rememberFocus(memory, shortcutKey("refresh")).layoutProbe("home.refresh"), leadingIcon = PlezyIcons.Refresh)
            }
            HomeShortcut.USER_MENU -> item(key = "userMenu") { UserMenuAction(app, Modifier.rememberFocus(memory, shortcutKey("userMenu"))) }
        }
    }
}

/** A place in Home's shortcut row; [LIBRARIES] stands for a chip per visible library. */
internal enum class HomeShortcut { LIVE_TV, LIBRARIES, WATCH_TOGETHER, DOWNLOADS, SERVER_TASKS, REFRESH, USER_MENU }

/**
 * Home's shortcut row, in order: Live TV while a server has it (pushed over Home), the libraries, Watch Together (its
 * participant count), the downloads (Libraries' section) where the device keeps them ([downloads]), Server Tasks (which
 * shows off phones and tablets), Refresh on [tv] (a pull refreshes on touch, Ctrl+R everywhere) and, on a phone's [bar]
 * layout, which has no profile button, the user menu.
 */
internal fun homeShortcutOrder(tv: Boolean, liveTv: Boolean, downloads: Boolean, bar: Boolean): List<HomeShortcut> = buildList {
    if (liveTv) add(HomeShortcut.LIVE_TV)
    add(HomeShortcut.LIBRARIES)
    add(HomeShortcut.WATCH_TOGETHER)
    if (downloads) add(HomeShortcut.DOWNLOADS)
    add(HomeShortcut.SERVER_TASKS)
    if (tv) add(HomeShortcut.REFRESH)
    if (bar) add(HomeShortcut.USER_MENU)
}

/**
 * A chip per library shortcut: its kind's icon (as Libraries' picker shows it), its title and, beside a namesake from another server, the
 * server's name; a tap opens it in Libraries. Harness names `home.library.<index>`.
 */
internal fun LazyListScope.libraryChips(libraries: List<LibraryShortcutUi>, memory: FocusMemory, open: (String) -> Unit) {
    itemsIndexed(libraries, key = { _, library -> "library:${library.globalKey}" }) { index, library ->
        PlezyChip(
            listOfNotNull(library.title, library.serverName).joinToString(" · "),
            false,
            { open(library.globalKey) },
            Modifier.rememberFocus(memory, shortcutKey("library:${library.globalKey}")).layoutProbe("home.library.$index"),
            leadingIcon = libraryIcon(library.kind),
        )
    }
}

/**
 * Home's shortcuts as one line of chips (none selected: each opens a screen or acts) from the shelves' leading edge,
 * scrolling sideways. Up or Down into the row lands on its [first] chip (a key in [memory]); Down from it goes to
 * [below] (the first hub's first card) while it is composed, not to the card under the chip. A chip arriving before
 * the others (Live TV once the server says it has it) keeps the row at its start until the user scrolls it. Harness
 * name `home.shortcuts`.
 */
@Composable
internal fun ShortcutRow(memory: FocusMemory, first: String, below: String?, modifier: Modifier = Modifier, content: LazyListScope.() -> Unit) {
    val state = rememberLazyListState()
    var scrolled by remember { mutableStateOf(false) }
    LaunchedEffect(state) { snapshotFlow { state.isScrollInProgress }.collect { if (it) scrolled = true } }
    // The list keeps its first visible chip in place as chips are inserted before it, which would open the row scrolled.
    LaunchedEffect(first) { if (!scrolled) state.requestScrollToItem(0) }
    ScrollRow(
        state = state,
        modifier = modifier
            .fillMaxWidth()
            .layoutProbe("home.shortcuts", reportsFocus = false)
            .clipToNavigation()
            .onPreviewKeyEvent { event -> event.isDown() && below != null && memory.focus(below) }
            .focusProperties {
                onEnter = {
                    if (requestedFocusDirection == FocusDirection.Up || requestedFocusDirection == FocusDirection.Down) memory.focus(first)
                }
            }
            .focusGroup(),
        contentPadding = PaddingValues(horizontal = LocalPlezyDimens.current.screenPadding),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        content = content,
    )
}

/** A shortcut in Home's focus memory. */
internal fun shortcutKey(key: String) = "shortcut:$key"

/**
 * Which copy a merged Continue Watching row opens ([com.edde746.plezy.presentation.browse.MediaActions.picker]): a
 * sheet of the copies, each saying what tells it apart. Harness name `copyPicker`.
 */
@Composable
internal fun CopyPickerSheet(app: AppSession) {
    val picker by app.mediaActions.picker.collectAsState()
    val shown = picker.takeIf { it.shown } ?: return
    PlezySheet(onDismiss = app.mediaActions::dismiss, title = shown.title, probe = "copyPicker") {
        shown.options.forEachIndexed { index, label ->
            SheetOption(label, onClick = { app.mediaActions.pick(index) }, Modifier.layoutProbe("copyPicker.option.$index"), choice = false)
        }
    }
}

private const val CONTINUE_WATCHING = "continueWatching"
private const val SHORTCUTS = "shortcuts"
private const val SHELF = "shelf"
private const val LOADING = "loading"
private const val STATE = "state"
private const val LOADING_SHELVES = 3

/** How long focus rests on a card before its backdrop comes. */
internal const val BACKDROP_SETTLE_MS = 350L

/** The longest Home's chip row waits to show whole: a slow server's answer doesn't keep it empty. */
private const val SHORTCUTS_WAIT_MS = 3000L

/** The artwork's opacity over the page, in colour: the shelf headings stay readable over bright pictures. */
private const val BACKDROP_ALPHA = 0.3f

/** How far across the backdrop, from its start edge, it takes to clear of the background. */
private const val BACKDROP_FADE = 0.6f

/** The backdrop's resolution: a half, under its fades. */
private const val BACKDROP_SCALE = 2
