#if os(iOS)
import SwiftUI
import UIKit

extension View {
    /// Always Keep Sidebar Open on iPad (`keep`): the tab view's sidebar shows as the shell starts, tiled beside the
    /// screen where the window is wide enough (landscape), and there shows again as soon as it was hidden (its toggle).
    /// Where it can only lie over the screen (portrait), which a tap on the screen hides, it stays hidden once hidden:
    /// shown again, it would take every tap meant for the screen. `shown` is the tab bar's placement as the tab view
    /// reports it (`TabBarPlacementReader`), whose change brings the check here. Set on a tab's content, inside the
    /// tab view.
    @available(iOS 18, *)
    func keepsSidebarShown(_ keep: Bool, shown: Bool) -> some View {
        background(SidebarKeeper(keep: keep, shown: shown).frame(width: 0, height: 0).accessibilityHidden(true))
    }
}

@available(iOS 18, *)
private struct SidebarKeeper: UIViewControllerRepresentable {
    let keep: Bool
    let shown: Bool

    func makeUIViewController(context: Context) -> Probe {
        Probe()
    }

    func updateUIViewController(_ probe: Probe, context: Context) {
        probe.keep = keep
        probe.apply()
    }

    final class Probe: UIViewController {
        var keep = false
        /// The sidebar, last shown, sat beside the screen (the screen moved over for it) rather than over it.
        private var beside = true

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        /// A turn (to landscape, say) may give the sidebar room beside the screen: shown again, it says whether.
        override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.beside = true
                self?.apply()
            }
        }

        func apply() {
            guard traitCollection.userInterfaceIdiom == .pad, let tabs = tabBarController else { return }
            let layout: UITabBarController.Sidebar.Layout = keep ? .tile : .automatic
            if tabs.sidebar.preferredLayout != layout { tabs.sidebar.preferredLayout = layout }
            guard keep, traitCollection.horizontalSizeClass == .regular else { return }
            if !tabs.sidebar.isHidden {
                // Once the sidebar's animation has placed the screen.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self, !tabs.sidebar.isHidden, let screen = tabs.selectedViewController?.view else { return }
                    beside = screen.convert(screen.bounds, to: nil).minX > 1
                }
            } else if beside {
                // Not within the update that reported the hide: the tab view is still laying that out.
                DispatchQueue.main.async { tabs.sidebar.isHidden = false }
            }
        }
    }
}
#endif
