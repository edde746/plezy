import UIKit
import Flutter
import AVKit

/// Flutter plugin that bridges MPV player to Dart via method and event channels
class MpvPlayerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, MpvPlayerDelegate {

    // MARK: - Properties

    private var playerCore: MpvPlayerCore?
    private var eventSink: FlutterEventSink?
    private weak var registrar: FlutterPluginRegistrar?
    private var nameToId: [String: Int] = [:]

    // PiP
    private var pipController: MpvPipController?
    private var pipChannel: FlutterMethodChannel?
    private var autoPipEnabled = false
    private var isManualPipRequest = false
    private var pipTimebaseSyncTimer: Timer?
    private var pendingInlineRestoreAfterPip = false
    private var sceneActivationObserverRegistered = false

    // MARK: - FlutterPlugin Registration

    static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.plezy/mpv_player",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.plezy/mpv_player/events",
            binaryMessenger: registrar.messenger()
        )
        let pipChannel = FlutterMethodChannel(
            name: "app.plezy/pip",
            binaryMessenger: registrar.messenger()
        )

        let instance = MpvPlayerPlugin()
        instance.registrar = registrar
        instance.pipChannel = pipChannel

        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
        pipChannel.setMethodCallHandler(instance.handlePipCall)
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
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

    // MARK: - PiP

    private func ensurePipController() -> MpvPipController {
        if let existing = pipController { return existing }
        let controller = MpvPipController()
        controller.delegate = self
        pipController = controller
        return controller
    }

    private func registerSceneActivationObserver() {
        guard !sceneActivationObserverRegistered else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidActivate),
            name: UIScene.didActivateNotification,
            object: nil
        )
        sceneActivationObserverRegistered = true
    }

    private func unregisterSceneActivationObserver() {
        guard sceneActivationObserverRegistered else { return }
        NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
        sceneActivationObserverRegistered = false
    }

    private var isSceneActive: Bool {
        UIApplication.shared.connectedScenes.contains { $0.activationState == .foregroundActive }
    }

    private func restoreInlinePlayerAfterPip() {
        guard pendingInlineRestoreAfterPip,
              let playerCore = playerCore,
              !playerCore.isPipActive,
              !playerCore.isPipStarting else { return }

        print("[MpvPlayerPlugin] Restoring inline player after PiP")
        playerCore.setVisible(true)
        playerCore.updateFrame()
        if playerCore.isPaused {
            playerCore.forceDraw()
        }
        pendingInlineRestoreAfterPip = false
    }

    private func handlePipCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSupported":
            result(MpvPipController.isSupported)
        case "enter":
            enterPip(manual: true, result: result)
        case "setAutoPipReady":
            if let args = call.arguments as? [String: Any], let ready = args["ready"] as? Bool {
                autoPipEnabled = ready
                if ready {
                    let pip = ensurePipController()
                    pip.setAutoStart(true)
                    // Warm the layer so the system considers PiP possible
                    if let pc = playerCore {
                        pip.warmLayer(currentTime: pc.timePos, isPlaying: !pc.isPaused)
                    }
                } else {
                    pipController?.setAutoStart(false)
                }
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Switch to PiP VO and prepare the sample buffer layer for PiP display.
    /// Returns the MpvPipController on success, nil on failure.
    @discardableResult
    private func switchToPipAndPrepare() -> MpvPipController? {
        guard let playerCore = playerCore else { return nil }
        let pip = ensurePipController()
        guard playerCore.switchToPipVO(layerPtr: pip.layerPointer) else { return nil }
        pendingInlineRestoreAfterPip = false
        playerCore.isPipStarting = true
        pip.pushBlankFrame()
        pip.syncTimebase(currentTime: playerCore.timePos, isPlaying: !playerCore.isPaused)
        pip.invalidatePlaybackState()
        return pip
    }

    /// Manual PiP entry (button press). Auto-PiP is handled by the system via
    /// canStartPictureInPictureAutomaticallyFromInline + pipWillStart delegate.
    private func enterPip(manual: Bool, result: FlutterResult? = nil) {
        guard MpvPipController.isSupported else {
            result?(["success": false, "errorCode": "ios_version", "errorMessage": "Requires iOS 15.0+"])
            return
        }
        guard playerCore != nil else {
            result?(["success": false, "errorCode": "failed", "errorMessage": "Player not initialized"])
            return
        }
        guard let pip = switchToPipAndPrepare() else {
            result?(["success": false, "errorCode": "vo_switch_failed", "errorMessage": "Failed to switch VO"])
            return
        }

        isManualPipRequest = manual
        pip.startPip(waitForFrame: manual) { [weak self] started in
            if started {
                result?(["success": true])
            } else {
                self?.cleanupPip(notify: false)
                result?(["success": false, "errorCode": "failed", "errorMessage": "PiP failed to start"])
            }
        }
    }

    /// Unified cleanup for all PiP exit paths
    private func cleanupPip(notify: Bool, pause: Bool = false) {
        playerCore?.isPipStarting = false
        playerCore?.isPipActive = false
        isManualPipRequest = false
        stopPipTimebaseSync()
        pipController?.flushLayer()
        let restoredInlineVO = playerCore?.switchToGpuNextVO() ?? false
        if pause { playerCore?.setProperty("pause", value: "yes") }
        pendingInlineRestoreAfterPip = restoredInlineVO
        if pendingInlineRestoreAfterPip {
            if isSceneActive {
                restoreInlinePlayerAfterPip()
            } else {
                print("[MpvPlayerPlugin] Deferring inline restore until scene activation")
            }
        }
        if notify { pipChannel?.invokeMethod("onPipChanged", arguments: false) }
    }

    /// Scene became active — restore inline playback if needed and re-warm the
    /// sample-buffer layer so future auto-PiP remains possible.
    @objc private func sceneDidActivate() {
        restoreInlinePlayerAfterPip()
        if autoPipEnabled, let pip = pipController, let pc = playerCore, !pc.isPipActive {
            pip.warmLayer(currentTime: pc.timePos, isPlaying: !pc.isPaused)
        }
    }

    // MARK: - Timebase Sync

    private func syncPipTimebase() {
        guard let playerCore = playerCore, let pipController = pipController else { return }
        pipController.syncTimebase(
            currentTime: playerCore.timePos,
            isPlaying: !playerCore.isPaused
        )
    }

    private func startPipTimebaseSync() {
        stopPipTimebaseSync()
        pipTimebaseSyncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.syncPipTimebase()
        }
    }

    private func stopPipTimebaseSync() {
        pipTimebaseSyncTimer?.invalidate()
        pipTimebaseSyncTimer = nil
    }

    // MARK: - Method Handlers

    private func handleInitialize(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                result(FlutterError(code: "ERROR", message: "Plugin deallocated", details: nil))
                return
            }

            if self.playerCore?.isInitialized == true {
                self.registerSceneActivationObserver()
                result(true)
                return
            }

            guard let window = self.findKeyWindow() else {
                result(FlutterError(code: "NO_WINDOW", message: "Could not find key window", details: nil))
                return
            }

            let core = MpvPlayerCore()
            core.delegate = self

            guard core.initialize(in: window) else {
                result(FlutterError(code: "MPV_INIT_FAILED", message: "Failed to initialize MPV", details: nil))
                return
            }

            self.playerCore = core
            self.registerSceneActivationObserver()
            core.setVisible(false)
            result(true)
        }
    }

    private func handleDispose(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { result(nil); return }
            self.pipController?.teardown()
            self.pipController = nil
            self.autoPipEnabled = false
            self.pendingInlineRestoreAfterPip = false
            self.unregisterSceneActivationObserver()
            self.stopPipTimebaseSync()
            self.playerCore?.dispose()
            self.playerCore = nil
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

        if name == "pause" {
            pipController?.invalidatePlaybackState()
            if playerCore?.isPipActive == true { syncPipTimebase() }
        }

        result(nil)
    }

    private func handleGetProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let name = args["name"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'name' argument", details: nil))
            return
        }
        result(playerCore?.getProperty(name))
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
            if visible { self?.playerCore?.updateFrame() }
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
        guard let args = call.arguments as? [String: Any],
              let level = args["level"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'level'", details: nil))
            return
        }
        playerCore?.setLogLevel(level)
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

    // MARK: - Helpers

    private func findKeyWindow() -> UIWindow? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        return window
    }
}

// MARK: - MpvPipDelegate

extension MpvPlayerPlugin: MpvPipDelegate {

    func pipWillStart() {
        // If PiP was system-initiated (not via our enterPip), switch VO now
        guard let playerCore = playerCore, !playerCore.isPipStarting else { return }
        print("[MpvPlayerPlugin] System-initiated PiP detected, switching VO")
        if switchToPipAndPrepare() == nil {
            print("[MpvPlayerPlugin] VO switch failed for system-initiated PiP")
            pipController?.stopPip()
        }
    }

    func pipDidStart() {
        playerCore?.isPipStarting = false
        playerCore?.isPipActive = true
        pendingInlineRestoreAfterPip = false
        pipChannel?.invokeMethod("onPipChanged", arguments: true)
        syncPipTimebase()
        startPipTimebaseSync()

        if isManualPipRequest {
            isManualPipRequest = false
            UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        }
    }

    func pipDidStop(restored: Bool) {
        cleanupPip(notify: true, pause: !restored)
    }

    func pipDidFailToStart(error: Error?) {
        cleanupPip(notify: true)
    }

    func pipSetPlaying(_ playing: Bool) {
        playerCore?.setProperty("pause", value: playing ? "no" : "yes")
        pipController?.invalidatePlaybackState()
        syncPipTimebase()
    }

    func pipSkip(byInterval seconds: Double) {
        guard let playerCore = playerCore else { return }
        let newTime = max(0, playerCore.timePos + seconds)
        playerCore.command(["seek", String(newTime), "absolute"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.syncPipTimebase()
            self?.pipController?.invalidatePlaybackState()
        }
    }

    var isPipPlaying: Bool { !(playerCore?.isPaused ?? true) }
    var pipDuration: Double { playerCore?.duration ?? 0 }
}
