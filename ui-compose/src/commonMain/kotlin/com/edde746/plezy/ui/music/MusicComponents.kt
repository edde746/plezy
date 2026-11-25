package com.edde746.plezy.ui.music

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.StartOffset
import androidx.compose.animation.core.StartOffsetType
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.music.MusicRepeatMode
import com.edde746.plezy.presentation.music.MUSIC_HEADER_WIDE_FROM
import com.edde746.plezy.presentation.music.MusicHeaderUi
import com.edde746.plezy.presentation.music.TrackRowUi
import com.edde746.plezy.presentation.music.label
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.cast.CastButton
import com.edde746.plezy.ui.cast.castInTopBar
import com.edde746.plezy.ui.components.FoldingActionRow
import com.edde746.plezy.ui.components.RowAction
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.detail.EpisodeListRow
import androidx.compose.material3.LocalContentColor
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import com.edde746.plezy.ui.theme.contentDirection

/** The track number's (or the equalizer's) column at a track row's start. */
private val TrackLeadWidth = 32.dp

/** A track's artwork at a track row's start (a playlist's, the queue's). */
private val TrackArtworkSize = 44.dp

/**
 * Three bars rising and falling while [animate] (the playing track), still otherwise: the current track's mark in lists
 * and the TV rail's Now Playing item. They move on the reduced effects tier too, and are only redrawn, never laid out
 * again. Moving, they share one period, each 220 ms behind the one before, so they are never all low at once, and never
 * lower than 0.4 of the mark, so two short bars still read as bars; still, they stand at three heights. Bars of one
 * height, moving or still, read as a "more" mark (•••).
 */
@Composable
fun EqualizerIcon(animate: Boolean, color: Color, modifier: Modifier = Modifier) {
    val transition = rememberInfiniteTransition(label = "equalizer")
    val phases = listOf(0, 220, 440).map { offset ->
        if (animate) {
            transition.animateFloat(
                0.4f,
                1f,
                infiniteRepeatable(tween(520, easing = LinearEasing), RepeatMode.Reverse, StartOffset(offset, StartOffsetType.FastForward)),
                label = "bar$offset",
            )
        } else {
            null
        }
    }
    Canvas(modifier.size(18.dp)) {
        val gap = size.width / 7
        val bar = (size.width - gap * 2) / 3
        phases.forEachIndexed { i, phase ->
            // Read while drawing: each frame redraws the bars without composing them again.
            val h = size.height * (phase?.value ?: STILL_BARS[i])
            drawRoundRect(color, Offset(i * (bar + gap), size.height - h), Size(bar, h), CornerRadius(bar / 2))
        }
    }
}

/** The still bars' heights, as shares of the mark's. */
private val STILL_BARS = floatArrayOf(0.55f, 1f, 0.75f)

/**
 * A track row, an [EpisodeListRow] (hover tint, the primary fill with focus, [current] keeping a
 * faint tint): the track's artwork where the row has it (a playlist's; when [current] the now-playing mark over it, as
 * the player's lists mark their thumbnails), else [NowPlayingSlot], then the title over "subtitle · length", muted while
 * [TrackRowUi.dimmed], then ⋮ when it has a menu. At a large font scale it stays one row, its texts wrapping whole
 * between the number and ⋮. Tap, Select: [onClick]; ⋮, a long press, a right click, the Menu key: [onMenu] (the
 * track's item menu).
 */
@Composable
fun TrackRow(
    row: TrackRowUi,
    current: Boolean,
    playing: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    onMenu: (() -> Unit)? = null,
) {
    val info = listOfNotNull(row.subtitle, row.duration).joinToString(" · ").ifEmpty { null }
    // [modifier] on the outer box: a Row's weight reaches only its direct child.
    Box(modifier) {
        EpisodeListRow(
            title = row.title,
            infoLine = info,
            overview = null,
            onClick = onClick,
            modifier = Modifier
                .then(if (onMenu != null) Modifier.menuGestures(onMenu) else Modifier)
                .layoutProbe("music.track.${row.index}"),
            highlighted = current,
            keepsArtworkBeside = true,
            // A played row (the queue's) takes the muted colour for its title as well: dimmed, still 4.5:1.
            titleMuted = row.dimmed && !current,
            onLongClick = onMenu,
            trailing = {
                if (onMenu != null) PlezyIconButton(PlezyIcons.MoreVert, T.common.options, onMenu, style = IconButtonStyle.PLAIN)
            },
        ) {
            val artwork = row.artwork
            if (artwork != null) TrackArtwork(artwork, current, playing) else NowPlayingSlot(current, playing, row.trackNumber)
        }
    }
}

/**
 * A track's square [artwork] at a row's start, the album placeholder without it; when [current], the now-playing mark
 * over it (moving while [playing], named "Now playing" for screen readers), as the player's lists mark their thumbnails.
 */
@Composable
internal fun TrackArtwork(artwork: Artwork?, current: Boolean, playing: Boolean) {
    val name = T.player.nowPlaying
    val shape = RoundedCornerShape(6.dp)
    Box(Modifier.size(TrackArtworkSize).clip(shape), contentAlignment = Alignment.Center) {
        RemoteImage(artwork, null, Modifier.size(TrackArtworkSize), blank = PlezyColors.SurfaceHigh, error = { ArtworkPlaceholder(PlaceholderKind.ALBUM) })
        if (current) {
            Box(
                Modifier.size(TrackArtworkSize)
                    .background(Color.Black.copy(alpha = 0.6f))
                    .border(1.5.dp, PlezyColors.TextMuted, shape)
                    .semantics { contentDescription = name },
            )
            EqualizerIcon(playing, Color.White)
        }
    }
}

/**
 * The column at a track row's start, as wide on every row: the equalizer on the [current] row (moving while
 * [playing], named "Now playing" for screen readers), else the track's [number], else nothing. The playing row's title
 * starts where every other row's does.
 */
@Composable
internal fun NowPlayingSlot(current: Boolean, playing: Boolean, number: String? = null) {
    val name = T.player.nowPlaying
    Box(
        Modifier.width(TrackLeadWidth).then(if (current) Modifier.semantics { contentDescription = name } else Modifier),
        contentAlignment = Alignment.Center,
    ) {
        when {
            current -> EqualizerIcon(playing, if (LocalContentColor.current == PlezyColors.OnPrimary) PlezyColors.OnPrimary else MaterialTheme.colorScheme.primary)
            number != null -> Text(number, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.MutedContent)
        }
    }
}

/** The repeat button's icon for [mode]. */
internal val MusicRepeatMode.icon: ImageVector
    get() = if (this == MusicRepeatMode.ONE) PlezyIcons.RepeatOne else PlezyIcons.Repeat

/** Repeat's tooltip. */
internal val MusicRepeatMode.tooltip: String get() = label

/**
 * The music detail actions ([FoldingActionRow]): the Play pill, the cast button (on phones it sits in the screen's
 * header instead: [castInTopBar]), [leading] (the album's or the playlist's download), then Shuffle, Instant Mix while
 * [onInstantMix] (the server offers it) and the screen's own [actions] (a playlist's Edit and Delete Playlist), folded
 * into ⋮ where the width runs out: [more] (the album's item menu, `music.album.more`) where the screen has one, else
 * `music.more`. Play takes the first focus, and again each time [focusKey] changes (a playlist leaving Edit mode).
 * Harness name `music.actions`.
 */
@Composable
fun MusicActions(
    onPlay: () -> Unit,
    onShuffle: () -> Unit,
    onInstantMix: (() -> Unit)?,
    more: RowAction? = null,
    actions: List<RowAction> = emptyList(),
    focusKey: Any? = Unit,
    leading: @Composable () -> Unit = {},
) {
    // The screen's first focus (a remote, a keyboard): Play, once it shows.
    val playFocus = remember { FocusRequester() }
    LaunchedEffect(focusKey) { playFocus.requestFocus() }
    val fold = listOfNotNull(
        RowAction(PlezyIcons.Shuffle, T.common.shuffle, "music.shuffle", onClick = onShuffle),
        onInstantMix?.let { RowAction(PlezyIcons.AutoFixHigh, T.music.instantMix, "music.instantMix", onClick = it) },
    ) + actions
    FoldingActionRow("music.actions", fold, "music.more", more = more) {
        PlezyButton(T.common.play, onPlay, Modifier.focusRequester(playFocus).layoutProbe("music.play"), style = ButtonStyle.PRIMARY, icon = PlezyIcons.PlayArrow)
        if (!castInTopBar) CastButton()
        leading()
    }
}

/**
 * The album and artist header: below [MUSIC_HEADER_WIDE_FROM] the artwork ([compactArtwork] square) over centred
 * text and the actions; from it the artwork at 180 beside left-aligned text and the actions. Without artwork it shows
 * [placeholder], an artist's round.
 */
@Composable
fun MusicDetailHeader(
    header: MusicHeaderUi,
    placeholder: PlaceholderKind,
    compactArtwork: Int,
    onArtist: (() -> Unit)?,
    actions: @Composable () -> Unit,
    modifier: Modifier = Modifier,
) {
    BoxWithConstraints(modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
        val wide = maxWidth.value >= MUSIC_HEADER_WIDE_FROM
        val artShape = if (placeholder.circular) CircleShape else RoundedCornerShape(16.dp)
        val art = @Composable { side: Int ->
            RemoteImage(
                header.artwork,
                null,
                Modifier.size(side.dp).clip(artShape).layoutProbe("music.header.art"),
                blank = PlezyColors.SurfaceHigh,
                error = { ArtworkPlaceholder(placeholder) },
            )
        }
        val info = @Composable { centered: Boolean ->
            val align = if (centered) TextAlign.Center else TextAlign.Start
            Column(horizontalAlignment = if (centered) Alignment.CenterHorizontally else Alignment.Start) {
                // The page's one title (its header row has Back alone): screen readers take it as the heading.
                Text(header.title, style = MaterialTheme.typography.titleLarge.contentDirection(), textAlign = align, modifier = Modifier.semantics { heading() })
                header.artist?.let { artist ->
                    Spacer(Modifier.height(4.dp))
                    Text(
                        artist,
                        fontWeight = FontWeight.Medium,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = if (onArtist != null) {
                            Modifier.clip(RoundedCornerShape(8.dp)).combinedClickable(onClick = onArtist).padding(horizontal = 6.dp, vertical = 2.dp).layoutProbe("music.header.artist")
                        } else {
                            Modifier
                        },
                    )
                }
                header.meta?.let {
                    Spacer(Modifier.height(4.dp))
                    Text(it, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, textAlign = align)
                }
                header.bio?.let { bio ->
                    var expanded by remember { mutableStateOf(false) }
                    Spacer(Modifier.height(12.dp))
                    Text(
                        bio,
                        style = MaterialTheme.typography.bodyMedium,
                        color = PlezyColors.TextMuted,
                        maxLines = if (expanded) Int.MAX_VALUE else 3,
                        overflow = TextOverflow.Ellipsis,
                        textAlign = align,
                        modifier = Modifier.clip(RoundedCornerShape(8.dp)).combinedClickable { expanded = !expanded }.layoutProbe("music.header.bio"),
                    )
                }
            }
        }
        if (wide) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                art(180)
                Spacer(Modifier.width(24.dp))
                Column(Modifier.weight(1f)) {
                    info(false)
                    Spacer(Modifier.height(16.dp))
                    actions()
                }
            }
        } else {
            Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                art(compactArtwork)
                Spacer(Modifier.height(16.dp))
                info(true)
                Spacer(Modifier.height(16.dp))
                actions()
            }
        }
    }
}
