#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

/// Protocol for shared MpvPlayerPlugin method handlers across iOS and macOS.
/// Platform-specific methods (PiP, initialization, window finding) remain
/// in the per-platform MpvPlayerPlugin files.
protocol MpvPluginShared: AnyObject, MpvPlayerDelegate {
    var coreBase: MpvPlayerCoreBase? { get }
    var eventSink: FlutterEventSink? { get }
    var nameToId: [String: Int] { get set }

    func setPlayerVisible(_ visible: Bool)
    func updatePlayerFrame()
}

extension MpvPluginShared {

    func handleGetProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let name = args["name"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'name' argument", details: nil))
            return
        }
        result(coreBase?.getProperty(name))
    }

    func handleObserveProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let name = args["name"] as? String,
              let format = args["format"] as? String,
              let id = args["id"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'name', 'format', or 'id' argument", details: nil))
            return
        }

        nameToId[name] = id
        coreBase?.observeProperty(name, format: format)
        result(nil)
    }

    func handleCommand(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let commandArgs = args["args"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'args' argument", details: nil))
            return
        }

        coreBase?.commandAsync(commandArgs) { commandResult in
            switch commandResult {
            case .success:
                result(nil)
            case .failure(let error):
                result(FlutterError(code: "COMMAND_FAILED", message: error.localizedDescription, details: nil))
            }
        } ?? result(nil)
    }

    func handleSetVisible(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let visible = args["visible"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'visible' argument", details: nil))
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.setPlayerVisible(visible)
            if visible { self?.updatePlayerFrame() }
            result(nil)
        }
    }

    func handleUpdateFrame(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            self?.updatePlayerFrame()
            result(nil)
        }
    }

    func handleSetLogLevel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let level = args["level"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'level'", details: nil))
            return
        }
        coreBase?.setLogLevel(level)
        result(nil)
    }

    // MARK: - MpvPlayerDelegate

    func onPropertyChange(name: String, value: Any?) {
        guard let eventSink = eventSink, let propId = nameToId[name] else { return }
        eventSink([propId, value as Any])
    }

    func onEvent(name: String, data: [String: Any]?) {
        guard let eventSink = eventSink else { return }
        var event: [String: Any] = ["type": "event", "name": name]
        if let data = data { event["data"] = data }
        eventSink(event)
    }
}
