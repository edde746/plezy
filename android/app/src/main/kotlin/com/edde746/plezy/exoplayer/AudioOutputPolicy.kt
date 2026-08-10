package com.edde746.plezy.exoplayer

import android.content.Context
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.util.Log
import androidx.annotation.OptIn
import androidx.annotation.RequiresApi
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.audio.AudioCapabilities

private const val TAG = "AudioOutputPolicy"

internal fun isPassthroughAudioMimeType(mimeType: String): Boolean = when (mimeType) {
  "audio/ac3",
  "audio/eac3",
  "audio/eac3-joc",
  "audio/ac4",
  "audio/vnd.dts",
  "audio/vnd.dts.hd",
  "audio/vnd.dts.uhd",
  MimeTypes.AUDIO_TRUEHD -> true
  else -> false
}

internal fun shouldBlockDirectOutputForPassthrough(mimeType: String, audioPassthroughEnabled: Boolean): Boolean = !audioPassthroughEnabled && isPassthroughAudioMimeType(mimeType)

/**
 * Linear PCM output encodings, i.e. the sink decoded the bitstream instead of
 * passing it through. Mirrors the platform's `AudioFormat.ENCODING_PCM_*` set.
 */
internal fun isPcmEncoding(encoding: Int): Boolean = when (encoding) {
  AudioFormat.ENCODING_PCM_8BIT,
  AudioFormat.ENCODING_PCM_16BIT,
  AudioFormat.ENCODING_PCM_FLOAT,
  AudioFormat.ENCODING_PCM_24BIT_PACKED,
  AudioFormat.ENCODING_PCM_32BIT -> true
  else -> false
}

/**
 * mpv `audio-spdif` codec names and the exact platform encoding a route must
 * advertise to carry that bitstream.
 */
private val MPV_SPDIF_CODECS: List<Pair<String, Int>> = listOf(
  "ac3" to C.ENCODING_AC3,
  "eac3" to C.ENCODING_E_AC3,
  "dts" to C.ENCODING_DTS,
  "dts-hd" to C.ENCODING_DTS_HD,
  "truehd" to C.ENCODING_DOLBY_TRUEHD
)

/**
 * Builds an `audio-spdif` value naming only the codecs [supportsEncoding] advertises.
 *
 * mpv force-passes through every codec named here and has no decode fallback, so an
 * unsupported name leaves the file rendering video against a dead audio output (#1703).
 *
 * The gate is the exact encoding rather than media3's passthrough probe on purpose.
 * That probe answers DTS-HD by downgrading to the DTS core (and E-AC3 JOC to E-AC3)
 * for receivers that decode only the base layer, and it also rejects channel counts
 * above the route's PCM maximum, which does not apply to an IEC 61937 carrier. mpv
 * additionally treats `dts,dts-hd` as `dts-hd` alone, so accepting the downgrade would
 * name DTS-HD MA to a core-only receiver and lose DTS as well.
 */
internal fun mpvSpdifCodecs(supportsEncoding: (Int) -> Boolean): String = MPV_SPDIF_CODECS
  .filter { (_, encoding) -> supportsEncoding(encoding) }
  .joinToString(",") { (codec, _) -> codec }

/** [mpvSpdifCodecs] resolved against the audio route [context] is currently routed to. */
// Deprecated only in favour of an overload that also takes spatializer channel masks, which
// do not affect bitstream routing. Same probe ExoPlayerCore's TrueHD decision uses.
@Suppress("DEPRECATION")
@OptIn(UnstableApi::class)
internal fun supportedMpvSpdifCodecs(context: Context): String {
  val audioAttributes = AudioAttributes.Builder()
    .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
    .setUsage(C.USAGE_MEDIA)
    .build()
  val capabilities = try {
    AudioCapabilities.getCapabilities(context, audioAttributes, null)
  } catch (error: Exception) {
    Log.w(TAG, "Audio route capabilities unavailable; mpv will decode instead of bitstreaming", error)
    return ""
  }
  return mpvSpdifCodecs(capabilities::supportsEncoding)
}

/**
 * Whether this route can carry TrueHD as MAT inside IEC 61937 (#1804).
 *
 * This is Kodi's test, and deliberately not media3's. Kodi asks the AudioTrack layer whether it can
 * size a buffer for one exact tuple — `getMinBufferSize(rate, mask, encoding) > 0` — and gates the
 * carrier on the 192kHz/7.1 IEC combination specifically. media3 instead asks the audio policy
 * layer about the encoding, which on the boxes measured for this issue answers "TrueHD is
 * offload-capable" and says nothing about whether a raw TrueHD track will ever drain.
 *
 * Both are consulted: `getMinBufferSize` proves a track can be built, and a direct-playback oracle
 * proves the route will actually bitstream it rather than silently decode or wedge. Sizing alone is
 * not sufficient — on a Shield it answers yes for this tuple and the AudioTrack then fails to
 * initialise.
 *
 * The oracle is tiered by what the platform offers:
 * - API 33+: `getDirectPlaybackSupport`, whose bitstream flag also rules out offload-only answers.
 * - API 29–32: `AudioTrack.isDirectPlaybackSupported` for the same tuple. Coarser — it cannot tell
 *   bitstream from offload — but an IEC 61937 track is PCM-shaped by definition, so direct support
 *   for it means the route carries the frames. Fire OS 8 (API 30) devices bitstream TrueHD this way
 *   and lost passthrough entirely under an API 33 gate (#1863). A route that still lies here fails
 *   AudioTrack initialisation, which the audio recovery path answers by force-decoding.
 * - Below API 29 there is no oracle at all, so the carrier is not offered and TrueHD decodes as
 *   before.
 */
internal fun supportsTrueHdMatCarrier(): Boolean = trueHdMatCarrierSupported(
  sdkInt = Build.VERSION.SDK_INT,
  canSizeCarrierBuffer = {
    try {
      AudioTrack.getMinBufferSize(
        TrueHdMatPacker.CARRIER_SAMPLE_RATE,
        AudioFormat.CHANNEL_OUT_7POINT1_SURROUND,
        AudioFormat.ENCODING_IEC61937
      ) > 0
    } catch (error: Exception) {
      false
    }
  },
  // The SDK_INT guards repeat trueHdMatCarrierSupported's tiering only because lint's NewApi
  // check cannot see through the injected lambdas.
  bitstreamSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && iecCarrierBitstreamSupported()
  },
  directPlaybackSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && iecCarrierDirectPlaybackSupported()
  }
)

/**
 * [supportsTrueHdMatCarrier] with the platform probes injected. Probes are only consulted on the
 * API tiers where they exist: [bitstreamSupported] (`getDirectPlaybackSupport`) on 33+ and
 * [directPlaybackSupported] (`AudioTrack.isDirectPlaybackSupported`) on 29–32.
 */
internal fun trueHdMatCarrierSupported(
  sdkInt: Int,
  canSizeCarrierBuffer: () -> Boolean,
  bitstreamSupported: () -> Boolean,
  directPlaybackSupported: () -> Boolean
): Boolean = when {
  sdkInt < Build.VERSION_CODES.Q -> false
  !canSizeCarrierBuffer() -> false
  sdkInt >= Build.VERSION_CODES.TIRAMISU -> bitstreamSupported()
  else -> directPlaybackSupported()
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
private fun iecCarrierBitstreamSupported(): Boolean = try {
  val support = AudioManager.getDirectPlaybackSupport(iecCarrierProbeFormat(), movieAudioAttributes())
  (support and AudioManager.DIRECT_PLAYBACK_BITSTREAM_SUPPORTED) != 0
} catch (error: Exception) {
  Log.w(TAG, "IEC 61937 carrier probe failed; not offering the TrueHD carrier", error)
  false
}

@RequiresApi(Build.VERSION_CODES.Q)
@Suppress("DEPRECATION") // Deprecated in favour of the API 33 probe the tier above uses.
private fun iecCarrierDirectPlaybackSupported(): Boolean = try {
  AudioTrack.isDirectPlaybackSupported(iecCarrierProbeFormat(), movieAudioAttributes())
} catch (error: Exception) {
  Log.w(TAG, "IEC 61937 carrier probe failed; not offering the TrueHD carrier", error)
  false
}

/** The exact tuple the carrier's `AudioTrack` is built with; see [PlezyRenderersFactory]. */
private fun iecCarrierProbeFormat(): AudioFormat = AudioFormat.Builder()
  .setEncoding(AudioFormat.ENCODING_IEC61937)
  .setChannelMask(AudioFormat.CHANNEL_OUT_7POINT1_SURROUND)
  .setSampleRate(TrueHdMatPacker.CARRIER_SAMPLE_RATE)
  .build()

private fun movieAudioAttributes(): android.media.AudioAttributes = AudioAttributes.Builder()
  .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
  .setUsage(C.USAGE_MEDIA)
  .build()
  .getPlatformAudioAttributes()
