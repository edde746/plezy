package com.edde746.plezy.mpv

/**
 * Pure policy for when an mpv session must leave the video plane
 * (vo=mediacodec) for a GL video output, and which one. Kept free of player
 * and platform state so the routing matrix is unit-testable.
 */
internal object GpuVoPolicy {
  /**
   * Single-layer Dolby Vision Profile 5 (IPT-PQ-c2) has no compatible base
   * layer: on a device without native DV support it decodes as plain HEVC
   * with garbage colors, and the video plane applies no reshaping. gpu-next
   * (libplacebo) under software decode is the only Android path that
   * composites the RPU metadata (#1902). [dvProfile] comes from mpv's
   * track-list — the bitstream's DOVI configuration record — never from
   * server metadata, which mis-tags DV routinely. Only `auto` routes; the
   * other modes are explicit user choices.
   */
  fun needsDvReshaping(dvProfile: Long?, conversionMode: String, canPlayP5Natively: Boolean): Boolean = dvProfile == 5L && conversionMode == "auto" && !canPlayP5Natively

  /**
   * Whether an HDR signal has nowhere to tone-map: the video plane hands
   * PQ/HLG straight to a display pipeline that advertises no HDR output, so
   * it renders washed out (#2121). The GL vo tone-maps in the render chain.
   */
  fun needsHdrToneMapping(gamma: String?, displaySupportsHdr: Boolean): Boolean = (gamma == "pq" || gamma == "hlg") && !displaySupportsHdr

  /**
   * Whether the decoder is handing mpv software frames, from `hwdec-current`.
   *
   * The plane refuses every format but MediaCodec buffers, so a per-file
   * decode fallback (AV1 on Tegra, Hi10 without a profile match) has to move
   * to a GL vo. Routing on this gets there before mpv fails the chain and
   * [REASON_CHAIN_FAILURE] has to catch it.
   */
  fun needsSoftwareRender(hwdecCurrent: String?): Boolean = !hwdecCurrent.isNullOrBlank() && hwdecCurrent != "mediacodec"

  /**
   * The vo a session with these active requirements should run, or null for
   * the video plane.
   *
   * dv-reshape is the only reason that needs gpu-next, since libplacebo is
   * what composites the RPU. Everything else takes gpu, the battle-tested
   * GLES renderer on the Android device zoo. (The magenta field gpu-next
   * used to render for 10-bit software frames on Tegra was its AV1 film
   * grain shader overrunning the driver's uniform register budget; grain is
   * decoder-applied now, but gpu-next buys this path nothing over gpu.)
   */
  fun targetFor(reasons: Set<String>): String? = when {
    reasons.isEmpty() -> null
    REASON_DV_RESHAPE in reasons -> "gpu-next"
    else -> "gpu"
  }

  const val REASON_DV_RESHAPE = "dv-reshape"
  const val REASON_SHADERS = "shaders"
  const val REASON_CHAIN_FAILURE = "chain-failure"
  const val REASON_HDR_SDR = "hdr-sdr"
  const val REASON_SW_DECODE = "sw-decode"
}
