import SwiftUI
import PlezyKit

/// A show's upcoming airings (`Route.LiveTvShowSchedule`): its store (`AppSession.liveTvShowSchedule`, kept while the
/// route is on a stack) and screen.
struct ShowScheduleRoute: View {
    let app: AppModel

    @State private var model: (store: ShowScheduleStore, state: StoreObserver<ShowScheduleUiState>)?

    init(app: AppModel, route: any Route) {
        self.app = app
        let clock = LiveTvClock.uses24Hour
        if let store = app.session.liveTvShowSchedule(route: route, use24HourClock: clock) {
            store.setUse24HourClock(value: clock)
            _model = State(initialValue: (store, StoreObserver(store.state)))
        }
    }

    var body: some View {
        if let model {
            ShowScheduleScreen(state: model.state.state, store: model.store)
                .task { await model.state.observe() }
                .onClockChange { model.store.setUse24HourClock(value: $0) }
        }
    }
}

/// The show schedule (`ShowScheduleUiState`): the show's title as the page's, "Record show" in the bar (on Apple TV,
/// whose bar has no buttons, the list's first row) when the server records; a spinner while the airings load, the empty
/// state, else a list row each: "S1 · E2 — Title" with its NEW badge, the one on now with the play symbol, when it airs
/// ("12 min left", "Starting in 30 min", "Tomorrow at 20:00") and the summary, and the channel. A row tunes an airing on
/// now, else opens its details. Over it: the details sheet, the Record Options sheet and the snackbar.
///
/// Accessibility identifiers: `livetv.schedule`, `livetv.schedule.record`, `livetv.schedule.row.<index>`,
/// `livetv.schedule.empty`, `livetv.schedule.message`.
struct ShowScheduleScreen: View {
    let state: ShowScheduleUiState
    let store: ShowScheduleStore

    @FocusState private var focusedRow: Int?

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .pageTitle(state.title)
            #if !os(tvOS)
            .toolbar {
                if let record = state.recordShowLabel {
                    ToolbarItem(placement: .primaryAction) {
                        Button { store.recordShow() } label: {
                            Label(record, systemImage: "record.circle")
                        }
                        .accessibilityIdentifier("livetv.schedule.record")
                    }
                }
            }
            #endif
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("livetv.schedule")
            .toast(state.message?.text, id: "livetv.schedule.message", isError: state.message?.isError == true) { store.messageShown() }
            .programDetailsSheet(state.details) { store.closeDetails() }
            .recordOptionsSheet(state.recordOptions)
    }

    @ViewBuilder
    private var content: some View {
        if state.loading {
            LoadingStateView()
        } else if let empty = state.emptyText {
            EmptyStateView(message: empty, systemImage: "calendar")
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("livetv.schedule.empty")
        } else {
            List {
                #if os(tvOS)
                if let record = state.recordShowLabel {
                    Section {
                        Button { store.recordShow() } label: {
                            Label(record, systemImage: "record.circle")
                        }
                        .accessibilityIdentifier("livetv.schedule.record")
                    }
                }
                #endif
                Section {
                    ForEach(Array(state.rows.enumerated()), id: \.offset) { index, row in
                        Button { store.tap(index: Int32(index)) } label: { rowContent(row) }
                            .formRowButtonStyle()
                            .focused($focusedRow, equals: index)
                            .accessibilityIdentifier("livetv.schedule.row.\(index)")
                    }
                }
            }
            .readableColumn()
            // Given until it holds: opened at launch, the system first puts focus elsewhere.
            .task { await FocusRestore.restore($focusedRow, to: 0, hold: 1.5) }
        }
    }

    private func rowContent(_ row: ScheduleRow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(row.title).lineLimit(1)
                    if let premiere = row.premiereBadge { BadgeView(text: premiere, emphasis: .strong) }
                }
                if !row.subtitle.isEmpty {
                    Text(row.subtitle)
                        .font(.subheadline)
                        .mutedForeground()
                        .lineLimit(2)
                }
                if let channel = row.channelName {
                    Text(channel)
                        .font(.caption)
                        .mutedForeground()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if row.live {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }
}
