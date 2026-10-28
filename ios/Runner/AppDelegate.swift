import plezy_preparation
import Flutter
import UIKit
import AVFoundation
import MediaPlayer
import MusicKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var deviceAdjustmentChannel: FlutterMethodChannel?
  private var originalBrightness: CGFloat?
  private var volumeView: MPVolumeView?
  private weak var volumeSlider: UISlider?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    PlezyPreparationPlugin.registerBackgroundTasks { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // Configure the non-mixing session; activate it only when playback starts.
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
    } catch {
      MpvLog.error("Failed to configure audio session: \(error)")
    }
    // Declares that playback can carry 5.1/7.1 and Dolby content, so the
    // system offers multichannel Spatial Audio on AirPods (#2264). mpv's
    // AVFoundation output only declares it for sources above stereo, and only
    // in builds that compiled the call in; declaring it here does not depend
    // on either.
    do {
      try AVAudioSession.sharedInstance().setSupportsMultichannelContent(true)
    } catch {
      MpvLog.error("Failed to declare multichannel audio content: \(error)")
    }

    application.beginReceivingRemoteControlEvents()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MpvPlayerPlugin") {
      MpvPlayerPlugin.register(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MpvWorkspacePlayerPlugin") {
      MpvPlayerPlugin.registerWorkspace(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MpvAudioPlayerPlugin") {
      MpvAudioPlayerPlugin.register(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VideoDecodeCapabilitiesPlugin") {
      VideoDecodeCapabilitiesPlugin.register(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceAdjustmentChannel") {
      registerDeviceAdjustmentChannel(messenger: registrar.messenger())
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppIconPlugin") {
      AppIconPlugin.register(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeepLinkPlugin") {
      DeepLinkPlugin.register(with: registrar)
    }

    if #available(iOS 15.0, *),
       let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppleMusicKitPlugin") {
      AppleMusicKitPlugin.register(with: registrar)
    }
  }

  private func registerDeviceAdjustmentChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.plezy/device_adjustment", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      DispatchQueue.main.async {
        self?.handleDeviceAdjustmentCall(call, result: result)
      }
    }
    deviceAdjustmentChannel = channel
  }

  private func handleDeviceAdjustmentCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getBrightness":
      result(Double(UIScreen.main.brightness))
    case "setBrightness":
      guard let value = normalizedArgument(call.arguments, result: result) else { return }
      if originalBrightness == nil {
        originalBrightness = UIScreen.main.brightness
      }
      UIScreen.main.brightness = CGFloat(value)
      result(nil)
    case "restoreBrightness":
      if let originalBrightness = originalBrightness {
        UIScreen.main.brightness = originalBrightness
        self.originalBrightness = nil
      }
      result(nil)
    case "getMediaVolume":
      result(Double(AVAudioSession.sharedInstance().outputVolume))
    case "setMediaVolume":
      guard let value = normalizedArgument(call.arguments, result: result) else { return }
      if setMediaVolume(value) {
        result(nil)
      } else {
        result(
          FlutterError(code: "DEVICE_ADJUSTMENT_UNAVAILABLE", message: "System volume slider unavailable", details: nil)
        )
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func normalizedArgument(_ arguments: Any?, result: @escaping FlutterResult) -> Double? {
    guard let value = arguments as? NSNumber else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a numeric value", details: nil))
      return nil
    }
    let doubleValue = value.doubleValue
    guard doubleValue.isFinite else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a finite numeric value", details: nil))
      return nil
    }
    return min(1.0, max(0.0, doubleValue))
  }

  private func setMediaVolume(_ value: Double) -> Bool {
    guard let slider = ensureVolumeSlider() else { return false }
    slider.setValue(Float(value), animated: false)
    slider.sendActions(for: .valueChanged)
    slider.sendActions(for: .touchUpInside)
    return true
  }

  private func ensureVolumeSlider() -> UISlider? {
    if let volumeSlider = volumeSlider { return volumeSlider }

    let volumeView = self.volumeView ?? MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
    volumeView.showsRouteButton = false
    volumeView.showsVolumeSlider = true
    volumeView.alpha = 0.01
    volumeView.isUserInteractionEnabled = false

    if volumeView.superview == nil {
      activeWindow?.addSubview(volumeView)
    }
    volumeView.layoutIfNeeded()

    self.volumeView = volumeView
    let slider = findVolumeSlider(in: volumeView)
    volumeSlider = slider
    return slider
  }

  private func findVolumeSlider(in view: UIView) -> UISlider? {
    if let slider = view as? UISlider { return slider }
    for subview in view.subviews {
      if let slider = findVolumeSlider(in: subview) { return slider }
    }
    return nil
  }

  private var activeWindow: UIWindow? {
    if #available(iOS 13.0, *) {
      for scene in UIApplication.shared.connectedScenes {
        guard let windowScene = scene as? UIWindowScene else { continue }
        if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
          return keyWindow
        }
      }
      for scene in UIApplication.shared.connectedScenes {
        guard let windowScene = scene as? UIWindowScene, let window = windowScene.windows.first else { continue }
        return window
      }
      return nil
    }

    return UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first
  }
}


/// Narrow iOS MusicKit pilot. Apple remains the catalog and playback owner;
/// PlezyNG receives catalog metadata and never receives protected media bytes.
@available(iOS 15.0, *)
final class AppleMusicKitPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.plezy/apple_music_kit",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(AppleMusicKitPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task { @MainActor in
      await handleMusicKitCall(call, result: result)
    }
  }

  @MainActor
  private func handleMusicKitCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) async {
    switch call.method {
    case "requestAuthorization":
      let status = await MusicAuthorization.request()
      result(status == .authorized ? "authorized" : "denied")
    case "search":
      guard MusicAuthorization.currentStatus == .authorized,
            let arguments = call.arguments as? [String: Any],
            let query = arguments["query"] as? String,
            !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            query.count <= 160 else {
        result(FlutterError(code: "INVALID_OR_UNAUTHORIZED", message: "A granted MusicKit session and search query are required.", details: nil))
        return
      }
      do {
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = 20
        let response = try await request.response()
        result(response.songs.map { song in
          [
            "id": song.id.rawValue,
            "title": song.title,
            "artist": song.artistName,
            "album": song.albumTitle ?? ""
          ] as [String: Any]
        })
      } catch {
        result(FlutterError(code: "CATALOG_UNAVAILABLE", message: "Apple Music catalog search failed.", details: nil))
      }
    case "canPlayCatalogContent":
      guard MusicAuthorization.currentStatus == .authorized else {
        result(false)
        return
      }
      do {
        let subscription = try await MusicSubscription.current
        result(subscription.canPlayCatalogContent)
      } catch {
        result(FlutterError(code: "SUBSCRIPTION_UNAVAILABLE", message: "Apple Music subscription status is unavailable.", details: nil))
      }
    case "play":
      guard MusicAuthorization.currentStatus == .authorized,
            let arguments = call.arguments as? [String: Any],
            let songID = arguments["id"] as? String,
            !songID.isEmpty,
            songID.count <= 128 else {
        result(FlutterError(code: "INVALID_OR_UNAUTHORIZED", message: "A granted MusicKit session and song id are required.", details: nil))
        return
      }
      do {
        let subscription = try await MusicSubscription.current
        guard subscription.canPlayCatalogContent else {
          result(FlutterError(code: "SUBSCRIPTION_REQUIRED", message: "An Apple Music subscription is required for catalog playback.", details: nil))
          return
        }
        let request = MusicCatalogResourceRequest<Song>(
          matching: \.id,
          equalTo: MusicItemID(songID)
        )
        let response = try await request.response()
        guard let song = response.items.first else {
          result(FlutterError(code: "SONG_NOT_FOUND", message: "The selected Apple Music item is no longer available.", details: nil))
          return
        }
        let player = ApplicationMusicPlayer.shared
        player.queue = .init(for: [song])
        try await player.play()
        result(nil)
      } catch {
        result(FlutterError(code: "PLAYBACK_UNAVAILABLE", message: "Apple Music could not start playback.", details: nil))
      }
    case "stop":
      ApplicationMusicPlayer.shared.stop()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
