import SwiftUI

/// Debug builds: every text `announce` posted since the launch, in order.
@MainActor
@Observable
final class AnnouncementLog {
    static let shared = AnnouncementLog()

    var texts: [String] = []
}

/// Debug builds: what was announced (`AnnouncementLog`), one text per line (`none` before the first), as the label of
/// an element the UI tests read (`app.announcements`; the Mac doesn't report a plain element's value), since XCUITest
/// can't hear VoiceOver.
struct AnnouncementProbe: View {
    var body: some View {
        let texts = AnnouncementLog.shared.texts
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: texts.isEmpty ? "none" : texts.joined(separator: "\n")))
            .accessibilityIdentifier("app.announcements")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
