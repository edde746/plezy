package com.edde746.plezy.mpv.video.hdr

import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import kotlin.math.floor

/**
 * The source's colour space under mpv's own names, plus its HDR10 static metadata. A zero luminance means the source
 * did not state it (mpv omits the field rather than reporting zero); the names are empty when nothing is loaded.
 */
internal data class SourceHdrMetadata(
    /** mpv trc name, e.g. "pq", "hlg", "bt.1886". */
    val transfer: String = "",
    /** mpv primaries name, e.g. "bt.2020". */
    val primaries: String = "",
    /** Nits, maximum content light level. */
    val maxCll: Double = 0.0,
    /** Nits, maximum frame-average light level. */
    val maxFall: Double = 0.0,
    /** Nits, mastering display maximum. */
    val maxLuminance: Double = 0.0,
    /** Nits, mastering display minimum. */
    val minLuminance: Double = 0.0,
)

/**
 * The fields the HDR decision needs out of mpv's `video-params`, as the JSON text mpv delivers.
 *
 * Anything that is not the object mpv documents (null, another JSON type, malformed text) is the default, which reads
 * as "no stream" downstream and describes no plane. The names are taken verbatim whether or not any luminance came
 * with them: plenty of HDR10 carries a PQ curve and no static metadata, and what counts as HDR is the caller's call.
 * A luminance is taken only as a number (an integer too); a mistyped value is skipped without stopping the rest.
 * max-cll, max-fall and max-luma only when positive, since zero is how the pipeline spells "not stated"; min-luma
 * accepts zero (a display whose black is unmeasurably low) and refuses only a negative.
 */
internal fun parseSourceHdrMetadata(json: String?): SourceHdrMetadata {
    if (json == null) return SourceHdrMetadata()
    val params = try {
        Json.parseToJsonElement(json)
    } catch (_: SerializationException) {
        return SourceHdrMetadata()
    }
    if (params !is JsonObject) return SourceHdrMetadata()
    val maxCll = number(params["max-cll"])
    val maxFall = number(params["max-fall"])
    val maxLuminance = number(params["max-luma"])
    val minLuminance = number(params["min-luma"])
    return SourceHdrMetadata(
        transfer = name(params["gamma"]),
        primaries = name(params["primaries"]),
        maxCll = if (maxCll != null && maxCll > 0.0) maxCll else 0.0,
        maxFall = if (maxFall != null && maxFall > 0.0) maxFall else 0.0,
        maxLuminance = if (maxLuminance != null && maxLuminance > 0.0) maxLuminance else 0.0,
        minLuminance = if (minLuminance != null && minLuminance >= 0.0) minLuminance else 0.0,
    )
}

private fun name(value: JsonElement?): String =
    if (value is JsonPrimitive && value.isString) value.content else ""

private fun number(value: JsonElement?): Double? =
    if (value is JsonPrimitive && !value.isString) value.doubleOrNull else null

/**
 * The source as the plane's decision sees it. mpv's names map "pq" to PQ, "hlg" to HLG and "bt.2020" to BT.2020;
 * every other name is SDR / other. The protocol carries luminances as whole nits and a value that rounds to zero would
 * read as "not stated", so each is rounded half up, kept at least 1 when positive and capped at 0xFFFFFFFF.
 */
internal fun SourceHdrMetadata.toHdrMetadata(): HdrMetadata = HdrMetadata(
    transfer = when (transfer) {
        "pq" -> SourceTransfer.PQ
        "hlg" -> SourceTransfer.HLG
        else -> SourceTransfer.SDR
    },
    primaries = if (primaries == "bt.2020") SourcePrimaries.BT2020 else SourcePrimaries.OTHER,
    maxCll = wholeNits(maxCll),
    maxFall = wholeNits(maxFall),
    maxLuminance = wholeNits(maxLuminance),
    minLuminance = minLuminance,
)

private fun wholeNits(value: Double): Long {
    if (!(value > 0.0)) return 0
    val rounded = value + 0.5
    if (rounded >= UINT32_MAX.toDouble()) return UINT32_MAX
    return floor(rounded).toLong().coerceAtLeast(1)
}
