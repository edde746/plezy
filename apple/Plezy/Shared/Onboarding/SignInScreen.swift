import SwiftUI
import PlezyKit

/// The first sign-in (`SignInStore`), an account page under Plezy's logo: Plex's PIN sign-in (`PlexPinPanel`), then
/// Connect to Jellyfin and Connect to Emby, and the store's notice (why this device was signed out) under them.
struct SignInScreen: View {
    @State private var model: SignInModel?

    init(app: AppModel, route: any Route) {
        _model = State(initialValue: SignInModel(app: app, route: route))
    }

    var body: some View {
        if let model {
            let auth = T.shared.auth
            AccountPage(title: "Plezy") {
                PlezyLogo(size: 72)
            } content: {
                PlexPinPanel(state: model.plex.state, flow: model.store.plex, tv: model.store.tv)
                Divider().padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach([MediaBrowserDialect.jellyfin, .emby], id: \.self) { dialect in
                        ActionButton(
                            title: auth.connectToMediaBrowser(product: dialect.productName),
                            id: "signin.\(dialect.id)",
                            icon: BackendMark(backend: dialect.backend, size: 20)
                        ) { model.store.connect(dialect: dialect) }
                    }
                }
                .glassGroup(spacing: 12)
                if let notice = model.notice.state {
                    Label(notice, systemImage: "info.circle")
                        .font(.callout)
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                        .announcing(notice)
                        .accessibilityIdentifier("signin.notice")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("signin.screen")
            .task { await model.observe() }
        }
    }
}

@MainActor
final class SignInModel {
    let store: SignInStore
    let plex: StoreObserver<PlexPinUiState>
    let notice: StoreObserver<String?>

    init?(app: AppModel, route: any Route) {
        guard let store = app.session.signIn(route: route) else { return nil }
        self.store = store
        plex = StoreObserver(store.plex.state)
        notice = StoreObserver(store.notice)
    }

    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.plex.observe() }
            group.addTask { await self.notice.observe() }
        }
    }
}

/// Adds a Plex account from inside the app (`AddPlexAccountStore`): Plex's PIN sign-in alone, on an account page.
struct AddPlexAccountScreen: View {
    let app: AppModel
    @State private var model: StoreModel<AddPlexAccountStore, PlexPinUiState>?

    init(app: AppModel, route: any Route) {
        self.app = app
        _model = State(initialValue: StoreModel(app.session.addPlexAccount(route: route)) { $0.plex.state })
    }

    var body: some View {
        if let model {
            AccountPage(title: T.shared.addServer.addPlexTitle) {
                PlexPinPanel(state: model.state.state, flow: model.store.plex, tv: app.appearance.state.tv)
            }
            .task { await model.state.observe() }
        }
    }
}

/// Plex's PIN sign-in (`PlexPinFlow`). At rest the buttons, disabled until the sign-in service is ready: Sign in with
/// Plex (the browser) and Show QR Code; on a TV Show QR Code first (focused) and Use browser second, none on Apple TV,
/// which has no browser. Waiting on the browser: its progress line with Retry and Cancel. The QR code: how to sign in,
/// the QR code with "plex.tv/link" and the code to enter there (`CodeAndQR`), the waiting line, the last failure (an
/// expired code's alone), Retry and Cancel. Storing the account: its progress line. Elsewhere the last failure under it
/// all. Retry and Cancel are one height: both are bordered.
struct PlexPinPanel: View {
    let state: PlexPinUiState
    let flow: PlexPinFlow
    let tv: Bool

    @FocusState private var qrFocused: Bool

    var body: some View {
        let auth = T.shared.auth
        VStack(alignment: .leading, spacing: 12) {
            switch state.phase {
            case .idle:
                VStack(alignment: .leading, spacing: 12) {
                    if tv {
                        qrButton(prominence: .primary)
                        #if !os(tvOS)
                        ActionButton(title: auth.useBrowser, id: "signin.plex", enabled: state.ready) { flow.startBrowser() }
                        #endif
                    } else {
                        ActionButton(
                            title: auth.signInWithPlex, id: "signin.plex", prominence: .primary, enabled: state.ready,
                            icon: BackendMark(backend: .plex, size: 18)
                        ) { flow.startBrowser() }
                        qrButton(prominence: .secondary)
                    }
                }
                .glassGroup(spacing: 12)
            case .browser:
                ProgressLine(text: auth.waitingForAuth)
                retryCancel
            case .qr:
                if !state.expired {
                    Text(T.shared.services.deviceCode.instructions).fixedSize(horizontal: false, vertical: true)
                    if let url = state.qrUrl, let code = state.code {
                        CodeAndQR(
                            address: "plex.tv/link", addressId: "signin.link", code: code, codeId: "signin.code",
                            qrPayload: url, qrDescription: auth.scanQRToSignIn, qrId: "signin.qrcode"
                        )
                        ProgressLine(text: T.shared.services.deviceCode.waitingForAuthorization)
                            .accessibilityIdentifier("signin.waiting")
                    } else {
                        ProgressLine(text: nil).accessibilityIdentifier("signin.qrcode.loading")
                    }
                }
                errorLine
                retryCancel
            case .registering:
                ProgressLine(text: auth.waitingForAuth)
            }
            if state.phase != .qr { errorLine }
        }
        .task(id: state.ready) {
            #if os(tvOS)
            if state.ready, state.phase == .idle { qrFocused = true }
            #endif
        }
    }

    @ViewBuilder
    private var errorLine: some View {
        if let error = state.error {
            ErrorLine(text: error).accessibilityIdentifier("signin.error")
        }
    }

    private func qrButton(prominence: ButtonProminence) -> some View {
        ActionButton(
            title: T.shared.auth.showQRCode, id: "signin.qr", prominence: prominence, systemImage: "qrcode",
            enabled: state.ready
        ) { flow.startQr() }
        .focused($qrFocused)
    }

    private var retryCancel: some View {
        HStack(spacing: 12) {
            ActionButton(title: T.shared.common.retry, id: "signin.retry", systemImage: "arrow.clockwise", fullWidth: false) { flow.retry() }
            ActionButton(title: T.shared.common.cancel, id: "signin.cancel", systemImage: "xmark", fullWidth: false) { flow.cancel() }
        }
    }
}
