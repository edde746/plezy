package com.edde746.plezy.presentation.settings

import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.HidKeys
import com.edde746.plezy.settings.Hotkey
import com.edde746.plezy.settings.HotkeyModifier
import com.edde746.plezy.settings.Hotkeys
import com.edde746.plezy.settings.ShortcutAction
import com.edde746.plezy.strings.T
import kotlinx.coroutines.async
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/**
 * Keyboard shortcuts: the rows, recording a shortcut (stored in the HID format, refused when another
 * action has it, retryable when storing fails), clearing one for good, Reset restoring every default.
 */
class KeyboardShortcutsPageTest {
    private val key = AppSettings.keyboardHotkeys.key

    private class Shortcuts(val fixture: SettingsFixture, val store: KeyboardShortcutsPage) {
        val messages = fixture.collect(store.messages)
        val state get() = store.state.value
        fun row(id: String) = state.rows.single { it.actionId == id }
        suspend fun stored(): JsonObject = fixture.data.deviceSettings.value(AppSettings.keyboardHotkeys)
        suspend fun effective() = Hotkeys.effective(stored())
    }

    private suspend fun TestScope.shortcuts(platform: SettingsPlatform = SettingsPlatform(), stored: String? = null): Shortcuts {
        val fixture = settingsFixture(platform)
        stored?.let { fixture.data.deviceSettings.set(AppSettings.keyboardHotkeys, Json.parseToJsonElement(it).jsonObject) }
        val shortcuts = Shortcuts(fixture, fixture.stores.keyboardShortcuts())
        runCurrent()
        return shortcuts
    }

    @Test
    fun aRowPerActionInOrderNamingItsShortcut() = runTest {
        val shortcuts = shortcuts()
        assertEquals(ShortcutAction.entries.map { it.id }, shortcuts.state.rows.map { it.actionId })
        assertEquals("Space", shortcuts.row("play_pause").keys)
        assertEquals(T.hotkeys.actions.seekForward(AppSettings.seekTimeSmall.default.toString()), shortcuts.row("seek_forward").title)
        assertEquals("Shift + Arrow Right", shortcuts.row("seek_forward_large").keys)

        val mac = shortcuts(SettingsPlatform(os = "macOS"))
        assertEquals("\u21e7\u2192", mac.row("seek_forward_large").keys)
    }

    @Test
    fun theSeekRowsNameTheStepsSet() = runTest {
        val shortcuts = shortcuts()
        shortcuts.fixture.data.deviceSettings.set(AppSettings.seekTimeSmall, 5)
        shortcuts.fixture.data.deviceSettings.set(AppSettings.seekTimeLarge, 60)
        runCurrent()
        assertEquals(T.hotkeys.actions.seekBackward("5"), shortcuts.row("seek_backward").title)
        assertEquals(T.hotkeys.actions.seekBackward("60"), shortcuts.row("seek_backward_large").title)
    }

    @Test
    fun aRecordedShortcutIsStoredInTheHidFormat() = runTest {
        val shortcuts = shortcuts()
        val result = shortcuts.store.record("play_pause", HidKeys.letter('q'), setOf("shift"))
        runCurrent()
        assertEquals(ShortcutResult.SAVED, result)
        assertEquals(Json.parseToJsonElement("""{"key":"00070014","modifiers":["shift"]}"""), shortcuts.stored()["play_pause"])
        assertEquals("Shift + Q", shortcuts.row("play_pause").keys)
        assertEquals(listOf(SettingsEvent.Message(T.settings.shortcutUpdated(T.hotkeys.actions.playPause))), shortcuts.messages)
    }

    @Test
    fun aShortcutAnotherActionHasIsRefusedAndNothingChanges() = runTest {
        val shortcuts = shortcuts()
        val result = shortcuts.store.record("play_pause", HidKeys.ARROW_UP, emptySet())
        runCurrent()
        assertEquals(ShortcutResult.CONFLICT, result)
        assertEquals(JsonObject(emptyMap()), shortcuts.stored())
        assertEquals("Space", shortcuts.row("play_pause").keys)
        assertEquals("Arrow Up", shortcuts.row("volume_up").keys)
        assertEquals(
            listOf(SettingsEvent.Message(T.settings.shortcutAlreadyAssigned(T.hotkeys.actions.volumeUp), error = true)),
            shortcuts.messages,
        )
    }

    @Test
    fun anActionNoShortcutHasIsRefusedAndNothingIsStored() = runTest {
        val shortcuts = shortcuts()
        assertFailsWith<IllegalArgumentException> { shortcuts.store.record("retired_action", HidKeys.letter('q'), emptySet()) }
        assertFailsWith<IllegalArgumentException> { shortcuts.store.clear("retired_action") }
        assertFailsWith<IllegalArgumentException> { shortcuts.store.recorder("retired_action") }
        runCurrent()
        assertEquals(JsonObject(emptyMap()), shortcuts.stored())
        assertEquals(emptyList(), shortcuts.messages)
    }

    @Test
    fun aClearedShortcutStaysClearedAcrossRestartsUntilReset() = runTest {
        val shortcuts = shortcuts()
        assertEquals(ShortcutResult.SAVED, shortcuts.store.clear("play_pause"))
        runCurrent()
        assertTrue(shortcuts.row("play_pause").unset)
        assertEquals(T.hotkeys.noShortcutSet, shortcuts.row("play_pause").keys)
        assertEquals(Json.parseToJsonElement("""{"disabled":true}"""), shortcuts.stored()["play_pause"])

        // Its old key is free for another action.
        assertEquals(ShortcutResult.SAVED, shortcuts.store.record("volume_up", HidKeys.SPACE, emptySet()))
        shortcuts.store.release()

        val reopened = Shortcuts(shortcuts.fixture, shortcuts.fixture.stores.keyboardShortcuts())
        runCurrent()
        assertTrue(reopened.row("play_pause").unset)
        assertEquals("Space", reopened.row("volume_up").keys)
        assertEquals("Arrow Down", reopened.row("volume_down").keys)

        reopened.store.resetAll()
        runCurrent()
        assertEquals(JsonObject(emptyMap()), reopened.stored())
        assertEquals("Space", reopened.row("play_pause").keys)
        assertEquals("Arrow Up", reopened.row("volume_up").keys)
        assertEquals(SettingsEvent.Message(T.settings.shortcutsReset), reopened.messages.last())
    }

    @Test
    fun aRefusedShortcutClosesTheRecorderWithItsMessageAndAFailureKeepsIt() = runTest {
        val shortcuts = shortcuts()
        val recorder = shortcuts.store.recorder("play_pause")
        recorder.capture(HidKeys.ARROW_UP, emptySet())
        assertEquals("Arrow Up", recorder.state.value.keys)
        val result = recorder.save()
        runCurrent()
        assertEquals(ShortcutResult.CONFLICT, result)
        assertTrue(result!!.closesRecorder)
        assertEquals(
            listOf(SettingsEvent.Message(T.settings.shortcutAlreadyAssigned(T.hotkeys.actions.volumeUp), error = true)),
            shortcuts.messages,
        )
        assertEquals("Space", shortcuts.row("play_pause").keys)
        assertFalse(ShortcutResult.FAILED.closesRecorder)
        assertTrue(ShortcutResult.SAVED.closesRecorder)
    }

    @Test
    fun clearIsOnlyTheDialogsEditUntilSave() = runTest {
        val shortcuts = shortcuts()
        val recorder = shortcuts.store.recorder("play_pause")
        recorder.clear()
        runCurrent()
        assertTrue(recorder.state.value.unset)
        assertEquals(T.hotkeys.noShortcutSet, recorder.state.value.keys)
        assertEquals("Space", shortcuts.row("play_pause").keys)
        assertEquals(JsonObject(emptyMap()), shortcuts.stored())

        assertEquals(ShortcutResult.SAVED, recorder.save())
        runCurrent()
        assertTrue(shortcuts.row("play_pause").unset)
        assertEquals(Json.parseToJsonElement("""{"disabled":true}"""), shortcuts.stored()["play_pause"])
    }

    @Test
    fun anUnassignedActionWithNoEditHasNothingToSave() = runTest {
        val shortcuts = shortcuts()
        shortcuts.store.clear("play_pause")
        runCurrent()
        val recorder = shortcuts.store.recorder("play_pause")
        assertFalse(recorder.state.value.canSave)
        assertEquals(null, recorder.save())
    }

    @Test
    fun editsSaveOverADuplicateAndDropRetiredActions() = runTest {
        // play_pause took volume_up's key before that became its default; retired_action is from an earlier build.
        val shortcuts = shortcuts(stored = """{"play_pause":{"key":"00070052","modifiers":[]},"retired_action":{"key":"00070014","modifiers":[]}}""")
        assertEquals(ShortcutResult.SAVED, shortcuts.store.record("volume_down", HidKeys.letter('t'), emptySet()))
        runCurrent()
        val effective = shortcuts.effective()
        assertEquals(Hotkey(HidKeys.letter('t')), effective["volume_down"])
        assertEquals(Hotkey(HidKeys.ARROW_UP), effective["play_pause"])
        assertFalse("retired_action" in shortcuts.stored())

        // The retired action's key is free.
        assertEquals(ShortcutResult.SAVED, shortcuts.store.record("volume_up", HidKeys.letter('q'), emptySet()))
        assertEquals(Hotkey(HidKeys.letter('q')), shortcuts.effective()["volume_up"])
    }

    @Test
    fun quickEditsAreStoredOneAfterAnotherAndAFailureKeepsTheRest() = runTest {
        val shortcuts = shortcuts()
        shortcuts.fixture.io.held = true
        val first = async { shortcuts.store.record("play_pause", HidKeys.letter('q'), emptySet()) }
        val second = async { shortcuts.store.record("volume_up", HidKeys.letter('w'), emptySet()) }
        runCurrent()
        shortcuts.fixture.io.held = false
        assertEquals(ShortcutResult.SAVED, first.await())
        assertEquals(ShortcutResult.SAVED, second.await())
        val both = shortcuts.effective()
        assertEquals(Hotkey(HidKeys.letter('q')), both["play_pause"])
        assertEquals(Hotkey(HidKeys.letter('w')), both["volume_up"])

        shortcuts.fixture.failWrites(key)
        assertEquals(ShortcutResult.FAILED, shortcuts.store.record("play_pause", HidKeys.letter('e'), setOf("control")))
        runCurrent()
        assertEquals(SettingsEvent.Message(T.common.error, error = true), shortcuts.messages.last())
        assertEquals("Q", shortcuts.row("play_pause").keys)

        shortcuts.fixture.allowWrites(key)
        assertEquals(ShortcutResult.SAVED, shortcuts.store.record("play_pause", HidKeys.letter('e'), setOf("control")))
        runCurrent()
        assertEquals(Hotkey(HidKeys.letter('e'), setOf(HotkeyModifier.CONTROL)), shortcuts.effective()["play_pause"])
        assertEquals(Hotkey(HidKeys.letter('w')), shortcuts.effective()["volume_up"])
    }
}
