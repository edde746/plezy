import SwiftUI
import PlezyKit

/// A browse screen with nothing to list: the error with Retry after a failure (`browse.error`), else the empty state.
struct BrowsePlaceholder: View {
    let load: LoadState
    let error: String?
    let onRetry: () -> Void
    let emptyMessage: String
    var emptySymbol = "rectangle.stack"

    var body: some View {
        if load == .error {
            ErrorStateView(message: error ?? "", onRetry: onRetry)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("browse.error")
        } else {
            EmptyStateView(message: emptyMessage, systemImage: emptySymbol)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("browse.empty")
        }
    }
}
