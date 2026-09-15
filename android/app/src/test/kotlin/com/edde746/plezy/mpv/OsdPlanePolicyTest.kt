package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class OsdPlanePolicyTest {
  @Test
  fun `full resolution leaves the plane tracking its view`() {
    assertNull(OsdPlanePolicy.fixedSizeFor(1920, 1080, 1f))
  }

  @Test
  fun `fractions shrink both dimensions by the same scale`() {
    assertEquals(OsdPlanePolicy.Size(1440, 810), OsdPlanePolicy.fixedSizeFor(1920, 1080, 0.75f))
    assertEquals(OsdPlanePolicy.Size(960, 540), OsdPlanePolicy.fixedSizeFor(1920, 1080, 0.5f))
    assertEquals(OsdPlanePolicy.Size(640, 360), OsdPlanePolicy.fixedSizeFor(1920, 1080, 1f / 3f))
  }

  @Test
  fun `odd results round down to even`() {
    // 1/3 of 1000 is 333.3: rounds to 333, then to the even 332.
    assertEquals(OsdPlanePolicy.Size(332, 250), OsdPlanePolicy.fixedSizeFor(1000, 750, 1f / 3f))
  }

  @Test
  fun `unlaid-out views and nonsense scales are ignored`() {
    assertNull(OsdPlanePolicy.fixedSizeFor(0, 0, 0.5f))
    assertNull(OsdPlanePolicy.fixedSizeFor(1920, 1080, 0f))
    assertNull(OsdPlanePolicy.fixedSizeFor(1920, 1080, 1.5f))
  }
}
