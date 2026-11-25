package com.edde746.plezy.ui.settings

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.settings.SettingCheckOption
import com.edde746.plezy.presentation.settings.SettingChecklistRow
import com.edde746.plezy.presentation.settings.SettingChoiceOption
import com.edde746.plezy.presentation.settings.SettingChoiceRow
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The settings' choice and checklist overlays: a choice opens on the value it has, for a keyboard or a remote; a
 * checklist keeps its locked option ticked and out of reach and saves the ticked options in their order.
 */
@OptIn(ExperimentalTestApi::class)
class SettingsChoicesTest {
    private var open by mutableStateOf(true)

    @Test
    fun aChoiceOpensWithItsSelectedValueFocusedOnTvAndOnADesktop() {
        for (formFactor in listOf(FormFactor.TV, FormFactor.DESKTOP)) {
            runComposeUiTest {
                val picked = mutableListOf<String>()
                screen(formFactor) { SettingChoiceItem(DEINTERLACE, { picked += it }, "choice", groupShape(0, 1)) }
                onNode(hasText(DEINTERLACE.title) and hasClickAction()).performClick()
                waitForIdle()
                onNode(isFocused()).assert(hasText("Film"))

                onNode(hasText("Video") and hasClickAction() and !hasText(DEINTERLACE.title)).performClick()
                waitForIdle()
                assertEquals(listOf("VIDEO"), picked, formFactor.name)
            }
        }
    }

    @Test
    fun aChecklistKeepsItsLockedOptionTickedAndSavesTheTickedOnesInOrder() = runComposeUiTest {
        val saved = mutableListOf<List<String>>()
        screen(FormFactor.TV) { if (open) ChecklistSheet(CODECS, onSave = { saved += it }, onDismiss = { open = false }) }
        waitForIdle()
        onNode(isFocused()).assert(hasText("AV1"))
        onNode(hasText("H.264") and hasClickAction()).assertIsNotEnabled()

        onNode(hasText("HEVC") and hasClickAction()).performClick()
        onNode(hasText("AV1") and hasClickAction()).performClick()
        onNodeWithText(T.common.save).performClick()
        waitForIdle()
        assertEquals(listOf(listOf("hevc", "h264")), saved)
    }

    private fun ComposeUiTest.screen(formFactor: FormFactor, content: @androidx.compose.runtime.Composable () -> Unit) = setContent {
        PlezyTheme {
            AdaptiveLayout(formFactor) {
                OverlayHostBox(Modifier.fillMaxSize()) { content() }
            }
        }
    }

    private companion object {
        val DEINTERLACE = SettingChoiceRow(
            "deinterlace", "Deinterlacing", null,
            listOf(SettingChoiceOption("OFF", "Off", false), SettingChoiceOption("VIDEO", "Video", false), SettingChoiceOption("FILM", "Film", true)),
        )
        val CODECS = SettingChecklistRow(
            "codecs", "Video Codecs", "", null,
            listOf(SettingCheckOption("av1", "AV1", true), SettingCheckOption("hevc", "HEVC", false), SettingCheckOption("h264", "H.264", true, locked = true)),
        )
    }
}
