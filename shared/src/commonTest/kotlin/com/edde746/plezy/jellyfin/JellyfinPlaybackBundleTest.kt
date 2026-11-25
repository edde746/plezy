package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaBrowserDialect
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.jsonPrimitive

/** The playback bundle: one item detail fetch → chosen source, versions, chapters, trickplay. */
class JellyfinPlaybackBundleTest {
    private fun fixture(body: String, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN) = PlaybackFixture(dialect).apply {
        server.handler = { req -> if (req.path.startsWith("/Users/user-1/Items/")) ok(body) else FakeResponse(404) }
    }

    private val twoSources =
        """{"Id":"item-2","Type":"Movie","MediaSources":[
           {"Id":"src-A","Container":"mkv","MediaStreams":[{"Type":"Video","Codec":"h264","Height":720,"Width":1280}]},
           {"Id":"src-B","Container":"mp4","MediaStreams":[{"Type":"Video","Codec":"hevc","Height":1080,"Width":1920}]}]}"""

    @Test fun nullWithoutMediaSources() = runTest {
        assertNull(fixture("""{"Id":"item-1","Type":"Movie"}""").playback.fetchPlaybackBundle("item-1"))
        assertNull(fixture("""{"Id":"item-1","Type":"Movie","MediaSources":[]}""").playback.fetchPlaybackBundle("item-1"))
    }

    @Test fun singleSourceCarriesChaptersContainerAndSourceId() = runTest {
        val bundle = fixture(
            """{"Id":"item-1","Name":"Example","Type":"Movie","MediaSources":[{"Id":"src-1","Container":"mkv","Bitrate":5000000,"MediaStreams":[
                 {"Type":"Video","Codec":"h264","Width":1920,"Height":1080},{"Type":"Audio","Codec":"eac3","Language":"eng","IsDefault":true}]}],
               "Chapters":[{"Name":"Cold Open","StartPositionTicks":0},{"Name":"Act 1","StartPositionTicks":6000000000}]}""",
        ).playback.fetchPlaybackBundle("item-1")
        assertNotNull(bundle)
        assertEquals(1, bundle.availableVersions.size)
        assertEquals("mkv", bundle.container)
        assertEquals("src-1", bundle.selectedSourceId)
        assertEquals("src-1", bundle.selectedSource["Id"]!!.jsonPrimitive.content)
        assertEquals(2, bundle.chapters.size)
    }

    @Test fun outOfRangeIndexFallsBackToTheFirstSource() = runTest {
        val playback = fixture(twoSources).playback
        assertEquals("src-A", playback.fetchPlaybackBundle("item-2", sourceIndex = -3)!!.selectedSourceId)
        assertEquals("src-A", playback.fetchPlaybackBundle("item-2", sourceIndex = 7)!!.selectedSourceId)
        val mid = playback.fetchPlaybackBundle("item-2", sourceIndex = 1)!!
        assertEquals("src-B", mid.selectedSourceId)
        assertEquals("mp4", mid.container)
        assertEquals(1, mid.selectedSourceIndex)
    }

    @Test fun sourceIdWinsOverIndex() = runTest {
        val bundle = fixture(
            """{"Id":"item-4","Type":"Movie","MediaSources":[
               {"Id":"src-4k","Container":"mkv","MediaStreams":[{"Type":"Video","Codec":"hevc","Height":1608,"Width":3840}]},
               {"Id":"src-1080","Container":"mp4","MediaStreams":[{"Type":"Video","Codec":"h264","Height":804,"Width":1920}]}]}""",
        ).playback.fetchPlaybackBundle("item-4", sourceIndex = 0, sourceId = "src-1080")!!
        assertEquals("src-1080", bundle.selectedSourceId)
        assertEquals("mp4", bundle.container)
        assertEquals(listOf("src-4k", "src-1080"), bundle.availableVersions.map { it.id })
    }

    @Test fun savedSignatureSelectsWhenNoSourceIdPinsOne() = runTest {
        val playback = fixture(
            """{"Id":"item-5","Type":"Movie","MediaSources":[
               {"Id":"src-1080","Container":"mp4","MediaStreams":[{"Type":"Video","Codec":"h264","Height":1080,"Width":1920}]},
               {"Id":"src-4k","Container":"mkv","MediaStreams":[{"Type":"Video","Codec":"hevc","Height":2160,"Width":3840}]}]}""",
        ).playback
        val signature = playback.fetchPlaybackBundle("item-5")!!.availableVersions[1].signature
        val bundle = playback.fetchPlaybackBundle("item-5", sourceIndex = 0, preferredSignature = signature)!!
        assertEquals("src-4k", bundle.selectedSourceId)
        assertEquals(1, bundle.selectedSourceIndex)
        assertEquals("src-1080", playback.fetchPlaybackBundle("item-5", sourceIndex = 0, sourceId = "src-1080", preferredSignature = signature)!!.selectedSourceId)
    }

    @Test fun chaptersDefaultToEmpty() = runTest {
        val bundle = fixture("""{"Id":"item-3","Type":"Movie","MediaSources":[{"Id":"src","Container":"mkv","MediaStreams":[{"Type":"Video","Codec":"h264"}]}]}""")
            .playback.fetchPlaybackBundle("item-3")!!
        assertTrue(bundle.chapters.isEmpty())
    }

    @Test fun pinnedSourceIdIsNeverInvented() = runTest {
        val idless = fixture("""{"Id":"item-6","Type":"Movie","MediaSources":[{"Container":"mkv"}]}""").playback.fetchPlaybackBundle("item-6")!!
        assertNull(idless.pinnedSourceId)
        assertEquals("0", idless.availableVersions.single().id)
        val blank = fixture("""{"Id":"item-6","Type":"Movie","MediaSources":[{"Id":"  ","Container":"mkv"}]}""").playback.fetchPlaybackBundle("item-6")!!
        assertNull(blank.pinnedSourceId)
    }

    @Test fun playbackLookupsRideTheFreshCachedRow() = runTest {
        // Playback start re-requests what the detail screen fetched seconds earlier.
        val f = fixture("""{"Id":"item-fresh","Type":"Movie","MediaSources":[{"Id":"src-network","Container":"mp4"}]}""")
        f.cached["item-fresh"] = f.mapped("""{"Id":"item-fresh","Type":"Movie","MediaSources":[{"Id":"src-fresh","Container":"mkv"}]}""")
        val bundle = f.playback.fetchPlaybackBundle("item-fresh")!!
        assertEquals("src-fresh", bundle.selectedSourceId)
        assertEquals(listOf("fresh:item-fresh"), f.lookups)
        assertTrue(f.server.requests.isEmpty())
    }

    @Test fun cachedSourceInfoResolvesSavedSourcesWithoutNetwork() = runTest {
        for (dialect in MediaBrowserDialect.entries) {
            val f = fixture("{}", dialect)
            f.server.handler = { error("no network expected") }
            f.cached["preview-item"] = f.mapped(
                """{"Id":"preview-item","Type":"Movie","Name":"Alternate versions","MediaSources":[
                   {"Id":"a","Container":"mkv","MediaStreams":[{"Type":"Video","Index":0,"Codec":"h264","Height":1080,"Width":1920},{"Type":"Audio","Index":1,"Language":"eng","IsDefault":true}]},
                   {"Id":"b","Container":"mkv","MediaStreams":[{"Type":"Video","Index":0,"Codec":"hevc","Height":2160,"Width":3840},{"Type":"Audio","Index":1,"Language":"jpn","IsDefault":true}]}]}""",
            )
            val saved = f.playback.fetchCachedMediaSourceInfo("preview-item", mediaSourceId = "b", preferredVersionSignature = "1080:h264:mkv")!!
            assertEquals("jpn", saved.audioTracks.single().languageCode, dialect.name)
            assertEquals(1, saved.mediaIndex)
            assertEquals("b", saved.mediaSourceId)
            // Another episode's source id falls through to the signature.
            val sibling = f.playback.fetchCachedMediaSourceInfo("preview-item", mediaSourceId = "other-episode", preferredVersionSignature = "4k:hevc:mkv")!!
            assertEquals("jpn", sibling.audioTracks.single().languageCode)
            val missing = f.playback.fetchCachedMediaSourceInfo("preview-item", mediaIndex = 99, mediaSourceId = "removed")!!
            assertEquals("eng", missing.audioTracks.single().languageCode)
            assertNull(f.playback.fetchCachedMediaSourceInfo("not-cached"))
            assertTrue(f.server.requests.isEmpty())
        }
    }
}
