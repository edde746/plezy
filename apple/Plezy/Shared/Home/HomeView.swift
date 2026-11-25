import SwiftUI
import PlezyKit

/// Home: Continue Watching first, then Home's shortcuts (`HomeShortcuts`), then the hubs, each a
/// shelf (`HubShelf`). Nothing sits above the first shelf: no header and no bar buttons on any device; Refresh is also
/// ⌘R and pull to refresh. While Home loads, a loading shelf in Continue Watching's place (titled, in its cards' shape,
/// as tall as its row) and loading shelves in the hubs'; the error with Retry or the empty state in the hubs' place.
/// The shortcuts stay above them in every state, their row's place kept until it shows whole. A card opens its item
/// (Continue Watching's play directly, asking first which copy when the row merged several); its menu is the item's
/// (`MediaMenu`); a hub with more opens its View all from its heading's link or its last card (`HubShelf`). On Apple TV
/// and wide windows the focused item's backgrounds fade in and turn behind the top of the page (`Backdrop`).
///
/// Focus: on Apple TV the first card (Continue Watching's, else the first hub's) takes focus once Home has one, held
/// while Home loads, unless the user moved focus while Home was on top (the tab bar, a shortcut): a first focus asked
/// for while another screen is over Home (the profile picker after a switch) lands when that screen goes
/// (`ScreenFirstFocus`); Up from the top shelf reaches the tab bar. Off Apple TV nothing has focus under touch; Tab into
/// the page lands on that same first card, from where the arrows move along and between the shelves. A card's row changing under focus (Continue Watching moving
/// the card just played to its front) keeps focus on it (`followFocus`).
struct HomeView: View {
    let app: AppModel
    let route: any Route

    @State private var model: StoreModel<HomeStore, HomeUiState>?
    @State private var firstFocus = ScreenFirstFocus(pending: true)
    @FocusState private var focus: String?
    /// The card focus lost without a replacement in its row, still followed on the row's next change (`followFocus`).
    @State private var displaced: MediaCardUi?
    /// The card focus was last moved to by `follow`, not by the user, until the user moves it.
    @State private var followed: String?
    /// The card that last had focus: the one `follow` follows when the row changes while focus is away (the app in the
    /// background, the focused card gone before the change reached the view).
    @State private var lastFocus: String?
    /// The card focus is on, whose backgrounds the backdrop shows once focus rests.
    @State private var backdropCard: MediaCardUi?
    @Environment(\.formFactor) private var formFactor
    @Environment(\.dimens) private var dimens

    init(app: AppModel, route: any Route) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.home(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            page(state: state, store: store)
                .background(alignment: .top) {
                    if formFactor != .compact {
                        // Its backgrounds, else its own artwork unless blurred (a spoiler), else none.
                        Backdrop(key: backdropCard?.id, backdrops: backdropCard.map { $0.backdrops.isEmpty ? [$0.blurred ? nil : $0.artwork].compactMap { $0 } : $0.backdrops } ?? [])
                    }
                }
                #if !os(tvOS)
                .background {
                    // ⌘R wherever Home shows.
                    Button(T.shared.common.refresh, action: store.refresh)
                        .keyboardShortcut("r", modifiers: .command)
                        .opacity(0)
                        .accessibilityHidden(true)
                }
                #endif
                .toast(state.message, id: "home.message", isError: true) { store.messageShown() }
                .copyPicker(app: app)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("home.screen")
                .onChange(of: focus) {
                    guard let focus else { return }
                    if focus != followed {
                        displaced = nil
                        followed = nil
                    }
                    lastFocus = focus
                    if let card = card(focus, in: state.rows) { backdropCard = card }
                }
                .onChange(of: state.rows) { old, new in follow(from: old, to: new) }
                .task(id: followed) {
                    // Held there: the system can drop or move focus as the card under it goes.
                    await FocusRestore.restore($focus, to: followed, hold: 1, replacing: true)
                }
                #if os(tvOS)
                .firstFocus(firstFocus, to: firstCard(state.rows), isTop: app.isTop(route), focus: $focus, hold: 1.5)
                #endif
                .task { await model.state.observe() }
                // Home leaving closes the Server Tasks panel. Here, not on its chip: the shelves' lazy stack can make the
                // chips' row anew as Home settles, and the old chip's going would close a panel just opened from the new
                // one.
                .onDisappear { app.session.serverTasks.close() }
        }
    }

    private func page(state: HomeUiState, store: HomeStore) -> some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: dimens.sectionSpacing) {
                if let continueWatching = state.continueWatching {
                    shelf(continueWatching, store: store)
                } else if state.load == .loading {
                    // Continue Watching's place, as tall as its row: the chips and the shelves under it stay put as it
                    // comes.
                    LoadingShelf(title: T.shared.discover.continueWatching, shape: state.loadingShape)
                        .accessibilityIdentifier("home.continueWatching.loading")
                }
                HomeShortcuts(
                    app: app, focus: $focus, libraries: state.libraries, settled: state.shortcutsSettled, onRefresh: store.refresh,
                    onOpenLibrary: store.openLibrary(globalKey:)
                )
                switch state.load {
                case .loading:
                    LoadingShelves()
                case .content:
                    ForEach(state.hubs, id: \.id) { hub in shelf(hub, store: store) }
                    if state.hubsLoading { LoadingShelves(rows: state.hubs.isEmpty ? 3 : 1) }
                default:
                    BrowsePlaceholder(load: state.load, error: state.error, onRetry: store.retry, emptyMessage: T.shared.discover.noContentAvailable)
                        .frame(maxWidth: .infinity, minHeight: 320)
                }
            }
            .padding(.top, dimens.headingGap)
            .padding(.bottom, dimens.sectionSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("home.rail")
        }
        .scrollIndicators(.hidden)
        .scrollMemory(ScrollMemory.of(store))
        #if os(iOS)
        .refreshable {
            // The spinner holds until the refresh's pass ends; the rows stay meanwhile.
            store.refresh()
            for await busy in store.refreshing where !busy.boolValue { break }
        }
        #endif
    }

    private func shelf(_ hub: HubUi, store: HomeStore) -> some View {
        HubShelf(
            hub: hub, focus: $focus,
            onOpen: { card in store.open(hubId: hub.id, cardId: card.id) },
            onMenu: { card in store.menu(hubId: hub.id, cardId: card.id) },
            onViewAll: { store.openHub(hubId: hub.id) }
        )
    }

    /// The first card on the page: Continue Watching's, else the first hub's.
    private func firstCard(_ rows: [HubUi]) -> String? {
        guard let hub = rows.first, let card = hub.items.first else { return nil }
        return HubShelf.focusKey(hub: hub, card: card)
    }

    /// The card whose focus key is `key`.
    private func card(_ key: String, in rows: [HubUi]) -> MediaCardUi? {
        for hub in rows {
            if let card = hub.items.first(where: { HubShelf.focusKey(hub: hub, card: $0) == key }) { return card }
        }
        return nil
    }

    /// Keeps focus on the card it was on when its row changes under it (`followFocus`): the same card at its new place
    /// (Continue Watching moves the one just played to the front), or the next episode of its series that took its
    /// place, even when that comes a change later; without either, the card now at its place. On Apple TV a change while
    /// focus is away from Home's cards but Home is on top (the app coming back to the front) follows the card that last
    /// had it; a restore stops short of the tab bar (`FocusRestore`).
    private func follow(from old: [HubUi], to new: [HubUi]) {
        #if os(tvOS)
        guard let key = focus ?? (app.isTop(route) ? lastFocus : nil) else { return }
        #else
        guard let key = focus else { return }
        #endif
        let hubId = String(key.prefix { $0 != "|" })
        guard let before = old.first(where: { $0.id == hubId }), let after = new.first(where: { $0.id == hubId }),
              !after.items.isEmpty, let position = before.items.firstIndex(where: { HubShelf.focusKey(hub: before, card: $0) == key })
        else { return }
        let result = FocusFollowKt.followFocus(items: after.items, focused: before.items[position], displaced: displaced)
        let index = result.index >= 0 ? Int(result.index) : min(position, after.items.count - 1)
        let target = HubShelf.focusKey(hub: after, card: after.items[index])
        displaced = result.displaced
        guard target != focus else { return }
        followed = target
        lastFocus = target
        // Focus away (the app in the background, the card gone): the restore puts it back, never off the tab bar.
        if focus != nil { focus = target }
    }
}

extension View {
    /// Which copy a merged Continue Watching row opens (`MediaActions.picker`): a dialog of the copies, each saying what
    /// tells it apart. Identifiers `copyPicker.option.<i>`.
    func copyPicker(app: AppModel) -> some View {
        modifier(CopyPickerDialog(app: app))
    }
}

private struct CopyPickerDialog: ViewModifier {
    let app: AppModel

    @State private var picker: StoreObserver<CopyPicker>?

    func body(content: Content) -> some View {
        let actions = app.session.mediaActions
        let state = picker?.state ?? actions.picker.value
        content
            .confirmationDialog(
                state.title,
                isPresented: Binding(get: { state.shown }, set: { if !$0 { actions.dismiss() } }),
                titleVisibility: .visible
            ) {
                ForEach(Array(state.options.enumerated()), id: \.offset) { index, label in
                    Button(label) { actions.pick(index: Int32(index)) }
                        .accessibilityIdentifier("copyPicker.option.\(index)")
                }
            }
            .task {
                let observer = picker ?? StoreObserver(actions.picker)
                picker = observer
                await observer.observe()
            }
    }
}
