package com.edde746.plezy.app

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.KeyModifiers
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.jellyfin.FakeResponse
import com.edde746.plezy.jellyfin.JellyfinTestServer
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.secrets.MemorySecretStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * A server item's playback in the running app: its server hears it stopped where it was as the app ends, and the
 * player's pause key while the file reopens is how the new file opens.
 */
class AppVideoReportsTest {
    private val server = JellyfinTestServer(
        handler = { request ->
            when {
                request.path == "/Users/user-1" || request.path == "/Users/Me" ->
                    FakeResponse(200, """{"Id":"user-1","Name":"edde","Policy":{"IsAdministrator":false}}""")
                request.path == "/Users/user-1/Views" ->
                    FakeResponse(200, """{"Items":[{"Id":"lib-movies","Name":"Movies","CollectionType":"movies","Type":"CollectionFolder"}]}""")
                request.path == "/Users/user-1/Items/movie-1" -> FakeResponse(200, """{"Id":"movie-1","Type":"Movie","Name":"Heat","MediaSources":$SOURCES}""")
                request.path == "/Items/movie-1/PlaybackInfo" -> FakeResponse(200, """{"PlaySessionId":"play-1","MediaSources":$SOURCES}""")
                request.path.startsWith("/Sessions/Playing") -> FakeResponse(204, "")
                else -> FakeResponse(404)
            }
        },
    )

    @Test
    fun `closing the app reports the playing video stopped where it was`() = runTest {
        val app = appWithJellyfin()
        val movie = MediaItem("movie-1", BackendKind.JELLYFIN, MediaKind.MOVIE, title = "Heat", serverId = "machine-1", durationMs = 600_000)
        app.play(PlayRequest.Item(ServerId("machine-1"), "movie-1", item = movie))
        runCurrent()
        val engine = platform.playbacks.single().scripted
        engine.open(600.0)
        engine.play(120.0)
        runCurrent()
        assertTrue(server.requests.any { it.path == "/Sessions/Playing" }, "${server.requests.map { it.path }}")

        app.close()
        runCurrent()
        val stopped = server.requests.filter { it.path == "/Sessions/Playing/Stopped" }
        assertEquals(1, stopped.size, "${server.requests.map { it.path }}")
        assertTrue("\"PositionTicks\":1200000000" in stopped.single().body, stopped.single().body)
        assertTrue(engine.released)
    }

    @Test
    fun `the pause key while the file reopens opens the new file paused`() = runTest {
        val app = appWithJellyfin()
        val movie = MediaItem("movie-1", BackendKind.JELLYFIN, MediaKind.MOVIE, title = "Heat", serverId = "machine-1", durationMs = 600_000)
        app.play(PlayRequest.Item(ServerId("machine-1"), "movie-1", item = movie))
        runCurrent()
        val engine = platform.playbacks.single().scripted
        engine.open(600.0)
        engine.play(120.0)
        runCurrent()
        val store = assertNotNull(app.player.value).store

        store.dispatch(PlayerCommand.SelectQuality(TranscodeQualityPreset.P720_2MBPS))
        store.onInput(InputEvent.KeyDown(InputKey.MEDIA_PAUSE, KeyModifiers.NONE))
        runCurrent()
        assertEquals(2, engine.loads.size)
        assertEquals(true, engine.pauses.last(), "paused as it reopened, the file opens paused: ${engine.pauses}")
        app.close()
    }

    private val platform = FakeAppPlatform()

    /** The app with [server]'s Jellyfin connection bound to the active profile, its libraries loaded. */
    private suspend fun TestScope.appWithJellyfin(): AppSession {
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
        val app = AppSession(testGraph(data, http = server.http, secrets = secrets), platform)
        app.servers.libraries.state.first { it.hasLoaded }
        return app
    }

    private companion object {
        const val SOURCES = """[{"Id":"src-1","Container":"mkv","SupportsDirectPlay":true,"MediaStreams":[{"Index":0,"Type":"Video"}]}]"""
    }
}
