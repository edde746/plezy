import SwiftUI
import PlezyKit

#if os(macOS) || os(tvOS)
import Combine
#endif

#if os(macOS)
import Carbon.HIToolbox
#endif

/// Where focus goes in the player. tvOS moves it as the Compose TV player does (`PlayerFocus.target`); iOS and macOS
/// leave focus to the user (a Mac's keyboard keeps its focus on the video, whose keys go to the store, until Tab takes it
/// to the timeline and the buttons; iOS takes a hardware keyboard's keys without focus, `HardwareKeys`).
enum PlayerFocus: Hashable {
    case video
    case scrub
    /// Play/pause: Apple TV's, which takes the timeline's place while live without a rewind window (`TVControls`); the
    /// Mac's in the control bar, where Down from the timeline goes.
    case playPause
    /// Apple TV's live label with a rewind window: the go-to-live button, first among the transport bar's buttons.
    case goToLive
    /// The transport bar's previous and next episode buttons.
    case previousEpisode
    case nextEpisode
    /// The transport bar's menu buttons, by the panel tab each opens (`PlayerMenuBar`): a panel closing gives focus
    /// back to the one that opened it.
    case menuButton(PlayerPanelTab)
    /// The tabs of the panel across the bottom (`PlayerTVPanel`: the chapters, the queue), and the chapters' and the
    /// queue's items, by index.
    case panelTab(PlayerPanelTab)
    case panelItem(Int)
    case menuItem(Int)
    case delayDecrease
    /// The custom speed's − (`PlayerMenu.customSpeed`).
    case speedDecrease
    /// The subtitle menu's More subtitles row.
    case moreSubtitles
    /// The Options menu's row of an option.
    case option(PlayerOptionId)
    case stillWatching
    /// The prompt button (skip, up next).
    case prompt
    /// The error's buttons (`ErrorState.buttons`), by what each does: the primary one takes focus.
    case error(ErrorAction)
    /// A watch-together room's Play, while the player refused to start in a playing room (`PlayerWatchPromptCard`).
    case watchPrompt

    /// The focus a change of the player's layers calls for, or nil to leave it where it is: the error's primary
    /// action; when the panel opens, the open menu's selected entry (the current chapter or queue entry on their tabs,
    /// the first option's row for the options), the delay's decrease button when a
    /// delay opens in it, a page's selected entry when it opens (an option's choices, More subtitles' languages, a
    /// language's subtitles) and the row that opened it when Back leaves it; nothing as another tab of the panel takes
    /// its place while focus is on the tabs (moving along them switches it); a watch-together room's Play as it comes
    /// up; still watching's Continue and the prompt button when they come up (the prompt button by itself, not as it
    /// comes back with the controls past its own seconds, and not in the middle of a scrub, whose left and right the
    /// timeline takes); the timeline when a scrub starts; when the panel closes (Menu, a pick, its own close) what
    /// opened it (`opener`, from `panelOpener`; a menu button only while it is among `menuButtons`), as AVKit's menus
    /// give focus back to their button; and the timeline (live: play/pause in its place, `home`) when the controls come
    /// up, the prompt button with them or not, when a tab of the panel opened from it (Down) closes, when the error
    /// goes, when the first frame shows, when the playback turns live or back under the controls and when the episode
    /// button that has focus (`focused`) turns off, Previous on a series' first episode, where tvOS would leave focus on
    /// the dimmed button until the controls go; the card or the prompt button while the controls are down, else the
    /// video.
    static func target(
        from old: PlayerFocusContext,
        to new: PlayerFocusContext,
        focused: PlayerFocus?,
        opener: PlayerFocus?,
        menuButtons: Set<PlayerPanelTab>,
        state: PlayerUiState
    ) -> PlayerFocus? {
        if let error = new.error { return error == old.error ? nil : error }
        if let panel = new.panel, let menu = state.menu {
            if old.panel == nil { return entry(menu, state: state) }
            if old.panel != panel {
                if case .panelTab = focused, panel.isPanelTab, old.panel?.isPanelTab == true { return nil }
                return entry(menu, state: state)
            }
            if new.page != old.page {
                if let page = old.page, new.page == nil || new.page == page.back,
                   let row = Self.opener(of: page, language: old.language, state: state) {
                    return row
                }
                if new.page != nil { return entry(menu, state: state) }
            }
            return new.delay && !old.delay ? .delayDecrease : nil
        }
        // A watch-together room's Play, as it comes up.
        if new.watchPrompt, !old.watchPrompt { return .watchPrompt }
        // Still watching's Continue and the prompt button, as they come up, over the controls too.
        if new.stillWatching, !old.stillWatching { return .stillWatching }
        if new.prompt, !old.prompt, !new.stillWatching, !new.scrubbing { return .prompt }
        if new.scrubbing, !old.scrubbing { return .scrub }
        if new.controls {
            let home: PlayerFocus = new.live ? .playPause : .scrub
            if old.panel != nil {
                if let opener, shows(opener, menuButtons: menuButtons, state: state) { return opener }
                return home
            }
            if !old.controls || old.error != nil || old.live != new.live || (new.firstFrame && !old.firstFrame) { return home }
            if let focused, old.episodeButtons.contains(focused), !new.episodeButtons.contains(focused) { return home }
            return nil
        }
        return new.stillWatching ? .stillWatching : new.prompt ? .prompt : new.watchPrompt ? .watchPrompt : .video
    }

    /// Where focus rests with the controls up: the timeline, live without a rewind window play/pause in its place.
    static func home(_ state: PlayerUiState) -> PlayerFocus {
        state.showsTimeline ? .scrub : .playPause
    }

    /// What a panel opening on `state` gives focus back to as it closes, as AVKit's transport bar does: its menu's
    /// button; nil for the tabs across the bottom (Down from the timeline, a swipe), which give it back to the timeline.
    static func panelOpener(_ state: PlayerUiState) -> PlayerFocus? {
        guard let tab = PlayerPanelTab(state), !tab.isPanelTab else { return nil }
        return .menuButton(tab)
    }

    /// Whether `opener` is still on the transport bar to take focus back: a menu button shows and can take focus while
    /// it reports its frame (`menuButtons`), which the track menus' buttons stop with their tracks.
    private static func shows(_ opener: PlayerFocus, menuButtons: Set<PlayerPanelTab>, state: PlayerUiState) -> Bool {
        switch opener {
        case .menuButton(let tab): menuButtons.contains(tab)
        case .video, .scrub, .playPause, .goToLive, .previousEpisode, .nextEpisode, .panelTab, .panelItem, .menuItem,
             .delayDecrease, .speedDecrease, .moreSubtitles, .option, .stillWatching, .prompt, .error, .watchPrompt:
            true
        }
    }

    /// The entry the panel opens on: the selected track, speed or choice, the delay's and the custom speed's decrease
    /// button, the first option's row, the current chapter or queue entry.
    private static func entry(_ menu: PlayerMenu, state: PlayerUiState) -> PlayerFocus {
        switch menu {
        case .subtitleDelay, .audioDelay: .delayDecrease
        case .customSpeed: .speedDecrease
        case .options: state.menuOptions.first.map { .option($0.id) } ?? .menuItem(0)
        case .chapters, .contentStrip: .panelItem(state.chapters.firstIndex(where: \.current) ?? 0)
        case .queue: .panelItem(state.queue.firstIndex(where: \.current) ?? 0)
        // The selected track, speed or choice (`PlayerUiState.selectedEntry`); the first of More subtitles' languages,
        // of a page that lists apart (the version and quality, the subtitle search, the file info) and of the room's.
        case .audio, .subtitles, .speed, .moreSubtitles, .subtitleLanguage, .videoFit, .zoom, .shaders, .sleepTimer,
             .audioChannels, .audioOutput, .watchTogether, .tracks, .subtitleSearch, .versions, .fileInfo,
             .dolbyVisionConversion, .httpStatus:
            .menuItem(Int(state.selectedEntry))
        }
    }

    /// The row that opened `page`, which takes focus when Back leaves it: the option's (in the options or the audio
    /// menu), More subtitles', the speeds' Custom (their last), or the row of `language` (the language page's key) among
    /// More subtitles' languages.
    private static func opener(of page: PlayerMenu, language: String?, state: PlayerUiState) -> PlayerFocus? {
        if page == .moreSubtitles { return .moreSubtitles }
        if page == .subtitleLanguage { return state.moreSubtitles.firstIndex { $0.key == language }.map(PlayerFocus.menuItem) }
        if page == .customSpeed { return state.openOption.map { PlayerFocus.menuItem($0.choices.count - 1) } }
        return (state.menuOptions + state.audioOptions).first { $0.page == page }.map { PlayerFocus.option($0.id) }
    }
}

/// The parts of the player's state its focus follows.
struct PlayerFocusContext: Equatable {
    var controls: Bool
    /// The panel's tab (tvOS), nil while it is closed.
    var panel: PlayerPanelTab?
    /// A delay shows in the panel.
    var delay: Bool
    /// The page that shows in the panel: an option's, More subtitles or one of its languages.
    var page: PlayerMenu?
    /// The language whose page shows (`PlayerUiState.subtitleLanguage`).
    var language: String?
    var scrubbing: Bool
    /// The playback is live without a rewind window (`PlayerUiState.showsTimeline` false): play/pause in the timeline's
    /// place.
    var live: Bool
    var stillWatching: Bool
    /// The prompt button (skip, up next) shows by itself: counting down or in its first seconds, not only with the
    /// controls (`PlayerPrompt.withControls`).
    var prompt: Bool
    /// The error's primary button, which takes focus; nil without an error.
    var error: PlayerFocus?
    /// The episode buttons that show (`.previousEpisode`, `.nextEpisode`), on or off: the ones focus may rest on (an off
    /// one stays focusable on tvOS, `playerOff`).
    var episodeButtons: Set<PlayerFocus>
    /// A watch-together room's Play card shows (`PlayerWatchUi.playBlocked`).
    var watchPrompt: Bool
    /// The video's first frame has shown (`PlayerUiState.hasFirstFrame`): the timeline shows.
    var firstFrame: Bool

    init(_ state: PlayerUiState) {
        controls = state.controlsVisible
        panel = PlayerPanelTab(state)
        delay = state.menu == .subtitleDelay || state.menu == .audioDelay
        page = state.menu?.back != nil ? state.menu : nil
        language = state.subtitleLanguage?.key
        scrubbing = state.scrubbing
        live = !state.showsTimeline
        stillWatching = state.stillWatching != nil
        prompt = state.prompt.map { !$0.withControls } ?? false
        error = state.error.map { PlayerFocus.error($0.primary.action) }
        episodeButtons = state.episodes != nil ? [.previousEpisode, .nextEpisode] : []
        watchPrompt = state.watch?.playBlocked != nil
        firstFrame = state.hasFirstFrame
    }

    /// Nothing up: what the player's first state changes from.
    static let opening = PlayerFocusContext()

    private init() {
        controls = false
        panel = nil
        delay = false
        page = nil
        language = nil
        scrubbing = false
        live = false
        stillWatching = false
        prompt = false
        error = nil
        episodeButtons = []
        watchPrompt = false
        firstFrame = false
    }
}
