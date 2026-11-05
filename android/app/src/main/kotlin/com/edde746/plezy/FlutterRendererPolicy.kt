package com.edde746.plezy

internal enum class FlutterRenderer(
  val diagnosticName: String,
  val shellArgument: String?
) {
  SKIA("Skia", "--enable-impeller=false"),
  IMPELLER("Impeller", null)
}

/** Selects the Flutter UI renderer before the engine starts. */
internal object FlutterRendererPolicy {
  private const val ANDROID_12_API = 31

  fun select(
    isEWaste: Boolean,
    manufacturer: String,
    isAndroidTv: Boolean,
    sdkInt: Int,
    supportsVulkan11: Boolean,
    is64Bit: Boolean
  ): FlutterRenderer {
    if (isEWaste) return FlutterRenderer.SKIA
    if (manufacturer.equals("NVIDIA", ignoreCase = true)) return FlutterRenderer.SKIA
    if (manufacturer.equals("Huawei", ignoreCase = true) ||
      manufacturer.equals("HONOR", ignoreCase = true)
    ) {
      return FlutterRenderer.SKIA
    }
    // Without Vulkan 1.1, Impeller can only fall back to its GLES backend. The engine's own
    // guard keys on API level, which custom ROMs defeat: LineageOS 21 reports API 34 on a
    // Nexus 7 (2013) still running the 2016 Adreno 320 driver, whose shader compiler crashes
    // the raster thread on Impeller's GLES shaders at launch (#2948, flutter/flutter#164906).
    if (!supportsVulkan11) return FlutterRenderer.SKIA
    if (!isAndroidTv) return FlutterRenderer.IMPELLER
    if (sdkInt < ANDROID_12_API || manufacturer.equals("Amazon", ignoreCase = true)) {
      return FlutterRenderer.SKIA
    }

    // 32-bit Android TV SoCs are the low-memory / low-throughput class. Skia avoids
    // Impeller/Vulkan's substantially higher raster cost on these devices.
    if (!is64Bit) return FlutterRenderer.SKIA

    return FlutterRenderer.IMPELLER
  }
}
