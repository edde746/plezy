import Foundation
import Security
import WatchConnectivity
import Flutter

/// Plex credentials on their way to the watch.
private struct WatchCredentials: Codable {
  let serverUrl: String
  let token: String
  var machineIdentifier: String?
  /// Newline-separated remote addresses, for a watch away from home.
  var fallbackUrls: String?

  init(serverUrl: String, token: String, machineIdentifier: String? = nil, fallbackUrls: String? = nil) {
    self.serverUrl = serverUrl
    self.token = token
    self.machineIdentifier = machineIdentifier
    self.fallbackUrls = fallbackUrls
  }

  init?(arguments: Any?) {
    guard let args = arguments as? [String: Any],
      let serverUrl = args["serverUrl"] as? String,
      let token = args["token"] as? String,
      !serverUrl.isEmpty, !token.isEmpty
    else { return nil }
    self.init(
      serverUrl: serverUrl,
      token: token,
      machineIdentifier: args["machineIdentifier"] as? String,
      fallbackUrls: args["fallbackUrls"] as? String
    )
  }

  /// What WatchConnectivity carries, which is also what a reply answers with.
  var payload: [String: Any] {
    var payload: [String: Any] = ["serverUrl": serverUrl, "token": token]
    payload["machineIdentifier"] = machineIdentifier
    payload["fallbackUrls"] = fallbackUrls
    return payload
  }
}

/// Manages Watch Connectivity on the iOS side
/// Handles communication between the Flutter app and Apple Watch
class WatchSessionManager: NSObject {
  static let shared = WatchSessionManager()

  private var session: WCSession?
  private var methodChannel: FlutterMethodChannel?
  private var isMethodChannelReady = false

  /// Pre-Keychain home of the cached credentials, removed on first activation.
  private let legacyCredentialsKey = "plexCredentialsForWatch"

  /// The newest credentials Dart has given us. Memory only until a watch is
  /// known to be there: most iPhones have none, and for those nothing is
  /// written to disk at all.
  private var latestCredentials: WatchCredentials?

  /// A sign-out that arrived before the session had activated.
  private var pendingClear = false

  // Queue of messages received before method channel was ready
  private var pendingMessages: [(message: [String: Any], replyHandler: (([String: Any]) -> Void)?)] = []

  override init() {
    super.init()
    NSLog("[iOS-Watch] WatchSessionManager initializing")

    if WCSession.isSupported() {
      session = WCSession.default
      session?.delegate = self
      session?.activate()
      NSLog("[iOS-Watch] WCSession activation requested")
    } else {
      NSLog("[iOS-Watch] WCSession not supported")
      UserDefaults.standard.removeObject(forKey: legacyCredentialsKey)
    }
  }

  /// Set up the Flutter method channel for communication
  func setupMethodChannel(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: "com.edde746.plezy/watch",
      binaryMessenger: messenger
    )

    methodChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call, result: result)
    }

    isMethodChannelReady = true
    NSLog("[iOS-Watch] Flutter method channel configured, processing %d pending messages", pendingMessages.count)

    // Process any pending messages
    for pending in pendingMessages {
      handleWatchMessage(pending.message, replyHandler: pending.replyHandler)
    }
    pendingMessages.removeAll()

    // Push cached credentials only — Dart bridge will push fresh ones when ready.
    if let cached = cachedCredentials() {
      pushCredentialsToWatch(cached)
    }
  }

  /// Flutter platform channels must be used on the main thread.
  private func onMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async(execute: work)
    }
  }

  private func invokeFlutter(_ method: String, arguments: Any?, completion: @escaping (Any?) -> Void) {
    onMain { [weak self] in
      guard let methodChannel = self?.methodChannel else {
        completion(nil)
        return
      }
      methodChannel.invokeMethod(method, arguments: arguments, result: completion)
    }
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    NSLog("[iOS-Watch] Flutter method call: %@", call.method)

    switch call.method {
    case "updatePlexCredentials":
      if let credentials = WatchCredentials(arguments: call.arguments) {
        updateCredentials(credentials)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid credentials", details: nil))
      }

    case "clearPlexCredentials":
      clearCredentials()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Ensure the WCSession is activated
  private func ensureSessionActive() {
    guard let session = session else { return }
    if session.activationState != .activated {
      NSLog("[iOS-Watch] Session not activated, reactivating...")
      session.activate()
    }
  }

  private var sessionIsActivated: Bool {
    session?.activationState == .activated
  }

  /// Only meaningful once activated; before that both answers are false.
  private var watchIsAvailable: Bool {
    guard let session, sessionIsActivated else { return false }
    return session.isPaired && session.isWatchAppInstalled
  }

  /// Cache Plex credentials and push them to the watch for standalone playback.
  private func updateCredentials(_ credentials: WatchCredentials) {
    latestCredentials = credentials
    pendingClear = false
    // Before activation there is no telling if a watch exists, and
    // reconcileWithWatch picks this up from memory when there is.
    guard sessionIsActivated else { return }
    guard watchIsAvailable else {
      WatchCredentialsKeychain.delete()
      return
    }
    WatchCredentialsKeychain.save(credentials)
    pushCredentialsToWatch(credentials)
  }

  /// Dart has no signed-in Plex server any more: forget the token here and
  /// take it back from the watch.
  private func clearCredentials() {
    latestCredentials = nil
    WatchCredentialsKeychain.delete()
    guard let session, sessionIsActivated else {
      pendingClear = true
      return
    }
    pendingClear = false
    guard watchIsAvailable else { return }

    // The context too, even when reachable: it replaces the one holding the
    // token, which the watch would otherwise read again on its next launch.
    let payload: [String: Any] = ["clearCredentials": true]
    do {
      try session.updateApplicationContext(payload)
    } catch {
      NSLog("[iOS-Watch] Error clearing credentials via context: %@", error.localizedDescription)
    }
    if session.isReachable {
      session.sendMessage(payload, replyHandler: nil) { error in
        NSLog("[iOS-Watch] Error sending sign-out: %@", error.localizedDescription)
      }
    }
  }

  private func cachedCredentials() -> WatchCredentials? {
    latestCredentials ?? WatchCredentialsKeychain.load()
  }

  /// Credentials as an earlier build left them in UserDefaults, removing them.
  private func takeLegacyCredentials() -> WatchCredentials? {
    let defaults = UserDefaults.standard
    guard let payload = defaults.dictionary(forKey: legacyCredentialsKey) else { return nil }
    defaults.removeObject(forKey: legacyCredentialsKey)
    guard let serverUrl = payload["serverUrl"] as? String,
      let token = payload["plexToken"] as? String ?? payload["token"] as? String,
      !serverUrl.isEmpty, !token.isEmpty
    else { return nil }
    return WatchCredentials(serverUrl: serverUrl, token: token)
  }

  /// Bring what is stored in line with whether a watch is actually there.
  /// Runs on activation and when a watch is paired, unpaired, or gets the app.
  private func reconcileWithWatch() {
    let legacy = takeLegacyCredentials()

    if pendingClear {
      clearCredentials()
      return
    }
    guard watchIsAvailable else {
      WatchCredentialsKeychain.delete()
      return
    }
    if let credentials = latestCredentials ?? WatchCredentialsKeychain.load() ?? legacy {
      WatchCredentialsKeychain.save(credentials)
      pushCredentialsToWatch(credentials)
    } else {
      refreshCredentialsFromFlutter()
    }
  }

  private func refreshCredentialsFromFlutter() {
    guard isMethodChannelReady else { return }

    invokeFlutter("getCredentials", arguments: nil) { [weak self] result in
      if let credentials = WatchCredentials(arguments: result) {
        self?.updateCredentials(credentials)
      }
    }
  }

  private func pushCredentialsToWatch(_ credentials: WatchCredentials) {
    guard let session = session else { return }
    guard watchIsAvailable else {
      NSLog("[iOS-Watch] No watch to push credentials to yet")
      return
    }

    let payload = credentials.payload

    if session.isReachable {
      session.sendMessage(payload, replyHandler: nil) { error in
        NSLog("[iOS-Watch] Error pushing credentials: %@", error.localizedDescription)
        try? session.updateApplicationContext(payload)
      }
    } else {
      do {
        try session.updateApplicationContext(payload)
      } catch {
        NSLog("[iOS-Watch] Error pushing credentials via context: %@", error.localizedDescription)
      }
    }
  }

  private func replyWithStreamUrl(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
    guard let replyHandler else { return }
    let ratingKey = message["ratingKey"] as? String ?? ""
    guard !ratingKey.isEmpty else {
      replyHandler(["error": "Missing ratingKey"])
      return
    }

    var arguments: [String: Any] = ["ratingKey": ratingKey]
    arguments["machineIdentifier"] = message["machineIdentifier"] as? String

    invokeFlutter("resolveMusicStreamUrl", arguments: arguments) { result in
      if let dict = result as? [String: Any], let streamUrl = dict["streamUrl"] as? String {
        NSLog("[iOS-Watch] Sending stream URL to watch")
        replyHandler(["streamUrl": streamUrl])
      } else {
        NSLog("[iOS-Watch] Could not resolve stream URL from Flutter")
        replyHandler(["error": "No stream URL"])
      }
    }
  }

  private func replyWithCredentials(_ replyHandler: (([String: Any]) -> Void)?) {
    guard let replyHandler else { return }

    if let cached = cachedCredentials() {
      NSLog("[iOS-Watch] Sending cached credentials to watch")
      replyHandler(cached.payload)
      return
    }

    invokeFlutter("getCredentials", arguments: nil) { [weak self] result in
      if let credentials = WatchCredentials(arguments: result) {
        NSLog("[iOS-Watch] Sending credentials from Flutter to watch")
        self?.updateCredentials(credentials)
        replyHandler(credentials.payload)
      } else {
        NSLog("[iOS-Watch] No credentials available from Flutter")
        replyHandler(["error": "No credentials"])
      }
    }
  }
}

// MARK: - WCSessionDelegate
extension WatchSessionManager: WCSessionDelegate {
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?)
  {
    if let error = error {
      NSLog("[iOS-Watch] Session activation failed: %@", error.localizedDescription)
    } else {
      NSLog(
        "[iOS-Watch] Session activated: state=%d, isPaired=%d, isReachable=%d",
        activationState.rawValue, session.isPaired, session.isReachable)

      #if os(iOS)
        NSLog("[iOS-Watch] isWatchAppInstalled=%d", session.isWatchAppInstalled)
      #endif

      if activationState == .activated {
        onMain { self.reconcileWithWatch() }
      }
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
    NSLog("[iOS-Watch] Session became inactive")
  }

  func sessionDidDeactivate(_ session: WCSession) {
    NSLog("[iOS-Watch] Session deactivated, reactivating...")
    session.activate()
  }

  func sessionWatchStateDidChange(_ session: WCSession) {
    NSLog(
      "[iOS-Watch] Watch state changed: isPaired=%d, isWatchAppInstalled=%d",
      session.isPaired, session.isWatchAppInstalled)
    onMain { [weak self] in
      self?.reconcileWithWatch()
    }
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    NSLog("[iOS-Watch] Reachability changed: %d", session.isReachable)
    onMain { [weak self] in
      guard let self else { return }
      if session.isReachable, let cached = self.cachedCredentials() {
        self.pushCredentialsToWatch(cached)
      }
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    NSLog("[iOS-Watch] Received message from watch (no reply handler): %@", message.keys.joined(separator: ", "))
    onMain { [weak self] in
      self?.handleWatchMessage(message, replyHandler: nil)
    }
  }

  func session(
    _ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void
  ) {
    NSLog("[iOS-Watch] Received message from watch WITH reply handler: %@", message.keys.joined(separator: ", "))
    onMain { [weak self] in
      self?.handleWatchMessage(message, replyHandler: replyHandler)
    }
  }

  private func handleWatchMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
    // If method channel isn't ready yet, queue the message
    if !isMethodChannelReady {
      NSLog("[iOS-Watch] Method channel not ready, queuing message")
      pendingMessages.append((message: message, replyHandler: replyHandler))
      return
    }

    switch message["command"] as? String {
    case "requestCredentials":
      replyWithCredentials(replyHandler)
    case "requestStreamUrl":
      replyWithStreamUrl(message, replyHandler: replyHandler)
    default:
      NSLog("[iOS-Watch] Ignoring unknown watch message")
      replyHandler?(["error": "Unknown command"])
    }
  }
}

/// The phone's copy of what the watch was given, so a watch that asks while the
/// Flutter engine is still starting gets an answer. Not the source of truth:
/// that is Dart's credential vault, which also replaces this on every launch.
private enum WatchCredentialsKeychain {
  private static var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "plezy.watch.plex-credentials",
      kSecAttrAccount as String: "default",
    ]
  }

  static func load() -> WatchCredentials? {
    var lookup = query
    lookup[kSecReturnData as String] = true
    lookup[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    guard SecItemCopyMatching(lookup as CFDictionary, &result) == errSecSuccess,
      let data = result as? Data
    else { return nil }
    return try? JSONDecoder().decode(WatchCredentials.self, from: data)
  }

  /// After first unlock: WatchConnectivity can wake this app with the phone locked.
  static func save(_ credentials: WatchCredentials) {
    guard let data = try? JSONEncoder().encode(credentials) else { return }
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      status = SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
    }
    if status != errSecSuccess {
      NSLog("[iOS-Watch] Could not store credentials in the Keychain: %d", status)
    }
  }

  static func delete() {
    SecItemDelete(query as CFDictionary)
  }
}
