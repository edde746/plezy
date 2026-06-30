import Cocoa
import FlutterMacOS

// MARK: - ForwardingView
// A view that forwards mouse events to the Flutter view controller
class ForwardingView: NSView {
  weak var flutterViewController: NSViewController?

  override func mouseDown(with event: NSEvent) {
    flutterViewController?.mouseDown(with: event)
  }

  override func mouseUp(with event: NSEvent) {
    flutterViewController?.mouseUp(with: event)
  }
}

// MARK: - ForwardingToolbar
// A custom toolbar that forwards mouse events from the toolbar area to Flutter
class ForwardingToolbar: NSToolbar, NSToolbarDelegate {
  let flutterViewController: NSViewController

  init(flutterViewController: NSViewController) {
    self.flutterViewController = flutterViewController
    super.init(identifier: "ForwardingToolbar")
    self.delegate = self
    self.showsBaselineSeparator = false

    // Prevent toolbar customization UI (the "rounded box")
    self.allowsUserCustomization = false
    self.allowsExtensionItems = false
    if #available(macOS 15.0, *) {
      self.allowsDisplayModeCustomization = false
    }
  }

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [.flexibleSpace, NSToolbarItem.Identifier("ForwardingItem")]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }

  func toolbar(
    _ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    if itemIdentifier == NSToolbarItem.Identifier("ForwardingItem") {
      let item = NSToolbarItem(itemIdentifier: itemIdentifier)
      item.isBordered = false  // Remove the rounded box appearance
      let view = ForwardingView()
      view.flutterViewController = flutterViewController
      view.widthAnchor.constraint(lessThanOrEqualToConstant: 100000).isActive = true
      view.widthAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
      item.view = view
      return item
    }
    return nil
  }
}

// MARK: - WindowUtilsPlugin
class WindowUtilsPlugin: NSObject, FlutterPlugin {
  private static var instance: WindowUtilsPlugin?
  private var channel: FlutterMethodChannel?
  private weak var window: NSWindow?
  private var windowDelegate: WindowDelegate?
  private var originalButtonConstraints: [NSWindow.ButtonType: [NSLayoutConstraint]] = [:]

  // Centralized traffic light positions - the single source of truth
  private static let customButtonPositions: [(NSWindow.ButtonType, CGPoint)] = [
    (.closeButton, CGPoint(x: 20, y: 21)),
    (.miniaturizeButton, CGPoint(x: 40, y: 21)),
    (.zoomButton, CGPoint(x: 60, y: 21)),
  ]

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.plezy/window_utils",
      binaryMessenger: registrar.messenger
    )
    let instance = WindowUtilsPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    self.instance = instance
  }

  static func setWindow(_ window: NSWindow) {
    instance?.window = window
    instance?.windowDelegate?.window = window
  }

  static func installWindowDelegate() {
    guard let instance = instance, let window = instance.window else { return }
    instance.installWindowDelegate(window: window)
  }

  static func syncWindowChrome() {
    guard let instance = instance else { return }
    instance.syncWindowChrome()
  }

  /// Apply traffic light positions. Called by WindowDelegate during fullscreen transitions.
  static func setTrafficLightPositions(custom: Bool, window: NSWindow) {
    guard let instance = instance else { return }
    instance.applyTrafficLightPositions(custom: custom, window: window)
  }

  static func setTrafficLightsVisible(_ visible: Bool, window: NSWindow) {
    for buttonType in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
      window.standardWindowButton(buttonType)?.isHidden = !visible
    }
  }

  private func applyTrafficLightPositions(custom: Bool, window: NSWindow) {
    if custom {
      for (buttonType, offset) in WindowUtilsPlugin.customButtonPositions {
        overrideButtonPosition(window: window, buttonType: buttonType, offset: offset)
      }
    } else {
      for (buttonType, _) in WindowUtilsPlugin.customButtonPositions {
        resetButtonPosition(window: window, buttonType: buttonType)
      }
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let window = window else {
      result(FlutterError(code: "NO_WINDOW", message: "Window not available", details: nil))
      return
    }

    switch call.method {
    case "initialize":
      let args = call.arguments as? [String: Any]
      let enableWindowDelegate = args?["enableWindowDelegate"] as? Bool ?? false
      initialize(window: window, enableWindowDelegate: enableWindowDelegate)
      result(nil)

    case "setTrafficLightsVisible":
      let args = call.arguments as? [String: Any]
      let visible = args?["visible"] as? Bool ?? true
      WindowUtilsPlugin.setTrafficLightsVisible(visible, window: window)
      result(nil)

    case "syncWindowChrome":
      syncWindowChrome()
      result(nil)

    case "enterFullscreen":
      if !window.styleMask.contains(.fullScreen) {
        window.toggleFullScreen(nil)
      }
      result(nil)

    case "exitFullscreen":
      if window.styleMask.contains(.fullScreen) {
        window.toggleFullScreen(nil)
      }
      result(nil)

    case "isFullscreen":
      result(window.styleMask.contains(.fullScreen))

    case "setImpellerEnabled":
      let args = call.arguments as? [String: Any]
      let enabled = args?["enabled"] as? Bool ?? true
      Self.updateImpellerPlist(enabled: enabled)
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func initialize(window: NSWindow, enableWindowDelegate: Bool) {
    self.window = window

    if enableWindowDelegate {
      installWindowDelegate(window: window)
    }

    windowDelegate?.syncWindowChrome()
  }

  private func installWindowDelegate(window: NSWindow) {
    let delegate = windowDelegate ?? WindowDelegate()
    delegate.channel = channel
    delegate.window = window
    windowDelegate = delegate
    window.delegate = delegate
  }

  private func syncWindowChrome() {
    guard let window = window else { return }
    if windowDelegate == nil {
      installWindowDelegate(window: window)
    } else {
      windowDelegate?.channel = channel
      windowDelegate?.window = window
      window.delegate = windowDelegate
    }
    windowDelegate?.syncWindowChrome()
  }

  private func withButton(
    _ buttonType: NSWindow.ButtonType,
    in window: NSWindow,
    action: (NSButton, NSView) -> Void
  ) {
    guard let button = window.standardWindowButton(buttonType),
      let superview = button.superview
    else { return }
    action(button, superview)
  }

  private func positionConstraints(for button: NSButton, in superview: NSView)
    -> [NSLayoutConstraint]
  {
    superview.constraints.filter { constraint in
      ((constraint.firstItem as? NSButton) == button
        || (constraint.secondItem as? NSButton) == button)
        && (constraint.firstAttribute == .left || constraint.firstAttribute == .leading
          || constraint.firstAttribute == .top || constraint.firstAttribute == .centerY)
    }
  }

  private func overrideButtonPosition(
    window: NSWindow, buttonType: NSWindow.ButtonType, offset: CGPoint
  ) {
    withButton(buttonType, in: window) { button, superview in
      // Store original constraints if not already stored
      if originalButtonConstraints[buttonType] == nil {
        let constraints = superview.constraints.filter { constraint in
          (constraint.firstItem as? NSButton) == button
            || (constraint.secondItem as? NSButton) == button
        }
        originalButtonConstraints[buttonType] = constraints
      }

      // Remove existing position constraints
      superview.removeConstraints(positionConstraints(for: button, in: superview))

      button.translatesAutoresizingMaskIntoConstraints = false

      // Add new positioning constraints
      superview.addConstraints([
        button.leftAnchor.constraint(equalTo: superview.leftAnchor, constant: offset.x),
        button.topAnchor.constraint(equalTo: superview.topAnchor, constant: offset.y),
      ])
      superview.layoutSubtreeIfNeeded()
    }
  }

  private func resetButtonPosition(window: NSWindow, buttonType: NSWindow.ButtonType) {
    withButton(buttonType, in: window) { button, superview in
      // Remove custom constraints
      superview.removeConstraints(positionConstraints(for: button, in: superview))

      // Restore original constraints if we have them
      if let originalConstraints = originalButtonConstraints[buttonType] {
        superview.addConstraints(originalConstraints)
        originalButtonConstraints.removeValue(forKey: buttonType)
      }

      button.translatesAutoresizingMaskIntoConstraints = true
      superview.layoutSubtreeIfNeeded()
    }
  }

  /// Updates FLTEnableImpeller in the app bundle's Info.plist on disk.
  /// Takes effect on the next app launch.
  static func updateImpellerPlist(enabled: Bool) {
    let plistURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Info.plist")
    guard let dict = NSMutableDictionary(contentsOf: plistURL) else { return }
    if enabled {
      dict.removeObject(forKey: "FLTEnableImpeller")
    } else {
      dict["FLTEnableImpeller"] = false
    }
    dict.write(to: plistURL, atomically: true)
  }
}
