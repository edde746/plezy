import Foundation

@Observable
final class SyncManager {
    private let service: WatchTogetherService
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 2
    private let maxDriftMs: Int = 2000

    var currentPosition: Int = 0
    var isPlaying: Bool = false
    var playbackRate: Double = 1.0

    var onSeek: ((Int) -> Void)?
    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    var onRateChange: ((Double) -> Void)?
    var onMediaSwitch: ((String, String, String) -> Void)?
    var onHostExited: (() -> Void)?

    init(service: WatchTogetherService) {
        self.service = service
        setupMessageHandler()
    }

    deinit {
        syncTimer?.invalidate()
    }

    private func setupMessageHandler() {
        service.onSyncMessage = { [weak self] message in
            self?.handleMessage(message)
        }
    }

    private func handleMessage(_ message: SyncMessage) {
        switch message.type {
        case .play:
            if let pos = message.positionMs {
                onSeek?(pos)
            }
            onPlay?()
        case .pause:
            onPause?()
        case .seek:
            if let pos = message.positionMs {
                onSeek?(pos)
            }
        case .positionSync:
            handlePositionSync(message)
        case .rate:
            if let rate = message.rate {
                onRateChange?(rate)
            }
        case .sessionConfig:
            handleSessionConfig(message)
        case .mediaSwitch:
            if let rk = message.ratingKey, let sid = message.serverId, let title = message.mediaTitle {
                onMediaSwitch?(rk, sid, title)
            }
        case .hostExitedPlayer:
            onHostExited?()
        case .buffering:
            // Track peer buffering state if needed
            break
        case .ping:
            if let pingId = message.pingId, let peerId = service.session?.peerId {
                Task {
                    try? await service.broadcast(.pong(id: pingId, peerId: peerId))
                }
            }
        default:
            break
        }
    }

    private func handlePositionSync(_ message: SyncMessage) {
        guard let remotePos = message.positionMs else { return }
        let drift = abs(remotePos - currentPosition)
        if drift > maxDriftMs {
            onSeek?(remotePos)
        }
        if let remotePlaying = message.isPlaying, remotePlaying != isPlaying {
            if remotePlaying { onPlay?() } else { onPause?() }
        }
    }

    private func handleSessionConfig(_ message: SyncMessage) {
        if let pos = message.positionMs {
            onSeek?(pos)
        }
        if let rate = message.rate {
            onRateChange?(rate)
        }
        // bufferingState is inverted for isPlaying in sessionConfig
        if let isPlaying = message.bufferingState {
            if !isPlaying { onPlay?() } else { onPause?() }
        }
    }

    func startSyncBroadcast() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            let pos = self.currentPosition
            let playing = self.isPlaying
            guard let peerId = self.service.session?.peerId else { return }
            Task { [weak self] in
                guard let self else { return }
                let msg = SyncMessage.positionSync(
                    position: pos,
                    isPlaying: playing,
                    peerId: peerId
                )
                try? await self.service.broadcast(msg)
            }
        }
    }

    func stopSyncBroadcast() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    func broadcastPlay(position: Int? = nil) async {
        guard let peerId = service.session?.peerId else { return }
        try? await service.broadcast(.play(position: position, peerId: peerId))
    }

    func broadcastPause() async {
        guard let peerId = service.session?.peerId else { return }
        try? await service.broadcast(.pause(peerId: peerId))
    }

    func broadcastSeek(position: Int) async {
        guard let peerId = service.session?.peerId else { return }
        try? await service.broadcast(.seek(position: position, peerId: peerId))
    }

    func broadcastMediaSwitch(ratingKey: String, serverId: String, title: String) async {
        guard let peerId = service.session?.peerId else { return }
        try? await service.broadcast(.mediaSwitch(ratingKey: ratingKey, serverId: serverId, title: title, peerId: peerId))
    }
}
