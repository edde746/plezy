package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertSame

class MediaItemMergeTest {
    private fun item(serverId: String? = null, serverName: String? = null, libraryId: String? = null, libraryTitle: String? = null) = MediaItem(
        id = "item",
        backend = BackendKind.PLEX,
        kind = MediaKind.MOVIE,
        serverId = serverId,
        serverName = serverName,
        libraryId = libraryId,
        libraryTitle = libraryTitle,
    )

    @Test
    fun usesTheAuthoritativeFallbackWhenBothItemsOmitServerIdentity() {
        val merged = mergeFetchedMediaItem(fetched = item(), fallbackServerId = ServerId("fallback"))
        assertEquals("fallback", merged.serverId)
        assertEquals("fallback:item", merged.globalKey)
    }

    @Test
    fun preservesExistingIdentityWhilePreferringFetchedLibraryContext() {
        val merged = mergeFetchedMediaItem(
            fetched = item(serverId = "fetched", serverName = "Fetched", libraryId = "new-lib", libraryTitle = "New"),
            existing = item(serverId = "existing", serverName = "Existing", libraryId = "old-lib", libraryTitle = "Old"),
            fallbackServerId = ServerId("fallback"),
        )
        assertEquals("existing", merged.serverId)
        assertEquals("Existing", merged.serverName)
        assertEquals("new-lib", merged.libraryId)
        assertEquals("New", merged.libraryTitle)
    }

    @Test
    fun fillsMissingFetchedLibraryContextFromTheExistingItem() {
        val merged = mergeFetchedMediaItem(fetched = item(), existing = item(libraryId = "old-lib", libraryTitle = "Old"), fallbackServerId = ServerId("fallback"))
        assertEquals("old-lib", merged.libraryId)
        assertEquals("Old", merged.libraryTitle)
    }

    @Test
    fun aFetchedItemThatMovedLibrariesDoesNotInheritTheOldLabel() {
        val merged = mergeFetchedMediaItem(
            fetched = item(libraryId = "new-lib"),
            existing = item(libraryId = "old-lib", libraryTitle = "Old"),
            fallbackServerId = ServerId("fallback"),
        )
        assertEquals("new-lib", merged.libraryId)
        assertNull(merged.libraryTitle)
    }

    @Test
    fun aFetchedItemNamingTheSameLibraryFillsItsLabelFromTheExistingItem() {
        val merged = mergeFetchedMediaItem(
            fetched = item(libraryId = "old-lib"),
            existing = item(libraryId = "old-lib", libraryTitle = "Old"),
            fallbackServerId = ServerId("fallback"),
        )
        assertEquals("old-lib", merged.libraryId)
        assertEquals("Old", merged.libraryTitle)
    }

    private fun copy(
        id: String,
        libraryId: String? = null,
        libraryTitle: String? = null,
        videoResolution: String? = null,
        mediaVersions: List<MediaVersion>? = null,
    ) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.MOVIE,
        serverId = "server-1",
        serverName = "Living Room",
        libraryId = libraryId ?: if (libraryTitle == null) null else "$id-lib",
        libraryTitle = libraryTitle,
        mediaVersions = mediaVersions ?: videoResolution?.let { listOf(MediaVersion(id = "$id-v", videoResolution = it)) },
    )

    @Test
    fun ordersLibraryCopiesByResolutionBestFirst() {
        val merged = mergeLibraryCopies(
            emptyList(),
            listOf(copy("hd", libraryTitle = "Movies", videoResolution = "1080"), copy("uhd", libraryTitle = "4K Movies", videoResolution = "4k")),
        )
        assertEquals(listOf("uhd", "hd"), merged.map { it.id })
    }

    @Test
    fun keepsCopiesALaterPassDidNotReturn() {
        assertEquals(listOf("hd"), mergeLibraryCopies(listOf(copy("hd", libraryTitle = "Movies")), emptyList()).map { it.id })
    }

    @Test
    fun anUnstampedReResolveDoesNotStripACopyOfItsLibrary() {
        // Jellyfin's library stamp is a best-effort ancestors lookup that returns the item unstamped when it fails.
        val merged = mergeLibraryCopies(listOf(copy("hd", libraryTitle = "Movies", videoResolution = "1080")), listOf(copy("hd"))).single()
        assertEquals("hd-lib", merged.libraryId)
        assertEquals("Movies", merged.libraryTitle)
        assertEquals("Living Room", merged.serverName)
        assertEquals("1080", merged.mediaVersions?.single()?.videoResolution)
    }

    @Test
    fun aReResolveCarryingFresherLibraryContextWins() {
        val merged = mergeLibraryCopies(
            listOf(copy("hd", libraryTitle = "Movies", videoResolution = "1080")),
            listOf(copy("hd", libraryTitle = "Renamed Movies", videoResolution = "4k")),
        ).single()
        assertEquals("Renamed Movies", merged.libraryTitle)
        assertEquals("4k", merged.mediaVersions?.single()?.videoResolution)
    }

    @Test
    fun aReResolveNamingAnotherLibraryTakesItsIdWithoutTheOldLabel() {
        val merged = mergeLibraryCopies(listOf(copy("hd", libraryTitle = "Movies")), listOf(copy("hd", libraryId = "other-lib"))).single()
        assertEquals("other-lib", merged.libraryId)
        assertNull(merged.libraryTitle)
    }

    @Test
    fun anEmptyVersionListIsTreatedAsAbsentNotAsADowngrade() {
        val merged = mergeLibraryCopies(
            listOf(copy("hd", libraryTitle = "Movies", videoResolution = "1080")),
            listOf(copy("hd", libraryTitle = "Movies", mediaVersions = emptyList())),
        ).single()
        assertEquals("1080", merged.mediaVersions?.single()?.videoResolution)
    }

    @Test
    fun aCopyThatInheritsNothingIsReturnedAsIs() {
        val addition = copy("hd", libraryTitle = "Movies", videoResolution = "4k")
        assertSame(addition, mergeLibraryCopy(copy("hd", libraryTitle = "Movies", videoResolution = "1080"), addition))
    }

    @Test
    fun qualityLabelNamesTheTallestVersionAndNothingWithoutAResolution() {
        val twoVersions = copy(
            "hd",
            mediaVersions = listOf(MediaVersion(id = "a", videoResolution = "720"), MediaVersion(id = "b", videoResolution = "1080", videoCodec = "hevc")),
        )
        assertEquals(MediaVersion(id = "b", videoResolution = "1080", videoCodec = "hevc").displayLabel, libraryCopyQualityLabel(twoVersions))
        assertNull(libraryCopyQualityLabel(copy("none", mediaVersions = listOf(MediaVersion(id = "x", videoCodec = "h264")))))
    }
}
