import Flutter
import UIKit

/// Hands playback to another tvOS app on `com.plezy/external_player`.
///
/// The tvOS Runner carries no url_launcher implementation, so external player
/// handoff asks these two questions here. `openUrl` deliberately skips
/// `canOpenURL`: that answers false for any scheme missing from
/// LSApplicationQueriesSchemes, which would refuse every custom player. The
/// open completion reports a missing handler instead.
class ExternalPlayerPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.plezy/external_player",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(ExternalPlayerPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "canOpenUrl":
      guard let url = Self.url(from: call) else {
        result(Self.invalidUrlError())
        return
      }
      result(UIApplication.shared.canOpenURL(url))

    case "openUrl":
      guard let url = Self.url(from: call) else {
        result(Self.invalidUrlError())
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in
        result(opened)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func url(from call: FlutterMethodCall) -> URL? {
    guard let args = call.arguments as? [String: Any],
      let value = args["url"] as? String
    else { return nil }
    return URL(string: value)
  }

  private static func invalidUrlError() -> FlutterError {
    FlutterError(code: "INVALID_ARGUMENTS", message: "url must be a valid URL", details: nil)
  }
}
