import Foundation
import Observation

@Observable
final class DownloadManager: NSObject {
    static let shared = DownloadManager()

    private(set) var downloads: [DownloadItem] = []
    private var session: URLSession!
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private let downloadsKey = "vibestream_downloads"
    private let maxConcurrent = 1

    /// Stored token so processQueue can be called automatically after completion
    private var currentToken: String?

    /// Tracks the last speed sample per download for calculating bytes/sec
    private var lastSpeedSample: [String: (bytes: Int64, time: Date)] = [:]

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        loadDownloads()
    }

    // MARK: - Queue Management

    func queueDownload(metadata: PlexMetadata, videoURL: URL, token: String) {
        currentToken = token

        let item = DownloadItem(
            globalKey: metadata.globalKey,
            ratingKey: metadata.ratingKey,
            serverId: metadata.serverId ?? "",
            title: metadata.displayTitle,
            type: metadata.type,
            status: .queued,
            progress: 0,
            downloadedBytes: 0,
            totalBytes: 0,
            localFilePath: nil,
            thumbPath: nil,
            addedAt: Date(),
            videoURL: videoURL.absoluteString,
            thumb: metadata.thumb,
            grandparentThumb: metadata.grandparentThumb,
            grandparentTitle: metadata.grandparentTitle,
            grandparentRatingKey: metadata.grandparentRatingKey,
            episodeTitle: metadata.mediaType == .episode ? metadata.title : nil,
            parentTitle: metadata.parentTitle,
            parentIndex: metadata.parentIndex,
            index: metadata.index,
            year: metadata.year
        )

        guard !downloads.contains(where: { $0.globalKey == item.globalKey }) else { return }
        downloads.append(item)
        saveDownloads()
        processQueue()
    }

    func pauseDownload(globalKey: String) {
        if let task = activeTasks[globalKey] {
            task.cancel(byProducingResumeData: { _ in })
        }
        activeTasks.removeValue(forKey: globalKey)
        lastSpeedSample.removeValue(forKey: globalKey)
        updateStatus(globalKey: globalKey, status: .paused)
    }

    func cancelDownload(globalKey: String) {
        activeTasks[globalKey]?.cancel()
        activeTasks.removeValue(forKey: globalKey)
        lastSpeedSample.removeValue(forKey: globalKey)
        updateStatus(globalKey: globalKey, status: .cancelled)
    }

    func deleteDownload(globalKey: String) {
        if let item = downloads.first(where: { $0.globalKey == globalKey }),
           let path = item.localFilePath {
            try? FileManager.default.removeItem(atPath: path)
        }
        downloads.removeAll { $0.globalKey == globalKey }
        activeTasks.removeValue(forKey: globalKey)
        lastSpeedSample.removeValue(forKey: globalKey)
        saveDownloads()
    }

    func retryDownload(globalKey: String, token: String) {
        currentToken = token
        if let index = downloads.firstIndex(where: { $0.globalKey == globalKey }) {
            downloads[index].status = .queued
            downloads[index].speed = 0
            saveDownloads()
        }
        processQueue()
    }

    var completedDownloads: [DownloadItem] {
        downloads.filter { $0.status == .completed }
    }

    var activeDownloads: [DownloadItem] {
        downloads.filter { $0.status == .downloading || $0.status == .queued }
    }

    // MARK: - Private

    private func processQueue() {
        guard let token = currentToken else { return }
        let activeCount = activeTasks.count
        guard activeCount < maxConcurrent else { return }

        let queued = downloads.filter { $0.status == .queued }
        for item in queued.prefix(maxConcurrent - activeCount) {
            startDownload(item, token: token)
        }
    }

    private func startDownload(_ item: DownloadItem, token: String) {
        guard let urlString = item.videoURL, let url = URL(string: urlString) else {
            updateStatus(globalKey: item.globalKey, status: .failed)
            if let index = downloads.firstIndex(where: { $0.globalKey == item.globalKey }) {
                downloads[index].errorMessage = "Missing video URL"
                saveDownloads()
            }
            return
        }

        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let task = session.downloadTask(with: request)
        activeTasks[item.globalKey] = task
        updateStatus(globalKey: item.globalKey, status: .downloading)
        task.resume()
    }

    private func updateStatus(globalKey: String, status: DownloadStatus) {
        if let index = downloads.firstIndex(where: { $0.globalKey == globalKey }) {
            downloads[index].status = status
            saveDownloads()
        }
    }

    private func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: downloadsKey)
        }
    }

    private func loadDownloads() {
        if let data = UserDefaults.standard.data(forKey: downloadsKey),
           var items = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            // Prune cancelled/failed items older than 7 days to prevent unbounded growth
            let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            let beforeCount = items.count
            items.removeAll { item in
                (item.status == .cancelled || item.status == .failed) && item.addedAt < cutoff
            }
            // Reset any items stuck in .downloading (from a previous session crash) back to queued
            for i in items.indices where items[i].status == .downloading {
                items[i].status = .queued
                items[i].speed = 0
            }
            downloads = items
            if items.count != beforeCount {
                saveDownloads()
            }
        }
    }

    func storageWarning() -> String? {
        let fileManager = FileManager.default
        guard let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeSpace = attrs[.systemFreeSize] as? Int64 else {
            return nil
        }
        // Warn if less than 500MB free
        if freeSpace < 500 * 1024 * 1024 {
            return "Low storage: \(ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)) remaining"
        }
        return nil
    }
}

// MARK: - URLSession Delegate

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let globalKey = activeTasks.first(where: { $0.value == downloadTask })?.key else { return }

        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let mediaDir = documentsDir.appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)

        let destURL = mediaDir.appendingPathComponent("\(globalKey.replacingOccurrences(of: ":", with: "_")).mp4")
        try? FileManager.default.moveItem(at: location, to: destURL)

        if let index = downloads.firstIndex(where: { $0.globalKey == globalKey }) {
            downloads[index].status = .completed
            downloads[index].progress = 1.0
            downloads[index].speed = 0
            downloads[index].localFilePath = destURL.path
            saveDownloads()
        }

        activeTasks.removeValue(forKey: globalKey)
        lastSpeedSample.removeValue(forKey: globalKey)

        // Start next queued download
        processQueue()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let globalKey = activeTasks.first(where: { $0.value == downloadTask })?.key,
              let index = downloads.firstIndex(where: { $0.globalKey == globalKey }) else { return }

        downloads[index].downloadedBytes = totalBytesWritten
        downloads[index].totalBytes = totalBytesExpectedToWrite
        if totalBytesExpectedToWrite > 0 {
            downloads[index].progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        }

        // Calculate speed (update every ~1 second to smooth out fluctuations)
        let now = Date()
        if let last = lastSpeedSample[globalKey] {
            let elapsed = now.timeIntervalSince(last.time)
            if elapsed >= 1.0 {
                let bytesDelta = totalBytesWritten - last.bytes
                downloads[index].speed = Double(bytesDelta) / elapsed
                lastSpeedSample[globalKey] = (totalBytesWritten, now)
            }
        } else {
            lastSpeedSample[globalKey] = (totalBytesWritten, now)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        guard let globalKey = activeTasks.first(where: { $0.value === task })?.key else { return }
        if let index = downloads.firstIndex(where: { $0.globalKey == globalKey }) {
            downloads[index].status = .failed
            downloads[index].speed = 0
            downloads[index].errorMessage = error.localizedDescription
            saveDownloads()
        }
        activeTasks.removeValue(forKey: globalKey)
        lastSpeedSample.removeValue(forKey: globalKey)

        // Try next queued download even after failure
        processQueue()
    }
}
