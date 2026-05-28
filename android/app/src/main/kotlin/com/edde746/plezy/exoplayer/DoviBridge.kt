package com.edde746.plezy.exoplayer

import android.content.Context
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.os.Build
import android.util.Log
import android.view.Display
import android.view.WindowManager

enum class DvConversionMode { DISABLED, DV81, HEVC_STRIP }

object DoviBridge {
  private const val TAG = "DoviBridge"

  private val DOLBY_VISION_MIME_TYPES = setOf(
    "video/dolby-vision",
    "video/hevcdv",
    "video/dv_hevc"
  )

  const val CONVERT_FAILED = -1
  const val DESTINATION_TOO_SMALL = -2

  private data class DvProfileLevel(val profile: Int, val level: Int)

  private data class DvDecoderCapability(
    val name: String,
    val mimeType: String,
    val profileLevels: List<DvProfileLevel>
  )

  private val nativeLoaded: Boolean by lazy {
    try {
      System.loadLibrary("dovi_bridge")
      true
    } catch (_: UnsatisfiedLinkError) {
      Log.w(TAG, "Native lib not found")
      false
    }
  }

  private val conversionPathReady: Boolean by lazy {
    nativeLoaded && runCatching { nativeIsConversionPathReady() }.getOrDefault(false)
  }

  fun isAvailable(): Boolean = conversionPathReady

  private val dolbyVisionDecoders: List<DvDecoderCapability> by lazy {
    try {
      val codecList = MediaCodecList(MediaCodecList.REGULAR_CODECS)
      codecList.codecInfos.flatMap { info ->
        if (info.isEncoder) {
          emptyList()
        } else {
          info.supportedTypes.mapNotNull { type ->
            if (!DOLBY_VISION_MIME_TYPES.contains(type.lowercase())) return@mapNotNull null
            val capabilities = runCatching { info.getCapabilitiesForType(type) }
              .onFailure { Log.w(TAG, "Failed to query ${info.name} capabilities for $type", it) }
              .getOrNull()
              ?: return@mapNotNull null
            DvDecoderCapability(
              name = info.name,
              mimeType = type,
              profileLevels = capabilities.profileLevels.map { DvProfileLevel(it.profile, it.level) }
            )
          }
        }
      }
    } catch (e: Exception) {
      Log.w(TAG, "Failed to query native Dolby Vision decoder support", e)
      emptyList()
    }
  }

  val hasNativeDolbyVisionDecoder: Boolean by lazy {
    dolbyVisionDecoders.isNotEmpty().also {
      Log.i(TAG, "Native Dolby Vision decoder available: $it; decoders=${describeDolbyVisionDecoders()}")
    }
  }

  private fun deviceAdvertisesDvProfile(profile: Int, minApi: Int = 0): Boolean {
    if (Build.VERSION.SDK_INT < minApi) return false
    return dolbyVisionDecoders.any { decoder ->
      decoder.profileLevels.any { it.profile == profile }
    }
  }

  val deviceSupportsDvProfile7: Boolean by lazy {
    deviceAdvertisesDvProfile(MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheDtb)
      .also { Log.i(TAG, "Device advertises exact DV Profile 7 (DvheDtb): $it") }
  }

  val deviceSupportsDvProfile8: Boolean by lazy {
    deviceAdvertisesDvProfile(MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheSt, minApi = 27)
      .also { Log.i(TAG, "Device advertises DV Profile 8 (DvheSt): $it") }
  }

  fun displaySupportsDolbyVision(context: Context): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
      Log.i(TAG, "Display Dolby Vision support: false (HDR capabilities require API 24, device API=${Build.VERSION.SDK_INT})")
      return false
    }

    val display = getCurrentDisplay(context)
    if (display == null) {
      Log.i(TAG, "Display Dolby Vision support: false (no active display)")
      return false
    }

    val hdrTypes = runCatching {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        display.mode.supportedHdrTypes
      } else {
        @Suppress("DEPRECATION")
        val legacyHdrTypes = display.hdrCapabilities.supportedHdrTypes
        legacyHdrTypes
      }
    }.getOrElse { error ->
      Log.w(TAG, "Display Dolby Vision support: false (failed to query HDR types)", error)
      return false
    }
    val supported = hdrTypes.contains(Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION)
    Log.i(TAG, "Display Dolby Vision support: $supported; hdrTypes=${describeHdrTypes(hdrTypes)}")
    return supported
  }

  fun logSupportSummary(context: Context) {
    Log.i(
      TAG,
      "DV support summary: bridgeReady=${isAvailable()}, displayDV=${displaySupportsDolbyVision(context)}, " +
        "nativeDecoder=$hasNativeDolbyVisionDecoder, advertisedP7=$deviceSupportsDvProfile7, " +
        "advertisedP8=$deviceSupportsDvProfile8, decoders=${describeDolbyVisionDecoders()}"
    )
  }

  fun getConversionMode(context: Context): DvConversionMode {
    val bridgeReady = isAvailable()
    val displayDv = displaySupportsDolbyVision(context)
    val nativeDecoder = hasNativeDolbyVisionDecoder
    val advertisedP7 = deviceSupportsDvProfile7
    val advertisedP8 = deviceSupportsDvProfile8

    val mode = when {
      !displayDv -> DvConversionMode.HEVC_STRIP
      advertisedP7 -> DvConversionMode.DISABLED
      advertisedP8 && bridgeReady -> DvConversionMode.DV81
      else -> DvConversionMode.HEVC_STRIP
    }
    val reason = when {
      !displayDv -> "active display does not support Dolby Vision; stripping DV metadata for HEVC fallback"
      advertisedP7 -> "active display supports Dolby Vision and decoder advertises exact Profile 7; trying native DV first"
      advertisedP8 && bridgeReady -> "active display supports Dolby Vision and decoder advertises Profile 8; converting to Profile 8.1"
      !bridgeReady -> "conversion bridge unavailable; stripping DV metadata for HEVC fallback"
      else -> "Dolby Vision output path is unavailable; stripping DV metadata for HEVC fallback"
    }
    Log.i(
      TAG,
      "AUTO DV decision: mode=$mode; reason=$reason; bridgeReady=$bridgeReady, " +
        "displayDV=$displayDv, nativeDecoder=$nativeDecoder, advertisedP7=$advertisedP7, advertisedP8=$advertisedP8"
    )
    return mode
  }

  /** Get the fallback mode when native DV7 decoding fails. */
  fun getDv7FallbackMode(context: Context): DvConversionMode {
    val bridgeReady = isAvailable()
    val displayDv = displaySupportsDolbyVision(context)
    val advertisedP8 = deviceSupportsDvProfile8
    val mode = if (displayDv && advertisedP8 && bridgeReady) DvConversionMode.DV81 else DvConversionMode.HEVC_STRIP
    val reason = when {
      mode == DvConversionMode.DV81 -> "display supports Dolby Vision and decoder advertises Profile 8"
      !bridgeReady -> "conversion bridge unavailable; stripping DV metadata for HEVC fallback"
      else -> "Dolby Vision output or Profile 8 support is unavailable"
    }
    Log.i(
      TAG,
      "DV7 fallback decision: mode=$mode; reason=$reason; bridgeReady=$bridgeReady, " +
        "displayDV=$displayDv, advertisedP8=$advertisedP8"
    )
    return mode
  }

  private fun getCurrentDisplay(context: Context): Display? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
    context.display
  } else {
    @Suppress("DEPRECATION")
    (context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager)?.defaultDisplay
  }

  private fun describeDolbyVisionDecoders(): String {
    if (dolbyVisionDecoders.isEmpty()) return "none"
    return dolbyVisionDecoders.joinToString { decoder ->
      val profiles = if (decoder.profileLevels.isEmpty()) {
        "none"
      } else {
        decoder.profileLevels.joinToString(prefix = "[", postfix = "]") {
          "${describeDvProfile(it.profile)}/${describeDvLevel(it.level)}"
        }
      }
      "${decoder.name}(${decoder.mimeType}, profiles=$profiles)"
    }
  }

  private fun describeHdrTypes(hdrTypes: IntArray): String {
    if (hdrTypes.isEmpty()) return "none"
    return hdrTypes.joinToString(prefix = "[", postfix = "]") { type ->
      when (type) {
        Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION -> "DOLBY_VISION"
        Display.HdrCapabilities.HDR_TYPE_HDR10 -> "HDR10"
        Display.HdrCapabilities.HDR_TYPE_HLG -> "HLG"
        Display.HdrCapabilities.HDR_TYPE_HDR10_PLUS -> "HDR10_PLUS"
        else -> "unknown(${hex(type)})"
      }
    }
  }

  private fun describeDvProfile(profile: Int): String = when (profile) {
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvavPer -> "P0/DvavPer"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvavPen -> "P1/DvavPen"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheDer -> "P2/DvheDer"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheDen -> "P3/DvheDen"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheDtr -> "P4/DvheDtr"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheStn -> "P5/DvheStn"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheDth -> "P6/DvheDth"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheDtb -> "P7/DvheDtb"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheSt -> "P8/DvheSt"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvavSe -> "P9/DvavSe"
    else -> "unknown(${hex(profile)})"
  }

  private fun describeDvLevel(level: Int): String = when (level) {
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelHd24 -> "L1/Hd24"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelHd30 -> "L2/Hd30"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelFhd24 -> "L3/Fhd24"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelFhd30 -> "L4/Fhd30"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelFhd60 -> "L5/Fhd60"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelUhd24 -> "L6/Uhd24"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelUhd30 -> "L7/Uhd30"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelUhd48 -> "L8/Uhd48"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelUhd60 -> "L9/Uhd60"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevelUhd120 -> "L10/Uhd120"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevel8k30 -> "L11/8k30"
    MediaCodecInfo.CodecProfileLevel.DolbyVisionLevel8k60 -> "L12/8k60"
    else -> "unknown(${hex(level)})"
  }

  private fun hex(value: Int): String = "0x${value.toString(16)}"

  fun convertRpuNalu(
    payload: ByteArray,
    payloadOffset: Int,
    payloadLength: Int,
    output: ByteArray,
    outputOffset: Int,
    outputCapacity: Int,
    mode: Int = 2
  ): Int {
    if (!conversionPathReady || payloadLength <= 0) return CONVERT_FAILED
    return runCatching {
      nativeConvertDv7RpuToDv81(payload, payloadOffset, payloadLength, output, outputOffset, outputCapacity, mode)
    }
      .onFailure { Log.w(TAG, "RPU conversion failed: ${it.message}") }
      .getOrDefault(CONVERT_FAILED)
  }

  fun getVersion(): String? {
    if (!nativeLoaded) return null
    return runCatching { nativeGetBridgeVersion() }.getOrNull()
  }

  @JvmStatic
  private external fun nativeConvertDv7RpuToDv81(
    payload: ByteArray,
    payloadOffset: Int,
    payloadLength: Int,
    output: ByteArray,
    outputOffset: Int,
    outputCapacity: Int,
    mode: Int
  ): Int

  @JvmStatic
  private external fun nativeIsConversionPathReady(): Boolean

  @JvmStatic
  private external fun nativeGetBridgeVersion(): String
}
