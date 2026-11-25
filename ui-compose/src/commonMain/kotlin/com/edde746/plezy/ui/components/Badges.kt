package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.rememberTextMeasurer
import com.edde746.plezy.presentation.browse.BadgeIcon
import com.edde746.plezy.presentation.browse.BadgeShortForm
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * A short fact about an item (resolution, HDR, codec, size, "Built in", a count), as preformatted by the store: a
 * solid rounded rectangle a step lighter than what it sits on (the background, a row's surfaceHigh or surfaceHighest
 * fill, a sheet); [emphasised] (the one thing to notice, a stream's 4K) in the primary fill. One line unless [maxLines]
 * lets a longer one (an addon's note, a sentence) wrap rather than be cut where its row ends. [leading] (a source's
 * mark) goes before the text, in the text's colour.
 * On a light fill (a focused row: its content colour turns dark) the badges invert, so none vanishes into the row:
 * the emphasised one dark with light text, the others a mid grey with dark text. In the light theme, whose text is dark
 * everywhere, a plain badge is the text colour's light tint, as in the dark theme, not the focused row's mid grey.
 */
@Composable
fun Badge(text: String, modifier: Modifier = Modifier, emphasised: Boolean = false, maxLines: Int = 1, leading: (@Composable () -> Unit)? = null) {
    val (fill, color) = badgeColors(emphasised)
    val style = badgeStyle()
    val box = modifier.background(fill, BadgeShape).padding(horizontal = BADGE_PADDING, vertical = 2.dp)
    if (leading == null) return Text(text, box, color = color, style = style, maxLines = maxLines)
    Row(box, horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
        CompositionLocalProvider(LocalContentColor provides color) { leading() }
        Text(text, color = color, style = style, maxLines = maxLines)
    }
}

/**
 * A poster's badges ([Badge], emphasised) down its corner: each label on one line at the badge's size when that fits
 * the width the poster leaves; otherwise its short form from [shortForms] (✓, a clock, ◐, "4K", "2/3") with the label
 * as its accessibility label, consecutive short forms side by side on one line (as many as fit), so a small poster
 * keeps its picture; a label without one is left out. Never wraps, shrinks or cuts a word.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun PosterBadges(labels: List<String>, shortForms: Map<String, BadgeShortForm>, modifier: Modifier = Modifier) {
    val measurer = rememberTextMeasurer()
    val style = badgeStyle()
    BoxWithConstraints(modifier) {
        val padding = with(LocalDensity.current) { (BADGE_PADDING * 2).roundToPx() }
        val lines = mutableListOf<List<Pair<String, BadgeShortForm?>>>()
        for (label in labels) {
            val fits = measurer.measure(label, style, maxLines = 1, softWrap = false).size.width + padding <= constraints.maxWidth
            val short = shortForms[label]
            when {
                fits -> lines.add(listOf(label to null))
                short == null -> Unit
                lines.lastOrNull()?.firstOrNull()?.second != null -> lines[lines.lastIndex] = lines.last() + (label to short)
                else -> lines.add(listOf(label to short))
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            for (line in lines) {
                val (label, short) = line.first()
                if (short == null) {
                    Badge(label, emphasised = true)
                    continue
                }
                FlowRow(horizontalArrangement = Arrangement.spacedBy(4.dp), maxLines = 1) {
                    for ((text, form) in line) ShortBadge(text, form!!)
                }
            }
        }
    }
}

@Composable
private fun ShortBadge(label: String, form: BadgeShortForm) {
    val icon = form.icon
    if (icon != null) return IconBadge(icon.vector, label)
    Badge(form.text.orEmpty(), Modifier.semantics { contentDescription = label }, emphasised = true)
}

@Composable
private fun IconBadge(icon: ImageVector, label: String) {
    val (fill, color) = badgeColors(emphasised = true)
    // As tall as a one-line badge: the text's line height plus its 2 dp above and below.
    val size = with(LocalDensity.current) { badgeStyle().lineHeight.toDp() }
    Icon(icon, label, Modifier.background(fill, BadgeShape).padding(horizontal = 4.dp, vertical = 2.dp).size(size), tint = color)
}

private val BadgeIcon.vector: ImageVector
    get() = when (this) {
        BadgeIcon.AVAILABLE -> PlezyIcons.Check
        BadgeIcon.PARTIAL -> PlezyIcons.HalfCircle
        BadgeIcon.REQUESTED -> PlezyIcons.Schedule
        BadgeIcon.DECLINED -> PlezyIcons.Block
    }

@Composable
private fun badgeStyle(): TextStyle = MaterialTheme.typography.labelSmall.copy(fontSize = 12.sp, fontWeight = FontWeight.Medium)

/** A badge's fill and content colour. */
@Composable
private fun badgeColors(emphasised: Boolean): Pair<Color, Color> {
    val content = LocalContentColor.current
    val onLight = content.luminance() < 0.5f
    val fill = when {
        onLight && emphasised -> PlezyColors.OnPrimary
        onLight && PlezyColors.Text.luminance() < 0.5f -> PlezyColors.Text.copy(alpha = 0.08f)
        onLight -> OnLightBadge
        emphasised -> PlezyColors.Primary
        else -> PlezyColors.Text.copy(alpha = 0.14f)
    }
    // On a light fill the plain badge takes the dark content colour (the light theme's accent text is light).
    val color = when {
        onLight && !emphasised -> content
        onLight == emphasised -> PlezyColors.Text
        else -> PlezyColors.OnPrimary
    }
    return fill to color
}

private val BADGE_PADDING = 6.dp

private val BadgeShape = RoundedCornerShape(6.dp)

/** A badge's fill on a light (focused) row: a mid grey under dark text. */
private val OnLightBadge = Color(0xFFBDBDBD)
