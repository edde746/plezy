import CryptoKit
import Foundation
import TVServices

/// The Apple TV's Top Shelf as the app hands it to its extension: the active profile's Continue Watching, which the
/// shared core writes as JSON (`TopShelfPayload`, shared/…/presentation/homescreen) and the app keeps in the App Group's
/// defaults (`TopShelfPublisher`), and the extension shows when the system asks (`TopShelfProvider`). The app has
/// already downloaded every poster into the App Group's container (`artworkFolder(owner:)`): the payload names only the
/// file, so the extension reads finished content, makes no network call, and never sees a server address or a token.
/// Without an owner or items the system shows the app's static Top Shelf image.
///
/// Compiled into the tvOS app (the App Group, the key and the folders it writes) and the extension.
struct TopShelfContent: Decodable, Equatable {
    /// The App Group the app and its extension share, named after the app's bundle identifier.
    static let appGroup = "group.com.edde746.plezy"
    /// The payload's key in the App Group's defaults.
    static let defaultsKey = "topShelf.continueWatching"
    /// The payload's format (`TopShelfPayload.SCHEMA_VERSION`): another one (an older or newer build's) shows nothing
    /// until the app writes its own.
    static let schemaVersion = 2

    /// One item of the row.
    struct Item: Decodable, Equatable {
        /// `plezy_<serverId>_<itemId>`.
        let id: String
        /// The label (`S1 E2 - Title`, the title for a movie).
        let title: String
        /// How far into its video playback got, 0 to 1; absent for none.
        let progress: Double?
        /// The poster's file name in the owner's artwork folder; absent without one.
        let imageFile: String?
        /// `plezy://play?content_id=<id>`: Play and Select alike.
        let playUrl: String
    }

    let schemaVersion: Int
    /// The profile whose Continue Watching it is; absent for none (the shelf shows the static image).
    let ownerId: String?
    /// "Continue Watching" in the app's language: the extension has none of the app's strings.
    let sectionTitle: String
    let items: [Item]

    /// The payload in `data`, or nil when another schema version wrote it, whatever its other fields. Throws for bytes
    /// that aren't a payload of this version.
    static func decode(_ data: Data) throws -> TopShelfContent? {
        struct Version: Decodable { let schemaVersion: Int }
        let decoder = JSONDecoder()
        guard try decoder.decode(Version.self, from: data).schemaVersion == schemaVersion else { return nil }
        return try decoder.decode(TopShelfContent.self, from: data)
    }

    /// The App Group's folder of every owner's posters.
    static func artworkRoot() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("SystemShelfArtwork", isDirectory: true)
    }

    /// `owner`'s poster folder: named by the SHA-256 of the profile id, so no profile id shows in the container.
    static func artworkFolder(owner: String) -> URL? {
        artworkRoot()?.appendingPathComponent(sha256(owner), isDirectory: true)
    }

    static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// A poster file's name as the app writes it: `<64 hex>.art`; any other name (a path out of the folder) is refused.
    static func isArtworkFileName(_ name: String) -> Bool {
        name.count == 68 && name.hasSuffix(".art") && name.dropLast(4).allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }

    /// The row titled `sectionTitle` with the items in their order; nil when there is no owner or no item to show.
    func sectioned() -> TVTopShelfSectionedContent? {
        guard let ownerId, let folder = Self.artworkFolder(owner: ownerId) else { return nil }
        let shelfItems = items.compactMap { Self.shelfItem($0, folder: folder) }
        guard !shelfItems.isEmpty else { return nil }
        let section = TVTopShelfItemCollection(items: shelfItems)
        section.title = sectionTitle
        return TVTopShelfSectionedContent(sections: [section])
    }

    /// The item as the shelf shows it; nil without a link (the shelf would open nothing).
    private static func shelfItem(_ item: Item, folder: URL) -> TVTopShelfSectionedItem? {
        guard let play = URL(string: item.playUrl) else { return nil }
        let shelfItem = TVTopShelfSectionedItem(identifier: item.id)
        shelfItem.title = item.title
        shelfItem.imageShape = .poster
        if let progress = item.progress { shelfItem.playbackProgress = min(max(progress, 0), 1) }
        // One URL per scale, as TVServices keys them: a URL set for both scales at once reads nil for each alone.
        if let name = item.imageFile, isArtworkFileName(name) {
            let image = folder.appendingPathComponent(name, isDirectory: false)
            shelfItem.setImageURL(image, for: .screenScale1x)
            shelfItem.setImageURL(image, for: .screenScale2x)
        }
        shelfItem.playAction = TVTopShelfAction(url: play)
        shelfItem.displayAction = TVTopShelfAction(url: play)
        return shelfItem
    }
}
