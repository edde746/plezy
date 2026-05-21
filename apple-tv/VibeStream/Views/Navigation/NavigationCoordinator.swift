import AVFoundation
import SwiftUI

@MainActor
final class NavigationCoordinator: ObservableObject {

    // MARK: - Tab Model

    /// Tab identity — supports fixed tabs plus dynamic per-library tabs.
    enum Tab: Hashable {
        case home
        case search
        case library(key: String)
        case downloads
        case settings
    }

    enum Route: Hashable {
        case mediaDetail(ratingKey: String)
        case hubDetail(hubKey: String, title: String)
    }

    @Published var selectedTab: Tab = .home

    @Published var homePath = NavigationPath()
    @Published var libraryPaths: [String: NavigationPath] = [:]  // keyed by library key
    @Published var searchPath = NavigationPath()

    /// Background tint extracted from hero artwork — shared so detail pages
    /// can start with the same color and avoid a black flash during navigation.
    @Published var backgroundTint: Color = .black

    /// Pre-resolved hero data passed from the home page so the detail view
    /// can display the logo and description immediately (no loading gap) and
    /// animate from home-like layout to detail layout.
    struct HeroTransition {
        let metadata: PlexMetadata
        let logoSource: LogoSource
        let backgroundColor: Color
        var previewPlayer: AVPlayer?

        enum LogoSource {
            case plexClearLogo(String)
            case tmdbURL(String)
            case textOnly
        }
    }
    @Published var heroTransition: HeroTransition?

    // Player state
    @Published var isPresentingPlayer = false
    @Published var playerRatingKey: String?
    @Published var playerResumeOffset: Int?

    /// Incremented when the home screen should silently refresh its data.
    @Published var homeRefreshTrigger: UInt = 0

    // MARK: - Navigation Paths

    func pathBinding(for tab: Tab) -> Binding<NavigationPath> {
        switch tab {
        case .home:
            Binding(get: { self.homePath }, set: { self.homePath = $0 })
        case .search:
            Binding(get: { self.searchPath }, set: { self.searchPath = $0 })
        case .library(let key):
            Binding(
                get: { self.libraryPaths[key, default: NavigationPath()] },
                set: { self.libraryPaths[key] = $0 }
            )
        case .downloads, .settings:
            .constant(NavigationPath())
        }
    }

    func showMediaDetail(ratingKey: String) {
        let route = Route.mediaDetail(ratingKey: ratingKey)
        switch selectedTab {
        case .home:
            homePath.append(route)
        case .library(let key):
            libraryPaths[key, default: NavigationPath()].append(route)
        case .search:
            searchPath.append(route)
        case .downloads, .settings:
            break
        }
    }

    func showHubDetail(hubKey: String, title: String) {
        let route = Route.hubDetail(hubKey: hubKey, title: title)
        switch selectedTab {
        case .home:
            homePath.append(route)
        case .library(let key):
            libraryPaths[key, default: NavigationPath()].append(route)
        case .search:
            searchPath.append(route)
        case .downloads, .settings:
            break
        }
    }

    func playMedia(ratingKey: String, resumeOffset: Int? = nil) {
        playerRatingKey = ratingKey
        playerResumeOffset = resumeOffset
        isPresentingPlayer = true
    }

    func dismissPlayer() {
        isPresentingPlayer = false
    }

    func clearPlayerState() {
        playerRatingKey = nil
        playerResumeOffset = nil
        homeRefreshTrigger &+= 1
    }
}
