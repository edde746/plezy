package com.edde746.plezy.ui.cast

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.format.formatTimecode
import com.edde746.plezy.presentation.cast.CastNowPlaying
import com.edde746.plezy.presentation.cast.CastOption
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ChoiceMenu
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.focus.sliderKeys
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.settings.PlezySlider
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The cast control sheet, titled "Casting to <device>" ([receiverName]): the app's sheet on phones and tablets, the side
 * panel on TV and the desktop. While the receiver plays ([playing]): the artwork beside the title and subtitle, the seek
 * bar with the position and duration (not for what can't seek: live TV), previous, back 10 s, play or pause (a spinner
 * while it buffers), forward 10 s and next, then the audio, subtitle and quality choices it offers, the volume when the
 * receiver has one, Stop and Disconnect. Nothing playing: [idleText] and Disconnect. Back closes it. Focus opens on play
 * or pause, else Disconnect.
 *
 * Harness names `cast.controls`, `cast.controls.<seek|previous|seekBack|playPause|seekForward|next|audio|subtitles|
 * quality|volume|stop|disconnect>`.
 */
@Composable
fun CastControlSheet(receiverName: String, playing: CastNowPlaying?, idleText: String?, intents: CastIntents) {
    val initial = remember { FocusRequester() }
    PlezySheet(
        onDismiss = intents.closeControls,
        title = T.cast.bar.castingTo(name = receiverName),
        initialFocus = initial,
        probe = "cast.controls",
    ) {
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(vertical = LocalPlezyDimens.current.focusReach),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            if (playing == null) {
                Text(idleText.orEmpty(), Modifier.padding(horizontal = 8.dp), style = MaterialTheme.typography.bodyLarge, color = PlezyColors.TextMuted)
            } else {
                Heading(playing)
                if (playing.canSeek) SeekBar(playing, intents)
                Transport(playing, intents, initial)
                Options(playing, intents)
                playing.volume?.let { Volume(it, intents.setVolume) }
            }
            Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                if (playing != null) {
                    PlezyButton(T.cast.controls.stop, intents.stop, Modifier.weight(1f).layoutProbe("cast.controls.stop"), icon = PlezyIcons.Stop)
                }
                PlezyButton(
                    T.cast.controls.disconnect,
                    intents.disconnect,
                    Modifier.weight(1f).then(if (playing == null) Modifier.focusRequester(initial) else Modifier).layoutProbe("cast.controls.disconnect"),
                    icon = PlezyIcons.LinkOff,
                )
            }
        }
    }
}

/** The artwork beside the title and subtitle. */
@Composable
private fun Heading(playing: CastNowPlaying) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        Box(Modifier.size(72.dp).clip(RoundedCornerShape(8.dp)).background(PlezyColors.SurfaceHigh), contentAlignment = Alignment.Center) {
            val fallback = @Composable { Icon(PlezyIcons.CastConnected, null, Modifier.size(28.dp), tint = PlezyColors.TextFaint) }
            val artwork = playing.artworkUrl
            if (artwork != null) RemoteImage(artwork, null, Modifier.fillMaxSize(), error = fallback) else fallback()
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(playing.title, style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold), maxLines = 2, overflow = TextOverflow.Ellipsis)
            playing.subtitle?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, maxLines = 2, overflow = TextOverflow.Ellipsis) }
        }
    }
}

/**
 * The seek bar: a drag seeks where it is let go, showing the time under it meanwhile; Left and Right (a remote, the
 * keyboard) skip 10 s back and forward; Up and Down move on.
 */
@Composable
private fun SeekBar(playing: CastNowPlaying, intents: CastIntents) {
    var dragging by remember { mutableStateOf<Float?>(null) }
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    Column(Modifier.fillMaxWidth().padding(horizontal = 8.dp)) {
        PlezySlider(
            value = dragging ?: playing.progress,
            onChange = { dragging = it },
            range = 0f..1f,
            steps = 0,
            label = T.videoControls.timelineSlider,
            modifier = Modifier
                .onPreviewKeyEvent { event ->
                    val forward = when (event.key) {
                        Key.DirectionRight -> !rtl
                        Key.DirectionLeft -> rtl
                        else -> return@onPreviewKeyEvent false
                    }
                    if (event.type == KeyEventType.KeyDown) intents.seekBy(if (forward) SEEK_STEP else -SEEK_STEP)
                    true
                }
                .layoutProbe("cast.controls.seek"),
            onChangeFinished = {
                dragging?.let { intents.seekTo(it * playing.durationSeconds) }
                dragging = null
            },
        )
        Row {
            val shown = dragging?.let { formatTimecode(it * playing.durationSeconds) } ?: playing.position
            Text(shown, style = MaterialTheme.typography.labelMedium, color = PlezyColors.TextMuted)
            Spacer(Modifier.weight(1f))
            Text(playing.duration, style = MaterialTheme.typography.labelMedium, color = PlezyColors.TextMuted)
        }
    }
}

/** How far the controls' skip buttons and keys move. */
private const val SEEK_STEP = 10.0

/** Previous, back 10 s, play or pause in the primary fill, forward 10 s, next; the skips only for what can seek. */
@Composable
private fun Transport(playing: CastNowPlaying, intents: CastIntents, playFocus: FocusRequester) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically) {
        PlezyIconButton(PlezyIcons.SkipPrevious, T.cast.controls.previous, intents.previous, Modifier.layoutProbe("cast.controls.previous"), style = IconButtonStyle.PLAIN, enabled = playing.hasPrevious)
        if (playing.canSeek) {
            PlezyIconButton(PlezyIcons.Replay10, T.cast.controls.seekBack, { intents.seekBy(-SEEK_STEP) }, Modifier.layoutProbe("cast.controls.seekBack"), style = IconButtonStyle.PLAIN)
        }
        PlezySurface(
            onClick = intents.togglePause,
            modifier = Modifier.size(64.dp).focusRequester(playFocus).layoutProbe("cast.controls.playPause"),
            shape = CircleShape,
            color = MaterialTheme.colorScheme.primary,
            contentColor = PlezyColors.OnPrimary,
            contentAlignment = Alignment.Center,
        ) {
            if (playing.buffering) {
                CircularProgressIndicator(Modifier.size(24.dp), color = LocalContentColor.current, strokeWidth = 2.5.dp)
            } else {
                Icon(if (playing.paused) PlezyIcons.PlayArrow else PlezyIcons.Pause, if (playing.paused) T.common.play else T.common.pause, Modifier.size(32.dp))
            }
        }
        if (playing.canSeek) {
            PlezyIconButton(PlezyIcons.Forward10, T.cast.controls.seekForward, { intents.seekBy(SEEK_STEP) }, Modifier.layoutProbe("cast.controls.seekForward"), style = IconButtonStyle.PLAIN)
        }
        PlezyIconButton(PlezyIcons.SkipNext, T.cast.controls.next, intents.next, Modifier.layoutProbe("cast.controls.next"), style = IconButtonStyle.PLAIN, enabled = playing.hasNext)
    }
}

/** The audio, subtitle and quality choices the receiver offers, one row each showing the one in effect. */
@Composable
private fun Options(playing: CastNowPlaying, intents: CastIntents) {
    val rows = listOfNotNull(
        OptionRow(T.cast.controls.audio, PlezyIcons.Audiotrack, playing.audioTracks, intents.selectAudio, "audio").takeIf { it.options.isNotEmpty() },
        OptionRow(T.cast.controls.subtitles, PlezyIcons.Subtitles, playing.subtitleTracks, intents.selectSubtitle, "subtitles").takeIf { it.options.isNotEmpty() },
        OptionRow(T.cast.controls.quality, PlezyIcons.Tune, playing.qualities, intents.selectQuality, "quality").takeIf { it.options.isNotEmpty() },
    )
    if (rows.isEmpty()) return
    RowGroup(Modifier.padding(horizontal = 8.dp)) {
        rows.forEachIndexed { index, row -> OptionChoice(row, groupShape(index, rows.size)) }
    }
}

private class OptionRow(val title: String, val icon: ImageVector, val options: List<CastOption>, val onPick: (String) -> Unit, val probe: String)

/** One of [Options]' rows: the choice in effect as its value; a pick from its menu selects it. */
@Composable
private fun OptionChoice(row: OptionRow, shape: Shape) {
    var open by remember { mutableStateOf(false) }
    Box {
        GroupRow(
            row.title,
            onClick = { open = true },
            modifier = Modifier.layoutProbe("cast.controls.${row.probe}"),
            shape = shape,
            value = row.options.firstOrNull { it.selected }?.label,
            icon = row.icon,
        )
        ChoiceMenu(
            expanded = open,
            onDismiss = { open = false },
            title = row.title,
            choices = row.options.map { MenuChoice(it.label, it.selected, detail = it.detail) },
            onPick = { row.onPick(row.options[it].key) },
            probe = "cast.controls.${row.probe}",
        )
    }
}

/** The receiver's volume: a drag sets it where it is let go; Left and Right step it 5 %. */
@Composable
private fun Volume(volume: Int, onChange: (Int) -> Unit) {
    var dragging by remember { mutableStateOf<Float?>(null) }
    val value = dragging ?: volume.toFloat()
    Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(if (volume == 0) PlezyIcons.VolumeOff else PlezyIcons.VolumeUp, contentDescription = null, tint = PlezyColors.TextMuted)
        PlezySlider(
            value = value,
            onChange = { dragging = it },
            range = 0f..100f,
            steps = 0,
            label = T.cast.controls.volume,
            modifier = Modifier.weight(1f).sliderKeys(value, 0f..100f) { onChange(it.toInt()) }.layoutProbe("cast.controls.volume"),
            onChangeFinished = {
                dragging?.let { onChange(it.toInt()) }
                dragging = null
            },
        )
    }
}
