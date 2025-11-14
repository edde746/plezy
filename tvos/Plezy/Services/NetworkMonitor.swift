//
//  NetworkMonitor.swift
//  Plezy tvOS
//
//  Network reachability monitoring service
//

import Foundation
import Network
import SwiftUI
import Combine

/// Monitors network connectivity and notifies observers of status changes
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var hasBeenDisconnected: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    enum ConnectionType {
        case wifi
        case ethernet
        case cellular
        case unknown
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }

                let wasConnected = self.isConnected
                self.isConnected = path.status == .satisfied

                // Track if we've ever been disconnected
                if !self.isConnected {
                    self.hasBeenDisconnected = true
                }

                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else {
                    self.connectionType = .unknown
                }

                // Log status changes
                if wasConnected != self.isConnected {
                    if self.isConnected {
                        print("🌐 [NetworkMonitor] Connected (\(self.connectionType))")
                    } else {
                        print("❌ [NetworkMonitor] Disconnected")
                    }
                }
            }
        }

        monitor.start(queue: queue)
        print("🌐 [NetworkMonitor] Started monitoring")
    }

    nonisolated func stopMonitoring() {
        monitor.cancel()
        print("🌐 [NetworkMonitor] Stopped monitoring")
    }

    deinit {
        stopMonitoring()
    }
}

// MARK: - Offline Banner View

struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @State private var showBanner = false

    var body: some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected && showBanner {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.title3)

                    Text("No Internet Connection")
                        .font(.headline)

                    Spacer()

                    Button {
                        withAnimation {
                            showBanner = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 80)
                .padding(.vertical, 20)
                .background(Color.red.opacity(0.9))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: networkMonitor.isConnected) { _, newValue in
            if !newValue {
                withAnimation(.spring(response: 0.3)) {
                    showBanner = true
                }
            } else {
                // Connection restored, hide banner after a moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.spring(response: 0.3)) {
                        showBanner = false
                    }
                }
            }
        }
    }
}

// MARK: - Offline State View

struct OfflineStateView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("No Internet Connection")
                .font(.title)
                .foregroundColor(.white)

            Text("Please check your network connection and try again")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 100)

            Button {
                onRetry()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.title3)
            }
            .buttonStyle(ClearGlassButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Offline Banner") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            OfflineBanner()
            Spacer()
        }
    }
}

#Preview("Offline State") {
    ZStack {
        Color.black.ignoresSafeArea()
        OfflineStateView {
            print("Retry tapped")
        }
    }
}
