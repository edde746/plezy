import SwiftUI
import PlezyKit

/// A sign-in waiting for the user, as a form in a sheet titled by the service: the instructions over a device code's
/// code, large, beside the sign-in link's QR code on wide screens (under the code on phones); the link to type; the
/// waiting line and Open to go there in the browser (not on Apple TV, which has none). On iPhone, iPad and the Mac a tap
/// on the code or the link copies it. Cancel in the sheet's bar (on Apple TV the form's last button); every way out
/// (Cancel, a swipe down, Escape, the remote's Menu) cancels the sign-in once.
///
/// Accessibility identifiers: `services.dialog`, `services.dialog.code`, `services.dialog.qr`, `services.dialog.url`,
/// `services.dialog.open`, `services.dialog.cancel`, `services.dialog.copied`.
struct TrackerConnectSheet: View {
    let dialog: any ConnectDialogUi
    let onOpen: (String) -> Void
    let onCancel: () -> Void

    /// What was copied last ("Code copied"), as a toast.
    @State private var copied: String?
    @Environment(\.formFactor) private var formFactor
    @Environment(\.dimens) private var dimens

    var body: some View {
        let cancel = SheetAction(title: dialog.cancel, id: "services.dialog.cancel", action: onCancel)
        SheetPage(id: "services.dialog", title: dialog.title, cancel: cancel, confirm: nil) {
            Form {
                Section {
                    codeAndQR
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    url
                } header: {
                    Text(dialog.body).textCase(nil)
                }
                Section {
                    ProgressLine(text: dialog.waiting)
                        .accessibilityElement(children: .combine)
                    #if !os(tvOS)
                    Button { onOpen(dialog.url) } label: {
                        Label(dialog.openLabel, systemImage: "safari")
                    }
                    .accessibilityIdentifier("services.dialog.open")
                    #endif
                }
                SheetActionsSection(actions: [cancel])
            }
            .settingsForm()
        }
        .backAction(onCancel)
        .toast(copied, id: "services.dialog.copied") { copied = nil }
    }

    /// The QR code of the sign-in link beside a device code's code on wide layouts, above it on phones.
    private var codeAndQR: some View {
        let layout = formFactor == .compact
            ? AnyLayout(VStackLayout(alignment: .center, spacing: 16))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 32))
        return layout {
            QRCodeImage(payload: dialog.url, description: dialog.readableUrl, size: dimens.qrSize)
                .clipShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
                .accessibilityIdentifier("services.dialog.qr")
            if case .deviceCode(let device) = onEnum(of: dialog) {
                copyable(device.userCode, copied: device.codeCopied, label: device.copyCode, id: "services.dialog.code") {
                    CodeText(code: device.userCode, id: "")
                }
            }
        }
    }

    /// The link to type, without its scheme.
    private var url: some View {
        copyable(dialog.url, copied: dialog.urlCopied, label: dialog.copyUrl, id: "services.dialog.url") {
            Label {
                Text(dialog.readableUrl).font(.body.monospaced())
            } icon: {
                Image(systemName: "link")
            }
        }
    }

    /// `content` showing `value`: a tap copies it and says `copied` (iOS, macOS); on Apple TV, which has no pasteboard,
    /// the text alone.
    @ViewBuilder
    private func copyable(_ value: String, copied: String, label: String, id: String, @ViewBuilder content: () -> some View) -> some View {
        #if os(tvOS)
        content()
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(id)
        #else
        Button {
            Pasteboard.copy(value)
            self.copied = copied
        } label: {
            content().contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Palette.onBackground)
        .accessibilityHint(label)
        .accessibilityIdentifier(id)
        #endif
    }
}
