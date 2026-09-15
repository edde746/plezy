import Flutter
import UIKit
import AVFoundation
import universal_gamepad
import os_media_controls
import wakelock_plus

@objc class PlezyFlutterViewController: FlutterViewController {
  private lazy var tvRemoteChannel = FlutterBasicMessageChannel(
    name: "flutter/gamepadtouchevent",
    binaryMessenger: binaryMessenger,
    codec: FlutterJSONMessageCodec.sharedInstance()
  )

  override var canBecomeFirstResponder: Bool {
    true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    resignFirstResponder()
    super.viewWillDisappear(animated)
  }

  override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    if handlePlayPausePress(presses) {
      return
    }

    super.pressesBegan(presses, with: event)
  }

  override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    if containsPlayPausePress(presses) {
      return
    }

    super.pressesEnded(presses, with: event)
  }

  override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    if containsPlayPausePress(presses) {
      return
    }

    super.pressesCancelled(presses, with: event)
  }

  override func remoteControlReceived(with event: UIEvent?) {
    guard let event = event else {
      super.remoteControlReceived(with: event)
      return
    }

    let subtype = event.subtype
    print("PlezyTvRemote: remote control event subtype=\(remoteControlSubtypeName(subtype))")
    switch subtype {
    case .remoteControlPlay, .remoteControlPause, .remoteControlTogglePlayPause:
      sendPlayPauseEvent(source: "remote_control", detail: remoteControlSubtypeName(subtype))
    default:
      super.remoteControlReceived(with: event)
    }
  }

  private func handlePlayPausePress(_ presses: Set<UIPress>) -> Bool {
    guard containsPlayPausePress(presses) else { return false }

    sendPlayPauseEvent(source: "presses", detail: "playPause")
    return true
  }

  private func containsPlayPausePress(_ presses: Set<UIPress>) -> Bool {
    presses.contains { press in
      press.type == .playPause
    }
  }

  private func sendPlayPauseEvent(source: String, detail: String) {
    print("PlezyTvRemote: intercepted play/pause source=\(source) detail=\(detail)")
    tvRemoteChannel.sendMessage(["type": "play_pause", "source": source, "detail": detail])
  }

  private func remoteControlSubtypeName(_ subtype: UIEvent.EventSubtype) -> String {
    switch subtype {
    case .remoteControlPlay:
      return "remoteControlPlay"
    case .remoteControlPause:
      return "remoteControlPause"
    case .remoteControlTogglePlayPause:
      return "remoteControlTogglePlayPause"
    case .remoteControlStop:
      return "remoteControlStop"
    case .remoteControlNextTrack:
      return "remoteControlNextTrack"
    case .remoteControlPreviousTrack:
      return "remoteControlPreviousTrack"
    case .remoteControlBeginSeekingForward:
      return "remoteControlBeginSeekingForward"
    case .remoteControlEndSeekingForward:
      return "remoteControlEndSeekingForward"
    case .remoteControlBeginSeekingBackward:
      return "remoteControlBeginSeekingBackward"
    case .remoteControlEndSeekingBackward:
      return "remoteControlEndSeekingBackward"
    default:
      return "unknown(\(subtype.rawValue))"
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure the long-form profile before playback. The media controls
    // plugin claims the session when playback actually starts.
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playback, mode: .default, policy: .longFormAudio, options: [])
    } catch {
      print("Failed to configure long-form audio session: \(error)")
      do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      } catch {
        print("Failed to configure audio session: \(error)")
      }
    }

    application.beginReceivingRemoteControlEvents()

    if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
      _ = SystemShelfPlugin.handleOpenURL(url)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene creates the storyboard's Flutter engine after application launch.
  // Register plugins against that engine instead of creating a second one.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let pluginRegistry = engineBridge.pluginRegistry

    if let r = pluginRegistry.registrar(forPlugin: "SharedPreferencesPlugin") {
      SharedPreferencesPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "MpvPlayerPlugin") {
      MpvPlayerPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "MpvAudioPlayerPlugin") {
      MpvAudioPlayerPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "PackageInfoPlusPlugin") {
      PackageInfoPlusPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "PathProviderPlugin") {
      PathProviderPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "GamepadPlugin") {
      GamepadPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "DeviceInfoPlusPlugin") {
      DeviceInfoPlusPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "ConnectivityPlusPlugin") {
      ConnectivityPlusPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "OsMediaControlsPlugin") {
      OsMediaControlsPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "WakelockPlusPlugin") {
      WakelockPlusPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "SystemShelfPlugin") {
      SystemShelfPlugin.register(with: r)
    }
    if let r = pluginRegistry.registrar(forPlugin: "VideoDecodeCapabilitiesPlugin") {
      VideoDecodeCapabilitiesPlugin.register(with: r)
    }
  }

  override func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if SystemShelfPlugin.handleOpenURL(url) {
      return true
    }
    return super.application(application, open: url, options: options)
  }
}
