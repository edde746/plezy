import CryptoKit
import Foundation
import Security

// Live-fetch source descriptors persisted by SystemShelfPlugin.updateSources.
// This file must not import Flutter: it compiles into both TopShelfExtension
// and RunnerTests.

enum ShelfServerKind: String, Decodable {
  case plex
  case jellyfin
  case emby
}

/// Token-free server descriptor as persisted in app-group defaults.
struct ShelfServerDescriptor: Decodable {
  let serverId: String
  let kind: ShelfServerKind
  let name: String
  let baseUrl: String
  let userId: String?
}

/// A descriptor joined with its keychain token. Never persisted.
struct ShelfServerSource {
  let descriptor: ShelfServerDescriptor
  let token: String
}

extension ShelfServerSource: CustomStringConvertible, CustomDebugStringConvertible {
  // The token must never leak through interpolation or reflection dumps.
  var description: String {
    "ShelfServerSource(serverId: \(descriptor.serverId), kind: \(descriptor.kind.rawValue))"
  }
  var debugDescription: String { description }
}

struct ShelfSourcesPayload: Decodable {
  let schemaVersion: Int
  let ownerId: String
  let maxItems: Int?
  let sectionTitle: String?
  let servers: [ShelfServerDescriptor]

  private enum CodingKeys: String, CodingKey {
    case schemaVersion
    case ownerId
    case maxItems
    case sectionTitle
    case servers
  }

  /// One malformed server entry (e.g. an unknown kind written by a future
  /// schema) must not sink the whole shelf; siblings decode best-effort.
  private struct LossyServer: Decodable {
    let descriptor: ShelfServerDescriptor?

    init(from decoder: Decoder) throws {
      descriptor = try? ShelfServerDescriptor(from: decoder)
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    ownerId = try container.decode(String.self, forKey: .ownerId)
    maxItems = try container.decodeIfPresent(Int.self, forKey: .maxItems)
    sectionTitle = try container.decodeIfPresent(String.self, forKey: .sectionTitle)
    servers = (try container.decodeIfPresent([LossyServer].self, forKey: .servers) ?? [])
      .compactMap(\.descriptor)
  }
}

enum ShelfSourceStore {
  /// Must stay in lockstep with TopShelfShared.schemaVersion and
  /// SystemShelfPlugin.schemaVersion (duplicated here so this file compiles
  /// into RunnerTests without TopShelfProvider.swift).
  static let schemaVersion = 3
  static let appGroupIdentifier = "group.com.edde746.plezy"
  static let sourcesKey = "PlezySystemShelfSources"
  static let tokenKeychainService = "com.edde746.plezy.systemshelf.tokens"
  static let defaultMaxItems = 20
  static let maxItemsLimit = 20

  struct Sources {
    let ownerId: String
    let maxItems: Int
    let sectionTitle: String?
    let servers: [ShelfServerSource]
  }

  static func load() -> Sources? {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
      let data = defaults.data(forKey: sourcesKey),
      let payload = decodePayload(data)
    else { return nil }
    return join(payload: payload, tokensByServerId: loadTokens(ownerId: payload.ownerId))
  }

  /// Pure resolution used by tests: validates the persisted payload and
  /// attaches externally supplied tokens.
  static func resolve(payloadData: Data, tokensByServerId: [String: String]) -> Sources? {
    guard let payload = decodePayload(payloadData) else { return nil }
    return join(payload: payload, tokensByServerId: tokensByServerId)
  }

  static func ownerAccount(_ ownerId: String) -> String {
    SHA256.hash(data: Data(ownerId.utf8)).map { String(format: "%02x", $0) }.joined()
  }

  private static func decodePayload(_ data: Data) -> ShelfSourcesPayload? {
    guard let payload = try? JSONDecoder().decode(ShelfSourcesPayload.self, from: data),
      payload.schemaVersion == schemaVersion,
      !payload.ownerId.isEmpty
    else { return nil }
    return payload
  }

  private static func join(
    payload: ShelfSourcesPayload,
    tokensByServerId: [String: String]
  ) -> Sources? {
    let servers = payload.servers.compactMap { descriptor -> ShelfServerSource? in
      guard !descriptor.serverId.isEmpty, !descriptor.baseUrl.isEmpty,
        let token = tokensByServerId[descriptor.serverId], !token.isEmpty
      else { return nil }
      return ShelfServerSource(descriptor: descriptor, token: token)
    }
    guard !servers.isEmpty else { return nil }
    let maxItems = min(max(payload.maxItems ?? defaultMaxItems, 1), maxItemsLimit)
    return Sources(
      ownerId: payload.ownerId,
      maxItems: maxItems,
      sectionTitle: payload.sectionTitle,
      servers: servers
    )
  }

  private static func loadTokens(ownerId: String) -> [String: String] {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: tokenKeychainService,
      kSecAttrAccessGroup as String: appGroupIdentifier,
      kSecAttrAccount as String: ownerAccount(ownerId),
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
      let data = result as? Data,
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return [:] }
    return object.compactMapValues { $0 as? String }
  }
}
