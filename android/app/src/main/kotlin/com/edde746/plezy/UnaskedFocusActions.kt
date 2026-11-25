package com.edde746.plezy

import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnectionWrapper
import android.view.inputmethod.InputMethodManager
import androidx.compose.ui.platform.PlatformTextInputInterceptor
import androidx.compose.ui.platform.PlatformTextInputMethodRequest
import androidx.compose.ui.platform.PlatformTextInputSession

/**
 * Turns a Next or Previous editor action a text field didn't ask for (its [EditorInfo.imeOptions] action) into putting
 * the keyboard away, focus and the cursor staying where they are. Fire TV's keyboard answers Back with Previous
 * instead of closing itself, whatever action the field asked for, and then moves the cursor to the text's start
 * (`setSelection(0, 0)`, seen on the Fire TV Stick 4K, Fire OS 8, 26 Oct); Compose answers an action the field has no
 * handler for by its default, which for those two moves focus out of the field (the keyboard closing with it): to the
 * element before it, or, from a screen's first element (Search's field), around to the TV column. So the cursor move
 * that follows such an action is dropped: the cursor stays after what was typed, where the next letters go and where
 * Right leaves the field (`remoteLeavesField`); until then the next letter went before the text and Right moved the
 * cursor. Every text field's connection goes through it ([androidx.compose.ui.platform.InterceptPlatformTextInput]
 * around the app's content), so Back with the keyboard up closes it and leaves focus and the cursor on the field, as
 * the other boxes' keyboards do.
 */
internal object UnaskedFocusActions : PlatformTextInputInterceptor {
    override suspend fun interceptStartInputMethod(request: PlatformTextInputMethodRequest, nextHandler: PlatformTextInputSession): Nothing {
        val view = nextHandler.view
        nextHandler.startInputMethod(
            PlatformTextInputMethodRequest { attributes ->
                val connection = request.createInputConnection(attributes)
                val asked = attributes.imeOptions and EditorInfo.IME_MASK_ACTION
                object : InputConnectionWrapper(connection, false) {
                    // The keyboard was put away for an action the field didn't ask for: its next cursor move is dropped.
                    private var closed = false

                    override fun performEditorAction(editorAction: Int): Boolean {
                        val movesFocus = editorAction == EditorInfo.IME_ACTION_NEXT || editorAction == EditorInfo.IME_ACTION_PREVIOUS
                        if (!movesFocus || editorAction == asked) return super.performEditorAction(editorAction)
                        view.context.getSystemService(InputMethodManager::class.java).hideSoftInputFromWindow(view.windowToken, 0)
                        closed = true
                        return true
                    }

                    override fun setSelection(start: Int, end: Int): Boolean {
                        if (!closed) return super.setSelection(start, end)
                        closed = false
                        return true
                    }
                }
            },
        )
    }
}
