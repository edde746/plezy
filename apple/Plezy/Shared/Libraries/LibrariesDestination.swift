import SwiftUI
import PlezyKit

/// The Libraries destination: the servers' libraries (`LibrariesScreen`) and, where the device keeps downloads (not
/// Apple TV), the downloads (`DownloadsScreen`), as its sections (`LibrarySection`), switched by the view menu leading
/// either's header row (`LibraryViewMenu`: the library's tabs, then Downloads). Offline only the downloads show. A
/// section asked for from elsewhere (Home's Downloads button, a remote's Downloads tab, `--dev-open downloads`:
/// `PlezyNavigator.openLibrary`) shows at once and holds until another is picked here: the navigator keeps it, as the
/// Mac lays its window's destination out several times over and one of those taking it would leave the others on
/// Libraries. The Libraries tab picked again while it shows brings the shown lists back to their tops
/// (`scrollToTopRequests`).
struct LibrariesDestination: View {
    let app: AppModel

    @State private var chosen = LibrarySection.library
    @State private var asked: StoreObserver<LibrarySection?>
    /// The destination shows (its tab is the selected one); while it doesn't, it keeps the section it last showed, and
    /// shows none before it first shows.
    @State private var appeared = false
    @State private var held: LibrarySection?
    /// The times the Libraries tab was picked again while it showed (`PlezyNavigator.reselected`).
    @State private var reselections = 0

    init(app: AppModel, route: any Route) {
        self.app = app
        _asked = State(initialValue: StoreObserver(app.navigator.librarySection))
    }

    var body: some View {
        // The observed value redraws the destination as a section is asked for; the navigator's own value is read, as
        // the mirrored one trails a pick here by a frame. It shows once the destination does: a screen swapped in while
        // its tab hid got its appearance and disappearance at once from iOS, and none as the tab showed, so it never
        // observed its store.
        let _ = asked.state
        let shown = appeared ? app.navigator.librarySection.value ?? chosen : held
        Group {
            // Made as the destination shows, not as the shell lays its tabs out (the navigator keeps the libraries'
            // store for the route on its stack), and nothing before it first shows: a Libraries screen laid out there,
            // at no width, then swapped for the section asked for as the destination showed, kept the main thread
            // laying its header row out for good (iOS 27.0, `--dev-open downloads` signed in to a server).
            if let shown {
                LibrariesSections(app: app, chosen: Binding(get: { shown }, set: { section in
                    _ = app.navigator.takeLibrarySection()
                    chosen = section
                }))
            } else {
                Color.clear
            }
        }
        .environment(\.scrollToTopRequests, reselections)
        .task { await asked.observe() }
        .task {
            for await destination in app.navigator.reselected where destination == .libraries { reselections += 1 }
        }
        .onAppear { appeared = true }
        .onDisappear {
            held = app.navigator.librarySection.value ?? chosen
            appeared = false
        }
    }
}

/// The section shown (`chosen`, Downloads alone offline or where the libraries' store is gone) over the libraries'
/// store, whose state it mirrors while the destination shows.
private struct LibrariesSections: View {
    let app: AppModel
    @Binding var chosen: LibrarySection

    @State private var model: StoreModel<LibrariesScreenStore, LibrariesUiState>?

    init(app: AppModel, chosen: Binding<LibrarySection>) {
        self.app = app
        _chosen = chosen
        _model = State(initialValue: StoreModel(app.session.libraries()) { $0.state })
    }

    var body: some View {
        let downloads = app.session.downloads != nil
        let offline = app.shell.state.offline
        let section = !downloads ? LibrarySection.library : offline || model == nil ? .downloads : chosen
        Group {
            switch section {
            case .downloads:
                #if os(tvOS)
                EmptyView()
                #else
                DownloadsScreen(app: app, views: offline ? nil : model.map(downloadsViews))
                #endif
            default:
                if let model {
                    LibrariesScreen(app: app, model: model, onDownloads: downloads ? { chosen = .downloads } : nil)
                }
            }
        }
        .task { await model?.state.observe() }
        .onChange(of: section, initial: true) { app.librariesSection = section }
    }

    /// Downloads' view menu: the library's tabs, which show it again on that tab, then Downloads, shown. While the
    /// libraries load it shows with Downloads alone: Downloads opened as the app starts would otherwise get it ahead of
    /// what shows once the server's libraries came in, moving that menu from under a click on it.
    private func downloadsViews(_ model: StoreModel<LibrariesScreenStore, LibrariesUiState>) -> LibraryViews {
        let state = model.state.state
        let tabs = state.load == .content && state.selected != nil ? state.tabs : []
        let labels = tabs.map(\.label) + [LibrarySection.downloads.label]
        return LibraryViews(labels: labels, selected: tabs.count, loading: state.load == .loading) { index in
            guard index < tabs.count else { return }
            model.store.selectTab(tab: tabs[index])
            chosen = .library
        }
    }
}

extension LibrarySection {
    /// The section's name in the view menu.
    var label: String {
        switch self {
        case .library: T.shared.navigation.libraries
        case .downloads: T.shared.navigation.downloads
        }
    }
}
