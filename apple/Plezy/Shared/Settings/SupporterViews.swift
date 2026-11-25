import SwiftUI
import PlezyKit
#if !os(macOS)
import UIKit
#endif

/// The Supporter's settings rows and sheets over the shared stores (`AppSession.supporterSheet`,
/// `AppSession.appIconPicker`). This is the hub's top tile: the Supporter tile in builds that sell the purchase, the
/// donation tile elsewhere. `SettingsSlots` places it in the hub's first group.
struct SupporterTile: View {
    let app: AppModel
    @State private var supporterOpen = false

    init(app: AppModel) {
        self.app = app
    }

    var body: some View {
        if app.session.supporterSheet.canOpen {
            SettingsLinkRow(
                title: app.supporterTile.state.title, subtitle: app.supporterTile.state.subtitle, systemImage: "paintpalette.fill", id: "settings.supporter"
            ) {
                supporterOpen = true
            }
            .appSheet(isPresented: $supporterOpen) {
                SupporterSheet(store: app.session.supporterSheet) { supporterOpen = false }
            }
        } else if let url = app.session.donationUrl {
            SettingsLinkRow(
                title: T.shared.settings.supportDeveloper, subtitle: T.shared.settings.supportDeveloperDescription,
                systemImage: "heart.fill", trailingSymbol: "arrow.up.right", id: "settings.donate"
            ) {
                app.session.openUrl(url: url)
            }
        }
    }
}

/// The Supporter sheet, a settings form titled Supporter: the intro, the perks, the store's notice, Buy at the store's
/// price and Restore Purchases; once unlocked, thanks. Close in the sheet's bar (on Apple TV the remote's Menu, and a
/// Close button once unlocked). On Apple TV focus starts on Restore while the price loads, moves to Buy once it can act
/// and to Close on unlock. Identifiers `supporter.sheet`, `supporter.<buy|retry|restore|close>`.
struct SupporterSheet: View {
    let store: SupporterSheetStore
    let close: () -> Void
    @State private var state: StoreObserver<SupporterSheetUiState>
    @FocusState private var focus: Control?

    private enum Control: Hashable { case buy, restore, close }

    init(store: SupporterSheetStore, close: @escaping () -> Void) {
        self.store = store
        self.close = close
        _state = State(initialValue: StoreObserver(store.state))
    }

    var body: some View {
        let ui = state.state
        let strings = T.shared.supporter
        let closeAction = SheetAction(title: T.shared.common.close, id: "supporter.close", action: close)
        SheetPage(id: "supporter.sheet", title: strings.title, close: closeAction) {
            ScrollViewReader { scroll in
                Form {
                    if ui.unlocked {
                        Section {
                            VStack(spacing: 12) {
                                Image(systemName: "heart.fill").font(.system(size: 48)).foregroundStyle(Palette.primary)
                                Text(strings.thankYouTitle).font(.headline)
                                Text(strings.thankYouBody).mutedForeground().multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        #if os(tvOS)
                        Section {
                            Button(closeAction.title, action: close)
                                .focused($focus, equals: .close)
                                .accessibilityIdentifier(closeAction.id)
                        }
                        #endif
                    } else {
                        Section {
                            ForEach(ui.perks, id: \.self) { perk in
                                Label {
                                    SettingsRowText(title: perk.title, subtitle: perk.description_)
                                } icon: {
                                    Image(systemName: perk.symbol).foregroundStyle(Palette.primary)
                                }
                            }
                        } header: {
                            Text(strings.intro).textCase(nil).id("top")
                        } footer: {
                            if let notice = ui.notice {
                                Label(notice.message, systemImage: notice.pending ? "hourglass" : notice.failure ? "exclamationmark.circle" : "info.circle")
                                    .foregroundStyle(notice.failure ? Palette.error : Palette.onSurfaceVariant)
                            }
                        }
                        Section {
                            if ui.retry {
                                ActionButton(title: T.shared.common.retry, id: "supporter.retry", systemImage: "arrow.clockwise", action: store.retry)
                                    .focused($focus, equals: .buy)
                            } else {
                                ActionButton(
                                    title: ui.buyLabel, id: "supporter.buy", prominence: .primary, enabled: ui.buyEnabled,
                                    icon: SpinnerOrSymbol(spinning: ui.buySpinner, systemImage: "heart.fill"), action: store.buy
                                )
                                .focused($focus, equals: .buy)
                            }
                            ActionButton(
                                title: strings.restore, id: "supporter.restore", enabled: ui.restoreEnabled,
                                icon: SpinnerOrSymbol(spinning: ui.restoreSpinner, systemImage: "arrow.counterclockwise"), action: store.restore
                            )
                            .focused($focus, equals: .restore)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    }
                }
                .settingsForm()
                // Moving up to the top button brings the intro and perks above it, which take no focus, into view.
                .onChange(of: focus) { _, control in
                    if control == .buy || (control == .restore && !ui.buyEnabled) {
                        withAnimation(.easeOut(duration: 0.2)) { scroll.scrollTo("top", anchor: .top) }
                    }
                }
            }
        }
        .task { await state.observe() }
        .onAppear {
            store.open()
            focus = ui.unlocked ? .close : .restore
        }
        .onChange(of: ui.buyEnabled) { _, enabled in
            if enabled && focus == .restore { focus = .buy }
        }
        .onChange(of: ui.unlocked) { _, unlocked in
            if unlocked { focus = .close }
        }
    }
}

/// A button's icon while its work runs: a small spinner, else `systemImage`.
private struct SpinnerOrSymbol: View {
    let spinning: Bool
    let systemImage: String

    var body: some View {
        if spinning { ProgressView().controlSize(.small) } else { Image(systemName: systemImage) }
    }
}

private extension SupporterPerk {
    var symbol: String {
        switch self {
        case .presetThemes: "paintpalette.fill"
        case .customTheme: "eyedropper"
        case .appIcons: "square.grid.2x2.fill"
        }
    }
}

#if !os(macOS)
/// Appearance's App icon row (below Theme), with the icon shown now, following a pick; it opens the picker. Settings
/// shows it where `AppIconPickerUiState.shown`: the build offers the perks and the device switches its icon.
struct AppIconRow: View {
    let app: AppModel
    @State private var open = false

    init(app: AppModel) {
        self.app = app
    }

    var body: some View {
        SettingsLinkRow(
            title: T.shared.appIcon.title, subtitle: app.appIconPicker.state.rowSubtitle, value: app.appIconPicker.state.rowTrailingValue,
            systemImage: "app", id: "settings.appIcon"
        ) { open = true }
            .appSheet(isPresented: $open, size: .fullHeightForm) {
                AppIconPicker(app: app) { open = false }
            }
    }
}

/// Every app icon in a grid (tiles at least 76 pt wide, 3 to 8 columns) under the sheet's title, the current one ringed
/// and checked, locked alternates with a lock; Close in the bar (`close`). A locked alternate opens the Supporter sheet
/// and applies once a purchase there unlocks it. The system shows its own alert when the icon changes.
struct AppIconPicker: View {
    let app: AppModel
    let close: () -> Void
    @State private var supporterOpen = false
    @State private var width: CGFloat = 0

    init(app: AppModel, close: @escaping () -> Void) {
        self.app = app
        self.close = close
    }

    private var store: AppIconPickerStore { app.session.appIconPicker }

    var body: some View {
        let ui = app.appIconPicker.state
        let spacing: CGFloat = 12
        let columns = min(8, max(3, Int((width + spacing) / (76 + spacing))))
        SheetPage(title: T.shared.appIcon.title, close: SheetAction(title: T.shared.common.close, id: "appIcon.close", action: close)) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let hint = ui.lockedHint {
                        Text(hint).font(.footnote).mutedForeground()
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
                        ForEach(ui.tiles, id: \.id) { tile in
                            Button { store.choose(id: tile.id) } label: { AppIconTile(tile: tile) }
                                .cardButtonStyle()
                                .accessibilityLabel(tile.label)
                                .accessibilityValue(tile.stateLabel ?? "")
                                .accessibilityIdentifier("appIcon.\(tile.id)")
                        }
                    }
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
                }
                .padding(20)
            }
        }
        .task {
            store.refresh()
            for await event in store.events {
                switch onEnum(of: event) {
                case .openSupporter: supporterOpen = true
                }
            }
        }
        .appSheet(isPresented: Binding(get: { supporterOpen }, set: { shown in
            if !shown {
                supporterOpen = false
                store.supporterSheetClosed()
            }
        })) {
            SupporterSheet(store: app.session.supporterSheet) {
                supporterOpen = false
                store.supporterSheetClosed()
            }
        }
    }
}

/// One icon of the picker: its picture as the home screen shows it, the current one ringed with a check, a locked one
/// with a lock, its name under it.
private struct AppIconTile: View {
    let tile: AppIconTileUi

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        VStack(spacing: 6) {
            AppIconPreview(id: tile.id)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(shape)
                .overlay { if tile.current { shape.strokeBorder(Palette.primary, lineWidth: 3) } }
                .overlay(alignment: .bottomTrailing) {
                    if tile.current || tile.locked {
                        Image(systemName: tile.current ? "checkmark" : "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(tile.current ? Palette.onPrimary : Palette.onBackground)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(tile.current ? Palette.primary : Palette.surfaceContainer))
                            .overlay(Circle().strokeBorder(Palette.background, lineWidth: 1.5))
                            .padding(4)
                    }
                }
            Text(tile.label)
                .font(.caption.weight(tile.current ? .bold : .regular))
                .foregroundStyle(tile.current ? Palette.onBackground : Palette.onSurfaceVariant)
                .lineLimit(1)
        }
    }
}

/// The icon as this device's home screen draws it: the alternates' bundled thumbnails (app_icons/previews); the default
/// on Apple TV as its dark plate (default-tvos), on iPhone and iPad the logo on the icon's light plate.
private struct AppIconPreview: View {
    let id: String

    var body: some View {
        #if os(tvOS)
        let name: String? = id == "default" ? "default-tvos" : id
        #else
        let name: String? = id == "default" ? nil : id
        #endif
        if let name, let path = Bundle.main.path(forResource: name, ofType: "webp", inDirectory: "app_icons/previews"),
           let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Color(red: 0.946, green: 0.946, blue: 0.946)
                .overlay { Image("DefaultIconPreview").resizable().scaledToFit().padding(12) }
        }
    }
}
#endif
