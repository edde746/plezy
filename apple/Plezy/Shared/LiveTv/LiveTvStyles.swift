import SwiftUI
import PlezyKit

/// The system's clock as the Live TV stores take it (`use24HourClock`).
enum LiveTvClock {
    /// 24-hour, unless the locale's hour (the "j" template) carries an AM/PM marker.
    static var uses24Hour: Bool {
        !(DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "").contains("a")
    }
}

extension View {
    /// Runs `action` with the system's clock (`LiveTvClock.uses24Hour`) each time the locale's settings change.
    func onClockChange(_ action: @escaping (Bool) -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)) { _ in
            action(LiveTvClock.uses24Hour)
        }
    }

    /// `focused(_:equals:)` on `field` where `condition` holds (a tab's first control); the view as it is otherwise.
    @ViewBuilder
    func focused(_ binding: FocusState<LiveTvField?>.Binding, as field: LiveTvField, when condition: Bool) -> some View {
        if condition {
            focused(binding, equals: field)
        } else {
            self
        }
    }

    /// The Record Options sheet of `store` while it is set; closed by the user, it is cancelled.
    func recordOptionsSheet(_ store: RecordOptionsStore?) -> some View {
        appSheet(item: store, onDismiss: { store?.cancel() }) { options in
            RecordOptionsSheet(store: options)
        }
    }

    /// A store's destructive `confirmation` (cancel a recording, delete a rule) in the system alert (`confirmation`)
    /// while it is set: the confirm button (destructive) and Cancel; dismissed without an answer, `onCancel`.
    func liveTvConfirmation(_ confirmation: LiveTvConfirmation?, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        self.confirmation(
            confirmation.map {
                Confirmation(
                    title: $0.title, message: $0.message, confirmLabel: $0.confirmText, cancelLabel: T.shared.common.cancel,
                    confirmId: "livetv.confirm", cancelId: "livetv.confirm.cancel"
                )
            },
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

extension AppModel {
    /// A Live TV image (a channel's logo, an airing's poster) on `serverId`'s server, drawn as `kind`; nil without the
    /// server, the path or a connected client.
    func liveTvArtwork(serverId: String?, path: String?, kind: ImageKind) -> Artwork? {
        guard let serverId, !serverId.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return Artwork.companion.of(backend: session.servers.store.client(serverId: serverId), path: path, kind: kind)
    }
}

/// A chip of the Live TV screen (its tabs on Apple TV, the guide's time navigation), as the guide's chips are: the app's
/// chip (`chipLabel`, `ChipStyle`), the selected one's name semibold after a checkmark, each as wide either way so a
/// pick moves no chip.
struct LiveTvChip<Label: View>: View {
    var selected = false
    let id: String
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @Environment(\.formFactor) private var formFactor

    var body: some View {
        Button(action: action) {
            ZStack {
                checked.opacity(selected ? 1 : 0).accessibilityHidden(!selected)
                label().fontWeight(.regular).opacity(selected ? 0 : 1).accessibilityHidden(selected)
            }
            .chipLabel(formFactor)
        }
        .modifier(ChipStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }

    private var checked: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark").fontWeight(.bold)
            label().fontWeight(.semibold)
        }
    }
}

extension LiveTvChip where Label == Text {
    init(_ title: String, selected: Bool = false, id: String, action: @escaping () -> Void) {
        self.init(selected: selected, id: id, action: action) { Text(title) }
    }
}

/// A `LiveTvChip` that opens `options` in the system's menu (the guide's day picker), which on Apple TV gives it focus
/// back as it closes: the app's chip (`chipLabel`, `ChipStyle`).
struct LiveTvMenuChip<Label: View, Options: View>: View {
    let id: String
    @ViewBuilder let options: () -> Options
    @ViewBuilder let label: () -> Label

    @Environment(\.formFactor) private var formFactor

    var body: some View {
        Menu(content: options) {
            label().fontWeight(.regular).chipLabel(formFactor)
        }
        #if os(macOS)
        // A Mac's menu takes no button style without it: the chip's glass as its look.
        .menuStyle(.button)
        #endif
        #if !os(tvOS)
        // The label draws its own chevron.
        .menuIndicator(.hidden)
        #endif
        .modifier(ChipStyle())
        .accessibilityIdentifier(id)
    }
}
