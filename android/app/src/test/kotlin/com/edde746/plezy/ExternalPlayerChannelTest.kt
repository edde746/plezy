package com.edde746.plezy

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ExternalPlayerChannelTest {

  @Test
  fun mxPlayerResultPreservesPositionDurationAndCompletion() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val channel = ExternalPlayerChannel(activity)
    val data = Intent("com.mxtech.intent.result.VIEW")
      .putExtra("position", 123)
      .putExtra("duration", "456")
      .putExtra("end_by", "playback_completion")

    val result = channel.buildResult(Activity.RESULT_OK, data)

    assertEquals(123L, result["positionMs"])
    assertEquals(456L, result["durationMs"])
    assertEquals(true, result["playbackCompleted"])
    assertEquals(false, result["playbackError"])
  }

  @Test
  fun freshLaunchTellsPlayerToStartFromBeginning() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val channel = ExternalPlayerChannel(activity)
    val source = ExternalPlayerChannel.Source(
      Uri.parse("http://plex:32400/library/parts/9808/1775431760/file.mkv?X-Plex-Token=tok"),
      grantRead = false,
      fileName = "file.mkv"
    )

    val intent = channel.buildIntent(source, packageName = null, startPositionMs = 0L, title = "Episode")

    assertTrue(intent.getBooleanExtra("from_start", false))
    assertFalse(intent.hasExtra("position"))
    assertFalse(intent.hasExtra("startfrom"))
  }

  @Test
  fun resumeLaunchPassesPositionAndDisablesFromStart() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val channel = ExternalPlayerChannel(activity)
    val source = ExternalPlayerChannel.Source(
      Uri.parse("http://plex:32400/library/parts/9808/1775431760/file.mkv?X-Plex-Token=tok"),
      grantRead = false,
      fileName = "file.mkv"
    )

    val intent = channel.buildIntent(source, packageName = null, startPositionMs = 90_000L, title = null)

    assertFalse(intent.getBooleanExtra("from_start", true))
    assertEquals(90_000, intent.getIntExtra("position", -1))
    assertEquals(90_000, intent.getIntExtra("startfrom", -1))
  }

  @Test
  @Suppress("DEPRECATION")
  fun streamedSubtitlesReachThePlayerWithOnlyTheSelectedTrackEnabled() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val channel = ExternalPlayerChannel(activity)
    val video = ExternalPlayerChannel.Source(
      Uri.parse("https://jf.example/Videos/item/stream.mkv?Static=true&api_key=tok"),
      grantRead = false,
      fileName = "stream.mkv"
    )
    val swedish = Uri.parse("https://jf.example/Videos/item/src/Subtitles/3/Stream.srt?api_key=tok")
    val english = Uri.parse("https://jf.example/Videos/item/src/Subtitles/4/Stream.ass?api_key=tok")
    val subtitles = listOf(
      ExternalPlayerChannel.Subtitle(
        ExternalPlayerChannel.Source(swedish, grantRead = false, fileName = "Stream.srt"),
        name = null,
        enabled = false
      ),
      ExternalPlayerChannel.Subtitle(
        ExternalPlayerChannel.Source(english, grantRead = false, fileName = "Stream.ass"),
        name = "English - ASS",
        enabled = true
      )
    )

    val intent = channel.buildIntent(video, "is.xyz.mpv", startPositionMs = 0L, title = null, subtitles = subtitles)

    // MX Player, mpv-android and Just Player all read these as Parcelable[]
    // of Uri; a String[] is silently ignored.
    assertArrayEquals(arrayOf(swedish, english), intent.getParcelableArrayExtra("subs"))
    assertArrayEquals(arrayOf(english), intent.getParcelableArrayExtra("subs.enable"))
    assertArrayEquals(arrayOf("Stream.srt", "English - ASS"), intent.getStringArrayExtra("subs.name"))
    assertArrayEquals(arrayOf("Stream.srt", "Stream.ass"), intent.getStringArrayExtra("subs.filename"))
    assertNull(intent.clipData)
    assertEquals(0, intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION)
  }

  @Test
  fun downloadedSubtitlesAreGrantedAlongsideTheVideo() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val channel = ExternalPlayerChannel(activity)
    val video = ExternalPlayerChannel.Source(
      Uri.parse("content://com.edde746.plezy.fileprovider/app_files/downloads/Movie.mkv"),
      grantRead = true,
      fileName = "Movie.mkv"
    )
    val first = Uri.parse("content://com.edde746.plezy.fileprovider/app_files/downloads/Movie_subs/401.srt")
    val second = Uri.parse("content://com.edde746.plezy.fileprovider/app_files/downloads/Movie_subs/402.srt")
    val subtitles = listOf(first, second).map {
      ExternalPlayerChannel.Subtitle(
        ExternalPlayerChannel.Source(it, grantRead = true, fileName = it.lastPathSegment),
        name = null,
        enabled = false
      )
    }

    val intent = channel.buildIntent(video, "is.xyz.mpv", startPositionMs = 0L, title = null, subtitles = subtitles)

    // The read grant only covers the data URI and ClipData, never extras.
    assertTrue(intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0)
    val clip = intent.clipData!!
    assertEquals(listOf(first, second), (0 until clip.itemCount).map { clip.getItemAt(it).uri })
  }

  @Test
  fun activityDestroyCompletesPendingChannelCall() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val channel = ExternalPlayerChannel(activity)
    val result = RecordingResult()
    channel.javaClass.getDeclaredField("pendingResult").apply {
      isAccessible = true
      set(channel, result)
    }

    channel.dispose()

    assertTrue(result.completed)
    assertEquals("ACTIVITY_DESTROYED", result.errorCode)
  }

  private class RecordingResult : MethodChannel.Result {
    var completed = false
    var errorCode: String? = null

    override fun success(result: Any?) {
      completed = true
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
      completed = true
      this.errorCode = errorCode
    }

    override fun notImplemented() {
      completed = true
    }
  }
}
