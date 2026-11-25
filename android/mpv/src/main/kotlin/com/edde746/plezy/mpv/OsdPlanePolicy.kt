package com.edde746.plezy.mpv

import kotlin.math.roundToInt

/**
 * The `vo=mediacodec` subtitle/OSD plane: its buffer size for the Subtitle render resolution setting
 * ([com.edde746.plezy.settings.SubtitleRenderResolution.androidRenderScale]), where mpv draws subtitles at the OSD
 * Surface's size, so a fixed buffer below the view's size has libass, the composite and the Surface copy work on fewer
 * pixels and the compositor scales the plane back up; and the plane's options for the device's SoC ([socOptions]).
 */
internal object OsdPlanePolicy {
    data class Size(val width: Int, val height: Int)

    /**
     * The plane's mpv options for a device whose SoC vendor is [socManufacturer] (`Build.SOC_MANUFACTURER`, which
     * Android reports from API 31; null before), made by [manufacturer] (`Build.MANUFACTURER`), a TV box when [tv]:
     * - `vo-mediacodec-osd-vsync-delay=1` on Amlogic and MediaTek TV boxes. Their hardware video plane reaches the
     *   screen a refresh after a graphics layer given the same presentation timestamp, so the plane led its picture by
     *   a refresh: HDMI captures showed it on an Amlogic S905X4 and a MediaTek MT8696, while a Tegra X1 shows both on
     *   the same refresh. Nothing on the device reports the lag. With the delay the plane is presented on every video
     *   frame, which keeps Amlogic video from juddering.
     * - `vo-mediacodec-letterbox-fill=no` on Amlogic devices but Amazon's. Their display pipeline raises opaque black
     *   on a graphics layer in Dolby Vision output and scans a transparent area out black, so the plane's black
     *   letterbox fill came out gray; MediaTek boxes, and the Amlogic Fire TV Cube, need the opaque fill.
     */
    fun socOptions(socManufacturer: String?, manufacturer: String, tv: Boolean): List<Pair<String, String>> = buildList {
        val amlogic = socManufacturer.equals("Amlogic", ignoreCase = true)
        if (tv && (amlogic || socManufacturer.equals("Mediatek", ignoreCase = true))) add("vo-mediacodec-osd-vsync-delay" to "1")
        if (amlogic && !manufacturer.equals("Amazon", ignoreCase = true)) add("vo-mediacodec-letterbox-fill" to "no")
    }

    /**
     * The fixed buffer size for a plane whose view measures [viewWidth]×[viewHeight], each side rounded and made
     * even (at least 2); null where the plane follows its view: full resolution, a scale out of (0, 1), or a view not
     * laid out yet.
     */
    fun fixedSizeFor(viewWidth: Int, viewHeight: Int, renderScale: Double): Size? {
        if (viewWidth <= 0 || viewHeight <= 0) return null
        if (!(renderScale > 0.0) || renderScale >= 1.0) return null
        return Size(scaledEven(viewWidth, renderScale), scaledEven(viewHeight, renderScale))
    }

    private fun scaledEven(value: Int, scale: Double): Int = (value * scale).roundToInt().coerceAtLeast(2) and 1.inv()
}
