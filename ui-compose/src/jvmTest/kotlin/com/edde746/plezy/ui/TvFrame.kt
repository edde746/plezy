package com.edde746.plezy.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.LocalOverlayOpeners
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.focus.LocalScreenFocus
import com.edde746.plezy.ui.focus.ScreenFocus
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.focus.focusGate
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner

/**
 * A TV app as the browse screens' focus tests need it, 960 × 540: the overlays' host, the navigation (one button at the
 * start, [NAVIGATION]) and one screen of the back stack (its focus home and gate) holding [content], on view while
 * [onView] (false: a screen or a root route over it). The system's Back comes from [back]
 * ([DirectNavigationEventInput.backCompleted]).
 */
@Composable
internal fun TvFrame(back: DirectNavigationEventInput? = null, onView: () -> Boolean = { true }, content: @Composable () -> Unit) {
    val dispatcher = remember { NavigationEventDispatcher().also { dispatcher -> back?.let(dispatcher::addInput) } }
    val owner = remember {
        object : NavigationEventDispatcherOwner {
            override val navigationEventDispatcher = dispatcher
        }
    }
    CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
        PlezyTheme {
            Box(Modifier.size(960.dp, 540.dp)) {
                AdaptiveLayout(FormFactor.TV, Modifier.arrowKeyFocus()) {
                    CompositionLocalProvider(LocalAppearance provides Appearance.of(AppearanceSettings(), FormFactor.TV, supporterUnlocked = false)) {
                        OverlayHostBox {
                            val screen = remember { ScreenFocus(onView) }
                            Row {
                                CompositionLocalProvider(LocalOverlayOpeners provides false) { PlezyButton(NAVIGATION, {}, Modifier.fillMaxHeight()) }
                                Box(Modifier.fillMaxSize().then(screen.modifier).focusGate(onView)) {
                                    CompositionLocalProvider(LocalScreenFocus provides screen) { content() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/** The navigation's button in a [TvFrame]. */
internal const val NAVIGATION = "Navigation"

/** A movie's card titled [title], under the id [id]. */
internal fun movieCard(id: String, title: String = id) =
    MediaCardUi(id = id, title = title, caption = null, shape = CardShape.POSTER, placeholder = PlaceholderKind.MOVIE, artwork = null)

/** The card titled [title]. */
internal fun card(title: String): SemanticsMatcher = hasContentDescription(title)
