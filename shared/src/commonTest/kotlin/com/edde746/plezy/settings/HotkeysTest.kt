package com.edde746.plezy.settings

import com.edde746.plezy.strings.T
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

/**
 * The keyboard shortcuts as `keyboard_hotkeys` stores them: the 27 actions and their defaults, the
 * stored format, earlier releases' key formats, conflicts and how a shortcut is named.
 */
class HotkeysTest {
    private fun stored(json: String): JsonObject = Json.parseToJsonElement(json).jsonObject

    @Test
    fun twentySevenActionsInSettingsOrderWithTheirDefaults() {
        assertEquals(
            listOf(
                "play_pause", "volume_up", "volume_down", "seek_forward", "seek_backward", "seek_forward_large",
                "seek_backward_large", "fullscreen_toggle", "mute_toggle", "subtitle_toggle", "audio_track_next",
                "subtitle_track_next", "chapter_next", "chapter_previous", "episode_next", "episode_previous",
                "speed_increase", "speed_decrease", "speed_reset", "zoom_in", "zoom_out", "zoom_reset", "sub_seek_next",
                "sub_seek_prev", "shader_toggle", "skip_marker", "screenshot",
            ),
            ShortcutAction.entries.map { it.id },
        )
        val defaults = Hotkeys.effective(JsonObject(emptyMap()))
        assertEquals(27, defaults.size)
        assertEquals(Hotkey(HidKeys.SPACE), defaults["play_pause"])
        assertEquals(Hotkey(HidKeys.ARROW_RIGHT, setOf(HotkeyModifier.SHIFT)), defaults["seek_forward_large"])
        assertEquals(Hotkey(HidKeys.EQUAL, setOf(HotkeyModifier.ALT)), defaults["zoom_in"])
        assertEquals(Hotkey(HidKeys.letter('s'), setOf(HotkeyModifier.CONTROL)), defaults["screenshot"])
        assertEquals(Hotkey(HidKeys.ENTER), defaults["skip_marker"])
        // No two actions share a default.
        assertEquals(27, defaults.values.toSet().size)
    }

    @Test
    fun aShortcutIsStoredAsItsHidUsageAndModifiersAndAClearedOneAsDisabled() {
        val encoded = Hotkeys.encode(mapOf("play_pause" to Hotkey(HidKeys.letter('q'), setOf(HotkeyModifier.SHIFT)), "volume_up" to null))
        assertEquals(stored("""{"play_pause":{"key":"00070014","modifiers":["shift"]},"volume_up":{"disabled":true}}"""), encoded)

        val read = Hotkeys.effective(encoded)
        assertEquals(Hotkey(HidKeys.letter('q'), setOf(HotkeyModifier.SHIFT)), read["play_pause"])
        assertNull(read["volume_up"])
        assertEquals(Hotkey(HidKeys.ARROW_DOWN), read["volume_down"], "unstored actions keep their default")
    }

    @Test
    fun modifiersAreStoredInOneOrderWhateverTheyWerePressedIn() {
        val hotkey = Hotkey(HidKeys.letter('k'), setOf(HotkeyModifier.SHIFT, HotkeyModifier.ALT, HotkeyModifier.CONTROL))
        assertEquals(stored("""{"a":{"key":"0007000e","modifiers":["alt","control","shift"]}}"""), Hotkeys.encode(mapOf("a" to hotkey)))
    }

    @Test
    fun earlierReleasesKeyFormatsAreStillRead() {
        val read = Hotkeys.effective(
            stored(
                """{"play_pause":{"key":"PhysicalKeyboardKey#abcde(usbHidUsage: \"0x00070013\", debugName: \"Key P\")","modifiers":["control"]}}""",
            ),
        )
        assertEquals(Hotkey(HidKeys.letter('p'), setOf(HotkeyModifier.CONTROL)), read["play_pause"])
        assertEquals(Hotkey(HidKeys.ARROW_UP), read["volume_up"])

        assertEquals(HidKeys.SPACE, Hotkeys.parseKey("space"))
        assertEquals(HidKeys.ARROW_LEFT, Hotkeys.parseKey("LogicalKeyboardKey#arrowLeft"))
        assertEquals(HidKeys.function(12), Hotkeys.parseKey("PhysicalKeyboardKey#F12"))
        assertEquals(HidKeys.function(1), Hotkeys.parseKey("PhysicalKeyboardKey#F1"))
        assertEquals(HidKeys.digit(0), Hotkeys.parseKey("digit0"))
        assertEquals(HidKeys.letter('z'), Hotkeys.parseKey("keyZ"))
        assertEquals(0x0007002cL, Hotkeys.parseKey("0007002c"))
        assertNull(Hotkeys.parseKey("nothing known"))
    }

    @Test
    fun retiredActionsAndUnreadableEntriesAreDropped() {
        val read = Hotkeys.effective(
            stored(
                """{"retired_action":{"key":"00070014","modifiers":[]},"volume_up":{"key":"???","modifiers":[]},"mute_toggle":{"key":"00070010"}}""",
            ),
        )
        assertEquals(ShortcutAction.entries.map { it.id }, read.keys.toList())
        assertEquals(Hotkey(HidKeys.ARROW_UP), read["volume_up"])
        assertEquals(Hotkey(HidKeys.letter('m')), read["mute_toggle"])
    }

    @Test
    fun aConflictIsAnotherKnownActionWithTheSameKeyAndModifiers() {
        val hotkeys = Hotkeys.effective(stored("""{"play_pause":{"key":"00070052","modifiers":[]}}"""))
        assertEquals("play_pause", Hotkeys.conflict(hotkeys, Hotkey(HidKeys.ARROW_UP), except = "volume_up"))
        assertNull(Hotkeys.conflict(hotkeys, Hotkey(HidKeys.ARROW_UP, setOf(HotkeyModifier.SHIFT)), except = "volume_up"))
        assertNull(Hotkeys.conflict(hotkeys, Hotkey(HidKeys.SPACE), except = "play_pause"), "an action's own shortcut")
        assertNull(Hotkeys.conflict(hotkeys + ("retired" to Hotkey(HidKeys.letter('x'))), Hotkey(HidKeys.letter('x')), except = "play_pause"))
    }

    @Test
    fun shortcutsAreNamedByTheirKeysAndModifiers() {
        assertEquals("Ctrl + S", Hotkeys.format(Hotkey(HidKeys.letter('s'), setOf(HotkeyModifier.CONTROL)), mac = false))
        assertEquals("Ctrl + Alt + Shift + Arrow Right", Hotkeys.format(Hotkey(HidKeys.ARROW_RIGHT, setOf(HotkeyModifier.SHIFT, HotkeyModifier.ALT, HotkeyModifier.CONTROL)), mac = false))
        assertEquals("\u2303\u21e7\u2192", Hotkeys.format(Hotkey(HidKeys.ARROW_RIGHT, setOf(HotkeyModifier.SHIFT, HotkeyModifier.CONTROL)), mac = true))
        assertEquals("\u2318S", Hotkeys.format(Hotkey(HidKeys.letter('s'), setOf(HotkeyModifier.META)), mac = true))
        assertEquals("Space", Hotkeys.format(Hotkey(HidKeys.SPACE), mac = true))
        assertEquals("F12", Hotkeys.keyLabel(HidKeys.function(12), mac = false))
        assertEquals("1", Hotkeys.keyLabel(HidKeys.digit(1), mac = false))
        assertEquals("\\", Hotkeys.keyLabel(0x00070031L, mac = false))
        assertEquals("'", Hotkeys.keyLabel(0x00070034L, mac = false))
        assertEquals("Key 0x000700ff", Hotkeys.keyLabel(0x000700ffL, mac = false))
        assertEquals(T.hotkeys.noShortcutSet, Hotkeys.format(null, mac = false))
    }

    @Test
    fun aMacNamesModifiersInItsOwnOrderAndKeysByTheirSymbols() {
        val every = setOf(HotkeyModifier.META, HotkeyModifier.SHIFT, HotkeyModifier.ALT, HotkeyModifier.CONTROL)
        assertEquals("\u2303\u2325\u21e7\u2318K", Hotkeys.format(Hotkey(HidKeys.letter('k'), every), mac = true))
        assertEquals("Ctrl + Alt + Shift + Meta + K", Hotkeys.format(Hotkey(HidKeys.letter('k'), every), mac = false))
        assertEquals("CapsLock + Fn + K", Hotkeys.format(Hotkey(HidKeys.letter('k'), setOf(HotkeyModifier.FN, HotkeyModifier.CAPS_LOCK)), mac = false))
        val symbols = mapOf(
            0x00070028L to "\u21a9", 0x00070029L to "\u238b", 0x0007002aL to "\u232b", 0x0007002bL to "\u21e5", 0x00070039L to "\u21ea",
            0x0007004aL to "\u2196", 0x0007004bL to "\u21de", 0x0007004cL to "\u2326", 0x0007004dL to "\u2198", 0x0007004eL to "\u21df",
            0x0007004fL to "\u2192", 0x00070050L to "\u2190", 0x00070051L to "\u2193", 0x00070052L to "\u2191",
        )
        for ((usage, symbol) in symbols) assertEquals(symbol, Hotkeys.keyLabel(usage, mac = true), usage.toString(16))
        assertEquals("Enter", Hotkeys.keyLabel(0x00070028L, mac = false))
    }

    @Test
    fun keysBeyondTheKeyboardPageHaveTheirOwnNames() {
        assertEquals("Fn", Hotkeys.keyLabel(0x00000012L, mac = false))
        assertEquals("Sleep", Hotkeys.keyLabel(0x00010082L, mac = false))
        assertEquals("Game Button 1", Hotkeys.keyLabel(0x0005ff01L, mac = false))
        assertEquals("Game Button 1", Hotkeys.keyLabel(0x0005ff01L, mac = true))
        assertEquals("Meta", Hotkeys.keyLabel(0x000700e3L, mac = false))
        assertEquals("\u2318", Hotkeys.keyLabel(0x000700e3L, mac = true))
    }

    @Test
    fun aSettingsFileBringsInOnlyWellFormedShortcutsWithoutSharedBindings() {
        Hotkeys.validate(stored("""{"play_pause":{"key":"00070014","modifiers":["shift","alt"]},"volume_up":{"disabled":true}}"""))
        Hotkeys.validate(stored("{}"))
        val refused = listOf(
            """{"retired_action":{"key":"00070014","modifiers":[]}}""",
            """{"play_pause":{"key":"00070014","modifiers":[],"extra":1}}""",
            """{"play_pause":{"key":"70014","modifiers":[]}}""",
            """{"play_pause":{"key":"space","modifiers":[]}}""",
            """{"play_pause":{"key":"00000000","modifiers":[]}}""",
            """{"play_pause":{"key":"00070014"}}""",
            """{"play_pause":{"key":"00070014","modifiers":"shift"}}""",
            """{"play_pause":{"key":"00070014","modifiers":["shift","shift"]}}""",
            """{"play_pause":{"key":"00070014","modifiers":["hyper"]}}""",
            """{"play_pause":{"disabled":false}}""",
            """{"play_pause":null}""",
            // Arrow Up is volume_up's default.
            """{"play_pause":{"key":"00070052","modifiers":[]}}""",
        )
        for (json in refused) assertFailsWith<IllegalArgumentException>(json) { Hotkeys.validate(stored(json)) }
        // Moving the default away first frees its key.
        Hotkeys.validate(stored("""{"play_pause":{"key":"00070052","modifiers":[]},"volume_up":{"disabled":true}}"""))
    }
}
