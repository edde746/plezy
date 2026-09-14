package com.edde746.plezy

import org.junit.Assert.assertEquals
import org.junit.Test

class FlutterRendererPolicyTest {

  @Test
  fun affected32BitTclTvUsesSkia() {
    val renderer = select(manufacturer = "TCL", is64Bit = false)

    assertEquals(FlutterRenderer.SKIA, renderer)
    assertEquals("--enable-impeller=false", renderer.shellArgument)
    assertEquals("Skia", renderer.diagnosticName)
  }

  @Test
  fun capable64BitTclTvKeepsAutomaticImpellerBackend() {
    assertEquals(FlutterRenderer.IMPELLER, select(manufacturer = "TCL", is64Bit = true))
  }

  @Test
  fun ordinary32BitAndroidTvUsesSkia() {
    assertEquals(FlutterRenderer.SKIA, select(manufacturer = "SEI Robotics", is64Bit = false))
  }

  @Test
  fun unsupportedTvsStayOnSkia() {
    assertEquals(FlutterRenderer.SKIA, select(sdkInt = 30))
    assertEquals(FlutterRenderer.SKIA, select(supportsVulkan11 = false))
    assertEquals(FlutterRenderer.SKIA, select(manufacturer = "Amazon"))
  }

  @Test
  fun existingDeviceDenylistStillTakesPrecedence() {
    assertEquals(FlutterRenderer.SKIA, select(isEWaste = true, isAndroidTv = false))
    assertEquals(FlutterRenderer.SKIA, select(manufacturer = "NVIDIA", isAndroidTv = false))
    assertEquals(FlutterRenderer.SKIA, select(manufacturer = "Huawei", isAndroidTv = false))
    assertEquals(FlutterRenderer.SKIA, select(manufacturer = "HONOR", isAndroidTv = false))
  }

  @Test
  fun ordinaryAndroidDevicesKeepAutomaticImpellerBackend() {
    assertEquals(
      FlutterRenderer.IMPELLER,
      select(manufacturer = "Samsung", isAndroidTv = false, sdkInt = 28, supportsVulkan11 = false, is64Bit = false)
    )
  }

  private fun select(
    isEWaste: Boolean = false,
    manufacturer: String = "Google",
    isAndroidTv: Boolean = true,
    sdkInt: Int = 31,
    supportsVulkan11: Boolean = true,
    is64Bit: Boolean = true
  ): FlutterRenderer = FlutterRendererPolicy.select(
    isEWaste = isEWaste,
    manufacturer = manufacturer,
    isAndroidTv = isAndroidTv,
    sdkInt = sdkInt,
    supportsVulkan11 = supportsVulkan11,
    is64Bit = is64Bit
  )
}
