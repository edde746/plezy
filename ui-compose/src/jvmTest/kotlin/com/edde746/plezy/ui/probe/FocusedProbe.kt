package com.edde746.plezy.ui.probe

import androidx.compose.ui.geometry.Rect

/** The focused element's harness name, as the device harness reads it. */
internal class FocusedProbe : LayoutProbe {
    var focused: String? = null
    override val placements: Boolean get() = false
    override fun place(name: String, bounds: Rect?) {}
    override fun focus(name: String, focused: Boolean) {
        if (focused) this.focused = name else if (this.focused == name) this.focused = null
    }
}
