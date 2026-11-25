package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogAvailability
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogNextEpisode
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.CatalogRequestState
import com.edde746.plezy.catalog.CatalogServerState
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.BadgeIcon
import com.edde746.plezy.presentation.browse.BadgeShortForm
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.time.Duration.Companion.days
import kotlin.time.Instant

class CatalogCardTextTest {
    @Test
    fun `badges keep priority order and stop at the limit`() {
        val show = CatalogItem(
            CatalogSourceId.TRAKT,
            MediaKind.SHOW,
            "Show",
            CatalogItemIds(tmdb = 2),
            recommendationCount = 4,
            isAdult = true,
            episodeCount = 10,
            runtimeMinutes = 45,
        )

        val badges = catalogBadges(show, NOW)

        assertEquals(CATALOG_BADGE_LIMIT, badges.size)
        assertEquals(listOf(T.explore.detail.recommendedByUsers(4), T.explore.badge.adult), badges.take(2))
        assertEquals(
            listOf(T.explore.badge.episodesShort("10"), T.explore.badge.minutesPerEpisode("45")).joinToString(" • "),
            badges[2],
        )
    }

    @Test
    fun `next episode badge shows only while the episode is ahead and episode counts only for shows`() {
        val past = CatalogItem(
            CatalogSourceId.TRAKT,
            MediaKind.MOVIE,
            "Movie",
            CatalogItemIds(tmdb = 3),
            nextEpisode = CatalogNextEpisode(NOW - 1.days),
            episodeCount = 10,
            runtimeMinutes = 45,
        )
        assertEquals(emptyList(), catalogBadges(past, NOW))

        val upcoming = past.copy(nextEpisode = CatalogNextEpisode(NOW + 2.days))
        assertEquals(1, catalogBadges(upcoming, NOW).size)
    }

    @Test
    fun `status badges carry their short forms`() {
        val show = CatalogItem(CatalogSourceId.TRAKT, MediaKind.SHOW, "Show", CatalogItemIds(tmdb = 4))
        fun forms(state: CatalogServerState) = catalogBadgeShortForms(show.copy(serverState = state))

        assertEquals(
            mapOf(
                T.explore.badge.available to BadgeShortForm(BadgeIcon.AVAILABLE),
                T.explore.badge.pendingApproval to BadgeShortForm(BadgeIcon.REQUESTED),
            ),
            forms(CatalogServerState(CatalogAvailability.AVAILABLE, request = CatalogRequestState.PENDING)),
        )
        assertEquals(
            mapOf(T.explore.badge.seasonsAvailable("2", "3") to BadgeShortForm(text = "2/3")),
            forms(CatalogServerState(CatalogAvailability.PARTIALLY_AVAILABLE, availableSeasons = 2, totalSeasons = 3)),
        )
        assertEquals(
            mapOf(T.explore.badge.partiallyAvailable to BadgeShortForm(BadgeIcon.PARTIAL)),
            forms(CatalogServerState(CatalogAvailability.PARTIALLY_AVAILABLE)),
        )
        assertEquals(
            mapOf(
                T.explore.badge.availableIn4k to BadgeShortForm(text = "4K"),
                T.explore.badge.declined to BadgeShortForm(BadgeIcon.DECLINED),
            ),
            forms(CatalogServerState(availability4k = CatalogAvailability.AVAILABLE, request = CatalogRequestState.DECLINED)),
        )
    }

    @Test
    fun `unwatched badge caps at 999 plus and hides at zero`() {
        assertNull(MediaCardUi.unwatchedLabel(0))
        assertEquals("999", MediaCardUi.unwatchedLabel(999))
        assertEquals("999+", MediaCardUi.unwatchedLabel(1000))
    }

    private companion object {
        val NOW = Instant.parse("2026-01-01T00:00:00Z")
    }
}
