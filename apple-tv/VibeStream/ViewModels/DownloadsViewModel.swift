import Foundation
import Observation

@Observable
final class DownloadsViewModel {
    private let manager = DownloadManager.shared

    var downloads: [DownloadItem] { manager.downloads }
    var completedDownloads: [DownloadItem] { manager.completedDownloads }
    var activeDownloads: [DownloadItem] { manager.activeDownloads }
    var storageWarning: String? { manager.storageWarning() }

    func pauseDownload(globalKey: String) {
        manager.pauseDownload(globalKey: globalKey)
    }

    func cancelDownload(globalKey: String) {
        manager.cancelDownload(globalKey: globalKey)
    }

    func deleteDownload(globalKey: String) {
        manager.deleteDownload(globalKey: globalKey)
    }

    func retryDownload(globalKey: String, token: String) {
        manager.retryDownload(globalKey: globalKey, token: token)
    }
}
