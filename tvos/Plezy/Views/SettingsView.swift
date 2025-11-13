//
//  SettingsView.swift
//  Plezy tvOS
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: PlexAuthService
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var storageService: StorageService
    @State private var showLogoutConfirmation = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    // Header
                    Text("Settings")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 40)

                    // Server Info
                    SettingsSection(title: "Server") {
                        if let server = authService.selectedServer {
                            SettingsRow(
                                icon: "server.rack",
                                title: server.name,
                                subtitle: "Connected"
                            )
                        }
                    }

                    // User Info
                    SettingsSection(title: "Account") {
                        if let user = authService.currentUser {
                            SettingsRow(
                                icon: "person.fill",
                                title: user.username,
                                subtitle: user.email ?? ""
                            )
                        }
                    }

                    // Playback Settings
                    SettingsSection(title: "Playback") {
                        SettingsToggle(
                            icon: "play.circle",
                            title: "Auto-play next episode",
                            isOn: $settingsService.autoPlayNext
                        )

                        SettingsToggle(
                            icon: "forward.fill",
                            title: "Skip intros",
                            isOn: $settingsService.skipIntroEnabled
                        )

                        SettingsToggle(
                            icon: "forward.end.fill",
                            title: "Skip credits",
                            isOn: $settingsService.skipCreditsEnabled
                        )
                    }

                    // Subtitle Settings
                    SettingsSection(title: "Subtitles") {
                        SettingsToggle(
                            icon: "captions.bubble",
                            title: "Auto-select subtitles",
                            isOn: $settingsService.autoSelectSubtitles
                        )

                        HStack {
                            Image(systemName: "textformat.size")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Subtitle size")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Slider(value: $settingsService.subtitleSize, in: 0.5...2.0, step: 0.1)
                                    .frame(width: 400)
                            }
                        }
                    }

                    // Appearance
                    SettingsSection(title: "Appearance") {
                        HStack {
                            Image(systemName: "moon.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 40)

                            Text("Theme")
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            Picker("Theme", selection: $settingsService.theme) {
                                ForEach(SettingsService.ThemeMode.allCases, id: \.self) { theme in
                                    Text(theme.displayName).tag(theme)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 400)
                        }
                    }

                    // App Info
                    SettingsSection(title: "About") {
                        SettingsRow(
                            icon: "info.circle",
                            title: "Version",
                            subtitle: PlexAPIClient.plexVersion
                        )

                        SettingsRow(
                            icon: "tv.fill",
                            title: "Platform",
                            subtitle: PlexAPIClient.plexPlatform
                        )
                    }

                    // Logout
                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title2)

                            Text("Sign Out")
                                .font(.headline)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .buttonStyle(.card)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 40)
            }
        }
        .alert("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .textCase(.uppercase)

            VStack(spacing: 15) {
                content
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
    }
}

struct SettingsToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 40)

            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PlexAuthService())
        .environmentObject(SettingsService())
        .environmentObject(StorageService())
}
