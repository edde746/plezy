#if os(iOS)
import PlezyKit
import SwiftUI
import UIKit

/// iPhone's More menu: the destinations the tab bar leaves to its More tab (`AppShell.moreHeld`), each with its symbol,
/// the shown one checked, in the system menu the player's track menus use (`SystemMenuButton`). A tab can't hold a
/// menu: a pick of More asks for it (`request` counts the picks), and the screen showing then opens it from a button
/// laid over the More tab's item in the bar, which takes no touch and leaves the bar as the menu goes. A pick in the
/// menu goes to `pick`. Set on each tab's screen; nothing while More holds no destination.
struct MoreMenu: ViewModifier {
    let destinations: [TopLevelDestination]
    let shown: TopLevelDestination
    let request: Int
    let pick: (TopLevelDestination) -> Void

    func body(content: Content) -> some View {
        if destinations.isEmpty {
            content
        } else {
            content.background(
                MoreMenuAnchor(destinations: destinations, shown: shown, request: request, pick: pick)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            )
        }
    }
}

private struct MoreMenuAnchor: UIViewControllerRepresentable {
    let destinations: [TopLevelDestination]
    let shown: TopLevelDestination
    let request: Int
    let pick: (TopLevelDestination) -> Void

    func makeUIViewController(context: Context) -> Anchor {
        Anchor(request: request)
    }

    func updateUIViewController(_ anchor: Anchor, context: Context) {
        let pick = self.pick
        anchor.button.menu = UIMenu(options: .singleSelection, children: destinations.map { destination in
            UIAction(
                title: destination.label,
                image: UIImage(systemName: destination.systemImage),
                state: destination == shown ? .on : .off
            ) { _ in pick(destination) }
        })
        guard anchor.request != request else { return }
        anchor.request = request
        // A turn later: as the bar hands over More's pick, the screen showing is out of the window for a moment.
        if #available(iOS 17.4, *) { DispatchQueue.main.async { anchor.open() } }
    }

    final class Anchor: UIViewController {
        let button = MenuSource(type: .system)
        /// The last pick of More this screen heard: a screen made after a pick doesn't open the menu for it.
        var request: Int

        init(request: Int) {
            self.request = request
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override func loadView() {
            view = UIView()
            button.showsMenuAsPrimaryAction = true
            button.isAccessibilityElement = false
            button.onOpen = { [weak button] in button?.runAfterClose { button?.removeFromSuperview() } }
        }

        /// Opens the menu from the More tab's item while this screen shows (the screens of the other tabs are out of
        /// the window). The button goes in the bar itself: from a view under the bar (this one) UIKit opened the menu
        /// at the top of the screen.
        @available(iOS 17.4, *)
        func open() {
            guard view.window != nil else { return }
            guard let bar = tabBarController?.tabBar,
                  let item = bar.items?.first(where: { $0.title == T.shared.navigation.more }),
                  let frame = item.frame(in: bar) else {
                assertionFailure("the tab bar has no More item to open its menu from")
                return
            }
            bar.addSubview(button)
            button.frame = frame
            button.performPrimaryAction()
        }
    }

    /// The menu's button over the More item, which leaves every touch to the item under it.
    final class MenuSource: SystemMenuButton {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { false }
    }
}
#endif
