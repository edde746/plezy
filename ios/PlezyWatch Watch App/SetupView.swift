import SwiftUI

/// Manual credential entry for standalone Watch setup (without phone)
struct SetupView: View {
    @State private var serverUrl = ""
    @State private var plexToken = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Manual Setup")
                    .font(.system(size: 14, weight: .semibold))

                Text("Enter your Plex server details to use the Watch app without your phone.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("Server URL", text: $serverUrl)
                    .font(.system(size: 12))
                    .textContentType(.URL)
                    .autocorrectionDisabled()

                TextField("Plex Token", text: $plexToken)
                    .font(.system(size: 12))
                    .autocorrectionDisabled()

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                }

                Button(action: save) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(serverUrl.isEmpty || plexToken.isEmpty || isSaving)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.2)))
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Setup")
    }

    private func save() {
        // Normalize URL: remove trailing slash
        var url = serverUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if url.hasSuffix("/") { url = String(url.dropLast()) }

        // Basic validation
        guard url.hasPrefix("http://") || url.hasPrefix("https://") else {
            errorMessage = "URL must start with http:// or https://"
            return
        }

        let token = plexToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            errorMessage = "Token is required"
            return
        }

        isSaving = true
        errorMessage = nil

        PlexWatchClient.shared.saveCredentials(serverUrl: url, token: token)

        // Verify the credentials work
        Task {
            let libraries = await PlexWatchClient.shared.getMusicLibraries()
            await MainActor.run {
                isSaving = false
                if libraries.isEmpty {
                    errorMessage = "Could not connect. Check URL and token."
                }
                // If successful, the parent view will detect hasCredentials and navigate away
            }
        }
    }
}
