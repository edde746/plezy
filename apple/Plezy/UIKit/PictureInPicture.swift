#if os(iOS)
import AVKit
import Observation
import os
import OSLog
import PlezyKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "player")

/// iOS's picture in picture over mpv's avfoundation VO (PiP is native, not shared): an `AVPictureInPictureController`
/// over the surface's `AVSampleBufferDisplayLayer`, the layer mpv's avfoundation VO enqueues into. The VO presents on
/// the media timeline and owns the layer's control timebase, which is what the PiP window's progress reads. The Mac's
/// counterpart, under the same name, is AppKit/PictureInPicture.swift.
///
/// PiP can start (`possible`) once AVKit says it can and the layer shows mpv's video: the VO's timebase is on it and,
/// from iOS 17.4, its first frame is ready for display. AVKit says PiP is possible
/// as soon as the layer is on screen, before mpv has shown anything, and a start then fails (`PGPegasusErrorDomain`
/// -1003) with nothing to see, so the player's button stays disabled until the video is up, while a stream loads. It
/// also stays disabled where AVKit doesn't support PiP at all (the iPhone simulators). The layer is read again when
/// AVKit's answer changes, when the engine has shown a format (`videoShown`) and before a start; where the layer lags
/// behind the video, a few times more, 100 ms apart. Nothing reads it while no video shows (a stream that loads, fails
/// or has no video). AVKit's controller itself is set up once the video's first frame has shown (`setUp`, from
/// `PlayerScreen`), not in the frames that bring the player up.
///
/// PiP shows the samples on the display layer alone, not the VO's subtitle layer beside it: from its start (the
/// player's button, or AVKit's will-start for one by Home) until it ends or fails to start, mpv draws the subtitles
/// into the video's frames instead (`onSubtitlesInPicture`).
///
/// The PiP window's controls are OS media controls like Now Playing: they show the shared `NowPlaying` (paused, the
/// duration) and act through its `MediaCommand`s (play, pause, skip), so they behave exactly like the player's own.
/// PiP starts from the player's button, or on its own when the app goes to the background while the video plays. The
/// button ends it again, as does the window's way back to the app, and the playback goes on; closed in the window
/// instead, the playback pauses, as the system player's does. The end of the playback closes it. While it runs the
/// player stays up under AVKit's placeholder with close and the PiP button alone (`TouchControls`): the window's own
/// controls play, pause and skip.
///
/// The window's progress is the display layer's clock less the start of the range handed to AVKit
/// (`timeRangeForPlayback`: the clock's time less the engine's position, `readPosition`). A seek, another speed or a
/// stall moves the two apart while it plays, and a seek from elsewhere (Now Playing, watch together, the companion
/// remote) while it is paused: from its start until it ends, every 0.5 s, a range whose progress is more than 0.25 s
/// off the position, or whose length is no longer the duration, is handed again (`checkTimeline`), as is one 100 ms
/// after the window's skip.
///
/// AVKit doesn't promise the thread it calls the delegates on, and KVO reports a change on the thread that made it,
/// so they read a copy of the state under a lock (`playback`, `timeline`, `position`) and hop to the main actor to act.
@MainActor
@Observable
final class PictureInPicture: NSObject {
    /// PiP can start now: the device supports it, AVKit says it can and the layer shows mpv's video.
    private(set) var possible = false
    private(set) var active = false
    /// AVKit is starting PiP (from its will-start until it started or failed to).
    private(set) var starting = false
    /// The engine's: draws the subtitles into the video's frames (true) or on their own layer again (false).
    @ObservationIgnored var onSubtitlesInPicture: ((Bool) -> Void)?
    /// A start from the player's button failed (the layer not ready, AVKit's error, or no start within `startTimeout`):
    /// the player says why (`PlayerStore.onPictureInPictureFailed`). A start by itself as the app leaves reports nothing.
    @ObservationIgnored var onStartFailed: ((PictureInPictureResultFailed) -> Void)?

    @ObservationIgnored private let layer: AVSampleBufferDisplayLayer
    /// The display layer's clock (its `controlTimebase`, which vo_avfoundation sets) as last read on the main actor
    /// (`update`, `checkTimeline`), for AVKit's threads (`timeRangeForPlayback`).
    @ObservationIgnored private let clock = OSAllocatedUnfairLock<CMTimebase?>(uncheckedState: nil)
    @ObservationIgnored private var controller: AVPictureInPictureController?
    /// AVKit's `isPictureInPicturePossible`.
    @ObservationIgnored private var observation: NSKeyValueObservation?
    /// The engine has shown a format (`videoShown`): until then the layer has nothing to be ready with.
    @ObservationIgnored private var videoShownOnce = false
    /// The next read of the layer while AVKit says PiP is possible but the layer isn't ready yet, and how many are left.
    @ObservationIgnored private var recheck: Task<Void, Never>?
    @ObservationIgnored private var rechecksLeft = 0
    /// The subtitles go into the video's frames (`onSubtitlesInPicture`), as last asked.
    @ObservationIgnored private var subtitlesInPicture = false
    @ObservationIgnored private weak var nowPlaying: NowPlayingCenter?
    /// The user returned to the app from the PiP window (rather than closing it).
    @ObservationIgnored private var restoring = false
    /// What the delegates report, copied from Now Playing on the main actor and read on AVKit's threads.
    @ObservationIgnored private let playback = OSAllocatedUnfairLock(initialState: PlaybackReport())
    /// The range last handed to AVKit (`timeRangeForPlayback`), on AVKit's threads and the main actor.
    @ObservationIgnored private let timeline = OSAllocatedUnfairLock(initialState: Timeline())
    /// Where the playback is: the engine's position (`readPosition`), read on AVKit's threads and the main actor.
    @ObservationIgnored private let position = OSAllocatedUnfairLock<(@Sendable () -> Double)?>(initialState: nil)
    /// The check of the window's progress against the position, every `timelineInterval` while PiP is up.
    @ObservationIgnored private var timelineCheck: Task<Void, Never>?

    /// The PiP window's playback state: paused, and the duration (0 while unknown) or a live playback.
    private struct PlaybackReport {
        var paused = true
        var duration = 0.0
        var live = false
    }

    /// The range last handed to AVKit: where it starts on the display layer's clock (nil while there is none, or a
    /// live one), its length and the position it was handed at.
    private struct Timeline {
        var start: CMTime?
        var duration = 0.0
        var position = 0.0
    }

    /// How often the window's progress is checked while PiP is up, how far it may be off the position before the
    /// range is handed again, and how long after the window's skip it is handed again.
    private static let timelineInterval = Duration.milliseconds(500)
    private static let timelineTolerance = 0.25
    private static let skipSettle = Duration.milliseconds(100)

    /// Reads of the layer after a trigger while it lags behind the video, 50 ms apart (`PictureInPictureRules`).
    private static let rechecks = Int(PictureInPictureRules.shared.READY_RETRIES)
    private static let recheckMillis = Int(PictureInPictureRules.shared.READY_RETRY_MILLIS)
    /// How long a start from the button waits for AVKit to say it started.
    private static let startTimeout = Duration.milliseconds(PictureInPictureRules.shared.START_TIMEOUT_MILLIS)

    /// PiP starts by itself as the app leaves while the video plays (the `auto_pip` setting, `AppSettings.autoPipOn`).
    @ObservationIgnored var autoPipOn = true {
        didSet { updateAutomaticStart() }
    }
    @ObservationIgnored private var playing = false
    /// The button's start, until AVKit says it started or failed, or the timeout: one at a time.
    @ObservationIgnored private var pendingStart: Task<Void, Never>?
    /// The button started PiP: once it has, the app goes to the background, as the system player's does.
    @ObservationIgnored private var manualStart = false
    /// `setUp` ran, or the playback ended first: the controller is made once, never after `stop`.
    @ObservationIgnored private var setUpDone = false

    /// PiP shows the video, or is about to: mpv must keep decoding it (`ApplePlayback`).
    var showsVideo: Bool { active || starting }

    init(layer: AVSampleBufferDisplayLayer) {
        self.layer = layer
        super.init()
    }

    /// Sets AVKit's controller up over the layer, once; nothing after `stop`.
    func setUp() {
        guard !setUpDone else { return }
        setUpDone = true
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            log.info("picture in picture: not supported on this device")
            return
        }
        let controller = AVPictureInPictureController(contentSource: .init(sampleBufferDisplayLayer: layer, playbackDelegate: self))
        controller.delegate = self
        self.controller = controller
        updateAutomaticStart()
        observation = controller.observe(\.isPictureInPicturePossible) { @Sendable [weak self] _, _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh()
    }

    /// Takes the PiP window's state from `nowPlaying` and sends its commands there.
    func follow(_ nowPlaying: NowPlayingCenter) {
        self.nowPlaying = nowPlaying
        nowPlaying.onChange = { [weak self, weak nowPlaying] in
            guard let self else { return }
            let current = nowPlaying?.current
            let report = PlaybackReport(
                paused: !(current?.playing ?? false),
                duration: current?.durationSeconds ?? 0,
                live: current?.live ?? false
            )
            playback.withLock { $0 = report }
            controller?.invalidatePlaybackState()
            playing = !report.paused
            updateAutomaticStart()
        }
    }

    /// Reads the playback's position from `source` (the engine's), on any thread.
    nonisolated func readPosition(from source: @escaping @Sendable () -> Double) {
        position.withLock { $0 = source }
    }

    /// The playback's position within `duration`.
    private nonisolated func currentPosition(within duration: Double) -> Double {
        let read = position.withLock { $0 }
        return min(max(read?() ?? 0, 0), duration)
    }

    /// Checks the window's progress every `timelineInterval` while `tracking` (from AVKit's will-start until PiP ends).
    private func trackTimeline(_ tracking: Bool) {
        timelineCheck?.cancel()
        timelineCheck = nil
        guard tracking else { return }
        timelineCheck = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.timelineInterval)
                guard !Task.isCancelled, let self else { return }
                self.checkTimeline()
            }
        }
    }

    /// Hands AVKit the range again when the window's progress is off: a duration known since a live range was handed,
    /// another duration, or a progress more than `timelineTolerance` from the position. Playing, the window shows the
    /// clock less the range's start; paused, the position the range was handed at.
    private func checkTimeline() {
        let timebase = layer.controlTimebase
        clock.withLockUnchecked { $0 = timebase }
        guard let controller, let timebase else { return }
        let report = playback.withLock { $0 }
        let handed = timeline.withLock { $0 }
        guard let start = handed.start else {
            if report.duration > 0, !report.live { controller.invalidatePlaybackState() }
            return
        }
        guard report.duration == handed.duration else { return controller.invalidatePlaybackState() }
        let shown = report.paused ? handed.position : CMTimeGetSeconds(CMTimeSubtract(CMTimebaseGetTime(timebase), start))
        if abs(shown - currentPosition(within: report.duration)) > Self.timelineTolerance {
            controller.invalidatePlaybackState()
        }
    }

    /// Auto-PiP is ready while it is on and the video plays (`PictureInPictureRules.autoEnterReady`).
    private func updateAutomaticStart() {
        controller?.canStartPictureInPictureAutomaticallyFromInline = PictureInPictureRules.shared.autoEnterReady(autoPipOn: autoPipOn, playing: playing)
    }

    /// Starts PiP, or stops it when it is up. A start waits up to `startTimeout` for AVKit; one at a time.
    func toggle() {
        guard let controller else { return }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            refresh()
            guard pendingStart == nil else { return }
            guard possible else { return reportStartFailed(.prepareFailed) }
            drawSubtitlesInPicture(true)
            manualStart = true
            controller.startPictureInPicture()
            pendingStart = Task { [weak self] in
                try? await Task.sleep(for: Self.startTimeout)
                guard let self, !Task.isCancelled else { return }
                self.pendingStart = nil
                if !self.active {
                    log.error("picture in picture: no start after \(Self.startTimeout, privacy: .public)")
                    self.manualStart = false
                    self.starting = false
                    self.drawSubtitlesInPicture(false)
                    self.reportStartFailed(.failed)
                }
            }
        }
    }

    private func startEnded() {
        pendingStart?.cancel()
        pendingStart = nil
    }

    private func reportStartFailed(_ error: PictureInPictureError) {
        onStartFailed?(PictureInPictureResultFailed(code: error.code, message: nil))
    }

    /// The engine has shown the video in a format (the first frame of a file, or another format): the layer can be ready.
    func videoShown() {
        videoShownOnce = true
        refresh()
    }

    /// The playback ended: PiP closes and no longer starts on its own.
    func stop() {
        setUpDone = true
        guard let controller else { return }
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        startEnded()
        if controller.isPictureInPictureActive { controller.stopPictureInPicture() }
        observation = nil
        self.controller = nil
        recheck?.cancel()
        recheck = nil
        trackTimeline(false)
        possible = false
    }

    /// Reads the layer again after a trigger, with a fresh allowance of rechecks.
    private func refresh() {
        rechecksLeft = Self.rechecks
        update()
    }

    /// Reads again whether PiP can start; a change is logged with what made it. While AVKit says PiP is possible, the
    /// engine has shown the video and the layer isn't ready yet, it reads again in 100 ms, while rechecks are left.
    private func update() {
        guard let controller else { return }
        let system = controller.isPictureInPicturePossible
        let clockNow = layer.controlTimebase
        clock.withLockUnchecked { $0 = clockNow }
        let timebase = clockNow != nil
        let frame: Bool
        if #available(iOS 17.4, *) {
            frame = layer.isReadyForDisplay
        } else {
            frame = true
        }
        let now = system && timebase && frame
        if system, !now, videoShownOnce, recheck == nil, rechecksLeft > 0 {
            rechecksLeft -= 1
            recheck = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(Self.recheckMillis))
                guard !Task.isCancelled else { return }
                self?.recheck = nil
                self?.update()
            }
        }
        guard now != possible else { return }
        possible = now
        log.info("picture in picture \(now ? "possible" : "not possible", privacy: .public): AVKit \(system, privacy: .public), timebase \(timebase, privacy: .public), first frame \(frame, privacy: .public)")
    }

    private func drawSubtitlesInPicture(_ inPicture: Bool) {
        guard inPicture != subtitlesInPicture else { return }
        subtitlesInPicture = inPicture
        onSubtitlesInPicture?(inPicture)
    }

    private func perform(_ command: any MediaCommand) {
        nowPlaying?.commands?.perform(command: command)
    }

    /// `command` on the main actor, from a delegate on any thread.
    private nonisolated func send(_ command: @escaping @Sendable () -> any MediaCommand) {
        Task { @MainActor in
            let value = command()
            self.perform(value)
        }
    }
}

extension PictureInPicture: AVPictureInPictureControllerDelegate {
    nonisolated func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            self.starting = true
            self.drawSubtitlesInPicture(true)
            self.trackTimeline(true)
        }
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        log.info("picture in picture started")
        Task { @MainActor in
            self.restoring = false
            self.starting = false
            self.active = true
            self.startEnded()
            // Started from the button: the app goes to the background, leaving the window over the home screen.
            if self.manualStart {
                self.manualStart = false
                UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
            }
        }
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        // The player stays presented under PiP, so there is nothing to rebuild.
        Task { @MainActor in self.restoring = true }
        completionHandler(true)
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            log.info("picture in picture stopped: \(self.restoring ? "back to the player" : "closed, pausing", privacy: .public)")
            self.active = false
            self.trackTimeline(false)
            self.drawSubtitlesInPicture(false)
            if !self.restoring { self.perform(MediaCommandPause.shared) }
            self.restoring = false
        }
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: any Error
    ) {
        log.error("picture in picture failed to start: \(String(describing: error), privacy: .public)")
        Task { @MainActor in
            let manual = self.manualStart
            self.starting = false
            self.manualStart = false
            self.startEnded()
            self.trackTimeline(false)
            self.drawSubtitlesInPicture(false)
            if manual { self.reportStartFailed(.failed) }
        }
    }
}

extension PictureInPicture: AVPictureInPictureSampleBufferPlaybackDelegate {
    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        send { playing ? MediaCommandPlay.shared as any MediaCommand : MediaCommandPause.shared }
    }

    /// The range from the display layer's clock less the position, as long as the duration; for a live playback, one of
    /// unknown duration or before the layer has a clock, a live range: no progress, no skipping.
    nonisolated func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        let report = playback.withLock { $0 }
        guard report.duration > 0, !report.live, let timebase = clock.withLockUnchecked({ $0 }) else {
            timeline.withLock { $0 = Timeline() }
            return CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
        }
        let position = currentPosition(within: report.duration)
        let start = CMTimeSubtract(CMTimebaseGetTime(timebase), CMTime(seconds: position, preferredTimescale: 1_000_000_000))
        timeline.withLock { $0 = Timeline(start: start, duration: report.duration, position: position) }
        return CMTimeRange(start: start, duration: CMTime(seconds: report.duration, preferredTimescale: 1_000_000_000))
    }

    nonisolated func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        playback.withLock { $0.paused }
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {}

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        let seconds = skipInterval.seconds
        let completion = UncheckedBox(completionHandler)
        Task { @MainActor in
            self.perform(MediaCommandSeekBy(seconds: seconds))
            // The seek lands on the engine's queue: the window reads the range once it has.
            try? await Task.sleep(for: Self.skipSettle)
            self.controller?.invalidatePlaybackState()
            completion.value()
        }
    }
}
#endif
