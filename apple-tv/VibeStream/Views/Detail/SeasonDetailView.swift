import SwiftUI

struct SeasonDetailView: View {
    let showTitle: String
    let seasonRatingKey: String

    @Environment(AppState.self) private var appState
    @State private var episodes: [PlexMetadata] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showPlayer = false
    @State private var playRatingKey: String?
    @State private var resumeOffset: Int?

    private var client: PlexClient? {
        guard let server = appState.activeServer, let token = appState.authToken else { return nil }
        return PlexClient(
            baseURL: server.baseURL,
            token: server.accessToken ?? token,
            clientIdentifier: appState.clientIdentifier,
            serverId: server.clientIdentifier,
            serverName: server.name
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if isLoading {
                    ProgressView("Loading episodes...")
                        .padding(.top, 100)
                } else if let error {
                    ErrorStateView(
                        message: error,
                        retryAction: {
                            await loadEpisodes()
                        }
                    )
                    .padding(.top, 100)
                } else {
                    ForEach(episodes) { episode in
                        Button {
                            playRatingKey = episode.ratingKey
                            resumeOffset = episode.viewOffset
                            showPlayer = true
                        } label: {
                            HStack(spacing: 16) {
                                PlexImage(
                                    path: episode.thumb,
                                    token: appState.serverToken,
                                    baseURL: appState.activeServer?.baseURL ?? "",
                                    width: 250,
                                    aspectRatio: 16/9
                                )

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        if let index = episode.index {
                                            Text("Episode \(index)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Text(episode.title)
                                        .font(.headline)
                                        .lineLimit(1)

                                    if let summary = episode.summary {
                                        Text(summary)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(3)
                                    }

                                    HStack(spacing: 12) {
                                        if let duration = episode.durationFormatted {
                                            Text(duration)
                                        }
                                        if let date = episode.originallyAvailableAt {
                                            Text(date)
                                        }
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)

                                    if let progress = episode.watchProgress {
                                        ProgressBar(progress: progress)
                                            .frame(height: 3)
                                            .frame(maxWidth: 250)
                                    }
                                }

                                Spacer()

                                if episode.isWatched {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.card)
                        .padding(.horizontal, 50)
                    }
                }
            }
            .padding(.vertical, 30)
        }
        .navigationTitle(showTitle)
        .fullScreenCover(isPresented: $showPlayer) {
            if let key = playRatingKey {
                PlayerView(ratingKey: key, resumeOffset: resumeOffset)
            }
        }
        .task(id: appState.connectionStatus) {
            guard appState.connectionStatus == .connected else { return }
            await loadEpisodes()
        }
    }

    private func loadEpisodes() async {
        isLoading = true
        error = nil
        if let client {
            do {
                episodes = try await client.getChildren(ratingKey: seasonRatingKey)
            } catch is URLError {
                error = "Could not connect to server."
            } catch {
                self.error = error.localizedDescription
            }
        }
        isLoading = false
    }
}
