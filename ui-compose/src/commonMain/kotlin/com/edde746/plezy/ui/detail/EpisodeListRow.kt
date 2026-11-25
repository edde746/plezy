package com.edde746.plezy.ui.detail

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorProducer
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.WidthClass
import com.edde746.plezy.ui.adaptive.largeFontScale
import com.edde746.plezy.ui.components.ArtworkProgress
import com.edde746.plezy.ui.components.ArtworkRow
import com.edde746.plezy.ui.components.RowInset
import com.edde746.plezy.ui.components.overlayOpener
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.theme.LocalPlezyColors
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection

/** An episode thumbnail's corners; the row's are this plus [RowInset], so the two curves run parallel. */
private val ThumbnailRadius = 8.dp

/** An episode row's corners and its thumbnail's. */
private val RowShape = RoundedCornerShape(ThumbnailRadius + RowInset)

internal val ThumbnailShape: Shape = RoundedCornerShape(ThumbnailRadius)

/** An episode row's thumbnail width in a narrow window's list: a phone's, else wider. */
@Composable
internal fun listThumbnailWidth(): Dp = if (LocalWindowLayout.current.widthClass == WidthClass.COMPACT) 128.dp else 176.dp

/**
 * An episode (or a playlist's item) as a free-flowing row: [artwork] (its 16:9 [EpisodeThumbnail]), [title] in
 * semibold, [infoLine] muted on [infoLines] lines, [badge] (its download), [overview] muted on two lines, [RowInset]
 * around and between them, then [trailing] (its ⋮). No card: hover and press lay a tint behind the whole row; focus
 * (keyboard, D-pad) the primary fill with dark text, the row keeping its size. [highlighted] (the on-deck episode) keeps a faint
 * tint at rest. A click takes focus too (a mouse click doesn't), so focus is on the row once what it opened closes,
 * then does [onClick]; a long press does [onLongClick]. At a large font scale the texts show whole, under the artwork
 * ([ArtworkRow]) or, with [keepsArtworkBeside] (a track's number, a small square), still beside it, the row keeping one
 * line of artwork, texts and [trailing]. [modifier] comes before the row's focus target: its focus memory, harness name,
 * semantics and menu gestures. [titleMuted] (a played track in the queue) sets the title in the muted colour too.
 */
@Composable
internal fun EpisodeListRow(
    title: String,
    infoLine: String?,
    infoLines: Int = 1,
    overview: String?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    highlighted: Boolean = false,
    onLongClick: (() -> Unit)? = null,
    trailing: @Composable () -> Unit = {},
    keepsArtworkBeside: Boolean = false,
    badge: @Composable () -> Unit = {},
    titleMuted: Boolean = false,
    artwork: @Composable () -> Unit,
) {
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    val hovered by interactions.collectIsHoveredAsState()
    val pressed by interactions.collectIsPressedAsState()
    val filled = focused && isFocusVisible()
    val hover = PlezyColors.HoverTint
    val fill = animateColorAsState(
        when {
            filled -> PlezyColors.Primary
            pressed || hovered || highlighted -> hover
            else -> hover.copy(alpha = 0f)
        },
        tween(durationMillis = 120),
        label = "episodeFill",
    )
    val contentTarget = if (filled) PlezyColors.OnPrimary else PlezyColors.Text
    val content = animateColorAsState(contentTarget, tween(durationMillis = 120), label = "episodeContent")
    val colors = LocalPlezyColors.current
    val text = remember(content) { ColorProducer { content.value } }
    val muted = remember(content, colors) { ColorProducer { colors.muted(content.value) } }
    val rowFocus = remember { FocusRequester() }
    val largeText = largeFontScale()
    val stacked = largeText && !keepsArtworkBeside
    CompositionLocalProvider(LocalContentColor provides contentTarget) {
        ArtworkRow(
            stacked,
            gap = RowInset,
            artwork = artwork,
            modifier = Modifier
                .fillMaxWidth()
                .then(modifier)
                .focusRequester(rowFocus)
                .drawWithCache {
                    val outline = RowShape.createOutline(size, layoutDirection, this)
                    onDrawBehind {
                        val color = fill.value
                        if (color.alpha > 0f) drawOutline(outline, color)
                    }
                }
                .overlayOpener()
                .combinedClickable(
                    interactionSource = interactions,
                    indication = null,
                    role = Role.Button,
                    onLongClick = onLongClick,
                    onClick = {
                        rowFocus.requestFocus()
                        onClick()
                    },
                )
                .padding(RowInset),
            trailing = trailing,
        ) {
            BasicText(
                title,
                style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold).contentDirection(),
                overflow = TextOverflow.Ellipsis,
                maxLines = if (largeText) Int.MAX_VALUE else 2,
                color = if (titleMuted) muted else text,
            )
            infoLine?.let {
                BasicText(it, style = MaterialTheme.typography.bodySmall, maxLines = if (largeText) Int.MAX_VALUE else infoLines, overflow = TextOverflow.Ellipsis, color = muted)
            }
            badge()
            overview?.let {
                BasicText(
                    it,
                    Modifier.padding(top = 2.dp),
                    style = MaterialTheme.typography.bodySmall.contentDirection(),
                    overflow = TextOverflow.Ellipsis,
                    maxLines = if (largeText) Int.MAX_VALUE else 2,
                    color = muted,
                )
            }
        }
    }
}

/**
 * An episode's 16:9 thumbnail: [artwork], else [fallbackArtwork] where it has none or it fails to load, else the TV
 * icon; blurred past recognition while [blurred] (spoilers hidden), its [progress] inside the bottom edge
 * ([ArtworkProgress]), a check while [watched]; [overlay] over it (a TV card's code).
 */
@Composable
internal fun EpisodeThumbnail(
    artwork: Artwork?,
    blurred: Boolean,
    modifier: Modifier,
    fallbackArtwork: Artwork? = null,
    watched: Boolean = false,
    progress: Float? = null,
    overlay: @Composable BoxScope.() -> Unit = {},
) {
    Box(modifier.aspectRatio(16f / 9f).clip(ThumbnailShape).background(PlezyColors.SurfaceHigh)) {
        RemoteImage(
            artwork,
            contentDescription = null,
            modifier = Modifier.matchParentSize(),
            fallbackArtwork = fallbackArtwork,
            blurred = blurred,
            error = { ArtworkPlaceholder(PlaceholderKind.EPISODE) },
        )
        if (watched) {
            Icon(
                PlezyIcons.CheckCircle,
                contentDescription = null,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(6.dp)
                    .size(20.dp)
                    .background(Color.Black.copy(alpha = 0.55f), CircleShape),
                tint = Color.White,
            )
        }
        progress?.let { ArtworkProgress(it, Modifier.matchParentSize()) }
        overlay()
    }
}
