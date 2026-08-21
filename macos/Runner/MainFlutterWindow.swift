import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // Keep the window itself opaque so WindowServer does not have to blend the
    // whole video window with the desktop every frame. Flutter stays clear so
    // the native video layer behind it remains visible.
    self.isOpaque = true
    self.backgroundColor = NSColor.black
    flutterViewController.backgroundColor = NSColor.clear

    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Configure window chrome before restoring the saved frame.
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)

    // Add forwarding toolbar for click-through in titlebar area
    let toolbar = ForwardingToolbar(flutterViewController: flutterViewController)
    self.toolbar = toolbar

    MpvPlayerPlugin.register(
      with: flutterViewController.registrar(forPlugin: "MpvPlayerPlugin"))

    MpvAudioPlayerPlugin.register(
      with: flutterViewController.registrar(forPlugin: "MpvAudioPlayerPlugin"))

    WindowUtilsPlugin.register(
      with: flutterViewController.registrar(forPlugin: "WindowUtilsPlugin"))
    WindowUtilsPlugin.setWindow(self)
    WindowUtilsPlugin.installWindowDelegate()
    WindowUtilsPlugin.syncWindowChrome()

    AppLookupPlugin.register(
      with: flutterViewController.registrar(forPlugin: "AppLookupPlugin"))

    RegisterGeneratedPlugins(registry: flutterViewController)

    self.setFrameAutosaveName("com.edde746.plezy.MainWindow")
    WindowUtilsPlugin.syncWindowChrome()

    super.awakeFromNib()
  }
}
