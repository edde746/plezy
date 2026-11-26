import SwiftUI
import PlezyKit

#if !os(tvOS)
/// The sidebar (the Mac; iPad before iOS 18): the destinations, then Libraries' libraries (the visible ones, under their
/// servers' names where the list groups them by server (`railSections`), then a collapsed Hidden libraries group, which
/// a click on its title opens or closes as one on its chevron does; a library shows Libraries with it selected), and at
/// its bottom the offline or refused-account line and the running profile (`ProfileHeader`). The libraries stand for
/// Libraries, which has no row of its own; Downloads has its row among the destinations where the device keeps them,
/// offline beside Settings alone. The selected row is the one the screen on top
/// belongs to (`AppShell.selectionBinding`); a click on it picks it again (its stack back to its root, or out to it
/// from a screen pushed elsewhere). On the Mac the rows are buttons, the selected one drawn as the list's selection is,
/// and the list has no selection of its own: the split view takes a change of its sidebar list's selection as a
/// navigation and empties the detail column's path, and a page opened from one destination can move the highlight to
/// another's row (a movie opened from Search highlights Movies), which closed the page as it opened.
struct Sidebar: View {
    let app: AppModel
    let destinations: [TopLevelDestination]
    let libraries: StoreModel<LibrariesScreenStore, LibrariesUiState>?
    @Binding var selection: ShellTab
    /// The Mac's player covers the window (`AppShell`): the list goes meanwhile, as AppKit's outline would otherwise
    /// stay in the window's Tab order, disabled or not, and take Tab away from the player's controls.
    var covered = false

    @State private var hiddenOpen = false
    #if os(macOS)
    /// The list has the keyboard's focus (a click on a row, Tab), where Up and Down pick the row before or after the
    /// selected one, as a selecting list's arrows do.
    @FocusState private var listFocused: Bool
    #endif

    var body: some View {
        // The list scrolls above the pinned footer (a short window's list ends at it, nothing draws under it).
        VStack(spacing: 0) {
            if covered {
                Spacer(minLength: 0)
            } else {
                list
            }
            VStack(alignment: .leading, spacing: 12) {
                ShellNoticeLine(app: app, compact: true)
                ProfileHeader(app: app)
                    .padding(.leading, 19)
                    .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    private var list: some View {
        #if os(macOS)
        List { listRows }
            .focusable()
            .focusEffectDisabled()
            .focused($listFocused)
            .onKeyPress(keys: [.upArrow, .downArrow]) { press in
                step(press.key == .downArrow ? 1 : -1)
                return .handled
            }
        #else
        List(selection: Binding(get: { selection }, set: { if let tab = $0 { selection = tab } })) { listRows }
        #endif
    }

    #if os(macOS)
    /// Picks the row `by` rows after the selected one (before, when negative), stopping at the first and the last: the
    /// destinations', then the libraries' as listed, the hidden ones while their group is open.
    private func step(_ by: Int) {
        var tabs = rows.map { ShellTab.destination($0) }
        if let libraries, destinations.contains(.libraries) {
            let state = libraries.state.state
            tabs += state.railSections(hiddenOnes: false).flatMap { $0.rows }.map { .library($0.library.globalKey) }
            if hiddenOpen {
                tabs += state.railEntries(hiddenOnes: true).compactMap(\.libraryRow).map { .library($0.library.globalKey) }
            }
        }
        guard !tabs.isEmpty else { return }
        let next = tabs.firstIndex(of: selection).map { min(max($0 + by, 0), tabs.count - 1) } ?? 0
        if tabs[next] != selection { selection = tabs[next] }
    }
    #endif

    @ViewBuilder
    private var listRows: some View {
        Section {
            ForEach(rows, id: \.self) { destination in
                row(Label(destination.label, systemImage: destination.systemImage), tab: .destination(destination))
                    .accessibilityIdentifier(destination.accessibilityId)
            }
        }
        if let libraries, destinations.contains(.libraries) {
            let state = libraries.state.state
            let sections = state.railSections(hiddenOnes: false)
            // No Libraries heading over nothing (libraries still loading, or none); Hidden libraries alone go under one.
            let shown = sections.isEmpty && !state.hidden.isEmpty ? [(heading: String?.none, rows: [LibraryListEntryRow]())] : sections
            ForEach(Array(shown.enumerated()), id: \.offset) { index, section in
                Section(section.heading ?? T.shared.libraries.title) {
                    ForEach(section.rows, id: \.library.globalKey) { row in
                        libraryLabel(row)
                    }
                    if index == shown.count - 1, !state.hidden.isEmpty {
                        DisclosureGroup(isExpanded: $hiddenOpen) {
                            ForEach(state.railEntries(hiddenOnes: true).compactMap(\.libraryRow), id: \.library.globalKey) { row in
                                libraryLabel(row)
                            }
                        } label: {
                            // A click on the title opens or closes the group, as one on its chevron does; the keys and
                            // VoiceOver open and close it as the group's.
                            Button {
                                withAnimation { hiddenOpen.toggle() }
                            } label: {
                                Text(T.shared.libraries.hiddenLibrariesCount(count: String(state.hidden.count)))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("nav.hiddenLibraries")
                        }
                    }
                }
            }
        }
    }

    /// A row picking `tab`: on the Mac a button, drawn selected while `tab` is the selection; elsewhere the list's row,
    /// which the list reports only on a change of selection, so a click on the selected row picks it again here.
    private func row(_ label: Label<Text, Image>, tab: ShellTab) -> some View {
        #if os(macOS)
        let selected = selection == tab
        return Button {
            listFocused = true
            selection = tab
        } label: {
            label.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The Mac draws sidebar icons in the system accent colour; the palette's own instead: the row's tint.
        .listItemTint(Palette.onBackground)
        // The list's selection colours: emphasized while the list has the keyboard.
        .listRowBackground(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(selected ? Color(nsColor: listFocused ? .selectedContentBackgroundColor : .unemphasizedSelectedContentBackgroundColor) : .clear)
                .padding(.horizontal, 10)
        )
        .accessibilityAddTraits(selected ? .isSelected : [])
        #else
        return label
            .listItemTint(Palette.onBackground)
            .tag(tab)
            .simultaneousGesture(TapGesture().onEnded {
                if selection == tab { selection = tab }
            })
        #endif
    }

    /// The destinations' rows: Libraries' only where no libraries stand for it (no libraries' store).
    private var rows: [TopLevelDestination] {
        guard libraries != nil else { return destinations }
        return destinations.filter { $0 != .libraries }
    }

    private func libraryLabel(_ row: LibraryListEntryRow) -> some View {
        self.row(Label(row.library.title, systemImage: row.library.kind.librarySymbol), tab: .library(row.library.globalKey))
            .accessibilityIdentifier("nav.library.\(row.library.title)")
            // A name the column's width cuts short shows whole on hover.
            .help(row.library.title)
    }
}
#endif

#if os(iOS)
/// The running profile in iPad's sidebar bottom bar, which centres what it holds: only its drawing moves, to the
/// destinations' icons, so the bar lays out exactly as it does around the bare profile (a layout placing it at the
/// bar's edge kept the sidebar laying out without end).
struct SidebarBarProfile: View {
    let app: AppModel

    /// Where the bar placed the profile's leading edge, on screen.
    @State private var placed: CGFloat?

    /// The destinations' icons' leading edge, from the sidebar's.
    private static let iconInset: CGFloat = 33

    var body: some View {
        ProfileHeader(app: app)
            .padding(.trailing, Self.iconInset + 16)
            .offset(x: placed.map { Self.iconInset - $0 } ?? 0)
            // Read outside the offset: the place the bar gave it, which the offset doesn't move.
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minX } action: { placed = $0 }
            .padding(.bottom, 32)
    }
}
#endif

/// The running profile's avatar and name at the sidebar's foot (iPad, the Mac): a menu of the other profiles (a lock
/// where a PIN guards one), then Manage profiles, Settings and Log out (`UserMenuStore`); off while a switch runs.
/// Identifiers `nav.profile`, its entries `nav.profile.<i>`, `nav.profile.<manage|settings|logout>`.
struct ProfileHeader: View {
    let app: AppModel

    /// The avatar's side: 32 pt at the default text size, following Dynamic Type as the name beside it does.
    @ScaledMetric(relativeTo: .headline) private var avatarSide: CGFloat = 32

    init(app: AppModel) {
        self.app = app
    }

    var body: some View {
        let state = app.userMenu.state
        let store = app.session.userMenu
        // A divider between the groups, not sections: a menu's section drops its entries' accessibility identifiers.
        Menu {
            ForEach(Array(state.profiles.enumerated()), id: \.offset) { index, profile in
                Button { store.switchTo(id: profile.id) } label: {
                    Label(profile.name, systemImage: profile.locked ? "lock.fill" : "person.crop.circle")
                }
                .accessibilityIdentifier("nav.profile.\(index)")
            }
            if !state.profiles.isEmpty { Divider() }
            ForEach(state.actions, id: \.self) { action in
                let (probe, symbol) = Self.entry(action)
                Button(role: action == .logout ? .destructive : nil) { store.act(action: action) } label: {
                    Label(action.label, systemImage: symbol)
                }
                .accessibilityIdentifier("nav.profile.\(probe)")
            }
        } label: {
            HStack(spacing: 10) {
                if let active = state.active {
                    ProfileAvatar(name: active.name, url: active.avatarUrl, size: avatarSide)
                    Text(active.name).font(.headline).lineLimit(1)
                } else {
                    Image(systemName: "person.crop.circle.fill").font(.system(size: avatarSide - 2))
                    Text(T.shared.profiles.sectionTitle).font(.headline).lineLimit(1)
                }
            }
            .foregroundStyle(Palette.onBackground)
            .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .disabled(state.switching)
        .accessibilityLabel(state.active?.name ?? T.shared.profiles.sectionTitle)
        .accessibilityIdentifier("nav.profile")
    }

    private static func entry(_ action: UserMenuAction) -> (String, String) {
        switch action {
        case .manageProfiles: ("manage", "person.2")
        case .settings: ("settings", "gearshape")
        case .logout: ("logout", "rectangle.portrait.and.arrow.right")
        }
    }
}

/// The line over the screens while the app is offline (Reconnect) or a server refuses the account (Sign in again for a
/// rejected token; nothing to do for a refused account): its symbol in the error colour and its words in the text
/// colour on the raised surface; nothing otherwise. Across the top of the screens on iPhone, iPad and Apple TV, at the
/// sidebar's foot on the Mac (`compact`). Identifiers `offline.reconnect`, `app.authBanner.expired`, `.denied`,
/// `.signIn`.
struct ShellNoticeLine: View {
    let app: AppModel
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if app.shell.state.offline {
                let reconnecting = app.reconnect.state.reconnecting
                row(systemImage: "icloud.slash", text: T.shared.downloads.syncRuleOffline, id: "shell.offline") {
                    Button(T.shared.common.reconnect) { app.session.reconnect.reconnect() }
                        .disabled(reconnecting)
                        .accessibilityIdentifier("offline.reconnect")
                }
            }
            if let state = app.authErrorBanner.state {
                if let expired = state.sessionExpired {
                    row(systemImage: "lock.fill", text: expired, id: "app.authBanner.expired") {
                        // Not again while the expired server's sign-in is open below.
                        if state.signInAgain {
                            Button(T.shared.connections.signInAgain) { app.session.signInAgain() }
                                .accessibilityIdentifier("app.authBanner.signIn")
                        }
                    }
                }
                if let denied = state.accessDenied {
                    row(systemImage: "nosign", text: denied, id: "app.authBanner.denied") { EmptyView() }
                }
            }
        }
        #if os(tvOS)
        // Up from the screen below reaches the line's button.
        .focusSection()
        #endif
    }

    private func row(systemImage: String, text: String, id: String, @ViewBuilder action: () -> some View) -> some View {
        let label = Label {
            Text(text).foregroundStyle(Palette.onBackground).accessibilityIdentifier(id)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(Palette.error)
        }
        .font(.footnote)
        .lineLimit(2)
        return Group {
            if compact {
                VStack(alignment: .leading, spacing: 6) {
                    label
                    action().controlSize(.small)
                }
                .padding(.horizontal, 19)
            } else {
                HStack(spacing: 12) {
                    label.frame(maxWidth: .infinity, alignment: .leading)
                    action()
                        #if os(iOS)
                        .glassButtonStyle()
                        .controlSize(.small)
                        #endif
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Palette.surfaceContainerHigh.ignoresSafeArea(edges: .top))
            }
        }
        .accessibilityElement(children: .contain)
    }
}

extension View {
    /// What the profile menu shows over the app: "Switching profile…" while a switch runs, Log out's question, a failed
    /// switch's message (a toast in the band `relay` names). Identifier `nav.switching`.
    func userMenuNotices(_ app: AppModel, relay: ToastRelay) -> some View {
        modifier(UserMenuNotices(app: app, relay: relay))
    }
}

private struct UserMenuNotices: ViewModifier {
    let app: AppModel
    let relay: ToastRelay

    func body(content: Content) -> some View {
        let state = app.userMenu.state
        let store = app.session.userMenu
        content
            .overlay {
                if state.switching {
                    ZStack {
                        Palette.background.opacity(0.85).ignoresSafeArea()
                        ProgressView(T.shared.profiles.switchingProfile)
                    }
                    .accessibilityIdentifier("nav.switching")
                }
            }
            .confirmation(state.confirm?.dialog, onConfirm: { store.confirm() }, onCancel: { store.dismissConfirm() })
            .toast(state.message, id: "nav.profile.message", in: relay) { store.messageShown() }
    }
}
