package com.edde746.plezy.ui.components

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.player.player
import com.edde746.plezy.ui.player.testPlayerState
import kotlin.test.Test

/** A bottom sheet comes to rest once it is open: nothing in it asks for frame after frame. */
@OptIn(ExperimentalTestApi::class)
class SheetRestTest {
    /**
     * An upright phone's player with its options open: the sheet's list, at its top, can't take the scroll focus asks
     * of it for its first row, and the sheet took it instead, sliding down frame after frame without ever bringing the
     * row closer; the UI never came to rest. It now comes to rest (setting the content waits for that).
     */
    @Test
    fun anUprightPhonesPlayerOptionsSheetComesToRest() = runComposeUiTest {
        player(FormFactor.HANDHELD, size = DpSize(360.dp, 780.dp)) { testPlayerState(menu = PlayerMenu.OPTIONS) }
        waitForIdle()
    }
}
