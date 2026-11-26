import SwiftUI
import UniformTypeIdentifiers
import PlezyKit

#if os(iOS)
import UIKit
#endif

/// The audio and subtitle menus, the chapters and the queue, and the options menu (`PlayerOptionsButton`), as one group
/// of the controls. On iOS and macOS the menus are the system's own (Liquid Glass menus on 26): the tracks with the
/// current one checked (the second subtitle's with its "2" badge, on the Mac its name; the server's audio tracks while
/// it transcodes), then, in the subtitle menu, Second subtitle, More subtitles and Search subtitles
/// (`NativeMenu.secondSubtitle`, `moreSubtitles`), then the delay entry, which opens the delay in a popover
/// (`DelayPopover`), and in the audio menu the audio settings after it (`PlayerUiState.audioOptions`, as the options
/// menu lists its options). The chapters and the queue open their lists in a sheet (`PlayerSheets`). The store hears
/// a menu open and close (`PlayerCommandOpenMenu`, `CloseMenu`), so the controls stay up under it. On tvOS the buttons
/// open their menu above them (`PlayerTVPanel`), in AVKit's order and with its symbols: the app's menu (options), then
/// Subtitles and Audio at the trailing end, each focusable as `PlayerFocus.menuButton` of its tab, where focus goes back
/// as its menu closes; the chapters and the queue are tabs of the panel across the bottom there. Each button there that
/// can take focus reports its frame under its tab (`PlayerMenuButtonFrames`): where its card opens, and whether focus
/// can go back to it. The subtitles' symbol is struck through while the subtitle shortcut hid them
/// (`PlayerUiState.subtitlesHidden`), the options' carries a dot while the picture is zoomed or a shader runs
/// (`PlayerUiState.settingsHighlighted`).
struct PlayerMenuBar: View {
    let playback: PlayerModel
    let state: PlayerUiState
    #if os(tvOS)
    let focus: FocusState<PlayerFocus?>.Binding
    #endif

    var body: some View {
        HStack(spacing: PlayerMetrics.menuSpacing) {
            #if os(tvOS)
            options.focused(focus, equals: .menuButton(.options)).reportsFrame(.options)
            subtitles.focused(focus, equals: .menuButton(.subtitles)).reportsFrame(.subtitles)
            audio.focused(focus, equals: .menuButton(.audio)).reportsFrame(.audio)
            #else
            audio
            subtitles
            if !state.chapters.isEmpty {
                sheetButton(.chapters, systemImage: "book.pages", label: T.shared.videoControls.chaptersButton, id: "player.chapters")
            }
            if !state.queue.isEmpty {
                sheetButton(.queue, systemImage: "play.square.stack", label: T.shared.videoControls.queue, id: "player.queue")
            }
            options
            #endif
        }
    }

    @ViewBuilder private var audio: some View {
        if state.showsAudioMenu {
            menuButton(
                .audio,
                systemImage: Self.audioSymbol,
                label: T.shared.player.menu.audio,
                value: PlayerMenuContent.audioTracks(state).first(where: \.selected)?.label,
                id: "player.audio"
            )
            #if os(macOS)
            .equatable()
            #endif
        }
    }

    @ViewBuilder private var subtitles: some View {
        if state.showsSubtitleMenu {
            menuButton(
                .subtitles,
                systemImage: "captions.bubble",
                label: T.shared.player.menu.subtitles,
                value: state.subtitleTracks.first(where: \.selected)?.label,
                id: "player.subtitles",
                struck: state.subtitlesHidden
            )
            #if os(macOS)
            .equatable()
            #endif
        }
    }

    private func menuButton(_ menu: PlayerMenu, systemImage: String, label: String, value: String?, id: String, struck: Bool = false) -> PlayerMenuButton {
        PlayerMenuButton(menu: menu, systemImage: systemImage, label: label, value: value, id: id, struck: struck, state: state, store: playback.store)
    }

    #if !os(tvOS)
    /// A button that opens its list in a sheet (`PlayerSheets`): the chapters, the queue.
    private func sheetButton(_ menu: PlayerMenu, systemImage: String, label: String, id: String) -> some View {
        PlayerIconButton(systemImage: systemImage, label: label, id: id, selected: state.menu == menu) {
            playback.store.dispatch(command: PlayerCommandOpenMenu(menu: menu))
        }
    }
    #endif

    private var options: some View {
        PlayerOptionsButton(state: state, store: playback.store)
            #if os(macOS)
            .equatable()
            #endif
    }

    /// AVKit's audio symbol on tvOS; elsewhere the audio track's note, as the other players draw it: not a speaker,
    /// which beside the Mac's mute button reads as a second volume control.
    #if os(tvOS)
    private static let audioSymbol = "waveform"
    #else
    private static let audioSymbol = "music.note"
    #endif
}

/// A menu's entries, from the store's state, under its title (`PlayerUiState.menuTitle`): the tracks (subtitles start
/// with Off; a subtitle row's hold shows or removes the second subtitle, `Entry.hold`; the server's audio tracks while
/// it transcodes, `PlayerUiState.sourceAudioTracks`), with More subtitles' count and Search subtitles in the subtitle
/// menu while there are subtitles to add or a search, and the delay entry (the audio menu's settings follow it, listed
/// apart: `NativeMenu.track`, the TV panel); More subtitles' languages, each with its count, opening its page, and a
/// language's subtitles, a pick of which adds it and selects it (Apple TV's pages; the system menus on iOS and the Mac
/// nest them, `NativeMenu.moreSubtitles`); or an option's choices (its page, `PlayerOption.choices`).
struct PlayerMenuContent {
    struct Entry {
        let label: String
        let detail: String?
        /// After the label, for an entry that opens more: a language's count of subtitles.
        var value: String?
        let selected: Bool
        /// The subtitle track showing as the second subtitle: it carries the "2" badge (`secondBadgeSymbol`).
        var second = false
        /// What a long press on the row does (a held Select on Apple TV; the system menus' Second subtitle submenu on
        /// iOS and the Mac, whose entries take none); nil for a row whose long press is a click (not a subtitle's).
        var hold: Hold?
        /// Off for a choice that can't be picked (a quality above the source's).
        var enabled = true
        /// What a pick sends to `store` (`perform`): the entry's identity beside what it shows (`NativeMenu.target`).
        let command: any PlayerCommand
        let store: PlayerStore

        func perform() {
            store.dispatch(command: command)
        }
    }

    /// A subtitle row's long-press action, named for VoiceOver; no name where it does nothing.
    struct Hold {
        let name: String?
        let perform: () -> Void
    }

    /// The second subtitle's badge: a filled rounded square with a 2, in the row's foreground colour.
    static let secondBadgeSymbol = "2.square.fill"

    let title: String
    let entries: [Entry]
    /// How many subtitles the subtitle menu's More subtitles offers after its tracks; nil while there are none.
    var more: String?
    /// The subtitle menu offers Search subtitles (`PlayerMenu.subtitleSearch`, Plex).
    var search = false
    /// The delay this menu offers after its entries (audio, subtitles), with its current value.
    var delay: DelayState?

    init(_ menu: PlayerMenu, state: PlayerUiState, store: PlayerStore) {
        title = state.menuTitle(menu: menu)
        switch menu {
        case .audio:
            entries = Self.tracks(Self.audioTracks(state), kind: .audio, source: !state.sourceAudioTracks.isEmpty, store: store)
            delay = state.audioDelay
        case .subtitles:
            entries = Self.tracks(state.subtitleTracks, kind: .subtitle, source: false, store: store)
            more = state.moreSubtitles.isEmpty ? nil : state.moreSubtitlesCount
            search = state.subtitleSearch != nil
            delay = state.subtitleDelay
        case .moreSubtitles:
            entries = state.moreSubtitles.map { language in
                Entry(
                    label: language.label,
                    detail: nil,
                    value: language.count,
                    selected: false,
                    command: PlayerCommandOpenSubtitleLanguage(key: language.key),
                    store: store
                )
            }
        case .subtitleLanguage:
            entries = Self.choices(state.subtitleLanguage?.subtitles ?? [], store: store)
        // An option's page; the options themselves, the delays, the version and quality, the file info, the subtitle
        // search, the chapters, the queue and the room panel list apart (`PlayerOptionsButton`, the delay popovers, the
        // TV panel, `PlayerSheets`).
        case .options, .speed, .customSpeed, .videoFit, .zoom, .shaders, .sleepTimer, .audioChannels, .audioOutput, .subtitleDelay,
             .audioDelay, .watchTogether, .tracks, .subtitleSearch, .versions, .fileInfo, .chapters, .queue, .contentStrip,
             .dolbyVisionConversion, .httpStatus:
            entries = state.openOption.map { Self.choices($0.choices, store: store) } ?? []
        }
    }

    /// The audio menu's tracks: the server's while it transcodes (or serves the file's audio) and has several, else the
    /// player's.
    static func audioTracks(_ state: PlayerUiState) -> [TrackItem] {
        state.sourceAudioTracks.isEmpty ? state.audioTracks : state.sourceAudioTracks
    }

    /// Choices as entries: an option's (its page), a language's subtitles to add, a version or a quality.
    static func choices(_ choices: [OptionChoice], store: PlayerStore) -> [Entry] {
        choices.map { choice in
            Entry(label: choice.label, detail: choice.detail, selected: choice.selected, enabled: choice.enabled, command: choice.command, store: store)
        }
    }

    /// Tracks as entries, a pick of which selects its track (`source`: the server's, which reopens the video). A
    /// subtitle row's hold toggles the second subtitle (`PlayerCommandToggleSecondSubtitle`): a track's other than the
    /// subtitle's shows it as the second, the second's own or Off's removes it; the subtitle's row's, and Off's without
    /// a second subtitle, does nothing.
    private static func tracks(_ tracks: [TrackItem], kind: TrackKind, source: Bool, store: PlayerStore) -> [Entry] {
        let hasSecond = tracks.contains(where: \.second)
        return tracks.map { track in
            var hold: Hold?
            if kind == .subtitle {
                let name: String? = if track.second || (track.id == nil && hasSecond) {
                    T.shared.player.track.removeSecond
                } else if track.id != nil && !track.selected {
                    T.shared.player.track.showAsSecond
                } else {
                    nil
                }
                hold = Hold(name: name) { store.dispatch(command: PlayerCommandToggleSecondSubtitle(id: track.id)) }
            }
            let command: any PlayerCommand = source
                ? PlayerCommandSelectSourceTrack(kind: kind, id: track.id.map { KotlinInt(int: $0.int32Value) })
                : PlayerCommandSelectTrack(kind: kind, id: track.id)
            return Entry(
                label: track.label,
                detail: track.detail,
                selected: track.selected,
                second: track.second,
                hold: hold,
                command: command,
                store: store
            )
        }
    }
}

extension PlayerMenu {
    /// The delay popover this menu's delay entry opens.
    var delayMenu: PlayerMenu? {
        switch self {
        case .audio: .audioDelay
        case .subtitles: .subtitleDelay
        case .speed, .customSpeed, .subtitleDelay, .audioDelay, .moreSubtitles, .subtitleLanguage, .options, .videoFit, .zoom,
             .shaders, .sleepTimer, .audioChannels, .audioOutput, .watchTogether, .tracks, .subtitleSearch, .versions,
             .fileInfo, .chapters, .queue, .contentStrip, .dolbyVisionConversion, .httpStatus:
            nil
        }
    }

    /// A menu drawn by the system (iOS, macOS; the options menu with its options' pages as submenus), as opposed to
    /// the delay and custom speed popovers and the sheets the player draws itself (`PlayerSheets`).
    var isNativeMenu: Bool {
        switch self {
        case .audioDelay, .subtitleDelay, .customSpeed, .watchTogether, .tracks, .subtitleSearch, .fileInfo, .chapters, .queue,
             .contentStrip:
            false
        case .audio, .subtitles, .speed, .moreSubtitles, .subtitleLanguage, .options, .videoFit, .zoom, .shaders,
             .sleepTimer, .audioChannels, .audioOutput, .versions, .dolbyVisionConversion, .httpStatus:
            true
        }
    }
}

extension PlayerOptionId {
    /// The option's symbol in the options menu.
    var systemImage: String {
        switch self {
        case .watchTogether: "person.2"
        case .videoFit: "aspectratio"
        case .zoom: "plus.magnifyingglass"
        case .shaders: "wand.and.stars"
        case .sleepTimer: "moon.zzz"
        case .autoPlayNext: "text.line.first.and.arrowtriangle.forward"
        case .audioOutput: "hifispeaker"
        case .audioNormalization: "waveform"
        case .audioChannels: "speaker.wave.3"
        case .speed: "gauge.with.dots.needle.67percent"
        case .versions: "slider.horizontal.3"
        case .hdr, .hdrToneMapping: "sun.max"
        case .audioRendering: "hifispeaker.2"
        case .ambientLighting: "lightspectrum.horizontal"
        case .playbackInfo: "chart.xyaxis.line"
        case .fileInfo: "info.circle"
        case .dolbyVisionConversion: "circle.lefthalf.filled"
        case .httpStatus: "ladybug"
        }
    }

    /// The option's accessibility identifier: `player.option.videoFit`.
    var identifier: String { "player.option.\((self as __PlayerOptionId).probeName)" }
}

extension PlayerUiState {
    /// The options as the options menu lists them: the store's, with the picture's fit (`videoFit`, the aspect choices)
    /// after the zoom.
    var menuOptions: [PlayerOption] {
        guard let videoFit else { return options }
        var list = options
        list.insert(videoFit, at: (list.firstIndex { $0.id == .zoom }).map { $0 + 1 } ?? 0)
        return list
    }
}

#if os(tvOS)
/// The global frame of each tvOS menu button that shows and can take focus, by the tab it opens (`PlayerMenuBar`).
struct PlayerMenuButtonFrames: PreferenceKey {
    static var defaultValue: [PlayerPanelTab: CGRect] { [:] }

    static func reduce(value: inout [PlayerPanelTab: CGRect], nextValue: () -> [PlayerPanelTab: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

private extension View {
    /// Reports this menu button's global frame under `tab` (`PlayerMenuButtonFrames`) while `focusable`.
    func reportsFrame(_ tab: PlayerPanelTab, when focusable: Bool = true) -> some View {
        background {
            if focusable {
                GeometryReader { proxy in
                    Color.clear.preference(key: PlayerMenuButtonFrames.self, value: [tab: proxy.frame(in: .global)])
                }
            }
        }
    }
}

/// A menu button on tvOS: opens this menu's card above it (`PlayerTVPanel`).
struct PlayerMenuButton: View {
    let menu: PlayerMenu
    let systemImage: String
    let label: String
    let value: String?
    let id: String
    var struck = false
    let state: PlayerUiState
    let store: PlayerStore

    var body: some View {
        PlayerIconButton(systemImage: systemImage, label: label, value: value, id: id, selected: state.menu?.parent == menu, struck: struck) {
            store.dispatch(command: PlayerCommandOpenMenu(menu: menu))
        }
    }
}

/// The options button on tvOS: opens the options menu above it, which lists the playback info and the options.
struct PlayerOptionsButton: View {
    let state: PlayerUiState
    let store: PlayerStore

    var body: some View {
        PlayerIconButton(
            systemImage: "ellipsis",
            label: T.shared.player.options.title,
            id: "player.more",
            selected: PlayerPanelTab(state) == .options,
            badged: state.settingsHighlighted
        ) {
            store.dispatch(command: PlayerCommandOpenMenu(menu: .options))
        }
    }
}
#else
/// A menu button on iOS and macOS: the system menu (see `PlayerMenuBar`), and the popover of its delay.
struct PlayerMenuButton: View {
    let menu: PlayerMenu
    let systemImage: String
    let label: String
    let value: String?
    let id: String
    var struck = false
    let state: PlayerUiState
    let store: PlayerStore

    var body: some View {
        menuButton(.track(menu, state: state, store: store))
            .overlay { if struck { StrikeMark() } }
            .delayPopover(menu.delayMenu, state: state, store: store)
    }

    #if os(iOS)
    private func menuButton(_ content: NativeMenu) -> some View {
        NativeMenuButton(menu: menu, systemImage: systemImage, label: label, value: value, id: id, content: content, store: store)
            .frame(width: PlayerMetrics.button, height: PlayerMetrics.button)
    }
    #else
    private func menuButton(_ content: NativeMenu) -> some View {
        Menu {
            NativeMenuEntries(entries: content.children ?? [], title: content.title)
        } label: {
            PlayerMenuIcon(systemImage: systemImage)
        }
        .playerMenuStyle(menu: menu, label: label, value: value, id: id)
    }
    #endif
}

private extension View {
    /// The popover of `delay` (`DelayPopover`) from this button while the store has it open.
    func delayPopover(_ delay: PlayerMenu?, state: PlayerUiState, store: PlayerStore) -> some View {
        let shown = delay.map { store.menuPresentation($0, shown: state.menu == $0) } ?? .constant(false)
        return statePresentation(shown) { base, shown in
            base.popover(isPresented: shown, arrowEdge: .top) {
                if let delay {
                    DelayPopover(delay: delay == .subtitleDelay ? state.subtitleDelay : state.audioDelay, store: store)
                        .playerPopover()
                }
            }
        }
    }

    /// The custom speed's popover (`SpeedPopover`) from this button while the store has it open.
    func speedPopover(state: PlayerUiState, store: PlayerStore) -> some View {
        statePresentation(store.menuPresentation(.customSpeed, shown: state.menu == .customSpeed)) { base, shown in
            base.popover(isPresented: shown, arrowEdge: .top) {
                SpeedPopover(speed: state.customSpeed, store: store)
                    .playerPopover()
            }
        }
    }

    /// A popover over the video (a delay, the custom speed): a popover on an iPhone too, on a blurred ground dimmed by
    /// 60 % black (darker over an HDR picture, `ControlsScrim`), as the player's other text over video: the system's
    /// glass took the video's colour, and its white text sat on pink over a red or magenta frame.
    func playerPopover() -> some View {
        presentationCompactAdaptation(.popover)
            .presentationBackground { PopoverGround() }
    }
}

/// The ground of the player's popovers (`playerPopover`).
private struct PopoverGround: View {
    @Environment(\.hdrPicture) private var hdr

    var body: some View {
        Color.black.opacity(Double(ControlsScrim.shared.alpha(alpha: 0.6, hdr: hdr)))
            .background(.ultraThinMaterial)
    }
}

/// The subtitles' strike through their symbol while the subtitle shortcut hid them, over the system's menu button.
private struct StrikeMark: View {
    var body: some View {
        Capsule()
            .frame(width: 2, height: PlayerMetrics.icon * 1.3)
            .rotationEffect(.degrees(-45))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The dot by the options' symbol while the picture is zoomed or a shader runs, over the system's menu button.
private struct BadgeDot: View {
    var body: some View {
        Circle()
            .frame(width: 6, height: 6)
            .offset(x: PlayerMetrics.icon * 0.55, y: -PlayerMetrics.icon * 0.45)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

extension PlayerStore {
    /// A presentation of one of the store's menus (a delay's popover, a sheet): it shows while `shown` holds, and its
    /// dismissal closes the menu if it is still the store's.
    @MainActor
    func menuPresentation(_ menu: PlayerMenu, shown: Bool) -> Binding<Bool> {
        Binding(
            get: { shown },
            set: { shown in
                if !shown, self.state.value.menu == menu { self.dispatch(command: PlayerCommandCloseMenu.shared) }
            }
        )
    }
}

/// The options button on iOS and macOS (`player.more`): a system menu (`NativeMenu.options`) with the playback info,
/// which shows or hides it (the sheet on iOS, the panel on the Mac), on a touch screen the screen and rotation locks,
/// and the player's options (`PlayerUiState.menuOptions`): an option with a page as a submenu with its value, its
/// choices checked; a switch as a checked entry; the sync offsets, the file info and the watch-together room as entries
/// that open their popover or sheet once the menu has gone. The store hears it open and close as `PlayerMenu.OPTIONS`,
/// so the controls stay up under it; a pick closes it. A delay opened from here while its track menu's button doesn't
/// show (no subtitles to pick) pops over this button, as the custom speed does (the Speed submenu's Custom).
struct PlayerOptionsButton: View {
    let state: PlayerUiState
    let store: PlayerStore
    @Environment(\.shaderPrompts) private var shaderPrompts

    var body: some View {
        button
            .overlay { if state.settingsHighlighted { BadgeDot() } }
            .delayPopover(orphanDelay, state: state, store: store)
            .speedPopover(state: state, store: store)
    }

    /// The delay open while its track menu's button doesn't show, which this button then shows.
    private var orphanDelay: PlayerMenu? {
        switch state.menu {
        case .audioDelay where !state.showsAudioMenu: .audioDelay
        case .subtitleDelay where !state.showsSubtitleMenu: .subtitleDelay
        default: nil
        }
    }

    #if os(iOS)
    private var button: some View {
        NativeMenuButton(
            menu: .options,
            systemImage: "ellipsis",
            label: T.shared.player.options.title,
            value: nil,
            id: "player.more",
            content: .options(state, store: store, shaders: shaderPrompts),
            store: store
        )
        .frame(width: PlayerMetrics.button, height: PlayerMetrics.button)
    }
    #else
    private var button: some View {
        Menu {
            NativeMenuEntries(entries: NativeMenu.options(PlayerMenuTracking.opened ?? state, store: store, shaders: shaderPrompts).children ?? [])
        } label: {
            PlayerMenuIcon(systemImage: "ellipsis.circle")
        }
        .playerMenuStyle(menu: .options, label: T.shared.player.options.title, value: nil, id: "player.more")
    }
    #endif
}

/// What the Shaders submenu's own entries open once the menu has gone: Import shader the open dialog, an imported
/// shader's Delete the question before it goes (a system menu's entries take no trailing button or swipe). The player
/// shows them (`ShaderPromptsPresenter`), not the options button: the controls, the button with them, hide on their
/// timer while the video plays, and a presentation goes with the view that shows it.
@Observable
final class ShaderPrompts {
    var importing = false
    var deleting: OptionChoice?
}

extension EnvironmentValues {
    /// The player's shader prompts, for its options button (`PlayerScreen`).
    @Entry var shaderPrompts: ShaderPrompts?
}

/// Shows `prompts` over the player and hands them to the options button in it: the open dialog, whose pick imports
/// the shader, and the question before an imported shader's deletion.
struct ShaderPromptsPresenter: ViewModifier {
    @Bindable var prompts: ShaderPrompts
    let store: PlayerStore

    func body(content: Content) -> some View {
        content
            .environment(\.shaderPrompts, prompts)
            // A `.glsl` file; any file where the system knows no such type, its extension checked once picked.
            .fileImporter(isPresented: $prompts.importing, allowedContentTypes: [UTType(filenameExtension: "glsl") ?? .data]) { result in
                if case .success(let url) = result { Task { await importShader(url) } }
            }
            .confirmation(
                prompts.deleting.map {
                    Confirmation(
                        title: T.shared.player.options.shader.deleteTitle(name: $0.label), message: "",
                        confirmLabel: T.shared.player.options.shader.delete, cancelLabel: T.shared.player.options.shader.cancel,
                        confirmId: "player.shader.delete.confirm", cancelId: "player.shader.delete.cancel"
                    )
                },
                onConfirm: {
                    if let delete = prompts.deleting?.delete { store.dispatch(command: delete) }
                    prompts.deleting = nil
                },
                onCancel: { prompts.deleting = nil }
            )
    }

    /// Reads the picked file (`importedText`) and sends its name and text (`PlayerCommandImportShader`); a file that
    /// can't be read, is too large or isn't UTF-8 fails the import (`PlayerCommandShaderImportFailed`).
    private func importShader(_ url: URL) async {
        let text = await importedText(url)
        if let text {
            store.dispatch(command: PlayerCommandImportShader(fileName: url.lastPathComponent, source: text))
        } else {
            store.dispatch(command: PlayerCommandShaderImportFailed.shared)
        }
    }
}

/// A system menu or one of its entries, built once from the store's state for iOS (`NativeMenuButton`, a `UIMenu`) and
/// the Mac (`NativeMenuEntries`, a SwiftUI `Menu`): an action, checked or not where it can be, or a submenu of more,
/// which `inline` makes a group of its menu's entries under its title. What an entry opens (a popover, a sheet, the
/// playback info) waits until the menu has gone (`afterClose`).
private struct NativeMenu {
    var title = ""
    var subtitle: String?
    var systemImage: String?
    /// The symbol's accessible name, for one that says something of its own (the second subtitle's badge); the Mac
    /// shows the name in the entry's second line instead of the symbol (`NativeMenuEntries`).
    var imageLabel: String?
    /// Whether the entry is checked, for one that can be; nil for one that can't.
    var checked: Bool?
    /// Off for an entry that can't be picked (a quality above the source's, a page's "nothing here" line).
    var enabled = true
    /// The entry's accessibility identifier on the Mac (UIKit's menu entries take none).
    var identifier = ""
    /// A submenu's entries; nil for an action.
    var children: [NativeMenu]?
    var inline = false
    /// One of the submenu's entries is checked at a time.
    var singleSelection = false
    var action: (() -> Void)?
    /// The command the entry's pick sends, where it sends one: entries that show the same can act apart (More
    /// subtitles' subtitles of the next episode, labelled as the last one's), so it is part of `signature`.
    var target: (any PlayerCommand)?
    var afterClose: (() -> Void)?
    /// The entry's text counts down while the menu is open (the sleep timer's time left): it doesn't count as a change
    /// (`signature`), which would build the menu again every second and close a submenu open under the pointer, and
    /// shows the time as the menu opened.
    var live = false

    /// What the menu shows and what its entries act on, to tell when it changed: iOS builds its menu again only then.
    /// Kotlin's commands compare as their `equals`, a data class's by its values; a `live` entry's text not at all.
    var signature: [AnyHashable] {
        let text = live ? "live" : "\(title)|\(subtitle ?? "")"
        let entry: [AnyHashable] = [
            "\(identifier)|\(text)|\(systemImage ?? "")|\(checked?.description ?? "-")|\(enabled)",
            AnyHashable(target.map { $0 as AnyObject as! NSObject }),
        ]
        guard let children else { return entry }
        return entry + ["["] + children.flatMap(\.signature) + ["]"]
    }

    /// A track menu (`PlayerMenuContent`): its entries, the current one checked, then the subtitle menu's Second
    /// subtitle (`secondSubtitle`), More subtitles (`moreSubtitles`) and Search subtitles, which opens the search's sheet,
    /// and the delay entry, which opens the delay's popover; then the audio menu's settings (`option`).
    static func track(_ menu: PlayerMenu, state: PlayerUiState, store: PlayerStore) -> NativeMenu {
        let content = PlayerMenuContent(menu, state: state, store: store)
        var more = [NativeMenu]()
        if menu == .subtitles, let second = secondSubtitle(content.entries) {
            more.append(second)
        }
        if let count = content.more {
            more.append(moreSubtitles(state.moreSubtitles, count: count, store: store))
        }
        if content.search {
            more.append(NativeMenu(
                title: InterfaceLocale.shared.menuTitle(text: T.shared.videoControls.searchSubtitles),
                systemImage: "magnifyingglass",
                identifier: "player.menu.search",
                afterClose: { store.dispatch(command: PlayerCommandOpenMenu(menu: .subtitleSearch)) }
            ))
        }
        if let delay = content.delay {
            more.append(delayEntry(delay, store: store))
        }
        if menu == .audio {
            more += state.audioOptions.map { option(option: $0, state: state, store: store, shaders: nil) }
        }
        var groups = [NativeMenu(children: choices(content.entries), inline: true, singleSelection: true)]
        if !more.isEmpty { groups.append(NativeMenu(children: more, inline: true)) }
        return NativeMenu(title: InterfaceLocale.shared.menuTitle(text: content.title), children: groups)
    }

    /// A delay's entry, its value under its name, opening its popover once the menu has gone.
    private static func delayEntry(_ delay: DelayState, store: PlayerStore) -> NativeMenu {
        NativeMenu(
            title: InterfaceLocale.shared.menuTitle(text: delay.title),
            subtitle: delay.label,
            systemImage: "timer",
            identifier: "player.menu.delay",
            afterClose: { store.dispatch(command: PlayerCommandOpenMenu(menu: delay.menu)) }
        )
    }

    /// Second subtitle, with its track (or Off) under its name: the subtitle rows' hold (`PlayerMenuContent.Entry.hold`)
    /// as a submenu, since a system menu's entries take no long press or right-click. It lists Off and every track but
    /// the subtitle's, the second's checked; a pick of another shows it as the second subtitle (Off removes it) and
    /// closes the menu. Nil while there is no track for it.
    private static func secondSubtitle(_ entries: [PlayerMenuContent.Entry]) -> NativeMenu? {
        guard let off = entries.first else { return nil }
        let tracks = entries.dropFirst().filter { $0.hold?.name != nil }
        guard !tracks.isEmpty else { return nil }
        let current = tracks.first(where: \.second)
        let items = ([off] + tracks).enumerated().map { index, entry in
            let checked = index == 0 ? current == nil : entry.second
            return NativeMenu(
                title: entry.label,
                subtitle: entry.detail,
                checked: checked,
                identifier: "player.menu.second.item.\(index)",
                action: checked ? nil : entry.hold?.perform,
                target: entry.command
            )
        }
        return NativeMenu(
            title: InterfaceLocale.shared.menuTitle(text: T.shared.player.track.second),
            subtitle: (current ?? off).label,
            systemImage: "captions.bubble",
            identifier: "player.menu.second",
            children: [NativeMenu(children: items, inline: true, singleSelection: true)]
        )
    }

    /// More subtitles (`PlayerUiState.moreSubtitles`) with their `count`: a submenu of their languages, each with its
    /// count, each a submenu of its subtitles, a pick of which adds it, selects it and closes the menu.
    private static func moreSubtitles(_ languages: [SubtitleLanguage], count: String, store: PlayerStore) -> NativeMenu {
        let pages = languages.enumerated().map { index, language in
            NativeMenu(
                title: language.label,
                subtitle: language.count,
                identifier: "player.menu.more.\(index)",
                children: choices(PlayerMenuContent.choices(language.subtitles, store: store))
            )
        }
        return NativeMenu(
            title: InterfaceLocale.shared.menuTitle(text: T.shared.player.menu.moreSubtitles),
            subtitle: count,
            systemImage: "plus.bubble",
            identifier: "player.menu.more",
            children: pages
        )
    }

    /// The options menu, with no title over it (the button's ellipsis says what it is, and the menu keeps the room): on a
    /// touch screen Lock screen (`PlayerUiState.lockLabel`), which locks it once the menu has gone, and the rotation lock
    /// (`PlayerUiState.rotationLocked`); then the options (`option`), the playback info's switch among them.
    static func options(_ state: PlayerUiState, store: PlayerStore, shaders: ShaderPrompts? = nil) -> NativeMenu {
        var first = [NativeMenu]()
        if let lockLabel = state.lockLabel {
            first.append(NativeMenu(
                title: InterfaceLocale.shared.menuTitle(text: lockLabel),
                systemImage: "lock.fill",
                identifier: "player.more.lock",
                afterClose: { store.dispatch(command: PlayerCommandLockScreen.shared) }
            ))
        }
        if let locked = state.rotationLocked?.boolValue {
            first.append(NativeMenu(
                title: InterfaceLocale.shared.menuTitle(text: locked ? T.shared.videoControls.unlockRotation : T.shared.videoControls.lockRotation),
                systemImage: locked ? "lock.rotation" : "rotate.right",
                identifier: "player.rotationLock",
                action: { store.dispatch(command: PlayerCommandToggleRotationLock.shared) }
            ))
        }
        let options = state.menuOptions.map { option(option: $0, state: state, store: store, shaders: shaders) }
        let groups = first.isEmpty ? [options] : [first, options]
        return NativeMenu(children: groups.map { NativeMenu(children: $0, inline: true) })
    }

    /// One option: a switch as an entry checked while it is on (its detail line under it; a dimmed one, unchecked, says
    /// why it is off for this video, "Not HDR", as Apple TV's panel does); a row to read (how the system renders the
    /// audio) as an entry that does nothing; the version and quality and the sleep timer as their submenus; the sync
    /// offsets, the file info and the watch-together room as entries opening their popover or sheet; else a submenu of
    /// its choices with its value under its name (the shaders' with their Delete and Import entries, a page with no
    /// choices saying so).
    private static func option(option: PlayerOption, state: PlayerUiState, store: PlayerStore, shaders: ShaderPrompts?) -> NativeMenu {
        let base = NativeMenu(title: InterfaceLocale.shared.menuTitle(text: option.label), subtitle: option.value.isEmpty ? nil : option.value, systemImage: option.id.systemImage, identifier: option.id.identifier)
        if let on = option.on, let toggle = option.toggle {
            var entry = base
            entry.subtitle = option.detail
            // A switch that can't act on this video shows no state, which would read as on for it.
            entry.checked = option.enabled ? on.boolValue : nil
            entry.enabled = option.enabled
            #if os(macOS)
            // The Mac's menus draw no symbol, and no second line beside one: the reason shows as the entry's second line.
            if !option.enabled { entry.systemImage = nil }
            #endif
            entry.action = { store.dispatch(command: toggle) }
            entry.target = toggle
            return entry
        }
        guard let page = option.page else { return base }
        switch page {
        case .versions:
            if let versions = state.versions { return versionsMenu(base, versions: versions, store: store) }
        case .sleepTimer:
            return sleepTimerMenu(base, option: option, banner: state.sleepTimer, store: store)
        case .audioDelay, .subtitleDelay, .fileInfo, .watchTogether:
            var entry = base
            entry.afterClose = { store.dispatch(command: PlayerCommandOpenMenu(menu: page)) }
            return entry
        default:
            break
        }
        var menu = base
        let picks = choices(PlayerMenuContent.choices(option.choices, store: store))
        let more = shaderEntries(option, prompts: shaders)
        if picks.isEmpty, let empty = option.empty {
            menu.children = [NativeMenu(title: empty, enabled: false)]
        } else if more.isEmpty {
            menu.children = picks
            menu.singleSelection = true
        } else {
            menu.children = [NativeMenu(children: picks, inline: true, singleSelection: true), NativeMenu(children: more, inline: true)]
        }
        return menu
    }

    /// Version and quality: the versions (with more than one) and the qualities, each a group under its name (the
    /// qualities alone untitled: the submenu's own title names them), the one playing checked, a quality above the
    /// source's off; a pick reopens the video at the position.
    private static func versionsMenu(_ base: NativeMenu, versions: VersionsMenu, store: PlayerStore) -> NativeMenu {
        var groups = [NativeMenu]()
        if versions.showsVersions {
            groups.append(NativeMenu(
                title: T.shared.videoControls.versionColumnHeader,
                children: choices(PlayerMenuContent.choices(versions.versions, store: store)),
                inline: true,
                singleSelection: true
            ))
        }
        if !versions.qualities.isEmpty {
            groups.append(NativeMenu(
                title: versions.showsVersions ? T.shared.videoControls.qualityColumnHeader : "",
                children: choices(PlayerMenuContent.choices(versions.qualities, store: store), offset: versions.showsVersions ? versions.versions.count : 0),
                inline: true,
                singleSelection: true
            ))
        }
        var menu = base
        menu.children = groups
        return menu
    }

    /// The sleep timer: while one runs its banner ("Playback will pause in 12:30") over "+15 min" while it counts down,
    /// then Stop at (Off, the end of the video), untitled under the submenu's own title, and the durations under theirs.
    private static func sleepTimerMenu(_ base: NativeMenu, option: PlayerOption, banner: SleepTimerBanner?, store: PlayerStore) -> NativeMenu {
        let entries = PlayerMenuContent.choices(option.choices, store: store)
        let stopAt = entries.filter { !($0.command is PlayerCommandSetSleepTimer) }
        let durations = entries.filter { $0.command is PlayerCommandSetSleepTimer }
        var groups = [NativeMenu]()
        if let banner {
            var active = [NativeMenu]()
            if let extend = banner.extend {
                active.append(NativeMenu(
                    title: extend,
                    systemImage: "plus",
                    identifier: "player.sleep.extend",
                    action: { store.dispatch(command: PlayerCommandExtendSleepTimer.shared) }
                ))
            }
            let heading = active.isEmpty ? [NativeMenu(title: banner.text, enabled: false, live: true)] : active
            groups.append(NativeMenu(title: banner.text, children: heading, inline: true, live: true))
        }
        groups.append(NativeMenu(children: choices(stopAt), inline: true, singleSelection: true))
        groups.append(NativeMenu(
            title: T.shared.videoControls.sleepTimerDurationHeader,
            children: choices(durations, offset: stopAt.count),
            inline: true,
            singleSelection: true
        ))
        var menu = base
        // Its value counts down while a timer runs ("0:25 left").
        menu.live = banner != nil
        menu.children = groups
        return menu
    }

    /// The Shaders submenu's entries after its choices: Delete <name> for each imported shader (`OptionChoice.delete`),
    /// which asks to confirm, and Import shader (`PlayerOption.importLabel`), which opens the open dialog.
    private static func shaderEntries(_ option: PlayerOption, prompts: ShaderPrompts?) -> [NativeMenu] {
        var entries = option.choices.enumerated().compactMap { index, choice -> NativeMenu? in
            guard choice.delete != nil else { return nil }
            return NativeMenu(
                title: T.shared.player.options.shader.deleteLabel(name: choice.label),
                systemImage: "trash",
                identifier: "player.shaders.delete.\(index)",
                target: choice.delete,
                afterClose: { prompts?.deleting = choice }
            )
        }
        if let importLabel = option.importLabel {
            entries.append(NativeMenu(
                title: importLabel,
                systemImage: "square.and.arrow.down",
                identifier: "player.shaders.import",
                afterClose: { prompts?.importing = true }
            ))
        }
        return entries
    }

    /// Entries as actions, the selected one checked, each with its detail line (`player.menu.item.<i>`, from `offset`
    /// on), the second subtitle's with its badge, one that can't be picked off. An entry that opens a page (the speeds'
    /// Custom) opens it once the menu has gone.
    private static func choices(_ entries: [PlayerMenuContent.Entry], offset: Int = 0) -> [NativeMenu] {
        entries.enumerated().map { index, entry in
            let opens = entry.command is PlayerCommandOpenMenu
            return NativeMenu(
                // The speeds' Custom asks for more before it acts: its entry ends in an ellipsis.
                title: opens && entry.label == T.shared.player.speed.custom ? T.shared.player.speed.customMore : entry.label,
                subtitle: entry.detail,
                systemImage: entry.second ? PlayerMenuContent.secondBadgeSymbol : nil,
                imageLabel: entry.second ? T.shared.player.track.second : nil,
                checked: entry.selected,
                enabled: entry.enabled,
                identifier: "player.menu.item.\(offset + index)",
                action: opens ? nil : entry.perform,
                target: entry.command,
                afterClose: opens ? entry.perform : nil
            )
        }
    }
}

#if os(macOS)
/// The Mac's menus are built again only when what they show changes (`PlayerMenuBar` compares them): each build hands
/// AppKit new submenus, so while the video played, the position's updates closed an open submenu (an option's, More
/// subtitles' or a language's) under the pointer and dropped a pick in it. SwiftUI compares views on the main actor,
/// where the button's state lives.
extension PlayerOptionsButton: @preconcurrency Equatable {
    static func == (lhs: PlayerOptionsButton, rhs: PlayerOptionsButton) -> Bool {
        lhs.store === rhs.store
            && lhs.state.settingsHighlighted == rhs.state.settingsHighlighted
            && (lhs.state.menu == .audioDelay || lhs.state.menu == .subtitleDelay) == (rhs.state.menu == .audioDelay || rhs.state.menu == .subtitleDelay)
            && (lhs.state.menu == .customSpeed) == (rhs.state.menu == .customSpeed)
            && lhs.state.customSpeed == rhs.state.customSpeed
            && NativeMenu.sameOptions(lhs.state, rhs.state)
    }
}

/// A track menu's button also shows its value and the popover of its delay (whose value the menu's delay entry
/// carries).
extension PlayerMenuButton: @preconcurrency Equatable {
    static func == (lhs: PlayerMenuButton, rhs: PlayerMenuButton) -> Bool {
        lhs.store === rhs.store
            && lhs.menu == rhs.menu && lhs.value == rhs.value && lhs.struck == rhs.struck
            && (lhs.state.menu == lhs.menu.delayMenu) == (rhs.state.menu == rhs.menu.delayMenu)
            && NativeMenu.sameTrack(lhs.menu, lhs.state, rhs.state)
    }
}

private extension NativeMenu {
    /// `options` builds the same menu from both states: it reads only these. While a sleep timer runs, its option's
    /// value and the banner's text count down, which doesn't count (`live`).
    static func sameOptions(_ lhs: PlayerUiState, _ rhs: PlayerUiState) -> Bool {
        let timing = lhs.sleepTimer != nil
        return lhs.lockLabel == rhs.lockLabel
            && lhs.rotationLocked == rhs.rotationLocked
            && lhs.versions == rhs.versions
            && timing == (rhs.sleepTimer != nil)
            && lhs.sleepTimer?.extend == rhs.sleepTimer?.extend
            && sameOptions(lhs.menuOptions, rhs.menuOptions, timing: timing)
    }

    static func sameOptions(_ lhs: [PlayerOption], _ rhs: [PlayerOption], timing: Bool) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { left, right in
            left == right
                || timing && left.page == .sleepTimer && right.page == .sleepTimer
                && left.id == right.id && left.label == right.label && left.choices == right.choices
        }
    }

    /// `track` builds the same menu for `menu` (audio or subtitles) from both states: it reads only these.
    static func sameTrack(_ menu: PlayerMenu, _ lhs: PlayerUiState, _ rhs: PlayerUiState) -> Bool {
        if menu == .audio {
            return lhs.audioTracks == rhs.audioTracks
                && lhs.sourceAudioTracks == rhs.sourceAudioTracks
                && lhs.audioDelay == rhs.audioDelay
                && lhs.audioOptions == rhs.audioOptions
        }
        return lhs.subtitleTracks == rhs.subtitleTracks
            && lhs.moreSubtitles == rhs.moreSubtitles
            && (lhs.subtitleSearch == nil) == (rhs.subtitleSearch == nil)
            && lhs.subtitleDelay == rhs.subtitleDelay
    }
}

/// A menu button's symbol on the Mac, as the player's other buttons draw theirs (`PlayerIconButton`).
private struct PlayerMenuIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: PlayerMetrics.icon, weight: .semibold))
            .frame(width: PlayerMetrics.button, height: PlayerMetrics.button)
            .contentShape(Rectangle())
    }
}

private extension View {
    /// A menu button of the Mac's controls: a bare symbol without the menu's indicator, `label` its tooltip; the pointer
    /// over it tells `PlayerScreen` which menu AppKit then tracks (`PlayerMenuTracking`).
    func playerMenuStyle(menu: PlayerMenu, label: String, value: String?, id: String) -> some View {
        menuStyle(.button)
            .buttonStyle(PlayerPressStyle())
            .menuIndicator(.hidden)
            .fixedSize()
            .onHover { if $0 { PlayerMenuTracking.hovered = menu } }
            .tooltip(label)
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityIdentifier(id)
    }
}

/// A system menu's entries as SwiftUI's (`NativeMenu`): a group set apart from the entries before it, under its title,
/// the menu's own title over its first group (a SwiftUI menu shows none of its own). What an entry opens waits a
/// moment, until AppKit's menu has closed, whose end closes the store's menu first (`PlayerScreen`).
private struct NativeMenuEntries: View {
    let entries: [NativeMenu]
    /// The menu's title, over its first group.
    var title = ""

    var body: some View {
        ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
            if let children = entry.children, entry.inline {
                if index > 0 { Divider() }
                let heading = index == 0 && entry.title.isEmpty ? title : entry.title
                if heading.isEmpty {
                    NativeMenuEntries(entries: children)
                } else {
                    Section(heading) { NativeMenuEntries(entries: children) }
                }
            } else if let children = entry.children {
                Menu { NativeMenuEntries(entries: children) } label: { label(entry) }
                    .accessibilityIdentifier(entry.identifier)
            } else if let checked = entry.checked {
                Toggle(isOn: Binding(get: { checked }, set: { _ in run(entry) })) { label(entry) }
                    .disabled(!entry.enabled)
                    .accessibilityIdentifier(entry.identifier)
            } else {
                Button { run(entry) } label: { label(entry) }
                    .disabled(!entry.enabled)
                    .accessibilityIdentifier(entry.identifier)
            }
        }
    }

    /// The entry's title and second line, after its symbol where it has one. A badge (the second subtitle's) shows as its
    /// name leading the second line: these menus draw no symbol of an entry, beside it or in its text, and no second
    /// line beside a symbol.
    @ViewBuilder
    private func label(_ entry: NativeMenu) -> some View {
        if let badge = entry.imageLabel {
            Text(entry.title)
            Text(([badge] + [entry.subtitle].compactMap { $0 }).joined(separator: T.shared.detail.listSeparator))
        } else if let systemImage = entry.systemImage {
            Label { text(entry) } icon: { Image(systemName: systemImage) }
        } else {
            text(entry)
        }
    }

    @ViewBuilder
    private func text(_ entry: NativeMenu) -> some View {
        Text(entry.title)
        if let subtitle = entry.subtitle { Text(subtitle) }
    }

    private func run(_ entry: NativeMenu) {
        entry.action?()
        if let afterClose = entry.afterClose {
            let box = UncheckedBox(afterClose)
            DispatchQueue.main.async { box.value() }
        }
    }
}
#endif

/// A delay (subtitles or audio, `player.delay`): − value + as the player's glass circle buttons (disabled at the ends of
/// the range; VoiceOver names them by the way they move the delay, "Audio delay: earlier"), a step of the store's each
/// and, held as long as a long press, a second at once and every 200 ms until let go (`PlayerIconButton.repeating`),
/// over a slider of ±`DelayState.limitSeconds` in `DelayState.stepSeconds` (10 ms audio, 50 ms subtitles) that sets the
/// delay where it is let go, and Reset.
private struct DelayPopover: View {
    let delay: DelayState
    let store: PlayerStore
    /// Where the slider is while dragged; let go, the store's delay again.
    @State private var dragging: Double?

    var body: some View {
        VStack(spacing: 14) {
            Text(InterfaceLocale.shared.menuTitle(text: delay.title))
                .font(.headline)
            HStack(spacing: 16) {
                step("minus", label: delay.decreaseLabel, id: "player.delay.decrease", command: delay.decrease, held: -1)
                    .disabled(!delay.canDecrease)
                Text(delay.label)
                    .font(.title3.monospacedDigit())
                    .frame(minWidth: 88)
                    .accessibilityIdentifier("player.delay")
                step("plus", label: delay.increaseLabel, id: "player.delay.increase", command: delay.increase, held: 1)
                    .disabled(!delay.canIncrease)
            }
            Slider(
                value: Binding(
                    get: { dragging ?? delay.seconds },
                    set: { dragging = ($0 / delay.stepSeconds).rounded() * delay.stepSeconds }
                ),
                in: -delay.limitSeconds...delay.limitSeconds
            ) { editing in
                guard !editing, let seconds = dragging else { return }
                store.dispatch(command: delay.menu == .subtitleDelay
                    ? PlayerCommandSetSubtitleDelay(seconds: seconds)
                    : PlayerCommandSetAudioDelay(seconds: seconds))
                dragging = nil
            }
            .accessibilityLabel(delay.title)
            .accessibilityValue(delay.label)
            .accessibilityIdentifier("player.delay.slider")
            Button(T.shared.player.menu.reset) { store.dispatch(command: delay.reset) }
                .disabled(!delay.canReset)
                .accessibilityIdentifier("player.delay.reset")
        }
        .padding(20)
        .frame(minWidth: 280)
    }

    /// − or +: `command` one step; held, `held` seconds a step.
    private func step(_ symbol: String, label: String, id: String, command: any PlayerCommand, held: Double) -> some View {
        let subtitles = delay.menu == .subtitleDelay
        return PlayerIconButton(systemImage: symbol, label: label, value: delay.label, id: id) {
            store.dispatch(command: command)
        } repeating: {
            store.dispatch(command: subtitles ? PlayerCommandAdjustSubtitleDelay(deltaSeconds: held) : PlayerCommandAdjustAudioDelay(deltaSeconds: held))
        }
        .playerGlass(in: Circle(), interactive: true)
    }
}

/// The custom speed (`player.speed`): − value + as the player's glass circle buttons (disabled at the ends of the range;
/// VoiceOver names them Slower and Faster), a step of the store's each and, held as long as a long press, a quarter at
/// once and every 200 ms until let go (the speed shortcuts' step), over a slider of the player's whole range that sets
/// the speed on the same grid as it moves, and Normal, off at 1×. Each change applies at once, as a preset's pick does;
/// on the Mac the arrow keys step it too.
private struct SpeedPopover: View {
    let speed: SpeedControl
    let store: PlayerStore
    #if os(macOS)
    @FocusState private var focused: Bool
    #endif

    var body: some View {
        VStack(spacing: 14) {
            Text(InterfaceLocale.shared.menuTitle(text: T.shared.player.speed.customTitle))
                .font(.headline)
            HStack(spacing: 16) {
                step("minus", label: speed.decreaseLabel, id: "player.speed.decrease", command: speed.decrease, held: PlayerCommandSpeedDown.shared)
                    .disabled(!speed.canDecrease)
                Text(speed.label)
                    .font(.title3.monospacedDigit())
                    .frame(minWidth: 88)
                    .accessibilityIdentifier("player.speed")
                step("plus", label: speed.increaseLabel, id: "player.speed.increase", command: speed.increase, held: PlayerCommandSpeedUp.shared)
                    .disabled(!speed.canIncrease)
            }
            Slider(
                value: Binding(
                    get: { speed.speed },
                    set: { value in
                        let picked = speed.snapped(value: value)
                        if picked != speed.speed { store.dispatch(command: PlayerCommandSetSpeed(speed: picked)) }
                    }
                ),
                in: speed.min...speed.max
            )
            .accessibilityLabel(T.shared.player.speed.customTitle)
            .accessibilityValue(speed.label)
            .accessibilityIdentifier("player.speed.slider")
            Button(T.shared.player.speed.normal) { store.dispatch(command: speed.reset) }
                .disabled(!speed.canReset)
                .accessibilityIdentifier("player.speed.reset")
        }
        .padding(20)
        .frame(minWidth: 280)
        #if os(macOS)
        // The popover takes the keys while it shows, with or without the system's keyboard navigation (as a text field
        // does): left and right step the speed.
        .focusable(interactions: .edit)
        .focused($focused)
        .focusEffectDisabled()
        .onAppear { focused = true }
        .onKeyPress(.leftArrow) {
            if speed.canDecrease { store.dispatch(command: speed.decrease) }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            if speed.canIncrease { store.dispatch(command: speed.increase) }
            return .handled
        }
        #endif
    }

    /// − or +: `command` one step; held, `held` (a quarter) a step.
    private func step(_ symbol: String, label: String, id: String, command: any PlayerCommand, held: any PlayerCommand) -> some View {
        PlayerIconButton(systemImage: symbol, label: label, value: speed.label, id: id) {
            store.dispatch(command: command)
        } repeating: {
            store.dispatch(command: held)
        }
        .playerGlass(in: Circle(), interactive: true)
    }
}
#endif

#if os(macOS)
/// The Mac's menus report no opening of their own: `PlayerScreen` hears AppKit's menu tracking, and the menu button the
/// pointer was last over tells which menu it is. While AppKit tracks a menu the options menu shows the state it opened
/// with (`opened`): the sleep timer's time left changing every second changed its entries, and SwiftUI's update of the
/// open menu closed the submenu under the pointer, a pick in it with it.
@MainActor
enum PlayerMenuTracking {
    static var hovered: PlayerMenu?
    static var opened: PlayerUiState?
}
#endif

#if os(iOS)
/// A UIKit button with the menu as its primary action (iOS, `SystemMenuButton`). UIKit tells a button when its menu shows
/// and goes, which a SwiftUI `Menu` doesn't: the store hears the menu open and close, and an entry that opens a popover or
/// a sheet (the delay, the playback info) does so once the menu is gone. The menu (`content`) is built again only when
/// what it shows changes (`NativeMenu.signature`).
private struct NativeMenuButton: UIViewRepresentable {
    let menu: PlayerMenu
    let systemImage: String
    let label: String
    let value: String?
    let id: String
    let content: NativeMenu
    let store: PlayerStore

    func makeUIView(context: Context) -> MenuButton {
        let button = MenuButton(type: .system)
        button.showsMenuAsPrimaryAction = true
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = UIColor(Palette.onVideo)
        configuration.contentInsets = .zero
        button.configuration = configuration
        // At the accessibility text sizes a long press shows the symbol and label large, as on `PlayerIconButton`.
        button.showsLargeContentViewer = true
        button.addInteraction(UILargeContentViewerInteraction())
        return button
    }

    func updateUIView(_ button: MenuButton, context: Context) {
        // The image, its size, the enabled state and the alpha only when they change: the player's state updates
        // often, and each set redraws the button, its open menu's source too.
        if button.systemImage != systemImage {
            button.systemImage = systemImage
            button.configuration?.image = UIImage(systemName: systemImage)
            button.largeContentImage = UIImage(systemName: systemImage)
        }
        // The symbol as SwiftUI draws the player's other buttons beside it (`PlayerIconButton`): the same point size at
        // the text size (SwiftUI's, which the overlay caps), weight and scale.
        let pointSize = UIFontMetrics(forTextStyle: .body).scaledValue(
            for: PlayerMetrics.icon,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(context.environment.dynamicTypeSize))
        )
        if button.symbolPointSize != pointSize {
            button.symbolPointSize = pointSize
            button.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
                pointSize: pointSize,
                weight: .semibold,
                scale: .medium
            )
        }
        button.accessibilityIdentifier = id
        button.accessibilityLabel = label
        button.accessibilityValue = value
        button.largeContentTitle = label
        // `disabled` around it (the speed, which a watch-together room may keep from this device).
        let enabled = context.environment.isEnabled
        if button.isEnabled != enabled {
            button.isEnabled = enabled
            button.alpha = enabled ? 1 : 0.45
        }
        let menu = self.menu
        let store = self.store
        button.onOpen = {
            if store.state.value.menu != menu { store.dispatch(command: PlayerCommandOpenMenu(menu: menu)) }
        }
        button.onClose = {
            if store.state.value.menu?.isNativeMenu == true { store.dispatch(command: PlayerCommandCloseMenu.shared) }
        }
        let signature = content.signature
        guard signature != button.signature else { return }
        button.signature = signature
        let built = UIMenu(title: content.title, children: Self.elements(content.children ?? [], button: button))
        button.menu = built
        if button.menuShown {
            button.contextMenuInteraction?.updateVisibleMenu { _ in built }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MenuButton, context: Context) -> CGSize? {
        CGSize(width: PlayerMetrics.button, height: PlayerMetrics.button)
    }

    /// A menu's entries as UIKit's; what an entry opens waits for `button`'s menu to close.
    private static func elements(_ entries: [NativeMenu], button: MenuButton) -> [UIMenuElement] {
        entries.map { entry -> UIMenuElement in
            let image = entry.systemImage.flatMap { systemImage in UIImage(systemName: systemImage) }
            if let label = entry.imageLabel { image?.accessibilityLabel = label }
            if let children = entry.children {
                var options: UIMenu.Options = []
                if entry.inline { options.insert(.displayInline) }
                if entry.singleSelection { options.insert(.singleSelection) }
                let menu = UIMenu(title: entry.title, image: image, options: options, children: elements(children, button: button))
                menu.subtitle = entry.subtitle
                return menu
            }
            let action = UIAction(title: entry.title, image: image, state: entry.checked == true ? .on : .off) { [weak button] _ in
                entry.action?()
                if let afterClose = entry.afterClose { button?.runAfterClose(afterClose) }
            }
            action.subtitle = entry.subtitle
            if !entry.enabled { action.attributes = .disabled }
            return action
        }
    }

    /// The menu's button, with what its configuration shows and what its menu was built from.
    final class MenuButton: SystemMenuButton {
        var signature: [AnyHashable] = []
        /// The symbol the button's configuration shows.
        var systemImage: String?
        /// The point size of the symbol the configuration shows.
        var symbolPointSize: CGFloat?
    }
}
#endif
