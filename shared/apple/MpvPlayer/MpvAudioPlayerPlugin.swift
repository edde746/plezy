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
  private var textureRegistry: FlutterTextureRegistry?
  private var visualizer: MilkRustFlutterTexture?
  private var visualizerTextureId: Int64 = -1
  private var visualizerSessionId: Int64 = 0
  var eventSink: FlutterEventSink?
  var nameToId: [String: Int] = [:]

  // MpvPluginShared conformance — the audio core has no visual surface.
  var coreBase: MpvPlayerCoreBase? { playerCore }
  func setPlayerVisible(_ visible: Bool, restoreOnWindowVisible _: Bool) {}
  func updatePlayerFrame() {}
  func setPlayerVideoRect(
    left _: Int, top _: Int, right _: Int, bottom _: Int, devicePixelRatio _: Double
  ) {}
  func setPlayerVideoZoom(_: Double) {}
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
    #if os(macOS)
      instance.textureRegistry = registrar.textures
    #else
      instance.textureRegistry = registrar.textures()
    #endif
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
    if call.method.hasPrefix("visualizer") { handleVisualizer(call, result: result); return }
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
    case "getAudioSpdifCodecs":
      result(MpvPlayerCoreBase.audioSpdifCodecs)
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
      self.disposeVisualizer()
      self.playerCore?.dispose()
      self.playerCore = nil
      result(nil)
    }
  }
  private func disposeVisualizer() {
    visualizer?.host.close()
    if visualizerTextureId >= 0 { textureRegistry?.unregisterTexture(visualizerTextureId) }
    visualizer = nil; visualizerTextureId = -1; visualizerSessionId &+= 1
    _ = playerCore?.setVisualizationTap(false)
  }

  private func handleVisualizer(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let engine = args["engine"] as? String ?? "projectm"
    func reason() -> String {
      guard playerCore?.isInitialized == true else { return "Initialize the music player before opening a preset." }
      guard engine == "milkrust" else { return "Select native MilkRust on Apple platforms; this host does not bundle projectM." }
      guard PlezyVisualizationTapAvailable() else { return "This mpv build lacks the visualization PCM tap ABI v1." }
      return PlezyMilkRustHost.dependencyError()
    }
    if call.method == "visualizerCapabilities" {
      let unavailable = reason()
      result(["available":unavailable.isEmpty, "reason":unavailable, "engine":"milkrust-native-abi1",
        "audioTap":PlezyVisualizationTapAvailable()]); return
    }
    do {
      if call.method == "visualizerCreate" {
        let unavailable = reason()
        guard unavailable.isEmpty, let core = playerCore, let registry = textureRegistry else {
          result(FlutterError(code:"VISUALIZER_UNAVAILABLE", message:unavailable, details:nil)); return
        }
        disposeVisualizer()
        guard core.setVisualizationTap(true) >= 0 else {
          result(FlutterError(code:"VISUALIZER_AUDIO", message:"Could not attach to music PCM.", details:nil)); return
        }
        let lease = visualizerSessionId
        let host: PlezyMilkRustHost?
        do {
          host = try PlezyMilkRustHost(audioReader: { [weak core] output, size in
            core?.readVisualizationAudio(output, size: size) ?? -1001
          }, frameAvailable: { [weak self] in
            DispatchQueue.main.async { [weak self] in
              guard let self, self.visualizerSessionId == lease, self.visualizerTextureId >= 0 else { return }
              self.textureRegistry?.textureFrameAvailable(self.visualizerTextureId)
            }
          })
        } catch { _ = core.setVisualizationTap(false); throw error }
        guard let host else {
          _ = core.setVisualizationTap(false)
          result(FlutterError(code:"VISUALIZER_CREATE", message:"Could not create the native renderer.", details:nil)); return
        }
        let texture = MilkRustFlutterTexture(host:host)
        let id = registry.register(texture)
        guard id >= 0 else {
          host.close(); _ = core.setVisualizationTap(false)
          result(FlutterError(code:"VISUALIZER_CREATE", message:"Flutter rejected the texture.", details:nil)); return
        }
        visualizer = texture; visualizerTextureId = id
        result(["sessionId":visualizerSessionId, "textureId":id]); return
      }
      guard let texture = visualizer, (args["sessionId"] as? NSNumber)?.int64Value == visualizerSessionId else {
        result(FlutterError(code:"VISUALIZER_STALE", message:"This visualization session has ended.", details:nil)); return
      }
      switch call.method {
      case "visualizerDispose": disposeVisualizer()
      case "visualizerLoad":
        guard let path = args["path"] as? String, let root = args["root"] as? String else {
          result(FlutterError(code:"INVALID_ARGS", message:"A preset path and pack root are required.", details:nil)); return
        }
        try texture.host.loadPreset(path, root:root)
      case "visualizerResize":
        guard let width = args["width"] as? Int, let height = args["height"] as? Int,
          width > 0, height > 0, width <= 16384, height <= 16384 else {
          result(FlutterError(code:"INVALID_ARGS", message:"Invalid dimensions.", details:nil)); return
        }
        texture.host.resizeWidth(width, height:height)
      case "visualizerSetPaused":
        guard let paused = args["paused"] as? Bool else {
          result(FlutterError(code:"INVALID_ARGS", message:"A paused boolean is required.", details:nil)); return
        }
        texture.host.setPaused(paused)
      case "visualizerStatus": result(texture.host.status()); return
      default: result(FlutterMethodNotImplemented); return
      }
      result(nil)
    } catch { result(FlutterError(code:"VISUALIZER_NATIVE", message:error.localizedDescription, details:nil)) }
  }

  deinit { disposeVisualizer() }

}

private final class MilkRustFlutterTexture: NSObject, FlutterTexture {
  let host: PlezyMilkRustHost
  init(host: PlezyMilkRustHost) { self.host = host; super.init() }
  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    guard let buffer = host.copyPixelBuffer() else { return nil }
    return Unmanaged.passRetained(buffer)
  }
}
