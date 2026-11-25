import SwiftUI
import PlezyKit

/// The profile's Seerr account: who is signed in and how, the instance and its address, and Disconnect (asked first).
/// The screen closes once the account has no session, disconnected here or dropped in the background.
struct SeerrSettingsScreen: View {
    let app: AppModel
    let route: RouteSeerrSettings

    @State private var model: StoreModel<SeerrSettingsStore, SeerrSettingsUiState>?

    init(app: AppModel, route: RouteSeerrSettings) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.seerrSettings(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            Form {
                Section {
                    Label { SettingsRowText(title: state.connectedAs, subtitle: state.method) } icon: { Image(systemName: "person.crop.circle.fill") }
                    Label { SettingsRowText(title: state.instanceLabel, subtitle: state.baseUrl) } icon: { Image(systemName: "server.rack") }
                }
                Section {
                    Button(role: .destructive, action: model.store.requestDisconnect) {
                        Label(state.disconnectLabel, systemImage: "rectangle.portrait.and.arrow.right").destructiveLabel(rest: Palette.error)
                    }
                    .accessibilityIdentifier("seerrSettings.disconnect")
                }
            }
            .settingsForm()
            .navigationTitle(state.title)
            .inlineNavigationTitle()
            .confirmation(
                state.confirm.map {
                    Confirmation(
                        title: $0.title, message: $0.message, confirmLabel: $0.confirmLabel, cancelLabel: $0.cancelLabel,
                        confirmId: "seerrSettings.confirm", cancelId: "seerrSettings.cancel"
                    )
                },
                onConfirm: model.store.confirmDisconnect,
                onCancel: model.store.cancelDisconnect
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("seerrSettings.screen")
            .task { await model.state.observe() }
            .onChange(of: state.closed, initial: true) {
                if state.closed { _ = app.navigator.pop(route: route) }
            }
        }
    }
}

/// The Services section's Seerr row, as the trackers' rows: Seerr's mark, "Seerr" over its connection; it opens the
/// account's settings while connected, else the connect screen.
struct SeerrServiceRowView: View {
    let app: AppModel

    @State private var session: SeerrSession?

    init(app: AppModel) {
        self.app = app
        _session = State(initialValue: app.session.seerr.session.value)
    }

    var body: some View {
        let row = SeerrServiceRow.companion.of(session: session)
        ServiceRow(title: row.title, subtitle: row.subtitle, id: "settings.seerr") {
            app.navigator.navigate(route: row.connected ? RouteSeerrSettings.shared : RouteSeerrConnect.shared)
        } mark: { size in
            SeerrLogo(size: size)
        }
        .task {
            for await value in app.session.seerr.session { session = value }
        }
    }
}
