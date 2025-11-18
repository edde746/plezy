//
//  AuthView.swift
//  Beacon tvOS
//
//  Authentication screen with PIN flow
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authService: PlexAuthService
    @State private var pin: PlexPin?
    @State private var showServerSelection = false

    var body: some View {
        ZStack {
            // Enhanced background with beacon colors
            LinearGradient(
                colors: [
                    Color.beaconBackground,
                    Color.beaconSurface,
                    Color.beaconBlue.opacity(0.08),
                    Color.beaconPurple.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 50) {
                // Logo and title
                VStack(spacing: 20) {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.beaconBlue, Color.beaconPurple, Color.beaconMagenta],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.beaconPurple.opacity(0.5), radius: 20, x: 0, y: 10)

                    Text("Plezy")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.beaconTextSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("for Apple TV")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                }

                if let pin = pin {
                    // Show PIN and instructions
                    PINDisplayView(pin: pin)
                } else if authService.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Connecting to Plex...")
                        .font(.title3)
                        .foregroundColor(.gray)
                } else {
                    // Start authentication button
                    Button {
                        Task {
                            await startAuthentication()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Sign in with Plex")
                        }
                        .font(.title2)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                    }
                    .buttonStyle(CardButtonStyle())
                }

                if let error = authService.error {
                    Text(error)
                        .font(.headline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding(80)
        }
        .sheet(isPresented: $showServerSelection) {
            ServerSelectionView()
        }
        .onChange(of: authService.isAuthenticated) { oldValue, isAuth in
            print("⚡️ [AuthView] onChange FIRED! oldValue: \(oldValue), newValue: \(isAuth), pin: \(pin != nil ? "exists" : "nil")")
            if isAuth && pin != nil {
                print("🟢 [AuthView] Conditions met, starting server load...")
                // User authenticated, load servers
                authService.cancelPinPolling()
                Task {
                    print("🟢 [AuthView] Authentication successful, loading servers...")
                    await authService.loadServers()
                    print("🟢 [AuthView] Loaded \(authService.availableServers.count) servers")

                    // If only one server, auto-select it
                    if authService.availableServers.count == 1, let server = authService.availableServers.first {
                        print("🟢 [AuthView] Only one server found, auto-selecting: \(server.name)")
                        await authService.selectServer(server)
                    } else if authService.availableServers.count > 1 {
                        // Multiple servers, show selection screen
                        print("🟢 [AuthView] Multiple servers found, showing selection screen")
                        showServerSelection = true
                    } else {
                        print("🔴 [AuthView] No servers found")
                    }
                }
            }
        }
    }

    private func startAuthentication() async {
        guard let pin = await authService.startPinAuth() else {
            return
        }

        self.pin = pin

        // Start polling for authentication
        authService.startPinPolling(pinId: pin.id) { success in
            if success {
                print("✅ Authentication successful")
            }
        }
    }
}

struct PINDisplayView: View {
    let pin: PlexPin

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Text("Sign in on your device")
                    .font(.title2)
                    .foregroundColor(.white)

                Text("Visit the URL below and enter this code:")
                    .font(.title3)
                    .foregroundColor(.gray)
            }

            // PIN code display with Liquid Glass
            HStack(spacing: 15) {
                ForEach(Array(pin.code.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 90)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge)
                                    .fill(.regularMaterial)
                                    .opacity(0.5)

                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.beaconBlue.opacity(0.15),
                                                Color.beaconPurple.opacity(0.12)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .blendMode(.plusLighter)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.beaconBlue.opacity(0.6),
                                            Color.beaconPurple.opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.beaconPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }

            // URL with enhanced beacon styling
            VStack(spacing: 10) {
                Text("plex.tv/link")
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                .fill(.ultraThinMaterial)
                                .opacity(0.4)

                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.beaconOrange.opacity(0.1),
                                            Color.beaconMagenta.opacity(0.08)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .blendMode(.plusLighter)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.beaconOrange, Color.beaconMagenta],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: Color.beaconOrange.opacity(0.4), radius: 15, x: 0, y: 5)
            }

            // Waiting indicator with beacon colors
            HStack(spacing: 15) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color.beaconPurple)

                Text("Waiting for authentication...")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .padding(.top, 20)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(PlexAuthService())
        .environmentObject(SettingsService())
        .environmentObject(StorageService())
}
