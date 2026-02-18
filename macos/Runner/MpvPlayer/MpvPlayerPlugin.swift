import Cocoa
import FlutterMacOS

/// Flutter plugin that bridges MPV player to Dart via method and event channels
class MpvPlayerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, MpvPlayerDelegate {

    // MARK: - Properties

    private var playerCore: MpvPlayerCore?
    private var eventSink: FlutterEventSink?
    private weak var registrar: FlutterPluginRegistrar?
    private var nameToId: [String: Int] = [:]

    // MARK: - FlutterPlugin Registration

    static func register(with registrar: FlutterPluginRegistrar) {
        // Method channel for commands
        let methodChannel = FlutterMethodChannel(
            name: "com.plezy/mpv_player",
            binaryMessenger: registrar.messenger
        )

        // Event channel for state updates
        let eventChannel = FlutterEventChannel(
            name: "com.plezy/mpv_player/events",
            binaryMessenger: registrar.messenger
        )

        let instance = MpvPlayerPlugin()
        instance.registrar = registrar

        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)

        print("[MpvPlayerPlugin] Registered with Flutter")
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        print("[MpvPlayerPlugin] Event stream connected")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        print("[MpvPlayerPlugin] Event stream disconnected")
        return nil
    }

    // MARK: - FlutterPlugin Method Handler

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(result: result)

        case "dispose":
            handleDispose(result: result)

        case "setProperty":
            handleSetProperty(call: call, result: result)

        case "getProperty":
            handleGetProperty(call: call, result: result)

        case "observeProperty":
            handleObserveProperty(call: call, result: result)

        case "command":
            handleCommand(call: call, result: result)

        case "setVisible":
            handleSetVisible(call: call, result: result)

        case "isInitialized":
            result(playerCore?.isInitialized ?? false)

        case "updateFrame":
            handleUpdateFrame(result: result)

        case "setLogLevel":
            handleSetLogLevel(call: call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleInitialize(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                result(FlutterError(code: "ERROR", message: "Plugin deallocated", details: nil))
                return
            }

            // Check if already initialized
            if self.playerCore?.isInitialized == true {
                print("[MpvPlayerPlugin] Already initialized")
                result(true)
                return
            }

            // Find the Flutter window
            guard let (window, _, _) = self.findFlutterWindow() else {
                print("[MpvPlayerPlugin] Failed to find Flutter window")
                result(FlutterError(code: "NO_WINDOW", message: "Could not find Flutter window", details: nil))
                return
            }

            // Create and initialize player core
            let core = MpvPlayerCore()
            core.delegate = self

            guard core.initialize(in: window) else {
                print("[MpvPlayerPlugin] Failed to initialize MPV")
                result(FlutterError(code: "MPV_INIT_FAILED", message: "Failed to initialize MPV", details: nil))
                return
            }

            self.playerCore = core

            // Start hidden
            core.setVisible(false)

            print("[MpvPlayerPlugin] Initialized successfully")
            result(true)
        }
    }

    private func handleDispose(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            self?.playerCore?.dispose()
            self?.playerCore = nil
            print("[MpvPlayerPlugin] Disposed")
            result(nil)
        }
    }

    private func handleSetProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let name = args["name"] as? String,
              let value = args["value"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'name' or 'value' argument", details: nil))
            return
        }

        playerCore?.setProperty(name, value: value)
        result(nil)
    }

    private func handleGetProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let name = args["name"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'name' argument", details: nil))
            return
        }

        let value = playerCore?.getProperty(name)
        result(value)
    }

    private func handleObserveProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let name = args["name"] as? String,
              let format = args["format"] as? String,
              let id = args["id"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'name', 'format', or 'id' argument", details: nil))
            return
        }

        nameToId[name] = id
        playerCore?.observeProperty(name, format: format)
        result(nil)
    }

    private func handleCommand(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let commandArgs = args["args"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'args' argument", details: nil))
            return
        }

        // Use async command to prevent UI blocking during network operations
        playerCore?.commandAsync(commandArgs) { commandResult in
            switch commandResult {
            case .success:
                result(nil)
            case .failure(let error):
                result(FlutterError(code: "COMMAND_FAILED", message: error.localizedDescription, details: nil))
            }
        } ?? result(nil)
    }

    private func handleSetVisible(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let visible = args["visible"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'visible' argument", details: nil))
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.playerCore?.setVisible(visible)

            // Update frame when becoming visible
            if visible {
                self?.playerCore?.updateFrame()
            }

            result(nil)
        }
    }

    private func handleUpdateFrame(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            self?.playerCore?.updateFrame()
            result(nil)
        }
    }

    private func handleSetLogLevel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let playerCore = playerCore else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Player not initialized", details: nil))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let level = args["level"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'level'", details: nil))
            return
        }
        playerCore.setLogLevel(level)
        result(nil)
    }

    // MARK: - MpvPlayerDelegate

    func onPropertyChange(name: String, value: Any?) {
        guard let eventSink = eventSink else { return }

        if let propId = nameToId[name] {
            eventSink([propId, value as Any])
        }
    }

    func onEvent(name: String, data: [String: Any]?) {
        guard let eventSink = eventSink else { return }

        var event: [String: Any] = ["type": "event", "name": name]
        if let data = data {
            event["data"] = data
        }

        eventSink(event)
    }

    // MARK: - Helpers

    private func findFlutterWindow() -> (NSWindow, NSView, NSView)? {
        for window in NSApplication.shared.windows {
            if window is MainFlutterWindow,
               let contentView = window.contentView,
               let contentVC = window.contentViewController {
                let flutterView = contentVC.view
                return (window, contentView, flutterView)
            }
        }

        // Fallback
        for window in NSApplication.shared.windows {
            if let contentView = window.contentView,
               let contentVC = window.contentViewController {
                let flutterView = contentVC.view
                return (window, contentView, flutterView)
            }
        }

        return nil
    }
}
