import Cocoa
import FlutterMacOS

// Custom overlay view for PiP controls with mouse tracking
class PipOverlayView: NSView {
  var onMouseEntered: (() -> Void)?
  var onMouseExited: (() -> Void)?

  override func updateTrackingAreas() {
    super.updateTrackingAreas()

    for trackingArea in trackingAreas {
      removeTrackingArea(trackingArea)
    }

    let trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea)
  }

  override func mouseEntered(with event: NSEvent) {
    onMouseEntered?()
  }

  override func mouseExited(with event: NSEvent) {
    onMouseExited?()
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  private var pipChannel: FlutterMethodChannel?
  private var isPipActive = false
  private var originalWindowFrame: NSRect?
  private var originalWindowLevel: NSWindow.Level?
  private var originalStyleMask: NSWindow.StyleMask?
  private var originalTitleVisibility: NSWindow.TitleVisibility?
  private var originalTitlebarTransparent: Bool?
  private var originalCollectionBehavior: NSWindow.CollectionBehavior?
  private var pipOverlayView: NSView?
  private var playPauseButton: NSButton?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Force window to normal size if it was saved in PiP mode
    if let window = mainFlutterWindow {
      let frame = window.frame
      // If window is too small (likely saved while in PiP), resize it
      if frame.width < 800 || frame.height < 600 {
        let screen = window.screen ?? NSScreen.main
        if let screenFrame = screen?.visibleFrame {
          let newWidth: CGFloat = 1200
          let newHeight: CGFloat = 800
          let newX = screenFrame.midX - newWidth / 2
          let newY = screenFrame.midY - newHeight / 2
          window.setFrame(NSRect(x: newX, y: newY, width: newWidth, height: newHeight), display: true, animate: false)
        }
      }
    }

    // Setup PiP channel
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      setupPipChannel(controller: controller)
    }

    // Monitor window close events to exit PiP before closing
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowWillClose(_:)),
      name: NSWindow.willCloseNotification,
      object: mainFlutterWindow
    )
  }

  @objc private func windowWillClose(_ notification: Notification) {
    // Exit PiP mode before window closes to ensure proper state restoration
    if isPipActive {
      exitPictureInPicture()
      // Give the window a moment to update before state is saved
      DispatchQueue.main.async {
        self.clearSavedState()
      }
    }
  }

  private func clearSavedState() {
    // Clear any saved state to prevent PiP size from persisting
    let bundleID = Bundle.main.bundleIdentifier ?? "com.edde.plezy"
    let savedStateURL = FileManager.default.urls(
      for: .libraryDirectory,
      in: .userDomainMask
    ).first?.appendingPathComponent("Saved Application State/\(bundleID).savedState")

    if let url = savedStateURL {
      try? FileManager.default.removeItem(at: url)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    // Exit PiP mode before terminating to ensure window size is restored
    if isPipActive {
      exitPictureInPicture()
    }
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    // Ensure window is not in PiP mode when reopening
    if isPipActive {
      exitPictureInPicture()
    }
    return true
  }

  private func setupPipChannel(controller: FlutterViewController) {
    pipChannel = FlutterMethodChannel(
      name: "app.plezy/pip",
      binaryMessenger: controller.engine.binaryMessenger
    )

    pipChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "isSupported":
        // Always supported on macOS via floating window
        result(true)

      case "enter":
        self?.enterPictureInPicture(arguments: call.arguments, result: result)

      case "updatePlayPauseIcon":
        if let isPlaying = call.arguments as? Bool {
          self?.updatePlayPauseIcon(isPlaying: isPlaying)
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func enterPictureInPicture(arguments: Any?, result: @escaping FlutterResult) {
    guard let window = mainFlutterWindow else {
      result(FlutterError(code: "NO_WINDOW", message: "Main window not found", details: nil))
      return
    }

    if isPipActive {
      // Exit PiP mode
      exitPictureInPicture()
      notifyPipStateChanged(false)
      result(nil)
      return
    }

    // Save original state
    originalWindowFrame = window.frame
    originalWindowLevel = window.level
    originalStyleMask = window.styleMask
    originalTitleVisibility = window.titleVisibility
    originalTitlebarTransparent = window.titlebarAppearsTransparent
    originalCollectionBehavior = window.collectionBehavior

    // Get video dimensions and playing state from arguments
    let width = 480.0
    var height = 270.0
    var isPlaying = true  // Default to playing

    if let args = arguments as? [String: Any] {
      if let w = args["width"] as? Int, let h = args["height"] as? Int, w > 0, h > 0 {
        // Calculate proportional size (max width 480)
        let aspectRatio = Double(h) / Double(w)
        height = width * aspectRatio
      }
      if let playing = args["isPlaying"] as? Bool {
        isPlaying = playing
      }
    }

    // Position in bottom-right corner
    if let screen = window.screen ?? NSScreen.main {
      let screenFrame = screen.visibleFrame
      let pipFrame = NSRect(
        x: screenFrame.maxX - width - 20,
        y: screenFrame.minY + 20,
        width: width,
        height: height
      )

      window.setFrame(pipFrame, display: true, animate: true)
    }

    // Make window float on top with borderless style for cleaner PiP look
    window.styleMask = [.borderless, .resizable]
    window.level = .floating
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true

    // Prevent saving PiP window state
    window.isRestorable = false

    // Add PiP overlay controls
    setupPipOverlay(in: window, isPlaying: isPlaying)

    isPipActive = true
    notifyPipStateChanged(true)
    result(nil)
  }

  private func setupPipOverlay(in window: NSWindow, isPlaying: Bool) {
    guard let contentView = window.contentView else { return }

    // Create custom overlay view with mouse tracking
    let overlay = PipOverlayView(frame: contentView.bounds)
    overlay.autoresizingMask = [.width, .height]
    overlay.wantsLayer = true
    overlay.layer?.backgroundColor = NSColor.clear.cgColor
    overlay.alphaValue = 0 // Hidden by default

    // Set up mouse tracking callbacks
    overlay.onMouseEntered = { [weak self, weak overlay] in
      guard let self = self, let overlay = overlay else { return }
      if self.isPipActive {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.2
          overlay.animator().alphaValue = 1.0
        }
      }
    }

    overlay.onMouseExited = { [weak self, weak overlay] in
      guard let self = self, let overlay = overlay else { return }
      if self.isPipActive {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.2
          overlay.animator().alphaValue = 0.0
        }
      }
    }

    // Exit PiP button (top-left corner)
    let exitButton = NSButton(frame: NSRect(x: 8, y: overlay.bounds.height - 36, width: 28, height: 28))
    exitButton.bezelStyle = .circular
    exitButton.image = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: "Exit PiP")
    exitButton.target = self
    exitButton.action = #selector(exitPipButtonClicked)
    exitButton.wantsLayer = true
    exitButton.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
    exitButton.layer?.cornerRadius = 14
    exitButton.contentTintColor = .white
    overlay.addSubview(exitButton)

    // Center controls container
    let controlsContainer = NSView()
    controlsContainer.wantsLayer = true
    controlsContainer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
    controlsContainer.layer?.cornerRadius = 8

    // Skip backward button
    let backButton = NSButton(frame: NSRect(x: 8, y: 8, width: 36, height: 36))
    backButton.bezelStyle = .circular
    backButton.image = NSImage(systemSymbolName: "gobackward.15", accessibilityDescription: "Skip back")
    backButton.target = self
    backButton.action = #selector(skipBackward)
    backButton.isBordered = false
    backButton.contentTintColor = .white
    controlsContainer.addSubview(backButton)

    // Play/Pause button - set initial icon based on playing state
    let playPauseButton = NSButton(frame: NSRect(x: 52, y: 8, width: 36, height: 36))
    playPauseButton.bezelStyle = .circular
    if isPlaying {
      playPauseButton.image = NSImage(systemSymbolName: "pause.fill", accessibilityDescription: "Pause")
    } else {
      playPauseButton.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Play")
    }
    playPauseButton.target = self
    playPauseButton.action = #selector(togglePlayPause)
    playPauseButton.isBordered = false
    playPauseButton.contentTintColor = .white
    controlsContainer.addSubview(playPauseButton)
    self.playPauseButton = playPauseButton

    // Skip forward button
    let forwardButton = NSButton(frame: NSRect(x: 96, y: 8, width: 36, height: 36))
    forwardButton.bezelStyle = .circular
    forwardButton.image = NSImage(systemSymbolName: "goforward.15", accessibilityDescription: "Skip forward")
    forwardButton.target = self
    forwardButton.action = #selector(skipForward)
    forwardButton.isBordered = false
    forwardButton.contentTintColor = .white
    controlsContainer.addSubview(forwardButton)

    // Size and position controls container
    controlsContainer.frame = NSRect(x: 0, y: 0, width: 140, height: 52)
    controlsContainer.frame.origin = CGPoint(
      x: (overlay.bounds.width - 140) / 2,
      y: (overlay.bounds.height - 52) / 2
    )
    controlsContainer.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
    overlay.addSubview(controlsContainer)

    contentView.addSubview(overlay)
    pipOverlayView = overlay
  }

  @objc private func exitPipButtonClicked() {
    exitPictureInPicture()
    notifyPipStateChanged(false)
  }

  @objc private func togglePlayPause() {
    pipChannel?.invokeMethod("playPause", arguments: nil)
  }

  @objc private func skipBackward() {
    pipChannel?.invokeMethod("seek", arguments: -15)
  }

  @objc private func skipForward() {
    pipChannel?.invokeMethod("seek", arguments: 15)
  }

  private func updatePlayPauseIcon(isPlaying: Bool) {
    DispatchQueue.main.async { [weak self] in
      if isPlaying {
        self?.playPauseButton?.image = NSImage(systemSymbolName: "pause.fill", accessibilityDescription: "Pause")
      } else {
        self?.playPauseButton?.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Play")
      }
    }
  }

  private func exitPictureInPicture() {
    guard let window = mainFlutterWindow else { return }

    // Remove overlay
    pipOverlayView?.removeFromSuperview()
    pipOverlayView = nil
    playPauseButton = nil

    // Restore original window state (without animation to prevent lag)
    if let originalFrame = originalWindowFrame {
      window.setFrame(originalFrame, display: true, animate: false)
    }

    if let originalLevel = originalWindowLevel {
      window.level = originalLevel
    }

    if let originalStyle = originalStyleMask {
      window.styleMask = originalStyle
    }

    if let originalTitleVis = originalTitleVisibility {
      window.titleVisibility = originalTitleVis
    }

    if let originalTransparent = originalTitlebarTransparent {
      window.titlebarAppearsTransparent = originalTransparent
    }

    if let originalBehavior = originalCollectionBehavior {
      window.collectionBehavior = originalBehavior
    }

    // Re-enable window state restoration
    window.isRestorable = true

    isPipActive = false
    originalWindowFrame = nil
    originalWindowLevel = nil
    originalStyleMask = nil
    originalTitleVisibility = nil
    originalTitlebarTransparent = nil
    originalCollectionBehavior = nil
  }

  private func notifyPipStateChanged(_ isActive: Bool) {
    pipChannel?.invokeMethod("onPipChanged", arguments: isActive)
  }
}
