import Flutter
import UIKit
import AVFoundation

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

    NSLog("[tvos] AppDelegate didFinishLaunching — registering plugins")

    if let spRegistrar = self.registrar(forPlugin: "SharedPreferencesPlugin") {
      NSLog("[tvos] Registering SharedPreferencesPlugin (Swift-direct)")
      SharedPreferencesPlugin.register(with: spRegistrar)
    } else {
      NSLog("[tvos] SharedPreferencesPlugin registrar nil")
    }

    if let mpvRegistrar = self.registrar(forPlugin: "MpvPlayerPlugin") {
      NSLog("[tvos] Registering MpvPlayerPlugin")
      MpvPlayerPlugin.register(with: mpvRegistrar)
    }

    if let r = self.registrar(forPlugin: "PackageInfoPlusPlugin") {
      NSLog("[tvos] Registering PackageInfoPlusPlugin")
      PackageInfoPlusPlugin.register(with: r)
    }

    if let r = self.registrar(forPlugin: "PathProviderPlugin") {
      NSLog("[tvos] Registering PathProviderPlugin")
      PathProviderPlugin.register(with: r)
    }

    if let r = self.registrar(forPlugin: "GamepadPlugin") {
      NSLog("[tvos] Registering GamepadPlugin")
      GamepadPlugin.register(with: r)
    }

    if let r = self.registrar(forPlugin: "DeviceInfoPlusPlugin") {
      NSLog("[tvos] Registering DeviceInfoPlusPlugin")
      DeviceInfoPlusPlugin.register(with: r)
    }

    if let r = self.registrar(forPlugin: "ConnectivityPlusPlugin") {
      NSLog("[tvos] Registering ConnectivityPlusPlugin")
      ConnectivityPlusPlugin.register(with: r)
    }

    if let r = self.registrar(forPlugin: "OsMediaControlsPlugin") {
      NSLog("[tvos] Registering OsMediaControlsPlugin")
      OsMediaControlsPlugin.register(with: r)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
