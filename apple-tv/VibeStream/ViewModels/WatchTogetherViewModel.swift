import Foundation
import Observation

@Observable
final class WatchTogetherViewModel {
    let service = WatchTogetherService()
    private(set) var syncManager: SyncManager?
    private(set) var error: String?
    private(set) var sessionCode: String?
    var joinCode = ""

    var isInSession: Bool { service.session?.isActive ?? false }
    var isHost: Bool { service.session?.isHost ?? false }
    var participants: [WatchSession.Participant] { service.session?.participants ?? [] }

    init() {
        service.onError = { [weak self] msg in
            self?.error = msg
        }
    }

    func createSession(displayName: String, peerId: String) async {
        error = nil
        do {
            let code = try await service.createSession(peerId: peerId, displayName: displayName)
            sessionCode = code
            syncManager = SyncManager(service: service)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func joinSession(displayName: String, peerId: String) async {
        error = nil
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else {
            error = "Enter a session code"
            return
        }

        do {
            try await service.joinSession(sessionId: code, peerId: peerId, displayName: displayName)
            sessionCode = code
            syncManager = SyncManager(service: service)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func leaveSession() {
        syncManager?.stopSyncBroadcast()
        syncManager = nil
        service.disconnect()
        sessionCode = nil
        joinCode = ""
    }
}
