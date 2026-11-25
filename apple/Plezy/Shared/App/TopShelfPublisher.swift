#if os(tvOS)
import OSLog
import PlezyKit
import TVServices
import UIKit

/// The Apple TV's home screen (`AppPlatform.homeScreen`): the Top Shelf above the app's icon, showing the active
/// profile's Continue Watching (`SystemShelf`).
///
/// Each shelf the shared core publishes goes to the App Group the extension reads: the app downloads every poster
/// itself into the owner's artwork folder in the App Group's container (`TopShelfContent.artworkFolder`), then writes
/// the shared core's JSON (`TopShelfPayload`), which names each poster's file only, and tells the system to ask the
/// extension again (`TopShelfProvider`). A poster's source URL carries its media server's address and token: it is
/// requested here and goes nowhere else, so the extension makes no network call and the container holds no credential.
///
/// A download takes http(s) only, an ephemeral session, 2.5 s per image and 8 s for the whole shelf, at most 2 MiB per
/// image and 8 MiB per shelf, read as it arrives and cut off at the first byte past either limit (`PosterByteCap`), and
/// keeps an image only if it decodes with sides of 1 to 4096 pixels. A poster fetched once is reused while its source
/// stays the same; one whose new source fails keeps the poster the shelf showed before for that item.
///
/// A file the written shelf no longer uses goes a minute later, if the shelf written by then still doesn't use it: the
/// system may draw its previous content from it meanwhile (`ShelfArtworkLedger`). Files a previous run left get the
/// same minute from the first write.
///
/// Shelves are written in order, one at a time; ones that arrive meanwhile collapse into the latest, and a shelf older
/// than the last one written (`HomeScreenShelf.generation`, or the same generation of another owner) is dropped. A
/// shelf without an owner (a profile switch, sign-out or removal) is written at once: it cancels the write under way
/// and any shelf waiting, so the previous profile's shelf never comes back after it.
///
/// Downloads and the files' clean-up run off the main actor, one after the other with the writes.
@MainActor
final class TopShelfPublisher: @preconcurrency HomeScreen {
    nonisolated private static let log = Logger(subsystem: "com.edde746.plezy", category: "topshelf")

    let artwork: HomeScreenArtwork = .poster

    private var pending: HomeScreenShelf?
    private var worker: Task<Void, Never>?
    private var currentWrite: Task<Void, Never>?
    private var committedOwner: String?
    private var committedGeneration: Int64 = .min
    private let ledger = ShelfArtworkLedger(
        graceMillis: ShelfArtworkLedger.companion.PRUNE_GRACE_MILLIS,
        batch: ShelfArtworkLedger.companion.PRUNE_BATCH
    )
    private var pruneDue = false
    private var pruneScheduled = false

    func publish(shelf: HomeScreenShelf) {
        guard shelf.ownerId == nil else {
            pending = shelf
            return work()
        }
        pending = nil
        currentWrite?.cancel()
        guard !isStale(shelf) else { return Self.log.info("Top Shelf: dropping a stale clear") }
        guard let defaults = UserDefaults(suiteName: TopShelfContent.appGroup) else {
            return Self.log.error("no App Group \(TopShelfContent.appGroup, privacy: .public): the Top Shelf keeps what it showed")
        }
        commit(shelf, files: [:], paths: [:], defaults: defaults)
    }

    /// Runs the waiting shelf's write and the due clean-up, one at a time, until neither is left.
    private func work() {
        guard worker == nil else { return }
        worker = Task {
            while true {
                if let next = pending {
                    pending = nil
                    let write = Task { await self.write(next) }
                    currentWrite = write
                    await write.value
                    currentWrite = nil
                } else if pruneDue, let root = TopShelfContent.artworkRoot() {
                    pruneDue = false
                    await prune(root: root)
                } else {
                    break
                }
            }
            worker = nil
        }
    }

    private func isStale(_ shelf: HomeScreenShelf) -> Bool {
        shelf.generation < committedGeneration || (shelf.generation == committedGeneration && shelf.ownerId != committedOwner)
    }

    private func write(_ shelf: HomeScreenShelf) async {
        guard !isStale(shelf) else { return Self.log.info("Top Shelf: dropping a stale shelf") }
        guard let defaults = UserDefaults(suiteName: TopShelfContent.appGroup), let root = TopShelfContent.artworkRoot(),
              let owner = shelf.ownerId, let folder = TopShelfContent.artworkFolder(owner: owner) else {
            return Self.log.error("no App Group \(TopShelfContent.appGroup, privacy: .public): the Top Shelf keeps what it showed")
        }
        let sources = shelf.items.compactMap { item in item.posterSource.map { (item.contentId, $0) } }
        let downloaded = await Self.posters(owner: owner, sources: sources, folder: folder)
        // A clear or a newer shelf came during the downloads: this one is no longer the shelf to show.
        guard !Task.isCancelled, !isStale(shelf) else { return Self.log.info("Top Shelf: dropping a shelf overtaken while it downloaded") }
        // Content id to the poster's file name in the owner's folder, and to its path under the root for the ledger.
        var files: [String: String] = [:]
        var paths: [String: String] = [:]
        for item in shelf.items {
            var name = downloaded[item.contentId]
            if name == nil, let previous = ledger.fallback(owner: owner, contentId: item.contentId),
               FileManager.default.fileExists(atPath: root.appendingPathComponent(previous).path) {
                name = (previous as NSString).lastPathComponent
            }
            if let name {
                files[item.contentId] = name
                paths[item.contentId] = folder.lastPathComponent + "/" + name
            }
        }
        commit(shelf, files: files, paths: paths, defaults: defaults)
    }

    private func commit(_ shelf: HomeScreenShelf, files: [String: String], paths: [String: String], defaults: UserDefaults) {
        defaults.set(Data(TopShelfPayload.shared.json(shelf: shelf, imageFiles: files).utf8), forKey: TopShelfContent.defaultsKey)
        committedOwner = shelf.ownerId
        committedGeneration = shelf.generation
        ledger.commit(owner: shelf.ownerId, files: paths, nowMillis: Self.nowMillis())
        TVTopShelfContentProvider.topShelfContentDidChange()
        Self.log.notice("Top Shelf: \(shelf.items.count) item(s), \(files.count) poster(s)")
        pruneDue = true
        work()
    }

    /// Content id to the file name of `owner`'s poster in `folder`, for each of `sources` (content id, poster source)
    /// that can be had within the shelf's limits (8 s, `ShelfByteBudget.SHELF_LIMIT`); stops at cancellation.
    nonisolated private static func posters(owner: String, sources: [(String, String)], folder: URL) async -> [String: String] {
        let budget = ShelfByteBudget(bytesLeft: ShelfByteBudget.companion.SHELF_LIMIT)
        let deadline = Date().addingTimeInterval(8)
        var names: [String: String] = [:]
        for (contentId, source) in sources {
            if Task.isCancelled { break }
            names[contentId] = await poster(owner: owner, source: source, folder: folder, budget: budget, deadline: deadline)
        }
        return names
    }

    nonisolated private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = 2.5
        configuration.timeoutIntervalForResource = 2.5
        return URLSession(configuration: configuration)
    }()

    /// The file name of `owner`'s poster from `source` in `folder`, downloading it first when this source has none
    /// yet; nil when it can't be had within the shelf's `budget` and `deadline`.
    nonisolated private static func poster(owner: String, source: String, folder: URL, budget: ShelfByteBudget, deadline: Date) async -> String? {
        let name = TopShelfContent.sha256(owner + "\u{0}" + source) + ".art"
        let file = folder.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: file.path) { return name }
        guard let url = URL(string: source), url.scheme == "http" || url.scheme == "https",
              budget.bytesLeft > 0, deadline.timeIntervalSinceNow > 0 else { return nil }
        var request = URLRequest(url: url, timeoutInterval: min(2.5, deadline.timeIntervalSinceNow))
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        let cap = PosterByteCap(budget: budget, imageLimit: PosterByteCap.companion.POSTER_IMAGE_LIMIT)
        do {
            let (bytes, response) = try await session.bytes(for: request)
            let length = response.expectedContentLength
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  http.mimeType?.hasPrefix("image/") == true,
                  cap.acceptsLength(length: length >= 0 ? KotlinLong(value: length) : nil) else {
                bytes.task.cancel()
                log.warning("Top Shelf: a poster answered with no usable image")
                return nil
            }
            var data = Data()
            var chunk = Data()
            chunk.reserveCapacity(chunkSize)
            for try await byte in bytes {
                chunk.append(byte)
                guard chunk.count == chunkSize else { continue }
                guard cap.accept(count: Int32(chunk.count)), deadline.timeIntervalSinceNow > 0 else {
                    bytes.task.cancel()
                    log.warning("Top Shelf: a poster is past its size, the shelf's budget or its time")
                    return nil
                }
                data.append(chunk)
                chunk.removeAll(keepingCapacity: true)
            }
            if !chunk.isEmpty {
                guard cap.accept(count: Int32(chunk.count)) else {
                    log.warning("Top Shelf: a poster is past its size or the shelf's budget")
                    return nil
                }
                data.append(chunk)
            }
            guard let image = UIImage(data: data), (1...4096).contains(Int(image.size.width * image.scale)),
                  (1...4096).contains(Int(image.size.height * image.scale)) else {
                log.warning("Top Shelf: a poster isn't a usable image")
                return nil
            }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return name
        } catch {
            // The URL carries a token: only the failure's kind is logged.
            log.warning("Top Shelf: a poster download failed: \(String(describing: type(of: error)), privacy: .public)")
            return nil
        }
    }

    nonisolated private static let chunkSize = 16 * 1024

    nonisolated private static func nowMillis() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }

    /// Deletes the poster files under `root` the ledger lets go now (and the folders left empty), then comes back when
    /// the next one is due.
    private func prune(root: URL) async {
        let existing = await Self.artworkFiles(root: root)
        await Self.remove(ledger.prunable(existing: existing, nowMillis: Self.nowMillis()), root: root)
        guard !pruneScheduled, let next = ledger.nextPruneAt()?.int64Value else { return }
        pruneScheduled = true
        let wait = UInt64(max(next - Self.nowMillis(), 1_000)) * 1_000_000
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: wait)
            guard let self else { return }
            pruneScheduled = false
            pruneDue = true
            work()
        }
    }

    /// Every file under `root`'s owner folders, as `<folder>/<file>`.
    nonisolated private static func artworkFiles(root: URL) async -> [String] {
        let manager = FileManager.default
        var existing: [String] = []
        for folder in (try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [] {
            for file in (try? manager.contentsOfDirectory(atPath: folder.path)) ?? [] {
                existing.append(folder.lastPathComponent + "/" + file)
            }
        }
        return existing
    }

    /// Deletes `paths` under `root`, then the owner folders left empty.
    nonisolated private static func remove(_ paths: [String], root: URL) async {
        let manager = FileManager.default
        for path in paths { try? manager.removeItem(at: root.appendingPathComponent(path)) }
        for folder in (try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
            where (try? manager.contentsOfDirectory(atPath: folder.path))?.isEmpty ?? true {
            try? manager.removeItem(at: folder)
        }
    }
}
#endif
