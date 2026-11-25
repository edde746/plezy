package com.edde746.plezy.ui.focus

import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.KeyInputModifierNode
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type
import androidx.compose.ui.node.CompositionLocalConsumerModifierNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.currentValueOf
import androidx.compose.ui.platform.LocalFocusManager

/**
 * The arrow keys move focus to the nearest element in their direction, as a D-pad does. Compose Desktop moves focus
 * with Tab only, so without this a keyboard can't walk a shelf or a grid. Place it once around the app's content: an
 * element that handles an arrow itself (a text field's cursor, the player's seek) keeps it, since this only sees the
 * arrows nothing under it took. On Android, where the platform does the same for the D-pad, it changes nothing.
 */
fun Modifier.arrowKeyFocus(): Modifier = this then ArrowKeyFocusElement

private data object ArrowKeyFocusElement : ModifierNodeElement<ArrowKeyFocusNode>() {
    override fun create() = ArrowKeyFocusNode()

    override fun update(node: ArrowKeyFocusNode) = Unit
}

private class ArrowKeyFocusNode :
    Modifier.Node(),
    KeyInputModifierNode,
    CompositionLocalConsumerModifierNode {
    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.type != KeyEventType.KeyDown) return false
        val direction = when (event.key) {
            Key.DirectionUp, Key.NumPadDirectionUp -> FocusDirection.Up
            Key.DirectionDown, Key.NumPadDirectionDown -> FocusDirection.Down
            Key.DirectionLeft, Key.NumPadDirectionLeft -> FocusDirection.Left
            Key.DirectionRight, Key.NumPadDirectionRight -> FocusDirection.Right
            else -> return false
        }
        return currentValueOf(LocalFocusManager).moveFocus(direction)
    }

    override fun onPreKeyEvent(event: KeyEvent): Boolean = false
}
