import SwiftUI
import PlezyKit

/// The Watch Together screen (`Route.WatchTogether`) over the active profile's store (`AppSession.watchTogether`, kept
/// while the route is on a stack); nothing without a profile.
struct WatchTogetherRoute: View {
    let app: AppModel

    @State private var model: (store: WatchTogetherStore, state: StoreObserver<WatchTogetherUiState>)?

    init(app: AppModel, route: any Route) {
        self.app = app
        if let store = app.session.watchTogether(route: route) {
            _model = State(initialValue: (store, StoreObserver(store.state)))
        }
    }

    var body: some View {
        if let model {
            WatchTogetherScreen(state: model.state.state, store: model.store, observer: model.state)
                .task { await model.state.observe() }
        }
    }
}

/// The Watch Together screen, a form within the readable column: the lobby, the connecting view or the room
/// (`WatchTogetherUiState.content`), and the join sheet while it is open. On Apple TV the room's code card stands beside
/// the form of the rest of the room (`WatchRoomCode`), so the very large code leaves every control of the room in view as
/// it opens. Focus starts on the view's first control (Create Room, Cancel; in a room Copy Code, on Apple TV the code's
/// card, as Apple TV has no pasteboard) and goes there again as the view changes. The remote's Menu and Escape close a
/// question, then a sheet, then the screen (the room goes on). What a control did ("Room code copied") and the store's
/// messages show as a toast (`watch.toast`).
///
/// Accessibility identifiers: `watch.screen`, the lobby's `watch.error`, `watch.create`, `watch.join`, `watch.relay`,
/// `watch.recent.<code>` (its menu `watch.recent.<code>.menu`, entries `.rename`, `.remove`), the connecting view's
/// `watch.connecting`, `watch.cancel`, the room's (`WatchRoomParts`; on Apple TV the code's card `watch.header`) and
/// `watch.leave`, `watch.end`.
struct WatchTogetherScreen: View {
    let state: WatchTogetherUiState
    let store: WatchTogetherStore
    let observer: StoreObserver<WatchTogetherUiState>

    @State private var toast: String?
    /// The page of the room open as a sheet (a participant's actions, the copies).
    @State private var page: WatchPage?
    @FocusState private var focus: WatchScreenFocus?

    var body: some View {
        layout
            // The lobby's hero names the screen: the bar shows no second title.
            .pageTitle(state.title, inContent: inLobby)
            .accessibilityIdentifier("watch.screen")
            .toast(toast, id: "watch.toast") { toast = nil }
            .appSheet(isPresented: Binding(get: { state.join != nil }, set: { if !$0 { store.closeJoin() } })) {
                WatchJoinSheet(observer: observer, store: store)
            }
            .appSheet(item: roomPage, onDismiss: { page = nil }) { open in
                if case .room(let room) = onEnum(of: observer.state.content) {
                    WatchPageSheet(page: open, room: room.room, actions: roomActions) { page = nil }
                }
            }
            .task { for await message in store.messages { toast = message } }
            // A view in another's place (the lobby's Create Room for the room's code) moves focus off what went, which
            // the focus state can still name: the new view's first control replaces it.
            .task(id: focusTarget) { await FocusRestore.restore($focus, to: focusTarget, replacing: true) }
    }

    /// The view's form; on Apple TV in a room, the code's card in a column of its own beside it.
    @ViewBuilder
    private var layout: some View {
        #if os(tvOS)
        if case .room(let room) = onEnum(of: state.content) {
            HStack(alignment: .top, spacing: 40) {
                Form { WatchRoomCode(room: room.room, actions: roomActions, focus: $focus) }
                    .settingsForm()
                    .frame(width: 720)
                Form { WatchRoom(room: room.room, actions: roomActions, focus: $focus) }
                    .settingsForm()
            }
        } else {
            form
        }
        #else
        form
        #endif
    }

    private var form: some View {
        Form {
            switch onEnum(of: state.content) {
            case .lobby(let lobby):
                WatchLobby(lobby: lobby.lobby, title: state.title, store: store, focus: $focus)
            case .connecting(let connecting):
                Section {
                    VStack(spacing: 24) {
                        ProgressView().controlSize(.large)
                        Text(connecting.label)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("watch.connecting")
                        WatchButton(title: connecting.cancel, systemImage: "xmark", id: "watch.cancel", action: store.cancel)
                            .focused($focus, equals: .cancel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                }
                .listRowBackground(Color.clear)
            case .room(let room):
                WatchRoom(room: room.room, actions: roomActions, focus: $focus)
            }
        }
        .settingsForm()
    }

    /// The open page while in a room: out of it the sheet closes.
    private var roomPage: WatchPage? {
        if case .room = onEnum(of: state.content) { page } else { nil }
    }

    /// The lobby shows, its hero naming the screen.
    private var inLobby: Bool {
        if case .lobby = onEnum(of: state.content) { true } else { false }
    }

    /// The view's first control, which takes focus as the view shows (with a keyboard or remote; touch has none).
    private var focusTarget: WatchScreenFocus? {
        switch onEnum(of: state.content) {
        case .lobby: .create
        case .connecting: .cancel
        case .room: .code
        }
    }

    private var roomActions: WatchRoomActions {
        WatchRoomActions(
            execute: { store.execute(command: $0) },
            copy: { text, done in
                Pasteboard.copy(text)
                toast = done
            },
            open: { page = $0 }
        )
    }
}

/// What takes focus on the screen: each view's first control.
enum WatchScreenFocus: Hashable {
    case create
    case cancel
    case code
}

/// The lobby: the group symbol, the title and what the screen is for; the last create's or recent join's failure;
/// Create Room ("Creating room…" with a spinner while it runs) and Join Room, both off while any attempt runs; the
/// relays rooms use; the profile's recent rooms on them. On a short screen (iPhone on its side) the title sits beside
/// the buttons, a smaller symbol above it, the failure under the buttons in their column: stacked, the buttons would
/// start under the floating tab bar, and a failure in a row of its own would.
private struct WatchLobby: View {
    let lobby: WatchLobbyUi
    let title: String
    let store: WatchTogetherStore
    let focus: FocusState<WatchScreenFocus?>.Binding

    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    var body: some View {
        if short {
            Section {
                HStack(spacing: 24) {
                    hero(symbolSize: 36)
                    VStack(spacing: 12) {
                        buttons
                        if let error = lobby.error { errorLine(error) }
                    }
                }
            } footer: {
                relay
            }
            .listRowBackground(Color.clear)
        } else {
            Section {
                hero(symbolSize: 56).padding(.top, 16)
            }
            .listRowBackground(Color.clear)
            error
            Section {
                buttons
            } footer: {
                relay
            }
            .listRowBackground(Color.clear)
        }
        if !lobby.recentRooms.isEmpty {
            Section(lobby.recentTitle) {
                ForEach(lobby.recentRooms, id: \.code) { room in
                    WatchRecentRoomRow(room: room, labels: lobby.recentActions, busy: lobby.busy, store: store)
                }
            }
        }
    }

    /// A screen too short for the title above the buttons: iPhone on its side.
    private var short: Bool {
        #if os(iOS)
        verticalSizeClass == .compact
        #else
        false
        #endif
    }

    private func hero(symbolSize: CGFloat) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .font(.system(size: symbolSize))
                .foregroundStyle(Palette.primary)
                .accessibilityHidden(true)
                .padding(.bottom, 8)
            PageHeading(title: title, id: "watch.lobby.title")
            Text(lobby.description_)
                .foregroundStyle(Palette.onSurfaceVariant)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var error: some View {
        if let error = lobby.error {
            Section { errorLine(error) }
        }
    }

    private func errorLine(_ error: String) -> some View {
        ErrorLine(text: error)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("watch.error")
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            WatchButton(
                title: lobby.create, systemImage: "plus", id: "watch.create", prominence: .primary, fullWidth: true,
                enabled: !lobby.busy, busy: lobby.creating, action: store.create
            )
            .focused(focus, equals: .create)
            WatchButton(title: lobby.join, systemImage: "person.badge.plus", id: "watch.join", fullWidth: true, enabled: !lobby.busy, action: store.openJoin)
        }
        .frame(maxWidth: .infinity)
    }

    private var relay: some View {
        Text(lobby.relay)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier("watch.relay")
    }
}

/// A recent room: Select joins it (or makes it again), off while any attempt runs; its ⋯ (not on Apple TV), a long
/// press, a held Select or a right click open its actions, Rename Room and Remove.
private struct WatchRecentRoomRow: View {
    let room: RecentRoomUi
    let labels: RecentRoomActionsUi
    let busy: Bool
    let store: WatchTogetherStore

    @State private var renaming = false

    var body: some View {
        let id = "watch.recent.\(room.code)"
        let entries = [
            ItemMenuEntry(label: labels.rename, systemImage: "pencil", id: "\(id).rename") { renaming = true },
            ItemMenuEntry(label: labels.remove, systemImage: "trash", id: "\(id).remove", destructive: true) {
                store.removeRecent(code: room.code)
            },
        ]
        HStack(spacing: 12) {
            Button {
                store.joinRecent(code: room.code)
            } label: {
                HStack(spacing: 16) {
                    Group {
                        if room.joining { ProgressView() } else { Image(systemName: "door.left.hand.open") }
                    }
                    .frame(width: 28)
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(room.title).lineLimit(1)
                        if let subtitle = room.subtitle {
                            Text(subtitle).font(.footnote.monospaced()).mutedForeground()
                        }
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.primary)
                .contentShape(Rectangle())
            }
            .formRowButtonStyle()
            .disabled(busy)
            .accessibilityIdentifier(id)
            .accessibilityActions(entries)
            .itemMenu(entries: entries, probe: "\(id).menu")
            #if !os(tvOS)
            ItemMenuButton(label: labels.menuLabel, entries: entries, probe: "\(id).menu")
            #endif
        }
        .appSheet(isPresented: $renaming) {
            WatchRenameSheet(room: room, labels: labels) { name in
                renaming = false
                if let name { store.renameRecent(code: room.code, name: name) }
            }
        }
    }
}

/// Rename Room: the field (the name, the code as its placeholder) has focus; Return saves; a blank name clears the name.
/// Accessibility identifiers `watch.rename.field`, `watch.rename.cancel`, `watch.rename.save`.
private struct WatchRenameSheet: View {
    let room: RecentRoomUi
    let labels: RecentRoomActionsUi
    /// The name to save, or nil for Cancel.
    let onDone: (String?) -> Void

    @State private var text: String
    @FocusState private var fieldFocused: Bool

    init(room: RecentRoomUi, labels: RecentRoomActionsUi, onDone: @escaping (String?) -> Void) {
        self.room = room
        self.labels = labels
        self.onDone = onDone
        _text = State(initialValue: room.name)
    }

    var body: some View {
        let save = SheetAction(title: labels.save, id: "watch.rename.save") { onDone(text) }
        let cancel = SheetAction(title: labels.cancel, id: "watch.rename.cancel") { onDone(nil) }
        SheetPage(title: labels.renameTitle, cancel: cancel, confirm: save) {
            Form {
                Section {
                    TextField(labels.renameTitle, text: $text, prompt: Text(room.hint))
                        .labelsHidden()
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(save.action)
                        .focused($fieldFocused)
                        .accessibilityIdentifier("watch.rename.field")
                        .formFieldRow()
                }
                SheetActionsSection(actions: [save, cancel])
            }
            .settingsForm()
        }
        .backAction(cancel.action)
        .onAppear { fieldFocused = true }
    }
}

/// Join Room: what to enter, the code field (`#` before it; `K7M-Q2X` as the store formats what is typed), its error,
/// Cancel and Join. Return or the keyboard's Join joins. While joining the field and Join are off and Join reads
/// "Joining room…"; Cancel, a swipe down, Escape or Menu close the sheet, cancelling the join. The sheet closes itself
/// once joined. Accessibility identifiers `watch.join.field`, `watch.join.error`, `watch.join.cancel`,
/// `watch.join.submit`.
private struct WatchJoinSheet: View {
    let observer: StoreObserver<WatchTogetherUiState>
    let store: WatchTogetherStore

    /// The field's text as shown: what was typed, then the store's formatting of it once typing pauses.
    @State private var text = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        if let join = observer.state.join ?? store.state.value.join {
            let submit = SheetAction(title: join.join, id: "watch.join.submit", enabled: !join.joining, action: store.submitJoin)
            let cancel = SheetAction(title: join.cancel, id: "watch.join.cancel", action: store.closeJoin)
            SheetPage(title: join.title, cancel: cancel, confirm: submit) {
                Form {
                    Section {
                        HStack(spacing: 12) {
                            #if !os(tvOS)
                            // Apple TV's field fills its row: no symbol beside it.
                            Image(systemName: "number").mutedForeground().accessibilityHidden(true)
                            #endif
                            TextField(join.fieldLabel, text: $text, prompt: Text(join.hint))
                                .labelsHidden()
                                .font(.title3.monospaced())
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.characters)
                                .keyboardType(.asciiCapable)
                                #endif
                                .submitLabel(.join)
                                .onSubmit {
                                    // The code first: the `onChange` of the last key typed can run after the submit.
                                    store.editJoin(text: text, caret: Int32(text.utf16.count))
                                    store.submitJoin()
                                }
                                .focused($fieldFocused)
                                .disabled(join.joining)
                                .accessibilityIdentifier("watch.join.field")
                        }
                        .formFieldRow()
                    } header: {
                        Text(join.prompt).textCase(nil)
                    } footer: {
                        if let error = join.error {
                            Text(error).foregroundStyle(Palette.error).accessibilityIdentifier("watch.join.error")
                        }
                    }
                    SheetActionsSection(actions: [submit, cancel])
                }
                .settingsForm()
            }
            .backAction(cancel.action)
            .onAppear {
                text = join.text
                fieldFocused = true
            }
            // The store takes each edit at once (its error clears, Join reads it); the field shows the store's formatting
            // of it (`K7M-Q2X`) once typing pauses: replacing the text under a key being typed loses that key.
            .onChange(of: text) { _, typed in
                store.editJoin(text: typed, caret: Int32(typed.utf16.count))
            }
            .task(id: text) {
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled, let formatted = store.state.value.join?.text, formatted != text else { return }
                text = formatted
            }
        }
    }
}

/// The room: the reconnecting banner, the code (`WatchRoomCode`; on Apple TV beside the room's form, not in it), the
/// media and this user's copy, the offset (with media), the participants (the host opens another's actions in a sheet),
/// the host's settings, then Leave Room and the host's End Room, each asked first.
private struct WatchRoom: View {
    let room: WatchRoomUi
    let actions: WatchRoomActions
    let focus: FocusState<WatchScreenFocus?>.Binding

    var body: some View {
        if let banner = room.reconnecting {
            Section { WatchReconnectingBanner(banner: banner) }.listRowBackground(Color.clear)
        }
        #if !os(tvOS)
        WatchRoomCode(room: room, actions: actions, focus: focus)
        #endif
        Section {
            WatchMediaSection(media: room.media, actions: actions).padding(.vertical, 4)
        }
        if room.media.title != nil {
            Section {
                WatchOffsetSection(offset: room.offset, actions: actions).padding(.vertical, 4)
            }
        }
        Section {
            ForEach(room.participants, id: \.peerId) { participant in
                WatchParticipantRow(participant: participant, onOpen: participant.actions.map { _ in { actions.open(.participant(participant.peerId)) } })
            }
        } header: {
            Text(room.participantsTitle)
        }
        if let settings = room.settings {
            Section(settings.title) {
                WatchHostSettings(settings: settings, actions: actions)
            }
        }
        Section {
            WatchButtonRow(centred: true) {
                WatchConfirmButton(confirm: room.leave, systemImage: "rectangle.portrait.and.arrow.right", id: "watch.leave") {
                    actions.execute(WatchCommandLeave.shared)
                }
                if let end = room.end {
                    WatchConfirmButton(confirm: end, systemImage: "xmark.circle", id: "watch.end") {
                        actions.execute(WatchCommandEnd.shared)
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
    }
}

/// The room's code and who runs it (`WatchRoomHeader`), a section of the room's form. Apple TV has no pasteboard, so no
/// Copy Code: the code's card takes focus and turns white with it as a focused row does.
private struct WatchRoomCode: View {
    let room: WatchRoomUi
    let actions: WatchRoomActions
    let focus: FocusState<WatchScreenFocus?>.Binding

    var body: some View {
        Section {
            #if os(tvOS)
            let codeFocused = focus.wrappedValue == .code
            WatchRoomHeader(header: room.header, actions: actions)
                .padding(.vertical, 8)
                .foregroundStyle(codeFocused ? Palette.onFocusedSurface : Palette.onBackground)
                .focusable()
                .focused(focus, equals: .code)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("watch.header")
                .listRowBackground(codeFocused ? RoundedRectangle(cornerRadius: Radius.large, style: .continuous).fill(Palette.focusedSurface) : nil)
            #else
            WatchRoomHeader(header: room.header, actions: actions, focus: focus)
                .padding(.vertical, 8)
            #endif
        }
    }
}

extension View {
    /// The room's notices ("Sam joined"), app-wide: a toast each in the band `relay` names, the next replacing the one
    /// showing (`watch.notice`). Not while the player is on top, which shows them as its own messages.
    func watchNotices(_ app: AppModel, relay: ToastRelay) -> some View {
        modifier(WatchNotices(app: app, relay: relay))
    }
}

private struct WatchNotices: ViewModifier {
    let app: AppModel
    let relay: ToastRelay

    @State private var notice: String?

    func body(content: Content) -> some View {
        content
            .toast(notice, id: "watch.notice", in: relay) { notice = nil }
            .task {
                for await text in app.session.watchNotices {
                    if !(app.backStack.last is RoutePlayer) { notice = text }
                }
            }
    }
}
