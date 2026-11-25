import SwiftUI
import PlezyKit

/// The guide search (`GuideSearchUiState`) in a sheet: the system's search field (active as the sheet opens; Return goes
/// to the first result), then the "Channels" section (logo, name, "Channel {number}") and the "Programs" section (the
/// airing, "{channel} · {day} {time}"; a spinner while they load), or the no-results text. A result closes the sheet and
/// shows itself in the guide. Close in the bar.
///
/// Accessibility identifiers: `livetv.search`, `livetv.search.close`, `livetv.search.channel.<index>`,
/// `livetv.search.program.<index>`, `livetv.search.none`.
struct GuideSearchSheet: View {
    let app: AppModel
    let state: GuideSearchUiState
    let store: LiveTvStore
    /// Bumped when focus goes to the first result (`LiveTvFocusTarget.SEARCH_RESULT`).
    let firstResultFocus: Int

    @FocusState private var firstResultFocused: Bool
    @State private var query: String
    @State private var searching = true

    init(app: AppModel, state: GuideSearchUiState, store: LiveTvStore, firstResultFocus: Int) {
        self.app = app
        self.state = state
        self.store = store
        self.firstResultFocus = firstResultFocus
        _query = State(initialValue: state.query)
    }

    var body: some View {
        NavigationStack {
            results
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("livetv.search")
                .navigationTitle(state.title)
                .inlineNavigationTitle()
                .sheetToolbar(close: SheetAction(title: T.shared.common.close, id: "livetv.search.close") { store.closeSearch() })
                #if os(tvOS)
                .searchable(text: $query, prompt: state.hint)
                #else
                .searchable(text: $query, isPresented: $searching, prompt: state.hint)
                #endif
                // The query first: the `onChange` of the last key typed can run after the submit.
                .onSubmit(of: .search) {
                    store.setSearchQuery(query: query)
                    store.submitSearch()
                }
                #if !os(macOS)
                .autocorrectionDisabled()
                #endif
        }
        .onChange(of: query) { _, text in store.setSearchQuery(query: text) }
        .onChange(of: firstResultFocus) { firstResultFocused = true }
    }

    @ViewBuilder
    private var results: some View {
        if let none = state.noResults {
            ContentUnavailableView(none, systemImage: "magnifyingglass")
                .accessibilityIdentifier("livetv.search.none")
        } else {
            List {
                if !state.channels.isEmpty {
                    Section(state.channelsLabel) {
                        ForEach(Array(state.channels.enumerated()), id: \.offset) { index, row in
                            resultRow(row.title, row.subtitle, id: "livetv.search.channel.\(index)", first: index == 0) {
                                RemoteImage(
                                    artwork: app.liveTvArtwork(serverId: row.channel.serverId, path: row.channel.thumb, kind: .thumb),
                                    contentMode: .fit
                                ) { failed in
                                    if failed { ArtworkPlaceholder(kind: .channel) }
                                }
                            } action: {
                                store.selectSearchChannel(channel: row.channel)
                            }
                        }
                    }
                }
                if state.showsPrograms {
                    Section(state.programsLabel) {
                        if state.programsLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            ForEach(Array(state.programs.enumerated()), id: \.offset) { index, row in
                                resultRow(row.title, row.subtitle, id: "livetv.search.program.\(index)", first: state.channels.isEmpty && index == 0) {
                                    Image(systemName: "clock").mutedForeground()
                                } action: {
                                    store.selectSearchProgram(channel: row.channel, program: row.program)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func resultRow<Leading: View>(
        _ title: String, _ subtitle: String?, id: String, first: Bool,
        @ViewBuilder leading: () -> Leading, action: @escaping () -> Void
    ) -> some View {
        let row = Button(action: action) {
            HStack(spacing: 12) {
                leading().frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let subtitle {
                        Text(subtitle).font(.subheadline).mutedForeground()
                    }
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .formRowButtonStyle()
        .accessibilityIdentifier(id)
        if first {
            row.focused($firstResultFocused)
        } else {
            row
        }
    }
}
