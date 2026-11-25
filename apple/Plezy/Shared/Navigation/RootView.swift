import SwiftUI
import PlezyKit

/// The product app: the splash while the database opens, the startup failure screen when it can't or the earlier
/// releases' data can't be imported (its Retry starts again), then the running app (`RootSession.screen`), with the
/// launch's update check once it shows and the dialog of the release that finds (`UpdatePrompt`). The splash and the
/// failure screen paint the theme the app will start in once the stored settings are read
/// (`RootModel.paintStartupTheme()`).
struct RootView: View {
    let root: RootModel

    var body: some View {
        let screen = onEnum(of: root.screen.state)
        let shell = if case .main = screen { true } else { false }
        Group {
            switch screen {
            case .starting:
                StartingView(startup: root.startup)
            case .failed(let failed):
                StartupFailureView(failure: failed.record) { root.root.retry() }
            case .main(let main):
                let app = root.model(for: main.app)
                SessionShell(app: app)
                    .task { root.updates.checkAtLaunch(graph: root.graph) }
            }
        }
        // Before the shell the vertical bar would hold the status bar alone.
        .verticalBarDisabled(!shell)
        .updatePrompt(root.updates)
        .task { await root.screen.observe() }
        .task { await root.paintStartupTheme() }
    }
}

/// The running app's shell (`AppShell`), made anew for each app and each active profile (`AppSession.profileSession`):
/// a profile switch restarts the navigator and releases every screen's store, so no screen of the last profile stays.
/// The product's app and a `--dev` session's.
struct SessionShell: View {
    let app: AppModel

    var body: some View {
        AppShell(app: app)
            .id(ShellIdentity(app: ObjectIdentifier(app), profileSession: app.profileSession.state.intValue))
    }
}

private struct ShellIdentity: Hashable {
    let app: ObjectIdentifier
    let profileSession: Int
}

/// The splash, while the app starts: the loader in the middle of the screen, whatever its safe areas, and, under it,
/// the step the start is on (`StartupUiState.status`: none until the start has taken half a second). `startup` is nil
/// before the launch has read its options, and for a `--dev` session.
struct StartingView: View {
    let startup: StoreObserver<StartupUiState>?

    var body: some View {
        LoadingStateView {
            if let status = startup?.state.status {
                Text(status)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("startup.status")
            }
        }
        .ignoresSafeArea()
        .background(Palette.background)
        .task { await startup?.observe() }
    }
}
