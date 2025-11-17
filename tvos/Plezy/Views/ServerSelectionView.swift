//
//  ServerSelectionView.swift
//  Plezy tvOS
//
//  Server selection screen
//

import SwiftUI

struct ServerSelectionView: View {
    @EnvironmentObject var authService: PlexAuthService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                // Header
                Text("Select Your Plex Server")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                if authService.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text(authService.availableServers.isEmpty ? "Finding servers..." : "Connecting to server...")
                        .font(.title3)
                        .foregroundColor(.gray)
                } else if authService.availableServers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "externaldrive.fill.badge.xmark")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)

                        Text("No servers found")
                            .font(.title2)
                            .foregroundColor(.gray)

                        Button("Retry") {
                            Task {
                                await authService.loadServers()
                            }
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 400, maximum: 600), spacing: 30)
                        ], spacing: 30) {
                            ForEach(authService.availableServers) { server in
                                ServerCard(server: server) {
                                    print("🔵 [ServerSelection] Button clicked for server: \(server.name)")
                                    Task {
                                        print("🔵 [ServerSelection] Starting selectServer for: \(server.name)")
                                        await authService.selectServer(server)
                                        print("🔵 [ServerSelection] Finished selectServer. Selected server: \(authService.selectedServer?.name ?? "nil")")
                                        // Only dismiss if server was successfully selected
                                        if authService.selectedServer != nil {
                                            print("🔵 [ServerSelection] Server selected successfully, dismissing sheet")
                                            dismiss()
                                        } else {
                                            print("🔴 [ServerSelection] Server selection failed, staying on sheet")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(40)
                    }
                }

                if let error = authService.error {
                    Text(error)
                        .font(.headline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
    }
}

struct ServerCard: View {
    let server: PlexServer
    let action: () -> Void
    @State private var isFocused = false

    var body: some View {
        Button {
            print("🔵 [ServerCard] Button tapped for: \(server.name)")
            action()
        } label: {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "server.rack")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Spacer()

                    if server.isOwned {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                }

                Text(server.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                        Text("Version \(server.productVersion)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.gray)
                        Text("\(server.connections.count) connection\(server.connections.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // Show connection types
                    HStack(spacing: 8) {
                        if server.connections.contains(where: { $0.local }) {
                            ConnectionBadge(text: "Local", color: .green)
                        }
                        if server.connections.contains(where: { !$0.local && !$0.relay }) {
                            ConnectionBadge(text: "Remote", color: .blue)
                        }
                        if server.connections.contains(where: { $0.relay }) {
                            ConnectionBadge(text: "Relay", color: .orange)
                        }
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(isFocused ? 0.15 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isFocused ? Color.orange : Color.white.opacity(0.2), lineWidth: isFocused ? 4 : 2)
            )
        }
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
        .onFocusChange(true) { focused in
            isFocused = focused
        }
    }
}

struct ConnectionBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.8))
            )
    }
}

#Preview {
    ServerSelectionView()
        .environmentObject(PlexAuthService())
}
