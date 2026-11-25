package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.probe.FocusedProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A phone's detail under a keyboard's arrows: where Up and Down from the action row go, the walk back up from the
 * sections below to Play with the page at its top, and the back button leaving only while the detail is on top.
 */
@OptIn(ExperimentalTestApi::class)
class DetailPageFocusTest {
    private val probe = FocusedProbe()

    @Test
    fun downFromPlayReachesTheOverviewAndUpComesBack() = runComposeUiTest {
        detail(DetailFixture.movie(tv = false))
        assertEquals("detail.play", probe.focused)
        press(Key.DirectionDown)
        assertEquals("detail.overviewMore", probe.focused)
        press(Key.DirectionUp)
        assertEquals("detail.play", probe.focused)
    }

    @Test
    fun withAnOverviewThatFitsDownFromPlayReachesTheFirstSection() = runComposeUiTest {
        detail(DetailFixture.movie(tv = false, overview = "A linguist talks to the visitors."))
        assertEquals("detail.play", probe.focused)
        press(Key.DirectionDown)
        assertEquals("detail.cast.0", probe.focused)
    }

    @Test
    fun theExtrasFollowTheCastInTheArrowKeyOrder() = runComposeUiTest {
        detail(DetailFixture.movie(tv = false, overview = "A linguist talks to the visitors."))
        press(Key.DirectionDown)
        assertEquals("detail.cast.0", probe.focused)
        press(Key.DirectionDown)
        assertEquals("detail.extra.0", probe.focused)
        press(Key.DirectionUp)
        assertEquals("detail.cast.0", probe.focused)
    }

    @Test
    fun upFromTheCastWalksBackThroughTheSeasonsAndTheOverviewToPlayAtThePagesTop() = runComposeUiTest {
        detail(DetailFixture.show(tv = false, episodes = 4))
        assertEquals("detail.play", probe.focused)
        val titleTop = onAllNodesWithText("Severance").onFirst().getBoundsInRoot().top
        repeat(MAX_STEPS) { if (probe.focused != "detail.cast.0") press(Key.DirectionDown) }
        assertEquals("detail.cast.0", probe.focused)

        val walk = mutableListOf<String>()
        repeat(MAX_STEPS) {
            if (probe.focused == "detail.play") return@repeat
            press(Key.DirectionUp)
            // An episode row and its ⋮ are one stop of the walk.
            probe.focused?.removeSuffix(".menu")?.takeIf { it != walk.lastOrNull() }?.let(walk::add)
        }
        assertEquals(
            listOf("detail.episode.s1e4", "detail.episode.s1e3", "detail.episode.s1e2", "detail.episode.s1e1", "detail.season.0", "detail.overviewMore", "detail.play"),
            walk,
        )
        assertEquals(titleTop, onAllNodesWithText("Severance").onFirst().getBoundsInRoot().top, "the page didn't come back to its top")
    }

    @Test
    fun theBackButtonLeavesOnlyWhileTheDetailIsTheTopScreen() = runComposeUiTest {
        val fixture = DetailFixture.movie(tv = false)
        detail(fixture)
        val child = Route.Person(ServerId(DetailFixture.SERVER), "p1", "Amy Adams", null, "Louise Banks")
        runOnIdle { fixture.navigator.navigate(child) }
        onNodeWithContentDescription(T.nav.back).performClick()
        runOnIdle { assertEquals(child, fixture.navigator.current) }
        runOnIdle { fixture.navigator.back() }
        onNodeWithContentDescription(T.nav.back).performClick()
        runOnIdle { assertEquals(Route.Home, fixture.navigator.current) }
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
                        AdaptiveLayout(FormFactor.HANDHELD, Modifier.arrowKeyFocus()) {
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

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private companion object {
        /** More presses than any walk here takes. */
        const val MAX_STEPS = 20
    }
}
