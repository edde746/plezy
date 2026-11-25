package com.edde746.plezy.ui.playlists

import androidx.compose.ui.geometry.Offset
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
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
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.playlists.PlaylistDetailStore
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.playlists.PlaylistFocusTest.Companion.PLAYLIST
import com.edde746.plezy.ui.playlists.PlaylistFocusTest.Companion.SERVER
import com.edde746.plezy.ui.playlists.PlaylistFocusTest.Companion.playlistServer
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Dragging a playlist's row by its handle on a phone at a large font scale, where an episode's row stacks its wide
 * artwork over its text and a track's row keeps its square beside it, so the rows differ in height.
 */
@OptIn(ExperimentalTestApi::class)
class PlaylistDragTest {
    private val moves = mutableListOf<Pair<String?, Int>>()
    private val store = PlaylistDetailStore(
        client = playlistServer(
            listOf(track("a", "Short A"), episode("w", WIDE), track("b", "Short B"), track("c", "Short C")),
        ) { item, index -> moves += item.title to index },
        playlistId = PLAYLIST,
        cardOptions = { CardOptions() },
        play = { _, _, _ -> },
        delete = { _, _ -> },
        openMenu = {},
        back = {},
        message = { _, _ -> },
        parentScope = CoroutineScope(Dispatchers.Unconfined),
    )

    @Test
    fun aShortRowDraggedOntoTheTallRowBelowDropsOnePlaceLowerAndIsSaved() = runComposeUiTest {
        store.edit(true)
        setContent {
            CompositionLocalProvider(LocalDensity provides Density(LocalDensity.current.density, fontScale = 2f)) {
                PlezyTheme {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        CompositionLocalProvider(LocalAppearance provides Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false)) {
                            Box(Modifier.requiredSize(411.dp, 3000.dp)) {
                                val state by store.state.collectAsState()
                                PlaylistRows(state.rows, state.editing, state.editable, state.moving, store, rememberFocusMemory(), state.loadingMore, state.moreError, remember { EditHandles() })
                            }
                        }
                    }
                }
            }
        }
        waitForIdle()
        val shortRow = onNode(hasText("Short A") and hasClickAction()).getBoundsInRoot().let { it.bottom - it.top }
        val wideRow = onNode(hasText(WIDE) and hasClickAction()).getBoundsInRoot().let { it.bottom - it.top }
        assertTrue(wideRow >= shortRow * 2, "the wide row ($wideRow) is far taller than a short one ($shortRow)")
        val short = onNode(handle("Short A")).getBoundsInRoot()
        val wide = onNode(handle(WIDE)).getBoundsInRoot()

        // From the short row's middle to the wide row's middle: onto the row below.
        val distance = (wide.top + wide.bottom) / 2 - (short.top + short.bottom) / 2
        onNode(handle("Short A")).performTouchInput {
            down(center)
            repeat(10) { moveBy(Offset(0f, distance.toPx() / 10)) }
            up()
        }
        waitForIdle()
        assertEquals(listOf(WIDE, "Short A", "Short B", "Short C"), store.state.value.rows.map { it.card.title })
        assertEquals(listOf<Pair<String?, Int>>("Short A" to 1), moves)
    }

    private fun handle(title: String) = hasContentDescription(T.libraries.dragToReorderNamed(title))

    private companion object {
        const val WIDE = "An Episode Whose Title Runs Long"

        fun track(id: String, title: String) = MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.TRACK, title = title, serverId = SERVER)

        fun episode(id: String, title: String) =
            MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE, title = title, grandparentTitle = title, serverId = SERVER)
    }
}
