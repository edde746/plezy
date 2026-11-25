package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeUp
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * A phone's detail as it scrolls: the bar over its top stays hidden while the title shows and shows the title once it
 * has gone under the back button, laid over the page, the back button staying on it.
 */
@OptIn(ExperimentalTestApi::class)
class DetailTitleBarTest {
    private val placed = mutableMapOf<String, Rect>()
    private val probe = LayoutProbe { name, bounds -> if (bounds == null) placed.remove(name) else placed[name] = bounds }

    @Test
    fun theTitleBarShowsOnceTheTitleHasScrolledUnderBackWithBackOnIt() = runComposeUiTest {
        // Enough episodes for the page to scroll its title well past the bar.
        detail(DetailFixture.show(tv = false, episodes = 12))
        val title = checkNotNull(placed["detail.title"])
        assertNull(placed["detail.titleBar"], "the bar shows over the title")
        assertNotNull(placed["detail.back"])
        assertNotNull(placed["detail.play"])

        onRoot().performTouchInput { swipeUp(startY = bottom - 20f, endY = title.bottom, durationMillis = 1000) }
        waitForIdle()

        val bar = assertNotNull(placed["detail.titleBar"], "no bar once the title has gone")
        val back = assertNotNull(placed["detail.back"], "the back button left the bar")
        assertEquals(0f, bar.top)
        assertTrue(back.top >= bar.top && back.bottom <= bar.bottom, "back $back outside the bar $bar")
    }

    private fun ComposeUiTest.detail(fixture: DetailFixture) {
        setContent {
            val owner = remember {
                object : NavigationEventDispatcherOwner {
                    override val navigationEventDispatcher = NavigationEventDispatcher()
                }
            }
            CompositionLocalProvider(
                LocalNavigationEventDispatcherOwner provides owner,
                LocalAppearance provides Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false),
                LocalLayoutProbe provides probe,
            ) {
                PlezyTheme {
                    Box(Modifier.size(411.dp, 760.dp)) {
                        AdaptiveLayout(FormFactor.HANDHELD) {
                            OverlayHostBox {
                                val state by fixture.store.state.collectAsState()
                                DetailContent(state, fixture.intents)
                            }
                        }
                    }
                }
            }
        }
        waitForIdle()
    }
}
