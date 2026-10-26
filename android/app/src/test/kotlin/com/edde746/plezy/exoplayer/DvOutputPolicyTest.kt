package com.edde746.plezy.exoplayer

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DvOutputPolicyTest {
  @Test
  fun `disabled DV hands every native DV profile to the converting player`() {
    for (profile in listOf(null, 5, 7, 8)) {
      assertTrue(DvOutputPolicy.needsClientConversion(profile, true, false, true, true, "auto"))
      assertFalse(DvOutputPolicy.needsClientConversion(profile, true, true, true, true, "auto"))
    }
  }

  @Test
  fun `P5 mislabeled HEVC still needs reshaping but compatible base layers stay native`() {
    assertTrue(DvOutputPolicy.needsClientConversion(5, false, false, true, true, "auto"))
    for (profile in listOf(null, 7, 8)) {
      assertFalse(DvOutputPolicy.needsClientConversion(profile, false, false, true, true, "auto"))
    }
  }

  @Test
  fun `explicit player tone mapping on SDR displays hands off HDR only`() {
    assertTrue(DvOutputPolicy.needsClientConversion(8, false, true, true, false, "player"))
    assertTrue(DvOutputPolicy.needsClientConversion(null, false, true, true, false, "player"))
    assertFalse(DvOutputPolicy.needsClientConversion(null, false, true, false, false, "player"))
    assertFalse(DvOutputPolicy.needsClientConversion(8, false, true, true, true, "player"))
    for (mode in listOf("auto", "device")) {
      assertFalse(DvOutputPolicy.needsClientConversion(8, false, true, true, false, mode))
    }
  }
}
