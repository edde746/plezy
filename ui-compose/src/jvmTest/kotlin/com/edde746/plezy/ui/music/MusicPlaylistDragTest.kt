package com.edde746.plezy.ui.music

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.detail.DetailFixture
import com.edde746.plezy.ui.music.MusicPlaylistFocusTest.Companion.PLAYLIST
import com.edde746.plezy.ui.music.MusicPlaylistFocusTest.Companion.SERVER
import com.edde746.plezy.ui.music.MusicPlaylistFocusTest.Companion.musicScreens
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Dragging an audio playlist's track by its handle on a phone at a large font scale, where a long title wraps over
 * several lines, so the rows differ in height.
 */
@OptIn(ExperimentalTestApi::class)
class MusicPlaylistDragTest {
    private val moves = mutableListOf<Pair<String?, Int>>()
    private val store = musicScreens(listOf(track(1, "Short"), track(2, LONG), track(3, "Third"), track(4, "Fourth"))) { item, index ->
        moves += item.title to index
    }.playlist(Route.MusicPlaylist(SERVER, PLAYLIST)) { _, _ -> }

    @Test
    fun aShortTrackDraggedOntoTheTallTrackBelowDropsOnePlaceLowerAndIsSaved() = runComposeUiTest {
        setContent {
            val owner = remember {
                object : NavigationEventDispatcherOwner {
                    override val navigationEventDispatcher = NavigationEventDispatcher()
                }
            }
            CompositionLocalProvider(
                LocalNavigationEventDispatcherOwner provides owner,
                LocalDensity provides Density(LocalDensity.current.density, fontScale = 2f),
            ) {
                PlezyTheme {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        CompositionLocalProvider(LocalAppearance provides Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false)) {
                            OverlayHostBox {
                                Box(Modifier.requiredSize(411.dp, 3000.dp)) { MusicPlaylistScreen(store, DetailFixture.movie(true).menu, onBack = {}) }
                            }
                        }
                    }
                }
            }
        }
        waitForIdle()
        store.edit(true)
        waitForIdle()
        val shortRow = onNode(hasText("Short") and hasClickAction()).getBoundsInRoot().let { it.bottom - it.top }
        val tallRow = onNode(hasText(LONG) and hasClickAction()).getBoundsInRoot().let { it.bottom - it.top }
        assertTrue(tallRow >= shortRow * 2, "the long title's row ($tallRow) is far taller than a short one ($shortRow)")
        val short = onNode(handle("Short")).getBoundsInRoot()
        val tall = onNode(handle(LONG)).getBoundsInRoot()

        // From the short row's middle to the tall row's middle: onto the row below.
        val distance = (tall.top + tall.bottom) / 2 - (short.top + short.bottom) / 2
        onNode(handle("Short")).performTouchInput {
            down(center)
            repeat(10) { moveBy(Offset(0f, distance.toPx() / 10)) }
            up()
        }
        waitForIdle()
        assertEquals(listOf(LONG, "Short", "Third", "Fourth"), store.state.value.rows.map { it.title })
        assertEquals(listOf<Pair<String?, Int>>("Short" to 1), moves)
    }

    private fun handle(title: String) = hasContentDescription(T.libraries.dragToReorderNamed(title))

    private companion object {
        const val LONG = "A Track Whose Title Runs Long Enough To Wrap Over Several Lines At A Large Font Scale On A Phone Screen, " +
            "Then Further Still"

        fun track(index: Int, title: String) =
            MediaItem(id = "t$index", backend = BackendKind.JELLYFIN, kind = MediaKind.TRACK, title = title, serverId = SERVER, index = index)
    }
}
