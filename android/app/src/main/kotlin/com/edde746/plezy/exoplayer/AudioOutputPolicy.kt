package com.edde746.plezy.exoplayer

import android.content.Context
import android.media.AudioFormat
import android.util.Log
import androidx.annotation.OptIn
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
