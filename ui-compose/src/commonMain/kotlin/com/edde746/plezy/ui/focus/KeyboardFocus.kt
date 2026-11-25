package com.edde746.plezy.ui.focus

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.IndicationNodeFactory
import androidx.compose.foundation.interaction.FocusInteraction
import androidx.compose.foundation.interaction.Interaction
import androidx.compose.foundation.interaction.InteractionSource
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.KeyInputModifierNode
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.PointerEvent
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerIcon
import androidx.compose.ui.input.pointer.pointerHoverIcon
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.node.CompositionLocalConsumerModifierNode
import androidx.compose.ui.node.DelegatableNode
import androidx.compose.ui.node.DelegatingNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.PointerInputModifierNode
import androidx.compose.ui.node.currentValueOf
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.input.KeySource
import com.edde746.plezy.ui.components.isContextMenuKey
import com.edde746.plezy.ui.player.HiddenPointerIcon
import com.edde746.plezy.ui.player.inputSource
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.navigation.LocalKeyboardHeight
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch

/**
 * Whether focus is drawn ("focus-visible", as browsers do): from a key press (keyboard, D-pad, remote) until the next
 * press of a mouse button or a touch, which hides it again until the next key. Focus itself stays where it is either
 * way, so the next key moves on from it. Phones, tablets and the desktop app start hidden: focus a screen places at
 * launch (its first card) shows only once the user reaches for the keys, also where Android's window starts outside
 * touch mode (keys the system took before the app started); TV starts visible.
 */
@Stable
class FocusVisibility(initial: Boolean) {
    var visible by mutableStateOf(initial)
        internal set

    /** The focused element that takes the arrows itself (the player's video), asked per arrow; null where none does. */
    internal var arrowOwner: ((Key) -> Boolean)? = null

    /** Puts Compose's input mode back to Keyboard, while [trackFocusVisibility] is attached. */
    internal var keyboardMode: (() -> Unit)? = null

    /**
     * Input that moves focus without a key event of the window's own (a game controller the app reads itself): focus
     * shows, as for a key.
     */
    fun reportNonPointerInput() {
        visible = true
        keyboardMode?.invoke()
    }
}

/**
 * Whether this key press asks to move through the app by focus, so focus starts to show: a key-down of Tab, the
 * context-menu key, Select (a D-pad's centre, a controller's A), a remote's Enter (and a keyboard's on [tv], whose
 * remotes may send Enter as a keyboard), a Back key (a remote's Escape too), or an arrow the focused element doesn't
 * take itself ([ownsArrow]). A keyboard's Enter and Escape only act on what has focus (activate, dismiss), so focus
 * stays hidden and the mouse cursor shown.
 */
internal fun KeyEvent.requestsFocusNavigation(tv: Boolean, ownsArrow: (Key) -> Boolean): Boolean {
    if (type != KeyEventType.KeyDown) return false
    return when (key) {
        Key.Tab, Key.DirectionCenter, Key.ButtonA, Key.Back, Key.ButtonB, Key.NavigateOut -> true
        Key.Enter, Key.NumPadEnter -> tv || inputSource() != KeySource.KEYBOARD
        Key.Escape -> inputSource() != KeySource.KEYBOARD
        Key.DirectionUp, Key.DirectionDown, Key.DirectionLeft, Key.DirectionRight -> !ownsArrow(key)
        else -> isContextMenuKey
    }
}

/**
 * Marks the element as taking [owns] arrows itself while it has focus (the player's video seeks with Left and Right
 * and raises its controls with Up and Down): those arrows don't show focus ([requestsFocusNavigation]). An arrow it
 * leaves to focus moves still does.
 */
@Composable
fun Modifier.ownsArrows(owns: (Key) -> Boolean): Modifier {
    val visibility = LocalFocusVisibility.current
    val current by rememberUpdatedState(owns)
    val owner = remember { { key: Key -> current(key) } }
    DisposableEffect(visibility) { onDispose { if (visibility.arrowOwner === owner) visibility.arrowOwner = null } }
    return onFocusChanged {
        if (it.isFocused) visibility.arrowOwner = owner else if (visibility.arrowOwner === owner) visibility.arrowOwner = null
    }
}

/** The app's [FocusVisibility] ([trackFocusVisibility] keeps it); visible where none is provided. */
val LocalFocusVisibility = staticCompositionLocalOf { FocusVisibility(true) }

/** Whether a focused element shows its focus now: [LocalFocusVisibility], and never in Android's touch mode. */
@Composable
fun isFocusVisible(): Boolean = LocalInputModeManager.current.inputMode != InputMode.Touch && LocalFocusVisibility.current.visible

/** [isFocusVisible] for a modifier node, read where it draws or collects. */
internal fun CompositionLocalConsumerModifierNode.focusShown(): Boolean =
    currentValueOf(LocalInputModeManager).inputMode != InputMode.Touch && currentValueOf(LocalFocusVisibility).visible

/**
 * The app's [androidx.compose.foundation.LocalIndication] (the theme's): Material's [ripple], whose focus layer shows
 * only while focus does ([isFocusVisible]), as the app's own focus looks; its press, hover and drag layers as they are.
 * A card focused where its screen placed focus, or still focused after a tap or a click, isn't lit by it.
 */
internal data object FocusVisibleRipple : IndicationNodeFactory {
    private val ripple = ripple()

    override fun create(interactionSource: InteractionSource): DelegatableNode = FocusVisibleRippleNode(interactionSource, ripple)
}

private class FocusVisibleRippleNode(source: InteractionSource, ripple: IndicationNodeFactory) :
    DelegatingNode(),
    CompositionLocalConsumerModifierNode {
    init {
        delegate(ripple.create(FocusVisibleInteractions(source) { isAttached && focusShown() }))
    }
}

/**
 * [source]'s interactions with its focus passed on only while [shown]: focus that shows later is passed on then, and
 * focus that stops showing ends with an [FocusInteraction.Unfocus], so nothing stays lit.
 */
private class FocusVisibleInteractions(private val source: InteractionSource, private val shown: () -> Boolean) : InteractionSource {
    override val interactions: Flow<Interaction> = channelFlow {
        // The source's focus, and the one passed on. Both collections run on the node's (main) thread.
        var focus: FocusInteraction.Focus? = null
        var passed: FocusInteraction.Focus? = null
        suspend fun pass(show: Boolean) {
            val now = focus.takeIf { show }
            if (now === passed) return
            passed?.let { send(FocusInteraction.Unfocus(it)) }
            now?.let { send(it) }
            passed = now
        }
        launch { snapshotFlow(shown).collect { pass(it) } }
        source.interactions.collect { interaction ->
            when (interaction) {
                is FocusInteraction.Focus -> {
                    focus = interaction
                    pass(shown())
                }
                is FocusInteraction.Unfocus -> {
                    if (interaction.focus === focus) focus = null
                    pass(shown())
                }
                else -> send(interaction)
            }
        }
    }
}

/**
 * Keeps [visibility] with the input: a key press asking to move by focus ([requestsFocusNavigation]) shows focus, a
 * mouse or touch press, or the mouse moving, hides it; on the desktop the mouse cursor hides while focus shows (a
 * click still lands). Place it once around the app's content; it only watches (every key and press still reaches the
 * elements under it). On desktop a key press also puts Compose's [InputMode] back to Keyboard ([desktopApp]).
 * On Android TV ([tv] off the desktop) pointer input never hides focus: the system synthesizes it, and the remote
 * stays the input.
 */
@Composable
fun Modifier.trackFocusVisibility(visibility: FocusVisibility, tv: Boolean): Modifier {
    // One element whatever the visibility, its icon changing in place: an element removed from the window's root while
    // a press is down (the press that hides focus) cancels that press, and the click would be lost.
    val visible = visibility.visible
    val cursor = if (desktopApp) Modifier.pointerHoverIcon(if (visible) HiddenPointerIcon else PointerIcon.Default, overrideDescendants = visible) else Modifier
    return this then FocusVisibilityElement(visibility, tv) then cursor
}

/**
 * Whether this is the desktop app (Windows, Linux), whatever its layout (TV mode too). There Compose turns its
 * [InputMode] Touch on every mouse press and back only for a Tab it moves focus with itself, so after a click an arrow
 * key ([arrowKeyFocus], a screen's own key handling) moved focus without drawing it: a key press puts it back to
 * Keyboard. Android leaves touch mode on a hardware key itself, and keeps it for a soft keyboard's keys. The desktop's
 * window also runs the system's back as Escape goes down ([com.edde746.plezy.ui.components.backOnKeyUp]).
 */
internal expect val desktopApp: Boolean

private data class FocusVisibilityElement(val visibility: FocusVisibility, val tv: Boolean) : ModifierNodeElement<FocusVisibilityNode>() {
    override fun create() = FocusVisibilityNode(visibility, tv)

    override fun update(node: FocusVisibilityNode) {
        node.visibility.keyboardMode = null
        node.visibility = visibility
        node.tv = tv
        node.attachKeyboardMode()
    }
}

private class FocusVisibilityNode(var visibility: FocusVisibility, var tv: Boolean) :
    Modifier.Node(),
    KeyInputModifierNode,
    PointerInputModifierNode,
    CompositionLocalConsumerModifierNode {
    private var pointerAt = Offset.Unspecified

    // Android TV keeps focus showing whatever pointer input the system synthesizes.
    private val pointerHides: Boolean get() = !tv || desktopApp

    override fun onAttach() = attachKeyboardMode()

    override fun onDetach() {
        visibility.keyboardMode = null
    }

    fun attachKeyboardMode() {
        if (!isAttached) return
        visibility.keyboardMode = {
            if (desktopApp) currentValueOf(LocalInputModeManager).requestInputMode(InputMode.Keyboard)
        }
    }

    override fun onPreKeyEvent(event: KeyEvent): Boolean {
        val owner = visibility.arrowOwner
        if (!event.requestsFocusNavigation(tv) { owner?.invoke(it) == true }) return false
        visibility.visible = true
        if (desktopApp) currentValueOf(LocalInputModeManager).requestInputMode(InputMode.Keyboard)
        return false
    }

    override fun onKeyEvent(event: KeyEvent): Boolean = false

    override fun onPointerEvent(pointerEvent: PointerEvent, pass: PointerEventPass, bounds: IntSize) {
        if (pass != PointerEventPass.Initial || !pointerHides) return
        val at = pointerEvent.changes.firstOrNull()?.position ?: return
        when (pointerEvent.type) {
            PointerEventType.Press -> visibility.visible = false
            // Compose moves a resting mouse itself as what lies under it changes (a list scrolled by the keys): only
            // a move to somewhere else is the user's.
            PointerEventType.Move, PointerEventType.Enter -> {
                if (pointerAt != Offset.Unspecified && at != pointerAt) visibility.visible = false
            }
        }
        pointerAt = at
    }

    override fun onCancelPointerInput() = Unit
}

/**
 * Keeps a text field in view while it has focus and the on-screen keyboard comes up (or changes height): the app pads
 * its content for the keyboard, so the screen's scrolling area shrinks above it, and a field that ends up below that
 * edge (a TV's keyboard over the lower half of a centred page, a field low on a phone's page) is scrolled back into
 * view by its nearest scrolling parent. [keyboard] is the keyboard's height in pixels (the window's IME inset).
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun Modifier.inViewAboveKeyboard(keyboard: Int = WindowInsets.ime.getBottom(LocalDensity.current)): Modifier {
    val requester = remember { BringIntoViewRequester() }
    var focused by remember { mutableStateOf(false) }
    LaunchedEffect(focused, keyboard) {
        if (!focused || keyboard <= 0) return@LaunchedEffect
        // The next frame: the layout has taken this keyboard height by then.
        withFrameNanos { }
        requester.bringIntoView()
    }
    return bringIntoViewRequester(requester).onFocusChanged { focused = it.isFocused }
}

/**
 * A text field's on-screen keyboard on an Android TV, where it waits for Select: the field takes focus (a screen or an
 * editor opening on it, a remote passing over it) without raising the keyboard, which would take the remote's keys;
 * Select (or a remote's Enter) raises it, and the field stays editable until focus leaves it or the keyboard is put
 * away. A text field raises the keyboard as it takes focus, and with
 * [androidx.compose.foundation.text.KeyboardOptions.showKeyboardOnFocus] off only on a tap, never on a remote's Select,
 * so there the field is [readOnly] (no input session, so no keyboard) until Select. Elsewhere, a desktop in TV mode
 * included (a keyboard types there, and a click or a gamepad's Enter must reach the field), the field is always
 * editable. Give the field [readOnly], and [modifier] before its own key handling.
 */
@Stable
class KeyboardOnSelect internal constructor(tv: Boolean) {
    private var typing by mutableStateOf(!tv)
    private var keyboardShown = false

    /** The field's `readOnly`: on TV, until Select. */
    val readOnly: Boolean get() = !typing

    /** On TV, whether the field's on-screen keyboard is up: the keyboard takes the next Back to put itself away. */
    val keyboardUp: Boolean get() = typing && keyboardShown

    /** Makes the field editable now, as Select would: a field given focus by the app for typing (Add line's new row). */
    fun startTyping() {
        typing = true
    }

    val modifier: Modifier = if (!tv) {
        Modifier
    } else {
        Modifier
            .onFocusChanged { if (!it.isFocused) typing = false }
            .onPreviewKeyEvent { event ->
                // A remote's Select (a controller's A, a remote's Enter); a keyboard's Enter goes to the field.
                val select = event.key == Key.DirectionCenter || event.key == Key.ButtonA ||
                    ((event.key == Key.Enter || event.key == Key.NumPadEnter) && event.inputSource() != KeySource.KEYBOARD)
                if (typing || !select) return@onPreviewKeyEvent false
                if (event.type == KeyEventType.KeyDown) typing = true
                true
            }
    }

    /**
     * The window's on-screen keyboard came up or went away: put away (Back), the field waits for Select again and the
     * remote's keys reach the app.
     */
    internal fun keyboardVisible(visible: Boolean) {
        if (keyboardShown && !visible) typing = false
        keyboardShown = visible
    }
}

/** A text field's [KeyboardOnSelect]. */
@Composable
fun rememberKeyboardOnSelect(): KeyboardOnSelect {
    val waits = LocalWindowLayout.current.formFactor == FormFactor.TV && LocalKeyboardWaitsForSelect.current
    val keyboard = remember(waits) { KeyboardOnSelect(waits) }
    if (waits) {
        val visible = keyboardShows()
        LaunchedEffect(keyboard, visible) { keyboard.keyboardVisible(visible) }
    }
    return keyboard
}

/**
 * Whether a TV layout's text fields wait for Select ([KeyboardOnSelect]): where an on-screen keyboard types, so not on a
 * desktop. Tests of the Android TV's fields provide true.
 */
internal val LocalKeyboardWaitsForSelect = staticCompositionLocalOf { !desktopApp }

/**
 * Whether the window's on-screen keyboard shows. On Android the IME's visibility: the Fire TV's keyboard is drawn over
 * the app and gives the window no inset. Elsewhere [LocalKeyboardHeight] over 0.
 */
@Composable
internal expect fun keyboardShows(): Boolean

/**
 * A single-line text field a remote can always leave, on TV: Right with the cursor at the text's end goes on to the
 * next control and Left with it at the start to the one before (the other way round in a right-to-left layout);
 * within the text they move the cursor. Up and Down move focus that way, else do nothing: a single-line field moves
 * its cursor to the text's start on Up and to its end on Down, and a cursor at the start keeps Right inside the text.
 * Compose's text fields move focus for a D-pad device's arrows themselves, but keep a virtual device's (the system's
 * injected keys, the harnesses') and a keyboard's for the cursor; on 26 Oct the Fire TV's join field, its cursor put
 * at the start by the keyboard as it closed, kept Right. Elsewhere the arrows are the field's. [state] is the field's
 * text and cursor, read as each key comes; place it after the field's own key handling, which comes first.
 */
@Composable
fun Modifier.remoteLeavesField(state: TextFieldState): Modifier {
    if (LocalWindowLayout.current.formFactor != FormFactor.TV) return this
    val focusManager = LocalFocusManager.current
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    return onPreviewKeyEvent { event ->
        if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
        val selection = state.selection
        val atStart = selection.collapsed && selection.start == 0
        val atEnd = selection.collapsed && selection.end == state.text.length
        when (event.key) {
            Key.DirectionUp, Key.DirectionDown -> {
                focusManager.moveFocus(if (event.key == Key.DirectionUp) FocusDirection.Up else FocusDirection.Down)
                true
            }
            Key.DirectionRight -> (if (rtl) atStart else atEnd) && focusManager.moveFocus(FocusDirection.Right)
            Key.DirectionLeft -> (if (rtl) atEnd else atStart) && focusManager.moveFocus(FocusDirection.Left)
            else -> false
        }
    }
}

/**
 * Tells [onChange] the text of a field that keeps its own ([state]) after each change (an edit, or text set from code),
 * not the text it starts with: for a store that hears each change. Text fields keep their text in a [TextFieldState],
 * which takes each of a keyboard's edits as it comes. A field over a String or a TextFieldValue drops an edit that
 * leaves its text as the last frame drew it: Android TV's keyboard (the SHIELD's) deletes a field's text and types it
 * back as it comes up, two edits in one frame, and such a field ended empty.
 */
@Composable
fun OnTextChange(state: TextFieldState, onChange: (String) -> Unit) {
    val current by rememberUpdatedState(onChange)
    LaunchedEffect(state) { snapshotFlow { state.text.toString() }.drop(1).collect { current(it) } }
}

/**
 * A slider without steps, moved by keys: Left and Right (the other way round right to left) move [value] by 5 % of
 * [range], clamped, each press a whole change ([onChange]: kept, as a drag's end is); Material's own keys move 1 %. Up
 * and Down stay with focus. Place it before the slider.
 */
@Composable
fun Modifier.sliderKeys(value: Float, range: ClosedFloatingPointRange<Float>, onChange: (Float) -> Unit): Modifier {
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val current by rememberUpdatedState(value)
    val change by rememberUpdatedState(onChange)
    return onPreviewKeyEvent { event ->
        val up = when (event.key) {
            Key.DirectionRight -> !rtl
            Key.DirectionLeft -> rtl
            else -> return@onPreviewKeyEvent false
        }
        if (event.type == KeyEventType.KeyDown) {
            val step = (range.endInclusive - range.start) * SLIDER_KEY_STEP
            change((current + if (up) step else -step).coerceIn(range))
        }
        true
    }
}

private const val SLIDER_KEY_STEP = 0.05f
