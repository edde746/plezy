// Pure-Swift tvOS port of fluttercommunity.plus/package_info.
// Matches the Objective-C FPPPackageInfoPlusPlugin on iOS exactly enough to
// satisfy PackageInfo.fromPlatform() in Dart.

import Foundation

#if os(iOS) || os(tvOS)
  import Flutter

  public class PackageInfoPlusPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(
        name: "dev.fluttercommunity.plus/package_info",
        binaryMessenger: registrar.messenger()
      )
      let instance = PackageInfoPlusPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard call.method == "getAll" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let bundle = Bundle.main
      let appStoreReceipt = bundle.appStoreReceiptURL?.path ?? ""
      let installerStore: String
      if appStoreReceipt.contains("CoreSimulator") {
        installerStore = "com.apple.simulator"
      } else if appStoreReceipt.contains("sandboxReceipt") {
        installerStore = "com.apple.testflight"
      } else {
        installerStore = "com.apple"
      }

      let appName =
        (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
        ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
        ?? ""
      let packageName = bundle.bundleIdentifier ?? ""
      let version =
        (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
      let buildNumber = (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? ""

      let installTime = Self.timeMillisString(from: Self.installDate())
      let updateTime = Self.timeMillisString(from: Self.updateDate())

      result([
        "appName": appName,
        "packageName": packageName,
        "version": version,
        "buildNumber": buildNumber,
        "installerStore": installerStore,
        "installTime": installTime as Any,
        "updateTime": updateTime as Any,
      ])
    }

    private static func installDate() -> Date? {
      guard
        let docsURL = FileManager.default.urls(
          for: .documentDirectory, in: .userDomainMask
        ).last
      else {
        return nil
      }
      let attrs = try? FileManager.default.attributesOfItem(atPath: docsURL.path)
      return attrs?[.creationDate] as? Date
    }

    private static func updateDate() -> Date? {
      let attrs = try? FileManager.default.attributesOfItem(atPath: Bundle.main.bundlePath)
      return attrs?[.modificationDate] as? Date
    }

    private static func timeMillisString(from date: Date?) -> String? {
      guard let date = date else { return nil }
      return String(Int64(date.timeIntervalSince1970 * 1000))
    }
  }
#endif
