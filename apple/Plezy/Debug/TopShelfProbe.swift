#if os(tvOS)
import SwiftUI
import TVServices

/// Debug builds on Apple TV: the Top Shelf as the extension would show it, read the extension's way (`TopShelfContent`:
/// the App Group's payload, decoded, sectioned, each image a file in the owner's artwork folder) every 2 s, as the label
/// of an element the UI tests read (`app.topShelf`): `owner=<yes|no> items=<n> shelf=<shown items> images=<files that
/// exist> remote=<image URLs not on disk>`, or `none` while nothing is written.
struct TopShelfProbe: View {
    @State private var summary = "none"

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: summary))
            .accessibilityIdentifier("app.topShelf")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .task {
                while !Task.isCancelled {
                    summary = Self.read()
                    try? await Task.sleep(for: .seconds(2))
                }
            }
    }

    private static func read() -> String {
        guard let data = UserDefaults(suiteName: TopShelfContent.appGroup)?.data(forKey: TopShelfContent.defaultsKey),
              let content = try? TopShelfContent.decode(data) else { return "none" }
        let items = content.sectioned()?.sections.flatMap(\.items) ?? []
        let images = items.compactMap { $0.imageURL(for: .screenScale1x) }
        let local = images.filter { $0.isFileURL && FileManager.default.fileExists(atPath: $0.path) }
        return "owner=\(content.ownerId == nil ? "no" : "yes") items=\(content.items.count) shelf=\(items.count) "
            + "images=\(local.count) remote=\(images.count - local.count)"
    }
}
#endif
