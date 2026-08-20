package com.edde746.plezy.exoplayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ExternalSubtitleIdsTest {

  @Test
  fun unmergedTagResolves() {
    assertTrue(ExternalSubtitleIds.isExternal("external_0"))
    assertEquals(0, ExternalSubtitleIds.indexOf("external_0"))
    assertEquals(7, ExternalSubtitleIds.indexOf("external_7"))
  }

  @Test
  fun mediaSourceFactoryMergePrefixResolves() {
    // DefaultMediaSourceFactory always merges side-loaded subtitles with the
    // primary source, so MergingMediaPeriod prefixes the period index.
    assertTrue(ExternalSubtitleIds.isExternal("1:external_0"))
    assertEquals(0, ExternalSubtitleIds.indexOf("1:external_0"))
    assertEquals(2, ExternalSubtitleIds.indexOf("3:external_2"))
  }

  @Test
  fun containerSidecarOuterMergePrefixResolves() {
    // The container-sidecar path wraps that merge in a second MergingMediaSource.
    assertTrue(ExternalSubtitleIds.isExternal("0:1:external_0"))
    assertEquals(0, ExternalSubtitleIds.indexOf("0:1:external_0"))
    assertEquals(4, ExternalSubtitleIds.indexOf("0:2:external_4"))
  }

  @Test
  fun embeddedAndUnknownIdsAreNotExternal() {
    assertFalse(ExternalSubtitleIds.isExternal(null))
    assertFalse(ExternalSubtitleIds.isExternal("1:2"))
    assertFalse(ExternalSubtitleIds.isExternal("0:"))
    // A container child whose own id merely ends in the tag's text.
    assertFalse(ExternalSubtitleIds.isExternal("1:not_external_0"))
    assertNull(ExternalSubtitleIds.indexOf("1:2"))
  }

  @Test
  fun malformedTagIsExternalWithoutAnIndex() {
    // Still a side-loaded track, but no usable URI lookup.
    assertTrue(ExternalSubtitleIds.isExternal("1:external_x"))
    assertNull(ExternalSubtitleIds.indexOf("1:external_x"))
  }

  @Test
  fun writtenIdRoundTrips() {
    for (index in 0..3) {
      val id = ExternalSubtitleIds.idFor(index)
      assertEquals(index, ExternalSubtitleIds.indexOf(id))
      assertEquals(index, ExternalSubtitleIds.indexOf("1:$id"))
      assertEquals(index, ExternalSubtitleIds.indexOf("0:1:$id"))
    }
  }
}
