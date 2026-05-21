import SwiftUI

struct HubDetailView: View {
    let hubKey: String
    let title: String

    @Environment(AppState.self) private var appState
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var viewModel = HubDetailViewModel()

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
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 50)
                    .focusable()

                MediaGrid(
                    items: viewModel.items,
                    baseURL: appState.activeServer?.baseURL ?? "",
                    token: appState.serverToken,
                    onItemSelected: { item in
                        coordinator.showMediaDetail(ratingKey: item.ratingKey)
                    }
                )
            }
            .padding(.vertical, 40)
            .focusSection()
        }
        .overlay {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView("Loading...")
            }
            if let error = viewModel.error, viewModel.items.isEmpty {
                ErrorStateView(
                    message: error,
                    errorType: viewModel.isAuthError ? .auth : .network,
                    retryAction: {
                        if let client {
                            await viewModel.loadContent(hubKey: hubKey, client: client)
                        }
                    },
                    signOutAction: viewModel.isAuthError ? { appState.signOut() } : nil
                )
            }
        }
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color(white: 0.15), location: 0),
                    .init(color: Color(white: 0.06), location: 0.5),
                    .init(color: .black, location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .task(id: appState.connectionStatus) {
            guard appState.connectionStatus == .connected else { return }
            if let client, viewModel.items.isEmpty {
                await viewModel.loadContent(hubKey: hubKey, client: client)
            }
        }
    }
}
