import AVKit
import UIKit

/// Delegate to notify the plugin of PiP lifecycle events
protocol MpvPipDelegate: AnyObject {
    /// Called when PiP is about to start (system or app-initiated)
    func pipWillStart()
    func pipDidStart()
    /// Called when PiP stops. `restored` is true if the user pressed maximize (restore UI).
    func pipDidStop(restored: Bool)
    func pipDidFailToStart(error: Error?)
    /// Forward play/pause commands from PiP overlay to mpv
    func pipSetPlaying(_ playing: Bool)
    /// Forward skip forward/backward commands from PiP overlay to mpv
    func pipSkip(byInterval seconds: Double)
    /// Query whether mpv is currently playing
    var isPipPlaying: Bool { get }
    /// Get total duration in seconds
    var pipDuration: Double { get }
}

/// Encapsulates all iOS Picture-in-Picture logic using AVSampleBufferDisplayLayer.
/// Requires iOS 15+ for the ContentSource API; on older versions, `setup()` is a no-op.
class MpvPipController: NSObject {

    // MARK: - Properties

    private var pipController: AVPictureInPictureController?
    private let sampleBufferLayer = AVSampleBufferDisplayLayer()
    private var containerView: UIView?
    weak var delegate: MpvPipDelegate?

    /// Pointer to the sample buffer layer for passing to mpv as `wid`
    var layerPointer: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(sampleBufferLayer).toOpaque()
    }

    // MARK: - Initialization

    override init() {
        super.init()
        setup()
    }

    private func setup() {
        guard #available(iOS 15.0, *) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[MpvPipController] Failed to configure audio session: \(error)")
        }

        // The sample buffer layer must be in a visible view hierarchy for
        // isPictureInPicturePossible to become true.
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            let view = UIView(frame: window.bounds)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.clipsToBounds = true
            view.isUserInteractionEnabled = false
            sampleBufferLayer.frame = view.bounds
            view.layer.addSublayer(sampleBufferLayer)
            window.addSubview(view)
            containerView = view
        }

        createPipController()
    }

    /// Helper that conforms to the iOS 15+ delegate protocols
    private var delegateHelper: AnyObject?

    private func createPipController() {
        guard #available(iOS 15.0, *) else { return }
        let helper = PipDelegateHelper(controller: self)
        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: sampleBufferLayer,
            playbackDelegate: helper
        )
        self.delegateHelper = helper
        pipController = AVPictureInPictureController(contentSource: contentSource)
        pipController?.delegate = helper
        if #available(iOS 14.2, *) {
            pipController?.canStartPictureInPictureAutomaticallyFromInline = false
        }
    }

    /// Enable/disable system auto-PiP (starts PiP automatically on background transition)
    func setAutoStart(_ enabled: Bool) {
        guard #available(iOS 14.2, *) else { return }
        pipController?.canStartPictureInPictureAutomaticallyFromInline = enabled
    }

    /// Push a black frame to the sample buffer layer so PiP has content
    /// to display immediately (before vo_pip decodes the first real frame).
    func pushBlankFrame(width: Int32 = 1920, height: Int32 = 1080) {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(width), Int(height),
            kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer
        )
        guard status == kCVReturnSuccess, let pb = pixelBuffer else { return }

        // Fill with black
        CVPixelBufferLockBaseAddress(pb, [])
        if let base = CVPixelBufferGetBaseAddress(pb) {
            memset(base, 0, CVPixelBufferGetDataSize(pb))
        }
        CVPixelBufferUnlockBaseAddress(pb, [])

        // Use current timebase time for PTS (if available) so the frame isn't stale
        let pts: CMTime
        if let tb = sampleBufferLayer.controlTimebase {
            pts = CMTimebaseGetTime(tb)
        } else {
            pts = CMTime(value: 0, timescale: 30)
        }

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: pts,
            decodeTimeStamp: .invalid
        )

        // Create format description and sample buffer
        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pb,
            formatDescriptionOut: &formatDesc
        )
        guard let fmt = formatDesc else { return }

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pb,
            formatDescription: fmt,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard let sb = sampleBuffer else { return }

        // Set DisplayImmediately so it shows regardless of timebase timing
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sb, createIfNecessary: true) as? [NSMutableDictionary],
           let dict = attachments.first {
            dict[kCMSampleAttachmentKey_DisplayImmediately] = true
        }

        sampleBufferLayer.enqueue(sb)
    }

    /// Sync the layer's controlTimebase with the actual playback position.
    /// This makes the PiP progress bar show the correct time.
    func syncTimebase(currentTime: Double, isPlaying: Bool) {
        guard let timebase = sampleBufferLayer.controlTimebase else { return }
        let cmTime = CMTime(seconds: currentTime, preferredTimescale: 1000)
        CMTimebaseSetTime(timebase, time: cmTime)
        CMTimebaseSetRate(timebase, rate: isPlaying ? 1.0 : 0.0)
    }

    /// Ensure the layer has a timebase and blank frame so the system considers
    /// PiP possible (required for canStartPictureInPictureAutomaticallyFromInline).
    func warmLayer(currentTime: Double, isPlaying: Bool) {
        if sampleBufferLayer.controlTimebase == nil {
            var timebase: CMTimebase?
            CMTimebaseCreateWithSourceClock(
                allocator: kCFAllocatorDefault,
                sourceClock: CMClockGetHostTimeClock(),
                timebaseOut: &timebase
            )
            if let tb = timebase {
                sampleBufferLayer.controlTimebase = tb
            }
        }
        syncTimebase(currentTime: currentTime, isPlaying: isPlaying)
        pushBlankFrame()
    }

    // MARK: - Public API

    static var isSupported: Bool {
        guard #available(iOS 15.0, *) else { return false }
        return AVPictureInPictureController.isPictureInPictureSupported()
    }

    /// Start PiP. When `waitForFrame` is false (auto-PiP), skips the frame
    /// readiness check since the scene is about to deactivate.
    func startPip(waitForFrame: Bool = true, completion: @escaping (Bool) -> Void) {
        guard let pipController = pipController else {
            completion(false)
            return
        }

        var attempts = 0
        func tryStart() {
            let possible = pipController.isPictureInPicturePossible
            let hasTimebase = sampleBufferLayer.controlTimebase != nil

            let hasFrame: Bool
            if !waitForFrame {
                hasFrame = true  // Skip frame check for auto-PiP
            } else if #available(iOS 17.4, *) {
                hasFrame = sampleBufferLayer.isReadyForDisplay
            } else {
                hasFrame = true
            }

            if possible && hasTimebase && hasFrame {
                print("[MpvPipController] vo_pip ready after \(attempts) retries, starting PiP")
                pipController.startPictureInPicture()
                completion(true)
            } else if attempts < 40 {
                attempts += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { tryStart() }
            } else {
                print("[MpvPipController] PiP not ready after \(attempts) retries (possible=\(possible), timebase=\(hasTimebase))")
                completion(false)
            }
        }
        tryStart()
    }

    func stopPip() {
        pipController?.stopPictureInPicture()
    }

    /// Invalidate the playback state so PiP updates its UI (play/pause button)
    func invalidatePlaybackState() {
        pipController?.invalidatePlaybackState()
    }

    /// Fully tear down PiP — removes the container view from the window and
    /// destroys the AVPictureInPictureController so the system can no longer
    /// trigger auto-PiP after the player is disposed.
    func teardown() {
        pipController?.stopPictureInPicture()
        if #available(iOS 14.2, *) {
            pipController?.canStartPictureInPictureAutomaticallyFromInline = false
        }
        pipController = nil
        delegateHelper = nil
        sampleBufferLayer.flushAndRemoveImage()
        sampleBufferLayer.controlTimebase = nil
        sampleBufferLayer.removeFromSuperlayer()
        containerView?.removeFromSuperview()
        containerView = nil
    }

    /// Flush enqueued sample buffers from the layer to free video frame memory
    func flushLayer() {
        sampleBufferLayer.flushAndRemoveImage()
    }
}

// MARK: - PiP Delegate Helper (iOS 15+)

/// Separate class conforming to AVPictureInPictureControllerDelegate and
/// AVPictureInPictureSampleBufferPlaybackDelegate since these require iOS 15+
/// availability for the ContentSource-based delegate methods.
@available(iOS 15.0, *)
private class PipDelegateHelper: NSObject, AVPictureInPictureControllerDelegate,
    AVPictureInPictureSampleBufferPlaybackDelegate
{
    weak var controller: MpvPipController?
    private var isRestoring = false

    init(controller: MpvPipController) {
        self.controller = controller
        super.init()
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("[MpvPipController] PiP will start")
        controller?.delegate?.pipWillStart()
    }

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("[MpvPipController] PiP did start")
        controller?.delegate?.pipDidStart()
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        let restored = isRestoring
        isRestoring = false
        print("[MpvPipController] PiP did stop (restored: \(restored))")
        controller?.delegate?.pipDidStop(restored: restored)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        print("[MpvPipController] PiP failed to start: \(error)")
        controller?.delegate?.pipDidFailToStart(error: error)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        print("[MpvPipController] PiP restore user interface")
        isRestoring = true
        completionHandler(true)
    }

    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("[MpvPipController] PiP will stop")
    }

    // MARK: - AVPictureInPictureSampleBufferPlaybackDelegate

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
        print("[MpvPipController] PiP setPlaying: \(playing)")
        controller?.delegate?.pipSetPlaying(playing)
    }

    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        let duration = controller?.delegate?.pipDuration ?? 0
        if duration > 0 {
            return CMTimeRange(
                start: .zero,
                duration: CMTime(seconds: duration, preferredTimescale: 1000)
            )
        }
        return CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 1))
    }

    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        return !(controller?.delegate?.isPipPlaying ?? false)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {}

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        let seconds = CMTimeGetSeconds(skipInterval)
        print("[MpvPipController] PiP skip by \(seconds)s")
        controller?.delegate?.pipSkip(byInterval: seconds)
        completionHandler()
    }
}
