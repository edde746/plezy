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
   * A MediaCodec decoder as [nativeDvDecoder] sees it: the component name,
   * one MIME type it serves, the profiles it advertises for that type
   * (`MediaCodecInfo.CodecProfileLevel` values) and the API 29+
   * `isSoftwareOnly` flag (false below, where the platform does not classify).
   */
  data class DvDecoderCandidate(val name: String, val mime: String, val profiles: List<Int>, val isSoftwareOnly: Boolean)

  /** The only MIME type the bundled FFmpeg asks MediaCodecList for a Dolby Vision decoder under. */
  const val DV_MIME = "video/dolby-vision"

  /** `MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheStn`: single-layer profile 5. */
  const val DV_PROFILE_DVHE_STN = 0x20

  /** `MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheSt`: single-layer profile 8. */
  const val DV_PROFILE_DVHE_ST = 0x100

  /** `MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheDtb`: dual-layer profile 7. */
  const val DV_PROFILE_DVHE_DTB = 0x80

  /**
   * The decoder the bundled FFmpeg's `hevc_mediacodec` will open for a
   * single-layer stream of [dvProfile] (5 or 8; null for any other profile,
   * including dual-layer P7, whose probes [dvRoute] makes), or null when it opens none — in which case
   * the base layer decodes as plain HEVC. Mirrors
   * `ff_AMediaCodecList_getCodecNameByType` exactly, because the previous
   * probe counted decoders FFmpeg never asks for and the two disagreed on
   * real devices: only [DV_MIME] (`video/hevcdv` and `video/dv_hevc` are
   * never probed), an exact `1 shl dvProfile` match
   * ([DV_PROFILE_DVHE_STN]/[DV_PROFILE_DVHE_ST]), `MediaCodecInfo
   * .isSoftwareOnly` skipped, and FFmpeg's own software name blacklist
   * skipped (`OMX.google*`, `OMX.ffmpeg*`, `OMX.SEC*.sw.*`,
   * `OMX.qcom.video.decoder.hevcswvdec`). First match in list order, as
   * FFmpeg takes it.
   */
  fun nativeDvDecoder(candidates: List<DvDecoderCandidate>, dvProfile: Long?): String? {
    val profileBit = when (dvProfile) {
      5L -> DV_PROFILE_DVHE_STN
      8L -> DV_PROFILE_DVHE_ST
      else -> return null
    }
    return dvDecoderFor(candidates, profileBit)
  }

  /** FFmpeg's `dv_probe_profile`: the first hardware [DV_MIME] decoder advertising exactly [profileBit]. */
  private fun dvDecoderFor(candidates: List<DvDecoderCandidate>, profileBit: Int): String? = candidates.firstOrNull { candidate ->
    !candidate.isSoftwareOnly &&
      !isFfmpegSoftwareDecoderName(candidate.name) &&
      candidate.mime.equals(DV_MIME, ignoreCase = true) &&
      profileBit in candidate.profiles
  }?.name

  /** What decodes a Dolby Vision file, as the performance overlay reports it (#2534). */
  enum class DvRoute(val id: String) {
    /** The [DV_MIME] decoder takes the stream as it is. */
    DV_DECODER("dv-decoder"),

    /** Profile 7's RPU is rewritten to 8.1 and the enhancement layer dropped, for a P8 [DV_MIME] decoder. */
    DV_DECODER_P81("dv-decoder-p81"),

    /** No DV decoder: the base layer decodes on its own and the RPU goes unused. */
    BASE_LAYER("base-layer"),

    /** Software decode on gpu-next, which applies the RPU itself (#1902). */
    RESHAPED("reshaped")
  }

  /**
   * The route the current file's video actually takes, for the overlay.
   * Reports what the fork FFmpeg's `dolby_vision_override` does with the
   * effective [decoderOptions] (mpv's `vd-lavc-o`, where a user's duplicate
   * key wins as it does in FFmpeg), rather than what the routing policy
   * asked for: [dvDecoderOptions] only says whether the DV decoder *may*
   * open. [hwdecCurrent] is the outcome check: a predicted DV decoder that
   * fails to open makes mpv fall back to software decode, which reads as
   * base layer or [DvRoute.RESHAPED] by [currentVo], never as the DV
   * decoder. MediaCodec output carries no RPU metadata, so only software
   * frames can be reshaped.
   *
   * Null when the track has no DOVI record ([dvProfile]) or no decoder is
   * open yet. P7 is predicted as dual-layer and every DV file as carrying
   * an RPU, because mpv exports neither `el_present_flag` nor
   * `rpu_present_flag`; FFmpeg uses the base layer when either assumption
   * is false.
   */
  fun dvRoute(
    dvProfile: Long?,
    decoderOptions: String?,
    candidates: List<DvDecoderCandidate>,
    hwdecCurrent: String?,
    currentVo: String?
  ): DvRoute? {
    if (dvProfile == null || hwdecCurrent.isNullOrBlank()) return null
    if (!hwdecCurrent.startsWith("mediacodec")) {
      return if (currentVo == "gpu-next") DvRoute.RESHAPED else DvRoute.BASE_LAYER
    }
    // FFmpeg's option defaults: dolby_vision=1, dv_p7_mode=auto.
    val dolbyVision = DecoderOptions.effectiveValue(decoderOptions, "dolby_vision")?.let(::avOptionBool) ?: true
    return when (dvProfile) {
      5L, 8L -> if (dolbyVision && nativeDvDecoder(candidates, dvProfile) != null) DvRoute.DV_DECODER else DvRoute.BASE_LAYER
      7L -> {
        // dolby_vision=0 leaves profile 7 on its base layer whatever dv_p7_mode says.
        val p7Mode = if (dolbyVision) dvP7Mode(DecoderOptions.effectiveValue(decoderOptions, "dv_p7_mode")) else "strip"
        when {
          p7Mode == "strip" -> DvRoute.BASE_LAYER
          p7Mode != "convert" && dvDecoderFor(candidates, DV_PROFILE_DVHE_DTB) != null -> DvRoute.DV_DECODER
          p7Mode != "native" && dvDecoderFor(candidates, DV_PROFILE_DVHE_ST) != null -> DvRoute.DV_DECODER_P81
          else -> DvRoute.BASE_LAYER
        }
      }
      // FFmpeg re-routes HEVC single-layer P5/P8 and dual-layer P7 only.
      else -> DvRoute.BASE_LAYER
    }
  }

  /** An `AV_OPT_TYPE_BOOL` value as FFmpeg parses it. */
  private fun avOptionBool(value: String): Boolean = when (value.lowercase()) {
    "false", "n", "no", "disable", "disabled", "off" -> false
    else -> value.toIntOrNull()?.let { it != 0 } ?: true
  }

  /** `dv_p7_mode` by constant name or its integer value. */
  private fun dvP7Mode(value: String?): String = when (value?.lowercase()) {
    "native", "1" -> "native"
    "convert", "2" -> "convert"
    "strip", "3" -> "strip"
    else -> "auto"
  }

  /** FFmpeg's `mediacodec_wrapper.c` software-decoder name blacklist, substring-matched as it does. */
  private fun isFfmpegSoftwareDecoderName(name: String): Boolean = name.contains("OMX.google") ||
    name.contains("OMX.ffmpeg") ||
    (name.contains("OMX.SEC") && name.contains(".sw.")) ||
    name == "OMX.qcom.video.decoder.hevcswvdec"

  /**
   * Whether a decoder that has fallen back to software is handing mpv an
   * unreshaped P5 base layer: [needsDvReshaping] predicted the native path
   * (or another decoder failed to open), but `hwdec-current` says the
   * stream is not on MediaCodec at all, so nothing composites the RPU
   * unless gpu-next does. [dvProfile] is the pending video track's profile
   * and [conversionMode] the session's; only `auto` routes, as in
   * [needsDvReshaping]. Reacting to the outcome is what keeps a wrong
   * prediction from scanning the base layer out as SDR BT.2020.
   */
  fun softwareDecodeNeedsDvReshaping(dvProfile: Long?, conversionMode: String, hwdecCurrent: String?): Boolean = needsSoftwareRender(hwdecCurrent) && dvProfile == 5L && conversionMode == "auto"

  /** `dolby_vision` and `dv_p7_mode` for the bundled FFmpeg's `vd-lavc-o`. */
  data class DvDecoderOptions(val dolbyVision: Boolean, val p7Mode: String)

  /** The `dv-conversion-mode` values [dvDecoderOptions] accepts. */
  val DV_CONVERSION_MODES: Set<String> = setOf("auto", "disabled", "native", "dv81", "hevc", "hevc_strip")

  /**
   * How the Dolby Vision decoder is driven for the file whose pending video
   * track carries [dvProfile] (null when the bitstream has no DOVI record,
   * or before any file is loaded) under [conversionMode]. Decided per file,
   * because `dolby_vision=1` sends every single-layer profile (5 and 8) to
   * the DV decoder and the right answer differs by profile. Paired with
   * [needsDvReshaping]: `dolby_vision=0` bypasses the DV decoder, so if this
   * says no for P5 while that says no reshaping, the P5 base layer reaches
   * the plane as plain HEVC with inverted colour. They disagreed once;
   * keeping them adjacent is the point.
   *
   * Only `auto` reads the device. With a DV display the DV decoder takes
   * every profile. Without one, only P5 goes to the DV decoder, and only when
   * the decoder FFmpeg will open advertises it ([canPlayP5Natively]): P5 has
   * no compatible base layer, so a converting decoder is the only hardware
   * path (measured on `c2.amlogic.dolby-vision.dvhe.decoder` against an
   * HDR10-only sink, #2290). P8 decodes as plain HEVC instead: its base layer
   * is compatible on its own, and what a DV decoder converts it *to* without
   * a DV sink is vendor-defined — the Shield's `OMX.Nvidia.DOVI.decode`
   * emits SDR, which scanned out muted with no HDR handoff (#2416). Dual-layer
   * P7 strips to its base layer either way. Throws for an unrecognised mode;
   * validate against [DV_CONVERSION_MODES] first.
   */
  fun dvDecoderOptions(conversionMode: String, displaySupportsDv: Boolean, dvProfile: Long?, canPlayP5Natively: Boolean): DvDecoderOptions = when (conversionMode) {
    "auto" -> when {
      displaySupportsDv -> DvDecoderOptions(dolbyVision = true, p7Mode = "auto")
      else -> DvDecoderOptions(dolbyVision = dvProfile == 5L && canPlayP5Natively, p7Mode = "strip")
    }
    "disabled", "native" -> DvDecoderOptions(dolbyVision = true, p7Mode = "native")
    "dv81" -> DvDecoderOptions(dolbyVision = true, p7Mode = "convert")
    "hevc", "hevc_strip" -> DvDecoderOptions(dolbyVision = true, p7Mode = "strip")
    else -> throw IllegalArgumentException("Invalid DV conversion mode: $conversionMode")
  }

  /** The conversion mode and display answer the DV routing decides with; see [dvRouting]. */
  data class DvRouting(val conversionMode: String, val displaySupportsDv: Boolean)

  /**
   * What [dvDecoderOptions], [needsDvReshaping] and
   * [softwareDecodeNeedsDvReshaping] are asked with, given the user's
   * [conversionMode], whether the display reports Dolby Vision, and the
   * user's "Disable Dolby Vision" setting ([dvOutputAllowed], #2543). With
   * Dolby Vision disabled the session routes as `auto` on a display without
   * Dolby Vision, whatever [conversionMode] says: single-layer P8 decodes as
   * plain HEVC and P7 strips to its base layer, so the TV receives the HDR10
   * (or HLG) the file carries instead of a Dolby Vision signal. P5 has no
   * compatible base layer and keeps that same route — the DV decoder when
   * the device has one, which still drives a Dolby Vision TV in Dolby
   * Vision, else software decode with gpu-next reshaping. Stripping P5
   * instead is the wrong-colour result Kodi's equivalent switch produces
   * (xbmc#26607).
   */
  fun dvRouting(conversionMode: String, displaySupportsDv: Boolean, dvOutputAllowed: Boolean): DvRouting = if (dvOutputAllowed) {
    DvRouting(conversionMode, displaySupportsDv)
  } else {
    DvRouting("auto", displaySupportsDv = false)
  }

  /** `hdr-sdr-conversion` values: who converts HDR for a display without HDR output. */
  val HDR_SDR_CONVERSION_MODES: Set<String> = setOf("auto", "device", "player")

  /**
   * The first API level whose platform converts an HDR layer for a display
   * without HDR output (Android 9). From P, AOSP SurfaceFlinger moves a PQ/HLG
   * layer to GPU composition when the HWC reports no HDR10/HLG and tone-maps
   * it in RenderEngine (libtonemap from 13). 7.x and 8.x have no such path,
   * which is the washed-out Fire OS 6 (API 25) report in #2121.
   */
  const val PLATFORM_HDR_TO_SDR_MIN_SDK = 28

  /**
   * Whether an HDR signal bound for a display without HDR output must leave
   * the video plane so mpv's GL vo tone-maps it. [conversionMode] is the
   * user's `hdr-sdr-conversion`: `device` keeps the plane and trusts the
   * platform, `player` always tone-maps in mpv, and `auto` keeps the plane
   * from [PLATFORM_HDR_TO_SDR_MIN_SDK]. The plane is what media3, Kodi and VLC
   * use for hardware-decoded HDR on SDR displays, and it costs no GPU time: a
   * Box R (Mali-G31) shows 4K HDR10 at ~11 fps through the GL vo and 25 fps on
   * the plane, where its Amlogic video layer converts. An HDR display keeps
   * the plane in every mode.
   */
  fun needsHdrToneMapping(gamma: String?, displaySupportsHdr: Boolean, conversionMode: String, sdkInt: Int): Boolean {
    if ((gamma != "pq" && gamma != "hlg") || displaySupportsHdr) return false
    return when (conversionMode) {
      "player" -> true
      "device" -> false
      "auto" -> sdkInt < PLATFORM_HDR_TO_SDR_MIN_SDK
      else -> throw IllegalArgumentException("Invalid HDR-to-SDR conversion mode: $conversionMode")
    }
  }

  /**
   * Whether the decoder is handing mpv software frames, from `hwdec-current`:
   * `no`, or `mediacodec-copy`, which reads frames back into system memory.
   * Only [softwareDecodeNeedsDvReshaping] asks; leaving the plane for such a
   * stream is mpv's own report (`vo-format-rejected`, [REASON_FORMAT_REJECTED]).
   */
  fun needsSoftwareRender(hwdecCurrent: String?): Boolean = !hwdecCurrent.isNullOrBlank() && hwdecCurrent != "mediacodec"

  /**
   * Select native software decoding before opening a decoder when hardware
   * cannot serve the stream. H.264 High 10 needs an advertised profile
   * (#2065); AV1 without a hardware decoder goes to dav1d directly rather
   * than through a software MediaCodec component (`c2.android.av1*`), which
   * only adds a process hop and a copy. Tensor's `c2.google.av1.decoder` is
   * hardware and stays on this path; its rebuild hazard is handled by
   * [needsParkedRebuild] (#2272). [codec] and [codecProfile] come from mpv's
   * pending video track.
   */
  fun needsSoftwareDecode(
    codec: String?,
    codecProfile: String?,
    hardwareHigh10: Boolean,
    hardwareAv1: Boolean
  ): Boolean = when (codec) {
    "h264" -> !hardwareHigh10 && codecProfile?.startsWith("High 10") == true
    "av1" -> !hardwareAv1
    else -> false
  }

  /**
   * Whether a video-chain rebuild — a vo switch (the plane to a GL renderer
   * or back), or a surface handoff while a GL renderer is live — must run
   * with the video track deselected. mpv re-creates the decoder inside that
   * rebuild, and Tensor's BigOcean AV1 service (`c2.google.av1.decoder`)
   * crashes when the next instance starts while the previous one is still
   * shutting down; mpv then lands on mediacodec-copy or software, and the
   * plane cannot show either (#2272). Deselecting first closes the old
   * instance, the rebuild runs without a decoder, and re-selecting creates
   * the next one against the finished output. Only an AV1 session that asks
   * for hardware decoding on that decoder pays the extra track switch.
   * A surface handoff on the plane is not a rebuild: the fork vo repoints
   * the running decoder at the new Surface in place. [codec] is the current
   * video track's codec; [hwdec] is the `hwdec` option (not `hwdec-current`,
   * which lags a freshly re-selected decoder).
   */
  fun needsParkedRebuild(codec: String?, hwdec: String?, bigOceanAv1: Boolean): Boolean = bigOceanAv1 && codec == "av1" && !hwdec.isNullOrBlank() && hwdec != "no"

  /**
   * The video track the per-file policies ([needsDvReshaping],
   * [needsSoftwareDecode]) decide for, or null when no video track will be
   * selected. They run inside on_preloaded, where the track list is complete
   * but nothing is selected yet, so "the selected track" does not exist:
   * `vid` still reads the option value, and mpv's own selection
   * (default/forced flags, --vlang, attached pictures skipped) only runs
   * after the hook. [vid] is the `vid` property: `no` and an explicit id are
   * authoritative on their own; `auto` defers to [pendingVid], the fork's
   * `pending-vid` property, which runs that selection ahead of time. A null
   * [pendingVid] means the libmpv has no such property, and the first track
   * in [videoTrackIds] (track-list order) is the best guess left — wrong for
   * files whose first video track is not the one mpv picks.
   */
  fun pendingVideoTrackId(vid: String?, pendingVid: String?, videoTrackIds: List<Long>): Long? {
    val requested = when {
      vid == null || vid == "auto" -> pendingVid ?: return videoTrackIds.firstOrNull()
      else -> vid
    }
    val id = requested.toLongOrNull() ?: return null
    return id.takeIf { it in videoTrackIds }
  }

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
  const val REASON_FORMAT_REJECTED = "format-rejected"
  const val REASON_HDR_SDR = "hdr-sdr"
  const val REASON_CODEC_SW_DECODE = "codec-sw-decode"
}
