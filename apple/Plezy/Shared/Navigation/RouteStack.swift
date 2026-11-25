import SwiftUI
import PlezyKit

/// The screens of `stack` in a `NavigationStack`: its root is the stack's bottom (a destination's route; a development
/// session's first screen), the routes above it are the path, the player and Now Playing excepted (Now Playing shows
/// over the chrome, `AppShell`). Popping the path (the back button, swipe-back, the remote's Back) pops the navigator;
/// the stack shows the shortened path until the navigator's state, which reaches the view a moment later, follows
/// (`poppedTo`). A stack another root replaces (the sidebar switched destinations) may empty its path as it goes, after
/// the navigator shows the next destination, whose stack doesn't hold the page (a screen is on one stack at a time):
/// no pop, and taken for one it left the stack's next root drawn without its pages for a moment (Settings' hub before
/// its General page). Every page is in the path, none pushed by a screen on its own: the Mac's split view keeps such a
/// page in its detail column after the sidebar has switched destinations. On iOS the music mini-player docks at its
/// foot where the tab view doesn't hold it; on the Mac each screen clears the playback bar floating over its foot
/// (`musicBarRoom`). The screen on top holds the band of `toasts` (the shell's, `toastBand`), above that bar.
struct RouteStack: View {
    let app: AppModel
    let stack: [any Route]
    let toasts: ToastRelay?

    /// How many pages SwiftUI left when it last shortened the path, until the pages follow.
    @State private var poppedTo: Int?
    #if os(iOS)
    /// The stack's top safe area, its navigation bar's not in it (`stackTop`).
    @State private var stackTop: CGFloat?
    #endif

    var body: some View {
        let root = stack[0]
        let pages = stack.dropFirst().filter { !($0 is RoutePlayer || $0 is RouteNowPlaying) }.map(RouteKey.init)
        let shown = poppedTo.map { Array(pages.prefix($0)) } ?? pages
        NavigationStack(path: pathBinding(pages, shown: shown)) {
            RouteView(app: app, route: root)
                .toastBand(shown.isEmpty ? toasts : nil)
                #if !os(tvOS)
                // The chrome names the destination: no second title while its screen is on top.
                .destinationChrome(TopLevelDestination.companion.of(route: root), onTop: shown.isEmpty)
                #endif
                // Outside the chrome, which narrows the top safe area: the whole band.
                .windowToolbarBand()
                #if os(macOS)
                .musicBarRoom()
                #endif
                .navigationDestination(for: RouteKey.self) { key in
                    RouteView(app: app, route: key.route)
                        .toastBand(key == shown.last ? toasts : nil)
                        .windowToolbarBand()
                        #if os(macOS)
                        .musicBarRoom()
                        #endif
                }
        }
        #if os(iOS)
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { stackTop = $0 }
        .environment(\.stackTop, stackTop)
        #endif
        // A stack of its own per root: a destination the sidebar switches to (the Mac's one detail column) starts on a
        // new stack rather than the previous destination's.
        .id(RouteKey(route: root))
        .onChange(of: pages) { poppedTo = nil }
        #if os(iOS)
        .musicMiniPlayer()
        #endif
    }

    /// The stack's path: `shown`, the start of `pages` while a pop hasn't reached them yet.
    private func pathBinding(_ pages: [RouteKey], shown: [RouteKey]) -> Binding<[RouteKey]> {
        Binding(
            get: { shown },
            set: { newPath in
                // SwiftUI only shortens the path (pushes go through the navigator): undo the first page it dropped,
                // where the shown stack holds it.
                guard newPath.count < shown.count, app.navigator.pop(route: pages[newPath.count].route) else { return }
                poppedTo = newPath.count
            }
        )
    }
}

/// A route as a `NavigationStack` path element: routes are Kotlin values, equal and hashed as Kotlin compares them.
struct RouteKey: Hashable {
    let route: any Route

    static func == (lhs: RouteKey, rhs: RouteKey) -> Bool {
        (lhs.route as AnyObject).isEqual(rhs.route)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine((route as AnyObject).hash)
    }
}
