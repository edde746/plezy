import SwiftUI
import PlezyKit

extension View {
    /// The receiver's pairing question (`CastReceiverUiState.prompt`) over everything while it waits, the player
    /// included: on iPhone, iPad and Apple TV in a window of its own above the app's (`CastPromptWindow`), so the
    /// player's cover and any sheet stay under it (Apple TV: in the docked side panel, `TrailingPanel`); on the Mac a
    /// sheet over the window, the player's overlay under it. Back (the remote's Menu, Escape) refuses.
    func castReceiverPrompt(_ cast: CastModel) -> some View {
        #if os(macOS)
        appSheet(item: cast.receiverState.state.prompt, id: "cast.prompt.panel", size: .progress, onDismiss: cast.receiver.refuse) { prompt in
            CastPromptCard(prompt: prompt, receiver: cast.receiver)
        }
        #else
        onChange(of: cast.receiverState.state.prompt, initial: true) { _, prompt in
            CastPromptWindow.shared.show(prompt, receiver: cast.receiver)
        }
        #endif
    }
}

/// "Allow <device> to cast?" with the 4-digit code the sender shows too, what to check, then Allow and Don't Allow; on
/// Apple TV Allow has focus first. Back (the remote's Menu, Escape) is Don't Allow.
///
/// Accessibility identifiers: `cast.prompt`, `cast.prompt.code`, `cast.prompt.allow`, `cast.prompt.deny`.
struct CastPromptCard: View {
    let prompt: CastPairingPrompt
    let receiver: CastReceiver

    private enum Choice: Hashable { case allow, deny }

    @FocusState private var focus: Choice?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv.badge.wifi")
                .font(.largeTitle)
                .foregroundStyle(Palette.primary)
                .accessibilityHidden(true)
            Text(prompt.title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            CodeText(code: prompt.code, id: "cast.prompt.code")
            Text(prompt.message)
                .font(.subheadline)
                .foregroundStyle(Palette.onSurfaceVariant)
                .multilineTextAlignment(.center)
            // The two share the row's width, so a narrow screen (an iPhone, the Duo's cover) shrinks them rather than
            // the row pushing the card past the screen's edges.
            HStack(spacing: 12) {
                Button(action: receiver.refuse) {
                    Text(T.shared.cast.pairing.deny).frame(maxWidth: .infinity)
                }
                .buttonProminence(.secondary)
                #if !os(tvOS)
                .keyboardShortcut(.cancelAction)
                #endif
                .focused($focus, equals: .deny)
                .accessibilityIdentifier("cast.prompt.deny")
                Button(action: receiver.approve) {
                    Text(T.shared.cast.pairing.allow).frame(maxWidth: .infinity)
                }
                .buttonProminence(.primary)
                #if !os(tvOS)
                .keyboardShortcut(.defaultAction)
                #endif
                .focused($focus, equals: .allow)
                .accessibilityIdentifier("cast.prompt.allow")
            }
            .largeControl()
        }
        .padding(24)
        .defaultFocus($focus, .allow)
        .onAppear { focus = .allow }
        .backAction(receiver.refuse)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cast.prompt")
        .announcing(prompt.title)
    }
}

#if !os(macOS)
/// The window the receiver's pairing question shows in, above the app's own (its player's cover and sheets too): the
/// question over the dimmed app (`CastPromptOverlay`). It takes the keyboard and the remote's focus while it shows, and
/// hands them back to the app's window as it goes.
@MainActor
final class CastPromptWindow {
    static let shared = CastPromptWindow()

    private var window: UIWindow?
    /// The app's key window when the question came up.
    private weak var previousKey: UIWindow?

    /// Shows `prompt`, replacing the one showing, or takes the window down (nil).
    func show(_ prompt: CastPairingPrompt?, receiver: CastReceiver) {
        guard let prompt else {
            hide()
            return
        }
        let root = CastPromptOverlay(prompt: prompt, receiver: receiver).id(prompt.code)
        if let host = window?.rootViewController as? UIHostingController<AnyView> {
            host.rootView = AnyView(root)
            return
        }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else { return }
        previousKey = scene.keyWindow
        let host = UIHostingController(rootView: AnyView(root))
        host.view.backgroundColor = .clear
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
    }

    private func hide() {
        guard let window else { return }
        window.isHidden = true
        self.window = nil
        previousKey?.makeKey()
    }
}

/// The question over the dimmed app: on a card inset from the screen's edges as an alert is, 400 pt wide at most; on
/// Apple TV in the side panel docked at the trailing edge (`TrailingPanel`), as Apple TV's other panels.
private struct CastPromptOverlay: View {
    let prompt: CastPairingPrompt
    let receiver: CastReceiver

    var body: some View {
        Group {
            #if os(tvOS)
            TrailingPanel(id: "cast.prompt.panel") {
                CastPromptCard(prompt: prompt, receiver: receiver)
            }
            #else
            ZStack {
                Palette.scrim.opacity(0.6).ignoresSafeArea()
                CastPromptCard(prompt: prompt, receiver: receiver)
                    .frame(maxWidth: 400)
                    .background(Palette.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
                    .padding(24)
            }
            #endif
        }
        .formFactorEnvironment()
    }
}
#endif
