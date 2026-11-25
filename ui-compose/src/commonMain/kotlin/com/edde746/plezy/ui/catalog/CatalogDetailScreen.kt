package com.edde746.plezy.ui.catalog

import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import com.edde746.plezy.presentation.browse.placeholderKind
import com.edde746.plezy.presentation.ratings.RatingChip
import com.edde746.plezy.presentation.ratings.ratingChips
import com.edde746.plezy.trackers.ratings.withCommunityRatings
import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.detail.bleed

import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.HubIcon
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.catalog.CatalogDetailFact
import com.edde746.plezy.presentation.catalog.CatalogDetailLink
import com.edde746.plezy.presentation.catalog.CatalogDetailUiState
import com.edde746.plezy.presentation.catalog.CatalogLibraryCopy
import com.edde746.plezy.presentation.catalog.CatalogLibrarySection
import com.edde746.plezy.presentation.catalog.CatalogRelationEntry
import com.edde746.plezy.presentation.catalog.CatalogRequestAction
import com.edde746.plezy.presentation.explore.toCatalogCard
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.seerr.SeerrBlock
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.FoldingActionRow
import com.edde746.plezy.ui.components.RowAction
import com.edde746.plezy.ui.components.Badge
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.HubRow
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.SectionTitle
import com.edde746.plezy.ui.components.ShelfRow
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.fadeStops
import com.edde746.plezy.ui.focus.FocusInto
import com.edde746.plezy.ui.focus.focusRing
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.LogoRecolour
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.libraries.libraryIcon
import com.edde746.plezy.ui.navigation.NavigationBackdrop
import com.edde746.plezy.ui.navigation.ScrollEdgeScrim
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.ratings.BackendLogo
import com.edde746.plezy.ui.ratings.RatingLogo
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import kotlin.time.Clock

/** What the catalog detail screen asks of its store and the app. */
class CatalogDetailIntents(
    val toggleWatchlist: () -> Unit,
    /** Opens the Seerr request sheet for the item. */
    val request: () -> Unit,
    val playTrailer: () -> Unit,
    val openLink: (String) -> Unit,
    val revealSpoilerTags: () -> Unit,
    val messageShown: () -> Unit,
    /** Opens another catalog title's detail (a relation, More like this). */
    val openItem: (CatalogItem) -> Unit,
    /** Opens a library's copy of the title (its media detail). */
    val openCopy: (CatalogLibraryCopy) -> Unit,
    /** Opens a cast member's Seerr person page ([CatalogDetailUiState.personRoute]). */
    val openPerson: (Route.SeerrPerson) -> Unit,
    /** Back, where the screen shows its own back button; null on TV. */
    val back: (() -> Unit)?,
)

/** A catalog title's detail ([route]) over [app]'s store. */
@Composable
fun CatalogDetailScreen(app: AppSession, route: Route.CatalogDetail, modifier: Modifier = Modifier) {
    val host = rememberCatalogDetailHost(app)
    val store = remember(app, route) { app.catalogDetail(route, host) } ?: return
    val state by store.state.collectAsState()
    val actions = rememberCatalogCardActions(app)
    val tv = LocalAppearance.current.tv
    val intents = remember(store, tv) {
        CatalogDetailIntents(
            toggleWatchlist = store::toggleWatchlist,
            request = {
                val current = store.state.value
                current.request?.takeIf { it.enabled }?.let { app.navigator.navigate(Route.SeerrRequest(it.tmdbId, current.item.kind, it.title)) }
            },
            playTrailer = store::playTrailer,
            openLink = store::openLink,
            revealSpoilerTags = store::revealSpoilerTags,
            messageShown = store::messageShown,
            openItem = actions.open,
            openCopy = { copy -> app.navigator.navigate(Route.MediaDetail(ServerId(checkNotNull(copy.item.serverId) { "library copy without a server" }), copy.item.id).seeded(copy.item)) },
            openPerson = { app.navigator.navigate(it) },
            back = if (tv) null else ({ app.navigator.back() }),
        )
    }
    CatalogDetailContent(state, intents, modifier)
}

/**
 * A catalog title's detail. Narrow windows ([NarrowPage]): one scrolling column, the
 * backdrop across the top fading into the page under the title (its clear logo, recoloured on light themes, else its
 * name), centred. Wide windows and TV ([WidePage]): the backdrop behind the whole screen, near the page's colour under
 * a details column at the start. Either way the headline ([Headline]: tagline, title, meta line and genres, the
 * actions — Watchlist, Request, Watch trailer, focus starting on the first —, the stats as badges, the overview folded
 * until opened), then the library availability, More like this, the related titles, the cast, the ratings and the
 * Information (facts, recommenders, schedule, crew, tags with "Show spoiler tags", the outbound links). The D-pad
 * walks them in that order. The store's one-off message shows at the foot. Harness names: `catalogDetail.*`.
 */
@Composable
fun CatalogDetailContent(state: CatalogDetailUiState, intents: CatalogDetailIntents, modifier: Modifier = Modifier) {
    val firstAction = remember { FocusRequester() }
    val tv = LocalAppearance.current.tv
    Box(modifier.fillMaxSize().layoutProbe("catalogDetail", reportsFocus = false)) {
        BoxWithConstraints(Modifier.fillMaxSize()) {
            if (tv || maxWidth >= WideLayoutWidth) {
                WidePage(state, intents, firstAction, maxWidth, maxHeight)
            } else {
                NarrowPage(state, intents, firstAction, maxWidth, maxHeight)
            }
        }
        intents.back?.let { back ->
            PlezyIconButton(
                PlezyIcons.ArrowBack,
                T.nav.back,
                back,
                Modifier.padding(start = 12.dp, top = statusBarOverlap + 8.dp).layoutProbe("catalogDetail.back"),
                style = IconButtonStyle.OVER_PICTURE,
            )
        }
        state.message?.let { text ->
            TimedToast(text, "catalogDetail.message", onShown = intents.messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = LocalPlezyDimens.current.sectionSpacing))
        }
    }
    // Focus starts on the first action that takes a press, and moves on to it again when Request turns into a state
    // (Requested, after the sheet sent one): never left on a status label.
    if (state.hasActions && (state.watchlist != null || state.request?.enabled == true || state.hasTrailer)) FocusInto(firstAction, state.request?.enabled)
}

/** Windows at least this wide put the details in a column over a full-screen backdrop. */
private val WideLayoutWidth = 840.dp

/** The details' column on wide layouts is at most this wide. */
private val InfoMaxWidth = 560.dp

/** Room above the details for the back button laid over the page. */
private val BackButtonSpace = 68.dp

/**
 * Phones and narrow windows: one column. The backdrop across the top (about 16:10, never most of a landscape window),
 * its picture fading into the page's colour behind the title, which sits centred over its bottom.
 */
@Composable
private fun NarrowPage(state: CatalogDetailUiState, intents: CatalogDetailIntents, firstAction: FocusRequester, width: Dp, height: Dp) {
    val dimens = LocalPlezyDimens.current
    val heroHeight = minOf(width * 0.62f, height * 0.6f, 420.dp)
    val backdrop = state.item.backdropFor(with(LocalDensity.current) { width.roundToPx() })
    val titleTop = if (backdrop != null) (heroHeight - NarrowTitleHeight).coerceAtLeast(BackButtonSpace + statusBarOverlap) else BackButtonSpace + statusBarOverlap
    val scroll = rememberScrollState()
    Column(Modifier.fillMaxSize().verticalScroll(scroll).padding(bottom = dimens.sectionSpacing * 2)) {
        Box(Modifier.fillMaxWidth()) {
            if (backdrop != null) NarrowBackdrop(backdrop, Modifier.fillMaxWidth().height(heroHeight + PictureUnderText))
            Column(Modifier.fillMaxWidth().padding(top = titleTop).padding(horizontal = dimens.screenPadding)) {
                Headline(state, intents, firstAction, centred = true, titleHeight = NarrowTitleHeight)
            }
        }
        Body(state, intents, width, Modifier.padding(top = dimens.sectionSpacing))
    }
    // The back button over the page: the column's top edge under it once the column has left its top.
    ScrollEdgeScrim({ scroll.canScrollBackward }, BackButtonSpace + statusBarOverlap)
}

/**
 * Wide windows and TV: the backdrop behind the whole screen, near the page's colour under the details column and
 * clearing past it, fading into the page at the bottom; the details in a column at the start (at most [InfoMaxWidth]),
 * starting under the picture's top third.
 */
@Composable
private fun WidePage(state: CatalogDetailUiState, intents: CatalogDetailIntents, firstAction: FocusRequester, width: Dp, height: Dp) {
    val dimens = LocalPlezyDimens.current
    val reach = dimens.focusReach
    val infoWidth = (width - dimens.screenPadding * 2).coerceAtMost(InfoMaxWidth)
    val backdrop = state.item.backdropFor(with(LocalDensity.current) { width.roundToPx() })
    val scroll = rememberScrollState()
    Box(Modifier.fillMaxSize()) {
        WideBackdrop(backdrop, dimens.screenPadding + infoWidth, softEdge = (width * 0.25f).coerceIn(200.dp, 400.dp), Modifier.fillMaxSize())
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(scroll)
                .padding(top = (height * 0.3f).coerceAtLeast(BackButtonSpace + statusBarOverlap), bottom = dimens.sectionSpacing * 2),
        ) {
            Column(Modifier.padding(start = dimens.screenPadding - reach).width(infoWidth + reach * 2).padding(horizontal = reach)) {
                Headline(state, intents, firstAction, centred = false, titleHeight = WideTitleHeight)
            }
            Body(state, intents, width, Modifier.padding(top = dimens.sectionSpacing))
        }
        // TV has no back button over the page.
        if (intents.back != null) ScrollEdgeScrim({ scroll.canScrollBackward }, BackButtonSpace + statusBarOverlap)
    }
}

/** The narrow page's title box: a logo centred in it. */
private val NarrowTitleHeight = 120.dp

/** The wide page's title box. */
private val WideTitleHeight = 140.dp

/** The narrow page's picture reaches this far under the title box, behind the meta line. */
private val PictureUnderText = 34.dp

/**
 * Narrow windows: the backdrop, a light scrim at its top (behind the back button and the status bar), clear through
 * the middle, fading into the page's colour towards its bottom, where the title sits. Harness name
 * `catalogDetail.backdrop`.
 */
@Composable
private fun NarrowBackdrop(url: String, modifier: Modifier) {
    val page = MaterialTheme.colorScheme.background
    NavigationBackdrop(modifier.layoutProbe("catalogDetail.backdrop", reportsFocus = false)) {
        RemoteImage(url, contentDescription = null, modifier = Modifier.matchParentSize())
        Box(
            Modifier.matchParentSize().drawWithCache {
                val stops = fadeStops(page, 0f, 0.25f, from = 0.45f, to = 0f) + fadeStops(page, 0.45f, 1f, from = 0f, to = 1f)
                val brush = Brush.verticalGradient(*stops)
                onDrawBehind { drawRect(brush) }
            },
        )
    }
}

/**
 * Wide windows: the backdrop behind the whole page. From the start edge the picture stays near the page's colour as far
 * as the details' column reaches ([infoEnd]), then clears over [softEdge]; the bottom fades into the page.
 */
@Composable
private fun WideBackdrop(url: String?, infoEnd: Dp, softEdge: Dp, modifier: Modifier) {
    val page = MaterialTheme.colorScheme.background
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    NavigationBackdrop(modifier.layoutProbe("catalogDetail.backdrop", reportsFocus = false)) {
        if (url != null) RemoteImage(url, contentDescription = null, modifier = Modifier.matchParentSize())
        Box(
            Modifier.matchParentSize().drawWithCache {
                val end = (infoEnd + softEdge).toPx()
                val solid = infoEnd / (infoEnd + softEdge)
                val stops = fadeStops(page, 0f, solid, from = 0.96f, to = COLUMN_SCRIM) + fadeStops(page, solid, 1f, from = COLUMN_SCRIM)
                val across = if (rtl) Brush.horizontalGradient(*stops, startX = size.width, endX = size.width - end) else Brush.horizontalGradient(*stops, startX = 0f, endX = end)
                val acrossWidth = minOf(end, size.width)
                val acrossLeft = if (rtl) size.width - acrossWidth else 0f
                val bottomTop = size.height * 0.45f
                val bottom = Brush.verticalGradient(*arrayOf(0f to Color.Transparent) + fadeStops(page, 1f, 0.45f, from = 1f), startY = 0f, endY = size.height)
                onDrawBehind {
                    drawRect(across, topLeft = Offset(acrossLeft, 0f), size = Size(acrossWidth, size.height))
                    drawRect(bottom, topLeft = Offset(0f, bottomTop), size = Size(size.width, size.height - bottomTop))
                }
            },
        )
    }
}

/** How close to the page's colour the wide backdrop stays at the details' column's far edge. */
private const val COLUMN_SCRIM = 0.86f

/**
 * The title, the lines under it and the actions; [centred] on narrow windows. The title fills a box [titleHeight] tall
 * ([TitleArt]); the actions follow ([CatalogActions]), then the stats as badges and the overview, folded until opened.
 */
@Composable
private fun Headline(state: CatalogDetailUiState, intents: CatalogDetailIntents, firstAction: FocusRequester, centred: Boolean, titleHeight: Dp) {
    val alignment = if (centred) Alignment.CenterHorizontally else Alignment.Start
    val textAlign = if (centred) TextAlign.Center else TextAlign.Start
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp), horizontalAlignment = alignment) {
        TitleArt(state, centred, titleHeight)
        val muted = PlezyColors.TextMuted
        if (state.tagline != null || state.metaLine != null || state.genres != null) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp), horizontalAlignment = alignment) {
                state.tagline?.let { Text(it, style = MaterialTheme.typography.bodyLarge.copy(fontStyle = FontStyle.Italic), color = muted, textAlign = textAlign) }
                state.metaLine?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = muted, textAlign = textAlign) }
                state.genres?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = muted, textAlign = textAlign) }
            }
        }
        if (state.hasActions) CatalogActions(state, intents, firstAction, centred)
        if (state.stats.isNotEmpty()) Badges(state.stats, centred, Modifier.layoutProbe("catalogDetail.stats", reportsFocus = false))
        state.overview?.let { FoldedText(it, OVERVIEW_LINES, "catalogDetail.overview", textAlign) }
    }
}

/**
 * The title's art: its clear logo fitted in the box (recoloured towards the theme's text on a light theme,
 * [LogoRecolour.TITLE]), or the name where there is none or it fails to load.
 */
@Composable
private fun TitleArt(state: CatalogDetailUiState, centred: Boolean, height: Dp) {
    val name = @Composable {
        Text(
            state.title,
            style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.SemiBold),
            textAlign = if (centred) TextAlign.Center else TextAlign.Start,
            maxLines = 3,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.layoutProbe("catalogDetail.title"),
        )
    }
    val logo = Artwork.fixed(state.item.logoUrl)
    if (logo == null) {
        name()
        return
    }
    val align = if (centred) Alignment.BottomCenter else Alignment.BottomStart
    RemoteImage(
        logo,
        contentDescription = state.title,
        modifier = Modifier.fillMaxWidth(if (centred) 0.8f else 1f).widthIn(max = InfoMaxWidth).height(height).layoutProbe("catalogDetail.logo"),
        contentScale = ContentScale.Fit,
        alignment = align,
        logo = LogoRecolour.TITLE,
        error = { Box(Modifier.fillMaxSize(), contentAlignment = align) { name() } },
    )
}

/**
 * Watchlist, Request and Watch trailer, whichever apply, in a [FoldingActionRow]: the first and Request (the page's
 * own action) pills with their words, the first the primary one; Watch trailer a round button, folded into ⋮
 * (`catalogDetail.more`) where the width runs out. A title Seerr has or that is requested shows that state where
 * Request was, as a status label in the text colour ([StatusLabel]), never as a disabled button; Request is as wide as
 * its widest state so the actions beside it stay put when it turns into Requested. [first] goes on the first action
 * that takes a press. Harness name `catalogDetail.actions`.
 */
@Composable
private fun CatalogActions(state: CatalogDetailUiState, intents: CatalogDetailIntents, first: FocusRequester, centred: Boolean) {
    class Pill(val action: RowAction, val enabled: Boolean = true, val widthOf: List<String> = emptyList())
    val pills = buildList {
        state.watchlist?.let { add(Pill(RowAction(if (it.onWatchlist == true) PlezyIcons.Bookmark else PlezyIcons.BookmarkBorder, it.label, "catalogDetail.watchlist", onClick = intents.toggleWatchlist))) }
        state.request?.let { add(Pill(RowAction(requestIcon(it.blocked), it.label, "catalogDetail.request", onClick = intents.request), it.enabled, it.states.map(CatalogRequestAction::label))) }
    }
    val firstPill = pills.indexOfFirst { it.enabled }
    // With no pill that takes a press, focus starts on Watch trailer.
    val trailer = if (state.hasTrailer) {
        RowAction(PlezyIcons.Trailer, T.explore.detail.watchTrailer, "catalogDetail.trailer", if (firstPill < 0) Modifier.focusRequester(first) else Modifier, onClick = intents.playTrailer)
    } else {
        null
    }
    val labelled = pills.ifEmpty { listOfNotNull(trailer?.let { Pill(it) }) }
    if (labelled.isEmpty()) return
    val fold = if (pills.isEmpty()) emptyList() else listOfNotNull(trailer)
    FoldingActionRow("catalogDetail.actions", fold, "catalogDetail.more", centred = centred) {
        labelled.forEachIndexed { index, pill ->
            val action = pill.action
            val style = if (index == 0) ButtonStyle.PRIMARY else ButtonStyle.SECONDARY
            WidestLabel(pill.widthOf, style, action.icon) {
                if (pill.enabled) {
                    PlezyButton(
                        action.label,
                        action.onClick,
                        action.modifier.then(if (index == firstPill) Modifier.focusRequester(first) else Modifier).layoutProbe(action.probe),
                        style = style,
                        icon = action.icon,
                    )
                } else {
                    StatusLabel(action.label, action.icon, centred, Modifier.layoutProbe(action.probe, reportsFocus = false))
                }
            }
        }
    }
}

/**
 * A state shown in an action's place (Available, Requested): its icon and words in the text colour, from the place's
 * start edge where a pill's icon would start or, in a [centred] row, in the place's centre; vertically centred in the
 * row; not a control.
 */
@Composable
private fun StatusLabel(text: String, icon: ImageVector, centred: Boolean, modifier: Modifier) {
    Row(
        modifier.fillMaxHeight().semantics(mergeDescendants = true) {}.padding(horizontal = 16.dp),
        horizontalArrangement = if (centred) Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally) else Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, Modifier.size(20.dp), tint = PlezyColors.Text)
        Text(text, style = MaterialTheme.typography.labelLarge, color = PlezyColors.Text, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

/**
 * [button] at least as wide as a [style] button with [icon] and the widest of [labels], so its width holds while its
 * label changes among them. The buttons it measures are never placed, and neither accessibility nor focus finds them.
 */
@Composable
private fun WidestLabel(labels: List<String>, style: ButtonStyle, icon: ImageVector, button: @Composable () -> Unit) {
    if (labels.isEmpty()) return button()
    Layout(
        contents = listOf(
            { labels.forEach { PlezyButton(it, {}, Modifier.clearAndSetSemantics {}, style = style, icon = icon, enabled = false) } },
            button,
        ),
    ) { (sizes, shown), constraints ->
        val loose = constraints.copy(minWidth = 0, minHeight = 0)
        val width = sizes.maxOf { it.measure(loose).width }.coerceIn(constraints.minWidth, constraints.maxWidth)
        val placeable = shown.single().measure(constraints.copy(minWidth = width))
        layout(placeable.width, placeable.height) { placeable.place(0, 0) }
    }
}

/** Request's symbol, or its state's when the title can't be requested. */
private fun requestIcon(blocked: SeerrBlock?): ImageVector = when (blocked) {
    null -> PlezyIcons.Add
    SeerrBlock.AVAILABLE, SeerrBlock.PARTIALLY_AVAILABLE -> PlezyIcons.CheckCircle
    SeerrBlock.PROCESSING, SeerrBlock.REQUESTED -> PlezyIcons.Schedule
    SeerrBlock.BLOCKLISTED -> PlezyIcons.Block
}

/**
 * Below the headline: the library availability, More like this, the related titles, the cast, the ratings and the
 * Information.
 */
@Composable
private fun Body(state: CatalogDetailUiState, intents: CatalogDetailIntents, width: Dp, modifier: Modifier) {
    val dimens = LocalPlezyDimens.current
    val padded = Modifier.padding(horizontal = dimens.screenPadding)
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(dimens.sectionSpacing)) {
        if (state.library != CatalogLibrarySection.SaidByStatus) Box(padded) { Library(state.library, intents.openCopy) }
        if (state.related.isNotEmpty()) Related(state, intents.openItem)
        if (state.relations.isNotEmpty()) Section(T.explore.detail.relatedTitles, padded) { Relations(state.relations, width, intents.openItem) }
        if (state.cast.isNotEmpty()) Section(state.castTitle, padded) { Cast(state, intents.openPerson) }
        val ratings = remember(state.ratings, state.communityRatings) { ratingChips(withCommunityRatings(state.ratings, state.communityRatings)) }
        if (ratings.isNotEmpty()) Section(T.explore.detail.ratings, padded) { RatingBadges(ratings) }
        Information(state, intents, padded)
    }
}

/**
 * The information block: the background, the facts, the recommenders, the schedule, the crew, the tags
 * (spoilers behind "Show spoiler tags") and the outbound links, each a label in a column of its own then its value.
 * The facts through the crew are one stop for the keyboard and the remote ([FactsStop]), so Down from the cast still
 * reaches the foot of a page whose information holds nothing that takes a press.
 */
@Composable
private fun Information(state: CatalogDetailUiState, intents: CatalogDetailIntents, modifier: Modifier) {
    Column(modifier.layoutProbe("catalogDetail.information", reportsFocus = false), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        state.background?.let { InformationRow(T.explore.detail.background) { FoldedText(it, OVERVIEW_LINES, "catalogDetail.background", TextAlign.Start) } }
        if (state.facts.isNotEmpty() || state.recommenders.isNotEmpty() || state.schedule.isNotEmpty() || state.crew.isNotEmpty()) {
            FactsStop {
                for (fact in state.facts) InformationRow(fact.label) { Text(fact.value, style = MaterialTheme.typography.bodyMedium) }
                for (recommender in state.recommenders) {
                    InformationRow(recommender.text) { recommender.note?.let { Text(it, style = MaterialTheme.typography.bodyMedium) } }
                }
                if (state.schedule.isNotEmpty()) InformationRow(T.explore.detail.schedule) { Badges(state.schedule, centred = false) }
                for (fact in state.crew) InformationRow(fact.label) { Text(fact.value, style = MaterialTheme.typography.bodyMedium) }
            }
        }
        state.tags?.let { tags ->
            InformationRow(T.explore.detail.tags) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (tags.visible.isNotEmpty()) Badges(tags.visible, centred = false)
                    if (tags.canRevealSpoilers) {
                        PlezyButton(T.explore.detail.revealSpoilerTags, intents.revealSpoilerTags, Modifier.layoutProbe("catalogDetail.revealSpoilers"), icon = PlezyIcons.Visibility)
                    }
                }
            }
        }
        if (state.watchOnLinks.isNotEmpty()) InformationRow(T.explore.detail.watchOn) { Links(state.watchOnLinks, intents.openLink) }
        if (state.links.isNotEmpty()) InformationRow(T.explore.detail.links) { Links(state.links, intents.openLink) }
    }
}

/** A line of the information block: [label] in a column of its own, then [value], the label on the value's first line. */
@Composable
private fun InformationRow(label: String, value: @Composable () -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, modifier = Modifier.width(112.dp).alignByBaseline())
        Box(Modifier.weight(1f).alignByBaseline()) { value() }
    }
}

/**
 * Plain lines of the information block as one stop for the keyboard and the remote (on a touch screen none, as the
 * cast's portraits): the page scrolls to it, its ring [FactsInset] past its words, which stay in line with the other
 * sections'. Left and Right stay on it; Up and Down leave it. Harness name `catalogDetail.facts`.
 */
@Composable
private fun FactsStop(content: @Composable ColumnScope.() -> Unit) {
    val keys = LocalInputModeManager.current.inputMode != InputMode.Touch
    Column(
        Modifier
            .fillMaxWidth()
            .bleed(FactsInset)
            .layoutProbe("catalogDetail.facts")
            .focusRing(RoundedCornerShape(12.dp))
            .focusProperties {
                left = FocusRequester.Cancel
                right = FocusRequester.Cancel
            }
            .focusable(enabled = keys)
            .padding(horizontal = FactsInset, vertical = 4.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        content = content,
    )
}

/** The facts' ring's room past their words, outside the column the sections line up in. */
private val FactsInset = 12.dp

/** A section: its [title] over its content. */
@Composable
private fun Section(title: String, modifier: Modifier, content: @Composable () -> Unit) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(LocalPlezyDimens.current.shelfHeaderGap)) {
        SectionTitle(title)
        content()
    }
}

/** [labels] as badges, wrapping; [centred] on narrow windows. */
@Composable
private fun Badges(labels: List<String>, centred: Boolean, modifier: Modifier = Modifier) {
    FlowRow(
        modifier,
        horizontalArrangement = Arrangement.spacedBy(6.dp, if (centred) Alignment.CenterHorizontally else Alignment.Start),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        for (label in labels) Badge(label)
    }
}

/**
 * The scores ([ratingChips]), each a badge: its source's logo (named for a screen reader) and its value as the source
 * writes it, or a star and the source's name with the score; the votes after it where the source counts them.
 */
@Composable
private fun RatingBadges(chips: List<RatingChip>) {
    FlowRow(
        Modifier.layoutProbe("catalogDetail.ratings", reportsFocus = false),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        for (chip in chips) {
            val spoken = if (chip.icon != null) "${chip.sourceLabel} ${chip.label}" else chip.label
            Badge(chip.label, Modifier.clearAndSetSemantics { contentDescription = spoken }) {
                val icon = chip.icon
                if (icon != null) {
                    RatingLogo(icon, Modifier.size(RatingMark * icon.aspect.toFloat(), RatingMark))
                } else {
                    Icon(PlezyIcons.Star, null, Modifier.size(RatingMark))
                }
            }
        }
    }
}

/** A score's logo's height in its badge. */
private val RatingMark = 14.dp

/** How many lines the overview and the background show until opened. */
private const val OVERVIEW_LINES = 4

/**
 * Text folded to [lines] lines; a press (Select, a tap, a click) unfolds it or folds it again. It is a stop for the
 * remote either way, so a long overview can be read. Its inset lies outside the column: the words line up with the
 * title above.
 */
@Composable
private fun FoldedText(text: String, lines: Int, probe: String, textAlign: TextAlign) {
    var open by remember { mutableStateOf(false) }
    PlezySurface(
        onClick = { open = !open },
        modifier = Modifier.fillMaxWidth().bleed(FoldedTextInset).layoutProbe(probe),
        color = Color.Transparent,
        grows = false,
    ) {
        Text(
            text,
            Modifier.padding(FoldedTextInset),
            style = MaterialTheme.typography.bodyLarge,
            textAlign = textAlign,
            maxLines = if (open) Int.MAX_VALUE else lines,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/** The folded text's room around its words inside its press highlight. */
private val FoldedTextInset = 4.dp

private fun gridColumns(width: Dp, count: Int): Int {
    val fits = when {
        width >= 1100.dp -> 3
        width >= 700.dp -> 2
        else -> 1
    }
    return fits.coerceAtMost(count).coerceAtLeast(1)
}

@Composable
private fun Links(links: List<CatalogDetailLink>, open: (String) -> Unit) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        for (link in links) PlezyButton(link.label, { open(link.url) }, icon = PlezyIcons.OpenInNew, style = ButtonStyle.SECONDARY)
    }
}

/**
 * Where the title is in the libraries: checking, not there, couldn't check, or the copies ([onOpen] opens one), each
 * with its library's kind icon and its server software's mark. Not shown where the Available status says it
 * ([CatalogLibrarySection.SaidByStatus]).
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun Library(section: CatalogLibrarySection, onOpen: (CatalogLibraryCopy) -> Unit) {
    val muted = PlezyColors.TextMuted
    Box(Modifier.layoutProbe("catalogDetail.library", reportsFocus = false)) {
        when (section) {
            CatalogLibrarySection.Checking -> Row(verticalAlignment = Alignment.CenterVertically) {
                LoadingIndicator(Modifier.size(16.dp))
                Spacer(Modifier.width(10.dp))
                Text(T.explore.checkingLibrary, style = MaterialTheme.typography.bodyMedium, color = muted)
            }
            CatalogLibrarySection.NotInLibrary -> Note(T.explore.notInLibrary, PlezyIcons.Info, muted)
            CatalogLibrarySection.SaidByStatus -> Unit
            is CatalogLibrarySection.Unchecked -> Note(section.text, PlezyIcons.CloudOff, muted)
            is CatalogLibrarySection.Copies -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(T.explore.inTheseLibraries, style = MaterialTheme.typography.titleMedium)
                RowGroup {
                    // Keyed by copy: a merge that adds or reorders copies keeps focus on the copy that had it.
                    section.copies.forEachIndexed { index, copy ->
                        key(copy.key) {
                            GroupRow(
                                copy.title,
                                onClick = { onOpen(copy) },
                                Modifier.layoutProbe("catalogDetail.copy.$index"),
                                subtitle = copy.subtitle,
                                icon = libraryIcon(copy.libraryKind),
                                trailing = { BackendLogo(copy.backend, Modifier.layoutProbe("catalogDetail.copy.$index.server", reportsFocus = false), size = 20.dp, tint = PlezyColors.MutedContent) },
                            )
                        }
                    }
                }
                section.uncheckedNote?.let { Note(it, PlezyIcons.CloudOff, muted) }
            }
        }
    }
}

@Composable
private fun Note(text: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, Modifier.size(18.dp), tint = color)
        Spacer(Modifier.width(8.dp))
        Text(text, style = MaterialTheme.typography.bodyMedium, color = color)
    }
}

/**
 * The cast as a row of round portraits with the name and the character or role under each; each one a stop for the
 * keyboard and the remote (the ring on the portrait), the row scrolling to keep it in view. A member with a person page
 * ([CatalogDetailUiState.personRoute]: a Seerr title's) is a button that opens it; the others take no press.
 */
@Composable
private fun Cast(state: CatalogDetailUiState, openPerson: (Route.SeerrPerson) -> Unit) {
    ShelfRow(
        title = state.castTitle,
        items = state.cast,
        key = { "${it.name}/${it.secondary}" },
        header = {},
        contentPadding = PaddingValues(vertical = 4.dp),
        spacing = 12.dp,
    ) { index, member ->
        val interactions = remember { MutableInteractionSource() }
        val focused by interactions.collectIsFocusedAsState()
        // Focusable for the D-pad and keys only: on a touch screen, focus handed back to the page (a sheet over it
        // closing) would land on the first card and scroll the page to it. A button is, as every clickable is.
        val keys = LocalInputModeManager.current.inputMode != InputMode.Touch
        val person = state.personRoute(index)
        Column(
            Modifier
                .width(96.dp)
                .layoutProbe("catalogDetail.cast.$index")
                .semantics(mergeDescendants = true) {}
                .then(
                    if (person != null) {
                        Modifier.clickable(interactionSource = interactions, indication = null, role = Role.Button) { openPerson(person) }
                    } else {
                        Modifier.focusable(enabled = keys, interactionSource = interactions)
                    },
                ),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            RemoteImage(
                member.imageUrl,
                contentDescription = null,
                Modifier.size(80.dp).focusRing(CircleShape, focused).clip(CircleShape),
                blank = PlezyColors.SurfaceHigh,
                error = { ArtworkPlaceholder(PlaceholderKind.PERSON) },
            )
            Spacer(Modifier.height(6.dp))
            Text(member.name, style = MaterialTheme.typography.labelLarge, maxLines = 2, overflow = TextOverflow.Ellipsis)
            member.secondary?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = PlezyColors.MutedContent, maxLines = 1, overflow = TextOverflow.Ellipsis) }
        }
    }
}

/** Franchise relations as tiles (small poster, how it relates, `title • year`), in columns as the facts are. */
@Composable
private fun Relations(relations: List<CatalogRelationEntry>, width: Dp, open: (CatalogItem) -> Unit) {
    val columns = gridColumns(width - 48.dp, relations.size)
    val tileWidth = (width - 48.dp - 12.dp * (columns - 1)) / columns
    val posterPx = with(LocalDensity.current) { 40.dp.roundToPx() }
    FlowRow(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        for (relation in relations) {
            PlezySurface(onClick = { open(relation.item) }, modifier = Modifier.width(tileWidth), shape = MaterialTheme.shapes.medium, grows = false) {
                Row(Modifier.padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    RemoteImage(
                        relation.item.posterFor(posterPx),
                        contentDescription = null,
                        Modifier.width(40.dp).height(60.dp).clip(MaterialTheme.shapes.extraSmall),
                        blank = PlezyColors.SurfaceHigh,
                        error = { ArtworkPlaceholder(placeholderKind(relation.item.kind)) },
                    )
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(relation.label, style = MaterialTheme.typography.labelSmall, color = PlezyColors.MutedContent)
                        Spacer(Modifier.height(2.dp))
                        Text(relation.text, style = MaterialTheme.typography.bodyMedium, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }
                    Icon(PlezyIcons.ChevronRight, contentDescription = null, Modifier.size(18.dp), tint = LocalContentColor.current.copy(alpha = 0.5f))
                }
            }
        }
    }
}

/** More like this: the related titles as a shelf of catalog cards. */
@Composable
private fun Related(state: CatalogDetailUiState, open: (CatalogItem) -> Unit) {
    val posterPx = with(LocalDensity.current) { 200.dp.roundToPx() }
    val items = remember(state.related) { state.related.map { it.toMediaItem() } }
    val hub = remember(items, posterPx) {
        val now = Clock.System.now()
        HubUi(
            id = "catalog-related:${state.item.source.id}:${state.item.identityKey}",
            title = T.discover.moreLikeThis,
            items = items.mapNotNull { it.toCatalogCard(now, posterPx, 0) },
            shape = CardShape.POSTER,
            icon = HubIcon.THUMB_UP,
        )
    }
    HubRow(hub, LocalAppearance.current, onCardClick = { card -> items.catalogItemOf(card.id)?.let(open) })
}
