package com.edde746.plezy.input

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlayerKeysTest {
    private val bare = KeyModifiers.NONE
    private val shift = KeyModifiers(shift = true)

    // Key classification

    @Test
    fun reservesOnlyPhysicalKeyboardEscapeForFullscreen() {
        assertEquals(NavigationKey.PHYSICAL_ESCAPE, PlayerKeys.navigation(InputKey.ESCAPE, bare, KeySource.KEYBOARD))
        assertEquals(NavigationKey.BACK, PlayerKeys.navigation(InputKey.ESCAPE, bare, KeySource.REMOTE))
    }

    @Test
    fun treatsTvosKeyboardEscapeAsSemanticBack() {
        assertEquals(NavigationKey.BACK, PlayerKeys.navigation(InputKey.ESCAPE, bare, KeySource.KEYBOARD, appleTv = true))
    }

    @Test
    fun recognizesControllerAndRemoteBack() {
        assertEquals(NavigationKey.BACK, PlayerKeys.navigation(InputKey.BACK, bare, KeySource.REMOTE))
    }

    @Test
    fun recognizesOnlyBarePhysicalBackspaceAsPlayerBack() {
        assertEquals(NavigationKey.BACK, PlayerKeys.navigation(InputKey.BACKSPACE, bare, KeySource.KEYBOARD))
        assertEquals(NavigationKey.NONE, PlayerKeys.navigation(InputKey.BACKSPACE, KeyModifiers(alt = true), KeySource.KEYBOARD))
    }

    @Test
    fun recognizesBareHome() {
        assertEquals(NavigationKey.HOME, PlayerKeys.navigation(InputKey.HOME, bare, KeySource.KEYBOARD))
        assertEquals(NavigationKey.NONE, PlayerKeys.navigation(InputKey.HOME, shift, KeySource.KEYBOARD))
    }

    @Test
    fun surrendersBareBackspaceAndHomeToAFocusedTextEditor() {
        assertEquals(NavigationKey.NONE, PlayerKeys.navigation(InputKey.BACKSPACE, bare, KeySource.KEYBOARD, textEditing = true))
        assertEquals(NavigationKey.NONE, PlayerKeys.navigation(InputKey.HOME, bare, KeySource.KEYBOARD, textEditing = true))
    }

    @Test
    fun keepsARemoteHomeNavigatingWhileATextEditorHasFocus() {
        assertEquals(NavigationKey.HOME, PlayerKeys.navigation(InputKey.HOME, bare, KeySource.REMOTE, textEditing = true))
    }

    @Test
    fun skipAndTransportKeys() {
        assertEquals(true, PlayerKeys.skipDirection(InputKey.MEDIA_FAST_FORWARD))
        assertEquals(true, PlayerKeys.skipDirection(InputKey.MEDIA_NEXT))
        assertEquals(false, PlayerKeys.skipDirection(InputKey.MEDIA_REWIND))
        assertEquals(false, PlayerKeys.skipDirection(InputKey.MEDIA_PREVIOUS))
        assertNull(PlayerKeys.skipDirection(InputKey.RIGHT))
        assertEquals(PlayerCommand.Play, PlayerKeys.transport(InputKey.MEDIA_PLAY))
        assertEquals(PlayerCommand.Pause, PlayerKeys.transport(InputKey.MEDIA_PAUSE))
        assertEquals(PlayerCommand.TogglePause, PlayerKeys.transport(InputKey.MEDIA_PLAY_PAUSE))
        assertTrue(PlayerKeys.isReserved(InputKey.UP))
        assertTrue(PlayerKeys.isReserved(InputKey.SELECT))
        assertFalse(PlayerKeys.isReserved(InputKey.SPACE))
    }

    // Hotkeys

    private fun decode(json: String) = Hotkeys.decode(Json.parseToJsonElement(json).jsonObject)

    @Test
    fun defaultsAreThePlayersShortcuts() {
        val keys = Hotkeys.DEFAULT
        assertEquals(ShortcutAction.PLAY_PAUSE, keys.actionFor(InputKey.SPACE, bare))
        assertEquals(ShortcutAction.SEEK_FORWARD, keys.actionFor(InputKey.RIGHT, bare))
        assertEquals(ShortcutAction.SEEK_FORWARD_LARGE, keys.actionFor(InputKey.RIGHT, shift))
        assertEquals(ShortcutAction.SUB_SEEK_PREV, keys.actionFor(InputKey.LEFT, KeyModifiers(ctrl = true)))
        assertEquals(ShortcutAction.SUBTITLE_TOGGLE, keys.actionFor(InputKey.S, bare))
        assertEquals(ShortcutAction.SUBTITLE_TRACK_NEXT, keys.actionFor(InputKey.S, shift))
        assertEquals(ShortcutAction.SCREENSHOT, keys.actionFor(InputKey.S, KeyModifiers(ctrl = true)))
        assertEquals(ShortcutAction.ZOOM_IN, keys.actionFor(InputKey.PLUS, KeyModifiers(alt = true)))
        assertEquals(ShortcutAction.ZOOM_RESET, keys.actionFor(InputKey.BACKSPACE, KeyModifiers(alt = true)))
        assertEquals(ShortcutAction.SKIP_MARKER, keys.actionFor(InputKey.SELECT, bare))
        assertEquals(ShortcutAction.EPISODE_NEXT, keys.actionFor(InputKey.N, shift))
        assertTrue(ShortcutAction.ZOOM_IN.repeatable && ShortcutAction.ZOOM_OUT.repeatable)
        assertFalse(ShortcutAction.ZOOM_RESET.repeatable)
    }

    @Test
    fun commandModifiedKeysAreNotTheShortcuts() {
        assertNull(Hotkeys.DEFAULT.actionFor(InputKey.S, KeyModifiers(meta = true)))
        assertNull(Hotkeys.DEFAULT.actionFor(InputKey.SPACE, KeyModifiers(alt = true)))
    }

    @Test
    fun aRebindingReplacesTheDefaultAndKeepsTheRest() {
        val keys = decode("""{"play_pause":{"key":"00070013","modifiers":["control"]},"mute_toggle":{"disabled":true}}""")
        assertEquals(ShortcutAction.PLAY_PAUSE, keys.actionFor(InputKey.P, KeyModifiers(ctrl = true)))
        assertNull(keys.actionFor(InputKey.SPACE, bare), "Space no longer plays")
        assertNull(keys.binding(ShortcutAction.MUTE_TOGGLE))
        assertNull(keys.actionFor(InputKey.M, bare))
        assertEquals(ShortcutAction.SEEK_FORWARD, keys.actionFor(InputKey.RIGHT, bare), "the rest stay the defaults")
    }

    @Test
    fun anEarlierReleasesKeyNamesStillRead() {
        val keys = decode(
            """{"play_pause":{"key":"keyk","modifiers":[]},"seek_forward":{"key":"PhysicalKeyboardKey#ec9ed(usbHidUsage: \"0x0007004d\", debugName: \"End\")","modifiers":["shift"]},"volume_up":{"key":"digit5","modifiers":[]}}""",
        )
        assertEquals(Hotkey(InputKey.K), keys.binding(ShortcutAction.PLAY_PAUSE))
        assertEquals(Hotkey(InputKey.END, shift), keys.binding(ShortcutAction.SEEK_FORWARD))
        assertEquals(Hotkey(InputKey.DIGIT_5), keys.binding(ShortcutAction.VOLUME_UP))
    }

    @Test
    fun anUnknownActionsKeyIsKeptApartAndUnparseableEntriesAreDropped() {
        val keys = decode("""{"retired":{"key":"00070014","modifiers":[]},"volume_up":"x","volume_down":{"key":"zz?","modifiers":[]}}""")
        for (action in ShortcutAction.entries) assertEquals(action.default, keys.binding(action))
        assertTrue(keys.isUnknown(InputKey.Q, bare))
        assertFalse(keys.isUnknown(InputKey.Q, shift))
        assertEquals(Hotkeys.DEFAULT, Hotkeys.decode(JsonObject(emptyMap())))
    }

    @Test
    fun aKeyThePlayerHasNoKeyForBindsNothing() {
        val keys = decode("""{"play_pause":{"key":"0005ff01","modifiers":[]}}""")
        assertNull(keys.binding(ShortcutAction.PLAY_PAUSE))
    }

    @Test
    fun hidUsagesRoundTrip() {
        for (key in listOf(InputKey.SPACE, InputKey.A, InputKey.Z, InputKey.DIGIT_1, InputKey.DIGIT_0, InputKey.F12, InputKey.UP, InputKey.MEDIA_PLAY_PAUSE)) {
            assertEquals(key, HidUsage.key(HidUsage.of(key)!!))
        }
        assertEquals(0x0007002cL, HidUsage.of(InputKey.SPACE))
    }
}
