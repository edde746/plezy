import Foundation
import TVServices

#if os(tvOS)
  import Flutter

  final class SystemShelfPlugin: NSObject, FlutterPlugin {
    private static let channelName = "com.plezy/system_shelf"
    private static let appGroupIdentifier = "group.com.edde746.plezy"
    private static let cacheDataKey = "PlezySystemShelfCacheData"
    private static var pendingDeepLink: String?
    private static var methodChannel: FlutterMethodChannel?

    static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: registrar.messenger()
      )
      methodChannel = channel
      registrar.addMethodCallDelegate(SystemShelfPlugin(), channel: channel)
    }

    static func handleOpenURL(_ url: URL) -> Bool {
      guard let contentId = contentId(from: url) else { return false }
      pendingDeepLink = contentId
      methodChannel?.invokeMethod("onShelfItemTap", arguments: ["contentId": contentId])
      return true
    }

    private static func contentId(from url: URL) -> String? {
      guard url.scheme == "plezy", url.host == "play" else { return nil }
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      return components?.queryItems?.first { $0.name == "content_id" }?.value
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "isSupported":
        result(Self.sharedDefaults != nil)
      case "sync":
        guard let args = call.arguments as? [String: Any], let rawItems = args["items"] as? [[String: Any]] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing items", details: nil))
          return
        }
        result(Self.writeItems(rawItems.map(Self.normalizedItem)))
      case "clear":
        result(Self.clearCache())
      case "remove":
        guard let args = call.arguments as? [String: Any], let contentId = args["contentId"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing contentId", details: nil))
          return
        }
        result(Self.removeItem(contentId: contentId))
      case "getInitialDeepLink":
        let contentId = Self.pendingDeepLink
        Self.pendingDeepLink = nil
        result(contentId)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    private static var sharedDefaults: UserDefaults? {
      UserDefaults(suiteName: appGroupIdentifier)
    }

    private static func normalizedItem(_ item: [String: Any]) -> [String: Any] {
      item.reduce(into: [String: Any]()) { result, entry in
        if entry.value is NSNull { return }
        result[entry.key] = entry.value
      }
    }

    private static func writeItems(_ items: [[String: Any]]) -> Bool {
      let payload: [String: Any] = [
        "updatedAt": Date().timeIntervalSince1970,
        "sections": [
          [
            "id": "continue_watching",
            "title": "Continue Watching",
            "items": items,
          ]
        ],
      ]

      return writePayload(payload)
    }

    private static func writePayload(_ payload: [String: Any]) -> Bool {
      guard let defaults = sharedDefaults else {
        return false
      }

      let sanitizedPayload = sanitizedJSONObject(payload)
      guard JSONSerialization.isValidJSONObject(sanitizedPayload) else {
        return false
      }

      do {
        let data = try JSONSerialization.data(withJSONObject: sanitizedPayload)
        defaults.set(data, forKey: cacheDataKey)
        defaults.synchronize()
      } catch {
        return false
      }

      TVTopShelfContentProvider.topShelfContentDidChange()
      return true
    }

    private static func sanitizedJSONObject(_ object: [String: Any]) -> [String: Any] {
      object.reduce(into: [String: Any]()) { result, entry in
        if let value = sanitizedJSONValue(entry.value) {
          result[entry.key] = value
        }
      }
    }

    private static func sanitizedJSONValue(_ value: Any) -> Any? {
      if value is NSNull { return nil }

      if let value = value as? String { return value }
      if let value = value as? NSNumber {
        if CFGetTypeID(value) == CFBooleanGetTypeID() { return value.boolValue }
        return value.doubleValue.isFinite ? value : nil
      }
      if let value = value as? Bool { return value }
      if let value = value as? Int { return value }
      if let value = value as? Int64 { return value }
      if let value = value as? Double { return value.isFinite ? value : nil }
      if let value = value as? Float { return value.isFinite ? Double(value) : nil }

      if let value = value as? [String: Any] {
        return value.reduce(into: [String: Any]()) { result, entry in
          if let nestedValue = sanitizedJSONValue(entry.value) {
            result[entry.key] = nestedValue
          }
        }
      }

      if let value = value as? [Any] {
        return value.compactMap { nestedValue in
          sanitizedJSONValue(nestedValue)
        }
      }

      return nil
    }

    private static func clearCache() -> Bool {
      guard let defaults = sharedDefaults else {
        return false
      }

      defaults.removeObject(forKey: cacheDataKey)
      defaults.synchronize()

      TVTopShelfContentProvider.topShelfContentDidChange()
      return true
    }

    private static func removeItem(contentId: String) -> Bool {
      guard let defaults = sharedDefaults,
        let data = defaults.data(forKey: cacheDataKey),
        var payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let sections = payload["sections"] as? [[String: Any]]
      else {
        return false
      }

      var removed = false
      let filteredSections = sections.map { section -> [String: Any] in
        var nextSection = section
        if let items = section["items"] as? [[String: Any]] {
          let filteredItems = items.filter { $0["contentId"] as? String != contentId }
          removed = removed || filteredItems.count != items.count
          nextSection["items"] = filteredItems
        }
        return nextSection
      }

      if !removed {
        return false
      }
      payload["updatedAt"] = Date().timeIntervalSince1970
      payload["sections"] = filteredSections
      return writePayload(payload)
    }
  }
#endif
