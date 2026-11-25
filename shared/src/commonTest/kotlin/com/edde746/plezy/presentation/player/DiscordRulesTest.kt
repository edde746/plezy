package com.edde746.plezy.presentation.player

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.HttpTimeoutCapability
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.OutgoingContent
import io.ktor.http.headersOf
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

class DiscordRulesTest {
    private val now = 1_800_000_000_000L

    private fun item(kind: MediaKind, title: String = "Pilot", configure: MediaItem.() -> MediaItem = { this }) =
        MediaItem(id = "1", backend = BackendKind.PLEX, kind = kind, title = title, serverId = "srv").configure()

    private fun playing(item: MediaItem?, position: Double = 60.0, duration: Double = 3600.0, rate: Double = 1.0, status: NowPlayingStatus = NowPlayingStatus.PLAYING) =
        NowPlaying(
            title = "Player title", subtitle = "Player subtitle", artworkUrl = "https://server.example/art?X-Plex-Token=t",
            durationSeconds = duration, positionSeconds = position, rate = rate, status = status,
            canSeek = true, canSkipNext = false, canSkipPrevious = false, live = false, item = item,
        )

    @Test
    fun `a movie shows its title and year over its studio`() {
        val activity = DiscordActivity.of(playing(item(MediaKind.MOVIE, "Heat") { copy(year = 1995, studio = "Warner Bros.") }), now)!!
        assertEquals("Heat (1995)", activity.details)
        assertEquals("Warner Bros.", activity.state)
        assertEquals("Heat", activity.imageText)
        assertFalse(activity.listening)
    }

    @Test
    fun `an episode shows its series over season episode and title`() {
        val episode = item(MediaKind.EPISODE) { copy(grandparentTitle = "Severance", parentIndex = 1, index = 5) }
        val activity = DiscordActivity.of(playing(episode), now)!!
        assertEquals("Severance", activity.details)
        assertEquals("S1 E5 - Pilot", activity.state)
        assertEquals("Severance", activity.imageText)
        val unnumbered = DiscordActivity.of(playing(item(MediaKind.EPISODE)), now)!!
        assertEquals("Pilot", unnumbered.details)
        assertEquals("Pilot", unnumbered.state)
    }

    @Test
    fun `a track publishes a listening activity with the artist as state and the album as tooltip`() {
        val track = item(MediaKind.TRACK, "Teardrop") { copy(originalTitle = "Massive Attack", parentTitle = "Mezzanine") }
        val activity = DiscordActivity.of(playing(track), now)!!
        assertTrue(activity.listening)
        assertEquals("Teardrop", activity.details)
        assertEquals("Massive Attack", activity.state)
        assertEquals(track.albumTitle ?: "Massive Attack", activity.imageText)
        assertTrue(DiscordRpc.setActivity(activity, 1, "n").contains("\"type\":2"))
        assertTrue(DiscordRpc.setActivity(DiscordActivity.of(playing(item(MediaKind.MOVIE)), now)!!, 1, "n").contains("\"type\":3"))
    }

    @Test
    fun `a paused playback shows no card`() {
        assertNull(DiscordActivity.of(playing(item(MediaKind.MOVIE), status = NowPlayingStatus.PAUSED), now))
    }

    @Test
    fun `a server item shows only its hosted poster never the servers artwork`() {
        assertNull(DiscordActivity.of(playing(item(MediaKind.MOVIE)), now)!!.imageUrl)
        assertEquals("https://ice.plezy.app/posters/a.jpg", DiscordActivity.of(playing(item(MediaKind.MOVIE)), now, "https://ice.plezy.app/posters/a.jpg")!!.imageUrl)
    }

    @Test
    fun `timestamps span the length at the playback speed`() {
        val activity = DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 600.0, duration = 3600.0, rate = 2.0), now)!!
        assertEquals((now + 1_500_000) / 1000, activity.endSeconds)
        assertEquals((now + 1_500_000 - 1_800_000) / 1000, activity.startSeconds)
        val unknownLength = DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 30.0, duration = 0.0), now)!!
        assertEquals((now - 30_000) / 1000, unknownLength.startSeconds)
        assertNull(unknownLength.endSeconds)
    }

    @Test
    fun `only a seek or a new speed republishes`() {
        val shown = DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 60.0), now)!!
        // Ten seconds later at its pace, or with a position report up to five seconds behind: the same card.
        assertTrue(DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 70.0), now + 10_000)!!.sameAs(shown))
        assertTrue(DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 65.0), now + 10_000)!!.sameAs(shown))
        // A jump of more than five seconds is a seek.
        assertFalse(DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 80.0), now + 10_000)!!.sameAs(shown))
        assertFalse(DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 60.0, rate = 1.25), now)!!.sameAs(shown))
    }

    @Test
    fun `the relays expiry is honoured and a missing invalid or year long one falls back to three hours`() {
        val at = Instant.fromEpochMilliseconds(now)
        assertEquals(at + 600.seconds, DiscordPosters.expiry(JsonPrimitive(600), at))
        assertEquals(at, DiscordPosters.expiry(JsonPrimitive(0), at))
        assertEquals(at, DiscordPosters.expiry(JsonPrimitive(-5), at))
        assertEquals(at + 3.hours, DiscordPosters.expiry(null, at))
        assertEquals(at + 3.hours, DiscordPosters.expiry(JsonPrimitive("600"), at))
        assertEquals(at + 3.hours, DiscordPosters.expiry(JsonPrimitive((366.days).inWholeSeconds), at))
    }

    @Test
    fun `hosted poster URLs are absolute http or a posters path`() {
        val upload = DiscordPosters.UPLOAD_URL
        assertEquals("https://cdn.example/p.jpg", DiscordPosters.hostedUrl("https://cdn.example/p.jpg", upload))
        assertEquals("https://ice.plezy.app/posters/abc.jpg", DiscordPosters.hostedUrl("/posters/abc.jpg", upload))
        assertNull(DiscordPosters.hostedUrl("/other/abc.jpg", upload))
        assertNull(DiscordPosters.hostedUrl("ftp://x/p.jpg", upload))
        assertNull(DiscordPosters.hostedUrl("", upload))
    }

    @Test
    fun `posters are the album art the series poster or the items own at Discords size`() {
        val track = item(MediaKind.TRACK) { copy(thumbPath = "/album", grandparentThumbPath = "/artist") }
        assertEquals("/album", DiscordPosters.thumbPath(track))
        assertEquals(512 to 512, DiscordPosters.size(track))
        val episode = item(MediaKind.EPISODE) { copy(thumbPath = "/ep", grandparentThumbPath = "/show") }
        assertEquals("/show", DiscordPosters.thumbPath(episode))
        assertEquals(512 to 768, DiscordPosters.size(episode))
        assertEquals(960 to 540, DiscordPosters.size(episode.copy(grandparentThumbPath = null)))
    }

    @Test
    fun `a poster is fetched with the servers headers only from the server posted as bytes and cached for its expiry`() = runTest {
        val requests = mutableListOf<Pair<String, String?>>()
        val bodies = mutableListOf<ByteArray>()
        val engine = MockEngine { request ->
            requests += "${request.method.value} ${request.url}" to (request.headers["X-Plex-Token"] ?: request.body.contentType?.toString())
            if (request.method == HttpMethod.Get) {
                respond(byteArrayOf(1, 2, 3), HttpStatusCode.OK)
            } else {
                bodies += (request.body as OutgoingContent.ByteArrayContent).bytes()
                respond("""{"url":"/posters/abc.jpg","expiresIn":600}""", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))
            }
        }
        val http = HttpClient(engine) { install(HttpTimeout) }
        val backend = object : FakeMediaBackend("srv") {
            override fun thumbnailUrl(path: String?, width: Int?, height: Int?, cover: Boolean): String =
                if (path.orEmpty().startsWith("https://")) path.orEmpty() else "https://server.example${path.orEmpty()}"
        }.apply { streamHeaders = mapOf("X-Plex-Token" to "tok") }
        val posters = DiscordPosters(http, Clock.System)
        val movie = item(MediaKind.MOVIE) { copy(thumbPath = "/thumb") }
        assertEquals("https://ice.plezy.app/posters/abc.jpg", posters.posterFor(movie, backend))
        assertEquals("https://ice.plezy.app/posters/abc.jpg", posters.posterFor(movie, backend))
        posters.posterFor(item(MediaKind.MOVIE) { copy(thumbPath = "https://image.example/poster.jpg") }, backend)
        assertEquals(
            listOf<Pair<String, String?>>(
                "GET https://server.example/thumb" to "tok",
                "POST https://ice.plezy.app/posters" to "application/octet-stream",
                "GET https://image.example/poster.jpg" to null,
                "POST https://ice.plezy.app/posters" to "application/octet-stream",
            ),
            requests,
        )
        assertEquals(listOf(1, 2, 3), bodies.first().map { it.toInt() })
    }

    @Test
    fun `a movie without a year shows its title and other kinds show their title without a state`() {
        val movie = DiscordActivity.of(playing(item(MediaKind.MOVIE, "Heat") { copy(studio = "Warner Bros.") }), now)!!
        assertEquals("Heat", movie.details)
        val clip = DiscordActivity.of(playing(item(MediaKind.CLIP, "Trailer") { copy(year = 2020, grandparentTitle = "Show") }), now)!!
        assertEquals("Trailer", clip.details)
        assertNull(clip.state)
        assertEquals("Show", clip.imageText)
    }

    @Test
    fun `a track without its own artist shows the album artist`() {
        val track = item(MediaKind.TRACK, "Angel") { copy(grandparentTitle = "Massive Attack", parentTitle = "Mezzanine") }
        assertEquals("Massive Attack", DiscordActivity.of(playing(track), now)!!.state)
    }

    @Test
    fun `the tooltip falls back from album to artist to title and from series to title`() {
        val withAlbum = item(MediaKind.TRACK, "Angel") { copy(parentTitle = "Mezzanine", originalTitle = "Massive Attack") }
        assertEquals("Mezzanine", DiscordActivity.of(playing(withAlbum), now)!!.imageText)
        assertEquals("Massive Attack", DiscordActivity.of(playing(withAlbum.copy(parentTitle = null)), now)!!.imageText)
        assertEquals("Angel", DiscordActivity.of(playing(withAlbum.copy(parentTitle = null, originalTitle = null)), now)!!.imageText)
        val episode = item(MediaKind.EPISODE) { copy(grandparentTitle = "Severance") }
        assertEquals("Severance", DiscordActivity.of(playing(episode), now)!!.imageText)
        assertEquals("Pilot", DiscordActivity.of(playing(episode.copy(grandparentTitle = null)), now)!!.imageText)
    }

    @Test
    fun `the status line names the details and the tooltip rides with the image`() {
        val activity = DiscordActivity("Heat (1995)", null, "https://ice.plezy.app/posters/a.jpg", "Heat", 1, 2)
        val sent = Json.parseToJsonElement(DiscordRpc.setActivity(activity, 1, "n")).jsonObject.getValue("args").jsonObject.getValue("activity").jsonObject
        assertEquals(2, sent.getValue("status_display_type").jsonPrimitive.int)
        assertEquals(3, sent.getValue("type").jsonPrimitive.int)
        assertEquals("Heat", sent.getValue("assets").jsonObject.getValue("large_text").jsonPrimitive.content)
    }

    @Test
    fun `a jump of just over five seconds is a seek`() {
        val shown = DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 60.0), now)!!
        assertTrue(DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 65.0), now)!!.sameAs(shown))
        assertFalse(DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 66.0), now)!!.sameAs(shown))
        assertFalse(DiscordActivity.of(playing(item(MediaKind.MOVIE), position = 54.0), now)!!.sameAs(shown))
    }

    @Test
    fun `an episode without a series poster uses its own thumb and other kinds their own poster`() {
        val episode = item(MediaKind.EPISODE) { copy(thumbPath = "/ep") }
        assertEquals("/ep", DiscordPosters.thumbPath(episode))
        val movie = item(MediaKind.MOVIE) { copy(thumbPath = "/poster") }
        assertEquals("/poster", DiscordPosters.thumbPath(movie))
        assertEquals(512 to 768, DiscordPosters.size(movie))
    }

    @Test
    fun `an empty or oversized image is never uploaded and each request has its timeout`() = runTest {
        var image = ByteArray(0)
        val requests = mutableListOf<Pair<String, Long?>>()
        val engine = MockEngine { request ->
            requests += request.method.value to request.getCapabilityOrNull(HttpTimeoutCapability)?.requestTimeoutMillis
            if (request.method == HttpMethod.Get) {
                respond(image, HttpStatusCode.OK)
            } else {
                respond("""{"url":"/posters/abc.jpg","expiresIn":600}""", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))
            }
        }
        val posters = DiscordPosters(HttpClient(engine) { install(HttpTimeout) }, Clock.System)
        val backend = FakeMediaBackend("srv")
        assertNull(posters.posterFor(item(MediaKind.MOVIE) { copy(thumbPath = "/empty") }, backend))
        image = ByteArray(DiscordPosters.MAX_BYTES + 1)
        assertNull(posters.posterFor(item(MediaKind.MOVIE) { copy(thumbPath = "/huge") }, backend))
        assertEquals(listOf<Pair<String, Long?>>("GET" to 10_000, "GET" to 10_000), requests, "nothing posted")
        image = ByteArray(DiscordPosters.MAX_BYTES)
        assertEquals("https://ice.plezy.app/posters/abc.jpg", posters.posterFor(item(MediaKind.MOVIE) { copy(thumbPath = "/max") }, backend))
        assertEquals(listOf<Pair<String, Long?>>("GET" to 10_000, "POST" to 15_000), requests.drop(2))
    }

    @Test
    fun `poster URLs are cached per server and path until they expire and a non positive expiry is not cached`() = runTest {
        var nowAt = Instant.fromEpochMilliseconds(now)
        val clock = object : Clock {
            override fun now() = nowAt
        }
        var expiresIn = "600"
        val fetched = mutableListOf<String>()
        val engine = MockEngine { request ->
            if (request.method == HttpMethod.Get) {
                fetched += request.url.encodedPath
                respond(byteArrayOf(1), HttpStatusCode.OK)
            } else {
                respond("""{"url":"/posters/${fetched.size}.jpg","expiresIn":$expiresIn}""", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))
            }
        }
        val posters = DiscordPosters(HttpClient(engine) { install(HttpTimeout) }, clock)
        val movie = item(MediaKind.MOVIE) { copy(thumbPath = "https://server.example/thumb") }
        val backend = FakeMediaBackend("srv")
        assertEquals("https://ice.plezy.app/posters/1.jpg", posters.posterFor(movie, backend))
        nowAt += 599.seconds
        assertEquals("https://ice.plezy.app/posters/1.jpg", posters.posterFor(movie, backend), "a hit within the expiry")
        assertEquals("https://ice.plezy.app/posters/2.jpg", posters.posterFor(movie.copy(serverId = "other"), backend), "another server's same path")
        nowAt += 1.seconds
        assertEquals("https://ice.plezy.app/posters/3.jpg", posters.posterFor(movie, backend), "evicted at its expiry")

        expiresIn = "0"
        val episode = item(MediaKind.EPISODE) { copy(thumbPath = "https://server.example/ep") }
        assertEquals("https://ice.plezy.app/posters/4.jpg", posters.posterFor(episode, backend))
        assertEquals("https://ice.plezy.app/posters/5.jpg", posters.posterFor(episode, backend), "not cached")

        expiresIn = "null"
        val track = item(MediaKind.TRACK) { copy(thumbPath = "https://server.example/album") }
        assertEquals("https://ice.plezy.app/posters/6.jpg", posters.posterFor(track, backend))
        nowAt += 3.hours - 1.seconds
        assertEquals("https://ice.plezy.app/posters/6.jpg", posters.posterFor(track, backend), "a missing expiry keeps it three hours")
        nowAt += 1.seconds
        assertEquals("https://ice.plezy.app/posters/7.jpg", posters.posterFor(track, backend))
    }
}
