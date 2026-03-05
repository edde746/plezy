package com.edde746.plezy.exoplayer

import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.os.Build
import android.util.Log

enum class DvConversionMode { DISABLED, DV81, HEVC_STRIP }

object DoviBridge {
    private const val TAG = "DoviBridge"

    private val nativeLoaded: Boolean by lazy {
        try {
            System.loadLibrary("dovi_bridge")
            true
        } catch (_: UnsatisfiedLinkError) {
            Log.w(TAG, "Native lib not found")
            false
        }
    }

    fun isAvailable(): Boolean = nativeLoaded &&
        runCatching { nativeIsConversionPathReady() }.getOrDefault(false)

    /**
     * Check if the device has a hardware decoder that supports Dolby Vision Profile 7.
     * Queries MediaCodecList for decoders supporting video/dolby-vision with
     * DolbyVisionProfileDvheDtr (profile 7).
     */
    val deviceSupportsDvProfile7: Boolean by lazy {
        try {
            val codecList = MediaCodecList(MediaCodecList.REGULAR_CODECS)
            val supported = codecList.codecInfos.any { info ->
                !info.isEncoder && info.supportedTypes.any { type ->
                    type.equals("video/dolby-vision", ignoreCase = true) &&
                        info.getCapabilitiesForType(type).profileLevels.any { pl ->
                            pl.profile == MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheDtr
                        }
                }
            }
            Log.i(TAG, "Device DV Profile 7 support: $supported")
            supported
        } catch (e: Exception) {
            Log.w(TAG, "Failed to query DV7 support", e)
            false
        }
    }

    /**
     * Check if the device has a hardware decoder that supports Dolby Vision Profile 8
     * (DvheSt). DolbyVisionProfileDvheSt constant requires API 27+.
     */
    val deviceSupportsDvProfile8: Boolean by lazy {
        try {
            if (Build.VERSION.SDK_INT < 27) {
                Log.i(TAG, "API < 27, cannot check DV Profile 8 support")
                return@lazy false
            }
            val codecList = MediaCodecList(MediaCodecList.REGULAR_CODECS)
            val supported = codecList.codecInfos.any { info ->
                !info.isEncoder && info.supportedTypes.any { type ->
                    type.equals("video/dolby-vision", ignoreCase = true) &&
                        info.getCapabilitiesForType(type).profileLevels.any { pl ->
                            pl.profile == MediaCodecInfo.CodecProfileLevel.DolbyVisionProfileDvheSt
                        }
                }
            }
            Log.i(TAG, "Device DV Profile 8 support: $supported")
            supported
        } catch (e: Exception) {
            Log.w(TAG, "Failed to query DV8 support", e)
            false
        }
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

    fun convertRpuNalu(payload: ByteArray, mode: Int = 2): ByteArray? {
        if (!isAvailable() || payload.isEmpty()) return null
        return runCatching { nativeConvertDv7RpuToDv81(payload, mode) }
            .onFailure { Log.w(TAG, "RPU conversion failed: ${it.message}") }
            .getOrNull()
    }

    fun getVersion(): String? {
        if (!nativeLoaded) return null
        return runCatching { nativeGetBridgeVersion() }.getOrNull()
    }

    @JvmStatic
    private external fun nativeConvertDv7RpuToDv81(payload: ByteArray, mode: Int): ByteArray?

    @JvmStatic
    private external fun nativeIsConversionPathReady(): Boolean

    @JvmStatic
    private external fun nativeGetBridgeVersion(): String
}
