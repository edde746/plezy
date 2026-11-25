package com.edde746.plezy.ui.components

import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.delay
import androidx.compose.animation.core.Animatable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.key
import androidx.compose.runtime.rememberCoroutineScope
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.presentation.browse.BackdropRotation
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.focus.LocalScreenFocus
import com.edde746.plezy.ui.image.LocalArtworkDisplay
import com.edde746.plezy.ui.image.RemoteImage
import kotlinx.coroutines.launch


/** Whether the app can be seen (in front, its window not minimized): backdrops hold still while it can't. */
val LocalAppVisible = compositionLocalOf { true }

/**
 * An item's backgrounds ([backdrops]) filling the bounds, the next every 10 s while [rotate] ([BackdropRotation.rotates]:
 * and the screen is on view ([LocalScreenFocus]), the app in sight, not on the reduced effects tier nor under reduced
 * motion), each fading in over the last (280 ms; at once on the reduced tier or under reduced motion) once it has
 * loaded: the last stays until then, and one that fails is skipped, the turn moving on at once. Without any, or once
 * every one has failed, [fallback] in their place; with no fallback either, the last fades out. A new [key] (the item)
 * starts again at its first background, fading in over the last item's. [fill] under them. [image] draws one background
 * and tells whether it loaded (by default a [RemoteImage] of it).
 */
@Composable
fun CyclingBackdrop(
    key: Any?,
    backdrops: List<Artwork>,
    modifier: Modifier = Modifier,
    rotate: Boolean = true,
    fallback: Artwork? = null,
    fill: Color = PlezyColors.Surface,
    image: @Composable (artwork: Artwork, modifier: Modifier, onResult: (Artwork, Boolean) -> Unit) -> Unit = { artwork, layer, onResult ->
        RemoteImage(artwork, contentDescription = null, modifier = layer, onResult = onResult)
    },
) {
    val reducedTier = LocalArtworkDisplay.current.reduced
    // Only a backdrop that can rotate reads the motion setting; a single one stays still anyway.
    val reducedMotion = rotate && backdrops.size > 1 && LocalPlezyPlatform.current.reducedMotion
    val screen = LocalScreenFocus.current
    val onView by remember(screen) { derivedStateOf { screen?.onView?.invoke() != false } }
    var rotation by remember(key, backdrops) { mutableStateOf(BackdropRotation(backdrops.size)) }
    if (BackdropRotation.rotates(rotation, rotate && onView, LocalAppVisible.current, reducedTier, reducedMotion)) {
        // Restarted by every turn and failure; leaving the front stops it, coming back starts the interval over.
        LaunchedEffect(rotation) {
            delay(BackdropRotation.ROTATION_MILLIS)
            rotation = rotation.advance()
        }
    }
    val target = rotation.current
    val incoming = target?.let(backdrops::getOrNull) ?: fallback
    // The background that has drawn: it stays under the incoming one until that has loaded and faded in, and fades out
    // when nothing comes in.
    var settled by remember { mutableStateOf<Artwork?>(null) }
    val fade = BackdropRotation.fadeMillis(reducedTier, reducedMotion)
    val scope = rememberCoroutineScope()
    Box(modifier.background(fill)) {
        for (layer in listOfNotNull(settled, incoming.takeIf { it != settled })) {
            key(layer) {
                val alpha = remember { Animatable(if (layer == settled) 1f else 0f) }
                // Nothing coming in: it fades out (and leaves); coming in again before it has, it fades back.
                val goal = when (incoming) {
                    null -> 0f
                    layer -> 1f
                    else -> null
                }
                if (layer == settled && goal != null) {
                    LaunchedEffect(goal) {
                        alpha.animateTo(goal, tween(fade))
                        if (goal == 0f) settled = null
                    }
                }
                image(layer, Modifier.fillMaxSize().graphicsLayer { this.alpha = alpha.value }) { tried, loaded ->
                    if (tried == incoming && tried != settled) {
                        if (loaded) {
                            scope.launch {
                                alpha.animateTo(1f, tween(fade))
                                settled = tried
                            }
                        } else {
                            target?.let { rotation = rotation.fail(it) }
                        }
                    }
                }
            }
        }
    }
}
