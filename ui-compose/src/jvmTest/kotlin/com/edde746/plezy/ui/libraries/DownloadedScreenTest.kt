package com.edde746.plezy.ui.libraries

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.navigation.Route
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Where a title in Downloads opens: its offline screen, or nothing (it plays, or opens elsewhere). */
class DownloadedScreenTest {
    /** A downloaded collection's folder opens the collection's own screen, offline, on its server. */
    @Test
    fun aCollectionFolderOpensItsOfflineCollectionScreen() {
        assertEquals(Route.CollectionDetail(ServerId("s1"), "c1", offline = true), downloadedScreen(item("c1", MediaKind.COLLECTION)))
    }

    /** A movie, show or season opens its offline detail. */
    @Test
    fun aMovieShowOrSeasonOpensItsOfflineDetail() {
        for (kind in listOf(MediaKind.MOVIE, MediaKind.SHOW, MediaKind.SEASON)) {
            assertEquals(Route.MediaDetail(ServerId("s1"), "m1", offline = true), downloadedScreen(item("m1", kind)), "$kind")
        }
    }

    /** An episode, a track or an album has no offline screen of its own here: it plays or opens its album. */
    @Test
    fun anEpisodeTrackOrAlbumOpensNoScreen() {
        for (kind in listOf(MediaKind.EPISODE, MediaKind.TRACK, MediaKind.ALBUM)) assertNull(downloadedScreen(item("e1", kind)), "$kind")
    }

    private fun item(id: String, kind: MediaKind) = MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = kind, title = id, serverId = "s1")
}
