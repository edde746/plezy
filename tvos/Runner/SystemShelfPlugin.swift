import Foundation
import TVServices

#if os(tvOS)
  import Flutter

  final class SystemShelfPlugin: NSObject, FlutterPlugin {
    private static let channelName = "com.plezy/system_shelf"
    private static let appGroupIdentifier = "group.com.edde746.plezy"
    private static let cacheFileName = "PlezySystemShelfCache.json"
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
        let supported = Self.cacheURL != nil
        if !supported {
          Self.log("App Group container unavailable")
        }
        result(supported)
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

    private static var appGroupContainerURL: URL? {
      FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    private static var cacheURL: URL? {
      appGroupContainerURL?.appendingPathComponent(cacheFileName, isDirectory: false)
    }

    private static func log(_ message: String) {
      NSLog("PlezySystemShelf: %@", message)
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
      guard let url = cacheURL else {
        log("Cannot write cache because App Group container is unavailable")
        return false
      }

      guard JSONSerialization.isValidJSONObject(payload),
        let data = try? JSONSerialization.data(withJSONObject: payload)
      else {
        log("Cannot write cache because payload is not valid JSON")
        return false
      }

      do {
        try data.write(to: url, options: [.atomic])
      } catch {
        log("Failed to write cache: \(error)")
        return false
      }

      let itemCount =
        (payload["sections"] as? [[String: Any]])?.reduce(0) { count, section in
          count + ((section["items"] as? [[String: Any]])?.count ?? 0)
        } ?? 0
      log("Wrote cache with \(itemCount) items")
      TVTopShelfContentProvider.topShelfContentDidChange()
      return true
    }

    private static func clearCache() -> Bool {
      guard let url = cacheURL else {
        log("Cannot clear cache because App Group container is unavailable")
        return false
      }

      do {
        if FileManager.default.fileExists(atPath: url.path) {
          try FileManager.default.removeItem(at: url)
        }
      } catch {
        log("Failed to clear cache: \(error)")
        return false
      }

      log("Cleared cache")
      TVTopShelfContentProvider.topShelfContentDidChange()
      return true
    }

    private static func removeItem(contentId: String) -> Bool {
      guard let url = cacheURL,
        let data = try? Data(contentsOf: url),
        var payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let sections = payload["sections"] as? [[String: Any]]
      else {
        log("Cannot remove cache item because cache is unavailable or invalid")
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

      if !removed { return false }
      payload["updatedAt"] = Date().timeIntervalSince1970
      payload["sections"] = filteredSections
      return writePayload(payload)
    }
  }
#endif
