package com.edde746.plezy.catalog.matching

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

private val TTL = CatalogLibraryMatcher.NEGATIVE_TTL

private fun movie(title: String, ids: CatalogItemIds, source: CatalogSourceId = CatalogSourceId.TRAKT) =
    CatalogItem(source = source, kind = MediaKind.MOVIE, title = title, ids = ids)

/**
 * A Jellyfin server searching each title candidate for [rows] (id to TMDB id, per stored title) and returning only the
 * hits whose TMDB id matches: the title alone never matches. [searches] records every title searched.
 */
private class TitleSearchServer(id: String, var rows: (String) -> List<Pair<String, Int>>) : FakeMediaBackend(id, BackendKind.JELLYFIN) {
    val searches = mutableListOf<String>()
    var failOn: String? = null

    init {
        byExternalIds = { ids, kind, titles, _, _, _ ->
            searches += titles
            val failing = failOn
            if (failing != null && failing in titles) {
                throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "Unavailable", statusCode = 403)
            }
            titles.flatMap(rows).filter { (_, tmdb) -> tmdb == ids.tmdb }.map { (itemId, _) -> itemId }.distinct()
                .map { libraryCopy(it, serverId.value, kind, BackendKind.JELLYFIN) }
        }
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
class CatalogLibraryMatcherTest {
    @Test
    fun cancelledAndNonQueryableRetriesRetainCopiesUntilThisServerExecutesAMiss() = runTest {
        val h = LiveHarness(this)
        val copy = libraryCopy("retained", "a")
        val a = LookupServer("a", copies = listOf(copy))
        val b = LookupServer("b", error = IllegalStateException("offline"))
        h.register(a)
        h.register(b)
        val item = movie("Retained Movie", CatalogItemIds(tmdb = 42))
        assertEquals(listOf(copy), h.matcher.match(item).items)

        a.error = MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "aborted")
        b.error = null
        h.clock += TTL
        val cancelled = h.matcher.match(item)
        assertEquals(listOf(copy), cancelled.items)
        assertEquals(ids("a"), cancelled.cancelledServerIds)
        assertTrue(cancelled.failedServerIds.isEmpty())

        a.error = null
        a.copies = null
        h.clock += TTL
        val unqueried = h.matcher.match(item)
        assertEquals(listOf(copy), unqueried.items)
        assertEquals(ids("a"), unqueried.unqueriedServerIds)
        assertEquals(ids("b"), unqueried.succeededServerIds)
        h.clock += TTL - 1.seconds
        assertSame(unqueried, h.matcher.match(item))

        a.copies = emptyList()
        h.clock += 1.seconds
        val removed = h.matcher.match(item)
        assertTrue(removed.items.isEmpty())
        assertEquals(ids("a", "b"), removed.succeededServerIds)
        assertTrue(removed.unqueriedServerIds.isEmpty())
    }

    @Test
    fun membershipAdditionsRetryPositiveCachesWhileRetainingOfflineCopiesStillInScope() = runTest {
        val h = LiveHarness(this)
        val aCopy = libraryCopy("a-copy", "a")
        val bCopy = libraryCopy("b-copy", "b")
        val a = LookupServer("a", copies = listOf(aCopy))
        val b = LookupServer("b", copies = listOf(bCopy))
        h.register(a)
        h.register(b)
        h.setExpected(ids("a"))
        val item = movie("Membership Movie", CatalogItemIds(tmdb = 42))
        assertEquals(listOf(aCopy), h.matcher.match(item).items)
        assertEquals(0, b.lookups)

        h.register(a, online = false)
        h.setExpected(ids("a", "b"))
        val added = h.matcher.match(item)
        assertEquals(listOf(aCopy, bCopy), added.items)
        assertEquals(ids("a"), added.unqueriedServerIds)
        assertEquals(ids("b"), added.succeededServerIds)

        // Removed and re-added between matches: the change itself drops A's old copy, though the next lookup sees the
        // same final set.
        h.setExpected(ids("b"))
        h.setExpected(ids("a", "b"))
        val readded = h.matcher.match(item)
        assertEquals(listOf(bCopy), readded.items)
        assertEquals(ids("a"), readded.unqueriedServerIds)
        assertEquals(2, b.lookups)

        h.setExpected(ids("b"))
        val removed = h.matcher.match(item)
        assertEquals(listOf(bCopy), removed.items)
        assertTrue(removed.unqueriedServerIds.isEmpty())
        assertEquals(ids("b"), removed.succeededServerIds)
    }

    @Test
    fun aMembershipChangeDuringLookupCannotPublishOrCacheTheDepartedServerResponse() = runTest {
        val h = LiveHarness(this)
        val aCopy = libraryCopy("a-copy", "a")
        val bCopy = libraryCopy("b-copy", "b")
        val a = LookupServer("a").apply { pending = CompletableDeferred() }
        val b = LookupServer("b", copies = listOf(bCopy))
        h.register(a)
        h.register(b)
        h.setExpected(ids("a"))
        val item = movie("In-flight Movie", CatalogItemIds(tmdb = 42))

        val pending = async { h.matcher.match(item) }
        runCurrent()
        h.setExpected(ids("b"))
        a.pending!!.complete(listOf(aCopy))
        val result = pending.await()
        assertEquals(listOf(bCopy), result.items)
        assertEquals(ids("b"), result.succeededServerIds)
        assertTrue(result.unqueriedServerIds.isEmpty())
        assertEquals(listOf(bCopy), h.matcher.match(item).items)
    }

    @Test
    fun aWeakerCachedHitCannotSuppressFailedRicherQueryRetriesOrRecovery() = runTest {
        val clock = TestTimeSource()
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup, clock)
        val bareCopy = libraryCopy("bare-copy", "a")
        val nativeCopy = libraryCopy("native-copy", "a")
        lookup.responses += listOf(
            wave(listOf(bareCopy), succeeded = ids("a")),
            wave(emptyList(), failed = ids("a")),
            wave(listOf(bareCopy, nativeCopy), succeeded = ids("a")),
        )
        val bare = movie("Night on the Galactic Railroad", CatalogItemIds(plex = "5d776b59ad5437001f79c6f8"), CatalogSourceId.PLEX)
        val enriched = bare.copy(originalTitle = "銀河鉄道の夜", ids = CatalogItemIds(plex = "5d776b59ad5437001f79c6f8", tmdb = 34523))

        assertEquals(listOf(bareCopy), matcher.match(bare).items)
        val failed = matcher.match(enriched)
        assertEquals(ids("a"), failed.failedServerIds)
        assertTrue(failed.succeededServerIds.isEmpty())
        assertEquals(listOf(bareCopy), matcher.match(bare).items)
        clock += TTL - 1.seconds
        assertSame(failed, matcher.match(enriched))
        clock += 1.seconds
        val recovered = matcher.match(enriched)
        assertEquals(listOf(bareCopy, nativeCopy), recovered.items)
        assertEquals(ids("a"), recovered.succeededServerIds)
        assertTrue(recovered.failedServerIds.isEmpty())
    }

    @Test
    fun seasonEntriesSharingCanonicalIdsKeepIndependentCachedMatches() = runTest {
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup)
        val firstHit = libraryCopy("server-season-1", kind = MediaKind.SHOW)
        val secondHit = libraryCopy("server-season-2", kind = MediaKind.SHOW)
        lookup.responses += listOf(wave(listOf(firstHit)), wave(listOf(secondHit)))
        val first = CatalogItem(CatalogSourceId.MAL, MediaKind.SHOW, "Mushoku Tensei", CatalogItemIds(mal = 39535, imdb = "tt13293588"))
        val second = CatalogItem(CatalogSourceId.MAL, MediaKind.SHOW, "Mushoku Tensei II", CatalogItemIds(mal = 51179, imdb = "tt13293588"))

        assertEquals(first.identityKey, second.identityKey)
        assertNotEquals(first.entryIdentityKey, second.entryIdentityKey)
        assertSame(firstHit, matcher.match(first).items.single())
        assertSame(secondHit, matcher.match(second).items.single())
        assertSame(firstHit, matcher.match(first).items.single())
        assertEquals(2, lookup.calls.size)
    }

    @Test
    fun negativeCacheEntriesAreIsolatedByCatalogSource() = runTest {
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup)
        val anilistHit = libraryCopy("japanese-title-match", kind = MediaKind.SHOW)
        lookup.responses += listOf(wave(emptyList()), wave(listOf(anilistHit)))
        val malItem = CatalogItem(CatalogSourceId.MAL, MediaKind.SHOW, "English Title", CatalogItemIds(mal = 100, tmdb = 200))
        val anilistItem = CatalogItem(
            CatalogSourceId.ANILIST,
            MediaKind.SHOW,
            "English Title",
            CatalogItemIds(mal = 100, anilist = 300, tmdb = 200),
            originalTitle = "日本語タイトル",
        )

        assertEquals(malItem.entryIdentityKey, anilistItem.entryIdentityKey)
        assertTrue(matcher.match(malItem).items.isEmpty())
        assertSame(anilistHit, matcher.match(anilistItem).items.single())
        assertEquals(2, lookup.calls.size)
        assertTrue("日本語タイトル" in lookup.calls.last().titles)
    }

    @Test
    fun negativeMatchesExpireAfterNegativeTtlWhilePositiveMatchesPersist() = runTest {
        val clock = TestTimeSource()
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup, clock)
        val hit = libraryCopy("new-library-item", kind = MediaKind.SHOW)
        lookup.responses += listOf(wave(emptyList()), wave(listOf(hit)))
        val item = CatalogItem(CatalogSourceId.ANILIST, MediaKind.SHOW, "New Show", CatalogItemIds(anilist = 1, tmdb = 42))

        assertTrue(matcher.match(item).items.isEmpty())
        clock += TTL - 1.seconds
        assertTrue(matcher.match(item).items.isEmpty())
        assertEquals(1, lookup.calls.size)

        clock += 1.seconds
        assertSame(hit, matcher.match(item).items.single())
        assertEquals(2, lookup.calls.size)

        clock += 30.days
        assertSame(hit, matcher.match(item).items.single())
        assertEquals(2, lookup.calls.size)
    }

    @Test
    fun aWaveAServerSatOutIsRetriedAfterNegativeTtlEvenWhenItFoundCopies() = runTest {
        // A slow server timing out is no evidence the title is absent there: the degraded answer is shown with the
        // failed server named, but not kept for the session like a complete hit.
        val clock = TestTimeSource()
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup, clock)
        val fastCopy = libraryCopy("fast-copy", "fast")
        val slowCopy = libraryCopy("slow-copy", "slow")
        lookup.responses += listOf(
            wave(listOf(fastCopy), succeeded = ids("fast"), failed = ids("slow")),
            wave(listOf(fastCopy, slowCopy), succeeded = ids("fast", "slow")),
        )
        val item = movie("Slow Server Movie", CatalogItemIds(trakt = 9, tmdb = 77))

        val degraded = matcher.match(item)
        assertEquals(listOf(fastCopy), degraded.items)
        assertEquals(ids("slow"), degraded.failedServerIds)
        clock += TTL - 1.seconds
        assertSame(degraded, matcher.match(item))
        assertEquals(1, lookup.calls.size)

        clock += 1.seconds
        assertEquals(listOf(fastCopy, slowCopy), matcher.match(item).items)
        assertEquals(2, lookup.calls.size)
        clock += 30.days
        assertEquals(listOf(fastCopy, slowCopy), matcher.match(item).items)
        assertEquals(2, lookup.calls.size, "every server answered, so the hit is kept")
    }

    @Test
    fun aServerThatSitsOutTheRetryKeepsItsLastKnownCopiesUntilItAnswersItself() = runTest {
        // Wave 1: A holds a copy, B is unreachable. Wave 2: A is unreachable, B answers empty. Nothing says A removed
        // its copy, so it stays; only A's own answer may replace it.
        val clock = TestTimeSource()
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup, clock)
        val aCopy = libraryCopy("a-copy", "a")
        lookup.responses += listOf(
            wave(listOf(aCopy), succeeded = ids("a"), failed = ids("b")),
            wave(emptyList(), succeeded = ids("b"), failed = ids("a")),
            wave(emptyList(), succeeded = ids("a", "b")),
        )
        val item = movie("Flaky Servers Movie", CatalogItemIds(trakt = 10, tmdb = 78))

        assertEquals(listOf(aCopy), matcher.match(item).items)
        clock += TTL
        val retained = matcher.match(item)
        assertEquals(listOf(aCopy), retained.items)
        assertEquals(ids("a"), retained.failedServerIds)
        assertEquals(ids("b"), retained.succeededServerIds)
        assertEquals(2, lookup.calls.size)

        // A answering empty for itself is the evidence that the copy is gone.
        clock += TTL
        assertTrue(matcher.match(item).items.isEmpty())
        assertEquals(3, lookup.calls.size)
    }

    @Test
    fun aRegisteredServerThatIsOfflineForTheRetryKeepsItsCopiesAndStaysRetryable() = runTest {
        // An offline server is not in the fan-out: it never said the title was gone, and the surviving wave is not a
        // complete answer for the session either.
        val h = LiveHarness(this)
        val aCopy = libraryCopy("a-copy", "a")
        val bCopy = libraryCopy("b-copy", "b")
        val a = LookupServer("a", copies = listOf(aCopy))
        val b = LookupServer("b", error = IllegalStateException("unreachable"))
        h.register(a)
        h.register(b)
        val item = movie("Offline Server Movie", CatalogItemIds(trakt = 11, tmdb = 79))

        assertEquals(listOf(aCopy), h.matcher.match(item).items)

        h.register(a, online = false)
        b.error = null
        b.copies = listOf(bCopy)
        h.clock += TTL
        assertEquals(listOf(aCopy, bCopy), h.matcher.match(item).items, "A was never asked, so its verified copy stands")
        assertEquals(1, a.lookups)

        // Only A's own answer may drop A's copy, so the wave stays retryable.
        h.register(a)
        a.copies = emptyList()
        h.clock += TTL
        assertEquals(listOf(bCopy), h.matcher.match(item).items)
        assertEquals(2, a.lookups)
    }

    @Test
    fun aWaveWithNoOnlineServerKeepsKnownCopiesAndIsNotAnAuthoritativeAbsence() = runTest {
        val h = LiveHarness(this)
        val aCopy = libraryCopy("a-copy", "a")
        val a = LookupServer("a", copies = listOf(aCopy))
        val b = LookupServer("b", error = IllegalStateException("unreachable"))
        h.register(a)
        h.register(b)
        val item = movie("All Servers Offline Movie", CatalogItemIds(trakt = 12, tmdb = 80))

        assertEquals(listOf(aCopy), h.matcher.match(item).items)

        h.register(a, online = false)
        h.register(b, online = false)
        h.clock += TTL
        val blind = h.matcher.match(item)
        assertEquals(listOf(aCopy), blind.items, "a wave nobody answered erases nothing")
        assertTrue(blind.succeededServerIds.isEmpty())

        h.register(a)
        h.clock += TTL
        assertEquals(listOf(aCopy), h.matcher.match(item).items)
        assertEquals(2, a.lookups, "the blind wave is no hit, so the next match asks again")
    }

    @Test
    fun aServerThatLeftTheAccountLosesItsCopies() = runTest {
        // The one wave shape that means removal: the server is in no outcome set at all.
        val clock = TestTimeSource()
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup, clock)
        val aCopy = libraryCopy("a-copy", "a")
        val bCopy = libraryCopy("b-copy", "b")
        lookup.responses += listOf(
            wave(listOf(aCopy), succeeded = ids("a"), failed = ids("b")),
            wave(listOf(bCopy), succeeded = ids("b")),
        )
        val item = movie("Removed Server Movie", CatalogItemIds(trakt = 13, tmdb = 81))

        assertEquals(listOf(aCopy), matcher.match(item).items)
        clock += TTL
        assertEquals(listOf(bCopy), matcher.match(item).items)
    }

    @Test
    fun aRetryThatLostTheLibraryStampKeepsTheLabelFromThePreviousWave() = runTest {
        // Wave 2, the first every server took part in and so kept for the session, returns the copy unstamped (the
        // Jellyfin stamp is a best-effort ancestors call). Nothing says it moved, so the label survives.
        val clock = TestTimeSource()
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup, clock)
        val stamped = libraryCopy("j-copy", "j", libraryId = "lib-1", libraryTitle = "Movies")
        val unstamped = libraryCopy("j-copy", "j")
        lookup.responses += listOf(
            wave(listOf(stamped), succeeded = ids("j"), failed = ids("k")),
            wave(listOf(unstamped), succeeded = ids("j", "k")),
        )
        val item = movie("Unstamped Retry Movie", CatalogItemIds(trakt = 14, tmdb = 82))

        assertEquals(listOf(stamped), matcher.match(item).items)
        clock += TTL
        val retried = matcher.match(item).items.single()
        assertEquals("lib-1", retried.libraryId)
        assertEquals("Movies", retried.libraryTitle)
        clock += 30.days
        assertEquals("Movies", matcher.match(item).items.single().libraryTitle)
        assertEquals(2, lookup.calls.size, "the merged wave is the kept hit")
    }

    @Test
    fun aRetryThatNamesAnotherLibraryTakesItsIdWithoutTheOldLabel() = runTest {
        val clock = TestTimeSource()
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup, clock)
        val stamped = libraryCopy("j-copy", "j", libraryId = "lib-1", libraryTitle = "Movies")
        val moved = libraryCopy("j-copy", "j", libraryId = "lib-2")
        lookup.responses += listOf(
            wave(listOf(stamped), succeeded = ids("j"), failed = ids("k")),
            wave(listOf(moved), succeeded = ids("j", "k")),
        )
        val item = movie("Moved Library Movie", CatalogItemIds(trakt = 15, tmdb = 83))

        assertEquals(listOf(stamped), matcher.match(item).items)
        clock += TTL
        val retried = matcher.match(item).items.single()
        assertEquals("lib-2", retried.libraryId)
        assertNull(retried.libraryTitle)
    }

    @Test
    fun aRetryThatNoLongerReturnsACopyStillDropsIt() = runTest {
        // Enrichment is per copy; which copies a server holds stays that server's answer alone.
        val clock = TestTimeSource()
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup, clock)
        val stamped = libraryCopy("j-copy", "j", libraryId = "lib-1", libraryTitle = "Movies")
        val other = libraryCopy("j-other", "j")
        lookup.responses += listOf(
            wave(listOf(stamped), succeeded = ids("j"), failed = ids("k")),
            wave(listOf(other), succeeded = ids("j", "k")),
        )
        val item = movie("Dropped Copy Movie", CatalogItemIds(trakt = 16, tmdb = 84))

        assertEquals(listOf(stamped), matcher.match(item).items)
        clock += TTL
        assertEquals(listOf(other), matcher.match(item).items)
    }

    @Test
    fun keepsTheYearForAnEntryThatIsNotASequel() = runTest {
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup)
        lookup.responses += wave(emptyList())
        val item = CatalogItem(CatalogSourceId.TRAKT, MediaKind.SHOW, "Severance", CatalogItemIds(trakt = 1, tvdb = 371980), year = 2022)

        matcher.match(item)

        val call = lookup.calls.single()
        assertEquals(2022, call.year)
        assertEquals(listOf("Severance"), call.titles, "nothing to strip, so one candidate and one search")
    }

    @Test
    fun detailAliasesGainVerifiedCopiesWithoutDroppingRowOnlyAliasesOrReusingAWeakerCache() = runTest {
        val h = LiveHarness(this)
        val server = TitleSearchServer("jellyfin") { title ->
            val id = when (title) {
                "Row Alias" -> "row-copy"
                "君の名は。" -> "native-copy"
                else -> null
            }
            if (id == null) emptyList() else listOf(id to 372058, "wrong-id" to 999)
        }
        h.register(server)
        val row = CatalogItem(
            CatalogSourceId.SIMKL,
            MediaKind.MOVIE,
            "Your Name.",
            CatalogItemIds(simkl = 210, tmdb = 372058),
            altTitles = listOf("Row Alias", "Other Alias", "Overflow Alias"),
            originalTitle = "Kimi no Na wa.",
        )
        val detail = CatalogItem(
            CatalogSourceId.SIMKL,
            MediaKind.MOVIE,
            "Your Name.",
            CatalogItemIds(simkl = 210, tmdb = 372058),
            altTitles = listOf("君の名は。", "君の名は。"),
        )
        val enriched = row.enrichedWith(detail)

        assertEquals(listOf("row-copy"), h.matcher.match(row).items.map { it.id })
        assertTrue(server.searches.size <= 4)
        server.searches.clear()

        // A fifth title family stays best-effort: it can't spend more searches or invalidate the cache when no admitted
        // candidate changed.
        val outsideBudget = row.copy(altTitles = row.altTitles + "君の名は。")
        assertEquals(listOf("row-copy"), h.matcher.match(outsideBudget).items.map { it.id })
        assertTrue(server.searches.isEmpty())

        val richer = h.matcher.match(enriched)
        assertEquals(setOf("row-copy", "native-copy"), richer.items.map { it.id }.toSet())
        assertTrue(richer.failedServerIds.isEmpty())
        assertTrue(server.searches.size <= 4)
        server.searches.clear()
        assertEquals(listOf("row-copy"), h.matcher.match(row).items.map { it.id })
        assertEquals(setOf("row-copy", "native-copy"), h.matcher.match(enriched).items.map { it.id }.toSet())
        assertTrue(server.searches.isEmpty(), "the candidate-sensitive answers stay memoized independently")
    }

    @Test
    fun aFailedAliasQueryRetainsPriorVerifiedCopiesUntilTheServerAnswersACompleteMiss() = runTest {
        val h = LiveHarness(this)
        var hasCopy = true
        val server = TitleSearchServer("jellyfin") { title -> if (title == "君の名は。" && hasCopy) listOf("owned" to 372058) else emptyList() }
        val other = LookupServer("offline", error = IllegalStateException("unavailable"))
        h.register(server)
        h.register(other)
        val item = CatalogItem(
            CatalogSourceId.MAL,
            MediaKind.MOVIE,
            "Kimi no Na wa.",
            CatalogItemIds(mal = 32281, tmdb = 372058),
            altTitles = listOf("君の名は。"),
        )

        assertEquals(listOf("owned"), h.matcher.match(item).items.map { it.id })
        other.error = null
        server.failOn = "君の名は。"
        h.clock += TTL
        val partial = h.matcher.match(item)
        assertEquals(listOf("owned"), partial.items.map { it.id })
        assertEquals(ids("jellyfin"), partial.failedServerIds)
        assertEquals(ids("offline"), partial.succeededServerIds)

        server.failOn = null
        hasCopy = false
        h.clock += TTL
        val absent = h.matcher.match(item)
        assertTrue(absent.items.isEmpty())
        assertTrue(absent.failedServerIds.isEmpty())
        assertEquals(ids("jellyfin", "offline"), absent.succeededServerIds)
    }

    @Test
    fun aDetailLoadThatAddsTheNativeTitleIsNotServedTheBareFormsCachedNegative() = runTest {
        // A Plex Discover row carries no original title; the detail body does, and only that title reaches a library
        // filed under it.
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup)
        val romajiCopy = libraryCopy("romaji-copy", kind = MediaKind.SHOW)
        lookup.responses += listOf(wave(emptyList()), wave(listOf(romajiCopy)))
        val bare = CatalogItem(CatalogSourceId.PLEX, MediaKind.SHOW, "Frieren: Beyond Journey's End", CatalogItemIds(plex = "631cc", tvdb = 424536))
        val enriched = bare.copy(originalTitle = "葬送のフリーレン")

        assertTrue(matcher.match(bare).items.isEmpty())
        assertSame(romajiCopy, matcher.match(enriched).items.single())
        assertEquals(2, lookup.calls.size)
        assertEquals("葬送のフリーレン", lookup.calls.last().titles.first())
    }

    @Test
    fun dropsTheYearFromASequelTitleEvenWhenNoSeasonIsMapped() = runTest {
        // Without a mapped season, a strippable suffix says sequel as reliably; the year window around the sequel's own
        // year would exclude the parent show.
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup)
        lookup.responses += wave(emptyList())
        val item = CatalogItem(CatalogSourceId.ANILIST, MediaKind.SHOW, "Some Show 2nd Season", CatalogItemIds(anilist = 5, tvdb = 1), year = 2026)

        matcher.match(item)

        assertNull(lookup.calls.single().year)
    }

    @Test
    fun constructsAPlexGuidForDiscoverItemsWithoutExternalIds() = runTest {
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup)
        lookup.responses += wave(emptyList())
        val item = movie("Plex-only Movie", CatalogItemIds(plex = "5d776828880197001ec90e13"), CatalogSourceId.PLEX)

        matcher.match(item)

        val call = lookup.calls.single()
        assertFalse(call.ids.hasAny)
        assertEquals("plex://movie/5d776828880197001ec90e13", call.plexGuid)
    }

    @Test
    fun anIdPoorNegativeDoesNotSuppressTheDetailEnrichedRetry() = runTest {
        // A Plex Discover row carries only its rating key, and the exact-guid lookup can miss owned titles (Discover
        // duplicates). The detail body brings external ids moments later; that lookup must reach the servers.
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup)
        val hit = libraryCopy("server-movie")
        lookup.responses += listOf(wave(emptyList()), wave(listOf(hit)))
        val bare = movie("Night on the Galactic Railroad", CatalogItemIds(plex = "5d776b59ad5437001f79c6f8"), CatalogSourceId.PLEX)
        val enriched = bare.copy(ids = CatalogItemIds(plex = "5d776b59ad5437001f79c6f8", imdb = "tt0089445", tmdb = 34523))

        assertEquals(bare.entryIdentityKey, enriched.entryIdentityKey)
        assertTrue(matcher.match(bare).items.isEmpty())
        assertSame(hit, matcher.match(enriched).items.single())
        assertEquals(2, lookup.calls.size)
        assertEquals("tt0089445", lookup.calls.last().ids.imdb)

        // Both forms stay memoized independently.
        assertSame(hit, matcher.match(enriched).items.single())
        assertEquals(2, lookup.calls.size)
    }

    @Test
    fun onlyAPlexDiscoverItemContributesAGuidAndItCostsNoRequest() = runTest {
        // A MAL entry can carry a Plex rating key, but that key is no Discover guid and is never turned into one.
        val lookup = ScriptedLookup()
        val matcher = scriptedMatcher(lookup)
        lookup.responses += listOf(wave(emptyList()), wave(emptyList()))
        val foreign = CatalogItem(CatalogSourceId.MAL, MediaKind.SHOW, "Not A Discover Item", CatalogItemIds(mal = 7, plex = "1234"))
        val discover = CatalogItem(CatalogSourceId.PLEX, MediaKind.SHOW, "Discover Show", CatalogItemIds(plex = "abc123"))

        matcher.match(foreign)
        matcher.match(discover)

        assertEquals(listOf(null, "plex://show/abc123"), lookup.calls.map { it.plexGuid })
    }

    @Test
    fun theLookupAsksTheExpectedServersWithTheItemsIdsKindAndTitles() = runTest {
        val h = LiveHarness(this)
        val seen = mutableListOf<Triple<ExternalIds, MediaKind, List<String>>>()
        val server = FakeMediaBackend("a").apply {
            byExternalIds = { ids, kind, titles, _, _, _ ->
                seen += Triple(ids, kind, titles)
                emptyList<MediaItem>()
            }
        }
        h.register(server)
        val item = CatalogItem(CatalogSourceId.TRAKT, MediaKind.SHOW, "Severance", CatalogItemIds(trakt = 1, imdb = "tt11280740", tvdb = 371980))

        val result = h.matcher.match(item)

        assertEquals(ids("a"), result.succeededServerIds)
        assertEquals(ids("a"), h.matcher.expectedServerIds)
        assertEquals(listOf(Triple(ExternalIds(imdb = "tt11280740", tvdb = 371980), MediaKind.SHOW, listOf("Severance"))), seen)
    }

    @Test
    fun aDetailThatAddsIdFormsOrTitleCandidatesWidensTheLookup() {
        val row = movie("Night on the Galactic Railroad", CatalogItemIds(plex = "5d776b59ad5437001f79c6f8"), CatalogSourceId.PLEX)

        assertFalse(CatalogLibraryMatcher.widensLookup(row, row.copy(overview = "A boy rides a train through the stars.")))
        assertTrue(CatalogLibraryMatcher.widensLookup(row, row.copy(ids = row.ids.copy(tmdb = 34523))))
        assertTrue(CatalogLibraryMatcher.widensLookup(row, row.copy(originalTitle = "銀河鉄道の夜")))
        // A detail without one of the row's aliases asks nothing the row didn't.
        assertFalse(CatalogLibraryMatcher.widensLookup(row.copy(altTitles = listOf("Ginga Tetsudou no Yoru")), row))
    }

    @Test
    fun theUncheckedServersAreTheOnesThatFailedWereCancelledOrWereNotAsked() {
        val result = wave(emptyList(), succeeded = ids("d"), failed = ids("a"), cancelled = ids("b"), unqueried = ids("c"))

        assertEquals(ids("a", "b", "c"), result.uncheckedServerIds)
    }
}
