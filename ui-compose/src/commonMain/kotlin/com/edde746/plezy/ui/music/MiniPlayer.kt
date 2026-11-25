package com.edde746.plezy.ui.music

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.browse.MediaMenu
import com.edde746.plezy.presentation.music.MiniPlayerStore
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.navigation.RailExtra
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * The mini-player, docked at the content's foot (the navigation scaffold's bottom accessory): above the bottom bar on
 * phones, under the screen beside the rail on wider windows, never on TV. A bar across the content on the surface
 * colour, the track's progress as a thin line along its top edge: the artwork, the title over the artist, previous
 * (desktop), play or pause, next and stop (✕). A tap opens Now Playing; a long press, a right click or the Menu
 * key the track's item menu ([menu]); a swipe sideways stops the session too. It expands in and collapses out.
 */
@Composable
fun MiniPlayer(store: MiniPlayerStore, menu: MediaMenu) {
    val state by store.state.collectAsState()
    AnimatedVisibility(state.visible, enter = expandVertically(tween(200)), exit = shrinkVertically(tween(150))) {
        MiniPlayerBar(store, menu, desktop = LocalWindowLayout.current.formFactor == FormFactor.DESKTOP)
    }
}

@Composable
private fun MiniPlayerBar(store: MiniPlayerStore, menu: MediaMenu, desktop: Boolean) {
    val state by store.state.collectAsState()
    val progress by store.progress.collectAsState()
    val track = state.track ?: return
    var drag by remember { mutableFloatStateOf(0f) }
    Column(Modifier.fillMaxWidth().background(PlezyColors.Surface)) {
        LinearProgressIndicator(
            progress = { progress },
            modifier = Modifier.fillMaxWidth().height(2.dp),
            color = MaterialTheme.colorScheme.primary,
            trackColor = PlezyColors.Hairline,
            drawStopIndicator = {},
            gapSize = 0.dp,
        )
        Box(
            Modifier
                .offset { IntOffset(drag.roundToInt(), 0) }
                .fillMaxWidth()
                .height(64.dp)
                .draggable(
                    rememberDraggableState { drag += it },
                    Orientation.Horizontal,
                    onDragStopped = { velocity -> if (abs(drag) > 120f || abs(velocity) > 1200f) store.dismiss() else drag = 0f },
                )
                .menuGestures { store.item?.let { menu.open(it) } }
                .combinedClickable(onLongClick = { store.item?.let { menu.open(it) } }, onClick = store::open)
                .layoutProbe("music.mini"),
        ) {
            Row(Modifier.fillMaxSize().padding(start = 12.dp, end = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                RemoteImage(
                    track.artwork,
                    null,
                    Modifier.size(44.dp).clip(RoundedCornerShape(8.dp)),
                    blank = PlezyColors.SurfaceHigh,
                    error = { ArtworkPlaceholder(PlaceholderKind.TRACK) },
                )
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(
                        track.title,
                        style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.layoutProbe("music.mini.title"),
                    )
                    track.artist?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted, maxLines = 1, overflow = TextOverflow.Ellipsis) }
                }
                if (desktop) {
                    PlezyIconButton(
                        PlezyIcons.SkipPrevious,
                        T.music.previousTrack,
                        store::previous,
                        Modifier.layoutProbe("music.mini.previous"),
                        style = IconButtonStyle.PLAIN,
                        enabled = state.canGoPrevious,
                    )
                }
                PlezyIconButton(
                    if (state.isPlaying) PlezyIcons.Pause else PlezyIcons.PlayArrow,
                    if (state.isPlaying) T.common.pause else T.common.play,
                    store::togglePlayPause,
                    Modifier.layoutProbe("music.mini.playPause"),
                    style = IconButtonStyle.PLAIN,
                )
                PlezyIconButton(PlezyIcons.SkipNext, T.music.nextTrack, store::next, Modifier.layoutProbe("music.mini.next"), style = IconButtonStyle.PLAIN, enabled = state.canGoNext)
                PlezyIconButton(PlezyIcons.Close, T.music.stopPlayback, store::dismiss, Modifier.layoutProbe("music.mini.close"), style = IconButtonStyle.PLAIN)
            }
        }
    }
}

/** The TV rail's Now Playing item while a track plays: the equalizer, animated while playing, and the track's title. */
@Composable
fun nowPlayingRailItem(store: MiniPlayerStore): RailExtra? {
    val state by store.state.collectAsState()
    if (!state.railItem) return null
    val playing = state.isPlaying
    val title = state.track?.title
    return remember(playing, title) {
        RailExtra(T.music.nowPlaying, "nav.nowPlaying", { tint -> EqualizerIcon(playing, tint) }, store::open, subtitle = title)
    }
}
