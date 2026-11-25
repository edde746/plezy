package com.edde746.plezy.playback

import com.edde746.plezy.settings.AppSettings
import kotlinx.serialization.Serializable
import kotlin.math.pow
import kotlin.math.roundToLong

/**
 * The most channels decoded audio plays with (the Audio Channels setting, `AudioChannelLimit`), as mpv's
 * `audio-channels` ([mpv]); this device keeps the last one chosen (`AppSettings.audioChannelLimit`).
 */
@Serializable
enum class AudioChannels(val mpv: String) {
    /** Every channel of the track (mpv's default, `auto-safe`). */
    ORIGINAL("auto-safe"),

    /**
     * 7.1 mixed down to 5.1 for TVs and receivers that only take 5.1 PCM; stereo stays stereo (a list, so mpv picks
     * the closest layout rather than padding). Passthrough is unaffected.
     */
    SURROUND_51("stereo,5.1"),

    /** Mixed down to two channels for stereo speakers and headphones; the audio is decoded, never passed through. */
    STEREO("stereo"),
}

/**
 * Loudness normalization on desktop and Apple, as mpv's `af`: lavfi `loudnorm` at streaming loudness, then
 * mpv's own `format` filter back to 48 kHz float, since `loudnorm` outputs 192 kHz doubles that the audio output would
 * otherwise convert on its deadline. Android uses [ANDROID_LOUDNESS_NORMALIZATION_FILTER]. Normalized audio is decoded,
 * never passed through.
 */
const val LOUDNESS_NORMALIZATION_FILTER = "loudnorm=I=-14:TP=-3:LRA=4,format=srate=48000:format=floatp"

/**
 * Android's loudness normalization, as mpv's `af`: `acompressor` as a slow gain control toward -14 LUFS, then
 * `alimiter` as a -3 dB ceiling with 1 ms of look-ahead. `link=maximum` drives every channel's gain from the loudest,
 * so 5.1 keeps its balance without a fold to stereo, and the chain stays at the source sample rate.
 * [LOUDNESS_NORMALIZATION_FILTER] is too heavy there: it runs on mpv's core thread, which hands Android's video frames
 * on, and its 192 kHz pass made them late on 32-bit TV boxes. The platform's DynamicsProcessing on the AudioTrack's
 * session (mpv-build's `audiotrack-normalize`) is no substitute: on a Galaxy Z Fold6 it silenced 5.1 and stuttered the
 * video (its ring buffer overflowed and the audio HAL spun), and it left a Fold3's spatialized 5.1
 * untouched. Needs mpv-build `957086a` or later, whose Android FFmpeg has both filters. Normalized audio is decoded,
 * never passed through.
 */
const val ANDROID_LOUDNESS_NORMALIZATION_FILTER =
    "acompressor=threshold=-34dB:ratio=4:knee=6dB:attack=30:release=300:makeup=15dB:link=maximum," +
        "alimiter=limit=-3dB:attack=1:release=60:level=false"

/**
 * An audio output mpv can play to (an entry of its `audio-device-list`): [name] is what `audio-device` takes ("auto"
 * for the system's choice), [description] what a menu shows.
 */
data class AudioDevice(val name: String, val description: String)

/**
 * How a channel limit folds decoded audio down: [centerBoostDb] (0 to [MAX_CENTER_BOOST_DB]) lifts the center channel,
 * where dialogue lives, in a stereo fold; [normalize] scales the mix so the folded channels never clip
 * (`audio-normalize-downmix`, which guards the 7.1 to 5.1 fold as well). The Center Boost and Normalize Downmix
 * settings.
 */
data class Downmix(val centerBoostDb: Int = 0, val normalize: Boolean = true) {
    companion object {
        const val MAX_CENTER_BOOST_DB = 12
    }
}

/**
 * The mpv property writes, in order, that put the audio at [channels] folded as [downmix]. [AudioChannels.ORIGINAL]
 * resets the fold options. Otherwise swresample's options land first, since they are read as the audio chain is built,
 * and `audio-channels` goes through `auto-safe` so the chain is rebuilt even when the limit stays the same. Only a
 * stereo fold mixes the center away, so only it takes the boost: swresample's `center_mix_level`, 10^((-3 + boost) / 20)
 * (its -3 dB default plus the boost); its surround and LFE defaults already fit.
 */
fun channelLimitWrites(channels: AudioChannels, downmix: Downmix): List<Pair<String, String>> {
    if (channels == AudioChannels.ORIGINAL) {
        return listOf("audio-channels" to channels.mpv, "audio-swresample-o" to "", "audio-normalize-downmix" to "no")
    }
    val centerMix = if (channels == AudioChannels.STEREO) "center_mix_level=${centerMixLevel(downmix.centerBoostDb)}" else ""
    return listOf(
        "audio-swresample-o" to centerMix,
        "audio-normalize-downmix" to if (downmix.normalize) "yes" else "no",
        "audio-channels" to AudioChannels.ORIGINAL.mpv,
        "audio-channels" to channels.mpv,
    )
}

/** swresample's `center_mix_level` for a center boost of [boostDb] dB, to four decimals ("0.7079" for none). */
internal fun centerMixLevel(boostDb: Int): String {
    val gain = 10.0.pow((-3 + boostDb.coerceIn(0, Downmix.MAX_CENTER_BOOST_DB)) / 20.0)
    val tenThousandths = (gain * 10_000).roundToLong()
    return "${tenThousandths / 10_000}.${(tenThousandths % 10_000).toString().padStart(4, '0')}"
}

/** Writes one mpv property as text; throws when mpv refuses the value. */
fun interface MpvPropertyWriter {
    @Throws(Exception::class)
    fun write(name: String, value: String)
}

/**
 * The audio options as one state: the passthrough setting, loudness normalization, the channel limit with its fold,
 * and the playback speed (mpv `speed`).
 */
data class AudioState(
    val passthrough: Boolean = false,
    val normalization: Boolean = false,
    val channels: AudioChannels = AudioChannels.ORIGINAL,
    val downmix: Downmix = Downmix(normalize = false),
    val rate: Double = 1.0,
) {
    /**
     * Whether a bitstream may go out: a filter can't process one, so normalization decodes; the stereo limit is a
     * promise for everything that plays; and mpv can't change the tempo of a bitstream. The 5.1 limit only shapes
     * decoded audio, so a bitstream passes it.
     */
    val passesThrough: Boolean
        get() = passthrough && rate == 1.0 && channels != AudioChannels.STEREO && !normalization
}

/** A part of [AudioState] a request changes; the channel limit and its fold are one. */
enum class AudioField { PASSTHROUGH, NORMALIZATION, DOWNMIX, RATE }

/**
 * Keeps mpv's audio properties at the requested [AudioState], on the engine's own thread. A setter records the
 * request ([request]) and applies it ([reconcile]) in call order. Each application writes only what changed, in an
 * order that never hands a bitstream to the filter, the fold or another speed: passthrough leaves first, then the
 * speed, the channel limit and the normalization filter, and passthrough comes back last.
 *
 * A write mpv refuses throws out of [reconcile] after the state mpv last accepted is put back (the fold and the filter
 * rewritten, since the failure may have left them half written), and the request's fields return to the accepted
 * values unless a newer request for the same field came after it.
 *
 * @param normalizationFilter the `af` value for normalization ([LOUDNESS_NORMALIZATION_FILTER],
 *   [ANDROID_LOUDNESS_NORMALIZATION_FILTER]).
 * @param exclusiveHint whether passthrough also claims the device (`audio-exclusive`, desktop only). A refused hint
 *   is only [warn]ed about: `audio-spdif` is what passthrough is.
 * @param codecs the formats the output takes undecoded, as `audio-spdif` lists them, asked as passthrough turns on.
 */
class AudioStateReconciler(
    private val normalizationFilter: String,
    private val exclusiveHint: Boolean,
    private val codecs: () -> String,
    private val warn: (message: String, error: Throwable) -> Unit,
    private val writer: MpvPropertyWriter,
) {
    /** One recorded request: the requested state when it was made, the [fields] it changes and their generations. */
    class Request internal constructor(
        internal val state: AudioState,
        internal val fields: Set<AudioField>,
        internal val generations: Map<AudioField, Int>,
    )

    /** What the setters asked for. */
    var requested = AudioState()
        private set

    /** What mpv last took as a whole. */
    var accepted = AudioState()
        private set

    /** `audio-spdif` as mpv holds it: empty while the audio is decoded. */
    var activeSpdif = ""
        private set

    /** Whether passthrough is in effect: mpv accepted a non-empty `audio-spdif`. */
    val passthroughActive: Boolean get() = activeSpdif.isNotEmpty()

    private val generations = AudioField.entries.associateWith { 0 }.toMutableMap()
    private var normalizationActive = false
    private var activeChannels = AudioChannels.ORIGINAL
    private var activeDownmix = Downmix(normalize = false)
    private var currentRate = 1.0
    private var exclusive = false

    fun requestPassthrough(enabled: Boolean): Request = request(requested.copy(passthrough = enabled), AudioField.PASSTHROUGH)

    fun requestNormalization(enabled: Boolean): Request = request(requested.copy(normalization = enabled), AudioField.NORMALIZATION)

    fun requestChannels(channels: AudioChannels, downmix: Downmix): Request =
        request(requested.copy(channels = channels, downmix = downmix), AudioField.DOWNMIX)

    fun requestRate(rate: Double): Request = request(requested.copy(rate = rate), AudioField.RATE)

    /** Every field as requested, for an mpv that holds its defaults (a new core). */
    fun requestAll(): Request = request(requested, *AudioField.entries.toTypedArray())

    private fun request(state: AudioState, vararg fields: AudioField): Request {
        requested = state
        for (field in fields) generations[field] = generations.getValue(field) + 1
        return Request(state, fields.toSet(), generations.toMap())
    }

    /** Applies [request] (rebased on the accepted state); rethrows a refused write after the rollback. */
    @Throws(Exception::class)
    fun reconcile(request: Request) {
        val previous = accepted
        val target = rebase(previous, request)
        try {
            apply(target)
            accepted = target
        } catch (e: Exception) {
            val downmix = AudioField.DOWNMIX in request.fields
            try {
                apply(previous, forceDownmix = downmix, forceNormalization = downmix)
            } catch (rollback: Exception) {
                warn("could not restore the accepted audio state", rollback)
            }
            restoreRequested(previous, request)
            throw e
        }
    }

    private fun rebase(accepted: AudioState, request: Request): AudioState {
        val r = request.state
        val f = request.fields
        return AudioState(
            passthrough = if (AudioField.PASSTHROUGH in f) r.passthrough else accepted.passthrough,
            normalization = if (AudioField.NORMALIZATION in f) r.normalization else accepted.normalization,
            channels = if (AudioField.DOWNMIX in f) r.channels else accepted.channels,
            downmix = if (AudioField.DOWNMIX in f) r.downmix else accepted.downmix,
            rate = if (AudioField.RATE in f) r.rate else accepted.rate,
        )
    }

    private fun restoreRequested(previous: AudioState, request: Request) {
        fun current(field: AudioField) = field in request.fields && request.generations[field] == generations[field]
        var state = requested
        if (current(AudioField.PASSTHROUGH)) state = state.copy(passthrough = previous.passthrough)
        if (current(AudioField.NORMALIZATION)) state = state.copy(normalization = previous.normalization)
        if (current(AudioField.DOWNMIX)) state = state.copy(channels = previous.channels, downmix = previous.downmix)
        if (current(AudioField.RATE)) state = state.copy(rate = previous.rate)
        requested = state
    }

    private fun apply(target: AudioState, forceDownmix: Boolean = false, forceNormalization: Boolean = false) {
        val passes = target.passesThrough
        if (passthroughActive && !passes) setSpdif("")
        if (currentRate != target.rate) {
            writer.write("speed", target.rate.toString())
            currentRate = target.rate
        }
        val foldChanged = target.channels != AudioChannels.ORIGINAL && activeDownmix != target.downmix
        if (forceDownmix || activeChannels != target.channels || foldChanged) {
            for ((name, value) in channelLimitWrites(target.channels, target.downmix)) writer.write(name, value)
            activeChannels = target.channels
            activeDownmix = target.downmix
        }
        if (forceNormalization || normalizationActive != target.normalization) {
            writer.write("af", if (target.normalization) normalizationFilter else "")
            normalizationActive = target.normalization
        }
        if (passes) {
            val spdif = codecs()
            if (spdif != activeSpdif) setSpdif(spdif)
        }
    }

    private fun setSpdif(value: String) {
        writer.write("audio-spdif", value)
        activeSpdif = value
        val claim = value.isNotEmpty()
        if (!exclusiveHint || claim == exclusive) return
        try {
            writer.write("audio-exclusive", if (claim) "yes" else "no")
            exclusive = claim
        } catch (e: Exception) {
            warn("could not set audio-exclusive", e)
        }
    }
}
