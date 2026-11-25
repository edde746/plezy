import SwiftUI
import PlezyKit

#if !os(tvOS)
/// A sheet's Close, which loses nothing, for its bar's cancellation slot: the system's close button on iOS and macOS 26
/// and later (an ✕), `title` (Close) before. Escape presses it, with or without focus in the sheet; Return doesn't.
/// `id` is its accessibility identifier. Apple TV has the remote's Menu.
struct SheetCloseButton: View {
    var title = T.shared.nav.close
    let id: String
    let action: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26, macOS 26, *) {
                Button(role: .close, action: action)
            } else {
                Button(title, action: action)
            }
        }
        .keyboardShortcut(.cancelAction)
        .accessibilityIdentifier(id)
    }
}
#endif
