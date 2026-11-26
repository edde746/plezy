package com.edde746.plezy.ui.downloads

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.playDownloaded
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.ui.components.LocalScrollToTop
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map

/**
 * The Downloads destination ([DownloadsScreen]): a movie, show, season or collection opens its offline screen
 * ([downloadedScreen]), an album opens its screen, an episode or a track plays.
 */
@Composable
fun DownloadsDestination(app: AppSession, modifier: Modifier = Modifier) {
    val store = app.downloadsStore() ?: return
    // Downloads picked again while it shows: its lists go back to their tops.
    val toTop = remember(app) { app.navigator.reselected.filter { it == TopLevelDestination.DOWNLOADS }.map { } }
    CompositionLocalProvider(LocalScrollToTop provides toTop) {
        DownloadsScreen(
            store,
            onSyncRules = { app.navigator.navigate(Route.SyncRules) },
            onOpen = { item ->
                val screen = downloadedScreen(item)
                when {
                    screen != null -> app.navigator.navigate(screen)
                    // A downloaded album opens its screen, which shows its downloaded tracks while offline.
                    item.kind == MediaKind.ALBUM -> app.musicScreens.open(item)
                    else -> app.playDownloaded(item)
                }
            },
            modifier = modifier,
            onPlayTracks = app.musicScreens::playDownloaded,
        )
    }
}

/**
 * The offline screen a downloaded [item] opens on: a movie's or show's detail (a season's, which the detail opens as its
 * show at that season), a collection's own screen (its downloaded titles); null for what plays or opens elsewhere
 * (albums, episodes, tracks).
 */
internal fun downloadedScreen(item: MediaItem): Route? {
    val serverId = { ServerId(checkNotNull(item.serverId) { "download without a server" }) }
    return when (item.kind) {
        MediaKind.MOVIE, MediaKind.SHOW, MediaKind.SEASON -> Route.MediaDetail(serverId(), item.id, offline = true)
        MediaKind.COLLECTION -> Route.CollectionDetail(serverId(), item.id, offline = true)
        else -> null
    }
}
