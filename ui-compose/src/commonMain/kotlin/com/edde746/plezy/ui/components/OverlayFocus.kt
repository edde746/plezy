package com.edde746.plezy.ui.components

import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusEventModifierNode
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.FocusRequesterModifierNode
import androidx.compose.ui.focus.FocusState
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusTarget
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.focus.requestFocus
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.layout.LocalPinnableContainer
import androidx.compose.ui.layout.PinnableContainer
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.boundsInWindow
import androidx.compose.ui.node.CompositionLocalConsumerModifierNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.ObserverModifierNode
import androidx.compose.ui.node.TraversableNode
import androidx.compose.ui.node.TraversableNode.Companion.TraverseDescendantsAction
import androidx.compose.ui.node.currentValueOf
import androidx.compose.ui.node.findNearestAncestor
import androidx.compose.ui.node.observeReads
import androidx.compose.ui.node.requireLayoutCoordinates
import androidx.compose.ui.node.traverseDescendants
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.ScreenAnchorKey
import com.edde746.plezy.ui.focus.ScreenAnchorNode
import com.edde746.plezy.ui.focus.ScreenFocus

/**
 * Makes this control one an overlay gives focus back to: a dialog, sheet or line ([ModalOverlay], [PlezySheet],
 * [TopOverlay]) that opens while it has focus returns focus to it once it closes, or, when it is gone by then (the
 * action the overlay confirmed replaced it: Trakt's Connect turned into Disconnect), to the control nearest its place on
 * its screen ([OverlayHost.closed]). Every control has it: [PlezySurface] and [PlezyToggleSurface] (the buttons,
 * rows, chips and icon buttons), the cards and the links. Place it before the control's focus target.
 */
fun Modifier.overlayOpener(): Modifier = this then OverlayOpenerElement

/**
 * Whether the controls composed here are openers ([overlayOpener]). The navigation's aren't: it opens no overlay, and
 * focus that sat there as one opened (the platform puts focus on the window's first control, the navigation, when the
 * focused one leaves) goes to the screen on view as it closes, never back to the navigation ([NavigationScaffold]).
 */
internal val LocalOverlayOpeners = staticCompositionLocalOf { true }

private data object OverlayOpenerElement : ModifierNodeElement<OpenerNode>() {
    override fun create() = OpenerNode()

    override fun update(node: OpenerNode) = Unit
}

private object OpenerKey

/** [overlayOpener]'s node: tells the [OverlayHost] while its control has focus, and gives it focus. */
internal class OpenerNode :
    Modifier.Node(),
    FocusEventModifierNode,
    FocusRequesterModifierNode,
    CompositionLocalConsumerModifierNode,
    ObserverModifierNode,
    TraversableNode {
    override val traverseKey: Any get() = OpenerKey

    private var host: OverlayHost? = null
    private var focused = false

    /** The screen the control is on, null outside one (the player, an overlay). */
    var screen: ScreenFocus? = null
        private set

    /** The lazy list item the control is in ([LocalPinnableContainer], one per item): its row. */
    var item: PinnableContainer? = null
        private set

    /** Where the control was when it last had focus. */
    var place: ControlPlace? = null
        private set

    override fun onAttach() = onObservedReadsChanged()

    override fun onObservedReadsChanged() = observeReads {
        val opener = currentValueOf(LocalOverlayOpeners)
        host = if (opener) currentValueOf(LocalOverlayHost) else null
        screen = if (opener) (findNearestAncestor(ScreenAnchorKey) as? ScreenAnchorNode)?.screen else null
        item = if (opener) currentValueOf(LocalPinnableContainer) else null
    }

    override fun onFocusEvent(focusState: FocusState) {
        // Told after it has left: [onDetach] has seen to it.
        if (!isAttached) return
        val host = host ?: return
        if (focusState.isFocused) {
            focused = true
            host.focusedControl = this
            place = currentPlace()
        } else if (focused) {
            focused = false
            if (host.focusedControl === this) host.focusedControl = null
            if (host.returned === this) {
                host.returned = null
                // Compose gives focus to the next element before telling the one losing it: nothing focused now is a
                // drop (it is leaving, or was disabled), and the control nearest its place gets focus; else focus moved
                // on (a key, a screen taking it), and stays where it went.
                if (!host.appFocus.held) place?.let(host::left)
            }
        }
    }

    override fun onDetach() {
        val host = host ?: return
        if (host.focusedControl === this) host.focusedControl = null
        if (host.returned === this) {
            host.returned = null
            // Gone with focus an overlay gave it back, before its focus target told it: the control nearest its place
            // gets it.
            if (focused) place?.let(host::left)
        }
        focused = false
        this.host = null
    }

    /** Where the control is now; null once it has left. */
    fun currentPlace(): ControlPlace? =
        if (isAttached) ControlPlace(screen, item, requireLayoutCoordinates().boundsInRoot()).also { place = it } else null

    /** Focus to the control; false once it has left, or while it is disabled. */
    fun takeFocus(): Boolean = isAttached && requestFocus()

    /** How far the control's centre is from [bounds]' (root pixels); null while it isn't on view. */
    fun distanceTo(bounds: Rect): Float? {
        if (!isAttached) return null
        val coordinates = requireLayoutCoordinates()
        if (coordinates.boundsInWindow().isEmpty) return null
        return (coordinates.boundsInRoot().center - bounds.center).getDistance()
    }
}

/** A control's place: its [screen], its lazy list [item] (its row) and its [bounds] in the root (pixels). */
internal class ControlPlace(val screen: ScreenFocus?, val item: PinnableContainer?, val bounds: Rect) {
    /**
     * Focus to the control nearest this place on its screen: one in the same row first, then by distance, never one off
     * view or outside the screen (the navigation). The row comes first because what changed the screen can also move
     * it: a notice arriving at the top of the list as Trakt connects pushes the row down by about a row.
     */
    fun nearest(): OpenerNode? {
        val anchor = screen?.anchor ?: return null
        val candidates = ArrayList<Pair<OpenerNode, Float>>()
        anchor.traverseDescendants(OpenerKey) { node ->
            if (node is OpenerNode && node.screen === screen) node.distanceTo(bounds)?.let { candidates += node to it }
            TraverseDescendantsAction.ContinueTraversal
        }
        candidates.sortWith(compareBy({ (node, _) -> item == null || node.item !== item }, { (_, distance) -> distance }))
        return candidates.firstOrNull { (node, _) -> node.takeFocus() }?.first
    }
}

/**
 * Where focus goes back to once an overlay closes ([OverlayHost.opener]): the element that had focus as it opened, by
 * its [key] where a screen's [memory] knows it, and as the [control] it is ([overlayOpener]) with its [place].
 */
internal class FocusOpener(
    private val memory: FocusMemory?,
    private val key: String?,
    private val control: OpenerNode?,
    private val place: ControlPlace?,
) {
    /** Focus to the element itself; false while it can't take it (gone, or still disabled while the overlay was up). */
    fun exact(host: OverlayHost): Boolean {
        if (memory != null && key != null) return memory.focus(key)
        if (control?.takeFocus() != true) return false
        host.returned = control
        return true
    }

    /**
     * Focus to the element, else, once it is gone, to the place its screen keeps for that ([FocusMemory]'s fallback: the
     * Board's first card), else to the control nearest its place ([ControlPlace.nearest]); false when none takes it.
     */
    fun restore(host: OverlayHost): Boolean {
        if (exact(host)) return true
        if (memory?.fallback?.let(memory::place) == true) return true
        host.returned = place?.nearest() ?: return false
        return true
    }
}

/**
 * Holds focus between an overlay leaving and focus going back to its opener ([OverlayHost.closed]): a focus target of
 * no size beside the app, which takes focus only while asked to, so the platform never moves it to the window's first
 * control (the navigation) meanwhile.
 */
internal class FocusHolder {
    private val requester = FocusRequester()
    private var armed = false

    /** Whether it has focus. */
    var held = false
        private set

    /** Its place, beside the app's content in the [OverlayHostBox]. */
    val modifier: Modifier = Modifier
        .onFocusChanged { state ->
            held = state.isFocused
            if (!held) armed = false
        }
        .focusRequester(requester)
        .focusProperties { canFocus = armed }
        .focusTarget()

    /** Takes focus. */
    fun take() {
        armed = true
        if (!requester.requestFocus()) armed = false
    }
}
