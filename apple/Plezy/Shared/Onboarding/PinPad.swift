import SwiftUI
import PlezyKit

extension View {
    /// The PIN the app asks for (`Onboarding.pin`) while `request` is set: the PIN pad (`PinPad`) titled by the request,
    /// in a full-height sheet on iOS and macOS, a `TrailingPanel` on Apple TV. Four digits submit by themselves; a wrong
    /// PIN comes back as a new request with its error, on an empty pad. Closing it (Cancel, a swipe, Escape, the remote's
    /// Menu) cancels the request.
    func pinPrompt(_ request: PinRequest?, prompter: PinPrompter) -> some View {
        appSheet(item: request, id: "pin.dialog", size: .fullHeightPanel, onDismiss: prompter.cancel) { request in
            RequestPad(request: request, prompter: prompter).id(request.id)
        }
    }
}

/// One PIN request's pad: the digits typed so far, kept here until four submit.
private struct RequestPad: View {
    let request: PinRequest
    let prompter: PinPrompter

    @State private var digits = ""

    var body: some View {
        PinPad(
            title: request.title,
            entered: digits.count,
            length: 4,
            enteredText: "\(digits.count)/4",
            message: request.error,
            acceptsInput: true,
            onDigit: { digit in
                guard digits.count < 4 else { return }
                digits += String(digit)
                if digits.count == 4 { prompter.submit(pin: digits) }
            },
            onBackspace: { if !digits.isEmpty { digits.removeLast() } },
            onCancel: prompter.cancel
        ) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(Palette.onSurfaceVariant)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pin.dialog")
    }
}

/// A tile (a profile in the picker; a PIN key off tvOS) as a button: on tvOS it grows and casts a shadow when focused and
/// shrinks a little while clicked (`tvPressed`); elsewhere it dims while pressed (the label draws its focus ring for
/// keyboard focus).
struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Tile(configuration: configuration)
    }

    private struct Tile: View {
        let configuration: Configuration
        @Environment(\.isFocused) private var focused

        var body: some View {
            #if os(tvOS)
            configuration.label
                .scaleEffect(focused ? 1.1 : 1)
                .shadow(color: .black.opacity(focused ? 0.5 : 0), radius: 16, y: 8)
                .animation(.easeOut(duration: 0.15), value: focused)
                .tvPressed(configuration.isPressed)
            #else
            configuration.label
                .opacity(configuration.isPressed ? 0.7 : 1)
            #endif
        }
    }
}

/// A four-digit PIN pad: `header` and `title`, one dot per digit with `entered` filled (spoken as `enteredText`),
/// `message` (a wrong PIN), digits 0–9 and backspace, and Cancel (not on tvOS, where the remote's Back is the way out).
/// Digit and Delete keys work from a keyboard; Back and Escape cancel. While `acceptsInput` is false the keys stay
/// focusable, so focus stays on the pad, and show dimmed. In a tvOS `TrailingPanel` it lies on the panel's surface;
/// focus goes to 1 when it shows (from the screen under the panel too). The message is announced as it shows.
/// Accessibility identifiers: `pin.entered` (the dots), `pin.error`, `pin.digit.<0-9>`, `pin.backspace`, `pin.cancel`.
struct PinPad<Header: View>: View {
    let title: String
    let entered: Int
    let length: Int
    let enteredText: String
    let message: String?
    let acceptsInput: Bool
    let onDigit: (Int) -> Void
    let onBackspace: () -> Void
    let onCancel: () -> Void
    @ViewBuilder var header: () -> Header

    @Environment(\.dimens) private var dimens
    #if os(tvOS)
    @Environment(\.isInSheet) private var inSheet
    #endif
    @FocusState private var focusedKey: Int?

    /// A key's diameter: larger on a TV, read from across the room.
    private var keySize: CGFloat {
        #if os(tvOS)
        110
        #else
        64
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header()
                Text(title).font(.title2.weight(.semibold)).multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                HStack(spacing: 16) {
                    ForEach(0..<length, id: \.self) { index in
                        Circle()
                            .fill(index < entered ? Palette.onBackground : Palette.surfaceContainerHighest)
                            .frame(width: 16, height: 16)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel(enteredText)
                .accessibilityIdentifier("pin.entered")
                Text(message ?? " ")
                    .foregroundStyle(Palette.error)
                    .multilineTextAlignment(.center)
                    .onChange(of: message != nil, initial: true) { _, shown in
                        if shown, let message { announce(message) }
                    }
                    .accessibilityIdentifier("pin.error")
                VStack(spacing: 12) {
                    ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                        HStack(spacing: 16) {
                            ForEach(row, id: \.self) { digit in
                                digitKey(digit)
                            }
                        }
                    }
                    HStack(spacing: 16) {
                        Color.clear.frame(width: keySize, height: keySize)
                        digitKey(0)
                        Button(action: onBackspace) {
                            Image(systemName: "delete.left")
                                .font(.title2)
                                .frame(width: keySize, height: keySize)
                                .contentShape(Circle())
                        }
                        .buttonStyle(keyStyle(fill: .clear))
                        #if os(macOS)
                        .tooltip(T.shared.common.back)
                        #endif
                        .accessibilityLabel(T.shared.common.back)
                        .accessibilityIdentifier("pin.backspace")
                    }
                }
                #if os(tvOS)
                .focusSection()
                #endif
                #if !os(tvOS)
                ActionButton(title: T.shared.common.cancel, id: "pin.cancel", prominence: .plain, fullWidth: false, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                #endif
            }
            .padding(dimens.screenPadding)
            .frame(maxWidth: .infinity)
        }
        .background(inPanel ? Color.clear : Palette.background)
        .backAction(onCancel)
        #if !os(tvOS)
        .onKeyPress(characters: .decimalDigits) { press in
            guard let digit = Int(press.characters) else { return .ignored }
            onDigit(digit)
            return .handled
        }
        .onKeyPress(.delete) {
            onBackspace()
            return .handled
        }
        #endif
        .onAppear { focusedKey = 1 }
        #if os(tvOS)
        .task { await FocusRestore.restore($focusedKey, to: 1) }
        #endif
    }

    /// In a tvOS `TrailingPanel`, on its surface.
    private var inPanel: Bool {
        #if os(tvOS)
        inSheet
        #else
        false
        #endif
    }

    private func digitKey(_ digit: Int) -> some View {
        Button { onDigit(digit) } label: {
            Text(String(digit))
                .font(.title.weight(.semibold))
                #if os(tvOS)
                // The surface's text colour, dark on its focused white; dimmed while input waits.
                .foregroundStyle(acceptsInput ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .frame(width: keySize, height: keySize)
                #else
                .foregroundStyle(acceptsInput ? Palette.onBackground : Palette.onSurfaceVariant)
                .frame(width: keySize, height: keySize)
                .background(Palette.surfaceContainerHigh, in: Circle())
                .focusRing(radius: keySize / 2)
                #endif
        }
        .buttonStyle(keyStyle(fill: Palette.surfaceContainerHigh))
        .focused($focusedKey, equals: digit)
        .accessibilityIdentifier("pin.digit.\(digit)")
    }

    /// A key's button style: on tvOS a round surface on `fill`, white with dark text while focused (a lift and a shadow
    /// alone didn't show on the dark panel); elsewhere a tile that dims while pressed, its label drawing its circle.
    private func keyStyle(fill: Color) -> some ButtonStyle {
        #if os(tvOS)
        SurfaceButtonStyle(fill: fill, radius: keySize / 2)
        #else
        TileButtonStyle()
        #endif
    }
}
