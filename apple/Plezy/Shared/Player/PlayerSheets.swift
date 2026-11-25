import SwiftUI
import PlezyKit

#if !os(tvOS)
/// The sheets over the player on iOS and the Mac, each for the store's open menu (`PlayerUiState.menu`), each closed by
/// its Close, a swipe or Escape, which closes the menu: the chapters and the queue (`player.chapters.sheet`,
/// `player.queue.sheet`), lists with their thumbnails; the subtitle search (`player.search.sheet`), a form; the file info
/// (`player.fileInfo.sheet`); the watch-together session. The shaders' open dialog and delete question show over the
/// player (`ShaderPrompts`). Apple TV shows them in its panel (`PlayerTVPanel`).
struct PlayerSheets: ViewModifier {
    let playback: PlayerModel
    let prompts: ShaderPrompts

    func body(content: Content) -> some View {
        let state = playback.state.state
        let store = playback.store
        content
            .appSheet(isPresented: store.menuPresentation(.chapters, shown: state.menu == .chapters && !state.chapters.isEmpty), id: "player.chapters.sheet", size: .list) {
                let state = playback.state.state
                PlayerListPage(id: "player.chapters.sheet", title: T.shared.videoControls.chapters, current: state.chapters.firstIndex(where: \.current), store: store) {
                    ForEach(Array(state.chapters.enumerated()), id: \.offset) { index, chapter in
                        PlayerListRow(
                            title: chapter.title,
                            detail: chapter.start,
                            imageUrl: chapter.imageUrl,
                            placeholder: .movie,
                            current: chapter.current,
                            playing: !state.paused,
                            id: "player.menu.item.\(index)"
                        ) {
                            if let command = chapter.command { store.dispatch(command: command) }
                        }
                        .disabled(chapter.command == nil)
                    }
                }
            }
            .appSheet(isPresented: store.menuPresentation(.queue, shown: state.menu == .queue && !state.queue.isEmpty), id: "player.queue.sheet", size: .list) {
                let state = playback.state.state
                PlayerListPage(id: "player.queue.sheet", title: T.shared.videoControls.queue, current: state.queue.firstIndex(where: \.current), store: store) {
                    ForEach(Array(state.queue.enumerated()), id: \.offset) { index, item in
                        PlayerListRow(
                            title: item.title,
                            detail: item.subtitle,
                            imageUrl: item.imageUrl,
                            placeholder: .episode,
                            current: item.current,
                            playing: !state.paused,
                            spoiler: item.spoiler,
                            id: "player.menu.item.\(index)"
                        ) {
                            store.dispatch(command: PlayerCommandPlayQueueItem(key: item.key))
                        }
                    }
                }
            }
            .appSheet(isPresented: store.menuPresentation(.subtitleSearch, shown: state.menu == .subtitleSearch && state.subtitleSearch != nil)) {
                if let search = playback.state.state.subtitleSearch {
                    SubtitleSearchForm(search: search, store: store)
                }
            }
            .appSheet(isPresented: store.menuPresentation(.fileInfo, shown: state.menu == .fileInfo), id: "player.fileInfo.sheet", size: .panel) {
                FileInfoPage(state: playback.state.state, store: store)
            }
            // The watch-together session sheet (`PlayerMenu.watchTogether`), from the room pill or the options.
            .appSheet(isPresented: store.menuPresentation(.watchTogether, shown: state.menu == .watchTogether && state.watch != nil), size: .player) {
                if let watch = playback.state.state.watch { WatchSessionSheet(watch: watch, store: store) }
            }
            .modifier(ShaderPromptsPresenter(prompts: prompts, store: store))
    }
}

extension View {
    /// The player's sheets over it (`PlayerSheets`).
    func playerSheets(playback: PlayerModel, prompts: ShaderPrompts) -> some View {
        modifier(PlayerSheets(playback: playback, prompts: prompts))
    }
}

/// A sheet's page of rows (the chapters, the queue) under its title, with Close (`player.menu.close`), which closes the
/// store's menu. On iOS the title is the sheet's bar's; on the Mac, whose sheet bar would set it in past where the rows
/// start, it heads the list, at the rows' leading edge (`player.list.title`), as the Mac's music queue's does. It opens
/// scrolled to the `current` row (the rows' ids are their offsets), so the chapter or episode playing is in view.
private struct PlayerListPage<Rows: View>: View {
    let id: String
    let title: String
    let current: Int?
    let store: PlayerStore
    @ViewBuilder let rows: () -> Rows
    #if os(macOS)
    /// The sheet is as tall as the rows, up to its cap (`SheetSize.list`).
    @Environment(\.formSetsSheetHeight) private var listSetsHeight
    #endif

    var body: some View {
        #if os(macOS)
        SheetPage(id: id, title: title, titleInContent: true, close: close) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("player.list.title")
                    // The plain list insets its rows' content by 8 pt.
                    .padding(.horizontal, 8)
                    .padding(.top, 16)
                ScrollViewReader { scroller in
                    List { rows() }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .modifier(SheetHeightFromForm(active: listSetsHeight))
                        .onAppear { scrollToCurrent(scroller) }
                }
            }
        }
        #else
        // Plain, as the music queue's: the grouped style's top inset left 35 pt of nothing under the bar, a tenth of an
        // iPhone's height on its side. No section lines (one ran under the bar) and no row fill (the sheet's own shows
        // to its foot, without a band where the rows end).
        SheetPage(id: id, title: title, close: close) {
            ScrollViewReader { scroller in
                List {
                    rows()
                        .listSectionSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onAppear { scrollToCurrent(scroller) }
            }
        }
        #endif
    }

    private func scrollToCurrent(_ scroller: ScrollViewProxy) {
        guard let current else { return }
        #if os(macOS)
        // At the list's top on the Mac: its table places a row by the estimated heights of the rows not yet drawn, a
        // third of a drawn row's, so a centred row came out off by the difference, half under the title.
        scroller.scrollTo(current, anchor: .top)
        #else
        scroller.scrollTo(current, anchor: .center)
        #endif
    }

    private var close: SheetAction {
        SheetAction(title: T.shared.nav.close, id: "player.menu.close") { store.dispatch(command: PlayerCommandCloseMenu.shared) }
    }
}

/// A chapter or a queue entry, alike: its 16:9 thumbnail, 64 × 36 so a row stays the height of its two lines of text
/// (the `placeholder` kind's symbol where it has none; an unwatched episode's blurred past recognition while spoilers
/// are hidden), its title over its detail (the chapter's start, the episode's line). The one playing carries the
/// now-playing mark on its thumbnail (`nowPlayingMark`, the equalizer the music queue's playing row has), its title
/// semibold, selected and valued "Now playing" for VoiceOver; the title starts where every row's does. A pick seeks to
/// the chapter or plays the entry, which closes the sheet.
private struct PlayerListRow: View {
    let title: String
    let detail: String?
    let imageUrl: String?
    let placeholder: PlaceholderKind
    let current: Bool
    let playing: Bool
    var spoiler = false
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RemoteImage(url: imageUrl, blurred: spoiler) { failed in
                    // The playing row's mark stands alone: no placeholder symbol under its bars.
                    if failed && !current { ArtworkPlaceholder(kind: placeholder) }
                }
                    .frame(width: 64, height: 36)
                    .nowPlayingMark(current, playing: playing)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).fontWeight(current ? .semibold : .regular).lineLimit(2)
                    if let detail {
                        Text(detail).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .formRowButtonStyle()
        .accessibilityElement(children: .combine)
        .accessibilityValue(current ? T.shared.player.nowPlaying : "")
        .accessibilityAddTraits(current ? .isSelected : [])
        .accessibilityIdentifier(id)
    }
}

/// The file info (`PlayerMenu.fileInfo`): a spinner while it loads, then the file's info (`FileInfoContent`) or why
/// there is none.
private struct FileInfoPage: View {
    let state: PlayerUiState
    let store: PlayerStore

    var body: some View {
        SheetPage(id: "player.fileInfo.sheet", title: InterfaceLocale.shared.menuTitle(text: T.shared.fileInfo.title), close: close) {
            if let info = state.fileInfo, !info.loading {
                if let file = info.info {
                    FileInfoContent(info: file, title: info.title, probe: "player.fileInfo")
                } else {
                    ContentUnavailableView(info.error ?? T.shared.fileInfo.title, systemImage: "info.circle")
                }
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var close: SheetAction {
        SheetAction(title: T.shared.nav.close, id: "player.menu.close") { store.dispatch(command: PlayerCommandCloseMenu.shared) }
    }
}

/// The subtitle search (Plex) as a form: the language (a picker of the languages) and the title searched, then the
/// results, a pick of which downloads it (one at a time), the outcome under them. Opening it searches; each edit of the
/// title searches again once the typing stops (the store waits), submitting it and a language pick at once.
private struct SubtitleSearchForm: View {
    let search: SubtitleSearchState
    let store: PlayerStore
    @State private var title: String?

    var body: some View {
        SheetPage(id: "player.search.sheet", title: InterfaceLocale.shared.menuTitle(text: T.shared.videoControls.searchSubtitles), close: SheetAction(title: T.shared.nav.close, id: "player.menu.close") {
            store.dispatch(command: PlayerCommandCloseMenu.shared)
        }) {
            Form {
                Section {
                    Picker(T.shared.videoControls.language, selection: Binding(
                        get: { search.languages.firstIndex(where: \.selected) ?? 0 },
                        set: { index in store.dispatch(command: search.languages[index].command) }
                    )) {
                        ForEach(Array(search.languages.enumerated()), id: \.offset) { index, language in
                            Text(language.label).tag(index)
                        }
                    }
                    .accessibilityIdentifier("player.search.language")
                    TextField(T.shared.videoControls.searchSubtitles, text: titleBinding)
                        .onSubmit { send(now: true) }
                        .accessibilityIdentifier("player.search.title")
                }
                Section {
                    if search.searching {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        ForEach(Array(search.results.enumerated()), id: \.offset) { index, result in
                            Button { store.dispatch(command: result.command) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.label).lineLimit(2)
                                        if let detail = result.detail {
                                            Text(detail).font(.subheadline).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer(minLength: 8)
                                    if search.downloading == result.key { ProgressView() }
                                }
                                .contentShape(Rectangle())
                            }
                            .formRowButtonStyle()
                            .disabled(search.downloading != nil)
                            .accessibilityIdentifier("player.menu.item.\(index)")
                        }
                    }
                } footer: {
                    if let message = search.message, !search.searching {
                        Text(message).accessibilityIdentifier("player.search.message")
                    }
                }
            }
            .formStyle(.grouped)
        }
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { title ?? search.title },
            set: { text in
                title = text
                send(now: false)
            }
        )
    }

    /// An edit searches once the title rests; submitting the field searches at once.
    private func send(now: Bool) {
        store.dispatch(command: PlayerCommandSearchSubtitles(language: search.languageCode, title: title ?? search.title, now: now))
    }
}
#endif
