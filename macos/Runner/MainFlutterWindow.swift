import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let project = FlutterDartProject()
    project.dartEntrypointArguments = Array(CommandLine.arguments.dropFirst())
    let flutterViewController = FlutterViewController(project: project)
    let preparationWorker = CommandLine.arguments.contains("--plezy-preparation-worker")
    if preparationWorker {
      NSApp.setActivationPolicy(.prohibited)
      self.orderOut(nil)
      RegisterGeneratedPlugins(registry: flutterViewController)
      self.contentViewController = flutterViewController
      return
    }

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

    MpvPlayerPlugin.registerWorkspace(
      with: flutterViewController.registrar(forPlugin: "MpvWorkspacePlayerPlugin"))

    MpvAudioPlayerPlugin.register(
      with: flutterViewController.registrar(forPlugin: "MpvAudioPlayerPlugin"))

    WindowUtilsPlugin.register(
      with: flutterViewController.registrar(forPlugin: "WindowUtilsPlugin"))
    WindowUtilsPlugin.setWindow(self)
    WindowUtilsPlugin.installWindowDelegate()
    WindowUtilsPlugin.syncWindowChrome()

    AppLookupPlugin.register(
      with: flutterViewController.registrar(forPlugin: "AppLookupPlugin"))

    DeepLinkPlugin.register(
      with: flutterViewController.registrar(forPlugin: "DeepLinkPlugin"))

    RegisterGeneratedPlugins(registry: flutterViewController)

    self.setFrameAutosaveName("org.snapetech.plezyng.MainWindow")
    WindowUtilsPlugin.syncWindowChrome()

    super.awakeFromNib()
  }
}
