//
//  MainTabView.swift
//  Beacon tvOS
//
//  Main navigation with tabs
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: PlexAuthService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                .onAppear {
                    print("📱 [MainTabView] Home tab appeared")
                }

            TVShowsLibraryView()
                .tabItem {
                    Label("TV Shows", systemImage: "tv.fill")
                }
                .tag(1)

            MoviesLibraryView()
                .tabItem {
                    Label("Movies", systemImage: "film.fill")
                }
                .tag(2)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .tabViewStyle(.automatic)
        .onAppear {
            print("📱 [MainTabView] MainTabView appeared")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(PlexAuthService())
        .environmentObject(SettingsService())
        .environmentObject(StorageService())
}
