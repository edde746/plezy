package com.edde746.plezy.playback.mpv

import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * The frame rate an Android MediaCodec decoder is told to be ready for (MediaFormat `operating-rate`, mpv's
 * `hwdec-mediacodec-operating-rate`).
 *
 * Vendors pick the codec's clock from this number, not from the stream. On a Pixel 7, Tensor's AV1 block with nothing
 * declared decoded 30 Mb/s 1080p24 film grain at 40 ms a frame, which played at 5-8 fps; with 60 declared it took 18
 * ms a frame. The content rate alone (24) changed nothing: the vendor provisions for a typical bitrate at that rate,
 * and a heavy one needs headroom over it. Only some stacks read the number (Tensor, Qualcomm); within the codec's
 * advertised range it does no harm on the rest, and MediaTek's decoders are configured without it.
 */
object DecoderOperatingRate {
    /** The least any file declares: 24 alone changed nothing on Tensor, 60 did. */
    const val FLOOR_FPS = 60.0

    /** Headroom over the content rate, for bitrate the vendor's model doesn't see. */
    const val HEADROOM = 2.0

    /** A saturating rate buys nothing (the clock tables top out) and is the one value known to break decoders. */
    const val CEILING_FPS = 240

    /**
     * The rate to declare for a file of [fps] (the container's; null when it gives none) played at [speed]: the
     * content rate with [HEADROOM], at least [FLOOR_FPS], times the speed, capped by the decoder's advertised maximum at
     * the file's size ([codecMaxFps], null when it advertises none) and by [CEILING_FPS].
     */
    fun of(fps: Double?, speed: Double, codecMaxFps: Int?): Int {
        val content = fps?.takeIf { it.isFinite() && it > 0 } ?: 0.0
        val upper = min(codecMaxFps?.takeIf { it > 0 } ?: CEILING_FPS, CEILING_FPS)
        return min(ceil(max(HEADROOM * content, FLOOR_FPS) * speed).toInt(), upper)
    }
}
