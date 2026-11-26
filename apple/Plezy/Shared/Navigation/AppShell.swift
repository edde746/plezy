import SwiftUI
import PlezyKit

/// The running app: the navigation chrome over the shared navigator's back stacks, each route drawn by `RouteView` in a
/// `RouteStack`, the chrome's destinations those the shell shows (`ShellStore`: which show, online or not; a pick goes
/// through `select`).
///
/// The destinations (`TopLevelDestination`) are the system's tabs. Each has a back stack of its own (`NavigationStacks`),
/// which its tab shows in a `NavigationStack` and keeps while another tab shows:
///
/// - iPhone: the tab bar, which names the destination: its screen shows no navigation bar (`destinationChrome`). Online
///   the bar leaves Downloads out (`NavigationTabs.bar`): Home's Downloads chip opens it, its tab in the bar while it
///   shows.
/// - iPad: the floating tab bar, which opens into a sidebar listing the destinations, then the libraries of Libraries
///   (the visible ones, then Hidden libraries) and at its bottom the running profile (`SidebarBarProfile`). With Always
///   Keep Sidebar Open the sidebar shows from the start and stays where it fits beside the screen (`keepsSidebarShown`).
/// - Mac: the window's sidebar (`NavigationSplitView`, `Sidebar`) with the destinations, the libraries and the running
///   profile at its bottom, which Always Keep Sidebar Open keeps shown; the toolbar is compact (the window's
///   `unifiedCompact` style) and holds navigation only.
/// - Apple TV: the top tab bar.
///
/// A stack with no top-level destination (the sign-in, the required profile picker, a `--dev-open` start on another
/// screen) shows its screens without the chrome: the root switch between signing in and the running app. Offline, or
/// while a server refuses the account, a line over the screens says so (`ShellNoticeLine`): on iOS across the top of
/// each tab's stack, whose screens start under it (`tabScreen`). The shell's toasts show in the band at the foot of the
/// screen on top (`ToastRelay`, `RouteStack`), clear of the tab bar, the mini-player and the cast or playback bar, and
/// over the Mac's Now Playing in its own. The menus' destinations (`AppCommands`) go through the shell too. Music: Now
/// Playing is a full-screen cover while it is the top screen; on the Mac the full-window player over the window, with the playback
/// bar and its side panel on the split view while music plays (`MacNowPlaying`). On Apple TV the remote's Play/Pause
/// that no screen takes pauses the music or plays it again (`NowPlayingCenter.remotePlayPause`).
/// Casting (`CastModel`): while this device casts, the cast bar takes the mini-player's place (on Apple TV a Casting
/// tab), its control sheet and notices show over the shell, and the receiver's pairing question over everything.
///
/// The player (`RoutePlayer` on top) shows the app's current playback (`AppModel.playback`) over the chrome: a
/// full-screen cover on iOS and tvOS (on tvOS up at once), an overlay in the Mac window. Dismissing the cover pops the
/// player's route, which ends the playback. A tab picked shows its stack as it was left; the selected tab picked again
/// pops its stack to its root (`PlezyNavigator.pick`). A sidebar (iPad, the Mac) highlights the row the screen on top
/// belongs to, wherever it was pushed from (`highlightedTab`): a movie opened from Home highlights its library, an
/// artist its music library.
struct AppShell: View {
    let app: AppModel

    @State private var music: MusicChromeModel
    /// The shell's toasts, shown in the band of the screen on top.
    @State private var toasts = ToastRelay()
    @Environment(\.displayScale) private var displayScale
    @Environment(\.appActive) private var appActive
    /// The libraries the sidebars list (iPad, the Mac); nil without a Libraries store.
    @State private var libraries: StoreModel<LibrariesScreenStore, LibrariesUiState>?
    /// The tab last picked, until the shell's state follows (`selectionBinding`).
    @State private var pickedTab: ShellTab?
    #if !os(tvOS)
    /// The split view's columns (`splitChrome`): the sidebar shown as each shell starts, a profile switch's new shell
    /// too, which the split view otherwise opened with its sidebar collapsed.
    @State private var columns = NavigationSplitViewVisibility.all
    #endif
    #if os(macOS)
    /// The Mac's music player: the playback bar and its side panel (`MacNowPlaying`).
    @State private var macPlayer: MacPlayerModel?
    /// The sidebar's width, which the playback bar keeps clear of.
    @State private var sidebarWidth: CGFloat = 200
    #endif

    #if !os(macOS)
    /// The player's cover is up.
    @State private var coverShown = false
    /// The player's cover waiting for a sheet over the shell to go (`showCover`).
    @State private var coverWait: Task<Void, Never>?
    #endif
    #if os(iOS)
    /// The tabs show as iPad's sidebar (not as a tab bar).
    @State private var sidebarShown = false
    #endif
    #if os(tvOS)
    /// The Now Playing tab is the selected one.
    @State private var nowPlayingTab = false
    /// The Casting tab is the selected one.
    @State private var castingTab = false
    #endif

    init(app: AppModel) {
        self.app = app
        _music = State(initialValue: MusicChromeModel(session: app.session))
        #if os(macOS)
        _macPlayer = State(initialValue: MacPlayerModel(session: app.session))
        #endif
        _libraries = State(initialValue: StoreModel(app.session.libraries()) { $0.state })
    }

    var body: some View {
        let appearance = app.appearance.state
        let shell = app.shell.state
        let layout = BackStackLayout.companion.of(backStack: app.backStack)
        let screens = layout.screens
        let playerShown = screens.last is RoutePlayer
        // The required profile picker a return to the app asked for covers the player, which stays up, paused, under it.
        let overPlayer = layout.overPlayer
        let nowPlaying = screens.last is RouteNowPlaying
        // iPhone's, iPad's and Apple TV's Now Playing is a full-screen cover, which the shell can't present over: while it
        // shows, its own hosts present the item menus (its ⋯) and the download flows' questions.
        #if os(macOS)
        let covered = false
        #else
        let covered = nowPlaying
        #endif
        // Read on every pass, so an ended playback's model goes as the playback does (`AppModel.playback`).
        let playback = app.playback
        // The tier the user's visual effects choice picks: the views below read it (`reducedEffects`), the artwork's
        // memory budget follows it (`ArtworkPipeline.use`).
        let reduced = ArtworkScreen.display(scale: displayScale, tv: appearance.tv, visualEffects: appearance.visualEffects).reduced
        chrome(shell: shell, screens: screens.filter { !($0 is RouteNowPlaying) }, nowPlaying: nowPlaying)
            #if os(macOS)
            // Under the player the screens take no keys: Tab and the arrows stay in the player's controls rather than
            // reaching the screen hidden behind it.
            .disabled(playerShown)
            // The player's video had the keyboard: closed, the window's SwiftUI view kept it with nothing focused under
            // it, and took Escape for nothing. The window takes the keys again, so Escape goes back (`WindowBack`).
            .onChange(of: playerShown) { _, shown in
                if !shown { NSApp.keyWindow?.makeFirstResponder(nil) }
            }
            // The Mac's Now Playing: the full-window player over the window, under the shell's menus, the shell's toasts
            // in its own band.
            .overlay { if nowPlaying { MacFullPlayer(app: app).toastBand(toasts) } }
            .task { await macPlayer?.run() }
            #endif
            // Under the player the screens aren't in use: their artwork timers (the hero's pages, the backdrops'
            // rotation) hold still, as while the app is away.
            .environment(\.appActive, appActive && !playerShown)
            #if os(iOS)
            // iPad's floating tab bar reads the shell's top safe area (`shellTop`); iPhone's shell is as it was.
            .modifier(PadShellTop())
            #elseif os(tvOS)
            .safeAreaInset(edge: .top, spacing: 0) {
                if TopLevelDestination.companion.selectedIn(backStack: screens) != nil { ShellNoticeLine(app: app) }
            }
            // The remote's Play/Pause that no screen takes (the player and the guide take their own) pauses the music or
            // plays it again, on Now Playing too; without music it does nothing.
            .onPlayPauseCommand { AppleAppPlatform.musicNowPlaying.remotePlayPause() }
            #endif
            .environment(\.musicChrome, music)
            #if !os(macOS)
            .fullScreenCover(isPresented: nowPlayingBinding(nowPlaying)) {
                NowPlayingScreen(app: app)
                    #if os(tvOS)
                    .onPlayPauseCommand { AppleAppPlatform.musicNowPlaying.remotePlayPause() }
                    #else
                    .downloadOverlays(app.session.downloads)
                    #endif
                    .mediaMenuHost(app.menu)
                    .toast(app.menu.message?.text, id: "menu.message", isError: app.menu.message?.isError == true, onShown: app.menu.menu.messageShown)
                    .environment(\.musicChrome, music)
                    .environment(\.cast, app.cast)
                    .castNotice(app.cast, shown: true)
                    .formFactorEnvironment(tv: appearance.tv)
                    .environment(\.visualEffects, appearance.visualEffects)
                    .environment(\.reducedEffects, reduced)
            }
            // The reduced tier puts the cover up and takes it down at once.
            .transaction(value: nowPlaying) { if reduced { $0.disablesAnimations = true } }
            #endif
            #if DEBUG
            .modifier(OverlaySample())
            #endif
            #if !os(tvOS)
            // The download flows' questions and a slow deletion's progress, wherever they are asked from.
            .downloadOverlays(app.session.downloads, presenting: !covered)
            #endif
            #if DEBUG && os(tvOS)
            .overlay { TopShelfProbe() }
            #endif
            #if DEBUG && os(macOS)
            .overlay { KeyboardFocusProbe() }
            #endif
            // Items' and playlists' menus, their questions and sheets.
            .mediaMenuHost(app.menu, presenting: !covered)
            .modifier(ShellPrompts(app: app, pinElsewhere: pinInPlayerCover(overPlayer)))
            // A sheet route on top of the shown stack (Seerr's request) over its screens; closing it pops it.
            .appSheet(item: layout.sheet.map(RouteKey.init), onDismiss: {
                if let sheet = layout.sheet { _ = app.navigator.pop(route: sheet) }
            }) { key in
                RouteView(app: app, route: key.route)
            }
            .modifier(ShellNotices(app: app, toasts: toasts))
            .watchNotices(app, relay: toasts)
            .userMenuNotices(app, relay: toasts)
            .formFactorEnvironment(tv: appearance.tv)
            .environment(\.visualEffects, appearance.visualEffects)
            .environment(\.reducedEffects, reduced)
            .environment(\.openRoute, app.openRoute)
            .onChange(of: appearance.visualEffects, initial: true) { _, effects in ArtworkPipeline.use(visualEffects: effects) }
            .background(Palette.background)
            // Back at the first destination's root (a remote's, a controller's B, the Mac's Escape) arms the exit.
            .toast(shell.exitPrompt ? T.shared.common.pressBackAgainToExit : nil, id: "shell.exitPrompt", in: toasts) {}
            .modifier(ShellMessages(app: app, music: music, toasts: toasts, covered: covered))
            // Casting: the receiver's pairing question over everything, the sender's control sheet (from the cast bar)
            // and its notices, while no cover is up over the shell (the player's and Now Playing's show their own).
            .castReceiverPrompt(app.cast)
            .castControls(app.cast, presenting: !covered && !playerShown)
            .castNotice(app.cast, shown: !covered && !playerShown, in: toasts)
            .environment(\.cast, app.cast)
            // Game controllers' menu key and Back (and on the Mac the window's Escape).
            .gamepadInput(app, playerShown: playerShown && overPlayer == nil)
            .task { await app.observe() }
            // The start's work that waits for the app's first frame (`afterFirstFrame`): the shell is on screen.
            .onAppear { AfterFirstFrameKt.afterFirstFrame(graph: app.session.graph, platform: app.platform) }
            .task { for await value in app.session.notice { if let value { app.notice = value } } }
            .task { await music.observe() }
            .task { await libraries?.state.observe() }
            .onChange(of: shell.selected) { pickedTab = nil }
            .modifier(LibrarySelectionWatch(libraries: libraries) { pickedTab = nil })
            .onChange(of: highlightedTab(shell, screens: screens)) { pickedTab = nil }
            #if !os(tvOS)
            // The menus' destinations (`AppCommands`), but while the player is up.
            .focusedSceneValue(\.destinationPicker, playerShown ? nil : DestinationPicker(
                session: app.session, destinations: shell.destinations, language: InterfaceLocale.shared.tag.value as String,
                tv: appearance.tv
            ))
            #endif
            #if os(iOS)
            // The Playback menu's player while its cover is up.
            .playbackCommands(playerShown && coverShown && overPlayer == nil ? playback : nil)
            #endif
            #if os(macOS)
            .overlay {
                if playerShown, let playback {
                    PlayerScreen(playback: playback).id(ObjectIdentifier(playback))
                        .disabled(overPlayer != nil)
                        .castPlayerPicker(app.cast)
                        .castNotice(app.cast, shown: true)
                        // The overlay is outside the shell's environment: its cast button and "Casting from" line.
                        .environment(\.cast, app.cast)
                    pickerOverPlayer(overPlayer)
                }
            }
            #else
            .fullScreenCover(isPresented: playerBinding) {
                ZStack {
                    Palette.background.ignoresSafeArea()
                    if let playback {
                        PlayerScreen(playback: playback).id(ObjectIdentifier(playback))
                            .disabled(overPlayer != nil)
                            .castPlayerPicker(app.cast)
                            .castNotice(app.cast, shown: true)
                            .environment(\.cast, app.cast)
                    }
                    pickerOverPlayer(overPlayer)
                        .formFactorEnvironment(tv: appearance.tv)
                        .environment(\.visualEffects, appearance.visualEffects)
                        .environment(\.reducedEffects, reduced)
                }
            }
            .onChange(of: playerShown, initial: true) { _, shown in
                coverWait?.cancel()
                if shown, Self.sheetUp {
                    coverWait = Task { await showCoverAfterSheets() }
                } else if shown {
                    showCover()
                } else {
                    coverShown = false
                }
            }
            #endif
    }

    /// The required profile picker over the player (`BackStackLayout.overPlayer`), in a stack of its own for its Back.
    @ViewBuilder
    private func pickerOverPlayer(_ route: (any Route)?) -> some View {
        if let route {
            NavigationStack { RouteView(app: app, route: route) }
                .background(Palette.background.ignoresSafeArea())
                .pinPrompt(pinInPlayerCover(route) ? app.pin.state : nil, prompter: app.session.onboarding.pin)
        }
    }

    /// The shell can't present over the player's full-screen cover (iOS, tvOS): the picker over it asks for PINs.
    private func pinInPlayerCover(_ overPlayer: (any Route)?) -> Bool {
        #if os(macOS)
        false
        #else
        overPlayer != nil
        #endif
    }

    @ViewBuilder
    private func chrome(shell: ShellUiState, screens: [any Route], nowPlaying: Bool) -> some View {
        if TopLevelDestination.companion.selectedIn(backStack: screens) == nil {
            // Signing in, the required profile pick: no chrome.
            RouteStack(app: app, stack: screens, toasts: toasts)
        } else {
            #if os(macOS)
            // The Mac's own sidebar: a `TabView`'s sidebar rows carry no accessibility identifiers there, and the
            // player's overlay loses the keyboard to it.
            splitChrome(shell: shell, screens: screens, nowPlaying: nowPlaying)
            #elseif os(tvOS)
            tabs(shell: shell, screens: screens)
            #else
            if #available(iOS 18, *) {
                tabs(shell: shell, screens: screens)
            } else {
                legacyChrome(shell: shell, screens: screens)
            }
            #endif
        }
    }

    #if !os(tvOS)
    /// The sidebar (`Sidebar`) beside the shown destination's stack: the Mac, and iPad before iOS 18. With Always Keep
    /// Sidebar Open the sidebar stays shown: no toggle, and a collapse (View → Hide Sidebar, the divider dragged) is
    /// undone at once. On the Mac the music's playback bar floats over the detail and its side panel opens beside it
    /// (`macMusicPlayer`); while Now Playing (`nowPlaying`, on top of the stack) covers the window the toolbar hides.
    private func splitChrome(shell: ShellUiState, screens: [any Route], nowPlaying: Bool = false) -> some View {
        let keep = app.appearance.state.alwaysKeepSidebarOpen
        #if os(macOS)
        let covered = screens.last is RoutePlayer
        #else
        let covered = false
        #endif
        return NavigationSplitView(columnVisibility: $columns) {
            Sidebar(
                app: app, destinations: shell.destinations, libraries: libraries, selection: selectionBinding(shell, screens: screens),
                covered: covered
            )
            .toolbar(removing: keep ? .sidebarToggle : nil)
            #if os(macOS)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { sidebarWidth = $0 }
            // Wide enough for a library name of a dozen letters beside its symbol; a longer one shows whole on hover.
            .navigationSplitViewColumnWidth(min: 180, ideal: 230)
            #endif
        } detail: {
            RouteStack(app: app, stack: screens, toasts: toasts)
        }
        #if os(macOS)
        .macMusicPlayer(macPlayer, chrome: music, sidebarWidth: columns == .detailOnly ? 0 : sidebarWidth, nowPlaying: nowPlaying)
        .toolbar(nowPlaying ? .hidden : .visible, for: .windowToolbar)
        // In full screen the screens come down with the title bar the pointer brings down at the screen's top edge.
        .fullScreenTitleBarDrop()
        #endif
        .onChange(of: keep, initial: true) { if keep { columns = .all } }
        // Not within the change: the split view is still collapsing.
        .onChange(of: columns) { if keep, columns != .all { DispatchQueue.main.async { columns = .all } } }
    }
    #endif

    #if os(iOS)
    /// Before iOS 18: the split view on iPad, a tab bar elsewhere.
    @ViewBuilder
    private func legacyChrome(shell: ShellUiState, screens: [any Route]) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            splitChrome(shell: shell, screens: screens)
        } else {
            legacyTabs(shell: shell, screens: screens)
        }
    }

    private func legacyTabs(shell: ShellUiState, screens: [any Route]) -> some View {
        TabView(selection: selectionBinding(shell, screens: screens)) {
            ForEach(tabbedDestinations(shell), id: \.self) { destination in
                tabScreen(destination, shell: shell, screens: screens)
                    .tabItem {
                        Label(destination.label, systemImage: destination.systemImage)
                            .accessibilityIdentifier(destination.accessibilityId)
                    }
                    .tag(ShellTab.destination(destination))
            }
        }
    }

    /// The destinations with a tab: every one, but on iPhone the bar's (`NavigationTabs.bar`: no Downloads online) and
    /// the shown one where the bar leaves it out (Downloads from Home's chip), selected, for as long as it shows: a tab
    /// view shows nothing for a selection without a tab, and a tab hidden from the bar (`defaultVisibility`) stayed in
    /// it once picked.
    private func tabbedDestinations(_ shell: ShellUiState) -> [TopLevelDestination] {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return shell.destinations }
        let bar = NavigationTabs.shared.bar(visible: shell.destinations)
        return bar.contains(shell.selected) ? bar : bar + [shell.selected]
    }
    #endif

    #if !os(macOS)
    /// The destinations as the system's tabs, a `Tab` carrying its accessibility identifier to the bar's button
    /// (`nav.home`). iPad's sidebar adds the libraries, which the bars leave out. iPhone's bar has the tabs
    /// `tabbedDestinations` says.
    @available(iOS 18, *)
    private func tabs(shell: ShellUiState, screens: [any Route]) -> some View {
        // In iPad's sidebar the row the screen on top belongs to is the selected tab: its tab shows the shown stack.
        #if os(iOS)
        let host = sidebarShown ? highlightedTab(shell, screens: screens) : nil
        let tabbed = tabbedDestinations(shell)
        #else
        let host: ShellTab? = nil
        let tabbed = shell.destinations
        #endif
        return TabView(selection: selectionBinding(shell, screens: screens)) {
            ForEach(tabbed, id: \.self) { destination in
                Tab(value: ShellTab.destination(destination)) {
                    tabScreen(destination, shell: shell, screens: screens, host: host, tab: .destination(destination))
                        #if os(iOS)
                        .modifier(TabBarPlacementReader { sidebarShown = $0 == .sidebar })
                        .tabBarIdentifiers(Dictionary(shell.destinations.map { ($0.label, $0.accessibilityId) }) { first, _ in first })
                        .keepsSidebarShown(app.appearance.state.alwaysKeepSidebarOpen, shown: sidebarShown)
                        #endif
                } label: {
                    Label(destination.label, systemImage: destination.systemImage)
                }
                .accessibilityIdentifier(destination.accessibilityId)
            }
            #if os(iOS)
            // iPad's sidebar alone: on iPhone the tabs past the bar's five went under a More tab.
            if let libraries, shell.destinations.contains(.libraries), UIDevice.current.userInterfaceIdiom == .pad {
                librarySections(libraries.state.state, shell: shell, screens: screens, host: host)
            }
            #endif
            #if os(tvOS)
            // A TV has no mini-player: while music plays, a Now Playing tab, whose page opens Now Playing.
            if music.state.state.railItem {
                Tab(value: ShellTab.nowPlaying) {
                    NowPlayingTabPage(music: music)
                } label: {
                    Label(T.shared.music.nowPlaying, systemImage: "waveform")
                }
                .accessibilityIdentifier("nav.nowPlaying")
            }
            // A TV has no cast bar: while this device casts, a Casting tab with the controls.
            if app.cast.senderState.state.casting {
                Tab(value: ShellTab.casting) {
                    CastTabPage(cast: app.cast)
                } label: {
                    Label(T.shared.cast.title, systemImage: castSymbol(casting: true))
                }
                .accessibilityIdentifier("nav.casting")
            }
            #endif
        }
        #if os(iOS)
        // iPhone: the tab bar. iPad: the floating tab bar, which opens into the sidebar, the running profile at its
        // bottom.
        .tabViewStyle(.sidebarAdaptable)
        .tabViewSidebarBottomBar { SidebarBarProfile(app: app) }
        // The mini-player over the tab bar while music plays.
        .musicMiniPlayerAccessory(music, cast: app.cast)
        .tint(sidebarShown ? Palette.onSurfaceVariant : Palette.primary)
        // Made anew when its tabs change (online again, Explore turned on, Downloads opened on iPhone): the bar's
        // buttons for tabs added to a shown tab view carry no accessibility identifiers.
        .id(tabbed)
        #endif
        #if os(tvOS)
        .background(TabBarSelect { repick(shell, screens: screens) })
        #endif
    }
    #endif

    #if os(iOS)
    /// iPad's sidebar's libraries: the visible ones (under their servers' names where the list groups them by server,
    /// `railSections`), then Hidden libraries; each shows Libraries with it selected.
    @available(iOS 18, *)
    @TabContentBuilder<ShellTab>
    private func librarySections(_ state: LibrariesUiState, shell: ShellUiState, screens: [any Route], host: ShellTab?) -> some TabContent<ShellTab> {
        ForEach(Array(state.railSections(hiddenOnes: false).enumerated()), id: \.offset) { _, section in
            TabSection(section.heading ?? T.shared.libraries.title) {
                ForEach(section.rows, id: \.library.globalKey) { row in
                    libraryTab(row, shell: shell, screens: screens, host: host)
                }
            }
            .tabPlacement(.sidebarOnly)
        }
        if !state.hidden.isEmpty {
            TabSection(T.shared.libraries.hiddenLibrariesCount(count: String(state.hidden.count))) {
                ForEach(state.railEntries(hiddenOnes: true).compactMap(\.libraryRow), id: \.library.globalKey) { row in
                    libraryTab(row, shell: shell, screens: screens, host: host)
                }
            }
            .tabPlacement(.sidebarOnly)
        }
    }

    @available(iOS 18, *)
    private func libraryTab(_ row: LibraryListEntryRow, shell: ShellUiState, screens: [any Route], host: ShellTab?) -> some TabContent<ShellTab> {
        Tab(value: ShellTab.library(row.library.globalKey)) {
            tabScreen(.libraries, shell: shell, screens: screens, host: host, tab: .library(row.library.globalKey))
        } label: {
            Label(row.library.title, systemImage: row.library.kind.librarySymbol)
        }
        .defaultVisibility(.hidden, for: .tabBar)
        .accessibilityIdentifier("nav.library.\(row.library.title)")
    }
    #endif

    /// The screen of the tab `tab` of `destination`: the shown stack (`screens`) while `destination` is the shown one, its
    /// kept stack while another is, its root alone before it first shows. In iPad's sidebar the highlighted row's tab
    /// (`host`, `highlightedTab`) shows the shown stack instead, and the shown destination's own tab its root meanwhile.
    /// Each tab keeps its screens while another shows. One `RouteStack` throughout: a stand-in replaced by the stack as
    /// the tab showed took Apple TV's focus from the tab bar into the screen. On iOS the offline or refused-account line
    /// (`ShellNoticeLine`) goes above the stack, which starts under it, its navigation bar and its screens' header rows
    /// too: as an inset of the tab view (or of the stack) it drew over them (iPad's navigation bar kept its line under it).
    /// The shown tab's stack holds the shell's toasts.
    private func tabScreen(
        _ destination: TopLevelDestination, shell: ShellUiState, screens: [any Route], host: ShellTab? = nil, tab: ShellTab? = nil
    ) -> some View {
        let hosting = host != nil && host == tab
        let shown = hosting || (host == nil && destination == shell.selected)
        let stack = shown ? screens : destination == shell.selected ? [] : app.stacks.state.stack(destination: destination) ?? []
        let routes = RouteStack(app: app, stack: stack.isEmpty ? [destination.route] : stack, toasts: shown ? toasts : nil)
        #if os(iOS)
        return VStack(spacing: 0) {
            ShellNoticeLine(app: app)
            routes
        }
        #else
        return routes
        #endif
    }

    /// The chrome's selection: the shown destination, or in a sidebar the row the screen on top belongs to
    /// (`highlightedTab`), else the library selected in Libraries while it shows. A pick (the selected one too) goes
    /// through the shell (`ShellStore.select`); a library picks Libraries with it selected. The
    /// picked tab holds until the shell's state follows (`pickedTab`): handed the old selection meanwhile, Apple TV's tab
    /// bar switched back and forth and its focus fell into the new tab's screen.
    private func selectionBinding(_ shell: ShellUiState, screens: [any Route]) -> Binding<ShellTab> {
        Binding(
            get: {
                if let pickedTab { return pickedTab }
                #if os(iOS)
                let sidebar = sidebarShown
                #elseif os(macOS)
                let sidebar = true
                #else
                let sidebar = false
                #endif
                if sidebar, let highlighted = highlightedTab(shell, screens: screens) { return highlighted }
                if sidebar, shell.selected == .libraries,
                   let key = libraries?.state.state.selected?.globalKey {
                    return .library(key)
                }
                #if os(tvOS)
                if nowPlayingTab, music.state.state.railItem { return .nowPlaying }
                if castingTab, app.cast.senderState.state.casting { return .casting }
                #endif
                return .destination(shell.selected)
            },
            set: { tab in
                #if os(tvOS)
                nowPlayingTab = tab == .nowPlaying
                castingTab = tab == .casting
                #endif
                if tab != .nowPlaying, tab != .casting { pickedTab = tab }
                switch tab {
                case .destination(let destination):
                    app.session.shell.select(destination: destination)
                case .library(let key):
                    app.session.pickLibrary(globalKey: key)
                case .nowPlaying, .casting:
                    break
                }
            }
        )
    }

    /// The row the screen on top of `screens` belongs to (`TopLevelDestination.highlightedIn`): under Libraries the
    /// library it stands for (`highlightedLibrary`: the library a title was opened under or belongs to, an artist's,
    /// album's or playlist's music library, Libraries' selected one), else its destination where that isn't the shown
    /// one; nil where the shown destination's row is the one, and on Apple TV, whose tab bar shows only over a
    /// destination's root.
    private func highlightedTab(_ shell: ShellUiState, screens: [any Route]) -> ShellTab? {
        #if os(tvOS)
        return nil
        #else
        let companion = TopLevelDestination.companion
        guard let destination = companion.highlightedIn(screens: screens, shown: shell.destinations) else { return nil }
        if destination == .libraries,
           let library = companion.highlightedLibrary(
               screens: screens,
               shown: shell.destinations,
               libraries: libraries?.state.state.libraries ?? [],
               placed: app.stacks.state.libraries,
               selected: libraries?.state.state.selected
           ) {
            return .library(library.globalKey)
        }
        return destination == shell.selected ? nil : .destination(destination)
        #endif
    }

    #if os(tvOS)
    /// Apple TV's Select on the tab bar: its focused tab, which is the selected one there, picked again (`selectionBinding`),
    /// which the tab view doesn't tell. Now Playing's tab has no stack to go back to.
    private func repick(_ shell: ShellUiState, screens: [any Route]) {
        let selection = selectionBinding(shell, screens: screens)
        let tab = selection.wrappedValue
        if tab != .nowPlaying, tab != .casting { selection.wrappedValue = tab }
    }
    #endif

    /// Now Playing's cover (the Mac's sheet) while it is the top screen; dismissing it pops it.
    private func nowPlayingBinding(_ shown: Bool) -> Binding<Bool> {
        Binding(get: { shown }, set: { if !$0 { _ = app.navigator.pop(route: RouteNowPlaying.shared) } })
    }

    #if !os(macOS)
    /// The player's cover: dismissed by the system (a swipe, the remote's Menu), it pops the player's route.
    private var playerBinding: Binding<Bool> {
        Binding(get: { coverShown }, set: { shown in
            guard !shown else { return }
            coverShown = false
            _ = app.navigator.pop(route: RoutePlayer.shared)
        })
    }

    /// Puts the player's cover up: on tvOS at once, as the system player comes up.
    private func showCover() {
        #if os(tvOS)
        withTransaction(\.disablesAnimations, true) { coverShown = true }
        #else
        coverShown = true
        #endif
    }

    /// Puts the player's cover up once no sheet is over the shell: a presentation can't come from a view that is
    /// already presenting, and SwiftUI drops it rather than waiting (the play queue's loading sheet is still up as its
    /// playback starts).
    private func showCoverAfterSheets() async {
        while Self.sheetUp {
            try? await Task.sleep(for: .milliseconds(50))
            if Task.isCancelled { return }
        }
        showCover()
    }

    /// A sheet, alert or cover is presented over the app's window.
    private static var sheetUp: Bool {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .contains { $0.rootViewController?.presentedViewController != nil }
    }
    #endif
}

/// A row of the chrome: a destination, or in iPad's and the Mac's sidebars a library of Libraries (its global key).
enum ShellTab: Hashable {
    case destination(TopLevelDestination)
    case library(String)
    /// Apple TV's Now Playing tab, while music plays.
    case nowPlaying
    /// Apple TV's Casting tab, while this device casts (`CastTabPage`).
    case casting
}

/// The rating sheet an item menu's Rate opened, and the PIN the profiles ask for, over every screen and the sign-in's;
/// over the player's cover the picker there asks it itself (`pinElsewhere`, `pickerOverPlayer`). Their own view, so a
/// prompt coming or going doesn't rebuild the shell.
private struct ShellPrompts: ViewModifier {
    let app: AppModel
    let pinElsewhere: Bool

    func body(content: Content) -> some View {
        content
            .ratingSheet(store: app.ratingSheet.state?.store, backend: app.ratingSheet.state?.backend ?? .plex) {
                app.session.closeRatingSheet()
            }
            .metadataMenuOverlays(app.session.metadata)
            .pinPrompt(pinElsewhere ? nil : app.pin.state, prompter: app.session.onboarding.pin)
    }
}

/// A message from a sheet that closed itself, or from the session (an edit saved or failed), and a link's message, over
/// the screen they were on. Their own view, so a message doesn't rebuild the shell.
private struct ShellNotices: ViewModifier {
    let app: AppModel
    let toasts: ToastRelay

    func body(content: Content) -> some View {
        content
            .toast(app.notice?.text, id: "app.notice", isError: app.notice?.isError == true, in: toasts) {
                app.notice = nil
                app.session.noticeShown()
            }
            .toast(app.linkMessage, id: "app.linkMessage", in: toasts) {
                if let shown = app.linkMessage { app.session.links.dismissMessage(shown: shown) }
            }
    }
}

/// The menus', the reconnection's and the music's messages; the menus' while no cover is up (`covered`: Now Playing's
/// shows its own). Their own view, so a message doesn't rebuild the shell.
private struct ShellMessages: ViewModifier {
    let app: AppModel
    let music: MusicChromeModel
    let toasts: ToastRelay
    let covered: Bool

    func body(content: Content) -> some View {
        content
            .toast(
                covered ? nil : app.menu.message?.text, id: "menu.message", isError: app.menu.message?.isError == true, in: toasts,
                onShown: app.menu.menu.messageShown
            )
            .toast(app.reconnect.state.message, id: "shell.reconnect.message", in: toasts) { app.session.reconnect.messageShown() }
            .toast(music.message?.text, id: "music.message", isError: music.message?.error == true, in: toasts) { music.message = nil }
    }
}

/// Calls `changed` as the library selected in Libraries changes, reading the selection in a view of its own.
private struct LibrarySelectionWatch: ViewModifier {
    let libraries: StoreModel<LibrariesScreenStore, LibrariesUiState>?
    let changed: () -> Void

    func body(content: Content) -> some View {
        content.onChange(of: libraries?.state.state.selected?.globalKey) { changed() }
    }
}

#if os(tvOS)
/// Apple TV's Now Playing tab: the track playing and a button that opens Now Playing.
private struct NowPlayingTabPage: View {
    let music: MusicChromeModel

    var body: some View {
        let state = music.state.state
        VStack(spacing: 24) {
            if let track = state.track {
                Text(track.title).font(.title2.weight(.semibold))
            }
            Button(T.shared.music.nowPlaying, systemImage: "waveform", action: music.store.open)
                .accessibilityIdentifier("nowPlaying.open")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Calls `action` as the remote's Select is pressed while the tab bar has focus. On the window, beside the tab bar's own
/// handling of the press, which goes on.
private struct TabBarSelect: UIViewRepresentable {
    let action: @MainActor () -> Void

    func makeUIView(context: Context) -> Probe {
        let probe = Probe()
        probe.isUserInteractionEnabled = false
        return probe
    }

    func updateUIView(_ probe: Probe, context: Context) { probe.press.action = action }

    final class Probe: UIView {
        let press = TabBarSelectPress()

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            window?.removeGestureRecognizer(press.recognizer)
            newWindow?.addGestureRecognizer(press.recognizer)
        }
    }
}

/// The Select press of `TabBarSelect`: taken only while the tab bar has focus as it begins, never cancelling it.
@MainActor
private final class TabBarSelectPress: NSObject, UIGestureRecognizerDelegate {
    let recognizer = UITapGestureRecognizer()
    var action: @MainActor () -> Void = {}

    override init() {
        super.init()
        recognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        recognizer.allowedTouchTypes = []
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        recognizer.addTarget(self, action: #selector(pressed))
    }

    @objc private func pressed() { action() }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        FocusRestore.focusInTabBar
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
#endif

extension LibraryListEntry {
    /// The library row this entry is, nil for a server's header.
    var libraryRow: LibraryListEntryRow? { self as? LibraryListEntryRow }
}

extension LibrariesUiState {
    /// The sidebars' sections of the rail's libraries (`railEntries`, the libraries menu's grouping): a server's name
    /// over its libraries where the list groups them by server (several servers), else one section without a name.
    func railSections(hiddenOnes: Bool) -> [(heading: String?, rows: [LibraryListEntryRow])] {
        var sections: [(heading: String?, rows: [LibraryListEntryRow])] = []
        for entry in railEntries(hiddenOnes: hiddenOnes) {
            if let header = entry as? LibraryListEntryHeader {
                sections.append((header.serverName, []))
            } else if let row = entry.libraryRow {
                if sections.isEmpty { sections.append((nil, [])) }
                sections[sections.count - 1].rows.append(row)
            }
        }
        return sections
    }
}

extension TopLevelDestination {
    /// This destination's SF Symbol in the tab bar and the sidebar.
    var systemImage: String {
        switch self {
        case .home: "house"
        case .libraries: "books.vertical"
        case .downloads: "arrow.down.circle"
        case .explore: "safari"
        case .search: "magnifyingglass"
        case .settings: "gearshape"
        }
    }

    /// This destination's accessibility identifier in the tab bar and the sidebar (`nav.home`).
    var accessibilityId: String { "nav.\(name.lowercased())" }
}
