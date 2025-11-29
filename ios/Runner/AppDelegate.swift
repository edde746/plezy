import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register MPV player plugin
    if let registrar = self.registrar(forPlugin: "MpvPlayerPlugin") {
      MpvPlayerPlugin.register(with: registrar)
    }

    // Configure audio session for media playback
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
    } catch {
      print("Failed to configure audio session: \(error)")
    }

    application.beginReceivingRemoteControlEvents()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
