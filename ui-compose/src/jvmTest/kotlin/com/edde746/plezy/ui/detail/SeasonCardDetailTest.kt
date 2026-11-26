package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.libraries.detailRouteFor
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A season card opens its show's page with that season's chip selected, never a page of the season's own, whether the
 * card names the show or not; Back from it returns to where the card was.
 */
@OptIn(ExperimentalTestApi::class)
class SeasonCardDetailTest {
    @Test
    fun `a season card opens its show with that season selected and back returns`() = runComposeUiTest {
        val fixture = DetailFixture.show(tv = false) { seasons -> detailRouteFor(seasons[1]) as Route.MediaDetail }
        assertEquals(Route.MediaDetail(ServerId(DetailFixture.SERVER), "show", initialSeasonId = "s2"), fixture.route)
        detail(fixture)
        assertShowAtSeasonTwo(fixture)
        onNodeWithContentDescription(T.nav.back).performClick()
        runOnIdle { assertEquals(Route.Home, fixture.navigator.current) }
    }

    @Test
    fun `a season card naming no show opens its show with that season selected`() = runComposeUiTest {
        val fixture = DetailFixture.show(tv = false) { seasons -> detailRouteFor(seasons[1].copy(parentId = null)) as Route.MediaDetail }
        assertEquals("s2", fixture.route.itemId)
        detail(fixture)
        assertShowAtSeasonTwo(fixture)
    }

    private fun ComposeUiTest.assertShowAtSeasonTwo(fixture: DetailFixture) {
        runOnIdle { assertEquals(MediaKind.SHOW, fixture.store.state.value.kind) }
        onAllNodesWithText("Severance").onFirst().assertExists()
        onNode(hasText("Season 2") and hasClickAction()).assertIsSelected()
        onNode(hasText("Season 1") and hasClickAction()).assertIsNotSelected()
        onAllNodesWithText("1. Episode 1").onFirst().assertExists()
        runOnIdle { assertEquals(listOf("s2e1", "s2e2", "s2e3"), fixture.store.state.value.episodes!!.rows.map { it.id }) }
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
            ) {
                PlezyTheme {
                    Box(Modifier.size(411.dp, 2000.dp)) {
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
