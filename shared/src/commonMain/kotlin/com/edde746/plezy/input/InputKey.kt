package com.edde746.plezy.input

/**
 * A key, platform-neutral: each platform translates its raw key codes (Android `KeyEvent`, Compose
 * `Key`, `UIPress`/`NSEvent`) into one of these and hands them to the player store, and the shared keymaps decide
 * what they mean. A key the platform can't translate is simply not passed on.
 *
 * Letters, digits and punctuation are logical keys: the character the key types without modifiers, so shortcuts
 * follow the keyboard layout (`M` mutes on an AZERTY keyboard too). A key typing a letter or digit of another script
 * than Latin (a Russian, Greek or Arabic layout) is the key in its place on a US keyboard, so the player's keys work on
 * every layout. Arrow keys and a remote's D-pad are the same keys.
 */
enum class InputKey {
    UP, DOWN, LEFT, RIGHT,

    /** Enter/Return, the D-pad centre, a remote's Select/OK. */
    SELECT,

    /** Android Back, the tvOS remote's Back (Menu) button. Desktop keyboards send [ESCAPE] instead. */
    BACK,
    ESCAPE, SPACE, BACKSPACE, TAB, HOME, END, PAGE_UP, PAGE_DOWN,
    F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,

    A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
    DIGIT_0, DIGIT_1, DIGIT_2, DIGIT_3, DIGIT_4, DIGIT_5, DIGIT_6, DIGIT_7, DIGIT_8, DIGIT_9,

    /** `-` on the main keyboard or the numeric keypad. */
    MINUS,

    /** The `=`/`+` key or the numeric keypad's `+`. */
    PLUS,
    BRACKET_LEFT, BRACKET_RIGHT, COMMA, PERIOD,

    /** A remote's menu/options key (Android `KEYCODE_MENU`, `KEYCODE_SETTINGS`). */
    MENU,

    /** A remote's info/guide key (Android `KEYCODE_INFO`). */
    INFO,

    /** A remote's subtitles key (Android `KEYCODE_CAPTIONS`). */
    CAPTIONS,

    /** A remote's audio-track key (Android `KEYCODE_MEDIA_AUDIO_TRACK`). */
    AUDIO_TRACK,

    /** A remote's channel up and down keys (Android `KEYCODE_CHANNEL_UP`, `KEYCODE_CHANNEL_DOWN`). */
    CHANNEL_UP, CHANNEL_DOWN,

    MEDIA_PLAY_PAUSE, MEDIA_PLAY, MEDIA_PAUSE, MEDIA_STOP, MEDIA_NEXT, MEDIA_PREVIOUS, MEDIA_FAST_FORWARD, MEDIA_REWIND,
    ;

    /** 0–9 for a digit key, otherwise null. */
    val digitValue: Int? get() = (ordinal - DIGIT_0.ordinal).takeIf { it in 0..9 }

    companion object {
        /** The digit key for [value] (0–9). */
        fun digit(value: Int): InputKey {
            require(value in 0..9) { "not a digit: $value" }
            return entries[DIGIT_0.ordinal + value]
        }

        /** The letter key [index] letters after [A] (0–25). */
        fun letter(index: Int): InputKey {
            require(index in 0..25) { "not a letter: $index" }
            return entries[A.ordinal + index]
        }
    }
}
