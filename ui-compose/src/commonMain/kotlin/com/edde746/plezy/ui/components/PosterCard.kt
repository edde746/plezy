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
import androidx.compose.ui.focus.FocusEventModifierNode
import androidx.compose.ui.focus.FocusState
import androidx.compose.ui.relocation.bringIntoView
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
import androidx.compose.ui.graphics.drawscope.ContentDrawScope
import androidx.compose.ui.layout.Measurable
import androidx.compose.ui.layout.MeasureResult
import androidx.compose.ui.layout.MeasureScope
import androidx.compose.ui.node.DrawModifierNode
import androidx.compose.ui.node.LayoutModifierNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.invalidateDraw
import androidx.compose.ui.node.invalidateMeasurement
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.constrainHeight
import androidx.compose.ui.unit.constrainWidth

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
    Column(modifier.width(width).then(InViewOnFocusElement)) {
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
                )
                // The card's own semantics alone, without a node for the image or the labels inside (they add nothing
                // to it): an accessibility service walks every node again on each frame a grid scrolls.
                .clearAndSetSemantics {},
            corner,
            // The card's clip above (around its click, so the press ripple is rounded) already clips the artwork.
            clip = false,
        )
        if (!caption && !tv) return@Column
        // On TV the focused artwork grows over the gap: the caption stays clear of it.
        Spacer(Modifier.height(if (tv) 10.dp else 6.dp))
        val lines = if (largeFontScale()) 2 else 1
        // A TV card without its caption keeps the room, shown while focused.
        val shown = caption || focused
        val titleStyle = MaterialTheme.typography.titleSmall.contentDirection().hyphenated()
        val captionStyle = MaterialTheme.typography.bodySmall.hyphenated()
        val captionText = item.caption.orEmpty()
        val links = item.titleLink != null || item.captionLink?.let { captionText.startsWith(it.prefix) } == true
        if (links && LocalOpenRoute.current != null && !isFocusVisible()) {
            // Links under a pointer or a touch; the text under the artwork is hidden from screen readers: one cleared
            // node, not one per line.
            val alpha = if (shown) Modifier else Modifier.alpha(0f)
            Column(Modifier.clearAndSetSemantics {}) {
                DetailLinkText(item.title, item.titleLink, titleStyle, LocalContentColor.current, alpha, maxOf(lines, titleLines))
                LinkedLine(captionText, item.captionLink, captionStyle, PlezyColors.TextMuted, alpha, lines)
            }
        } else {
            CardLabel(
                listOf(
                    LabelLine(item.title, titleStyle, LocalContentColor.current, maxOf(lines, titleLines)),
                    LabelLine(captionText, captionStyle, PlezyColors.TextMuted, lines, item.captionLink?.prefix),
                ),
                shown,
            )
        }
    }
}

/**
 * An item's artwork in [modifier]'s bounds, clipped to [shape] (by [modifier] itself without [clip]: one clip, one
 * layer): the image over the raised fill while it loads, its
 * fallback once it fails, blurred while a spoiler, its placeholder when there is none ([ArtworkPlaceholder]); over it its quality labels (or a catalog title's availability) down the
 * top start corner, the watched check or the unwatched count at the top end, and the watch progress along the foot
 * ([ArtworkProgress]); an artist has neither check, count nor progress.
 */
@Composable
fun CardArtwork(item: MediaCardUi, modifier: Modifier, shape: Shape = MaterialTheme.shapes.medium, clip: Boolean = true) {
    val fill = PlezyColors.SurfaceHigh
    // The fill is the image's blank: under an opaque poster it would be drawn for nothing on every frame.
    Box(if (clip) modifier.clip(shape) else modifier) {
        val primary = item.primaryArtwork
        val retry = item.retryArtwork
        RemoteImage(
            artwork = primary,
            contentDescription = null,
            modifier = Modifier.matchParentSize(),
            blank = fill,
            blankUnderAlpha = true,
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

/** Brings the card, its labels too, into view as focus comes into it: one node, without a coroutine scope a card. */
private data object InViewOnFocusElement : ModifierNodeElement<InViewOnFocusNode>() {
    override fun create() = InViewOnFocusNode()

    override fun update(node: InViewOnFocusNode) = Unit
}

private class InViewOnFocusNode :
    Modifier.Node(),
    FocusEventModifierNode {
    private var focused = false

    override fun onFocusEvent(focusState: FocusState) {
        if (focusState.hasFocus && !focused) coroutineScope.launch { bringIntoView() }
        focused = focusState.hasFocus
    }
}

/**
 * One line of a [CardLabel]: [text] in [style] and [color], at most [lines] lines and as many reserved; a [prefix] it
 * starts with (a [CardLink]'s) is laid out as [LinkedLine] lays it: on one line, the rest on one line after it.
 */
internal data class LabelLine(val text: String, val style: TextStyle, val color: Color, val lines: Int, val prefix: String? = null)

/**
 * A card's [lines] (its title over its caption) laid out and drawn as a column of [Text]s at its start would (each cut
 * short with an ellipsis, its lines reserved), by one element with no semantics: no layout node and no semantics node
 * per line, which a grid lays out, and an accessibility service walks, for every card it brings in as it scrolls.
 * Drawn while [shown]; the room stays either way.
 */
@Composable
internal fun CardLabel(lines: List<LabelLine>, shown: Boolean) {
    Spacer(CardLabelElement(lines, LocalCardText.current ?: rememberCardText(), shown))
}

/**
 * The text measurer [CardLabel]s lay out with, and the heights [Text] reserves for a style's lines beyond the first
 * (as its minLines measures them: the height of two reference lines less one), measured once a style.
 */
internal class CardText(val measurer: TextMeasurer) {
    private val lineHeights = HashMap<TextStyle, FloatArray>()

    fun reservedHeight(style: TextStyle, lines: Int): Int {
        if (lines <= 1) return 0
        val (one, two) = lineHeights.getOrPut(style) {
            floatArrayOf(
                measurer.measure(REFERENCE_LINE, style, softWrap = false, maxLines = 1).multiParagraph.height,
                measurer.measure("$REFERENCE_LINE\n$REFERENCE_LINE", style, maxLines = 2).multiParagraph.height,
            )
        }
        return (one + (two - one) * (lines - 1)).roundToInt()
    }
}

/** The cards' shared [CardText] (a grid's, [MediaGrid]); without one each card has its own. */
internal val LocalCardText = staticCompositionLocalOf<CardText?> { null }

@Composable
internal fun rememberCardText(): CardText {
    val measurer = rememberTextMeasurer()
    return remember(measurer) { CardText(measurer) }
}

private data class CardLabelElement(val lines: List<LabelLine>, val text: CardText, val shown: Boolean) :
    ModifierNodeElement<CardLabelNode>() {
    override fun create() = CardLabelNode(lines, text, shown)

    override fun update(node: CardLabelNode) = node.update(lines, text, shown)
}

private class CardLabelNode(private var lines: List<LabelLine>, private var text: CardText, private var shown: Boolean) :
    Modifier.Node(),
    LayoutModifierNode,
    DrawModifierNode {
    private var laid: List<LaidLine> = emptyList()
    private var tops = IntArray(0)

    fun update(lines: List<LabelLine>, text: CardText, shown: Boolean) {
        if (lines != this.lines || text !== this.text) {
            this.lines = lines
            this.text = text
            invalidateMeasurement()
        }
        if (shown != this.shown) {
            this.shown = shown
            invalidateDraw()
        }
    }

    override fun MeasureScope.measure(measurable: Measurable, constraints: Constraints): MeasureResult {
        val results = lines.map { lay(it, constraints.maxWidth) }
        val tops = IntArray(lines.size)
        var height = 0
        results.forEachIndexed { i, line ->
            tops[i] = height
            height += line.height
        }
        if (results.map { it.parts } != laid.map { it.parts }) invalidateDraw()
        laid = results
        this@CardLabelNode.tops = tops
        val w = constraints.constrainWidth(results.maxOfOrNull { it.width } ?: 0)
        val h = constraints.constrainHeight(height)
        val placeable = measurable.measure(Constraints.fixed(w, h))
        return layout(w, h) { placeable.place(0, 0) }
    }

    private fun lay(line: LabelLine, maxWidth: Int): LaidLine {
        val measurer = text.measurer
        val prefix = line.prefix?.takeIf { line.text.startsWith(it) }
        if (prefix == null) {
            val result = measurer.measure(line.text, line.style, TextOverflow.Ellipsis, maxLines = line.lines, constraints = Constraints(maxWidth = maxWidth))
            return LaidLine(listOf(result), result.size.width, maxOf(result.size.height, text.reservedHeight(line.style, line.lines)))
        }
        // As a row of two texts: the prefix, then the rest in the width left.
        val head = measurer.measure(prefix, line.style, TextOverflow.Ellipsis, maxLines = 1, constraints = Constraints(maxWidth = maxWidth))
        val left = (maxWidth - head.size.width).coerceAtLeast(0)
        val rest = measurer.measure(line.text.removePrefix(prefix), line.style, TextOverflow.Ellipsis, maxLines = 1, constraints = Constraints(maxWidth = left))
        return LaidLine(listOf(head, rest), head.size.width + rest.size.width, maxOf(head.size.height, rest.size.height))
    }

    override fun ContentDrawScope.draw() {
        if (!shown) return
        val rtl = layoutDirection == LayoutDirection.Rtl
        laid.forEachIndexed { i, line ->
            // From the start edge: the left one, or the right one right to left.
            var x = if (rtl) size.width else 0f
            for (part in line.parts) {
                if (rtl) x -= part.size.width
                drawText(part, color = lines[i].color, topLeft = Offset(x, tops[i].toFloat()))
                if (!rtl) x += part.size.width
            }
        }
    }
}

/** A laid out [LabelLine]: its texts (a prefix's first) and its room. */
private class LaidLine(val parts: List<TextLayoutResult>, val width: Int, val height: Int)

/** The reference line [Text] measures its reserved lines with. */
private const val REFERENCE_LINE = "HHHHHHHHHH"

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
