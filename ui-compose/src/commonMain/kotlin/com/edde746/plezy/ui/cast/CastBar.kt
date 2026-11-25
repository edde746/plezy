package com.edde746.plezy.ui.cast

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.cast.CastSenderUiState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The now-playing bar while casting ([CastSenderUiState.casting]), docked where the music mini-player is (above the
 * bottom bar on phones, at the content's foot beside the rail on wider windows; on TV the rail's cast item,
 * [castRailItem], stands for it): what the receiver plays as a thin progress line along its top edge, the artwork, the
 * title over "Casting to <device>" (nothing playing: the device over "Ready to cast"), then play or pause while
 * something plays and Disconnect. A tap opens the control sheet. It expands in and collapses out.
 *
 * Harness names `cast.bar`, `cast.bar.title`, `cast.bar.playPause`, `cast.bar.disconnect`.
 */
@Composable
fun CastBar(state: CastSenderUiState, intents: CastIntents) {
    AnimatedVisibility(state.casting, enter = expandVertically(tween(200)), exit = shrinkVertically(tween(150))) {
        val target = state.target ?: return@AnimatedVisibility
        val playing = state.nowPlaying
        Column(Modifier.fillMaxWidth().background(PlezyColors.Surface)) {
            LinearProgressIndicator(
                progress = { playing?.progress ?: 0f },
                modifier = Modifier.fillMaxWidth().height(2.dp),
                color = MaterialTheme.colorScheme.primary,
                trackColor = PlezyColors.Hairline,
                drawStopIndicator = {},
                gapSize = 0.dp,
            )
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(64.dp)
                    .clickable(onClickLabel = T.cast.title, role = Role.Button, onClick = intents.openControls)
                    .layoutProbe("cast.bar"),
            ) {
                Row(Modifier.fillMaxSize().padding(start = 12.dp, end = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(44.dp).clip(RoundedCornerShape(8.dp)).background(PlezyColors.SurfaceHigh), contentAlignment = Alignment.Center) {
                        val fallback = @Composable { Icon(PlezyIcons.CastConnected, null, Modifier.size(20.dp), tint = PlezyColors.TextFaint) }
                        val artwork = playing?.artworkUrl
                        if (artwork != null) RemoteImage(artwork, null, Modifier.fillMaxSize(), error = fallback) else fallback()
                    }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(
                            // Nothing playing: the device's name over "Ready to cast", not "Ready to cast" over "Casting to".
                            playing?.title ?: target.name,
                            Modifier.layoutProbe("cast.bar.title", reportsFocus = false),
                            style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                        Text(
                            if (playing != null) T.cast.bar.castingTo(name = target.name) else state.barIdleText.orEmpty(),
                            style = MaterialTheme.typography.bodySmall,
                            color = PlezyColors.TextMuted,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    if (playing != null) {
                        PlezyIconButton(
                            if (playing.paused) PlezyIcons.PlayArrow else PlezyIcons.Pause,
                            if (playing.paused) T.common.play else T.common.pause,
                            intents.togglePause,
                            Modifier.layoutProbe("cast.bar.playPause"),
                            style = IconButtonStyle.PLAIN,
                        )
                    }
                    PlezyIconButton(PlezyIcons.LinkOff, T.cast.controls.disconnect, intents.disconnect, Modifier.layoutProbe("cast.bar.disconnect"), style = IconButtonStyle.PLAIN)
                }
            }
        }
    }
}
