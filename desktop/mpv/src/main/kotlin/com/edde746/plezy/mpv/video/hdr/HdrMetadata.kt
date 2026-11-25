package com.edde746.plezy.mpv.video.hdr

/*
 * The source's HDR10 static metadata and the rules for turning it into colour-management-v1 requests the compositor
 * accepts, plus the decision whether the video plane carries HDR at all. No Wayland here: the validation is the
 * interesting part, and getting it wrong is a protocol error that disconnects the client, so it is tested without a
 * compositor. Nit values are uint32 on the wire and held as Long in 0..0xFFFFFFFF.
 */

/**
 * The source's transfer function, so far as describing the plane cares. Every SDR curve collapses to [SDR]: the plane
 * is then left undescribed and mpv's normal output is already right.
 */
internal enum class SourceTransfer { SDR, PQ, HLG }

/**
 * The source's container primaries. Only BT.2020 has a named counterpart worth describing for video; everything else
 * leaves the plane undescribed.
 */
internal enum class SourcePrimaries { OTHER, BT2020 }

/**
 * What the current source is, plus its HDR10 static metadata from mpv's `video-params`. A zero luminance means the
 * source did not state it.
 *
 * The colorimetry matters as much as the luminances: describing a plane as PQ / BT.2020 because a setting is on,
 * rather than because the stream is, tells the compositor to undo a transform that was never applied. Equality covers
 * every field, so a changed source is never mistaken for the one already described.
 */
internal data class HdrMetadata(
    val transfer: SourceTransfer = SourceTransfer.SDR,
    val primaries: SourcePrimaries = SourcePrimaries.OTHER,
    /** Nits, maximum content light level. */
    val maxCll: Long = 0,
    /** Nits, maximum frame-average light level. */
    val maxFall: Long = 0,
    /** Nits, mastering display maximum. */
    val maxLuminance: Long = 0,
    /** Nits, mastering display minimum. */
    val minLuminance: Double = 0.0,
) {
    /** The source carries an HDR transfer function, i.e. there is anything to pass through at all. */
    val isHdr: Boolean get() = transfer != SourceTransfer.SDR
}

/**
 * Who reduces the source's dynamic range to what the display shows.
 *
 * [COMPOSITOR] is passthrough: the source's metadata is declared and the compositor's curve does the work. It adapts
 * to monitor changes with no re-render, but a source that declares no metadata is assumed to reach the curve's
 * maximum, which rolls highlights off far harder than the content needs.
 *
 * [PLAYER] tone-maps in mpv to the display's real peak and declares that peak, leaving the compositor an identity
 * transform.
 */
internal enum class HdrToneMapping { COMPOSITOR, PLAYER }

/**
 * The primary colour volume maxima the protocol attaches to each named transfer function. Not interchangeable: PQ
 * swings to 10000 cd/m², HLG is relative to a 1000 cd/m² display. An HLG stream declaring a 4000-nit MaxCLL with no
 * mastering range passes a PQ-shaped check and then trips a fatal invalid_luminance.
 */
internal const val PQ_MAX_LUMINANCE_NITS = 10000L
internal const val HLG_MAX_LUMINANCE_NITS = 1000L

/** The protocol carries the mastering minimum scaled by this, keeping four decimals of a fraction of a nit. */
internal const val MIN_LUMINANCE_SCALE = 10000L

/**
 * The primary colour volume floor both PQ and HLG declare, 0.005 cd/m², in scaled units. Containment is two-sided: a
 * mastering range below it leaves the volume as surely as one above its maximum. Sources routinely declare 0.0001 or
 * nothing, so this is the common case.
 */
internal const val PRIMARY_VOLUME_MIN_SCALED = 50L

/**
 * The primary colour volume maximum for [transfer]. Light levels are bounded by it when no mastering luminance is
 * sent, because an unset mastering range takes the primary colour volume's range.
 */
internal fun primaryVolumeMaxNits(transfer: SourceTransfer): Long =
    if (transfer == SourceTransfer.HLG) HLG_MAX_LUMINANCE_NITS else PQ_MAX_LUMINANCE_NITS

/** What the compositor advertised, which decides how much of the source's metadata may be forwarded. */
internal data class CompositorLuminanceSupport(
    /** feature.set_mastering_display_primaries; without it set_mastering_luminance is unsupported_feature. */
    val mastering: Boolean = false,
    /**
     * feature.extended_target_volume; without it only target volumes fully contained in the primary colour volume are
     * promised, and exceeding it may fail the description.
     */
    val extendedTargetVolume: Boolean = false,
    /** Bound wp_color_manager_v1 version; see [planHdrLuminance] for what the versions differ about. */
    val interfaceVersion: Int = 1,
)

/**
 * Which luminance requests to emit. A false flag leaves the field unset so the compositor applies its own default,
 * which is always safer than a value the protocol rejects.
 */
internal data class HdrLuminancePlan(
    val sendMastering: Boolean = false,
    val masteringMinScaled: Long = 0,
    val masteringMax: Long = 0,
    val sendMaxCll: Boolean = false,
    val maxCll: Long = 0,
    val sendMaxFall: Boolean = false,
    val maxFall: Long = 0,
)

/**
 * A mastering minimum in nits as the protocol's scaled units, rounded half up and saturating at 0xFFFFFFFF. NaN and
 * anything not positive is 0: the negated comparison is what keeps NaN out.
 */
internal fun scaleMinLuminance(nits: Double): Long {
    if (!(nits > 0.0)) return 0
    val scaled = nits * MIN_LUMINANCE_SCALE + 0.5
    if (scaled >= UINT32_MAX.toDouble()) return UINT32_MAX
    return scaled.toLong()
}

/**
 * [valueNits] sits inside the mastering range, which version 1 spells as strictly greater than min L and at most max
 * L. The minimum is compared in scaled units.
 */
internal fun luminanceInMasteringRange(valueNits: Long, minScaled: Long, maxNits: Long): Boolean {
    if (valueNits > maxNits) return false
    return valueNits * MIN_LUMINANCE_SCALE > minScaled
}

/**
 * Which of set_mastering_luminance / set_max_cll / set_max_fall may be sent for [metadata] given [support].
 *
 * Every rule here guards a protocol error on create(), not a failed description: the compositor disconnects the
 * client. Badly authored HDR violates them (MaxCLL above the mastering peak is common, MaxFALL above MaxCLL happens),
 * so the stream is never trusted.
 */
internal fun planHdrLuminance(metadata: HdrMetadata, support: CompositorLuminanceSupport): HdrLuminancePlan {
    val volumeMax = primaryVolumeMaxNits(metadata.transfer)

    // Mastering needs the advertised feature and max L strictly above min L. Without extended_target_volume both ends
    // are clamped into the primary colour volume: the maximum down to the curve's ceiling, the minimum up to the
    // 0.005-nit floor. Clamping rather than dropping, because the mastering maximum is the compositor's fallback peak
    // when there is no MaxCLL.
    val masteringCeiling = if (support.extendedTargetVolume) PQ_MAX_LUMINANCE_NITS else volumeMax
    val masteringFloorScaled = if (support.extendedTargetVolume) 0L else PRIMARY_VOLUME_MIN_SCALED
    val masteringMax = metadata.maxLuminance.coerceAtMost(masteringCeiling)
    val masteringMinScaled = scaleMinLuminance(metadata.minLuminance).coerceAtLeast(masteringFloorScaled)
    val sendMastering =
        support.mastering && masteringMax > 0 && masteringMax * MIN_LUMINANCE_SCALE > masteringMinScaled

    // With no mastering request the primary colour volume is the range, so HLG is bounded at 1000 either way.
    val rangeMax = if (sendMastering) masteringMax else volumeMax
    val rangeMinScaled = if (sendMastering) masteringMinScaled else 0L

    // The curve has no code point above its volume maximum in either version; with extended_target_volume the
    // mastering range may reach 10000 even for HLG, so rangeMax alone is not enough. The light level goes, not the
    // mastering range, which is the more trustworthy of the two.
    var sendMaxCll = metadata.maxCll in 1..volumeMax
    var sendMaxFall = metadata.maxFall in 1..volumeMax

    // Version 1 also requires both inside the mastering range; version 2 dropped that.
    if (support.interfaceVersion < 2) {
        if (sendMaxCll && !luminanceInMasteringRange(metadata.maxCll, rangeMinScaled, rangeMax)) sendMaxCll = false
        if (sendMaxFall && !luminanceInMasteringRange(metadata.maxFall, rangeMinScaled, rangeMax)) sendMaxFall = false
    }

    // Every version requires max_fall <= max_cll while both are set, so it is judged after the drops above. MaxFALL
    // goes: it is the less trustworthy field and no compositor curve consults it.
    if (sendMaxCll && sendMaxFall && metadata.maxFall > metadata.maxCll) sendMaxFall = false

    return HdrLuminancePlan(
        sendMastering = sendMastering,
        masteringMinScaled = if (sendMastering) masteringMinScaled else 0L,
        masteringMax = if (sendMastering) masteringMax else 0L,
        sendMaxCll = sendMaxCll,
        maxCll = metadata.maxCll,
        sendMaxFall = sendMaxFall,
        maxFall = metadata.maxFall,
    )
}

/**
 * [source] rewritten to describe a signal mpv tone-mapped to [peakNits] (clamped to the curve's volume). Once mpv has
 * mapped the content down, declaring the source's original range would have the compositor compress levels that are
 * no longer there. Curve, gamut and the mastering floor are unchanged. MaxFALL is kept only while it still fits under
 * the new peak, since a frame average equal to the peak would be a claim nobody measured. A zero peak means unknown and
 * changes nothing.
 */
internal fun describeTonemappedTo(source: HdrMetadata, peakNits: Long): HdrMetadata {
    if (peakNits == 0L) return source
    val peak = peakNits.coerceAtMost(primaryVolumeMaxNits(source.transfer))
    return source.copy(
        maxLuminance = peak,
        maxCll = peak,
        maxFall = if (source.maxFall in 1..peak) source.maxFall else 0L,
    )
}

/**
 * The output's reported luminances leave enough room above its diffuse white to pass HDR through rather than
 * tone-map here.
 *
 * A headroom question, because no colour-management-v1 signal says "HDR is on": compositors now report their blending
 * space (gamma 2.2, extended range) as the preferred description whether or not it is. Headroom describes the panel.
 *
 * The margin is half a stop (max at least 1.5 × reference): a compositor that dims SDR white in software keeps
 * reporting the undimmed maximum, so a bare `max > reference` reads an 80%-brightness SDR output (200 over 161) as HDR.
 * Every HDR output clears it (a 400-nit panel reports 400 over 203). Stated as 2·max ≥ 3·reference so the boundary
 * is exact and nothing overflows on unvalidated values.
 */
internal fun outputHasHdrHeadroom(maxLuminance: Long, referenceLuminance: Long): Boolean {
    if (referenceLuminance == 0L) return false
    return maxLuminance * 2 >= referenceLuminance * 3
}

/** The named primaries and curves the compositor advertised. */
internal data class CompositorColorSupport(
    val bt2020: Boolean = false,
    val pq: Boolean = false,
    val hlg: Boolean = false,
)

/**
 * This source can be described to the compositor: an HDR curve over BT.2020, each advertised. Naming a curve the
 * compositor never advertised is a fatal invalid_tf on create(), which disconnects the client.
 */
internal fun sourceIsDescribable(metadata: HdrMetadata, support: CompositorColorSupport): Boolean {
    if (!metadata.isHdr) return false
    if (metadata.primaries != SourcePrimaries.BT2020 || !support.bt2020) return false
    return when (metadata.transfer) {
        SourceTransfer.PQ -> support.pq
        SourceTransfer.HLG -> support.hlg
        SourceTransfer.SDR -> false
    }
}

/** Everything outside the source that bears on whether the plane carries HDR. */
internal data class HdrInputs(
    /** The user's permission (the HDR setting). */
    val allowed: Boolean = false,
    /** 10-bit plane, colour-managed surface, advertised curve. */
    val clientCanDescribe: Boolean = false,
    /** The output offers headroom above reference white. */
    val outputIsHdr: Boolean = false,
    /** This source's curve and gamut are both advertised. */
    val sourceDescribable: Boolean = false,
    val requested: HdrToneMapping = HdrToneMapping.COMPOSITOR,
    /** The output's peak while in HDR; 0 means unknown. */
    val displayPeakNits: Long = 0,
    /**
     * The output's diffuse-white luminance, the most an SDR signal reaches on it; distinct from [displayPeakNits],
     * which only a described signal can reach. 0 means unknown.
     */
    val sdrReferenceNits: Long = 0,
)

/** What to do about it. */
internal data class HdrDecision(
    /** Attach an image description at all. */
    val describe: Boolean = false,
    /** mpv reduces the range rather than the compositor. */
    val toneMapInPlayer: Boolean = false,
    /**
     * The peak mpv aims at, and while described also the peak declared to the compositor: one number, because the two
     * disagreeing makes a compositor remap the signal twice. Zero leaves target-peak on auto.
     */
    val targetPeakNits: Long = 0,
)

/** [nits] clamped to [volumeMax], or 0 below 10: mpv's target-peak accepts 10..10000, and auto is the honest answer. */
internal fun usableTargetPeak(nits: Long, volumeMax: Long): Long {
    val clamped = nits.coerceAtMost(volumeMax)
    return if (clamped >= 10) clamped else 0L
}

/**
 * The single gate. The setting, the compositor's capabilities, the output's state and the file must all allow it
 * before the plane is described as HDR; any one failing falls back to mpv's tone-mapped SDR output, which is always
 * safe.
 *
 * Undescribed, an HDR source is mapped to the output's diffuse white: the buffer is an ordinary SDR signal, and
 * claiming the HDR peak would ask for range the encoding cannot express. An SDR source keeps the peak on auto, so plain
 * SDR playback is untouched. Described in player mode, mpv maps to the display's peak clamped to the curve's volume,
 * so the peak handed to mpv and the one declared are the same number.
 */
internal fun decideHdr(inputs: HdrInputs, source: HdrMetadata): HdrDecision {
    val describe = inputs.allowed && inputs.clientCanDescribe && inputs.outputIsHdr && inputs.sourceDescribable &&
        source.isHdr
    if (!describe) {
        if (!source.isHdr) return HdrDecision()
        // No curve is declared, so the only ceiling is what the option accepts.
        val peak = usableTargetPeak(inputs.sdrReferenceNits, PQ_MAX_LUMINANCE_NITS)
        return HdrDecision(describe = false, toneMapInPlayer = peak > 0, targetPeakNits = peak)
    }
    if (inputs.requested == HdrToneMapping.PLAYER && inputs.displayPeakNits > 0) {
        val peak = usableTargetPeak(inputs.displayPeakNits, primaryVolumeMaxNits(source.transfer))
        if (peak > 0) return HdrDecision(describe = true, toneMapInPlayer = true, targetPeakNits = peak)
    }
    return HdrDecision(describe = true)
}

/** The largest uint32, where nit values saturate. */
internal const val UINT32_MAX = 0xFFFFFFFFL
