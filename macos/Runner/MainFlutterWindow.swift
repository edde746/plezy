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

    // Apply initial window configuration BEFORE frame restoration
    // This prevents the window from shrinking on launch
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)

    // Add forwarding toolbar for click-through in titlebar area
    let toolbar = ForwardingToolbar(flutterViewController: flutterViewController)
    self.toolbar = toolbar

    // Register MPV player plugin for video playback
    MpvPlayerPlugin.register(with: flutterViewController.registrar(forPlugin: "MpvPlayerPlugin"))

    // Register window utils plugin for dynamic titlebar/fullscreen control from Dart
    WindowUtilsPlugin.register(with: flutterViewController.registrar(forPlugin: "WindowUtilsPlugin"))
    WindowUtilsPlugin.setWindow(self)

    // Set custom traffic light positions using centralized values from plugin
    WindowUtilsPlugin.setInitialTrafficLightPositions()

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Enable window position/size persistence
    self.setFrameAutosaveName("com.edde746.plezy.MainWindow")

    super.awakeFromNib()
  }
}
