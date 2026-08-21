package com.edde746.plezy.exoplayer

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.exoplayer.ExoPlayer
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Pins the side-loaded subtitle identity contract against the real media3 the
 * app links, on a real device.
 *
 * `ExoPlayerCore` tags each `MediaItem.SubtitleConfiguration` with
 * [ExternalSubtitleIds.idFor] and recovers it from the `Format` the track
 * selector reports. media3 does not hand that id back verbatim:
 * `DefaultMediaSourceFactory` merges side-loaded subtitles with the primary
 * source, and `MergingMediaPeriod` prefixes every child format id with its
 * period index. Matching the raw id therefore classifies every sidecar as an
 * embedded track and drops its URI, which is what broke Plex sidecar
 * subtitles (#1713).
 *
 * A JVM test can only assert the parsing rule. This asserts that the rule
 * still matches what media3 actually emits.
 */
@RunWith(AndroidJUnit4::class)
class ExternalSubtitleIdentityTest {

  private companion object {
    const val TAG = "ExternalSubtitleIdentityTest"
    const val SRT = "1\n00:00:00,500 --> 00:00:05,000\nplezy sidecar identity\n\n"
  }

  @Test
  fun sideLoadedSubtitleIdSurvivesMedia3Merging() {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val context = instrumentation.targetContext
    val media = copyAsset(instrumentation.context, context, "ffmpeg/planar_5_1.m4a")
    val subtitle = File.createTempFile("sidecar-", ".srt", context.cacheDir).apply {
      writeText(SRT)
    }

    val thread = HandlerThread("plezy-sidecar-identity-test").apply { start() }
    val handler = Handler(thread.looper)
    val settled = CountDownLatch(1)
    val playerRef = AtomicReference<ExoPlayer>()
    val errorRef = AtomicReference<Throwable>()
    val textFormatId = AtomicReference<String>()
    val textGroupCount = AtomicReference(0)

    handler.post {
      try {
        val player = ExoPlayer.Builder(context).setLooper(thread.looper).build()
        playerRef.set(player)
        player.addListener(object : Player.Listener {
          override fun onPlayerError(error: PlaybackException) {
            errorRef.set(error)
            settled.countDown()
          }

          override fun onTracksChanged(tracks: Tracks) {
            val text = tracks.groups.filter { it.type == C.TRACK_TYPE_TEXT }
            if (text.isEmpty()) return
            textGroupCount.set(text.size)
            textFormatId.set(text.first().mediaTrackGroup.getFormat(0).id)
            settled.countDown()
          }
        })
        // setMediaItem (not setMediaSource) so DefaultMediaSourceFactory owns
        // the subtitle configuration exactly as ExoPlayerCore.open does.
        player.setMediaItem(
          MediaItem.Builder()
            .setUri(Uri.fromFile(media))
            .setSubtitleConfigurations(
              listOf(
                MediaItem.SubtitleConfiguration.Builder(Uri.fromFile(subtitle))
                  .setId(ExternalSubtitleIds.idFor(0))
                  .setLabel("Plezy sidecar")
                  .setLanguage("en")
                  .setMimeType(MimeTypes.APPLICATION_SUBRIP)
                  .setSelectionFlags(C.SELECTION_FLAG_DEFAULT)
                  .build()
              )
            )
            .build()
        )
        player.prepare()
      } catch (error: Throwable) {
        errorRef.set(error)
        settled.countDown()
      }
    }

    val finished = settled.await(30, TimeUnit.SECONDS)
    val released = CountDownLatch(1)
    handler.post {
      playerRef.get()?.release()
      thread.quitSafely()
      released.countDown()
    }
    val teardownFinished = released.await(5, TimeUnit.SECONDS)
    thread.join(5_000)
    media.delete()
    subtitle.delete()

    assertTrue("Player teardown timed out", teardownFinished)
    assertNull("Playback failed", errorRef.get())
    assertTrue("Timed out before any text track group was reported", finished)
    assertEquals("Expected exactly one side-loaded text group", 1, textGroupCount.get())

    val reportedId = textFormatId.get()
    Log.i(TAG, "media3 reported side-loaded subtitle Format.id=$reportedId")
    assertNotNull("Side-loaded subtitle reported a null Format.id", reportedId)

    // The contract ExoPlayerCore depends on.
    assertTrue(
      "Side-loaded subtitle was not recognised as external (Format.id=$reportedId)",
      ExternalSubtitleIds.isExternal(reportedId)
    )
    assertEquals(
      "Side-loaded subtitle did not resolve to its configuration index (Format.id=$reportedId)",
      0,
      ExternalSubtitleIds.indexOf(reportedId)
    )
  }

  private fun copyAsset(instrumentationContext: Context, targetContext: Context, asset: String): File {
    val output = File.createTempFile("sidecar-primary-", null, targetContext.cacheDir)
    instrumentationContext.assets.open(asset).use { input ->
      output.outputStream().use(input::copyTo)
    }
    return output
  }
}
