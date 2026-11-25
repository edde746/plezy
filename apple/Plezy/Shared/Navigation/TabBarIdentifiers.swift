#if os(iOS)
import SwiftUI
import UIKit

extension View {
    /// Puts each tab's accessibility identifier (`ids`, by the tab's title) on the tab bar's item, whose button reads it.
    /// `Tab.accessibilityIdentifier` reaches the bar's buttons only some of the time: a tab view made as a session
    /// starts often came up with buttons that had their names but no identifiers. Set on a tab's content; any tab's
    /// does for the whole bar, again on each change and layout, as the bar makes its items anew.
    func tabBarIdentifiers(_ ids: [String: String]) -> some View {
        background(TabBarIdentifiers(ids: ids).frame(width: 0, height: 0).accessibilityHidden(true))
    }
}

private struct TabBarIdentifiers: UIViewControllerRepresentable {
    let ids: [String: String]

    func makeUIViewController(context: Context) -> Probe {
        Probe()
    }

    func updateUIViewController(_ probe: Probe, context: Context) {
        probe.ids = ids
        probe.apply()
    }

    final class Probe: UIViewController {
        var ids: [String: String] = [:]

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            apply()
        }

        func apply() {
            guard let items = tabBarController?.tabBar.items else { return }
            for item in items {
                guard let title = item.title, let id = ids[title], item.accessibilityIdentifier != id else { continue }
                item.accessibilityIdentifier = id
            }
        }
    }
}
#endif
