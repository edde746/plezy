package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import coil3.compose.LocalPlatformContext
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.MediaMenu
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.browse.RowAction
import com.edde746.plezy.presentation.browse.primaryArtwork
import com.edde746.plezy.presentation.detail.MediaDetailUiState
import com.edde746.plezy.presentation.detail.MediaDetailStore
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.trackers.DetailWatchlistStore
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.cast.CastButton
import com.edde746.plezy.ui.cast.castInTopBar
import com.edde746.plezy.ui.components.BusyOverlay
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.aspectRatio
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.image.LocalArtworkDisplay
import com.edde746.plezy.ui.image.prefetchImage
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import kotlin.math.roundToInt

/**
 * A movie's, show's, season's or episode's detail ([Route.MediaDetail]): on phones and
 * narrow windows one list ([NarrowPage]: the backdrop across the top, the title, the metadata line with the ratings,
 * the actions, the track status and the overview, then the season chips and the episode rows, the cast, the extras,
 * the related hubs and the information); on windows at least [WideLayoutWidth] wide the backdrop behind the page, the
 * details in a column and a show's episodes in a column beside them ([WidePage]); on TV a page of sections
 * ([TvDetailPage]), drawn by [DetailContent]. On phones ([castInTopBar]) the cast button sits across from Back, out of
 * the action row. Back leaves only while the detail is the top screen ([detailIntents]); a Back key's release in the
 * first frames after it shows again (coming back from a child screen) is ignored. A shuffle shows its loading dialog
 * with Cancel. The store's messages show as toasts; once the item is gone the screen leaves. Focus starts on Play.
 * Harness name `detail`.
 */
@Composable
fun MediaDetailScreen(app: AppSession, route: Route.MediaDetail, modifier: Modifier = Modifier) {
    val store = remember(app, route) { app.mediaDetail(route) } ?: return
    val state by store.state.collectAsState()
    var toast by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(state.message) {
        state.message?.let {
            toast = it
            store.messageShown()
        }
    }
    LeaveWhenGone(state.gone, route, app.navigator)
    val watchlist = remember(app, route) { app.detailWatchlist(route) }
    val watchlistMessage = watchlist?.let { it.state.collectAsState().value?.message }
    LaunchedEffect(watchlistMessage) {
        watchlistMessage?.let {
            toast = it
            watchlist?.messageShown()
        }
    }
    val intents = remember(app, store, watchlist) { detailIntents(route, store, watchlist, app.mediaActions.menu, app.navigator) }
    DetailContent(state, intents, modifier) {
        toast?.let { TimedToast(it, "detail.toast", onShown = { toast = null }, Modifier.align(Alignment.BottomCenter).padding(bottom = LocalPlezyDimens.current.sectionSpacing)) }
    }
}

/**
 * The detail's page for [state] (the TV page, the wide or the narrow one), [overlay] over it, the loading dialog of a
 * shuffle, and focus starting on Play. A Back key's release in the first frames after the page shows again over a
 * child screen's leaving is ignored: it is the end of the press that left the child, not a second Back.
 */
@Composable
internal fun DetailContent(state: MediaDetailUiState, intents: DetailIntents, modifier: Modifier = Modifier, overlay: @Composable BoxScope.() -> Unit = {}) {
    val tv = LocalAppearance.current.tv
    val memory = rememberFocusMemory()
    val hero = state.hero
    var swallowBack by remember { mutableStateOf(hero != null) }
    LaunchedEffect(Unit) {
        repeat(BACK_GUARD_FRAMES) { withFrameNanos { } }
        swallowBack = false
    }
    Box(
        modifier
            .fillMaxSize()
            .onPreviewKeyEvent { swallowBack && it.type == KeyEventType.KeyUp && (it.key == Key.Back || it.key == Key.Escape) }
            .layoutProbe("detail", reportsFocus = false),
    ) {
        when {
            state.load == SectionLoad.ERROR -> {
                if (state.canRetry) {
                    ErrorState(T.messages.mediaUnavailable, onRetry = intents.store::retry)
                } else {
                    EmptyState(T.messages.mediaUnavailable, icon = PlezyIcons.Block)
                }
                if (!tv) BackButton(intents.back, Modifier.padding(LocalPlezyDimens.current.screenPadding / 2))
            }
            hero == null -> {
                LoadingState()
                if (!tv) BackButton(intents.back, Modifier.padding(LocalPlezyDimens.current.screenPadding / 2))
            }
            tv -> TvDetailPage(state, hero, memory, intents)
            else -> BoxWithConstraints(Modifier.fillMaxSize()) {
                if (maxWidth >= WideLayoutWidth) {
                    WidePage(state, hero, memory, intents, maxWidth, maxHeight)
                } else {
                    NarrowPage(state, hero, memory, intents, maxWidth, maxHeight)
                }
                BackButton(intents.back, Modifier.padding(BackButtonPadding))
                if (castInTopBar) CastButton(Modifier.align(Alignment.TopEnd).padding(BackButtonPadding), overPicture = true)
            }
        }
        overlay()
    }
    // The sections show whole once the page is ready (TV) or its item is in (elsewhere). The TV page composes them
    // hidden meanwhile, so its cards ask for their posters themselves.
    val sectionsShown = if (tv) state.ready else hero != null && !state.itemLoading
    if (!tv && !sectionsShown) PrefetchRelated(state.related)
    state.launching?.let { BusyOverlay(it, intents.store::cancelLaunch, "detail.launching") }
    RestoreFocus(memory, ready = sectionsShown, fallback = if (tv) tvFocusStart(state) else PLAY_KEY)
}

/** What the detail's pages ask of the app: the store's actions, the menus and navigation. */
internal class DetailIntents(
    val store: MediaDetailStore,
    val watchlist: DetailWatchlistStore?,
    /** The item's media menu (⋮), without the entries of the buttons in the row ([RowAction]s); nothing offline. */
    val openMenu: (Set<RowAction>) -> Unit,
    val openEpisodeMenu: (String) -> Unit,
    val openSeasonMenu: (String) -> Unit,
    val openExtraMenu: (String) -> Unit,
    val openRelatedMenu: (String) -> Unit,
    val navigate: (Route?) -> Unit,
    val back: () -> Unit,
)

/**
 * The intents of [route]'s detail: its item's, seasons', episodes', extras' and related titles' menus are the shared
 * media [menu] (the item's with Play trailer where it has one, and Play from beginning for a show's or season's Play
 * target); Back leaves only while the detail is [navigator]'s top screen.
 */
internal fun detailIntents(
    route: Route.MediaDetail,
    store: MediaDetailStore,
    watchlist: DetailWatchlistStore?,
    menu: MediaMenu,
    navigator: PlezyNavigator,
): DetailIntents {
    val place = { MenuPlace(seriesId = store.seriesId()) }
    return DetailIntents(
        store = store,
        watchlist = watchlist,
        openMenu = { onRow ->
            store.menuItem()?.let { item ->
                val trailer = if (store.state.value.actions.trailer) store::playTrailer else null
                menu.open(item, place(), detailMenuExtras(store, item), playTrailer = trailer, onRow = onRow)
            }
        },
        openEpisodeMenu = { id -> store.episodeItem(id)?.let { menu.open(it, place()) } },
        openSeasonMenu = { id -> store.seasonItem(id)?.let { menu.open(it, place()) } },
        openExtraMenu = { id -> store.extraItem(id)?.let { menu.open(it, place()) } },
        openRelatedMenu = { id -> store.relatedItem(id)?.let { menu.open(it, MenuPlace()) } },
        navigate = { target -> target?.let(navigator::navigate) },
        back = { if (navigator.current == route) navigator.back() },
    )
}

/**
 * Leaves [route]'s screen once its content is [gone] (deleted), while it is [navigator]'s top screen: at once, or as soon
 * as it is again (a screen or sheet over it closed, its destination shown again).
 */
@Composable
internal fun LeaveWhenGone(gone: Boolean, route: Route, navigator: PlezyNavigator) {
    val stack by navigator.backStack.collectAsState()
    LaunchedEffect(gone, stack) {
        if (gone && navigator.current == route) navigator.back()
    }
}

/** How many frames a Back key's release is ignored after the detail shows again over a child screen's leaving. */
private const val BACK_GUARD_FRAMES = 2

/**
 * Asks for the first cards' posters of each related hub that lands while the page still hides its sections, at the size
 * their cards draw them, so the rows show them as the page does. Once the sections show, the cards ask themselves.
 */
@Composable
private fun PrefetchRelated(hubs: List<HubUi>) {
    val context = LocalPlatformContext.current
    val display = LocalArtworkDisplay.current
    val density = LocalDensity.current.density
    val dimens = LocalPlezyDimens.current
    val asked = remember { HashSet<String>() }
    SideEffect {
        for (hub in hubs) {
            val width = (dimens.cardWidth(hub.shape).value * density).roundToInt()
            val height = (width / hub.shape.aspectRatio).roundToInt()
            for (card in hub.items.take(PREFETCHED_CARDS)) {
                val artwork = card.primaryArtwork ?: continue
                if (asked.add(artwork.key)) prefetchImage(context, artwork, display, density, width, height)
            }
        }
    }
}

/** How many cards of each related hub [PrefetchRelated] asks for: a TV row's width and a little more. */
private const val PREFETCHED_CARDS = 8

/** Play's key in the screen's focus memory. */
internal const val PLAY_KEY = "play"

/** The back button's place over the page, its room [BackButtonSpace]. */
internal val BackButtonPadding = 12.dp

/** The round back button over the picture. Harness name `detail.back`. */
@Composable
internal fun BackButton(onBack: () -> Unit, modifier: Modifier = Modifier) {
    PlezyIconButton(PlezyIcons.ArrowBack, T.nav.back, onBack, modifier.layoutProbe("detail.back"), style = IconButtonStyle.OVER_PICTURE)
}
