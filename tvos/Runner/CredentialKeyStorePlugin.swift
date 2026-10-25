import Flutter
import Security

/// tvOS uses the same OS keychain policy as the federated iOS plugin. The
/// federated plugin has no tvOS target, so register this narrow adapter here.
final class CredentialKeyStorePlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.plezy/credential_keys", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(CredentialKeyStorePlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let key = args["key"] as? String,
      !key.isEmpty, key.utf8.count <= 128
    else {
      result(FlutterError(code: "invalid_argument", message: "Invalid credential key identifier", details: nil))
      return
    }
    let service = (Bundle.main.bundleIdentifier ?? "com.plezy.tv") + ".credential-keys"
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecAttrSynchronizable as String: false,
    ]
    switch call.method {
    case "read":
      var readQuery = query
      readQuery[kSecReturnData as String] = true
      readQuery[kSecMatchLimit as String] = kSecMatchLimitOne
      var item: CFTypeRef?
      let status = SecItemCopyMatching(readQuery as CFDictionary, &item)
      if status == errSecItemNotFound {
        result(nil)
      } else if status == errSecSuccess, let data = item as? Data,
        let value = String(data: data, encoding: .utf8)
      {
        result(value)
      } else {
        result(FlutterError(code: "keychain_unavailable", message: "Credential key could not be read", details: status))
      }
    case "write":
      guard let value = args["value"] as? String, let data = value.data(using: .utf8) else {
        result(FlutterError(code: "invalid_argument", message: "Missing credential key", details: nil))
        return
      }
      let attributes: [String: Any] = [
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      ]
      var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
      if status == errSecItemNotFound {
        status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
      }
      if status == errSecSuccess {
        result(nil)
      } else {
        result(
          FlutterError(code: "keychain_unavailable", message: "Credential key could not be saved", details: status))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
