import Flutter
import UIKit
import AVFoundation
import universal_gamepad
import os_media_controls
import wakelock_plus

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
    } catch {
      print("Failed to configure audio session: \(error)")
    }

    application.beginReceivingRemoteControlEvents()

    if let r = self.registrar(forPlugin: "SharedPreferencesPlugin") {
      SharedPreferencesPlugin.register(with: r)
    }
    if let r = self.registrar(forPlugin: "MpvPlayerPlugin") {
      MpvPlayerPlugin.register(with: r)
    }
    if let r = self.registrar(forPlugin: "PackageInfoPlusPlugin") {
      PackageInfoPlusPlugin.register(with: r)
    }
    if let r = self.registrar(forPlugin: "PathProviderPlugin") {
      PathProviderPlugin.register(with: r)
    }
    if let r = self.registrar(forPlugin: "GamepadPlugin") {
      GamepadPlugin.register(with: r)
    }
    if let r = self.registrar(forPlugin: "DeviceInfoPlusPlugin") {
      DeviceInfoPlusPlugin.register(with: r)
    }
    if let r = self.registrar(forPlugin: "ConnectivityPlusPlugin") {
      ConnectivityPlusPlugin.register(with: r)
    }
    if let r = self.registrar(forPlugin: "OsMediaControlsPlugin") {
      OsMediaControlsPlugin.register(with: r)
    }
    if let r = self.registrar(forPlugin: "WakelockPlusPlugin") {
      WakelockPlusPlugin.register(with: r)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
