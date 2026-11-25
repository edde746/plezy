package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Instant

class CatalogCardsTest {
    private val now = Instant.fromEpochSeconds(0)

    @Test
    fun aCatalogCardsCaptionLeadsWithTheScoreThenYearAndRuntimeAlone() {
        val heat = CatalogItem(
            CatalogSourceId.TRAKT,
            MediaKind.MOVIE,
            "Heat",
            CatalogItemIds(tmdb = 949),
            year = 1995,
            runtimeMinutes = 170,
            rating = 8.3,
            votes = 12_300,
            genres = listOf("Crime", "Drama"),
            certification = "R",
            network = "Warner",
        ).toMediaItem().copy(editionTitle = "Director's Cut", studio = "Forward Pass")
        assertEquals("8.3★ • 1995 • 2 h 50 min", heat.toCatalogCard(now, 342, 1280)?.caption)

        val bare = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Bare", CatalogItemIds(tmdb = 1), year = 2001).toMediaItem()
        assertEquals("2001", bare.toCatalogCard(now, 342, 1280)?.caption)
    }
}
