#if os(iOS) || os(tvOS)
  import Flutter
  import UIKit
#elseif os(macOS)
  import FlutterMacOS
#endif

/// Answers `com.plezy/deep_link` on iOS, iPadOS, tvOS and macOS: hands every `plezy:` URL the
/// system opens the app with to Dart unchanged.
///
/// Dart owns the link grammar (lib/services/deep_links/deep_link.dart), so only the scheme is
/// checked here. A link stays retained until Dart takes it: `getInitialLink` returns it and
/// switches the engine to live delivery, after which `onLink` delivers each new link and only a
/// `true` reply clears it. Compiled into the iOS, tvOS and macOS Runners.
final class DeepLinkPlugin: NSObject, FlutterPlugin {
  private static let scheme = "plezy"
  // Process-wide so a link received before a (re)created engine registers is not lost.
  private static let delivery = DeepLinkDeliveryCoordinator()
  private static var channel: FlutterMethodChannel?

  static func register(with registrar: FlutterPluginRegistrar) {
    #if os(macOS)
      let messenger = registrar.messenger
    #else
      let messenger = registrar.messenger()
    #endif
    let channel = FlutterMethodChannel(name: "com.plezy/deep_link", binaryMessenger: messenger)
    Self.channel = channel
    delivery.bindEngine()
    let instance = DeepLinkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    #if os(macOS)
      registrar.addApplicationDelegate(instance)
    #else
      registrar.addSceneDelegate(instance)
    #endif
  }

  /// The string Dart receives for `url`, or nil when it is not a Plezy link.
  static func forwardedLink(for url: URL) -> String? {
    url.scheme?.lowercased() == scheme ? url.absoluteString : nil
  }

  /// Takes `url` when it is a Plezy link, delivering it now or retaining it for Dart.
  static func receive(_ url: URL) -> Bool {
    guard let link = forwardedLink(for: url) else { return false }
    if case let .deliver(event) = delivery.receive(url: link) {
      deliverLive(event)
    }
    return true
  }

  /// Offers every URL to `handler` and reports whether any was taken.
  static func receiveAll(
    _ urls: [URL],
    using handler: (URL) -> Bool = DeepLinkPlugin.receive
  ) -> Bool {
    var handled = false
    for url in urls where handler(url) {
      handled = true
    }
    return handled
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getInitialLink":
      let event = Self.delivery.beginLiveDelivery()
      result(event?.url)
      if let event, let next = Self.delivery.complete(event, succeeded: true) {
        Self.deliverLive(next)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  #if os(macOS)
    func handleOpen(_ urls: [URL]) -> Bool {
      Self.receiveAll(urls)
    }
  #endif

  private static func deliverLive(_ event: DeepLinkDeliveryCoordinator.Event) {
    guard let channel else { return }
    channel.invokeMethod("onLink", arguments: event.flutterArguments) { reply in
      // Anything but `true` (no handler yet, error, not implemented) keeps the link retained.
      let succeeded = reply as? Bool == true
      if let next = delivery.complete(event, succeeded: succeeded) {
        deliverLive(next)
      }
    }
  }
}

#if os(iOS) || os(tvOS)
  extension DeepLinkPlugin: FlutterSceneLifeCycleDelegate {
    // A cold launch carries its link in the connection options; `scene(_:openURLContexts:)` only
    // fires for links that arrive while the scene is connected.
    func scene(
      _ scene: UIScene,
      willConnectTo session: UISceneSession,
      options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
      guard let connectionOptions else { return false }
      return Self.receiveAll(connectionOptions.urlContexts.map(\.url))
    }

    func scene(
      _ scene: UIScene,
      openURLContexts URLContexts: Set<UIOpenURLContext>
    ) -> Bool {
      Self.receiveAll(URLContexts.map(\.url))
    }
  }
#endif
