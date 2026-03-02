import Cocoa

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
/// This approach wraps the existing Metal rendering view in PiP — no VO switching needed.
/// mpv continues rendering to its CAMetalLayer throughout PiP.
class MpvPipController: NSObject, PIPViewControllerDelegate {

    // MARK: - Properties

    private lazy var pip: PIPViewController = {
        let vc = PIPViewController()
        vc.delegate = self
        return vc
    }()

    private var pipVideoVC: NSViewController?
    private var pipVideoView: NSView?

    weak var delegate: MpvPipDelegate?
    private(set) var isActive = false
    var autoPipEnabled = false

    // Keep reference to the window for restore animation
    private weak var sourceWindow: NSWindow?

    // MARK: - Public API

    static var isSupported: Bool { true }

    /// Enter PiP by wrapping the given Metal layer in a view and presenting it.
    /// The layer continues receiving mpv frames — no VO switch needed.
    func startPip(metalLayer: CAMetalLayer, window: NSWindow, aspectRatio: NSSize) {
        guard !isActive else { return }

        sourceWindow = window

        // Create a layer-hosting wrapper view for the Metal layer.
        // PIPViewController resizes the view (and its root layer) as the PiP window resizes.
        let videoView = NSView(frame: NSRect(origin: .zero, size: aspectRatio))
        videoView.wantsLayer = true
        videoView.layer = metalLayer

        // Reset drawableSize to zero so it auto-derives from the layer's bounds.
        // Without this, the explicit drawableSize set by updateFrame() (main window size)
        // persists and causes mpv/MoltenVK to render at the wrong resolution in PiP.
        metalLayer.drawableSize = .zero

        // Create a view controller for PIPViewController
        let vc = NSViewController()
        vc.view = videoView

        pipVideoVC = vc
        pipVideoView = videoView

        // Configure PiP
        pip.playing = delegate?.isPipPlaying ?? false
        pip.aspectRatio = aspectRatio
        pip.replacementWindow = window
        pip.replacementRect = window.contentView?.frame ?? .zero

        delegate?.pipWillStart()

        // Present PiP
        pip.presentAsPicture(inPicture: vc)
        isActive = true
        delegate?.pipDidStart()
    }

    func stopPip() {
        guard isActive else { return }
        pip.dismiss(pipVideoVC!)
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

    /// Clean up after PiP closes — detaches the Metal layer from the wrapper view
    /// so MpvPlayerCore can re-add it to the main window.
    /// Returns the Metal layer that was hosted in PiP.
    @discardableResult
    func detachLayer() -> CAMetalLayer? {
        let metalLayer = pipVideoView?.layer as? CAMetalLayer
        pipVideoView?.layer = CALayer() // detach before removing
        pipVideoView = nil
        pipVideoVC = nil
        return metalLayer
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
