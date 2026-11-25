package com.edde746.plezy.catalog

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class TrailerUrlsTest {
    @Test
    fun aBareYouTubeIdBecomesAWatchUrlAndAnAbsoluteUrlIsKept() {
        assertEquals("https://www.youtube.com/watch?v=dQw4w9WgXcQ", youTubeTrailerUrl(" dQw4w9WgXcQ "))
        assertEquals("https://vimeo.com/123456789", youTubeTrailerUrl("https://vimeo.com/123456789"))
        assertNull(youTubeTrailerUrl(null))
        assertNull(youTubeTrailerUrl("   "))
    }

    @Test
    fun readsTheIdFromEveryYouTubeLinkShapeProvidersSend() {
        for (url in listOf(
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "https://youtube.com/watch?v=dQw4w9WgXcQ&t=42",
            "https://m.youtube.com/watch?feature=share&v=dQw4w9WgXcQ",
            "https://youtu.be/dQw4w9WgXcQ?si=abc",
            "https://www.youtube.com/embed/dQw4w9WgXcQ",
            " https://www.youtube.com/shorts/dQw4w9WgXcQ ",
        )) {
            assertEquals("dQw4w9WgXcQ", youTubeVideoId(url), url)
        }
    }

    @Test
    fun rejectsOtherSitesBareIdsAndMalformedIds() {
        for (url in listOf(
            null,
            "",
            "dQw4w9WgXcQ",
            "https://vimeo.com/123456789",
            "https://notyoutube.com/watch?v=dQw4w9WgXcQ",
            "https://www.youtube.com/watch",
            "https://www.youtube.com/watch?v=too-short",
            "https://www.youtube.com/channel/UC1234567890",
        )) {
            assertNull(youTubeVideoId(url), url)
        }
    }

    @Test
    fun theAppUrlPassesTheIdAsTheWatchQueryUnderTheAppScheme() {
        assertEquals("youtube://www.youtube.com/watch?v=dQw4w9WgXcQ", youTubeAppUrl("https://youtu.be/dQw4w9WgXcQ"))
        assertNull(youTubeAppUrl("https://vimeo.com/123456789"))
    }
}
