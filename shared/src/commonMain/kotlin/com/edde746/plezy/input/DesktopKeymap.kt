package com.edde746.plezy.input

/**
 * Mouse clicks on the video (Windows, Linux, macOS): a click toggles pause, or shows and hides the controls as the
 * profile has it ([InputContext.videoClick]) or when the viewer may not control playback, at once; a second click
 * within the double-click interval toggles fullscreen alone (the first one already paused or toggled the controls).
 */
internal class DesktopKeymap : Keymap {
    override fun click(x: Float, context: InputContext): PlayerCommand? = when {
        context.menuOpen -> PlayerCommand.CloseMenu
        context.errorShown -> null
        context.videoClick == VideoClickAction.CONTROLS || !context.canControl -> PlayerCommand.ToggleControls
        else -> PlayerCommand.TogglePause
    }

    override fun doubleClick(x: Float, context: InputContext): PlayerCommand = PlayerCommand.ToggleFullscreen
}
