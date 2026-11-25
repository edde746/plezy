package com.edde746.plezy.ui.probe

import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusEventModifierNode
import androidx.compose.ui.focus.FocusState
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.boundsInWindow
import androidx.compose.ui.layout.findRootCoordinates
import androidx.compose.ui.node.CompositionLocalConsumerModifierNode
import androidx.compose.ui.node.GlobalPositionAwareModifierNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.ObserverModifierNode
import androidx.compose.ui.node.currentValueOf
import androidx.compose.ui.node.observeReads

/**
 * Test hook: where named elements are on screen and which has focus, so a harness driving the real app with OS input
 * (the desktop harness launcher's `--report` runs; the Android test report)
 * knows what to click and where the D-pad is. Provided through [LocalLayoutProbe] only in those runs; otherwise
 * [layoutProbe] costs one null check per placement or focus change.
 */
fun interface LayoutProbe {
    /** [name] is at [bounds] (window or screen pixels, as [onScreen] asks), or gone (null). */
    fun place(name: String, bounds: Rect?)

    /** [name]'s element (its first focus target) gained or lost focus. */
    fun focus(name: String, focused: Boolean) {}

    /**
     * Whether [place] takes screen pixels rather than the window's: Android, where a menu is a window of its own
     * (its entries' window pixels are the menu's) and `adb shell input tap` takes screen pixels. The desktop draws
     * menus inside the app's window and the harness adds the window's position itself.
     */
    val onScreen: Boolean get() = false

    /**
     * Whether [place] is called at all: false for a probe that follows focus only (the Android perf runs), so a
     * scrolling list measures no element's bounds for it.
     */
    val placements: Boolean get() = true
}

val LocalLayoutProbe = staticCompositionLocalOf<LayoutProbe?> { null }

/**
 * Reports this element's bounds and focus under [name] to the [LocalLayoutProbe], if any. Place it before the
 * element's focus target. A region holding other elements (the screen's place, a column, a header with its back
 * button) takes [reportsFocus] false and reports its bounds only: Compose tells every focus event modifier between a
 * focused element and the next focus target above it that it is focused, so the region would otherwise report its
 * first element's focus under its own name, after that element's probe.
 */
fun Modifier.layoutProbe(name: String, reportsFocus: Boolean = true): Modifier = this then LayoutProbeElement(name, reportsFocus)

private data class LayoutProbeElement(val name: String, val reportsFocus: Boolean) : ModifierNodeElement<LayoutProbeNode>() {
    override fun create() = LayoutProbeNode(name, reportsFocus)

    override fun update(node: LayoutProbeNode) {
        if (node.name != name) node.rename(name)
        node.reportsFocus = reportsFocus
    }
}

private class LayoutProbeNode(var name: String, var reportsFocus: Boolean) :
    Modifier.Node(),
    GlobalPositionAwareModifierNode,
    FocusEventModifierNode,
    CompositionLocalConsumerModifierNode,
    ObserverModifierNode {
    var probe: LayoutProbe? = null
    private var focused = false

    /**
     * The element is named [to] from now on (one that changed what it is, the player's prompt button from skip to up
     * next): the old name is gone, and its focus goes with the new one. The new name's bounds come with the next
     * placement.
     */
    fun rename(to: String) {
        probe?.let {
            it.place(name, null)
            if (focused && reportsFocus) {
                it.focus(name, false)
                it.focus(to, true)
            }
        }
        name = to
    }

    override fun onAttach() = onObservedReadsChanged()

    override fun onObservedReadsChanged() = observeReads { probe = currentValueOf(LocalLayoutProbe) }

    override fun onGloballyPositioned(coordinates: LayoutCoordinates) {
        val probe = probe?.takeIf { it.placements } ?: return
        val bounds = coordinates.boundsInWindow()
        probe.place(name, if (probe.onScreen) bounds.translate(coordinates.findRootCoordinates().localToScreen(Offset.Zero)) else bounds)
    }

    override fun onFocusEvent(focusState: FocusState) {
        focused = focusState.isFocused
        if (reportsFocus) probe?.focus(name, focused)
    }

    override fun onDetach() {
        probe?.place(name, null)
        probe = null
    }
}
