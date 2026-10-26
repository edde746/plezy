import CoreMedia
import Flutter
import AVKit
import VideoToolbox

/// Answers `com.plezy/device`'s `getVideoDecodeCapabilities` on iOS and tvOS.
///
/// Compiled into the iOS and tvOS Runners only — macOS keeps its own sources
/// and is deliberately left unprobed, because desktop CPUs software-decode
/// both codecs in real time and narrowing the profile there would force
/// transcodes for nothing.
class VideoDecodeCapabilitiesPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.plezy/device",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(VideoDecodeCapabilitiesPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getVideoDecodeCapabilities":
      result([
        "hevc": VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC),
        "av1": VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1),
        // This app's Apple sample-buffer path accepts the documented single-
        // layer P5/P8 profiles when the active Apple output path reports DV.
        "dolbyVisionProfiles": AVPlayer.availableHDRModes.contains(.dolbyVision) ? [5, 8] : [Int](),
      ])
    default:
      // The rest of `com.plezy/device` is Android-only.
      result(FlutterMethodNotImplemented)
    }
  }
}
