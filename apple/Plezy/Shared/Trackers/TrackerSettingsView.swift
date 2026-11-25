import SwiftUI
import PlezyKit

/// A connected service's settings: its account (and Simkl's Reconnect while the connection uses the sign-in Simkl is
/// retiring), its switches and library filter, and Disconnect, which asks first. Once the service is no longer
/// connected, the screen closes.
///
/// Accessibility identifiers: `trackerSettings.screen`, `trackerSettings.account`, `trackerSettings.reconnect`,
/// `trackerSettings.toggle.<scrobble|watchedSync>`, `trackerSettings.libraryFilter`, `trackerSettings.disconnect`,
/// `trackerSettings.disconnect.<confirm|cancel>`.
struct TrackerSettingsView: View {
    let app: AppModel
    let route: RouteTrackerSettings

    @State private var model: StoreModel<TrackerServicesStore, ServicesUiState>?
    @State private var confirming = false

    init(app: AppModel, route: RouteTrackerSettings) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.services(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let service = route.service
            let settings = model.state.state.settings(service: service)
            // A ZStack, not a Group: a Group hands its modifiers to its content, so with the settings gone (the
            // content empty) the pop below had nothing to run on and the screen stayed up blank.
            ZStack {
                if let settings {
                    form(settings, store: model.store)
                        .confirmation(
                            confirming ? confirmation(settings.disconnectConfirm) : nil,
                            onConfirm: {
                                confirming = false
                                model.store.disconnect(service: service)
                            },
                            onCancel: { confirming = false }
                        )
                }
            }
            .trackerConnect(app: app, route: route, model: model)
            .task { await model.state.observe() }
            .onChange(of: settings == nil, initial: true) { _, gone in
                if gone { _ = app.navigator.pop(route: route) }
            }
        }
    }

    private func form(_ settings: TrackerSettingsUi, store: TrackerServicesStore) -> some View {
        let service = route.service
        return Form {
            Section {
                HStack(spacing: 16) {
                    TrackerLogo(service: service, size: Self.logoSize)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.accountTitle).font(.headline)
                        if let subtitle = settings.accountSubtitle {
                            Text(subtitle).font(.footnote).mutedForeground()
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("trackerSettings.account")
                if let reconnect = settings.reconnect {
                    SettingsLinkRow(
                        title: reconnect.title, subtitle: reconnect.subtitle, systemImage: "arrow.triangle.2.circlepath",
                        trailingSymbol: nil, id: "trackerSettings.reconnect"
                    ) {
                        store.reconnect(service: service, pointer: trackerSignInPointer)
                    }
                }
            }
            Section(settings.behaviorTitle) {
                ForEach(settings.toggles, id: \.toggle) { toggle in
                    SettingsToggleRow(title: toggle.title, subtitle: toggle.subtitle, checked: toggle.on, id: "trackerSettings.toggle.\(toggle.toggle.idSuffix)") {
                        store.setToggle(service: service, toggle: toggle.toggle, on: $0)
                    }
                }
                SettingsLinkRow(
                    title: settings.libraryFilterTitle, subtitle: settings.libraryFilterSubtitle, value: settings.libraryFilterTrailingValue,
                    systemImage: "line.3.horizontal.decrease", id: "trackerSettings.libraryFilter"
                ) {
                    app.navigator.navigate(route: RouteTrackerLibraryFilter(service: service))
                }
            }
            Section {
                Button(role: .destructive) { confirming = true } label: {
                    Label(settings.disconnect, systemImage: "rectangle.portrait.and.arrow.right")
                        .destructiveLabel(rest: Palette.error)
                }
                .formRowButtonStyle()
                .accessibilityIdentifier("trackerSettings.disconnect")
            }
        }
        .settingsForm()
        .pageTitle(settings.title)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trackerSettings.screen")
    }

    private func confirmation(_ confirm: DisconnectConfirmUi) -> Confirmation {
        Confirmation(
            title: confirm.title,
            message: confirm.body,
            confirmLabel: confirm.confirm,
            cancelLabel: confirm.cancel,
            confirmId: "trackerSettings.disconnect.confirm",
            cancelId: "trackerSettings.disconnect.cancel"
        )
    }

    /// A tracker's mark: 24 pt, on tvOS 48 (the same share of its screen).
    #if os(tvOS)
    private static let logoSize: CGFloat = 48
    #else
    private static let logoSize: CGFloat = 24
    #endif
}

private extension TrackerToggle {
    var idSuffix: String {
        switch self {
        case .scrobble: "scrobble"
        case .watchedSync: "watchedSync"
        }
    }
}

/// A service's library filter: the mode's hint, the mode (Blacklist or Whitelist) and a switch per library, by server
/// where there is more than one; each change is kept at once.
///
/// Accessibility identifiers: `libraryFilter.screen`, `libraryFilter.mode`, `libraryFilter.library.<global key>`.
struct LibraryFilterView: View {
    let app: AppModel
    let route: RouteTrackerLibraryFilter

    @State private var model: StoreModel<TrackerServicesStore, ServicesUiState>?

    init(app: AppModel, route: RouteTrackerLibraryFilter) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.services(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let service = route.service
            let state = model.state.state
            // A ZStack, not a Group, so the pop runs with the filter gone (TrackerSettingsView).
            ZStack {
                if let filter = state.filter(service: service) {
                    form(filter, store: model.store)
                }
            }
            .task { await model.state.observe() }
            .onChange(of: state.settings(service: service) == nil, initial: true) { _, gone in
                if gone { _ = app.navigator.pop(route: RouteTrackerSettings(service: service)) }
            }
        }
    }

    private func form(_ filter: LibraryFilterUi, store: TrackerServicesStore) -> some View {
        let service = route.service
        let mode = Binding(
            get: { filter.modes.first(where: \.selected)?.mode ?? .blacklist },
            set: { store.setFilterMode(service: service, mode: $0) }
        )
        return Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(filter.modeTitle)
                    Picker(filter.modeTitle, selection: mode) {
                        ForEach(filter.modes, id: \.mode) { Text($0.label).tag($0.mode) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityIdentifier("libraryFilter.mode")
                }
            } header: {
                Text(filter.hint).textCase(nil)
            }
            ForEach(Array(filter.groups.enumerated()), id: \.offset) { _, group in
                Section(group.title) {
                    ForEach(group.libraries, id: \.globalKey) { library in
                        SettingsToggleRow(title: library.title, subtitle: nil, checked: library.on, id: "libraryFilter.library.\(library.globalKey)") {
                            store.setLibraryFiltered(service: service, globalKey: library.globalKey, on: $0)
                        }
                    }
                    if group.libraries.isEmpty, let empty = filter.empty {
                        Text(empty).mutedForeground()
                    }
                }
            }
        }
        .settingsForm()
        .pageTitle(filter.title)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("libraryFilter.screen")
    }
}
