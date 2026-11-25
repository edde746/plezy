package com.edde746.plezy.ui.adaptive

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The window the screens adapt to ([AdaptiveLayout]) on a car's display, 1080 pixels across at a density of 0.75: a
 * new density over the same pixels (the car's Display Scale changed) resizes it at once, its width class with it.
 */
@OptIn(ExperimentalTestApi::class)
class AdaptiveDensityTest {
    @Test
    fun aNewDensityOverTheSamePixelsResizesTheWindow() = runComposeUiTest {
        var density by mutableFloatStateOf(0.75f * 1.35f)
        var width = 0f
        var widthClass: WidthClass? = null
        setContent {
            CompositionLocalProvider(LocalDensity provides Density(0.75f)) {
                // 1080 by 600 pixels.
                Box(Modifier.requiredSize(1440.dp, 800.dp)) {
                    CompositionLocalProvider(LocalDensity provides Density(density)) {
                        AdaptiveLayout(FormFactor.HANDHELD) {
                            width = LocalWindowSize.current.value.width.value
                            widthClass = LocalWindowLayout.current.widthClass
                        }
                    }
                }
            }
        }
        waitForIdle()
        assertEquals(1440 / 1.35f, width, 0.01f)
        assertEquals(WidthClass.EXPANDED, widthClass)

        density = 0.75f * 2f
        waitForIdle()
        assertEquals(720f, width, 0.01f)
        assertEquals(WidthClass.MEDIUM, widthClass)
    }
}
