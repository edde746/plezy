import SwiftUI
import Observation

@Observable
final class MediaFocusModel {
    var focusedMedia: PlexMetadata?

    private var debounceTask: Task<Void, Never>?

    /// Debounced focus update — prevents rapid scrolling from triggering
    /// expensive hero backdrop/color/logo updates for every intermediate card.
    func updateFocus(_ item: PlexMetadata) {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            focusedMedia = item
        }
    }
}
