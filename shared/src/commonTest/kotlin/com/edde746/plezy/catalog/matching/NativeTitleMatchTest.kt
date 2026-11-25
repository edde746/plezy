package com.edde746.plezy.catalog.matching

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaKind
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** A stored copy: its id, TMDB id and the seasons it holds. */
private data class StoredCopy(val id: String, val tmdb: Int, val seasons: Set<Int>)

/**
 * A server of [backend] whose library files [copies] under [storedTitle] with the original title [nativeQuery]: a title
 * search finds them only by [nativeQuery], and only those whose TMDB id (and requested season, by either numbering)
 * match are returned. Every title searched and every year hint is recorded.
 */
private class NativeTitleServer(
    backend: BackendKind,
    nativeQuery: String,
    storedTitle: String,
    copies: List<StoredCopy>,
) : FakeMediaBackend("native-${backend.id}", backend) {
    val searches = mutableListOf<String>()
    val years = mutableListOf<Int?>()

    init {
        byExternalIds = { ids, kind, titles, year, _, season ->
            searches += titles
            years += year
            val seasons = season?.let { listOfNotNull(it.tvdb, it.tmdb) }
            val hits = if (nativeQuery in titles) copies else emptyList()
            hits.filter { copy -> copy.tmdb == ids.tmdb && (seasons == null || seasons.any { it in copy.seasons }) }
                .map { libraryCopy(it.id, serverId.value, kind, backend).copy(title = storedTitle, originalTitle = nativeQuery) }
        }
    }
}

/**
 * Library matching of MyAnimeList entries filed under their native title, on every backend: the lookup's title
 * candidates must reach the native title within the four-search budget, and only the ID-verified copy comes back.
 */
class NativeTitleMatchTest {
    private suspend fun TestScope.expectNativeLibraryMatch(
        backend: BackendKind,
        item: CatalogItem,
        nativeQuery: String,
        storedTitle: String,
        tmdbId: Int,
        availableSeason: Int? = null,
    ) {
        val copies = buildList {
            val seasons = setOfNotNull(availableSeason)
            add(StoredCopy("owned", tmdbId, seasons))
            add(StoredCopy("wrong-id", 999, seasons))
            if (availableSeason != null) add(StoredCopy("no-sequel", tmdbId, emptySet()))
        }
        val server = NativeTitleServer(backend, nativeQuery, storedTitle, copies)
        val h = LiveHarness(this)
        h.register(server)

        val result = h.matcher.match(item)

        assertEquals(listOf("owned"), result.items.map { it.id }, "on $backend")
        assertEquals(backend, result.items.single().backend)
        assertTrue(result.failedServerIds.isEmpty())
        assertEquals(setOf(server.serverId), result.succeededServerIds)
        assertTrue(server.searches.size <= 4, "title searches on $backend: ${server.searches}")
        if (availableSeason != null) assertTrue(server.years.all { it == null }, "a sequel sends no year on $backend")
    }

    @Test
    fun kimiNoNaWaFindsOnlyTheIdVerifiedNativeTitleCopy() = runTest {
        val item = CatalogItem(
            CatalogSourceId.MAL,
            MediaKind.MOVIE,
            "Kimi no Na wa.",
            CatalogItemIds(mal = 32281, tmdb = 372058),
            altTitles = listOf("Kimi no Na wa."),
            originalTitle = "君の名は。",
        )
        for (backend in BackendKind.entries) {
            expectNativeLibraryMatch(backend, item, nativeQuery = "君の名は。", storedTitle = "Your Name.", tmdbId = 372058)
        }
    }

    @Test
    fun threeSequelTitleFamiliesReachTheNativeParentWithinBudget() = runTest {
        val item = CatalogItem(
            CatalogSourceId.MAL,
            MediaKind.SHOW,
            "Attack on Titan Season 3",
            CatalogItemIds(mal = 35760, tmdb = 1429),
            altTitles = listOf("Shingeki no Kyojin Season 3", "AoT 3", "Attack on Titan 3rd Season", "Shingeki no Kyojin 3"),
            season = ExternalSeasonRef(tvdb = 3, tmdb = 3),
            year = 2018,
            originalTitle = "進撃の巨人 Season 3",
        )
        assertTrue("進撃の巨人" in CatalogLibraryMatcher.lookupTitles(item))
        for (backend in BackendKind.entries) {
            expectNativeLibraryMatch(
                backend,
                item,
                nativeQuery = "進撃の巨人",
                storedTitle = "Ataque a los titanes",
                tmdbId = 1429,
                availableSeason = 3,
            )
        }
    }
}
