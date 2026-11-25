package com.edde746.plezy.mpv

import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.view.Display
import com.edde746.mpv.GpuVoPolicy

/**
 * The HDR output types of the display playback runs on: the Dolby Vision decoder routing ([GpuVoPolicy]) and the app's
 * HDR capability (the Hdr setting, the output plan).
 */
object DisplayHdr {
    /** Whether the default display accepts a Dolby Vision signal (Android TV boxes on a DV sink; no phone so far). */
    fun supportsDolbyVision(context: Context): Boolean = Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION in hdrTypes(context)

    /** The default display's HDR types (`Display.HdrCapabilities.HDR_TYPE_*`); empty when it reports none. */
    fun hdrTypes(context: Context): IntArray {
        val display = context.getSystemService(DisplayManager::class.java)?.getDisplay(Display.DEFAULT_DISPLAY) ?: return IntArray(0)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            runCatching { display.mode.supportedHdrTypes }.getOrNull()?.let { return it }
        }
        @Suppress("DEPRECATION")
        return display.hdrCapabilities?.supportedHdrTypes ?: IntArray(0)
    }
}
