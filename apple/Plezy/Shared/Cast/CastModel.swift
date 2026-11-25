import SwiftUI
import PlezyKit

/// Casting for the views: the session's sender (`CastSender`: the picker, the target Play plays on, its now-playing bar
/// and controls) and receiver (`CastReceiver`: the pairing prompt, the player's "Casting from" line), their states
/// mirrored. One per session (`AppModel.cast`), in the environment of the shell and of the player's and Now Playing's
/// covers (`cast`).
@MainActor
@Observable
final class CastModel {
    @ObservationIgnored let sender: CastSender
    @ObservationIgnored let receiver: CastReceiver
    let senderState: StoreObserver<CastSenderUiState>
    let receiverState: StoreObserver<CastReceiverUiState>

    init(session: AppSession) {
        sender = session.castSender
        receiver = session.castReceiver
        senderState = StoreObserver(sender.state)
        receiverState = StoreObserver(receiver.state)
    }

    /// Mirrors both states until the calling task is cancelled.
    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.senderState.observe() }
            group.addTask { await self.receiverState.observe() }
        }
    }
}

extension EnvironmentValues {
    /// The session's casting (`CastModel`): the cast buttons, the bar and the player's "Casting from" line read it.
    @Entry var cast: CastModel?
}

/// The cast button's symbol: a screen sending, filled while this device casts.
func castSymbol(casting: Bool) -> String {
    casting ? "tv.badge.wifi.fill" : "tv.badge.wifi"
}

extension CastDeviceKind {
    /// The picker's icon for a receiver of this kind.
    var systemImage: String {
        switch self {
        case .tv: "tv"
        case .desktop: "desktopcomputer"
        case .handheld: "iphone"
        }
    }
}

/// The picker's icon for "This device": the kind of device the app runs on.
var thisDeviceSymbol: String {
    #if os(tvOS)
    "appletv"
    #elseif os(macOS)
    "desktopcomputer"
    #else
    UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
    #endif
}
