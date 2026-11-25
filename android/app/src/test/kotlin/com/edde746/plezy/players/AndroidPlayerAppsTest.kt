package com.edde746.plezy.players

import android.app.Activity
import android.content.Intent
import android.net.Uri
import com.edde746.plezy.playback.players.ExternalPlaybackResult
import com.edde746.plezy.players.AndroidPlayerApps.Source
import com.edde746.plezy.players.AndroidPlayerApps.Subtitle
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/** The intent players are handed and the result they answer with, as Android's own classes carry them. */
@RunWith(RobolectricTestRunner::class)
class AndroidPlayerAppsTest {
    private val stream = Source(Uri.parse("http://plex:32400/library/parts/9808/1775431760/file.mkv?X-Plex-Token=tok"), grantRead = false, fileName = "file.mkv")

    @Test
    fun mxPlayersResultKeepsPositionDurationAndCompletion() {
        val data = Intent("com.mxtech.intent.result.VIEW")
            .putExtra("position", 123)
            .putExtra("duration", "456")
            .putExtra("end_by", "playback_completion")
        assertEquals(ExternalPlaybackResult(123, 456, completed = true), AndroidPlayerApps.readResult(Activity.RESULT_OK, data))
    }

    @Test
    fun vlcsLongExtrasAreRead() {
        val data = Intent("org.videolan.vlc.player.result").putExtra("extra_position", 61_000L).putExtra("extra_duration", 120_000L)
        assertEquals(ExternalPlaybackResult(61_000, 120_000), AndroidPlayerApps.readResult(Activity.RESULT_OK, data))
        assertEquals(ExternalPlaybackResult(null, null), AndroidPlayerApps.readResult(Activity.RESULT_CANCELED, null))
    }

    @Test
    fun aFreshLaunchTellsThePlayerToStartFromTheBeginning() {
        val intent = AndroidPlayerApps.buildIntent(stream, startPositionMs = 0, title = "Episode")
        assertEquals(Intent.ACTION_VIEW, intent.action)
        assertEquals("video/*", intent.type)
        assertTrue(intent.getBooleanExtra("from_start", false))
        assertFalse(intent.hasExtra("position"))
        assertFalse(intent.hasExtra("startfrom"))
        assertTrue(intent.getBooleanExtra("return_result", false))
        assertEquals("Episode", intent.getStringExtra("title"))
        assertEquals("file.mkv", intent.getStringExtra("filename"))
    }

    @Test
    fun aResumeLaunchPassesThePositionAndTurnsFromStartOff() {
        val intent = AndroidPlayerApps.buildIntent(stream, startPositionMs = 90_000, title = null)
        assertFalse(intent.getBooleanExtra("from_start", true))
        assertEquals(90_000, intent.getIntExtra("position", -1))
        assertEquals(90_000, intent.getIntExtra("startfrom", -1))
    }

    @Test
    @Suppress("DEPRECATION")
    fun streamedSubtitlesReachThePlayerWithOnlyTheSelectedTrackEnabled() {
        val video = Source(Uri.parse("https://jf.example/Videos/item/stream.mkv?Static=true&api_key=tok"), grantRead = false, fileName = "stream.mkv")
        val swedish = Uri.parse("https://jf.example/Videos/item/src/Subtitles/3/Stream.srt?api_key=tok")
        val english = Uri.parse("https://jf.example/Videos/item/src/Subtitles/4/Stream.ass?api_key=tok")
        val subtitles = listOf(
            Subtitle(Source(swedish, grantRead = false, fileName = "Stream.srt"), name = null, enabled = false),
            Subtitle(Source(english, grantRead = false, fileName = "Stream.ass"), name = "English - ASS", enabled = true),
        )

        val intent = AndroidPlayerApps.buildIntent(video, startPositionMs = 0, title = null, subtitles = subtitles)

        // MX Player, mpv-android and Just Player read these as Parcelable[] of Uri; a String[] is silently ignored.
        assertArrayEquals(arrayOf(swedish, english), intent.getParcelableArrayExtra("subs"))
        assertArrayEquals(arrayOf(english), intent.getParcelableArrayExtra("subs.enable"))
        assertArrayEquals(arrayOf("Stream.srt", "English - ASS"), intent.getStringArrayExtra("subs.name"))
        assertArrayEquals(arrayOf("Stream.srt", "Stream.ass"), intent.getStringArrayExtra("subs.filename"))
        assertNull(intent.clipData)
        assertEquals(0, intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    @Test
    fun downloadedSubtitlesAreGrantedAlongsideTheVideo() {
        val video = Source(Uri.parse("content://com.edde746.plezy.fileprovider/app_files/downloads/Movie.mkv"), grantRead = true, fileName = "Movie.mkv")
        val first = Uri.parse("content://com.edde746.plezy.fileprovider/app_files/downloads/Movie_subs/401.srt")
        val second = Uri.parse("content://com.edde746.plezy.fileprovider/app_files/downloads/Movie_subs/402.srt")
        val subtitles = listOf(first, second).map { Subtitle(Source(it, grantRead = true, fileName = it.lastPathSegment), name = null, enabled = false) }

        val intent = AndroidPlayerApps.buildIntent(video, startPositionMs = 0, title = null, subtitles = subtitles)

        // The read grant only covers the data URI and the ClipData, never extras.
        assertTrue(intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0)
        val clip = intent.clipData!!
        assertEquals(listOf(first, second), (0 until clip.itemCount).map { clip.getItemAt(it).uri })
    }
}
