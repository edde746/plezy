import Foundation
import Observation
import PlezyKit

/// The running app for SwiftUI: the shared `AppSession` (`session`: its navigator, chrome, screens' stores and
/// playbacks), with its back stacks, chrome, appearance and current playback mirrored for the views and a `PlayerModel`
/// for that playback. The root makes one per session (`RootModel.model(for:)`); a `--dev` launch makes one for its
/// session. The shell's view runs the observations (`observe()`), which paint the session's theme (`ThemeState`) as
/// it changes; its first paints from the start.
@MainActor
@Observable
final class AppModel {
    let session: AppSession
    /// The platform the session runs on (the root's or the dev launch's), for the start's work after the first frame.
    let platform: AppleAppPlatform
    /// The navigator's back stacks, one per destination, and the one shown.
    let stacks: StoreObserver<NavigationStacks>
    /// The navigation chrome: the destinations it shows, the selected one, offline.
    let shell: StoreObserver<ShellUiState>
    /// The theme, the effective form factor and the card settings.
    let appearance: StoreObserver<Appearance>
    /// Items' and playlists' menus, which the shell draws over every screen (`mediaMenuHost`).
    let menu: MediaMenuModel
    /// The current playback (`AppSession.player`) as `observePlayer()` last mirrored it.
    private var active: ActivePlayback?
    /// What a `plezy://` link couldn't do (`AppLinks.message`), shown as a toast until dismissed.
    private(set) var linkMessage: String?

    @ObservationIgnored private var player: PlayerModel?
    /// The PIN the app asks for, shown over everything (`pinPrompt`).
    let pin: StoreObserver<PinRequest?>
    /// The rating sheet an item menu's Rate opened, drawn over the app (`ratingSheet`) until it closes.
    let ratingSheet: StoreObserver<OpenRatingSheet?>
    /// The offline chrome's Reconnect.
    let reconnect: StoreObserver<ReconnectUiState>
    /// Counts the active profile's switches: the shell is keyed on it, so a switch starts every screen anew.
    let profileSession: StoreObserver<KotlinInt>
    /// The running profile's menu: Home's chip, the sidebar's `ProfileHeader`, Settings' profile row and their notices.
    let userMenu: StoreObserver<UserMenuUiState>
    /// The watch-together room Home's shortcuts show.
    let watchToolbar: StoreObserver<WatchToolbarUi>
    /// Home's Server Tasks chip and its panel.
    let serverTasks: StoreObserver<ServerTasksUiState>
    /// The rejected-sign-in line across the top of the screens (`ShellNoticeLine`).
    let authErrorBanner: StoreObserver<AuthErrorBannerUi?>
    /// The Supporter tile atop Settings.
    let supporterTile: StoreObserver<SupporterTileUi>
    /// The app icon row and its picker.
    let appIconPicker: StoreObserver<AppIconPickerUiState>
    /// A one-off message for the screen on top, from a sheet that closed itself (Seerr's "Request submitted", an error
    /// when the permission went); the stack shows it (`RouteStack`) and clears it.
    var notice: MenuMessage?
    /// The section Libraries shows (`LibrariesSections`): over the downloads the sidebar highlights Libraries itself,
    /// not the library the libraries' section has selected.
    var librariesSection = LibrarySection.library
    /// Casting: this device as a sender (the picker, the bar, the controls) and as a receiver (the pairing question).
    let cast: CastModel
    /// Opens a route on the navigator: the shell's `openRoute`. Made once, so every card reading it isn't made anew
    /// each time the shell's body runs (a closure made there never equals the last).
    let openRoute: (any Route) -> Void

    init(_ session: AppSession, platform: AppleAppPlatform) {
        self.session = session
        self.platform = platform
        stacks = StoreObserver(session.navigator.stacks)
        shell = StoreObserver(session.shell.state)
        appearance = StoreObserver(session.appearance)
        pin = StoreObserver(session.onboarding.pin.request)
        ratingSheet = StoreObserver(session.ratingSheet)
        reconnect = StoreObserver(session.reconnect.state)
        profileSession = StoreObserver(session.profileSession)
        userMenu = StoreObserver(session.userMenu.state)
        watchToolbar = StoreObserver(session.watchToolbar)
        serverTasks = StoreObserver(session.serverTasks.state)
        authErrorBanner = StoreObserver(session.authErrorBanner)
        supporterTile = StoreObserver(session.supporterSheet.tile)
        appIconPicker = StoreObserver(session.appIconPicker.state)
        menu = MediaMenuModel(session.mediaActions.menu)
        cast = CastModel(session: session)
        openRoute = { [navigator = session.navigator] in navigator.navigate(route: $0) }
        ThemeState.shared.apply(session.appearance.value.theme)
        active = session.player.value
        linkMessage = session.links.message.value
        // The profile picker covers the session's screens: their first focus waits for it to go.
        FocusRestore.coverShown = { [session] in session.navigator.backStack.value.contains { $0 is RouteProfilePicker } }
    }

    /// Mirrors the stacks, the chrome, the appearance and the current playback until the calling task is cancelled, painting each theme the
    /// appearance brings.
    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.stacks.observe() }
            group.addTask { await self.shell.observe() }
            group.addTask { await self.appearance.observe() }
            group.addTask { await self.pin.observe() }
            group.addTask { await self.ratingSheet.observe() }
            group.addTask { await self.reconnect.observe() }
            group.addTask { await self.profileSession.observe() }
            group.addTask { await self.userMenu.observe() }
            group.addTask { await self.watchToolbar.observe() }
            group.addTask { await self.serverTasks.observe() }
            group.addTask { await self.authErrorBanner.observe() }
            group.addTask { await self.supporterTile.observe() }
            group.addTask { await self.appIconPicker.observe() }
            group.addTask { await self.cast.observe() }
            group.addTask { await self.paintThemes() }
            group.addTask { await self.observePlayer() }
            group.addTask { await self.observeLinkMessages() }
        }
    }

    private func paintThemes() async {
        for await appearance in session.appearance {
            ThemeState.shared.apply(appearance.theme)
        }
    }

    var graph: AppGraph { session.graph }
    var navigator: PlezyNavigator { session.navigator }

    /// The shown destination's back stack, bottom to top.
    var backStack: [any Route] { stacks.state.current }

    /// Mirrors the current playback (`AppSession.player`) until the calling task is cancelled.
    func observePlayer() async {
        active = session.player.value
        for await value in session.player {
            active = value
        }
    }

    /// Mirrors what a link couldn't do (`AppLinks.message`) until the calling task is cancelled.
    private func observeLinkMessages() async {
        for await message in session.links.message {
            linkMessage = message
        }
    }

    /// The player's model of the current playback, the same one for as long as that playback lasts; nil for none, the
    /// ended playback's model let go of (its video surface, engine and Now Playing with it).
    var playback: PlayerModel? {
        guard let active else {
            player = nil
            return nil
        }
        if let player, player.playback === active { return player }
        let model = PlayerModel(active)
        player = model
        return model
    }
}

/// The player screen's view of the shared `ActivePlayback`: its store's state and timeline mirrored for SwiftUI, and the
/// Apple side of the playback (`ApplePlayback`: the video surface, Now Playing).
@MainActor
final class PlayerModel {
    let playback: ActivePlayback
    let state: StoreObserver<PlayerUiState>
    /// The store's timeline (`PlayerStore.timeline`), which moves several times a second as the video plays: only the
    /// views drawing it read it, and the controls observe it while they show it.
    let timeline: StoreObserver<TimelineState>
    /// The timeline again, for the video's position value (`player.video`), which an assistive technology reads: observed
    /// apart from the controls' (`PlayerScreen`), so two observations never mirror into one.
    let videoTimeline: StoreObserver<TimelineState>
    /// The playback info's sections (`PlayerStore.playbackInfo`), observed while its card shows.
    let playbackInfo: StoreObserver<[InfoSection]>
    let apple: ApplePlayback

    init(_ playback: ActivePlayback) {
        self.playback = playback
        // ApplePlatform makes every playback's platform side.
        apple = playback.platform as! ApplePlayback
        state = StoreObserver(playback.store.state)
        timeline = StoreObserver(playback.store.timeline)
        videoTimeline = StoreObserver(playback.store.timeline)
        playbackInfo = StoreObserver(playback.store.playbackInfo.sections)
    }

    var store: PlayerStore { playback.store }
    var config: PlayerConfig { playback.config }

    var surface: VideoSurface { apple.surface }
    var nowPlaying: NowPlayingCenter { apple.nowPlaying }
}
