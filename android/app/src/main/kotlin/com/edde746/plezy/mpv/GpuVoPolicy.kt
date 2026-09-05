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
   * Whether a video track must be software-decoded up front because the
   * bitstream is H.264 High 10 and no hardware decoder advertises the
   * profile (#2065). Without this the session still ends up in software —
   * MediaCodec refuses the stream, FFmpeg falls back, the 10-bit frames
   * cannot enter the video plane and the chain fails — but only after a
   * decoder init, a failed video chain and a vo recreation, several seconds
   * of black with audio already running. [codec] and [codecProfile] come
   * from mpv's track-list; the profile string is FFmpeg's
   * (`avcodec_profile_name`: "High 10", "High 10 Intra").
   */
  fun needsSoftwareDecode(codec: String?, codecProfile: String?, hardwareHigh10: Boolean): Boolean = !hardwareHigh10 && codec == "h264" && codecProfile?.startsWith("High 10") == true

  /**
   * Whether a GL vo session should drop to the cheap render tier: bilinear
   * scalers and no dither. Keyed on `GL_EXT_texture_norm16` being absent,
   * which on Android singles out the low-end Mali/Adreno TV class whose
   * texture units cannot afford a second full-resolution pass at 1080p
   * (measured on an S905X4/Mali-G31: mpv's default lanczos chroma pass alone
   * runs the frame over budget, bilinear brings it back under; every
   * norm16-capable GPU tested renders the whole default ladder in a few
   * milliseconds). The video plane never scales in GL, so hardware sessions
   * on it are untouched.
   */
  fun needsCheapRenderTier(glVoActive: Boolean, textureNorm16: Boolean): Boolean = glVoActive && !textureNorm16

  /** mpv option -> value for the cheap render tier, applied only where the
   * option still carries its mpv default (a user's mpv.conf line wins). */
  val CHEAP_RENDER_OPTIONS: Map<String, String> = linkedMapOf(
    "scale" to "bilinear",
    "cscale" to "bilinear",
    "dscale" to "bilinear",
    "dither" to "no"
  )

  /** The values mpv 0.41 reports for [CHEAP_RENDER_OPTIONS] when nothing
   * set them; anything else is a user choice and stays. `cscale` inherits
   * `scale` by default, which the property reads back as an empty string
   * (measured on 0.41) or `inherit`. */
  val MPV_DEFAULT_RENDER_OPTIONS: Map<String, Set<String>> = mapOf(
    "scale" to setOf("lanczos"),
    "cscale" to setOf("", "inherit"),
    "dscale" to setOf("hermite"),
    "dither" to setOf("fruit")
  )

  /** Whether [value] is what mpv reports for [option] by default. */
  fun isDefaultRenderOption(option: String, value: String?): Boolean = value != null && MPV_DEFAULT_RENDER_OPTIONS[option]?.contains(value) == true

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
  const val REASON_HI10_SW_DECODE = "hi10-sw-decode"
}
