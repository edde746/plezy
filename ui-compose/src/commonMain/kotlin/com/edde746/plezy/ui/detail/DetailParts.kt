package com.edde746.plezy.ui.detail

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.ui.graphics.Shape
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.material3.Icon
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.ui.components.DownloadMark
import com.edde746.plezy.ui.components.icon
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.browse.MenuExtra
import com.edde746.plezy.presentation.browse.MenuIcon
import com.edde746.plezy.presentation.browse.RowAction
import com.edde746.plezy.presentation.detail.CastUi
import com.edde746.plezy.presentation.detail.DetailActionsUi
import com.edde746.plezy.presentation.detail.DetailHeroUi
import com.edde746.plezy.presentation.detail.EpisodeDownloadUi
import com.edde746.plezy.presentation.detail.EpisodeRowUi
import com.edde746.plezy.presentation.detail.InfoRowUi
import com.edde746.plezy.presentation.detail.MediaDetailStore
import com.edde746.plezy.presentation.detail.MediaDetailUiState
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.presentation.ratings.GenericRatingIcon
import com.edde746.plezy.presentation.ratings.inlineRatingBadges
import com.edde746.plezy.presentation.ratings.ratingsSemanticLabel
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.WidthClass
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.ItemMenuSection
import com.edde746.plezy.ui.components.SectionedItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.LabelAutoSize
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.PosterCard
import com.edde746.plezy.ui.components.ShelfRow
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.components.overlayOpener
import com.edde746.plezy.ui.downloads.DetailDownloadButton
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.focusRing
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.icons.watchedIcon
import com.edde746.plezy.ui.image.LogoRecolour
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.menu.anchorsMenus
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.ratings.RatingGlyphs
import com.edde746.plezy.ui.ratings.RatingLogo
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import com.edde746.plezy.ui.trackers.DetailWatchlistButton

/**
 * The item's clear logo (else its name) at the bottom of [box], centred or from the start ([centred]): the logo
 * aspect-fit in the box, the name in the page's headline size on as many lines as it takes, growing the box downwards
 * when taller. A logo that fails to load gives its place to the name. An episode's own title follows on a line of its
 * own. [titleModifier] goes to the logo's or the name's box. Harness names `detail.title`, `detail.logo`.
 */
@Composable
internal fun TitleArt(hero: DetailHeroUi, centred: Boolean, box: DpSize, titleModifier: Modifier = Modifier) {
    val layout = LocalWindowLayout.current
    val style = when {
        LocalAppearance.current.tv -> MaterialTheme.typography.headlineLarge
        layout.widthClass == WidthClass.COMPACT -> MaterialTheme.typography.headlineMedium
        else -> MaterialTheme.typography.displaySmall
    }.copy(textAlign = if (centred) TextAlign.Center else TextAlign.Start).contentDirection()
    val alignment = if (centred) Alignment.BottomCenter else Alignment.BottomStart
    val name = @Composable { Text(hero.title, style = style) }
    Column(horizontalAlignment = if (centred) Alignment.CenterHorizontally else Alignment.Start) {
        Box(
            titleModifier.fillMaxWidth().then(if (hero.logo != null) Modifier.heightIn(min = box.height) else Modifier).layoutProbe("detail.title"),
            contentAlignment = alignment,
        ) {
            val logo = hero.logo
            if (logo == null) {
                name()
            } else {
                RemoteImage(
                    logo,
                    contentDescription = hero.title,
                    modifier = Modifier.widthIn(max = box.width).fillMaxWidth().height(box.height).layoutProbe("detail.logo"),
                    contentScale = ContentScale.Fit,
                    alignment = alignment,
                    error = { Box(Modifier.fillMaxWidth(), contentAlignment = alignment) { name() } },
                    logo = LogoRecolour.TITLE,
                )
            }
        }
        hero.episodeTitle?.let {
            Text(
                it,
                Modifier.padding(top = 6.dp),
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold, textAlign = if (centred) TextAlign.Center else TextAlign.Start),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

/** The metadata line: "S1 E4", the date or year, certification, duration, the edition, the quality labels and the genres. Harness name `detail.infoLine`. */
@Composable
internal fun MetaLine(hero: DetailHeroUi, centred: Boolean, modifier: Modifier = Modifier, maxLines: Int = Int.MAX_VALUE) {
    val parts = hero.metadata + listOfNotNull(hero.edition) + hero.qualityLabels + hero.genres.take(MAX_GENRES)
    if (parts.isEmpty()) return
    Text(
        parts.joinToString(META_SEPARATOR),
        modifier.layoutProbe("detail.infoLine"),
        style = MaterialTheme.typography.bodyLarge,
        color = PlezyColors.TextMuted,
        textAlign = if (centred) TextAlign.Center else TextAlign.Start,
        maxLines = maxLines,
        overflow = TextOverflow.Ellipsis,
    )
}

private const val META_SEPARATOR = " · "
private const val MAX_GENRES = 3

/**
 * The ratings row under the metadata line: each score after its source's mark (a star, people for an audience score,
 * without one), drawn plain in the store's order, wrapping onto more lines where the window is too narrow for one;
 * one element for screen readers. Harness name `ratings.strip`.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun RatingsRow(hero: DetailHeroUi, centred: Boolean, tv: Boolean = false) {
    val badges = remember(hero.ratings) { inlineRatingBadges(hero.ratings) }
    if (badges.isEmpty()) return
    val text = if (tv) {
        MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold)
    } else {
        MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold)
    }
    val mark = if (tv) 20.dp else 16.dp
    val label = remember(hero.ratings) { ratingsSemanticLabel(hero.ratings) }
    Box(Modifier.fillMaxWidth(), contentAlignment = if (centred) Alignment.Center else Alignment.CenterStart) {
        FlowRow(
            Modifier.layoutProbe("ratings.strip", reportsFocus = false).clearAndSetSemantics { contentDescription = label },
            horizontalArrangement = Arrangement.spacedBy(if (tv) 24.dp else 16.dp, if (centred) Alignment.CenterHorizontally else Alignment.Start),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) {
            for (badge in badges) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    val icon = badge.icon
                    if (icon != null) {
                        RatingLogo(icon, Modifier.size(mark * icon.aspect.toFloat(), mark), tint = PlezyColors.Text)
                    } else {
                        Icon(if (badge.generic == GenericRatingIcon.PEOPLE) RatingGlyphs.People else PlezyIcons.Star, null, Modifier.size(mark), tint = PlezyColors.Text)
                    }
                    Text(badge.value, style = text, color = PlezyColors.Text, maxLines = 1)
                }
            }
        }
    }
}

/**
 * Play: the primary pill, the play symbol and the store's label ("S1E4"), else Play or Resume; a long press plays from
 * the start where it resumes. Not pressable until the item's episodes have loaded. [LocalPlezyDimens]' `controlHeight`
 * tall (an [ActionRow][com.edde746.plezy.ui.components.ActionRow]'s height in one), in [shape] (the start of a split
 * capsule beside its chevron). Harness name `detail.play`.
 */
@Composable
internal fun PlayButton(actions: DetailActionsUi, store: MediaDetailStore, modifier: Modifier = Modifier, shape: Shape = CircleShape) {
    val size = LocalPlezyDimens.current.controlHeight
    val label = actions.playLabel ?: if (actions.resume) T.common.resume else T.common.play
    PlezySurface(
        onClick = store::play,
        onLongClick = if (actions.resume) store::playFromStart else null,
        onLongClickLabel = if (actions.resume) T.mediaMenu.playFromBeginning else null,
        modifier = modifier.height(size).widthIn(min = PlayMinWidth).layoutProbe("detail.play"),
        shape = shape,
        color = PlezyColors.Primary,
        contentColor = PlezyColors.OnPrimary,
        enabled = actions.playEnabled,
        contentAlignment = Alignment.Center,
        hitTarget = true,
    ) {
        Row(Modifier.padding(horizontal = 20.dp), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(PlezyIcons.PlayArrow, contentDescription = null, Modifier.size(size * 0.5f))
            Text(label, style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold), maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

/** Play is at least this wide. */
internal val PlayMinWidth = 120.dp

/**
 * Play ([PlayButton]) with its chevron ([VersionsButton]) where it has one: one split capsule, Play its start and the
 * narrower chevron its end, a hairline between them, both the row's height; the chevron keeps its room where the label
 * is cut short. Focus keys `play` and `versions` in [focus].
 */
@Composable
internal fun PlaySplitButton(actions: DetailActionsUi, store: MediaDetailStore, focus: FocusMemory) {
    if (!actions.hasVersionMenu) {
        PlayButton(actions, store, Modifier.rememberFocus(focus, PLAY_KEY))
        return
    }
    Row(verticalAlignment = Alignment.CenterVertically) {
        PlayButton(actions, store, Modifier.weight(1f, fill = false).rememberFocus(focus, PLAY_KEY), SplitStart)
        VersionsButton(actions, store, Modifier.rememberFocus(focus, "versions"))
    }
}

/** The start and the end of Play's split capsule ([PlaySplitButton]). */
private val SplitStart = RoundedCornerShape(topStartPercent = 50, bottomStartPercent = 50)
private val SplitEnd = RoundedCornerShape(topEndPercent = 50, bottomEndPercent = 50)

/**
 * Play's chevron, the end of Play's split capsule ([PlaySplitButton]), narrower than the row's circles, a hairline at
 * its start: a menu of the item's versions where it has several, the one Play plays
 * checked, then where the server transcodes the Quality submenu, the quality Play plays at checked (with one version,
 * its qualities are the menu); a pick plays it. Shown where [DetailActionsUi.versions] or [DetailActionsUi.qualities]
 * has entries ([hasVersionMenu]). Harness names `detail.versions`, `detail.version.<i>`, `detail.version.quality`,
 * `detail.version.quality.<i>`.
 */
@Composable
internal fun VersionsButton(actions: DetailActionsUi, store: MediaDetailStore, modifier: Modifier = Modifier) {
    var open by remember { mutableStateOf(false) }
    val size = LocalPlezyDimens.current.controlHeight
    Box {
        PlezySurface(
            onClick = { open = true },
            modifier = modifier.height(size).width(size * 0.8f).layoutProbe("detail.versions"),
            shape = SplitEnd,
            color = PlezyColors.Primary,
            contentColor = PlezyColors.OnPrimary,
            enabled = actions.playEnabled,
            contentAlignment = Alignment.Center,
            hitTarget = true,
        ) {
            Box(Modifier.align(Alignment.CenterStart).width(1.dp).fillMaxHeight(0.5f).background(LocalContentColor.current.copy(alpha = 0.3f)))
            Icon(PlezyIcons.KeyboardArrowDown, contentDescription = T.mediaMenu.playVersion, Modifier.size(size * 0.5f))
        }
        val versions = actions.versions.mapIndexed { index, name ->
            ItemMenuEntry(name, selected = index == actions.version, contentLabel = true) { store.playVersion(index) }
        }
        val qualities = actions.qualities.mapIndexed { index, name -> ItemMenuEntry(name, selected = index == actions.quality) { store.playQuality(index) } }
        val quality = ItemMenuEntry(T.videoControls.qualityColumnHeader, probe = "quality", icon = PlezyIcons.Tune, children = qualities)
        SectionedItemMenu(
            expanded = open,
            onDismiss = { open = false },
            // With one version, its qualities are the menu.
            sections = if (versions.isEmpty()) {
                listOf(ItemMenuSection(null, qualities))
            } else {
                listOfNotNull(ItemMenuSection(null, versions), ItemMenuSection(null, listOf(quality)).takeIf { qualities.isNotEmpty() })
            },
            probe = "detail.version",
            title = T.mediaMenu.playVersion,
        )
    }
}

/** Whether Play has its chevron ([VersionsButton]). */
internal val DetailActionsUi.hasVersionMenu: Boolean
    get() = versions.isNotEmpty() || qualities.isNotEmpty()

/** The action row's optional buttons, in the row's order; [row] the same button as the ⋮ menu knows it. */
internal enum class DetailAction(val row: RowAction) {
    TRAILER(RowAction.TRAILER),
    SHUFFLE(RowAction.SHUFFLE),
    DOWNLOAD(RowAction.DOWNLOAD),
    WATCHED(RowAction.WATCHED),
    WATCHLIST(RowAction.WATCHLIST),
}

/** The buttons a row of [shown] shows with Play's chevron where it has one: the ⋮ menu leaves their entries out. */
internal fun DetailActionsUi.onRow(shown: List<DetailAction>): Set<RowAction> =
    shown.mapTo(mutableSetOf()) { it.row }.apply { if (hasVersionMenu) add(RowAction.VERSIONS) }

/** The buttons the item offers ([DetailAction]s), in the row's order. */
@Composable
internal fun offeredActions(state: MediaDetailUiState, intents: DetailIntents): List<DetailAction> {
    val actions = state.actions
    val watchlist = intents.watchlist?.let { it.state.collectAsState().value != null } == true
    return buildList {
        if (actions.trailer) add(DetailAction.TRAILER)
        if (actions.shuffle) add(DetailAction.SHUFFLE)
        if (state.download != null) add(DetailAction.DOWNLOAD)
        if (actions.canMarkWatched) add(DetailAction.WATCHED)
        if (watchlist) add(DetailAction.WATCHLIST)
    }
}

/**
 * The buttons that fit [slots] round buttons beside Play (⋮ taking one where the item has its menu, [more]): the
 * watched toggle stays longest, then Shuffle, then the download, then the trailer and the watchlist, each still in ⋮'s
 * menu (online) once shed; in the row's order.
 */
internal fun fitActions(offered: List<DetailAction>, slots: Int, more: Boolean): List<DetailAction> {
    val room = (slots - if (more) 1 else 0).coerceAtLeast(0)
    val kept = KeepOrder.filter { it in offered }.take(room).toSet()
    return offered.filter { it in kept }
}

/** Which buttons stay longest as the row runs out of room. */
private val KeepOrder = listOf(DetailAction.WATCHED, DetailAction.SHUFFLE, DetailAction.DOWNLOAD, DetailAction.TRAILER, DetailAction.WATCHLIST)

/** One of the action row's round buttons over the picture. Harness names `detail.<trailer|shuffle|download|watched|watchlist>`. */
@Composable
internal fun ActionButton(action: DetailAction, state: MediaDetailUiState, intents: DetailIntents, modifier: Modifier = Modifier) {
    val store = intents.store
    when (action) {
        DetailAction.TRAILER ->
            PlezyIconButton(PlezyIcons.Trailer, T.tooltips.playTrailer, store::playTrailer, modifier.layoutProbe("detail.trailer"), style = IconButtonStyle.OVER_PICTURE)
        DetailAction.SHUFFLE ->
            PlezyIconButton(PlezyIcons.Shuffle, T.tooltips.shufflePlay, store::shuffle, modifier.layoutProbe("detail.shuffle"), style = IconButtonStyle.OVER_PICTURE)
        DetailAction.DOWNLOAD -> state.download?.let { DetailDownloadButton(it, store::pressDownload, modifier.anchorsMenus().layoutProbe("detail.download"), overPicture = true) }
        DetailAction.WATCHED -> PlezyIconButton(
            if (state.actions.watched) PlezyIcons.CheckCircle else watchedIcon(watched = false),
            if (state.actions.watched) T.tooltips.markAsUnwatched else T.tooltips.markAsWatched,
            store::toggleWatched,
            modifier.layoutProbe("detail.watched"),
            style = IconButtonStyle.OVER_PICTURE,
            selected = state.actions.watched,
        )
        DetailAction.WATCHLIST -> intents.watchlist?.let { DetailWatchlistButton(it, modifier) }
    }
}

/** ⋮: the item's media menu (online only), without the entries of the buttons the row shows ([onRow]). Harness name `detail.more`. */
@Composable
internal fun MoreButton(intents: DetailIntents, onRow: Set<RowAction>, modifier: Modifier = Modifier) {
    PlezyIconButton(PlezyIcons.MoreVert, T.common.options, { intents.openMenu(onRow) }, modifier.overlayOpener().layoutProbe("detail.more"), style = IconButtonStyle.OVER_PICTURE)
}

/**
 * The overview: three lines, then More opens the rest (Less closes it again); More and Less take focus, Up from them
 * going to Play ([up]) and Left and Right staying. Text that fits is plain text and takes no focus. Harness name of the
 * toggle `detail.overviewMore`.
 */
@Composable
internal fun Overview(text: String, focus: FocusMemory, up: FocusRequester?, modifier: Modifier = Modifier, lines: Int = 3) {
    var expanded by rememberSaveable(text) { mutableStateOf(false) }
    var overflows by remember(text) { mutableStateOf(false) }
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(
            text,
            style = MaterialTheme.typography.bodyMedium.contentDirection(),
            color = PlezyColors.TextMuted,
            maxLines = if (expanded) Int.MAX_VALUE else lines,
            overflow = TextOverflow.Ellipsis,
            onTextLayout = { if (!expanded) overflows = it.hasVisualOverflow },
        )
        if (overflows || expanded) {
            PlezySurface(
                onClick = { expanded = !expanded },
                modifier = Modifier
                    .offset(x = (-8).dp)
                    .rememberFocus(focus, OVERVIEW_KEY)
                    .focusProperties {
                        if (up != null) this.up = up
                        left = FocusRequester.Cancel
                        right = FocusRequester.Cancel
                    }
                    .layoutProbe("detail.overviewMore"),
                shape = MaterialTheme.shapes.small,
                // On TV a tonal pill at rest, as every text button there.
                color = if (LocalPlezyDimens.current.focusGrows) PlezyColors.TonalRest else Color.Transparent,
                hitTarget = true,
                grows = false,
            ) {
                Text(
                    if (expanded) T.discover.less else T.discover.more,
                    style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                )
            }
        }
    }
}

private const val OVERVIEW_KEY = "overview"

/**
 * The information block: studio, directors and rating, each its label over its value. One focus stop (a keyboard or a
 * D-pad reaches it, the page scrolling to it), its ring [StopInset] off its lines and outside the column, so its words
 * line up with the headings above; Up leaves it for the section above,
 * and the other keys stay. Not a stop at all without [focusStop] (a person's facts above their titles, which Up from
 * the titles passes). Harness name `detail.info`.
 */
@Composable
internal fun Information(rows: List<InfoRowUi>, modifier: Modifier = Modifier, focusStop: Boolean = true) {
    if (rows.isEmpty()) return
    val shape = RoundedCornerShape(12.dp)
    val stop = if (focusStop) {
        Modifier
            .focusRing(shape)
            .focusProperties {
                down = FocusRequester.Cancel
                left = FocusRequester.Cancel
                right = FocusRequester.Cancel
            }
            .focusable()
    } else {
        Modifier
    }
    Column(
        modifier.layoutProbe("detail.info", reportsFocus = focusStop)
            .then(if (focusStop) Modifier.bleed(StopInsetSide).then(stop).padding(StopInset) else Modifier.padding(vertical = 4.dp)),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        for (row in rows) {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(row.label, style = MaterialTheme.typography.labelLarge, color = PlezyColors.TextMuted)
                Text(row.value, style = MaterialTheme.typography.bodyMedium.contentDirection())
            }
        }
    }
}

/** The room between a block of text that is a focus stop of its own and its lines: its ring's inset. */
private val StopInsetSide = 12.dp
private val StopInset = PaddingValues(horizontal = StopInsetSide, vertical = 8.dp)

/**
 * Cast as a row of round portraits ([ShelfRow]): each opens the actor's titles ([MediaDetailStore.castRoute]); Left and
 * Right move along the row, scrolling it, Up and Down leave it. Harness names `detail.cast.<i>`.
 */
@Composable
internal fun CastShelf(cast: List<CastUi>, focus: FocusMemory, intents: DetailIntents, modifier: Modifier = Modifier) {
    if (cast.isEmpty()) return
    val width = LocalPlezyDimens.current.cardWidth(CardShape.POSTER) * 0.8f
    ShelfRow(T.discover.cast, cast.indices.toList(), key = { it }, modifier = modifier.layoutProbe("detail.cast", reportsFocus = false)) { _, index ->
        val member = cast[index]
        val target = intents.store.castRoute(index)
        PersonCard(member, width, target?.let { { intents.navigate(it) } }, Modifier.rememberFocus(focus, "cast/$index").layoutProbe("detail.cast.$index"))
    }
}

/**
 * A cast member [width] wide: a round portrait (the person icon without one), the name and the character. A name's
 * word too wide for the card (a large font) shrinks the name until each word fits a line whole.
 */
@Composable
internal fun PersonCard(cast: CastUi, width: Dp, onClick: (() -> Unit)?, modifier: Modifier = Modifier) {
    Column(modifier.width(width), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier
                .size(width)
                .focusRing(CircleShape)
                .clearAndSetSemantics {
                    contentDescription = listOfNotNull(cast.name, cast.role).joinToString(", ")
                    role = Role.Button
                }
                .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, enabled = onClick != null) { onClick?.invoke() },
        ) {
            PersonPhoto(cast.image, Modifier.matchParentSize())
        }
        // Its line height in ems, so the lines stay together as the name shrinks.
        val name = MaterialTheme.typography.titleSmall.let { it.copy(lineHeight = (it.lineHeight.value / it.fontSize.value).em) }
        Text(
            cast.name,
            Modifier.padding(top = 6.dp),
            style = name,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
            autoSize = LabelAutoSize(name.fontSize, byWord = true),
        )
        cast.role?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, maxLines = 1, overflow = TextOverflow.Ellipsis, textAlign = TextAlign.Center) }
    }
}

/** A person's photo filling [modifier]'s bounds in a circle, the person placeholder while there is none. */
@Composable
internal fun PersonPhoto(artwork: Artwork?, modifier: Modifier) {
    RemoteImage(
        artwork,
        contentDescription = null,
        modifier = modifier.clip(CircleShape),
        blank = PlezyColors.SurfaceHigh,
        error = { ArtworkPlaceholder(PlaceholderKind.PERSON) },
    )
}

/**
 * Trailers and extras as a row of wide cards: a card plays its extra; its menu (a long press, a right click, the Menu
 * key) is the extra's media menu. Harness names `detail.extra.<i>`.
 */
@Composable
internal fun ExtrasShelf(extras: List<MediaCardUi>, focus: FocusMemory, intents: DetailIntents, modifier: Modifier = Modifier) {
    if (extras.isEmpty()) return
    ShelfRow(T.discover.extras, extras, key = { it.id }, modifier = modifier.layoutProbe("detail.extras", reportsFocus = false)) { index, card ->
        PosterCard(
            card,
            onClick = { intents.store.playExtra(card.id) },
            modifier = Modifier.rememberFocus(focus, "extra/${card.id}").layoutProbe("detail.extra.$index"),
            shape = CardShape.WIDE,
            onLongClick = { intents.openExtraMenu(card.id) },
        )
    }
}

/**
 * An episode row of the detail's list ([EpisodeListRow]): its thumbnail (progress, a check once watched, blurred while
 * a spoiler), "4. Title", the metadata line, its download's state and two lines of summary, then its ⋮. A click plays
 * it; its menu (a long press, a right click, the Menu key, its ⋮) is the episode's media menu, offline too. The on-deck
 * episode keeps a faint tint. Harness names `detail.episode.<id>` with its `.menu`.
 */
@Composable
internal fun EpisodeRow(row: EpisodeRowUi, focus: FocusMemory, intents: DetailIntents, thumbnailWidth: Dp, modifier: Modifier = Modifier) {
    val probe = "detail.episode.${row.id}"
    val openMenu = { intents.openEpisodeMenu(row.id) }
    EpisodeListRow(
        title = row.title,
        // Up to two lines, broken only between facts (no-break spaces inside each, and before its dot), so no fact is
        // cut short or split: its audio and size read whole on a phone.
        infoLine = row.metadata.joinToString("\u00A0· ") { it.replace(' ', '\u00A0') }.ifEmpty { null },
        infoLines = 2,
        overview = row.summary,
        onClick = { intents.store.playEpisode(row.id) },
        modifier = modifier
            .rememberFocus(focus, episodeFocusKey(row.id))
            .menuGestures(openMenu)
            .layoutProbe(probe),
        highlighted = row.onDeck,
        onLongClick = openMenu,
        trailing = {
            PlezyIconButton(PlezyIcons.MoreVert, T.common.options, openMenu, Modifier.overlayOpener().layoutProbe("$probe.menu"), style = IconButtonStyle.PLAIN, size = 32.dp)
        },
        badge = { row.download?.let { EpisodeDownloadMark(it) } },
    ) {
        EpisodeThumbnail(row.thumb, row.blurThumb, Modifier.width(thumbnailWidth), watched = row.watched, progress = row.progress?.toFloat())
    }
}

/** The focus key of the episode row or card [episodeId]. */
internal fun episodeFocusKey(episodeId: String): String = "episode:$episodeId"

/** An episode's download: a small spinner while it is being queued, else its muted status icon; both name its state. */
@Composable
internal fun EpisodeDownloadMark(download: EpisodeDownloadUi) {
    val label = download.label
    if (download.queueing) {
        CircularProgressIndicator(Modifier.size(12.dp).semantics { label?.let { contentDescription = it } }, color = PlezyColors.TextMuted, strokeWidth = 1.5.dp)
        return
    }
    val status = download.status ?: return
    val downloading = status == DownloadedMediaStatus.DOWNLOADING
    CompositionLocalProvider(LocalContentColor provides if (status == DownloadedMediaStatus.FAILED) PlezyColors.Error else PlezyColors.TextMuted) {
        DownloadMark(status.icon, download.progress.takeIf { downloading }, size = 16.dp, contentDescription = label)
    }
}

/** The episodes' state while they aren't rows: a spinner, the error with Retry, or the empty text. */
@Composable
internal fun EpisodesState(state: MediaDetailUiState, intents: DetailIntents, modifier: Modifier = Modifier) {
    val episodes = state.episodes ?: return
    val store = intents.store
    val seasonsFailed = state.seasonsLoad == SectionLoad.ERROR
    when (episodes.load) {
        SectionLoad.LOADING -> SectionSpinner(modifier)
        SectionLoad.ERROR -> SectionRetry(
            if (seasonsFailed) T.messages.seasonsLoadFailed else T.messages.episodesLoadFailed,
            if (seasonsFailed) store::retrySeasons else store::retryEpisodes,
            modifier,
        )
        SectionLoad.EMPTY -> Text(
            if (state.seasonsLoad == SectionLoad.EMPTY) T.messages.noSeasonsFound else T.messages.noEpisodesFoundGeneral,
            modifier.fillMaxWidth().padding(vertical = 32.dp),
            color = PlezyColors.TextMuted,
            textAlign = TextAlign.Center,
        )
        SectionLoad.CONTENT -> Unit
    }
}

/** The episode list's tail: the next page loads as it comes into view (its spinner), or Retry after a failed page. */
@Composable
internal fun EpisodesTail(state: MediaDetailUiState, intents: DetailIntents, modifier: Modifier = Modifier) {
    val episodes = state.episodes ?: return
    when {
        episodes.moreFailed -> SectionRetry(T.messages.episodesLoadFailed, intents.store::retryEpisodes, modifier)
        episodes.hasMore -> {
            LaunchedEffect(episodes.rows.size) { intents.store.loadMoreEpisodes() }
            SectionSpinner(modifier)
        }
    }
}

@Composable
internal fun SectionSpinner(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().padding(24.dp), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(Modifier.size(32.dp))
    }
}

/** A section that failed: [message] and Retry ([onRetry]). */
@Composable
internal fun SectionRetry(message: String, onRetry: () -> Unit, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth().padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(message, color = PlezyColors.TextMuted, textAlign = TextAlign.Center)
        PlezyButton(T.common.retry, onRetry, icon = PlezyIcons.Refresh)
    }
}

/**
 * The detail's own entry at the top of its item's menu: Play from beginning for a show's or season's Play target (a
 * movie's or episode's is in the menu already). Harness name `menu.detail_play_from_beginning`.
 */
internal fun detailMenuExtras(store: MediaDetailStore, item: MediaItem): List<MenuExtra> {
    val actions = store.state.value.actions
    val playable = item.kind == MediaKind.MOVIE || item.kind == MediaKind.EPISODE
    return buildList {
        if (actions.resume && !playable) {
            add(MenuExtra("detail_play_from_beginning", T.mediaMenu.playFromBeginning, MenuIcon.REPLAY, leading = true) { store.playFromStart() })
        }
    }
}
