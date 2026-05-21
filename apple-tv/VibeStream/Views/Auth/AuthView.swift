import SwiftUI
import CoreImage.CIFilterBuiltins

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @State private var pinCode: String?
    @State private var isLoading = false
    @State private var error: String?
    @State private var servers: [PlexServer] = []
    @State private var showServerPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // App branding
                VStack(spacing: 16) {
                    Image(systemName: "play.tv")
                        .font(.system(size: 80))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text("Vibe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Sign in with your Plex account")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                // PIN display
                if let pinCode {
                    VStack(spacing: 20) {
                        // Two-column layout: PIN instructions | divider | QR code
                        HStack(spacing: 40) {
                            // Left column — existing PIN instructions
                            VStack(spacing: 16) {
                                Text("Go to")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                Text("plex.tv/link")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                                Text("and enter this code:")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                Text(pinCode)
                                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                                    .tracking(8)
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 40)
                                    .glassMaterial(in: RoundedRectangle(cornerRadius: 16))
                                    .accessibilityLabel("PIN code: \(pinCode.map(String.init).joined(separator: " "))")
                            }

                            Rectangle()
                                .fill(.secondary)
                                .frame(width: 3, height: 340)

                            // Right column — QR code
                            VStack(spacing: 16) {
                                if let qrImage = generateQRCode(from: "https://plex.tv/link") {
                                    Image(uiImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 330, height: 330)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .accessibilityLabel("QR code to open plex.tv/link")
                                }
                                Text("Scan to open")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Spinner + status (centered below columns)
                        ProgressView()
                            .padding(.top, 10)
                        Text("Waiting for authentication...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    Button("Sign In with Plex") {
                        Task { await startAuth() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .padding()

                    Button("Try Again") {
                        self.error = nil
                        self.pinCode = nil
                        Task { await startAuth() }
                    }
                }

                Spacer()
            }
            .padding(60)
            .sheet(isPresented: $showServerPicker) {
                ServerPickerView(servers: servers) { server in
                    showServerPicker = false
                    Task { await selectServer(server) }
                }
            }
        }
    }

    private func startAuth() async {
        isLoading = true
        error = nil

        let authService = PlexAuthService(clientIdentifier: appState.clientIdentifier)

        do {
            let pin = try await authService.createPin()
            pinCode = pin.code
            isLoading = false

            // Poll for token
            let token = try await authService.pollPinUntilClaimed(pinId: pin.pinId)

            // Fetch servers
            let fetchedServers = try await authService.fetchServers(token: token)
            guard !fetchedServers.isEmpty else {
                error = "No Plex servers found"
                pinCode = nil
                return
            }

            // Store token temporarily
            appState.authToken = token

            if fetchedServers.count == 1 {
                var server = fetchedServers[0]
                if let best = await authService.findBestConnection(for: server, token: token) {
                    server.activeConnectionUri = best.uri
                } else {
                    // No connection worked — use the first URI as fallback
                    server.activeConnectionUri = server.connections.first?.uri
                }
                let user = try? await authService.getUserInfo(token: token)
                appState.setAuthenticated(token: token, server: server, user: user)
            } else {
                // Test connections for each server before showing picker
                var serversWithConnections: [PlexServer] = []
                for var server in fetchedServers {
                    if let best = await authService.findBestConnection(for: server, token: token) {
                        server.activeConnectionUri = best.uri
                    } else {
                        server.activeConnectionUri = server.connections.first?.uri
                    }
                    serversWithConnections.append(server)
                }
                servers = serversWithConnections
                showServerPicker = true
            }

            pinCode = nil
        } catch {
            self.error = error.localizedDescription
            pinCode = nil
            isLoading = false
        }
    }

    private func selectServer(_ server: PlexServer) async {
        guard let token = appState.authToken else { return }
        let authService = PlexAuthService(clientIdentifier: appState.clientIdentifier)

        var selectedServer = server
        if let best = await authService.findBestConnection(for: server, token: token) {
            selectedServer.activeConnectionUri = best.uri
        }
        let user = try? await authService.getUserInfo(token: token)
        appState.setAuthenticated(token: token, server: selectedServer, user: user)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scale = 10.0
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct ServerPickerView: View {
    let servers: [PlexServer]
    let onSelect: (PlexServer) -> Void

    var body: some View {
        NavigationStack {
            List(servers, id: \.clientIdentifier) { server in
                Button {
                    onSelect(server)
                } label: {
                    HStack {
                        Image(systemName: "server.rack")
                            .font(.title2)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading) {
                            Text(server.name)
                                .font(.headline)
                            if let owner = server.sourceTitle {
                                Text("Owned by \(owner)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("\(server.connections.count) connections")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select Server")
        }
    }
}
