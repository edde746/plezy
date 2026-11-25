package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertHeightIsEqualTo
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.assertWidthIsEqualTo
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.downloads.DownloadsContent
import com.edde746.plezy.presentation.downloads.DownloadsGrouping
import com.edde746.plezy.presentation.downloads.DownloadsOptionsState
import com.edde746.plezy.presentation.downloads.DownloadsTab
import com.edde746.plezy.presentation.downloads.DownloadsTabState
import com.edde746.plezy.presentation.downloads.DownloadsUiState
import com.edde746.plezy.presentation.downloads.MusicRow
import com.edde746.plezy.presentation.downloads.downloadCard
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/** The Downloads screen's bar, tabs and titles with a keyboard or remote, on a desktop-sized window. */
@OptIn(ExperimentalTestApi::class)
class DownloadsScreenFocusTest {
    private var syncRulesOpened = 0
    private val actions = DownloadsScreenActions(syncRules = { syncRulesOpened++ })

    /** Right from the last tab (Music) reaches Active sync rules, and Select opens them. */
    @Test
    fun rightFromTheLastTabFocusesAndOpensSyncRules() = runComposeUiTest {
        screen(DownloadsUiState())
                onAllNodesWithText(DownloadsTab.MUSIC.label)[0].requestFocus()
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        onNodeWithContentDescription(DownloadsUiState().syncRulesLabel).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.Enter) }
        runOnIdle { assertEquals(1, syncRulesOpened) }
    }

    /** Retry failed shows only while a download failed, and passes focus on to Active sync rules. */
    @Test
    fun retryFailedShowsOnlyWhileADownloadFailedAndHandsFocusToSyncRules() = runComposeUiTest {
        val failed = DownloadsUiState(retryFailed = true)
        var state by androidx.compose.runtime.mutableStateOf(failed)
        setContent { frame { DownloadsContentView(state, { downloadCard(it, null) }, { null }, { null }, actions) } }
                onAllNodesWithText(DownloadsTab.MUSIC.label)[0].requestFocus()
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        onNodeWithContentDescription(failed.retryFailedLabel).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        onNodeWithContentDescription(failed.syncRulesLabel).assertIsFocused()
        state = DownloadsUiState(retryFailed = false)
        waitForIdle()
        onNodeWithContentDescription(failed.retryFailedLabel).assertDoesNotExist()
    }

    /** The grid view shows every downloaded title as a card; Up from the first card goes back to the bar. */
    @Test
    fun gridViewShowsTheDownloadedCardsAndUpReturnsToTheTabs() = runComposeUiTest {
        screen(moviesState(4))
        assertEquals(4, (0 until 4).sumOf { onAllNodesWithContentDescription("Downloaded Movie $it", substring = true).fetchSemanticsNodes().size })
                onNodeWithContentDescription("Downloaded Movie 0", substring = true).requestFocus()
        onRoot().performKeyInput { pressKey(Key.DirectionUp) }
        assertFocusInTheBar()
    }

    /** The list view shows every downloaded title as a row; Up from the first row goes back to the bar. */
    @Test
    fun listViewShowsTheDownloadedRowsAndUpReturnsToTheTabs() = runComposeUiTest {
        screen(moviesState(3), list = true)
        repeat(3) { onNodeWithContentDescription("Downloaded Movie $it", substring = true).assertExists() }
                onNodeWithContentDescription("Downloaded Movie 0", substring = true).requestFocus()
        onRoot().performKeyInput { pressKey(Key.DirectionUp) }
        assertFocusInTheBar()
    }

    /** A downloaded album's header shows its title over its stored artwork, bounded to 120 dp square. */
    @Test
    fun albumHeaderShowsItsArtworkBounded() = runComposeUiTest {
        val album = MediaItem(id = "album", backend = BackendKind.PLEX, kind = MediaKind.ALBUM, title = "Downloaded Album", serverId = SERVER)
        val track = MediaItem(id = "track", backend = BackendKind.PLEX, kind = MediaKind.TRACK, title = "Track", serverId = SERVER)
        val content = DownloadsContent.Albums(listOf(MusicRow.Album(album, null), MusicRow.Track(listOf(track), 0)))
        screen(tabState(DownloadsTab.MUSIC, DownloadsGrouping.ALBUMS, content))
        onNodeWithText("Downloaded Album").assertExists()
        onNodeWithTag(ALBUM_ART_TAG, useUnmergedTree = true).assertWidthIsEqualTo(120.dp).assertHeightIsEqualTo(120.dp)
    }

    /** Manage without downloads shows the titles tabs' empty state: its title and what shows there. */
    @Test
    fun manageWithoutDownloadsShowsTheTabsEmptyState() = runComposeUiTest {
        screen(DownloadsUiState())
        val empty = DownloadsContent.Empty(filtered = false)
        onNodeWithText(empty.title).assertExists()
        onNodeWithText(empty.description!!).assertExists()
    }

    /** Focus is on a control of the bar (a tab or an option chip), above the titles. */
    private fun ComposeUiTest.assertFocusInTheBar() {
        val focused = onNode(isFocused()).fetchSemanticsNode()
        val bar = onAllNodesWithText(DownloadsTab.MANAGE.label)[0].fetchSemanticsNode().boundsInRoot
        assertEquals(bar.center.y, focused.boundsInRoot.center.y, 1f, "focus is in the bar row")
    }

    private fun movie(index: Int) = MediaItem(
        id = "movie-$index", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = "Downloaded Movie $index", serverId = SERVER,
    )

    private fun moviesState(count: Int) =
        tabState(DownloadsTab.MOVIES, DownloadsGrouping.MOVIES, DownloadsContent.Grid((0 until count).map(::movie)))

    private fun tabState(tab: DownloadsTab, grouping: DownloadsGrouping, content: DownloadsContent) = DownloadsUiState(
        selected = tab,
        tab = DownloadsTabState(tab, DownloadsOptionsState(grouping), content),
    )

    private fun ComposeUiTest.screen(state: DownloadsUiState, list: Boolean = false) = setContent {
        frame(list) { DownloadsContentView(state, { downloadCard(it, null) }, { null }, { null }, actions) }
    }

    @androidx.compose.runtime.Composable
    private fun frame(list: Boolean = false, content: @androidx.compose.runtime.Composable () -> Unit) {
        PlezyTheme {
            Box(Modifier.size(1200.dp, 744.dp).background(Color.Black)) {
                AdaptiveLayout(FormFactor.DESKTOP, Modifier.arrowKeyFocus()) {
                    val appearance = Appearance.of(AppearanceSettings(viewMode = if (list) ViewMode.LIST else ViewMode.GRID), FormFactor.DESKTOP, supporterUnlocked = false)
                    CompositionLocalProvider(LocalAppearance provides appearance) { content() }
                }
            }
        }
    }

    private companion object {
        const val SERVER = "downloads-layout-server"
    }
}
