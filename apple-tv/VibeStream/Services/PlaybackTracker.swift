import Foundation

@Observable
final class PlaybackTracker {
    private var timer: Timer?
    private var client: PlexClient?
    private var ratingKey: String?
    private var failCount = 0
    private var skipTicks = 0

    var currentPosition: Int = 0
    var duration: Int = 0
    var isPlaying: Bool = false
    var sessionId: String?

    private let updateInterval: TimeInterval = 10
    private static let pendingProgressKey = "PlaybackTracker.pendingProgress"

    func startTracking(client: PlexClient, ratingKey: String, duration: Int) {
        self.client = client
        self.ratingKey = ratingKey
        self.duration = duration
        self.failCount = 0
        self.skipTicks = 0

        // Attempt to send any previously persisted progress that failed
        Task { await loadAndSendPendingProgress() }

        stopTracking()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.tick() }
        }
    }

    func stopTracking() {
        timer?.invalidate()
        timer = nil
    }

    func sendProgress(state: String) async {
        guard let client, let ratingKey else { return }
        do {
            try await client.updateProgress(
                ratingKey: ratingKey,
                time: currentPosition,
                state: state,
                duration: duration > 0 ? duration : nil,
                session: sessionId
            )
            failCount = 0
            skipTicks = 0

            // Clear any pending progress for this item on success
            clearPendingProgress(ratingKey: ratingKey)

            // Mark as watched at 90%
            if duration > 0, Double(currentPosition) / Double(duration) >= 0.9 {
                try? await client.markAsWatched(ratingKey: ratingKey)
            }
        } catch {
            failCount += 1
            // Exponential backoff: skip 1, 2, 4, 8, 16, 32 ticks
            skipTicks = min(1 << failCount, 32)

            // Persist the position so it isn't lost during network outages
            savePendingProgress(ratingKey: ratingKey, position: currentPosition)
        }
    }

    private func tick() async {
        if skipTicks > 0 {
            skipTicks -= 1
            return
        }
        let state = isPlaying ? "playing" : "paused"
        await sendProgress(state: state)
    }

    func dispose() {
        stopTracking()
        Task {
            await sendProgress(state: "stopped")
        }
        client = nil
        ratingKey = nil
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Pending Progress Persistence

    /// Saves an unsent playback position to UserDefaults so it survives
    /// network failures and app restarts.
    private func savePendingProgress(ratingKey: String, position: Int) {
        var pending = loadPendingProgressMap()
        pending[ratingKey] = position
        UserDefaults.standard.set(pending, forKey: Self.pendingProgressKey)
    }

    /// Removes the pending progress entry for a given item after a
    /// successful server update.
    private func clearPendingProgress(ratingKey: String) {
        var pending = loadPendingProgressMap()
        guard pending.removeValue(forKey: ratingKey) != nil else { return }
        UserDefaults.standard.set(pending, forKey: Self.pendingProgressKey)
    }

    /// Reads the pending progress dictionary from UserDefaults.
    private func loadPendingProgressMap() -> [String: Int] {
        UserDefaults.standard.dictionary(forKey: Self.pendingProgressKey) as? [String: Int] ?? [:]
    }

    /// Attempts to send all previously persisted pending progress entries
    /// to the server. Called when tracking starts (network likely available).
    private func loadAndSendPendingProgress() async {
        guard let client else { return }
        let pending = loadPendingProgressMap()
        guard !pending.isEmpty else { return }

        for (key, position) in pending {
            do {
                try await client.updateProgress(
                    ratingKey: key,
                    time: position,
                    state: "stopped",
                    duration: nil
                )
                clearPendingProgress(ratingKey: key)
            } catch {
                // Will be retried on next startTracking call
            }
        }
    }
}
