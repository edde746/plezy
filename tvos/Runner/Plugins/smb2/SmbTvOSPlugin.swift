import Darwin
import Flutter
import Foundation
import AMSMB2

private enum SmbBridgeFailure: Error {
  case invalidParameter
  case cancelled
}

final class SmbTvOSPlugin: NSObject, FlutterPlugin {
  private let lock = NSLock()
  private var managers: [String: SMB2Manager] = [:]

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "org.snapetech.plezyng/smb2",
      binaryMessenger: registrar.messenger()
    )
    let instance = SmbTvOSPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard ["connect", "listDirectory", "stat", "read", "disconnect"].contains(call.method) else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let arguments = call.arguments as? [String: Any] else {
      deliver(FlutterError(code: "invalidParam", message: "Invalid SMB request.", details: nil), result)
      return
    }

    Task {
      do {
        let value = try await perform(method: call.method, arguments: arguments)
        deliver(value, result)
      } catch {
        deliver(mapError(error, operation: call.method), result)
      }
    }
  }

  private func perform(method: String, arguments: [String: Any]) async throws -> Any? {
    switch method {
    case "connect":
      guard
        let host = arguments["host"] as? String, !host.isEmpty,
        let share = arguments["share"] as? String, !share.isEmpty,
        !share.contains("/"), !share.contains("\\"), share != ".", share != ".."
      else {
        throw SmbBridgeFailure.invalidParameter
      }

      var components = URLComponents()
      components.scheme = "smb"
      components.host = host
      guard let serverURL = components.url else {
        throw SmbBridgeFailure.invalidParameter
      }

      let username = (arguments["user"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      let password = arguments["password"] as? String ?? ""
      let domain = arguments["domain"] as? String ?? ""
      let credential: URLCredential?
      if let username, !username.isEmpty {
        credential = URLCredential(
          user: username,
          password: password,
          persistence: .forSession
        )
      } else {
        credential = nil
      }

      guard let manager = SMB2Manager(url: serverURL, domain: domain, credential: credential) else {
        throw SmbBridgeFailure.invalidParameter
      }
      let timeoutMs = (arguments["timeoutMilliseconds"] as? NSNumber)?.doubleValue ?? 20_000
      manager.timeout = max(1, timeoutMs / 1_000)
      let seal = (arguments["seal"] as? NSNumber)?.boolValue ?? false
      try await manager.connectShare(name: share, encrypted: seal)

      let handle = UUID().uuidString
      store(manager, for: handle)
      return handle

    case "listDirectory":
      let manager = try manager(for: arguments)
      let path = try validatedPath(arguments["path"])
      let rows = try await manager.contentsOfDirectory(atPath: path)
      return rows.compactMap { row -> [String: Any]? in
        guard let name = row[.nameKey] as? String, !name.isEmpty else { return nil }
        return resourceValues(row, name: name)
      }

    case "stat":
      let manager = try manager(for: arguments)
      let path = try validatedPath(arguments["path"])
      let values = try await manager.attributesOfItem(atPath: path)
      let name = values[.nameKey] as? String ?? (path as NSString).lastPathComponent
      return resourceValues(values, name: name)

    case "read":
      let manager = try manager(for: arguments)
      let path = try validatedPath(arguments["path"])
      guard
        let offsetNumber = arguments["offset"] as? NSNumber,
        let lengthNumber = arguments["length"] as? NSNumber
      else {
        throw SmbBridgeFailure.invalidParameter
      }
      let offset = offsetNumber.int64Value
      let length = lengthNumber.int64Value
      let maximumLength: Int64 = 8 * 1024 * 1024
      guard
        offset >= 0, length >= 0, length <= maximumLength,
        offset <= Int64.max - length
      else {
        throw SmbBridgeFailure.invalidParameter
      }
      let range = UInt64(offset)..<UInt64(offset + length)
      let data: Data = try await manager.contents(atPath: path, range: range, progress: nil)
      return FlutterStandardTypedData(bytes: data)

    case "disconnect":
      guard let handle = arguments["handle"] as? String else {
        throw SmbBridgeFailure.invalidParameter
      }
      let manager = removeManager(for: handle)
      if let manager {
        try await manager.disconnectShare(gracefully: true)
      }
      return nil

    default:
      throw SmbBridgeFailure.invalidParameter
    }
  }

  private func store(_ manager: SMB2Manager, for handle: String) {
    lock.lock()
    managers[handle] = manager
    lock.unlock()
  }

  private func removeManager(for handle: String) -> SMB2Manager? {
    lock.lock()
    defer { lock.unlock() }
    return managers.removeValue(forKey: handle)
  }

  private func manager(for arguments: [String: Any]) throws -> SMB2Manager {
    guard let handle = arguments["handle"] as? String else {
      throw SmbBridgeFailure.invalidParameter
    }
    lock.lock()
    let manager = managers[handle]
    lock.unlock()
    guard let manager else { throw SmbBridgeFailure.cancelled }
    return manager
  }

  private func validatedPath(_ value: Any?) throws -> String {
    guard let path = value as? String, !path.contains("\\"), !path.contains("\0") else {
      throw SmbBridgeFailure.invalidParameter
    }
    let segments = path.split(separator: "/", omittingEmptySubsequences: true)
    guard !segments.contains(where: { $0 == "." || $0 == ".." }) else {
      throw SmbBridgeFailure.invalidParameter
    }
    return segments.joined(separator: "/")
  }

  private func resourceValues(
    _ values: [URLResourceKey: Any],
    name: String
  ) -> [String: Any] {
    let isDirectory = bool(values[.isDirectoryKey]) ?? false
    let isFile = bool(values[.isRegularFileKey]) ?? false
    let hidden = bool(values[.isHiddenKey]) ?? name.hasPrefix(".")
    let size = (values[.fileSizeKey] as? NSNumber)?.int64Value ?? 0
    let modified = values[.contentModificationDateKey] as? Date
    let modifiedMilliseconds = modified.map {
      Int64(($0.timeIntervalSince1970 * 1_000).rounded())
    } ?? 0
    return [
      "name": name,
      "size": size,
      "modified": modifiedMilliseconds,
      "isHidden": hidden,
      "isFile": isFile,
      "isDirectory": isDirectory,
    ]
  }

  private func bool(_ value: Any?) -> Bool? {
    if let number = value as? NSNumber { return number.boolValue }
    if let value = value as? Bool { return value }
    return nil
  }

  private func mapError(_ error: Error, operation: String) -> FlutterError {
    let code: String
    if let failure = error as? SmbBridgeFailure {
      switch failure {
      case .invalidParameter: code = "invalidParam"
      case .cancelled: code = "cancelled"
      }
    } else {
      let value = error as NSError
      if value.domain == NSOSStatusErrorDomain {
        code = operation == "connect" ? "auth" : "network"
      } else if value.domain == NSPOSIXErrorDomain {
        switch value.code {
        case Int(ENOENT): code = "notFound"
        case Int(ENOTDIR): code = "notADirectory"
        case Int(EISDIR): code = "isADirectory"
        case Int(EACCES), Int(EPERM): code = operation == "connect" ? "auth" : "accessDenied"
        case Int(EINVAL): code = "invalidParam"
        case Int(ECANCELED): code = "cancelled"
        default: code = "network"
        }
      } else {
        code = "network"
      }
    }
    return FlutterError(code: code, message: "SMB request failed.", details: nil)
  }

  private func deliver(_ value: Any?, _ result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      result(value)
    }
  }
}
