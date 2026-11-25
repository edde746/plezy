package com.edde746.plezy.ui.app

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isAltPressed
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.isMetaPressed
import androidx.compose.ui.input.key.isShiftPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.LocalOverlayHost

/** The desktop app's own key chords (Windows and Linux; the Mac's are its menus' commands). */
internal enum class DesktopShortcut {
    /** F11: the window enters or leaves fullscreen. */
    FULLSCREEN,

    /** Ctrl+F: the Search destination, its field focused. */
    SEARCH,

    /** Ctrl+R: the shown destination's content loads again. */
    REFRESH,

    /** Ctrl+,: Settings. */
    SETTINGS,
}

/**
 * The shortcut a key going down is on a desktop, or null: F11; Ctrl+F; Ctrl+R without Shift or Alt; Ctrl+, (the
 * comma). The Ctrl chords never with Meta (the Windows or Super key). A key held down repeats nothing ([repeat]).
 * Refresh and Settings aren't shortcuts in TV mode ([tv]).
 */
internal fun desktopShortcut(key: Key, ctrl: Boolean, meta: Boolean, shift: Boolean, alt: Boolean, repeat: Boolean, tv: Boolean): DesktopShortcut? {
    if (repeat) return null
    if (key == Key.F11) return DesktopShortcut.FULLSCREEN
    if (!ctrl || meta) return null
    return when (key) {
        Key.F -> DesktopShortcut.SEARCH
        Key.R -> DesktopShortcut.REFRESH.takeIf { !shift && !alt && !tv }
        Key.Comma -> DesktopShortcut.SETTINGS.takeIf { !tv }
        else -> null
    }
}

/**
 * What [shortcut] does in [app]: true when the key is taken.
 *
 * - Fullscreen toggles the window's fullscreen ([PlezyPlatform.setFullscreen]).
 * - Search shows the Search destination and focuses its field ([com.edde746.plezy.presentation.search.SearchStore.focusField]);
 *   offline, where there is no Search, the key is taken and nothing happens.
 * - Refresh loads the shown destination's content again ([AppSession.manualRefresh]); a destination with nothing to
 *   refresh leaves the key.
 * - Settings shows the Settings destination ([AppSession.openSettings]: a tab of the sidebar or rail, the bar's hidden
 *   one on a narrow window);
 *   while it shows already (a page of it open) it stays as it is.
 */
internal fun AppSession.perform(shortcut: DesktopShortcut, platform: PlezyPlatform): Boolean {
    when (shortcut) {
        DesktopShortcut.FULLSCREEN -> platform.setFullscreen(!platform.isFullscreen)
        DesktopShortcut.SEARCH -> if (!offline) {
            shell.select(TopLevelDestination.SEARCH)
            search(Route.Search)?.focusField()
        }
        DesktopShortcut.REFRESH -> {
            if (!manualRefresh()) return false
            Log.i(TAG) { "refreshed ${navigator.stacks.value.shown}" }
        }
        DesktopShortcut.SETTINGS -> if (shell.state.value.selected != TopLevelDestination.SETTINGS) openSettings()
    }
    return true
}

/** What the mouse's back button closes ([mouseBack]). */
internal enum class MouseBack {
    /** The newest dialog or sheet, as Back (Escape) closes it: the system's back event, which its handler takes. */
    OVERLAY,

    /**
     * The top screen of the shown stack, the player and a route's sheet too
     * ([com.edde746.plezy.presentation.navigation.PlezyNavigator.back]).
     */
    SCREEN,
}

/**
 * What the mouse's back button closes, as the earlier releases' root navigator popped first: an open dialog or sheet
 * ([overlayOpen]) before anything under it, else the top screen of the shown stack while it has more than its root
 * ([stackSize]); at a destination's root, nothing.
 */
internal fun mouseBack(overlayOpen: Boolean, stackSize: Int): MouseBack? = when {
    overlayOpen -> MouseBack.OVERLAY
    stackSize > 1 -> MouseBack.SCREEN
    else -> null
}

/**
 * The desktop's shortcuts ([desktopShortcut]) and the mouse's back button ([mouseBack]) over [app]'s screens, on a
 * desktop window (Windows, Linux); nothing elsewhere. A key reaches the shortcuts after the focused element left it, and
 * none is one while the player is up, which takes its keys itself. The back button is heard over the dialogs and
 * sheets too ([com.edde746.plezy.ui.components.OverlayHost.mouseBack]).
 */
@Composable
internal fun Modifier.desktopShortcuts(app: AppSession): Modifier {
    val platform = LocalPlezyPlatform.current
    if (platform.formFactor != FormFactor.DESKTOP) return this
    val tv by rememberUpdatedState(LocalWindowLayout.current.formFactor == FormFactor.TV)
    val overlays = LocalOverlayHost.current
    val dispatcher = LocalNavigationEventDispatcherOwner.current?.navigationEventDispatcher
    DisposableEffect(app, overlays, dispatcher) {
        val systemBack = DirectNavigationEventInput()
        dispatcher?.addInput(systemBack)
        overlays?.mouseBack = {
            when (mouseBack(overlays.entries.isNotEmpty(), app.navigator.backStack.value.size)) {
                MouseBack.OVERLAY -> systemBack.backCompleted()
                MouseBack.SCREEN -> app.navigator.back()
                null -> Unit
            }
        }
        onDispose {
            overlays?.mouseBack = null
            dispatcher?.removeInput(systemBack)
        }
    }
    // The key that went down last and hasn't come up: its next press is the key repeating.
    val held = remember { arrayOfNulls<Key>(1) }
    return onKeyEvent { event ->
        when (event.type) {
            KeyEventType.KeyUp -> {
                if (held[0] == event.key) held[0] = null
                false
            }
            KeyEventType.KeyDown -> {
                val repeat = held[0] == event.key
                held[0] = event.key
                if (app.navigator.current == Route.Player) return@onKeyEvent false
                val shortcut = desktopShortcut(event.key, event.isCtrlPressed, event.isMetaPressed, event.isShiftPressed, event.isAltPressed, repeat, tv)
                shortcut != null && app.perform(shortcut, platform)
            }
            else -> false
        }
    }
}

private const val TAG = "DesktopShortcuts"
