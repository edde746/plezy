package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ArtistDiscographyTest {
    private fun album(id: String) = MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.ALBUM, title = id)

    private val kinds = mapOf(
        "ep-1" to DiscographyGroupKind.SINGLES_AND_EPS,
        "live-1" to DiscographyGroupKind.LIVE,
        "comp-1" to DiscographyGroupKind.COMPILATIONS,
    )

    private fun kindOf(item: MediaItem) = kinds[item.id] ?: DiscographyGroupKind.ALBUMS

    private fun ids(group: ArtistDiscographyGroup) = group.items.map { it.id }

    @Test
    fun partitionsAlbumsIntoSectionsInDisplayOrder() {
        val groups = buildArtistDiscographyGroups(listOf(album("lp-1"), album("ep-1"), album("live-1"), album("comp-1"), album("lp-2")), ::kindOf)

        assertEquals(
            listOf(DiscographyGroupKind.ALBUMS, DiscographyGroupKind.SINGLES_AND_EPS, DiscographyGroupKind.LIVE, DiscographyGroupKind.COMPILATIONS),
            groups.map { it.kind },
        )
        assertEquals(listOf("lp-1", "lp-2"), ids(groups[0]))
        assertEquals(listOf("ep-1"), ids(groups[1]))
        assertEquals(listOf("live-1"), ids(groups[2]))
        assertEquals(listOf("comp-1"), ids(groups[3]))
    }

    @Test
    fun preservesAlbumOrderWithinEachSection() {
        val groups = buildArtistDiscographyGroups(listOf(album("lp-3"), album("ep-1"), album("lp-1"), album("lp-2")), ::kindOf)

        assertEquals(listOf("lp-3", "lp-1", "lp-2"), ids(groups[0]))
        assertEquals(listOf("ep-1"), ids(groups[1]))
    }

    @Test
    fun dropsEmptySectionsAndReturnsAnEmptyListForNoAlbums() {
        val groups = buildArtistDiscographyGroups(listOf(album("lp-1"), album("live-1")), ::kindOf)
        assertEquals(listOf(DiscographyGroupKind.ALBUMS, DiscographyGroupKind.LIVE), groups.map { it.kind })

        assertTrue(buildArtistDiscographyGroups(emptyList(), ::kindOf).isEmpty())
    }
}
