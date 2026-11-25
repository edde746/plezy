package com.edde746.plezy.ui.player

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.TouchPhase
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A new playback's store takes the last one's place under the player (a stream picked over the player): what the
 * player reports goes to the new store from then on, the controls' height (which keeps subtitles above them) at once,
 * the fingers on the video as they come.
 */
@OptIn(ExperimentalTestApi::class)
class PlayerNewStoreTest {
    /** What a store hears from the player: the controls' height and the touches. */
    private class Store {
        val heights = mutableListOf<Double>()
        val touches = mutableListOf<InputEvent.Touch>()
        val onControlsHeightChanged: (Double) -> Unit = { heights += it }
        val onInput: (InputEvent) -> Boolean = { event ->
            if (event is InputEvent.Touch) touches += event
            event is InputEvent.Touch
        }
    }

    private var store by mutableStateOf(Store())

    /** The new store hears how much of the video the controls cover, though that hasn't changed. */
    @Test
    fun theNewStoreHearsTheControlsHeight() = runComposeUiTest {
        val first = store
        player(FormFactor.DESKTOP)
        runOnIdle { assertTrue(first.heights.isNotEmpty() && first.heights.last() > 0.0, "the first store's controls' heights: ${first.heights}") }

        val second = Store()
        store = second
        runOnIdle { assertEquals(listOf(first.heights.last()), second.heights, "the new store's controls' heights") }
    }

    /** Fingers on the video after the new store came go to it; the last store hears nothing more. */
    @Test
    fun aTouchGoesToTheNewStore() = runComposeUiTest {
        val first = store
        player(FormFactor.HANDHELD)
        pinch()
        runOnIdle { assertTrue(first.touches.isNotEmpty(), "the first store heard no touch") }

        val second = Store()
        store = second
        val heard = first.touches.size
        pinch()
        runOnIdle {
            assertEquals(emptyList(), first.touches.drop(heard), "the last store's touches after the new one came")
            assertEquals(4, second.touches.count { it.phase != TouchPhase.MOVE }, "the new store's touches: ${second.touches}")
        }
    }

    /** Two fingers spreading apart on the video, between the top bar and the controls. */
    private fun ComposeUiTest.pinch() {
        onRoot().performTouchInput {
            val y = height * 0.4f
            down(0, Offset(width * 0.45f, y))
            down(1, Offset(width * 0.55f, y))
            moveTo(0, Offset(width * 0.35f, y))
            moveTo(1, Offset(width * 0.65f, y))
            up(0)
            up(1)
        }
        waitForIdle()
    }

    /** The player on a 960 × 540 dp window of [formFactor], reporting to the current [store]. */
    private fun ComposeUiTest.player(formFactor: FormFactor) = setContent {
        val owner = remember {
            object : NavigationEventDispatcherOwner {
                override val navigationEventDispatcher = NavigationEventDispatcher()
            }
        }
        CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
            PlezyTheme {
                Box(Modifier.size(960.dp, 540.dp)) {
                    AdaptiveLayout(formFactor) {
                        OverlayHostBox {
                            val current = store
                            PlayerScreen(
                                testPlayerState(),
                                MutableStateFlow(testTimeline),
                                testPlayerConfig,
                                onCommand = {},
                                onInput = current.onInput,
                                onTimelineFocusChanged = {},
                                onControlsHeightChanged = current.onControlsHeightChanged,
                            ) {}
                        }
                    }
                }
            }
        }
    }
}
