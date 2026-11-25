package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.layout.ListRowLayout
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.WidthClass
import com.edde746.plezy.ui.adaptive.largeFontScale
import com.edde746.plezy.ui.onboarding.OnboardingMarks
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection

/**
 * A list row of [artwork] (a poster, a thumbnail), its [text] in a column and [trailing] (a status mark, a ⋮) at its
 * end, [gap] apart: the text beside the artwork, taking the room between, or, [stacked] (a large font scale,
 * [largeFontScale]), under it across the row, [gap] below, with [trailing] at the end of the artwork's line. A stacked
 * row's text is meant whole: its callers lift their line limits.
 */
@Composable
fun ArtworkRow(
    stacked: Boolean,
    gap: Dp,
    artwork: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    textModifier: Modifier = Modifier,
    trailing: @Composable () -> Unit = {},
    text: @Composable ColumnScope.() -> Unit,
) {
    val lines = Arrangement.spacedBy(2.dp)
    if (stacked) {
        Column(modifier, verticalArrangement = Arrangement.spacedBy(gap)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                artwork()
                Spacer(Modifier.weight(1f))
                trailing()
            }
            Column(textModifier.fillMaxWidth(), verticalArrangement = lines, content = text)
        }
    } else {
        Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(gap)) {
            artwork()
            Column(textModifier.weight(1f), verticalArrangement = lines, content = text)
            trailing()
        }
    }
}

/** The inset of a row's artwork and text inside its fill, and the gap between them. */
val RowInset = 12.dp

/**
 * An item as a row of a list (a library's list view, search results): its artwork ([CardArtwork] in [shape], at the
 * row's artwork width) beside its title (two lines, a link to its detail), metadata line ([MediaCardUi.listMetadata]),
 * subtitle ([MediaCardUi.listSubtitle], its season a link) and summary (more lines at a roomier
 * library [density]); at a large font scale the text goes under the artwork, whole ([ArtworkRow]). The row is one
 * focusable element ([PlezySurface], a row of a list: its fill alone shows focus, no growth) in [rowShape]
 * ([groupShape] in a group). With [source] it says where the item lives after [backend]'s mark ([SourceLine]), a wide
 * row giving up a summary line for it. [onClick] opens it; [onLongClick] is its menu (a long press, a held Select, a right click
 * or the Menu key, [menuGestures]). Screen readers hear [label] (its title by default) with its state ([cardState]).
 */
@Composable
fun MediaRow(
    item: MediaCardUi,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
    shape: CardShape = item.shape,
    density: Int = 3,
    onLongClick: (() -> Unit)? = null,
    rowShape: Shape = MaterialTheme.shapes.medium,
    source: String? = null,
    backend: BackendKind? = null,
    label: String = item.title,
) {
    val state = item.cardState()
    PlezySurface(
        onClick = onClick ?: {},
        modifier = modifier
            .fillMaxWidth()
            .semantics {
                contentDescription = label
                if (state != null) stateDescription = state
            }
            .then(if (onLongClick != null) Modifier.menuGestures(onLongClick) else Modifier),
        shape = rowShape,
        color = Color.Transparent,
        onLongClick = onLongClick,
        grows = false,
    ) {
        val stacked = largeFontScale()
        val width = rowArtworkWidth(shape)
        ArtworkRow(
            stacked,
            gap = RowInset,
            artwork = {
                CardArtwork(
                    item,
                    Modifier.width(width).aspectRatio(shape.aspectRatio),
                    if (item.placeholder.circular) CircleShape else MaterialTheme.shapes.small,
                )
            },
            modifier = Modifier.padding(RowInset),
            // The row says its title and state itself.
            textModifier = Modifier.clearAndSetSemantics {},
        ) {
            val muted = PlezyColors.MutedContent
            val all = if (stacked) Int.MAX_VALUE else null
            DetailLinkText(
                item.title,
                item.titleLink,
                MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold).contentDirection(),
                LocalContentColor.current,
                maxLines = all ?: 2,
                minLines = 1,
            )
            item.listMetadata?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = muted, maxLines = all ?: 1, overflow = TextOverflow.Ellipsis) }
            item.listSubtitle?.let { LinkedLine(it, item.captionLink, MaterialTheme.typography.bodySmall, muted, maxLines = all ?: 1, minLines = 1) }
            item.summary?.let {
                Text(
                    it,
                    style = MaterialTheme.typography.bodySmall.contentDirection(),
                    color = muted,
                    maxLines = all ?: ListRowLayout.summaryLines(density).let { if (source != null && shape == CardShape.WIDE && it > 1) it - 1 else it },
                    overflow = TextOverflow.Ellipsis,
                )
            }
            if (source != null && backend != null) SourceLine(backend, source)
        }
    }
}

/** A list row's artwork width for [shape]: a poster's or a square's narrow, a thumbnail's wide; larger on TV. */
@Composable
fun rowArtworkWidth(shape: CardShape): Dp {
    val layout = LocalWindowLayout.current
    val poster = shape != CardShape.WIDE
    return when {
        layout.formFactor == FormFactor.TV -> if (poster) 64.dp else 176.dp
        layout.widthClass == WidthClass.COMPACT -> if (poster) 48.dp else 112.dp
        else -> if (poster) 56.dp else 144.dp
    }
}

/** Where an item lives ("Server • Library") after its [backend]'s mark, in the muted colour. */
@Composable
fun SourceLine(backend: BackendKind, text: String) {
    val tint = PlezyColors.MutedContent
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Icon(OnboardingMarks.backend(backend), contentDescription = null, Modifier.size(14.dp), tint = tint)
        Text(text, style = MaterialTheme.typography.bodySmall, color = tint, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}
