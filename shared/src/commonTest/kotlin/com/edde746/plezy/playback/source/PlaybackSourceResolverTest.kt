package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.InMemoryApiCacheStore
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes

class PlaybackSourceResolverTest {
    private val store = InMemoryApiCacheStore()
    private val downloads = FakeDownloads()

    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    private fun resolver(vararg clients: PlaybackClient, configure: FakePlaybackServers.() -> Unit = {}) =
        PlaybackSourceResolver(FakePlaybackServers(*clients).apply(configure), downloads, cachedMetadata(store))

    private fun options(
        item: MediaItem,
        selectedMediaIndex: Int = 0,
        selectedMediaSourceId: String? = null,
        qualityPreset: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
        sessionIdentifier: String? = null,
        startPosition: Duration? = null,
    ) = PlaybackInitializationOptions(
        metadata = item,
        selectedMediaIndex = selectedMediaIndex,
        selectedMediaSourceId = selectedMediaSourceId,
        qualityPreset = qualityPreset,
        sessionIdentifier = sessionIdentifier,
        startPosition = startPosition,
    )

    private suspend fun putPlex(serverId: String, itemId: String, json: String) =
        store.put(serverId, "/library/metadata/$itemId", Json.parseToJsonElement(json).jsonObject)

    // Which client plays, and where reports go.

    @Test
    fun onlinePlaybackUsesTheRegisteredClientEvenWhenItsStatusIsStaleOffline() = runTest {
        val client = PlaybackClient("srv")
        val context = resolver(client) { online.clear() }.resolve(options(testItem("item-1", "srv")), offlineLibraryMode = false)

        assertEquals("https://example.com/video.mp4", context.result.videoUrl)
        assertSame(client, context.reportingClient)
        assertEquals(PlaybackReportingMode.ONLINE, context.reportingMode)
    }

    @Test
    fun anItemsImageIsTheStillItsDownloadSavedOrNone() = runTest {
        downloads.artwork["${ServerId("srv")}:/thumb/e2"] = "file:///saved/e2.jpg"
        val resolver = resolver(PlaybackClient("srv"))
        assertEquals("file:///saved/e2.jpg", resolver.downloadedArtwork(testItem("e2", "srv"), "/thumb/e2"))
        assertNull(resolver.downloadedArtwork(testItem("e3", "srv"), "/thumb/e3"), "nothing saved")
        assertNull(resolver.downloadedArtwork(testItem("e2", "srv"), null))
        assertNull(resolver.downloadedArtwork(testItem("e2", "srv"), " "))
        assertNull(resolver.downloadedArtwork(testItem("e2", ""), "/thumb/e2"), "no server to look under")
    }

    @Test
    fun aHiddenOrRefusedServerHasNoClientAndNothingToPlay() = runTest {
        val item = testItem("item-1", "srv")
        for (configure in listOf<FakePlaybackServers.() -> Unit>({ hidden += ServerId("srv") }, { refusedServerIds = setOf(ServerId("srv")) })) {
            val client = PlaybackClient("srv")
            val error = assertFailsWith<PlaybackException> { resolver(client, configure = configure).resolve(options(item), offlineLibraryMode = false) }
            assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, error.reason)
            assertEquals(T.messages.noVideoUrl, error.message)
            assertEquals(0, client.initializations)
        }
    }

    @Test
    fun offlineLaunchCannotFallThroughToALiveServerWhenTheDownloadIsMissing() = runTest {
        val client = PlaybackClient("srv")
        val error = assertFailsWith<PlaybackException> {
            resolver(client).resolve(options(testItem("missing-download", "srv")), offlineLibraryMode = true)
        }
        assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, error.reason)
        assertEquals(0, client.initializations)
    }

    @Test
    fun theOfflineLibraryReportsToTheServerWhenItIsOnlineAndQueuesOtherwise() = runTest {
        downloads.add(FakeDownloads.Copy("srv", "movie-1", listOf("/media/movie-1.mkv")))
        val client = failingClient("srv")

        val reachable = resolver(client).resolve(options(testItem("movie-1", "srv")), offlineLibraryMode = true)
        assertEquals(PlaybackReportingMode.ONLINE_WITH_OFFLINE_FALLBACK, reachable.reportingMode)
        assertSame(client, reachable.reportingClient)

        val unreachable = resolver(client) { online.clear() }.resolve(options(testItem("movie-1", "srv")), offlineLibraryMode = true)
        assertEquals(PlaybackSourceKind.LOCAL_FILE, unreachable.sourceKind)
        assertEquals(PlaybackReportingMode.OFFLINE_QUEUE, unreachable.reportingMode)
        assertNull(unreachable.reportingClient)
        assertNull(unreachable.streamHeaders)
    }

    @Test
    fun aTranscodeIsARemoteTranscodeSource() = runTest {
        val client = PlaybackClient("srv") { PlaybackInitializationResult(emptyList(), videoUrl = "https://example.com/t.m3u8", isTranscoding = true) }
        val context = resolver(client).resolve(
            options(testItem("item-1", "srv"), qualityPreset = TranscodeQualityPreset.P720_2MBPS),
            offlineLibraryMode = false,
        )
        assertEquals(PlaybackSourceKind.REMOTE_TRANSCODE, context.sourceKind)
    }

    // Stream headers.

    @Test
    fun plexDirectPlaybackAddsThePlaybackSessionHeaderToStreamHeaders() = runTest {
        val client = PlaybackClient("srv").apply { streamHeaders = mapOf("X-Test" to "token") }
        val context = resolver(client).resolve(
            options(testItem("item-1", "srv"), sessionIdentifier = "playback-session-id"),
            offlineLibraryMode = false,
        )

        assertEquals(PlaybackSourceKind.REMOTE_DIRECT, context.sourceKind)
        assertEquals(mapOf("X-Test" to "token", "X-Plex-Session-Identifier" to "playback-session-id"), context.streamHeaders)
    }

    @Test
    fun nonPlexDirectPlaybackDoesNotAddThePlexSessionHeader() = runTest {
        val client = PlaybackClient("srv", BackendKind.JELLYFIN).apply { streamHeaders = mapOf("X-Test" to "token") }
        val context = resolver(client).resolve(
            options(testItem("item-1", "srv", BackendKind.JELLYFIN), sessionIdentifier = "playback-session-id"),
            offlineLibraryMode = false,
        )

        assertEquals(PlaybackSourceKind.REMOTE_DIRECT, context.sourceKind)
        assertEquals(mapOf("X-Test" to "token"), context.streamHeaders)
    }

    private suspend fun trackStreamHeaders(videoUrl: String): Map<String, String>? {
        val client = PlaybackClient("srv") { PlaybackInitializationResult(emptyList(), videoUrl = videoUrl) }
        client.streamHeaders = mapOf("X-Test" to "token")
        return resolver(client).resolve(
            options(testItem("track-1", "srv", kind = MediaKind.TRACK), sessionIdentifier = "playback-session-id"),
            offlineLibraryMode = false,
        ).streamHeaders
    }

    @Test
    fun aTrackThatNamesItsSessionInTheStreamUrlGetsNoSessionHeader() = runTest {
        // Gapless playback sends the playing track's headers with the next track's request; the server refuses a music
        // transcode start whose header names another active session.
        val headers = trackStreamHeaders(
            "https://example.com/music/:/transcode/universal/start.mp3?session=transcode-id&X-Plex-Session-Identifier=playback-session-id",
        )
        assertEquals(mapOf("X-Test" to "token"), headers)
    }

    @Test
    fun aTrackWhoseStreamUrlDoesNotNameItsSessionKeepsTheSessionHeader() = runTest {
        val headers = trackStreamHeaders("https://example.com/library/parts/1/file.flac")
        assertEquals("playback-session-id", headers?.get("X-Plex-Session-Identifier"))
    }

    // A downloaded copy under a capped quality preset.

    private suspend fun resolveAt720p(client: PlaybackClient, downloadOutranksQuality: Boolean): PlaybackContext {
        downloads.add(FakeDownloads.Copy("srv", "movie-1", listOf("content://sdcard/movie-1.mkv")))
        return resolver(client).resolve(
            options(testItem("movie-1", "srv"), qualityPreset = TranscodeQualityPreset.P720_2MBPS),
            offlineLibraryMode = false,
            downloadOutranksQuality = downloadOutranksQuality,
        )
    }

    @Test
    fun aSavedDefaultQualityPlaysTheDownloadWhileTheServerIsReachable() = runTest {
        val context = resolveAt720p(PlaybackClient("srv"), downloadOutranksQuality = true)

        assertEquals(PlaybackSourceKind.LOCAL_FILE, context.sourceKind)
        assertEquals("content://sdcard/movie-1.mkv", context.result.videoUrl)
        assertEquals(PlaybackReportingMode.ONLINE_WITH_OFFLINE_FALLBACK, context.reportingMode)
    }

    @Test
    fun aQualityPickedForThisPlaybackStreamsFromTheServer() = runTest {
        val context = resolveAt720p(PlaybackClient("srv"), downloadOutranksQuality = false)

        assertEquals(PlaybackSourceKind.REMOTE_DIRECT, context.sourceKind)
        assertEquals("https://example.com/video.mp4", context.result.videoUrl)
    }

    @Test
    fun offlineLibraryModePlaysTheDownloadedVersionEvenWhenAnotherOneIsPreferred() = runTest {
        // The server is reachable, but offline mode has nothing to stream from: the version on disk beats failing.
        downloads.add(FakeDownloads.Copy("srv", "movie-1", listOf("content://sdcard/movie-1.mkv")))
        val context = resolver(PlaybackClient("srv")).resolve(options(testItem("movie-1", "srv"), selectedMediaIndex = 1), offlineLibraryMode = true)

        assertEquals(PlaybackSourceKind.LOCAL_FILE, context.sourceKind)
        assertEquals("content://sdcard/movie-1.mkv", context.result.videoUrl)
    }

    // The startup quality and a pick in the player against a downloaded copy.

    private val switchClient = PlaybackClient("srv") { options ->
        PlaybackInitializationResult(
            emptyList(),
            videoUrl = "https://example.invalid/switch/${options.qualityPreset.name.lowercase()}/audio-${options.selectedAudioStreamId}",
            isTranscoding = !options.qualityPreset.isOriginal,
        )
    }

    private suspend fun open(choice: QualityChoice, audioStreamId: Int): String? = resolver(switchClient).resolve(
        PlaybackInitializationOptions(testItem("movie-1", "srv"), 0, qualityPreset = choice.preset, selectedAudioStreamId = audioStreamId),
        offlineLibraryMode = false,
        downloadOutranksQuality = choice.downloadOutranksQuality,
    ).result.videoUrl

    private fun startupChoice() = QualityChoice.atStartup(
        requested = null,
        offlineLibraryMode = false,
        live = false,
        serverSupportsTranscoding = true,
        onCellularOnly = false,
        cellularDefault = null,
        generalDefault = TranscodeQualityPreset.P720_2MBPS,
    )

    @Test
    fun aDownloadOutranksTheSavedDefaultQualityWhenTheSourceReloads() = runTest {
        downloads.add(FakeDownloads.Copy("srv", "movie-1", listOf("/downloads/movie-1.mkv")))
        val choice = startupChoice()

        assertEquals(TranscodeQualityPreset.P720_2MBPS, choice.preset)
        assertEquals("file:///downloads/movie-1.mkv", open(choice, audioStreamId = 2))
        assertEquals(0, switchClient.initializations)
    }

    @Test
    fun aDownloadYieldsToAQualityPickedInThePlayerForTheRestOfTheSession() = runTest {
        downloads.add(FakeDownloads.Copy("srv", "movie-1", listOf("/downloads/movie-1.mkv")))
        val picked = startupChoice().picked(TranscodeQualityPreset.P720_2MBPS)
        val opened = listOf(
            open(picked, audioStreamId = 1),
            // A later reload carries the picked quality and must not fall back to the download.
            open(picked, audioStreamId = 2),
            // Picking Original plays the download again.
            open(picked.picked(TranscodeQualityPreset.ORIGINAL), audioStreamId = 2),
        )
        assertEquals(
            listOf(
                "https://example.invalid/switch/p720_2mbps/audio-1",
                "https://example.invalid/switch/p720_2mbps/audio-2",
                "file:///downloads/movie-1.mkv",
            ),
            opened,
        )
    }

    // The downloaded copy.

    @Test
    fun pureOfflinePlaybackLoadsCachedPlexMediaSourceInfoWithoutAClient() = runTest {
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("content://offline/movie-1")))
        putPlex("srv-1", "movie-1", plexMetadataEnvelope())

        val result = resolver().resolve(options(testItem("movie-1", "srv-1")), offlineLibraryMode = false).result

        assertTrue(result.isOffline)
        assertEquals("content://offline/movie-1", result.videoUrl)
        assertEquals("eng", result.mediaInfo?.audioTracks?.single()?.languageCode)
    }

    @Test
    fun aDownloadedTrackResolvesToItsLocalFileThroughTheOfflinePath() = runTest {
        // Music reaches this at Original quality, so a downloaded track plays from disk.
        downloads.add(FakeDownloads.Copy("srv-1", "track-1", listOf("content://offline/track-1")))
        val client = failingClient("srv-1")

        val result = resolver(client).resolve(options(testItem("track-1", "srv-1", kind = MediaKind.TRACK)), offlineLibraryMode = false).result

        assertEquals(0, client.initializations)
        assertTrue(result.isOffline)
        assertEquals("content://offline/track-1", result.videoUrl)
        assertEquals("DirectPlay", result.playMethod)
    }

    @Test
    fun preferringTheDownloadUsesTheCacheWithoutCallingTheLiveClient() = runTest {
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("content://offline/movie-1")))
        putPlex("srv-1", "movie-1", plexMetadataEnvelope())
        val client = failingClient("srv-1")

        val result = resolver(client).resolve(options(testItem("movie-1", "srv-1")), offlineLibraryMode = false).result

        assertEquals(0, client.initializations)
        assertTrue(result.isOffline)
        assertEquals("content://offline/movie-1", result.videoUrl)
        assertTrue(result.availableVersions.isEmpty())
        assertEquals("eng", result.mediaInfo?.audioTracks?.single()?.languageCode)
    }

    @Test
    fun pureOfflinePlaybackUsesTheCachedPlexMediaSourceOfTheSelectedVersion() = runTest {
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("content://offline/movie-1-v2"), mediaIndex = 1))
        putPlex("srv-1", "movie-1", plexMetadataEnvelope(includeSecondVersion = true))

        val result = resolver().resolve(options(testItem("movie-1", "srv-1"), selectedMediaIndex = 1), offlineLibraryMode = false).result

        assertEquals("content://offline/movie-1-v2", result.videoUrl)
        assertEquals("fre", result.mediaInfo?.audioTracks?.single()?.languageCode)
    }

    @Test
    fun noClientPlaybackFallsBackToTheDownloadedVersionOnADefaultRequest() = runTest {
        // Only the non-default version is downloaded, but a plain play asks for the default one. With no client to
        // stream from, the downloaded copy plays with its own version's metadata.
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("content://offline/movie-1-v2"), mediaIndex = 1, mediaSourceId = "source-b"))
        putPlex("srv-1", "movie-1", plexMetadataEnvelope(includeSecondVersion = true))

        val result = resolver().resolve(options(testItem("movie-1", "srv-1")), offlineLibraryMode = false).result

        assertTrue(result.isOffline)
        assertEquals("content://offline/movie-1-v2", result.videoUrl)
        assertEquals(1, result.selectedMediaIndex)
        assertEquals("source-b", result.selectedMediaSourceId)
        assertEquals("fre", result.mediaInfo?.audioTracks?.single()?.languageCode)
    }

    @Test
    fun noClientPlaybackPlaysTheLocalCopyEvenOnAnExplicitVersionMismatch() = runTest {
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("content://offline/movie-1-v2"), mediaIndex = 1, mediaSourceId = "source-b"))

        val result = resolver().resolve(options(testItem("movie-1", "srv-1"), selectedMediaSourceId = "source-a"), offlineLibraryMode = false).result

        assertTrue(result.isOffline)
        assertEquals("content://offline/movie-1-v2", result.videoUrl)
        assertEquals(1, result.selectedMediaIndex)
    }

    @Test
    fun anOnlineExplicitVersionMismatchKeepsStreamingFromTheServer() = runTest {
        // Play Version at Original on a version that isn't downloaded checks the download first, but the strict match
        // sends it to the server.
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("content://offline/movie-1-v2"), mediaIndex = 1, mediaSourceId = "source-b"))
        val client = streamingClient("srv-1")

        val result = resolver(client).resolve(options(testItem("movie-1", "srv-1"), selectedMediaSourceId = "source-a"), offlineLibraryMode = false).result

        assertEquals(1, client.initializations)
        assertFalse(result.isOffline)
        assertEquals("https://server/stream/0", result.videoUrl)
    }

    @Test
    fun noClientAndNoDownloadHasNoVideoUrl() = runTest {
        val error = assertFailsWith<PlaybackException> { resolver().resolve(options(testItem("movie-1", "srv-1")), offlineLibraryMode = false) }
        assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, error.reason)
        assertEquals(T.messages.noVideoUrl, error.message)
    }

    @Test
    fun pureOfflineJellyfinCacheWorksWithoutAConnectionRow() = runTest {
        downloads.add(FakeDownloads.Copy("jf-machine", "item-1", listOf("content://offline/jf-item-1"), clientScopeId = "jf-machine/user-a"))
        store.put("jf-machine/user-a", "/Users/user-a/Items/item-1", Json.parseToJsonElement(JELLYFIN_ITEM).jsonObject)

        val result = resolver().resolve(options(testItem("item-1", "jf-machine", BackendKind.JELLYFIN)), offlineLibraryMode = false).result

        assertEquals("content://offline/jf-item-1", result.videoUrl)
        assertEquals("eng", result.mediaInfo?.audioTracks?.single()?.languageCode)
        assertEquals("Chapter 1", result.mediaInfo?.chapters?.single()?.title)
    }

    @Test
    fun aLiveClientReadsTheCachedMediaInfoUnderItsOwnCacheScope() = runTest {
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("content://offline/movie-1"), clientScopeId = "stale-scope"))
        putPlex("srv-1/profile-a", "movie-1", plexMetadataEnvelope())
        val client = PlaybackClient("srv-1", scopeId = "srv-1/profile-a")

        val result = resolver(client).resolve(options(testItem("movie-1", "srv-1")), offlineLibraryMode = false).result

        assertEquals("eng", result.mediaInfo?.audioTracks?.single()?.languageCode)
    }

    @Test
    fun aPlainPathPlaysAsAFileUrl() = runTest {
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("/downloads/Movie (2020)/Movie.mkv")))

        val result = resolver().resolve(options(testItem("movie-1", "srv-1")), offlineLibraryMode = false).result

        assertEquals("file:///downloads/Movie (2020)/Movie.mkv", result.videoUrl)
    }

    // Sidecar subtitles of a download.

    @Test
    fun offlinePlaybackPreloadsTheDownloadedSidecarSubtitles() = runTest {
        downloads.add(
            FakeDownloads.Copy(
                "srv-1",
                "movie-1",
                listOf("content://offline/movie-1"),
                subtitles = listOf("/data/downloads/srv-1/movie-1/subtitles/2.srt", "/data/downloads/srv-1/movie-1/subtitles/Forced Signs.ass"),
            ),
        )
        putPlex("srv-1", "movie-1", plexMetadataEnvelope(subtitle = true))

        val sidecars = resolver().resolve(options(testItem("movie-1", "srv-1")), offlineLibraryMode = false).result.subtitleSidecars

        assertEquals(listOf("file:///data/downloads/srv-1/movie-1/subtitles/2.srt", "file:///data/downloads/srv-1/movie-1/subtitles/Forced%20Signs.ass"), sidecars.map { it.track.url })
        assertTrue(sidecars.all { it.preload }, "local sidecars load with the media so they stay selectable as secondary subtitles")
        val known = sidecars[0]
        assertEquals(2, known.sourceStreamId)
        assertEquals("English (SRT)", known.track.title)
        assertEquals("eng", known.track.language)
        assertEquals("srt", known.track.codec)
        assertTrue(known.track.forced)
        val unknown = sidecars[1]
        assertNull(unknown.sourceStreamId)
        assertEquals(T.videoControls.subtitleFile("Forced Signs"), unknown.track.title)
    }

    // A stacked item.

    @Test
    fun aStackedDownloadPlaysTheFileHoldingTheStartPosition() = runTest {
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("content://offline/movie-1", "content://offline/movie-1 - part2")))
        putPlex("srv-1", "movie-1", STACKED_ENVELOPE)

        val first = resolver().resolve(options(testItem("movie-1", "srv-1"), startPosition = 10.minutes), offlineLibraryMode = false).result
        assertEquals("content://offline/movie-1", first.videoUrl)
        assertEquals(0, first.mediaInfo?.partTimeline?.currentIndex)

        val second = resolver().resolve(options(testItem("movie-1", "srv-1"), startPosition = 55.minutes), offlineLibraryMode = false).result
        assertTrue(second.isOffline)
        assertEquals("content://offline/movie-1 - part2", second.videoUrl)
        assertEquals(50.minutes, second.mediaInfo?.partTimeline?.current?.start)
    }

    @Test
    fun aCopyHoldingOnlyTheFirstFileStreamsTheRestOrFailsWhenItMustStayOffline() = runTest {
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("content://offline/movie-1")))
        putPlex("srv-1", "movie-1", STACKED_ENVELOPE)

        val client = streamingClient("srv-1")
        val streamed = resolver(client).resolve(options(testItem("movie-1", "srv-1"), startPosition = 55.minutes), offlineLibraryMode = false).result
        assertFalse(streamed.isOffline)
        assertEquals(1, client.initializations)

        val error = assertFailsWith<PlaybackException> {
            resolver().resolve(options(testItem("movie-1", "srv-1"), startPosition = 55.minutes), offlineLibraryMode = false)
        }
        assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, error.reason)
    }

    @Test
    fun aFailedDownloadLookupStreamsFromTheServer() = runTest {
        downloads.failure = IllegalStateException("database closed")
        val client = streamingClient("srv-1")

        val result = resolver(client).resolve(options(testItem("movie-1", "srv-1")), offlineLibraryMode = false).result

        assertEquals("https://server/stream/0", result.videoUrl)
    }

    @Test
    fun anExternalPlayerGetsTheDownloadedSidecarsLabelledFromTheCache() = runTest {
        downloads.add(FakeDownloads.Copy("srv-1", "movie-1", listOf("/downloads/movie-1.mkv"), subtitles = listOf("/downloads/movie-1_subs/2.srt")))
        putPlex("srv-1", "movie-1", plexMetadataEnvelope(subtitle = true))
        val item = testItem("movie-1", "srv-1")
        val video = downloads.resolve(ServerId("srv-1"), "movie-1", 0, null, allowAnyVersion = false, partIndex = 0)!!

        val sidecars = resolver().downloadedSubtitles(item, video, client = null)

        assertEquals(listOf("file:///downloads/movie-1_subs/2.srt"), sidecars.map { it.track.url })
        assertEquals("English (SRT)", sidecars.single().track.title)
    }
}
