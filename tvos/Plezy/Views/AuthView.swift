//
//  AuthView.swift
//  Plezy tvOS
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
            // Background
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 50) {
                // Logo and title
                VStack(spacing: 20) {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white)

                    Text("Plezy")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)

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
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth && pin != nil {
                // User authenticated, show server selection
                authService.cancelPinPolling()
                Task {
                    await authService.loadServers()
                    showServerSelection = true
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

            // PIN code display
            HStack(spacing: 15) {
                ForEach(Array(pin.code.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 90)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                }
            }

            // URL
            VStack(spacing: 10) {
                Text("plex.tv/link")
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange, lineWidth: 3)
                    )
            }

            // Waiting indicator
            HStack(spacing: 15) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.orange)

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
