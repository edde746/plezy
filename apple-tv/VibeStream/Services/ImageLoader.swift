import SwiftUI
import CryptoKit

actor ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private var activeTasks: [String: Task<UIImage?, Never>] = [:]

    private init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDir.appendingPathComponent("PlexImages", isDirectory: true)

        // One-time migration: clear old disk cache that used NSString.hash (collision-prone)
        let migrationKey = "image_cache_sha256_migrated"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            try? FileManager.default.removeItem(at: diskCacheURL)
            UserDefaults.standard.set(true, forKey: migrationKey)
        }

        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }

    private func diskCacheFilename(for key: String) -> String {
        let digest = SHA256.hash(data: Data(key.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func loadImage(from url: URL, token: String? = nil) async -> UIImage? {
        let cacheKey = url.absoluteString as NSString

        // Memory cache
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        // Disk cache
        let diskPath = diskCacheURL.appendingPathComponent(diskCacheFilename(for: url.absoluteString))
        if let diskData = try? Data(contentsOf: diskPath),
           let diskImage = UIImage(data: diskData) {
            cache.setObject(diskImage, forKey: cacheKey, cost: diskData.count)
            return diskImage
        }

        // Deduplicate concurrent requests
        if let existing = activeTasks[url.absoluteString] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            if let token {
                request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
            }

            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let image = UIImage(data: data) else {
                return nil
            }

            cache.setObject(image, forKey: cacheKey, cost: data.count)
            try? data.write(to: diskPath)
            return image
        }

        activeTasks[url.absoluteString] = task
        let result = await task.value
        activeTasks.removeValue(forKey: url.absoluteString)
        return result
    }

    func clearCache() {
        cache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    func cacheSize() -> Int {
        guard let enumerator = FileManager.default.enumerator(
            at: diskCacheURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += size
            }
        }
        return total
    }
}
