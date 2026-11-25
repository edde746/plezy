import OSLog
import TVServices

/// The Top Shelf extension (Info.plist's NSExtensionPrincipalClass): when the app's icon is in the top row of the home
/// screen and has focus, the system asks it for the shelf above, which shows Continue Watching as the app last wrote it
/// to the App Group (`TopShelfContent`), poster, progress and links included. The app tells the system after each
/// write (`TopShelfPublisher`).
/// Nothing written, no item, or a payload of another build's format: nil, and the system shows the static Top Shelf
/// image from the app's asset catalog.
final class TopShelfProvider: TVTopShelfContentProvider {
    private static let log = Logger(subsystem: "com.edde746.plezy", category: "topshelf")

    /// The completion handler's form: the content is made and handed over on the system's call, nothing crossing to
    /// another task (TVServices' content objects aren't Sendable).
    override func loadTopShelfContent(completionHandler: @escaping ((any TVTopShelfContent)?) -> Void) {
        completionHandler(Self.content())
    }

    private static func content() -> (any TVTopShelfContent)? {
        guard let defaults = UserDefaults(suiteName: TopShelfContent.appGroup) else {
            log.error("no defaults for the App Group \(TopShelfContent.appGroup, privacy: .public)")
            return nil
        }
        guard let data = defaults.data(forKey: TopShelfContent.defaultsKey) else { return nil }
        do {
            guard let content = try TopShelfContent.decode(data) else {
                log.notice("the payload is another schema version's; showing the static image")
                return nil
            }
            return content.sectioned()
        } catch {
            log.error("the payload doesn't decode: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
