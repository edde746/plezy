package com.edde746.plezy.ui.detail

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.key
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.detail.DetailHeroUi
import com.edde746.plezy.presentation.detail.MediaDetailUiState
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.cast.CastButton
import com.edde746.plezy.ui.cast.castInTopBar
import com.edde746.plezy.ui.components.ActionRow
import com.edde746.plezy.ui.components.CyclingBackdrop
import com.edde746.plezy.ui.components.HubRow
import com.edde746.plezy.ui.components.RowInset
import com.edde746.plezy.ui.components.SectionTitle
import com.edde746.plezy.ui.components.fadeStops
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.StayInViewSpec
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.navigation.NavigationBackdrop
import com.edde746.plezy.ui.navigation.ScrollEdgeScrim
import com.edde746.plezy.ui.navigation.extendStart
import com.edde746.plezy.ui.navigation.navigationInset
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import kotlinx.coroutines.launch

/** Room above the details for the back button laid over the page. */
internal val BackButtonSpace = 68.dp

/** Windows at least this wide put the details and the episodes side by side over a full-screen backdrop. */
internal val WideLayoutWidth = 840.dp

/** The details' column on wide layouts is at most this wide. */
private val InfoMaxWidth = 560.dp

/** The episodes' column on wide windows is at most this wide (longer rows read badly). */
private val EpisodesMaxWidth = 960.dp

/** The title's box on narrow windows (a logo centred in it, at most 80 % of the page's width): its height. */
private val NarrowLogoHeight = 140.dp

/** The logo's largest height in the details' column of wide windows. */
private val WideLogoHeight = 160.dp

/** Between the narrow page's title and each line under it. */
private val HeadlineGap = 14.dp

/** The narrow page's picture reaches this far under the metadata line's top, behind the line. */
private val PictureUnderText = 34.dp

/**
 * Phones and narrow windows: one list. The backdrop across the top (the poster where there is none), its picture
 * reaching behind the metadata line and fading into the page; the title, the metadata line, the ratings and the
 * actions centred under it, the track status and the overview; then a show's season chips and the season's episode
 * rows, the cast, the extras, the related hubs (their View all opening the hub's grid) and the information. Beside a
 * rail the list reaches under it, so the backdrop runs to the window's edge. Up to the actions (from the overview or a
 * row below) scrolls the page back to its top. A deep link's episode or season is scrolled to the middle and focused
 * once ([MediaDetailUiState.initialFocus]). Once the title has scrolled under the back button the bar over the top
 * shows it ([TitleBar]). While the item loads ([MediaDetailUiState.itemLoading]) only the backdrop and the title show:
 * the rest comes in together once it has landed. Harness name of the list `detail.list`.
 */
@Composable
internal fun NarrowPage(state: MediaDetailUiState, hero: DetailHeroUi, focus: FocusMemory, intents: DetailIntents, width: Dp, height: Dp) {
    val dimens = LocalPlezyDimens.current
    val heroHeight = minOf(width * 0.62f, height * 0.6f, 420.dp)
    val titleTop = (heroHeight - NarrowLogoHeight).coerceAtLeast(BackButtonSpace)
    val textTop = titleTop + NarrowLogoHeight + HeadlineGap
    val box = DpSize((width - dimens.screenPadding * 2) * 0.8f, NarrowLogoHeight)
    val inset = navigationInset
    val list = rememberLazyListState()
    val thumbnailWidth = listThumbnailWidth()
    val section = Modifier.fillMaxWidth().padding(horizontal = dimens.screenPadding)
    var titleHeight by remember { mutableIntStateOf(0) }
    InitialDetailFocus(state, list, focus, firstRow = 2)
    LazyColumn(
        Modifier.fillMaxSize().extendStart(inset).layoutProbe("detail.list", reportsFocus = false),
        state = list,
        contentPadding = PaddingValues(start = inset, bottom = dimens.sectionSpacing * 2),
    ) {
        item(key = "hero") {
            Box(Modifier.fillMaxWidth()) {
                if (hero.backdrops.isNotEmpty() || hero.poster != null) NarrowBackdrop(hero, titleTop, textTop, Modifier.fillMaxWidth().height(textTop + PictureUnderText))
                Column(
                    Modifier.fillMaxWidth().padding(top = titleTop).padding(horizontal = dimens.screenPadding),
                    verticalArrangement = Arrangement.spacedBy(HeadlineGap),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Headline(
                        state, hero, focus, intents, centred = true, box, scrollToTop = { list.animateScrollToItem(0) },
                        titleModifier = Modifier.onSizeChanged { titleHeight = it.height },
                    )
                }
            }
        }
        if (state.itemLoading) return@LazyColumn
        if (state.episodes != null) {
            if (state.seasons.isNotEmpty()) {
                item(key = "seasons") {
                    SeasonChips(state, focus, intents.store::selectSeason, intents.openSeasonMenu, nameStart = dimens.screenPadding, Modifier.padding(top = dimens.sectionSpacing, bottom = 4.dp))
                }
            } else {
                item(key = "episodes.title") { SectionTitle(T.libraries.groupings.episodes, section.padding(top = dimens.sectionSpacing, bottom = dimens.shelfHeaderGap)) }
            }
            val episodes = state.episodes!!
            if (episodes.load == SectionLoad.CONTENT) {
                items(episodes.rows, key = { "ep:${it.id}" }) { row ->
                    EpisodeRow(row, focus, intents, thumbnailWidth, Modifier.padding(horizontal = dimens.screenPadding - RowInset))
                }
                item(key = "episodes.tail") { EpisodesTail(state, intents, section) }
            } else {
                item(key = "episodes.state") { EpisodesState(state, intents, section) }
            }
        }
        sections(state, focus, intents, section)
    }
    // The back button over the page: the list's top edge under it once the list has left its top.
    ScrollEdgeScrim({ list.canScrollBackward }, BackButtonSpace)
    val density = LocalDensity.current
    TitleBar(hero.title) {
        // How far the title's foot has gone up under the bar, over TitleBarFade: 0 still below it, 1 gone under it.
        if (list.firstVisibleItemIndex > 0) return@TitleBar 1f
        with(density) { (list.firstVisibleItemScrollOffset - (titleTop - BackButtonSpace).toPx() - titleHeight) / TitleBarFade.toPx() }.coerceIn(0f, 1f)
    }
}

/** How far the page scrolls while the title bar fades in. */
private val TitleBarFade = 40.dp

/**
 * The bar over a narrow page's top, behind Back (and the cast button on phones): the item's [title] on the bar's colour,
 * shown as much as [shown] says (0 to 1: fading in as the page's own title scrolls under it), so the page still says what
 * it is once its title is gone. The colour comes over the first half, covering the page's title, the bar's title over
 * the second, so the two titles never show at once. Laid over the list, nothing under it moves. Harness name
 * `detail.titleBar`.
 */
@Composable
private fun TitleBar(title: String, shown: () -> Float) {
    val current by rememberUpdatedState(shown)
    val visible by remember { derivedStateOf { current() > 0f } }
    if (!visible) return
    val inset = navigationInset
    val room = BackButtonPadding * 2 + LocalPlezyDimens.current.iconButtonSize
    Box(
        Modifier
            .fillMaxWidth()
            .height(BackButtonSpace)
            .extendStart(inset)
            .graphicsLayer { alpha = (shown() * 2).coerceAtMost(1f) }
            .background(PlezyColors.Surface)
            .layoutProbe("detail.titleBar", reportsFocus = false),
        contentAlignment = Alignment.CenterStart,
    ) {
        Text(
            title,
            Modifier.padding(start = inset + room, end = room).graphicsLayer { alpha = (shown() * 2 - 1).coerceAtLeast(0f) },
            style = MaterialTheme.typography.titleLarge.contentDirection(),
            color = PlezyColors.Text,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/** What follows the episodes on both layouts: the cast, the extras, the related hubs and the information. */
private fun LazyListScope.sections(state: MediaDetailUiState, focus: FocusMemory, intents: DetailIntents, section: Modifier) {
    if (state.cast.isNotEmpty()) item(key = "cast") { CastShelf(state.cast, focus, intents, Modifier.padding(top = LocalPlezyDimens.current.sectionSpacing)) }
    if (state.extras.isNotEmpty()) item(key = "extras") { ExtrasShelf(state.extras, focus, intents, Modifier.padding(top = LocalPlezyDimens.current.sectionSpacing)) }
    items(state.related, key = { "hub:${it.id}" }) { hub -> RelatedHub(hub, state.actions.more, focus, intents, Modifier.padding(top = LocalPlezyDimens.current.sectionSpacing)) }
    if (state.info.isNotEmpty()) item(key = "info") { Information(state.info, section.padding(top = LocalPlezyDimens.current.sectionSpacing)) }
}

/**
 * A related hub (the collection, similar titles, more with the cast) as a shelf: a card opens its detail, its menu is
 * the title's media menu, and See all (TV: the row's last card, remembered as the cards are, so Back from the grid
 * comes back to it) opens the hub's grid ([MediaDetailStore.relatedHubRoute]).
 */
@Composable
internal fun RelatedHub(hub: HubUi, menus: Boolean, focus: FocusMemory, intents: DetailIntents, modifier: Modifier = Modifier) {
    HubRow(
        hub,
        LocalAppearance.current,
        modifier,
        cardModifier = { Modifier.rememberFocus(focus, "${hub.id}/${it.id}") },
        seeAllModifier = Modifier.rememberFocus(focus, "seeAll:${hub.id}"),
        onCardClick = { intents.navigate(intents.store.relatedRoute(it.id)) },
        onCardLongClick = if (menus) ({ intents.openRelatedMenu(it.id) }) else null,
        onViewAll = intents.store.relatedHubRoute(hub.id)?.let { route -> { intents.navigate(route) } },
    )
}

/**
 * Wide windows: the backdrop behind the whole screen, near-black under the details and clearing past them, fading to
 * the page at the bottom. The details in a column on the left (at most [InfoMaxWidth]): the title, the metadata line,
 * the ratings, the actions, the track status, the overview, then the cast, the extras, the related hubs and the
 * information; a show's season chips and episode rows in a column on the right, the backdrop dimmed under them. A
 * movie's details start lower, under the backdrop's picture. While the item loads only the backdrop and the title show.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun WidePage(state: MediaDetailUiState, hero: DetailHeroUi, focus: FocusMemory, intents: DetailIntents, width: Dp, height: Dp) {
    val dimens = LocalPlezyDimens.current
    val reach = dimens.focusReach
    val series = state.episodes != null
    val usable = width - dimens.screenPadding * 2
    val gap = 48.dp
    val infoWidth = if (series) (usable * 0.4f).coerceIn(340.dp, InfoMaxWidth) else usable.coerceAtMost(InfoMaxWidth)
    val paneWidth = (usable - infoWidth - gap).coerceAtMost(EpisodesMaxWidth)
    val top = BackButtonSpace
    val detailsTop = if (series) top else (height * 0.3f).coerceAtLeast(top)
    val box = DpSize(infoWidth, WideLogoHeight)
    val platformScroll = LocalBringIntoViewSpec.current
    val stayInView = remember(platformScroll) { StayInViewSpec(platformScroll) }
    val scroll = rememberScrollState()
    Box(Modifier.fillMaxSize()) {
        WideBackdrop(hero, navigationInset + dimens.screenPadding + infoWidth, softEdge = (width * 0.25f).coerceIn(200.dp, 400.dp), dim = series, Modifier.fillMaxSize())
        CompositionLocalProvider(LocalBringIntoViewSpec provides stayInView) {
            Column(
                Modifier
                    .padding(start = dimens.screenPadding - reach)
                    .width(infoWidth + reach * 2)
                    .fillMaxHeight()
                    .verticalScroll(scroll)
                    .padding(horizontal = reach)
                    .padding(top = detailsTop, bottom = dimens.sectionSpacing * 2),
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                Headline(state, hero, focus, intents, centred = false, box, scrollToTop = { scroll.animateScrollTo(0) })
                if (!state.itemLoading) {
                    CompositionLocalProvider(LocalPlezyDimens provides dimens.copy(screenPadding = reach)) {
                        CastShelf(state.cast, focus, intents, Modifier.bleed(reach))
                        ExtrasShelf(state.extras, focus, intents, Modifier.bleed(reach))
                        for (hub in state.related) RelatedHub(hub, state.actions.more, focus, intents, Modifier.bleed(reach))
                    }
                    Information(state.info)
                }
            }
        }
        // Under the back button, once the details' column has left its top: across the page, as on every screen, so the
        // backdrop under the column shows no edge of it (a show's episodes are drawn over it).
        ScrollEdgeScrim({ scroll.canScrollBackward }, BackButtonSpace)
        if (series && !state.itemLoading) {
            EpisodesPane(
                state,
                focus,
                intents,
                Modifier
                    .align(Alignment.TopEnd)
                    .padding(end = dimens.screenPadding - RowInset, top = 16.dp)
                    .width(paneWidth + RowInset * 2)
                    .fillMaxHeight(),
            )
        }
    }
}

/**
 * Lays the content out [by] wider on both sides: a shelf's cards scroll out of sight past the column's edges; a pressable
 * text's inset falls outside the column, its words in line with the column's other text.
 */
internal fun Modifier.bleed(by: Dp): Modifier = layout { measurable, constraints ->
    val extra = by.roundToPx() * 2
    val placeable = measurable.measure(constraints.copy(maxWidth = constraints.maxWidth + extra, minWidth = constraints.minWidth + extra))
    layout(placeable.width - extra, placeable.height) { placeable.placeRelative(-extra / 2, 0) }
}

/**
 * A show's episodes beside its details (wide windows): the season chips over the selected season's rows, paged as the
 * list's end comes into view. A deep link's episode is scrolled to the middle and focused once.
 */
@Composable
private fun EpisodesPane(state: MediaDetailUiState, focus: FocusMemory, intents: DetailIntents, modifier: Modifier) {
    val dimens = LocalPlezyDimens.current
    val list = rememberSaveable(state.selectedSeason, saver = LazyListState.Saver) { LazyListState() }
    val episodes = state.episodes ?: return
    InitialDetailFocus(state, list, focus, firstRow = 0)
    Column(modifier) {
        if (state.seasons.isNotEmpty()) {
            SeasonChips(state, focus, intents.store::selectSeason, intents.openSeasonMenu, nameStart = RowInset, Modifier.padding(bottom = 4.dp))
        } else {
            SectionTitle(T.libraries.groupings.episodes, Modifier.padding(horizontal = RowInset).padding(bottom = dimens.shelfHeaderGap))
        }
        LazyColumn(Modifier.fillMaxSize().layoutProbe("detail.episodes", reportsFocus = false), state = list, contentPadding = PaddingValues(bottom = dimens.sectionSpacing * 2)) {
            if (episodes.load == SectionLoad.CONTENT) {
                items(episodes.rows, key = { "ep:${it.id}" }) { row -> EpisodeRow(row, focus, intents, thumbnailWidth = 176.dp) }
                item(key = "episodes.tail") { EpisodesTail(state, intents) }
            } else {
                item(key = "episodes.state") { EpisodesState(state, intents) }
            }
        }
    }
}

/**
 * The title, the metadata line and the ratings row, the actions, the track status and the overview, centred
 * ([centred], narrow windows) or from the start; the overview across the column. The title fills [titleBox]
 * ([titleModifier] on it). A move Up onto the actions with the keyboard or a D-pad brings the page back to its top
 * ([scrollToTop]). While the item loads ([MediaDetailUiState.itemLoading]) the title shows alone: what follows it comes
 * in together once the item has landed, so nothing it brings moves the page.
 */
@Composable
private fun Headline(
    state: MediaDetailUiState,
    hero: DetailHeroUi,
    focus: FocusMemory,
    intents: DetailIntents,
    centred: Boolean,
    titleBox: DpSize,
    scrollToTop: suspend () -> Unit,
    titleModifier: Modifier = Modifier,
) {
    val alignment = if (centred) Alignment.CenterHorizontally else Alignment.Start
    val scope = rememberCoroutineScope()
    val keyboard = LocalInputModeManager.current.inputMode == InputMode.Keyboard
    val play = focus.requester(PLAY_KEY)
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(HeadlineGap), horizontalAlignment = alignment) {
        TitleArt(hero, centred, titleBox, titleModifier)
        if (state.itemLoading) return@Column
        Column(verticalArrangement = Arrangement.spacedBy(10.dp), horizontalAlignment = alignment) {
            MetaLine(hero, centred)
            RatingsRow(hero, centred)
        }
        DetailActions(
            state,
            focus,
            intents,
            Modifier.onFocusChanged { if (it.hasFocus && keyboard) scope.launch { scrollToTop() } },
        )
        if (state.tracks != null || state.tracksLoading) {
            TrackStatus(
                state.tracks,
                TextStyle(fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 0.1.sp, lineHeight = 1.2.em, color = PlezyColors.TextMuted),
                if (centred) Modifier else Modifier.fillMaxWidth(),
            )
        }
        hero.summary?.let { Overview(it, focus, up = play) }
    }
}

/**
 * The one row of actions ([ActionRow]), never wrapping: Play (with its label) and the version picker, the cast button
 * (on phones it sits across from Back instead: [castInTopBar]), then round buttons over the picture for the trailer,
 * Shuffle, the download, the watched mark and the watchlist, then ⋮ (the item's media menu, online, without the entries
 * of the buttons the row shows). Where the row has no room for them all (a phone, the details' column beside a show's
 * episodes) the watched mark stays longest, then Shuffle, then the download, the others shed first ([fitActions]), each
 * back in ⋮'s menu. Narrow windows: the row is one compact group, which the headline centres. Harness name
 * `detail.actions`.
 */
@Composable
private fun DetailActions(state: MediaDetailUiState, focus: FocusMemory, intents: DetailIntents, modifier: Modifier) {
    val offered = offeredActions(state, intents)
    val actions = state.actions
    ActionRow(
        "detail.actions",
        modifier,
        shed = { slots ->
            val shown = fitActions(offered, slots, actions.more)
            for (action in shown) key(action) { ActionButton(action, state, intents, Modifier.rememberFocus(focus, "action/$action")) }
            if (actions.more) MoreButton(intents, actions.onRow(shown), Modifier.rememberFocus(focus, "more"))
        },
    ) {
        PlaySplitButton(actions, intents.store, focus)
        if (!castInTopBar) CastButton(Modifier.rememberFocus(focus, "cast"), overPicture = true)
    }
}

/**
 * The narrow page's backdrop across the top, turning through the hero's backgrounds ([CyclingBackdrop]; the poster
 * where there is none): 45 % of the page's colour at its top (behind the back button), clear from the back button's
 * room down to the title, 80 % at the metadata line's top ([textTop]) and the page's colour at its bottom edge, every
 * fade eased. Beside a rail it runs under it. Harness name `detail.backdrop`.
 */
@Composable
private fun NarrowBackdrop(hero: DetailHeroUi, titleTop: Dp, textTop: Dp, modifier: Modifier) {
    val page = PlezyColors.Background
    NavigationBackdrop(modifier.layoutProbe("detail.backdrop", reportsFocus = false)) {
        CyclingBackdrop(hero.title, hero.backdrops, Modifier.matchParentSize(), fallback = hero.poster)
        Box(
            Modifier.matchParentSize().drawWithCache {
                val bars = BackButtonSpace.toPx() / size.height
                val title = titleTop.toPx() / size.height
                val text = textTop.toPx() / size.height
                val stops = fadeStops(page, 0f, bars, from = 0.45f, to = 0f) + fadeStops(page, title, text, from = 0f, to = 0.8f) +
                    fadeStops(page, text, 1f, from = 0.8f, to = 1f)
                val brush = Brush.verticalGradient(*stops)
                onDrawBehind { drawRect(brush) }
            },
        )
    }
}

/**
 * Wide windows: the backdrop behind the whole page, turning through the hero's backgrounds ([CyclingBackdrop]; the
 * poster where there is none). From the leading edge the picture stays near-black as far as the details' column
 * reaches ([infoEnd]), so every line of it reads, then clears over [softEdge]; the bottom fades to the page too. [dim]
 * darkens the rest of the picture (under a show's episodes).
 */
@Composable
private fun WideBackdrop(hero: DetailHeroUi, infoEnd: Dp, softEdge: Dp, dim: Boolean, modifier: Modifier) {
    val page = PlezyColors.Background
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    NavigationBackdrop(modifier.layoutProbe("detail.backdrop", reportsFocus = false)) {
        CyclingBackdrop(hero.title, hero.backdrops, Modifier.matchParentSize(), fallback = hero.poster)
        Box(
            Modifier.matchParentSize().drawWithCache {
                val end = (infoEnd + softEdge).toPx()
                val solid = infoEnd / (infoEnd + softEdge)
                val dimAlpha = if (dim) SERIES_DIM else 0f
                val stops = (fadeStops(page, 0f, solid, from = 0.96f, to = COLUMN_SCRIM) + fadeStops(page, solid, 1f, from = COLUMN_SCRIM))
                    .map { (at, color) -> at to color.copy(alpha = 1 - (1 - color.alpha) * (1 - dimAlpha)) }
                    .toTypedArray()
                val across = if (rtl) Brush.horizontalGradient(*stops, startX = size.width, endX = size.width - end) else Brush.horizontalGradient(*stops, startX = 0f, endX = end)
                val acrossWidth = if (dim) size.width else minOf(end, size.width)
                val acrossLeft = if (rtl) size.width - acrossWidth else 0f
                val bottomTop = size.height * 0.45f
                val bottom = Brush.verticalGradient(*fadeStops(page, 0.45f, 1f, from = 0f, to = 1f), startY = 0f, endY = size.height)
                onDrawBehind {
                    drawRect(across, topLeft = Offset(acrossLeft, 0f), size = Size(acrossWidth, size.height))
                    drawRect(bottom, topLeft = Offset(0f, bottomTop), size = Size(size.width, size.height - bottomTop))
                }
            },
        )
    }
}

/** How dark a show's backdrop is under its episodes, so the season names over it read. */
private const val SERIES_DIM = 0.7f

/** How dark the wide backdrop stays at the details' column's far edge, where its scrim starts to clear. */
private const val COLUMN_SCRIM = 0.86f

/**
 * Once per screen, a deep link's first focus ([MediaDetailUiState.initialFocus]): scrolls [list] to its episode row
 * ([firstRow] the list's index of the first row) or the season chips and centres it, then focuses the row or the
 * selected season's chip.
 */
@Composable
private fun InitialDetailFocus(state: MediaDetailUiState, list: LazyListState, focus: FocusMemory, firstRow: Int) {
    var applied by rememberSaveable { mutableStateOf(false) }
    val target = state.initialFocus
    LaunchedEffect(target) {
        if (target == null || applied) return@LaunchedEffect
        applied = true
        val episodeId = target.episodeId
        val (index, key) = if (episodeId != null) {
            firstRow + state.episodes!!.rows.indexOfFirst { it.id == episodeId } to episodeFocusKey(episodeId)
        } else {
            (firstRow - 1).coerceAtLeast(0) to seasonFocusKey(state.seasons[target.seasonIndex!!].id)
        }
        list.scrollToItem(index.coerceAtLeast(0))
        list.layoutInfo.visibleItemsInfo.firstOrNull { it.index == index }?.let { item ->
            list.scrollBy(item.offset + item.size / 2f - (list.layoutInfo.viewportEndOffset + list.layoutInfo.viewportStartOffset) / 2f)
        }
        repeat(INITIAL_FOCUS_FRAMES) {
            withFrameNanos { }
            if (focus.place(key)) return@LaunchedEffect
        }
    }
}

/** How many frames the initial focus waits for its row to attach after the scroll. */
private const val INITIAL_FOCUS_FRAMES = 30
