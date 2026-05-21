import Foundation
import Observation

@Observable
final class HubDetailViewModel: ErrorReporting {
    private(set) var items: [PlexMetadata] = []
    private(set) var isLoading = false
    var error: String?
    var isAuthError = false

    func loadContent(hubKey: String, client: PlexClient) async {
        isLoading = true
        error = nil
        isAuthError = false

        do {
            items = try await client.getHubContent(hubKey: hubKey)
        } catch {
            handlePlexError(error)
        }

        isLoading = false
    }
}
