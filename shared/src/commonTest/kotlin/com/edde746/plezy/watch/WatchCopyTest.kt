package com.edde746.plezy.watch

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaVersion
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNull

/** A room's copy: what makes two the same file, and which of an item's versions the room opens. */
class WatchCopyTest {
    private val versions = listOf(
        MediaVersion(id = "v0", videoResolution = "4k", videoCodec = "hevc", container = "mkv"),
        MediaVersion(id = "v1", videoResolution = "1080", videoCodec = "h264", container = "mkv"),
    )
    private val movie = MediaItem(id = "movie-1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = "Alien", serverId = "srv", mediaVersions = versions)

    private fun copyOf(versionId: String) = WatchCopy(serverId = "srv", itemId = "movie-1", versionId = versionId, item = movie)

    @Test
    fun aCopyIsItsServerItemAndVersionOnly() {
        assertEquals(copyOf("v1"), WatchCopy("srv", "movie-1", "v1"))
        assertNotEquals(copyOf("v1"), copyOf("v0"))
        assertNotEquals(copyOf(""), WatchCopy("other", "movie-1", ""))
        assertEquals("", WatchCopy.of(movie.copy(mediaVersions = null), null).versionId, "an item without versions")
    }

    @Test
    fun opensTheVersionTheRoomChose() {
        assertEquals(WatchVersion(1, "v1"), watchVersionOf(movie, copyOf("v1")))
    }

    @Test
    fun yieldsToTheViewersOwnVersionWhenTheCopyNamesNoneOrTheItemNoLongerListsIt() {
        assertNull(watchVersionOf(movie, copyOf("")))
        assertNull(watchVersionOf(movie, copyOf("replaced")))
    }

    @Test
    fun passesTheSourceThroughWhenTheItemListsNoVersions() {
        assertEquals(WatchVersion(0, "v1"), watchVersionOf(movie.copy(mediaVersions = null), copyOf("v1")))
    }
}
