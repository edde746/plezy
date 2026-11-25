package com.edde746.plezy.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.input.pointer.PointerIcon
import androidx.compose.ui.input.pointer.pointerHoverIcon
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.TextStyle
import androidx.compose.foundation.layout.Row
import com.edde746.plezy.presentation.browse.CardLink
import com.edde746.plezy.presentation.browse.FailedArtwork
import com.edde746.plezy.presentation.browse.primaryArtwork
import com.edde746.plezy.presentation.browse.retryArtwork
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.ui.focus.isFocusVisible
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.hideFromAccessibility
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.largeFontScale
import com.edde746.plezy.ui.focus.focusRing
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import com.edde746.plezy.ui.theme.hyphenated
import kotlin.math.roundToInt

/** Width ÷ height of a card's artwork in [this] shape. */
val CardShape.aspectRatio: Float get() = aspect.toFloat()

/**
 * An item as a card: its artwork in [shape] ([CardArtwork]: a circle for an artist), then its title on [titleLines]
 * lines (a grid's at its density: `GridLayout.titleLines`) and its caption on one more (both preformatted by the store;
 * the title and a caption's season open their detail on a click or a tap, [DetailLinkText]; the lines stay reserved
 * where the text is shorter or there is none, so the cards of a row or a grid keep one height); at a large font scale
 * ([largeFontScale]) two lines each at least. A word wider than the card breaks between syllables ([hyphenated]). In a
 * grid, pass `Modifier.fillMaxWidth()` to fill the cell.
 *
 * Focusable and clickable as one element, with the focus ring on the artwork and, on TV, its growth; focus scrolls the
 * whole card into view, the text under the artwork too. [onClick] opens it
 * (a tap, a click, Select), [onLongClick] is its menu: a long press, a held Select, a right click or the Menu key
 * ([menuGestures]). Screen readers take that element alone: named by the title, its state the caption, the progress or
 * "watched", the unwatched count and the quality labels ([cardState]), then [position] (where it sits in a grid: "Row 2
 * of 5, column 3 of 4"); the text under it is hidden from them. Without [caption] the card is the artwork alone; on TV
 * the room stays and the focused card alone shows its caption, so the row keeps its height as the focus moves.
 */
@Composable
fun PosterCard(
    item: MediaCardUi,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
    shape: CardShape = item.shape,
    onLongClick: (() -> Unit)? = null,
    width: Dp = LocalPlezyDimens.current.cardWidth(shape),
    caption: Boolean = true,
    position: String? = null,
    titleLines: Int = 1,
) {
    val dimens = LocalPlezyDimens.current
    val corner = if (item.placeholder.circular) CircleShape else MaterialTheme.shapes.medium
    val tv = dimens.focusGrows
    var focused by remember { mutableStateOf(false) }
    val state = listOfNotNull(item.cardState(), position).joinToString(", ").ifEmpty { null }
    val inView = remember { BringIntoViewRequester() }
    val scope = rememberCoroutineScope()
    Column(modifier.width(width).bringIntoViewRequester(inView).onFocusChanged { if (it.hasFocus) scope.launch { inView.bringIntoView() } }) {
        CardArtwork(
            item,
            Modifier
                .fillMaxWidth()
                .then(if (!caption && tv) Modifier.onFocusChanged { focused = it.hasFocus } else Modifier)
                .aspectRatio(shape.aspectRatio)
                .focusRing(corner)
                .clip(corner)
                .semantics {
                    contentDescription = item.title
                    if (state != null) stateDescription = state
                }
                .then(if (onLongClick != null) Modifier.menuGestures(onLongClick) else Modifier)
                .overlayOpener()
                .then(
                    if (onClick != null) {
                        Modifier.combinedClickable(role = Role.Button, onLongClick = onLongClick, onClick = onClick)
                    } else {
                        Modifier.focusable()
                    },
                ),
            corner,
        )
        if (!caption && !tv) return@Column
        // On TV the focused artwork grows over the gap: the caption stays clear of it.
        Spacer(Modifier.height(if (tv) 10.dp else 6.dp))
        val lines = if (largeFontScale()) 2 else 1
        // A TV card without its caption keeps the room, shown while focused.
        val shown = Modifier.semantics { hideFromAccessibility() }.alpha(if (caption || focused) 1f else 0f)
        DetailLinkText(
            item.title,
            item.titleLink,
            MaterialTheme.typography.titleSmall.contentDirection().hyphenated(),
            LocalContentColor.current,
            shown,
            maxOf(lines, titleLines),
        )
        LinkedLine(item.caption.orEmpty(), item.captionLink, MaterialTheme.typography.bodySmall.hyphenated(), PlezyColors.TextMuted, shown, lines)
    }
}

/**
 * An item's artwork in [modifier]'s bounds, clipped to [shape]: the image over the raised fill while it loads, its
 * fallback once it fails, blurred while a spoiler, its placeholder when there is none ([ArtworkPlaceholder]); over it its quality labels (or a catalog title's availability) down the
 * top start corner, the watched check or the unwatched count at the top end, and the watch progress along the foot
 * ([ArtworkProgress]); an artist has neither check, count nor progress.
 */
@Composable
fun CardArtwork(item: MediaCardUi, modifier: Modifier, shape: Shape = MaterialTheme.shapes.medium) {
    val fill = PlezyColors.SurfaceHigh
    Box(modifier.clip(shape).background(fill)) {
        val primary = item.primaryArtwork
        val retry = item.retryArtwork
        RemoteImage(
            artwork = primary,
            contentDescription = null,
            modifier = Modifier.matchParentSize(),
            blank = fill,
            fallbackArtwork = retry,
            blurred = item.blurred,
            // A primary that failed is remembered, so the next card of it starts on the fallback.
            onResult = { tried, loaded -> if (!loaded && retry != null && tried == primary) FailedArtwork.remember(tried) },
            error = { ArtworkPlaceholder(item.placeholder) },
        )
        if (item.qualityLabels.isNotEmpty()) {
            PosterBadges(item.qualityLabels, item.badgeShortForms, Modifier.align(Alignment.TopStart).padding(6.dp).clearAndSetSemantics {})
        }
        if (item.placeholder.circular) return@Box
        val count = item.unwatchedLabel
        when {
            item.watched -> Icon(
                PlezyIcons.CheckCircle,
                contentDescription = null,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(6.dp)
                    .size(22.dp)
                    .background(Color.Black.copy(alpha = 0.55f), CircleShape),
                tint = Color.White,
            )
            count != null -> Badge(count, Modifier.align(Alignment.TopEnd).padding(6.dp).clearAndSetSemantics {}, emphasised = true)
        }
        item.progress?.let { ArtworkProgress(it.toFloat(), Modifier.matchParentSize()) }
    }
}

/**
 * How much of an item is watched, over its artwork (a poster, a thumbnail; place it with `matchParentSize()`): a
 * rounded bar 4 dp high (TV 6) inset 8 dp from the left, right and bottom edges (TV 10), white on a 30 % white
 * track, filled from its leading edge (right to left in Arabic), over a scrim darkening the lowest 30 % of the artwork
 * from 60 % black at the bottom edge to none, so the bar reads on light artwork too.
 */
@Composable
fun ArtworkProgress(progress: Float, modifier: Modifier = Modifier) {
    val watched = progress.coerceIn(0f, 1f)
    val tv = LocalPlezyDimens.current.focusGrows
    val barHeight = if (tv) 6.dp else 4.dp
    val inset = if (tv) 10.dp else 8.dp
    Spacer(
        modifier.drawBehind {
            val scrimTop = size.height * 0.7f
            drawRect(
                Brush.verticalGradient(listOf(Color.Transparent, PlezyColors.ArtworkScrim), startY = scrimTop, endY = size.height),
                topLeft = Offset(0f, scrimTop),
                size = Size(size.width, size.height - scrimTop),
            )
            val bar = barHeight.toPx()
            val track = Size((size.width - inset.toPx() * 2).coerceAtLeast(0f), bar)
            val origin = Offset(inset.toPx(), size.height - inset.toPx() - bar)
            val radius = CornerRadius(bar / 2)
            drawRoundRect(PlezyColors.ArtworkProgressTrack, origin, track, radius)
            // A started item shows at least a round dot.
            if (watched > 0f) {
                val fill = minOf(maxOf(track.width * watched, bar), track.width)
                val start = if (layoutDirection == LayoutDirection.Rtl) origin.x + track.width - fill else origin.x
                drawRoundRect(PlezyColors.ArtworkProgressFill, Offset(start, origin.y), Size(fill, bar), radius)
            }
        },
    )
}

/**
 * A blank card the size of a [PosterCard] of [shape] with its two caption lines, in the raised fill: a place for an
 * item still on its way (a shelf loading, a page of a grid not yet fetched). Each line keeps a text line's room in
 * its style ([BlankLine]), so the cards that take its place are as tall. Takes no focus.
 */
@Composable
fun BlankCard(shape: CardShape, modifier: Modifier = Modifier, width: Dp = LocalPlezyDimens.current.cardWidth(shape)) {
    val fill = PlezyColors.SurfaceHigh
    val tv = LocalPlezyDimens.current.focusGrows
    val lines = if (largeFontScale()) 2 else 1
    Column(modifier.width(width)) {
        Box(Modifier.fillMaxWidth().aspectRatio(shape.aspectRatio).background(fill, MaterialTheme.shapes.medium))
        Spacer(Modifier.height(if (tv) 10.dp else 6.dp))
        BlankLine(MaterialTheme.typography.titleSmall, lines, 0.7f, 12.dp)
        BlankLine(MaterialTheme.typography.bodySmall, lines, 0.4f, 10.dp)
    }
}

/** [lines] lines of text in [style], as much room as a card's line of it takes, with a bar of [fraction] its width. */
@Composable
private fun BlankLine(style: TextStyle, lines: Int, fraction: Float, bar: Dp) {
    Box(contentAlignment = Alignment.CenterStart) {
        Text("", style = style, minLines = lines, modifier = Modifier.fillMaxWidth().semantics { hideFromAccessibility() })
        Box(Modifier.fillMaxWidth(fraction).height(bar).background(PlezyColors.SurfaceHigh, MaterialTheme.shapes.extraSmall))
    }
}

/**
 * The card's state as a screen reader says it after its title: its caption, how much is watched (or "watched"), the
 * unwatched count and the quality labels; null when there is none of these.
 */
internal fun MediaCardUi.cardState(): String? {
    val progress = progress
    val parts = buildList {
        caption?.let(::add)
        when {
            progress != null -> add(T.accessibility.mediaCardPartiallyWatched(percent = (progress * 100).roundToInt().toString()))
            watched -> add(T.accessibility.mediaCardWatched)
        }
        unwatchedLabel?.let(::add)
        addAll(qualityLabels)
    }
    return parts.takeIf { it.isNotEmpty() }?.joinToString(", ")
}

/**
 * Opens a route: what a card's title and season links do ([MediaCardUi.titleLink], [MediaCardUi.captionLink]), the
 * app's navigator. Without one the links are plain text.
 */
val LocalOpenRoute = staticCompositionLocalOf<((Route) -> Unit)?> { null }

/**
 * [text] in at most [maxLines] lines (as many reserved) that opens [route]'s detail on a click or a tap ([LocalOpenRoute]):
 * the hand pointer and an underline on hover, announced as "View details". Under a keyboard or a remote (or without a
 * route) plain text: the card itself is what takes focus.
 */
@Composable
internal fun DetailLinkText(text: String, route: Route?, style: TextStyle, color: Color, modifier: Modifier = Modifier, maxLines: Int = 1, minLines: Int = maxLines) {
    val open = LocalOpenRoute.current
    if (route == null || open == null || isFocusVisible()) {
        Text(text, modifier, color = color, style = style, maxLines = maxLines, minLines = minLines, overflow = TextOverflow.Ellipsis)
        return
    }
    val hover = remember { MutableInteractionSource() }
    val hovered by hover.collectIsHoveredAsState()
    Text(
        text,
        modifier
            .pointerHoverIcon(PointerIcon.Hand)
            .focusProperties { canFocus = false }
            .clickable(hover, indication = null, onClickLabel = T.mediaMenu.viewDetails) { open(route) },
        color = color,
        style = if (hovered) style.copy(textDecoration = TextDecoration.Underline) else style,
        maxLines = maxLines,
        minLines = minLines,
        overflow = TextOverflow.Ellipsis,
    )
}

/** [text] in [maxLines] lines, its leading [CardLink.prefix] a [DetailLinkText] when [link] has one ("S2" of "S2 E5 · Title"). */
@Composable
internal fun LinkedLine(text: String, link: CardLink?, style: TextStyle, color: Color, modifier: Modifier = Modifier, maxLines: Int = 1, minLines: Int = maxLines) {
    if (link == null || !text.startsWith(link.prefix)) {
        Text(text, modifier, style = style, color = color, maxLines = maxLines, minLines = minLines, overflow = TextOverflow.Ellipsis)
        return
    }
    Row(modifier) {
        DetailLinkText(link.prefix, link.route, style, color, maxLines = 1, minLines = 1)
        Text(text.removePrefix(link.prefix), style = style, color = color, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}
