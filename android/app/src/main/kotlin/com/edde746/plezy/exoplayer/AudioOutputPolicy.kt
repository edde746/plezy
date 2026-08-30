package com.edde746.plezy.exoplayer

import android.content.Context
import android.media.AudioDeviceInfo
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
 * The DTS-family mimes the bundled FFmpeg decoder claims (`FfmpegLibrary` maps both to `dca`).
 *
 * DTS Express (`audio/vnd.dts.hd;profile=lbr`) and DTS:X (`audio/vnd.dts.uhd`) are deliberately
 * excluded: FFmpeg does not claim them, so hiding their platform decoders would leave those
 * streams with no decoder at all.
 */
internal fun isFfmpegDtsMimeType(mimeType: String): Boolean = mimeType == MimeTypes.AUDIO_DTS || mimeType == MimeTypes.AUDIO_DTS_HD

/**
 * Whether a DTS stream should decode in the app's FFmpeg decoder instead of a platform
 * MediaCodec decoder.
 *
 * Platform DTS decoders cannot be trusted with decode. On Amlogic-based Google TV boxes (the
 * Onn family) DTS decode is license-gated in firmware, so `c2.amlogic.audio.decoder.dtshd`
 * initialises, drains and advances the playback position while rendering silence — and collapses
 * 5.1 to stereo where it does produce sound (#1995). FFmpeg decodes the whole `dca` family to
 * full multichannel PCM everywhere, which is what mpv and Kodi ship on the same hardware.
 *
 * Scoped to streams that are actually going to decode: [directOutputBlocked] (passthrough off,
 * downmix, normalization, the AudioTrack-failure blocklist) or a route that cannot bitstream DTS
 * in any shape ([routeCanBitstreamDts] false — the Android TV default leaves passthrough on, so
 * the setting alone cannot identify the decode path). Bitstream-capable routes are left exactly
 * alone: media3 selects direct output before it ever consults the decoder list, and leaving the
 * platform decoder visible there keeps the hardware-decoder tunneling gate unchanged.
 */
internal fun shouldForceFfmpegDtsDecode(
  mimeType: String,
  directOutputBlocked: () -> Boolean,
  routeCanBitstreamDts: () -> Boolean
): Boolean = isFfmpegDtsMimeType(mimeType) && (directOutputBlocked() || !routeCanBitstreamDts())

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

/** The IEC 61937 track shape a codec's spdif burst rides. */
internal enum class MpvIecShape { STEREO_48K, STEREO_192K, SURROUND_192K }

private class MpvSpdifCodec(
  val name: String,
  val encoding: Int,
  val shape: MpvIecShape,
  /** Whether the fork's audiotrack AO opens this codec as a raw bitstream track first. */
  val raw: Boolean = false
)

/**
 * mpv `audio-spdif` codec names, the platform encoding a route must advertise to carry that
 * bitstream, and the track shape the fork's `ao_audiotrack` opens for it.
 *
 * Since the raw-passthrough patch (0102), the AO feeds AC3, E-AC3 and the DTS core to a raw
 * `ENCODING_AC3`/`E_AC3`/`DTS` track at 48kHz/stereo — the transport ExoPlayer and Kodi use —
 * and only falls back to the IEC 61937 carrier when the route rejects the raw encoding
 * outright. Raw tracks keep the platform's Dolby/DTS transcoder in the path; a pre-packed IEC
 * track bypasses it and drains into silence on routes whose sink cannot decode the codec
 * itself (#2177's Shield in front of a Dolby-Digital-only Sonos). TrueHD (MAT) and DTS-HD MA
 * stay on the 8-channel 192kHz IEC carrier the multichannel patch (0101) added: their raw
 * forms are not recoverable from the burst stream.
 *
 * `dts-hd` supersedes plain `dts`: that literal is what selects the lossless `spdif_dts_hd`
 * decoder, and it enables spdif for the whole `dts` codec while doing so, with the core burst
 * still chosen per file for tracks that are not HD (`ad_spdif.c:240-249`, `:400-418`). HRA rides
 * a 2ch/192kHz burst under the same name, so gating it on the 8-channel carrier is the
 * conservative choice.
 */
private val MPV_SPDIF_CODECS: List<MpvSpdifCodec> = listOf(
  MpvSpdifCodec("ac3", C.ENCODING_AC3, MpvIecShape.STEREO_48K, raw = true),
  MpvSpdifCodec("eac3", C.ENCODING_E_AC3, MpvIecShape.STEREO_192K, raw = true),
  MpvSpdifCodec("truehd", C.ENCODING_DOLBY_TRUEHD, MpvIecShape.SURROUND_192K),
  MpvSpdifCodec("dts", C.ENCODING_DTS, MpvIecShape.STEREO_48K, raw = true),
  MpvSpdifCodec("dts-hd", C.ENCODING_DTS_HD, MpvIecShape.SURROUND_192K)
)

/**
 * Builds an `audio-spdif` value naming only the codecs the route can carry: [supportsEncoding]
 * advertises the codec's encoding *and* a transport the AO's ladder can open exists —
 * [supportsRawTrack] for the raw bitstream track it tries first, or [supportsShape] for the
 * IEC 61937 burst it falls back to. Plain `dts` is dropped whenever `dts-hd` qualifies, which
 * already covers the core burst.
 *
 * mpv force-passes through every codec named here and has no decode fallback, so an
 * unsupported name leaves the file rendering video against a dead audio output (#1703).
 *
 * The gate is the exact encoding rather than media3's passthrough probe on purpose. That
 * probe answers by downgrading (DTS-HD to the DTS core, E-AC3 JOC to E-AC3) and rejects
 * channel counts above the route's PCM maximum, neither of which describes what a
 * passthrough track carries.
 */
internal fun mpvSpdifCodecs(
  supportsEncoding: (Int) -> Boolean,
  supportsShape: (MpvIecShape) -> Boolean,
  supportsRawTrack: (Int) -> Boolean = { false }
): String {
  val carried = MPV_SPDIF_CODECS.filter {
    supportsEncoding(it.encoding) &&
      ((it.raw && supportsRawTrack(it.encoding)) || supportsShape(it.shape))
  }
  val dtsHd = carried.any { it.name == "dts-hd" }
  return (if (dtsHd) carried.filterNot { it.name == "dts" } else carried).joinToString(",") { it.name }
}

/**
 * [mpvSpdifCodecs] resolved against the audio route [context] is currently routed to.
 *
 * Two conditions per codec, both required:
 * - The route must accept a track shape the AO's ladder actually opens. For AC3, E-AC3 and the
 *   DTS core that is the raw bitstream track probed by [supportsMpvRawTrack], with the IEC
 *   stereo shapes ([supportsMpvIecShape], [supportsMpvHighRateIecShape]) as the AO's fallback
 *   transport; TrueHD and DTS-HD MA need the 192kHz/7.1 carrier ([supportsIecCarrier]).
 *   Advertising the raw encoding only says the receiver decodes it, not that the HAL takes the
 *   track: #1991's Shield strands playback on every mpv IEC attempt while bitstreaming AC3 raw.
 *   The probes are independent, so none of them may veto the whole list: a route that takes the
 *   192kHz carrier but no raw track still bitstreams TrueHD and DTS-HD MA.
 * - The receiver must decode the codec itself — the raw encoding on the current
 *   [AudioCapabilities] — because passthrough is transport, not transcoding. (On a raw track
 *   the platform may additionally transcode, which is exactly why the AO prefers it.)
 */
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
  // Every probe costs real route calls and may be shared by more than one codec, so probe once.
  val shapeProbed = HashMap<MpvIecShape, Boolean>(3)
  val rawProbed = HashMap<Int, Boolean>(3)
  val codecs = mpvSpdifCodecs(
    capabilities::supportsEncoding,
    { shape -> shapeProbed.getOrPut(shape) { routeTakesIecShape(context, shape) } },
    { encoding -> rawProbed.getOrPut(encoding) { supportsMpvRawTrack(context, encoding) } }
  )
  if (codecs.isEmpty()) {
    Log.i(TAG, "Route takes no passthrough track mpv can fill; mpv will decode instead of bitstreaming")
  } else {
    Log.i(TAG, "mpv will bitstream: $codecs")
  }
  return codecs
}

private fun routeTakesIecShape(context: Context, shape: MpvIecShape): Boolean = when (shape) {
  MpvIecShape.STEREO_48K -> supportsMpvIecShape(context)
  MpvIecShape.STEREO_192K -> supportsMpvHighRateIecShape(context)
  MpvIecShape.SURROUND_192K -> supportsIecCarrier(context)
}

/** The track shape mpv's audiotrack AO opens for an AC3 or DTS-core burst: stereo at the mixer rate. */
private const val MPV_IEC_SAMPLE_RATE = 48_000
private const val MPV_IEC_CHANNEL_COUNT = 2
private const val MPV_IEC_HIGH_SAMPLE_RATE = 192_000

internal fun supportsMpvIecShape(context: Context): Boolean = iecRouteSupported(
  sdkInt = Build.VERSION.SDK_INT,
  canSizeBuffer = { canSizeIecBuffer(MPV_IEC_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO) },
  // The SDK_INT guards repeat iecRouteSupported's tiering only because lint's NewApi
  // check cannot see through the injected lambdas.
  bitstreamSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
      iecBitstreamSupported(iecProbeFormat(MPV_IEC_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO))
  },
  directPlaybackSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
      iecDirectPlaybackSupported(iecProbeFormat(MPV_IEC_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO))
  },
  hdmiRouteAdvertised = { hdmiAdvertisesIecRoute(context, MPV_IEC_SAMPLE_RATE, MPV_IEC_CHANNEL_COUNT) }
)

/**
 * Whether the route takes a raw bitstream `AudioTrack` for [encoding] at the shape the fork's
 * `ao_audiotrack` opens first: the codec frame rate with a stereo mask (Kodi's raw shape; the
 * HAL reads the real channel layout from the bitstream). Same probe tiering as the IEC shapes,
 * except below API 29, where no runtime oracle exists for raw tracks and media3 gates its raw
 * path on the advertised encoding alone — which [supportedMpvSpdifCodecs] already requires via
 * [AudioCapabilities]. #1991's API 28 Shield bitstreams AC3 exactly this way.
 */
internal fun supportsMpvRawTrack(context: Context, encoding: Int): Boolean = iecRouteSupported(
  sdkInt = Build.VERSION.SDK_INT,
  canSizeBuffer = { canSizeDirectBuffer(MPV_IEC_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO, encoding) },
  // The SDK_INT guards repeat iecRouteSupported's tiering only because lint's NewApi
  // check cannot see through the injected lambdas.
  bitstreamSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
      iecBitstreamSupported(directProbeFormat(encoding, MPV_IEC_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO))
  },
  directPlaybackSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
      iecDirectPlaybackSupported(directProbeFormat(encoding, MPV_IEC_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO))
  },
  hdmiRouteAdvertised = { true }
)

/** E-AC3's geometry: the stereo shape at the 192kHz burst rate, same route tiering as the others. */
internal fun supportsMpvHighRateIecShape(context: Context): Boolean = iecRouteSupported(
  sdkInt = Build.VERSION.SDK_INT,
  canSizeBuffer = { canSizeIecBuffer(MPV_IEC_HIGH_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO) },
  // The SDK_INT guards repeat iecRouteSupported's tiering only because lint's NewApi
  // check cannot see through the injected lambdas.
  bitstreamSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
      iecBitstreamSupported(iecProbeFormat(MPV_IEC_HIGH_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO))
  },
  directPlaybackSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
      iecDirectPlaybackSupported(iecProbeFormat(MPV_IEC_HIGH_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO))
  },
  hdmiRouteAdvertised = { hdmiAdvertisesIecRoute(context, MPV_IEC_HIGH_SAMPLE_RATE, MPV_IEC_CHANNEL_COUNT) }
)

/**
 * Whether this route can carry a packed bitstream inside IEC 61937 at 192kHz/7.1 — TrueHD as MAT
 * (#1804) and DTS-HD MA as DTS type IV (#1988) both ride this exact tuple.
 *
 * This is Kodi's test, and deliberately not media3's. Kodi asks the AudioTrack layer whether it can
 * size a buffer for one exact tuple — `getMinBufferSize(rate, mask, encoding) > 0` — and gates the
 * carrier on the 192kHz/7.1 IEC combination specifically. media3 instead asks the audio policy
 * layer about the encoding, which on the boxes measured for this issue answers "TrueHD is
 * offload-capable" and says nothing about whether a raw TrueHD track will ever drain.
 *
 * Both are consulted: `getMinBufferSize` proves a track can be built, and a route oracle proves
 * the route will actually bitstream it rather than silently decode or wedge. Sizing alone is
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
 * - API 24–28: no runtime oracle exists, so the HDMI `AudioDeviceInfo` must explicitly advertise
 *   IEC 61937 at 192kHz/8ch. Shield Experience 8.x is API 28, and the previous flat `false` on
 *   this tier force-decoded TrueHD on routes that genuinely carry it (#1991). A route that
 *   advertises and still refuses the track fails AudioTrack initialisation into the same
 *   recovery path as the tier above.
 */
internal fun supportsIecCarrier(context: Context): Boolean = iecRouteSupported(
  sdkInt = Build.VERSION.SDK_INT,
  canSizeBuffer = { canSizeIecBuffer(IecCarrier.SAMPLE_RATE, AudioFormat.CHANNEL_OUT_7POINT1_SURROUND) },
  // The SDK_INT guards repeat iecRouteSupported's tiering only because lint's NewApi
  // check cannot see through the injected lambdas.
  bitstreamSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
      iecBitstreamSupported(iecProbeFormat(IecCarrier.SAMPLE_RATE, AudioFormat.CHANNEL_OUT_7POINT1_SURROUND))
  },
  directPlaybackSupported = {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
      iecDirectPlaybackSupported(iecProbeFormat(IecCarrier.SAMPLE_RATE, AudioFormat.CHANNEL_OUT_7POINT1_SURROUND))
  },
  hdmiRouteAdvertised = { hdmiAdvertisesIecRoute(context, IecCarrier.SAMPLE_RATE, IecCarrier.CHANNEL_COUNT) }
)

/**
 * [supportsIecCarrier]/[supportsMpvIecShape] with the platform probes injected. Probes are only
 * consulted on the API tiers where they exist: [bitstreamSupported] (`getDirectPlaybackSupport`)
 * on 33+, [directPlaybackSupported] (`AudioTrack.isDirectPlaybackSupported`) on 29–32, and
 * [hdmiRouteAdvertised] (explicit HDMI `AudioDeviceInfo` advertisement) on 24–28 (#1991).
 */
internal fun iecRouteSupported(
  sdkInt: Int,
  canSizeBuffer: () -> Boolean,
  bitstreamSupported: () -> Boolean,
  directPlaybackSupported: () -> Boolean,
  hdmiRouteAdvertised: () -> Boolean
): Boolean = when {
  // ENCODING_IEC61937 itself only exists from API 24.
  sdkInt < Build.VERSION_CODES.N -> false
  !canSizeBuffer() -> false
  sdkInt >= Build.VERSION_CODES.TIRAMISU -> bitstreamSupported()
  sdkInt >= Build.VERSION_CODES.Q -> directPlaybackSupported()
  else -> hdmiRouteAdvertised()
}

private fun canSizeIecBuffer(sampleRate: Int, channelMask: Int): Boolean =
  canSizeDirectBuffer(sampleRate, channelMask, AudioFormat.ENCODING_IEC61937)

private fun canSizeDirectBuffer(sampleRate: Int, channelMask: Int, encoding: Int): Boolean = try {
  AudioTrack.getMinBufferSize(sampleRate, channelMask, encoding) > 0
} catch (error: Exception) {
  false
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
private fun iecBitstreamSupported(format: AudioFormat): Boolean = try {
  val support = AudioManager.getDirectPlaybackSupport(format, movieAudioAttributes())
  (support and AudioManager.DIRECT_PLAYBACK_BITSTREAM_SUPPORTED) != 0
} catch (error: Exception) {
  Log.w(TAG, "IEC 61937 route probe failed; not offering bitstream output", error)
  false
}

@RequiresApi(Build.VERSION_CODES.Q)
@Suppress("DEPRECATION") // Deprecated in favour of the API 33 probe the tier above uses.
private fun iecDirectPlaybackSupported(format: AudioFormat): Boolean = try {
  AudioTrack.isDirectPlaybackSupported(format, movieAudioAttributes())
} catch (error: Exception) {
  Log.w(TAG, "IEC 61937 route probe failed; not offering bitstream output", error)
  false
}

/**
 * Whether an HDMI output *explicitly* advertises IEC 61937 at [sampleRate]/[channelCount] —
 * the only oracle below API 29 (#1991).
 *
 * Empty `AudioDeviceInfo` capability arrays mean "unspecified" and deliberately fail this
 * check: an unvouched IEC track that initialises on a route that then renders it as PCM plays
 * the carrier as full-scale noise, which the AudioTrack-init recovery path cannot catch.
 */
private fun hdmiAdvertisesIecRoute(context: Context, sampleRate: Int, channelCount: Int): Boolean = try {
  val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
  manager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).any { device ->
    (device.type == AudioDeviceInfo.TYPE_HDMI || device.type == AudioDeviceInfo.TYPE_HDMI_ARC) &&
      device.encodings.contains(AudioFormat.ENCODING_IEC61937) &&
      device.sampleRates.contains(sampleRate) &&
      device.channelCounts.contains(channelCount)
  }
} catch (error: Exception) {
  Log.w(TAG, "HDMI route inspection failed; not offering IEC 61937 output", error)
  false
}

/** The exact tuple an IEC output's `AudioTrack` is built with; see [PlezyRenderersFactory]. */
private fun iecProbeFormat(sampleRate: Int, channelMask: Int): AudioFormat =
  directProbeFormat(AudioFormat.ENCODING_IEC61937, sampleRate, channelMask)

private fun directProbeFormat(encoding: Int, sampleRate: Int, channelMask: Int): AudioFormat = AudioFormat.Builder()
  .setEncoding(encoding)
  .setChannelMask(channelMask)
  .setSampleRate(sampleRate)
  .build()

private fun movieAudioAttributes(): android.media.AudioAttributes = AudioAttributes.Builder()
  .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
  .setUsage(C.USAGE_MEDIA)
  .build()
  .getPlatformAudioAttributes()
