import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainView()
            } else {
                AuthView()
            }
        }
    }
}

struct MainView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var coordinator = NavigationCoordinator()

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            switch appState.connectionStatus {
            case .connected:
                tabView
            case .failed:
                ConnectionFailedView()
            case .checking, .reconnecting:
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(appState.connectionStatus == .reconnecting
                         ? "Reconnecting to server..."
                         : "Checking connection...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .environmentObject(coordinator)
        .fullScreenCover(isPresented: $coordinator.isPresentingPlayer, onDismiss: {
            coordinator.clearPlayerState()
        }) {
            if let key = coordinator.playerRatingKey {
                PlayerView(ratingKey: key, resumeOffset: coordinator.playerResumeOffset)
                    .environment(appState)
                    .environmentObject(coordinator)
            }
        }
        .onChange(of: coordinator.selectedTab) { oldTab, newTab in
            if case .home = newTab, !(oldTab == .home) {
                coordinator.homeRefreshTrigger &+= 1
            }
        }
        .onChange(of: appState.deepLinkAction) {
            guard let action = appState.deepLinkAction else { return }
            appState.deepLinkAction = nil
            switch action {
            case .play(let ratingKey):
                coordinator.playMedia(ratingKey: ratingKey)
            case .detail(let ratingKey):
                coordinator.selectedTab = .home
                coordinator.homePath = NavigationPath()
                coordinator.showMediaDetail(ratingKey: ratingKey)
            }
        }
        .task {
            await appState.validateConnection()
        }
    }

    // MARK: - Tab View

    @ViewBuilder
    private var tabView: some View {
        if #available(tvOS 18.0, *) {
            sidebarTabView
        } else {
            classicTabView
        }
    }

    /// tvOS 18+ — sidebar-style navigation (Apple TV+ style)
    private var userDisplayName: String {
        appState.activeUser?.displayName ?? "User"
    }

    private var tabSelectionBinding: Binding<NavigationCoordinator.Tab> {
        Binding(
            get: { coordinator.selectedTab },
            set: { newTab in
                if newTab == coordinator.selectedTab {
                    // Re-selected same tab — pop to root
                    switch newTab {
                    case .home:
                        coordinator.homePath = NavigationPath()
                    case .search:
                        coordinator.searchPath = NavigationPath()
                    case .library(let key):
                        coordinator.libraryPaths[key] = NavigationPath()
                    case .downloads, .settings:
                        break
                    }
                } else {
                    // Clear the old tab's stack so it's at root next time
                    switch coordinator.selectedTab {
                    case .home:
                        if !coordinator.homePath.isEmpty { coordinator.homePath = NavigationPath() }
                    case .search:
                        if !coordinator.searchPath.isEmpty { coordinator.searchPath = NavigationPath() }
                    case .library(let key):
                        if let path = coordinator.libraryPaths[key], !path.isEmpty {
                            coordinator.libraryPaths[key] = NavigationPath()
                        }
                    case .downloads, .settings:
                        break
                    }
                    coordinator.selectedTab = newTab
                }
            }
        )
    }

    @available(tvOS 18.0, *)
    private var sidebarTabView: some View {
        TabView(selection: tabSelectionBinding) {
            Tab("Home", systemImage: "house", value: NavigationCoordinator.Tab.home) {
                NavigationStack(path: coordinator.pathBinding(for: .home)) {
                    HomeView()
                        .navigationDestination(for: NavigationCoordinator.Route.self) { route in
                            destination(for: route)
                        }
                }
            }

            Tab("Search", systemImage: "magnifyingglass", value: NavigationCoordinator.Tab.search) {
                NavigationStack(path: coordinator.pathBinding(for: .search)) {
                    SearchView()
                        .navigationDestination(for: NavigationCoordinator.Route.self) { route in
                            destination(for: route)
                        }
                }
            }

            TabSection("Libraries") {
                ForEach(appState.libraries) { library in
                    Tab(library.title, systemImage: libraryIcon(for: library.type), value: NavigationCoordinator.Tab.library(key: library.key)) {
                        NavigationStack(path: coordinator.pathBinding(for: .library(key: library.key))) {
                            LibraryContentView(libraryKey: library.key, libraryTitle: library.title)
                                .navigationDestination(for: NavigationCoordinator.Route.self) { route in
                                    destination(for: route)
                                }
                        }
                    }
                }
            }

            Tab("Downloads", systemImage: "arrow.down.circle", value: NavigationCoordinator.Tab.downloads) {
                DownloadsView()
            }

            Tab("Settings", systemImage: "gearshape", value: NavigationCoordinator.Tab.settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }

    /// tvOS 17 — classic top tab bar
    private var classicTabView: some View {
        TabView(selection: tabSelectionBinding) {
            NavigationStack(path: coordinator.pathBinding(for: .home)) {
                HomeView()
                    .navigationDestination(for: NavigationCoordinator.Route.self) { route in
                        destination(for: route)
                    }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(NavigationCoordinator.Tab.home)

            NavigationStack(path: coordinator.pathBinding(for: .search)) {
                SearchView()
                    .navigationDestination(for: NavigationCoordinator.Route.self) { route in
                        destination(for: route)
                    }
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(NavigationCoordinator.Tab.search)

            if let firstLibrary = appState.libraries.first {
                NavigationStack(path: coordinator.pathBinding(for: .library(key: firstLibrary.key))) {
                    LibraryView()
                        .navigationDestination(for: NavigationCoordinator.Route.self) { route in
                            destination(for: route)
                        }
                }
                .tabItem { Label("Libraries", systemImage: "rectangle.stack") }
                .tag(NavigationCoordinator.Tab.library(key: firstLibrary.key))
            }

            DownloadsView()
                .tabItem { Label("Downloads", systemImage: "arrow.down.circle") }
                .tag(NavigationCoordinator.Tab.downloads)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(NavigationCoordinator.Tab.settings)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func destination(for route: NavigationCoordinator.Route) -> some View {
        switch route {
        case .mediaDetail(let ratingKey):
            MediaDetailView(ratingKey: ratingKey)
                .toolbar(.hidden, for: .tabBar)
        case .hubDetail(let hubKey, let title):
            HubDetailView(hubKey: hubKey, title: title)
                .toolbar(.hidden, for: .tabBar)
        }
    }

    private func libraryIcon(for type: String) -> String {
        switch type {
        case "movie": return "film"
        case "show": return "tv"
        case "artist": return "music.note"
        case "photo": return "photo"
        default: return "rectangle.stack"
        }
    }
}

struct ConnectionFailedView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Unable to connect to server")
                .font(.title2)
                .fontWeight(.semibold)

            if let server = appState.activeServer {
                VStack(spacing: 8) {
                    Text("Could not reach \(server.name)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Make sure your Plex server is running and reachable from this network.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }

            HStack(spacing: 16) {
                Button("Retry") {
                    Task { await appState.validateConnection() }
                }
                .buttonStyle(.borderedProminent)

                Button("Sign Out") {
                    appState.signOut()
                }
            }
        }
        .padding(40)
    }
}
