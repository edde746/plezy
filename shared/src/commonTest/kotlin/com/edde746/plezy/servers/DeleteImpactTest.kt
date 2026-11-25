package com.edde746.plezy.servers

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaVersion
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class DeleteImpactTest {
    private val shared = "/tv/Breaking Bad/Season 01/S01E02-E03.mkv"

    /** A browse row that carried no media: the probe has to ask the detail endpoint. */
    private val thinEpisode = episode("ep-2", index = 2)

    @Test
    fun aThinRowRecoversScopeFromDetailAndFindsTheEpisodeSharingItsFile() = runTest {
        val server = server(
            details = mapOf("ep-2" to episode("ep-2", 2, files = listOf(shared))),
            season = listOf(
                episode("ep-1", 1, files = listOf("/tv/Breaking Bad/Season 01/S01E01.mkv")),
                episode("ep-2", 2, files = listOf(shared)),
                episode("ep-3", 3, files = listOf(shared)),
            ),
        )

        val impact = resolveDeleteImpact(thinEpisode, server)

        assertEquals(DeleteImpactScope.BROAD, impact.scope)
        assertEquals(setOf(shared), impact.files)
        assertEquals(listOf("ep-3"), impact.sharedWith.map { it.id })
        assertTrue("fetchItem:ep-2" in server.calls && "fetchChildren:season-1" in server.calls)
    }

    @Test
    fun anEpisodeAloneInItsFileResolvesAsExclusive() = runTest {
        val own = "/tv/Breaking Bad/Season 01/S01E02.mkv"
        val server = server(
            details = mapOf("ep-2" to episode("ep-2", 2, files = listOf(own))),
            season = listOf(episode("ep-2", 2, files = listOf(own)), episode("ep-3", 3, files = listOf("/tv/Breaking Bad/Season 01/S01E03.mkv"))),
        )

        val impact = resolveDeleteImpact(thinEpisode, server)

        assertEquals(DeleteImpactScope.EXCLUSIVE, impact.scope)
        assertTrue(impact.sharedWith.isEmpty())
    }

    @Test
    fun aMultiPartEpisodeCountsEveryFileItWillDestroy() = runTest {
        val parts = listOf("/tv/bb/S01E02-cd1.mkv", "/tv/bb/S01E02-cd2.mkv")
        val server = server(details = mapOf("ep-2" to episode("ep-2", 2, files = parts)), season = listOf(episode("ep-2", 2, files = parts)))

        val impact = resolveDeleteImpact(thinEpisode, server)

        assertEquals(DeleteImpactScope.BROAD, impact.scope)
        assertEquals(parts.toSet(), impact.files)
        assertTrue(impact.sharedWith.isEmpty())
    }

    @Test
    fun aPartCarryingNoPathIsUnverifiedNotASingleKnownFile() = runTest {
        val server = server(details = mapOf("ep-2" to episode("ep-2", 2, files = listOf(null))), season = emptyList())

        val impact = resolveDeleteImpact(thinEpisode, server)

        assertEquals(DeleteImpactScope.UNVERIFIED, impact.scope)
        assertEquals(DeleteImpactUnverifiedReason.NO_FILE_INFO, impact.reason)
        assertTrue(impact.files.isEmpty())
    }

    @Test
    fun aPayloadWithNoMediaAtAllIsUnverified() = runTest {
        val server = server(details = mapOf("ep-2" to episode("ep-2", 2)), season = emptyList())

        val impact = resolveDeleteImpact(thinEpisode, server)

        assertEquals(DeleteImpactUnverifiedReason.NO_FILE_INFO, impact.reason)
    }

    @Test
    fun aSiblingWhosePathStaysUnknownBlocksAnExclusiveVerdict() = runTest {
        val server = server(
            details = mapOf("ep-2" to episode("ep-2", 2, files = listOf(shared)), "ep-3" to episode("ep-3", 3, files = listOf(null))),
            season = listOf(episode("ep-2", 2, files = listOf(shared)), episode("ep-3", 3, files = listOf(null))),
        )

        val impact = resolveDeleteImpact(thinEpisode, server)

        assertEquals(DeleteImpactScope.UNVERIFIED, impact.scope)
        assertEquals(DeleteImpactUnverifiedReason.NO_FILE_INFO, impact.reason)
        assertTrue("fetchItem:ep-3" in server.calls)
    }

    @Test
    fun aSiblingRowWithoutAPathIsResolvedBeforeRulingOutASharedFile() = runTest {
        val server = server(
            details = mapOf("ep-2" to episode("ep-2", 2, files = listOf(shared)), "ep-3" to episode("ep-3", 3, files = listOf(shared))),
            season = listOf(episode("ep-2", 2, files = listOf(shared)), episode("ep-3", 3)),
        )

        val impact = resolveDeleteImpact(thinEpisode, server)

        assertEquals(DeleteImpactScope.BROAD, impact.scope)
        assertEquals(listOf("ep-3"), impact.sharedWith.map { it.id })
    }

    @Test
    fun aFailedSiblingLookupIsATransientProbeFailure() = runTest {
        val server = server(details = mapOf("ep-2" to episode("ep-2", 2, files = listOf(shared))), season = listOf(episode("ep-3", 3)))

        val impact = resolveDeleteImpact(thinEpisode, server)

        assertEquals(DeleteImpactScope.UNVERIFIED, impact.scope)
        assertEquals(DeleteImpactUnverifiedReason.PROBE_FAILED, impact.reason)
    }

    @Test
    fun aMovieIsBoundByItsOwnPartsWithoutListingAnything() = runTest {
        val movie = MediaItem("m-1", BackendKind.PLEX, MediaKind.MOVIE, mediaVersions = versions(listOf("/movies/a.mkv")))
        val server = server(details = emptyMap(), season = emptyList())

        val impact = resolveDeleteImpact(movie, server)

        assertEquals(DeleteImpactScope.EXCLUSIVE, impact.scope)
        assertTrue(server.calls.isEmpty())
    }

    @Test
    fun stopsAtTheFirstSiblingItCannotResolveInsteadOfFanningOut() = runTest {
        val server = server(
            details = mapOf("ep-2" to episode("ep-2", 2, files = listOf(shared))),
            season = listOf(episode("ep-3", 3), episode("ep-4", 4), episode("ep-5", 5)),
        )

        resolveDeleteImpact(thinEpisode, server)

        assertEquals(listOf("fetchItem:ep-2", "fetchChildren:season-1", "fetchItem:ep-3"), server.calls)
    }

    @Test
    fun asksNothingExtraOfASeasonWhoseRowsAlreadyCarryPaths() = runTest {
        val server = server(
            details = emptyMap(),
            season = listOf(episode("ep-3", 3, files = listOf("/a.mkv")), episode("ep-4", 4, files = listOf("/b.mkv"))),
        )

        resolveDeleteImpact(episode("ep-2", 2, files = listOf(shared)), server)

        assertEquals(listOf("fetchChildren:season-1"), server.calls)
    }

    @Test
    fun noFurtherSiblingIsFetchedOnceTheDeadlineHasPassed() = runTest {
        val server = server(
            details = mapOf("ep-2" to episode("ep-2", 2, files = listOf(shared))),
            season = listOf(episode("ep-3", 3), episode("ep-4", 4)),
        )
        server.items = { id ->
            if (id == "ep-3") delay(20.seconds)
            if (id == "ep-2") episode("ep-2", 2, files = listOf(shared)) else episode(id, 3, files = listOf("/other.mkv"))
        }

        val impact = resolveDeleteImpact(thinEpisode, server, timeout = 10.seconds)

        assertEquals(DeleteImpactUnverifiedReason.PROBE_FAILED, impact.reason)
        assertTrue("fetchItem:ep-4" !in server.calls)
    }

    @Test
    fun theSeasonIsNeverListedWhenTheDeadlineExpiresOnTheItemItself() = runTest {
        val server = server(details = emptyMap(), season = emptyList())
        server.items = { awaitCancellation() }

        val impact = resolveDeleteImpact(thinEpisode, server, timeout = 10.seconds)

        assertEquals(DeleteImpactUnverifiedReason.PROBE_FAILED, impact.reason)
        assertEquals(listOf("fetchItem:ep-2"), server.calls)
    }

    @Test
    fun completePartFilesRejectsWhatItCannotTrust() {
        assertNull(completePartFiles(emptyList()))
        assertNull(completePartFiles(listOf(MediaVersion("v-1"))))
        assertNull(completePartFiles(listOf(MediaVersion("v-1", parts = listOf(MediaPart("p-1", file = "/a.mkv"), MediaPart("p-2"))))))
    }

    @Test
    fun completePartFilesCollapsesDuplicatePathsAndKeepsEveryPart() {
        val a = MediaVersion("v-1", parts = listOf(MediaPart("p-1", file = "/a.mkv"), MediaPart("p-2", file = "/b.mkv")))
        val b = MediaVersion("v-2", parts = listOf(MediaPart("p-3", file = "/a.mkv")))
        assertEquals(setOf("/a.mkv", "/b.mkv"), completePartFiles(listOf(a, b)))
    }

    private fun server(details: Map<String, MediaItem>, season: List<MediaItem>) = FakeMediaBackend("plex-1").apply {
        items = { id -> details[id] ?: throw IllegalStateException("404 $id") }
        children = { parent -> if (parent == "season-1") season else throw IllegalStateException("404 $parent") }
    }

    private fun episode(id: String, index: Int, files: List<String?>? = null) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        title = "Episode $index",
        index = index,
        parentIndex = 1,
        parentId = "season-1",
        grandparentId = "show-1",
        grandparentTitle = "Breaking Bad",
        serverId = "plex-1",
        mediaVersions = files?.let(::versions),
    )

    private fun versions(files: List<String?>) =
        listOf(MediaVersion("v-1", parts = files.mapIndexed { i, file -> MediaPart("p-$i", file = file) }))
}
