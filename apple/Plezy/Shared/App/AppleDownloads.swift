#if !os(tvOS)
import Foundation
import PlezyKit
#if os(macOS)
import AppKit
#endif

/// Downloads on iPhone, iPad and the Mac (`AppPlatform.downloads`; Apple TV has none): the shared downloader on
/// `AppleDownloadPlatform`'s background `URLSession`, stored in Documents (iPhone, iPad; excluded from backup) or the
/// app's Application Support folder (Mac). No background-work signals are read. Settings → Downloads location picks a folder on the Mac only.
final class AppleDownloads: PlatformDownloads {
    let storage: DownloadStoragePlatform = DownloadStoragePlatform.companion.apple()
    let safStorage: any SafStorageOperations = UnsupportedSafStorage.shared
    let folderPicker: any FolderPicker = AppleFolderPicker()
    let backgroundWork: (any BackgroundWorkProbe)? = nil
    private let platform = AppleDownloadPlatform()

    /// The background session moves the bytes: the shared HTTP client isn't used.
    func install(http: Ktor_client_coreHttpClient, create: @escaping (any DownloadPlatform) -> TaskDownloader) -> TaskDownloader {
        create(platform)
    }

    /// The background session goes on with the system's transfers; the next session's downloader adopts them.
    func uninstall(downloader: TaskDownloader) {}
}

/// The Mac's folder panel; iPhone and iPad offer no download folder.
private final class AppleFolderPicker: FolderPicker {
    #if os(macOS)
    var available: Bool { true }

    nonisolated func __pick(title: String) async throws -> PickedFolder? {
        guard let path = await Self.choose(title: title) else { return nil }
        return PickedFolder(path: path, type: PickedFolder.companion.FILE)
    }

    @MainActor private static func choose(title: String) -> String? {
        let panel = NSOpenPanel()
        panel.message = title
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
    #else
    var available: Bool { false }

    nonisolated func __pick(title: String) async throws -> PickedFolder? { nil }
    #endif
}
#endif
