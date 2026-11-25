import SwiftUI
import PlezyKit
#if os(macOS)
import AppKit
#endif

extension EnvironmentValues {
    /// Opens a route on the shell's navigator: what a card's title or caption link opens (`MediaCardUi.titleLink`,
    /// `captionLink`). The shell sets it; nil leaves the links plain text.
    @Entry var openRoute: ((any Route) -> Void)?
}

/// A card's text that opens a detail (`MediaCardUi.titleLink`, `captionLink`) with a click, a pointer's tap or a
/// touch: a link, underlined while the pointer is over it, with the link pointer on the Mac and the pointer's highlight
/// on an iPad. A remote or a keyboard opens the card itself, so on Apple TV, or without `openRoute`, it is plain text.
struct CardLinkText: View {
    let text: String
    let route: (any Route)?

    @Environment(\.openRoute) private var openRoute
    @State private var hovered = false

    var body: some View {
        #if os(tvOS)
        Text(text)
        #else
        if let route, let openRoute {
            Text(text)
                .underline(hovered)
                .onHover { inside in
                    hovered = inside
                    #if os(macOS)
                    if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    #endif
                }
                #if os(iOS)
                .hoverEffect(.highlight)
                #endif
                .highPriorityGesture(TapGesture().onEnded { openRoute(route) })
        } else {
            Text(text)
        }
        #endif
    }
}

/// A card's caption with its leading link (`MediaCardUi.captionLink`: an episode's "S2", opening its season), the rest
/// plain; the whole caption plain without one.
struct LinkedCaption: View {
    let text: String
    let link: CardLink?

    var body: some View {
        if let link, text.hasPrefix(link.prefix) {
            HStack(spacing: 0) {
                CardLinkText(text: link.prefix, route: link.route).fixedSize()
                Text(text.dropFirst(link.prefix.count))
            }
        } else {
            Text(text)
        }
    }
}

extension View {
    /// "View details" among this element's accessibility actions where `route` is given, opening it.
    func viewDetailsAction(_ route: (any Route)?, open: ((any Route) -> Void)?) -> some View {
        accessibilityActions {
            if let route, let open {
                Button(T.shared.mediaMenu.viewDetails) { open(route) }
            }
        }
    }
}
