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

  @Test
  fun carrierIsNeverOfferedBelowApi29() {
    // No direct-playback oracle exists there, and getMinBufferSize alone is known to lie
    // (a Shield sizes the tuple, then the AudioTrack fails to initialise).
    assertFalse(
      iecCarrierSupported(
        sdkInt = 28,
        canSizeCarrierBuffer = { true },
        bitstreamSupported = { true },
        directPlaybackSupported = { true }
      )
    )
  }

  @Test
  fun carrierRequiresASizableBufferOnEveryTier() {
    for (sdkInt in intArrayOf(29, 30, 32, 33, 34)) {
      assertFalse(
        "api $sdkInt",
        iecCarrierSupported(
          sdkInt = sdkInt,
          canSizeCarrierBuffer = { false },
          bitstreamSupported = { true },
          directPlaybackSupported = { true }
        )
      )
    }
  }

  @Test
  fun carrierOnApi29To32FollowsTheDirectPlaybackProbe() {
    // Fire OS 8 (API 30) bitstreams TrueHD over this route; an API 33 gate force-decoded it (#1863).
    for (supported in booleanArrayOf(true, false)) {
      for (sdkInt in intArrayOf(29, 30, 32)) {
        assertEquals(
          "api $sdkInt supported=$supported",
          supported,
          iecCarrierSupported(
            sdkInt = sdkInt,
            canSizeCarrierBuffer = { true },
            bitstreamSupported = { throw AssertionError("getDirectPlaybackSupport does not exist below API 33") },
            directPlaybackSupported = { supported }
          )
        )
      }
    }
  }

  @Test
  fun carrierOnApi33UsesTheBitstreamProbe() {
    // getDirectPlaybackSupport distinguishes bitstream from offload-only; the coarser API 29
    // probe must not shadow it where the platform can answer precisely.
    for (supported in booleanArrayOf(true, false)) {
      assertEquals(
        "supported=$supported",
        supported,
        iecCarrierSupported(
          sdkInt = 33,
          canSizeCarrierBuffer = { true },
          bitstreamSupported = { supported },
          directPlaybackSupported = { throw AssertionError("API 29 probe must not be consulted on API 33+") }
        )
      )
    }
  }
}
