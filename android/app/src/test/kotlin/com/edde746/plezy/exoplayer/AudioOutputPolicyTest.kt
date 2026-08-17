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
  fun spdifListNamesOnlyCodecsMpvsStereoIecTrackCanCarry() {
    // eac3 (a 192kHz burst), truehd and dts-hd (192kHz/8ch) never survive mpv's audiotrack
    // AO, which opens every spdif format as a stereo IEC 61937 track at the mixer rate;
    // naming them strands playback on a dead audio output (#1991).
    assertEquals("ac3,dts", mpvSpdifCodecs { true })
  }

  @Test
  fun spdifListDropsCodecsTheRouteCannotBitstream() {
    // Google TV Streamer over HDMI to a Dolby-only sink: AC3 bitstreams, DTS does not (#1703).
    val dolbyOnlyRoute = setOf(C.ENCODING_AC3, C.ENCODING_E_AC3)

    assertEquals("ac3", mpvSpdifCodecs { encoding -> encoding in dolbyOnlyRoute })
  }

  @Test
  fun spdifListIsEmptyForPcmOnlyRoutes() {
    assertEquals("", mpvSpdifCodecs { false })
  }

  @Test
  fun iecRouteIsNeverOfferedBelowApi24() {
    // ENCODING_IEC61937 does not exist there.
    assertFalse(
      iecRouteSupported(
        sdkInt = 23,
        canSizeBuffer = { true },
        bitstreamSupported = { true },
        directPlaybackSupported = { true },
        hdmiRouteAdvertised = { true }
      )
    )
  }

  @Test
  fun iecRouteRequiresASizableBufferOnEveryTier() {
    for (sdkInt in intArrayOf(25, 28, 29, 30, 32, 33, 34)) {
      assertFalse(
        "api $sdkInt",
        iecRouteSupported(
          sdkInt = sdkInt,
          canSizeBuffer = { false },
          bitstreamSupported = { true },
          directPlaybackSupported = { true },
          hdmiRouteAdvertised = { true }
        )
      )
    }
  }

  @Test
  fun routeOnApi24To28FollowsTheHdmiAdvertisement() {
    // No runtime oracle exists below API 29; only an HDMI AudioDeviceInfo that explicitly
    // advertises the IEC tuple can vouch for it. Shield Experience 8.x is API 28, and a flat
    // `false` on this tier force-decoded TrueHD on routes that genuinely carry it (#1991).
    for (supported in booleanArrayOf(true, false)) {
      for (sdkInt in intArrayOf(25, 28)) {
        assertEquals(
          "api $sdkInt supported=$supported",
          supported,
          iecRouteSupported(
            sdkInt = sdkInt,
            canSizeBuffer = { true },
            bitstreamSupported = { throw AssertionError("getDirectPlaybackSupport does not exist below API 33") },
            directPlaybackSupported = { throw AssertionError("isDirectPlaybackSupported does not exist below API 29") },
            hdmiRouteAdvertised = { supported }
          )
        )
      }
    }
  }

  @Test
  fun routeOnApi29To32FollowsTheDirectPlaybackProbe() {
    // Fire OS 8 (API 30) bitstreams TrueHD over this route; an API 33 gate force-decoded it (#1863).
    for (supported in booleanArrayOf(true, false)) {
      for (sdkInt in intArrayOf(29, 30, 32)) {
        assertEquals(
          "api $sdkInt supported=$supported",
          supported,
          iecRouteSupported(
            sdkInt = sdkInt,
            canSizeBuffer = { true },
            bitstreamSupported = { throw AssertionError("getDirectPlaybackSupport does not exist below API 33") },
            directPlaybackSupported = { supported },
            hdmiRouteAdvertised = { throw AssertionError("the HDMI advertisement must not shadow the runtime probe") }
          )
        )
      }
    }
  }

  @Test
  fun routeOnApi33UsesTheBitstreamProbe() {
    // getDirectPlaybackSupport distinguishes bitstream from offload-only; the coarser API 29
    // probe must not shadow it where the platform can answer precisely.
    for (supported in booleanArrayOf(true, false)) {
      assertEquals(
        "supported=$supported",
        supported,
        iecRouteSupported(
          sdkInt = 33,
          canSizeBuffer = { true },
          bitstreamSupported = { supported },
          directPlaybackSupported = { throw AssertionError("API 29 probe must not be consulted on API 33+") },
          hdmiRouteAdvertised = { throw AssertionError("the HDMI advertisement must not shadow the runtime probe") }
        )
      )
    }
  }
}
