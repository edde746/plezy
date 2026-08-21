#if os(iOS) || os(tvOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

/// Flutter plugin for the dedicated audio-only mpv core (music playback).
///
/// Registers `com.plezy/mpv_audio_player` + `/events` and delegates all
/// generic property/command/observe traffic to the shared [MpvPluginShared]
/// handlers. There is no render layer, so the visual hooks are no-ops and
/// `setVisible`/`updateFrame` succeed without doing anything. Shared across
/// iOS, tvOS, and macOS — unlike the video plugin there is nothing
/// platform-specific beyond the messenger accessor.
class MpvAudioPlayerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, MpvPluginShared {

  private var playerCore: MpvAudioPlayerCore?
  var eventSink: FlutterEventSink?
  var nameToId: [String: Int] = [:]

  // MpvPluginShared conformance — the audio core has no visual surface.
  var coreBase: MpvPlayerCoreBase? { playerCore }
  func setPlayerVisible(_ visible: Bool, restoreOnWindowVisible _: Bool) {}
  func updatePlayerFrame() {}
  func didSetPauseProperty(value _: String) {}

  // MARK: - FlutterPlugin Registration

  static func register(with registrar: FlutterPluginRegistrar) {
    #if os(macOS)
      let messenger = registrar.messenger
    #else
      let messenger = registrar.messenger()
    #endif

    let methodChannel = FlutterMethodChannel(
      name: "com.plezy/mpv_audio_player",
      binaryMessenger: messenger
    )
    let eventChannel = FlutterEventChannel(
      name: "com.plezy/mpv_audio_player/events",
      binaryMessenger: messenger
    )

    let instance = MpvAudioPlayerPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
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
    case "isInitialized":
      result(playerCore?.isInitialized ?? false)
    case "setVisible", "updateFrame":
      // No render layer — succeed so shared Dart call sites stay unconditional.
      result(nil)
    case "setLogLevel":
      handleSetLogLevel(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        result(FlutterError(code: "ERROR", message: "Plugin deallocated", details: nil))
        return
      }

      if self.playerCore?.isInitialized == true {
        result(true)
        return
      }

      let core = MpvAudioPlayerCore()
      core.delegate = self

      guard core.initialize() else {
        result(
          FlutterError(
            code: "MPV_INIT_FAILED", message: "Failed to initialize MPV audio core", details: nil))
        return
      }

      self.playerCore = core
      result(true)
    }
  }

  private func handleDispose(result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { result(nil); return }
      self.playerCore?.dispose()
      self.playerCore = nil
      result(nil)
    }
  }
}
