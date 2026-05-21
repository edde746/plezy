import Foundation

/// Shared error-handling protocol for ViewModels that interact with the
/// Plex server. Provides a single `handlePlexError` method that maps
/// errors into user-facing messages and detects auth failures, replacing
/// duplicate catch-block logic across ViewModels.
protocol ErrorReporting: AnyObject {
    var error: String? { get set }
    var isAuthError: Bool { get set }
}

extension ErrorReporting {
    func handlePlexError(_ error: Error) {
        if let plexError = error as? PlexClientError {
            self.error = plexError.localizedDescription
            self.isAuthError = plexError.isAuthError
        } else if error is URLError {
            self.error = "Could not connect to server. Check your network connection."
            self.isAuthError = false
        } else {
            self.error = error.localizedDescription
            self.isAuthError = false
        }
    }
}
