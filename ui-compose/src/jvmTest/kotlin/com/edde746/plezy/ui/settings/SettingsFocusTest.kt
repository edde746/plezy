package com.edde746.plezy.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.SaveableStateHolder
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.ui.InternalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isFocusable
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyPress
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.settings.LogEntryUi
import com.edde746.plezy.presentation.settings.LogsStore
import com.edde746.plezy.presentation.settings.LogsUiState
import com.edde746.plezy.presentation.settings.SettingLinkRow
import com.edde746.plezy.presentation.settings.SettingRow
import com.edde746.plezy.presentation.settings.SettingSlot
import com.edde746.plezy.presentation.settings.SettingSlotRow
import com.edde746.plezy.presentation.settings.SettingToggleRow
import com.edde746.plezy.presentation.settings.SettingsEvent
import com.edde746.plezy.presentation.settings.SettingsPageStore
import com.edde746.plezy.presentation.settings.SettingsPageUiState
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.LocalOverlayOpeners
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.focus.LocalScreenFocus
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.ScreenFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.probe.FocusedProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

/**
 * The hub on TV and with a keyboard: shown the first time, focus is on its top setting (not the Support Plezy offer
 * above it); shown again (the Settings tab re-entered, back from a page), on the row that had it last; the title takes
 * none. One Back on Logs, a log entry focused, goes back to the hub.
 */
@OptIn(ExperimentalTestApi::class, InternalComposeUiApi::class)
class SettingsFocusTest {
    private var shown by mutableStateOf(true)

    /** Logs is pushed over the hub. */
    private var logs by mutableStateOf(false)
    private val probe = FocusedProbe()
    private val dispatcher = NavigationEventDispatcher()

    /** The window's system back: the back gesture, a remote's Back from Android 13 on, an earlier one's nothing took. */
    private val windowBack = DirectNavigationEventInput().also(dispatcher::addInput)

    @Test
    fun theTabReEnteredFocusesTheRowThatHadFocusLast() = runComposeUiTest {
        hub()
        waitForIdle()
        row("General").assertIsFocused()
        row("Debug Logging").requestFocus()
        waitForIdle()
        shown = false
        waitForIdle()
        onNode(hasText("Navigation") and isFocusable()).requestFocus()
        shown = true
        waitForIdle()
        row("Debug Logging").assertIsFocused()
    }

    /** The remote's Back on Android 12 and older, where it comes as keys only: the entries' text is no stop on the way. */
    @Test
    fun tvBackKeyOnALogEntryLeavesLogsWithFocusOnTheLogsRow() = runComposeUiTest {
        openLogs()
        pressBackAsAndroidDoes()
        assertFalse(logs, "Back stayed on Logs, focus on ${probe.focused}")
        assertEquals("settings.row.logs", probe.focused)
    }

    @Test
    fun systemBackOnALogEntryLeavesLogsWithFocusOnTheLogsRow() = runComposeUiTest {
        openLogs()
        windowBack.backCompleted()
        waitForIdle()
        assertFalse(logs)
        assertEquals("settings.row.logs", probe.focused)
    }

    private fun ComposeUiTest.row(title: String) = onNode(hasText(title) and isFocusable(), useUnmergedTree = false)

    /** The hub with focus on its Logs row, then Logs pushed over it: focus on its first entry. */
    private fun ComposeUiTest.openLogs() {
        hub()
        waitForIdle()
        row("Logs").requestFocus()
        waitForIdle()
        logs = true
        waitForIdle()
        assertEquals("settings.logs.entry.0", probe.focused)
    }

    /**
     * Back as an Android window of 12 or older delivers a remote's: its press, then its release, each to where focus is
     * then; the activity makes it the system's back ([windowBack]) when neither was taken.
     */
    private fun ComposeUiTest.pressBackAsAndroidDoes() {
        val down = onRoot().performKeyPress(KeyEvent(Key.Back, KeyEventType.KeyDown))
        waitForIdle()
        val up = onRoot().performKeyPress(KeyEvent(Key.Back, KeyEventType.KeyUp))
        if (!down && !up) windowBack.backCompleted()
        waitForIdle()
    }

    /**
     * The navigation, then while [shown] the hub's rows from the renderer, its focus memory saved while it is away, or
     * Logs pushed over it, which the system's back leaves as the navigation's does.
     */
    private fun ComposeUiTest.hub() = setContent {
        val owner = remember {
            object : NavigationEventDispatcherOwner {
                override val navigationEventDispatcher = dispatcher
            }
        }
        CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner, LocalLayoutProbe provides probe) {
            PlezyTheme {
                Box(Modifier.size(1280.dp, 720.dp)) {
                    AdaptiveLayout(FormFactor.TV) {
                        OverlayHostBox {
                            SystemBackHandler(enabled = logs) { logs = false }
                            val states = rememberSaveableStateHolder()
                            Column {
                                CompositionLocalProvider(LocalOverlayOpeners provides false) { PlezyButton("Navigation", {}) }
                                if (shown && !logs) {
                                    states.Screen("hub") {
                                        val memory = rememberFocusMemory()
                                        SettingsPageFrame("Settings", hub = true, toasts = remember { SettingsToasts() }, onBack = {}) {
                                            SettingsList {
                                                settingsGroup("top", null, ROWS.map { row -> SettingsItem(row.id) { shape -> SettingRowItem(row, Store, shape, memory, onOpen = {}) { _, _, _ -> } } })
                                            }
                                        }
                                        RestoreFocus(memory, ready = true, fallback = firstFocusRow(listOf(ROWS)))
                                    }
                                }
                                if (shown && logs) {
                                    states.Screen("logs") { LogsPage(Logs, remember { SettingsToasts() }, onBack = { logs = false }) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private companion object {
        val ROWS: List<SettingRow> = listOf(
            SettingSlotRow("supporter", SettingSlot.SUPPORTER),
            SettingLinkRow("general", "General", "Language, startup, and window behavior"),
            SettingLinkRow("appearance", "Appearance", "OLED · Library Density 3"),
            SettingToggleRow("debug_logging", "Debug Logging", "Enable detailed logging for troubleshooting", checked = false),
            SettingLinkRow("logs", "Logs", "View application logs"),
            SettingLinkRow("about", "About", "App information and licenses"),
        )
    }

    /** A store that takes every intent and changes nothing. */
    private object Store : SettingsPageStore {
        override val state = MutableStateFlow(SettingsPageUiState("Settings", emptyList()))
        override val events = emptyFlow<SettingsEvent>()
        override fun toggle(id: String, checked: Boolean) = Unit
        override fun choose(id: String, optionId: String) = Unit
        override fun setNumber(id: String, text: String): String? = null
        override fun checkNumber(id: String, text: String): String? = null
        override fun setSlider(id: String, value: Double) = Unit
        override fun setChecked(id: String, checkedIds: List<String>) = Unit
        override fun submitText(id: String, text: String): String? = null
        override fun checkText(id: String, text: String): String? = null
        override fun resetText(id: String): String? = ""
        override fun setColor(id: String, hex: String) = Unit
        override fun activate(id: String) = Unit
        override fun confirm(id: String) = Unit
        override fun exported(saved: Boolean, error: String?) = Unit
        override fun imported(bytes: ByteArray?) = Unit
        override fun release() = Unit
    }

    /** A log of two entries under the device block that changes nothing. */
    private object Logs : LogsStore {
        override val state = MutableStateFlow(
            LogsUiState(
                listOf(
                    LogEntryUi(1_767_250_560_895L, "INFO", "DataAggregation", "Fetched 2 on deck items from all servers", null),
                    LogEntryUi(1_767_250_560_234L, "INFO", "MultiServerManager", "Added Plezy Test Jellyfin", null),
                ),
                uploading = false,
                header = "Plezy v2.26.0",
            ),
        )
        override val events = emptyFlow<SettingsEvent>()
        override fun text() = ""
        override fun copy() = Unit
        override fun refresh() = Unit
        override fun clear() = Unit
        override fun upload() = Unit
        override fun release() = Unit
    }
}

/** A screen of the stack, its state kept in the holder under [key] while it is away, as the navigation shows one. */
@Composable
private fun SaveableStateHolder.Screen(key: String, content: @Composable () -> Unit) = SaveableStateProvider(key) {
    val screen = remember { ScreenFocus { true } }
    Box(screen.modifier) { CompositionLocalProvider(LocalScreenFocus provides screen, content = content) }
}
