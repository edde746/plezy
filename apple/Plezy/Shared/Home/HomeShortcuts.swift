import SwiftUI
import PlezyKit

/// Home's shortcuts on every Apple platform: under Continue Watching (at the top without
/// it) and above the hubs, in every state of Home (loading, failed, empty), so Home's actions are always reachable. In
/// Compose's order: Live TV (pushed over Home) where a server has it, a chip per visible library in the libraries' order
/// where no sidebar lists them (iPhone, an iPad window of compact width, Apple TV; `libraries`: its kind's symbol, as
/// the sidebar has it, its title and, beside a namesake on another server, its server's name; it opens the library in
/// Libraries, `onOpenLibrary`), Watch Together (with the room's participant count), Downloads (Libraries' Downloads
/// section) where the device keeps them, Server Tasks where they show, Refresh on Apple TV (iPhone and iPad pull to
/// refresh, and ⌘R refreshes wherever Home shows, `HomeView`), and the profile menu (`HomeUserMenu`) on iPhone and Apple
/// TV (iPad and the Mac have it at the sidebar's foot). One line of chips (`ShortcutChip`) from the shelves' leading
/// edge, scrolling sideways; on Apple TV a focus section that lands on its first chip (`firstKey`: Live TV, else the
/// first library, else Watch Together), so Down from Continue Watching and Up from the shelf under it reach it. The row
/// shows whole, once `settled` (`HomeUiState.shortcutsSettled`,
/// at most `wait` after Home opens), its place kept meanwhile and nothing in it shown, focused or read: chips arriving
/// one by one (Live TV before the others, the libraries) would push the row's chips along. Accessibility identifiers
/// `home.shortcuts` (the row), each chip's `home.<action>` and the libraries' `home.library.<i>`.
struct HomeShortcuts: View {
    let app: AppModel
    let focus: FocusState<String?>.Binding
    let libraries: [LibraryShortcutUi]
    let settled: Bool
    let onRefresh: () -> Void
    let onOpenLibrary: (String) -> Void

    /// The row shows: settled, or `wait` gone by.
    @State private var shown: Bool

    @Environment(\.formFactor) private var formFactor
    @Environment(\.screenSides) private var sides
    @Environment(\.dimens) private var dimens
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    init(
        app: AppModel, focus: FocusState<String?>.Binding, libraries: [LibraryShortcutUi], settled: Bool,
        onRefresh: @escaping () -> Void, onOpenLibrary: @escaping (String) -> Void
    ) {
        self.app = app
        self.focus = focus
        self.libraries = libraries
        self.settled = settled
        self.onRefresh = onRefresh
        self.onOpenLibrary = onOpenLibrary
        _shown = State(initialValue: settled)
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: formFactor == .tv ? 16 : 8) {
                if app.shell.state.liveTv {
                    ShortcutChip(title: T.shared.navigation.liveTv, systemImage: "tv", id: "home.liveTv") {
                        app.session.shell.openLiveTv()
                    }
                    .shortcutFocus(focus, Self.liveTvKey)
                }
                ForEach(Array(shownLibraries.enumerated()), id: \.element.globalKey) { index, library in
                    ShortcutChip(
                        title: library.serverName.map { "\(library.title) · \($0)" } ?? library.title,
                        systemImage: library.kind.librarySymbol, id: "home.library.\(index)"
                    ) {
                        onOpenLibrary(library.globalKey)
                    }
                    .shortcutFocus(focus, Self.libraryKey(library.globalKey))
                }
                let room = app.watchToolbar.state
                ShortcutChip(
                    title: room.badge.map { "\(room.label) · \($0)" } ?? room.label,
                    systemImage: room.inSession ? "person.2.fill" : "person.2", id: "home.watchTogether"
                ) {
                    app.navigator.navigate(route: RouteWatchTogether.shared)
                }
                .shortcutFocus(focus, Self.watchTogetherKey)
                if app.session.downloads != nil {
                    ShortcutChip(title: T.shared.navigation.downloads, systemImage: "arrow.down.circle", id: "home.downloads") {
                        app.session.shell.openLibrary(section: .downloads)
                    }
                }
                ServerTasksButton(app: app)
                #if os(tvOS)
                ShortcutChip(title: T.shared.common.refresh, systemImage: "arrow.clockwise", id: "home.refresh", action: onRefresh)
                HomeUserMenu(app: app)
                #else
                if formFactor == .compact { HomeUserMenu(app: app) }
                #endif
            }
            // The chips' glass (26 and later), one row of it, 8 pt apart.
            .glassGroup(spacing: 8)
            .padding(sides.insets)
            // Room for Apple TV's focus or a keyboard's focus ring, which the row doesn't clip.
            .padding(.vertical, dimens.focusRoom)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .clearOfVerticalBar()
        .opacity(shown ? 1 : 0)
        .disabled(!shown)
        .accessibilityHidden(!shown)
        .shelfFocusSection()
        #if os(tvOS)
        .defaultFocus(focus, firstKey, priority: .userInitiated)
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.shortcuts")
        // Restarted as `settled` changes: shown at once once settled, else after `wait`.
        .task(id: settled) {
            guard !shown else { return }
            if !settled { try? await Task.sleep(for: Self.wait) }
            shown = true
        }
    }

    /// The sidebar lists the libraries (`AppShell`): iPad's at regular width and the Mac's, while Libraries shows.
    private var sidebarListsLibraries: Bool {
        guard app.shell.state.destinations.contains(.libraries) else { return false }
        #if os(macOS)
        return true
        #elseif os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
        #else
        return false
        #endif
    }

    /// The libraries the row has a chip for: none where the sidebar lists them.
    private var shownLibraries: [LibraryShortcutUi] { sidebarListsLibraries ? [] : libraries }

    /// The first chip's key in Home's focus: Live TV, else the first library, else Watch Together.
    private var firstKey: String {
        if app.shell.state.liveTv { return Self.liveTvKey }
        if let library = shownLibraries.first { return Self.libraryKey(library.globalKey) }
        return Self.watchTogetherKey
    }

    private static let liveTvKey = "shortcut:liveTv"
    private static let watchTogetherKey = "shortcut:watchTogether"
    private static func libraryKey(_ globalKey: String) -> String { "shortcut:library:\(globalKey)" }

    /// The longest the row waits to show whole: a slow server's answer doesn't keep it empty.
    private static let wait = Duration.seconds(3)
}

/// The running profile's menu on Home where nothing else shows it (a shortcut chip on iPhone and Apple TV; iPad and the
/// Mac have it at the sidebar's foot, `ProfileHeader`): the other profiles (a lock where a PIN guards one), then Manage
/// profiles, Settings and Log out (`UserMenuStore`, which asks before logging out); off while a switch runs.
/// Identifiers `home.userMenu`, its entries `home.userMenu.<i>` and `home.userMenu.<manage|settings|logout>`.
struct HomeUserMenu: View {
    let app: AppModel

    var body: some View {
        let state = app.userMenu.state
        let store = app.session.userMenu
        let name = state.active?.name ?? T.shared.profiles.sectionTitle
        Menu {
            Section {
                ForEach(Array(state.profiles.enumerated()), id: \.offset) { index, profile in
                    Button { store.switchTo(id: profile.id) } label: {
                        Label(profile.name, systemImage: profile.locked ? "lock.fill" : "person.crop.circle")
                    }
                    .accessibilityIdentifier("home.userMenu.\(index)")
                }
            }
            Section {
                ForEach(state.actions, id: \.self) { action in
                    let (probe, symbol) = Self.entry(action)
                    Button(role: action == .logout ? .destructive : nil) { store.act(action: action) } label: {
                        Label(action.label, systemImage: symbol)
                    }
                    .accessibilityIdentifier("home.userMenu.\(probe)")
                }
            }
        } label: {
            ShortcutChipLabel(title: name, systemImage: "person.crop.circle")
        }
        .modifier(ChipStyle())
        .menuIndicator(.hidden)
        .disabled(state.switching)
        .accessibilityLabel(name)
        .accessibilityIdentifier("home.userMenu")
    }

    private static func entry(_ action: UserMenuAction) -> (String, String) {
        switch action {
        case .manageProfiles: ("manage", "person.2")
        case .settings: ("settings", "gearshape")
        case .logout: ("logout", "rectangle.portrait.and.arrow.right")
        }
    }
}

/// One of Home's shortcuts: `ShortcutChipLabel` in the app's chip (`ChipStyle`), which swells under a press.
private struct ShortcutChip: View {
    let title: String
    let systemImage: String
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { ShortcutChipLabel(title: title, systemImage: systemImage) }
            .modifier(ChipStyle())
            .accessibilityLabel(title)
            .accessibilityIdentifier(id)
    }
}

private extension View {
    /// On Apple TV, the chip's `key` in Home's focus, which the row's first focus (`HomeShortcuts.firstKey`) names.
    @ViewBuilder
    func shortcutFocus(_ focus: FocusState<String?>.Binding, _ key: String) -> some View {
        #if os(tvOS)
        focused(focus, equals: key)
        #else
        self
        #endif
    }
}

/// A shortcut chip's label: the symbol before the title (10 pt apart on Apple TV, else 6), one line, in the chips' font
/// (the body on Apple TV, else the subheadline), as the app's chips' labels are (`chipLabel`).
struct ShortcutChipLabel: View {
    let title: String
    let systemImage: String

    @Environment(\.formFactor) private var formFactor

    var body: some View {
        HStack(spacing: formFactor == .tv ? 10 : 6) {
            Image(systemName: systemImage).accessibilityHidden(true)
            Text(title).chipName(maxWidth: ChipMetrics.maxNameWidth(formFactor))
        }
        .chipLabel(formFactor)
    }
}

/// Home's Server Tasks (`AppSession.serverTasks`): on the Mac and Apple TV (and in TV mode), while a Plex server is
/// online, a shortcut chip that opens the servers' running tasks (`ServerTasksPanel`): a popover under it, on Apple TV a
/// `TrailingPanel`. Leaving Home closes it (`HomeView`). Identifier `home.serverTasks`.
struct ServerTasksButton: View {
    let app: AppModel

    var body: some View {
        let state = app.serverTasks.state
        let store = app.session.serverTasks
        let open = Binding(get: { app.serverTasks.state.open }, set: { if !$0 { store.close() } })
        let panel = {
            ServerTasksPanel(state: app.serverTasks.state) { server, uuid in store.cancel(serverId: server, uuid: uuid) }
        }
        Group {
            if state.shown {
                let chip = ShortcutChip(title: T.shared.serverTasks.title, systemImage: "waveform.path.ecg.rectangle", id: "home.serverTasks") {
                    store.toggle()
                }
                #if os(tvOS)
                chip.appSheet(isPresented: open, id: "home.serverTasks.sheet", size: .panel, content: panel)
                #else
                chip.popover(isPresented: open, arrowEdge: .bottom, content: panel)
                #endif
            }
        }
    }
}

/// The Server Tasks: the title over Loading…, Failed to load tasks, No tasks running, or each server's tasks under its
/// name and their count: a task's title, subtitle and progress, and ✕ where it can be cancelled. In a popover 320 wide,
/// scrolling past 360 tall. Identifiers `home.serverTasks.panel`, `home.serverTasks.cancel.<uuid>`.
private struct ServerTasksPanel: View {
    let state: ServerTasksUiState
    let onCancel: (String, String) -> Void

    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        VStack(alignment: .leading, spacing: 0) {
            Label(T.shared.serverTasks.title, systemImage: "waveform.path.ecg.rectangle")
                .font(.headline)
                .padding(.horizontal, 16 * unit)
                .padding(.vertical, 10 * unit)
                .accessibilityAddTraits(.isHeader)
            Divider()
            ViewThatFits(in: .vertical) {
                content(unit)
                ScrollView(.vertical) { content(unit) }
            }
            #if !os(tvOS)
            .frame(maxHeight: 360 * unit)
            #endif
        }
        #if os(tvOS)
        .padding(.top, 48)
        .frame(maxHeight: .infinity, alignment: .top)
        // Nothing to focus without a task to cancel: the panel holds focus, so the remote's Menu closes it.
        .holdsBackFocus(!state.groups.contains { $0.tasks.contains(where: \.cancellable) })
        #else
        .frame(width: 320 * unit)
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.serverTasks.panel")
    }

    @ViewBuilder
    private func content(_ unit: CGFloat) -> some View {
        let notice = { (text: String) in
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Palette.onSurfaceVariant)
                .frame(maxWidth: .infinity)
                .padding(24 * unit)
        }
        switch state.load {
        case .loading:
            notice(T.shared.common.loading)
        case .error:
            VStack(spacing: 8 * unit) {
                Image(systemName: "exclamationmark.circle").foregroundStyle(Palette.error)
                Text(T.shared.serverTasks.failedToLoad).font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(24 * unit)
        case .content:
            if state.groups.isEmpty {
                notice(T.shared.serverTasks.noTasks)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(state.groups, id: \.serverId) { group in
                        HStack(spacing: 6 * unit) {
                            Text(group.name.uppercased())
                                .font(.caption2.weight(.medium))
                                .kerning(0.8)
                                .foregroundStyle(Palette.onSurfaceVariant)
                            Text("\(group.tasks.count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Palette.background)
                                .padding(.horizontal, 6 * unit)
                                .padding(.vertical, 1 * unit)
                                .background(Palette.onBackground, in: Capsule())
                        }
                        .padding(EdgeInsets(top: 12 * unit, leading: 16 * unit, bottom: 4 * unit, trailing: 16 * unit))
                        ForEach(group.tasks, id: \.uuid) { task in
                            TaskRow(task: task, unit: unit) { onCancel(group.serverId, task.uuid) }
                        }
                    }
                    Spacer().frame(height: 8 * unit)
                }
                #if os(tvOS)
                .focusSection()
                #endif
            }
        }
    }
}

/// A task: its title (medium), its subtitle (60 %), its progress as a 4 tall bar, and ✕ where it can be cancelled.
private struct TaskRow: View {
    let task: PlexActivity
    let unit: CGFloat
    let onCancel: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 2 * unit) {
                Text(task.title).font(.caption.weight(.medium)).lineLimit(1)
                if let subtitle = task.subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(Palette.onSurfaceVariant).lineLimit(1)
                }
                GeometryReader { bar in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.onBackground.opacity(0.15))
                        Capsule().fill(Palette.primary).frame(width: bar.size.width * CGFloat(min(max(task.progress, 0), 100)) / 100)
                    }
                }
                .frame(height: 4 * unit)
                .padding(.top, 4 * unit)
                .accessibilityValue("\(task.progress) %")
            }
            .foregroundStyle(Palette.onBackground)
            .frame(maxWidth: .infinity, alignment: .leading)
            if task.cancellable {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12 * unit, weight: .semibold))
                        #if !os(tvOS)
                        .foregroundStyle(Palette.onBackground)
                        #endif
                        .frame(width: 32 * unit, height: 32 * unit)
                }
                // A round surface: on Apple TV white with a dark ✕ while focused.
                .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: 16 * unit))
                .accessibilityLabel(T.shared.common.cancel)
                .accessibilityIdentifier("home.serverTasks.cancel.\(task.uuid)")
            }
        }
        .padding(EdgeInsets(top: 8 * unit, leading: 16 * unit, bottom: 4 * unit, trailing: 8 * unit))
    }
}
