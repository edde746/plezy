import Foundation
import UIKit

/// Simple in-memory LRU image cache for the Watch app
/// Keeps images scaled to small sizes to minimize memory pressure
class WatchImageCache {
    static let shared = WatchImageCache()

    private let maxEntries = 15
    private let targetSize = CGSize(width: 100, height: 100)

    private var cache: [String: CacheEntry] = [:]
    private var accessOrder: [String] = []

    struct CacheEntry {
        let image: UIImage
        let timestamp: Date
    }

    /// Get a cached image for the given URL string
    func get(_ urlString: String) -> UIImage? {
        guard let entry = cache[urlString] else { return nil }
        // Move to end of access order (most recently used)
        accessOrder.removeAll { $0 == urlString }
        accessOrder.append(urlString)
        return entry.image
    }

    /// Store an image in the cache, scaled to target size
    func set(_ urlString: String, image: UIImage) {
        let scaled = scale(image, to: targetSize)
        cache[urlString] = CacheEntry(image: scaled, timestamp: Date())

        accessOrder.removeAll { $0 == urlString }
        accessOrder.append(urlString)

        // Evict least recently used if over capacity
        while cache.count > maxEntries, let oldest = accessOrder.first {
            accessOrder.removeFirst()
            cache.removeValue(forKey: oldest)
        }
    }

    /// Load an image from URL with caching
    func loadImage(urlString: String, token: String?, completion: @escaping (UIImage?) -> Void) {
        if let cached = get(urlString) {
            completion(cached)
            return
        }

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        if let token = token {
            request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.set(urlString, image: image)
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }

    private func scale(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}
