package com.edde746.plezy.ui.onboarding

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.rightClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.test.withKeyDown
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.onboarding.ConnectionChip
import com.edde746.plezy.presentation.onboarding.ProfileAction
import com.edde746.plezy.presentation.onboarding.ProfilePickerUiState
import com.edde746.plezy.presentation.onboarding.ProfileTileUi
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.focus.FocusInto
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * The profile picker on TV. A required pick asks "Who's watching?" and its first tile takes focus as it shows, and again
 * each time it is mounted anew (a bind rolled back remounts it); once a pick switches the profile, the screen of the new
 * session that replaces it takes focus, and the remote drives that screen. One opened later is titled Switch Profile
 * with a back button. Manage is a button under its tile; the tile's menu (held Select, a right click) offers its other
 * actions, which screen readers find on the tile itself.
 */
@OptIn(ExperimentalTestApi::class)
class ProfilePickerTest {
    private var picked: String? = null
    private val acted = mutableListOf<Pair<String, ProfileAction>>()
    private var sessionClicks = 0

    @Test
    fun theFirstTileTakesFocusAsThePickerShowsAndAfterTwoRemounts() = runComposeUiTest {
        var mount by mutableIntStateOf(0)
        screen(mount = { mount })
        onNode(tile(MAESTRO)).assertIsFocused()

        mount++
        waitForIdle()
        onNode(tile(MAESTRO)).assertIsFocused()
        mount++
        waitForIdle()
        onNode(tile(MAESTRO)).assertIsFocused()
    }

    @Test
    fun afterASwitchTheNewSessionsScreenTakesFocusAndTheRemote() = runComposeUiTest {
        screen()
        press(Key.DirectionRight)
        onNode(tile(GUEST)).assertIsFocused()
        press(Key.DirectionCenter)
        assertEquals("guest", picked)

        onNode(hasText(SESSION) and hasClickAction()).assertIsFocused()
        press(Key.DirectionCenter)
        assertEquals(1, sessionClicks)
    }

    @Test
    fun aRequiredPickAsksWhoIsWatchingAndOneOpenedLaterIsTitledSwitchProfileWithBack() = runComposeUiTest {
        var required by mutableStateOf(true)
        var backs = 0
        screen(state = { state.copy(required = required) }, back = { backs++ })
        onNode(hasText(T.profiles.whosWatching)).assertExists()
        onAllNodes(hasContentDescription(T.nav.back)).assertCountEquals(0)

        required = false
        waitForIdle()
        onNode(hasText(T.screens.switchProfile)).assertExists()
        onAllNodes(hasText(T.profiles.whosWatching)).assertCountEquals(0)
        onNode(hasContentDescription(T.nav.back) and hasClickAction()).performClick()
        assertEquals(1, backs)
        for (name in listOf(MAESTRO, GUEST)) onNode(tile(name)).assertExists()
    }

    @Test
    fun aHeldSelectOpensTheTilesMenuWithItsOtherActions() = runComposeUiTest {
        screen()
        onRoot().performKeyInput { withKeyDown(Key.DirectionCenter) { advanceEventTime(1_000) } }
        waitForIdle()
        for (label in listOf("Show profile link", "Delete", "Sign out")) onNode(hasText(label) and hasClickAction()).assertExists()
        onNode(hasText("Show profile link") and hasClickAction()).performClick()
        waitForIdle()
        assertEquals(listOf("maestro" to ProfileAction.SHOW_LINK), acted)
        assertEquals(null, picked)
    }

    @Test
    fun aRightClickOnTheTileOpensItsMenu() = runComposeUiTest {
        screen()
        onNode(tile(MAESTRO)).performMouseInput { rightClick() }
        waitForIdle()
        onNode(hasText("Sign out") and hasClickAction()).performClick()
        waitForIdle()
        assertEquals(listOf("maestro" to ProfileAction.SIGN_OUT), acted)
    }

    @Test
    fun manageIsAButtonUnderItsTileAndScreenReadersFindTheOtherActionsOnTheTile() = runComposeUiTest {
        screen()
        val actions = onNode(tile(MAESTRO)).fetchSemanticsNode().config[SemanticsActions.CustomActions]
        assertEquals(listOf("Show profile link", "Delete", "Sign out"), actions.map { it.label })
        onAllNodes(hasText("Manage") and hasClickAction()).assertCountEquals(1)
        onNode(hasText("Manage") and hasClickAction()).performClick()
        assertEquals(listOf("maestro" to ProfileAction.MANAGE), acted)
    }

    /** A profile's connections show a line each under its name: a long first one never hides the second. */
    @Test
    fun eachConnectionShowsOnItsOwnLineUnderTheProfile() = runComposeUiTest {
        val jellyfin = "Plezy Test Jellyfin on the living room server"
        val emby = "Plezy Test Emby"
        val chips = listOf(ConnectionChip(BackendKind.JELLYFIN, jellyfin), ConnectionChip(BackendKind.EMBY, emby))
        screen(state = { state.copy(tiles = listOf(state.tiles[0].copy(chips = chips)) + state.tiles.drop(1)) })
        val first = onNode(hasText(jellyfin), useUnmergedTree = true).getUnclippedBoundsInRoot()
        val second = onNode(hasText(emby), useUnmergedTree = true).assertIsDisplayed()
        val layouts = mutableListOf<TextLayoutResult>()
        second.performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(layouts) }
        assertFalse(layouts.single().isLineEllipsized(0) || layouts.single().didOverflowHeight, "\"$emby\" is cut")
        assertTrue(second.getUnclippedBoundsInRoot().top >= first.bottom, "\"$emby\" isn't on a line of its own under \"$jellyfin\"")
    }

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private fun tile(name: String): SemanticsMatcher = hasText(name) and hasClickAction()

    /**
     * A TV window with the picker of [state] (by default the required one of Maestro, active elsewhere, with actions, and
     * Guest), keyed by [mount]; a pick replaces it by the new session's screen, whose button takes focus as it shows, as
     * the app's screens' do.
     */
    private fun ComposeUiTest.screen(mount: () -> Int = { 0 }, state: () -> ProfilePickerUiState = { this@ProfilePickerTest.state }, back: () -> Unit = {}) {
        setContent {
            PlezyTheme {
                Box(Modifier.size(960.dp, 540.dp)) {
                    AdaptiveLayout(FormFactor.TV, Modifier.arrowKeyFocus()) {
                        OverlayHostBox {
                            var picking by remember { mutableStateOf(true) }
                            if (picking) {
                                key(mount()) {
                                    ProfilePickerScreen(
                                        state(),
                                        ProfilePickerIntents(
                                            select = {
                                                picked = it
                                                picking = false
                                            },
                                            act = { id, action -> acted += id to action },
                                            addProfile = {},
                                            back = back,
                                            messageShown = {},
                                            confirm = {},
                                            dismissConfirm = {},
                                            setConfirmToggle = {},
                                            linkCopied = {},
                                            dismissLink = {},
                                        ),
                                    )
                                }
                            } else {
                                val first = remember { FocusRequester() }
                                PlezyButton(SESSION, { sessionClicks++ }, Modifier.focusRequester(first))
                                FocusInto(first, key = Unit)
                            }
                        }
                    }
                }
            }
        }
        waitForIdle()
    }

    private val state = ProfilePickerUiState(
        required = true,
        loading = false,
        tiles = listOf(
            ProfileTileUi("maestro", MAESTRO, null, active = false, locked = false, chips = listOf(ConnectionChip(BackendKind.JELLYFIN, "Test Jellyfin")), hasConnections = true, actions = ProfileAction.entries),
            ProfileTileUi("guest", GUEST, null, active = false, locked = false, chips = emptyList(), hasConnections = false, actions = emptyList()),
        ),
    )
}

private const val MAESTRO = "Maestro"
private const val GUEST = "Guest"
private const val SESSION = "Nine Winters North"
