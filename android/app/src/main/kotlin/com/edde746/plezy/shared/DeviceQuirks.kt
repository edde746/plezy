package com.edde746.plezy.shared

import android.os.Build

object DeviceQuirks {
  val isEWaste: Boolean
    get() = isGooglePixelDevice || isGoogleTensorDevice

  /**
   * Highest content frame rate for which [hasUnreliableTunneledPlayback] applies.
   *
   * Tunneling exists to meet the scheduling deadlines of high-frame-rate 4K, which Amazon
   * documents and recommends for exactly that workload, so the cut-off keeps 4K50/60
   * tunneled. Withdrawing tunneling is not free even below it — the device pipeline saves
   * CPU and power at any rate — but ~33ms per frame is well inside what media3's own
   * release path handles, and a juddering picture is the worse trade.
   */
  const val MAX_UNRELIABLE_TUNNELED_FPS = 30f

  /**
   * Fire TV Stick 4K (AFTMM) judders continuously on 23.976p direct play while tunneled.
   * The #1802 reporter A/B-tested it: tunneling off, every other setting unchanged, and
   * the judder goes away. Untunneled, media3's VideoFrameReleaseHelper owns frame release
   * and vsync-aligns it; tunneled, the device owns it and media3 notes it "may do frame
   * rate conversion".
   *
   * The mechanism is unconfirmed. Tunneling fires no VideoFrameMetadataListener and stops
   * media3 counting frames in the codec, so nothing app-side can measure the cadence or
   * drops. Only the trigger is established.
   *
   * Deliberately scoped to the one model and the one rate class that were tested: AFTMM
   * keeps tunneling for high-frame-rate content, and an unknown rate changes nothing.
   * Widen only on further reports.
   */
  fun hasUnreliableTunneledPlayback(contentFrameRate: Float): Boolean = hasUnreliableTunneledPlayback(Build.MANUFACTURER, Build.MODEL, contentFrameRate)

  internal fun hasUnreliableTunneledPlayback(
    manufacturer: String,
    model: String,
    contentFrameRate: Float
  ): Boolean = manufacturer.equals("Amazon", ignoreCase = true) &&
    model.equals("AFTMM", ignoreCase = true) &&
    contentFrameRate > 0f &&
    contentFrameRate <= MAX_UNRELIABLE_TUNNELED_FPS

  /**
   * The display pipeline raises opaque black on a graphics layer while the output is in Dolby
   * Vision, and scans a transparent area out black. Letterbox bars filled black on the mpv OSD
   * plane therefore come out gray here (#2926), while ExoPlayer, which leaves its overlay plane
   * transparent over the same picture-sized video surface, shows black ones. MediaTek boxes (Google
   * TV Streamer, Fire TV 4K Max) behave the other way round (#2163), which is why the fill stays on
   * everywhere else.
   *
   * Scoped to Amlogic by SoC vendor, which Android reports from API 31 (S). Amazon is excluded by
   * name: Kodi lists the Amlogic Fire TV Cube 3 with the MediaTek Fire TV Stick 4K Max as needing
   * opaque black (xbmc/xbmc#22561).
   */
  val raisesGraphicsBlackInDolbyVision: Boolean
    get() = raisesGraphicsBlackInDolbyVision(
      socManufacturer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MANUFACTURER else null,
      manufacturer = Build.MANUFACTURER
    )

  internal fun raisesGraphicsBlackInDolbyVision(socManufacturer: String?, manufacturer: String): Boolean = socManufacturer.equals("Amlogic", ignoreCase = true) &&
    !manufacturer.equals("Amazon", ignoreCase = true)

  private val isGooglePixelDevice: Boolean
    get() = (
      Build.MANUFACTURER.equals("Google", ignoreCase = true) ||
        Build.BRAND.equals("google", ignoreCase = true)
      ) &&
      Build.MODEL.contains("Pixel", ignoreCase = true)

  private val isGoogleTensorDevice: Boolean
    get() {
      if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
      val soc = Build.SOC_MODEL
      return soc.startsWith("Tensor", ignoreCase = true) ||
        soc.startsWith("GS", ignoreCase = true)
    }
}
