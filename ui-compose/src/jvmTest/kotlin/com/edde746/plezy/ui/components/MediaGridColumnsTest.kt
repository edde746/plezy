package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * How many columns a media grid has. On TV the cards are at most a width for the density setting and the columns round
 * up, so a 960 dp TV screen (its grid 826 dp wide past the navigation and the screen's padding) holds 7 posters or 4
 * episode thumbnails across, and a 640 dp one (506 dp of grid) 5 and 3; elsewhere the cards are at least a width.
 */
@OptIn(ExperimentalTestApi::class)
class MediaGridColumnsTest {
    @Test
    fun aTvGridAt960HoldsSevenPostersAndFourThumbnails() {
        assertEquals(7, columns(FormFactor.TV, 960.dp, 826.dp, CardShape.POSTER))
        assertEquals(4, columns(FormFactor.TV, 960.dp, 826.dp, CardShape.WIDE))
    }

    @Test
    fun aTvGridAt640HoldsFivePostersAndThreeThumbnails() {
        assertEquals(5, columns(FormFactor.TV, 640.dp, 506.dp, CardShape.POSTER))
        assertEquals(3, columns(FormFactor.TV, 640.dp, 506.dp, CardShape.WIDE))
    }

    @Test
    fun theTvDensitySettingSpansTenToSixPosters() {
        assertEquals(listOf(10, 8, 7, 6, 6), (1..5).map { columns(FormFactor.TV, 960.dp, 826.dp, CardShape.POSTER, it) })
        assertEquals(listOf(6, 5, 4, 4, 3), (1..5).map { columns(FormFactor.TV, 960.dp, 826.dp, CardShape.WIDE, it) })
    }

    @Test
    fun phoneAndDesktopGridsKeepTheirColumns() {
        assertEquals(2, columns(FormFactor.HANDHELD, 360.dp, 328.dp, CardShape.POSTER))
        assertEquals(1, columns(FormFactor.HANDHELD, 360.dp, 328.dp, CardShape.WIDE))
        assertEquals(7, columns(FormFactor.DESKTOP, 1280.dp, 1232.dp, CardShape.POSTER))
        assertEquals(3, columns(FormFactor.DESKTOP, 1280.dp, 1232.dp, CardShape.WIDE))
    }

    /** The columns of a grid [gridWidth] wide of [shape] cards at [density], in a [formFactor] window [windowWidth] wide. */
    private fun columns(formFactor: FormFactor, windowWidth: Dp, gridWidth: Dp, shape: CardShape, density: Int = 3): Int {
        val state = LazyGridState()
        runComposeUiTest {
            val appearance = Appearance.of(AppearanceSettings(libraryDensity = density), formFactor, supporterUnlocked = false)
            val items = (0 until 12).map { MediaCardUi(id = "$it", title = "$it", caption = null, shape = shape, placeholder = PlaceholderKind.MOVIE, artwork = null) }
            setContent {
                PlezyTheme {
                    Box(Modifier.size(windowWidth, 720.dp)) {
                        AdaptiveLayout(formFactor) {
                            Box(Modifier.size(gridWidth, 700.dp)) {
                                MediaGrid(items.size, items::getOrNull, shape, PaddingValues(0.dp), onClick = {}, state = state, appearance = appearance)
                            }
                        }
                    }
                }
            }
            waitForIdle()
        }
        return state.layoutInfo.maxSpan
    }
}
