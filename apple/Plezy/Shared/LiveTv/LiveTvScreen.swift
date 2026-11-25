import SwiftUI
import PlezyKit

/// The Live TV destination's stores (`AppSession.liveTv`, kept while the route is on a stack) with their states mirrored
/// for the views. Obtained once per appearance of the route.
@MainActor
final class LiveTvModel {
    let screen: LiveTvScreen
    let state: StoreObserver<LiveTvUiState>
    let guide: StoreObserver<GuideUiState>
    let whatsOn: StoreObserver<WhatsOnUiState>
    let recordings: StoreObserver<RecordingsUiState>
    let details: StoreObserver<ProgramDetailsStore?>

    init?(app: AppModel, route: any Route) {
        let clock = LiveTvClock.uses24Hour
        guard let screen = app.session.liveTv(route: route, use24HourClock: clock) else { return nil }
        // Kept from an earlier appearance, the screen may have the clock as it was then.
        screen.setUse24HourClock(value: clock)
        self.screen = screen
        state = StoreObserver(screen.screen.state)
        guide = StoreObserver(screen.guide.state)
        whatsOn = StoreObserver(screen.whatsOn.state)
        recordings = StoreObserver(screen.recordings.state)
        details = StoreObserver(screen.details)
    }

    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.state.observe() }
            group.addTask { await self.guide.observe() }
            group.addTask { await self.whatsOn.observe() }
            group.addTask { await self.recordings.observe() }
            group.addTask { await self.details.observe() }
        }
    }
}

/// Where focus is on the Live TV screen (the remote's, a keyboard's) that the stores move it to: a tab chip, an action,
/// or the selected tab's first control (the guide keeps its own, `GuideView`).
enum LiveTvField: Hashable {
    case tab(LiveTvTab)
    case action(LiveTvAction)
    case content
}

/// The Live TV route.
struct LiveTvRoute: View {
    let app: AppModel

    @State private var model: LiveTvModel?

    init(app: AppModel, route: any Route) {
        self.app = app
        _model = State(initialValue: LiveTvModel(app: app, route: route))
    }

    var body: some View {
        if let model {
            LiveTvScreenView(app: app, model: model)
        }
    }
}

/// The Live TV screen (`LiveTvUiState`): its header row, the tabs (Guide, What's On, Scheduled) leading (the system's
/// segmented control on iPhone, iPad and the Mac; chips on Apple TV, whose focus moves along them) and the actions
/// (search, the favourites filter's star, reorder favourites, re-evaluate rules, refresh) trailing, over the selected
/// tab; a spinner while the channels load, the error with Retry, or the empty state. The page's title (Live TV) in the
/// bar where it shows one. Over it: the snackbar of the screen and its tabs, and the sheets of the program details, the
/// guide search and reorder favourites.
///
/// Focus (the remote's, a keyboard's) moves where the store asks: into the selected tab, to the tabs, to the actions,
/// to the search's first result. A chip selects its tab when pressed, as the guide's chips do.
///
/// Accessibility identifiers: `livetv.screen`, `livetv.tab.<guide|whatsOn|recordings>`, `livetv.action.<search|
/// favorites|reorder|rules|refresh>`, `livetv.loading`, `livetv.error`, `livetv.empty`, `livetv.favorites.empty`,
/// `livetv.favorites.showAll`, `livetv.message`.
struct LiveTvScreenView: View {
    let app: AppModel
    let model: LiveTvModel

    @Environment(\.formFactor) private var formFactor
    @Environment(\.screenSides) private var sides
    @Environment(\.dimens) private var dimens
    @FocusState private var field: LiveTvField?
    /// Bumped to put focus on the guide's first channel.
    @State private var guideEntry = 0
    /// Bumped to put focus on the guide search's first result.
    @State private var searchResultFocus = 0

    var body: some View {
        let state = model.state.state
        page(state)
        .background(Palette.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("livetv.screen")
        .toast(message?.text, id: "livetv.message", isError: message?.isError == true) { messageShown() }
        // A controller's shoulder buttons: the tab before or after, focus on its chip.
        .gamepadTabs(
            enabled: state.search == nil && state.reorder == nil && model.details.state == nil && model.whatsOn.state.details == nil
                && tabsShown(state),
            tabs: { model.state.state.tabs.map(\.tab) },
            selected: { model.state.state.selectedTab }
        ) { tab in
            model.screen.screen.selectTab(tab: tab)
            field = .tab(tab)
        }
        .programDetailsSheet(model.details.state ?? model.whatsOn.state.details) { closeDetails() }
        .appSheet(
            isPresented: Binding(get: { state.search != nil }, set: { if !$0 { model.screen.screen.closeSearch() } }),
            id: "livetv.searchPanel", size: .panel
        ) {
            if let search = model.state.state.search {
                GuideSearchSheet(app: app, state: search, store: model.screen.screen, firstResultFocus: searchResultFocus)
            }
        }
        .appSheet(
            isPresented: Binding(get: { state.reorder != nil }, set: { if !$0 { model.screen.screen.closeReorder() } }),
            id: "livetv.reorderPanel", size: .panel
        ) {
            if let reorder = model.state.state.reorder {
                ReorderFavoritesSheet(app: app, state: reorder, store: model.screen.screen)
            }
        }
        .task { await model.observe() }
        .onAppear { model.screen.screen.setShown(shown: true) }
        .onDisappear { model.screen.screen.setShown(shown: false) }
        .onClockChange { model.screen.setUse24HourClock(value: $0) }
        .onChange(of: state.focus, initial: true) { _, target in
            guard let target else { return }
            moveFocus(target, state: model.state.state)
            model.screen.screen.focusHandled()
        }
        // The last favourite removed in the sheet leaves nothing in the guide: focus goes to Show all channels.
        .onChange(of: state.reorder == nil) { _, closed in
            guard closed, model.state.state.favoritesEmpty != nil else { return }
            Task { @MainActor in await FocusRestore.restore($field, to: .content, hold: 1) }
        }
    }

    // MARK: Header

    #if os(tvOS)
    /// The tabs as chips leading, the actions after them, above the selected tab.
    private func page(_ state: LiveTvUiState) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                chips(state)
                    .padding(.leading, sides.leading)
                Spacer(minLength: 0)
                HStack(spacing: 16) {
                    ForEach(state.actions, id: \.action) { action in
                        IconButton(systemImage: symbol(action), label: action.label, id: "livetv.action.\(actionId(action.action))") {
                            model.screen.screen.perform(action: action.action)
                        }
                        .accessibilityAddTraits(action.active ? .isSelected : [])
                        .focused($field, equals: .action(action.action))
                    }
                }
                .padding(.trailing, sides.trailing)
            }
            .shelfFocusSection()
            content(state)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    #else
    /// The screen's header row (`screenHeader`): the tabs as a segmented control, whole, scrolling sideways on a phone
    /// where it doesn't fit, and the actions where the platform puts a screen's actions, over the selected tab.
    private func page(_ state: LiveTvUiState) -> some View {
        content(state)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .screenHeader(scrolls: true) {
                if tabsShown(state) {
                    Picker(state.title, selection: Binding(get: { model.state.state.selectedTab }, set: { model.screen.screen.selectTab(tab: $0) })) {
                        ForEach(state.tabs, id: \.tab) { tab in
                            Text(tab.label).tag(tab.tab).accessibilityIdentifier("livetv.tab.\(tabId(tab.tab))")
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    .focused($field, equals: .tab(state.selectedTab))
                    .accessibilityIdentifier("livetv.tabs")
                }
            } actions: {
                ForEach(state.actions, id: \.action) { action in
                    Button { model.screen.screen.perform(action: action.action) } label: {
                        Label(action.label, systemImage: symbol(action))
                    }
                    .accessibilityLabel(action.label)
                    .accessibilityAddTraits(action.active ? .isSelected : [])
                    .accessibilityIdentifier("livetv.action.\(actionId(action.action))")
                    .focused($field, equals: .action(action.action))
                }
            }
            .pageTitle(state.title)
    }
    #endif

    #if os(tvOS)
    private func chips(_ state: LiveTvUiState) -> some View {
        HStack(spacing: 16) {
            if tabsShown(state) {
                ForEach(state.tabs, id: \.tab) { tab in
                    LiveTvChip(tab.label, selected: tab.tab == state.selectedTab, id: "livetv.tab.\(tabId(tab.tab))") {
                        model.screen.screen.selectTab(tab: tab.tab)
                    }
                    .focused($field, equals: .tab(tab.tab))
                }
            }
        }
    }
    #endif

    private func tabsShown(_ state: LiveTvUiState) -> Bool {
        if case .tabs = onEnum(of: state.body) { true } else { false }
    }

    private func symbol(_ action: LiveTvActionUi) -> String {
        switch action.action {
        case .search: "magnifyingglass"
        case .favoritesFilter: action.active ? "star.fill" : "star"
        case .reorderFavorites: "arrow.up.arrow.down"
        case .processRules: "bolt"
        default: "arrow.clockwise"
        }
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ state: LiveTvUiState) -> some View {
        switch onEnum(of: state.body) {
        case .loading:
            LoadingStateView().accessibilityIdentifier("livetv.loading")
        case .failed(let failed):
            ErrorStateView(message: failed.message, retryLabel: failed.retryLabel, onRetry: { model.screen.screen.retry() })
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("livetv.error")
        case .empty(let empty):
            EmptyStateView(message: empty.message, systemImage: "play.tv")
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("livetv.empty")
        case .tabs:
            switch state.selectedTab {
            case .whatsOn:
                WhatsOnTab(app: app, state: model.whatsOn.state, store: model.screen.whatsOn, focus: $field)
            case .recordings:
                RecordingsTab(state: model.recordings.state, store: model.screen.recordings, focus: $field)
            default:
                if let noChannels = state.guideEmpty {
                    EmptyStateView(message: noChannels, systemImage: "play.tv")
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("livetv.empty")
                } else if let empty = state.favoritesEmpty {
                    EmptyStateView(message: empty.hint, title: empty.title, systemImage: "star") {
                        ActionButton(title: empty.actionLabel, id: "livetv.favorites.showAll", prominence: .primary, systemImage: "list.bullet", fullWidth: false) {
                            model.screen.screen.showAllChannels(hadFocus: formFactor == .tv || field == .content)
                        }
                        .focused($field, equals: .content)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("livetv.favorites.empty")
                } else {
                    GuideView(app: app, state: model.guide.state, store: model.screen.guide, entryRequest: guideEntry)
                }
            }
        }
    }

    // MARK: Focus and messages

    private func moveFocus(_ target: LiveTvFocusTarget, state: LiveTvUiState) {
        switch target {
        case .content:
            if state.selectedTab == .guide && state.favoritesEmpty == nil {
                guideEntry += 1
            } else {
                field = .content
            }
        case .tabBar:
            field = .tab(state.selectedTab)
        case .actions:
            if let first = state.actions.first { field = .action(first.action) }
        default:
            searchResultFocus += 1
        }
    }

    /// The snackbar shown: the screen's, else the What's On or Recordings tab's.
    private var message: LiveTvMessage? {
        model.state.state.message ?? model.whatsOn.state.message ?? model.recordings.state.message
    }

    private func messageShown() {
        if model.state.state.message != nil {
            model.screen.screen.messageShown()
        } else if model.whatsOn.state.message != nil {
            model.screen.whatsOn.messageShown()
        } else {
            model.screen.recordings.messageShown()
        }
    }

    private func closeDetails() {
        if model.details.state != nil {
            model.screen.closeDetails()
        } else {
            model.screen.whatsOn.closeDetails()
        }
    }

    private func tabId(_ tab: LiveTvTab) -> String {
        switch tab {
        case .whatsOn: "whatsOn"
        case .recordings: "recordings"
        default: "guide"
        }
    }

    private func actionId(_ action: LiveTvAction) -> String {
        switch action {
        case .search: "search"
        case .favoritesFilter: "favorites"
        case .reorderFavorites: "reorder"
        case .processRules: "rules"
        default: "refresh"
        }
    }
}
