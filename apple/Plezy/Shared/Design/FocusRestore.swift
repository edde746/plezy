import SwiftUI
#if os(tvOS)
import UIKit
#endif

/// Focus a screen asks for (a page's first focus, the player's controls) given until it holds or the user moves.
@MainActor
enum FocusRestore {
    /// The user's moves of focus since launch: the focus system's updates with a heading (a press or a swipe on the
    /// remote), not focus the app sets, nor tvOS's own as a screen opens or a focused view goes (`countUserMoves`).
    private(set) static var userMoves = 0

    #if os(tvOS)
    /// Counts the user's moves (`userMoves`) from now on: once, as the app starts.
    static func countUserMoves() {
        _ = NotificationCenter.default.addObserver(forName: UIFocusSystem.didUpdateNotification, object: nil, queue: .main) { notification in
            // Delivered on the main queue, where it is read.
            nonisolated(unsafe) let notification = notification
            MainActor.assumeIsolated {
                guard let context = notification.userInfo?[UIFocusSystem.focusUpdateContextUserInfoKey] as? UIFocusUpdateContext,
                      !context.focusHeading.isEmpty else { return }
                userMoves += 1
            }
        }
    }

    /// Apple TV's tab bar holds focus the user put there (a move since launch): the user is moving across the tabs, each
    /// tab's screen showing as its tab takes focus, and a screen's first focus would pull focus off the bar mid-way. At
    /// launch, before any move, the system's own first focus on the bar doesn't count.
    static var tabBarHasFocus: Bool {
        userMoves > 0 && focusInTabBar
    }

    /// Apple TV's tab bar, shown, holds focus, whoever put it there. A hidden one (a pushed screen's) doesn't count: the
    /// focus engine parks focus on its button when the screen that had focus goes and the one now on top has nothing to
    /// focus yet (a detail still loading as its push ends), where no one chose to put it.
    static var focusInTabBar: Bool {
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        guard let window = windows.first(where: \.isKeyWindow) ?? windows.first,
              var node: (any UIFocusEnvironment)? = UIFocusSystem.focusSystem(for: window)?.focusedItem else { return false }
        while let current = node {
            if let bar = current as? UITabBar { return !bar.isHidden }
            node = current.parentFocusEnvironment
        }
        return false
    }
    #endif

    /// Whether a cover (the profile picker over the session's screens) is up: a restore asked for `afterCover` waits
    /// for it to go. Set by the running app (`AppModel`).
    static var coverShown: @MainActor () -> Bool = { false }

    /// Moves focus to `target` unless an element of `focus` has it (with `replacing`, unless `target` has it), until one
    /// has held it for `hold` seconds (for up to 4 s), both measured on the clock however late each look comes: a lazily
    /// built card can take a few frames to attach, and at launch the system gives its first focus to the tab bar a
    /// moment after the first frames, so the first focus holds longer. A move of the user's ends it, before it has moved
    /// focus or after: once `userMoves` is past `since` (the moves as the restore was asked for; by default as it
    /// starts), focus stays where the user put it, the tab bar included. With `afterCover` it first waits, however long,
    /// while a cover is up (`coverShown`), and its 4 s and the user's moves count from when it goes: a screen made under
    /// the profile picker gets its first focus once the picker closes. The Compose `RestoreFocus` asks once per frame
    /// the same way, until the user moves, behind its `focusGate`.
    static func restore<Value: Hashable>(
        _ focus: FocusState<Value?>.Binding, to target: Value?, hold: Double = 0.5, since: Int? = nil, replacing: Bool = false,
        afterCover: Bool = false
    ) async {
        guard let target else { return }
        var since = since ?? userMoves
        if afterCover, coverShown() {
            while coverShown() {
                if Task.isCancelled { return }
                try? await Task.sleep(for: .milliseconds(100))
            }
            since = userMoves
        }
        let clock = ContinuousClock()
        let giveUp = clock.now + .seconds(4)
        var heldSince = clock.now
        while clock.now < giveUp {
            if Task.isCancelled || userMoves != since { return }
            #if os(tvOS)
            if tabBarHasFocus { return }
            #endif
            if replacing ? focus.wrappedValue != target : focus.wrappedValue == nil {
                focus.wrappedValue = target
                heldSince = clock.now
            } else if heldSince.duration(to: clock.now) >= .seconds(hold) {
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}
