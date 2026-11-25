package com.edde746.plezy.input

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull

/**
 * Every keyboard shortcut the video player has, in the order the shortcut settings list them. [id] is what the
 * `keyboard_hotkeys` setting stores the binding under, [default] the binding until the user picks another.
 * [repeatable] actions repeat while their key is held (the zoom); the others act once per press. [requiresPlayback]
 * actions drive playback (refused where a watch-together room doesn't let this device control it),
 * [requiresMediaNavigation] ones change the item.
 */
enum class ShortcutAction(
    val id: String,
    val default: Hotkey,
    val repeatable: Boolean = false,
    val requiresPlayback: Boolean = false,
    val requiresMediaNavigation: Boolean = false,
) {
    PLAY_PAUSE("play_pause", Hotkey(InputKey.SPACE), requiresPlayback = true),
    VOLUME_UP("volume_up", Hotkey(InputKey.UP)),
    VOLUME_DOWN("volume_down", Hotkey(InputKey.DOWN)),
    SEEK_FORWARD("seek_forward", Hotkey(InputKey.RIGHT), requiresPlayback = true),
    SEEK_BACKWARD("seek_backward", Hotkey(InputKey.LEFT), requiresPlayback = true),
    SEEK_FORWARD_LARGE("seek_forward_large", Hotkey(InputKey.RIGHT, KeyModifiers(shift = true)), requiresPlayback = true),
    SEEK_BACKWARD_LARGE("seek_backward_large", Hotkey(InputKey.LEFT, KeyModifiers(shift = true)), requiresPlayback = true),
    FULLSCREEN_TOGGLE("fullscreen_toggle", Hotkey(InputKey.F)),
    MUTE_TOGGLE("mute_toggle", Hotkey(InputKey.M)),
    SUBTITLE_TOGGLE("subtitle_toggle", Hotkey(InputKey.S)),
    AUDIO_TRACK_NEXT("audio_track_next", Hotkey(InputKey.A), requiresPlayback = true),
    SUBTITLE_TRACK_NEXT("subtitle_track_next", Hotkey(InputKey.S, KeyModifiers(shift = true)), requiresPlayback = true),
    CHAPTER_NEXT("chapter_next", Hotkey(InputKey.N), requiresPlayback = true),
    CHAPTER_PREVIOUS("chapter_previous", Hotkey(InputKey.P), requiresPlayback = true),
    EPISODE_NEXT("episode_next", Hotkey(InputKey.N, KeyModifiers(shift = true)), requiresMediaNavigation = true),
    EPISODE_PREVIOUS("episode_previous", Hotkey(InputKey.P, KeyModifiers(shift = true)), requiresMediaNavigation = true),
    SPEED_INCREASE("speed_increase", Hotkey(InputKey.PLUS), requiresPlayback = true),
    SPEED_DECREASE("speed_decrease", Hotkey(InputKey.MINUS), requiresPlayback = true),
    SPEED_RESET("speed_reset", Hotkey(InputKey.R), requiresPlayback = true),
    ZOOM_IN("zoom_in", Hotkey(InputKey.PLUS, KeyModifiers(alt = true)), repeatable = true),
    ZOOM_OUT("zoom_out", Hotkey(InputKey.MINUS, KeyModifiers(alt = true)), repeatable = true),
    ZOOM_RESET("zoom_reset", Hotkey(InputKey.BACKSPACE, KeyModifiers(alt = true))),
    SUB_SEEK_NEXT("sub_seek_next", Hotkey(InputKey.RIGHT, KeyModifiers(ctrl = true)), requiresPlayback = true),
    SUB_SEEK_PREV("sub_seek_prev", Hotkey(InputKey.LEFT, KeyModifiers(ctrl = true)), requiresPlayback = true),
    SHADER_TOGGLE("shader_toggle", Hotkey(InputKey.G)),
    SKIP_MARKER("skip_marker", Hotkey(InputKey.SELECT), requiresPlayback = true),
    SCREENSHOT("screenshot", Hotkey(InputKey.S, KeyModifiers(ctrl = true))),
    ;

    companion object {
        private val byId = entries.associateBy { it.id }

        /** The action stored under [id], or null for one this release doesn't know. */
        fun fromId(id: String): ShortcutAction? = byId[id]
    }
}

/**
 * A key with exactly these modifiers held: Ctrl+S is not S, and Command (meta) never stands in for Ctrl, so a
 * system's Command shortcuts never reach the player's.
 */
data class Hotkey(val key: InputKey, val modifiers: KeyModifiers = KeyModifiers.NONE) {
    fun matches(key: InputKey, modifiers: KeyModifiers): Boolean = key == this.key && modifiers == this.modifiers
}

/**
 * The player's shortcut bindings: the defaults, with the user's from the `keyboard_hotkeys` setting over them
 * ([decode]); an action bound to null has no key. [unknown] are the keys stored for actions this release doesn't know:
 * they do nothing, but a press of one is still the player's ([isUnknown]), so a stale binding never reaches another
 * handler.
 */
class Hotkeys(private val bindings: Map<ShortcutAction, Hotkey?>, private val unknown: List<Hotkey> = emptyList()) {
    /** The action [key] with [modifiers] triggers, if any. */
    fun actionFor(key: InputKey, modifiers: KeyModifiers): ShortcutAction? =
        bindings.entries.firstOrNull { it.value?.matches(key, modifiers) == true }?.key

    fun binding(action: ShortcutAction): Hotkey? = bindings[action]

    /** [key] with [modifiers] is what [action] is bound to. */
    fun isBound(action: ShortcutAction, key: InputKey, modifiers: KeyModifiers): Boolean =
        bindings[action]?.matches(key, modifiers) == true

    /** [key] with [modifiers] is bound to an action this release doesn't know. */
    fun isUnknown(key: InputKey, modifiers: KeyModifiers): Boolean = unknown.any { it.matches(key, modifiers) }

    override fun equals(other: Any?): Boolean = other is Hotkeys && other.bindings == bindings && other.unknown == unknown

    override fun hashCode(): Int = 31 * bindings.hashCode() + unknown.hashCode()

    override fun toString(): String = "Hotkeys($bindings, unknown=$unknown)"

    companion object {
        val DEFAULT = Hotkeys(ShortcutAction.entries.associateWith { it.default })

        /**
         * The bindings the `keyboard_hotkeys` setting stores, merged over the defaults: each entry is an action id
         * with `{"key": "<USB HID usage, 8 hex digits>", "modifiers": ["shift", "control", "alt", "meta", …]}` or
         * `{"disabled": true}`; an earlier format's key name (`"arrowleft"`, a debug string carrying the HID usage)
         * reads too. Entries that don't parse are dropped (the default stays); a key this player has no key for (a
         * function key past F12, a game button) binds the action to nothing. An unknown action's key is kept apart.
         */
        fun decode(stored: JsonObject): Hotkeys {
            val result = ShortcutAction.entries.associateWith<ShortcutAction, Hotkey?> { it.default }.toMutableMap()
            val unknown = mutableListOf<Hotkey>()
            for ((id, value) in stored) {
                val action = ShortcutAction.fromId(id)
                val entry = value as? JsonObject ?: continue
                if ((entry["disabled"] as? JsonPrimitive)?.booleanOrNull == true) {
                    if (action != null) result[action] = null
                    continue
                }
                val keyText = (entry["key"] as? JsonPrimitive)?.takeIf { it.isString }?.content ?: continue
                val modifierNames = (entry["modifiers"] as? JsonArray ?: continue)
                    .mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p.isString }?.content }
                val usage = keyText.toLongOrNull(16) ?: legacyUsage(keyText) ?: continue
                val modifiers = KeyModifiers(
                    shift = "shift" in modifierNames,
                    ctrl = "control" in modifierNames,
                    alt = "alt" in modifierNames,
                    meta = "meta" in modifierNames,
                )
                val hotkey = HidUsage.key(usage)?.let { Hotkey(it, modifiers) }
                if (action != null) result[action] = hotkey else hotkey?.let(unknown::add)
            }
            return Hotkeys(result, unknown)
        }

        private val LEGACY_NAMES: List<Pair<String, InputKey>> = buildList {
            add("space" to InputKey.SPACE)
            add("backspace" to InputKey.BACKSPACE)
            add("enter" to InputKey.SELECT)
            add("escape" to InputKey.ESCAPE)
            add("tab" to InputKey.TAB)
            add("arrowleft" to InputKey.LEFT)
            add("arrowup" to InputKey.UP)
            add("arrowright" to InputKey.RIGHT)
            add("arrowdown" to InputKey.DOWN)
            add("home" to InputKey.HOME)
            add("end" to InputKey.END)
            add("pageup" to InputKey.PAGE_UP)
            add("pagedown" to InputKey.PAGE_DOWN)
            add("equal" to InputKey.PLUS)
            add("minus" to InputKey.MINUS)
            // Two-digit function keys first: "f1" is in "f10".
            for (n in 12 downTo 1) add("f$n" to InputKey.entries[InputKey.F1.ordinal + n - 1])
            for (n in 0..9) add("digit$n" to InputKey.digit(n))
            for (i in 0..25) add("key${'a' + i}" to InputKey.letter(i))
        }

        private val DEBUG_USAGE = Regex("""usbhidusage: "0x([0-9a-f]+)"""")

        /** The HID usage an earlier release's key name stands for: by the usage it carries, else by its name. */
        private fun legacyUsage(text: String): Long? {
            val normalized = text.lowercase()
            DEBUG_USAGE.find(normalized)?.let { return it.groupValues[1].toLongOrNull(16) }
            return LEGACY_NAMES.firstOrNull { normalized.contains(it.first) }?.second?.let(HidUsage::of)
        }
    }
}

/**
 * The USB HID usages (page shl 16 or usage) the `keyboard_hotkeys` setting stores keys as, for the keys the player
 * knows: physical keys, so a letter is the key in its place on a US keyboard.
 */
object HidUsage {
    private val USAGES: Map<InputKey, Long> = buildMap {
        for (i in 0..25) put(InputKey.letter(i), 0x00070004L + i)
        for (n in 1..9) put(InputKey.digit(n), 0x0007001dL + n)
        put(InputKey.digit(0), 0x00070027L)
        put(InputKey.SELECT, 0x00070028L)
        put(InputKey.ESCAPE, 0x00070029L)
        put(InputKey.BACKSPACE, 0x0007002aL)
        put(InputKey.TAB, 0x0007002bL)
        put(InputKey.SPACE, 0x0007002cL)
        put(InputKey.MINUS, 0x0007002dL)
        put(InputKey.PLUS, 0x0007002eL)
        put(InputKey.BRACKET_LEFT, 0x0007002fL)
        put(InputKey.BRACKET_RIGHT, 0x00070030L)
        put(InputKey.COMMA, 0x00070036L)
        put(InputKey.PERIOD, 0x00070037L)
        for (n in 1..12) put(InputKey.entries[InputKey.F1.ordinal + n - 1], 0x00070039L + n)
        put(InputKey.HOME, 0x0007004aL)
        put(InputKey.PAGE_UP, 0x0007004bL)
        put(InputKey.END, 0x0007004dL)
        put(InputKey.PAGE_DOWN, 0x0007004eL)
        put(InputKey.RIGHT, 0x0007004fL)
        put(InputKey.LEFT, 0x00070050L)
        put(InputKey.DOWN, 0x00070051L)
        put(InputKey.UP, 0x00070052L)
        put(InputKey.MENU, 0x00070076L)
        put(InputKey.MEDIA_PLAY, 0x000c00b0L)
        put(InputKey.MEDIA_PAUSE, 0x000c00b1L)
        put(InputKey.MEDIA_FAST_FORWARD, 0x000c00b3L)
        put(InputKey.MEDIA_REWIND, 0x000c00b4L)
        put(InputKey.MEDIA_NEXT, 0x000c00b5L)
        put(InputKey.MEDIA_PREVIOUS, 0x000c00b6L)
        put(InputKey.MEDIA_STOP, 0x000c00b7L)
        put(InputKey.MEDIA_PLAY_PAUSE, 0x000c00cdL)
    }

    private val KEYS: Map<Long, InputKey> = USAGES.entries.associate { (key, usage) -> usage to key } + mapOf(
        // The numeric keypad's Enter, minus and plus are the same keys to the player.
        0x00070058L to InputKey.SELECT,
        0x00070056L to InputKey.MINUS,
        0x00070057L to InputKey.PLUS,
    )

    fun of(key: InputKey): Long? = USAGES[key]

    fun key(usage: Long): InputKey? = KEYS[usage]
}
