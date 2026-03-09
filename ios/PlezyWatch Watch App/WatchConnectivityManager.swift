import Foundation
import WatchConnectivity

enum PlaybackCommand: String {
    case play
    case pause
    case next
    case previous
    case transferToWatch
    case volumeUp
    case volumeDown
}

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // Published state for remote control (when phone is playing)
    @Published var isReachable = false
    @Published var isPlaying = false
    @Published var hasTrackInfo = false
    @Published var trackTitle = ""
    @Published var trackArtist: String?
    @Published var albumArtData: Data?
    @Published var canGoNext = true
    @Published var canGoPrevious = true

    // Remote playback position/duration (sent from phone)
    @Published var remotePosition: Double = 0
    @Published var remoteDuration: Double = 0

    // App mode state machine
    @Published var appMode: AppMode = .idle

    // Legacy flags kept for compatibility
    @Published var hasLocalQueue = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    // Debug info
    @Published var debugInfo: String = "Initializing..."

    private var session: WCSession?
    private var activationRetryCount = 0
    private let maxRetries = 3

    // Reference to the audio player
    var audioPlayer: WatchAudioPlayer {
        WatchAudioPlayer.shared
    }

    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            debugInfo = "Session activating..."
        } else {
            debugInfo = "WCSession not supported"
        }
    }

    /// Ensure session is activated
    private func ensureSessionActive() {
        guard let session = session else { return }
        if session.activationState != .activated {
            session.activate()
        }
    }

    func sendCommand(_ command: PlaybackCommand) {
        guard let session = session else { return }
        ensureSessionActive()
        guard session.isReachable else { return }

        let message: [String: Any] = ["command": command.rawValue]
        session.sendMessage(message, replyHandler: nil) { error in
            // Ignore errors for simple commands
        }
    }

    /// Request Plex credentials from the phone
    func requestCredentials() {
        guard let session = session, session.isReachable else { return }
        guard !PlexWatchClient.shared.hasCredentials else { return }

        let message: [String: Any] = ["command": "requestCredentials"]
        session.sendMessage(message, replyHandler: { [weak self] response in
            if let serverUrl = response["serverUrl"] as? String,
               let token = response["token"] as? String {
                PlexWatchClient.shared.saveCredentials(serverUrl: serverUrl, token: token)
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
        }) { error in
            // Silently fail — user can still use manual setup
        }
    }

    func requestPlayPhoneQueue() {
        guard let session = session else {
            DispatchQueue.main.async {
                self.errorMessage = "No watch session"
                self.debugInfo = "No WCSession"
            }
            return
        }

        // Ensure session is active
        ensureSessionActive()

        // Update debug info with session state
        let state = "Act: \(session.activationState.rawValue), Reach: \(session.isReachable)"
        DispatchQueue.main.async {
            self.debugInfo = state
            self.isLoading = true
            self.errorMessage = nil
        }

        // Check reachability
        guard session.isReachable else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Phone not reachable"
                self.debugInfo = "Not reachable (act: \(session.activationState.rawValue))"
            }
            return
        }

        // Send request to phone to transfer queue
        let message: [String: Any] = ["command": "transferToWatch"]

        session.sendMessage(message, replyHandler: { [weak self] response in
            DispatchQueue.main.async {
                self?.isLoading = false
            }

            // Check for play queue reference first (preferred method)
            var playQueueRef: PlayQueueReference?
            if let refData = response["playQueueRef"] as? [String: Any] {
                playQueueRef = PlayQueueReference(from: refData)
                DispatchQueue.main.async {
                    self?.debugInfo = "Got queue ref: \(playQueueRef?.playQueueId ?? 0)"
                }
            }

            // Phone will send queue data in response (either with or without ref)
            if let queueData = response["queue"] as? [[String: Any]] {
                DispatchQueue.main.async {
                    self?.debugInfo = "Got \(queueData.count) items" + (playQueueRef != nil ? " + ref" : "")
                }
                self?.handleQueueTransfer(queueData, startIndex: response["currentIndex"] as? Int ?? 0, playQueueRef: playQueueRef)
            } else if let error = response["error"] as? String {
                DispatchQueue.main.async {
                    self?.errorMessage = error
                    self?.debugInfo = "Phone error: \(error)"
                }
            } else {
                DispatchQueue.main.async {
                    self?.errorMessage = "No content"
                    self?.debugInfo = "Empty response from phone"
                }
            }
        }) { [weak self] error in
            let errorDesc = error.localizedDescription
            DispatchQueue.main.async {
                self?.isLoading = false

                // Provide more specific error messages
                if errorDesc.contains("not reachable") || errorDesc.contains("payload") {
                    self?.errorMessage = "Phone app not responding"
                    self?.debugInfo = "Delivery failed - restart phone app"
                } else {
                    self?.errorMessage = "Connection failed"
                    self?.debugInfo = "Error: \(errorDesc)"
                }
            }
        }
    }

    private func handleQueueTransfer(_ queueData: [[String: Any]], startIndex: Int, playQueueRef: PlayQueueReference? = nil) {
        // Persist Plex credentials from the queue transfer for independent Watch operation
        if let ref = playQueueRef {
            PlexWatchClient.shared.saveCredentials(serverUrl: ref.plexServerUrl, token: ref.plexToken)
        } else if let first = queueData.first,
                  let streamUrl = first["streamUrl"] as? String,
                  let token = first["plexToken"] as? String,
                  let url = URL(string: streamUrl),
                  let scheme = url.scheme, let host = url.host {
            let port = url.port.map { ":\($0)" } ?? ""
            PlexWatchClient.shared.saveCredentials(serverUrl: "\(scheme)://\(host)\(port)", token: token)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let items = queueData.compactMap { QueueItem(from: $0) }

            if !items.isEmpty {
                self.hasLocalQueue = true
                self.appMode = .localPlaying
                self.errorMessage = nil
                self.debugInfo = "Playing \(items.count) items" + (playQueueRef.map { " (ref: \($0.playQueueId))" } ?? "")
                self.audioPlayer.loadQueue(items, startIndex: startIndex, queueRef: playQueueRef)
            } else if playQueueRef != nil {
                // Have a reference but no items - try to fetch from Plex
                self.debugInfo = "Fetching from Plex..."
                self.isLoading = true
                Task {
                    // Store the reference first
                    await MainActor.run {
                        self.audioPlayer.playQueueRef = playQueueRef
                    }
                    let success = await self.audioPlayer.refreshQueueFromPlex()
                    await MainActor.run {
                        self.isLoading = false
                        if success {
                            self.hasLocalQueue = true
                            self.appMode = .localPlaying
                            self.errorMessage = nil
                            self.debugInfo = "Playing from Plex"
                            self.audioPlayer.play()
                        } else {
                            self.errorMessage = "Failed to load from Plex"
                            self.debugInfo = "Plex fetch failed"
                        }
                    }
                }
            } else {
                self.errorMessage = "No playable items"
                self.debugInfo = "Empty queue"
            }
        }
    }

    private func updateState(from message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Check for play queue reference
            var playQueueRef: PlayQueueReference?
            if let refData = message["playQueueRef"] as? [String: Any] {
                playQueueRef = PlayQueueReference(from: refData)
            }

            // Handle queue transfer
            if let queueData = message["queue"] as? [[String: Any]] {
                self.handleQueueTransfer(queueData, startIndex: message["currentIndex"] as? Int ?? 0, playQueueRef: playQueueRef)
                return
            }

            if let playing = message["isPlaying"] as? Bool {
                self.isPlaying = playing
            }

            if let title = message["title"] as? String {
                self.trackTitle = title
                self.hasTrackInfo = !title.isEmpty
            }

            self.trackArtist = message["artist"] as? String

            if let artData = message["albumArt"] as? Data {
                self.albumArtData = artData
            }

            if let canNext = message["canGoNext"] as? Bool {
                self.canGoNext = canNext
            }

            if let canPrev = message["canGoPrevious"] as? Bool {
                self.canGoPrevious = canPrev
            }

            // Remote position/duration
            if let position = message["position"] as? Double {
                self.remotePosition = position
            }
            if let duration = message["duration"] as? Double {
                self.remoteDuration = duration
            }

            // Handle clear state message
            if let clear = message["clearState"] as? Bool, clear {
                self.isPlaying = false
                self.hasTrackInfo = false
                self.trackTitle = ""
                self.trackArtist = nil
                self.albumArtData = nil
                self.remotePosition = 0
                self.remoteDuration = 0
                // Return to idle if we were remote controlling
                if self.appMode == .remoteControl {
                    self.appMode = .idle
                }
            }

            // Auto-switch to remote control mode if phone is playing and we're idle
            // Don't interrupt local playback or browsing
            if self.appMode == .idle && (self.isPlaying || self.hasTrackInfo) {
                self.appMode = .remoteControl
            }
            // If we're in local modes, don't switch — user chose local playback
        }
    }

    // MARK: - App Mode Management

    /// Start local playback mode (called when browse/search triggers playback)
    func startLocalPlayback() {
        hasLocalQueue = true
        appMode = .localPlaying
        errorMessage = nil
    }

    /// Dismiss the player UI but keep audio playing
    func dismissToBackground() {
        if audioPlayer.hasQueue {
            appMode = .localBrowsing
        } else {
            appMode = .idle
        }
    }

    /// Return to the player from browse mode
    func returnToPlayer() {
        if audioPlayer.hasQueue {
            appMode = .localPlaying
        }
    }

    /// Stop local playback and clear queue entirely
    func stopLocalPlayback() {
        audioPlayer.stop()
        hasLocalQueue = false
        appMode = .idle
        errorMessage = nil
        debugInfo = "Stopped"
    }

    // Retry activation if needed
    func retryActivation() {
        guard activationRetryCount < maxRetries else {
            DispatchQueue.main.async {
                self.debugInfo = "Activation failed after \(self.maxRetries) retries"
            }
            return
        }

        activationRetryCount += 1
        session?.activate()

        DispatchQueue.main.async {
            self.debugInfo = "Retrying activation (\(self.activationRetryCount)/\(self.maxRetries))..."
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable

            if let error = error {
                self.debugInfo = "Activation error: \(error.localizedDescription)"
                // Try to retry
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.retryActivation()
                }
                return
            }

            switch activationState {
            case .activated:
                self.activationRetryCount = 0 // Reset on success
                self.debugInfo = session.isReachable ? "Connected" : "Activated, not reachable"
                if session.isReachable {
                    self.requestCredentials()
                }
            case .inactive:
                self.debugInfo = "Inactive"
            case .notActivated:
                self.debugInfo = "Not activated"
            @unknown default:
                self.debugInfo = "Unknown"
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.debugInfo = session.isReachable ? "Connected" : "Not reachable"
            if session.isReachable {
                self.requestCredentials()
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        updateState(from: message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        updateState(from: message)
        replyHandler(["received": true])
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        updateState(from: applicationContext)
    }
}
