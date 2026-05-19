import AVFoundation
import AVKit
import UIKit

#if os(tvOS)
  // tvOS stub: AVPictureInPictureController has different constraints on tvOS
  // and is not supported by the Plezy flow. Provide a no-op shell so callers
  // in MpvPlayerPlugin compile unchanged; isSupported reports false so PiP is
  // never attempted at runtime.
  protocol MpvPipDelegate: AnyObject {
    func pipWillStart()
    func pipDidStart()
    func pipDidStop(restored: Bool)
    func pipDidFailToStart(error: Error?)
    func pipSetPlaying(_ playing: Bool)
    func pipSkip(byInterval seconds: Double, completion: @escaping () -> Void)
    var isPipPlaying: Bool { get }
    var pipDuration: Double { get }
  }

  class MpvPipController: NSObject {
    static var isSupported: Bool { false }
    weak var delegate: MpvPipDelegate?
    var isPipActive: Bool { false }
    var autoStartEnabled: Bool { false }
    init(sampleBufferDisplayLayer: AVSampleBufferDisplayLayer) { super.init() }
    func setup(with layer: CALayer, containerView: UIView) {}
    func setAutoStart(_ enabled: Bool) {}
    func warmLayer(currentTime: Double, isPlaying: Bool) {}
    func startPip(waitForFrame: Bool = true, completion: @escaping (Bool) -> Void) {
      completion(false)
    }
    func stopPip() {}
    func invalidatePlaybackState() {}
    func syncTimebase(currentTime: Double, isPlaying: Bool) {}
    func teardown() {}
  }
#else

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
    func pipSkip(byInterval seconds: Double, completion: @escaping () -> Void)
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
    private weak var sampleBufferLayer: AVSampleBufferDisplayLayer?
    weak var delegate: MpvPipDelegate?

    // MARK: - Initialization

    init(sampleBufferDisplayLayer: AVSampleBufferDisplayLayer) {
      self.sampleBufferLayer = sampleBufferDisplayLayer
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

      createPipController()
    }

    /// Helper that conforms to the iOS 15+ delegate protocols
    private var delegateHelper: AnyObject?

    private func createPipController() {
      guard #available(iOS 15.0, *), let sampleBufferLayer else { return }
      let helper = PipDelegateHelper(controller: self)
      let contentSource = AVPictureInPictureController.ContentSource(
        sampleBufferDisplayLayer: sampleBufferLayer,
        playbackDelegate: helper
      )
      self.delegateHelper = helper
      pipController = AVPictureInPictureController(contentSource: contentSource)
      pipController?.delegate = helper
      pipController?.canStartPictureInPictureAutomaticallyFromInline = false
    }

    /// Enable/disable system auto-PiP (starts PiP automatically on background transition)
    func setAutoStart(_ enabled: Bool) {
      guard #available(iOS 14.2, *) else { return }
      pipController?.canStartPictureInPictureAutomaticallyFromInline = enabled
    }

    /// MPVKit owns the sample-buffer layer timebase. PiP only reads it.
    func syncTimebase(currentTime: Double, isPlaying: Bool) {
    }

    /// Ensure the layer has MPVKit's renderer-owned timebase before PiP starts.
    func warmLayer(currentTime: Double, isPlaying: Bool) {
      if sampleBufferLayer?.controlTimebase == nil {
        print("[MpvPipController] Waiting for MPVKit renderer timebase before PiP")
      }
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
        let hasTimebase = self.sampleBufferLayer?.controlTimebase != nil

        let hasFrame: Bool
        if !waitForFrame {
          hasFrame = true  // Skip frame check for auto-PiP
        } else if #available(iOS 17.4, *) {
          hasFrame = self.sampleBufferLayer?.isReadyForDisplay ?? false
        } else {
          hasFrame = true
        }

        if possible && hasTimebase && hasFrame {
          print("[MpvPipController] vo_avfoundation ready after \(attempts) retries, starting PiP")
          pipController.startPictureInPicture()
          completion(true)
        } else if attempts < 40 {
          attempts += 1
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { tryStart() }
        } else {
          print(
            "[MpvPipController] PiP not ready after \(attempts) retries (possible=\(possible), timebase=\(hasTimebase))"
          )
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
      guard #available(iOS 15.0, *) else { return }
      pipController?.invalidatePlaybackState()
    }

    /// Fully tear down PiP without touching the shared inline display layer.
    func teardown() {
      pipController?.stopPictureInPicture()
      if #available(iOS 14.2, *) {
        pipController?.canStartPictureInPictureAutomaticallyFromInline = false
      }
      pipController = nil
      delegateHelper = nil
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
      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler:
        @escaping (Bool) -> Void
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
      guard let delegate = controller?.delegate else {
        completionHandler()
        return
      }
      delegate.pipSkip(byInterval: seconds, completion: completionHandler)
    }
  }

#endif  // !os(tvOS)
