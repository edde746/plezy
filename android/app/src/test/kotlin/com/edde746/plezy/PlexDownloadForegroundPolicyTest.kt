package com.edde746.plezy

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PlexDownloadForegroundPolicyTest {
  @Test
  fun plexProgressiveVideoDownloadRunsInForeground() {
    assertTrue(
      PlexDownloadForegroundPolicy.shouldForceForeground(
        "https://plex.example/video/:/transcode/universal/start.mkv?path=%2Flibrary%2Fmetadata%2F1"
      )
    )
  }

  @Test
  fun plexOriginalDownloadKeepsExistingBehavior() {
    assertFalse(
      PlexDownloadForegroundPolicy.shouldForceForeground(
        "https://plex.example/library/parts/123/456/file.mkv?download=1"
      )
    )
  }

  @Test
  fun jellyfinDownloadKeepsExistingBehavior() {
    assertFalse(
      PlexDownloadForegroundPolicy.shouldForceForeground(
        "https://jellyfin.example/Videos/123/stream.mkv?static=true"
      )
    )
  }

  @Test
  fun plexPlaybackTranscodeKeepsExistingBehavior() {
    assertFalse(
      PlexDownloadForegroundPolicy.shouldForceForeground(
        "https://plex.example/video/:/transcode/universal/start.m3u8?path=%2Flibrary%2Fmetadata%2F1"
      )
    )
  }

  @Test
  fun endpointTextInQueryDoesNotEnableForegroundMode() {
    assertFalse(
      PlexDownloadForegroundPolicy.shouldForceForeground(
        "https://example.test/file.mkv?next=/video/:/transcode/universal/start.mkv"
      )
    )
  }
}
