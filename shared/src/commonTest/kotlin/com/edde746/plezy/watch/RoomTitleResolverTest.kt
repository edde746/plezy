package com.edde746.plezy.watch

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind as ItemKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.TitleQuery
import com.edde746.plezy.servers.LibraryLookupResult
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import party.openwatch.Candidate
import party.openwatch.Media
import party.openwatch.MediaKind
import party.openwatch.Series
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class RoomTitleResolverTest {
    private val servers = mutableMapOf<String, FakeMediaBackend>()
    private val queries = mutableListOf<TitleQuery>()
    private var answer: suspend (TitleQuery) -> LibraryLookupResult = { lookup(emptyList()) }

    private val resolver = RoomTitleResolver(clientFor = { servers[it] }, findCopies = { query -> queries += query; answer(query) })

    private fun lookup(
        items: List<MediaItem>,
        succeeded: Set<String> = emptySet(),
        failed: Set<String> = emptySet(),
        cancelled: Set<String> = emptySet(),
    ) = LibraryLookupResult(items, succeeded.ids(), cancelled.ids(), failed.ids(), emptySet())

    private fun Set<String>.ids() = mapTo(LinkedHashSet(), ::ServerId)

    private fun server(id: String, items: Map<String, MediaItem> = emptyMap(), error: Exception? = null) =
        FakeMediaBackend(id).apply { this.items = { itemId -> error?.let { throw it } ?: items[itemId] } }.also { servers[id] = it }

    private fun version(id: String, durationMs: Long? = null, sizeBytes: Long? = null, file: String? = null, accessible: Boolean? = null) =
        MediaVersion(id = id, parts = listOf(MediaPart(id = "$id-p", durationMs = durationMs, sizeBytes = sizeBytes, file = file, accessible = accessible)))

    private fun movie(id: String, serverId: String?, versions: List<MediaVersion>? = null, durationMs: Long? = null, kind: ItemKind = ItemKind.MOVIE) =
        MediaItem(id = id, backend = BackendKind.PLEX, kind = kind, title = "Alien", year = 1979, serverId = serverId,
            durationMs = durationMs, mediaVersions = versions)

    private fun movieMedia(ids: Map<String, String> = emptyMap(), server: String? = null, item: String? = null, version: String? = null) = Media(
        kind = MediaKind.MOVIE, title = "Alien", year = 1979, ids = ids, durationMs = 7_020_000,
        ext = server?.let { ext(it, item!!, version) },
    )

    private fun ext(server: String, item: String, version: String?) = buildJsonObject {
        put(MediaDescriptor.EXT_NAME, buildJsonObject {
            put("server", server)
            put("item", item)
            version?.let { put("version", it) }
        })
    }

    private fun ids(candidates: List<Candidate<WatchCopy>>) = candidates.map { it.id }

    @Test
    fun theSharedItemComesFirstItsSharedVersionLeadingAndIsNotListedTwice() = runTest {
        val shared = movie("m1", "home", versions = listOf(version("v1", 7_020_000), version("v2", 7_380_000)))
        server("home", mapOf("m1" to shared))
        val elsewhere = movie("m9", "nas", versions = listOf(version("w1", 7_020_000)))
        answer = { lookup(listOf(elsewhere, shared), succeeded = setOf("home", "nas")) }

        val candidates = resolver.resolve(movieMedia(server = "home", item = "m1", version = "v2"))

        assertEquals(listOf("home:m1:v2", "home:m1:v1", "nas:m9:w1"), ids(candidates))
        assertEquals(WatchCopy.of(shared, shared.mediaVersions!![1]), candidates.first().ref)
        assertSame(shared, candidates.first().ref.item, "the ref opens without another lookup")
    }

    @Test
    fun aServerThisProfileDoesNotReachOrAnUnreadableItemFallsBackToTheCatalogueSearch() = runTest {
        server("home", error = IllegalStateException("offline"))
        val found = movie("m9", "nas", versions = listOf(version("w1", 7_020_000)))
        answer = { lookup(listOf(found), succeeded = setOf("nas")) }

        assertEquals(listOf("nas:m9:w1"), ids(resolver.resolve(movieMedia(server = "home", item = "m1"))))
        assertEquals(listOf("nas:m9:w1"), ids(resolver.resolve(movieMedia(server = "elsewhere", item = "m1"))))
        assertEquals(2, queries.size)
    }

    @Test
    fun aVideoIsFoundThroughTheShortcutOnly() = runTest {
        val clip = movie("c1", "home", kind = ItemKind.CLIP, versions = listOf(version("v1", 60_000)))
        server("home", mapOf("c1" to clip))
        val video = Media(kind = MediaKind.VIDEO, title = "Birthday", durationMs = 60_000)

        assertEquals(listOf("home:c1:v1"), ids(resolver.resolve(video.copy(ext = ext("home", "c1", null)))))
        assertEquals(emptyList(), resolver.resolve(video))
        assertEquals(emptyList(), queries, "a video has no catalogue identity to search by")
    }

    @Test
    fun anItemOfAnotherKindThanTheMediaIsNoCandidate() = runTest {
        val episode = movie("e1", "home", kind = ItemKind.EPISODE, versions = listOf(version("v1", 7_020_000)))
        server("home", mapOf("e1" to episode))
        val show = movie("s1", "nas", kind = ItemKind.SHOW)
        val track = movie("t1", "nas", kind = ItemKind.TRACK, versions = listOf(version("v1", 7_020_000)))
        answer = { lookup(listOf(show, track, episode), succeeded = setOf("nas")) }

        assertEquals(emptyList(), resolver.resolve(movieMedia(server = "home", item = "e1")))
    }

    @Test
    fun everyPlayableVersionIsOneWithItsLengthSizeAndFileName() = runTest {
        val item = movie("m1", "nas", durationMs = 7_020_000, versions = listOf(
            version("hd", 7_020_000, 100, "/m/Alien HD.mkv"),
            version("gone", 7_020_000, accessible = false),
            version("4k", 7_021_000, 900, """D:\m\Alien 4K.mkv"""),
        ))
        answer = { lookup(listOf(item), succeeded = setOf("nas")) }

        val candidates = resolver.resolve(movieMedia())

        assertEquals(listOf("nas:m1:hd", "nas:m1:4k"), ids(candidates))
        assertEquals(
            listOf(listOf(7_020_000L, 100L, "Alien HD.mkv", null), listOf(7_021_000L, 900L, "Alien 4K.mkv", null)),
            candidates.map { listOf(it.durationMs, it.sizeBytes, it.name, it.probe) },
        )
    }

    @Test
    fun anItemWithoutVersionsIsOneCandidateWithTheItemLength() = runTest {
        answer = { lookup(listOf(movie("m1", "nas", durationMs = 7_020_000)), succeeded = setOf("nas")) }

        val candidate = resolver.resolve(movieMedia()).single()

        assertEquals("nas:m1:", candidate.id)
        assertEquals("", candidate.ref.versionId)
        assertEquals(7_020_000L, candidate.durationMs)
        assertEquals(null to null, candidate.sizeBytes to candidate.name)
    }

    @Test
    fun aVersionOfUnknownLengthGetsAProbeThatReadsTheItemAgain() = runTest {
        val listed = movie("m1", "nas", durationMs = 7_020_000, versions = listOf(version("a"), version("b")))
        val fresh = movie("m1", "nas", versions = listOf(version("a", 7_020_000), version("b", 7_380_000)))
        var stored = mapOf("m1" to fresh)
        val nas = FakeMediaBackend("nas").apply { items = { stored[it] } }.also { servers["nas"] = it }
        answer = { lookup(listOf(listed), succeeded = setOf("nas")) }

        val candidates = resolver.resolve(movieMedia())

        assertEquals(listOf(null, null), candidates.map { it.durationMs })
        assertEquals(7_380_000L, candidates[1].probe!!())
        assertEquals(listOf("fetchItem:m1"), nas.calls)

        stored = emptyMap()
        assertNull(candidates[0].probe!!(), "the item is gone")
    }

    @Test
    fun withoutAClientForItsServerACandidateOfUnknownLengthHasNoProbe() = runTest {
        answer = { lookup(listOf(movie("m1", "gone", versions = listOf(version("a"), version("b")))), succeeded = setOf("gone")) }
        assertEquals(listOf(null, null), resolver.resolve(movieMedia()).map { it.probe })
    }

    @Test
    fun itemsWithoutAServerAndDuplicatesAreDropped() = runTest {
        val item = movie("m1", "nas", versions = listOf(version("v", 7_020_000)))
        val orphan = movie("m2", null, durationMs = 7_020_000)
        answer = { lookup(listOf(item, orphan, item), succeeded = setOf("nas")) }

        assertEquals(listOf("nas:m1:v"), ids(resolver.resolve(movieMedia())))
    }

    @Test
    fun copiesFoundOnSomeServersAreReturnedThoughOthersFailed() = runTest {
        val item = movie("m1", "nas", versions = listOf(version("v", 7_020_000)))
        answer = { lookup(listOf(item), succeeded = setOf("nas"), failed = setOf("down")) }
        assertEquals(listOf("nas:m1:v"), ids(resolver.resolve(movieMedia())))
    }

    @Test
    fun nothingFoundWhileAServerFailedIsAnIncompleteLookupNotAnAbsence() = runTest {
        answer = { lookup(emptyList(), succeeded = setOf("nas"), failed = setOf("down", "slow")) }
        val error = assertFailsWith<LibraryLookupIncomplete> { resolver.resolve(movieMedia()) }
        assertEquals(setOf("down", "slow").ids(), error.failedServerIds)
    }

    @Test
    fun theShortcutCopyIsEnoughThoughTheSearchFailedEverywhere() = runTest {
        server("home", mapOf("m1" to movie("m1", "home", durationMs = 7_020_000)))
        answer = { lookup(emptyList(), failed = setOf("nas")) }
        assertEquals(listOf("home:m1:"), ids(resolver.resolve(movieMedia(server = "home", item = "m1"))))
    }

    @Test
    fun nothingFoundAnywhereIsNoCandidates() = runTest {
        answer = { lookup(emptyList(), succeeded = setOf("nas"), cancelled = setOf("torn")) }
        assertEquals(emptyList(), resolver.resolve(movieMedia()))
    }

    @Test
    fun cancellingDuringTheSearchCancelsIt() = runTest {
        var searchCancelled = false
        answer = {
            try {
                awaitCancellation()
            } finally {
                searchCancelled = true
            }
        }
        val resolving = async { resolver.resolve(movieMedia()) }
        runCurrent()
        resolving.cancel()
        runCurrent()
        assertTrue(searchCancelled)
        assertTrue(resolving.isCancelled)
    }

    @Test
    fun cancellingWhileTheSharedItemLoadsSearchesNoFurther() = runTest {
        val gate = CompletableDeferred<Unit>()
        FakeMediaBackend("home").apply { items = { gate.await(); movie("m1", "home", durationMs = 7_020_000) } }.also { servers["home"] = it }

        val resolving = async { resolver.resolve(movieMedia(server = "home", item = "m1")) }
        runCurrent()
        resolving.cancel()
        gate.complete(Unit)
        runCurrent()

        assertTrue(resolving.isCancelled)
        assertEquals(emptyList(), queries)
    }

    @Test
    fun aMovieIsSearchedByItsTitleYearIdsAndPlexGuid() {
        val query = titleQueryFor(movieMedia(ids = mapOf("imdb" to "tt0078748", "tmdb" to "348", "plex" to "plex://movie/5d776826")))!!
        assertEquals(ItemKind.MOVIE, query.kind)
        assertEquals("Alien" to 1979, query.title to query.year)
        assertEquals(ExternalIds(imdb = "tt0078748", tmdb = 348), query.ids)
        assertEquals("plex://movie/5d776826", query.plexGuid)
    }

    @Test
    fun anEpisodeIsSearchedByItsShowAndNumbers() {
        val query = titleQueryFor(Media(
            kind = MediaKind.EPISODE, title = "Half Loop", ids = mapOf("tvdb" to "8247063"),
            series = Series(title = "Severance", year = 2022, ids = mapOf("tvdb" to "371980", "plex" to "plex://show/5d9c086c")),
            season = 1, episode = 2, durationMs = 3_300_000,
        ))!!
        assertEquals(ItemKind.EPISODE, query.kind)
        assertEquals(listOf<Any?>("Severance", 2022, 1, 2), listOf(query.showTitle, query.showYear, query.season, query.episode))
        assertEquals(ExternalIds(tvdb = 371_980), query.showIds)
        assertEquals("plex://show/5d9c086c", query.showPlexGuid)
        assertEquals(ExternalIds(tvdb = 8_247_063), query.ids)
        assertEquals("Half Loop", query.title)
    }

    @Test
    fun anEpisodeWithoutItsNumbersAndAVideoAreNotSearched() = runTest {
        val unnumbered = Media(kind = MediaKind.EPISODE, title = "Pilot", series = Series(title = "Severance"), season = 1, durationMs = 1)
        assertNull(titleQueryFor(unnumbered))
        assertNull(titleQueryFor(Media(kind = MediaKind.VIDEO, title = "Clip", durationMs = 1)))

        assertEquals(emptyList(), resolver.resolve(unnumbered))
        assertEquals(emptyList(), queries)
    }

    @Test
    fun malformedIdsFromAnotherParticipantAreNotSearchTerms() {
        val query = titleQueryFor(movieMedia(ids = mapOf(
            "imdb" to "tt0078748 OR 1=1", "tmdb" to "348abc", "tvdb" to "-5", "anidb" to "1234567890123",
            "plex" to "plex://movie/../../library/sections", "mal" to "42",
        )))!!
        assertFalse(query.ids.hasAny)
        assertNull(query.plexGuid)

        assertEquals(ExternalIds(imdb = "tt0078748", anidb = 42), externalIdsOf(mapOf("imdb" to "tt0078748", "anidb" to "42")))
        assertFalse(externalIdsOf(mapOf("imdb" to "TT0078748", "tmdb" to " 348", "tvdb" to "١٢٣")).hasAny)
    }
}
