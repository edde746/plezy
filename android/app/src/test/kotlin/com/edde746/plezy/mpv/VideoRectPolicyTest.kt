package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class VideoRectPolicyTest {
  @Test
  fun `contain letterboxes wide content inside the container`() {
    // 2.39:1 content on a 16:9 container: full width, bars top and bottom.
    val size = VideoRectPolicy.sizeFor(1920, 1080, 2390, 1000)!!
    assertEquals(1920, size.width)
    assertEquals(803, size.height)
    assertTrue(size.height < 1080)
  }

  @Test
  fun `contain pillarboxes tall content inside the container`() {
    val size = VideoRectPolicy.sizeFor(1920, 1080, 1000, 2390)!!
    assertEquals(1080, size.height)
    assertTrue(size.width < 1920)
  }

  @Test
  fun `panscan 1 fills the container so the image is cropped, not letterboxed`() {
    // The regression this exists for: cover used to be a no-op on the plane.
    val size = VideoRectPolicy.sizeFor(1920, 1080, 2390, 1000, panscan = 1f)!!
    assertTrue("cover must reach the container height", size.height >= 1080)
    assertTrue("width must overflow and be clipped", size.width > 1920)
  }

  @Test
  fun `panscan interpolates between contain and cover`() {
    val contain = VideoRectPolicy.sizeFor(1920, 1080, 2390, 1000)!!
    val half = VideoRectPolicy.sizeFor(1920, 1080, 2390, 1000, panscan = 0.5f)!!
    val cover = VideoRectPolicy.sizeFor(1920, 1080, 2390, 1000, panscan = 1f)!!
    assertTrue(half.height > contain.height)
    assertTrue(half.height < cover.height)
  }

  @Test
  fun `video-zoom is a log2 factor on top of the fit`() {
    val base = VideoRectPolicy.sizeFor(1920, 1080, 1920, 1080)!!
    val doubled = VideoRectPolicy.sizeFor(1920, 1080, 1920, 1080, videoZoomLog2 = 1f)!!
    val halved = VideoRectPolicy.sizeFor(1920, 1080, 1920, 1080, videoZoomLog2 = -1f)!!
    assertEquals(base.width * 2, doubled.width)
    assertEquals(base.width / 2, halved.width)
  }

  @Test
  fun `cover fills a container whose aspect is wildly mismatched`() {
    // Scope content in a portrait container: cover/fit exceeds 4, which a
    // fit-relative clamp would truncate back into letterboxing.
    val size = VideoRectPolicy.sizeFor(1080, 2400, 2390, 1000, panscan = 1f)!!
    assertTrue("height must reach the container", size.height >= 2400)
  }

  @Test
  fun `an absurd zoom is bounded rather than allocating an unbounded surface`() {
    val fit = VideoRectPolicy.sizeFor(1920, 1080, 1920, 1080)!!
    val absurd = VideoRectPolicy.sizeFor(1920, 1080, 1920, 1080, videoZoomLog2 = 12f)!!
    assertEquals(fit.width * 4, absurd.width)
  }

  @Test
  fun `unknown dimensions yield no size instead of a degenerate one`() {
    assertNull(VideoRectPolicy.sizeFor(0, 1080, 1920, 1080))
    assertNull(VideoRectPolicy.sizeFor(1920, 1080, 0, 0))
    assertNull(VideoRectPolicy.sizeFor(1920, 0, 1920, 1080))
  }
}
