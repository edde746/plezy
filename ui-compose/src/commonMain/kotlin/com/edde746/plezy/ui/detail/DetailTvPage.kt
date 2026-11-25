package com.edde746.plezy.ui.detail

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.BringIntoViewSpec
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.Dp
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.detail.DetailHeroUi
import com.edde746.plezy.presentation.detail.EpisodeRowUi
import com.edde746.plezy.presentation.detail.MediaDetailUiState
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.cast.CastButton
import com.edde746.plezy.ui.components.ActionRow
import com.edde746.plezy.ui.components.CyclingBackdrop
import com.edde746.plezy.ui.components.SectionTitle
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.focus.focusRing
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.tvRow
import com.edde746.plezy.ui.navigation.NavigationBackdrop
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.semantics.clearAndSetSemantics
import com.edde746.plezy.presentation.detail.CastUi
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.ShelfRow
import com.edde746.plezy.ui.theme.contentDirection

/**
 * The TV detail: one page of sections over the item's backdrop, top to bottom: the
 * title block (the logo, the metadata line, the ratings with the user's rating at their end, three lines of overview
 * ending in More), the action row ([TvActionRow]: Play, the versions, every offered button and ⋮; nothing shed), the
 * track status, a show's season chips ([SeasonChips]: focus selects the season, each chip's menu is the season's media
 * menu: watched, download, delete), the focused episode's details over the selected season's episode row
 * ([TvEpisodeRow]), then Cast, Extras, the related hubs (each with View all where it has more) and the information.
 * Focusing an episode puts it in the hero ([MediaDetailStore.focusEpisode]); focusing anything above the episodes gives
 * the hero back to the item. The page moves a section at a time: on the title block while it or the action row has
 * focus; else the focused section (the seasons for the seasons and the episodes) rests at the top under the title's
 * name ([SmallTitle]), the title block fading out and the backdrop dimming. The title block shows as soon as the item
 * does (the card's while the server's loads); the actions and the sections below are composed as their data lands but
 * shown whole only once the page is [MediaDetailUiState.ready] ([Held]), and focus starts on [tvFocusStart].
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun TvDetailPage(state: MediaDetailUiState, hero: DetailHeroUi, focus: FocusMemory, intents: DetailIntents) {
    val dimens = LocalPlezyDimens.current
    val store = intents.store
    // The section the page rests on: the title block (HERO_STOP), else the section with focus, at the top under the
    // title's line.
    var stop by rememberSaveable { mutableStateOf(HERO_STOP) }
    val dim by animateFloatAsState(if (stop == HERO_STOP) 0f else 1f, tween(PAGE_MOVE_MS))
    val list = rememberLazyListState()
    // The page's sections in the list's order, so a stop is the list's index of its section.
    val sections = buildList {
        add(HERO_STOP)
        add("actions")
        if (state.seasons.isNotEmpty()) add("seasons")
        if (state.episodes != null) add("episodes")
        if (state.extras.isNotEmpty()) add("extras")
        state.related.forEach { add("hub:${it.id}") }
        if (state.cast.isNotEmpty()) add("cast")
        if (state.info.isNotEmpty()) add("info")
    }
    // Focus moving into a section moves the page there; a seasons' or episodes' focus rests on the seasons.
    val episodesStop = if (state.seasons.isNotEmpty()) "seasons" else "episodes"
    fun Modifier.stopAt(key: String) = onFocusChanged { if (it.hasFocus) stop = key }
    // Focus doesn't scroll the page itself (the stops do); the rows inside its sections scroll as the platform's do.
    val platformScroll = LocalBringIntoViewSpec.current
    val section: @Composable (@Composable () -> Unit) -> Unit = { content -> CompositionLocalProvider(LocalBringIntoViewSpec provides platformScroll, content = content) }
    // The rest shows whole once it has all landed (no button or section moves in after it), laid out meanwhile from the
    // page's second frame on: the first, the title block's, waits for none of it.
    val held: @Composable (@Composable () -> Unit) -> Unit = { content -> section { Held(state.ready, content) } }
    var laidOut by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        withFrameNanos { }
        laidOut = true
    }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val side = dimens.screenPadding
        val top = maxHeight * TOP_SHARE
        // A section rests with its content at the title's line, the list's top padding scrolled past and the spacing
        // above the section inside the title's band: the section before it ends under the band, out of view.
        val restsAt = with(LocalDensity.current) { (top - (SmallTitleSpace - dimens.sectionSpacing)).roundToPx() }
        LaunchedEffect(stop) {
            val index = sections.indexOf(stop)
            if (index <= 0) list.animateScrollToItem(0) else list.animateScrollToItem(index, restsAt)
        }
        NavigationBackdrop(Modifier.fillMaxSize()) { TvBackdrop(hero) { dim } }
        CompositionLocalProvider(LocalBringIntoViewSpec provides StaysPut) {
            LazyColumn(
                Modifier.fillMaxSize().layoutProbe("detail.page", reportsFocus = false),
                state = list,
                // Room below the last section for it to rest at the top as well: a list ending short of that stops
                // with the section above it under the title's line.
                contentPadding = PaddingValues(top = top, bottom = maxHeight - SmallTitleSpace),
            ) {
                item(key = "hero") {
                    section {
                        Column(
                            Modifier
                                .padding(horizontal = side)
                                .widthIn(max = TextColumnWidth)
                                .graphicsLayer { alpha = 1f - dim }
                                .stopAt(HERO_STOP)
                                .heroBack(intents)
                                .layoutProbe("detail.info", reportsFocus = false),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            TitleArt(hero, centred = false, LogoBox)
                            MetaLine(hero, centred = false, maxLines = 1)
                            RatingsRow(hero, centred = false, tv = true)
                            hero.summary?.let { Overview(it, focus, up = null) }
                        }
                    }
                }
                if (!state.ready && !laidOut) return@LazyColumn
                item(key = "actions") {
                    held {
                        Column(
                            Modifier
                                .padding(horizontal = side)
                                .padding(top = 20.dp)
                                .graphicsLayer { alpha = 1f - dim }
                                .stopAt(HERO_STOP)
                                .heroBack(intents),
                        ) {
                            TvActionRow(state, focus, intents)
                            if (state.tracks != null || state.tracksLoading) {
                                TrackStatus(
                                    state.tracks,
                                    TextStyle(fontSize = 15.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 0.1.sp, lineHeight = 1.2.em, color = PlezyColors.TextMuted),
                                    Modifier.padding(top = 12.dp).widthIn(max = TextColumnWidth),
                                )
                            }
                        }
                    }
                }
                if (state.seasons.isNotEmpty()) {
                    item(key = "seasons") {
                        held {
                            SeasonChips(
                                state,
                                focus,
                                store::selectSeason,
                                intents.openSeasonMenu,
                                nameStart = side,
                                modifier = Modifier.padding(top = dimens.sectionSpacing).stopAt(episodesStop).heroBack(intents),
                                up = { focus.requester(PLAY_KEY).requestFocus() },
                            )
                        }
                    }
                }
                if (state.episodes != null) {
                    item(key = "episodes") { held { TvEpisodes(state, focus, intents, Modifier.padding(top = 12.dp).stopAt(episodesStop)) } }
                }
                val below = Modifier.padding(top = dimens.sectionSpacing).heroBack(intents)
                if (state.extras.isNotEmpty()) item(key = "extras") { held { ExtrasShelf(state.extras, focus, intents, below.stopAt("extras")) } }
                items(state.related, key = { "hub:${it.id}" }) { hub -> held { RelatedHub(hub, state.actions.more, focus, intents, below.stopAt("hub:${hub.id}")) } }
                // The viewing choices first; the cast after them, as names.
                if (state.cast.isNotEmpty()) item(key = "cast") { held { TvCastRow(state.cast, focus, intents, below.stopAt("cast")) } }
                if (state.info.isNotEmpty()) {
                    item(key = "info") { held { Information(state.info, Modifier.padding(horizontal = side).then(below).stopAt("info")) } }
                }
            }
        }
        SmallTitle(hero.title, side) { dim }
    }
}

/**
 * [content] composed and measured (its images asked for) at its size, but placed only once [shown]: unplaced, it is
 * neither drawn nor focused, and it is kept from screen readers; showing it takes a placement, not a frame of
 * composition.
 */
@Composable
private fun Held(shown: Boolean, content: @Composable () -> Unit) {
    Layout(content, if (shown) Modifier else Modifier.clearAndSetSemantics {}) { measurables, constraints ->
        val placeables = measurables.map { it.measure(constraints) }
        layout(placeables.maxOfOrNull { it.width } ?: 0, placeables.maxOfOrNull { it.height } ?: 0) {
            if (shown) placeables.forEach { it.place(0, 0) }
        }
    }
}

/**
 * The title's name on one line at the top of the page, faded in by [shown] (0-1) as the page moves off the title block,
 * over a fade from the page's background so the section under it reads. Harness name `detail.smallTitle`.
 */
@Composable
private fun SmallTitle(title: String, side: Dp, shown: () -> Float) {
    val page = PlezyColors.Background
    Box(
        Modifier
            .fillMaxWidth()
            .height(SmallTitleSpace)
            .graphicsLayer { alpha = shown() }
            .background(Brush.verticalGradient(0.6f to page, 1f to page.copy(alpha = 0f)))
            .layoutProbe("detail.smallTitle", reportsFocus = false),
    ) {
        Text(
            title,
            Modifier.padding(start = side, end = side, top = SmallTitleTop).widthIn(max = TextColumnWidth),
            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/** The page's stop on the title block (and the action row under it). */
private const val HERO_STOP = "hero"

/** Room at the top for the title's name once the page has moved off the title block, and where its line starts. */
private val SmallTitleSpace = 56.dp
private val SmallTitleTop = 20.dp

/** The page's own scrolling for focus: none, as the page moves by its stops. */
@OptIn(ExperimentalFoundationApi::class)
private object StaysPut : BringIntoViewSpec {
    override fun calculateScrollDistance(offset: Float, size: Float, containerSize: Float): Float = 0f
}

/** Gives the hero back to the item once focus is in this section. */
private fun Modifier.heroBack(intents: DetailIntents): Modifier = onFocusChanged { if (it.hasFocus) intents.store.focusEpisode(null) }

/** How long the backdrop takes to dim. */
private const val PAGE_MOVE_MS = 240

/** The title block starts this far down the screen. */
private const val TOP_SHARE = 0.12f

/** The title block's text column is at most this wide. */
private val TextColumnWidth = 720.dp

/** The logo's largest size. */
private val LogoBox = DpSize(480.dp, 140.dp)

/**
 * The action row across the page ([ActionRow]): Play (with its label), the versions, the cast button, then every
 * offered round button ([offeredActions]: the trailer, Shuffle, the download, the watched mark, the watchlist) and ⋮,
 * whose menu leaves those out; on TV nothing is shed. Left and Right move along it; a move into it lands on the button
 * that had focus last, else Play. Harness name `detail.actions`.
 */
@Composable
private fun TvActionRow(state: MediaDetailUiState, focus: FocusMemory, intents: DetailIntents) {
    val actions = state.actions
    val offered = offeredActions(state, intents)
    ActionRow("detail.actions", Modifier.tvRow { focus.focus(PLAY_KEY) }) {
        PlaySplitButton(actions, intents.store, focus)
        CastButton(Modifier.rememberFocus(focus, "cast"), overPicture = true)
        for (action in offered) {
            ActionButton(action, state, intents, Modifier.rememberFocus(focus, "action/${action.name}"))
        }
        if (actions.more) MoreButton(intents, actions.onRow(offered), Modifier.rememberFocus(focus, "more"))
    }
}

/**
 * The selected season's episodes: the focused episode's details (its title, metadata and three lines of summary; as tall
 * as three lines always, so the row holds still) over a row of 16:9 cards ([TvEpisodeCard]), paged as its end comes
 * into view. The row opens on the episode [tvFocusStart] names (the route's, else the on-deck one); a move into it lands
 * on the card that had focus last, else that one. While the episodes load or failed, their state.
 */
@Composable
private fun TvEpisodes(state: MediaDetailUiState, focus: FocusMemory, intents: DetailIntents, modifier: Modifier) {
    val episodes = state.episodes ?: return
    val side = LocalPlezyDimens.current.screenPadding
    if (episodes.load != SectionLoad.CONTENT) {
        Column(modifier.fillMaxWidth()) {
            if (state.seasons.isEmpty()) SectionTitle(T.libraries.groupings.episodes, Modifier.padding(horizontal = side))
            EpisodesState(state, intents)
        }
        return
    }
    val rows = episodes.rows
    val startId = rows.firstOrNull { it.id == state.initialEpisodeId }?.id ?: rows.firstOrNull()?.id
    var shownId by rememberSaveable(state.selectedSeason) { mutableStateOf(startId) }
    val shown = rows.firstOrNull { it.id == shownId } ?: rows.firstOrNull()
    val row = rememberSaveable(state.selectedSeason, saver = androidx.compose.foundation.lazy.LazyListState.Saver) {
        androidx.compose.foundation.lazy.LazyListState((rows.indexOfFirst { it.id == startId } - 1).coerceAtLeast(0))
    }
    Column(modifier.fillMaxWidth()) {
        if (state.seasons.isEmpty()) SectionTitle(T.libraries.groupings.episodes, Modifier.padding(horizontal = side).padding(bottom = LocalPlezyDimens.current.shelfHeaderGap))
        shown?.let { TvEpisodeDetails(it, Modifier.padding(horizontal = side).widthIn(max = TextColumnWidth)) }
        LazyRow(
            Modifier
                .fillMaxWidth()
                .tvRow { shownId?.let { focus.focus(episodeFocusKey(it)) } }
                .layoutProbe("detail.episodes", reportsFocus = false),
            state = row,
            contentPadding = PaddingValues(horizontal = side, vertical = LocalPlezyDimens.current.focusReach),
            horizontalArrangement = Arrangement.spacedBy(EpisodeGap),
        ) {
            itemsIndexed(rows, key = { _, it -> it.id }) { index, episode ->
                TvEpisodeCard(episode, index, focus, intents) {
                    shownId = episode.id
                    intents.store.focusEpisode(episode.id)
                }
            }
            if (episodes.moreFailed || episodes.hasMore) {
                item(key = "tail") { EpisodesTail(state, intents, Modifier.width(EpisodeWidth)) }
            }
        }
    }
}

private val EpisodeWidth = 260.dp
private val EpisodeGap = 16.dp

/** The focused episode large above the row: its numbered title, its metadata, three lines of summary. Harness name `detail.episodeDetails`. */
@Composable
private fun TvEpisodeDetails(episode: EpisodeRowUi, modifier: Modifier) {
    Column(modifier.heightIn(min = 120.dp).layoutProbe("detail.episodeDetails", reportsFocus = false), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(episode.title, style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold), maxLines = 1, overflow = TextOverflow.Ellipsis)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            episode.download?.let { EpisodeDownloadMark(it) }
            Text(episode.metadata.joinToString("  •  "), style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        Text(episode.summary.orEmpty(), style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, maxLines = 3, overflow = TextOverflow.Ellipsis)
    }
}

/**
 * An episode's 16:9 card ([EpisodeThumbnail]: progress, a check once watched, blurred while a spoiler). Select plays it
 * (directly, whatever the card preference); a held Select, a right click or the Menu key opens its media menu, offline
 * too. One semantics node named by its numbered title. Harness name `detail.episode.<id>`.
 */
@Composable
private fun TvEpisodeCard(episode: EpisodeRowUi, index: Int, focus: FocusMemory, intents: DetailIntents, onFocused: () -> Unit) {
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    val openMenu = { intents.openEpisodeMenu(episode.id) }
    Box(
        Modifier
            .width(EpisodeWidth)
            .rememberFocus(focus, episodeFocusKey(episode.id))
            .onFocusChanged { if (it.isFocused) onFocused() }
            .menuGestures(openMenu)
            .semantics(mergeDescendants = true) { contentDescription = episode.title }
            .combinedClickable(interactions, indication = null, onLongClick = openMenu) { intents.store.playEpisode(episode.id) }
            .layoutProbe("detail.episode.${episode.id}"),
    ) {
        EpisodeThumbnail(
            episode.thumb,
            episode.blurThumb,
            Modifier.fillMaxWidth().focusRing(ThumbnailShape, focused),
            watched = episode.watched,
            progress = episode.progress?.toFloat(),
        )
        Text(
            "${index + 1}",
            Modifier.align(Alignment.BottomStart).padding(8.dp).alpha(if (focused) 1f else 0.7f),
            style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
            color = Color.White,
        )
    }
}

/**
 * The key of the element the TV detail focuses first ([RestoreFocus]'s fallback): Play on a movie; on a show or season
 * the selected season's episode the route names, else the on-deck one ([MediaDetailUiState.initialEpisodeId]), else
 * its first; Play otherwise.
 */
internal fun tvFocusStart(state: MediaDetailUiState): String {
    if (state.kind == MediaKind.MOVIE) return PLAY_KEY
    val episodes = state.episodes ?: return PLAY_KEY
    val rows = if (episodes.load == SectionLoad.CONTENT) episodes.rows else return PLAY_KEY
    val row = rows.firstOrNull { it.id == state.initialEpisodeId } ?: rows.firstOrNull() ?: return PLAY_KEY
    return episodeFocusKey(row.id)
}

/**
 * The backdrop behind the page, turning through the hero's backgrounds ([CyclingBackdrop]; the poster where there is
 * none), with its scrims: dark from the start edge and toward the foot; [dim] (0-1) darkens it as focus leaves the
 * title block. Harness name `detail.backdrop`.
 */
@Composable
private fun TvBackdrop(hero: DetailHeroUi, dim: () -> Float) {
    val background = PlezyColors.Background
    Box(Modifier.fillMaxSize().layoutProbe("detail.backdrop", reportsFocus = false)) {
        CyclingBackdrop(hero.title, hero.backdrops, Modifier.fillMaxSize(), fallback = hero.poster)
        Box(Modifier.fillMaxSize().background(Brush.horizontalGradient(0f to background.copy(alpha = 0.95f), 0.55f to background.copy(alpha = 0.8f), 1f to background.copy(alpha = 0.1f))))
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.3f to Color.Transparent, 1f to background)))
        Box(Modifier.fillMaxSize().graphicsLayer { alpha = dim() }.background(background.copy(alpha = 0.7f)))
    }
}

/**
 * The cast as a row of names, each with the character played, after the viewing choices: each opens the actor's
 * titles ([MediaDetailStore.castRoute][com.edde746.plezy.presentation.detail.MediaDetailStore.castRoute]). They rest
 * on the translucent picture fill and take the focus fill without growth, as the season chips do. Harness names
 * `detail.cast.<i>`.
 */
@Composable
private fun TvCastRow(cast: List<CastUi>, focus: FocusMemory, intents: DetailIntents, modifier: Modifier) {
    ShelfRow(T.discover.cast, cast.indices.toList(), key = { it }, modifier = modifier.layoutProbe("detail.cast", reportsFocus = false)) { _, index ->
        val member = cast[index]
        val target = intents.store.castRoute(index)
        PlezySurface(
            onClick = { target?.let { intents.navigate(it) } },
            modifier = Modifier
                .heightIn(min = LocalPlezyDimens.current.chipHeight)
                .rememberFocus(focus, "cast/$index")
                .semantics { contentDescription = listOfNotNull(member.name, member.role).joinToString(", ") }
                .layoutProbe("detail.cast.$index"),
            shape = CircleShape,
            // The dark picture fill whatever the theme, so white content, as an OVER_PICTURE button's.
            color = PlezyColors.PictureButton,
            contentColor = Color.White,
            contentAlignment = Alignment.Center,
            grows = false,
        ) {
            // The chip says the name and the character itself.
            Row(Modifier.widthIn(max = CastChipMaxWidth).padding(horizontal = 18.dp, vertical = 8.dp).clearAndSetSemantics {}, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(member.name, style = MaterialTheme.typography.labelLarge.contentDirection(), maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                // Muted from the chip's own content colour, so it stays readable on the white focus fill too.
                member.role?.let { Text(it, style = MaterialTheme.typography.labelLarge.contentDirection(), color = PlezyColors.MutedContent, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false)) }
            }
        }
    }
}

/** The widest a cast name chip grows. */
private val CastChipMaxWidth = 360.dp
