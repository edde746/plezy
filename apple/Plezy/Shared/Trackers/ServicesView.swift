import SwiftUI
import PlezyKit

/// A sign-in opens its link in the browser at once where the user has a pointer or touch; on Apple TV, which has no
/// browser, the dialog's QR code is the way.
var trackerSignInPointer: Bool {
    #if os(tvOS)
    false
    #else
    true
    #endif
}

/// Services: the trackers' rows (mark, name, connection, chevron); the Seerr row follows them. A connected service's
/// row opens its settings; any other starts its sign-in, whose dialog shows over the screen (`trackerConnect`). Under
/// them, where the app offers it (the Mac), Integrations: Discord's Rich Presence.
///
/// Accessibility identifiers: `services.screen`, `services.row.<service id>`, `services.discord`.
struct ServicesView: View {
    let app: AppModel
    let route: any Route

    @State private var model: StoreModel<TrackerServicesStore, ServicesUiState>?

    init(app: AppModel, route: any Route) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.services(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            Form {
                Section {
                    ForEach(state.rows, id: \.service) { row in
                        ServiceRow(title: row.title, subtitle: row.subtitle, busy: row.busy, id: "services.row.\(row.service.id)") {
                            if row.connected {
                                app.navigator.navigate(route: RouteTrackerSettings(service: row.service))
                            } else {
                                model.store.connect(service: row.service, pointer: trackerSignInPointer)
                            }
                        } mark: { size in
                            TrackerLogo(service: row.service, size: size)
                        }
                    }
                    SeerrServiceRowView(app: app)
                } header: {
                    Text(state.subtitle).textCase(nil)
                }
                if let discord = state.discordPresence {
                    Section(T.shared.services.integrations) {
                        SettingsToggleRow(
                            title: T.shared.settings.discordRichPresence,
                            subtitle: T.shared.settings.discordRichPresenceDescription,
                            checked: discord.boolValue, id: "services.discord",
                            onChange: model.store.setDiscordPresence
                        )
                    }
                }
            }
            .settingsForm()
            .pageTitle(state.title)
            .trackerConnect(app: app, route: route, model: model)
            .task { await model.state.observe() }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("services.screen")
        }
    }
}

/// A service's row: its mark (`mark`, given its size), its name over its connection, then a
/// spinner while it connects, else the chevron; the whole row is the button. The trackers' rows and Seerr's.
struct ServiceRow<Mark: View>: View {
    let title: String
    let subtitle: String
    var busy = false
    let id: String
    let action: () -> Void
    @ViewBuilder let mark: (_ size: CGFloat) -> Mark

    var body: some View {
        Button(action: action) {
            HStack(spacing: Self.spacing) {
                mark(Self.logoSize)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.footnote).mutedForeground()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if busy {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .formRowButtonStyle()
        .accessibilityIdentifier(id)
    }

    /// Plezy's 24-point mark and 16-point gap; on tvOS, whose points are a 1080p screen's pixels, the same share of the
    /// screen.
    #if os(tvOS)
    private static var logoSize: CGFloat { 48 }
    private static var spacing: CGFloat { 32 }
    #else
    private static var logoSize: CGFloat { 24 }
    private static var spacing: CGFloat { 16 }
    #endif
}

extension View {
    /// The services store's sign-in on this screen while it is the top of its stack (`route`): the connect dialog as a
    /// sheet (closing it cancels the sign-in), the sign-in's link opened in the browser as the store asks, and its
    /// failure as a toast.
    func trackerConnect(app: AppModel, route: any Route, model: StoreModel<TrackerServicesStore, ServicesUiState>) -> some View {
        modifier(TrackerConnectHost(app: app, route: route, model: model))
    }
}

private struct TrackerConnectHost: ViewModifier {
    let app: AppModel
    let route: any Route
    let model: StoreModel<TrackerServicesStore, ServicesUiState>

    /// This copy of the screen (`SolePresenter`: Apple TV builds a pushed screen twice).
    @State private var copy = UUID()

    func body(content: Content) -> some View {
        let state = model.state.state
        let store = model.store
        // The screens under the top one stay alive in the navigation stack: only the top one presents, and of its
        // copies the one on screen.
        let top = app.backStack.last.map { RouteKey(route: $0) == RouteKey(route: route) } ?? false
        let presents = top && SolePresenter.shared.holds(store, copy)
        content
            .appSheet(item: presents ? state.dialog.map(ConnectDialogItem.init) : nil, size: .fullHeightForm, onDismiss: store.cancelConnect) { item in
                TrackerConnectSheet(dialog: item.dialog, onOpen: { app.session.openUrl(url: $0) }, onCancel: store.cancelConnect)
            }
            .onAppear { SolePresenter.shared.claim(store, by: copy) }
            .onDisappear { SolePresenter.shared.release(store, by: copy) }
            .onChange(of: presents ? state.openUrl : nil, initial: true) { _, url in
                guard let url else { return }
                app.session.openUrl(url: url)
                store.urlOpened()
            }
            .toast(presents ? state.message : nil, id: "services.message", onShown: store.messageShown)
    }
}

/// A connect dialog as a sheet's item: equal as Kotlin compares the dialogs.
private struct ConnectDialogItem: Equatable {
    let dialog: any ConnectDialogUi

    static func == (lhs: ConnectDialogItem, rhs: ConnectDialogItem) -> Bool {
        (lhs.dialog as AnyObject).isEqual(rhs.dialog)
    }
}
