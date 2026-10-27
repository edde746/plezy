import AVFoundation
import AVKit
import UIKit

/// Delegate to notify the plugin of PiP lifecycle events
protocol MpvPipDelegate: AnyObject {
  func pipWillStart()
  func pipDidStart()
  func pipDidStop(restored: Bool)
  func pipDidFailToStart(error: Error?)
  func pipSetPlaying(_ playing: Bool)
  func pipSkip(byInterval seconds: Double, completion: @escaping () -> Void)
  var isPipPlaying: Bool { get }
  var pipDuration: Double { get }
  var pipPosition: Double { get }
}

#if os(tvOS)
  // tvOS stub: AVPictureInPictureController has different constraints on tvOS
  // and is not supported by the Plezy flow. Provide a no-op shell so callers
  // in MpvPlayerPlugin compile unchanged; isSupported reports false so PiP is
  // never attempted at runtime.
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
    func teardown() {}
  }
#else

  protocol MpvPictureInPictureControlling: AnyObject {
    var isPictureInPicturePossible: Bool { get }
    func startPictureInPicture()
    func stopPictureInPicture()
    func setAutomaticStart(_ enabled: Bool)
    func invalidatePlaybackState()
  }

  @available(iOS 15.0, *)
  extension AVPictureInPictureController: MpvPictureInPictureControlling {
    func setAutomaticStart(_ enabled: Bool) {
      canStartPictureInPictureAutomaticallyFromInline = enabled
    }
  }

  /// Encapsulates all iOS Picture-in-Picture logic using AVSampleBufferDisplayLayer.
  /// Requires iOS 15+ for the ContentSource API; on older versions, `setup()` is a no-op.
  class MpvPipController: NSObject {

    // MARK: - Properties

    private var pipController: MpvPictureInPictureControlling?
    private weak var sampleBufferLayer: AVSampleBufferDisplayLayer?
    weak var delegate: MpvPipDelegate?
    private var startGeneration = 0
    private var pendingStartCompletion: ((Bool) -> Void)?
    private var startRequested = false
    private var systemStartExpected = false
    private var hasActiveSession = false
    private var restoreRequested = false
    private var isTornDown = false
    private let readinessOverride: (() -> (possible: Bool, timebase: Bool, frame: Bool))?
    private let retryScheduler: (@escaping () -> Void) -> Void
    private let startTimeoutScheduler: (@escaping () -> Void) -> Void
    private var autoStartEnabled = false
    /// Start, length and playback position of the last range handed to PiP,
    /// on the display layer's timeline; start is nil while PiP has none or a
    /// live one.
    private var timelineStart: CMTime?
    private var timelineDuration = 0.0
    private var timelinePosition = 0.0
    private var timelineTimer: Timer?
    /// How far PiP's elapsed time may drift from mpv's position before the
    /// range is re-sent, and how often that is checked while PiP is up.
    private static let timelineTolerance = 0.25
    private static let timelineCheckInterval: TimeInterval = 0.5
    static let liveTimeRange = CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)

    // MARK: - Initialization

    init(sampleBufferDisplayLayer: AVSampleBufferDisplayLayer) {
      self.sampleBufferLayer = sampleBufferDisplayLayer
      self.readinessOverride = nil
      self.retryScheduler = { work in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
      }
      self.startTimeoutScheduler = { work in
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
      }
      super.init()
      setup()
    }

    init(
      controller: MpvPictureInPictureControlling,
      sampleBufferDisplayLayer: AVSampleBufferDisplayLayer? = nil,
      readiness: @escaping () -> (possible: Bool, timebase: Bool, frame: Bool),
      retryScheduler: @escaping (@escaping () -> Void) -> Void,
      startTimeoutScheduler: @escaping (@escaping () -> Void) -> Void = { work in
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
      }
    ) {
      self.pipController = controller
      self.sampleBufferLayer = sampleBufferDisplayLayer
      self.readinessOverride = readiness
      self.retryScheduler = retryScheduler
      self.startTimeoutScheduler = startTimeoutScheduler
      super.init()
    }

    deinit {
      timelineTimer?.invalidate()
      if let completion = pendingStartCompletion {
        pendingStartCompletion = nil
        if Thread.isMainThread {
          completion(false)
        } else {
          DispatchQueue.main.async { completion(false) }
        }
      }
    }

    private func setup() {
      guard #available(iOS 15.0, *) else { return }

      do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {
        MpvLog.debug("[MpvPipController] Failed to configure audio session: \(error)")
      }

      createPipController()
    }

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
      (pipController as? AVPictureInPictureController)?.delegate = helper
      pipController?.setAutomaticStart(autoStartEnabled)
    }

    /// Enable/disable system auto-PiP (starts PiP automatically on background transition)
    func setAutoStart(_ enabled: Bool) {
      guard !isTornDown else { return }
      let wasEnabled = autoStartEnabled
      autoStartEnabled = enabled
      if enabled && !wasEnabled { systemStartExpected = false }
      pipController?.setAutomaticStart(enabled)
    }

    /// Ensure the layer has MPVKit's renderer-owned timebase before PiP starts.
    func warmLayer(currentTime: Double, isPlaying: Bool) {
      if sampleBufferLayer?.controlTimebase == nil {
        MpvLog.debug("[MpvPipController] Waiting for MPVKit renderer timebase before PiP")
      }
    }

    // MARK: - Public API

    static var isSupported: Bool {
      guard #available(iOS 15.0, *) else { return false }
      return AVPictureInPictureController.isPictureInPictureSupported()
    }

    fileprivate func isCurrentController(_ controller: MpvPictureInPictureControlling) -> Bool {
      guard let pipController else { return false }
      return ObjectIdentifier(pipController) == ObjectIdentifier(controller)
    }

    private func finishStart(generation: Int, success: Bool) {
      guard generation == startGeneration, let completion = pendingStartCompletion else { return }
      pendingStartCompletion = nil
      startRequested = false
      completion(success)
    }

    private func cancelPendingStart() {
      startGeneration &+= 1
      startRequested = false
      guard let completion = pendingStartCompletion else { return }
      pendingStartCompletion = nil
      completion(false)
    }

    private func readiness(waitForFrame: Bool) -> (possible: Bool, timebase: Bool, frame: Bool) {
      if let readinessOverride {
        return readinessOverride()
      }
      let possible = pipController?.isPictureInPicturePossible ?? false
      let timebase = sampleBufferLayer?.controlTimebase != nil
      let frame: Bool
      if !waitForFrame {
        frame = true
      } else if #available(iOS 17.4, *) {
        frame = sampleBufferLayer?.isReadyForDisplay ?? false
      } else {
        frame = true
      }
      return (possible, timebase, frame)
    }

    /// A timed-out start keeps its controller rather than building a replacement
    /// on the same layer: AVKit tracks the layer's PiP player controller through
    /// an unretained association that any of the layer's content sources clears
    /// on dealloc, so freeing the timed-out controller would leave AVKit reading
    /// a freed player controller on the replacement's behalf.
    private func scheduleStartTimeout(generation: Int) {
      startTimeoutScheduler { [weak self] in
        guard let self, !isTornDown, generation == startGeneration,
          startRequested, let completion = pendingStartCompletion
        else { return }
        MpvLog.debug("[MpvPipController] PiP start produced no delegate outcome before the deadline")
        stopTimelineTracking()
        pendingStartCompletion = nil
        startRequested = false
        systemStartExpected = false
        pipController?.stopPictureInPicture()
        completion(false)
      }
    }

    private func retryStart(generation: Int, waitForFrame: Bool, attempts: Int) {
      guard !isTornDown, generation == startGeneration, pendingStartCompletion != nil,
        let pipController
      else { return }

      let readiness = readiness(waitForFrame: waitForFrame)
      if readiness.possible && readiness.timebase && readiness.frame {
        guard !startRequested else { return }
        startRequested = true
        MpvLog.debug("[MpvPipController] vo_avfoundation ready after \(attempts) retries, starting PiP")
        pipController.startPictureInPicture()
        scheduleStartTimeout(generation: generation)
      } else if attempts < 40 {
        retryScheduler { [weak self] in
          self?.retryStart(
            generation: generation, waitForFrame: waitForFrame, attempts: attempts + 1)
        }
      } else {
        MpvLog.debug(
          "[MpvPipController] PiP not ready after \(attempts) retries "
            + "(possible=\(readiness.possible), timebase=\(readiness.timebase))"
        )
        finishStart(generation: generation, success: false)
      }
    }

    func pictureInPictureWillStart(from controller: MpvPictureInPictureControlling) {
      guard !isTornDown, isCurrentController(controller) else { return }
      systemStartExpected = true
      startTimelineTracking()
      delegate?.pipWillStart()
    }

    func pictureInPictureWillStart() {
      guard let pipController else { return }
      pictureInPictureWillStart(from: pipController)
    }

    func pictureInPictureDidStart(from controller: MpvPictureInPictureControlling) {
      guard !isTornDown, isCurrentController(controller) else { return }
      guard systemStartExpected || pendingStartCompletion != nil else {
        controller.stopPictureInPicture()
        return
      }
      hasActiveSession = true
      systemStartExpected = false
      // Resolve the pending manual method call before the delegate publishes
      // PiP state: the plugin's delegate path may suspend the application.
      finishStart(generation: startGeneration, success: true)
      delegate?.pipDidStart()
    }

    func pictureInPictureDidStart() {
      guard let pipController else { return }
      pictureInPictureDidStart(from: pipController)
    }

    func pictureInPictureFailedToStart(
      from controller: MpvPictureInPictureControlling,
      error: Error
    ) {
      guard !isTornDown, isCurrentController(controller),
        systemStartExpected || pendingStartCompletion != nil
      else { return }
      systemStartExpected = false
      stopTimelineTracking()
      delegate?.pipDidFailToStart(error: error)
      finishStart(generation: startGeneration, success: false)
    }

    func pictureInPictureFailedToStart(error: Error) {
      guard let pipController else { return }
      pictureInPictureFailedToStart(from: pipController, error: error)
    }

    func pictureInPictureDidStop(from controller: MpvPictureInPictureControlling) {
      guard !isTornDown, isCurrentController(controller) else { return }
      stopTimelineTracking()
      guard hasActiveSession else { return }
      hasActiveSession = false
      let restored = restoreRequested
      restoreRequested = false
      delegate?.pipDidStop(restored: restored)
    }

    func pictureInPictureDidStop() {
      guard let pipController else { return }
      pictureInPictureDidStop(from: pipController)
    }

    func restoreUserInterface(completion: @escaping (Bool) -> Void) {
      let canRestore = !isTornDown && hasActiveSession && delegate != nil
      restoreRequested = canRestore
      completion(canRestore)
    }

    /// Start PiP. Completion reports the delegate-confirmed terminal outcome.
    func startPip(waitForFrame: Bool = true, completion: @escaping (Bool) -> Void) {
      guard !isTornDown, pipController != nil else {
        completion(false)
        return
      }
      guard pendingStartCompletion == nil else {
        completion(false)
        return
      }
      startGeneration &+= 1
      let generation = startGeneration
      pendingStartCompletion = completion
      startRequested = false
      systemStartExpected = false
      retryStart(generation: generation, waitForFrame: waitForFrame, attempts: 0)
    }

    func stopPip() {
      cancelPendingStart()
      systemStartExpected = false
      restoreRequested = false
      pipController?.stopPictureInPicture()
    }

    /// Invalidate the playback state so PiP re-reads the play state and range.
    func invalidatePlaybackState() {
      guard !isTornDown else { return }
      pipController?.invalidatePlaybackState()
    }

    /// The playback range on the display layer's timeline. PiP shows the
    /// layer timebase's time minus the range start as elapsed time. Host
    /// presentation runs that timebase on mpv's clock at 1x, not on the
    /// playback position, so the range starts at (timebase now - position).
    /// While playing, a seek, a speed other than 1x or a stall moves the two
    /// apart; while paused, a seek from outside PiP moves mpv's position.
    /// `checkTimeline` catches both and re-sends the range.
    fileprivate func playbackTimeRange() -> CMTimeRange {
      guard let timebase = sampleBufferLayer?.controlTimebase,
        let delegate, delegate.pipDuration > 0
      else {
        timelineStart = nil
        timelineDuration = 0
        timelinePosition = 0
        return Self.liveTimeRange
      }
      let duration = delegate.pipDuration
      let position = Self.clampedPosition(delegate.pipPosition, duration: duration)
      let start = CMTimeSubtract(
        CMTimebaseGetTime(timebase), CMTime(seconds: position, preferredTimescale: 1_000_000_000))
      timelineStart = start
      timelineDuration = duration
      timelinePosition = position
      return CMTimeRange(start: start, duration: CMTime(seconds: duration, preferredTimescale: 1_000_000_000))
    }

    private static func clampedPosition(_ position: Double, duration: Double) -> Double {
      min(max(position, 0), duration)
    }

    private func startTimelineTracking() {
      timelineTimer?.invalidate()
      let timer = Timer(timeInterval: Self.timelineCheckInterval, repeats: true) { [weak self] _ in
        self?.checkTimeline()
      }
      RunLoop.main.add(timer, forMode: .common)
      timelineTimer = timer
    }

    private func stopTimelineTracking() {
      timelineTimer?.invalidate()
      timelineTimer = nil
      timelineStart = nil
      timelineDuration = 0
      timelinePosition = 0
    }

    private func checkTimeline() {
      guard !isTornDown, let delegate, let timebase = sampleBufferLayer?.controlTimebase else { return }
      guard let start = timelineStart else {
        // A live range until the duration is known.
        if delegate.pipDuration > 0 { invalidatePlaybackState() }
        return
      }
      let duration = delegate.pipDuration
      guard duration == timelineDuration else {
        invalidatePlaybackState()
        return
      }
      // Playing, PiP shows the running timebase minus the range start.
      // Paused, it holds the elapsed time from when the range was last sent
      // (the pause itself re-sends it), so a seek from outside PiP, such as
      // Control Center, Watch Together or the companion remote, only shows
      // once the range is sent again.
      let shown =
        delegate.isPipPlaying
        ? CMTimeGetSeconds(CMTimeSubtract(CMTimebaseGetTime(timebase), start))
        : timelinePosition
      if abs(shown - Self.clampedPosition(delegate.pipPosition, duration: duration)) > Self.timelineTolerance {
        invalidatePlaybackState()
      }
    }

    /// Fully tear down PiP without touching the shared inline display layer.
    func teardown() {
      guard !isTornDown else { return }
      cancelPendingStart()
      isTornDown = true
      systemStartExpected = false
      hasActiveSession = false
      restoreRequested = false
      stopTimelineTracking()
      if #available(iOS 15.0, *) {
        (delegateHelper as? PipDelegateHelper)?.controller = nil
        (pipController as? AVPictureInPictureController)?.delegate = nil
      }
      pipController?.setAutomaticStart(false)
      pipController?.stopPictureInPicture()
      pipController = nil
      delegateHelper = nil
      delegate = nil
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

    init(controller: MpvPipController) {
      self.controller = controller
      super.init()
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureControllerWillStartPictureInPicture(
      _ pictureInPictureController: AVPictureInPictureController
    ) {
      MpvLog.debug("[MpvPipController] PiP will start")
      controller?.pictureInPictureWillStart(from: pictureInPictureController)
    }

    func pictureInPictureControllerDidStartPictureInPicture(
      _ pictureInPictureController: AVPictureInPictureController
    ) {
      MpvLog.debug("[MpvPipController] PiP did start")
      controller?.pictureInPictureDidStart(from: pictureInPictureController)
    }

    func pictureInPictureControllerDidStopPictureInPicture(
      _ pictureInPictureController: AVPictureInPictureController
    ) {
      MpvLog.debug("[MpvPipController] PiP did stop")
      controller?.pictureInPictureDidStop(from: pictureInPictureController)
    }

    func pictureInPictureController(
      _ pictureInPictureController: AVPictureInPictureController,
      failedToStartPictureInPictureWithError error: Error
    ) {
      MpvLog.debug("[MpvPipController] PiP failed to start: \(error)")
      controller?.pictureInPictureFailedToStart(
        from: pictureInPictureController,
        error: error
      )
    }

    func pictureInPictureController(
      _ pictureInPictureController: AVPictureInPictureController,
      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler:
        @escaping (Bool) -> Void
    ) {
      MpvLog.debug("[MpvPipController] PiP restore user interface")
      guard let controller,
        controller.isCurrentController(pictureInPictureController)
      else {
        completionHandler(false)
        return
      }
      controller.restoreUserInterface(completion: completionHandler)
    }

    func pictureInPictureControllerWillStopPictureInPicture(
      _ pictureInPictureController: AVPictureInPictureController
    ) {
      guard controller?.isCurrentController(pictureInPictureController) == true else { return }
      MpvLog.debug("[MpvPipController] PiP will stop")
    }
    // MARK: - AVPictureInPictureSampleBufferPlaybackDelegate

    func pictureInPictureController(
      _ pictureInPictureController: AVPictureInPictureController,
      setPlaying playing: Bool
    ) {
      guard let controller,
        controller.isCurrentController(pictureInPictureController)
      else { return }
      MpvLog.debug("[MpvPipController] PiP setPlaying: \(playing)")
      controller.delegate?.pipSetPlaying(playing)
    }

    func pictureInPictureControllerTimeRangeForPlayback(
      _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
      guard let controller,
        controller.isCurrentController(pictureInPictureController)
      else {
        return MpvPipController.liveTimeRange
      }
      return controller.playbackTimeRange()
    }

    func pictureInPictureControllerIsPlaybackPaused(
      _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
      guard let controller,
        controller.isCurrentController(pictureInPictureController)
      else { return true }
      return !(controller.delegate?.isPipPlaying ?? false)
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
      guard let controller,
        controller.isCurrentController(pictureInPictureController)
      else {
        completionHandler()
        return
      }
      let seconds = CMTimeGetSeconds(skipInterval)
      MpvLog.debug("[MpvPipController] PiP skip by \(seconds)s")
      guard let delegate = controller.delegate else {
        completionHandler()
        return
      }
      delegate.pipSkip(byInterval: seconds, completion: completionHandler)
    }
  }

#endif  // !os(tvOS)
