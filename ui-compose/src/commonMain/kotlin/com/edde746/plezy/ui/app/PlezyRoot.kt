package com.edde746.plezy.ui.app

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.RootScreen
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.updates.UpdateDialog

/**
 * The product app: [root] on [platform], the splash while the database opens, the startup failure screen when it can't
 * or the earlier releases' data can't be imported ([RootScreen.Failed], whose Retry starts again), then the app. They
 * switch without a cross-fade. The splash and the failure screen paint the theme the app will start in
 * ([RootSession.startupAppearance]) once the stored settings are read, the device's default before. With
 * [transparentWhileLoading] the splash paints no background, so the platform's launch screen under the window stays on
 * display (Android, whose window already holds the user's launch colour); the failure screen is always opaque. Where
 * the platform has [PlezyPlatform.updates], their launch check runs once the app shows and their dialog shows over it.
 * [onResetData] resets the app's saved data when the start failed for it ([StartupFailureScreen]'s Reset app data) and
 * starts the app again; null where the platform's database never fails here.
 */
@Composable
fun PlezyRoot(
    root: RootSession,
    platform: PlezyPlatform,
    modifier: Modifier = Modifier,
    transparentWhileLoading: Boolean = false,
    onResetData: (suspend () -> Unit)? = null,
) {
    val screen by root.screen.collectAsState()
    val app = (screen as? RootScreen.Main)?.app
    val appearance = shownAppearance(root)
    val loading = screen == RootScreen.Starting && transparentWhileLoading
    val player = app != null && key(app) { playerShown(app) }
    PlezyFrame(root.graph, platform, appearance, modifier, transparent = loading || player, playerShown = player) {
        when (val shown = screen) {
            RootScreen.Starting -> {
                val startup by root.startup.state.collectAsState()
                StartingScreen(startup.status, transparent = loading)
            }
            is RootScreen.Failed -> StartupFailureScreen(shown.record, root::retry, onResetData)
            is RootScreen.Main -> key(shown.app) { AppContent(shown.app) }
        }
        platform.updates?.let { updates ->
            LaunchedEffect(updates) { updates.checkAtLaunch(root) }
            UpdateDialog(updates)
        }
    }
}

/**
 * The appearance [root] paints ([PlezyRoot]): the running app's, else the one it will start in
 * ([RootSession.startupAppearance]); null before that is known.
 */
@Composable
fun shownAppearance(root: RootSession): Appearance? {
    val app = (root.screen.collectAsState().value as? RootScreen.Main)?.app
    val startupAppearance by root.startupAppearance.collectAsState()
    return app?.let { key(it) { it.appearance.collectAsState().value } } ?: startupAppearance
}

private val LoaderSize = 56.dp

/**
 * The splash, while the app starts: the loader in the middle of the screen and, under it, [status], the step the
 * start is on (`StartupUiState.status`: null until the start has taken half a second). The loader stays where it is
 * when the line comes. In the theme of the caller: the app's frame, or the desktop window's before the frame; on the
 * theme's background, or none while [transparent] (the platform's launch screen shows under it).
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun StartingScreen(status: String?, transparent: Boolean = false) {
    val background = if (transparent) Color.Transparent else MaterialTheme.colorScheme.background
    Box(Modifier.fillMaxSize().background(background), contentAlignment = Alignment.Center) {
        LoadingIndicator(Modifier.size(LoaderSize))
        if (status != null) {
            // The lower half of the screen, the line at its top just under the loader.
            Column(Modifier.fillMaxSize()) {
                Spacer(Modifier.weight(1f))
                Box(
                    Modifier.weight(1f).fillMaxWidth().padding(start = 32.dp, top = LoaderSize / 2 + 20.dp, end = 32.dp),
                    contentAlignment = Alignment.TopCenter,
                ) {
                    Text(
                        status,
                        Modifier.layoutProbe("startup.status"),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.bodyLarge,
                    )
                }
            }
        }
    }
}
