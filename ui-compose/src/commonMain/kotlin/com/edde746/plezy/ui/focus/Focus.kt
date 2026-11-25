package com.edde746.plezy.ui.focus

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusEventModifierNode
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.FocusState
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.ContentDrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.node.CompositionLocalConsumerModifierNode
import androidx.compose.ui.node.DrawModifierNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.currentValueOf
import androidx.compose.ui.node.invalidateDraw
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.components.LocalOverlayHost
import com.edde746.plezy.ui.image.LocalArtworkDisplay
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.LocalPlezyColors
import com.edde746.plezy.ui.theme.PlezyDimens
import kotlin.math.max
import kotlin.math.min
import kotlinx.coroutines.launch

/**
 * Focus on artwork (posters, thumbnails, avatars) for keyboard, D-pad and remote users: a ring drawn exactly on the
 * element's own [shape] (inside its bounds, no gap), [LocalPlezyDimens]' `focusRing` wide in the content colour (the
 * text's, never the accent), and on TV a scale-up
 * (`posterFocusScale`). Place it before the element's focus target (`clickable`, `focusable`) so it sees that
 * target's focus. Keep the element's ancestors from clipping the growth ([focusReach]; lists pad their content for
 * it). Drawn only while focus shows ([isFocusVisible]): not after a tap (Android's touch mode) or a mouse click.
 */
fun Modifier.focusRing(shape: Shape = RoundedCornerShape(12.dp)): Modifier = this then FocusIndicationElement(shape, FocusStyle.ARTWORK)

/**
 * [focusRing] on artwork inside a larger focus target (an avatar in a clickable tile): drawn while [focused], the
 * target's focus (from its interaction source).
 */
fun Modifier.focusRing(shape: Shape, focused: Boolean): Modifier = this then FocusIndicationElement(shape, FocusStyle.ARTWORK, focused)

/**
 * Focus on a control (a button or a row) whose own fill shows focus (it turns the primary fill,
 * [com.edde746.plezy.ui.components.PlezySurface]): on TV a scale-up (`controlFocusScale`, by at most
 * [MaxFocusGrowth] on each side) unless [grows] is false (a row of a list). With [ring] (a control whose resting fill
 * already is the primary fill: a primary button off TV) a ring just outside the element marks focus as well. Chips keep their
 * size instead ([focusInset]). Place it before the focus target.
 */
fun Modifier.focusGrowth(shape: Shape, ring: Boolean = false, grows: Boolean = true): Modifier =
    this then FocusIndicationElement(shape, if (ring) FocusStyle.CONTROL_RING else FocusStyle.CONTROL, grows = grows)

/**
 * Focus on a control that keeps its size and draws nothing past its bounds (a chip in a row of chips, which keeps one
 * height): no scale on TV, and a ring inside its edge, [RingGap] in, in the primary fill's content colour. The control
 * shows focus in the primary fill ([com.edde746.plezy.ui.components.PlezySurface]), so the ring reads on it, also
 * on a control resting in that fill (a selected chip). Place it before the focus target.
 */
fun Modifier.focusInset(shape: Shape): Modifier = this then FocusIndicationElement(shape, FocusStyle.CONTROL_INSET, grows = false)

private enum class FocusStyle { ARTWORK, CONTROL, CONTROL_RING, CONTROL_INSET }

/**
 * The most a focused element grows on each side on TV: a wide row (a setting, a recent search) grown by the whole
 * scale would swell over the elements beside it.
 */
private val MaxFocusGrowth = 8.dp

/** The gap between a control's edge and its ring: outside it ([focusGrowth] with `ring`) or inside it ([focusInset]). */
private val RingGap = 2.dp

/**
 * How far a focused element's indication reaches beyond its bounds at most (the TV growth, then a control's outside
 * ring): the room to keep between the element and its neighbours or a clipping ancestor, so nothing covers or cuts it.
 */
val PlezyDimens.focusReach: Dp get() = (if (focusGrows) MaxFocusGrowth else 0.dp) + RingGap + focusRing

private data class FocusIndicationElement(
    val shape: Shape,
    val style: FocusStyle,
    val external: Boolean? = null,
    val grows: Boolean = true,
) : ModifierNodeElement<FocusIndicationNode>() {
    override fun create() = FocusIndicationNode(shape, style, grows).also { node -> external?.let { node.focusChanged(it) } }

    override fun update(node: FocusIndicationNode) {
        node.shape = shape
        node.style = style
        node.grows = grows
        external?.let { node.focusChanged(it) }
        node.invalidateDraw()
    }
}

private class FocusIndicationNode(var shape: Shape, var style: FocusStyle, var grows: Boolean) :
    Modifier.Node(),
    FocusEventModifierNode,
    DrawModifierNode,
    CompositionLocalConsumerModifierNode {
    private var focused = false
    private var external = false

    // 0 → 1 as the element takes focus: how much of its growth is drawn.
    private val grown = Animatable(0f)

    override fun onFocusEvent(focusState: FocusState) {
        if (!external) update(focusState.isFocused)
    }

    /** The focus of a target elsewhere (the tile around this artwork). */
    fun focusChanged(now: Boolean) {
        external = true
        if (isAttached) update(now) else focused = now
    }

    override fun onAttach() {
        if (focused) coroutineScope.launch { if (currentValueOf(LocalPlezyDimens).focusGrows) grown.snapTo(1f) }
    }

    private fun update(now: Boolean) {
        if (now == focused) return
        focused = now
        invalidateDraw()
        val target = if (now && currentValueOf(LocalPlezyDimens).focusGrows) 1f else 0f
        if (grown.targetValue == target) return
        // The reduced effects tier snaps: each animation frame would draw the focused card again. A node losing focus
        // as it leaves can't read the tier, and has nothing left to draw.
        if (!isAttached || currentValueOf(LocalArtworkDisplay).reduced) {
            coroutineScope.launch { grown.snapTo(target) }
        } else {
            coroutineScope.launch { grown.animateTo(target, tween(durationMillis = 120)) }
        }
    }

    // The scale is drawn, not laid out: no layer (a layer would cull what is drawn outside the bounds), and the
    // element keeps its place and hit area.
    override fun ContentDrawScope.draw() {
        val dimens = currentValueOf(LocalPlezyDimens)
        val visible = focusShown()
        val scale = if (style == FocusStyle.ARTWORK) dimens.posterFocusScale else dimens.controlFocusScale
        val growth = if (visible && grows) min(scale - 1f, 2 * MaxFocusGrowth.toPx() / max(size.width, size.height)) else 0f
        scale(1f + growth * grown.value) {
            this@draw.drawContent()
            if (!focused || style == FocusStyle.CONTROL || !visible) return@scale
            val width = dimens.focusRing.toPx()
            // Artwork: on its own edge, inside the bounds. A control: just outside, clear of its (primary) fill, in the
            // content colour of where it sits (white over the video); or, inset, as far inside it.
            val offset = when (style) {
                FocusStyle.ARTWORK -> -width / 2
                FocusStyle.CONTROL_INSET -> -(RingGap.toPx() + width / 2)
                else -> RingGap.toPx() + width / 2
            }
            translate(-offset, -offset) {
                val outline = shape.createOutline(Size(size.width + 2 * offset, size.height + 2 * offset), layoutDirection, this)
                val color = if (style == FocusStyle.CONTROL_INSET) {
                    currentValueOf(LocalPlezyColors).onFocusFill(dimens.focusGrows)
                } else {
                    currentValueOf(LocalContentColor)
                }
                drawOutline(outline, color, style = Stroke(width))
            }
        }
    }
}

/**
 * Remembers which element of a screen had focus, so it gets focus back when the user returns (Back from the next
 * screen restores the row they left from, a destination shown again the element it left). Survives the screen leaving
 * composition while its route stays on a stack (it is saveable); keys are the screen's own stable ids.
 */
@Stable
class FocusMemory internal constructor(initial: String?) {
    /** The key of the element that had focus last. */
    var lastFocused: String? = initial
        private set

    /** The key of the element that has focus now, if one of this memory's has it. */
    internal var focusedKey: String? = null
        private set

    /**
     * The key of the element that has focus because the screen put it there itself ([restore]'s fallback, [place]),
     * while it keeps it and the user leaves the screen alone: focus the user neither moved nor came back to, on a
     * screen they haven't pressed, touched or scrolled ([endPlacement]), which the screen may move on as its content
     * arrives. Null for the remembered element [restore] gives focus back to.
     */
    internal var placedKey: String? = null
        private set

    /** The key of the element that has focus where the screen placed it ([placedKey]), if it has. */
    internal val placedFocus: String? get() = focusedKey?.takeIf { it == placedKey }

    /**
     * The user has taken the screen over with the pointer (a press, a touch, the wheel; [ScreenFocus]): focus the screen
     * placed stays where it is, no longer the screen's to move.
     */
    internal fun endPlacement() {
        placedKey = null
    }

    private val requesters = HashMap<String, FocusRequester>()

    // One callback per key, so an element composed again under the same key gets an equal modifier and can skip.
    private val callbacks = HashMap<String, (FocusState) -> Unit>()

    // How many elements are attached under each key ([rememberFocus]). A key none is attached under (a card scrolled out
    // of its list, a search's old results) loses its requester and callback, unless it is [lastFocused], so the memory
    // holds what is on screen, not every key it saw in the session.
    private val attached = HashMap<String, Int>()

    /** The screen this memory is composed in ([LocalScreenFocus]), whose home it becomes when one of its elements has focus. */
    internal var screen: ScreenFocus? = null

    internal fun requester(key: String): FocusRequester = requesters.getOrPut(key) { FocusRequester() }

    internal fun onFocusChanged(key: String): (FocusState) -> Unit = callbacks.getOrPut(key) { { onFocusChanged(key, it.isFocused) } }

    /** An element under [key] holding [requester] is attached. */
    internal fun attach(key: String, requester: FocusRequester) {
        requesters[key] = requester
        attached[key] = (attached[key] ?: 0) + 1
    }

    /** An element under [key] is detached. */
    internal fun detach(key: String) {
        val left = (attached[key] ?: return) - 1
        if (left > 0) {
            attached[key] = left
            return
        }
        attached.remove(key)
        if (key != lastFocused) release(key)
    }

    private fun release(key: String) {
        requesters.remove(key)
        callbacks.remove(key)
    }

    private fun onFocusChanged(key: String, focused: Boolean) {
        if (focused) {
            val previous = lastFocused
            lastFocused = key
            focusedKey = key
            screen?.memory = this
            // The element focused before, kept while it was the last focused, can go now if it left the screen.
            if (previous != null && previous != key && previous !in attached) release(previous)
        } else {
            if (focusedKey == key) focusedKey = null
            if (placedKey == key) placedKey = null
        }
    }

    /** The screen's element focus falls back on ([RestoreFocus]'s fallback: the Board's first card). */
    internal var fallback: String? = null

    /** Whether focus may go back to the remembered element under a key ([RestoreFocus]'s `remembered`). */
    internal var remembered: (String) -> Boolean = { true }

    /** Moves focus to the element under [key]; false when it is gone. */
    internal fun focus(key: String): Boolean = requesters[key]?.requestFocus() == true

    /** Moves focus to the element under [key] as the screen's own choice ([placedKey]); false when it is gone. */
    internal fun place(key: String): Boolean {
        if (!focus(key)) return false
        placedKey = key
        return true
    }

    /**
     * Moves focus to the remembered element, or to [fallback] when there is none, it is gone or it may not take focus
     * back now ([remembered]; focus the screen placed: [placedKey]); true if it moved.
     */
    fun restore(fallback: String? = null): Boolean {
        lastFocused?.takeIf(remembered)?.let { key -> if (requesters[key]?.requestFocus() == true) return true }
        if (fallback == null || requesters[fallback]?.requestFocus() != true) return false
        placedKey = fallback
        return true
    }

    internal companion object {
        val saver = Saver<FocusMemory, String>(save = { it.lastFocused ?: "" }, restore = { FocusMemory(it.ifEmpty { null }) })
    }
}

/**
 * A screen's [FocusMemory]. While it is composed an overlay opened from one of its elements gives focus back to exactly
 * that element when it closes, or to its fallback once the element is gone (a menu's action removed it: a card taken
 * out of Continue Watching; [com.edde746.plezy.ui.components.OverlayHost.closed]), and focus that drops on its screen
 * goes back through it ([ScreenFocus]).
 */
@Composable
fun rememberFocusMemory(): FocusMemory {
    val memory = rememberSaveable(saver = FocusMemory.saver) { FocusMemory(null) }
    val host = LocalOverlayHost.current
    val screen = LocalScreenFocus.current
    DisposableEffect(host, screen, memory) {
        host?.memories?.add(memory)
        memory.screen = screen
        onDispose {
            host?.memories?.remove(memory)
            memory.screen = null
            if (screen?.memory === memory) screen.memory = null
        }
    }
    return memory
}

/**
 * Makes this element's focus part of [memory] under [key]. Place it before the element's focus target. The memory keeps
 * the key while the element is attached, and after that only while it is the one focused last.
 */
fun Modifier.rememberFocus(memory: FocusMemory, key: String): Modifier {
    val requester = memory.requester(key)
    return focusRequester(requester).onFocusChanged(memory.onFocusChanged(key)) then FocusKeyElement(memory, key, requester)
}

/** Tells [memory] while an element under [key] is attached ([FocusMemory.attach], [FocusMemory.detach]). */
private data class FocusKeyElement(val memory: FocusMemory, val key: String, val requester: FocusRequester) : ModifierNodeElement<FocusKeyNode>() {
    override fun create() = FocusKeyNode(memory, key, requester)

    override fun update(node: FocusKeyNode) = node.update(memory, key, requester)
}

private class FocusKeyNode(private var memory: FocusMemory, private var key: String, private var requester: FocusRequester) : Modifier.Node() {
    override fun onAttach() = memory.attach(key, requester)

    override fun onDetach() = memory.detach(key)

    fun update(memory: FocusMemory, key: String, requester: FocusRequester) {
        if (isAttached) this.memory.detach(this.key)
        this.memory = memory
        this.key = key
        this.requester = requester
        if (isAttached) memory.attach(key, requester)
    }
}

/**
 * Once [ready] (the screen's focusable content is on its way) and the screen is on view ([ScreenFocus.onView]: the top
 * one with no sheet over it), gives focus back to the element [memory] remembers, or to [fallback] the first time. Runs
 * again when either turns true after being false, so a screen that comes on view with nothing of it focused gets focus
 * too: a stream list opened over a Detail from Home's menu closing hands focus to Detail's Play, not to the navigation.
 * In touch mode (Android, after a tap; desktop, after a click) only the first time: coming back leaves focus alone, as
 * Android focuses nothing while the user touches the screen (clickable elements can't take it then, and the fallback
 * would, raising the keyboard over Search's results). A screen whose [fallback] can sit off screen gives none in touch
 * mode until it is on screen whole (the Board's first card): focus taken after a click or a tap never scrolls the page.
 * On the desktop, where an arrow key reaches nothing while nothing has focus (Compose moves focus with Tab only), the
 * screen coming back with nothing in the app focused holds focus itself, unseen ([ScreenFocus.hold]): the first key
 * takes it to the remembered element, as Android's first key out of touch mode does.
 * An overlay closing over an element that is gone gives focus to [fallback] too.
 *
 * A screen that comes on view while another screen has focus (pushed over it, or popped back to) takes focus at once,
 * holding it itself ([ScreenFocus.hold]) until its content is [ready]: Search's result opening a Detail that is still
 * loading never leaves focus to the navigation as the result goes.
 *
 * Focus a key took out of the screen since it came on view ([ScreenFocus.keyExits]: the user walked to the navigation
 * while the screen's content was on its way) stays where the user put it while it is outside the screen: on a TV box
 * Home's content arrives seconds after Back, while the remote already walks the navigation column.
 *
 * A screen's content arrives in any order (Home's catalogs, the addons' streams, Detail's library entry after its
 * title), so [fallback] can change after focus came to it. Focus the screen placed itself ([FocusMemory.placedKey]:
 * before the user moved it, pressed, touched or scrolled the screen) follows to the new [fallback], as if the content
 * had come in order; left where it was, it would sit below what came above it (the first press would walk through
 * it), or on Detail's Add to library while Play came.
 *
 * Lazily composed items (a list's rows, a shelf's cards inside a row) can take several frames to attach, more so while
 * the window isn't in front, so it asks once per frame until an element takes focus, for up to [FOCUS_RETRY_FRAMES]
 * frames. Without that, a screen could open with nothing focused, and the arrow keys and the D-pad would do nothing.
 *
 * [remembered] says whether focus may go back to the remembered element under a key now; one it may not gives way to
 * [fallback] (Explore while a search shows results: always its first result, never the field, where focus would raise
 * the keyboard over them).
 */
@Composable
fun RestoreFocus(memory: FocusMemory, ready: Boolean, fallback: String?, remembered: (String) -> Boolean = { true }) {
    val currentFallback by rememberUpdatedState(fallback)
    SideEffect {
        memory.fallback = fallback
        memory.remembered = remembered
    }
    val inputMode = LocalInputModeManager.current
    val screen = LocalScreenFocus.current
    val onView by remember(screen) { derivedStateOf { screen?.onView?.invoke() != false } }
    // The keys that had taken focus out of the screen when it came on view.
    val exitsOnView = remember(screen, onView) { screen?.keyExits }
    val host = LocalOverlayHost.current
    // A screen pushed over the one that has focus (a result opened with the remote) takes it at once, holding it itself
    // while its content is on its way: else the covered screen's element leaving drops it, and Android hands it to the
    // window's first element, the navigation, which opens until the content comes.
    LaunchedEffect(onView) {
        if (!onView || screen == null || inputMode.inputMode == InputMode.Touch) return@LaunchedEffect
        if (host?.screens?.any { it !== screen && it.focused } == true) screen.hold()
    }
    LaunchedEffect(ready && onView) {
        if (!ready || !onView) return@LaunchedEffect
        if (inputMode.inputMode == InputMode.Touch && memory.lastFocused != null) {
            if (!desktopApp || screen == null) return@LaunchedEffect
            // The screen it came back from may still hold focus for a frame or more as it leaves.
            repeat(FOCUS_RETRY_FRAMES) {
                withFrameNanos { }
                if (screen.focused || inputMode.inputMode != InputMode.Touch) return@LaunchedEffect
                if (host?.appFocus?.held != true) {
                    screen.hold()
                    return@LaunchedEffect
                }
            }
            return@LaunchedEffect
        }
        repeat(FOCUS_RETRY_FRAMES) {
            withFrameNanos { }
            if (screen != null && !screen.focused && screen.keyExits != exitsOnView) return@LaunchedEffect
            if (!memory.restore(currentFallback)) return@repeat
            // Asked from outside the app's content (a closing sheet still holds focus while it slides away), focus can
            // go where the content's focus restorer saw it last (the navigation) instead; asked again from there, it
            // moves to the element.
            if (memory.focusedKey == null) {
                withFrameNanos { }
                memory.restore(currentFallback)
            }
            return@LaunchedEffect
        }
    }
    LaunchedEffect(fallback) {
        val placed = memory.placedFocus
        if (fallback == null || placed == null || placed == fallback) return@LaunchedEffect
        // The new fallback may compose with the next measure (a list's new first row).
        repeat(FOCUS_RETRY_FRAMES) {
            withFrameNanos { }
            if (memory.placedFocus != placed || memory.place(fallback)) return@LaunchedEffect
        }
    }
}

/**
 * Once per [key], moves focus into the group [requester] is on (to its first element that can take focus): for a pane
 * that replaces the element that had focus (a Settings section pushed over the list), where a remote would otherwise
 * find focus back in the navigation. Asks once per frame until an element takes it, for up to [FOCUS_RETRY_FRAMES]
 * frames (the pane's content may still be loading). Not in touch mode, where Android focuses nothing.
 */
@Composable
fun FocusInto(requester: FocusRequester, key: Any?) {
    val inputMode = LocalInputModeManager.current
    LaunchedEffect(key) {
        if (inputMode.inputMode == InputMode.Touch) return@LaunchedEffect
        repeat(FOCUS_RETRY_FRAMES) {
            withFrameNanos { }
            if (requester.requestFocus()) return@LaunchedEffect
        }
    }
}

/**
 * A screen of the back stack as a focus group that focus enters only while [open]: for the screen the user sees, the
 * top one with no sheet over it. A screen under a sheet, under the screen pushed over it or leaving takes no focus,
 * asked for ([RestoreFocus], a card's own request) or moved to with the arrow keys, so a key pressed meanwhile never
 * lands on it; focus already in it stays until the screen on view takes it.
 */
fun Modifier.focusGate(open: () -> Boolean): Modifier =
    focusProperties { onEnter = { if (!open()) cancelFocusChange() } }.focusGroup()

/** The focus moves of the arrow keys and a D-pad. */
internal val DirectionalMoves = setOf(FocusDirection.Left, FocusDirection.Right, FocusDirection.Up, FocusDirection.Down)

/**
 * Makes this element a focus group that an arrow key's or a D-pad's move enters on the element that had focus in it
 * last, else on [entry]'s (its first, primary or selected element), so where the move lands doesn't depend on how the
 * group lays its elements out: Compose's own pick, the element nearest the move, follows text wrap, label widths and
 * how many elements there are. Where neither can take focus (gone, disabled, [entry] null) Compose picks. Focus asked
 * for an element in the group, and Tab, go where they would. The group competes as one rectangle in a move's search.
 */
@Composable
fun Modifier.focusEntry(entry: FocusRequester?): Modifier {
    val group = remember { FocusRequester() }
    return focusRequester(group).focusProperties {
        onExit = { group.saveFocusedChild() }
        onEnter = { if (requestedFocusDirection in DirectionalMoves && !group.restoreFocusedChild()) entry?.requestFocus() }
    }.focusGroup()
}

/**
 * How many frames focus is asked for while what should take it may not be composed yet ([RestoreFocus], [FocusInto],
 * [focusHome]): about two seconds.
 */
internal const val FOCUS_RETRY_FRAMES = 120
