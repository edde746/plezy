package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.InMemoryApiCacheStore
import com.edde746.plezy.model.BackendKind
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class CachedPlaybackMetadataTest {
    private val store = InMemoryApiCacheStore()
    private val metadata = cachedMetadata(store)

    private suspend fun put(scope: String, endpoint: String, json: String) = store.put(scope, endpoint, Json.parseToJsonElement(json).jsonObject)

    @Test
    fun cacheOnlyPlaybackExtrasFillMissingPlexMarkerTypesFromChapters() = runTest {
        put("srv-1", "/library/metadata/movie-1", plexMetadataEnvelope())

        val extras = metadata.playbackExtras(BackendKind.PLEX, "srv-1", "movie-1")

        assertEquals(listOf("Intro", "Part A"), extras?.chapters?.map { it.title })
        assertEquals(listOf("intro", "credits"), extras?.markers?.map { it.type })
    }

    @Test
    fun plexExtrasSkipMalformedEntriesAndKeepValidOnes() = runTest {
        put("srv-1", "/library/metadata/movie-1", plexMetadataEnvelope(malformedExtras = true))

        val extras = metadata.playbackExtras(BackendKind.PLEX, "srv-1", "movie-1")

        assertEquals(listOf("Intro", "Part A"), extras?.chapters?.map { it.title })
        assertEquals(listOf("intro", "credits"), extras?.markers?.map { it.type })
    }

    @Test
    fun cacheOnlyJellyfinPlaybackExtrasUseChapterFallbackPatterns() = runTest {
        put(
            "srv-1/user-1",
            "/Users/user-1/Items/item-1",
            """
            {"Id":"item-1","Type":"Episode","Name":"Episode","RunTimeTicks":1200000000,"Chapters":[
            {"Name":"OP","StartPositionTicks":100000000},{"Name":"Episode","StartPositionTicks":450000000},
            {"Name":"ED","StartPositionTicks":900000000}]}
            """,
        )

        val extras = metadata.playbackExtras(BackendKind.JELLYFIN, "srv-1/user-1", "item-1")

        assertEquals(listOf("intro", "credits"), extras?.markers?.map { it.type })
        assertEquals(120000, extras?.markers?.last()?.endTimeOffset)
    }

    @Test
    fun cacheOnlyJellyfinPlaybackExtrasUseCachedNativeMediaSegments() = runTest {
        put("srv-1/user-1", "/Users/user-1/Items/item-1", """{"Id":"item-1","Type":"Episode","Name":"Episode","Chapters":[]}""")
        put(
            "srv-1/user-1",
            "/MediaSegments/item-1",
            """{"Items":[{"Type":"Intro","StartTicks":50000000,"EndTicks":450000000},{"Type":"Outro","StartTicks":900000000,"EndTicks":1000000000}]}""",
        )

        val extras = metadata.playbackExtras(BackendKind.JELLYFIN, "srv-1/user-1", "item-1")

        assertEquals(listOf("intro", "credits"), extras?.markers?.map { it.type })
        assertEquals(5000, extras?.markers?.first()?.startTimeOffset)
        assertEquals(100000, extras?.markers?.last()?.endTimeOffset)
    }

    @Test
    fun aMissingRowReadsAsNull() = runTest {
        assertNull(metadata.mediaSourceInfo(BackendKind.PLEX, "srv-1", "movie-1"))
        assertNull(metadata.mediaSourceInfo(BackendKind.JELLYFIN, "srv-1", "item-1"))
        assertNull(metadata.playbackExtras(BackendKind.EMBY, "srv-1", "item-1"))
    }

    @Test
    fun anOutOfRangeJellyfinVersionReadsTheFirstSource() = runTest {
        put("jf/user-a", "/Users/user-a/Items/item-1", JELLYFIN_ITEM)

        val info = metadata.mediaSourceInfo(BackendKind.JELLYFIN, "jf/user-a", "item-1", mediaIndex = 4)

        assertEquals("src-1", info?.mediaSourceId)
        assertEquals(0, info?.mediaIndex)
    }

    @Test
    fun aCachedPlexVersionIsTakenAsStoredEvenWhenTheServerMarkedItUnplayable() = runTest {
        // The file is already on disk: a stale accessibility flag must not swap in another version's tracks.
        put(
            "srv-1",
            "/library/metadata/movie-1",
            """
            {"MediaContainer":{"Metadata":[{"ratingKey":"movie-1","type":"movie","Media":[
            {"id":1,"Part":[{"id":11,"accessible":false,"exists":false,"Stream":[{"id":10,"streamType":2,"languageCode":"eng"}]}]},
            {"id":2,"Part":[{"id":21,"Stream":[{"id":20,"streamType":2,"languageCode":"fre"}]}]}]}]}}
            """,
        )

        val info = metadata.mediaSourceInfo(BackendKind.PLEX, "srv-1", "movie-1", mediaIndex = 0)

        assertEquals("eng", info?.audioTracks?.single()?.languageCode)
    }
}
