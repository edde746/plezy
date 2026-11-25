package com.edde746.plezy.settings

import com.edde746.plezy.strings.T
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** A key held with a shortcut's key ([Hotkey.modifiers]); [id] is how `keyboard_hotkeys` stores it. */
enum class HotkeyModifier(val id: String) {
    ALT("alt"),
    CAPS_LOCK("capsLock"),
    CONTROL("control"),
    FN("fn"),
    META("meta"),
    SHIFT("shift"),
    ;

    companion object {
        fun fromId(id: String): HotkeyModifier? = entries.firstOrNull { it.id == id }
    }
}

/**
 * A keyboard shortcut: the physical [key] as its USB HID usage (`0x00070004` is A) pressed with exactly [modifiers].
 * Two hotkeys are the same shortcut when key and modifiers match, in any order.
 */
data class Hotkey(val key: Long, val modifiers: Set<HotkeyModifier> = emptySet())

/**
 * Every action the video player's keyboard shortcuts trigger, in the order Settings lists them, each with the id
 * `keyboard_hotkeys` stores it under and the shortcut it has until the user assigns another.
 */
enum class ShortcutAction(val id: String, val defaultHotkey: Hotkey) {
    PLAY_PAUSE("play_pause", Hotkey(HidKeys.SPACE)),
    VOLUME_UP("volume_up", Hotkey(HidKeys.ARROW_UP)),
    VOLUME_DOWN("volume_down", Hotkey(HidKeys.ARROW_DOWN)),
    SEEK_FORWARD("seek_forward", Hotkey(HidKeys.ARROW_RIGHT)),
    SEEK_BACKWARD("seek_backward", Hotkey(HidKeys.ARROW_LEFT)),
    SEEK_FORWARD_LARGE("seek_forward_large", Hotkey(HidKeys.ARROW_RIGHT, setOf(HotkeyModifier.SHIFT))),
    SEEK_BACKWARD_LARGE("seek_backward_large", Hotkey(HidKeys.ARROW_LEFT, setOf(HotkeyModifier.SHIFT))),
    FULLSCREEN_TOGGLE("fullscreen_toggle", Hotkey(HidKeys.letter('f'))),
    MUTE_TOGGLE("mute_toggle", Hotkey(HidKeys.letter('m'))),
    SUBTITLE_TOGGLE("subtitle_toggle", Hotkey(HidKeys.letter('s'))),
    AUDIO_TRACK_NEXT("audio_track_next", Hotkey(HidKeys.letter('a'))),
    SUBTITLE_TRACK_NEXT("subtitle_track_next", Hotkey(HidKeys.letter('s'), setOf(HotkeyModifier.SHIFT))),
    CHAPTER_NEXT("chapter_next", Hotkey(HidKeys.letter('n'))),
    CHAPTER_PREVIOUS("chapter_previous", Hotkey(HidKeys.letter('p'))),
    EPISODE_NEXT("episode_next", Hotkey(HidKeys.letter('n'), setOf(HotkeyModifier.SHIFT))),
    EPISODE_PREVIOUS("episode_previous", Hotkey(HidKeys.letter('p'), setOf(HotkeyModifier.SHIFT))),
    SPEED_INCREASE("speed_increase", Hotkey(HidKeys.EQUAL)),
    SPEED_DECREASE("speed_decrease", Hotkey(HidKeys.MINUS)),
    SPEED_RESET("speed_reset", Hotkey(HidKeys.letter('r'))),
    ZOOM_IN("zoom_in", Hotkey(HidKeys.EQUAL, setOf(HotkeyModifier.ALT))),
    ZOOM_OUT("zoom_out", Hotkey(HidKeys.MINUS, setOf(HotkeyModifier.ALT))),
    ZOOM_RESET("zoom_reset", Hotkey(HidKeys.BACKSPACE, setOf(HotkeyModifier.ALT))),
    SUB_SEEK_NEXT("sub_seek_next", Hotkey(HidKeys.ARROW_RIGHT, setOf(HotkeyModifier.CONTROL))),
    SUB_SEEK_PREV("sub_seek_prev", Hotkey(HidKeys.ARROW_LEFT, setOf(HotkeyModifier.CONTROL))),
    SHADER_TOGGLE("shader_toggle", Hotkey(HidKeys.letter('g'))),
    SKIP_MARKER("skip_marker", Hotkey(HidKeys.ENTER)),
    SCREENSHOT("screenshot", Hotkey(HidKeys.letter('s'), setOf(HotkeyModifier.CONTROL))),
    ;

    /** The action's name as Settings lists it; the seek actions name their steps ([seekSmall], [seekLarge] seconds). */
    fun label(seekSmall: Int, seekLarge: Int): String {
        val actions = T.hotkeys.actions
        return when (this) {
            PLAY_PAUSE -> actions.playPause
            VOLUME_UP -> actions.volumeUp
            VOLUME_DOWN -> actions.volumeDown
            SEEK_FORWARD -> actions.seekForward(seekSmall.toString())
            SEEK_BACKWARD -> actions.seekBackward(seekSmall.toString())
            SEEK_FORWARD_LARGE -> actions.seekForward(seekLarge.toString())
            SEEK_BACKWARD_LARGE -> actions.seekBackward(seekLarge.toString())
            FULLSCREEN_TOGGLE -> actions.fullscreenToggle
            MUTE_TOGGLE -> actions.muteToggle
            SUBTITLE_TOGGLE -> actions.subtitleToggle
            AUDIO_TRACK_NEXT -> actions.audioTrackNext
            SUBTITLE_TRACK_NEXT -> actions.subtitleTrackNext
            CHAPTER_NEXT -> actions.chapterNext
            CHAPTER_PREVIOUS -> actions.chapterPrevious
            EPISODE_NEXT -> actions.episodeNext
            EPISODE_PREVIOUS -> actions.episodePrevious
            SPEED_INCREASE -> actions.speedIncrease
            SPEED_DECREASE -> actions.speedDecrease
            SPEED_RESET -> actions.speedReset
            ZOOM_IN -> actions.zoomIn
            ZOOM_OUT -> actions.zoomOut
            ZOOM_RESET -> actions.zoomReset
            SUB_SEEK_NEXT -> actions.subSeekNext
            SUB_SEEK_PREV -> actions.subSeekPrev
            SHADER_TOGGLE -> actions.shaderToggle
            SKIP_MARKER -> actions.skipMarker
            SCREENSHOT -> actions.screenshot
        }
    }

    companion object {
        /** The action stored under [id]; null for one this build doesn't know (a retired action). */
        fun fromId(id: String): ShortcutAction? = entries.firstOrNull { it.id == id }
    }
}

/** USB HID usages of the keys the default shortcuts and earlier releases' key names use. */
object HidKeys {
    const val ENTER: Long = 0x00070028
    const val ESCAPE: Long = 0x00070029
    const val BACKSPACE: Long = 0x0007002a
    const val TAB: Long = 0x0007002b
    const val SPACE: Long = 0x0007002c
    const val MINUS: Long = 0x0007002d
    const val EQUAL: Long = 0x0007002e
    const val CAPS_LOCK: Long = 0x00070039
    const val HOME: Long = 0x0007004a
    const val PAGE_UP: Long = 0x0007004b
    const val DELETE: Long = 0x0007004c
    const val END: Long = 0x0007004d
    const val PAGE_DOWN: Long = 0x0007004e
    const val ARROW_RIGHT: Long = 0x0007004f
    const val ARROW_LEFT: Long = 0x00070050
    const val ARROW_DOWN: Long = 0x00070051
    const val ARROW_UP: Long = 0x00070052

    /** The letter key [c] (`a`..`z`). */
    fun letter(c: Char): Long = 0x00070004L + (c.lowercaseChar() - 'a')

    /** The digit key [d] (0..9) of the main row. */
    fun digit(d: Int): Long = if (d == 0) 0x00070027L else 0x0007001eL + (d - 1)

    /** The function key F[n] (1..12). */
    fun function(n: Int): Long = 0x0007003aL + (n - 1)
}

/**
 * The keyboard shortcuts as `keyboard_hotkeys` stores them: `{actionId: {"key": "<8 hex digits: the USB HID usage>",
 * "modifiers": ["alt"|"control"|"shift"|"meta"|"capsLock"|"fn"]} | {"disabled": true}}`, read merged over every
 * action's default ([effective]). Earlier releases wrote some keys as a name or a debug description (`"space"`,
 * `"PhysicalKeyboardKey#ec9ed(usbHidUsage: "0x0007002c", …)"`), still read ([parseKey]).
 */
object Hotkeys {
    /** Every action's shortcut: the stored one, else its default; null where the user cleared it. In action order. */
    fun effective(stored: JsonObject): Map<String, Hotkey?> {
        val result = LinkedHashMap<String, Hotkey?>()
        for (action in ShortcutAction.entries) result[action.id] = action.defaultHotkey
        for ((id, value) in stored) {
            if (ShortcutAction.fromId(id) == null) continue
            val entry = value as? JsonObject ?: continue
            if ((entry["disabled"] as? JsonPrimitive)?.booleanOrNull == true) {
                result[id] = null
                continue
            }
            decode(entry)?.let { result[id] = it }
        }
        return result
    }

    /** [hotkeys] (action id → shortcut, null cleared) as stored. */
    fun encode(hotkeys: Map<String, Hotkey?>): JsonObject = buildJsonObject {
        for ((id, hotkey) in hotkeys) {
            put(
                id,
                if (hotkey == null) {
                    buildJsonObject { put("disabled", true) }
                } else {
                    buildJsonObject {
                        put("key", hotkey.key.toString(16).padStart(8, '0'))
                        put("modifiers", JsonArray(HotkeyModifier.entries.filter { it in hotkey.modifiers }.map { JsonPrimitive(it.id) }))
                    }
                },
            )
        }
    }

    /** The action other than [except] that [hotkey] already triggers in [hotkeys]; null when none does. */
    fun conflict(hotkeys: Map<String, Hotkey?>, hotkey: Hotkey, except: String): String? =
        hotkeys.entries.firstOrNull { (id, assigned) -> id != except && assigned == hotkey && ShortcutAction.fromId(id) != null }?.key

    /**
     * Throws IllegalArgumentException unless [stored] is shortcuts a settings file may bring in: every entry a known
     * action, either `{"disabled": true}` or exactly `{"key", "modifiers"}` with the key 8 hex digits other than 0 and
     * the modifiers known and none twice; and, merged over the defaults ([effective]), no two actions on one shortcut.
     */
    fun validate(stored: JsonObject) {
        for ((id, value) in stored) {
            require(ShortcutAction.fromId(id) != null) { "keyboard_hotkeys: unknown action $id" }
            val entry = value as? JsonObject ?: throw IllegalArgumentException("keyboard_hotkeys: $id is not a shortcut")
            if (entry.keys == setOf("disabled")) {
                require((entry["disabled"] as? JsonPrimitive)?.booleanOrNull == true) { "keyboard_hotkeys: $id has a bad disabled flag" }
                continue
            }
            val key = (entry["key"] as? JsonPrimitive)?.takeIf { it.isString }?.content
            val modifiers = entry["modifiers"] as? JsonArray
            require(entry.keys == setOf("key", "modifiers") && key != null && HID_KEY.matches(key) && modifiers != null) {
                "keyboard_hotkeys: $id needs a USB HID key and a modifier list"
            }
            require(key.toLong(16) != 0L) { "keyboard_hotkeys: $id has no key" }
            val ids = modifiers.map { (it as? JsonPrimitive)?.takeIf { p -> p.isString }?.content }
            require(ids.all { it != null && HotkeyModifier.fromId(it) != null } && ids.toSet().size == ids.size) {
                "keyboard_hotkeys: $id has an unknown or repeated modifier"
            }
        }
        val assigned = effective(stored)
        for ((id, hotkey) in assigned) {
            if (hotkey != null) require(conflict(assigned, hotkey, id) == null) { "keyboard_hotkeys: $id shares its shortcut" }
        }
    }

    private val HID_KEY = Regex("^[0-9a-fA-F]{8}$")

    /**
     * [hotkey] as Settings shows it: "Shift + Arrow Right", on a Mac the system's symbols run together ("⇧→"); "No
     * shortcut set" for none.
     */
    fun format(hotkey: Hotkey?, mac: Boolean): String {
        if (hotkey == null) return T.hotkeys.noShortcutSet
        val modifiers = MODIFIER_ORDER.filter { it in hotkey.modifiers }.map { if (mac) MAC_MODIFIER_LABELS.getValue(it) else MODIFIER_LABELS.getValue(it) }
        val key = keyLabel(hotkey.key, mac)
        return if (mac) (modifiers + key).joinToString("") else (modifiers + key).joinToString(" + ")
    }

    /** The name of the key [usage]: a Mac's symbol where it has one, else its name, else `Key 0x…`. */
    fun keyLabel(usage: Long, mac: Boolean): String =
        (if (mac) MAC_KEY_LABELS[usage] else null) ?: HID_KEY_LABELS[usage] ?: "Key 0x" + usage.toString(16).padStart(8, '0')

    /**
     * A stored `key`: 8 (or fewer) hex digits, else an earlier release's description holding `usbHidUsage: "0x…"`,
     * else the first key name it contains (named keys, then F-keys, digits, letters); null for none.
     */
    fun parseKey(text: String): Long? {
        text.toLongOrNull(16)?.let { return it }
        val normalized = text.lowercase()
        LEGACY_USAGE.find(normalized)?.let { match -> match.groupValues[1].toLongOrNull(16)?.let { return it } }
        for ((name, usage) in LEGACY_NAMES) if (name in normalized) return usage
        for (n in 1..12) {
            // f10..f12 before f1, which they contain.
            val key = 13 - n
            if ("f$key" in normalized) return HidKeys.function(key)
        }
        for (d in 0..9) if ("digit$d" in normalized) return HidKeys.digit(d)
        for (c in 'a'..'z') if ("key$c" in normalized) return HidKeys.letter(c)
        return null
    }

    private fun decode(entry: JsonObject): Hotkey? {
        val key = (entry["key"] as? JsonPrimitive)?.takeIf { it.isString }?.content?.let(::parseKey) ?: return null
        val modifiers = (entry["modifiers"] as? JsonArray ?: return null)
            .mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p.isString }?.content?.let(HotkeyModifier::fromId) }
            .toSet()
        return Hotkey(key, modifiers)
    }

    private val LEGACY_USAGE = Regex("""usbhidusage: "0x([0-9a-f]+)"""")

    private val LEGACY_NAMES = listOf(
        "space" to HidKeys.SPACE,
        "backspace" to HidKeys.BACKSPACE,
        "delete" to HidKeys.DELETE,
        "enter" to HidKeys.ENTER,
        "escape" to HidKeys.ESCAPE,
        "tab" to HidKeys.TAB,
        "capslock" to HidKeys.CAPS_LOCK,
        "arrowleft" to HidKeys.ARROW_LEFT,
        "arrowup" to HidKeys.ARROW_UP,
        "arrowright" to HidKeys.ARROW_RIGHT,
        "arrowdown" to HidKeys.ARROW_DOWN,
        "home" to HidKeys.HOME,
        "end" to HidKeys.END,
        "pageup" to HidKeys.PAGE_UP,
        "pagedown" to HidKeys.PAGE_DOWN,
        "equal" to HidKeys.EQUAL,
        "minus" to HidKeys.MINUS,
    )

    /** The order modifiers show in, a Mac's standard one: ⌃ ⌥ ⇧ ⌘. */
    private val MODIFIER_ORDER = listOf(HotkeyModifier.CONTROL, HotkeyModifier.ALT, HotkeyModifier.SHIFT, HotkeyModifier.META, HotkeyModifier.CAPS_LOCK, HotkeyModifier.FN)

    private val MODIFIER_LABELS = mapOf(
        HotkeyModifier.ALT to "Alt",
        HotkeyModifier.CONTROL to "Ctrl",
        HotkeyModifier.SHIFT to "Shift",
        HotkeyModifier.META to "Meta",
        HotkeyModifier.CAPS_LOCK to "CapsLock",
        HotkeyModifier.FN to "Fn",
    )

    private val MAC_MODIFIER_LABELS = mapOf(
        HotkeyModifier.CONTROL to "\u2303",
        HotkeyModifier.ALT to "\u2325",
        HotkeyModifier.SHIFT to "\u21e7",
        HotkeyModifier.META to "\u2318",
        HotkeyModifier.CAPS_LOCK to "\u21ea",
        HotkeyModifier.FN to "fn",
    )

    private val MAC_KEY_LABELS = mapOf(
        0x00070028L to "\u21a9",
        0x00070029L to "\u238b",
        0x0007002aL to "\u232b",
        0x0007002bL to "\u21e5",
        0x00070039L to "\u21ea",
        0x0007004aL to "\u2196",
        0x0007004bL to "\u21de",
        0x0007004cL to "\u2326",
        0x0007004dL to "\u2198",
        0x0007004eL to "\u21df",
        0x0007004fL to "\u2192",
        0x00070050L to "\u2190",
        0x00070051L to "\u2193",
        0x00070052L to "\u2191",
        0x000700e0L to "\u2303",
        0x000700e1L to "\u21e7",
        0x000700e2L to "\u2325",
        0x000700e3L to "\u2318",
        0x000700e4L to "\u2303",
        0x000700e5L to "\u21e7",
        0x000700e6L to "\u2325",
        0x000700e7L to "\u2318",
        0x00000012L to "fn",
    )
}
