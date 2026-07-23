import Foundation
import TVServices

#if os(tvOS)
  import Flutter

  /// Bridges the active Apple TV *system* user to Flutter so Plezy can
  /// auto-activate the matching in-app profile.
  ///
  /// Channel: `com.plezy/tv_user`
  ///   - Flutter → native `getCurrentUser` → String? (tvOS user identifier)
  ///   - Flutter → native `isSupported`   → Bool
  ///   - native → Flutter `onUserChanged` (arguments: { "userId": String? })
  ///
  /// Requires the `com.apple.developer.user-management` entitlement with the
  /// `get-current-user` value (see Runner.entitlements).
  ///
  /// NOTE: `TVUserManager.currentUserIdentifier` and
  /// `currentUserIdentifierDidChangeNotification` are deprecated as of tvOS 16
  /// but remain functional; the non-deprecated alternative is the
  /// `runs-as-current-user` entitlement, which trades the explicit mapping
  /// for fully separate per-user containers.
  final class TvUserPlugin: NSObject, FlutterPlugin {
    private static let channelName = "com.plezy/tv_user"
    private static var methodChannel: FlutterMethodChannel?

    private let userManager = TVUserManager()

    static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: registrar.messenger()
      )
      methodChannel = channel
      let instance = TvUserPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)
      instance.startObservingUserChanges()
    }

    private func startObservingUserChanges() {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(currentUserDidChange),
        name: TVUserManager.currentUserIdentifierDidChangeNotification,
        object: nil
      )
    }

    @objc private func currentUserDidChange() {
      // The notification may arrive on an arbitrary thread, but Flutter
      // requires channel calls to happen on the main thread.
      let userId = currentUserId()
      DispatchQueue.main.async {
        Self.methodChannel?.invokeMethod(
          "onUserChanged",
          arguments: ["userId": userId as Any]
        )
      }
    }

    /// The active Apple TV system user identifier, or nil when unavailable
    /// (entitlement missing, default user, or multi-user sharing disabled).
    private func currentUserId() -> String? {
      return userManager.currentUserIdentifier
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "isSupported":
        result(true)
      case "getCurrentUser":
        result(currentUserId())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }
  }
#endif
