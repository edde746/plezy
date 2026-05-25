import UIKit
import Flutter
import AVKit

/// Flutter plugin that bridges MPV player to Dart via method and event channels
class MpvPlayerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, MpvPluginShared {

  // MARK: - Properties

  private var playerCore: MpvPlayerCore?
  var eventSink: FlutterEventSink?
  private weak var registrar: FlutterPluginRegistrar?
  var nameToId: [String: Int] = [:]

  // MpvPluginShared conformance
  var coreBase: MpvPlayerCoreBase? { playerCore }
  func setPlayerVisible(_ visible: Bool, restoreOnWindowVisible _: Bool) { playerCore?.setVisible(visible) }
  func updatePlayerFrame() { playerCore?.updateFrame() }

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
      name: "com.plezy/pip",
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

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
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
    case "setDisplayCriteria":
      handleSetDisplayCriteria(call: call, result: result)
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

  private func ensurePipController() -> MpvPipController? {
    if let existing = pipController { return existing }
    guard let layer = playerCore?.sampleBufferDisplayLayer else { return nil }
    let controller = MpvPipController(sampleBufferDisplayLayer: layer)
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
    NotificationCenter.default.removeObserver(
      self, name: UIScene.didActivateNotification, object: nil)
    sceneActivationObserverRegistered = false
  }

  private var isSceneActive: Bool {
    #if os(iOS)
      ExternalDisplayManager.hasActiveApplicationScene
    #else
      UIApplication.shared.connectedScenes.contains { $0.activationState == .foregroundActive }
    #endif
  }

  private func restoreInlinePlayerAfterPip() {
    guard pendingInlineRestoreAfterPip,
      let playerCore = playerCore,
      !playerCore.isPipActive,
      !playerCore.isPipStarting
    else { return }

    print("[MpvPlayerPlugin] Restoring inline player after PiP")
    playerCore.setVisible(true)
    playerCore.updateFrame()
    if playerCore.isPaused {
      playerCore.forceDraw()
    }
    pendingInlineRestoreAfterPip = false
  }

  private func handlePipCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "isSupported":
        result(MpvPipController.isSupported)
      case "enter":
        self.enterPip(manual: true, result: result)
      case "setAutoPipReady":
        if let args = call.arguments as? [String: Any], let ready = args["ready"] as? Bool {
          self.autoPipEnabled = ready
          if ready {
            guard let pip = self.ensurePipController() else {
              result(nil)
              return
            }
            pip.setAutoStart(true)
            // Warm the layer so the system considers PiP possible
            if let pc = self.playerCore {
              pip.warmLayer(currentTime: pc.timePos, isPlaying: !pc.isPaused)
            }
          } else {
            self.pipController?.setAutoStart(false)
          }
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Prepare the shared AVFoundation display layer for PiP display.
  /// Returns the MpvPipController on success, nil on failure.
  @discardableResult
  private func preparePip() -> MpvPipController? {
    guard let playerCore = playerCore else { return nil }
    guard let pip = ensurePipController() else { return nil }
    pendingInlineRestoreAfterPip = false
    playerCore.setPipSubtitleCompositing(true)
    playerCore.isPipStarting = true
    pip.syncTimebase(currentTime: playerCore.timePos, isPlaying: !playerCore.isPaused)
    pip.invalidatePlaybackState()
    return pip
  }

  /// Manual PiP entry (button press). Auto-PiP is handled by the system via
  /// canStartPictureInPictureAutomaticallyFromInline + pipWillStart delegate.
  private func enterPip(manual: Bool, result: FlutterResult? = nil) {
    guard MpvPipController.isSupported else {
      result?([
        "success": false, "errorCode": "ios_version", "errorMessage": "Requires iOS 15.0+",
      ])
      return
    }
    guard playerCore != nil else {
      result?([
        "success": false, "errorCode": "failed", "errorMessage": "Player not initialized",
      ])
      return
    }
    guard let pip = preparePip() else {
      result?([
        "success": false, "errorCode": "pip_prepare_failed",
        "errorMessage": "Failed to prepare PiP",
      ])
      return
    }

    isManualPipRequest = manual
    pip.startPip(waitForFrame: manual) { [weak self] started in
      if started {
        result?(["success": true])
      } else {
        self?.cleanupPip(notify: false)
        result?([
          "success": false, "errorCode": "failed", "errorMessage": "PiP failed to start",
        ])
      }
    }
  }

  /// Unified cleanup for all PiP exit paths
  private func cleanupPip(notify: Bool, pause: Bool = false) {
    playerCore?.setPipSubtitleCompositing(false)
    playerCore?.isPipStarting = false
    playerCore?.isPipActive = false
    isManualPipRequest = false
    stopPipTimebaseSync()
    if pause {
      playerCore?.setPropertyAsync("pause", value: "yes") { [weak self] _ in
        self?.pipController?.invalidatePlaybackState()
        self?.syncPipTimebase()
      }
    }
    pendingInlineRestoreAfterPip = true
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
    pipTimebaseSyncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
      [weak self] _ in
      self?.syncPipTimebase()
    }
  }

  private func stopPipTimebaseSync() {
    pipTimebaseSyncTimer?.invalidate()
    pipTimebaseSyncTimer = nil
  }

  // MARK: - Platform-Specific Method Handlers

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
        result(
          FlutterError(
            code: "NO_WINDOW", message: "Could not find key window", details: nil))
        return
      }

      let core = MpvPlayerCore()
      core.delegate = self

      guard core.initialize(in: window) else {
        result(
          FlutterError(
            code: "MPV_INIT_FAILED", message: "Failed to initialize MPV", details: nil))
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
      let value = args["value"] as? String
    else {
      result(
        FlutterError(
          code: "INVALID_ARGS", message: "Missing 'name' or 'value' argument",
          details: nil))
      return
    }

    guard let core = playerCore else {
      result(nil)
      return
    }

    core.setPropertyAsync(name, value: value) { [weak self] _ in
      if name == "pause" {
        self?.pipController?.invalidatePlaybackState()
        if core.isPipActive == true { self?.syncPipTimebase() }
      }
      result(nil)
    }
  }

  private func handleSetDisplayCriteria(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
      return
    }

    guard let core = playerCore else {
      result(nil)
      return
    }

    guard let raw = args["criteria"] as? [String: Any] else {
      DispatchQueue.main.async {
        core.setServerDisplayCriteria(nil)
        result(nil)
      }
      return
    }

    let criteria = ServerDisplayCriteria(
      doviProfile: int64Value(raw["doviProfile"]) ?? 0,
      doviLevel: int64Value(raw["doviLevel"]) ?? 0,
      doviCompatibilityId: int64Value(raw["doviCompatibilityId"]),
      fps: doubleValue(raw["fps"]) ?? 0,
      width: Int32(truncatingIfNeeded: int64Value(raw["width"]) ?? 0),
      height: Int32(truncatingIfNeeded: int64Value(raw["height"]) ?? 0),
      gamma: stringValue(raw["transfer"]),
      primaries: stringValue(raw["primaries"]),
      colorMatrix: stringValue(raw["matrix"])
    )
    DispatchQueue.main.async {
      core.setServerDisplayCriteria(criteria)
      result(nil)
    }
  }

  private func int64Value(_ value: Any?) -> Int64? {
    switch value {
    case let value as Int64:
      return value
    case let value as Int:
      return Int64(value)
    case let value as NSNumber:
      return value.int64Value
    case let value as String:
      return Int64(value)
    default:
      return nil
    }
  }

  private func doubleValue(_ value: Any?) -> Double? {
    switch value {
    case let value as Double:
      return value
    case let value as NSNumber:
      return value.doubleValue
    case let value as String:
      return Double(value)
    default:
      return nil
    }
  }

  private func stringValue(_ value: Any?) -> String? {
    guard let value else { return nil }
    let string = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
    return string.isEmpty ? nil : string
  }

  // MARK: - Helpers

  private func findKeyWindow() -> UIWindow? {
    #if os(iOS)
      return ExternalDisplayManager.mainApplicationWindow()
    #else
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

      for scene in scenes {
        if let window = scene.windows.first(where: { $0.isKeyWindow }) {
          return window
        }
      }

      for scene in scenes {
        if let window = scene.windows.first(where: { !$0.isHidden }) {
          return window
        }
      }

      return scenes.first?.windows.first
    #endif
  }
}

// MARK: - MpvPipDelegate

extension MpvPlayerPlugin: MpvPipDelegate {

  func pipWillStart() {
    // If PiP was system-initiated (not via our enterPip), prepare the shared layer now.
    guard let playerCore = playerCore, !playerCore.isPipStarting else { return }
    print("[MpvPlayerPlugin] System-initiated PiP detected, preparing shared layer")
    if preparePip() == nil {
      print("[MpvPlayerPlugin] PiP preparation failed for system-initiated PiP")
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
      UIControl().sendAction(
        #selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }
  }

  func pipDidStop(restored: Bool) {
    cleanupPip(notify: true, pause: !restored)
  }

  func pipDidFailToStart(error: Error?) {
    cleanupPip(notify: true)
  }

  func pipSetPlaying(_ playing: Bool) {
    playerCore?.setPropertyAsync("pause", value: playing ? "no" : "yes") { [weak self] _ in
      self?.pipController?.invalidatePlaybackState()
      self?.syncPipTimebase()
    }
  }

  func pipSkip(byInterval seconds: Double, completion: @escaping () -> Void) {
    guard let playerCore = playerCore else {
      completion()
      return
    }
    let newTime = max(0, playerCore.timePos + seconds)
    playerCore.commandAsync(["seek", String(newTime), "absolute"]) { [weak self] _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self?.pipController?.invalidatePlaybackState()
        completion()
      }
    }
  }

  var isPipPlaying: Bool { !(playerCore?.isPaused ?? true) }
  var pipDuration: Double { playerCore?.duration ?? 0 }
}
