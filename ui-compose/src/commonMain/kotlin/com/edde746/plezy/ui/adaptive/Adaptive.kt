package com.edde746.plezy.ui.adaptive

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalViewConfiguration
import androidx.compose.ui.platform.ViewConfiguration
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyDimens

/** Material 3 window width classes: under 600 dp, under 840 dp, and wider. */
enum class WidthClass {
    COMPACT, MEDIUM, EXPANDED;

    companion object {
        fun of(width: Dp): WidthClass = when {
            width < 600.dp -> COMPACT
            width < 840.dp -> MEDIUM
            else -> EXPANDED
        }
    }
}

/** How the top-level destinations are offered. */
enum class NavigationKind {
    /** A bar along the bottom (compact windows: phones held upright). */
    BAR,

    /** An 80 dp rail along the start edge (tablets in either orientation, phones held sideways, desktop). */
    RAIL,

    /** The TV's column: 72 dp of icons that widens to 248 dp over the screen while it has focus. */
    TV_SIDE,
}

/**
 * The window the app currently fills, by its kind: what changes only at a breakpoint. Its exact size changes on every
 * frame of a resize or of the keyboard sliding in, so it isn't here: the few that need it read [LocalWindowSize].
 */
@Immutable
data class WindowLayout(val formFactor: FormFactor, val widthClass: WidthClass) {
    /** The TV's column on TV; otherwise the window decides: a bar under 600 dp, a rail from there. */
    val navigation: NavigationKind
        get() = when {
            formFactor == FormFactor.TV -> NavigationKind.TV_SIDE
            widthClass == WidthClass.COMPACT -> NavigationKind.BAR
            else -> NavigationKind.RAIL
        }
}

/**
 * A static local: a new value composes everything under it again, which it gets only at a breakpoint (a resize from a
 * phone's width to a tablet's, not each frame of one).
 */
val LocalWindowLayout = staticCompositionLocalOf { WindowLayout(FormFactor.DESKTOP, WidthClass.EXPANDED) }

/**
 * The space the app has, as it changes: read where it is used (in layout, or through a derived state), so a resize
 * or the keyboard's slide recomposes only what depends on the size.
 */
val LocalWindowSize = compositionLocalOf<State<DpSize>> { mutableStateOf(DpSize(1280.dp, 720.dp)) }

/**
 * Measures the space the app has and provides [LocalWindowLayout], [LocalWindowSize] and the matching
 * [LocalPlezyDimens] to [content]. Placed once at the root, so every screen adapts to the window, not the device. On
 * TV a hold of Select is a long press after 500 ms, whatever the system's timeout (400 ms from Android 12):
 * it opens an item's menu, a shorter press activates the item.
 */
@Composable
fun AdaptiveLayout(formFactor: FormFactor, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    BoxWithConstraints(modifier.fillMaxSize()) {
        // The space in the composition's density, not the measure's: a new density (the car's scale changed) over the
        // same pixels recomposes this before it measures again.
        val (width, height) = with(LocalDensity.current) { constraints.maxWidth.toDp() to constraints.maxHeight.toDp() }
        val widthClass = WidthClass.of(width)
        val layout = remember(formFactor, widthClass) { WindowLayout(formFactor, widthClass) }
        val dimens = remember(layout) { PlezyDimens.of(layout) }
        val measured = DpSize(width, height)
        val size = remember { mutableStateOf(measured) }
        SideEffect { size.value = measured }
        val system = LocalViewConfiguration.current
        val configuration = remember(formFactor, system) {
            if (formFactor == FormFactor.TV) {
                object : ViewConfiguration by system {
                    override val longPressTimeoutMillis = TV_HOLD_MILLIS
                }
            } else {
                system
            }
        }
        CompositionLocalProvider(
            LocalWindowLayout provides layout,
            LocalWindowSize provides size,
            LocalPlezyDimens provides dimens,
            LocalViewConfiguration provides configuration,
        ) {
            content()
        }
    }
}

/** How long Select is held on TV before it opens an item's menu. */
private const val TV_HOLD_MILLIS = 500L

/**
 * Whether text is at a large font scale: Android's 1.5 and up (its largest is 2.0), the scales that match iOS's
 * accessibility text sizes. A row that puts artwork beside text then puts the text under the artwork, whole.
 */
@Composable
@ReadOnlyComposable
fun largeFontScale(): Boolean = LocalDensity.current.fontScale >= LARGE_FONT_SCALE

/** The least font scale at which [largeFontScale] holds. */
private const val LARGE_FONT_SCALE = 1.5f
