package com.edde746.plezy.ui.focus

import androidx.compose.runtime.Stable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusEventModifierNode
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.FocusState
import androidx.compose.ui.focus.FocusTargetModifierNode
import androidx.compose.ui.focus.Focusability
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.KeyInputModifierNode
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.node.CompositionLocalConsumerModifierNode
import androidx.compose.ui.node.DelegatingNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.ObserverModifierNode
import androidx.compose.ui.node.TraversableNode
import androidx.compose.ui.node.currentValueOf
import androidx.compose.ui.node.findNearestAncestor
import androidx.compose.ui.node.observeReads
import androidx.compose.ui.platform.LocalInputModeManager
import com.edde746.plezy.ui.components.LocalOverlayHost
import com.edde746.plezy.ui.components.OverlayHost
import kotlinx.coroutines.launch

/**
 * A surface the D-pad works in (the player, a screen, a dialog) never sits on view with nothing focused. When the
 * element that has focus in it is disabled or leaves (Previous at the first episode, a row removed, a button swapped
 * for another), Compose drops focus from the whole window, and the platform leaves it nowhere (desktop) or hands it to
 * the window's first element (Android: the player itself, where the D-pad moves nothing, or the navigation). A frame
 * later, and once no surface is handing focus on itself ([AppFocus.handOffs]: a shelf's card to its neighbour; for up
 * to [FOCUS_RETRY_FRAMES] frames), unless focus has come back to one of the surface's elements meanwhile, [home] takes
 * it: [home] moves focus to where the surface keeps it (the player's play/pause, a screen's remembered element or its
 * first) and says whether it could. A control an overlay gave focus back to goes to the control nearest its place
 * instead ([OverlayHost.follow]). While [home] can't (what replaced the element isn't composed yet) the surface holds
 * focus itself, and [home] is asked again each frame for up to [FOCUS_RETRY_FRAMES] frames, then at each D-pad key the
 * surface gets meanwhile: the key takes focus to [home], or where [home] still can't moves it on as it would from the
 * surface. Focus moved on purpose (to a sheet, the navigation, the next screen) is left alone, and so is the touch
 * screen (Android's touch mode focuses nothing). Of surfaces inside one another the innermost takes the drop.
 *
 * Place it before the surface's focus target, the `focusable` the surface is (the player, which holds focus itself
 * while its controls are down); a surface that is a group of elements takes [focusHomeGroup] instead. It needs the app's
 * [com.edde746.plezy.ui.components.OverlayHostBox] around it, which tells a drop from a move.
 */
fun Modifier.focusHome(home: () -> Boolean): Modifier = this then FocusHomeElement(home)

/**
 * [focusHome] for a surface that is a group of elements (a screen, a Settings section, a dialog's card): a focus group
 * around the surface's own, which takes focus itself only while [home] can't, so the D-pad's keys reach the surface
 * then. Place it before the surface's focus group.
 */
fun Modifier.focusHomeGroup(home: () -> Boolean): Modifier = this then FocusHomeElement(home) then HoldingGroupElement

/** [focusHomeGroup] for [screen], which can then hold focus itself ([ScreenFocus.hold]). */
private fun Modifier.screenHomeGroup(screen: ScreenFocus): Modifier = this then FocusHomeElement(screen::home, screen) then HoldingGroupElement

/** The keys that move focus, or press the focused element, on a remote. */
private val DpadKeys = setOf(Key.DirectionUp, Key.DirectionDown, Key.DirectionLeft, Key.DirectionRight, Key.DirectionCenter)

private data class FocusHomeElement(val home: () -> Boolean, val screen: ScreenFocus? = null) : ModifierNodeElement<FocusHomeNode>() {
    override fun create() = FocusHomeNode(home, screen)

    override fun update(node: FocusHomeNode) {
        node.home = home
        node.bind(screen)
    }
}

internal class FocusHomeNode(var home: () -> Boolean, private var screen: ScreenFocus?) :
    Modifier.Node(),
    FocusEventModifierNode,
    KeyInputModifierNode,
    CompositionLocalConsumerModifierNode,
    TraversableNode {
    override val traverseKey: Any get() = FocusHomeKey

    /** A group surface's own focus target ([focusHomeGroup]). */
    var group: FocusTargetModifierNode? = null
    private var focus: FocusState? = null

    /** The surface itself has focus (the player, or a group holding it), not one of its elements. */
    private val holding get() = focus?.isFocused == true

    /** One of the surface's elements has focus, not the surface itself. */
    private val onElement get() = focus?.let { it.hasFocus && !it.isFocused } == true

    override fun onAttach() {
        screen?.homeNode = this
    }

    override fun onDetach() {
        if (screen?.homeNode === this) screen?.homeNode = null
    }

    fun bind(screen: ScreenFocus?) {
        if (this.screen === screen) return
        if (isAttached) onDetach()
        this.screen = screen
        if (isAttached) onAttach()
    }

    override fun onFocusEvent(focusState: FocusState) {
        val had = focus?.hasFocus == true
        focus = focusState
        if (!isAttached) return
        // Focus gone on from the group that held it: the group takes none again (the arrow keys, a screen's first
        // focus pass it by). Not changed in the middle of Compose's own focus change.
        if (!focusState.isFocused && group?.focusability == Focusability.Always) {
            coroutineScope.launch { if (!holding) group?.focusability = Focusability.Never }
        }
        if (!had || focusState.hasFocus) return
        val host = currentValueOf(LocalOverlayHost) ?: return
        val app = host.appFocus
        // Compose gives focus to the next element before telling the one losing it: nothing focused now is a drop. The
        // surfaces around one that took it hear of it next, and leave it.
        if (app.held || app.dropTaken) return
        if (currentValueOf(LocalInputModeManager).inputMode == InputMode.Touch) return
        app.dropTaken = true
        coroutineScope.launch {
            app.dropTaken = false
            // After the surfaces' own handovers (a shelf's card to its neighbour), for up to FOCUS_RETRY_FRAMES frames.
            var frames = 0
            do withFrameNanos { } while (app.handOffs.isNotEmpty() && ++frames < FOCUS_RETRY_FRAMES)
            // Where the platform put focus meanwhile (Android: the window's first element) was no one's choice.
            if (onElement || host.follow() || home() || !hold()) return@launch
            repeat(FOCUS_RETRY_FRAMES - 1) {
                withFrameNanos { }
                // Focus moved on from the surface meanwhile (a key, the screen's own first focus): left where it went.
                if (!holding || home()) return@launch
            }
        }.invokeOnCompletion { app.dropTaken = false }
    }

    /** The surface takes focus itself: true if it has it (the player, which Android gives it to) or its group took it. */
    fun hold(): Boolean {
        if (holding) return true
        val group = group ?: return false
        group.focusability = Focusability.Always
        if (group.requestFocus()) return true
        group.focusability = Focusability.Never
        return false
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.type != KeyEventType.KeyDown || !holding || event.key !in DpadKeys) return false
        home()
        return !holding
    }

    override fun onPreKeyEvent(event: KeyEvent): Boolean = false
}

private object FocusHomeKey

private data object HoldingGroupElement : ModifierNodeElement<HoldingGroupNode>() {
    override fun create() = HoldingGroupNode()

    override fun update(node: HoldingGroupNode) = Unit
}

/** [focusHomeGroup]'s focus target: a group, focusable only while its [FocusHomeNode] holds focus on it. */
private class HoldingGroupNode : DelegatingNode() {
    private val target = delegate(FocusTargetModifierNode(focusability = Focusability.Never))
    private var owner: FocusHomeNode? = null

    override fun onAttach() {
        owner = findNearestAncestor(FocusHomeKey) as FocusHomeNode
        owner?.group = target
    }

    override fun onDetach() {
        if (owner?.group === target) owner?.group = null
        owner = null
    }
}

/**
 * Whether anything in the app has focus: a focus group around the app and its overlays
 * ([com.edde746.plezy.ui.components.OverlayHostBox]), its state as Compose holds it, which [focusHome] reads to tell
 * focus dropped from focus moved.
 */
internal class AppFocus {
    private var group: FocusTargetModifierNode? = null

    val held: Boolean get() = group?.focusState?.hasFocus == true

    /** A surface has taken the drop being told: the surfaces around it leave it. */
    var dropTaken = false

    /**
     * The surfaces handing focus on themselves (a shelf whose focused card left, to the card taking its place): a
     * [focusHome] whose focus dropped waits until there are none (for up to [FOCUS_RETRY_FRAMES] frames), then takes
     * the drop only if they left it nowhere.
     */
    val handOffs = HashSet<Any>()

    /** The group, for the box around the app and its overlays. */
    val modifier: Modifier = AppFocusElement(this)

    private data class AppFocusElement(val focus: AppFocus) : ModifierNodeElement<AppFocusNode>() {
        override fun create() = AppFocusNode(focus)

        override fun update(node: AppFocusNode) = Unit
    }

    private class AppFocusNode(val focus: AppFocus) : DelegatingNode() {
        private val group = delegate(FocusTargetModifierNode(focusability = Focusability.Never))

        override fun onAttach() {
            focus.group = group
        }

        override fun onDetach() {
            if (focus.group === group) focus.group = null
        }
    }
}

/**
 * A screen of the back stack as a [focusHomeGroup] surface: focus that drops in it goes back to the element the
 * screen's [FocusMemory] that had focus last remembers, else to that memory's fallback ([RestoreFocus]: the Board's
 * first card, Detail's Play), else to the screen's first element. [onView] says whether the screen is the one on view
 * (the top one with no sheet over it; read in a snapshot, so [RestoreFocus] follows it). Provided to the screen
 * ([LocalScreenFocus]), where [rememberFocusMemory] finds it. A press, a touch or the wheel on the screen ends the focus
 * the screen placed itself ([FocusMemory.endPlacement]): the screen no longer moves it, nor scrolls back to it. Its
 * place in the layout ([anchor]) holds the screen's controls, among which an overlay that closes finds the one nearest
 * its opener ([com.edde746.plezy.ui.components.overlayOpener]); it also tells whether focus is in the screen
 * ([focused]) and counts the keys that took it out ([keyExits]: the user's moves to the navigation, which [RestoreFocus]
 * leaves alone).
 */
@Stable
class ScreenFocus(val onView: () -> Boolean) {
    internal var memory: FocusMemory? = null

    /** Focus is in the screen: on one of its elements, or the screen holding it. */
    internal var focused = false

    /** How many times a key (an arrow, Tab, Select) took focus out of the screen. */
    internal var keyExits = 0

    private val group = FocusRequester()

    /** The screen's node, while the screen is laid out. */
    internal var anchor: ScreenAnchorNode? = null

    /** Focus to the screen's remembered element, else its memory's fallback, else its first element. */
    internal fun home(): Boolean = memory?.let { it.restore(it.fallback) } == true || group.requestFocus()

    /** The screen's [focusHomeGroup] node, while it is attached. */
    internal var homeNode: FocusHomeNode? = null

    /**
     * The screen takes focus itself, on none of its elements, so the next D-pad key reaches it and takes focus to
     * [home]; true if it has it.
     */
    internal fun hold(): Boolean = homeNode?.hold() == true

    /** The screen's place, before its focus group. */
    val modifier: Modifier = Modifier.then(ScreenAnchorElement(this)).screenHomeGroup(this).focusRequester(group).pointerInput(this) {
        awaitPointerEventScope {
            while (true) {
                val type = awaitPointerEvent(PointerEventPass.Initial).type
                if (type == PointerEventType.Press || type == PointerEventType.Scroll) memory?.endPlacement()
            }
        }
    }
}

private data class ScreenAnchorElement(val screen: ScreenFocus) : ModifierNodeElement<ScreenAnchorNode>() {
    override fun create() = ScreenAnchorNode(screen)

    override fun update(node: ScreenAnchorNode) = Unit
}

/**
 * A [ScreenFocus]'s node: the screen's controls lie under it, and the app's [OverlayHost] knows the screen while it is
 * laid out ([OverlayHost.screens]). It hears the screen's focus and each key pressed in it, so focus that leaves the
 * screen while a key is down left by that key ([ScreenFocus.keyExits]).
 */
internal class ScreenAnchorNode(val screen: ScreenFocus) :
    Modifier.Node(),
    TraversableNode,
    CompositionLocalConsumerModifierNode,
    ObserverModifierNode,
    FocusEventModifierNode,
    KeyInputModifierNode {
    override val traverseKey: Any get() = ScreenAnchorKey

    private var host: OverlayHost? = null

    // Between a key's down and its up: Compose moves focus for an arrow after the key passed through the screen unused.
    private var keyDown = false

    override fun onAttach() {
        screen.anchor = this
        onObservedReadsChanged()
    }

    override fun onObservedReadsChanged() = observeReads {
        host?.screens?.remove(screen)
        host = currentValueOf(LocalOverlayHost)?.also { it.screens += screen }
    }

    override fun onDetach() {
        host?.screens?.remove(screen)
        host = null
        if (screen.anchor === this) screen.anchor = null
        screen.focused = false
    }

    override fun onFocusEvent(focusState: FocusState) {
        val had = screen.focused
        screen.focused = focusState.hasFocus
        if (had && !focusState.hasFocus && keyDown) screen.keyExits++
        if (!focusState.hasFocus) keyDown = false
    }

    override fun onPreKeyEvent(event: KeyEvent): Boolean {
        keyDown = event.type == KeyEventType.KeyDown
        return false
    }

    override fun onKeyEvent(event: KeyEvent): Boolean = false
}

/** [ScreenAnchorNode]'s traverse key. */
internal object ScreenAnchorKey

/** The [ScreenFocus] of the screen composed here. */
val LocalScreenFocus = staticCompositionLocalOf<ScreenFocus?> { null }
