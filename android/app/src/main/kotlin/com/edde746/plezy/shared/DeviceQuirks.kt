package com.edde746.plezy.shared

import android.os.Build

object DeviceQuirks {
  val isEWaste: Boolean
    get() = isGooglePixelDevice || isGoogleTensorDevice

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
