package com.edde746.plezy.ui.components

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.TvFrame
import kotlin.test.Test
import kotlin.test.assertTrue

/** On TV a media item's menu docks along the right edge, as the player's panels do, with its title at the top. */
@OptIn(ExperimentalTestApi::class)
class MediaMenuPanelTest {
    @Test
    fun onTvAMediaItemsMenuIsThePanelAlongTheRightEdge() = runComposeUiTest {
        setContent {
            TvFrame {
                ItemMenu(true, {}, (1..12).map { ItemMenuEntry("Entry $it") {} }, probe = "menu", title = "Two Versions", media = true)
            }
        }
        val title = onNode(hasText("Two Versions")).getBoundsInRoot()
        // The 960 dp frame's panel is 480 dp wide, at its end.
        assertTrue(title.left >= 480.dp, "the menu's title starts at ${title.left}, not in the right edge's panel")
        assertTrue(title.top <= 64.dp, "the menu's title is at ${title.top}, not at the top of a full-height panel")
    }
}
