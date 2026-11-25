import SwiftUI
import PlezyKit

/// The screen of one route. The player and Now Playing are never in a `NavigationStack` (`RouteStack` leaves them out),
/// so their routes have no screen here.
struct RouteView: View {
    let app: AppModel
    let route: any Route

    var body: some View {
        screen
            .id(RouteKey(route: route))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.background)
            #if os(tvOS)
            // The tab bar names a destination's screen: no second title over it.
            .toolbar(TopLevelDestination.companion.of(route: route) != nil ? .hidden : .automatic, for: .navigationBar)
            // A pushed screen takes the whole screen: Menu goes back to the destination, whose
            // tab bar shows again.
            .toolbar(TopLevelDestination.companion.of(route: route) != nil ? .automatic : .hidden, for: .tabBar)
            #endif
    }

    @ViewBuilder
    private var screen: some View {
        switch onEnum(of: route) {
        case .home:
            HomeView(app: app, route: route)
        case .libraries:
            LibrariesDestination(app: app, route: route)
        case .liveTv:
            LiveTvRoute(app: app, route: route)
        case .liveTvShowSchedule:
            ShowScheduleRoute(app: app, route: route)
        case .search:
            SearchScreen(app: app, route: route)
        #if os(tvOS)
        // Apple TV keeps no downloads: nothing leads here.
        case .syncRules:
            EmptyView()
        #else
        case .syncRules:
            SyncRulesScreen(app: app)
        #endif
        case .settings, .settingsPage:
            SettingsScreen(app: app, route: route)
        case .services:
            ServicesView(app: app, route: route)
        case .trackerSettings(let route):
            TrackerSettingsView(app: app, route: route)
        case .trackerLibraryFilter(let route):
            LibraryFilterView(app: app, route: route)
        case .musicArtist(let artist):
            ArtistScreen(app: app, route: artist)
        case .musicAlbum(let album):
            AlbumScreen(app: app, route: album)
        case .musicPlaylist(let playlist):
            MusicPlaylistScreen(app: app, route: playlist)
        case .explore:
            ExploreScreen(app: app, route: route)
        case .exploreRow(let row):
            ExploreRowScreen(app: app, route: row)
        case .catalogSearch(let search):
            CatalogSearchScreen(app: app, route: search)
        case .catalogDetail(let detail):
            CatalogDetailScreen(app: app, route: detail)
        case .seerrConnect(let connect):
            SeerrConnectScreen(app: app, route: connect)
        case .seerrSettings(let settings):
            SeerrSettingsScreen(app: app, route: settings)
        case .seerrRequest(let request):
            SeerrRequestSheet(app: app, route: request)
        case .seerrPerson(let person):
            SeerrPersonScreen(app: app, route: person)
        case .player, .nowPlaying:
            EmptyView()
        case .signIn:
            SignInScreen(app: app, route: route)
        case .profilePicker:
            ProfilePickerScreen(app: app, route: route)
        case .addProfile:
            AddProfileScreen(app: app, route: route)
        case .profileDetail:
            ProfileDetailScreen(app: app, route: route)
        case .addConnection:
            AddConnectionScreen(app: app, route: route)
        case .addPlexAccount:
            AddPlexAccountScreen(app: app, route: route)
        case .addMediaBrowser:
            AddMediaBrowserScreen(app: app, route: route)
        case .editConnection:
            EditConnectionScreen(app: app, route: route)
        case .borrowConnection:
            BorrowConnectionScreen(app: app, route: route)
        case .mediaDetail(let detail):
            MediaDetailScreen(app: app, route: detail)
        case .person(let person):
            PersonScreen(app: app, route: person)
        case .collectionDetail(let collection):
            CollectionScreen(app: app, route: collection)
        case .metadataEdit(let edit):
            MetadataEditScreen(app: app, route: edit)
        case .plexMatch(let match):
            PlexMatchScreen(app: app, route: match)
        case .hubDetail(let detail):
            HubDetailView(app: app, route: detail)
        case .playlistDetail(let playlist):
            PlaylistDetailView(app: app, route: playlist)
        case .watchTogether:
            WatchTogetherRoute(app: app, route: route)
        }
    }
}
