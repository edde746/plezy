//
//  MainTabView.swift
//  Plezy tvOS
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

            LibrariesView()
                .tabItem {
                    Label("Libraries", systemImage: "folder.fill")
                }
                .tag(1)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
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
