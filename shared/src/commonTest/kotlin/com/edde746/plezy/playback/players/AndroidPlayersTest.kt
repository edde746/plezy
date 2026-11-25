package com.edde746.plezy.playback.players

import com.edde746.plezy.playback.players.AndroidExtra.Flag
import com.edde746.plezy.playback.players.AndroidExtra.IntValue
import com.edde746.plezy.playback.players.AndroidExtra.Text
import com.edde746.plezy.playback.players.AndroidExtra.Texts
import com.edde746.plezy.playback.players.AndroidExtra.Uris
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class AndroidPlayersTest {
    private val video = AndroidSource("http://plex:32400/library/parts/9808/1775431760/file.mkv?X-Plex-Token=tok", "file.mkv")

    @Test
    fun aFreshLaunchTellsThePlayerToStartFromTheBeginning() {
        val extras = AndroidPlayers.extras(video, 0, "Episode", emptyList())
        assertEquals(
            listOf(
                Flag("from_start", true), Flag("return_result", true), Flag("secure_uri", true), Flag("forceresume", false),
                Text("title", "Episode"), Text("forcename", "Episode"), Text("filename", "file.mkv"),
            ),
            extras,
        )
        assertFalse(extras.any { it.key == "position" || it.key == "startfrom" })
    }

    @Test
    fun aResumeLaunchPassesThePositionAndTurnsFromStartOff() {
        val extras = AndroidPlayers.extras(video, 90_000, null, emptyList())
        assertEquals(listOf(IntValue("position", 90_000), IntValue("startfrom", 90_000), Flag("from_start", false)), extras.take(3))
        assertFalse(extras.any { it.key == "title" || it.key == "forcename" })
    }

    @Test
    fun streamedSubtitlesReachThePlayerWithOnlyTheSelectedTrackEnabled() {
        val swedish = AndroidSource("https://jf.example/Videos/item/src/Subtitles/3/Stream.srt?api_key=tok", "Stream.srt")
        val english = AndroidSource("https://jf.example/Videos/item/src/Subtitles/4/Stream.ass?api_key=tok", "Stream.ass")
        val extras = AndroidPlayers.extras(
            video, 0, null,
            listOf(AndroidSubtitle(swedish, name = null, enabled = false), AndroidSubtitle(english, name = "English - ASS", enabled = true)),
        )
        assertEquals(
            listOf(
                Uris("subs", listOf(swedish.uri, english.uri)),
                Texts("subs.name", listOf("Stream.srt", "English - ASS")),
                Texts("subs.filename", listOf("Stream.srt", "Stream.ass")),
                Uris("subs.enable", listOf(english.uri)),
            ),
            extras.takeLast(4),
        )
    }

    @Test
    fun mxPlayersResultKeepsPositionDurationAndCompletion() {
        assertEquals(
            ExternalPlaybackResult(123, 456, completed = true),
            AndroidPlayers.result("com.mxtech.intent.result.VIEW", -1, mapOf("position" to 123, "duration" to "456", "end_by" to "playback_completion")),
        )
        assertEquals(
            ExternalPlaybackResult(5_000, 6_000),
            AndroidPlayers.result("com.mxtech.intent.result.VIEW", -1, mapOf("position" to 5_000, "duration" to 6_000, "end_by" to "user")),
        )
    }

    @Test
    fun vlcsResultIsReadFromItsOwnExtras() {
        assertEquals(
            ExternalPlaybackResult(12_345L, 99_000L),
            AndroidPlayers.result("org.videolan.vlc.player.result", -1, mapOf("extra_position" to 12_345L, "extra_duration" to 99_000L)),
        )
    }

    @Test
    fun mpvsSuccessWithoutAPositionIsAFinishedPlay() {
        val mpv = "is.xyz.mpv.MPVActivity.result"
        assertEquals(ExternalPlaybackResult(null, null, completed = true), AndroidPlayers.result(mpv, -1, emptyMap()))
        assertEquals(ExternalPlaybackResult(78_000, 90_021), AndroidPlayers.result(mpv, -1, mapOf("position" to 78_000, "duration" to 90_021)))
        assertEquals(ExternalPlaybackResult(null, null), AndroidPlayers.result(mpv, 0, emptyMap()))
    }

    @Test
    fun vimusResultCodeSaysWhetherItFinishedOrFailed() {
        assertEquals(ExternalPlaybackResult(null, null, completed = true), AndroidPlayers.result("net.gtvbox.videoplayer.result", 1, emptyMap()))
        assertEquals(ExternalPlaybackResult(null, null, error = true), AndroidPlayers.result("net.gtvbox.videoplayer.result", 4, emptyMap()))
        assertEquals(ExternalPlaybackResult(7_000, 8_000), AndroidPlayers.result("net.gtvbox.videoplayer.result", 0, mapOf("position" to 7_000, "duration" to 8_000)))
    }

    @Test
    fun aResultWithoutExtrasSaysNothing() {
        assertEquals(ExternalPlaybackResult(null, null), AndroidPlayers.result(null, 0, emptyMap()))
        assertEquals(ExternalPlaybackResult(null, null), AndroidPlayers.result(null, -1, mapOf("position" to "soon")))
    }
}
