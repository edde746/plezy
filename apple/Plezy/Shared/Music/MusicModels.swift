import SwiftUI
import PlezyKit

/// The music chrome over every screen: the mini-player's store (`AppSession.musicMiniPlayer`: the floating card, Apple
/// TV's rail item), its played fraction, the item menu its track opens (`MediaMenu`), and the music screens' snackbars
/// (`MusicScreens.messages`), the latest shown as a toast. One for the shell (`AppShell`).
@MainActor
@Observable
final class MusicChromeModel {
    @ObservationIgnored let screens: MusicScreens
    @ObservationIgnored let store: MiniPlayerStore
    @ObservationIgnored let menu: MediaMenu
    let state: StoreObserver<MiniPlayerUiState>
    let progress: StoreObserver<KotlinFloat>
    /// The snackbar showing, until its toast has shown.
    var message: MusicMessage?

    init(session: AppSession) {
        screens = session.musicScreens
        store = session.musicMiniPlayer
        menu = session.mediaActions.menu
        state = StoreObserver(store.state)
        progress = StoreObserver(store.progress)
    }

    /// Opens the session's track's item menu (the mini-player's long press, right click).
    func openMenu() {
        guard let item = store.item else { return }
        menu.open(item: item, place: .anywhere, extras: [], playTrailer: nil, onRow: [])
    }

    /// Mirrors the state and collects the snackbars until the calling task is cancelled.
    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.state.observe() }
            group.addTask { await self.collectMessages() }
        }
    }

    private func collectMessages() async {
        for await message in screens.messages {
            self.message = message
        }
    }
}

extension MenuPlace {
    /// An item menu away from its item's album and artist screens (Now Playing, the mini-player, a playlist): it keeps
    /// Go to album and Go to artist.
    static var anywhere: MenuPlace {
        MenuPlace(continueWatching: false, collectionId: nil, seriesId: nil, albumId: nil, artistId: nil)
    }
}
