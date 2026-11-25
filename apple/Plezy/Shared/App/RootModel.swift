import Observation
import PlezyKit

/// The product's top level for SwiftUI: the shared `RootSession` (`root`: the splash while the database opens, the
/// startup failure screen when it can't, then the app), with its screen and the start's status mirrored for the views,
/// and an `AppModel` for the running app. `RootView` runs `screen.observe()` and `paintStartupTheme()`.
///
/// Built once per process from the product `AppBootstrap`.
@MainActor
@Observable
final class RootModel {
    let root: RootSession
    /// What the app shows.
    let screen: StoreObserver<any RootScreen>
    /// The start the splash names the steps of (`RootSession.startup`).
    let startup: StoreObserver<StartupUiState>
    /// The launch's update check and the dialog of the release it finds.
    let updates = UpdatePrompt()

    @ObservationIgnored private var app: AppModel?
    @ObservationIgnored private let platform: AppleAppPlatform

    /// - Parameters:
    ///   - boot: the product bootstrap (`AppBootstrap.product`).
    ///   - startup: the start the launch began before the bootstrap, which it was given.
    init(boot: AppBootstrap, platform: AppleAppPlatform, startup: Startup) {
        root = RootSession(graph: boot.graph, platform: platform, startup: startup)
        self.platform = platform
        screen = StoreObserver(root.screen)
        self.startup = StoreObserver(startup.state)
    }

    var graph: AppGraph { root.graph }

    /// Paints the theme the app will start in (`RootSession.startupAppearance`, from the stored settings once the
    /// database is open) on the splash and the failure screen, until the calling task is cancelled; the running app
    /// paints its own from then on (`AppModel`). Before it is read the device's default paints (`ThemeState`).
    func paintStartupTheme() async {
        for await appearance in root.startupAppearance {
            guard let appearance, app == nil else { continue }
            ThemeState.shared.apply(appearance.theme)
        }
    }

    /// The model of the running app `session`, the same one for as long as the session runs.
    func model(for session: AppSession) -> AppModel {
        if let app, app.session === session { return app }
        let model = AppModel(session, platform: platform)
        app = model
        return model
    }
}
