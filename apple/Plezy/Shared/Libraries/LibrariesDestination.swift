import SwiftUI
import PlezyKit

/// The Libraries destination: the servers' libraries (`LibrariesScreen`) over the libraries' store, whose state it
/// mirrors while it shows. The Libraries tab picked again while it shows brings the shown lists back to their tops
/// (`scrollToTopRequests`).
struct LibrariesDestination: View {
    let app: AppModel

    @State private var model: StoreModel<LibrariesScreenStore, LibrariesUiState>?
    /// The times the Libraries tab was picked again while it showed (`PlezyNavigator.reselected`).
    @State private var reselections = 0

    init(app: AppModel, route: any Route) {
        self.app = app
        _model = State(initialValue: StoreModel(app.session.libraries()) { $0.state })
    }

    var body: some View {
        Group {
            if let model { LibrariesScreen(app: app, model: model) }
        }
        .environment(\.scrollToTopRequests, reselections)
        .task { await model?.state.observe() }
        .task {
            for await destination in app.navigator.reselected where destination == .libraries { reselections += 1 }
        }
    }
}
