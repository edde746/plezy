package com.edde746.plezy.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DownloadChoicesTest {
    @Test
    fun episodeCountValidationReturnsALocalizedMessageForInvalidInput() {
        assertEquals(T.downloads.invalidEpisodeCount, validateEpisodeCountInput("", allowZero = false))
        assertEquals(T.downloads.invalidEpisodeCount, validateEpisodeCountInput("0", allowZero = false))
        assertEquals(T.downloads.invalidEpisodeCount, validateEpisodeCountInput("not-a-number", allowZero = true))
    }

    @Test
    fun episodeCountValidationAcceptsZeroOnlyWhenRequested() {
        assertNull(validateEpisodeCountInput("0", allowZero = true))
        assertNull(validateEpisodeCountInput("12", allowZero = false))
    }

    @Test
    fun aResultsMessageNamesTheRuleChangeFirstThenTheQueuedKind() {
        assertEquals(T.downloads.syncRuleUpdated, DownloadResult(count = 3, syncRuleCreated = true, syncRuleUpdated = true).toSnackBarMessage())
        assertEquals(T.downloads.syncRuleListCreated, DownloadResult(count = 3, syncRuleCreated = true, isListRule = true).toSnackBarMessage())
        assertEquals(T.downloads.syncRuleCreated(count = "3"), DownloadResult(count = 3, syncRuleCreated = true).toSnackBarMessage())
        assertEquals(T.downloads.tracksQueued(count = "4"), DownloadResult(count = 4, unit = QueuedUnit.TRACKS).toSnackBarMessage())
        assertEquals(T.downloads.episodesQueued(count = "4"), DownloadResult(count = 4).toSnackBarMessage())
        assertEquals(T.downloads.downloadQueued, DownloadResult(count = 1).toSnackBarMessage())
    }

    @Test
    fun aCollectionsToastNamesMoviesEpisodesTracksOrItemsByWhatItQueued() {
        fun toast(vararg kinds: MediaKind) = DownloadResult(count = 4, isListRule = true, unit = QueuedUnit.of(kinds.asList())).toSnackBarMessage()
        assertEquals(T.downloads.moviesQueued(count = "4"), toast(MediaKind.MOVIE, MediaKind.MOVIE))
        assertEquals(T.downloads.episodesQueued(count = "4"), toast(MediaKind.SHOW, MediaKind.EPISODE))
        assertEquals(T.downloads.tracksQueued(count = "4"), toast(MediaKind.ALBUM, MediaKind.TRACK))
        assertEquals(T.downloads.itemsQueued(count = "4"), toast(MediaKind.MOVIE, MediaKind.SHOW))
        assertEquals(T.downloads.itemsQueued(count = "4"), toast())
    }

    @Test
    fun aSingleItemsUnitFollowsItsKind() {
        assertEquals(QueuedUnit.MOVIES, QueuedUnit.of(MediaKind.MOVIE))
        assertEquals(QueuedUnit.EPISODES, QueuedUnit.of(MediaKind.SEASON))
        assertEquals(QueuedUnit.TRACKS, QueuedUnit.of(MediaKind.ARTIST))
        assertEquals(QueuedUnit.ITEMS, QueuedUnit.of(MediaKind.CLIP))
    }

    @Test
    fun feedbackMapsCellularBlocksAndFailuresToErrors() = runTest {
        assertEquals(DownloadFeedback(T.downloads.downloadQueued, false), queueWithFeedback { DownloadResult(1) })
        assertNull(queueWithFeedback { null })
        assertEquals(DownloadFeedback(T.settings.cellularDownloadBlocked, true), queueWithFeedback { throw CellularDownloadBlockedException() })
        assertEquals(true, queueWithFeedback { throw IllegalStateException("boom") }?.isError)
    }

    @Test
    fun pickerRowsMapToFilterAndCap() {
        assertEquals(DownloadChoice.entries - DownloadChoice.DELETE, DownloadChoice.options(hasDownloads = false))
        assertEquals(DownloadChoice.DELETE, DownloadChoice.options(hasDownloads = true).last())
        assertEquals(DownloadFilter.ALL, DownloadChoice.ALL.filter)
        assertNull(DownloadChoice.UNWATCHED.maxCount())
        assertEquals(10, DownloadChoice.NEXT_10.maxCount())
        assertEquals(7, DownloadChoice.CUSTOM.maxCount(7))
    }

    private val versions = listOf(MediaVersion("1080", videoResolution = "1080"))

    private fun episode(id: String, versions: List<MediaVersion>? = null) =
        MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.EPISODE, mediaVersions = versions)

    private fun season(id: String, index: Int = 1) = MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.SEASON, index = index)

    @Test
    fun representativeVersionsUsePagedLookupForSeasonMetadata() = runTest {
        val pages = mutableListOf<String>()
        val backend = FakeMediaBackend("s1").apply {
            childrenPage = { parent, start, size -> pages += "$parent@$start+$size"; LibraryPage(if (parent == "season-1") listOf(episode("episode-1")) else emptyList(), 10) }
            items = { id -> if (id == "episode-1") episode(id, versions) else null }
        }

        assertEquals(versions, fetchRepresentativeVersions(backend, season("season-1")))
        assertEquals(listOf("season-1@0+1"), pages)
        assertEquals(listOf("fetchChildrenPage:season-1", "fetchItem:episode-1"), backend.calls)
    }

    @Test
    fun representativeVersionsKeepFullSeasonLookupButPageTheSelectedSeasonsEpisodes() = runTest {
        val pages = mutableListOf<String>()
        val backend = FakeMediaBackend("s1").apply {
            children = { listOf(season("specials", 0), season("season-1")) }
            childrenPage = { parent, start, size -> pages += "$parent@$start+$size"; LibraryPage(if (parent == "season-1") listOf(episode("episode-1")) else emptyList(), 10) }
            items = { id -> if (id == "episode-1") episode(id, versions) else null }
        }
        val show = MediaItem(id = "show-1", backend = BackendKind.PLEX, kind = MediaKind.SHOW, title = "Show")

        assertEquals(versions, fetchRepresentativeVersions(backend, show))
        assertEquals(listOf("season-1@0+1"), pages)
        assertEquals(listOf("fetchChildren:show-1", "fetchChildrenPage:season-1", "fetchItem:episode-1"), backend.calls)
    }
}
