import Foundation
import WatchConnectivity
import Flutter

/// Manages Watch Connectivity on the iOS side
/// Handles communication between the Flutter app and Apple Watch
class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    private var session: WCSession?
    private var methodChannel: FlutterMethodChannel?
    private var isMethodChannelReady = false

    // Current playback state to sync to watch
    private var currentState: [String: Any] = [:]

    // Pending reply handler for queue transfer
    private var pendingQueueReplyHandler: (([String: Any]) -> Void)?

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
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("[iOS-Watch] Flutter method call: %@", call.method)

        switch call.method {
        case "updatePlaybackState":
            if let args = call.arguments as? [String: Any] {
                updatePlaybackState(args)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }

        case "clearPlaybackState":
            clearPlaybackState()
            result(nil)

        case "isWatchConnected":
            // Ensure session is active before checking
            ensureSessionActive()
            let connected = session?.isReachable ?? false
            NSLog("[iOS-Watch] isWatchConnected: %d, isPaired: %d, activationState: %d",
                  connected,
                  session?.isPaired ?? false,
                  session?.activationState.rawValue ?? -1)
            result(connected)

        case "isWatchPaired":
            let paired = session?.isPaired ?? false
            NSLog("[iOS-Watch] isWatchPaired: %d", paired)
            result(paired)

        case "sendQueueToWatch":
            if let args = call.arguments as? [String: Any] {
                sendQueueToWatch(args)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }

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

    /// Update playback state and sync to watch
    func updatePlaybackState(_ state: [String: Any]) {
        currentState = state
        sendStateToWatch()
    }

    /// Clear playback state (when playback stops)
    func clearPlaybackState() {
        currentState = ["clearState": true]
        sendStateToWatch()
        currentState = [:]
    }

    /// Send queue data to watch for local playback
    func sendQueueToWatch(_ queueData: [String: Any]) {
        NSLog("[iOS-Watch] sendQueueToWatch called")

        if let queue = queueData["queue"] as? [[String: Any]] {
            NSLog("[iOS-Watch] Queue has %d items", queue.count)

            // Log approximate payload size
            if let jsonData = try? JSONSerialization.data(withJSONObject: queueData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                NSLog("[iOS-Watch] Payload size: %d bytes", jsonString.count)
            }
        }

        // If we have a pending reply handler from the watch, use it
        if let replyHandler = pendingQueueReplyHandler {
            NSLog("[iOS-Watch] Using pending reply handler to send queue")
            // Sanitize the data to remove any null/NSNull values
            // WatchConnectivity doesn't support NSNull
            let sanitizedData = sanitizeForWatchConnectivity(queueData)
            replyHandler(sanitizedData)
            pendingQueueReplyHandler = nil
            return
        }

        // Otherwise send as a regular message
        guard let session = session else {
            NSLog("[iOS-Watch] No session available to send queue")
            return
        }

        if session.isReachable {
            NSLog("[iOS-Watch] Sending queue via direct message")
            session.sendMessage(queueData, replyHandler: { response in
                NSLog("[iOS-Watch] Queue sent successfully")
            }) { error in
                NSLog("[iOS-Watch] Error sending queue: %@", error.localizedDescription)
            }
        } else {
            NSLog("[iOS-Watch] Watch not reachable, cannot send queue")
        }
    }

    private func sendStateToWatch() {
        guard let session = session else { return }

        if session.isReachable {
            session.sendMessage(currentState, replyHandler: nil) { error in
                NSLog("[iOS-Watch] Error sending state: %@", error.localizedDescription)
                try? self.session?.updateApplicationContext(self.currentState)
            }
        } else {
            try? session.updateApplicationContext(currentState)
        }
    }

    /// Sanitize a dictionary for WatchConnectivity
    /// Removes NSNull values and recursively sanitizes nested structures
    /// WatchConnectivity only supports: String, Number, Data, Date, Array, Dictionary
    private func sanitizeForWatchConnectivity(_ input: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]

        for (key, value) in input {
            if value is NSNull {
                // Skip null values
                continue
            } else if let dict = value as? [String: Any] {
                // Recursively sanitize dictionaries
                result[key] = sanitizeForWatchConnectivity(dict)
            } else if let array = value as? [Any] {
                // Sanitize arrays
                result[key] = sanitizeArray(array)
            } else {
                // Keep supported types as-is
                result[key] = value
            }
        }

        return result
    }

    /// Sanitize an array for WatchConnectivity
    private func sanitizeArray(_ input: [Any]) -> [Any] {
        return input.compactMap { element in
            if element is NSNull {
                return nil
            } else if let dict = element as? [String: Any] {
                return sanitizeForWatchConnectivity(dict)
            } else if let array = element as? [Any] {
                return sanitizeArray(array)
            } else {
                return element
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            NSLog("[iOS-Watch] Session activation failed: %@", error.localizedDescription)
        } else {
            NSLog("[iOS-Watch] Session activated: state=%d, isPaired=%d, isReachable=%d",
                  activationState.rawValue, session.isPaired, session.isReachable)

            #if os(iOS)
            NSLog("[iOS-Watch] isWatchAppInstalled=%d", session.isWatchAppInstalled)
            #endif
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        NSLog("[iOS-Watch] Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        NSLog("[iOS-Watch] Session deactivated, reactivating...")
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        NSLog("[iOS-Watch] Reachability changed: %d", session.isReachable)
        if session.isReachable {
            sendStateToWatch()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        NSLog("[iOS-Watch] Received message from watch (no reply handler): %@", message.keys.joined(separator: ", "))
        handleWatchMessage(message, replyHandler: nil)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        NSLog("[iOS-Watch] Received message from watch WITH reply handler: %@", message.keys.joined(separator: ", "))
        handleWatchMessage(message, replyHandler: replyHandler)
    }

    private func handleWatchMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        // If method channel isn't ready yet, queue the message
        if !isMethodChannelReady {
            NSLog("[iOS-Watch] Method channel not ready, queuing message")
            pendingMessages.append((message: message, replyHandler: replyHandler))
            return
        }

        guard let command = message["command"] as? String else {
            NSLog("[iOS-Watch] Message has no command")
            replyHandler?(["error": "No command"])
            return
        }

        NSLog("[iOS-Watch] Watch command received: %@", command)

        if command == "transferToWatch" {
            // Store the reply handler - we need to respond to this
            if let handler = replyHandler {
                NSLog("[iOS-Watch] Storing reply handler for transferToWatch")
                pendingQueueReplyHandler = handler

                // Set a timeout to ensure we respond even if Flutter doesn't
                DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
                    if let pending = self?.pendingQueueReplyHandler {
                        NSLog("[iOS-Watch] Reply handler timeout - sending error")
                        pending(["error": "Timeout waiting for content"])
                        self?.pendingQueueReplyHandler = nil
                    }
                }
            }

            // Forward to Flutter
            DispatchQueue.main.async { [weak self] in
                NSLog("[iOS-Watch] Forwarding transferToWatch to Flutter")
                self?.methodChannel?.invokeMethod("onWatchCommand", arguments: ["command": command])
            }
        } else if command == "requestCredentials" {
            // Watch is asking for Plex server credentials
            NSLog("[iOS-Watch] Watch requesting credentials")
            DispatchQueue.main.async { [weak self] in
                self?.methodChannel?.invokeMethod("getCredentials", arguments: nil) { result in
                    if let creds = result as? [String: Any],
                       let serverUrl = creds["serverUrl"] as? String,
                       let token = creds["token"] as? String {
                        NSLog("[iOS-Watch] Sending credentials to watch")
                        replyHandler?(["serverUrl": serverUrl, "token": token])
                    } else {
                        NSLog("[iOS-Watch] No credentials available from Flutter")
                        replyHandler?(["error": "No credentials"])
                    }
                }
            }
        } else if command == "volumeUp" || command == "volumeDown" {
            // Forward volume commands to Flutter
            DispatchQueue.main.async { [weak self] in
                NSLog("[iOS-Watch] Forwarding volume command to Flutter: %@", command)
                self?.methodChannel?.invokeMethod("onWatchCommand", arguments: ["command": command])
            }
            replyHandler?(["received": true])
        } else {
            // For other commands, just forward to Flutter
            DispatchQueue.main.async { [weak self] in
                NSLog("[iOS-Watch] Forwarding command to Flutter: %@", command)
                self?.methodChannel?.invokeMethod("onWatchCommand", arguments: ["command": command])
            }
            replyHandler?(["received": true])
        }
    }
}
