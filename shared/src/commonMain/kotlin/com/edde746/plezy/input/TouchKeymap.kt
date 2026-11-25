package com.edde746.plezy.input

/**
 * Phones and tablets. The fingers on the video are the store's own (`InputEvent.Touch`: skip zones, two-finger taps,
 * edge swipes, holds, pinches); this maps what else reaches the video: a mouse's click shows or hides the controls (or
 * closes an open menu). Keys go through the store's key handling.
 */
internal object TouchKeymap : Keymap {
    override fun click(x: Float, context: InputContext): PlayerCommand? = when {
        context.menuOpen -> PlayerCommand.CloseMenu
        context.errorShown -> null
        else -> PlayerCommand.ToggleControls
    }

    override fun doubleClick(x: Float, context: InputContext): PlayerCommand? = null
}
