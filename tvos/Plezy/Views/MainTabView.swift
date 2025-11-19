//
//  MainTabView.swift
//  Beacon tvOS
//
//  Main navigation with tabs coordinated via TabCoordinator
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: PlexAuthService
    @StateObject private var tabCoordinator = TabCoordinator.shared

    var body: some View {
        TabView(selection: $tabCoordinator.selectedTab) {
            HomeView()
                .tabItem {
                    Label(TabSelection.home.rawValue, systemImage: TabSelection.home.systemImage)
                }
                .tag(TabSelection.home)
                .onAppear {
                    print("📱 [MainTabView] Home tab appeared")
                }

            MoviesLibraryView()
                .tabItem {
                    Label(TabSelection.movies.rawValue, systemImage: TabSelection.movies.systemImage)
                }
                .tag(TabSelection.movies)

            TVShowsLibraryView()
                .tabItem {
                    Label(TabSelection.tvShows.rawValue, systemImage: TabSelection.tvShows.systemImage)
                }
                .tag(TabSelection.tvShows)

            SearchView()
                .tabItem {
                    Label(TabSelection.search.rawValue, systemImage: TabSelection.search.systemImage)
                }
                .tag(TabSelection.search)

            SettingsView()
                .tabItem {
                    Label(TabSelection.settings.rawValue, systemImage: TabSelection.settings.systemImage)
                }
                .tag(TabSelection.settings)
        }
        .tabViewStyle(.automatic)
        .onAppear {
            print("📱 [MainTabView] MainTabView appeared")
        }
        .environmentObject(tabCoordinator)
    }
}

#Preview {
    MainTabView()
        .environmentObject(PlexAuthService())
        .environmentObject(SettingsService())
        .environmentObject(StorageService())
}
