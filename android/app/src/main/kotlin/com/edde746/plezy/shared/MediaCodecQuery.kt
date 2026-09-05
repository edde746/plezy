package com.edde746.plezy.shared

import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.os.Build
import java.util.Locale

/** Canonical decoder lookup and hardware classification for native playback. */
internal object MediaCodecQuery {
  /**
   * Codecs whose advertised support is decided by hardware: both have a
   * software decoder behind them, but a software HEVC or AV1 decode on
   * phone/TV-class hardware drops frames.
   */
  private val HARDWARE_GATED_VIDEO_MIME_TYPES = mapOf(
    "hevc" to "video/hevc",
    "av1" to "video/av01"
  )

  /** Codec name -> whether this device has a hardware decoder for it. */
  fun hardwareVideoDecodeSupport(
    hardwareMimeTypes: Set<String> = hardwareDecoderMimeTypes()
  ): Map<String, Boolean> = HARDWARE_GATED_VIDEO_MIME_TYPES.mapValues { (_, mimeType) -> mimeType in hardwareMimeTypes }

  /**
   * Every MIME type served by a hardware decoder, lowercased. One walk answers
   * for all codecs, unlike [findHardwareDecoder], which rescans per lookup.
   */
  private fun hardwareDecoderMimeTypes(): Set<String> {
    val mimeTypes = HashSet<String>()
    for (info in MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos) {
      if (info.isEncoder || !isHardwareAccelerated(info)) continue
      for (type in info.supportedTypes) mimeTypes.add(type.lowercase(Locale.ROOT))
    }
    return mimeTypes
  }

  /**
   * Whether a hardware `video/avc` decoder advertises H.264 High 10 (Hi10P).
   * Decoders that do not advertise it either refuse the stream (this is what
   * the mpv/FFmpeg MediaCodec path sees) or, on some SoCs, accept it and
   * render garbage; neither is a reason to let the hardware path try first
   * (#2065). Answered once per process: the codec list is static.
   */
  fun hardwareAvcHigh10Support(): Boolean = hardwareAvcHigh10.value

  private val hardwareAvcHigh10: Lazy<Boolean> = lazy {
    findHardwareDecoder("video/avc") { info, type ->
      val profiles = try {
        info.getCapabilitiesForType(type).profileLevels
      } catch (e: IllegalArgumentException) {
        return@findHardwareDecoder false
      }
      profiles.any { it.profile == MediaCodecInfo.CodecProfileLevel.AVCProfileHigh10 }
    } != null
  }

  fun findHardwareDecoder(
    mimeType: String,
    codecKind: Int = MediaCodecList.REGULAR_CODECS,
    predicate: (MediaCodecInfo, String) -> Boolean = { _, _ -> true }
  ): MediaCodecInfo? {
    for (info in MediaCodecList(codecKind).codecInfos) {
      if (info.isEncoder || !isHardwareAccelerated(info)) continue
      for (type in info.supportedTypes) {
        if (type.equals(mimeType, ignoreCase = true) && predicate(info, type)) {
          return info
        }
      }
    }
    return null
  }

  fun isHardwareAccelerated(info: MediaCodecInfo): Boolean {
    val name = info.name
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      isHardwareAccelerated(Build.VERSION.SDK_INT, info.isHardwareAccelerated, name)
    } else {
      // MediaCodecInfo.isHardwareAccelerated() does not exist before API 29.
      // Keep the call inside the version gate so older Fire OS releases do not
      // fail with NoSuchMethodError while initializing playback.
      isHardwareAccelerated(Build.VERSION.SDK_INT, false, name)
    }
  }

  internal fun isHardwareAccelerated(
    sdkInt: Int,
    platformReportsHardware: Boolean,
    name: String
  ): Boolean {
    // API 29 added manufacturer-provided classification, but some Codec2
    // builders still flag known software components as hardware. Require both
    // signals there; older releases expose only component names.
    return if (sdkInt >= Build.VERSION_CODES.Q) {
      platformReportsHardware && !isSoftwareCodecName(name)
    } else {
      !isSoftwareCodecName(name)
    }
  }

  internal fun isSoftwareCodecName(name: String): Boolean {
    val normalized = name.lowercase(Locale.ROOT)
    return normalized.startsWith("omx.google.") ||
      normalized.startsWith("omx.ffmpeg.") ||
      normalized.startsWith("c2.android.") ||
      normalized.startsWith("c2.google.") ||
      normalized.startsWith("c2.ffmpeg.") ||
      normalized.contains(".sw.")
  }
}
