import SwiftUI
import PlezyKit

/// Content is on its way: the large spinner in the middle of the space it is given, as pages show while they
/// load, and, with a `caption`, that caption in the lower half just under it (the spinner stays where it is when the
/// caption comes). On a pushed tvOS screen it holds focus (`holdsBackFocus`), so Menu goes back.
struct LoadingStateView<Caption: View>: View {
    @ViewBuilder var caption: Caption

    var body: some View {
        ZStack {
            ProgressView()
                .largeSpinner()
            VStack(spacing: 0) {
                Color.clear
                caption
                    .padding(.horizontal, 32)
                    .padding(.top, 48)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .holdsBackFocus()
    }
}

extension LoadingStateView where Caption == EmptyView {
    init() {
        self.init { EmptyView() }
    }
}

extension ProgressView {
    /// A screen's or the player's spinner: large (tvOS has the one size).
    func largeSpinner() -> some View {
        #if os(tvOS)
        self
        #else
        controlSize(.large)
        #endif
    }

}

/// Something failed: `message` (worded by the store) under `systemImage` and, with `onRetry`, a retry button (or what
/// the failure needs instead, `retryLabel` with `retrySystemImage`: Sign in again) that takes focus so a remote or
/// keyboard user can act at once; without one, on a pushed tvOS screen the view holds focus (`holdsBackFocus`).
struct ErrorStateView: View {
    let message: String
    var title: String?
    var systemImage: String = "exclamationmark.circle"
    var retryLabel: String = T.shared.nav.retry
    var retrySystemImage: String? = "arrow.clockwise"
    var onRetry: (() -> Void)?

    @FocusState private var retryFocused: Bool

    var body: some View {
        MessageStateView(systemImage: systemImage, title: title, message: message, holdsFocus: onRetry == nil) {
            if let onRetry {
                Button(action: onRetry) {
                    if let retrySystemImage {
                        Label(retryLabel, systemImage: retrySystemImage)
                    } else {
                        Text(retryLabel)
                    }
                }
                .glassButtonStyle()
                .accessibilityIdentifier("state.retry")
                .focused($retryFocused)
                .onAppear {
                    #if os(tvOS)
                    if FocusRestore.tabBarHasFocus { return }
                    #endif
                    retryFocused = true
                }
            }
        }
    }
}

/// Nothing to show: `message` (from the store), under `title` where there is one, under `systemImage`; `action` for
/// what the user can do about it. Without an action, on a pushed tvOS screen the view holds focus (`holdsBackFocus`).
struct EmptyStateView<Action: View>: View {
    let message: String
    var title: String?
    var systemImage: String = "film"
    @ViewBuilder var action: () -> Action

    var body: some View {
        MessageStateView(systemImage: systemImage, title: title, message: message, holdsFocus: Action.self == EmptyView.self, actions: action)
    }
}

extension EmptyStateView where Action == EmptyView {
    init(message: String, title: String? = nil, systemImage: String = "film") {
        self.init(message: message, title: title, systemImage: systemImage) { EmptyView() }
    }
}

/// A state screen: `systemImage`, `title` where there is one, `message`, and `actions` under them. On tvOS the whole
/// area it fills is a focus section, so a move into it from anywhere beside or above (a header row's control far off
/// the centred actions' column) lands on its actions.
struct MessageStateView<Actions: View>: View {
    let systemImage: String
    let title: String?
    let message: String
    /// There are no actions to focus: the view itself holds focus on a pushed tvOS screen.
    let holdsFocus: Bool
    /// The column's widest, for a message longer than a line or two.
    var maxWidth: CGFloat = 480
    @ViewBuilder var actions: () -> Actions

    @Environment(\.dimens) private var dimens

    var body: some View {
        VStack(spacing: 12 * dimens.unit) {
            Image(systemName: systemImage)
                .font(.system(size: 44 * dimens.unit))
                .foregroundStyle(Palette.onSurfaceVariant)
                .accessibilityHidden(true)
            if let title {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
            Text(message)
                .font(.body)
                .foregroundStyle(Palette.onSurfaceVariant)
                .multilineTextAlignment(.center)
            actions()
        }
        .frame(maxWidth: maxWidth)
        .padding(dimens.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(tvOS)
        .focusSection()
        #endif
        .holdsBackFocus(holdsFocus)
    }
}

extension EnvironmentValues {
    /// The screen is pushed over another: a route above the root of its tab's stack, a Settings section's page over
    /// the section list, a `TrailingPanel`'s content (`holdsBackFocus`).
    @Entry var isPushedScreen = false
}

extension View {
    /// tvOS: on a pushed screen (`isPushedScreen`), this view takes focus while `holds`; it is for what a screen shows
    /// while it has nothing else to focus (loading, a failure without a retry, nothing to list). The remote's Menu goes
    /// back from the screen that has focus, but a pushed screen with nothing focusable leaves focus on the tab bar (the
    /// system gives it focus at launch, and the focus engine moves it there when the screen that had it goes), and
    /// Menu on the tab bar leaves the app. Elsewhere, and on a tab's root (whose Menu goes to the tab bar anyway),
    /// nothing changes: there such a view leaves focus on the tab bar.
    func holdsBackFocus(_ holds: Bool = true) -> some View {
        modifier(BackFocusHolder(holds: holds))
    }
}

private struct BackFocusHolder: ViewModifier {
    let holds: Bool

    @Environment(\.isPushedScreen) private var pushed
    @FocusState private var focus: String?

    func body(content: Content) -> some View {
        #if os(tvOS)
        if holds, pushed {
            content
                .focusable()
                .focusEffectDisabled()
                .focused($focus, equals: "back")
                // Taken from the tab bar too, which the system focuses a moment after launch.
                .task { await FocusRestore.restore($focus, to: "back", hold: 1.5) }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// Something running: a small spinner and what it waits for.
struct ProgressLine: View {
    let text: String?

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            if let text {
                Text(text).foregroundStyle(Palette.onSurfaceVariant)
            }
        }
    }
}

/// A line saying what went wrong: the error icon, then the store's wording (which accessibility reads alone). It shows
/// after something failed, often away from where VoiceOver is, so its text is announced as it shows and as it changes.
struct ErrorLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .accessibilityHidden(true)
            Text(text)
        }
        .font(.callout)
        .foregroundStyle(Palette.error)
        .announcing(text)
    }
}
