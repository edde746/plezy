package com.edde746.plezy.app

import com.edde746.plezy.cast.CastCommand
import com.edde746.plezy.cast.CastItem
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.jellyfin.FakeResponse
import com.edde746.plezy.jellyfin.JellyfinTestServer
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.playback.session.track
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.secrets.MemorySecretStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.fail

/** A video cast to this device starts on the tracks the sender's account preferences pick, as it would on the sender. */
class AppCastTracksTest {
    private val server = JellyfinTestServer(
        handler = { request ->
            when {
                request.path == "/Users/user-1" || request.path == "/Users/Me" -> FakeResponse(200, USER)
                request.path == "/DisplayPreferences/usersettings" -> FakeResponse(200, """{"CustomPrefs":{}}""")
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
    fun `a cast video starts on the subtitle the account prefers as a local play does`() = runTest {
        val app = appWithJellyfin()

        app.play(PlayRequest.Item(ServerId("machine-1"), "movie-1", item = movie))
        val local = openedSubtitle(app, 1)
        app.navigator.pop(Route.Player)
        runCurrent()

        val handedOver = app.servers.handedOverMediaBrowserClient(server.connection())
        app.playbacks.play(PlayRequest.Item(ServerId("machine-1"), "movie-1", item = movie), handedOver)
        val cast = openedSubtitle(app, 2)

        assertEquals(2L, local, "the account's forced English, not the file's default French")
        assertEquals(local, cast)
    }

    @Test
    fun `audio subtitle and volume picks from a sender reach the cast player and come back as what it plays`() = runTest {
        val app = appWithJellyfin()
        val playback = app.castReceiver.playback
        val handedOver = app.servers.handedOverMediaBrowserClient(server.connection())
        val load = launch { playback.load(CastItem.Video("movie-1"), handedOver, "Phone") }
        runCurrent()
        val engine = platform.playbacks[0].scripted
        engine.fileTracks = FILE_TRACKS
        engine.open(600.0)
        engine.play(1.0)
        runCurrent()
        load.join()

        val audio = playback.state.value!!.audio
        val french = audio.firstOrNull { !it.selected } ?: fail("one audio track to pick: $audio")
        playback.control(CastCommand.Audio(french.key))
        runCurrent()
        assertEquals(TrackKind.AUDIO to 2L, engine.selections.lastOrNull { it.first == TrackKind.AUDIO }, "$audio")
        assertEquals(french.key, playback.state.value!!.audio.singleOrNull { it.selected }?.key, "${playback.state.value!!.audio}")

        val subtitles = playback.state.value!!.subtitles
        val off = subtitles.firstOrNull { it.key.endsWith("off") } ?: fail("no Off to pick: $subtitles")
        playback.control(CastCommand.Subtitle(off.key))
        runCurrent()
        assertEquals(TrackKind.SUBTITLE to null, engine.selections.lastOrNull { it.first == TrackKind.SUBTITLE }, "$subtitles")
        assertEquals(off.key, playback.state.value!!.subtitles.singleOrNull { it.selected }?.key, "${playback.state.value!!.subtitles}")

        playback.control(CastCommand.Volume(40))
        runCurrent()
        assertEquals(40, playback.state.value!!.volume)
    }

    /** Opens the [playback]th player's file and answers the subtitle it selected. */
    private fun TestScope.openedSubtitle(app: AppSession, playback: Int): Long? {
        runCurrent()
        val engine = platform.playbacks[playback - 1].scripted
        engine.fileTracks = FILE_TRACKS
        engine.open(600.0)
        runCurrent()
        return engine.selections.last { it.first == TrackKind.SUBTITLE }.second
    }

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
        app.accountPreferences.activePreferences.first { it != null }
        return app
    }

    private companion object {
        const val USER = """{"Id":"user-1","Name":"edde","Policy":{"IsAdministrator":false},""" +
            """"Configuration":{"SubtitleMode":"OnlyForced","SubtitleLanguagePreference":"eng","AudioLanguagePreference":"eng"}}"""
        const val SOURCES = """[{"Id":"src-1","Container":"mkv","SupportsDirectPlay":true,"MediaStreams":[""" +
            """{"Index":0,"Type":"Video"},{"Index":1,"Type":"Audio","Language":"eng","IsDefault":true},""" +
            """{"Index":2,"Type":"Subtitle","Language":"fre","IsDefault":true,"Codec":"subrip"},""" +
            """{"Index":3,"Type":"Subtitle","Language":"eng","IsForced":true,"Codec":"subrip"}]}]"""
        const val MOVIE = """{"Id":"movie-1","Type":"Movie","Name":"Heat","ProductionYear":1995,"MediaSources":$SOURCES}"""
        val FILE_TRACKS = listOf(
            track(1, TrackKind.AUDIO, "en", "English", selected = true, default = true),
            track(2, TrackKind.AUDIO, "fr", "Français"),
            track(1, TrackKind.SUBTITLE, "fr", "Français", default = true, codec = "subrip"),
            track(2, TrackKind.SUBTITLE, "en", "English (forced)", forced = true, codec = "subrip"),
        )
    }
}
