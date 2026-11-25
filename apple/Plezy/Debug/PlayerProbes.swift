import MediaPlayer
import SwiftUI
import PlezyKit

#if os(iOS)
import AVFoundation
#endif

/// Debug builds: the player's probes over the video (`PlayerScreen`), elements whose values carry what the UI tests
/// can't read from the app or the system. A probe the Mac's tests read carries its reading as its label too: the Mac
/// doesn't report a plain element's value.
struct PlayerProbes: View {
    let playback: PlayerModel

    var body: some View {
        NowPlayingProbe(center: playback.nowPlaying)
        EngineProbe(reading: playback.engineReading)
        TimelineProbes(store: playback.store)
        PlayerStateProbe(state: playback.state.state)
        #if os(macOS)
        DisplayClockProbe(reading: playback.apple.mpv.debug.displayClock)
        if let simulated = SimulatedDisplayModes.shared { DisplayModesProbe(reading: simulated) }
        #endif
        #if !os(macOS)
        KeepAwakeProbe(reading: playback.idleTimer)
        #endif
        #if os(tvOS)
        DisplaySwitchProbe(reading: .shared)
        #endif
        #if os(iOS)
        KeyboardProbe()
        PlaybackMenuProbe()
        SubtitlePlacementProbe(placement: playback.subtitlePlacement)
        BackgroundPlaybackProbe(store: playback.store, engine: playback.engineReading)
        GesturesProbe(store: playback.store, engine: playback.engineReading)
        #endif
    }
}

extension PlayerModel {
    /// The engine's loads and position, for the UI tests' probe.
    var engineReading: EngineReading { apple.mpv.debug.engineReading }
    #if os(iOS)
    /// Where mpv holds the subtitles, for the UI tests' probe.
    var subtitlePlacement: SubtitlePlacement { apple.mpv.debug.subtitlePlacement }
    #endif
    #if !os(macOS)
    /// The idle timer as the playback last read it back, for the UI tests' probe.
    var idleTimer: IdleTimerReading { apple.idleTimer }
    #endif
}

extension NowPlayingCenter {
    /// `title=…; state=…; rate=…; duration=…; live=…; album=…; artwork=…; next=…; previous=…; skip=…` from what the info
    /// center and the command center hold (`published`).
    static func describe(_ center: MPNowPlayingInfoCenter) -> String {
        guard let info = center.nowPlayingInfo else { return "" }
        let state = switch center.playbackState {
        case .playing: "playing"
        case .paused: "paused"
        case .stopped: "stopped"
        case .interrupted: "interrupted"
        default: "unknown"
        }
        let title = info[MPMediaItemPropertyTitle] as? String ?? ""
        let rate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0
        let duration = info[MPMediaItemPropertyPlaybackDuration] as? Double ?? 0
        let live = info[MPNowPlayingInfoPropertyIsLiveStream] as? Bool ?? false
        let album = info[MPMediaItemPropertyAlbumTitle] as? String ?? ""
        let artwork = info[MPMediaItemPropertyArtwork] != nil
        let commands = MPRemoteCommandCenter.shared()
        return "title=\(title); state=\(state); rate=\(rate); duration=\(Int(duration)); live=\(live); album=\(album); "
            + "artwork=\(artwork); next=\(commands.nextTrackCommand.isEnabled); previous=\(commands.previousTrackCommand.isEnabled); "
            + "skip=\(commands.skipForwardCommand.isEnabled); "
            + "skipInterval=\(commands.skipForwardCommand.preferredIntervals.first?.intValue ?? 0)"
    }
}

/// Debug builds: what the system's Now Playing holds (`NowPlayingCenter.published`), as the label and value of an
/// element the UI tests read (`player.nowPlaying`), since XCUITest can't read `MPNowPlayingInfoCenter`.
private struct NowPlayingProbe: View {
    let center: NowPlayingCenter

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: center.published))
            .accessibilityValue(center.published)
            .accessibilityIdentifier("player.nowPlaying")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Debug builds: the engine's loads, position, video track and audio output (`EngineReading`: `loads=<n> position=<s>
/// cacheStart=<s|none> video=<id|no> …`), as the label and value of an element the UI tests read (`player.engine`).
private struct EngineProbe: View {
    let reading: EngineReading

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: reading.summary))
            .accessibilityValue(reading.summary)
            .accessibilityIdentifier("player.engine")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

#if os(macOS)
/// Debug builds: the AVFoundation output's display layer clock (`DisplayClockReading`: `jumps=<n>`), as the label of an
/// element the UI tests read (`player.displayClock`).
private struct DisplayClockProbe: View {
    let reading: DisplayClockReading

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: "jumps=\(reading.jumps)"))
            .accessibilityIdentifier("player.displayClock")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}
#endif

/// Debug builds: the store's timeline as the UI tests read it with the controls down, which the product shows only on
/// the controls and, while an assistive technology runs, as the video's value (`player.video`): the position as the
/// video reads it (`player.playhead`: `TimelineState.positionLabel`) and in seconds (`player.livePosition`:
/// `position=12.3`), which a live playback without a rewind window shows nowhere, for the tests to see that no seek
/// moves it. Its own observation of the timeline, apart from the controls' and the video's.
private struct TimelineProbes: View {
    @State private var timeline: StoreObserver<TimelineState>

    init(store: PlayerStore) {
        _timeline = State(initialValue: StoreObserver(store.timeline))
    }

    var body: some View {
        let state = timeline.state
        let seconds = String(format: "position=%.1f", state.positionSeconds)
        VStack(spacing: 0) {
            probe(state.positionLabel, id: "player.playhead")
            probe(seconds, id: "player.livePosition")
        }
        .allowsHitTesting(false)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .task { await timeline.observe() }
    }

    private func probe(_ reading: String, id: String) -> some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: reading))
            .accessibilityValue(reading)
            .accessibilityIdentifier(id)
    }
}

/// Debug builds: what the player's state shows that the UI tests can't read off the screen (`player.state`, label and
/// value): `firstFrame=<bool>; playbackInfo=<visible|hidden|off>; zoom=<option value>; sleep=<banner|none>;
/// extend=<label|none>; osd=<text|none>; menu=<menu|none>; controls=<bool>`, the video's first frame (the black surface
/// turns transparent then), the playback info's card (out of the accessibility tree: it is the video's), the zoom option,
/// the sleep timer's banner and its extension, the message up, the store's open menu and whether the controls show; and
/// `lastOsd=<text|none>`, the last message shown, which a test reads after the message's second and a half has gone;
/// `episodes=<previous on|off>/<next on|off>|none`, the episode buttons' state (on tvOS an off one stays focusable, so
/// the tree can't tell).
private struct PlayerStateProbe: View {
    let state: PlayerUiState
    @State private var lastOsd: String?

    var body: some View {
        let zoom = state.menuOptions.first { $0.id == .zoom }?.value ?? "none"
        let playbackInfo = state.playbackInfo.map { $0.visible ? "visible" : "hidden" } ?? "off"
        let reading = "firstFrame=\(state.hasFirstFrame); playbackInfo=\(playbackInfo); zoom=\(zoom); "
            + "sleep=\(state.sleepTimer?.text ?? "none"); extend=\(state.sleepTimer?.extend ?? "none"); osd=\(state.osd ?? "none")"
            + "; menu=\(state.menu.map { "\($0)" } ?? "none"); controls=\(state.controlsVisible); lastOsd=\(lastOsd ?? "none")"
            + "; item=\(state.title) \(state.subtitle ?? "")"
            + "; episodes=\(state.episodes.map { "\($0.previous ? "on" : "off")/\($0.next ? "on" : "off")" } ?? "none")"
        Group {
            #if os(tvOS)
            // With what the focus system has focused (its accessibility identifier, else its class), for the remote's
            // tests: looked at twice a second, as no state of the app's changes with it.
            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                reader(reading + "; uiFocus=\(Self.focusedItem)")
            }
            #else
            reader(reading)
            #endif
        }
        .allowsHitTesting(false)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .onChange(of: state.osd, initial: true) { _, osd in if let osd { lastOsd = osd } }
    }

    private func reader(_ reading: String) -> some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: reading))
            .accessibilityValue(reading)
            .accessibilityIdentifier("player.state")
    }

    #if os(tvOS)
    private static var focusedItem: String {
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        guard let window = windows.first(where: \.isKeyWindow) ?? windows.first,
              let item = UIFocusSystem.focusSystem(for: window)?.focusedItem else { return "none" }
        if let id = (item as? UIAccessibilityIdentification)?.accessibilityIdentifier, !id.isEmpty { return id }
        return String(describing: type(of: item))
    }
    #endif
}

/// Debug builds: the playback info's card (`PlaybackInfoCard`), which VoiceOver passes by, as an element of its frame
/// (`player.infoCard`) whose label and value are `rows=<pt>; heading=<pt>; sections=<id>,…; cut=<label>,…`: its rows'
/// and headings' text size, the sections it shows, in order, and the rows whose data value is drawn cut short
/// (`PlaybackInfoCutProbe`; none, as it should be).
struct PlaybackInfoCardProbe: View {
    let reading: String

    var body: some View {
        Color.clear
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: reading))
            .accessibilityValue(reading)
            .accessibilityIdentifier("player.infoCard")
            .allowsHitTesting(false)
    }
}

/// Debug builds: the labels of the playback info's rows whose data value is drawn narrower than its text
/// (`PlaybackInfoCutProbe`), for the card's probe.
struct PlaybackInfoCutValues: PreferenceKey {
    static var defaultValue: [String] { [] }

    static func reduce(value: inout [String], nextValue: () -> [String]) {
        value += nextValue()
    }
}

/// Debug builds: behind a row's data value in the playback info, its `label` in `PlaybackInfoCutValues` when the value
/// as drawn is narrower than `value`'s whole text in `font`: cut short.
struct PlaybackInfoCutProbe: View {
    let label: String
    let value: String
    let font: Font

    var body: some View {
        GeometryReader { drawn in
            Text(value)
                .font(font)
                .lineLimit(1)
                .fixedSize()
                .hidden()
                .background {
                    GeometryReader { whole in
                        Color.clear.preference(key: PlaybackInfoCutValues.self, value: whole.size.width > drawn.size.width + 0.5 ? [label] : [])
                    }
                }
        }
        .accessibilityHidden(true)
    }
}

#if os(macOS)
/// Debug builds: what the simulated display went through (`SimulatedDisplayModes`: `switches=<n> restores=<n>
/// rate=<mHz>`), as the label of an element the UI tests read (`player.display`).
private struct DisplayModesProbe: View {
    let reading: SimulatedDisplayModes

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: reading.summary))
            .accessibilityIdentifier("player.display")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}
#endif

#if !os(macOS)
/// Debug builds: the app's idle timer as `ApplePlayback.keepDisplayAwake` read it back after its last call,
/// `idleTimerDisabled=<true|false>` (`none` before the first), for the UI tests' probe `player.keepAwake`
/// (`KeepAwakeProbe`): XCUITest can't read `UIApplication.isIdleTimerDisabled`. Each playback has its own
/// (`ApplePlayback.idleTimer`).
@MainActor
@Observable
final class IdleTimerReading {
    var summary = "none"
}

/// Debug builds: the app's idle timer as the playback last read it back (`IdleTimerReading`:
/// `idleTimerDisabled=<true|false>`), as the value of an element the UI tests read (`player.keepAwake`).
private struct KeepAwakeProbe: View {
    let reading: IdleTimerReading

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityValue(reading.summary)
            .accessibilityIdentifier("player.keepAwake")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
#endif

#if os(tvOS)
/// Debug builds: what the simulated display went through (`DisplaySwitchReading`: `writes=<n> clears=<n> switches=<n>
/// readyWhileSwitching=<n> rate=<mHz>`), as the value of an element the UI tests read (`player.display`).
private struct DisplaySwitchProbe: View {
    let reading: DisplaySwitchReading

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityValue(reading.summary)
            .accessibilityIdentifier("player.display")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}
#endif

#if os(iOS)
/// Debug builds: the software keyboard as the player sees it, as the value of an element the UI tests read
/// (`player.keyboard`): `keyboards=<n>; responders=<a>><b>…; last keyboard: <whose>`, how many keyboards UIKit has
/// announced since the player opened (it announces one before it has slid in, which XCUITest's keyboard query can
/// miss), the classes the app's first responder has gone through meanwhile (the last twelve; `none` while a menu shows)
/// and whether the last keyboard was this app's.
private struct KeyboardProbe: View {
    @State private var watch = KeyboardWatch()

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityValue(watch.summary)
            .accessibilityIdentifier("player.keyboard")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

/// Counts UIKit's keyboard announcements (a selector observer, which goes with the watch) and samples the first
/// responder five times a second (the timer stops once the watch has gone).
@MainActor
@Observable
private final class KeyboardWatch: NSObject {
    private(set) var summary = "keyboards=0; responders="
    @ObservationIgnored private var shown = 0
    @ObservationIgnored private var responders: [String] = []
    @ObservationIgnored private var lastKeyboard = "none"

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self else { return timer.invalidate() }
            MainActor.assumeIsolated { self.sample() }
        }
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        shown += 1
        sample()
        // Whose keyboard: this app's or another process's.
        let local = notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool
        lastKeyboard = local.map { $0 ? "this app's" : "another app's" } ?? "unknown"
        update()
    }

    private func sample() {
        let responder = FirstResponder.find().map { String(describing: type(of: $0)) } ?? "none"
        guard responders.last != responder else { return }
        responders.append(responder)
        if responders.count > 12 { responders.removeFirst() }
        update()
    }

    private func update() {
        summary = "keyboards=\(shown); responders=\(responders.joined(separator: ">")); last keyboard: \(lastKeyboard)"
    }
}

/// Debug builds: the Playback menu as UIKit holds it in the main menu (`AppCommands`), as the value of an element the
/// UI tests read (`player.playbackMenu`): `<title> (<shortcut>): enabled|disabled` per item, `; ` between them, the
/// shortcut `Space`, `←`, `→`, the key's letter or `none`; `no menu` before UIKit has built it. XCUITest reaches neither
/// iPadOS's menu bar nor the shortcuts listed while ⌘ is held. Read from the main menu system's root menu (UIKit's
/// `_rootMenu`) twice a second while the probe is up.
private struct PlaybackMenuProbe: View {
    @State private var watch = PlaybackMenuWatch()

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityValue(watch.summary)
            .accessibilityIdentifier("player.playbackMenu")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Reads the Playback menu twice a second (the timer stops once the watch has gone).
@MainActor
@Observable
private final class PlaybackMenuWatch {
    private(set) var summary = "no menu"

    init() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self else { return timer.invalidate() }
            MainActor.assumeIsolated { self.read() }
        }
    }

    private func read() {
        let next = Self.describe()
        if next != summary { summary = next }
    }

    private static func describe() -> String {
        let system = UIMenuSystem.main
        let rootMenu = NSSelectorFromString("_rootMenu")
        guard system.responds(to: rootMenu), let root = system.perform(rootMenu)?.takeUnretainedValue() as? UIMenu,
              let menu = find(T.shared.nav.menu.playback, in: root) else { return "no menu" }
        return items(of: menu).joined(separator: "; ")
    }

    private static func find(_ title: String, in menu: UIMenu) -> UIMenu? {
        if menu.title == title { return menu }
        return menu.children.lazy.compactMap { ($0 as? UIMenu).flatMap { find(title, in: $0) } }.first
    }

    /// The menu's items, those of its sections (SwiftUI's dividers) in turn.
    private static func items(of menu: UIMenu) -> [String] {
        menu.children.flatMap { child -> [String] in
            if let section = child as? UIMenu { return items(of: section) }
            guard let leaf = child as? UIMenuLeaf else { return [] }
            let state = leaf.attributes.contains(.disabled) ? "disabled" : "enabled"
            return ["\(leaf.title) (\(shortcut(child as? UIKeyCommand))): \(state)"]
        }
    }

    private static func shortcut(_ command: UIKeyCommand?) -> String {
        switch command?.input {
        case nil: "none"
        case " ": "Space"
        case UIKeyCommand.inputLeftArrow: "←"
        case UIKeyCommand.inputRightArrow: "→"
        case let input?: input.uppercased()
        }
    }
}

/// Debug builds: where mpv holds the subtitles (`SubtitlePlacement`: mpv's `sub-pos`, the frame it places them in and
/// the controls' lift), as the value of an element the UI tests read (`player.subtitlePosition`): mpv draws the
/// subtitles into the video, out of XCUITest's reach.
private struct SubtitlePlacementProbe: View {
    let placement: SubtitlePlacement

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityValue(placement.summary)
            .accessibilityIdentifier("player.subtitlePosition")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

/// Debug builds: the playback while the app was last in the background, as the store and the engine saw it, as the
/// value of an element the UI tests read (`player.background`): `from=<s> to=<s> away=<s> samples=<n> paused=<n>
/// video=<n> interruptions=<list>`, the engine's position when the app went and when it came back, the seconds between,
/// how many of the samples meanwhile (twice a second while the app runs; fewer once the system slows it) found it
/// paused and how many found mpv decoding the video (`EngineReading`'s `video=`), and the audio session's interruptions
/// (`began@<s>`, `ended@<s>`, seconds after it went); `none` before the app has been in the background. The video's own
/// value (its position) only refreshes once the app draws again, which XCUITest can read before it has.
private struct BackgroundPlaybackProbe: View {
    let store: PlayerStore
    let engine: EngineReading
    @State private var watch = BackgroundWatch()

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityValue(watch.summary)
            .accessibilityIdentifier("player.background")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .onAppear {
                watch.store = store
                watch.engine = engine
            }
    }
}

@MainActor
@Observable
private final class BackgroundWatch: NSObject {
    private(set) var summary = "none"
    @ObservationIgnored weak var store: PlayerStore?
    @ObservationIgnored weak var engine: EngineReading?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var went = Date()
    @ObservationIgnored private var from: Double?
    @ObservationIgnored private var to = 0.0
    @ObservationIgnored private var samples = 0
    @ObservationIgnored private var paused = 0
    @ObservationIgnored private var video = 0
    @ObservationIgnored private var interruptions: [String] = []

    override init() {
        super.init()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(background), name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(foreground), name: UIApplication.willEnterForegroundNotification, object: nil)
        center.addObserver(self, selector: #selector(interruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func background() {
        went = Date()
        from = nil
        samples = 0
        paused = 0
        video = 0
        interruptions = []
        sample()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sample() }
        }
    }

    @objc private func foreground() {
        sample()
        timer?.invalidate()
        timer = nil
        let start = from.map { String(format: "%.1f", $0) } ?? "?"
        let away = String(format: "%.1f", Date().timeIntervalSince(went))
        summary = "from=\(start) to=\(String(format: "%.1f", to)) away=\(away) samples=\(samples) paused=\(paused) video=\(video) interruptions=\(interruptions.joined(separator: ","))"
    }

    @objc private func interruption(_ notification: Notification) {
        let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
        let kind = raw.flatMap(AVAudioSession.InterruptionType.init(rawValue:)) == .began ? "began" : "ended"
        interruptions.append("\(kind)@\(String(format: "%.1f", Date().timeIntervalSince(went)))")
    }

    private func sample() {
        guard let store else { return }
        let state = store.state.value
        let position = store.timeline.value.positionSeconds
        if from == nil { from = position }
        to = position
        samples += 1
        if state.paused { paused += 1 }
        if engine?.summary.split(separator: " ").contains("video=no") == false { video += 1 }
    }
}

/// Debug builds: what the swipes and the holds did, as the value of an element the UI tests read (`player.gestures`):
/// `brightness=<b>; volume=<v>; slider=<yes|no>; level=<label|none>; holds=<n>; held=<text|none>; heldSpeed=<x|none>;
/// after=<x|none>; spinners=<n>`, the screen's brightness and the system's output volume now, whether the hidden volume
/// control has its slider in a window (`TouchLevels`), the last level a swipe showed (`PlayerUiState.level`'s label),
/// the holds so far, what showed while the last one was held (`PlayerUiState.heldSpeed`) and the engine's speed then
/// (the highest read), the engine's speed since it ended (`player.engine`'s `speed`), and the times the loading spinner
/// came up since the first hold began (`PlayerCentreLoading`). XCUITest does nothing while it holds a finger down
/// (`press(forDuration:)`), so it reads the hold here afterwards. Sampled ten times a second.
private struct GesturesProbe: View {
    let store: PlayerStore
    let engine: EngineReading
    @State private var watch = GesturesWatch()

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityValue(watch.summary)
            .accessibilityIdentifier("player.gestures")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onAppear {
                watch.store = store
                watch.engine = engine
            }
    }
}

@MainActor
@Observable
private final class GesturesWatch {
    private(set) var summary = "none"
    @ObservationIgnored weak var store: PlayerStore?
    @ObservationIgnored weak var engine: EngineReading?
    @ObservationIgnored private var level = "none"
    @ObservationIgnored private var holds = 0
    @ObservationIgnored private var holding = false
    @ObservationIgnored private var held = "none"
    @ObservationIgnored private var heldSpeed: Double?
    @ObservationIgnored private var after: Double?
    @ObservationIgnored private var spinning = false
    @ObservationIgnored private var spinners = 0

    init() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else { return timer.invalidate() }
            MainActor.assumeIsolated { self.sample() }
        }
    }

    private func sample() {
        guard let store else { return }
        let state = store.state.value
        let speed = engine?.summary.split(separator: " ").first { $0.hasPrefix("speed=") }.flatMap { Double($0.dropFirst(6)) }
        if let label = state.level?.label { level = label }
        if let shown = state.heldSpeed {
            if !holding {
                holding = true
                holds += 1
                heldSpeed = nil
                after = nil
            }
            held = shown
            if let speed { heldSpeed = max(heldSpeed ?? speed, speed) }
        } else {
            holding = false
            if holds > 0 { after = speed }
        }
        let spins = state.centre is PlayerCentreLoading
        if spins && !spinning && holds > 0 { spinners += 1 }
        spinning = spins
        let levels = TouchLevels.shared
        let slider = levels.volumeView.window != nil && levels.volumeSlider != nil
        let next = [
            "brightness=\(String(format: "%.2f", ApplePlatform.windowScreen?.brightness ?? -1))",
            "volume=\(String(format: "%.2f", AVAudioSession.sharedInstance().outputVolume))",
            "slider=\(slider ? "yes" : "no")",
            "level=\(level)",
            "holds=\(holds)",
            "held=\(held)",
            "heldSpeed=\(heldSpeed.map { String(format: "%.2f", $0) } ?? "none")",
            "after=\(after.map { String(format: "%.2f", $0) } ?? "none")",
            "spinners=\(spinners)",
        ].joined(separator: "; ")
        if next != summary { summary = next }
    }
}

/// The app's first responder, found by an action sent to whichever responder is first.
@MainActor
private enum FirstResponder {
    static var found: UIResponder?

    static func find() -> UIResponder? {
        found = nil
        _ = UIApplication.shared.sendAction(#selector(UIResponder.reportFirstResponder), to: nil, from: nil, for: nil)
        defer { found = nil }
        return found
    }
}

private extension UIResponder {
    @objc func reportFirstResponder() {
        FirstResponder.found = self
    }
}
#endif
