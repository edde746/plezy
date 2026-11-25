import AppKit
import AVFoundation
import Observation
import OSLog
import PlezyKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "player")

/// Picture in picture on the Mac (PiP is native, not shared): the system's picture in picture window from
/// PIP.framework's `PIPViewController`, private API declared in Plezy-Bridging-Header.h. This file is its only user,
/// and the Mac app ships as a Developer ID–signed, notarized DMG outside the Mac App Store, where private API is
/// acceptable. Over mpv's `AVSampleBufferDisplayLayer` the Mac's AVKit mirrors the layer into its window at the layer's
/// size in the player, unscaled, so a window smaller than the player shows a corner of the picture (macOS 27).
///
/// mpv keeps rendering into the same layers throughout: the surface lends them (the display layer and
/// vo_avfoundation's subtitle layer) to a view in the PiP window (`VideoSurface.lendLayers`), which keeps them at the
/// window's size, and takes them back when the window closes, so there is no second video output to switch to. While
/// the window is up the player shows the whole picture
/// (`PlayerStore`'s layout in picture in picture), letterboxed to the window. As on iOS, the window's controls follow
/// the shared `NowPlaying` (playing or paused) and act through its `MediaCommand`s. The window's close button pauses the
/// playback, its return button doesn't; either way the video goes back to the player. The playback ending takes the
/// layers into the player's window for mpv's teardown, then closes the window (`stop`).
@MainActor
@Observable
final class PictureInPicture: NSObject {
    /// PiP can start: the system has the framework and the video's first frame is up.
    private(set) var possible = false
    private(set) var active = false
    /// A start from the player's button failed: the player says why (`PlayerStore.onPictureInPictureFailed`).
    @ObservationIgnored var onStartFailed: ((PictureInPictureResultFailed) -> Void)?

    @ObservationIgnored private weak var surface: VideoSurface?
    @ObservationIgnored private var controller: PIPViewController?
    /// The PiP window's content while it is up: a view hosting the surface's layers.
    @ObservationIgnored private var content: NSViewController?
    @ObservationIgnored private weak var nowPlaying: NowPlayingCenter?
    /// The video's shape, which the window keeps.
    @ObservationIgnored private var aspectRatio = NSSize(width: 16, height: 9)
    /// The playback ended: PiP no longer starts, and a window closing late leaves the layers alone.
    @ObservationIgnored private var stopped = false

    /// PIP.framework is linked weakly; a system without it has no class to make.
    private static let available = NSClassFromString("PIPViewController") != nil

    /// PiP opens by itself as the app resigns active while the video plays (the `auto_pip` setting, off by default on
    /// the Mac: `AppSettings.autoPipOn`), and closes again as the app comes back if it opened so.
    @ObservationIgnored var autoPipOn = false
    @ObservationIgnored private var autoEntered = false
    @ObservationIgnored private var appObservers: [NSObjectProtocol] = []

    init(surface: VideoSurface) {
        self.surface = surface
        super.init()
        let center = NotificationCenter.default
        appObservers = [
            center.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.appResignedActive() }
            },
            center.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.appBecameActive() }
            },
        ]
    }

    private func appResignedActive() {
        guard PictureInPictureRules.shared.autoEnterReady(autoPipOn: autoPipOn, playing: playing), possible, !active else { return }
        start()
        autoEntered = active
    }

    private func appBecameActive() {
        guard autoEntered else { return }
        autoEntered = false
        if active { toggle() }
    }

    /// Takes the PiP window's play/pause state from `nowPlaying` and sends its commands there.
    func follow(_ nowPlaying: NowPlayingCenter) {
        self.nowPlaying = nowPlaying
        nowPlaying.onChange = { [weak self] in self?.controller?.playing = self?.playing ?? false }
    }

    /// The surface shows a video of `size`: PiP can start, in its shape.
    func videoShown(width: Int, height: Int) {
        if width > 0, height > 0 {
            aspectRatio = NSSize(width: width, height: height)
            controller?.aspectRatio = aspectRatio
        }
        possible = Self.available && !stopped
    }

    /// Starts PiP, or returns the video to the player when it is up.
    func toggle() {
        if active {
            if let content { controller?.dismiss(content) }
            ended()
        } else if !start() {
            onStartFailed?(PictureInPictureResultFailed(code: PictureInPictureError.failed.code, message: nil))
        }
    }

    /// The playback ended: the window closes at once, the surface having taken the layers out of it for the playback's
    /// teardown (`VideoSurface.endPlayback`); PiP no longer starts, nor follows the app's activation.
    func stop() {
        stopped = true
        possible = false
        appObservers.forEach(NotificationCenter.default.removeObserver)
        appObservers = []
        guard active else { return }
        if let content { controller?.dismiss(content) }
        ended()
    }

    /// The window is gone (dismissed here, or closed by its own buttons): unless the playback ended, its layers go
    /// back to the player. Once per window.
    private func ended() {
        guard let content else { return }
        self.content = nil
        active = false
        autoEntered = false
        if !stopped { surface?.takeLayersBack(content.view.layer?.sublayers ?? []) }
        log.notice("picture in picture ended")
    }

    /// Opens the window; false where it can't (no first frame yet, the player in no window, no layers to lend).
    @discardableResult
    private func start() -> Bool {
        guard possible, !active, let surface, let window = surface.window, let layers = surface.lendLayers() else { return false }
        let content = NSViewController()
        content.view = PictureInPictureView(layers: layers, size: surface.bounds.size)
        let controller = controller ?? PIPViewController()
        controller.delegate = self
        controller.aspectRatio = aspectRatio
        controller.playing = playing
        controller.replacementWindow = window
        controller.replacementRect = surface.frameInWindow
        self.controller = controller
        self.content = content
        controller.presentAsPicture(inPicture: content)
        // Presenting gives the PiP window's host focus; the player keeps it, so its keys and buttons go on working.
        window.makeKeyAndOrderFront(nil)
        active = true
        log.notice("picture in picture started")
        return true
    }

    private var playing: Bool { nowPlaying?.current?.playing ?? false }

    /// The window is about to animate back into the player: where to (it may have moved or been minimized meanwhile).
    private func prepareForClose(_ pip: PIPViewController) {
        guard let surface, let window = surface.window else { return }
        pip.replacementWindow = window
        pip.replacementRect = surface.frameInWindow
        NSApp.activate()
        window.deminiaturize(nil)
    }

    private func perform(_ command: any MediaCommand) {
        nowPlaying?.commands?.perform(command: command)
    }
}

extension PictureInPicture: @preconcurrency PIPViewControllerDelegate {
    func pipShouldClose(_ pip: PIPViewController) -> Bool {
        prepareForClose(pip)
        return true
    }

    func pipWillClose(_ pip: PIPViewController) {
        prepareForClose(pip)
    }

    func pipDidClose(_ pip: PIPViewController) {
        ended()
    }

    func pipActionPlay(_ pip: PIPViewController) {
        perform(MediaCommandPlay.shared)
    }

    func pipActionPause(_ pip: PIPViewController) {
        perform(MediaCommandPause.shared)
    }

    /// The window's close button (rather than its return button): the playback pauses, as on iOS.
    func pipActionStop(_ pip: PIPViewController) {
        perform(MediaCommandPause.shared)
    }
}

/// The PiP window's content: hosts the surface's layers and keeps them at the view's size, as the surface does in the
/// player: the display layer's bounds, which vo_avfoundation tracks.
private final class PictureInPictureView: NSView {
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

    /// The PiP window's container shows the view at the view's own size: it fills the container and follows it.
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

    private func sizeLayers() {
        guard let layers = layer?.sublayers, bounds.width > 0, bounds.height > 0 else { return }
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for case let display as AVSampleBufferDisplayLayer in layers {
            display.place(in: bounds, scale: scale)
        }
        CATransaction.commit()
    }
}
