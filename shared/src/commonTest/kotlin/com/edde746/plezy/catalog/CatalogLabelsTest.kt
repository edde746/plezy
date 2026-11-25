package com.edde746.plezy.catalog

import com.edde746.plezy.strings.T
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class CatalogLabelsTest {
    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    @Test
    fun aSeasonalRankKeepsItsWindow() {
        assertEquals("#3 airing", CatalogRank(3, CatalogRankScope.AIRING).label)
        assertEquals("#3 in Fall 2025", CatalogRank(3, CatalogRankScope.POPULAR, allTime = false, year = 2025, season = CatalogSeasonName.FALL).label)
        assertEquals("#3 in Fall", CatalogRank(3, CatalogRankScope.POPULAR, allTime = false, season = CatalogSeasonName.FALL).label)
        assertEquals("#3 in 2025", CatalogRank(3, CatalogRankScope.POPULAR, allTime = false, year = 2025).label)
        assertNull(CatalogRank(3, CatalogRankScope.POPULAR, allTime = false).label, "a window without season or year says nothing")
    }

    @Test
    fun fourKBadgesShowOnlyAvailabilityAndAnActiveRequest() {
        assertEquals("4K available", CatalogAvailability.AVAILABLE.label(is4k = true))
        assertNull(CatalogAvailability.PARTIALLY_AVAILABLE.label(is4k = true))
        assertEquals("Partly available", CatalogAvailability.PARTIALLY_AVAILABLE.label(is4k = false))
        assertNull(CatalogAvailability.UNAVAILABLE.label(is4k = false))

        for (state in listOf(CatalogRequestState.PENDING, CatalogRequestState.APPROVED, CatalogRequestState.PROCESSING)) {
            assertEquals("4K requested", state.label(is4k = true), state.id)
        }
        assertEquals("Declined", CatalogRequestState.DECLINED.label(is4k = true))
        assertEquals("Pending approval", CatalogRequestState.PENDING.label(is4k = false))
        assertEquals("Request failed", CatalogRequestState.FAILED.label(is4k = false))
    }
}
