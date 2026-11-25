package com.edde746.plezy.output

import android.content.Context
import android.hardware.display.DisplayManager
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import android.view.Display
import com.edde746.plezy.mpv.DisplayHdr
import com.edde746.plezy.mpv.supportedMpvSpdifCodecs
import com.edde746.plezy.playback.output.DisplayInfo
import com.edde746.plezy.playback.output.DisplayMode
import com.edde746.plezy.playback.output.VideoCapabilities
import com.edde746.plezy.playback.output.VideoCodec
import com.edde746.plezy.presentation.settings.DeviceFeatures

/**
 * What this device's display and audio route can do (detected here and reported to
 * shared code): the display's modes and HDR for the output plan, the compressed formats the route takes undecoded for
 * passthrough, and from both, which device settings apply here ([features]).
 */
internal object DeviceOutput {
    /** The default display: its modes (physical size), the current one, and its HDR support (always on where present). */
    fun display(context: Context): DisplayInfo? {
        val display = defaultDisplay(context) ?: return null
        val modes = display.supportedModes.map { DisplayMode(it.modeId, it.physicalWidth, it.physicalHeight, it.refreshRate.toDouble()) }
        val hdr = DisplayHdr.hdrTypes(context).isNotEmpty()
        return DisplayInfo(modes, modes.firstOrNull { it.id == display.mode.modeId }, hdrSupported = hdr, hdrEnabled = hdr)
    }

    /**
     * The device settings that do something here:
     * - HDR: the display shows HDR and the app can keep a video from it (`SurfaceView.setDesiredHdrHeadroom`, API 35)
     *   on phones and tablets. A TV's HDMI output follows the content by the system's own setting, which an app
     *   can't switch.
     * - Matching the frame rate: every Android device, whose window's preferred mode switches the display (TVs, and
     *   phones and tablets whose panels have several rates).
     * - Passthrough: the current audio route takes a compressed surround format undecoded.
     */
    fun features(context: Context, television: Boolean): DeviceFeatures {
        val display = display(context)
        return DeviceFeatures(
            hardwareDecoding = true,
            hdr = !television && Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM && display?.hdrSupported == true,
            matchFrameRate = true,
            audioPassthrough = passthroughCodecs(context).isNotEmpty(),
        )
    }

    /**
     * What the display and the decoders take ([com.edde746.plezy.app.AppPlatform.videoCapabilities]): its HDR types,
     * and the video codecs a hardware decoder takes (`MediaCodecInfo.isHardwareAccelerated` from API 29; before it, a
     * decoder that isn't Android's own software one).
     */
    fun videoCapabilities(context: Context): VideoCapabilities {
        val hdrTypes = DisplayHdr.hdrTypes(context)
        val hardware = MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.filter { info ->
            !info.isEncoder && if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                info.isHardwareAccelerated
            } else {
                !info.name.startsWith("OMX.google.") && !info.name.startsWith("c2.android.")
            }
        }
        val types = hardware.flatMap { it.supportedTypes.asList() }.mapTo(mutableSetOf()) { it.lowercase() }
        return VideoCapabilities(
            hdr = hdrTypes.isNotEmpty(),
            dolbyVision = Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION in hdrTypes,
            hardwareCodecs = HARDWARE_TYPES.filterKeys { it in types }.values.toSet(),
        )
    }

    private val HARDWARE_TYPES = mapOf(
        MediaFormat.MIMETYPE_VIDEO_AVC to VideoCodec.AVC,
        MediaFormat.MIMETYPE_VIDEO_HEVC to VideoCodec.HEVC,
        "video/av01" to VideoCodec.AV1,
        MediaFormat.MIMETYPE_VIDEO_VP9 to VideoCodec.VP9,
    )

    /**
     * The compressed formats the current audio route carries undecoded, as mpv's `audio-spdif` names them
     * ([supportedMpvSpdifCodecs]: a codec the platform encodes, on a track shape mpv's audiotrack output opens, and for
     * DTS an HDMI sink that lists it). Empty decodes everything, as does a route the probe can't read.
     */
    fun passthroughCodecs(context: Context): List<String> =
        runCatching { supportedMpvSpdifCodecs(context) }.getOrDefault("").split(',').filter { it.isNotEmpty() }

    private fun defaultDisplay(context: Context): Display? =
        context.getSystemService(DisplayManager::class.java)?.getDisplay(Display.DEFAULT_DISPLAY)
}
