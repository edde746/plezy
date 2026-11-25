import Observation
import OSLog
import PlezyKit

#if os(macOS)
import AppKit
import IOKit.pwr_mgt
#else
import UIKit
#endif

private let log = Logger(subsystem: "com.edde746.plezy", category: "player")

/// The Apple side of one playback (the shared `PlatformPlayback`), made by `AppleAppPlatform` for each one: mpv's
/// surface and the engine on it, the OS media controls (`nowPlaying`), the display following the shared output policy
/// and kept awake while the store says so (`keepDisplayAwake`), and on iOS and tvOS the audio session and the
/// video decoded only while someone sees it (`decodeVideoWhileSeen`). The shared
/// `PlaybackController` builds the session and the player store over it and ends it in order: the media controls and
/// the display first (which may sleep again), then `release()` (picture in picture stops, the audio session ends, on
/// tvOS the TV gets its own mode back unless another playback took the player's place, and on the Mac the surface
/// hides its layer and takes it out of the view tree, so nothing makes mpv draw again), then the store, and last the
/// session, which releases the engine (mpv tears down on its own queue).
///
/// Not an NSObject subclass: NSObject's (ARC-unavailable) `-release` would make the protocol's `release()` ambiguous.
@MainActor
final class ApplePlayback: @preconcurrency PlatformPlayback {
    let surface: VideoSurface
    let nowPlaying: NowPlayingCenter
    let mpv: MpvPlayerEngine
    private let outputHost: ApplePlaybackOutput
    #if os(iOS) || os(tvOS)
    private var audio: PlaybackAudioSession?
    #endif
    /// The playback's store while it runs, which hears the player go out of sight and come back and, on iOS and macOS,
    /// picture in picture come and go.
    private weak var attachedStore: PlayerStore?
    /// The observers of the player going out of sight and coming back (`followVisibility`), while the playback runs.
    private var visibilityObservers: [any NSObjectProtocol] = []
    #if os(iOS) || os(tvOS)
    /// The app is in the background (`followVisibility`, from the attach on: a playback that starts there, the next
    /// episode, starts so): mpv decodes the video only while someone sees it, on iOS picture in picture
    /// (`decodeVideoWhileSeen`).
    private var inBackground = false
    #endif
    #if os(macOS)
    /// The PreventUserIdleDisplaySleep assertion while the display is kept awake (`keepDisplayAwake`).
    private var displayAssertion: IOPMAssertionID?
    /// The store keeps the display awake: the video plays in sight or in picture in picture (`keepDisplayAwake`).
    private var keepAwake = false
    /// The player's window is in sight, and the screens are asleep (`followVisibility`): the video shows only while
    /// the one is and the other isn't (`showVideoWhileSeen`).
    private var windowVisible = true
    private var screensAsleep = false
    /// The observers of the screens' sleep and wake, on the workspace's notification center.
    private var workspaceObservers: [any NSObjectProtocol] = []
    /// The process's user-initiated, latency-critical activity while the video plays and the screens are awake
    /// (`updatePlaybackActivity`): App Nap and timer coalescing stay off the playback.
    private var playbackActivity: (any NSObjectProtocol)?
    #endif
    #if DEBUG && !os(macOS)
    let idleTimer = IdleTimerReading()
    #endif

    /// - Parameters:
    ///   - settings: the device settings the playback starts with (the engine's HDR output and Dolby Vision conversion,
    ///     on tvOS the Dolby Vision rules of the TV's criteria).
    ///   - speeds: the Now Playing rates, the player's own speeds.
    init(settings: DeviceSettings, speeds: [Double]) {
        #if os(macOS)
        surface = VideoSurface()
        #else
        surface = VideoSurface(settings: settings)
        #endif
        mpv = MpvPlayerEngine(surface: surface, settings: settings)
        nowPlaying = NowPlayingCenter(speeds: speeds)
        outputHost = ApplePlaybackOutput(surface: surface, engine: mpv)
        #if os(iOS) || os(macOS)
        surface.pictureInPicture.follow(nowPlaying)
        #endif
        #if os(iOS)
        surface.pictureInPicture.readPosition { [mpv] in mpv.positionSeconds }
        #endif
    }

    var engine: any PlayerEngine { mpv }

    /// iOS: with auto picture in picture on, the window may open as the app leaves, so the lifecycle is left alone;
    /// the Mac plays on in the background and tvOS has no auto start.
    var pictureInPictureStarting: Bool {
        #if os(iOS)
        surface.pictureInPicture.autoPipOn
        #else
        false
        #endif
    }

    /// VideoToolbox; the simulators have none and always decode in software.
    var hardwareDecoder: HardwareDecoder {
        #if targetEnvironment(simulator)
        .appleSimulator
        #else
        .apple
        #endif
    }

    var mediaControls: (any MediaControlsHost)? { nowPlaying }

    var output: (any PlaybackOutputHost)? { outputHost }

    /// libplacebo runs mpv's shaders on the display layer output, ambient lighting's among them.
    var runsAmbientLighting: Bool { true }

    func attach(store: PlayerStore) {
        #if os(iOS) || os(tvOS)
        audio = PlaybackAudioSession(store: store) { [mpv] in mpv.reloadAudioOutput() }
        #endif
        attachedStore = store
        followVisibility()
        #if os(iOS) || os(macOS)
        followPictureInPicture()
        // A failed start from the button says why, as the player's transient message.
        surface.pictureInPicture.onStartFailed = { [weak store] failure in
            store?.onPictureInPictureFailed(text: PictureInPictureRules.shared.message(result: failure))
        }
        #endif
    }

    func release() {
        attachedStore = nil
        visibilityObservers.forEach(NotificationCenter.default.removeObserver)
        visibilityObservers = []
        #if os(macOS)
        workspaceObservers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        workspaceObservers = []
        #endif
        // The controller lets the display sleep before this; a playback released without that holds nothing either.
        keepDisplayAwake(awake: false)
        #if os(iOS)
        surface.pictureInPicture.stop()
        #else
        surface.endPlayback()
        #endif
        #if os(iOS) || os(tvOS)
        audio?.end()
        audio = nil
        #endif
    }

    /// On the Mac one PreventUserIdleDisplaySleep assertion while `awake`, released once it isn't, and the playback's
    /// activity with it (`updatePlaybackActivity`); on iOS and tvOS the app's idle timer off while `awake`. Each change
    /// is logged with what the OS holds.
    func keepDisplayAwake(awake: Bool) {
        #if os(macOS)
        keepAwake = awake
        updatePlaybackActivity()
        if awake, displayAssertion == nil {
            var id = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Plezy is playing a video" as CFString,
                &id
            )
            guard result == kIOReturnSuccess else {
                return log.error("keep awake: IOPMAssertionCreateWithName failed: 0x\(UInt32(bitPattern: result), format: .hex, privacy: .public)")
            }
            displayAssertion = id
            log.notice("keep awake: display sleep assertion \(id, privacy: .public) created")
        } else if !awake, let id = displayAssertion {
            displayAssertion = nil
            let result = IOPMAssertionRelease(id)
            guard result == kIOReturnSuccess else {
                return log.error("keep awake: IOPMAssertionRelease(\(id, privacy: .public)) failed: 0x\(UInt32(bitPattern: result), format: .hex, privacy: .public)")
            }
            log.notice("keep awake: display sleep assertion \(id, privacy: .public) released")
        }
        #else
        let application = UIApplication.shared
        if application.isIdleTimerDisabled != awake {
            application.isIdleTimerDisabled = awake
            log.notice("keep awake: \(awake, privacy: .public), isIdleTimerDisabled=\(application.isIdleTimerDisabled, privacy: .public)")
        }
        #if DEBUG
        idleTimer.summary = "idleTimerDisabled=\(application.isIdleTimerDisabled)"
        #endif
        #endif
    }

    /// The store hears the player go out of sight and come back (`PlayerStore.onVisibleChanged`) until the playback is
    /// released: on the Mac its window's occlusion (minimized, hidden, covered whole), on iOS and tvOS the app going to
    /// the background and coming back. On the Mac the video hides meanwhile, and while the screens sleep, which doesn't
    /// always change the window's occlusion (`showVideoWhileSeen`).
    private func followVisibility() {
        let center = NotificationCenter.default
        #if os(macOS)
        visibilityObservers = [
            center.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: nil, queue: .main) { [weak self] notification in
                let changed = notification.object.map { ObjectIdentifier($0 as AnyObject) }
                MainActor.assumeIsolated {
                    guard let self, let window = self.surface.window, changed == ObjectIdentifier(window) else { return }
                    let visible = window.occlusionState.contains(.visible)
                    self.attachedStore?.onVisibleChanged(visible: visible)
                    self.windowVisible = visible
                    self.showVideoWhileSeen()
                }
            },
        ]
        let workspace = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            (NSWorkspace.screensDidSleepNotification, true),
            (NSWorkspace.screensDidWakeNotification, false),
        ].map { name, asleep in
            workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.screensAsleep = asleep
                    self.showVideoWhileSeen()
                }
            }
        }
        #else
        inBackground = UIApplication.shared.applicationState == .background
        visibilityObservers = [
            (UIApplication.didEnterBackgroundNotification, false),
            (UIApplication.willEnterForegroundNotification, true),
        ].map { name, visible in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, let store = self.attachedStore else { return }
                    store.onVisibleChanged(visible: visible)
                    self.inBackground = !visible
                    if visible { self.surface.recoverDisplayLayer() }
                    self.decodeVideoWhileSeen()
                }
            }
        }
        #endif
    }

    #if os(macOS)
    /// The video shows only while someone may see it: the window in sight and the screens awake (picture in picture
    /// keeps the video's layers in its own window). Back in sight, a display layer the surface had to flush draws its
    /// paused frame again.
    private func showVideoWhileSeen() {
        let outOfSight = !windowVisible || screensAsleep
        log.notice("video \(outOfSight ? "hidden: out of sight" : "shown", privacy: .public) (window \(self.windowVisible ? "visible" : "occluded", privacy: .public), screens \(self.screensAsleep ? "asleep" : "awake", privacy: .public))")
        if surface.setOutOfSight(outOfSight) { mpv.redrawIfPaused() }
        updatePlaybackActivity()
    }

    /// A user-initiated, latency-critical activity (`ProcessInfo.beginActivity`) while the store keeps the display
    /// awake (the video plays in sight, or in picture in picture) and the screens are awake; ended otherwise.
    private func updatePlaybackActivity() {
        let wanted = keepAwake && !screensAsleep
        if wanted, playbackActivity == nil {
            playbackActivity = ProcessInfo.processInfo.beginActivity(options: [.userInitiated, .latencyCritical], reason: "Video playback")
            log.notice("playback activity began")
        } else if !wanted, let activity = playbackActivity {
            ProcessInfo.processInfo.endActivity(activity)
            playbackActivity = nil
            log.notice("playback activity ended")
        }
    }
    #endif

    #if os(iOS) || os(tvOS)
    /// Video nobody sees isn't decoded: in the background (on iOS without picture in picture showing it, or starting
    /// to: it starts on its own as the app leaves), mpv plays the sound alone; back in the app, or with picture in
    /// picture up, the video again.
    private func decodeVideoWhileSeen() {
        #if os(iOS)
        mpv.setVideoSuspended(inBackground && !surface.pictureInPicture.showsVideo)
        #else
        mpv.setVideoSuspended(inBackground)
        #endif
    }
    #endif

    #if os(iOS) || os(macOS)
    /// The store hears picture in picture come and go, the window showing the whole picture meanwhile
    /// (`PlayerStore.onPictureInPictureChanged`), until the playback is released. On iOS mpv decodes the video in the
    /// background while picture in picture shows it (`decodeVideoWhileSeen`).
    private func followPictureInPicture() {
        guard let store = attachedStore else { return }
        let pictureInPicture = surface.pictureInPicture
        let active = withObservationTracking {
            #if os(iOS)
            _ = pictureInPicture.showsVideo
            #endif
            return pictureInPicture.active
        } onChange: { [weak self] in
            // Called as `active` is about to change: the new value is read once it has.
            Task { @MainActor [weak self] in self?.followPictureInPicture() }
        }
        store.onPictureInPictureChanged(active: active)
        #if os(iOS)
        decodeVideoWhileSeen()
        #endif
    }
    #endif
}
