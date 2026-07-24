package com.edde746.plezy

internal enum class FlutterRenderer(
  val diagnosticName: String,
  val shellArgument: String?
) {
  SKIA("Skia", "--enable-impeller=false"),
  IMPELLER("Impeller", null),
  IMPELLER_OPEN_GLES("Impeller (OpenGLES)", "--impeller-backend=opengles")
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
    if (!isAndroidTv) return FlutterRenderer.IMPELLER
    if (sdkInt < ANDROID_12_API || manufacturer.equals("Amazon", ignoreCase = true) || !supportsVulkan11) {
      return FlutterRenderer.SKIA
    }

    // PowerVR BXE-4-32 drivers in TCL's 32-bit Android 12 TV platform leave
    // stale Vulkan frames on screen while scrolling (#1658, flutter/flutter#189767).
    // Impeller's OpenGLES backend renders correctly on the same hardware.
    if (!is64Bit && manufacturer.equals("TCL", ignoreCase = true)) {
      return FlutterRenderer.IMPELLER_OPEN_GLES
    }

    return FlutterRenderer.IMPELLER
  }
}
