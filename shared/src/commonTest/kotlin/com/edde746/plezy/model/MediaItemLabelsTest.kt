package com.edde746.plezy.model

import com.edde746.plezy.strings.T
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

class MediaItemLabelsTest {
    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    private fun item(
        kind: MediaKind = MediaKind.MOVIE,
        title: String? = null,
        grandparentTitle: String? = null,
        parentTitle: String? = null,
        parentIndex: Int? = null,
        index: Int? = null,
        year: Int? = null,
        editionTitle: String? = null,
    ) = MediaItem(
        id = "item",
        backend = BackendKind.PLEX,
        kind = kind,
        title = title,
        grandparentTitle = grandparentTitle,
        parentTitle = parentTitle,
        parentIndex = parentIndex,
        index = index,
        year = year,
        editionTitle = editionTitle,
    )

    @Test
    fun formatsEpisodesWithShowAndSeasonEpisodeNumbers() {
        assertEquals("Show · S2E3", formatQueueItemSubtitle(item(MediaKind.EPISODE, grandparentTitle = "Show", parentIndex = 2, index = 3)))
    }

    @Test
    fun fallsBackThroughShowYearAndEditionThenMediaKind() {
        assertEquals("Show", formatQueueItemSubtitle(item(grandparentTitle = "Show")))
        assertEquals("2026 · Director Cut", formatQueueItemSubtitle(item(year = 2026, editionTitle = "Director Cut")))
        assertEquals("2026", formatQueueItemSubtitle(item(year = 2026)))
        assertEquals(T.common.mediaKind.movie, formatQueueItemSubtitle(item()))
    }

    @Test
    fun targetLabelNamesTheEpisodeNotJustItsShow() {
        assertEquals(
            "Show · S1 E2 · Pilot",
            formatMediaTargetLabel(item(MediaKind.EPISODE, title = "Pilot", grandparentTitle = "Show", parentIndex = 1, index = 2)),
        )
        assertEquals("Show · Season 1", formatMediaTargetLabel(item(MediaKind.SEASON, title = "Season 1", parentTitle = "Show")))
        assertEquals("Movie", formatMediaTargetLabel(item(title = "Movie")))
    }

    @Test
    fun targetLabelDropsMissingSegmentsAndFallsBackToTheDisplayTitle() {
        assertEquals("Show · Pilot", formatMediaTargetLabel(item(MediaKind.EPISODE, title = "Pilot", grandparentTitle = "Show")))
        assertEquals("", formatMediaTargetLabel(item(MediaKind.EPISODE, title = "")))
    }
}
