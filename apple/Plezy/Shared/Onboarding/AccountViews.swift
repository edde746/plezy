import SwiftUI
import PlezyKit

/// A backend's brand mark (Plex's chevron, Jellyfin's and Emby's logos) in the text colour around it.
struct BackendMark: View {
    let backend: BackendKind
    var size: CGFloat = 20

    var body: some View {
        Image("mark.\(backend.id)")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Plezy's logo, `size` points square.
struct PlezyLogo: View {
    var size: CGFloat = 120

    var body: some View {
        Image("logo.plezy")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// A profile's round avatar: its picture where it has one, else its initial on a colour of its own.
struct ProfileAvatar: View {
    let name: String
    let url: String?
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle().fill(AvatarInitialKt.avatarColorOf(name: name).map { Color(rgb: UInt32(truncatingIfNeeded: $0.int64Value & 0xFFFFFF)) } ?? Palette.primary)
            Text(AvatarInitialKt.initialOf(name: name))
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
            if let url {
                RemoteImage(url: url).clipShape(Circle())
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// An account screen: one centred column, no wider than a phone's (a room's width on TV), of `header` (the logo),
/// the `title` (a large title), the `intro` and `content`, scrolling when tall. Short pages sit in the middle of the
/// window.
struct AccountPage<Header: View, Content: View>: View {
    let title: String
    var intro: String?
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content

    @Environment(\.formFactor) private var formFactor
    @Environment(\.screenSides) private var sides

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        header()
                        Text(title)
                            .font(.largeTitle.bold())
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        if let intro {
                            Text(intro)
                                .foregroundStyle(Palette.onSurfaceVariant)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, 12)
                    content()
                }
                .frame(maxWidth: columnWidth, alignment: .leading)
                .padding(sides.insets)
                .padding(.vertical, 56)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Palette.background)
    }

    /// A phone's column: narrow enough to read at a glance on any window, a room's width on TV.
    private var columnWidth: CGFloat {
        switch formFactor {
        case .compact: 480
        case .regular: 440
        case .tv: 880
        }
    }
}

extension AccountPage where Header == EmptyView {
    init(title: String, intro: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, intro: intro, header: { EmptyView() }, content: content)
    }
}

/// A short code to read out or type elsewhere (`ABCD-EFGH`), large and monospaced, on one line (smaller where the
/// width beside a QR code is short, as on the Mac). `id` is its accessibility identifier.
struct CodeText: View {
    let code: String
    let id: String

    var body: some View {
        Text(code)
            .font(.system(.largeTitle, design: .monospaced).weight(.semibold))
            .tracking(4)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #if !os(tvOS)
            .textSelection(.enabled)
            #endif
            .accessibilityIdentifier(id)
    }
}

/// A code to enter at `address` (over the code) beside its QR code on wide layouts, under it on phones; `codeId` is the
/// code's accessibility identifier, `addressId` the address's and `qrId` the QR code's.
struct CodeAndQR: View {
    let address: String
    let addressId: String
    let code: String
    let codeId: String
    let qrPayload: String
    let qrDescription: String
    let qrId: String

    @Environment(\.formFactor) private var formFactor
    @Environment(\.dimens) private var dimens

    var body: some View {
        let layout = formFactor == .compact
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 32))
        layout {
            QRCodeImage(payload: qrPayload, description: qrDescription, size: dimens.qrSize)
                .accessibilityIdentifier(qrId)
                .clipShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(address).font(.headline).accessibilityIdentifier(addressId)
                // Beside the QR code at its own size: the stack scaled the code down to its minimum (iPad).
                CodeText(code: code, id: codeId).fixedSize(horizontal: formFactor != .compact, vertical: formFactor != .compact)
            }
        }
    }
}

/// A row of the account forms that opens something: a leading mark or symbol, a title and subtitle, a chevron.
struct AccountOptionRow<Leading: View>: View {
    let title: String
    var subtitle: String?
    /// A short state before the chevron ("Added").
    var detail: String?
    var enabled = true
    let id: String
    @ViewBuilder let leading: () -> Leading
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                leading().frame(width: 32)
                SettingsRowText(title: title, subtitle: subtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let detail {
                    Text(detail).font(.subheadline).mutedForeground()
                }
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .formRowButtonStyle()
        .disabled(!enabled)
        .accessibilityIdentifier(id)
    }
}


/// A text field over a store's text (`value`, changed through `send`): the field edits text of its own, so typing never
/// waits for the store's state to come back (it comes a moment later, and a field bound to it straight dropped the
/// keys typed meanwhile). Each value the store echoes back is one the field sent and is let go; any other is the
/// store's own change (the URLs a probe settled on, a form cleared), which the field then shows. The field's binding
/// sends each edit as it is made, so a Return's `onSubmit` acts on all that was typed (an `onChange` could run after it).
struct StoreText<Content: View>: View {
    let value: String
    let send: (String) -> Void
    @ViewBuilder let content: (Binding<String>) -> Content

    @State private var text: String
    /// What the field sent that the store hasn't echoed yet, oldest first.
    @State private var pending: [String] = []

    init(value: String, send: @escaping (String) -> Void, @ViewBuilder content: @escaping (Binding<String>) -> Content) {
        self.value = value
        self.send = send
        self.content = content
        _text = State(initialValue: value)
    }

    var body: some View {
        content(Binding(get: { text }, set: { new in
            text = new
            guard new != (pending.last ?? value) else { return }
            pending.append(new)
            send(new)
        }))
            .onChange(of: value) { _, new in
                if let index = pending.firstIndex(of: new) {
                    pending.removeFirst(index + 1)
                } else {
                    pending = []
                    text = new
                }
            }
    }
}

extension Binding<String> {
    /// This binding, each edit also passed to `send` as it is made (an unchanged value is not), before any `onSubmit`
    /// of the field reads the store: an `onChange` can run after the Return that ends the typing, losing its last key.
    /// Values set on the underlying state directly (the store's own) are not sent.
    func sending(_ send: @escaping (String) -> Void) -> Binding<String> {
        Binding(get: { wrappedValue }, set: { new in
            guard new != wrappedValue else { return }
            wrappedValue = new
            send(new)
        })
    }
}

extension ConfirmUi {
    /// The store's question in the system alert (`confirmation`), its answers `confirm.ok` and `confirm.cancel`, and
    /// where it has a switch, `confirm.toggle`: the confirm with the switch on.
    var dialog: Confirmation {
        Confirmation(
            title: title, message: message, confirmLabel: confirmLabel, cancelLabel: T.shared.common.cancel,
            confirmId: "confirm.ok", cancelId: "confirm.cancel",
            toggle: toggle.map { ConfirmationToggle(label: $0.title, description: $0.description_, id: "confirm.toggle") }
        )
    }
}
