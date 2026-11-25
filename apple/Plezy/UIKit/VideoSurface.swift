import AVFoundation
import OSLog
import SwiftUI
import PlezyKit
import UIKit

#if os(tvOS)
import AVKit
#endif

/// The view mpv's avfoundation VO presents into (iOS/tvOS). The `AVSampleBufferDisplayLayer` is mpv's `wid`; it sits
/// in a plain container (`content`) because vo_avfoundation adds its subtitle/OSD layer to the display layer's
/// superlayer. The container exists before playback starts, so that superlayer is in place when the VO comes up. On
/// iOS the container moves to an external screen while one is connected (`ExternalDisplay`, `placeVideo`), the surface
/// showing black under the player's controls meanwhile.
///
/// The screen follows the shared output policy (`apply`, from the playback's `PlaybackOutputHost`) for the format of
/// the video on it (`present`, from the engine): EDR on iOS, `AVDisplayManager` criteria (`AppleDisplayCriteria`) on
/// tvOS.
final class VideoSurface: UIView {
    private let displayLayer: AVSampleBufferDisplayLayer
    /// The video's container: the display layer and vo_avfoundation's subtitle layer beside it.
    private let content: VideoContent
    /// The window the surface shows in (`VideoSurfaceSlot`): the first to show it, while it lasts.
    weak var owner: UIWindow?
    #if os(tvOS)
    /// The TV's criteria, one for the app: the TV has one mode, and a playback that replaces another starts from the
    /// mode that one asked for.
    private static let displayCriteria = DisplayCriteria()
    /// The surfaces made so far, one per playback: the criteria are the latest one's (`endPlayback`).
    private static var made = 0
    /// This surface's place among them.
    private let number: Int
    /// Who waits for the display since a format was shown before the surface was in a window (`didMoveToWindow`).
    private var waitingForWindow: [@Sendable () -> Void] = []
    /// Whether the TV gets Dolby Vision at all ("Disable Dolby Vision" off), as the playback started; what the decoder
    /// makes of profile 7 is the plan's.
    private let dolbyVisionOutput: Bool
    #endif
    #if os(iOS)
    /// Picture in picture from the display layer.
    let pictureInPicture: PictureInPicture
    #endif

    /// The shared policy's latest plan for this playback; nil until the device settings are read.
    private var plan: OutputPlan?
    /// The format of the video on the surface, since the engine presented it.
    private var format: DisplayFormat?
    #if os(iOS)
    /// The dynamic range the display layer shows the video in (EDR on for an HDR one), since a plan showed it.
    private var shownRange: DynamicRange?
    #endif
    /// Called when the dynamic range `displayOutput()` reports may have changed (a format shown, a plan applied, the
    /// display handed back): the engine keeps what the display gets from it.
    var onOutputRangeChange: (@MainActor () -> Void)?

    /// The layer handed to mpv as `wid`.
    var renderLayer: CALayer { displayLayer }

    /// - Parameter settings: the device settings the playback starts with (on tvOS its Dolby Vision settings).
    init(settings: DeviceSettings) {
        let displayLayer = AVSampleBufferDisplayLayer()
        self.displayLayer = displayLayer
        content = VideoContent(displayLayer: displayLayer)
        #if os(iOS)
        pictureInPicture = PictureInPicture(layer: displayLayer)
        #endif
        #if os(tvOS)
        Self.made += 1
        number = Self.made
        dolbyVisionOutput = !settings.disableDolbyVision
        #endif
        super.init(frame: .zero)
        backgroundColor = .black
        // Input belongs to the SwiftUI overlay above.
        isUserInteractionEnabled = false
        // Smart Invert leaves the video as it is.
        accessibilityIgnoresInvertColors = true
        content.frame = bounds
        addSubview(content)
        #if os(iOS)
        followPlacement()
        #endif
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    #if os(iOS)
    override func didMoveToWindow() {
        super.didMoveToWindow()
        placeVideo()
    }

    /// Places the video again whenever an external screen comes or goes, or picture in picture starts or ends.
    private func followPlacement() {
        withObservationTracking {
            placeVideo()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in self?.followPlacement() }
        }
    }

    /// The video is on the external screen (`placeVideo`).
    var videoOnExternalScreen: Bool { content.superview != nil && content.superview !== self }

    /// The video goes to the external screen while one is connected, the surface is in the app's window (the player is
    /// up) and picture in picture doesn't show it, which takes the layer from the app's own window; back into the
    /// surface otherwise.
    private func placeVideo() {
        let external = ExternalDisplay.shared.videoHost
        let pictureInPictureShows = pictureInPicture.showsVideo
        let host = (window != nil && !pictureInPictureShows ? external : nil) ?? self
        guard content.superview !== host else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        content.removeFromSuperview()
        content.frame = host.bounds
        host.insertSubview(content, at: 0)
        CATransaction.commit()
        Logger(subsystem: "com.edde746.plezy", category: "display")
            .notice("video \(host === self ? "on the device" : "on the external screen", privacy: .public)")
    }
    #endif

    /// The shared policy decided how this playback's video shows (`OutputPlan`). A format shows by the plan's HDR
    /// output (`show`), so a plan shows the video on the surface again only when that changes: the first plan, if the
    /// engine presented a format before it, or the Hdr setting turned during the playback (the player's HDR switch),
    /// which on tvOS asks the TV for the other range without reloading the video. A plan for the next file's video,
    /// which comes before that file's format, leaves the screen to its `present`, rather than showing the last file's
    /// format by it. `completion` once the display is ready for the plan (on tvOS any switch it started has ended).
    func apply(_ plan: OutputPlan, completion: @escaping @Sendable () -> Void) {
        let shown = self.plan
        self.plan = plan
        guard let format, plan.hdrOutput != shown?.hdrOutput else { return completion() }
        show(format, completion: completion)
    }

    /// Sets the screen up for `format` and calls `completion` once it is ready to show it (the engine starts the file
    /// then). On iOS picture in picture reads the layer again, the video being up.
    func present(_ format: DisplayFormat, completion: @escaping @Sendable () -> Void) {
        self.format = format
        #if os(iOS)
        pictureInPicture.videoShown()
        #endif
        #if DEBUG && os(tvOS)
        let completion = DisplaySwitchReading.countingReady(completion)
        #endif
        show(format, completion: completion)
    }

    /// Hands the screen back when the playback's output is restored (`ApplePlaybackOutput.restore`): EDR off on iOS;
    /// on tvOS the TV's criteria go once the playback ends (`endPlayback`). A format the engine presents after this
    /// changes nothing.
    func resetDisplay() {
        plan = nil
        format = nil
        #if os(iOS)
        shownRange = nil
        displayLayer.showExtendedDynamicRange(false)
        #endif
        onOutputRangeChange?()
    }

    /// The app came back to the foreground: a display layer that failed meanwhile, or needs a flush before it decodes
    /// again (the system took its decoder in the background), is flushed, so the video shows again.
    func recoverDisplayLayer() {
        let renderer = displayLayer.sampleBufferRenderer
        guard renderer.status == .failed || renderer.requiresFlushToResumeDecoding else { return }
        renderer.flush()
        Logger(subsystem: "com.edde746.plezy", category: "display").notice("display layer flushed on return to the foreground")
    }

    #if os(tvOS)
    /// The playback ended (`ApplePlayback.release`), whether or not a plan came: the TV gets its own mode back a
    /// main-queue turn later, unless another playback's surface was made meanwhile. A playback that replaces this one
    /// is made in the same turn (`PlaybackController.open`), so the TV goes from this one's mode straight to the next
    /// one's: one switch, none when they match.
    func endPlayback() {
        let number = number
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                guard number == Self.made else { return }
                Self.displayCriteria.clear(reason: "playback ended")
            }
        }
    }
    #endif

    /// The screen the video is on as the playback info shows it (on iOS the external screen while the video is there).
    /// iOS: the screen's size in pixels the way it is turned, its refresh rate (`maximumFramesPerSecond`, 120 Hz on a
    /// ProMotion screen) and the dynamic range the display layer shows the video in (an HDR format with EDR on, else
    /// SDR). tvOS: the TV's resolution (`currentMode`; Match Content leaves it alone) and, while Match Content is on and
    /// criteria are out, the refresh rate and dynamic range they asked the TV for; otherwise the rate of the video format
    /// chosen in the tvOS settings (`maximumFramesPerSecond`) and no dynamic range, which no API reports. Nothing before
    /// the video is in a window.
    func displayOutput() -> DisplayOutput {
        guard let window = content.window else { return DisplayOutput() }
        #if os(tvOS)
        let screen = window.screen
        let size = screen.currentMode?.size
        let requested = displayManager(window).isDisplayCriteriaMatchingEnabled ? Self.displayCriteria.requested : nil
        return DisplayOutput(
            width: size.map { Int($0.width) },
            height: size.map { Int($0.height) },
            refreshRate: requested?.refreshRate ?? Double(screen.maximumFramesPerSecond),
            dynamicRange: requested?.range
        )
        #else
        guard let screen = window.windowScene?.screen else { return DisplayOutput() }
        // `nativeBounds` is the panel upright; `bounds` turns with the interface.
        let pixels = screen.nativeBounds.size
        let long = Int(max(pixels.width, pixels.height))
        let short = Int(min(pixels.width, pixels.height))
        let landscape = screen.bounds.width > screen.bounds.height
        return DisplayOutput(
            width: landscape ? long : short,
            height: landscape ? short : long,
            refreshRate: Double(screen.maximumFramesPerSecond),
            dynamicRange: shownRange
        )
        #endif
    }

    /// Shows the picture with `fit` and `zoom` (the player's `VideoLayout`, from the engine) on the display layer
    /// (`AVSampleBufferDisplayLayer.show`), the container clipping it only while zoomed.
    func show(fit: VideoFit, zoom: Double, stretchX: Double, stretchY: Double) {
        displayLayer.show(fit: fit, zoom: zoom, stretchX: stretchX, stretchY: stretchY) { content.clipsToBounds = $0 }
    }

    /// `format` as the plan has it. tvOS: `AVDisplayManager` criteria for the video as the shared `AppleDisplayCriteria`
    /// decides them (HDR only where the plan lets the playback present HDR: the Hdr setting is on and the TV can show
    /// it; the Dolby Vision settings; the ranges the TV has), whatever the app's settings: the TV switches only as its
    /// own Match Content setting allows. Ready once the display has settled for them, plus the display switch delay;
    /// before the surface is in a window, once it is (`didMoveToWindow`). iOS: EDR on the display layer for a video
    /// whose peak is above SDR white where the plan presents HDR, ready at once. Before the first plan nothing changes.
    private func show(_ format: DisplayFormat, completion: @escaping @Sendable () -> Void) {
        guard let plan else { return completion() }
        #if os(tvOS)
        guard let window else { return waitingForWindow.append(completion) }
        let criteria = AppleDisplayCriteria.companion.of(
            video: format.video,
            doviLevel: format.doviLevel.map { KotlinInt(int: Int32(clamping: $0)) },
            hdr: plan.hdrOutput,
            dvConversion: plan.dolbyVisionConversion,
            dolbyVisionOutput: dolbyVisionOutput,
            availableRanges: Self.availableRanges
        )
        Self.displayCriteria.apply(
            criteria,
            extraDelay: Int(plan.switchDelaySeconds) * 1000,
            manager: displayManager(window),
            completion: completion
        )
        onOutputRangeChange?()
        #else
        let extended = plan.hdrOutput && format.extendsDynamicRange
        shownRange = extended ? format.dynamicRange : .sdr
        displayLayer.showExtendedDynamicRange(extended)
        onOutputRangeChange?()
        completion()
        #endif
    }

    #if os(tvOS)
    /// The player's cover comes up only once the Streams sheet under it has gone, and a file can be ready sooner: the
    /// format shows, and whoever waits for the display (`waitingForWindow`) is called, once the surface is in the
    /// window, so the file still starts after the display has settled for it.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, let format, !waitingForWindow.isEmpty else { return }
        let waiting = waitingForWindow
        waitingForWindow = []
        show(format) { waiting.forEach { $0() } }
    }

    /// The window's display manager; in debug builds started with `-simulateMatchContent YES`, the simulated one.
    private func displayManager(_ window: UIWindow) -> any DisplayManaging {
        #if DEBUG
        if let simulated = SimulatedMatchContent.shared { return simulated }
        #endif
        return window.avDisplayManager
    }

    /// The HDR ranges the TV takes (`AVPlayer.availableHDRModes`); in debug builds with the simulated display, every
    /// one, as an HDR TV's.
    private static var availableRanges: Set<DynamicRange> {
        #if DEBUG
        if SimulatedMatchContent.shared != nil { return [.hdr10, .hlg, .dolbyVision] }
        #endif
        let modes = AVPlayer.availableHDRModes
        var ranges: Set<DynamicRange> = []
        if modes.contains(.hdr10) { ranges.insert(.hdr10) }
        if modes.contains(.hlg) { ranges.insert(.hlg) }
        if modes.contains(.dolbyVision) { ranges.insert(.dolbyVision) }
        return ranges
    }
    #endif
}

/// The video's container (`VideoSurface.content`): the display layer at its size in its screen's native scale (the
/// panel's own pixels, Display Zoom or not), which on iOS may be an external screen's.
private final class VideoContent: UIView {
    private let displayLayer: AVSampleBufferDisplayLayer

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
        super.init(frame: .zero)
        backgroundColor = .black
        isUserInteractionEnabled = false
        accessibilityIgnoresInvertColors = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        displayLayer.videoGravity = .resizeAspect
        displayLayer.isOpaque = true
        displayLayer.backgroundColor = UIColor.black.cgColor
        layer.addSublayer(displayLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        displayLayer.place(in: bounds, scale: window?.screen.nativeScale ?? traitCollection.displayScale)
    }

    /// Another window may be on another screen, of another scale.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsLayout()
    }
}

/// Hosts the long-lived [VideoSurface] in SwiftUI, through a slot of each player's own (`VideoSurfaceSlot`).
struct VideoSurfaceHost: UIViewRepresentable {
    let surface: VideoSurface

    func makeUIView(context: Context) -> VideoSurfaceSlot { VideoSurfaceSlot(surface: surface) }
    func updateUIView(_ uiView: VideoSurfaceSlot, context: Context) {}
}

/// Where a player shows the surface. iPadOS may show the app in several windows, each with the player: the surface
/// stays in the window that showed it first (`VideoSurface.owner`), so another window's player shows black rather than
/// taking the video, its picture in picture and its external screen from it. A slot takes the surface as it comes into
/// the owner's window, which moves it from an earlier slot there; the owner window gone, the next slot to come into a
/// window takes it.
final class VideoSurfaceSlot: UIView {
    private let surface: VideoSurface

    init(surface: VideoSurface) {
        self.surface = surface
        super.init(frame: .zero)
        backgroundColor = .black
        isUserInteractionEnabled = false
        #if DEBUG
        isAccessibilityElement = true
        accessibilityIdentifier = "player.surface"
        #endif
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window else { return }
        if let owner = surface.owner, owner !== window {
            Logger(subsystem: "com.edde746.plezy", category: "display").notice("video stays in the window that shows it")
        } else {
            surface.owner = window
            surface.frame = bounds
            surface.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(surface)
        }
    }

    #if DEBUG
    /// The UI tests' view of where the video is (`player.surface`): `elsewhere` (another window has it), `here`, or on
    /// iOS `here external` while it is on an external screen.
    override var accessibilityLabel: String? {
        get {
            guard surface.superview === self else { return "elsewhere" }
            #if os(iOS)
            if surface.videoOnExternalScreen { return "here external" }
            #endif
            return "here"
        }
        set {}
    }
    #endif
}
