package com.edde746.plezy.watch

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaVersion
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import party.openwatch.Media
import party.openwatch.MediaKind
import party.openwatch.checkMedia
import party.openwatch.parseMedia
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import com.edde746.plezy.model.MediaKind as ItemKind

class MediaDescriptorTest {
    private val showGuid = "plex://show/5d9c086c46115600200aa2fe"
    private val movieGuid = "plex://movie/5d7768ba96b655001fdc0408"

    private fun item(
        id: String,
        kind: ItemKind = ItemKind.MOVIE,
        title: String? = null,
        year: Int? = null,
        durationMs: Long? = null,
        versions: List<MediaVersion>? = null,
        guid: String? = null,
        grandparentId: String? = null,
        grandparentTitle: String? = null,
        parentIndex: Int? = null,
        index: Int? = null,
    ) = MediaItem(
        id = id, backend = BackendKind.PLEX, kind = kind, title = title, year = year, durationMs = durationMs,
        mediaVersions = versions, guid = guid, grandparentId = grandparentId, grandparentTitle = grandparentTitle,
        parentIndex = parentIndex, index = index, serverId = "fake-1",
    )

    private fun version(id: String, durationMs: Long? = null, sizeBytes: Long? = null, file: String? = null, parts: List<MediaPart>? = null) =
        MediaVersion(id = id, parts = parts ?: listOf(MediaPart(id = "$id-part", durationMs = durationMs, sizeBytes = sizeBytes, file = file)))

    /** A server whose lookups answer from [items] and [ids] (none: no ids), or fail with [itemError] / [idsError]. */
    private fun server(
        items: Map<String, MediaItem> = emptyMap(),
        ids: Map<String, ExternalIds> = emptyMap(),
        itemError: Exception? = null,
        idsError: Exception? = null,
    ) = FakeMediaBackend("fake-1").apply {
        this.items = { id -> itemError?.let { throw it } ?: items[id] }
        externalIds = { id -> idsError?.let { throw it } ?: ids[id] ?: ExternalIds() }
    }

    private suspend fun describe(copy: WatchCopy, client: FakeMediaBackend, playerDurationMs: Long? = null): Media {
        val result = MediaDescriptor.describe(client, copy, playerDurationMs)
        assertNull(result.failure)
        val media = assertNotNull(result.media)
        assertNull(checkMedia(media), "the SDK must accept what describe returns")
        return media
    }

    private fun ext(server: String, item: String, version: String? = null) = buildJsonObject {
        put(MediaDescriptor.EXT_NAME, buildJsonObject {
            put("server", server)
            put("item", item)
            version?.let { put("version", it) }
        })
    }

    @Test
    fun aMovieCarriesItsIdsItsPlexGuidTheVersionLengthAndFileHints() = runTest {
        val movie = item("movie-1", title = "The Matrix", year = 1999, guid = movieGuid, durationMs = 8_160_000,
            versions = listOf(version("11", 8_160_000, 4_200_000_000, "/movies/The Matrix (1999)/The Matrix (1999).mkv")))
        val client = server(ids = mapOf("movie-1" to ExternalIds(imdb = "tt0133093", tmdb = 603, tvdb = 169)))

        val media = describe(WatchCopy.of(movie, movie.mediaVersions!!.single()), client)

        assertEquals(MediaKind.MOVIE, media.kind)
        assertEquals("The Matrix", media.title)
        assertEquals(1999L, media.year)
        assertEquals(mapOf("imdb" to "tt0133093", "tmdb" to "603", "tvdb" to "169", "plex" to movieGuid), media.ids)
        assertNull(media.series)
        assertEquals(null to null, media.season to media.episode)
        assertEquals(8_160_000L, media.durationMs)
        assertEquals(4_200_000_000L, media.file?.sizeBytes)
        assertEquals("The Matrix (1999).mkv", media.file?.name)
        assertEquals(ext("fake-1", "movie-1", "11"), media.ext)
    }

    @Test
    fun eachVersionIsDescribedWithItsOwnLengthAndSize() = runTest {
        val movie = item("movie-1", title = "Blade Runner", year = 1982, durationMs = 7_020_000,
            versions = listOf(version("11", 7_020_000, 100, "/m/Theatrical.mkv"), version("12", 7_380_000, 200, "/m/Final Cut.mkv")))

        val media = describe(WatchCopy.of(movie, movie.mediaVersions!![1]), server())

        assertEquals(7_380_000L, media.durationMs)
        assertEquals(200L, media.file?.sizeBytes)
        assertEquals("Final Cut.mkv", media.file?.name)
        assertEquals(JsonPrimitive("12"), (media.ext!![MediaDescriptor.EXT_NAME] as JsonObject)["version"])
    }

    @Test
    fun aSingleSourceWithoutItsOwnLengthFallsBackToTheItemLength() = runTest {
        val movie = item("movie-1", title = "Alien", durationMs = 7_020_000, versions = listOf(version("src-1", sizeBytes = 100)))
        assertEquals(7_020_000L, describe(WatchCopy.of(movie, movie.mediaVersions!!.single()), server()).durationMs)
    }

    @Test
    fun anEpisodeCarriesItsNumbersAndItsShowAsSeries() = runTest {
        val show = item("show-1", kind = ItemKind.SHOW, title = "Severance", year = 2022, guid = showGuid)
        val episode = item("ep-1", kind = ItemKind.EPISODE, title = "Half Loop", year = 2022, grandparentId = "show-1",
            grandparentTitle = "Severance", parentIndex = 1, index = 2, durationMs = 3_300_000,
            guid = "plex://episode/5ea9e1c8a5bd6000418dc2b9", versions = listOf(version("31", 3_300_000, 300, "/tv/Severance/S01E02.mkv")))
        val client = server(
            items = mapOf("show-1" to show),
            ids = mapOf("ep-1" to ExternalIds(tvdb = 8_247_063), "show-1" to ExternalIds(imdb = "tt11280740", tvdb = 371_980)),
        )

        val media = describe(WatchCopy.of(episode, episode.mediaVersions!!.single()), client)

        assertEquals(MediaKind.EPISODE, media.kind)
        assertEquals("Half Loop", media.title)
        assertNull(media.year, "an episode names its series year, not its own")
        assertEquals(mapOf("tvdb" to "8247063", "plex" to "plex://episode/5ea9e1c8a5bd6000418dc2b9"), media.ids)
        assertEquals("Severance", media.series?.title)
        assertEquals(2022L, media.series?.year)
        assertEquals(mapOf("imdb" to "tt11280740", "tvdb" to "371980", "plex" to showGuid), media.series?.ids)
        assertEquals(1L to 2L, media.season to media.episode)
    }

    @Test
    fun aClipGoesOutAsAVideoWithoutIdsMatchedByFileOnly() = runTest {
        val clip = item("clip-1", kind = ItemKind.CLIP, title = "Birthday 2019", year = 2019, guid = "local://12345", durationMs = 60_000,
            versions = listOf(version("51", 60_000, 5000, """C:\Videos\Birthday 2019.mp4""")))
        val client = server(ids = mapOf("clip-1" to ExternalIds(imdb = "tt0133093")))

        val media = describe(WatchCopy.of(clip, clip.mediaVersions!!.single()), client)

        assertEquals(MediaKind.VIDEO, media.kind)
        assertEquals(emptyMap(), media.ids)
        assertEquals(2019L, media.year)
        assertEquals("Birthday 2019.mp4", media.file?.name, "Windows paths split too")
        assertEquals(5000L, media.file?.sizeBytes)
        assertEquals(emptyList(), client.calls, "a video looks up no ids")
    }

    @Test
    fun aVersionWithoutItsOwnLengthAmongSeveralHasNoneThePlayerLengthIsUsed() = runTest {
        val movie = item("movie-1", title = "Two Cuts", durationMs = 7_000_000, versions = listOf(version("a"), version("b")))
        val copy = WatchCopy.of(movie, movie.mediaVersions!!.last())
        val client = server()

        val none = MediaDescriptor.describe(client, copy, null)
        assertNull(none.media)
        assertEquals(DescribeFailure.NO_DURATION, none.failure)
        assertEquals(emptyList(), client.calls, "no lookups for a file that cannot be described")

        assertEquals(DescribeFailure.NO_DURATION, MediaDescriptor.describe(client, copy, 0).failure)
        assertEquals(7_300_000L, describe(copy, client, playerDurationMs = 7_300_000).durationMs)
    }

    @Test
    fun theServerLengthWinsOverThePlayerLength() = runTest {
        val movie = item("movie-1", title = "Alien", durationMs = 7_020_000)
        val media = describe(WatchCopy.of(movie, null), server(), playerDurationMs = 6_000_000)
        assertEquals(7_020_000L, media.durationMs)
        assertNull(media.file)
        assertEquals(ext("fake-1", "movie-1"), media.ext, "an item without versions names no version")
    }

    @Test
    fun aVersionOfSeveralPartsLastsTheirSumAndWeighsTheirSizes() = runTest {
        val movie = item("movie-1", title = "Stacked", versions = listOf(version("v", parts = listOf(
            MediaPart(id = "p1", durationMs = 3_000_000, sizeBytes = 10, file = "/m/cd1.avi"),
            MediaPart(id = "p2", durationMs = 2_000_000, sizeBytes = 15, file = "/m/cd2.avi"),
        ))))
        val media = describe(WatchCopy.of(movie, movie.mediaVersions!!.single()), server())
        assertEquals(5_000_000L, media.durationMs)
        assertEquals(25L, media.file?.sizeBytes)
        assertNull(media.file?.name, "no one file name stands for several parts")
    }

    @Test
    fun aMovieWhoseIdsCannotBeReadIsStillSharedWithoutIds() = runTest {
        val movie = item("movie-1", title = "Alien", year = 1979, durationMs = 7_020_000)
        val media = describe(WatchCopy.of(movie, null), server(idsError = IllegalStateException("server down")))
        assertEquals(MediaKind.MOVIE, media.kind)
        assertEquals(emptyMap(), media.ids)
    }

    @Test
    fun anUnreadableShowLeavesTheSeriesItsTitleFromTheEpisode() = runTest {
        val episode = item("ep-1", kind = ItemKind.EPISODE, title = "Half Loop", grandparentId = "show-1",
            grandparentTitle = " Severance ", parentIndex = 1, index = 2, durationMs = 3_300_000)
        val client = server(itemError = IllegalStateException("server down"), idsError = IllegalStateException("server down"))

        val media = describe(WatchCopy.of(episode, null), client)

        assertEquals("Severance", media.series?.title)
        assertNull(media.series?.year)
        assertEquals(emptyMap(), media.series?.ids)
        assertEquals(1L to 2L, media.season to media.episode)
    }

    @Test
    fun anEpisodeWithoutItsShowTitleTakesTheShowsOwnTitle() = runTest {
        val show = item("show-1", kind = ItemKind.SHOW, title = "Severance", year = 2022, guid = showGuid)
        val episode = item("ep-1", kind = ItemKind.EPISODE, title = "Half Loop", grandparentId = "show-1",
            parentIndex = 1, index = 2, durationMs = 3_300_000)
        val client = server(
            items = mapOf("show-1" to show),
            ids = mapOf("show-1" to ExternalIds(tvdb = 371_980), "ep-1" to ExternalIds(tvdb = 8_247_063)),
        )

        val media = describe(WatchCopy.of(episode, null), client)

        assertEquals("Severance", media.series?.title)
        assertEquals(2022L, media.series?.year)
        assertEquals(mapOf("tvdb" to "371980", "plex" to showGuid), media.series?.ids)
        assertEquals(mapOf("tvdb" to "8247063"), media.ids)
    }

    @Test
    fun anEpisodeWithoutAShowAtAllIsStillAnEpisodeOfAnUnknownSeries() = runTest {
        val episode = item("ep-1", kind = ItemKind.EPISODE, index = 3, parentIndex = -1, durationMs = 3_300_000)
        val client = server()

        val media = describe(WatchCopy.of(episode, null), client)

        assertEquals(MediaKind.EPISODE, media.kind)
        assertTrue(media.series!!.title.isNotEmpty())
        assertEquals(emptyMap(), media.series?.ids)
        assertEquals("Episode 3", media.title, "an untitled episode is named by its number")
        assertNull(media.season, "a negative season number is no number")
        assertEquals(3L, media.episode)
        assertEquals(listOf("fetchExternalIds:ep-1"), client.calls, "no show to look up")
    }

    @Test
    fun aFileNameTheRelayRefusesIsDroppedTheSizeKept() = runTest {
        val movie = item("movie-1", title = "Alien", versions = listOf(version("v", 7_020_000, 100, "/m/Alien\u0007.mkv")))
        val media = describe(WatchCopy.of(movie, movie.mediaVersions!!.single()), server())
        assertNull(media.file?.name)
        assertEquals(100L, media.file?.sizeBytes)
    }

    @Test
    fun aRefusedFileNameWithoutASizeLeavesNoFileHints() = runTest {
        val movie = item("movie-1", title = "Alien", versions = listOf(version("v", 7_020_000, file = "/m/Alien\u0007.mkv")))
        assertNull(describe(WatchCopy.of(movie, movie.mediaVersions!!.single()), server()).file)
    }

    @Test
    fun titlesWithDirectionMarksOrLineBreaksAreStillShared() = runTest {
        val episode = item("ep-1", kind = ItemKind.EPISODE, title = "\u200Fפרק\tראשון", grandparentTitle = "Line\nBreak\u202E",
            parentIndex = 1, index = 1, durationMs = 3_300_000)

        val media = describe(WatchCopy.of(episode, null), server())

        assertEquals("פרק ראשון", media.title)
        assertEquals("Line Break", media.series?.title)
    }

    @Test
    fun descriptorTextTurnsBlanksIntoSingleSpacesAndDropsWhatTheRelayRefuses() {
        assertEquals("Alien Director's Cut", MediaDescriptor.descriptorText("  Alien\r\n\t Director's  Cut "))
        assertEquals("עברית x", MediaDescriptor.descriptorText("\u202Bעברית\u202C \u2066x\u2069\u061C\u0007"))
        assertEquals("broken surrogate", MediaDescriptor.descriptorText("broken \uD800 surrogate"))
        assertEquals("😀 emoji", MediaDescriptor.descriptorText("😀 emoji"))
        for (empty in listOf(null, "", " \n\t", "\u200E\u200F\u0000")) assertNull(MediaDescriptor.descriptorText(empty), "$empty")
    }

    @Test
    fun aDisplayNameIsProtocolTextOfAtMost32CodePointsTrimmedAndPlezyWhenNothingIsLeft() {
        assertEquals("Ann Lee", watchDisplayName(" Ann\u000B\u000C  \t\r\nLee\n"))
        assertEquals("Ann", watchDisplayName("A\u0001n\u007Fn\u0085\u009F"))
        assertEquals("Bob", watchDisplayName("\u061CB\u200Eo\u200Fb\u202A\u202B\u202C\u202D\u202E\u2066\u2067\u2068\u2069"))
        assertEquals("Cat", watchDisplayName("Ca\uD800t\uDC00"))
        assertEquals("😀".repeat(32), watchDisplayName("😀".repeat(40)), "a surrogate pair is one code point")
        assertEquals("A".repeat(31) + "😀", watchDisplayName("A".repeat(31) + "😀😀"))
        assertEquals("A".repeat(31), watchDisplayName("A".repeat(31) + " B"), "trimmed after the cut")
        for (empty in listOf("", "   ", "\u202E\n", "\u0000\u200F")) assertEquals("Plezy", watchDisplayName(empty), empty)
    }

    @Test
    fun aDescriptorOverTheRelayLimitsIsRefused() = runTest {
        val movie = item("movie-1", title = "A".repeat(5000), durationMs = 7_020_000)
        val result = MediaDescriptor.describe(server(), WatchCopy.of(movie, null), null)
        assertNull(result.media)
        assertEquals(DescribeFailure.INVALID, result.failure)
    }

    @Test
    fun plezyRefReadsWhatDescribeWritesThroughTheWire() = runTest {
        val movie = item("movie-1", title = "Alien", versions = listOf(version("v1", 7_020_000)))
        val described = describe(WatchCopy.of(movie, movie.mediaVersions!!.single()), server())
        assertEquals(PlezyRef("fake-1", "movie-1", "v1"), MediaDescriptor.plezyRef(parseMedia(described.toJson())))
    }

    private fun media(ext: JsonObject?) = Media(kind = MediaKind.MOVIE, title = "Alien", durationMs = 1, ext = ext)

    private fun plezy(member: JsonElement) = JsonObject(mapOf(MediaDescriptor.EXT_NAME to member))

    private fun obj(vararg pairs: Pair<String, JsonElement>) = JsonObject(mapOf(*pairs))

    @Test
    fun plezyRefIgnoresHostileOrForeignShapes() {
        val s = JsonPrimitive("s")
        val i = JsonPrimitive("i")
        for (
        ext in listOf(
            null, JsonObject(emptyMap()), JsonObject(mapOf("com.example" to obj("server" to s, "item" to i))),
            plezy(JsonPrimitive("server:item")), plezy(JsonArray(listOf(s, i))), plezy(obj("server" to s)), plezy(obj("item" to i)),
            plezy(obj("server" to JsonPrimitive(""), "item" to i)), plezy(obj("server" to s, "item" to JsonPrimitive(""))),
            plezy(obj("server" to JsonPrimitive(1), "item" to i)), plezy(obj("server" to s, "item" to obj("id" to i))),
        )
        ) {
            assertNull(MediaDescriptor.plezyRef(media(ext)), "$ext")
        }
    }

    @Test
    fun aVersionThatIsNotANonEmptyStringIsNoVersion() {
        for (version in listOf(JsonPrimitive(""), JsonPrimitive(7), JsonNull, JsonArray(listOf(JsonPrimitive("v"))), obj("id" to JsonPrimitive("v")))) {
            val ext = plezy(obj("server" to JsonPrimitive("s"), "item" to JsonPrimitive("i"), "version" to version))
            assertEquals(PlezyRef("s", "i", null), MediaDescriptor.plezyRef(media(ext)), "$version")
        }
    }

    @Test
    fun fileBaseNameTakesTheLastSegmentOfEitherSeparator() {
        assertEquals("c.mkv", MediaDescriptor.fileBaseName("/a/b/c.mkv"))
        assertEquals("c.mkv", MediaDescriptor.fileBaseName("""C:\a\b\c.mkv"""))
        assertEquals("c.mkv", MediaDescriptor.fileBaseName("""\\nas\share/mixed\c.mkv"""))
        for (path in listOf(null, "", "/", "/a/", "/a/..", "/a/.", "   ")) assertNull(MediaDescriptor.fileBaseName(path), path)
    }
}
