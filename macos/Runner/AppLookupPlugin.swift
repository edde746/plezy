import Cocoa
import FlutterMacOS

// MARK: - AppLookupPlugin
/// Answers "is this application installed?" from Launch Services, the same
/// database `open -a` resolves through. Spotlight is deliberately not used:
/// an empty `mdfind` result also means indexing is off or incomplete, which
/// would hide players the user actually has.
class AppLookupPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.plezy/app_lookup",
      binaryMessenger: registrar.messenger
    )
    registrar.addMethodCallDelegate(AppLookupPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isApplicationInstalled":
      guard let args = call.arguments as? [String: Any],
        let bundleId = args["bundleId"] as? String, !bundleId.isEmpty
      else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENTS", message: "bundleId is required", details: nil))
        return
      }
      let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
      result(url != nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
