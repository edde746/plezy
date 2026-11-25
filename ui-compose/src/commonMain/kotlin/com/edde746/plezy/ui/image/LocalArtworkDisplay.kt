package com.edde746.plezy.ui.image

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import com.edde746.plezy.image.ArtworkDisplay

/**
 * The display artwork is fetched for: its density, the visual effects tier and the size budget
 * ([ArtworkDisplay.of]), provided at the root of the app. Without one (a test), 1 pixel per dp on the full tier.
 */
val LocalArtworkDisplay = staticCompositionLocalOf { ArtworkDisplay() }

/**
 * The reduced visual effects tier ([ArtworkDisplay.reduced]): no focus glow, animations that end at once, backdrops
 * that neither rotate nor blur.
 */
val reducedEffects: Boolean
    @Composable @ReadOnlyComposable
    get() = LocalArtworkDisplay.current.reduced

/** [millis] on the full visual effects tier, 0 on the reduced one ([reducedEffects]). */
@Composable
@ReadOnlyComposable
fun effectMillis(millis: Int): Int = if (reducedEffects) 0 else millis
