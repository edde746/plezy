package com.edde746.plezy.input

/** Where a key press came from: a physical keyboard, or a remote, game controller or the system synthesizing it. */
enum class KeySource { KEYBOARD, REMOTE }

/** The navigation a key stands for in the player ([PlayerKeys.navigation]). */
enum class NavigationKey {
    NONE,

    /** Escape on a physical keyboard: it leaves fullscreen before it is Back where the player entered fullscreen. */
    PHYSICAL_ESCAPE,
    BACK,

    /** Home: the app's home, the platform's to handle. */
    HOME,
}

/** The player's key classes, shared by the store and every platform. */
object PlayerKeys {
    /**
     * The navigation [key] stands for. Escape is Back but on a physical keyboard ([PHYSICAL_ESCAPE][NavigationKey.PHYSICAL_ESCAPE]),
     * and always on Apple TV, whose keyboards' Escape is the remote's Menu. Backspace without modifiers on a physical
     * keyboard is Back, and Home without modifiers is Home, unless a text field has focus ([textEditing]), whose caret
     * they move; a remote's Home always is Home.
     */
    fun navigation(
        key: InputKey,
        modifiers: KeyModifiers,
        source: KeySource,
        appleTv: Boolean = false,
        textEditing: Boolean = false,
    ): NavigationKey {
        val keyboard = source == KeySource.KEYBOARD
        val bare = modifiers == KeyModifiers.NONE
        return when (key) {
            InputKey.ESCAPE -> if (keyboard && !appleTv) NavigationKey.PHYSICAL_ESCAPE else NavigationKey.BACK
            InputKey.BACK -> NavigationKey.BACK
            InputKey.BACKSPACE ->
                if (keyboard && bare && !textEditing) NavigationKey.BACK else NavigationKey.NONE
            InputKey.HOME ->
                if (bare && !(keyboard && textEditing)) NavigationKey.HOME else NavigationKey.NONE
            else -> NavigationKey.NONE
        }
    }

    /**
     * A hardware key that moves within what plays: fast forward and next track forward (true), rewind and previous
     * track back (false); null for any other key.
     */
    fun skipDirection(key: InputKey): Boolean? = when (key) {
        InputKey.MEDIA_FAST_FORWARD, InputKey.MEDIA_NEXT -> true
        InputKey.MEDIA_REWIND, InputKey.MEDIA_PREVIOUS -> false
        else -> null
    }

    /** A hardware play, pause or play/pause key's command; null for any other key. */
    fun transport(key: InputKey): PlayerCommand? = when (key) {
        InputKey.MEDIA_PLAY -> PlayerCommand.Play
        InputKey.MEDIA_PAUSE -> PlayerCommand.Pause
        InputKey.MEDIA_PLAY_PAUSE -> PlayerCommand.TogglePause
        else -> null
    }

    fun isDirection(key: InputKey): Boolean =
        key == InputKey.UP || key == InputKey.DOWN || key == InputKey.LEFT || key == InputKey.RIGHT

    /**
     * Keys the player consumes even when nothing is bound to them, so they never reach the screen beneath: the
     * directions, Select, Back and the remote's menu key.
     */
    fun isReserved(key: InputKey): Boolean =
        isDirection(key) || key == InputKey.SELECT || key == InputKey.BACK || key == InputKey.ESCAPE || key == InputKey.MENU
}
