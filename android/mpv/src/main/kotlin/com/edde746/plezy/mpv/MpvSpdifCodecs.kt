package com.edde746.plezy.mpv

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.app.UiModeManager
import android.content.Context
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioProfile
import android.media.AudioTrack
import android.os.Build
import android.provider.Settings
import android.util.Log

private const val TAG = "MpvSpdifCodecs"

/** The IEC 61937 track shape a codec's spdif burst rides. */
internal enum class MpvIecShape { STEREO_48K, STEREO_192K, SURROUND_192K }

/** The order the fork's audiotrack AO tries a codec's transports in. */
private enum class MpvTransportOrder { RAW_THEN_CARRIER, CARRIER_THEN_RAW }

private class MpvSpdifCodec(
    val name: String,
    val encoding: Int,
    val shape: MpvIecShape,
    val order: MpvTransportOrder,
)

/**
 * mpv `audio-spdif` codec names, the platform encoding a route must advertise to carry that bitstream, and the track
 * shape the fork's `ao_audiotrack` opens for it.
 *
 * Since the raw-passthrough patch (0102), the AO feeds AC3, E-AC3 and the DTS core to a raw `ENCODING_AC3`/`E_AC3`/`DTS`
 * track at 48kHz/stereo — Kodi's transport — and only falls back to the IEC 61937 carrier when the route rejects the
 * raw encoding outright. Raw tracks keep the platform's Dolby/DTS transcoder in the path; a pre-packed IEC track
 * bypasses it and drains into silence on routes whose sink cannot decode the codec itself (#2177's Shield in front of
 * a Dolby-Digital-only Sonos).
 *
 * DTS-HD and TrueHD have both transports in the other order: the AO keeps the 8-channel 192kHz IEC carrier wherever
 * the route takes it, and unwraps the burst into a raw track only when the route refuses the carrier — the one
 * transport a TCL C8K's eARC port offers (#2333). For DTS-HD (0117) that raw track is `ENCODING_DTS_HD` at 48kHz/7.1;
 * Fire OS advertises it, opens it and renders silence (#1988) while its carrier plays. For TrueHD it is Kodi's raw
 * shape, `ENCODING_DOLBY_TRUEHD` at 192kHz/7.1 fed whole access units rebuilt from the MAT frames: the stream's own
 * 48kHz took one write and never played on #1804's box and froze a Box R, both routes whose carrier plays. A raw
 * TrueHD track that stops draining demotes TrueHD to decoding for the rest of the process.
 *
 * `dts-hd` supersedes plain `dts`: that literal is what selects the lossless `spdif_dts_hd` decoder, and it enables
 * spdif for the whole `dts` codec while doing so, with the core burst still chosen per file for tracks that are not HD
 * (`ad_spdif.c:240-249`, `:400-418`). HRA rides a 2ch/192kHz burst under the same name, so gating it on the 8-channel
 * shapes is the conservative choice.
 */
private val MPV_SPDIF_CODECS: List<MpvSpdifCodec> = listOf(
    MpvSpdifCodec("ac3", AudioFormat.ENCODING_AC3, MpvIecShape.STEREO_48K, MpvTransportOrder.RAW_THEN_CARRIER),
    MpvSpdifCodec("eac3", AudioFormat.ENCODING_E_AC3, MpvIecShape.STEREO_192K, MpvTransportOrder.RAW_THEN_CARRIER),
    MpvSpdifCodec("truehd", AudioFormat.ENCODING_DOLBY_TRUEHD, MpvIecShape.SURROUND_192K, MpvTransportOrder.CARRIER_THEN_RAW),
    MpvSpdifCodec("dts", AudioFormat.ENCODING_DTS, MpvIecShape.STEREO_48K, MpvTransportOrder.RAW_THEN_CARRIER),
    MpvSpdifCodec("dts-hd", AudioFormat.ENCODING_DTS_HD, MpvIecShape.SURROUND_192K, MpvTransportOrder.CARRIER_THEN_RAW),
)

/**
 * Builds an `audio-spdif` value naming only the codecs the route can carry: [supportsEncoding] advertises the codec's
 * encoding *and* a transport the AO's ladder can open exists — [supportsRawTrack] for the raw bitstream track,
 * [supportsShape] for the IEC 61937 burst — probed in the order the AO tries them, so the cheaper first choice spares
 * the second probe. Plain `dts` is dropped whenever `dts-hd` qualifies, which already covers the core burst.
 *
 * mpv force-passes through every codec named here and has no decode fallback, so an unsupported name leaves the file
 * rendering video against a dead audio output (#1703).
 *
 * The gate is the exact encoding on purpose, not a passthrough probe that answers by downgrading (DTS-HD to the DTS
 * core, E-AC3 JOC to E-AC3) and rejects channel counts above the route's PCM maximum: neither describes what a
 * passthrough track carries.
 *
 * [sinkDecodes] vetoes a codec the HDMI sink itself does not decode, whatever the platform advertises. A platform
 * encoding can be backed by the HAL's own decoder rather than by the sink: an Amlogic Mi Box S (Android 14) in front of
 * a Samsung TV lists `ENCODING_DTS` and `ENCODING_DTS_HD`, drains the 192kHz carrier into silence, and decodes a raw
 * DTS track to stereo only (`dtsx_sink_support_multich_pcm=0`). With the codec left out, mpv decodes DTS-HD MA itself
 * to the multichannel PCM that sink takes.
 */
internal fun mpvSpdifCodecs(
    supportsEncoding: (Int) -> Boolean,
    supportsShape: (MpvIecShape) -> Boolean,
    supportsRawTrack: (Int) -> Boolean = { false },
    sinkDecodes: (Int) -> Boolean = { true },
): String {
    val carried = MPV_SPDIF_CODECS.filter {
        supportsEncoding(it.encoding) &&
            sinkDecodes(it.encoding) &&
            when (it.order) {
                MpvTransportOrder.RAW_THEN_CARRIER -> supportsRawTrack(it.encoding) || supportsShape(it.shape)
                MpvTransportOrder.CARRIER_THEN_RAW -> supportsShape(it.shape) || supportsRawTrack(it.encoding)
            }
    }
    val dtsHd = carried.any { it.name == "dts-hd" }
    return (if (dtsHd) carried.filterNot { it.name == "dts" } else carried).joinToString(",") { it.name }
}

/**
 * [mpvSpdifCodecs] resolved against the audio route [context] is currently routed to.
 *
 * Three conditions per codec, all required:
 * - The route must accept a track shape the AO's ladder actually opens. For AC3, E-AC3 and the DTS core that is the
 *   raw bitstream track probed by [supportsMpvRawTrack], with the IEC stereo shapes ([supportsMpvIecShape],
 *   [supportsMpvHighRateIecShape]) as the AO's fallback transport; TrueHD and DTS-HD MA take the 192kHz/7.1 carrier
 *   ([supportsIecCarrier]) or, without it, the raw track the AO opens instead: 192kHz/7.1 `ENCODING_DOLBY_TRUEHD`,
 *   48kHz/7.1 `ENCODING_DTS_HD`.
 *   A route that takes one transport need not take the other: #1991's Shield strands playback on every mpv IEC
 *   attempt while bitstreaming AC3 raw.
 *   The probes are independent, so none of them may veto the whole list: a route that takes the 192kHz carrier but no
 *   raw track still bitstreams TrueHD and DTS-HD MA.
 * - The platform must advertise the codec's raw encoding ([routePassthroughEncodings]). This says the playback path
 *   takes the codec, not that the receiver decodes it: the platform may transcode a raw track, or decode it in the HAL.
 * - For the DTS family, the HDMI sink must advertise DTS itself ([hdmiSinkDecodesDts]). An Amlogic HAL advertises
 *   `ENCODING_DTS_HD` because it can decode DTS, then either drains the IEC carrier into silence or decodes a raw track
 *   to stereo on a sink with no DTS descriptor. Passthrough is transport, not transcoding, so such a sink gets DTS
 *   decoded by mpv instead. Dolby codecs are not gated this way: the same HAL carries TrueHD as MAT to a sink whose
 *   profiles do not list it.
 */
fun supportedMpvSpdifCodecs(context: Context): String {
    val encodings = try {
        advertisedEncodings(context)
    } catch (error: Exception) {
        Log.w(TAG, "Audio route capabilities unavailable; mpv will decode instead of bitstreaming", error)
        return ""
    }
    // Every probe costs real route calls and may be shared by more than one codec, so probe once.
    val shapeProbed = HashMap<MpvIecShape, Boolean>(3)
    val rawProbed = HashMap<Int, Boolean>(3)
    val sinkDecodesDts by lazy { hdmiSinkDecodesDts(context) }
    val codecs = mpvSpdifCodecs(
        { it in encodings },
        { shape -> shapeProbed.getOrPut(shape) { routeTakesIecShape(context, shape) } },
        { encoding -> rawProbed.getOrPut(encoding) { supportsMpvRawTrack(context, encoding) } },
        { encoding -> !isDtsEncoding(encoding) || sinkDecodesDts },
    )
    if (codecs.isEmpty()) {
        Log.i(TAG, "Route takes no passthrough track mpv can fill; mpv will decode instead of bitstreaming")
    } else {
        Log.i(TAG, "mpv will bitstream: $codecs")
    }
    return codecs
}

/** Encodings an Amazon or Xiaomi device's `external_surround_sound_enabled` setting vouches for. */
private val EXTERNAL_SURROUND_ENCODINGS = setOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_E_AC3)

/**
 * The bitstream encodings the platform says the movie route takes, by the rules of Media3's `AudioCapabilities` (the
 * encoding gate Android players share), tier by tier:
 * - API 33+ TV or car: the route's direct profiles ([directProfileEncodings], IEC 61937-encapsulated ones excluded).
 * - A Bluetooth route ([bluetoothRoute]): none.
 * - API 29+ TV or car: each encoding `AudioTrack.isDirectPlaybackSupported` takes at 48kHz stereo ([directPlaybackSupported]).
 * - Otherwise AC3 and E-AC3 when the external surround setting is on ([externalSurroundEnabled]) on a device that sets
 *   it ([manufacturerSetsExternalSurround]: Amazon, Xiaomi) or when `use_external_surround_sound_flag` forces it
 *   ([externalSurroundForced]), plus what the plugged HDMI sink lists in the sticky `ACTION_HDMI_AUDIO_PLUG`
 *   broadcast ([hdmiPlugEncodings], null when unplugged) unless the flag forces the setting over it.
 */
internal fun routePassthroughEncodings(
    sdkInt: Int,
    tvOrAutomotive: Boolean,
    manufacturerSetsExternalSurround: Boolean,
    directProfileEncodings: () -> Set<Int>,
    bluetoothRoute: () -> Boolean,
    directPlaybackSupported: (Int) -> Boolean,
    externalSurroundForced: () -> Boolean,
    externalSurroundEnabled: () -> Boolean,
    hdmiPlugEncodings: () -> IntArray?,
): Set<Int> = when {
    sdkInt >= Build.VERSION_CODES.TIRAMISU && tvOrAutomotive -> directProfileEncodings()
    bluetoothRoute() -> emptySet()
    sdkInt >= Build.VERSION_CODES.Q && tvOrAutomotive -> MPV_SPDIF_CODECS.map { it.encoding }.filter(directPlaybackSupported).toSet()
    else -> buildSet {
        val forced = externalSurroundForced()
        if ((forced || manufacturerSetsExternalSurround) && externalSurroundEnabled()) addAll(EXTERNAL_SURROUND_ENCODINGS)
        if (!forced) hdmiPlugEncodings()?.let { addAll(it.asIterable()) }
    }
}

// The sticky ACTION_HDMI_AUDIO_PLUG broadcast is protected, so no receiver flags apply; NewApi: tiered on SDK_INT.
@SuppressLint("UnprotectedReceiver", "NewApi")
private fun advertisedEncodings(context: Context): Set<Int> {
    val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    val resolver = context.contentResolver
    val tv = (context.applicationContext.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager)
        ?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
    return routePassthroughEncodings(
        sdkInt = Build.VERSION.SDK_INT,
        tvOrAutomotive = tv || context.packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE),
        manufacturerSetsExternalSurround = Build.MANUFACTURER == "Amazon" || Build.MANUFACTURER == "Xiaomi",
        directProfileEncodings = {
            manager.getDirectProfilesForAttributes(movieAudioAttributes())
                .filter { it.encapsulationType != AudioProfile.AUDIO_ENCAPSULATION_TYPE_IEC61937 }
                .map { it.format }
                .toSet()
        },
        bluetoothRoute = { routesToBluetooth(manager) },
        directPlaybackSupported = { encoding ->
            directPlaybackSupported(directProbeFormat(encoding, MPV_IEC_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO))
        },
        externalSurroundForced = { Settings.Global.getInt(resolver, "use_external_surround_sound_flag", 0) == 1 },
        externalSurroundEnabled = { Settings.Global.getInt(resolver, "external_surround_sound_enabled", 0) == 1 },
        hdmiPlugEncodings = {
            context.registerReceiver(null, IntentFilter(AudioManager.ACTION_HDMI_AUDIO_PLUG))
                ?.takeIf { it.getIntExtra(AudioManager.EXTRA_AUDIO_PLUG_STATE, 0) == 1 }
                ?.let { it.getIntArrayExtra(AudioManager.EXTRA_ENCODINGS) ?: IntArray(0) }
        },
    )
}

/** Whether the movie route (API 33+), or with none known any output, is a Bluetooth device. */
private fun routesToBluetooth(manager: AudioManager): Boolean {
    val routed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        manager.getAudioDevicesForAttributes(movieAudioAttributes()).firstOrNull()
    } else {
        null
    }
    val devices = routed?.let { listOf(it) } ?: manager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).asList()
    return devices.any { isBluetoothOutputType(it.type) }
}

private fun isBluetoothOutputType(type: Int): Boolean = type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
    type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
    (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && (type == AudioDeviceInfo.TYPE_BLE_HEADSET || type == AudioDeviceInfo.TYPE_BLE_SPEAKER)) ||
    (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && type == AudioDeviceInfo.TYPE_BLE_BROADCAST)

private fun routeTakesIecShape(context: Context, shape: MpvIecShape): Boolean = when (shape) {
    MpvIecShape.STEREO_48K -> supportsMpvIecShape(context)
    MpvIecShape.STEREO_192K -> supportsMpvHighRateIecShape(context)
    MpvIecShape.SURROUND_192K -> supportsIecCarrier(context)
}

/** The track shape mpv's audiotrack AO opens for an AC3 or DTS-core burst: stereo at the mixer rate. */
private const val MPV_IEC_SAMPLE_RATE = 48_000
private const val MPV_IEC_CHANNEL_COUNT = 2
private const val MPV_IEC_HIGH_SAMPLE_RATE = 192_000

/** The IEC 61937 carrier TrueHD (as MAT) and DTS-HD MA (as DTS type IV) ride: 192kHz, 8 channels. */
private const val IEC_CARRIER_SAMPLE_RATE = 192_000
private const val IEC_CARRIER_CHANNEL_COUNT = 8

private fun supportsMpvIecShape(context: Context): Boolean =
    iecShapeSupported(context, MPV_IEC_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO, MPV_IEC_CHANNEL_COUNT)

/** E-AC3's geometry: the stereo shape at the 192kHz burst rate, same route tiering as the others. */
private fun supportsMpvHighRateIecShape(context: Context): Boolean =
    iecShapeSupported(context, MPV_IEC_HIGH_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO, MPV_IEC_CHANNEL_COUNT)

/**
 * Whether this route can carry a packed bitstream inside IEC 61937 at 192kHz/7.1 — TrueHD as MAT (#1804) and DTS-HD
 * MA as DTS type IV (#1988) both ride this exact tuple.
 *
 * This is Kodi's test. Kodi asks the AudioTrack layer whether it can size a buffer for one exact tuple —
 * `getMinBufferSize(rate, mask, encoding) > 0` — and gates the carrier on the 192kHz/7.1 IEC combination
 * specifically. Asking the audio policy layer about the encoding instead, on the boxes measured for #1804, answers
 * "TrueHD is offload-capable" and says nothing about whether a raw TrueHD track will ever drain.
 *
 * Both are consulted: `getMinBufferSize` proves a track can be built, and a route oracle proves the route will actually
 * bitstream it rather than silently decode or wedge. Sizing alone is not sufficient — on a Shield it answers yes for
 * this tuple and the AudioTrack then fails to initialise.
 *
 * The oracle is tiered by what the platform offers:
 * - API 33+: `getDirectPlaybackSupport`, whose bitstream flag also rules out offload-only answers.
 * - API 29–32: `AudioTrack.isDirectPlaybackSupported` for the same tuple. Coarser — it cannot tell bitstream from
 *   offload — but an IEC 61937 track is PCM-shaped by definition, so direct support for it means the route carries the
 *   frames. Fire OS 8 (API 30) devices bitstream TrueHD this way and lost passthrough entirely under an API 33 gate
 *   (#1863). A route that still lies here fails AudioTrack initialisation, which mpv answers by decoding.
 * - API 24–28: no runtime oracle exists, so the HDMI `AudioDeviceInfo` must explicitly advertise IEC 61937 at
 *   192kHz/8ch. Shield Experience 8.x is API 28, and a flat `false` on this tier force-decoded TrueHD on routes that
 *   genuinely carry it (#1991).
 */
private fun supportsIecCarrier(context: Context): Boolean = iecShapeSupported(
    context,
    IEC_CARRIER_SAMPLE_RATE,
    AudioFormat.CHANNEL_OUT_7POINT1_SURROUND,
    IEC_CARRIER_CHANNEL_COUNT,
)

// NewApi: iecRouteSupported only calls each probe on the API tier that has it.
@SuppressLint("NewApi")
private fun iecShapeSupported(context: Context, sampleRate: Int, channelMask: Int, channelCount: Int): Boolean {
    val format = { directProbeFormat(AudioFormat.ENCODING_IEC61937, sampleRate, channelMask) }
    return iecRouteSupported(
        sdkInt = Build.VERSION.SDK_INT,
        canSizeBuffer = { canSizeDirectBuffer(sampleRate, channelMask, AudioFormat.ENCODING_IEC61937) },
        bitstreamSupported = { iecShapeDirectModeUsable(directPlaybackSupport(format())) },
        directPlaybackSupported = { directPlaybackSupported(format()) },
        hdmiRouteAdvertised = { hdmiAdvertisesIecRoute(context, sampleRate, channelCount) },
    )
}

/**
 * Whether the route takes a raw bitstream `AudioTrack` for [encoding] at the shape the fork's `ao_audiotrack` opens
 * ([mpvRawSampleRate], [mpvRawChannelMask]): stereo at the codec frame rate for AC3, E-AC3 and the DTS core (Kodi's raw
 * shape; the HAL reads the real channel layout from the bitstream), 48kHz/7.1 for DTS-HD MA, and 192kHz/7.1 for
 * TrueHD. Same probe tiering as the IEC shapes, with two differences:
 * - On API 33+ any direct mode `getDirectPlaybackSupport` reports counts, not only the bitstream bit
 *   ([rawTrackDirectModeUsable]).
 * - Below API 29 no runtime oracle exists for raw tracks, and the advertised encoding alone — which
 *   [supportedMpvSpdifCodecs] already requires — gates the raw path. #1991's API 28 Shield bitstreams AC3 exactly this
 *   way. The carrier-first codecs are the exception ([mpvRawTrackWithoutOracle]): the AO opens them raw only when the
 *   route oracle refuses the carrier, and with no oracle it keeps the carrier, so on that tier only
 *   [supportsIecCarrier] can qualify them.
 */
// NewApi: iecRouteSupported only calls each probe on the API tier that has it.
@SuppressLint("NewApi")
private fun supportsMpvRawTrack(context: Context, encoding: Int): Boolean {
    val sampleRate = mpvRawSampleRate(encoding)
    val channelMask = mpvRawChannelMask(encoding)
    val format = { directProbeFormat(encoding, sampleRate, channelMask) }
    return iecRouteSupported(
        sdkInt = Build.VERSION.SDK_INT,
        canSizeBuffer = { canSizeDirectBuffer(sampleRate, channelMask, encoding) },
        bitstreamSupported = { rawTrackDirectModeUsable(directPlaybackSupport(format())) },
        directPlaybackSupported = { directPlaybackSupported(format()) },
        hdmiRouteAdvertised = { mpvRawTrackWithoutOracle(encoding) },
    )
}

/**
 * Whether the AO opens [encoding]'s raw track on a route it cannot probe (below API 29): only for the raw-first codecs.
 * The carrier-first ones keep the carrier there.
 */
internal fun mpvRawTrackWithoutOracle(encoding: Int): Boolean =
    MPV_SPDIF_CODECS.any { it.encoding == encoding && it.order == MpvTransportOrder.RAW_THEN_CARRIER }

/** The rate the fork's AO opens a raw track at: the codec frame rate, and Kodi's 192kHz for TrueHD. */
internal fun mpvRawSampleRate(encoding: Int): Int =
    if (encoding == AudioFormat.ENCODING_DOLBY_TRUEHD) MPV_IEC_HIGH_SAMPLE_RATE else MPV_IEC_SAMPLE_RATE

/** The channel mask the fork's AO opens a raw track with: the burst's own, 7.1 for TrueHD and DTS-HD MA. */
internal fun mpvRawChannelMask(encoding: Int): Int = when (encoding) {
    AudioFormat.ENCODING_DTS_HD, AudioFormat.ENCODING_DOLBY_TRUEHD -> AudioFormat.CHANNEL_OUT_7POINT1_SURROUND
    else -> AudioFormat.CHANNEL_OUT_STEREO
}

/**
 * Whether a `getDirectPlaybackSupport` answer lets the fork open its raw AC3/E-AC3/DTS track: any direct mode does. The
 * answer only names the flag on the output profile that matched the tuple, and a HAL that declares its passthrough port
 * `DIRECT|COMPRESS_OFFLOAD` reports offload-only for the very port it bitstreams through — #2333's TCL C8K has no other
 * encoded-format port, plays E-AC3 5.1 through it, and demanding the bitstream bit refused every codec. The AudioTrack
 * open (`getProfileForOutput`, which prefers offload-capable profiles) and the API 29–32 tier
 * (`isDirectPlaybackSupported`) both accept such a profile; this was the one probe that did not.
 *
 * The IEC shapes keep the bitstream bit ([iecShapeDirectModeUsable]). The offload-only answer was measured to lie for
 * raw TrueHD on the boxes behind #1804, so mpv opens TrueHD raw only where that carrier gate refuses, and demotes it to
 * decoding if the raw track stops draining.
 */
internal fun rawTrackDirectModeUsable(support: Int): Boolean = support != AudioManager.DIRECT_PLAYBACK_NOT_SUPPORTED

/** Whether a `getDirectPlaybackSupport` answer vouches for an IEC 61937 shape: only the bitstream bit does. */
internal fun iecShapeDirectModeUsable(support: Int): Boolean = (support and AudioManager.DIRECT_PLAYBACK_BITSTREAM_SUPPORTED) != 0

/** The mpv spdif table's DTS entries: the codecs [hdmiSinkDecodesDts] gates. */
internal fun isDtsEncoding(encoding: Int): Boolean = encoding == AudioFormat.ENCODING_DTS || encoding == AudioFormat.ENCODING_DTS_HD

private const val ENCODING_DTS_UHD_P1 = 27
private const val ENCODING_DTS_HD_MA = 29
private const val ENCODING_DTS_UHD_P2 = 30

/**
 * Any DTS-family encoding an HDMI sink can list for a DTS short audio descriptor. The API 34 `AudioFormat` constants are
 * repeated as literals so the check also reads them on older platforms, where they can still appear in a HAL's profile
 * list.
 */
private fun isDtsSinkEncoding(encoding: Int): Boolean = when (encoding) {
    AudioFormat.ENCODING_DTS,
    AudioFormat.ENCODING_DTS_HD,
    ENCODING_DTS_UHD_P1,
    ENCODING_DTS_HD_MA,
    ENCODING_DTS_UHD_P2 -> true
    else -> false
}

/** Linear PCM output encodings, i.e. the sink decodes rather than passes through. */
private fun isPcmEncoding(encoding: Int): Boolean = when (encoding) {
    AudioFormat.ENCODING_PCM_8BIT,
    AudioFormat.ENCODING_PCM_16BIT,
    AudioFormat.ENCODING_PCM_FLOAT,
    AudioFormat.ENCODING_PCM_24BIT_PACKED,
    AudioFormat.ENCODING_PCM_32BIT -> true
    else -> false
}

/**
 * Whether the HDMI sinks in [hdmiSinkEncodings] (each an `AudioDeviceInfo.getEncodings()` array) advertise DTS
 * themselves.
 *
 * A sink counts as described only when it lists a compressed codec. PCM is not one, and neither is `ENCODING_IEC61937`,
 * which is a transport. #1458's Dynalink (Amlogic, Android TV 14) reports `pcm16|iec61937` alone for a sink that does
 * decode E-AC3. If no sink is given, or any of them is undescribed, the route probes keep the verdict (returns true):
 * the undescribed one may be the sink in use, and a HAL that reports no codecs never loses DTS bitstreaming.
 *
 * Otherwise a sink without a DTS entry does not decode DTS. On a Mi Box S (Android 14) in front of a Samsung QE55S95F
 * with an HW-Q930F, the output lists `pcm16|e-ac3-joc|ac3|e-ac3|iec61937`, the HAL logs
 * `get_sink_dts_capability: PCM_16_BIT`, and the DTS-HD carrier plays silent although the platform advertises
 * `ENCODING_DTS_HD`.
 */
internal fun sinkAdvertisesDts(hdmiSinkEncodings: List<IntArray>): Boolean {
    val undescribed = { encodings: IntArray -> encodings.none { !isPcmEncoding(it) && it != AudioFormat.ENCODING_IEC61937 } }
    if (hdmiSinkEncodings.isEmpty() || hdmiSinkEncodings.any(undescribed)) return true
    return hdmiSinkEncodings.any { encodings -> encodings.any(::isDtsSinkEncoding) }
}

/** An audio output as `AudioDeviceInfo` describes it. */
internal class AudioOutputRef(val type: Int, val address: String, val encodings: IntArray = IntArray(0))

/**
 * The encodings of the HDMI sinks a movie would play through, from every output [outputs] and the active movie route
 * [activeRoute] (`getAudioDevicesForAttributes`, API 33+; null below).
 *
 * - No active route known (below API 33, or the lookup returned nothing): every HDMI output.
 * - An active route with no HDMI device (optical, USB, Bluetooth): none. There is no HDMI sink to judge, so
 *   [sinkAdvertisesDts] leaves the verdict to the route probes.
 * - Otherwise the active HDMI outputs, matched by type and address, or every HDMI output when none matches.
 */
internal fun movieSinkEncodings(
    outputs: List<AudioOutputRef>,
    activeRoute: List<AudioOutputRef>?,
    isHdmiOutput: (Int) -> Boolean = ::isHdmiOutputType,
): List<IntArray> {
    val hdmiOutputs = outputs.filter { isHdmiOutput(it.type) }
    if (activeRoute.isNullOrEmpty()) return hdmiOutputs.map { it.encodings }
    val activeHdmi = activeRoute.filter { isHdmiOutput(it.type) }
    if (activeHdmi.isEmpty()) return emptyList()
    return hdmiOutputs
        .filter { device -> activeHdmi.any { it.type == device.type && it.address == device.address } }
        .ifEmpty { hdmiOutputs }
        .map { it.encodings }
}

private fun isHdmiOutputType(type: Int): Boolean = type == AudioDeviceInfo.TYPE_HDMI ||
    type == AudioDeviceInfo.TYPE_HDMI_ARC ||
    (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && type == AudioDeviceInfo.TYPE_HDMI_EARC)

private fun movieHdmiSinkEncodings(manager: AudioManager): List<IntArray> {
    val outputs = manager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).map { device ->
        val address = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) device.address else ""
        AudioOutputRef(device.type, address, device.encodings)
    }
    val activeRoute = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        manager.getAudioDevicesForAttributes(movieAudioAttributes()).map { AudioOutputRef(it.type, it.address) }
    } else {
        null
    }
    return movieSinkEncodings(outputs, activeRoute)
}

/**
 * [sinkAdvertisesDts] resolved against the HDMI outputs a movie would play through. When the sink advertises no DTS,
 * [mpvSpdifCodecs] names no DTS codec: mpv decodes DTS-HD MA to the multichannel PCM the sink takes, where the Mi Box
 * HAL would decode a raw DTS track to stereo only.
 */
private fun hdmiSinkDecodesDts(context: Context): Boolean = try {
    val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    val hdmiSinkEncodings = movieHdmiSinkEncodings(manager)
    sinkAdvertisesDts(hdmiSinkEncodings).also { decodes ->
        if (!decodes) {
            Log.i(TAG, "HDMI sink advertises no DTS (${hdmiSinkEncodings.joinToString { it.contentToString() }}); DTS will not be bitstreamed")
        }
    }
} catch (error: Exception) {
    Log.w(TAG, "HDMI sink inspection failed; keeping the DTS decision to the route probes", error)
    true
}

/**
 * [supportsIecCarrier]/[supportsMpvIecShape]/[supportsMpvRawTrack] with the platform probes injected. Probes are only
 * consulted on the API tiers where they exist: [bitstreamSupported] (`getDirectPlaybackSupport`) on 33+,
 * [directPlaybackSupported] (`AudioTrack.isDirectPlaybackSupported`) on 29–32, and [hdmiRouteAdvertised] (explicit HDMI
 * `AudioDeviceInfo` advertisement) on 24–28 (#1991).
 */
internal fun iecRouteSupported(
    sdkInt: Int,
    canSizeBuffer: () -> Boolean,
    bitstreamSupported: () -> Boolean,
    directPlaybackSupported: () -> Boolean,
    hdmiRouteAdvertised: () -> Boolean,
): Boolean = when {
    // ENCODING_IEC61937 itself only exists from API 24.
    sdkInt < Build.VERSION_CODES.N -> false
    !canSizeBuffer() -> false
    sdkInt >= Build.VERSION_CODES.TIRAMISU -> bitstreamSupported()
    sdkInt >= Build.VERSION_CODES.Q -> directPlaybackSupported()
    else -> hdmiRouteAdvertised()
}

private fun canSizeDirectBuffer(sampleRate: Int, channelMask: Int, encoding: Int): Boolean = try {
    AudioTrack.getMinBufferSize(sampleRate, channelMask, encoding) > 0
} catch (error: Exception) {
    false
}

@TargetApi(Build.VERSION_CODES.TIRAMISU)
private fun directPlaybackSupport(format: AudioFormat): Int = try {
    AudioManager.getDirectPlaybackSupport(format, movieAudioAttributes())
} catch (error: Exception) {
    Log.w(TAG, "Direct playback probe failed; not offering bitstream output", error)
    AudioManager.DIRECT_PLAYBACK_NOT_SUPPORTED
}

@TargetApi(Build.VERSION_CODES.Q)
@Suppress("DEPRECATION") // Deprecated in favour of the API 33 probe the tier above uses.
private fun directPlaybackSupported(format: AudioFormat): Boolean = try {
    AudioTrack.isDirectPlaybackSupported(format, movieAudioAttributes())
} catch (error: Exception) {
    Log.w(TAG, "Direct playback probe failed; not offering bitstream output", error)
    false
}

/**
 * Whether an HDMI output *explicitly* advertises IEC 61937 at [sampleRate]/[channelCount] — the only oracle below API
 * 29 (#1991).
 *
 * Empty `AudioDeviceInfo` capability arrays mean "unspecified" and deliberately fail this check: an unvouched IEC track
 * that initialises on a route that then renders it as PCM plays the carrier as full-scale noise, which no AudioTrack
 * initialisation failure reports.
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

private fun directProbeFormat(encoding: Int, sampleRate: Int, channelMask: Int): AudioFormat = AudioFormat.Builder()
    .setEncoding(encoding)
    .setChannelMask(channelMask)
    .setSampleRate(sampleRate)
    .build()

private fun movieAudioAttributes(): AudioAttributes = AudioAttributes.Builder()
    .setUsage(AudioAttributes.USAGE_MEDIA)
    .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
    .build()
