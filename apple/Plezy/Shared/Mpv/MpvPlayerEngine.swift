import Foundation
import Libmpv
import os
import PlezyKit

private let log = EngineLog(tag: "mpv")

/// The mpv engines' lines (the video engine's, tag "mpv", the music core's, "mpv-audio") into the app's log (`Log`):
/// View Logs, the log export, and through its sink the unified log under the tag as category. `Log` redacts the line as
/// a whole. `notice` is the app log's info, `debug` its debug (the once-a-second state line), which shows with Debug
/// logging on.
struct EngineLog: Sendable {
    let tag: String

    func notice(_ text: String) { write(.info, text) }
    func debug(_ text: String) { write(.debug, text) }
    func error(_ text: String) { write(.error, text) }

    /// One of mpv's own lines, as "[MPV:<prefix>] <text>" at mpv's level: fatal and error an error, warn a warning, info
    /// and v info, debug and trace debug.
    func mpv(prefix: String, level: mpv_log_level, text: String) {
        let shared: Log.Level = switch level {
        case MPV_LOG_LEVEL_FATAL, MPV_LOG_LEVEL_ERROR: .error
        case MPV_LOG_LEVEL_WARN: .warn
        case MPV_LOG_LEVEL_INFO, MPV_LOG_LEVEL_V: .info
        default: .debug
        }
        write(shared, "[MPV:\(prefix)] \(text)")
    }

    private func write(_ level: Log.Level, _ text: String) {
        Log.shared.log(level: level, tag: tag, error: nil) { text }
    }
}

/// The shared `PlayerEngine` on libmpv from MPVKit.
///
/// It handles the context lifecycle, wakeup callback, option set, async requests, and the per-platform `vo` and HDR.
/// The surface mpv renders into is a [VideoSurface]: an `AVSampleBufferDisplayLayer` (`vo=avfoundation`) on every
/// platform.
///
/// Threading: every libmpv call runs on `queue`, a private serial queue, and never on the main thread.
/// vo_avfoundation `dispatch_sync`s layer work to the main thread, so a main thread blocked inside libmpv
/// deadlocks the player. The public methods only enqueue, nothing ever waits for `queue`, commands and property
/// writes use libmpv's async API, and every value the engine reports comes from observed properties or, for the
/// playback info, `mpv_get_property_async` (never `mpv_get_property`), so `queue` does not park behind the VO either.
/// `onState` fires on `queue`.
/// Each engine owns its queue, handle and wakeup target, so one engine's teardown cannot touch another's.
/// `release()` is the only teardown: it runs `mpv_terminate_destroy` on `queue` while the surface is still alive, which
/// a `deinit` on an arbitrary thread could not guarantee.
///
/// macOS teardown: vo_avfoundation's `dispatch_sync`s to the main thread go through, as the main thread never waits
/// for `queue`. The video's layers, hidden at the end of the playback, stay in the window until the handle is gone and
/// their hidden frame is on screen (`VideoSurface.removeEndedLayers`, `layerRetireDelay`).
///
/// HDR and display modes: each load starts paused behind a [StartGate]. Once the first frame is up and mpv has
/// reported the video's format, the engine hands a [DisplayFormat] to the surface, which sets the screen up as the
/// shared output policy's plan says (EDR on iOS and the Mac, `AVDisplayManager` criteria on
/// tvOS), and plays when the surface reports the display ready, so a tvOS HDMI mode switch does not eat the start of
/// the file. Later format changes in the same file go to the surface without pausing. Between files the display keeps
/// its format: the next file changes it only if it needs another one. The playback's output host hands the display back
/// when the playback ends.
///
/// Not an NSObject subclass: NSObject's (ARC-unavailable) `-release` would make the protocol's `release()` ambiguous.
final class MpvPlayerEngine: PlayerEngine, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.edde746.plezy.mpv", qos: .userInitiated)

    /// Keeps the layer mpv holds as `wid` alive until the handle is gone (the engine outlives `release()`'s
    /// teardown block). Let go of on the main thread (`deinit`).
    private let surface: VideoSurface

    // Confined to `queue`.
    private var mpv: OpaquePointer?
    private var wakeupTarget: Unmanaged<WakeupTarget>?
    private var listener: (any PlayerEngineListener)?
    /// Each file's lifecycle and the state mpv's properties make (the shared `MpvLifecycle`); it holds while the start
    /// gate is shut.
    private let lifecycle = MpvLifecycle()
    /// The load in flight's start gate, until it opens.
    private var gate: StartGate?
    /// What each facet of the state read when it was last logged (`logChanges`), and what it was built from.
    private var logged: [String: String] = [:]
    private var loggedFrom: LogSource?
    private var released = false
    private var nextRequestId: UInt64 = 1
    /// What each request in flight is, for its failure's log line; a load's value or `loadfile` also names its load,
    /// whose error mpv's refusal is (`complete`).
    private var pendingRequests: [UInt64: (description: String, load: Int64?)] = [:]
    /// The load whose file opens once mpv took its last value (`load`, `complete`): that value's request, the load and
    /// its URL.
    private var opening: (request: UInt64, load: Int64, url: String)?
    /// The first mpv call that failed while the handle started (`create`, `check`): the handle is gone, and every
    /// load fails with this error.
    private var startupFailure: String?
    /// Loads and START_FILE events so far: a stats reading that spans one is of the replaced file.
    private var fileStarts: UInt64 = 0
    /// The playback info shows (`setStatsWanted`).
    private var statsWanted = false
    /// Bumped by each change of `statsWanted`: a reading, a reply or a timer of an earlier run finds itself stale.
    private var statsRun: UInt64 = 0
    /// The stats reading under way, until every answer is in.
    private var statsReading: StatsReading?
    /// The format last handed to the surface. Kept across files, so a file in the same format changes nothing.
    private var presentedFormat: DisplayFormat?
    /// mpv's `frame-drop-count` as last reported: frames the VO dropped, logged when a file ends and the handle goes.
    private var droppedFrames: Int64 = 0
    /// The latest subtitle style, the controls' lift and the frame mpv places text subtitles in, which `sub-pos`
    /// combines. Text subtitles may sit in the bands around the picture (`sub-use-margins`, `subtitleMargins` as last
    /// written) when the style lets them or the picture runs past the surface (`videoLayout`), and then go by the
    /// screen; otherwise by the picture, from `osd-dimensions` (`updateSubtitleFrame`).
    private var subtitleStyle = SubtitleStyle.companion.DEFAULT
    private var controlsLift = 0.0
    private var subtitleFrame = SubtitleFrame.companion.SCREEN
    private var subtitleMargins = ""
    /// The picture's place on the surface as mpv last reported it (`osd-dimensions`).
    private var pictureFrame = SubtitleFrame.companion.SCREEN
    /// mpv's `volume-max`, the `max_volume` setting the playback started with (`MpvStartup.volumeMax`): mpv refuses a
    /// volume above it (`setVolume`).
    private let volumeMax: Double
    /// The user's mpv.conf (`MpvUserConfig`): set after the engine's own options; a line wins over its later writes
    /// (`setAppProperty`).
    private let userConfig: MpvUserConfig
    #if os(iOS)
    /// mpv's `time-pos` as last reported, read on any thread (`positionSeconds`).
    private let reportedPosition = OSAllocatedUnfairLock(initialState: 0.0)
    #endif
    #if os(iOS) || os(tvOS)
    /// While nobody sees the video (`setVideoSuspended`): the video track it showed, and the file it showed it in.
    private var videoSuspension: (track: Int64?, fileStarts: UInt64)?
    #endif
    /// The picture's fit and zoom (`setVideoLayout`), the surface's width over its height as mpv last reported it
    /// (`osd-dimensions`; nil before mpv has an output), and the layout's mpv properties as last written.
    private var videoLayout = VideoLayout.companion.DEFAULT
    private var surfaceAspect: Double?
    private var layoutProperties: [String: String] = [:]
    /// How far the picture mpv places on the surface (`osd-dimensions` less its margins) stretches to fill the surface,
    /// across and down: the display layer's stretch for `VideoFit.FILL`.
    private var pictureStretch = (x: 1.0, y: 1.0)
    /// The audio options, the AudioPassthrough setting and the speed, applied in an order that never hands a bitstream
    /// to the filter, a fold or another speed (on `queue`). Passthrough names `passthroughCodecs` and leaves
    /// `audio-exclusive` alone: on the Mac it would open every CoreAudio output, PCM included, in hog mode, and on iOS
    /// and tvOS it is on from the start (`options`). mpv answers the writes later (`completeIfRejected` logs a
    /// refusal), so none is rolled back here.
    private lazy var audio = AudioStateReconciler(
        normalizationFilter: AudioOptionsKt.LOUDNESS_NORMALIZATION_FILTER,
        exclusiveHint: false,
        codecs: { Self.passthroughCodecs.joined(separator: ",") },
        warn: { [log] message, _ in log.error("mpv \(message)") },
        writer: AudioPropertyWriter { [unowned self] name, value in
            _ = setProperty(name, value)
            if name == "audio-spdif" { log.notice("audio-spdif = \(value.isEmpty ? "(none)" : value)") }
        }
    )
    /// Ambient lighting (`setAmbientLighting`, on `queue`). mpv answers its writes later (`completeIfRejected` logs a
    /// refusal), so each one sent counts as taken here.
    private lazy var ambientLighting = MpvAmbientLighting(
        set: { [unowned self] name, value in
            setProperty(name, value)
            return KotlinBoolean(value: mpv != nil)
        },
        command: { [unowned self] args in
            command(args)
            return KotlinBoolean(value: mpv != nil)
        }
    )
    /// mpv's `current-ao` as last reported (`setSpeed`).
    private var audioOutputDriver = ""
    /// Where the last absolute seek asked for goes, until mpv shows a frame after a seek (its `playback-restart`).
    private var seekTarget: Double?
    /// `target-colorspace-hint` as last written: `auto` while the playback may present HDR, `no` otherwise
    /// (`create`, `setHdrOutput`).
    private var colorspaceHint = ""
    #if os(macOS)
    /// The display hold under way (`holdForDisplaySwitch`), by its number; nil while none.
    private var displayHold: UInt64?
    private var displayHolds: UInt64 = 0
    #endif
    #if DEBUG
    let debug: EngineDebug
    #endif

    /// - Parameter settings: the device settings the playback started with: HDR output (`target-colorspace-hint`, a
    ///   startup option), what mpv-build's FFmpeg makes of Dolby Vision profile 7 (`AppleDisplayCriteria`'s
    ///   conversion environment, read by the decoder), the subtitle render resolution (`avfoundation-osd-video-res`),
    ///   and what every engine's mpv takes as it starts (`MpvStartup`): the log levels, the stored audio output, the
    ///   volume's top and the opening volume.
    @MainActor
    init(surface: VideoSurface, settings: DeviceSettings) {
        self.surface = surface
        #if DEBUG && os(macOS)
        debug = EngineDebug(displayLayer: surface.sampleBufferLayer)
        #elseif DEBUG
        debug = EngineDebug()
        #endif
        let wid = Int64(Int(bitPattern: Unmanaged.passUnretained(surface.renderLayer).toOpaque()))
        let environment = AppleDisplayCriteria.companion.conversionEnvironment(
            conversion: settings.dvConversionMode,
            log: settings.debugLogging
        )
        let startup = Startup(settings: settings)
        userConfig = MpvUserConfig.companion.of(text: settings.mpvConfigText, linuxPlane: false)
        volumeMax = userConfig.get(name: "volume-max").flatMap { Double($0) } ?? startup.volumeMax
        #if !os(macOS)
        surface.onOutputRangeChange = { [weak self] in
            guard let self else { return }
            let display = self.surface.displayOutput()
            queue.async { self.surfaceRangeRead(display) }
        }
        #endif
        #if os(iOS)
        surface.pictureInPicture.onSubtitlesInPicture = { [weak self] composite in
            guard let self else { return }
            queue.async { self.setProperty("avfoundation-pip-composite-osd", composite ? "yes" : "no") }
        }
        #endif
        queue.async { [self] in create(wid: wid, environment: environment, startup: startup) }
        #if !os(macOS)
        queue.async { [self] in readAudioRendering() }
        #endif
    }

    /// The last reference to the engine may go anywhere: on `queue` with `release()`'s teardown block or a block that
    /// came after it. The surface (a view, with its picture in picture) goes on the main thread, as UIKit and AppKit
    /// require: the block takes it before the engine lets go of it.
    deinit {
        DispatchQueue.main.async { [surface] in withExtendedLifetime(surface) {} }
    }

    #if !os(macOS)
    /// How the system renders the audio (`PlaybackAudioSession.rendering`), read every 2 s while the engine lives (the
    /// system resolves it as the route changes), and published when it changes.
    private func readAudioRendering() {
        guard !released else { return }
        let rendering = PlaybackAudioSession.rendering
        if rendering != lifecycle.state.audioRendering {
            lifecycle.audioRendering(rendering: rendering)
            publish()
        }
        queue.asyncAfter(deadline: .now() + 2) { [weak self] in self?.readAudioRendering() }
    }
    #endif

    // MARK: PlayerEngine

    func load(request: LoadRequest) -> Int64 {
        let id = lifecycle.nextLoadId()
        let url = request.url
        let decodingOptions = MpvLoad.shared.decodingOptions(options: request.options, live: request.live)
        let headerFields = MpvLoad.shared.headerFields(headers: request.headers)
        #if os(iOS)
        let uncachedRoots = MpvLoad.shared.IOS_UNCACHED_ROOTS
        #else
        let uncachedRoots: [String] = []
        #endif
        let fileProperties = MpvLoad.shared.fileProperties(
            request: request, streamBufferCap: MpvLoad.shared.MAX_STREAM_BUFFER_BYTES, uncachedRoots: uncachedRoots,
            cacheForced: userConfig.get(name: "cache") == "yes"
        )
        queue.async { [self] in
            guard !released else { return }
            fileStarts += 1
            lifecycle.load(id: id)
            // A load means play once the gate opens; `setPaused` behind it changes that. The gate takes over a display
            // hold.
            gate = StartGate(load: id)
            #if os(macOS)
            displayHold = nil
            #endif
            lifecycle.hold(viewerPaused: false)
            // mpv failed to start: no file opens, and the player shows why.
            if let startupFailure { return fail(startupFailure) }
            // The file's values as mpv's properties (`MpvLoad`), so the files mpv opens from this one's playlist keep
            // them. mpv answers async requests in order: once it took the last one, it took every one before it, and the
            // file opens (`complete`); one it refuses refuses the load (`refuse`), and nothing opens, but for a playback
            // default (`MpvLoad.refusalFailsLoad`), whose refusal is only logged.
            for (name, value) in decodingOptions { setAppProperty(name, value, load: id) }
            for (name, value) in fileProperties { setAppProperty(name, value, load: MpvLoad.shared.refusalFailsLoad(name: name) ? id : nil) }
            opening = (setProperty("http-header-fields", headerFields, secret: true, load: id), id, url)
            publish()
        }
        return id
    }

    func setPaused(paused: Bool) {
        queue.async { [self] in
            if isHeld {
                // mpv stays paused behind the gate or the display hold; their end applies the latest request.
                lifecycle.hold(viewerPaused: paused)
                publish()
            } else {
                setProperty("pause", paused ? "yes" : "no")
            }
        }
    }

    /// The start gate or the display hold keeps mpv paused.
    private var isHeld: Bool {
        #if os(macOS)
        gate != nil || displayHold != nil
        #else
        gate != nil
        #endif
    }

    /// HDR output for the playback, as the shared output plan has it (`OutputPlan.hdrOutput`: the Hdr setting, the
    /// player's HDR switch and the display): `target-colorspace-hint` `auto` while on, `no` while off, answered by mpv's
    /// write. On tvOS the TV's mode carries it (`AppleDisplayCriteria`), on iOS and the Mac the display layer's EDR too.
    func setHdrOutput(enabled: Bool, onResult: @escaping (KotlinBoolean) -> Void) {
        queue.async { [self] in
            let hint = enabled ? "auto" : "no"
            guard let mpv, hint != colorspaceHint else { return onResult(true) }
            // A line of the user's mpv.conf keeps its value.
            guard userConfig.appWrites(name: "target-colorspace-hint") else { return onResult(true) }
            let applied = mpv_set_property_string(mpv, "target-colorspace-hint", hint) >= 0
            if applied { colorspaceHint = hint }
            log.notice("target-colorspace-hint = \(hint), applied \(applied)")
            onResult(KotlinBoolean(value: applied))
        }
    }

    #if os(macOS)
    /// The display switched mode for the playback (`DisplayModeSwitch`): a playing video holds for `seconds`, the
    /// display switch delay, so the display has re-synced before it runs on; a paused one stays as it is. A pause or
    /// play asked for meanwhile is applied when the hold ends, and a load ends it (its start gate holds instead).
    func holdForDisplaySwitch(seconds: Int) {
        guard seconds > 0 else { return }
        queue.async { [self] in
            guard displayHold == nil, lifecycle.state.loaded, !lifecycle.state.paused else { return }
            displayHolds += 1
            let hold = displayHolds
            displayHold = hold
            if gate == nil {
                lifecycle.hold(viewerPaused: false)
                setProperty("pause", "yes")
                publish()
            }
            log.notice("display hold: \(seconds) s after the display switched")
            queue.asyncAfter(deadline: .now() + .seconds(seconds)) { [weak self] in self?.endDisplayHold(hold) }
        }
    }

    private func endDisplayHold(_ hold: UInt64) {
        guard displayHold == hold else { return }
        displayHold = nil
        // The start gate, still shut, ends the hold itself.
        guard gate == nil else { return }
        let paused = lifecycle.state.paused
        log.notice("display hold over (\(paused ? "stays paused" : "plays"))")
        lifecycle.endHold(paused: paused)
        if !paused { setProperty("pause", "no") }
        publish()
    }
    #endif

    func seek(seconds: Double, exact: Bool) {
        queue.async { [self] in
            seekTarget = seconds
            command(["seek", String(seconds), exact ? "absolute+exact" : "absolute+keyframes"])
        }
    }

    /// ao_avfoundation holds about four seconds of audio mpv already filtered at the old speed (mpv's buffer and what
    /// AVSampleBufferAudioRenderer reads ahead), and mpv's clock counts that audio at the new speed the moment the
    /// write lands: playback would go on (old - new) × 4 s away from where the new speed puts it, the video waiting for
    /// the clock meanwhile, and a watch-together room's guest would drift off the room. A seek back to the position
    /// before the write (or to a seek's target still on its way) drops that audio, and playback goes on at the new
    /// speed from there; the seek stays where the picture is, so it shows no buffering (`MpvLifecycle.seekInPlace`).
    /// The other outputs keep a short buffer and need no seek.
    func setSpeed(speed: Double) {
        queue.async { [self] in
            let flush = speed != audio.accepted.rate && audioOutputDriver == "avfoundation" && gate == nil && lifecycle.state.loaded
            reconcileAudio(audio.requestRate(rate: speed))
            guard flush else { return }
            let position = seekTarget ?? lifecycle.state.positionSeconds
            if seekTarget == nil { lifecycle.seekInPlace() }
            seekTarget = position
            command(["seek", String(position), "absolute+exact"])
        }
    }

    func setSubtitleDelay(seconds: Double) {
        queue.async { [self] in
            setProperty("sub-delay", seconds)
            setProperty("secondary-sub-delay", seconds)
        }
    }

    func setAudioDelay(seconds: Double) {
        queue.async { [self] in setProperty("audio-delay", seconds) }
    }

    /// The user's GLSL shaders, in order, for this file and the later ones: mpv's `glsl-shaders` list, cleared and filled
    /// one path per `change-list` so a path with spaces or the list separator stays whole, ambient lighting's shader
    /// back at its end. libplacebo renders them on vo_avfoundation; it skips them for Dolby Vision frames, a Core Image
    /// zoom, picture in picture with composited subtitles and while the app is inactive.
    func setShaders(paths: [String]) {
        queue.async { [self] in
            command(["change-list", "glsl-shaders", "clr", ""])
            for path in paths { command(["change-list", "glsl-shaders", "append", path]) }
            ambientLighting.afterShadersRebuilt()
        }
    }

    /// Ambient lighting as the shared `MpvAmbientLighting` writes it. `keepaspect=no` stretches only what libplacebo
    /// renders with the shaders: a frame vo_avfoundation shows without them (see `setShaders`) stays letterboxed.
    func setAmbientLighting(shaderPath: String?) {
        queue.async { [self] in
            ambientLighting.set(shaderPath: shaderPath)
            log.notice("ambient lighting \(shaderPath != nil ? "on" : "off")")
        }
    }

    func setSubtitleLift(fraction: Double) {
        queue.async { [self] in
            controlsLift = fraction
            applySubtitlePosition()
        }
    }

    func setSubtitleStyle(style: SubtitleStyle) {
        let box = UncheckedBox(style)
        queue.async { [self] in
            let style = box.value
            subtitleStyle = style
            for (name, value) in style.properties() { setAppProperty(name, value) }
            updateSubtitleFrame(reposition: true)
        }
    }

    /// `sub-pos` for the latest style, controls and frame (on `queue`).
    private func applySubtitlePosition() {
        setAppProperty("sub-pos", String(subtitleStyle.position(controlsLift: controlsLift, frame: subtitleFrame)))
        #if DEBUG && os(iOS)
        debug.reportSubtitles(frame: subtitleFrame, controlsLift: controlsLift)
        #endif
    }

    func setVideoLayout(layout: VideoLayout) {
        let box = UncheckedBox(layout)
        queue.async { [self] in
            videoLayout = box.value
            log.notice("video layout \(box.value.fit.name) zoom=\(box.value.zoom)")
            applyVideoLayout()
        }
    }

    /// Shows the picture as `videoLayout` says on a surface of `surfaceAspect` (on `queue`): the layout's mpv
    /// properties, written where they changed. The display layer scales the picture (`VideoSurface.show`: video
    /// gravity and `setVideoZoom`, and a stretch to the surface for `FILL`), and mpv keeps `video-zoom` at 0, since
    /// vo_avfoundation would re-render every zoomed frame through Core Image and lose HDR and Dolby Vision, and
    /// `video-aspect-override` at `no`: the display layer showed neither its `resize` gravity nor vo_avfoundation's
    /// pixel-aspect tag for the override (the picture kept its shape on iOS 27 and tvOS 26.5), so the layer stretches by
    /// its transform, from the picture mpv places (`pictureStretch`). panscan still places mpv's subtitles and OSD over a
    /// cropped picture. Text subtitles placed by the picture go by the screen while the picture runs past it, so they
    /// stay on it (`updateSubtitleFrame`).
    private func applyVideoLayout() {
        let layout = videoLayout
        var properties = layout.properties(surfaceAspect: surfaceAspect.map { KotlinDouble(double: $0) })
        properties["video-zoom"] = "0"
        properties["video-aspect-override"] = "no"
        let fit = layout.fit
        let zoom = layout.zoom
        let stretch = fit == .fill ? pictureStretch : (x: 1.0, y: 1.0)
        DispatchQueue.main.async { [surface] in
            MainActor.assumeIsolated { surface.show(fit: fit, zoom: zoom, stretchX: stretch.x, stretchY: stretch.y) }
        }
        for (name, value) in properties.sorted(by: { $0.key < $1.key }) where layoutProperties[name] != value {
            setAppProperty(name, value)
        }
        layoutProperties = properties
        updateSubtitleFrame()
    }

    func setAudioNormalization(enabled: Bool) {
        queue.async { [self] in reconcileAudio(audio.requestNormalization(enabled: enabled)) }
    }

    func setAudioChannels(channels: AudioChannels, downmix: Downmix) {
        queue.async { [self] in reconcileAudio(audio.requestChannels(channels: channels, downmix: downmix)) }
    }

    /// The AudioPassthrough setting, as the shared output plan has it (`ApplePlaybackOutput`): while on, `audio-spdif`
    /// names the formats this platform's outputs take undecoded (`passthroughCodecs`), unless the audio options need
    /// decoded audio (`AudioState.passesThrough`: normalized, stereo, another speed).
    func setAudioPassthrough(_ enabled: Bool) {
        queue.async { [self] in reconcileAudio(audio.requestPassthrough(enabled: enabled)) }
    }

    private func reconcileAudio(_ request: AudioStateReconciler.Request) {
        do {
            try audio.reconcile(request: request)
        } catch {
            log.error("mpv audio options refused: \(error.localizedDescription)")
        }
    }

    func setAudioDevice(name: String) {
        #if os(macOS)
        queue.async { [self] in setProperty("audio-device", name) }
        #endif
        // iOS and tvOS route audio through the audio session; the engine reports no devices there.
    }

    #if os(iOS)
    /// mpv's position as it last reported it, on any thread: picture in picture's timeline reads it
    /// (`PictureInPicture.readPosition`).
    var positionSeconds: Double { reportedPosition.withLock { $0 } }
    #endif

    #if os(iOS) || os(tvOS)
    /// Has mpv open its audio output again (`ao-reload`): a media-services reset takes the old one down with every
    /// audio object of the app (`PlaybackAudioSession`).
    func reloadAudioOutput() {
        queue.async { [self] in command(["ao-reload"]) }
    }
    #endif

    func setStatsWanted(wanted: Bool) {
        queue.async { [self] in
            guard wanted != statsWanted else { return }
            statsWanted = wanted
            statsRun += 1
            statsReading = nil
            if wanted {
                readStats()
            } else {
                lifecycle.stats(reading: nil)
                publish()
            }
        }
    }

    func setVolume(volume: Double) {
        // mpv rejects a volume above `volume-max` instead of clamping it.
        let clamped = min(max(volume, 0), volumeMax)
        queue.async { [self] in setProperty("volume", clamped) }
    }

    func setMuted(muted: Bool) {
        queue.async { [self] in setProperty("mute", muted ? "yes" : "no") }
    }

    func selectTrack(kind: TrackKind, id: KotlinLong?) {
        let property = switch kind {
        case .video: "vid"
        case .audio: "aid"
        case .subtitle: "sid"
        }
        let value = id.map { String($0.int64Value) } ?? "no"
        queue.async { [self] in
            setProperty(property, value)
            #if os(macOS)
            if kind == .subtitle { redrawPausedFrame() }
            #endif
        }
    }

    func selectSecondSubtitle(id: KotlinLong?) {
        let value = id.map { String($0.int64Value) } ?? "no"
        queue.async { [self] in
            setProperty("secondary-sid", value)
            #if os(macOS)
            redrawPausedFrame()
            #endif
        }
    }

    /// mpv's `screenshot subtitles` to `screenshot-directory` for a software-decoded video. A hardware-decoded one's
    /// frame mpv can't write (`FrameCapture`): on iOS and the Mac the shot is taken from the display layer instead,
    /// with the subtitles beside it, and written as mpv would, to the same folder.
    func screenshot(onResult: @escaping (KotlinBoolean) -> Void) {
        queue.async { [self] in
            guard let mpv else { return onResult(false) }
            #if !os(tvOS)
            if let hwdec = lifecycle.state.hwdec, hwdec != "no" {
                let answer = UncheckedBox(onResult)
                return DispatchQueue.main.async { [surface] in
                    let image = MainActor.assumeIsolated {
                        UncheckedBox(FrameCapture.image(displayLayer: surface.renderLayer))
                    }
                    DispatchQueue.global(qos: .userInitiated).async {
                        guard let frame = image.value else {
                            log.error("screenshot: no frame on the display layer")
                            return answer.value(false)
                        }
                        let saved = FrameCapture.write(frame, to: Self.screenshotDirectory)
                        if !saved { log.error("screenshot: couldn't write it to \(Self.screenshotDirectory)") }
                        answer.value(KotlinBoolean(value: saved))
                    }
                }
            }
            #endif
            let args = ["screenshot", "subtitles"]
            let cStrings = args.map { strdup($0) }
            defer { cStrings.forEach { free($0) } }
            var argv: [UnsafePointer<CChar>?] = cStrings.map { UnsafePointer($0) }
            argv.append(nil)
            onResult(KotlinBoolean(value: mpv_command(mpv, &argv) >= 0))
        }
    }

    #if !os(tvOS)
    /// Where screenshots go: the user's Pictures on the Mac, as on the desktops; on iPhone and iPad the app's Documents,
    /// which the Files app shows (`UIFileSharingEnabled`). Debug builds started with `-screenshotDirectory <path>` (the
    /// UI tests on a Mac someone works at) write there instead.
    private static let screenshotDirectory: String = {
        #if DEBUG
        if let path = UserDefaults.standard.string(forKey: "screenshotDirectory") { return path }
        #endif
        #if os(macOS)
        return MpvOptionsKt.DESKTOP_SCREENSHOT_DIRECTORY
        #else
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSHomeDirectory() + "/Documents"
        #endif
    }()
    #endif

    func stop() {
        queue.async { [self] in command(["stop"]) }
    }

    func subtitleSeek(forward: Bool) {
        queue.async { [self] in command(["sub-seek", forward ? "1" : "-1"]) }
    }

    /// The player's HDR switch (on Apple TV it sets the TV's criteria again, `AppleDisplayCriteria`, as the surface
    /// follows the new plan), the Mac's listed outputs, and Dolby Vision Profile 7's conversion, which mpv-build's
    /// FFmpeg reads at each Dolby Vision decoder it opens.
    var features: EngineFeatures {
        #if os(macOS)
        EngineFeatures(hdrControl: true, audioDevices: true, dolbyVisionConversion: true)
        #else
        EngineFeatures(hdrControl: true, audioDevices: false, dolbyVisionConversion: true)
        #endif
    }


    /// The conversion FFmpeg reads as it opens the next Dolby Vision decoder (`PLEZY_DV_CONVERSION_MODE`).
    func setDolbyVisionConversion(mode: DolbyVisionConversion) {
        queue.async { setenv("PLEZY_DV_CONVERSION_MODE", mode.wire, 1) }
    }

    func addSubtitle(url: String, title: String?, lang: String?) {
        // `auto` adds the track without forcing it on; choosing it is selectTrack's job.
        var args = ["sub-add", url, "auto"]
        if title != nil || lang != nil { args.append(title ?? "") }
        if let lang { args.append(lang) }
        queue.async { [self, args] in command(args) }
    }

    func setListener(listener: (any PlayerEngineListener)?) {
        let box = UncheckedBox(listener)
        queue.async { [self] in
            self.listener = box.value
            lifecycle.republish()
            // Before the first load there is nothing to report; a listener attached later gets the current state.
            if lifecycle.state.loadId != 0 || lifecycle.state.error != nil { publish() }
        }
    }

    func release() {
        queue.async { [self] in
            guard !released else { return }
            released = true
            listener = nil
            destroy()
            #if os(macOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.layerRetireDelay) { [surface] in
                MainActor.assumeIsolated { surface.removeEndedLayers() }
            }
            #endif
        }
    }

    #if os(macOS)
    /// How long the video's hidden layers stay in the window once the handle is gone: vo_avfoundation's
    /// own `AVF_LAYER_RETIRE_DELAY_NS` for its subtitle layer, several refreshes even at 24 Hz, so the hidden frame is on
    /// screen before they leave.
    private static let layerRetireDelay: DispatchTimeInterval = .milliseconds(200)
    #endif

    #if os(iOS) || os(tvOS)
    /// Stops decoding video while nobody sees it (the app in the background, on iOS without picture in picture showing
    /// it, `ApplePlayback`), and selects the video track it showed again once someone does: the same track in the same
    /// file, else mpv's own choice (`auto`), as for any new file. `vid=no` takes the video output down; the sound plays
    /// on. The video back, its format is presented again: EDR or the TV's criteria again, and on iOS picture in picture
    /// reads the layer (`videoShown`).
    ///
    /// In the same file the video comes back with a seek to where the playback is: meanwhile mpv's demuxer read on ahead
    /// for the audio alone, and where it can't take the video stream back to the playback's position (an MPEG-TS
    /// stream, read minutes ahead), the video resumes at the demuxer's read position and the audio skips ahead to it.
    func setVideoSuspended(_ suspended: Bool) {
        queue.async { [self] in
            guard suspended != (videoSuspension != nil) else { return }
            if suspended {
                videoSuspension = (selectedVideoTrack?.id, fileStarts)
                setProperty("vid", "no")
            } else if let suspension = videoSuspension {
                videoSuspension = nil
                presentedFormat = nil
                let sameFile = suspension.fileStarts == fileStarts
                setProperty("vid", (sameFile ? suspension.track.map(String.init) : nil) ?? "auto")
                if sameFile, gate == nil, lifecycle.state.loaded {
                    let position = seekTarget ?? lifecycle.state.positionSeconds
                    seekTarget = position
                    command(["seek", String(position), "absolute+exact"])
                }
            }
            log.notice("video \(suspended ? "suspended: nobody sees it" : "decoded again")")
        }
    }
    #endif

    /// Ends the handle (on `queue`).
    private func destroy() {
        guard let mpv else { return }
        self.mpv = nil
        // After this returns no wakeup callback is running or can start (libmpv takes the same lock).
        mpv_set_wakeup_callback(mpv, nil, nil)
        mpv_terminate_destroy(mpv)
        wakeupTarget?.release()
        wakeupTarget = nil
        #if DEBUG && os(macOS)
        debug.handleDestroyed()
        #endif
        log.notice("mpv handle destroyed; the VO dropped \(self.droppedFrames) frames of the last file")
    }

    // MARK: Setup

    /// Starts the handle. Every option and observation is required: the first mpv call that fails (`check`) ends the
    /// handle, as a failed `mpv_initialize` does, and is the engine's error, which the player shows instead of playing
    /// on a half-configured mpv. That includes HDR output (`startup.hdr`): `target-colorspace-hint` `auto`, or `no`
    /// with the Hdr setting off. `environment` goes to the process first: mpv-build's FFmpeg reads its Dolby Vision
    /// conversion there as it opens a decoder. The settings' startup values (`MpvStartup`) go in the shared order: the
    /// log levels (and on the Mac the screenshots' folder) with the options, the stored audio output once mpv runs, and
    /// last the volume's top and the opening volume.
    private func create(wid: Int64, environment: [String: String], startup: Startup) {
        for (name, value) in environment { setenv(name, value, 1) }
        // libmpv requires the C numeric locale (client.h). Apple processes start in "C", but nothing guarantees
        // that nobody called setlocale(LC_ALL, "") since.
        setlocale(LC_NUMERIC, "C")
        guard let handle = mpv_create() else {
            startupFailure = "mpv_create failed"
            return fail("mpv_create failed")
        }
        check(mpv_request_log_messages(handle, startup.logLevel), "request_log_messages")
        var wid = wid
        check(mpv_set_option(handle, "wid", MPV_FORMAT_INT64, &wid), "wid")
        for (name, value) in MpvOptionsKt.COMMON_MPV_OPTIONS {
            let status = mpv_set_option_string(handle, name, value)
            #if !os(macOS)
            // iOS's and tvOS's libmpv has no Lua: no scripts, and none of the options that turn them off.
            if status == MPV_ERROR_OPTION_NOT_FOUND.rawValue { continue }
            #endif
            check(status, name)
        }
        for (name, value) in Self.options + startup.options {
            check(mpv_set_option_string(handle, name, value), name)
        }
        colorspaceHint = startup.hdr ? "auto" : "no"
        check(mpv_set_option_string(handle, "target-colorspace-hint", colorspaceHint), "target-colorspace-hint")
        if let directory = Self.subtitleFontDirectory {
            check(mpv_set_option_string(handle, "sub-fonts-dir", directory), "sub-fonts-dir")
            check(mpv_set_option_string(handle, "sub-font", Self.subtitleFontFamily), "sub-font")
        }
        #if DEBUG
        for (name, value) in EngineDebug.startupOptions { check(mpv_set_option_string(handle, name, value), name) }
        #endif
        if startupFailure == nil { check(mpv_initialize(handle), "mpv_initialize") }
        if startupFailure == nil {
            for (name, format) in Self.observedProperties {
                check(mpv_observe_property(handle, 0, name, format), "observe \(name)")
            }
        }
        if let startupFailure {
            mpv_terminate_destroy(handle)
            return fail(startupFailure)
        }
        // libmpv keeps this pointer without retaining it; the target is released after mpv_terminate_destroy.
        let target = Unmanaged.passRetained(WakeupTarget(engine: self))
        mpv_set_wakeup_callback(handle, { context in
            guard let context else { return }
            Unmanaged<WakeupTarget>.fromOpaque(context).takeUnretainedValue().engine?.scheduleDrain()
        }, target.toOpaque())
        mpv = handle
        wakeupTarget = target
        #if DEBUG && os(macOS)
        debug.handleCreated()
        #endif
        #if os(macOS)
        // The stored audio output where the Mac has it now. Read at once: no file is open, so no video output exists
        // that a synchronous read could wait behind (vo_avfoundation's main-thread work).
        if let list = mpv_get_property_string(handle, "audio-device-list") {
            let devices = String(cString: list)
            mpv_free(list)
            if let device = MpvStartup.shared.preferredAudioDevice(settings: startup.settings.value, deviceList: devices) {
                setProperty("audio-device", device)
            }
        }
        #endif
        // The user's mpv.conf after the engine's own values; every later app write yields to it (`setAppProperty`).
        for option in userConfig.options {
            guard let name = option.first as? String, let value = option.second as? String else { continue }
            setProperty(name, value)
        }
        // The volume's top and the opening volume come last, after every other startup value (`MpvStartup`'s order).
        setAppProperty("volume-max", String(volumeMax))
        setProperty("volume", min(startup.volume, volumeMax))
    }

    /// The bundled subtitle fonts (`subtitle-fonts` in the app's resources, shared with Android): Go Noto Current
    /// (every living script but Hangul) and its Hangul companion, which carries Go Noto Current's family name and only
    /// the Hangul syllables. They are `sub-fonts-dir` and their family `sub-font`, plain-text subtitles' font and
    /// libass's fallback for a glyph a styled subtitle's font lacks, ahead of CoreText's: for CJK ideographs CoreText
    /// falls back to PingFang, whose outlines (Apple's `hvgl` table, on iOS, tvOS and macOS 26) FreeType can't read,
    /// and libass drew boxes. libass loads every file in the folder (16.7 MB). Nil, logged, when the folder is missing.
    private static let subtitleFontDirectory: String? = {
        guard let directory = Bundle.main.url(forResource: "subtitle-fonts", withExtension: nil) else {
            log.error("no subtitle fonts in the app's resources")
            return nil
        }
        return directory.path
    }()

    /// The bundled subtitle fonts' family (`subtitleFontDirectory`).
    private static let subtitleFontFamily = "Go Noto Current-Regular"

    /// Platform output options, after the ones every engine sets (`COMMON_MPV_OPTIONS`); they stay
    /// inside the engine by contract. `hwdec` comes with each file (the shared `PlaybackOptions`).
    private static let options: [(String, String)] = {
        var options = [
            ("vo", "avfoundation"),
            // Subtitles go to the VO's own layer next to the display layer instead of a Core Image composite of every
            // frame, which would also round-trip HDR frames through linear P3.
            ("avfoundation-composite-osd", "no"),
        ]
        #if os(tvOS) || os(macOS)
        // Samples carry mpv's scheduled display time against a free-running timebase, so audio clock
        // drift never accumulates in the VO, and no seek or stop moves the display layer's clock. On media time it
        // jumps back with every backward seek and to 0 when a file stops; on macOS 27 frames already taken for display
        // then sit ahead of it, and the window server stops updating the screen until the clock reaches them, or its
        // watchdog panics the Mac first. iOS stays on media time, which AVPictureInPictureController reads; tvOS has no
        // picture in picture, and the Mac's borrows the layers and never reads the clock (AppKit/PictureInPicture).
        options.append(("avfoundation-presentation", "host"))
        #endif
        #if os(iOS)
        // On an upright phone the surface is the whole screen and the video a band across it: subtitles sized by the
        // video, not the screen, keep its proportions. `sub-scale-with-window=no` sizes them by the video as tvOS,
        // macOS and the other platforms size them on a screen of the video's shape (`sub-scale-by-window=no` would fix
        // them at the style's size in pixels, under half of that on an iPad). Where they sit, in the bands around the
        // picture or within it, is `sub-use-margins` (`updateSubtitleFrame`).
        options.append(("sub-scale-with-window", "no"))
        #endif
        if !audioOutput.isEmpty { options.append(("ao", audioOutput)) }
        #if !os(macOS)
        // ao_audiounit (iOS's fallback, tvOS's PCM output) asks the audio session to mix with others unless this is
        // set, and a mixable session loses Now Playing; on iOS and tvOS it claims nothing else.
        options.append(("audio-exclusive", "yes"))
        // mpv expands its default title (`${?media-title:…}`) on every OSD update, to name a window and an audio stream
        // that iPhone, iPad and Apple TV don't have; a constant spares the core that work. The Mac names its window by it.
        options.append(("title", "mpv"))
        #endif
        options += [
            ("hwdec-codecs", "all"),
            ("hwdec-software-fallback", "yes"),
        ]
        #if !os(tvOS)
        options.append(("screenshot-directory", screenshotDirectory))
        #endif
        return options
    }()

    /// mpv's `ao`: the audio outputs mpv tries in turn, each refusing what it can't play. Empty for mpv's own.
    ///
    /// - Mac: CoreAudio first, so PCM plays through the one HAL-backed timing path, then AVFoundation. AVFoundation takes
    ///   Dolby passthrough: CoreAudio hands a bitstream to coreaudio_exclusive, which refuses an output without IEC 61937
    ///   streams (every built-in, AirPods and most USB outputs), so AC-3 and E-AC-3 reach the system's Dolby decoder
    ///   (Atmos on AirPods and the built-in speakers). It also plays everything when CoreAudio fails to open (macOS 27
    ///   betas reject ao_coreaudio's channel layout), where a single entry would mean no audio at all. mpv-build has no
    ///   `spatial` output for the Mac.
    /// - iPhone and iPad: AVFoundation before AudioUnit, mpv's default. ao_audiounit opens as many channels as the route
    ///   reports, and AirPods report 2 with Spatial Audio, so every 5.1 and 7.1 track was mixed down to stereo;
    ///   ao_avfoundation hands the system the track's own channels, which it spatializes, and its AC-3 and E-AC-3 go to
    ///   the system's Dolby decoder. AudioUnit only where AVFoundation's fails to open.
    /// - Apple TV: mpv's default (AudioUnit, then AVFoundation): AudioUnit plays PCM with the channels HDMI reports, and
    ///   refuses a bitstream, which AVFoundation then hands to the system's Dolby decoder.
    /// - From iOS and tvOS 26, mpv-build's `spatial` first. It takes TrueHD and DTS-HD passthrough alone, refusing every
    ///   other format before it touches the audio session, and plays TrueHD Atmos and DTS:X as Apple spatial audio; a
    ///   track its renderer can't play (TrueHD or DTS-HD MA without objects) reopens the output, and mpv decodes it. On
    ///   tvOS the trailing comma keeps mpv's default outputs after it.
    ///
    /// `audio-exclusive` stays off on the Mac, where it would open every CoreAudio output, PCM included, in hog mode
    /// (`options`).
    static let audioOutput: String = {
        #if os(macOS)
        return "coreaudio,avfoundation"
        #elseif os(iOS)
        if #available(iOS 26, *) { return "spatial,avfoundation,audiounit" }
        return "avfoundation,audiounit"
        #else
        if #available(tvOS 26, *) { return "spatial," }
        return ""
        #endif
    }()

    /// The formats passthrough names in `audio-spdif`: AC-3 and E-AC-3, which ao_avfoundation hands the
    /// system's Dolby decoder (on Apple TV the HDMI output then carries Dolby to a TV or receiver that takes it), and
    /// from iOS and tvOS 26 TrueHD and DTS-HD for `spatial` (`audioOutput`). The other formats would only cost an
    /// output's refusal before mpv decodes them: no Apple output carries DTS or TrueHD to HDMI.
    static let passthroughCodecs: [String] = {
        #if !os(macOS)
        if #available(iOS 26, tvOS 26, *) { return ["ac3", "eac3", "truehd", "dts-hd"] }
        #endif
        return ["ac3", "eac3"]
    }()

    /// `MpvLifecycle`'s properties, then this engine's own.
    private static let observedProperties: [(String, mpv_format)] = {
        var properties: [(String, mpv_format)] = MpvLifecycle.companion.DOUBLES.map { ($0, MPV_FORMAT_DOUBLE) }
            + MpvLifecycle.companion.FLAGS.map { ($0, MPV_FORMAT_FLAG) }
            + MpvLifecycle.companion.TEXTS.map { ($0, MPV_FORMAT_STRING) }
        properties += [
            // Logged only: which outputs mpv settled on, and how many frames it dropped (`destroy`, `endFile`).
            ("current-vo", MPV_FORMAT_STRING),
            ("current-ao", MPV_FORMAT_STRING),
            ("frame-drop-count", MPV_FORMAT_INT64),
            // The surface's size, which a stretched picture takes the shape of, and (iOS) the picture's place on it,
            // which text subtitles are placed by: it changes with a rotation, a resize and another file's shape.
            ("osd-dimensions", MPV_FORMAT_STRING),
        ]
        #if os(macOS)
        // The outputs the player offers (iOS and tvOS route audio through the audio session).
        properties += MpvLifecycle.companion.AUDIO_DEVICE_TEXTS.map { ($0, MPV_FORMAT_STRING) }
        #endif
        #if DEBUG && os(iOS)
        properties.append(("sub-pos", MPV_FORMAT_DOUBLE))
        #endif
        #if DEBUG
        // The passthrough tests' probe (`EngineDebug.audioChanged`), with `current-ao` and `audio-out-params/format`, and
        // the audio clock's lead over the video's (`EngineDebug.avSyncChanged`).
        properties.append(("audio-spdif", MPV_FORMAT_STRING))
        properties.append(("avsync", MPV_FORMAT_DOUBLE))
        // The startup values from the settings, for the probe (`EngineDebug.settingChanged`).
        properties += EngineDebug.settingProperties.map { ($0, MPV_FORMAT_STRING) }
        #endif
        return properties
    }()

    /// How often the stats are read while they are wanted (the playback info).
    private static let statsInterval: DispatchTimeInterval = .milliseconds(Int(MpvOptionsKt.STATS_INTERVAL_MS))

    #if os(macOS)
    /// Draws the paused frame again: the surface flushed its display layer as the video came back in sight
    /// (`VideoSurface.setOutOfSight`), and a playing video refills it on its own.
    func redrawIfPaused() {
        queue.async { [self] in redrawPausedFrame() }
    }

    /// Decodes the paused frame again where it is, which presents it anew (on `queue`): after a flush of the display
    /// layer, and after subtitles are picked while the video is paused, which stay off the paused picture until it
    /// plays on (seen on the Mac: vo_avfoundation's redraw of the paused frame leaves its subtitle layer as it was).
    private func redrawPausedFrame() {
        guard !released, lifecycle.state.loaded, lifecycle.state.paused else { return }
        command(["seek", "0", "relative+exact"])
    }
    #endif

    // MARK: Requests

    /// `load`: the load (`MpvLifecycle.load`) this is the `loadfile` of; mpv refusing it is that load's error (`complete`).
    private func command(_ args: [String], load: Int64? = nil) {
        guard let mpv else { return }
        let id = register(args.first ?? "command", load: load)
        let cStrings = args.map { strdup($0) }
        defer { cStrings.forEach { free($0) } }
        var argv: [UnsafePointer<CChar>?] = cStrings.map { UnsafePointer($0) }
        argv.append(nil)
        // libmpv copies the arguments before returning.
        completeIfRejected(id, mpv_command_async(mpv, id, &argv))
    }

    /// The load's file, once mpv took every value of it (`complete`). `pause` survives loadfile: the new file starts
    /// paused and openGate starts it. Written after loadfile so nothing changes for the outgoing file before it is
    /// replaced.
    private func open(load: Int64, url: String) {
        command(["loadfile", url, "replace"], load: load)
        setProperty("pause", "yes")
    }

    /// `secret`: a failure's log line names the property without its value (headers can carry an API key). `load`: the
    /// load (`MpvLifecycle.load`) whose file this value is; mpv refusing it is that load's error (`complete`). Returns
    /// the request's id.
    @discardableResult
    private func setProperty(_ name: String, _ value: String, secret: Bool = false, load: Int64? = nil) -> UInt64 {
        guard let mpv else { return 0 }
        let id = register(secret ? "set \(name)" : "set \(name)=\(value)", load: load)
        let status = value.withCString { valuePointer in
            var data: UnsafePointer<CChar>? = valuePointer
            return mpv_set_property_async(mpv, id, name, MPV_FORMAT_STRING, &data)
        }
        completeIfRejected(id, status)
        return id
    }

    /// An app write after mpv started: skipped where a line of the user's mpv.conf sets `name`
    /// (`MpvUserConfig.appWrites`).
    private func setAppProperty(_ name: String, _ value: String, load: Int64? = nil) {
        guard userConfig.appWrites(name: name) else { return }
        setProperty(name, value, load: load)
    }

    private func setProperty(_ name: String, _ value: Double) {
        guard let mpv else { return }
        let id = register("set \(name)=\(value)")
        var data = value
        // libmpv copies the value before returning.
        completeIfRejected(id, mpv_set_property_async(mpv, id, name, MPV_FORMAT_DOUBLE, &data))
    }

    private func register(_ description: String, load: Int64? = nil) -> UInt64 {
        let id = nextRequestId
        nextRequestId += 1
        pendingRequests[id] = (description, load)
        return id
    }

    private func completeIfRejected(_ id: UInt64, _ status: CInt) {
        guard status < 0 else { return }
        complete(id, status)
    }

    private func complete(_ id: UInt64, _ status: CInt) {
        guard let request = pendingRequests.removeValue(forKey: id) else { return }
        if let opening, opening.request == id {
            self.opening = nil
            // The load's last value is in, and mpv refused none before it: the load hasn't failed.
            if status >= 0, opening.load == lifecycle.state.loadId, lifecycle.state.error == nil {
                return open(load: opening.load, url: opening.url)
            }
        }
        guard status < 0 else { return }
        let message = "\(request.description) failed: \(Self.errorString(status))"
        // mpv refused the current load's file (a value of it, or its loadfile): nothing replaced the file playing.
        if let load = request.load, load == lifecycle.state.loadId { return refuse(load, message, kind: MpvState.shared.errorKind(code: status)) }
        log.error(message)
    }

    /// mpv refused a value of `load` or its loadfile: the load fails with mpv's reason, then the file mpv plays on is
    /// current again (`MpvLifecycle.keepOutgoing`), and the load's start gate lets go, mpv's pause the viewer's latest.
    private func refuse(_ load: Int64, _ message: String, kind: EngineErrorKind) {
        fail(message, kind: kind)
        lifecycle.keepOutgoing()
        if gate?.load == load { openGate(load) } else { publish() }
    }

    // MARK: Events

    fileprivate func scheduleDrain() {
        queue.async { [weak self] in self?.drainEvents() }
    }

    private func drainEvents() {
        while let mpv, let event = mpv_wait_event(mpv, 0), event.pointee.event_id != MPV_EVENT_NONE {
            handle(event.pointee)
        }
        updateDisplay()
        publish()
    }

    private func handle(_ event: mpv_event) {
        switch event.event_id {
        case MPV_EVENT_PROPERTY_CHANGE:
            guard let data = event.data else { return }
            propertyChanged(data.assumingMemoryBound(to: mpv_event_property.self).pointee)
        case MPV_EVENT_COMMAND_REPLY, MPV_EVENT_SET_PROPERTY_REPLY:
            complete(event.reply_userdata, event.error)
        case MPV_EVENT_GET_PROPERTY_REPLY:
            statsReplied(event)
        case MPV_EVENT_START_FILE:
            fileStarts += 1
            lifecycle.startFile()
        case MPV_EVENT_FILE_LOADED:
            lifecycle.fileLoaded()
        case MPV_EVENT_PLAYBACK_RESTART:
            seekTarget = nil
            _ = lifecycle.playbackRestart()
        case MPV_EVENT_END_FILE:
            guard let data = event.data else { return }
            endFile(data.assumingMemoryBound(to: mpv_event_end_file.self).pointee)
        case MPV_EVENT_LOG_MESSAGE:
            guard let data = event.data else { return }
            logMessage(data.assumingMemoryBound(to: mpv_event_log_message.self).pointee)
        default:
            break
        }
    }

    private func propertyChanged(_ property: mpv_event_property) {
        let name = String(cString: property.name)
        let value = MpvValue(property)
        #if os(iOS)
        if name == "time-pos" { reportedPosition.withLock { $0 = value.double ?? 0 } }
        #endif
        switch name {
        case "current-vo": log.notice("current-vo = \(value.string ?? "none")")
        case "current-ao":
            audioOutputDriver = value.string ?? ""
            log.notice("current-ao = \(value.string ?? "none")")
            #if DEBUG
            debug.audioChanged(name, value.string)
            #endif
        case "frame-drop-count": droppedFrames = value.int ?? 0
        case "osd-dimensions": osdDimensionsChanged(value.string)
        #if DEBUG && os(iOS)
        case "sub-pos": debug.subtitlePositionChanged(value.double, frame: subtitleFrame, controlsLift: controlsLift)
        #endif
        #if DEBUG
        case "audio-spdif": debug.audioChanged(name, value.string)
        case "avsync": debug.avSyncChanged(value.double)
        case _ where EngineDebug.settingProperties.contains(name): debug.settingChanged(name, value.string)
        #endif
        default:
            if let double = value.double {
                lifecycle.double(name: name, value: double)
            } else if let flag = value.flag {
                lifecycle.flag(name: name, value: flag)
            } else if let string = value.string {
                lifecycle.text(name: name, value: string)
            } else {
                lifecycle.unavailable(name: name)
            }
            if name == "video-params" {
                ambientLighting.onVideoParams(displayAspect: MpvState.shared.displayAspect(videoParams: value.string))
            }
            if name == "audio-out-params/format" {
                log.notice("audio-out-params/format = \(value.string ?? "none")")
                #if DEBUG
                debug.audioChanged(name, value.string)
                #endif
            }
        }
    }

    /// The surface or the picture on it changed (a rotation, a resize, another file's shape): a stretched picture takes
    /// the surface's new shape, and lifted subtitles placed by the picture follow it.
    private func osdDimensionsChanged(_ osdDimensions: String?) {
        let aspect = MpvState.shared.surfaceAspect(osdDimensions: osdDimensions)?.doubleValue
        var changed = aspect != surfaceAspect
        surfaceAspect = aspect
        // The picture as mpv places it without a crop (its margins are the bars): what a stretch scales to the surface.
        if videoLayout.fit != .cover, let dimensions = MpvState.shared.osdDimensions(osdDimensions: osdDimensions) {
            let pictureWidth = dimensions.width - dimensions.left - dimensions.right
            let pictureHeight = dimensions.height - dimensions.top - dimensions.bottom
            if pictureWidth > 0, pictureHeight > 0 {
                let stretch = (x: dimensions.width / pictureWidth, y: dimensions.height / pictureHeight)
                if abs(stretch.x - pictureStretch.x) > 0.001 || abs(stretch.y - pictureStretch.y) > 0.001 {
                    pictureStretch = stretch
                    changed = true
                }
            }
        }
        if changed { applyVideoLayout() }
        pictureFrame = MpvState.shared.subtitleFrame(osdDimensions: osdDimensions)
        updateSubtitleFrame()
    }

    /// `sub-use-margins` and the frame text subtitles go by: in the bands around the picture and by the screen when the
    /// style lets them sit there or the picture runs past the surface, else by the picture. `sub-pos` follows a new
    /// frame, and with `reposition` (a new style) whatever the frame.
    private func updateSubtitleFrame(reposition: Bool = false) {
        let margins = subtitleStyle.useMargins || videoLayout.overflows
        let value = margins ? "yes" : "no"
        if value != subtitleMargins {
            subtitleMargins = value
            setAppProperty("sub-use-margins", value)
        }
        let frame = margins ? SubtitleFrame.companion.SCREEN : pictureFrame
        guard reposition || frame != subtitleFrame else { return }
        subtitleFrame = frame
        applySubtitlePosition()
    }

    private func endFile(_ endFile: mpv_event_end_file) {
        log.notice("file ended (reason \(endFile.reason.rawValue)); the VO dropped \(self.droppedFrames) frames")
        lifecycle.endFile(reason: Int32(endFile.reason.rawValue), error: endFile.error, message: Self.errorString(endFile.error))
    }

    /// mpv's own lines go to the app's log (`MpvLogLines`), redacted: mpv names the URL it failed to open ("Failed to
    /// open <url>."), and stream URLs carry API keys. The lifecycle takes the line as it is: FFmpeg's HTTP protocol names
    /// the status only in its log ("HTTP error 404 Not Found"), and the error lines name the failure; libmpv hands over
    /// its queued events before its log lines, and `publish` runs once the drain has both.
    private func logMessage(_ message: mpv_event_log_message) {
        let prefix = message.prefix.map(mpvString) ?? ""
        let text = (message.text.map(mpvString) ?? "").trimmingCharacters(in: .newlines)
        let failure = message.log_level == MPV_LOG_LEVEL_FATAL || message.log_level == MPV_LOG_LEVEL_ERROR
        lifecycle.logLine(
            text: text, error: failure, prefix: prefix,
            warning: message.log_level == MPV_LOG_LEVEL_WARN || failure
        )
        log.mpv(prefix: prefix, level: message.log_level, text: text)
    }

    // MARK: Stats

    /// Starts a stats reading (on `queue`): `MpvState`'s stats properties from mpv, the text ones as strings and the
    /// numbers as doubles, and the display from the surface on the main thread, which hands it back here (nothing waits
    /// for either). They are read rather than observed: `video-bitrate`, `audio-bitrate` and `vo-delayed-frame-count`
    /// change with every frame (mpv's per-tick group), and none of it is wanted while the info is closed.
    /// `finishStatsReading` commits the answers as one, so a reading publishes once.
    private func readStats() {
        guard let mpv, statsWanted else { return }
        var reading = StatsReading(run: statsRun, fileStarts: fileStarts, started: .now())
        let requests = MpvState.shared.STATS_TEXT_PROPERTIES.map { ($0, MPV_FORMAT_STRING) }
            + MpvState.shared.STATS_NUMBER_PROPERTIES.map { ($0, MPV_FORMAT_DOUBLE) }
        for (name, format) in requests {
            let id = nextRequestId
            nextRequestId += 1
            if mpv_get_property_async(mpv, id, name, format) >= 0 { reading.replies[id] = name }
        }
        statsReading = reading
        let run = statsRun
        DispatchQueue.main.async { [weak self, surface] in
            let display = MainActor.assumeIsolated { surface.displayOutput() }
            guard let self else { return }
            queue.async { self.displayRead(display, run: run) }
        }
    }

    /// mpv's answer to a stats request (MPV_EVENT_GET_PROPERTY_REPLY); one of an earlier reading is dropped. An error
    /// (the property unavailable: no video, no cache) leaves the property without a value.
    private func statsReplied(_ event: mpv_event) {
        guard var reading = statsReading, let name = reading.replies[event.reply_userdata] else { return }
        reading.replies[event.reply_userdata] = nil
        if event.error >= 0, let data = event.data {
            let value = MpvValue(data.assumingMemoryBound(to: mpv_event_property.self).pointee)
            reading.texts[name] = value.string
            reading.numbers[name] = value.double
        }
        statsReading = reading
        finishStatsReading()
    }

    private func displayRead(_ display: DisplayOutput, run: UInt64) {
        guard var reading = statsReading, reading.run == run, reading.display == nil else { return }
        reading.display = display
        statsReading = reading
        finishStatsReading()
        publish()
    }

    /// The surface shows the video in another dynamic range (iOS, tvOS: `VideoSurface.onOutputRangeChange`), as its
    /// `displayOutput()` reports it: what the display gets.
    private func surfaceRangeRead(_ display: DisplayOutput) {
        lifecycle.outputRange(range: display.dynamicRange)
        publish()
    }

    /// Once every answer of the reading is in: the lifecycle takes it, with how the system renders the audio where it
    /// says (iOS, tvOS), unless a load came meanwhile (the next reading is the new file's), and the next reading starts
    /// `statsInterval` after this one started.
    private func finishStatsReading() {
        guard let reading = statsReading, reading.replies.isEmpty, let display = reading.display else { return }
        statsReading = nil
        if reading.fileStarts == fileStarts {
            #if os(macOS)
            let rendering: AudioRendering? = nil
            #else
            let rendering = PlaybackAudioSession.rendering
            #endif
            lifecycle.stats(reading: MpvState.shared.stats(
                text: { reading.texts[$0] },
                number: { reading.numbers[$0].map { KotlinDouble(double: $0) } },
                display: MpvState.DisplayMode(
                    width: display.width.map { KotlinInt(int: Int32(clamping: $0)) },
                    height: display.height.map { KotlinInt(int: Int32(clamping: $0)) },
                    refreshRate: display.refreshRate.map { KotlinDouble(double: $0) }
                ),
                audioRendering: rendering
            ))
        }
        let run = reading.run
        queue.asyncAfter(deadline: reading.started + Self.statsInterval) { [weak self] in
            guard let self, statsRun == run else { return }
            readStats()
        }
    }

    // MARK: Display

    /// How long the start gate waits for `video-params` after the first frame. Property changes trail events, so
    /// the format normally arrives in the same or the next drain; this only bounds a file whose video never reports
    /// one, which would otherwise never start.
    private static let videoParamsWait: DispatchTimeInterval = .seconds(2)

    /// Runs after every drain: opens the start gate once the first frame is up and the display is ready for the video's
    /// format, and keeps the display in step with the format after that.
    private func updateDisplay() {
        guard lifecycle.state.loaded else { return }
        guard var shut = gate, !shut.presenting else {
            // A format change within the file (another video track, a stream that changes resolution or range), also
            // while the gate waits for the display: the surface's wait for the display then covers the new format too,
            // so the file starts once the display has settled for the format it plays in.
            if let format = displayFormat, format != presentedFormat { present(format, then: nil) }
            return
        }
        let format = displayFormat
        if format == nil, selectedVideoTrack != nil {
            if !shut.timeoutArmed {
                shut.timeoutArmed = true
                gate = shut
                let load = shut.load
                queue.asyncAfter(deadline: .now() + Self.videoParamsWait) { [weak self] in
                    self?.videoParamsTimedOut(load)
                }
            }
            return
        }
        shut.presenting = true
        gate = shut
        let load = shut.load
        guard let format, format != presentedFormat else { return openGate(load) }
        present(format) { [weak self] in
            guard let self else { return }
            queue.async { self.openGate(load) }
        }
    }

    /// What the display should be set up for, once the video output is configured.
    private var displayFormat: DisplayFormat? {
        guard let video = lifecycle.state.video else { return nil }
        return DisplayFormat(video: video, doviLevel: lifecycle.videoTracks.first { $0.selected }?.doviLevel?.intValue)
    }

    private var selectedVideoTrack: Track? { lifecycle.state.tracks.first { $0.kind == .video && $0.selected } }

    private func videoParamsTimedOut(_ load: Int64) {
        guard let gate, gate.load == load, !gate.presenting else { return }
        log.error("no video format after the first frame; starting playback without one")
        openGate(load)
    }

    private func present(_ format: DisplayFormat, then completion: (@Sendable () -> Void)?) {
        presentedFormat = format
        log.notice(
            """
            display format \(format.dynamicRange.name) \(format.width)x\(format.height) \
            \(String(format: "%.3f", format.fps ?? 0)) fps peak=\(format.sigPeak ?? 0) dovi=\(format.doviProfile ?? 0).\(format.doviLevel ?? 0)
            """
        )
        DispatchQueue.main.async { [surface] in
            MainActor.assumeIsolated { surface.present(format, completion: completion ?? {}) }
        }
    }

    private func openGate(_ load: Int64) {
        guard let gate, gate.load == load else { return }
        self.gate = nil
        #if os(macOS)
        // The display switched during the gate: its hold plays when it ends.
        if displayHold != nil { return publish() }
        #endif
        // While the gate holds, the state's pause is the caller's.
        let paused = lifecycle.state.paused
        log.notice("start gate open: the display is ready (\(paused ? "stays paused" : "plays"))")
        // Reported at once; mpv's own `pause` change confirms it.
        lifecycle.endHold(paused: paused)
        if !paused { setProperty("pause", "no") }
        publish()
    }

    // MARK: State

    private func publish() {
        guard let listener, !released, let state = lifecycle.publishable() else { return }
        logChanges(state)
        listener.onState(state: state)
        #if DEBUG
        debug.reportEngine(state: state)
        #endif
    }

    /// The unified-log record of a run: what the engine reports, one line per changed facet, each built only when what
    /// it reads changed. The position line changes every second and stays at debug level (memory only unless
    /// streamed); the rest change a few times per file and persist.
    private func logChanges(_ state: EngineState) {
        let now = LogSource(state: state, gate: gate != nil, transfer: lifecycle.transfer, videoTracks: lifecycle.videoTracks)
        let last = loggedFrom
        loggedFrom = now
        func changed(_ same: (LogSource, LogSource) -> Bool) -> Bool { last.map { !same($0, now) } ?? true }
        if changed(LogSource.samePlayback) { logChange("state", state.playbackSummary(gate: now.gate), verbose: true) }
        if changed(LogSource.sameVideo) { logChange("video", state.videoSummary(transfer: now.transfer)) }
        if changed(LogSource.sameAudio) { logChange("audio", state.audioSummary) }
        if changed(LogSource.sameTracks) { logChange("tracks", state.trackSummary(videoTracks: now.videoTracks)) }
        if changed(LogSource.sameSettings) { logChange("settings", state.settingsSummary) }
    }

    private func logChange(_ name: String, _ line: String, verbose: Bool = false) {
        guard logged[name] != line else { return }
        logged[name] = line
        if verbose { log.debug("\(name) \(line)") } else { log.notice("\(name) \(line)") }
    }

    private func fail(_ message: String, kind: EngineErrorKind = .other) {
        log.error(message)
        lifecycle.fail(error: EngineError(message: message, httpStatus: nil, kind: kind))
        publish()
    }

    /// A startup call (`create`): the first that fails is `startupFailure`, which ends the handle; later ones are logged.
    private func check(_ status: CInt, _ what: String) {
        guard status < 0 else { return }
        let message = "\(what): \(Self.errorString(status))"
        if startupFailure == nil {
            startupFailure = message
        } else {
            log.error(message)
        }
    }

    static func errorString(_ status: CInt) -> String {
        mpv_error_string(status).map(mpvString) ?? "mpv error \(status)"
    }
}

/// A stats reading under way (`MpvPlayerEngine.readStats`): the answers so far and what it still waits for.
private struct StatsReading {
    /// The run of `setStatsWanted` it belongs to.
    let run: UInt64
    /// The engine's `fileStarts` when it started: a load since makes it the replaced file's.
    let fileStarts: UInt64
    let started: DispatchTime
    /// mpv's outstanding answers: the property each request id asked for.
    var replies: [UInt64: String] = [:]
    /// mpv's answers so far: `MpvState.STATS_TEXT_PROPERTIES` as text, `STATS_NUMBER_PROPERTIES` as numbers.
    var texts: [String: String] = [:]
    var numbers: [String: Double] = [:]
    /// The display as the surface reported it; nil until it has.
    var display: DisplayOutput?
}

/// The wakeup callback's context: libmpv calls it on its own threads, and it only schedules a drain on the engine's
/// queue. Weak, so a late callback never keeps a released engine alive.
private final class WakeupTarget: @unchecked Sendable {
    weak var engine: MpvPlayerEngine?
    init(engine: MpvPlayerEngine) { self.engine = engine }
}

/// What mpv takes from the device settings as it starts (`MpvPlayerEngine.create`), read from them in the engine's
/// `init`.
private struct Startup: @unchecked Sendable {
    let hdr: Bool
    /// The level mpv's log messages are asked at (`MpvStartup.logLevel`); debug builds' at least `info`, which their
    /// runs' logs keep.
    let logLevel: String
    /// Options from the settings: `MpvStartup.properties` (on the Mac a desktop's) and `avfoundation-osd-video-res`,
    /// the subtitles drawn at the video's resolution and scaled with it (the Subtitle render resolution setting's
    /// Video) or at the screen's.
    let options: [(String, String)]
    let volumeMax: Double
    let volume: Double
    /// The settings, for the stored audio output once mpv lists the outputs (`MpvStartup.preferredAudioDevice`).
    let settings: UncheckedBox<DeviceSettings>

    init(settings: DeviceSettings) {
        hdr = settings.hdr
        var logLevel = MpvStartup.shared.logLevel(debugLogging: settings.debugLogging)
        #if DEBUG
        if logLevel == "warn" { logLevel = "info" }
        #endif
        self.logLevel = logLevel
        #if os(macOS)
        let desktop = true
        #else
        let desktop = false
        #endif
        var options: [(String, String)] = MpvStartup.shared.properties(settings: settings, desktop: desktop).compactMap { pair in
            guard let name = pair.first as? String, let value = pair.second as? String else { return nil }
            return (name, value)
        }
        options.append(("avfoundation-osd-video-res", settings.subtitleRenderResolution == .video ? "yes" : "no"))
        self.options = options
        volumeMax = MpvStartup.shared.volumeMax(settings: settings)
        volume = MpvStartup.shared.volume(settings: settings)
        self.settings = UncheckedBox(settings)
    }
}

/// Each load starts paused and plays once its first frame is up and the display is set up for the video: on tvOS
/// that can be an HDMI mode switch that blanks the screen for seconds, and playing through it would lose the start.
/// Until it opens the lifecycle holds: the state buffers, and reports the caller's pause.
private struct StartGate: Equatable {
    /// The load it holds the start of (`MpvLifecycle.load`).
    let load: Int64
    /// The display format has gone to the surface; the gate opens when the surface reports the display ready.
    var presenting = false
    /// The wait for `video-params` after the first frame is bounded (`MpvPlayerEngine.videoParamsWait`).
    var timeoutArmed = false
}

/// Log lines (diagnostics, not user-visible text).
private extension EngineState {
    func playbackSummary(gate: Bool) -> String {
        let error = error.map { " error=\($0.message) http=\($0.httpStatus.map { String($0.intValue) } ?? "-")" } ?? ""
        return "position=\(Int(positionSeconds)) duration=\(String(format: "%.2f", durationSeconds)) paused=\(paused) "
            + "gate=\(gate) buffering=\(buffering) "
            + "loaded=\(loaded) restarts=\(playbackRestarts) seekable=\(seekable) eof=\(eof)"
            + " cache-start=\(cacheStartSeconds.map { String(Int($0.doubleValue)) } ?? "-")\(error)"
    }

    func videoSummary(transfer: String?) -> String {
        guard let video else { return "none hwdec=\(hwdec ?? "-")" }
        let dovi = video.dynamicRange == .dolbyVision ? " dovi=\(video.doviProfile.map { String($0.intValue) } ?? "?")" : ""
        return "\(video.width)x\(video.height) \(video.codec ?? "-") \(video.fps.map { String(format: "%.3f", $0.doubleValue) } ?? "-") fps "
            + "range=\(video.dynamicRange.name)\(dovi) gamma=\(transfer ?? "-") hwdec=\(hwdec ?? "-")"
    }

    var audioSummary: String {
        guard let audio else { return "none" }
        return "\(audio.codec ?? "-") channels=\(audio.channels.map { String($0.intValue) } ?? "-") "
            + "rate=\(audio.sampleRate.map { String($0.intValue) } ?? "-") passthrough=\(audioPassthrough)"
    }

    func trackSummary(videoTracks: [MpvState.VideoTrack]) -> String {
        tracks.map { track in
            let kind = switch track.kind {
            case .video: "video"
            case .audio: "audio"
            case .subtitle: "sub"
            }
            var flags: [String] = []
            if track.selected { flags.append("selected") }
            if track.isDefault { flags.append("default") }
            if track.forced { flags.append("forced") }
            if track.hearingImpaired { flags.append("sdh") }
            if track.visualImpaired { flags.append("ad") }
            if track.external { flags.append("external") }
            if let channels = track.channels { flags.append("\(channels.intValue)ch") }
            if let profile = videoTracks.first(where: { $0.id == track.id })?.doviProfile { flags.append("dvhe.\(profile.intValue)") }
            return "\(kind)#\(track.id) \(track.codec ?? "-") \(track.language ?? "-") [\(flags.joined(separator: ","))]"
        }.joined(separator: "; ")
    }

    var settingsSummary: String {
        "speed=\(speed) sub-delay=\(subtitleDelaySeconds) audio-delay=\(audioDelaySeconds) volume=\(volume) muted=\(muted)"
            + " chapters=\(chapters.count) audio-device=\(audioDevice) devices=\(audioDevices.count)"
    }
}

/// What `logChanges` builds its lines from: a facet's line is built again only when what it reads changed.
private struct LogSource {
    let state: EngineState
    let gate: Bool
    let transfer: String?
    let videoTracks: [MpvState.VideoTrack]

    static func samePlayback(_ lhs: Self, _ rhs: Self) -> Bool {
        let left = lhs.state, right = rhs.state
        return Int(left.positionSeconds) == Int(right.positionSeconds) && left.durationSeconds == right.durationSeconds
            && left.paused == right.paused && lhs.gate == rhs.gate && left.buffering == right.buffering
            && left.loaded == right.loaded && left.playbackRestarts == right.playbackRestarts && left.seekable == right.seekable
            && left.eof == right.eof && left.cacheStartSeconds == right.cacheStartSeconds && left.error == right.error
    }

    static func sameVideo(_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.state.video == rhs.state.video && lhs.transfer == rhs.transfer && lhs.state.hwdec == rhs.state.hwdec
    }

    static func sameAudio(_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.state.audio == rhs.state.audio && lhs.state.audioPassthrough == rhs.state.audioPassthrough
    }

    static func sameTracks(_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.state.tracks == rhs.state.tracks && lhs.videoTracks == rhs.videoTracks
    }

    static func sameSettings(_ lhs: Self, _ rhs: Self) -> Bool {
        let left = lhs.state, right = rhs.state
        return left.speed == right.speed && left.subtitleDelaySeconds == right.subtitleDelaySeconds
            && left.audioDelaySeconds == right.audioDelaySeconds && left.volume == right.volume && left.muted == right.muted
            && left.chapters.count == right.chapters.count && left.audioDevice == right.audioDevice
            && left.audioDevices.count == right.audioDevices.count
    }
}

/// The engine's mpv property writes for the shared audio reconciler.
private final class AudioPropertyWriter: MpvPropertyWriter {
    private let body: (String, String) -> Void

    init(_ body: @escaping (String, String) -> Void) {
        self.body = body
    }

    func write(name: String, value: String) throws {
        body(name, value)
    }
}
