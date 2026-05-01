package com.edde746.plezy.exoplayer

import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.os.Build
import android.util.Log

enum class DvConversionMode { DISABLED, DV81, HEVC_STRIP }

object DoviBridge {
  private const val TAG = "DoviBridge"

  const val CONVERT_FAILED = -1
  const val DESTINATION_TOO_SMALL = -2

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

  private fun deviceSupportsDvProfile(profile: Int, minApi: Int = 0): Boolean {
    try {
      if (Build.VERSION.SDK_INT < minApi) return false
      val codecList = MediaCodecList(MediaCodecList.REGULAR_CODECS)
      return codecList.codecInfos.any { info ->
        !info.isEncoder &&
          info.supportedTypes.any { type ->
            type.equals("video/dolby-vision", ignoreCase = true) &&
              info.getCapabilitiesForType(type).profileLevels.any { it.profile == profile }
          }
      }
    } catch (e: Exception) {
      Log.w(TAG, "Failed to query DV profile $profile support", e)
      return false
    }
  }

  val deviceSupportsDvProfile7: Boolean by lazy {
    deviceSupportsDvProfile(MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheDtr)
      .also { Log.i(TAG, "Device DV Profile 7 support: $it") }
  }

  val deviceSupportsDvProfile8: Boolean by lazy {
    deviceSupportsDvProfile(MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheSt, minApi = 27)
      .also { Log.i(TAG, "Device DV Profile 8 support: $it") }
  }

  fun getConversionMode(): DvConversionMode = when {
    !isAvailable() -> DvConversionMode.DISABLED
    deviceSupportsDvProfile7 -> DvConversionMode.DISABLED // try native first; ExoPlayerCore retries with conversion on failure
    deviceSupportsDvProfile8 -> DvConversionMode.DV81
    else -> DvConversionMode.HEVC_STRIP
  }

  /** Get the fallback mode when native DV7 decoding fails. */
  fun getDv7FallbackMode(): DvConversionMode = when {
    deviceSupportsDvProfile8 -> DvConversionMode.DV81
    else -> DvConversionMode.HEVC_STRIP
  }

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
