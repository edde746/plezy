package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.MimeTypes
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AudioOutputPolicyTest {

  @Test
  fun passthroughDisabledBlocksBitstreamFormats() {
    val bitstreamFormats = listOf(
      "audio/ac3",
      "audio/eac3",
      "audio/eac3-joc",
      "audio/ac4",
      "audio/vnd.dts",
      "audio/vnd.dts.hd",
      "audio/vnd.dts.uhd",
      MimeTypes.AUDIO_TRUEHD
    )

    for (mimeType in bitstreamFormats) {
      assertTrue(mimeType, shouldBlockDirectOutputForPassthrough(mimeType, audioPassthroughEnabled = false))
    }
  }

  @Test
  fun passthroughEnabledAllowsBitstreamFormats() {
    assertFalse(shouldBlockDirectOutputForPassthrough("audio/ac3", audioPassthroughEnabled = true))
    assertFalse(shouldBlockDirectOutputForPassthrough(MimeTypes.AUDIO_TRUEHD, audioPassthroughEnabled = true))
  }

  @Test
  fun passthroughDisabledLeavesDecodedFormatsAvailable() {
    val decodedFormats = listOf(
      MimeTypes.AUDIO_AAC,
      MimeTypes.AUDIO_OPUS,
      MimeTypes.AUDIO_RAW,
      MimeTypes.AUDIO_FLAC
    )

    for (mimeType in decodedFormats) {
      assertFalse(mimeType, shouldBlockDirectOutputForPassthrough(mimeType, audioPassthroughEnabled = false))
    }
  }

  @Test
  fun spdifListNamesEveryCodecAnUnrestrictedRouteAdvertises() {
    assertEquals("ac3,eac3,dts,dts-hd,truehd", mpvSpdifCodecs { true })
  }

  @Test
  fun spdifListDropsCodecsTheRouteCannotBitstream() {
    // Google TV Streamer over HDMI to a Dolby-only sink: AC3/E-AC3 bitstream,
    // TrueHD and DTS do not (#1703).
    val dolbyOnlyRoute = setOf(C.ENCODING_AC3, C.ENCODING_E_AC3)

    assertEquals("ac3,eac3", mpvSpdifCodecs { encoding -> encoding in dolbyOnlyRoute })
  }

  @Test
  fun spdifListOmitsDtsHdOnDtsCoreOnlyRoutes() {
    // media3's passthrough probe would answer yes for DTS-HD here by downgrading to the
    // DTS core. mpv reads `dts,dts-hd` as `dts-hd` alone and force-passes DTS-HD MA, so
    // accepting that downgrade would break DTS too.
    val dtsCoreOnlyRoute = setOf(C.ENCODING_DTS)

    assertEquals("dts", mpvSpdifCodecs { encoding -> encoding in dtsCoreOnlyRoute })
  }

  @Test
  fun spdifListKeepsDtsHdWhenTheRouteAdvertisesIt() {
    val dtsHdRoute = setOf(C.ENCODING_DTS, C.ENCODING_DTS_HD)

    assertEquals("dts,dts-hd", mpvSpdifCodecs { encoding -> encoding in dtsHdRoute })
  }

  @Test
  fun spdifListIsEmptyForPcmOnlyRoutes() {
    assertEquals("", mpvSpdifCodecs { false })
  }
}
