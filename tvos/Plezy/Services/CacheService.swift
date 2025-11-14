//
//  CacheService.swift
//  Plezy tvOS
//
//  Cache service to store API responses and reduce unnecessary network calls
//

import Foundation

@MainActor
class CacheService: ObservableObject {
    static let shared = CacheService()

    private struct CacheEntry<T> {
        let data: T
        let timestamp: Date
        let ttl: TimeInterval // Time to live in seconds

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }

    private var cache: [String: Any] = [:]

    // Default TTL: 5 minutes for home content, 10 minutes for libraries
    private let defaultHomeTTL: TimeInterval = 300  // 5 minutes
    private let defaultLibraryTTL: TimeInterval = 600  // 10 minutes

    func get<T>(_ key: String) -> T? {
        guard let entry = cache[key] as? CacheEntry<T> else {
            return nil
        }

        if entry.isExpired {
            print("🗑️ [Cache] Expired cache for key: \(key)")
            cache.removeValue(forKey: key)
            return nil
        }

        print("✅ [Cache] Hit for key: \(key)")
        return entry.data
    }

    func set<T>(_ key: String, value: T, ttl: TimeInterval? = nil) {
        let timeToLive = ttl ?? defaultHomeTTL
        cache[key] = CacheEntry(data: value, timestamp: Date(), ttl: timeToLive)
        print("💾 [Cache] Stored key: \(key) with TTL: \(timeToLive)s")
    }

    func invalidate(_ key: String) {
        cache.removeValue(forKey: key)
        print("🗑️ [Cache] Invalidated key: \(key)")
    }

    func invalidateAll() {
        cache.removeAll()
        print("🗑️ [Cache] Cleared all cache")
    }

    func invalidatePattern(_ pattern: String) {
        let keysToRemove = cache.keys.filter { $0.contains(pattern) }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
        print("🗑️ [Cache] Invalidated \(keysToRemove.count) keys matching pattern: \(pattern)")
    }

    // Convenience keys
    static func homeKey(serverID: String) -> String {
        "home_\(serverID)"
    }

    static func librariesKey(serverID: String) -> String {
        "libraries_\(serverID)"
    }

    static func libraryContentKey(serverID: String, libraryKey: String) -> String {
        "library_\(serverID)_\(libraryKey)"
    }
}
