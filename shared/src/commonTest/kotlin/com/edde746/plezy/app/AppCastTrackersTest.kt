package com.edde746.plezy.app

import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.jellyfin.FakeResponse
import com.edde746.plezy.jellyfin.JellyfinTestServer
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** A video cast to this device plays as the sender's user: this device's own trackers never hear it. */
class AppCastTrackersTest {
    private val server = JellyfinTestServer(
        handler = { request ->
            when {
                request.url.host == TRAKT -> FakeResponse(201, "{}")
                request.path == "/Users/user-1" || request.path == "/Users/Me" ->
                    FakeResponse(200, """{"Id":"user-1","Name":"edde","Policy":{"IsAdministrator":false}}""")
                request.path == "/Users/user-1/Views" ->
                    FakeResponse(200, """{"Items":[{"Id":"lib-movies","Name":"Movies","CollectionType":"movies","Type":"CollectionFolder"}]}""")
                request.path == "/System/Info/Public" -> FakeResponse(200, """{"Id":"machine-1","ServerName":"Jellyfin","Version":"10.11.0"}""")
                request.path == "/Users/user-1/Items/movie-1" -> FakeResponse(200, MOVIE)
                request.path == "/Items/movie-1/PlaybackInfo" -> FakeResponse(200, """{"PlaySessionId":"play-1","MediaSources":$SOURCES}""")
                request.path.startsWith("/Sessions/Playing") -> FakeResponse(204, "")
                else -> FakeResponse(404)
            }
        },
    )

    private val platform = FakeAppPlatform()
    private val movie = MediaItem("movie-1", BackendKind.JELLYFIN, MediaKind.MOVIE, title = "Heat", serverId = "machine-1", durationMs = 600_000)

    @Test
    fun `a played video reaches the trackers and a cast one never does`() = runTest {
        val app = appWithJellyfinAndTrakt()

        // Played here: Trakt hears it start.
        app.play(PlayRequest.Item(ServerId("machine-1"), "movie-1", item = movie))
        playFor(app, 1)
        assertTrue(traktRequests().isNotEmpty(), "${server.requests.map { "${it.url.host}${it.path}" }}")
        app.navigator.pop(Route.Player)
        playFor(app, 0)
        server.requests.clear()

        // Cast here, on the access the sender handed over: its server hears it, Trakt doesn't.
        val handedOver = app.servers.handedOverMediaBrowserClient(server.connection())
        app.playbacks.play(PlayRequest.Item(ServerId("machine-1"), "movie-1", item = movie), handedOver)
        playFor(app, 2)
        assertTrue(server.requests.any { it.path == "/Sessions/Playing" }, "${server.requests.map { it.path }}")
        app.navigator.pop(Route.Player)
        playFor(app, 0)
        assertEquals(emptyList(), traktRequests())
    }

    private fun traktRequests() = server.requests.filter { it.url.host == TRAKT }.map { it.path }

    /** Opens and plays the newest player's video, then lets the reports and the trackers run. */
    private fun TestScope.playFor(app: AppSession, playback: Int) {
        runCurrent()
        if (playback > 0) {
            val engine = platform.playbacks[playback - 1].scripted
            engine.open(600.0)
            engine.play(120.0)
        }
        runCurrent()
        advanceTimeBy(30.seconds)
        runCurrent()
    }

    /** The app with [server]'s Jellyfin connection bound to the active profile, which Trakt is connected to. */
    private suspend fun TestScope.appWithJellyfinAndTrakt(): AppSession {
        val data = testData()
        val secrets = MemorySecretStore()
        val connection = server.connection()
        ConnectionStore(data, secrets).upsert(StoredConnection(connection.id, connection.kind, connection.toConfigJson(), connection.createdAt))
        data.profiles.upsert(LocalProfile(id = "profile-1", displayName = "Me", createdAt = 0))
        ProfileConnectionRegistry(data, secrets).upsert(
            ProfileConnection(profileId = "profile-1", connectionId = connection.id, userIdentifier = "user-1"),
            makeDefault = true,
        )
        ProfileIdentity(data).setActiveProfileId("profile-1")
        val graph = testGraph(data, http = server.http, secrets = secrets)
        val app = AppSession(graph, platform)
        app.servers.libraries.state.first { it.hasLoaded }
        graph.trackers.accounts.connect(
            "profile-1",
            TrackerService.TRAKT,
            TrackerSession(accessToken = "trakt-token", refreshToken = "refresh", expiresAt = Long.MAX_VALUE / 2, username = "me", createdAt = 0),
        )
        return app
    }

    private companion object {
        const val TRAKT = "api.trakt.tv"
        const val SOURCES = """[{"Id":"src-1","Container":"mkv","SupportsDirectPlay":true,"MediaStreams":[{"Index":0,"Type":"Video"}]}]"""
        const val MOVIE = """{"Id":"movie-1","Type":"Movie","Name":"Heat","ProductionYear":1995,""" +
            """"ProviderIds":{"Imdb":"tt0113277","Tmdb":"949"},"MediaSources":$SOURCES}"""
    }
}
