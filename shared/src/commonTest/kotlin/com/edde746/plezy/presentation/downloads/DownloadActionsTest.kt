package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.DownloadTranscoding
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.downloads.SyncRuleFilter
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.data.testData
import com.edde746.plezy.downloads.ControllerHarness
import com.edde746.plezy.downloads.DownloadResult
import com.edde746.plezy.downloads.FakeBackgroundWorkProbe
import com.edde746.plezy.downloads.diagnostics
import com.edde746.plezy.downloads.testMediaItem
import com.edde746.plezy.format.formatByteSize
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.detail.mediaSizeLabel
import com.edde746.plezy.presentation.player.PlayerStates
import com.edde746.plezy.strings.T
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadActionsTest {
    private var harness: ControllerHarness? = null
    private val srv = ServerId("srv")
    private val collection = testMediaItem("c1", MediaKind.COLLECTION, "srv", title = "Favourites")
    private val dialogs = DownloadDialogs()

    @AfterTest
    fun close() {
        harness?.close()
    }

    private var warning: BackgroundDownloadWarning? = null

    private suspend fun TestScope.actions(): DownloadActions {
        val h = ControllerHarness.create().also { harness = it }
        val settings = testData().deviceSettings
        val warning = BackgroundDownloadWarning(diagnostics(FakeBackgroundWorkProbe()), settings, {}, { true }, backgroundScope)
        this@DownloadActionsTest.warning = warning
        return DownloadActions(h.controller, dialogs, warning, settings)
    }

    /** Answers the open dialog whose rows include [label] with that row. */
    private suspend fun pick(label: String) {
        val open = dialogs.dialog.first { d -> d is DownloadDialog.Options && d.options.any { it.label == label } } as DownloadDialog.Options
        dialogs.choose(open.options.indexOfFirst { it.label == label })
    }

    private suspend fun TestScope.listDownload(actions: DownloadActions, filter: String, sync: String): DownloadResult? {
        val result = async { actions.showListDownloadOptionsAndQueue(collection, SyncRuleTarget.COLLECTION, emptyList(), FakeMediaBackend("srv")) }
        pick(filter)
        pick(sync)
        return result.await()
    }

    @Test
    fun keepingAListSyncedCreatesItsRuleThenUpdatesItsFilter() = runTest {
        val actions = actions()
        val c = harness!!.controller
        val key = c.syncRuleKeyFor(srv, "c1")

        val created = listDownload(actions, T.downloads.unwatchedOnly, T.downloads.keepSynced)
        assertEquals(true, created?.syncRuleCreated)
        val rule = c.getSyncRule(key)!!
        assertEquals(SyncRuleTarget.COLLECTION, rule.target)
        assertEquals(0, rule.episodeCount)
        assertEquals(SyncRuleFilter.UNWATCHED, rule.downloadFilter)

        val updated = listDownload(actions, T.downloads.allEpisodes, T.downloads.keepSynced)
        assertEquals(true, updated?.syncRuleUpdated)
        assertEquals(false, updated?.syncRuleCreated)
        assertEquals(SyncRuleFilter.ALL, c.getSyncRule(key)!!.downloadFilter)
    }

    @Test
    fun downloadingAListOnceLeavesNoRule() = runTest {
        val actions = actions()
        val result = listDownload(actions, T.downloads.allEpisodes, T.downloads.downloadOnce)
        assertEquals(false, result?.syncRuleCreated)
        assertNull(harness!!.controller.getSyncRule(harness!!.controller.syncRuleKeyFor(srv, "c1")))
    }

    @Test
    fun aCollectionsMenuDownloadFetchesItsItemsAndAsksHowToKeepThem() = runTest {
        val actions = actions()
        val c = harness!!.controller
        val detail = DetailDownload(c, actions, dialogs, warning!!, SmartDeletion(c))
        assertEquals(listOf(DownloadMenuEntry.DOWNLOAD_COLLECTION), listDownloadMenuEntries(c, collection, playlist = false))
        var fetched = 0

        val feedback = async {
            detail.perform(collection, DownloadMenuEntry.DOWNLOAD_COLLECTION, FakeMediaBackend("srv")) {
                fetched++
                emptyList()
            }
        }
        pick(T.downloads.allEpisodes)
        pick(T.downloads.keepSynced)
        feedback.await()

        assertEquals(1, fetched)
        assertEquals(SyncRuleTarget.COLLECTION, c.getSyncRule(c.syncRuleKeyFor(srv, "c1"))!!.target)
        assertEquals(listOf(DownloadMenuEntry.MANAGE_SYNC, DownloadMenuEntry.REMOVE_SYNC), listDownloadMenuEntries(c, collection, playlist = false))
    }

    private class TranscodingBackend : FakeMediaBackend("srv", BackendKind.JELLYFIN), DownloadTranscoding {
        init {
            items = { null }
        }

        override suspend fun resolveTranscodedDownload(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, quality: TranscodeQualityPreset) =
            DownloadResolution(null)

        override suspend fun stopDownloadTranscode(downloadUrl: String) = Unit
    }

    /** A 30 s movie whose one version states [bitrateKbps] and, when [sizeBytes] is set, has a file of that size. */
    private fun movie(bitrateKbps: Int, height: Int, sizeBytes: Long?) = testMediaItem("m1", MediaKind.MOVIE, "srv", title = "Movie").copy(
        durationMs = 30_000,
        mediaVersions = listOf(MediaVersion("v1", height = height, bitrate = bitrateKbps, parts = listOf(MediaPart("p1", sizeBytes = sizeBytes)))),
    )

    private suspend fun TestScope.offeredFor(movie: MediaItem): DownloadDialog.Options {
        val actions = actions()
        backgroundScope.launch { actions.resolveDownloadVersion(movie, TranscodingBackend()) }
        return dialogs.dialog.first { it is DownloadDialog.Options } as DownloadDialog.Options
    }

    @Test
    fun aJellyfinMovieOffersOnlySmallerQualitiesOriginalFirst() = runTest {
        val actions = actions()

        val config = async { actions.resolveDownloadVersion(movie(bitrateKbps = 7_500, height = 2160, sizeBytes = 28_000_000), TranscodingBackend()) }
        val open = dialogs.dialog.first { it is DownloadDialog.Options } as DownloadDialog.Options
        assertEquals(T.videoControls.qualityColumnHeader, open.title)
        // 28 MB over 30 s is about 7.5 Mbps: caps over 80 % of it (6 Mbps) would barely make the file smaller.
        val offered = listOf(
            TranscodeQualityPreset.ORIGINAL, TranscodeQualityPreset.P720_4MBPS, TranscodeQualityPreset.P720_3MBPS, TranscodeQualityPreset.P720_2MBPS,
            TranscodeQualityPreset.P480_1_5MBPS, TranscodeQualityPreset.P320_720, TranscodeQualityPreset.P240_320,
        )
        assertEquals(offered.map { PlayerStates.qualityLabel(it, 28_000_000 * 8 / 30_000) }, open.options.map { it.label })
        dialogs.choose(3)

        assertEquals(TranscodeQualityPreset.P720_2MBPS, config.await()?.quality)
    }

    @Test
    fun aCapJustUnderTheFilesRealBitrateIsLeftOut() = runTest {
        // The server states 7.5 Mbps; 15.375 MB over 30 s is 4.1 Mbps, so 720p 4 Mbps would save under a fifth.
        val open = offeredFor(movie(bitrateKbps = 7_500, height = 2160, sizeBytes = 15_375_000))
        val expected = listOf(PlayerStates.qualityLabel(TranscodeQualityPreset.ORIGINAL, 4_100), PlayerStates.qualityLabel(TranscodeQualityPreset.P720_3MBPS, null))
        assertEquals(expected, open.options.take(2).map { it.label })
    }

    @Test
    fun aCapAtFourFifthsOfTheFilesRealBitrateIsOffered() = runTest {
        // 18.75 MB over 30 s is 5 Mbps: 720p 4 Mbps is 80 % of it.
        val open = offeredFor(movie(bitrateKbps = 7_500, height = 2160, sizeBytes = 18_750_000))
        assertEquals(PlayerStates.qualityLabel(TranscodeQualityPreset.P720_4MBPS, null), open.options[1].label)
    }

    @Test
    fun withoutTheFilesSizeTheStatedBitrateDecides() = runTest {
        val open = offeredFor(movie(bitrateKbps = 7_500, height = 2160, sizeBytes = null))
        assertEquals(PlayerStates.qualityLabel(TranscodeQualityPreset.P720_4MBPS, null), open.options[1].label)
    }

    @Test
    fun everySizeInTheListPrintsLikeTheDetailScreens() = runTest {
        val movie = movie(bitrateKbps = 7_500, height = 2160, sizeBytes = 15_296_153)
        val open = offeredFor(movie)
        // The original's size is the detail screen's; a transcode's is at most its cap over the runtime, the same way.
        assertEquals(mediaSizeLabel(movie), open.options.first().detail)
        assertEquals(formatByteSize(15_296_153), open.options.first().detail)
        val twoMbps = open.options.single { it.label == PlayerStates.qualityLabel(TranscodeQualityPreset.P720_2MBPS, null) }
        assertEquals("≤ ${formatByteSize(2_000L * 30_000 / 8)}", twoMbps.detail)
    }

    @Test
    fun aSmallSourceDownloadsTheOriginalWithoutAsking() = runTest {
        val actions = actions()
        val small = movie(bitrateKbps = 300, height = 180, sizeBytes = 1_000_000)
        assertEquals(TranscodeQualityPreset.ORIGINAL, actions.resolveDownloadVersion(small, TranscodingBackend())?.quality)
        assertTrue(dialogs.dialog.value == null)
    }

    @Test
    fun presetsAboveTheSourcesPictureAreLeftOut() = runTest {
        val actions = actions()
        val offered = actions.downloadQualities(MediaVersion("v1", height = 480, bitrate = 20_000), runtimeMs = null).map { it.preset }
        assertEquals(
            listOf(TranscodeQualityPreset.ORIGINAL, TranscodeQualityPreset.P480_1_5MBPS, TranscodeQualityPreset.P320_720, TranscodeQualityPreset.P240_320),
            offered,
        )
    }

    @Test
    fun plexAndEmbyDownloadTheOriginalWithoutAsking() = runTest {
        val actions = actions()
        for (kind in listOf(BackendKind.PLEX, BackendKind.EMBY)) {
            val movie = testMediaItem("m1", MediaKind.MOVIE, "srv", title = "Movie")
            val backend = FakeMediaBackend("srv", kind).apply { items = { null } }
            assertEquals(TranscodeQualityPreset.ORIGINAL, actions.resolveDownloadVersion(movie, backend)?.quality, kind.name)
        }
        assertTrue(dialogs.dialog.value == null)
    }

    @Test
    fun syncAndDownloadMenuEntriesFollowTheRuleAndTheFiles() {
        val download = DownloadMenuEntry.DOWNLOAD
        assertEquals(
            listOf(DownloadMenuEntry.MANAGE_SYNC, DownloadMenuEntry.REMOVE_SYNC, DownloadMenuEntry.DELETE_DOWNLOAD),
            syncDownloadMenuEntries(hasSyncRule = true, hasAnyDownload = true, download = download),
        )
        assertEquals(
            listOf(DownloadMenuEntry.MANAGE_SYNC, DownloadMenuEntry.REMOVE_SYNC),
            syncDownloadMenuEntries(hasSyncRule = true, hasAnyDownload = false, download = download),
        )
        assertEquals(listOf(DownloadMenuEntry.DELETE_DOWNLOAD), syncDownloadMenuEntries(hasSyncRule = false, hasAnyDownload = true, download = download))
        assertEquals(listOf(download), syncDownloadMenuEntries(hasSyncRule = false, hasAnyDownload = false, download = download))
    }
}
