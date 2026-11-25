package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.playDownloaded
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.navigation.LibrarySection
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.ui.components.LocalScrollToTop
import com.edde746.plezy.ui.downloads.DownloadsScreen
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map

/**
 * The Libraries destination: the servers' libraries ([LibrariesScreen]) and, where the device keeps downloads, the
 * downloads ([DownloadsScreen]), as its sections ([LibrarySection]). Each section's filter row starts with the library
 * chip, which picks a library or Downloads. Offline only the downloads show, without the chip. A section asked for from
 * elsewhere (Home's Downloads shortcut, a remote's Downloads tab, a development launch's start:
 * [com.edde746.plezy.presentation.navigation.PlezyNavigator.openLibrary]) shows at once and holds until another is
 * picked here: the navigator keeps it, so the screen made anew (a profile switch remakes every screen) shows it too.
 */
@Composable
fun LibrariesDestination(app: AppSession, modifier: Modifier = Modifier) {
    val shell by app.shell.state.collectAsState()
    val downloads = app.downloads != null
    var chosen by rememberSaveable { mutableStateOf(LibrarySection.LIBRARY) }
    val asked by app.navigator.librarySection.collectAsState()
    val pick = { picked: LibrarySection ->
        app.navigator.takeLibrarySection()
        chosen = picked
    }
    val section = when {
        !downloads -> LibrarySection.LIBRARY
        shell.offline -> LibrarySection.DOWNLOADS
        else -> asked ?: chosen
    }
    // The Libraries tab picked again while it shows: the library's or the downloads' lists go back to their tops.
    val toTop = remember(app) { app.navigator.reselected.filter { it == TopLevelDestination.LIBRARIES }.map { } }
    Box(modifier.fillMaxSize()) {
        CompositionLocalProvider(LocalScrollToTop provides toTop) {
            when (section) {
                LibrarySection.LIBRARY -> LibrariesScreen(app, onDownloads = if (downloads) ({ pick(LibrarySection.DOWNLOADS) }) else null)
                LibrarySection.DOWNLOADS -> DownloadsSection(app, picker = !shell.offline) { pick(LibrarySection.LIBRARY) }
            }
        }
    }
}

/**
 * The downloads: a movie, show, season or collection opens its offline screen ([downloadedScreen]), an album opens its
 * screen, an episode or a track plays. With [picker] its row starts with the library chip; a library picked there
 * shows ([onLibrary]).
 */
@Composable
private fun DownloadsSection(app: AppSession, picker: Boolean, onLibrary: () -> Unit) {
    val store = app.downloadsStore() ?: return
    val libraries = remember(app) { app.libraries() }
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
        onPlayTracks = app.musicScreens::playDownloaded,
        leading = {
            if (picker && libraries != null) {
                val state by libraries.state.collectAsState()
                LibraryPicker(
                    state,
                    downloads = true,
                    onLibrary = { key ->
                        libraries.selectLibrary(key)
                        onLibrary()
                    },
                    onDownloads = {},
                )
            }
        },
    )
}

/**
 * The offline screen a downloaded [item] opens on: a movie's, show's or season's detail, a collection's own screen (its
 * downloaded titles); null for what plays or opens elsewhere (albums, episodes, tracks).
 */
internal fun downloadedScreen(item: MediaItem): Route? {
    val serverId = { ServerId(checkNotNull(item.serverId) { "download without a server" }) }
    return when (item.kind) {
        MediaKind.MOVIE, MediaKind.SHOW, MediaKind.SEASON -> Route.MediaDetail(serverId(), item.id, offline = true)
        MediaKind.COLLECTION -> Route.CollectionDetail(serverId(), item.id, offline = true)
        else -> null
    }
}
