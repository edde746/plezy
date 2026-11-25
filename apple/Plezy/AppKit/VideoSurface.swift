import AppKit
import OSLog
import AVFoundation
import QuartzCore
import SwiftUI
import PlezyKit

/// The view mpv presents into (macOS): vo_avfoundation's `AVSampleBufferDisplayLayer`, mpv's `wid`, as on iOS
/// (UIKit/VideoSurface.swift). The view's own layer is the plain container vo_avfoundation adds its subtitle layer to,
/// beside the display layer. The display layer scales the picture for the player's fit and zoom (`show`) and shows HDR
/// and Dolby Vision with EDR where the shared output policy's plan shows HDR.
///
/// Picture in picture borrows the video's layers (`lendLayers`, `takeLayersBack`); meanwhile the view leaves their
/// geometry alone. When the playback ends, `endPlayback` hides the layers and keeps them in the window for mpv's
/// teardown.
final class VideoSurface: NSView {
    /// The layer handed to mpv as `wid`.
    let sampleBufferLayer = AVSampleBufferDisplayLayer()
    var renderLayer: CALayer { sampleBufferLayer }

    /// Picture in picture with this surface's layer.
    private(set) lazy var pictureInPicture = PictureInPicture(surface: self)

    /// The shared policy's latest plan for this playback.
    private var plan: OutputPlan?
    /// The format of the video, since the engine presented it.
    private var format: DisplayFormat?
    /// The layer is in the picture in picture window.
    private var layerLent = false
    /// The playback ended: the layers are hidden for good.
    private var ended = false
    /// The video's layers once the playback ended: hidden, in the window until mpv has let go of them
    /// (`endPlayback`, `removeEndedLayers`).
    private var endedLayers: CALayer?
    /// The forced frame-rate switch of the display the window is on.
    private lazy var displayModes = DisplayModeSwitch { [weak self] in self?.window }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        sampleBufferLayer.videoGravity = .resizeAspect
        sampleBufferLayer.isOpaque = true
        sampleBufferLayer.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(sampleBufferLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // Clicks and keys belong to the SwiftUI overlay above.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        #if DEBUG
        if window == nil, sampleBufferLayer.superlayer === layer {
            VideoTeardownLog.shared.displayLayerLeft(hidden: sampleBufferLayer.isHidden)
        }
        #endif
    }

    override func layout() {
        super.layout()
        updateSampleBufferLayer()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateSampleBufferLayer()
    }

    /// EDR on the display layer as the plan has the video (`showDynamicRange`), ready at once; the video's first frame
    /// is up, so picture in picture can start.
    func present(_ format: DisplayFormat, completion: @escaping @Sendable () -> Void) {
        self.format = format
        showDynamicRange()
        pictureInPicture.videoShown(width: format.width, height: format.height)
        completion()
    }

    /// The shared policy decided whether this playback may present HDR at all (`OutputPlan.hdrOutput`: the Hdr setting
    /// and the screen): the video on the display layer shows as the plan says from now on. The plan's mode (full screen
    /// only) goes to the window's display, `done` hearing whether the display switched to it; a plan without one puts
    /// the display's own back.
    func apply(_ plan: OutputPlan, done: @escaping @MainActor (Bool) -> Void) {
        self.plan = plan
        showDynamicRange()
        displayModes.apply(plan.mode, done: done)
    }

    /// The playback ended: the display's mode as it was before the playback switched it. The EDR lives on this
    /// playback's own layer.
    func resetDisplay() {
        displayModes.restore()
    }

    /// The current mode of the window's display (the main screen's before the view is in a window) and its refresh-rate
    /// variants, for the shared policy.
    func modes() -> DisplayModeSwitch.Modes? {
        DisplayModeSwitch.modes(on: window?.screen ?? NSScreen.main)
    }

    /// The screen as the playback info shows it: the mode of the screen the window is on, in pixels, and its refresh
    /// rate (the mode's, else the screen's highest: a built-in screen's mode may name none).
    func displayOutput() -> DisplayOutput {
        guard let screen = window?.screen,
              let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
              let mode = CGDisplayCopyDisplayMode(CGDirectDisplayID(number.uint32Value)) else {
            return DisplayOutput()
        }
        let rate = mode.refreshRate > 0 ? mode.refreshRate : Double(screen.maximumFramesPerSecond)
        return DisplayOutput(width: mode.pixelWidth, height: mode.pixelHeight, refreshRate: rate > 0 ? rate : nil)
    }

    /// The display layer's EDR, as the plan has the video on it (UIKit/VideoSurface.swift's): on for a video whose peak
    /// is above SDR white where the plan presents HDR (the Hdr setting is on and the screen can show it); otherwise
    /// macOS tone-maps HDR frames to SDR. Before the first plan and format nothing changes.
    private func showDynamicRange() {
        guard let plan, let format else { return }
        sampleBufferLayer.showExtendedDynamicRange(plan.hdrOutput && format.extendsDynamicRange)
    }

    /// Shows the picture with `fit` and `zoom` (the player's `VideoLayout`, from the engine) on the
    /// display layer, as iOS's surface does (`AVSampleBufferDisplayLayer.show`), the view clipping it only while zoomed.
    func show(fit: VideoFit, zoom: Double, stretchX: Double, stretchY: Double) {
        sampleBufferLayer.show(fit: fit, zoom: zoom, stretchX: stretchX, stretchY: stretchY) { clipsToBounds = $0 }
    }

    /// Hides the video while nobody sees it (`ApplePlayback`: the window out of sight, the screens asleep), as the view
    /// and so the video's layers under it, unless picture in picture has them; shown again, a display layer that
    /// failed meanwhile, or needs a flush before it decodes again, is flushed. True when it was: playing video refills
    /// it with its next frames, a paused one has to be drawn again (`MpvPlayerEngine.redrawIfPaused`).
    func setOutOfSight(_ outOfSight: Bool) -> Bool {
        guard outOfSight != isHidden else { return false }
        isHidden = outOfSight
        guard !outOfSight, !ended else { return false }
        let renderer = sampleBufferLayer.sampleBufferRenderer
        guard renderer.status == .failed || renderer.requiresFlushToResumeDecoding else { return false }
        renderer.flush()
        Logger(subsystem: "com.edde746.plezy", category: "display").notice("display layer flushed as the video came back in sight")
        return true
    }

    /// Where the video sits in its window, for the picture in picture window to animate from and back to.
    var frameInWindow: NSRect { convert(bounds, to: nil) }

    /// Hands the video's layers (the display layer and vo_avfoundation's subtitle layer beside it)
    /// to the picture in picture window, which sizes them from then on; nil while they are lent already or the playback
    /// has ended.
    func lendLayers() -> [CALayer]? {
        guard !layerLent, !ended, let layers = layer?.sublayers, !layers.isEmpty else { return nil }
        layerLent = true
        withoutAnimation { layers.forEach { $0.removeFromSuperlayer() } }
        return layers
    }

    /// The picture in picture window closed: its `layers` come back under the view, at the view's size.
    func takeLayersBack(_ layers: [CALayer]) {
        guard layerLent else { return }
        layerLent = false
        guard !ended else { return }
        withoutAnimation { layers.forEach { layer?.addSublayer($0) } }
        updateSampleBufferLayer()
    }

    /// The playback ended (before mpv goes): the video's layers (the display layer and vo_avfoundation's subtitle layer),
    /// in the player or lent to picture in picture, are hidden at once, and picture in picture closes. They stay in the
    /// window, hidden, until mpv has let go of them and the hidden frame is on screen (`removeEndedLayers`, from the
    /// engine): on macOS 27 a display layer that leaves the window while its video receiver is torn down can stop the
    /// whole display, and the window server's watchdog panics the Mac. The closing player takes this view out of the
    /// window and the closing PiP window takes its own, so they wait under the player window's content view, moved
    /// there before picture in picture closes; vo_avfoundation's teardown takes its timebase and observers off them on
    /// the main thread, which nothing here waits for.
    func endPlayback() {
        guard !ended else { return }
        ended = true
        layerLent = false
        let videoLayers = sampleBufferLayer.superlayer?.sublayers ?? []
        withoutAnimation { videoLayers.forEach { $0.isHidden = true } }
        if let windowLayer = window?.contentView?.layer {
            let holder = CALayer()
            holder.isHidden = true
            withoutAnimation {
                videoLayers.forEach { holder.addSublayer($0) }
                windowLayer.addSublayer(holder)
            }
            endedLayers = holder
        }
        pictureInPicture.stop()
    }

    /// mpv has let go of the video's layers, and their hidden frame is on screen: they leave the window.
    func removeEndedLayers() {
        guard let endedLayers else { return }
        self.endedLayers = nil
        #if DEBUG
        VideoTeardownLog.shared.displayLayerLeft(hidden: endedLayers.isHidden)
        #endif
        withoutAnimation { endedLayers.removeFromSuperlayer() }
    }

    /// The display layer at the view's size, in its window's scale (`AVSampleBufferDisplayLayer.place`).
    private func updateSampleBufferLayer() {
        guard !layerLent else { return }
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        sampleBufferLayer.place(in: bounds, scale: scale)
    }

    private func withoutAnimation(_ changes: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        changes()
        CATransaction.commit()
    }
}

/// Hosts the long-lived [VideoSurface] in SwiftUI.
struct VideoSurfaceHost: NSViewRepresentable {
    let surface: VideoSurface

    func makeNSView(context: Context) -> VideoSurface { surface }
    func updateNSView(_ nsView: VideoSurface, context: Context) {}
}
