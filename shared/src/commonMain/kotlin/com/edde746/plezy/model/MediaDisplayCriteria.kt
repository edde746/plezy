package com.edde746.plezy.model

/** The transfer, primaries and matrix tags of a colour classification; null where it has none. */
data class MediaDisplayColorTags(val transfer: String?, val primaries: String?, val matrix: String?)

enum class MediaDisplayColorType(val isHdr: Boolean) {
    DOLBY_VISION(true),
    HLG(true),
    PQ(true),
    SDR(false),
    UNKNOWN(false),
    ;

    /** The tags a display switch assumes for this classification when the stream reports none. */
    val defaultTags: MediaDisplayColorTags
        get() = when (this) {
            HLG -> MediaDisplayColorTags("arib-std-b67", "bt2020", "bt2020nc")
            PQ -> MediaDisplayColorTags("smpte2084", "bt2020", "bt2020nc")
            SDR -> MediaDisplayColorTags("bt709", "bt709", "bt709")
            DOLBY_VISION, UNKNOWN -> MediaDisplayColorTags(null, null, null)
        }
}

/**
 * Classifies already-extracted display metadata without relying on a backend JSON shape. Compatibility IDs describe
 * the Dolby Vision base layer. HLG wins over PQ, PQ over SDR, and an explicit base layer over Dolby Vision itself.
 */
fun classifyMediaDisplayColor(
    isDolbyVision: Boolean = false,
    doviCompatibilityId: Int? = null,
    range: String? = null,
    transfer: String? = null,
    primaries: String? = null,
    matrix: String? = null,
    assumeSdr: Boolean = false,
): MediaDisplayColorType {
    val tags = listOfNotNull(range, transfer, primaries, matrix).joinToString(" ").lowercase().replace(NON_ALNUM, "")
    if (doviCompatibilityId == 4 || "hlg" in tags || "arib" in tags) return MediaDisplayColorType.HLG
    if (doviCompatibilityId == 1 ||
        doviCompatibilityId == 6 ||
        "hdr" in tags ||
        "pq" in tags ||
        "smpte2084" in tags ||
        "st2084" in tags ||
        "bt2020" in tags
    ) {
        return MediaDisplayColorType.PQ
    }
    if (doviCompatibilityId == 2) return MediaDisplayColorType.SDR
    if (isDolbyVision) return MediaDisplayColorType.DOLBY_VISION
    if ("sdr" in tags || "bt709" in tags || assumeSdr) return MediaDisplayColorType.SDR
    return MediaDisplayColorType.UNKNOWN
}

private val NON_ALNUM = Regex("[^a-z0-9]")

/**
 * Backend-neutral description of a source's video stream as the server reports it. Display matching reads the decoded
 * stream from the player instead (server metadata is missing or wrong for transcodes and Live TV, and cannot see what
 * the filter chain does to the rate); this feeds the HDR classification of stream details.
 */
data class MediaDisplayCriteria(
    val fps: Double? = null,
    val width: Int? = null,
    val height: Int? = null,
    val doviProfile: Int? = null,
    val doviLevel: Int? = null,
    val doviCompatibilityId: Int? = null,
    val transfer: String? = null,
    val primaries: String? = null,
    val matrix: String? = null,
) {
    val hasDimensions: Boolean get() = (width ?: 0) > 0 && (height ?: 0) > 0

    val hasFrameRate: Boolean get() = (fps ?: 0.0) > 0

    val hasDisplayMetadata: Boolean
        get() = (doviProfile ?: 0) > 0 || !transfer.isNullOrEmpty() || !primaries.isNullOrEmpty() || !matrix.isNullOrEmpty()

    /** Whether the server said enough to describe a stream: a rate, or dimensions plus colour/Dolby Vision tags. */
    val isUsable: Boolean get() = hasFrameRate || (hasDimensions && hasDisplayMetadata)

    val colorType: MediaDisplayColorType
        get() = classifyMediaDisplayColor(
            isDolbyVision = (doviProfile ?: 0) > 0,
            doviCompatibilityId = doviCompatibilityId,
            transfer = transfer,
            primaries = primaries,
            matrix = matrix,
        )

    val isHdr: Boolean get() = colorType.isHdr

    companion object {
        /**
         * From server values that may arrive as numbers or numeric strings; strings are trimmed and blank ones dropped.
         */
        fun fromRaw(
            fps: Any? = null,
            width: Any? = null,
            height: Any? = null,
            doviProfile: Any? = null,
            doviLevel: Any? = null,
            doviCompatibilityId: Any? = null,
            transfer: Any? = null,
            primaries: Any? = null,
            matrix: Any? = null,
        ): MediaDisplayCriteria = MediaDisplayCriteria(
            fps = flexibleDouble(fps),
            width = flexibleInt(width),
            height = flexibleInt(height),
            doviProfile = flexibleInt(doviProfile),
            doviLevel = flexibleInt(doviLevel),
            doviCompatibilityId = flexibleInt(doviCompatibilityId),
            transfer = stringOrNull(transfer),
            primaries = stringOrNull(primaries),
            matrix = stringOrNull(matrix),
        )

        private fun flexibleInt(value: Any?): Int? = when (value) {
            is Number -> value.toInt()
            is String -> value.trim().toIntOrNull()
            else -> null
        }

        private fun flexibleDouble(value: Any?): Double? = when (value) {
            is Number -> value.toDouble()
            is String -> value.trim().toDoubleOrNull()
            else -> null
        }

        private fun stringOrNull(value: Any?): String? = value?.toString()?.trim()?.takeIf { it.isNotEmpty() }
    }
}
