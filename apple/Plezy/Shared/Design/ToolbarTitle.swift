import SwiftUI

#if !os(tvOS)
extension View {
    /// While `hidden`, the navigation bar (the Mac: the window's toolbar) leaves out the title (iOS 18 and macOS 15 and
    /// later; before, it shows it), where the screen names itself (Detail, a music header, Watch Together's lobby, the
    /// Streams sheet's heading, a top-level destination's sidebar entry) and keeps the title for the back menu and the
    /// Window menu. One modifier either way, so a screen keeps its state when `hidden` changes (a destination once a
    /// screen is pushed over it).
    @ViewBuilder
    func toolbarTitleHidden(_ hidden: Bool = true) -> some View {
        if #available(iOS 18, macOS 15, *) {
            toolbar(removing: hidden ? .title : nil)
        } else {
            self
        }
    }
}
#endif

extension View {
    /// The navigation title small in the bar's middle rather than large under it (iOS); elsewhere the view as it is.
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// `title` in the navigation bar of a page that shows the bar (a page pushed over another, a sheet's form), inline
    /// on iOS (`inlineNavigationTitle`); where the page names itself in its content (`inContent`, `titleInContent`) the
    /// bar shows none, and on tvOS, whose bar holds the title alone, the page has no navigation title then, so the
    /// heading isn't said twice. On tvOS the bar stays where it is while the page scrolls (tvOS 26.5), and where
    /// UIKit's own lists hide their rows above the bar's lower edge, fading them in below it, SwiftUI's draw them on up
    /// the screen, under the title: so the page shows nothing above that edge and fades in over the 24 points below
    /// it. The page's frame runs up under the bar; the mask keeps out of its top safe area, so it starts at the bar's
    /// edge, and runs on past the bottom and side safe areas, where rows still show.
    func pageTitle(_ title: String, inContent: Bool = false) -> some View {
        #if os(tvOS)
        navigationTitle(inContent ? "" : title)
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 24)
                    Color.black
                }
                .ignoresSafeArea(edges: [.horizontal, .bottom])
            }
        #else
        navigationTitle(title)
            .inlineNavigationTitle()
            .titleInContent(inContent)
        #endif
    }

    /// A page that names itself in its content (a detail page's hero title): on iOS its navigation bar shows no title at
    /// any scroll position, so the bar keeps one look and nothing under it moves as the page scrolls; on the Mac its
    /// toolbar shows none either, the window keeping the title for the Window menu. The page keeps its navigation title
    /// for Back's menu. On tvOS the view as it is (`pageTitle(_:inContent:)` leaves the title out there). `inContent`
    /// false shows the bar's title again (Watch Together past its lobby), one modifier either way so the page keeps its
    /// state.
    func titleInContent(_ inContent: Bool = true) -> some View {
        #if os(iOS)
        modifier(TitleInContent(inContent: inContent))
        #elseif os(macOS)
        toolbarTitleHidden(inContent)
        #else
        self
        #endif
    }
}

#if os(iOS)
private struct TitleInContent: ViewModifier {
    let inContent: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.toolbarTitleHidden(inContent)
        } else {
            // iOS 17 can't take the bar's title item away (`toolbar(removing:)` is iOS 18): an empty item takes its place.
            content.toolbar {
                if inContent {
                    ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
                }
            }
        }
    }
}
#endif
