import Foundation
import WatchConnectivity

/// Finishes a continuation exactly once, whichever of a reply, an error or a
/// timeout gets there first. WCSession's reply queue and the timer are different
/// threads, so the check and the resume have to be one step.
private final class ResumeOnce<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<Value?, Never>?

  init(_ continuation: CheckedContinuation<Value?, Never>) {
    self.continuation = continuation
  }

  /// Returns whether this call was the one that finished it.
  @discardableResult
  func finish(_ value: Value?) -> Bool {
    lock.lock()
    let pending = continuation
    continuation = nil
    lock.unlock()
    pending?.resume(returning: value)
    return pending != nil
  }
}

class WatchConnectivityManager: NSObject, ObservableObject {
  static let shared = WatchConnectivityManager()

  @Published var isReachable = false

  // App mode state machine
  @Published var appMode: AppMode = .idle

  @Published var credentialsHint: String?

  private var credentialsRetryTask: Task<Void, Never>?

  private var session: WCSession?
  private var activationRetryCount = 0
  private let maxRetries = 3

  // Reference to the audio player
  var audioPlayer: WatchAudioPlayer {
    WatchAudioPlayer.shared
  }

  override init() {
    super.init()
    WatchInstrument.log(.connectivity, "WatchConnectivityManager init")

    if WCSession.isSupported() {
      session = WCSession.default
      session?.delegate = self
      session?.activate()
    }
  }

  /// Ensure session is activated
  private func ensureSessionActive() {
    guard let session = session else { return }
    if session.activationState != .activated {
      session.activate()
    }
  }

  /// Request Plex credentials from the phone (initial setup or manual refresh).
  ///
  /// [force] is the owner asking, which is the only thing that lifts a
  /// sign-out on this watch.
  func requestCredentials(force: Bool = false) {
    guard let session = session else { return }
    let client = PlexWatchClient.shared
    if force {
      client.allowPhoneCredentials()
    } else if client.isSignedOutOnWatch || client.hasCredentials {
      credentialsHint = nil
      return
    }

    ensureSessionActive()

    if !session.receivedApplicationContext.isEmpty {
      updateState(from: session.receivedApplicationContext)
    }

    guard session.isReachable else {
      if !client.hasCredentials { credentialsHint = "Open Plezy on your iPhone" }
      return
    }

    credentialsHint = "Waiting for Plezy on iPhone…"

    Task { @MainActor in
      let creds = await Self.request(
        ["command": "requestCredentials"],
        label: "credentials",
        timeoutSeconds: 5,
        session: session
      ) { response -> (serverUrl: String, token: String, machineIdentifier: String?, fallbackUrls: [String]?)? in
        guard let serverUrl = response["serverUrl"] as? String,
          let token = response["token"] as? String
        else { return nil }
        return (serverUrl, token, response["machineIdentifier"] as? String, Self.fallbackUrls(response))
      }

      if let creds {
        self.applyPlexCredentials(
          serverUrl: creds.serverUrl,
          token: creds.token,
          machineIdentifier: creds.machineIdentifier,
          fallbackUrls: creds.fallbackUrls
        )
        self.credentialsHint = nil
      } else if !PlexWatchClient.shared.hasCredentials {
        self.credentialsHint = "Open Plezy on your iPhone"
      }
    }
  }

  /// Ask the iPhone to resolve a Plex stream URL (uses phone's optimized server endpoint + transcode).
  func requestStreamUrl(ratingKey: String) async -> String? {
    guard let session = session else { return nil }
    ensureSessionActive()
    guard session.isReachable else { return nil }

    // Rating keys are per server, so the phone has to be told which one.
    var message: [String: Any] = ["command": "requestStreamUrl", "ratingKey": ratingKey]
    message["machineIdentifier"] = PlexWatchClient.shared.credentials?.machineIdentifier

    return await Self.request(message, label: "stream URL", timeoutSeconds: 3, session: session) { response in
      guard let streamUrl = response["streamUrl"] as? String, !streamUrl.isEmpty else { return nil }
      return streamUrl
    }
  }

  /// Send [message] and read the reply, or give up after [timeoutSeconds]:
  /// `sendMessage` can stay silent well past the point anyone is waiting.
  private static func request<Value>(
    _ message: [String: Any],
    label: String,
    timeoutSeconds: UInt64,
    session: WCSession,
    parse: @escaping ([String: Any]) -> Value?
  ) async -> Value? {
    await withCheckedContinuation { continuation in
      let once = ResumeOnce<Value>(continuation)
      session.sendMessage(
        message,
        replyHandler: { response in
          once.finish(parse(response))
        },
        errorHandler: { error in
          WatchInstrument.connectivity("\(label) request failed: \(error.localizedDescription)")
          once.finish(nil)
        })
      Task {
        try? await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
        if once.finish(nil) {
          WatchInstrument.connectivity("\(label) request timed out after \(timeoutSeconds)s")
        }
      }
    }
  }

  func startCredentialsRetryLoop() {
    guard credentialsRetryTask == nil else { return }
    credentialsRetryTask = Task { @MainActor in
      while !Task.isCancelled {
        let client = PlexWatchClient.shared
        if client.hasCredentials || client.isSignedOutOnWatch {
          credentialsHint = nil
          break
        }
        requestCredentials()
        try? await Task.sleep(nanoseconds: 3_000_000_000)
      }
      credentialsRetryTask = nil
    }
  }

  func stopCredentialsRetryLoop() {
    credentialsRetryTask?.cancel()
    credentialsRetryTask = nil
  }

  /// The phone sends the server's remote addresses newline-separated.
  static func fallbackUrls(_ message: [String: Any]) -> [String]? {
    guard let joined = message["fallbackUrls"] as? String else { return nil }
    let urls = joined.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
    return urls.isEmpty ? nil : urls
  }

  private func applyPlexCredentials(
    serverUrl: String,
    token: String,
    machineIdentifier: String?,
    fallbackUrls: [String]?
  ) {
    let client = PlexWatchClient.shared
    guard !serverUrl.isEmpty, !token.isEmpty, !client.isSignedOutOnWatch else { return }
    if let existing = client.credentials,
      existing.serverUrl == serverUrl, existing.token == token,
      // None from the phone keeps the ones the watch looked up itself.
      fallbackUrls == nil || existing.fallbackUrls == fallbackUrls,
      machineIdentifier == nil || existing.machineIdentifier == machineIdentifier
    {
      return
    }
    WatchInstrument.connectivity("credentials updated from phone server=\(serverUrl)")
    client.saveCredentials(
      serverUrl: serverUrl,
      token: token,
      machineIdentifier: machineIdentifier,
      fallbackUrls: fallbackUrls
    )
    credentialsHint = nil
    objectWillChange.send()
  }

  private func refreshCredentialsFromPhoneIfNeeded() {
    guard !PlexWatchClient.shared.hasCredentials else { return }
    requestCredentials()
  }

  /// The owner signed out on the watch.
  func signOut() {
    WatchInstrument.action("signOut")
    stopCredentialsRetryLoop()
    stopLocalPlayback()
    PlexWatchClient.shared.signOutOnWatch()
    credentialsHint = nil
    objectWillChange.send()
  }

  /// The phone signed out, so what it gave us is no longer ours to use.
  /// Credentials typed in on the watch were never the phone's to revoke.
  private func applyPhoneSignOut() {
    let client = PlexWatchClient.shared
    guard let creds = client.credentials, creds.isManual != true else { return }
    WatchInstrument.connectivity("phone signed out")
    stopLocalPlayback()
    client.clearCredentials()
    objectWillChange.send()
  }

  private func updateState(from message: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      if message["clearCredentials"] as? Bool == true {
        self.applyPhoneSignOut()
      } else if let serverUrl = message["serverUrl"] as? String,
        let token = message["token"] as? String
      {
        self.applyPlexCredentials(
          serverUrl: serverUrl,
          token: token,
          machineIdentifier: message["machineIdentifier"] as? String,
          fallbackUrls: Self.fallbackUrls(message)
        )
      }
    }
  }

  // MARK: - App Mode Management

  /// Start local playback mode (called when browse/search triggers playback)
  func startLocalPlayback() {
    WatchInstrument.log(.connectivity, "startLocalPlayback")
    appMode = .localPlaying
  }

  /// Dismiss the player UI but keep audio playing
  func dismissToBackground() {
    WatchInstrument.log(.connectivity, "dismissToBackground hasQueue=\(audioPlayer.hasQueue)")
    if audioPlayer.hasQueue {
      appMode = .localBrowsing
    } else {
      appMode = .idle
    }
  }

  /// Return to the player from browse mode
  func returnToPlayer() {
    WatchInstrument.log(.connectivity, "returnToPlayer")
    if audioPlayer.hasQueue {
      appMode = .localPlaying
    }
  }

  /// Stop local playback and clear queue entirely
  func stopLocalPlayback() {
    WatchInstrument.log(.connectivity, "stopLocalPlayback")
    audioPlayer.stop()
    appMode = .idle
  }

  // Retry activation if needed
  func retryActivation() {
    guard activationRetryCount < maxRetries else { return }
    activationRetryCount += 1
    session?.activate()
  }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?)
  {
    DispatchQueue.main.async {
      self.isReachable = session.isReachable
      WatchInstrument.log(
        .connectivity,
        "session activated state=\(activationState.rawValue) reachable=\(session.isReachable) error=\(error?.localizedDescription ?? "none")"
      )

      if error != nil {
        // Try to retry
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          self.retryActivation()
        }
        return
      }

      if activationState == .activated {
        self.activationRetryCount = 0  // Reset on success
        if !session.receivedApplicationContext.isEmpty {
          self.updateState(from: session.receivedApplicationContext)
        }
        self.refreshCredentialsFromPhoneIfNeeded()
      }
    }
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async {
      WatchInstrument.log(.connectivity, "reachability changed → \(session.isReachable)")
      self.isReachable = session.isReachable
      if session.isReachable {
        self.refreshCredentialsFromPhoneIfNeeded()
      }
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    updateState(from: message)
  }

  func session(
    _ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void
  ) {
    updateState(from: message)
    replyHandler(["received": true])
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    updateState(from: applicationContext)
  }
}
