package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals

class MediaItemSortTest {
    private fun item(
        id: String = "item-1",
        title: String? = null,
        titleSort: String? = null,
        addedAt: Long? = null,
        originallyAvailableAt: String? = null,
        rating: Double? = null,
        libraryTitle: String? = null,
        serverName: String? = null,
    ) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.MOVIE,
        title = title,
        titleSort = titleSort,
        addedAt = addedAt,
        originallyAvailableAt = originallyAvailableAt,
        rating = rating,
        libraryTitle = libraryTitle,
        serverName = serverName,
    )

    private fun sortedIds(items: List<MediaItem>, key: String, descending: Boolean = false, extras: ((MediaItem) -> MediaItemSortExtras)? = null) =
        items.sortedWith(mediaItemSortComparator(key, descending, extras)).map { it.id }

    @Test
    fun titleOrdersCaseInsensitivelyByTitleSortFallingBackToTitle() {
        val items = listOf(item("a", title = "Banana"), item("b", title = "Ignored", titleSort = "apple"), item("c", title = "cherry"))
        assertEquals(listOf("b", "a", "c"), sortedIds(items, MEDIA_SORT_KEY_TITLE))
    }

    @Test
    fun titleDescendingReversesTheOrder() {
        val items = listOf(item("a", title = "Alpha"), item("b", title = "Beta"))
        assertEquals(listOf("b", "a"), sortedIds(items, MEDIA_SORT_KEY_TITLE, descending = true))
    }

    @Test
    fun dateAddedOrdersByAddedAt() {
        val items = listOf(item("new", addedAt = 300), item("old", addedAt = 100), item("mid", addedAt = 200))
        assertEquals(listOf("old", "mid", "new"), sortedIds(items, MEDIA_SORT_KEY_DATE_ADDED))
        assertEquals(listOf("new", "mid", "old"), sortedIds(items, MEDIA_SORT_KEY_DATE_ADDED, descending = true))
    }

    @Test
    fun missingAddedAtSortsLastInBothDirections() {
        val items = listOf(item("none", title = "Zed"), item("dated", addedAt = 100))
        assertEquals(listOf("dated", "none"), sortedIds(items, MEDIA_SORT_KEY_DATE_ADDED))
        assertEquals(listOf("dated", "none"), sortedIds(items, MEDIA_SORT_KEY_DATE_ADDED, descending = true))
    }

    @Test
    fun releaseDateOrdersByOriginallyAvailableAtWithNullsLastBothWays() {
        val items = listOf(
            item("undated", title = "Zed"),
            item("newer", originallyAvailableAt = "2024-01-01"),
            item("older", originallyAvailableAt = "1999-05-20"),
        )
        assertEquals(listOf("older", "newer", "undated"), sortedIds(items, MEDIA_SORT_KEY_RELEASE_DATE))
        assertEquals(listOf("newer", "older", "undated"), sortedIds(items, MEDIA_SORT_KEY_RELEASE_DATE, descending = true))
    }

    @Test
    fun ratingOrdersByRatingWithNullsLastBothWays() {
        val items = listOf(item("unrated", title = "Zed"), item("high", rating = 9.1), item("low", rating = 4.2))
        assertEquals(listOf("low", "high", "unrated"), sortedIds(items, MEDIA_SORT_KEY_RATING))
        assertEquals(listOf("high", "low", "unrated"), sortedIds(items, MEDIA_SORT_KEY_RATING, descending = true))
    }

    @Test
    fun downloadedAtOrdersByExtrasWithMissingExtrasLastBothWays() {
        val items = listOf(item("a", title = "Zed"), item("b"), item("c"))
        val extras = { item: MediaItem ->
            when (item.id) {
                "b" -> MediaItemSortExtras(downloadedAt = 200)
                "c" -> MediaItemSortExtras(downloadedAt = 100)
                else -> MediaItemSortExtras()
            }
        }
        assertEquals(listOf("c", "b", "a"), sortedIds(items, MEDIA_SORT_KEY_DOWNLOADED_AT, extras = extras))
        assertEquals(listOf("b", "c", "a"), sortedIds(items, MEDIA_SORT_KEY_DOWNLOADED_AT, descending = true, extras = extras))
    }

    @Test
    fun withoutAnExtrasLookupEveryItemIsMissingAndFallsBackToTitleOrder() {
        val items = listOf(item("b", title = "Beta"), item("a", title = "Alpha"))
        assertEquals(listOf("a", "b"), sortedIds(items, MEDIA_SORT_KEY_DOWNLOADED_AT))
        // The missing tail reads the same in both directions.
        assertEquals(listOf("a", "b"), sortedIds(items, MEDIA_SORT_KEY_DOWNLOADED_AT, descending = true))
    }

    @Test
    fun sizeOrdersByExtrasTotalBytesWithZeroAndNullMissing() {
        val items = listOf(item("zero", title = "Aaa"), item("none", title = "Zzz"), item("big"), item("small"))
        val extras = { item: MediaItem ->
            when (item.id) {
                "big" -> MediaItemSortExtras(totalBytes = 9000)
                "small" -> MediaItemSortExtras(totalBytes = 100)
                "zero" -> MediaItemSortExtras(totalBytes = 0)
                else -> MediaItemSortExtras()
            }
        }
        assertEquals(listOf("small", "big", "zero", "none"), sortedIds(items, MEDIA_SORT_KEY_SIZE, extras = extras))
        assertEquals(listOf("big", "small", "zero", "none"), sortedIds(items, MEDIA_SORT_KEY_SIZE, descending = true, extras = extras))
    }

    @Test
    fun libraryOrdersByLibraryTitleThenServerNameWithoutOne() {
        val items = listOf(
            item("c", title = "Zed", serverName = "Server B"),
            item("a", libraryTitle = "Movies", serverName = "Server A"),
            item("b", libraryTitle = "Shows", serverName = "Server A"),
        )
        // "server b" < "shows": the server name fallback sorts among real library titles.
        assertEquals(listOf("a", "c", "b"), sortedIds(items, MEDIA_SORT_KEY_LIBRARY))
    }

    @Test
    fun itemsInTheSameLibraryFallBackToTitle() {
        val items = listOf(item("b", title = "Beta", libraryTitle = "Movies"), item("a", title = "Alpha", libraryTitle = "Movies"))
        assertEquals(listOf("a", "b"), sortedIds(items, MEDIA_SORT_KEY_LIBRARY))
    }

    @Test
    fun equalPrimaryValuesOrderByTitleThenId() {
        val items = listOf(item("z", title = "Same", addedAt = 100), item("y", title = "Alpha", addedAt = 100), item("x", title = "Alpha", addedAt = 100))
        assertEquals(listOf("x", "y", "z"), sortedIds(items, MEDIA_SORT_KEY_DATE_ADDED))
    }

    @Test
    fun unknownKeyFallsBackToTitleIdOrder() {
        val items = listOf(item("b", title = "Beta"), item("a", title = "Alpha"))
        assertEquals(listOf("a", "b"), sortedIds(items, "notAKey"))
    }
}
