#if os(iOS)
import SwiftUI
import UIKit

/// Whether a menu is open on touch, for the app's glass, which stops taking touches while one is (`GlassShape`'s turns
/// non-interactive, a round glass button is disabled): a tap on a menu's entry (a card's context menu, a ⋯ menu) drawn
/// over interactive glass went to the glass under the menu, and the entry did nothing (Home's shortcuts, the header
/// row's filters and actions under a card's menu, iPhone, iOS 27). SwiftUI tells nothing of
/// a menu opening or closing, so this looks for UIKit's menu in the app's windows (`showsMenu`): as the app's glass
/// appears (`GlassShape`) and, from then on, at each touch in a window (`TouchWatch`), every 100 ms over the next
/// second, which a menu's opening and closing take, and while one is open until it closes.
@MainActor
@Observable
final class OpenItemMenu {
    static let shared = OpenItemMenu()

    private(set) var isOpen = false
    @ObservationIgnored private var looking: Task<Void, Never>?

    func look() {
        looking?.cancel()
        looking = Task {
            var waited = Duration.zero
            while !Task.isCancelled {
                update()
                if waited >= .seconds(1) && !isOpen { return }
                try? await Task.sleep(for: .milliseconds(100))
                waited += .milliseconds(100)
            }
        }
    }

    private func update() {
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        for window in windows where !(window.gestureRecognizers ?? []).contains(where: { $0 is TouchWatch }) {
            window.addGestureRecognizer(TouchWatch())
        }
        let open = windows.contains { window in
            window.subviews.contains { $0 !== window.rootViewController?.view && Self.showsMenu($0, depth: 3) }
        }
        if open != isOpen { isOpen = open }
    }

    /// Whether `view`, or a view up to `depth` levels into it, is UIKit's menu on screen: a context menu's or a menu
    /// button's container, which its class names (`_UIContextMenuContainerView`). The app's own views (its window's
    /// root view) are left out.
    private static func showsMenu(_ view: UIView, depth: Int) -> Bool {
        if view.isHidden || view.alpha < 0.01 { return false }
        if NSStringFromClass(type(of: view)).contains("ContextMenu") { return true }
        return depth > 0 && view.subviews.contains { showsMenu($0, depth: depth - 1) }
    }
}

/// Sees each touch in its window, to have `OpenItemMenu` look for a menu as one may open or close, without taking part:
/// it never recognizes, and nothing waits for it to fail.
private final class TouchWatch: UIGestureRecognizer, UIGestureRecognizerDelegate {
    init() {
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesEnded = false
        delegate = self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        OpenItemMenu.shared.look()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        ended(event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        ended(event)
    }

    private func ended(_ event: UIEvent) {
        OpenItemMenu.shared.look()
        if event.allTouches?.allSatisfy({ $0.phase == .ended || $0.phase == .cancelled }) ?? true { state = .failed }
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func shouldRequireFailure(of otherGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func shouldBeRequiredToFail(by otherGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}

/// A round glass button (not a menu), disabled while a menu is open (`OpenItemMenu`), as the app's glass buttons are:
/// enabled, it took the taps of a menu's entries drawn over it whatever its glass said. Its label stays in the enabled
/// label's white rather than the disabled grey, so nothing under the menu changes; a button disabled on its own stays
/// grey.
struct DisabledUnderOpenItemMenu: ViewModifier {
    @Environment(\.isEnabled) private var enabled

    func body(content: Content) -> some View {
        if enabled && OpenItemMenu.shared.isOpen {
            content.foregroundStyle(Palette.onBackground).disabled(true)
        } else {
            content
        }
    }
}
#endif
