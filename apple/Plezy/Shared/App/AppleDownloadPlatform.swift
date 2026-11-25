#if !os(tvOS)
import Foundation
import OSLog
import PlezyKit
import UserNotifications

private let log = Logger(subsystem: "com.edde746.plezy", category: "downloads")

/// The shared `TaskDownloader`'s `DownloadPlatform` on iPhone, iPad and the Mac (Apple TV has none: its storage is a
/// cache the system purges). The base directories are the earlier releases' (Documents and Application Support; on the
/// Mac, whose Application Support every app shares, the app's own folder there for both), so the paths they stored keep
/// resolving. A task's bytes arrive in `download_tasks` in Application Support, excluded from backups; the background
/// `URLSession` moves them (`BackgroundTransport`). A task that completes, fails or pauses shows a notification when the
/// app may post them. One per process.
final class AppleDownloadPlatform: DownloadPlatform {
    let transport: any DownloadTransport = BackgroundTransport.shared
    let tempDirectory: String
    private let documentsDirectory: String
    private let supportDirectory: String

    /// The app's Application Support folder (on the Mac, the app's own folder there).
    private static var supportDirectoryPath: String {
        let support = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
            ?? NSHomeDirectory() + "/Library/Application Support"
        #if os(macOS)
        return support + "/" + (Bundle.main.bundleIdentifier ?? "com.edde746.plezy")
        #else
        return support
        #endif
    }

    /// Where the downloader's transfers write their bytes until they complete; the startup discards them when the
    /// database can't open on a full disk (`AppBootstrap.product`).
    static var tempDirectoryPath: String { supportDirectoryPath + "/download_tasks" }

    init() {
        supportDirectory = Self.supportDirectoryPath
        #if os(macOS)
        documentsDirectory = supportDirectory
        #else
        documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            ?? NSHomeDirectory() + "/Documents"
        #endif
        tempDirectory = Self.tempDirectoryPath
        do {
            try FileManager.default.createDirectory(atPath: tempDirectory, withIntermediateDirectories: true)
        } catch {
            log.error("download temporary folder not made: \(String(describing: error), privacy: .public)")
        }
        var url = URL(filePath: tempDirectory, directoryHint: .isDirectory)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try url.setResourceValues(values)
        } catch {
            log.error("download temporary folder not excluded from backups: \(String(describing: error), privacy: .public)")
        }
    }

    func baseDirectoryPath(base: BaseDirectory) -> String {
        switch base {
        case .applicationDocuments: documentsDirectory
        case .applicationSupport: supportDirectory
        case .root: "/"
        }
    }

    func capacity(path: String) -> VolumeCapacity? {
        BackgroundTransport.capacity(atPath: path)
    }

    /// Storage-access-framework documents are Android's.
    var documents: (any DocumentStore)? { nil }

    /// The background session runs the transfers whether the app runs or not: nothing to start.
    func onActive(active: Bool, wifiOnly: Bool) {}

    func notify(notification: TaskNotification) {
        let id = notification.task.taskId
        let center = UNUserNotificationCenter.current()
        switch notification.state {
        case .complete, .error, .paused:
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            let request = UNNotificationRequest(identifier: Self.prefix + id, content: content, trigger: nil)
            center.getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
                center.add(request) { error in
                    if let error { log.error("download notification not posted: \(String(describing: error), privacy: .public)") }
                }
            }
        default:
            center.removeDeliveredNotifications(withIdentifiers: [Self.prefix + id])
        }
    }

    private static let prefix = "download."
}
#endif
