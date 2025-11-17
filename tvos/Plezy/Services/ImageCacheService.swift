//
//  ImageCacheService.swift
//  Beacon tvOS
//
//  Image caching service to reduce network usage and improve performance
//

import SwiftUI
import Combine

/// Manages in-memory and disk-based image caching
class ImageCacheService {
    static let shared = ImageCacheService()

    // In-memory cache using NSCache for automatic memory management
    private let memoryCache = NSCache<NSString, UIImage>()

    // Disk cache directory
    private let diskCacheDirectory: URL

    // Track ongoing downloads to avoid duplicate requests
    private var activeDownloads: [URL: Task<UIImage?, Never>] = [:]
    private let downloadLock = NSLock()

    // Default cache limits
    private let memoryCacheCountLimit = 100  // Max 100 images in memory
    private let memoryCacheTotalCostLimit = 50 * 1024 * 1024  // 50 MB max memory
    private let diskCacheSizeLimit = 200 * 1024 * 1024  // 200 MB max disk

    private init() {
        // Set up memory cache limits
        memoryCache.countLimit = memoryCacheCountLimit
        memoryCache.totalCostLimit = memoryCacheTotalCostLimit

        // Set up disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = cacheDir.appendingPathComponent("ImageCache")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)

        print("🖼️ [ImageCache] Initialized with memory limit: \(memoryCacheTotalCostLimit / 1024 / 1024)MB, disk limit: \(diskCacheSizeLimit / 1024 / 1024)MB")
    }

    /// Fetch image from cache or download it
    func image(for url: URL) async -> UIImage? {
        // Check memory cache first
        let cacheKey = url.absoluteString as NSString
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            print("✅ [ImageCache] Memory hit: \(url.lastPathComponent)")
            return cachedImage
        }

        // Check disk cache
        if let diskImage = loadFromDisk(url: url) {
            print("💾 [ImageCache] Disk hit: \(url.lastPathComponent)")
            // Store in memory for faster access next time
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }

        // Check if already downloading (async-safe)
        let existingTask = await withCheckedContinuation { continuation in
            downloadLock.lock()
            let task = activeDownloads[url]
            downloadLock.unlock()
            continuation.resume(returning: task)
        }

        if let existingTask = existingTask {
            print("⏳ [ImageCache] Waiting for existing download: \(url.lastPathComponent)")
            return await existingTask.value
        }

        // Create new download task
        let downloadTask = Task<UIImage?, Never> {
            await self.downloadImage(from: url)
        }

        await withCheckedContinuation { continuation in
            downloadLock.lock()
            activeDownloads[url] = downloadTask
            downloadLock.unlock()
            continuation.resume()
        }

        // Wait for download
        let image = await downloadTask.value

        // Clean up task (async-safe)
        await withCheckedContinuation { continuation in
            downloadLock.lock()
            activeDownloads.removeValue(forKey: url)
            downloadLock.unlock()
            continuation.resume()
        }

        return image
    }

    /// Download image from URL
    private func downloadImage(from url: URL) async -> UIImage? {
        print("⬇️ [ImageCache] Downloading: \(url.lastPathComponent)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("❌ [ImageCache] Download failed: Invalid response")
                return nil
            }

            guard let image = UIImage(data: data) else {
                print("❌ [ImageCache] Download failed: Invalid image data")
                return nil
            }

            print("✅ [ImageCache] Downloaded: \(url.lastPathComponent) (\(data.count / 1024)KB)")

            // Cache the image
            let cacheKey = url.absoluteString as NSString
            memoryCache.setObject(image, forKey: cacheKey, cost: data.count)

            // Save to disk asynchronously
            Task.detached(priority: .background) {
                await self.saveToDisk(image: image, url: url, data: data)
            }

            return image
        } catch {
            print("❌ [ImageCache] Download error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Load image from disk cache
    private func loadFromDisk(url: URL) -> UIImage? {
        let fileURL = diskCacheURL(for: url)

        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    /// Save image to disk cache
    private func saveToDisk(image: UIImage, url: URL, data: Data) async {
        let fileURL = diskCacheURL(for: url)

        do {
            try data.write(to: fileURL)
            print("💾 [ImageCache] Saved to disk: \(url.lastPathComponent)")

            // Clean up old cache if needed
            await cleanDiskCacheIfNeeded()
        } catch {
            print("❌ [ImageCache] Disk save error: \(error.localizedDescription)")
        }
    }

    /// Get disk cache file URL for a given image URL
    private func diskCacheURL(for url: URL) -> URL {
        // Use MD5 hash of URL as filename to avoid filesystem issues
        let filename = url.absoluteString.md5Hash
        return diskCacheDirectory.appendingPathComponent(filename)
    }

    /// Clean disk cache if it exceeds size limit
    private func cleanDiskCacheIfNeeded() async {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: diskCacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
            )

            // Calculate total size
            var totalSize: Int64 = 0
            var fileInfos: [(url: URL, size: Int64, date: Date)] = []

            for fileURL in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let size = attributes[.size] as? Int64 ?? 0
                let date = attributes[.modificationDate] as? Date ?? Date.distantPast

                totalSize += size
                fileInfos.append((url: fileURL, size: size, date: date))
            }

            // If under limit, no cleanup needed
            if totalSize <= diskCacheSizeLimit {
                return
            }

            print("🧹 [ImageCache] Disk cache cleanup needed: \(totalSize / 1024 / 1024)MB / \(diskCacheSizeLimit / 1024 / 1024)MB")

            // Sort by date (oldest first)
            fileInfos.sort { $0.date < $1.date }

            // Remove oldest files until under limit
            for fileInfo in fileInfos {
                if totalSize <= diskCacheSizeLimit {
                    break
                }

                try? FileManager.default.removeItem(at: fileInfo.url)
                totalSize -= fileInfo.size
                print("🗑️ [ImageCache] Removed old cache file: \(fileInfo.url.lastPathComponent)")
            }

            print("✅ [ImageCache] Cleanup complete: \(totalSize / 1024 / 1024)MB")
        } catch {
            print("❌ [ImageCache] Cleanup error: \(error.localizedDescription)")
        }
    }

    /// Clear all cached images
    func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        print("🗑️ [ImageCache] Cleared all caches")
    }

    /// Prefetch images for better performance
    func prefetch(urls: [URL]) {
        Task {
            for url in urls {
                _ = await image(for: url)
            }
        }
    }
}

// MARK: - String MD5 Extension

extension String {
    var md5Hash: String {
        // Simple hash function for filename generation
        // Using hashValue is platform-specific but good enough for cache keys
        let hash = abs(self.hashValue)
        return "\(hash)"
    }
}

// MARK: - Cached AsyncImage View

/// Drop-in replacement for AsyncImage that uses image caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = true

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else {
                placeholder()
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else {
            isLoading = false
            return
        }

        let cachedImage = await ImageCacheService.shared.image(for: url)
        self.image = cachedImage
        self.isLoading = false
    }
}

// MARK: - Convenience initializer matching AsyncImage API

extension CachedAsyncImage where Content == Image, Placeholder == EmptyView {
    init(url: URL?) {
        self.init(
            url: url,
            content: { $0.resizable() },
            placeholder: { EmptyView() }
        )
    }
}
