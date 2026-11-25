import SwiftUI
import PlezyKit

/// A `plezy://` link (an item's Show link, a profile's Show profile link) as a `SheetPage` for an `appSheet`: a QR
/// code and the text, what opening it does (`hint`) and, where there is a clipboard, Copy (`onCopied` says so); Close
/// in the bar (on Apple TV a button under the text, and the remote's Menu). Identifiers: `id`, with `<id>.qr`,
/// `<id>.text`, `<id>.copy` and `<id>.close` (Close). `toggle`, where given, is a switch under the hint (Show link's
/// "Open as {profile}", `<id>.asProfile`).
struct LinkDialog: View {
    let link: String
    let hint: String
    let id: String
    let onCopied: () -> Void
    let onClose: () -> Void
    var toggle: (label: String, isOn: Binding<Bool>)? = nil

    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        SheetPage(id: id, title: T.shared.deepLinks.dialogTitle, close: SheetAction(title: T.shared.common.close, id: "\(id).close", action: onClose)) {
            VStack(spacing: 16 * unit) {
                QRCodeImage(payload: link, description: T.shared.deepLinks.dialogTitle, size: dimens.qrSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8 * unit, style: .continuous))
                    .frame(width: dimens.qrSize, height: dimens.qrSize)
                    .accessibilityIdentifier("\(id).qr")
                Text(link)
                    .font(.subheadline.monospaced())
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    #if !os(tvOS)
                    .textSelection(.enabled)
                    #endif
                    .accessibilityIdentifier("\(id).text")
                Text(hint)
                    .font(.subheadline)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                if let toggle {
                    Toggle(toggle.label, isOn: toggle.isOn)
                        .accessibilityIdentifier("\(id).asProfile")
                }
                #if os(tvOS)
                // Something to focus in the panel; the remote's Menu closes it too.
                Button(T.shared.common.close, action: onClose)
                    .buttonProminence(.primary)
                    .accessibilityIdentifier("\(id).close")
                #else
                Button(T.shared.deepLinks.copyText) {
                    Pasteboard.copy(link)
                    onCopied()
                }
                .buttonProminence(.secondary)
                .accessibilityIdentifier("\(id).copy")
                #endif
            }
            .padding(24 * unit)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
