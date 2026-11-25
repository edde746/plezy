package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.CANCELLED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PARTIAL
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PAUSED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.downloads.DownloadProgress
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadTreeTest {
    private fun episodeNode(globalKey: String) = DownloadTreeNode(globalKey, "Episode", DownloadNodeType.EPISODE, COMPLETED)

    private fun seasonNode(key: String, children: List<DownloadTreeNode>) = DownloadTreeNode(key, "Season", DownloadNodeType.SEASON, COMPLETED, children = children)

    private fun showNode(key: String, children: List<DownloadTreeNode>) = DownloadTreeNode(key, "Show", DownloadNodeType.SHOW, COMPLETED, children = children)

    private fun episodeMeta(id: String, serverId: String?, grandparentId: String?, parentId: String?) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        title = "Ep $id",
        serverId = serverId,
        grandparentId = grandparentId,
        parentId = parentId,
    )

    private val standardMetadata = mapOf("plex1:ep100" to episodeMeta("100", "plex1", grandparentId = "42", parentId = "7"))

    @Test
    fun aShowRowBuildsItsGlobalKeyFromTheFirstEpisodesServerAndGrandparent() {
        val show = showNode("show42", listOf(seasonNode("show42:season7", listOf(episodeNode("plex1:ep100")))))

        assertEquals("plex1:42", resolveDownloadContainerGlobalKey(show, standardMetadata))
    }

    @Test
    fun aSeasonRowBuildsItsGlobalKeyFromTheFirstEpisodesServerAndParent() {
        val season = seasonNode("show42:season7", listOf(episodeNode("plex1:ep100")))

        assertEquals("plex1:7", resolveDownloadContainerGlobalKey(season, standardMetadata))
    }

    @Test
    fun episodeAndMovieRowsHaveNoContainerKey() {
        val movie = DownloadTreeNode("plex1:movie5", "M", DownloadNodeType.MOVIE, COMPLETED)

        assertNull(resolveDownloadContainerGlobalKey(episodeNode("plex1:ep100"), standardMetadata))
        assertNull(resolveDownloadContainerGlobalKey(movie, standardMetadata))
    }

    @Test
    fun aContainerWithoutDownloadsHasNoKey() {
        assertNull(resolveDownloadContainerGlobalKey(showNode("show42", emptyList()), emptyMap()))
    }

    @Test
    fun missingMetadataOfTheFirstDownloadGivesNoKey() {
        assertNull(resolveDownloadContainerGlobalKey(showNode("show42", listOf(episodeNode("plex1:ep100"))), emptyMap()))
    }

    @Test
    fun metadataWithoutAServerGivesNoKey() {
        val metadata = mapOf("plex1:ep100" to episodeMeta("100", serverId = null, grandparentId = "42", parentId = "7"))

        assertNull(resolveDownloadContainerGlobalKey(showNode("show42", listOf(episodeNode("plex1:ep100"))), metadata))
    }

    @Test
    fun aShowWhoseEpisodeLacksAGrandparentHasNoKey() {
        val metadata = mapOf("plex1:ep100" to episodeMeta("100", "plex1", grandparentId = null, parentId = "7"))

        assertNull(resolveDownloadContainerGlobalKey(showNode("show42", listOf(episodeNode("plex1:ep100"))), metadata))
    }

    @Test
    fun aSeasonWhoseEpisodeLacksAParentHasNoKey() {
        val metadata = mapOf("plex1:ep100" to episodeMeta("100", "plex1", grandparentId = "42", parentId = null))

        assertNull(resolveDownloadContainerGlobalKey(seasonNode("show42:season7", listOf(episodeNode("plex1:ep100"))), metadata))
    }

    @Test
    fun aShowWithSeveralSeasonsTakesTheFirstSeasonsFirstEpisode() {
        val show = showNode(
            "show42",
            listOf(
                seasonNode("show42:season1", listOf(episodeNode("plex1:ep100"))),
                seasonNode("show42:season2", listOf(episodeNode("plex1:ep200"))),
            ),
        )
        val metadata = mapOf(
            "plex1:ep100" to episodeMeta("100", "plex1", grandparentId = "42", parentId = "1"),
            "plex1:ep200" to episodeMeta("200", "plex1", grandparentId = "42", parentId = "2"),
        )

        assertEquals("plex1:42", resolveDownloadContainerGlobalKey(show, metadata))
    }

    @Test
    fun allCancelledChildrenAggregateToCancelledNotCompleted() {
        assertEquals(CANCELLED, determineDownloadAggregateStatus(listOf(CANCELLED)))
        assertEquals(CANCELLED, determineDownloadAggregateStatus(listOf(CANCELLED, CANCELLED)))
    }

    @Test
    fun completedMixedWithCancelledAggregatesToPartial() {
        assertEquals(PARTIAL, determineDownloadAggregateStatus(listOf(COMPLETED, CANCELLED)))
    }

    @Test
    fun aPartialChildKeepsTheContainerPartial() {
        assertEquals(PARTIAL, determineDownloadAggregateStatus(listOf(PARTIAL)))
        assertEquals(PARTIAL, determineDownloadAggregateStatus(listOf(COMPLETED, PARTIAL)))
    }

    @Test
    fun activePausedAndFailedTakePrecedenceInThatOrder() {
        assertEquals(DOWNLOADING, determineDownloadAggregateStatus(listOf(COMPLETED, DOWNLOADING, CANCELLED)))
        assertEquals(QUEUED, determineDownloadAggregateStatus(listOf(CANCELLED, QUEUED)))
        assertEquals(PAUSED, determineDownloadAggregateStatus(listOf(COMPLETED, PAUSED)))
        assertEquals(FAILED, determineDownloadAggregateStatus(listOf(FAILED, COMPLETED)))
        assertEquals(COMPLETED, determineDownloadAggregateStatus(listOf(COMPLETED)))
        assertEquals(QUEUED, determineDownloadAggregateStatus(emptyList()))
    }

    // Inserted out of order so the tree's own season and episode order shows.
    private val episodes = linkedMapOf(
        "srv:s2e1" to seasonEpisode("s2e1", season = 2, episode = 1),
        "srv:s1e2" to seasonEpisode("s1e2", season = 1, episode = 2),
        "srv:s1e1" to seasonEpisode("s1e1", season = 1, episode = 1),
    )

    private fun seasonEpisode(id: String, season: Int, episode: Int) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        title = "Episode $id",
        serverId = "srv",
        grandparentId = "show",
        grandparentTitle = "Show",
        parentId = "season-$season",
        parentTitle = "Season $season",
        parentIndex = season,
        index = episode,
    )

    private fun showRow(statuses: Map<String, DownloadedMediaStatus>): DownloadTreeNode {
        val downloads = statuses.mapValues { (key, status) -> DownloadProgress(globalKey = key, status = status) }
        return buildDownloadTree(downloads, episodes).single()
    }

    @Test
    fun retryAllRetriesAShowsFailedEpisodesInEpisodeOrderWhileAnotherStillDownloads() {
        val show = showRow(mapOf("srv:s2e1" to FAILED, "srv:s1e2" to FAILED, "srv:s1e1" to DOWNLOADING))

        assertTrue(DownloadRowAction.RETRY_ALL in downloadRowActions(show))
        assertEquals(listOf("srv:s1e2", "srv:s2e1"), show.leafKeys { it.status == FAILED })
    }

    @Test
    fun retryAllIsOfferedOnlyWhileAnEpisodeHasFailed() {
        val healthy = showRow(mapOf("srv:s2e1" to COMPLETED, "srv:s1e2" to QUEUED, "srv:s1e1" to DOWNLOADING))
        assertFalse(DownloadRowAction.RETRY_ALL in downloadRowActions(healthy))

        val failed = showRow(mapOf("srv:s2e1" to FAILED, "srv:s1e2" to COMPLETED, "srv:s1e1" to COMPLETED))
        assertTrue(DownloadRowAction.RETRY_ALL in downloadRowActions(failed))
    }

    @Test
    fun `container actions follow the aggregate status`() {
        fun show(status: DownloadedMediaStatus) = DownloadTreeNode("show", "Show", DownloadNodeType.SHOW, status)

        assertEquals(listOf(DownloadRowAction.PAUSE_ALL, DownloadRowAction.DELETE_ALL), downloadRowActions(show(DOWNLOADING)))
        assertEquals(listOf(DownloadRowAction.PAUSE_ALL, DownloadRowAction.DELETE_ALL), downloadRowActions(show(QUEUED)))
        assertEquals(listOf(DownloadRowAction.RESUME_ALL, DownloadRowAction.DELETE_ALL), downloadRowActions(show(PAUSED)))
        assertEquals(listOf(DownloadRowAction.DELETE_ALL), downloadRowActions(show(COMPLETED)))
    }

    @Test
    fun `leaf actions follow the leaf status`() {
        fun movie(status: DownloadedMediaStatus) = downloadRowActions(DownloadTreeNode("m", "Movie", DownloadNodeType.MOVIE, status))

        assertEquals(listOf(DownloadRowAction.PAUSE, DownloadRowAction.CANCEL), movie(DOWNLOADING))
        assertEquals(listOf(DownloadRowAction.CANCEL), movie(QUEUED))
        assertEquals(listOf(DownloadRowAction.RESUME), movie(PAUSED))
        assertEquals(listOf(DownloadRowAction.RETRY, DownloadRowAction.DELETE), movie(FAILED))
        assertEquals(listOf(DownloadRowAction.DELETE), movie(COMPLETED))
        assertEquals(listOf(DownloadRowAction.DELETE), movie(CANCELLED))
        assertEquals(emptyList(), movie(PARTIAL))
    }
}
