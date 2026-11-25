import Foundation
import Observation
import OSLog
import PlezyKit
#if os(macOS)
import AVFoundation
import CoreMedia
import SwiftUI
#endif

private let log = Logger(subsystem: "com.edde746.plezy", category: "mpv")

/// Debug builds: the engine's side of the UI tests' probes (`PlayerProbes`), held by `MpvPlayerEngine.debug`: the
/// readings it hands what mpv reports, and the `-mpvMute` launch argument. The engine calls it on its queue, which its
/// own state is confined to, as the engine's is; the readings are the main actor's.
final class EngineDebug: @unchecked Sendable {
    /// The UI tests' view of the engine's loads, position and audio output (`EngineReading`).
    let engineReading: EngineReading
    /// `engineReading`'s summary as last handed over.
    private var engineSummary = ""
    /// Its fields from the last publish (`reportEngine`), and the audio output's as mpv last reported them
    /// (`audioChanged`).
    private var engineFields = "loads=0"
    private var audioOutput = "none"
    private var spdif = "none"
    private var outputFormat = "none"
    /// mpv's `avsync` as last reported, to a tenth of a second (`avSyncChanged`).
    private var avSync = "none"
    /// The startup values from the settings as mpv last reported them (`settingChanged`), in `settingProperties`' order.
    private var settings: [String: String] = [:]

    /// The values mpv takes from the device settings as it starts (`MpvStartup`, the engine's own), the subtitle
    /// margins, HDR output and ambient lighting's fill, observed for the probe: `audio-exclusive` (iOS and tvOS),
    /// `avfoundation-osd-video-res`, `msg-level`, `volume-max`, `sub-use-margins`, `sub-font`, `target-colorspace-hint`
    /// (the output plan's HDR output), `keepaspect` (`no` while ambient lighting is on); then the platform's output
    /// options (`optionProperties`). The volume is the engine state's.
    static let settingProperties = [
        "audio-exclusive", "avfoundation-osd-video-res", "msg-level", "volume-max", "sub-use-margins", "sub-font",
        "target-colorspace-hint", "keepaspect", "demuxer-max-bytes", "deinterlace", "sub-ass", "sub-font-size", "sub-color",
        "sub-bold", "sub-italic", "sub-back-color", "sub-border-style", "sub-ass-override",
    ] + optionProperties

    /// The engine's platform output options (`MpvPlayerEngine.options`, `audioOutput`, the common `keep-open` and on the
    /// Mac `ytdl`) and each file's `hwdec`, in the probe as `<name>-option=<value>`, apart from the outputs mpv settled on
    /// (`ao=`).
    static let optionProperties: [String] = {
        var names = [
            "vo", "ao", "avfoundation-composite-osd", "avfoundation-presentation", "hwdec", "hwdec-codecs",
            "hwdec-software-fallback", "keep-open",
        ]
        #if os(macOS)
        names.append("ytdl")
        #endif
        return names
    }()

    #if os(iOS)
    /// The UI tests' view of where mpv holds the subtitles (`SubtitlePlacement`).
    let subtitlePlacement: SubtitlePlacement
    /// `sub-pos` as mpv last reported it.
    private var reportedSubtitlePosition: Double?
    #endif
    #if os(macOS)
    /// The UI tests' view of the AVFoundation output's display layer clock (`DisplayClockReading`).
    let displayClock: DisplayClockReading

    @MainActor
    init(displayLayer: AVSampleBufferDisplayLayer) {
        engineReading = EngineReading()
        displayClock = DisplayClockReading(layer: displayLayer)
    }
    #else
    @MainActor
    init() {
        engineReading = EngineReading()
        #if os(iOS)
        subtitlePlacement = SubtitlePlacement()
        #endif
    }
    #endif

    #if os(macOS)
    /// The engine's mpv handle started or went (`VideoTeardownLog.handles`).
    func handleCreated() {
        DispatchQueue.main.async { MainActor.assumeIsolated { VideoTeardownLog.shared.handles += 1 } }
    }

    func handleDestroyed() {
        DispatchQueue.main.async { MainActor.assumeIsolated { VideoTeardownLog.shared.handles -= 1 } }
    }
    #endif

    /// mpv's startup options from the launch arguments (UserDefaults' argument domain), in the order they are set:
    /// - `-mpvMute YES`: UI-test runs on a Mac someone works at (a local test run) start mpv muted, so the test
    ///   media's tones stay silent while the audio output, its format and the info panel's rows stay as they are;
    /// - `-mpvOption <name>=<value>`: one more startup option, for EngineFailureTests' option mpv rejects.
    static var startupOptions: [(name: String, value: String)] {
        var options: [(name: String, value: String)] = []
        if UserDefaults.standard.bool(forKey: "mpvMute") {
            log.notice("mpv starts muted by launch argument (-mpvMute)")
            options.append(("mute", "yes"))
        }
        if let option = UserDefaults.standard.string(forKey: "mpvOption"), let equals = option.firstIndex(of: "=") {
            let name = String(option[..<equals])
            log.notice("mpv option \(name, privacy: .public) by launch argument (-mpvOption)")
            options.append((name, String(option[option.index(after: equals)...])))
        }
        return options
    }

    /// Hands `engineReading` the loads so far (the state's load id: the engine's loads count from 1), the position,
    /// where what mpv holds read around it starts, the video track it decodes and its speed (after each publish).
    func reportEngine(state: EngineState) {
        engineFields = "loads=\(state.loadId) position=\(String(format: "%.1f", state.positionSeconds)) "
            + "cacheStart=\(state.cacheStartSeconds.map { String(format: "%.1f", $0.doubleValue) } ?? "none") "
            + "video=\(state.tracks.first { $0.kind == .video && $0.selected }.map { String($0.id) } ?? "no") "
            + "speed=\(String(format: "%.2f", state.speed))"
        handOverEngine()
    }

    /// mpv reported one of the audio output's properties: `current-ao`, `audio-spdif` or `audio-out-params/format`.
    func audioChanged(_ name: String, _ value: String?) {
        let shown = value.flatMap { $0.isEmpty ? nil : $0 } ?? "none"
        switch name {
        case "current-ao": audioOutput = shown
        case "audio-spdif": spdif = shown
        default: outputFormat = shown
        }
        handOverEngine()
    }

    /// mpv reported `avsync`: the audio clock less the video's, seconds.
    func avSyncChanged(_ value: Double?) {
        avSync = value.map { String(format: "%.1f", $0) } ?? "none"
        handOverEngine()
    }

    /// mpv reported one of `settingProperties`.
    func settingChanged(_ name: String, _ value: String?) {
        settings[name] = value.flatMap { $0.isEmpty ? nil : $0 } ?? "none"
        handOverEngine()
    }

    private func handOverEngine() {
        let startup = Self.settingProperties.map { name in
            "\(name)\(Self.optionProperties.contains(name) ? "-option" : "")=\(settings[name] ?? "none")"
        }.joined(separator: " ")
        let summary = "\(engineFields) ao=\(audioOutput) spdif=\(spdif) format=\(outputFormat) avsync=\(avSync) \(startup)"
        guard summary != engineSummary else { return }
        engineSummary = summary
        DispatchQueue.main.async { [engineReading] in
            MainActor.assumeIsolated { engineReading.summary = summary }
        }
    }

    #if os(iOS)
    /// mpv reported `sub-pos`: hands it to `subtitlePlacement` with the frame and the controls' lift as they are now.
    func subtitlePositionChanged(_ position: Double?, frame: SubtitleFrame, controlsLift: Double) {
        reportedSubtitlePosition = position
        reportSubtitles(frame: frame, controlsLift: controlsLift)
    }

    /// Hands `subtitlePlacement` mpv's `sub-pos`, the frame and the controls' lift as they are now.
    func reportSubtitles(frame: SubtitleFrame, controlsLift: Double) {
        let summary = String(
            format: "sub-pos=%.2f; frame=%.0f,%.0f,%.0f; controls=%.3f",
            reportedSubtitlePosition ?? -1, frame.height, frame.top, frame.bottom, controlsLift
        )
        DispatchQueue.main.async { [subtitlePlacement] in
            MainActor.assumeIsolated { subtitlePlacement.summary = summary }
        }
    }
    #endif
}

#if os(iOS)
/// Debug builds: where mpv holds the subtitles, for the UI tests' probe `player.subtitlePosition` (`PlayerProbes`):
/// `sub-pos=<mpv's sub-pos>; frame=<h>,<mt>,<mb>; controls=<lift>`, the frame the engine placed them in (the output's
/// height and the bands above and below the picture, in pixels; `1,0,0`, the whole surface, until mpv has an output)
/// and the controls' share of the surface it was given. mpv draws the subtitles into the video, out of XCUITest's reach.
@MainActor
@Observable
final class SubtitlePlacement {
    var summary = "sub-pos=none"
}
#endif

#if os(macOS)
/// Debug builds: how often the AVFoundation output's display layer clock jumped since the playback began (the layer's
/// `controlTimebase`, which vo_avfoundation sets: its `CMTimebase.timeJumped`), for the UI tests' probe
/// `player.displayClock` (`jumps=<n>`, `PlayerProbes`). On mpv's host clock no seek moves it; on media time each one does.
@MainActor
@Observable
final class DisplayClockReading {
    private(set) var jumps = 0
    @ObservationIgnored private weak var layer: AVSampleBufferDisplayLayer?
    @ObservationIgnored nonisolated(unsafe) private var observer: (any NSObjectProtocol)?

    init(layer: AVSampleBufferDisplayLayer) {
        self.layer = layer
        observer = NotificationCenter.default.addObserver(forName: CMTimebase.timeJumped, object: nil, queue: .main) {
            [weak self] note in
            let timebase = (note.object as AnyObject?).map(ObjectIdentifier.init)
            MainActor.assumeIsolated { self?.jumped(timebase) }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    private func jumped(_ timebase: ObjectIdentifier?) {
        guard let clock = layer?.controlTimebase, timebase == ObjectIdentifier(clock) else { return }
        jumps += 1
    }
}

/// Debug builds: for the UI tests' probe `app.videoTeardown` (`VideoTeardownProbe`), each time a playback's display
/// layer (the AVFoundation output's) left the window: `hidden` or `visible`, and whether an mpv handle was still alive
/// (`mpv=alive`) or every one was gone (`mpv=gone`), one line per playback.
@MainActor
@Observable
final class VideoTeardownLog {
    static let shared = VideoTeardownLog()

    private(set) var lines: [String] = []
    /// mpv handles alive (`EngineDebug.handleCreated`, `handleDestroyed`).
    @ObservationIgnored var handles = 0

    func displayLayerLeft(hidden: Bool) {
        lines.append("\(hidden ? "hidden" : "visible") mpv=\(handles > 0 ? "alive" : "gone")")
    }
}

/// Debug builds: `VideoTeardownLog`'s lines (`none` before the first), as the label of an element the UI tests read
/// (`app.videoTeardown`) once the player is gone.
struct VideoTeardownProbe: View {
    var body: some View {
        let lines = VideoTeardownLog.shared.lines
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: lines.isEmpty ? "none" : lines.joined(separator: "\n")))
            .accessibilityIdentifier("app.videoTeardown")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
#endif

/// Debug builds: the engine's loads, position, speed and audio output, for the UI tests' probe `player.engine`
/// (`PlayerProbes`):
/// `loads=<n> position=<s> cacheStart=<s|none> video=<id|no> speed=<x> ao=<name|none> spdif=<codecs|none>
/// format=<format|none>`, the loads of this playback so far (a live rewind's reopen is one), mpv's position in the open
/// file, where what it holds read around the position starts (`EngineState.cacheStartSeconds`), which the live tests
/// tell a seek within what mpv holds from a reopen by, the video track mpv decodes (`no` while none, as in the
/// background on iOS: `setVideoSuspended`), mpv's `speed`, and mpv's `current-ao`, `audio-spdif` and
/// `audio-out-params/format` (`spdif-eac3` while passthrough is in effect), which the passthrough tests read; then
/// `<name>=<value|none>` for each of `EngineDebug.settingProperties`, what mpv took from the device settings, and
/// `<name>-option=<value|none>` for each of its `optionProperties`, the platform's output options.
@MainActor
@Observable
final class EngineReading {
    var summary = "loads=0"
}
