import SwiftUI
import PlezyKit

/// Where other features draw into Settings: the rows of the hub and of Appearance those features own (`SettingSlotRow`),
/// the screens of other features the hub opens, and the App icon page, which the app icons' feature draws.
@MainActor
enum SettingsSlots {
    /// Whether `slot`'s row shows: a row whose provider draws nothing is left out of its group, so the group's corners
    /// stay right. The Supporter tile shows in purchasable builds, the donation tile in donation builds; App icon where
    /// the perks are offered and the device switches its icon (not the Mac); Download location on the Mac with
    /// downloads (iPhone and iPad keep them in the app's container, Apple TV has none). Background downloads has no
    /// provider.
    static func shown(_ slot: SettingSlot, app: AppModel) -> Bool {
        switch slot {
        case .supporter:
            return app.session.supporterSheet.canOpen || app.session.donationUrl != nil
        case .appIcon:
            #if os(macOS)
            return false
            #else
            return app.session.appIconPicker.state.value.shown
            #endif
        case .downloadLocation:
            #if os(macOS)
            return app.session.downloadLocation != nil
            #else
            return false
            #endif
        case .backgroundDownloads:
            // Android's background-run warning (the hub lists it on Android phones only).
            return false
        }
    }

    /// `slot`'s row, drawn by the feature that owns it, `id` its harness name; nothing where `shown` is false.
    @ViewBuilder
    static func row(_ slot: SettingSlot, app: AppModel, id: String) -> some View {
        switch slot {
        case .supporter:
            SupporterTile(app: app)
        case .appIcon:
            #if os(macOS)
            EmptyView()
            #else
            AppIconRow(app: app)
            #endif
        case .downloadLocation:
            #if os(macOS)
            if let model = app.session.downloadLocation { DownloadLocationRow(model: model, id: id) }
            #else
            EmptyView()
            #endif
        case .backgroundDownloads: EmptyView() // never listed on Apple (`shown`)
        }
    }

    /// Opens another feature's screen from Settings (`SettingsEvent.OpenExternal`): Services, the profile picker, Add
    /// connection, the donation page. The Supporter sheet opens from its own tile.
    static func openExternal(_ target: ExternalTarget, app: AppModel) {
        switch target {
        case .services: app.navigator.navigate(route: RouteServices.shared)
        case .profiles: app.navigator.navigate(route: RouteProfilePicker(required: false, manage: true))
        case .addConnection: app.session.onboarding.addConnection()
        case .donate: if let url = app.session.donationUrl { app.session.openUrl(url: url) }
        case .supporter: break
        case .logout: app.session.userMenu.act(action: .logout)
        }
    }
}
