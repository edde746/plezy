import Foundation
import Nuke
import os
import PlezyKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "artwork")

/// Nuke's shared pipeline, caching artwork as the shared core's `ArtworkCache` says:
///
/// - Each image is cached under `key(_:)`: its address's `ArtworkCache` key, without the server's token; the download
///   requests the address with its token. The disk cache (`artwork` in the app's caches, one file per image named by
///   the key's SHA-1) keeps the image as downloaded; there is no URL cache, which would store each address, token and
///   all.
/// - As the app starts, the disk cache drops the images `ArtworkCache.evictions` names: those written over 14 days
///   ago, then the oldest past 3,000. Nuke's own sweep still keeps it under 150 MB.
/// - At most six images download at once, three on the reduced visual effects tier; a download that receives nothing
///   for `ArtworkCache.STALL_TIMEOUT_MILLIS` (headers or body) is aborted, freeing its slot.
/// - Decoded images stay in memory within the platform's `ImageMemoryBudget` (`images`), a TV's sized to its display as
///   the window reports it (`fit(points:scale:)`), in the tier the user's visual effects choice picks (`use(visualEffects:)`).
/// - Requests send the app's `User-Agent: Plezy/<version>`, as its HTTP client does.
@MainActor
enum ArtworkPipeline {
    /// Sets the shared pipeline up: once, as the app starts, before any `RemoteImage`.
    static func setUp() {
        let session = URLSessionConfiguration.default
        session.urlCache = nil
        session.httpAdditionalHeaders = ["User-Agent": PlezyHttpClient.shared.userAgent(appVersion: ApplePlatform.appVersion)]
        // URLSession's request timeout is an idle one: it restarts with every byte received.
        session.timeoutIntervalForRequest = TimeInterval(ArtworkCache.shared.STALL_TIMEOUT_MILLIS) / 1000
        var configuration = ImagePipeline.Configuration(dataLoader: DataLoader(configuration: session))
        configuration.dataLoadingQueue = TaskQueue(maxConcurrentOperationCount: Int(ArtworkCache.shared.downloadConcurrency(reduced: false)))
        downloads = configuration.dataLoadingQueue
        configuration.dataCachePolicy = .storeOriginalData
        configuration.imageCache = images
        do {
            let cache = try DataCache(path: AppLaunch.caches.appending(path: "artwork", directoryHint: .isDirectory))
            // On the cache's write queue: before the images that load meanwhile are written, never under a write.
            cache.queue.async { sweep(cache.path) }
            configuration.dataCache = cache
        } catch {
            log.error("artwork disk cache unavailable: \(error.localizedDescription, privacy: .public)")
        }
        ImagePipeline.shared = ImagePipeline(configuration: configuration)
    }

    /// The decoded images in memory, within `budget(for:)`.
    nonisolated static let images: ImageCache = {
        let limits = budget(for: ArtworkDisplay(pixelRatio: 1, reduced: false, budget: 1))
        return ImageCache(costLimit: Int(limits.bytes), countLimit: Int(limits.images))
    }()

    nonisolated private static func budget(for display: ArtworkDisplay) -> ImageMemoryBudget {
        #if os(macOS)
        ImageMemoryBudget.companion.of(desktop: true, tv: false, display: display)
        #elseif os(tvOS)
        ImageMemoryBudget.companion.of(desktop: false, tv: true, display: display)
        #else
        ImageMemoryBudget.companion.of(desktop: false, tv: false, display: display)
        #endif
    }

    /// The window in pixels and its pixels per point (`fit`): the display the budgets are for.
    private static var fitted: (pixels: CGSize, scale: CGFloat)?
    /// The user's visual effects choice (`use`): the tier the budgets are for.
    private static var visualEffects = VisualEffects.auto
    /// The pipeline's download queue (`setUp`).
    private static var downloads: TaskQueue?

    /// The window, `points` at `scale` pixels per point, decides the display the memory budget is for (on a TV, the
    /// screen); the tier and the display go to the log as the window first reports them.
    static func fit(points: CGSize, scale: CGFloat) {
        guard points.width > 0, points.height > 0, scale > 0 else { return }
        let pixels = CGSize(width: (points.width * scale).rounded(), height: (points.height * scale).rounded())
        guard pixels != fitted?.pixels else { return }
        let first = fitted == nil
        fitted = (pixels, scale)
        apply(logging: first)
    }

    /// The user's visual effects choice (`Appearance.visualEffects`) picks the tier: the memory budget and the downloads
    /// at once follow a new choice at once, and the tier goes to the log.
    static func use(visualEffects effects: VisualEffects) {
        guard effects != visualEffects else { return }
        visualEffects = effects
        apply(logging: true)
    }

    /// Sizes the downloads at once to the tier and, once the window has reported the display, the memory budget to both.
    private static func apply(logging: Bool) {
        let device = ArtworkDevice(
            displayWidth: fitted.map { KotlinInt(int: Int32($0.pixels.width)) },
            displayHeight: fitted.map { KotlinInt(int: Int32($0.pixels.height)) },
            is64Bit: true, lowRamDevice: false, totalMemoryBytes: nil
        )
        #if os(tvOS)
        let tv = true
        #else
        let tv = false
        #endif
        let display = ArtworkDisplay.companion.of(
            reportedPixelRatio: Double(fitted?.scale ?? 1), tv: tv, visualEffects: visualEffects, device: device
        )
        downloads?.maxConcurrentOperationCount = Int(ArtworkCache.shared.downloadConcurrency(reduced: display.reduced))
        guard let fitted else { return }
        let limits = budget(for: display)
        images.costLimit = Int(limits.bytes)
        images.countLimit = Int(limits.images)
        guard logging else { return }
        // Into the app's log and the logs' header.
        ArtworkDiagnosticsLog.shared.log(
            effects: ArtworkDiagnosticsKt.describeEffects(visualEffects: visualEffects, device: device, display: display),
            display: ArtworkDiagnosticsKt.describeDisplay(
                physicalWidth: Int32(fitted.pixels.width), physicalHeight: Int32(fitted.pixels.height), pixelRatio: Double(fitted.scale),
                device: device, display: display
            )
        )
    }

    /// What `images` holds as `MemoryPressure.imageCacheData`, `after` a release or before it.
    nonisolated static func pressureData(after: Bool) -> [String: Any] {
        MemoryPressure.companion.imageCacheData(bytes: Int64(images.totalCost), images: Int32(images.totalCount), after: after)
    }

    /// `url`'s cache key: for a web address `ArtworkCache.key`, its tokens blanked and hashed; a file's own address.
    /// The latest 512 are kept: a view asks for its image's key each time it is drawn anew.
    static func key(_ url: URL) -> String {
        guard !url.isFileURL else { return url.absoluteString }
        let address = url.absoluteString as NSString
        if let key = keys.object(forKey: address) { return key as String }
        let key = ArtworkCache.shared.key(url: url.absoluteString)
        keys.setObject(key as NSString, forKey: address)
        return key
    }

    /// `key` (an artwork's key: a server path, or a whole address) with its tokens blanked (`UrlTokens`), for keys of
    /// in-memory caches of the app's own. The latest 512 are kept, as `key(_:)`'s.
    static func redacted(_ key: String) -> String {
        if let redacted = redactedKeys.object(forKey: key as NSString) { return redacted as String }
        let redacted = UrlTokens.shared.redact(url: key, mark: "")
        redactedKeys.setObject(redacted as NSString, forKey: key as NSString)
        return redacted
    }

    private static let redactedKeys: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 512
        return cache
    }()

    private static let keys: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 512
        return cache
    }()

    /// Deletes the images in `directory` (Nuke's data cache: a file per image, written when it was) that
    /// `ArtworkCache.evictions` names.
    nonisolated private static func sweep(_ directory: URL) {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles
        )) ?? []
        let written = files.map { file in
            let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            return KotlinLong(value: Int64((date?.timeIntervalSince1970 ?? 0) * 1000))
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        for index in ArtworkCache.shared.evictions(writtenAtMillis: written, nowMillis: now) {
            try? FileManager.default.removeItem(at: files[index.intValue])
        }
    }
}
