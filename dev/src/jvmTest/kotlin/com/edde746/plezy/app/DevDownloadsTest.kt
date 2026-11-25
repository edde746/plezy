package com.edde746.plezy.app

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DevDownloadsTest {
    private val movies = MediaLibrary("1", BackendKind.PLEX, "Movies", MediaKind.MOVIE)
    private val shows = MediaLibrary("2", BackendKind.PLEX, "Shows", MediaKind.SHOW)
    private val collections = mapOf(
        movies to listOf(collection("10", "Heist Films"), collection("11", "Maestro Saga")),
        shows to listOf(collection("20", "Maestro Saga")),
    )
    private val listed = mutableListOf<String>()

    private fun find(title: String) = runBlocking {
        findCollectionTitled(title, listOf(movies, shows)) { library -> listed += library.id; collections.getValue(library) }
    }

    @Test
    fun aCollectionsNameWithUnderscoresForSpacesFindsItAndItsLibrary() {
        val (found, library) = find("maestro_saga")!!
        assertEquals("11", found.id)
        assertEquals(movies, library)
        assertEquals(listOf("1"), listed)
    }

    @Test
    fun aCollectionInALaterLibraryIsFoundAfterTheEarlierOnesAreListed() {
        val libraries = listOf(movies, shows)
        val (found, library) = runBlocking {
            findCollectionTitled("Box_Set", libraries) { if (it.id == "2") listOf(collection("21", "Box Set")) else emptyList() }
        }!!
        assertEquals("21", found.id)
        assertEquals("2", library.id)
    }

    @Test
    fun aNameNoCollectionHasFindsNothing() {
        assertNull(find("Heist"))
        assertEquals(listOf("1", "2"), listed)
    }

    private fun collection(id: String, title: String) = MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.COLLECTION, title = title)
}
