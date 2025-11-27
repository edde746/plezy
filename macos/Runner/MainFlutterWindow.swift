import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // Enable transparency for Metal layer behind Flutter
    self.backgroundColor = NSColor.clear
    flutterViewController.backgroundColor = NSColor.clear

    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Register MPV player plugin for video playback
    MpvPlayerPlugin.register(with: flutterViewController.registrar(forPlugin: "MpvPlayerPlugin"))

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
