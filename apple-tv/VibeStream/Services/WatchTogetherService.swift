import Foundation

@Observable
final class WatchTogetherService: NSObject {
    private var webSocket: URLSessionWebSocketTask?
    private let relayURL = URL(string: "wss://ice.plezy.app/relay")!
    private var pingTimer: Timer?
    private var lastMessageTime: Date?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3

    private(set) var session: WatchSession?
    private(set) var isConnected = false

    var onSyncMessage: ((SyncMessage) -> Void)?
    var onPeerJoined: ((String) -> Void)?
    var onPeerLeft: ((String) -> Void)?
    var onError: ((String) -> Void)?

    deinit {
        pingTimer?.invalidate()
        webSocket?.cancel(with: .goingAway, reason: nil)
    }

    // MARK: - Connection

    func createSession(peerId: String, displayName: String) async throws -> String {
        let sessionId = generateSessionId()
        try await connect()

        let message = RelayMessage(type: .create, sessionId: sessionId, peerId: peerId)
        try await sendRelay(message)

        session = WatchSession(
            sessionId: sessionId,
            peerId: peerId,
            isHost: true,
            participants: [
                WatchSession.Participant(peerId: peerId, displayName: displayName, isHost: true)
            ],
            controlMode: .hostOnly,
            isActive: true
        )

        return sessionId
    }

    func joinSession(sessionId: String, peerId: String, displayName: String) async throws {
        try await connect()

        let message = RelayMessage(type: .join, sessionId: sessionId, peerId: peerId)
        try await sendRelay(message)

        session = WatchSession(
            sessionId: sessionId,
            peerId: peerId,
            isHost: false,
            participants: [
                WatchSession.Participant(peerId: peerId, displayName: displayName, isHost: false)
            ],
            controlMode: .hostOnly,
            isActive: true
        )
    }

    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        isConnected = false
        session?.isActive = false
        session = nil
        reconnectAttempts = 0
    }

    // MARK: - Messaging

    func broadcast(_ syncMessage: SyncMessage) async throws {
        guard let data = try? JSONEncoder().encode(syncMessage),
              let payload = String(data: data, encoding: .utf8) else { return }

        let relay = RelayMessage(type: .broadcast, payload: payload)
        try await sendRelay(relay)
    }

    func sendTo(peerId: String, syncMessage: SyncMessage) async throws {
        guard let data = try? JSONEncoder().encode(syncMessage),
              let payload = String(data: data, encoding: .utf8) else { return }

        let relay = RelayMessage(type: .sendTo, payload: payload, to: peerId)
        try await sendRelay(relay)
    }

    // MARK: - Private

    private func connect() async throws {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        webSocket = session.webSocketTask(with: relayURL)
        webSocket?.resume()
        isConnected = true
        startReceiving()
        startPingTimer()
    }

    private func startReceiving() {
        webSocket?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                self.lastMessageTime = Date()
                switch message {
                case .string(let text):
                    self.handleRelayMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleRelayMessage(text)
                    }
                @unknown default:
                    break
                }
                self.startReceiving() // Continue listening
            case .failure(let error):
                self.isConnected = false
                self.onError?("WebSocket error: \(error.localizedDescription)")
                Task { await self.attemptReconnect() }
            }
        }
    }

    private func handleRelayMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let relay = try? JSONDecoder().decode(RelayMessage.self, from: data) else { return }

        switch relay.type {
        case .created:
            // Session created successfully
            break
        case .joined:
            if let peers = relay.peers {
                for peerId in peers where peerId != session?.peerId {
                    if !(session?.participants.contains(where: { $0.peerId == peerId }) ?? false) {
                        session?.participants.append(
                            WatchSession.Participant(peerId: peerId, displayName: "Peer", isHost: false)
                        )
                    }
                }
            }
        case .peerJoined:
            if let peerId = relay.peerId {
                onPeerJoined?(peerId)
                if !(session?.participants.contains(where: { $0.peerId == peerId }) ?? false) {
                    session?.participants.append(
                        WatchSession.Participant(peerId: peerId, displayName: "Peer", isHost: false)
                    )
                }
                // Host sends session config to new peer
                if session?.isHost == true {
                    // The view model will handle sending session config
                }
            }
        case .peerLeft:
            if let peerId = relay.peerId {
                onPeerLeft?(peerId)
                session?.participants.removeAll { $0.peerId == peerId }
            }
        case .message:
            if let payload = relay.payload,
               let payloadData = payload.data(using: .utf8),
               let syncMessage = try? JSONDecoder().decode(SyncMessage.self, from: payloadData) {
                handleSyncMessage(syncMessage, from: relay.from)
            }
        case .error:
            onError?(relay.message ?? "Unknown relay error")
        case .pong:
            // Keepalive acknowledged
            break
        default:
            break
        }
    }

    private func handleSyncMessage(_ message: SyncMessage, from peerId: String?) {
        // Update participant info from join messages
        if message.type == .join, let name = message.displayName, let pid = message.peerId {
            if let index = session?.participants.firstIndex(where: { $0.peerId == pid }) {
                session?.participants[index] = WatchSession.Participant(
                    peerId: pid, displayName: name, isHost: message.isHost ?? false
                )
            } else {
                session?.participants.append(
                    WatchSession.Participant(peerId: pid, displayName: name, isHost: message.isHost ?? false)
                )
            }
        }

        onSyncMessage?(message)
    }

    private func sendRelay(_ message: RelayMessage) async throws {
        guard let data = try? JSONEncoder().encode(message),
              let text = String(data: data, encoding: .utf8) else { return }
        try await webSocket?.send(.string(text))
    }

    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { [weak self] in
                guard let self else { return }
                let ping = RelayMessage(type: .ping)
                try? await self.sendRelay(ping)
            }

            // Check for timeout
            if let lastMessage = self.lastMessageTime,
               Date().timeIntervalSince(lastMessage) > 30 {
                self.isConnected = false
                Task { [weak self] in await self?.attemptReconnect() }
            }
        }
    }

    private func attemptReconnect() async {
        guard reconnectAttempts < maxReconnectAttempts else {
            onError?("Failed to reconnect after \(maxReconnectAttempts) attempts")
            disconnect()
            return
        }

        reconnectAttempts += 1
        let delay = Double(reconnectAttempts) * 2 // 2, 4, 6 seconds
        try? await Task.sleep(for: .seconds(delay))

        guard let session else { return }
        do {
            try await connect()
            if session.isHost {
                let relay = RelayMessage(type: .create, sessionId: session.sessionId, peerId: session.peerId)
                try await sendRelay(relay)
            } else {
                let relay = RelayMessage(type: .join, sessionId: session.sessionId, peerId: session.peerId)
                try await sendRelay(relay)
            }
            reconnectAttempts = 0
        } catch {
            await attemptReconnect()
        }
    }

    private func generateSessionId() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).compactMap { _ in chars.randomElement() })
    }
}

extension WatchTogetherService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        lastMessageTime = Date()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
    }
}
