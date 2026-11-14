import Flutter
import UIKit
import AVFoundation
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var deviceAdjustmentChannel: FlutterMethodChannel?
  private var backupExclusionChannel: FlutterMethodChannel?
  /// The screen whose brightness the player changed, and the level to restore
  /// on it. Tracked per screen because iPhone Duo moves the app between its
  /// outer and inner displays when folded or unfolded (#2861).
  private var brightnessOverride: (screen: UIScreen, original: CGFloat)?
  private var volumeView: MPVolumeView?

  /// Observes the system output volume so the hardware buttons can drive a
  /// speaker in another room.
  ///
  /// iOS gives an app no direct key events for the volume buttons — the only
  /// supported signal is that `outputVolume` changed. While a remote output is
  /// selected the Dart side pins the system volume mid-scale, so a press in
  /// either direction produces a delta it can forward and then undo, and the
  /// handset's own level never drifts.
  private var volumeObservation: NSKeyValueObservation?
  private var volumeWatchActive = false
  private weak var volumeSlider: UISlider?

  /// Loops silence while a speaker in another room plays, so iOS treats this
  /// app as the one playing: only that app gets AirPods and lock-screen
  /// commands, and only it keeps running in the background to read the volume
  /// buttons. Samples are zero, so nothing is heard on the phone.
  private var keepAlivePlayer: AVAudioPlayer?
  private var keepAliveInterruptionObserver: NSObjectProtocol?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure the non-mixing session; activate it only for playback: a video
    // player core claims it as it is created (MpvAudioSessionActivation), mpv's
    // audio output otherwise.
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

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MpvAudioPlayerPlugin") {
      MpvAudioPlayerPlugin.register(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VideoDecodeCapabilitiesPlugin") {
      VideoDecodeCapabilitiesPlugin.register(with: registrar)
    }

    // Reports the system audio route and vends AVRoutePickerView, so the music
    // output picker can offer AirPlay as a destination distinct from both the
    // phone's own speaker and a Music Assistant player.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AudioRoutePlugin") {
      AudioRoutePlugin.register(with: registrar)
    }

    // Bonjour via mDNSResponder. A raw multicast socket — what the Dart mDNS
    // package uses — receives nothing on a device without an entitlement Apple
    // grants only on request, and fails silently when it is absent.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BonjourDiscoveryPlugin") {
      BonjourDiscoveryPlugin.register(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceAdjustmentChannel") {
      registerDeviceAdjustmentChannel(messenger: registrar.messenger())
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BackupExclusionChannel") {
      registerBackupExclusionChannel(messenger: registrar.messenger())
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppIconPlugin") {
      AppIconPlugin.register(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeepLinkPlugin") {
      DeepLinkPlugin.register(with: registrar)
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

  /// Marks a directory excluded from iCloud Backup. Downloads live in
  /// `Documents`, which is backed up by default (#2958); a directory's mark
  /// covers everything stored in it later.
  private func registerBackupExclusionChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.plezy/backup_exclusion", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let path = call.arguments as? String, !path.isEmpty else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a directory path", details: nil))
        return
      }
      var url = URL(fileURLWithPath: path, isDirectory: true)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(code: "EXCLUDE_FROM_BACKUP_FAILED", message: error.localizedDescription, details: nil))
      }
    }
    backupExclusionChannel = channel
  }

  private func handleDeviceAdjustmentCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getBrightness":
      result(activeScreen.map { Double($0.brightness) })
    case "setBrightness":
      guard let value = normalizedArgument(call.arguments, result: result) else { return }
      guard let screen = activeScreen else {
        result(FlutterError(code: "DEVICE_ADJUSTMENT_UNAVAILABLE", message: "No active screen", details: nil))
        return
      }
      if let override = brightnessOverride, override.screen !== screen {
        override.screen.brightness = override.original
        brightnessOverride = nil
      }
      if brightnessOverride == nil {
        brightnessOverride = (screen, screen.brightness)
      }
      screen.brightness = CGFloat(value)
      result(nil)
    case "restoreBrightness":
      if let override = brightnessOverride {
        override.screen.brightness = override.original
        brightnessOverride = nil
      }
      result(nil)
    case "startVolumeButtonWatch":
      startVolumeButtonWatch()
      result(nil)
    case "stopVolumeButtonWatch":
      stopVolumeButtonWatch()
      result(nil)
    case "startNowPlayingKeepAlive":
      startNowPlayingKeepAlive()
      result(nil)
    case "stopNowPlayingKeepAlive":
      stopNowPlayingKeepAlive()
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

  private func startVolumeButtonWatch() {
    guard !volumeWatchActive else { return }
    volumeWatchActive = true
    let session = AVAudioSession.sharedInstance()
    try? session.setActive(true)
    volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
      guard let self, let value = change.newValue else { return }
      DispatchQueue.main.async {
        self.deviceAdjustmentChannel?.invokeMethod("onSystemVolumeChanged", arguments: Double(value))
      }
    }
  }

  private func stopVolumeButtonWatch() {
    volumeObservation?.invalidate()
    volumeObservation = nil
    volumeWatchActive = false
  }

  private func startNowPlayingKeepAlive() {
    if keepAlivePlayer == nil {
      guard let player = try? AVAudioPlayer(data: Self.silentWav(seconds: 1)) else { return }
      player.numberOfLoops = -1
      player.prepareToPlay()
      keepAlivePlayer = player
    }
    try? AVAudioSession.sharedInstance().setActive(true)
    keepAlivePlayer?.play()

    // A phone call stops the player; pick the silence back up afterwards or
    // the controls go quiet for the rest of the session.
    if keepAliveInterruptionObserver == nil {
      keepAliveInterruptionObserver = NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: AVAudioSession.sharedInstance(),
        queue: .main
      ) { [weak self] note in
        guard
          let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          AVAudioSession.InterruptionType(rawValue: raw) == .ended,
          let player = self?.keepAlivePlayer
        else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        player.play()
      }
    }
  }

  private func stopNowPlayingKeepAlive() {
    keepAlivePlayer?.stop()
    keepAlivePlayer = nil
    if let observer = keepAliveInterruptionObserver {
      NotificationCenter.default.removeObserver(observer)
      keepAliveInterruptionObserver = nil
    }
  }

  /// A mono 16-bit PCM WAV of zeros.
  private static func silentWav(seconds: Int) -> Data {
    let sampleRate: UInt32 = 8000
    let dataSize = UInt32(seconds) * sampleRate * 2
    var data = Data()
    func append<T: FixedWidthInteger>(_ value: T) {
      withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }
    data.append(contentsOf: Array("RIFF".utf8))
    append(UInt32(36) + dataSize)
    data.append(contentsOf: Array("WAVEfmt ".utf8))
    append(UInt32(16))
    append(UInt16(1))
    append(UInt16(1))
    append(sampleRate)
    append(sampleRate * 2)
    append(UInt16(2))
    append(UInt16(16))
    data.append(contentsOf: Array("data".utf8))
    append(dataSize)
    data.append(Data(count: Int(dataSize)))
    return data
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

  /// The display showing the app. Not `UIScreen.main`: on iPhone Duo that is
  /// the outer display even while the app is on the inner one (#2861).
  private var activeScreen: UIScreen? {
    activeWindow?.windowScene?.screen
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
