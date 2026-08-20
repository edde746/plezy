package com.edde746.plezy.exoplayer

import androidx.media3.common.MimeTypes
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PlaybackMimeTypeTest {

  @Test
  fun livePlaybackIsAlwaysHls() {
    assertEquals(MimeTypes.APPLICATION_M3U8, playbackMimeType(isLive = true))
  }

  @Test
  fun nonLivePlaybackUsesNormalSourceInference() {
    assertNull(playbackMimeType(isLive = false))
  }
}
