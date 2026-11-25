package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyColors

/** The gap between the rows of a connected group. */
val GroupGap = 2.dp

/** The space above a group, apart from the gap a list leaves between its items: its [GroupHeader]'s top padding. */
val GroupSpacing = 12.dp

private val Outer = 20.dp
private val Inner = 5.dp

/**
 * The shape of the row at [index] of a connected group of [count] rows: 20 dp corners on the
 * group's outside, 5 dp between its rows, which stand [GroupGap] apart.
 */
fun groupShape(index: Int, count: Int): Shape {
    val top = if (index == 0) Outer else Inner
    val bottom = if (index == count - 1) Outer else Inner
    return RoundedCornerShape(topStart = top, topEnd = top, bottomStart = bottom, bottomEnd = bottom)
}

/** A connected group of rows: [content] draws them (each with its [groupShape]), [GroupGap] apart. */
@Composable
fun RowGroup(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(GroupGap), content = content)
}

/** A group's heading above it ("Video", "Languages"), [GroupSpacing] below what is above it. */
@Composable
fun GroupHeader(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier.padding(start = 16.dp, top = GroupSpacing, bottom = 6.dp).semantics { heading() },
    )
}

/**
 * A row of a group: an optional [icon] (or [logo], a mark drawn in its own colours: a sign-in provider's; or [leading],
 * drawn in the icon's place: a theme's swatch, a service's mark), [title] with its [subtitle], then an optional [value]
 * and [trailing] content (a chevron, a switch, a stepper) beside them or under them ([TextAndTrailing]), on the
 * surfaceHigh fill in [shape]. Title, subtitle and value wrap in full. The [value] sits beside the title only while
 * the title keeps one line beside it; else it leads the subtitle. With [onClick] the whole row is the control
 * (focus fills it, as every control, and as a row of a list it doesn't grow); [selected] marks the section shown
 * beside a list; [destructive] rows (sign out, delete) read in the error colour. [iconTint] paints the icon (an update
 * waiting: the warning colour); [subtitleLines] caps the subtitle's lines; [subtitleMonospace] sets it in a monospace
 * face (a pattern).
 */
@Composable
fun GroupRow(
    title: String,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.large,
    subtitle: String? = null,
    value: String? = null,
    icon: ImageVector? = null,
    logo: Painter? = null,
    enabled: Boolean = true,
    selected: Boolean = false,
    destructive: Boolean = false,
    iconTint: Color? = null,
    subtitleLines: Int = Int.MAX_VALUE,
    subtitleMonospace: Boolean = false,
    leading: (@Composable () -> Unit)? = null,
    trailing: (@Composable RowScope.() -> Unit)? = null,
) {
    val body: @Composable () -> Unit = {
        Row(
            Modifier.heightIn(min = 56.dp).padding(start = 16.dp, end = if (trailing != null) 12.dp else 16.dp, top = 10.dp, bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            if (leading != null) {
                leading()
            } else if (logo != null) {
                Icon(logo, contentDescription = null, Modifier.size(22.dp), tint = Color.Unspecified)
            } else if (icon != null) {
                Icon(icon, contentDescription = null, Modifier.size(22.dp), tint = iconTint ?: PlezyColors.MutedContent)
            }
            // The value sits beside the title only while the title keeps one line beside it (and what trails); else it
            // leads the subtitle, as a long value does.
            BoxWithConstraints(Modifier.weight(1f)) {
                val measurer = rememberTextMeasurer()
                val titleStyle = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium)
                val valueStyle = MaterialTheme.typography.bodyMedium
                val beside = value == null || !constraints.hasBoundedWidth || with(LocalDensity.current) {
                    val titleWidth = measurer.measure(title, titleStyle, maxLines = 1).size.width
                    val valueWidth = minOf(measurer.measure(value, valueStyle).size.width, ValueMaxWidth.roundToPx())
                    val end = if (trailing != null) (TrailingGap + TrailingMark).roundToPx() else 0
                    titleWidth + TrailingGap.roundToPx() + valueWidth + end <= constraints.maxWidth
                }
                val shownValue = value.takeIf { beside }
                val shownSubtitle = if (beside) subtitle else listOfNotNull(value, subtitle).joinToString("\n")
                TextAndTrailing(
                    text = {
                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(title, style = titleStyle)
                            if (shownSubtitle != null) {
                                Text(
                                    shownSubtitle,
                                    style = MaterialTheme.typography.bodySmall.let { if (subtitleMonospace) it.copy(fontFamily = FontFamily.Monospace) else it },
                                    color = PlezyColors.MutedContent,
                                    maxLines = subtitleLines,
                                    overflow = TextOverflow.Ellipsis,
                                )
                            }
                        }
                    },
                    trailing = {
                        if (shownValue != null || trailing != null) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(TrailingGap)) {
                                if (shownValue != null) {
                                    Text(
                                        shownValue,
                                        style = valueStyle,
                                        color = PlezyColors.MutedContent,
                                        modifier = Modifier.widthIn(max = ValueMaxWidth),
                                    )
                                }
                                trailing?.invoke(this)
                            }
                        }
                    },
                    // A pattern breaks anywhere: its long run of code never pushes what trails under it.
                    breakableText = subtitleMonospace,
                )
            }
        }
    }
    val color = if (selected) PlezyColors.SurfaceHighest else PlezyColors.SurfaceHigh
    if (onClick != null) {
        PlezySurface(
            onClick = onClick,
            modifier = modifier.fillMaxWidth(),
            shape = shape,
            color = color,
            contentColor = if (destructive) PlezyColors.Error else MaterialTheme.colorScheme.onSurface,
            enabled = enabled,
            selected = if (selected) true else null,
            grows = false,
        ) { body() }
    } else {
        Box(modifier.fillMaxWidth().background(color, shape)) { body() }
    }
}

/** A chevron at the end of a [GroupRow] that opens something. */
@Composable
fun RowScope.Chevron() {
    Icon(PlezyIcons.ChevronRight, contentDescription = null, tint = PlezyColors.MutedContent)
}

/**
 * A row's [text] and what trails it ([trailing]: a value, a switch, a stepper, a chevron, a button), the text wrapping
 * in full. The two sit side by side, centred on each other and [spacing] apart, while that leaves the text a column at
 * least [TEXT_MIN_EMS] of the rows' title size wide (about 16 characters: two or three words a line) and as wide as its
 * widest word. Otherwise (a narrow phone, a large font, a long word) [trailing] goes [STACK_GAP] under the text at the
 * row's end and the text takes the whole width, as Android's and iOS's own settings do at large text sizes. A
 * [trailing] that draws nothing takes no room. [text] and [trailing] are one layout node each. [breakableText] (code,
 * which wraps anywhere) keeps [trailing] beside it however long its words.
 *
 * The two are one focus group, so Up and Down from the rows around land on a control that trails the text (a stepper,
 * a button): Compose's search weighs how far off-centre a target lies, and alone at the row's end the control would
 * lose to a full-width row beyond it, whatever the text's wrap and the control's label made of its place.
 */
@Composable
fun TextAndTrailing(
    text: @Composable () -> Unit,
    trailing: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    spacing: Dp = 16.dp,
    breakableText: Boolean = false,
) {
    val titleSize = MaterialTheme.typography.bodyLarge.fontSize
    Layout(contents = listOf(text, trailing), modifier = modifier.focusGroup()) { (texts, trailings), constraints ->
        val words = texts.single()
        check(trailings.size <= 1) { "TextAndTrailing's trailing is ${trailings.size} layout nodes, not one" }
        val end = trailings.firstOrNull()?.measure(Constraints(maxWidth = constraints.maxWidth))
        if (end == null) {
            val placed = words.measure(constraints.copy(minHeight = 0))
            val height = maxOf(placed.height, constraints.minHeight)
            return@Layout layout(placed.width, height) { placed.placeRelative(0, (height - placed.height) / 2) }
        }
        val gap = spacing.roundToPx()
        val width = if (constraints.hasBoundedWidth) constraints.maxWidth else words.maxIntrinsicWidth(Constraints.Infinity) + gap + end.width
        val column = width - gap - end.width
        val ems = (titleSize * TEXT_MIN_EMS).toPx()
        val fewest = if (breakableText) ems else maxOf(ems, words.minIntrinsicWidth(Constraints.Infinity).toFloat())
        if (column >= fewest) {
            val placed = words.measure(Constraints(minWidth = column, maxWidth = column))
            val height = maxOf(placed.height, end.height, constraints.minHeight)
            layout(width, height) {
                placed.placeRelative(0, (height - placed.height) / 2)
                end.placeRelative(width - end.width, (height - end.height) / 2)
            }
        } else {
            val placed = words.measure(Constraints(minWidth = width, maxWidth = width))
            val below = STACK_GAP.roundToPx()
            val height = maxOf(placed.height + below + end.height, constraints.minHeight)
            layout(width, height) {
                placed.placeRelative(0, 0)
                end.placeRelative(width - end.width, placed.height + below)
            }
        }
    }
}

/** The narrowest text column [TextAndTrailing] keeps beside what trails it, in ems of the rows' title size. */
private const val TEXT_MIN_EMS = 8

/** The space between a row's text and what trails it once that goes under the text. */
private val STACK_GAP = 8.dp

/** The space between a row's value and what trails it, and between the text and the value. */
private val TrailingGap = 16.dp

/** The width of the mark that trails a value (a chevron, the drop-down mark). */
private val TrailingMark = 24.dp

/** The widest a value beside a row's title gets before it wraps. */
private val ValueMaxWidth = 240.dp
