package com.edde746.plezy.ui.libraries

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.ui.components.LocalScrollToTop
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map

/** The Libraries destination: the servers' libraries ([LibrariesScreen]). */
@Composable
fun LibrariesDestination(app: AppSession, modifier: Modifier = Modifier) {
    // The Libraries tab picked again while it shows: the library's lists go back to their tops.
    val toTop = remember(app) { app.navigator.reselected.filter { it == TopLevelDestination.LIBRARIES }.map { } }
    CompositionLocalProvider(LocalScrollToTop provides toTop) { LibrariesScreen(app, modifier) }
}
