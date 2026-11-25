import SwiftUI
import PlezyKit
#if os(tvOS)
import UIKit
#endif

/// The catalog screens' `CatalogDetailHost` on Apple platforms. iPhone, iPad and the Mac have a browser: links and the
/// provider's trailer open in it (`ApplePlatform.openURL`). Apple TV has none: there only the YouTube app's
/// `youtube://` links open, once `canOpenURL` says the app is installed. A library copy's own trailer plays in the
/// session's player. The shared core may ask from any thread; the opening itself runs on the main thread.
final class AppleCatalogHost: CatalogDetailHost, @unchecked Sendable {
    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    var hasBrowser: Bool {
        #if os(tvOS)
        false
        #else
        true
        #endif
    }

    /// The system's 12/24-hour clock, as the detail is built.
    var use24HourClock: Bool { LiveTvClock.uses24Hour }

    func __youTubeAppInstalled() async throws -> KotlinBoolean {
        #if os(tvOS)
        let installed = await MainActor.run { UIApplication.shared.canOpenURL(URL(string: "youtube://")!) }
        return KotlinBoolean(bool: installed)
        #else
        return KotlinBoolean(bool: false)
        #endif
    }

    func openUrl(url: String) -> Bool {
        #if os(tvOS)
        guard let target = URL(string: url), target.scheme == "youtube" else { return false }
        DispatchQueue.main.async { UIApplication.shared.open(target) }
        #else
        guard WebUrl.shared.isWeb(url: url) else { return false }
        DispatchQueue.main.async { ApplePlatform.openURL(url) }
        #endif
        return true
    }

    func playTrailer(trailer: MediaItem) -> Bool {
        session.playLibraryTrailer(trailer: trailer)
    }
}

/// What a catalog card does on every catalog surface (Explore's shelves, its search, a View All grid, More like this):
/// it opens the title's detail on the shown stack, and its menu is `CatalogItemMenu`'s (View details, Watch trailer,
/// Open on <site>, Add to or Remove from Watchlist). A card's entries are read ahead (`prepare`), the watchlist's
/// membership loaded first so its entry is there; a menu entry's failure shows as `message`.
@MainActor
@Observable
final class CatalogActions {
    /// A failed entry's message ("Couldn't update watchlist") until the screen has shown it.
    var message: String?

    @ObservationIgnored private let app: AppModel
    @ObservationIgnored private(set) lazy var host = AppleCatalogHost(session: app.session)
    @ObservationIgnored private lazy var menu = app.session.catalogMenu(host: host)
    /// The catalog title each card stands for, by the card's id.
    @ObservationIgnored private var items: [String: CatalogItem] = [:]
    private var entries: [String: [CatalogMenuEntry]] = [:]

    init(app: AppModel) {
        self.app = app
    }

    /// Opens `item`'s detail screen.
    func open(_ item: CatalogItem) {
        app.navigator.navigate(route: RouteCatalogDetail(item: item))
    }

    /// Opens the detail of the title `card` stands for.
    func open(card: MediaCardUi) {
        if let item = items[card.id] { open(item) }
    }

    /// `card`'s menu entries, once read (`prepare`); none before.
    func menu(card: MediaCardUi) -> [ItemMenuEntry] {
        guard let item = items[card.id], let entries = entries[card.id] else { return [] }
        return entries.map { entry in
            ItemMenuEntry(label: entry.label, systemImage: entry.action.systemImage) { self.run(card.id, item, entry.action) }
        }
    }

    /// Reads the entries of the catalog titles among `media` (catalog stand-ins), their watchlists' membership loaded
    /// first. Run again when a screen shows (another screen may have changed a watchlist).
    func prepare(_ media: [MediaItem]) async {
        let titles = media.compactMap { item in item.catalogItem.map { (item.id, $0) } }
        for (id, item) in titles { items[id] = item }
        let sources = app.session.catalogSources.value
        var loaded = Set<String>()
        do {
            for (_, item) in titles {
                guard let source = sources.watchlistSourceFor(item: item), loaded.insert(source.id.id).inserted else { continue }
                try await Self.loadWatchlist(UncheckedBox(source))
            }
            for (id, item) in titles {
                entries[id] = try await Self.entries(UncheckedBox(menu), UncheckedBox(item)).value
            }
        } catch {
            // Cancelled with the screen: what was read stays.
            return
        }
    }

    private func run(_ id: String, _ item: CatalogItem, _ action: CatalogMenuAction) {
        if case .viewDetails = onEnum(of: action) {
            open(item)
            return
        }
        let menu = UncheckedBox(menu), call = UncheckedBox((item, action))
        Task {
            do {
                message = try await Self.run(menu, call)
                entries[id] = try await Self.entries(menu, UncheckedBox(call.value.0)).value
            } catch {
                return
            }
        }
    }

    // The shared core's suspending calls, off the main actor with their Kotlin values boxed (`UncheckedBox`).

    nonisolated private static func loadWatchlist(_ source: UncheckedBox<any CatalogSource>) async throws {
        try await source.value.ensureWatchlistLoaded()
    }

    nonisolated private static func entries(
        _ menu: UncheckedBox<CatalogItemMenu>, _ item: UncheckedBox<CatalogItem>
    ) async throws -> UncheckedBox<[CatalogMenuEntry]> {
        UncheckedBox(try await menu.value.entries(item: item.value))
    }

    nonisolated private static func run(
        _ menu: UncheckedBox<CatalogItemMenu>, _ call: UncheckedBox<(CatalogItem, CatalogMenuAction)>
    ) async throws -> String? {
        try await menu.value.run(item: call.value.0, action: call.value.1)
    }
}

extension CatalogMenuAction {
    /// The SF Symbol beside the entry.
    var systemImage: String {
        switch onEnum(of: self) {
        case .viewDetails: "info.circle"
        case .trailer: "play.circle"
        case .link: "arrow.up.right.square"
        case .watchlist(let watchlist): watchlist.add ? "bookmark" : "bookmark.fill"
        }
    }
}
