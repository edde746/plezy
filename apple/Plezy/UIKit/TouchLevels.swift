#if os(iOS)
import AVFoundation
import MediaPlayer
import OSLog
import SwiftUI
import PlezyKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "player")

/// The screen's brightness and the system's volume, which swipes up and down the video's edges set (the shared
/// player's `DeviceLevels`): one for the process, the platform's `deviceLevels`. Main thread; both read at once.
///
/// The brightness is the screen's, for the whole system: the level the app's screen (its window scene's, not the main
/// screen: an iPhone Duo's inner or outer display) had before the first swipe comes back to that screen as the player
/// closes (the shared playback's end), as the app resigns active (Control Center, Notification Center, the app
/// switcher, a call; VLC for iOS gives it back there too) and as picture in picture starts (`PlayerScreen`), and the
/// next swipe starts from the screen's own level again. A swipe after the app moved to another screen first gives the
/// screen it left its own level back, then starts from the new screen's. Between those the swipes go on from the level
/// they set, which the simulator's screen doesn't read back.
///
/// The volume is the system's, set as VLC for iOS 3.7.3 sets it, iOS offering apps no other way: through the slider of
/// an `MPVolumeView` among the player's views (`SystemVolumeControl`), nearly transparent, which also keeps the system's
/// volume panel away while it is there; the slider's value set a moment later, the audio session active.
@MainActor
final class TouchLevels: NSObject, @preconcurrency DeviceLevels {
    static let shared = TouchLevels()

    /// The system's volume control, in the player's views while it is up.
    let volumeView: MPVolumeView

    /// The screen the swipes since the last restore set, its level before the first of them, and the level they set.
    private var brightness: (screen: UIScreen, before: CGFloat, level: CGFloat)?
    /// The volume the last swipe set, and when. The system reports a volume set through the slider a moment later, so
    /// within `volumeSettles` of a swipe's write the level reads as it set, and after it as the system reports (the
    /// volume buttons may have moved it).
    private var volume: (level: Float, at: ContinuousClock.Instant)?
    private static let volumeSettles = Duration.seconds(1)

    override private init() {
        volumeView = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        // Not hidden, which would bring the system's volume panel back: transparent to the eye alone.
        volumeView.alpha = 0.00001
        volumeView.isUserInteractionEnabled = false
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(resignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    func readBrightness(result: @escaping (KotlinDouble?) -> Void) {
        guard let screen = ApplePlatform.windowScreen else {
            log.error("brightness: the app has no screen")
            result(nil)
            return
        }
        let level = brightness.flatMap { $0.screen === screen ? $0.level : nil }
        result(KotlinDouble(double: Double(level ?? screen.brightness)))
    }

    func setBrightness(level: Double) {
        guard let screen = ApplePlatform.windowScreen else {
            log.error("brightness: the app has no screen")
            return
        }
        // The app moved to another screen: the one it left gets its own level back.
        if let held = brightness, held.screen !== screen { restoreBrightness() }
        let value = CGFloat(min(max(level, 0), 1))
        brightness = (screen, brightness?.before ?? screen.brightness, value)
        screen.brightness = value
    }

    func restoreBrightness() {
        guard let held = brightness else { return }
        brightness = nil
        held.screen.brightness = held.before
    }

    func readVolume(result: @escaping (KotlinDouble?) -> Void) {
        if let volume, ContinuousClock.now - volume.at < Self.volumeSettles {
            result(KotlinDouble(double: Double(volume.level)))
        } else {
            result(KotlinDouble(double: Double(AVAudioSession.sharedInstance().outputVolume)))
        }
    }

    func setVolume(level: Double) {
        let session = AVAudioSession.sharedInstance()
        let now = ContinuousClock.now
        let swiping = volume.map { now - $0.at < Self.volumeSettles } ?? false
        guard volumeView.window != nil, let slider = volumeSlider else {
            // No volume to set where the control shows no slider (the simulators, a route without one): the level
            // stays the system's. Said once a swipe.
            if !swiping { log.error("system volume: the volume control has no slider in a window") }
            volume = (session.outputVolume, now)
            return
        }
        if !swiping {
            do {
                try session.setActive(true)
            } catch {
                log.error("system volume: audio session activation: \(error.localizedDescription, privacy: .public)")
            }
        }
        let value = Float(min(max(level, 0), 1))
        volume = (value, now)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(10))
            slider.value = value
        }
    }

    /// The volume control's slider, which sets the system's volume.
    var volumeSlider: UISlider? {
        volumeView.subviews.lazy.compactMap { $0 as? UISlider }.first
    }

    @objc private func resignActive() {
        restoreBrightness()
    }
}

/// The system's volume control (`TouchLevels.volumeView`) among the player's views, where its slider sets the
/// system's volume and keeps the system's volume panel away.
struct SystemVolumeControl: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        TouchLevels.shared.volumeView
    }

    func updateUIView(_ view: MPVolumeView, context: Context) {}
}
#endif
