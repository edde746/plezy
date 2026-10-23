import AVFoundation
import Cocoa
import QuartzCore

/// Delegate to notify the plugin of PiP lifecycle events
protocol MpvPipDelegate: AnyObject {
  func pipWillStart()
  func pipDidStart()
  /// Called when PiP stops. `restored` is true if the user pressed the close button (restore UI).
  func pipDidStop(restored: Bool)
  /// Forward play/pause commands from PiP overlay to mpv
  func pipSetPlaying(_ playing: Bool)
  /// Query whether mpv is currently playing
  var isPipPlaying: Bool { get }
}

/// Encapsulates macOS Picture-in-Picture using the private PIP.framework (PIPViewController).
///
/// The player lends its display layer and vo_avfoundation's OSD layer to a
/// view in the PiP window, which keeps them at the window's size; mpv keeps
/// rendering into them throughout, so there is no VO switch and subtitles come
/// along. AVKit's sample-buffer PiP is not an option on macOS: it mirrors the
/// display layer into its window at the layer's size in the player, unscaled,
/// so a window smaller than the player shows one corner of the picture.
class MpvPipController: NSObject, PIPViewControllerDelegate {

  // MARK: - Properties

  private lazy var pip: PIPViewController = {
    let vc = PIPViewController()
    vc.delegate = self
    return vc
  }()

  private var pipVideoVC: NSViewController?
  private var pipVideoView: MpvPipVideoView?

  weak var delegate: MpvPipDelegate?
  private(set) var isActive = false
  var autoPipEnabled = false

  // Keep reference to the window for restore animation
  private weak var sourceWindow: NSWindow?

  // MARK: - Public API

  static var isSupported: Bool { true }

  /// Enter PiP by hosting the player's video layers in the PiP window.
  func startPip(layers: [CALayer], window: NSWindow, aspectRatio: NSSize) {
    guard !isActive else { return }

    sourceWindow = window

    let videoView = MpvPipVideoView(layers: layers, size: window.contentView?.bounds.size ?? aspectRatio)
    let vc = NSViewController()
    vc.view = videoView

    pipVideoVC = vc
    pipVideoView = videoView

    pip.playing = delegate?.isPipPlaying ?? false
    pip.aspectRatio = aspectRatio
    pip.replacementWindow = window
    pip.replacementRect = window.contentView?.frame ?? .zero

    delegate?.pipWillStart()

    pip.presentAsPicture(inPicture: vc)
    isActive = true
    delegate?.pipDidStart()
  }

  func stopPip() {
    guard isActive, let pipVideoVC else { return }
    pip.dismiss(pipVideoVC)
  }

  /// Update the play/pause button state in the PiP overlay
  func setPlaying(_ playing: Bool) {
    pip.playing = playing
  }

  /// Update the aspect ratio (e.g., when video track changes)
  func setAspectRatio(_ size: NSSize) {
    pip.aspectRatio = size
  }

  func setAutoStart(_ enabled: Bool) {
    autoPipEnabled = enabled
  }

  /// Clean up after PiP closes: takes the lent layers out of the PiP window's
  /// view and returns them, for the player to take back.
  @discardableResult
  func detachLayers() -> [CALayer] {
    let layers = pipVideoView?.releaseLayers() ?? []
    pipVideoView = nil
    pipVideoVC = nil
    return layers
  }

  // MARK: - PIPViewControllerDelegate

  func pipShouldClose(_ pip: PIPViewController) -> Bool {
    prepareForClose()
    return true
  }

  func pipWillClose(_ pip: PIPViewController) {
    prepareForClose()
  }

  func pipDidClose(_ pip: PIPViewController) {
    isActive = false
    delegate?.pipDidStop(restored: true)
  }

  func pipActionPlay(_ pip: PIPViewController) {
    delegate?.pipSetPlaying(true)
  }

  func pipActionPause(_ pip: PIPViewController) {
    delegate?.pipSetPlaying(false)
  }

  func pipActionStop(_ pip: PIPViewController) {
    delegate?.pipSetPlaying(false)
  }

  // MARK: - Private

  private func prepareForClose() {
    guard let window = sourceWindow else { return }
    pip.replacementWindow = window
    pip.replacementRect = window.contentView?.frame ?? .zero
    // Bring the main window forward for the restore animation
    NSApp.activate(ignoringOtherApps: true)
    window.deminiaturize(nil)
  }
}

/// The PiP window's content: hosts the player's display and OSD layers and
/// keeps them at the view's size, in bounds and position (the VO tracks the
/// display layer's bounds and contentsScale to size its output and OSD).
private final class MpvPipVideoView: NSView {
  init(layers: [CALayer], size: NSSize) {
    super.init(frame: NSRect(origin: .zero, size: size))
    wantsLayer = true
    layer?.backgroundColor = NSColor.black.cgColor
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layers.forEach { layer?.addSublayer($0) }
    CATransaction.commit()
    sizeLayers()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  /// The PiP window's container shows the view at the view's own size: it
  /// fills the container and follows it.
  override func viewDidMoveToSuperview() {
    super.viewDidMoveToSuperview()
    guard let superview else { return }
    autoresizingMask = [.width, .height]
    frame = superview.bounds
  }

  override func setFrameSize(_ newSize: NSSize) {
    super.setFrameSize(newSize)
    sizeLayers()
  }

  override func layout() {
    super.layout()
    sizeLayers()
  }

  override func viewDidChangeBackingProperties() {
    super.viewDidChangeBackingProperties()
    sizeLayers()
  }

  /// Takes the hosted layers out of the view.
  func releaseLayers() -> [CALayer] {
    let layers = layer?.sublayers ?? []
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layers.forEach { $0.removeFromSuperlayer() }
    CATransaction.commit()
    return layers
  }

  private func sizeLayers() {
    guard let layers = layer?.sublayers, bounds.width > 0, bounds.height > 0 else { return }
    let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for sublayer in layers where sublayer is AVSampleBufferDisplayLayer {
      sublayer.bounds = CGRect(origin: .zero, size: bounds.size)
      sublayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
      sublayer.contentsScale = scale
    }
    CATransaction.commit()
  }
}
