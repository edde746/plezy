import SwiftUI
import PlezyKit

extension View {
    /// A screen of `RouteStack` on the Mac, a top-level destination's or a pushed one's. The window's toolbar draws no
    /// background over it (macOS 15 and later), in a window and in full screen, where the window's buttons stay too
    /// (`WindowLikeFullScreenTitleBar`): the screen's black reaches up under the toolbar, which reads as black while the
    /// window is key. On macOS 26 and later, while the screen's content is scrolled up under the toolbar, it fades to the
    /// window's black in the band, most at the top, so the window's buttons, Back, the title and the toolbar's items stay
    /// readable over it (`WindowToolbarBand`); at rest the band shows what it did, the screen's black or the top of Home's
    /// and Detail's backdrop. A header row on the band draws the fade under itself (`screenHeader`). The toolbar's
    /// background was drawn over each scroll view under the band, as wide as that scroll
    /// view: once the window wasn't key (another app in front, a sheet over the window) it showed as a grey box over
    /// Addons' and Settings' centred column and over Detail's details column, and with the window key the pointer coming
    /// down from the band into a screen whose content reaches under it (Home, Settings, Discover, Library) faded that
    /// screen to black for about a third of a second before it snapped back (macOS 26). The toolbar's own scroll edge
    /// did the same, soft or automatic; hard, it was a dark bar with a hard edge. Without the background a click on a
    /// control on the band (a destination's header row) reaches the control, which the background would take. The band's
    /// empty parts are the title bar's (`WindowDragArea`): a header row's, and over a screen without one the whole band,
    /// where content scrolled up under it takes no clicks, as under a title bar. No blur: macOS has no public progressive
    /// blur, and the fade was chosen over a private one. Elsewhere it does nothing.
    @ViewBuilder
    func windowToolbarBand() -> some View {
        #if os(macOS)
        if #available(macOS 26, *) {
            modifier(WindowToolbarBand())
                .background(WindowLikeFullScreenTitleBar())
        } else if #available(macOS 15, *) {
            toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .background(WindowLikeFullScreenTitleBar())
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#if os(macOS)
@available(macOS 26, *)
private struct WindowToolbarBand: ViewModifier {
    /// A header row sits on the band and draws the fade under itself, its empty parts the title bar (`HeaderRowKey`).
    @State private var bandRow = false
    /// The band's height: the screen's top safe area.
    @State private var band: CGFloat = 0
    @State private var scrolled = false

    func body(content: Content) -> some View {
        content
            .environment(\.bandScrolled, scrolled)
            .scrollEdgeEffectHidden(true, for: .top)
            .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 0.5 } action: {
                scrolled = $1
            }
            .overlay(alignment: .top) {
                if !bandRow {
                    ZStack(alignment: .top) {
                        ScrollEdgeFade.under(band, shown: scrolled)
                        WindowDragArea().frame(height: band)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea(.container, edges: .top)
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { band = $0 }
            .onPreferenceChange(HeaderRowKey.self) { bandRow = $0 }
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }
}

extension View {
    /// A top-level destination's screen (`destination`, nil for any other), which the sidebar names. The toolbar is
    /// navigation chrome alone (`screenHeader` has the rules): while the screen is on top (`onTop`) it shows the
    /// sidebar's toggle and no title (the window keeps the title for the Window menu; before macOS 15 the toolbar shows
    /// it), over no background (`windowToolbarBand`). On macOS 26 and later the screen's header row, its actions at its
    /// end, sits on the band's line, level with the window's buttons, its height going down as `toolbarBand`, and the
    /// screen's content starts right under the band. A screen without a header row (Settings, Home) starts right under
    /// the band too: its first row's own top padding (`firstRowPadding`) lies under the band, whatever is pushed over the
    /// screen, so it doesn't move on a push or pop. A pushed screen's toolbar holds Back, its title and its actions.
    func destinationChrome(_ destination: TopLevelDestination?, onTop: Bool) -> some View {
        modifier(DestinationChrome(isDestination: destination != nil, onTop: onTop))
    }
}

private struct DestinationChrome: ViewModifier {
    let isDestination: Bool
    let onTop: Bool

    /// The toolbar's band over the screen: the height of its top safe area.
    @State private var band: CGFloat?

    /// The top padding of a screen's first row under the band.
    private static let firstRowPadding: CGFloat = 8

    func body(content: Content) -> some View {
        toolbar(content)
            // A negative spacing narrows the safe area by as much.
            .safeAreaInset(edge: .top, spacing: isDestination ? -Self.firstRowPadding : 0) { Color.clear.frame(height: 0) }
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { band = $0 > 0 ? $0 : nil }
    }

    @ViewBuilder
    private func toolbar(_ content: Content) -> some View {
        let topLevel = isDestination && onTop
        if #available(macOS 26, *) {
            content
                .environment(\.toolbarBand, isDestination ? band : nil)
                .toolbarTitleHidden(topLevel)
        } else {
            content.toolbarTitleHidden(topLevel)
        }
    }
}
#elseif os(iOS)
extension View {
    /// A top-level destination's screen (`destination`, nil for any other) while it is on top (`onTop`), which the tabs
    /// name. iPhone (the tab bar at the bottom): no navigation bar at all (where iOS 27.1's vertical bar shows, the bar
    /// for the screen's actions, whose items go in the vertical bar's column), the content fading softly under the
    /// status bar (`softTopEdge`) or under the screen's header row (`screenHeader`). iPad (the sidebar, or the floating
    /// tab bar at the top): the bar without its title, the content fading under it (iOS 26 and later). Hidden beside the sidebar, the bar left the app never idle
    /// once iPad turned to landscape (every tap waited out XCUITest's animation timeout), with the soft edge effect and
    /// with a plain fade alike. On iOS 26 and later the bar stays, empty and clear, holds none of the screen's actions,
    /// which end its header row (Library's Calendar alone in the bar above its filters wasted a row; under the floating
    /// tab bar Downloads' Sync rules stood a line above its filters), and the screen starts on its line as iPhone's does
    /// under the status bar: the header row level with the sidebar's toggle, or right under the floating tab bar, so no
    /// empty bar shows above it. Under the floating tab bar the stack's top safe area (`stackTop`) holds the tabs' line,
    /// but once the sidebar hides in landscape it is the shell's alone (`shellTop`, iOS 27.0) and the tabs sit on the
    /// bar's line: there the screen starts under the bar (kept at the stack's top, the row lay under the tabs, which
    /// covered its middle: Libraries' sort).
    /// Before iOS 18 iPad's split view keeps the title. Settings is a settings page as iOS has them on iPhone: the bar
    /// with its large title, which goes inline as the list scrolls up under it, its sections' pages pushed under the
    /// same bar. On iPad (the sidebar, or the floating tab bar) Settings is as the other destinations, its bar empty,
    /// and the hub names itself at the top of its centred column (`settingsTitleInContent`): the bar's large title sat
    /// at the screen's leading edge, out of line with the column.
    ///
    /// A page pushed over iPhone's destination shows the bar, which comes with it and goes with it: the destination's
    /// content keeps its top where it is at rest (`stackTop`, the stack's top safe area without the bar) all the while,
    /// and the bar holds no title for it (iOS 18 and later): the destination's title is inline, the bar's title item,
    /// which the bar leaves out. Large, it isn't the bar's title item: iOS 27.1's vertical bar (the iPhone Duo's cover
    /// turned) showed Home's and Library's large title over their content while a page went back. Following the
    /// bar, the content moved down by the bar's height as the page came and back up as it went, once the page had gone
    /// (iPhone: Settings back from a section, Home back from Downloads or Detail).
    @ViewBuilder
    func destinationChrome(_ destination: TopLevelDestination?, onTop: Bool) -> some View {
        if #available(iOS 18, *) {
            modifier(DestinationChrome(destination: destination, onTop: onTop))
        } else {
            modifier(LegacyDestinationChrome(destination: destination, onTop: onTop))
        }
    }

    /// While `enabled`, content scrolled up under the status bar or the navigation bar fades out there into the
    /// background, and only then (`SafeAreaTopFade`): the same drawn fade as under a header row (`screenHeader`), so
    /// every destination's edge matches (Home's), the system's own scroll edge effect hidden. Disabled, the bar is
    /// empty, and an empty bar takes the navigation bar's own effect away (iPad's Home showed its shelves sharp under
    /// the bar and its buttons).
    @available(iOS 18, *)
    func softTopEdge(_ enabled: Bool) -> some View {
        modifier(SoftTopEdge(enabled: enabled))
    }
}

@available(iOS 18, *)
private struct SoftTopEdge: ViewModifier {
    let enabled: Bool

    /// The content is scrolled up under the top of the screen.
    @State private var scrolled = false

    func body(content: Content) -> some View {
        edge(content)
            .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 0.5 } action: {
                scrolled = $1
            }
    }

    @ViewBuilder
    private func edge(_ content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .scrollEdgeEffectHidden(enabled, for: .top)
                .safeAreaBar(edge: .top, spacing: 0) {
                    if enabled { SafeAreaTopFade(shown: scrolled, below: statusBarFade) }
                }
        } else {
            content.safeAreaInset(edge: .top, spacing: 0) {
                if enabled { SafeAreaTopFade(shown: scrolled, below: statusBarFade) }
            }
        }
    }
}

/// How far the fade over the status bar (`SafeAreaTopFade`) reaches into the safe area under it: its whole ramp, so it
/// is opaque at the window's top also where no status bar lies there (iOS 27.1's vertical bar holds it, the iPhone
/// Duo), where a shorter one left Home's chips half faded under the top.
private let statusBarFade: CGFloat = 32

extension EnvironmentValues {
    /// The destination's screen shows no navigation bar (iPhone) or an empty one over its content (iPad on iOS 26 and
    /// later, `destinationChrome`): nothing goes in the bar. Its actions go in the screen's header row
    /// (`screenHeader`'s: Library's Calendar, Downloads' Pause all); the running profile stays in the sidebar's foot
    /// (iPad) or Settings' profile card (iPhone) (`RouteView`).
    @Entry var destinationBarEmpty = false
    /// Settings' hub shows its title at the top of its column, not in the bar (iPad, `destinationChrome`).
    @Entry var settingsTitleInContent = false
    /// The top safe area of the screen's stack (`RouteStack`), without the stack's navigation bar: where iPhone's
    /// destinations keep their content's top while a pushed page's bar comes and goes (`destinationChrome`). Nil until
    /// measured.
    @Entry var stackTop: CGFloat? = nil
    /// The top safe area of iPad's shell, its tabs' not in it (`PadShellTop`): under the floating tab bar a stack whose
    /// top safe area is no more than this one doesn't hold the tabs' line (`destinationChrome`). Nil until measured, and
    /// on iPhone.
    @Entry var shellTop: CGFloat? = nil
}

/// iPad's shell: measures its top safe area for the screens' chrome (`shellTop`). iPhone's shell is left as it is.
struct PadShellTop: ViewModifier {
    @State private var shellTop: CGFloat?

    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { shellTop = $0 }
                .environment(\.shellTop, shellTop)
        } else {
            content
        }
    }
}

@available(iOS 18, *)
private struct DestinationChrome: ViewModifier {
    let destination: TopLevelDestination?
    let onTop: Bool

    @Environment(\.tabBarPlacement) private var placement
    @Environment(\.stackTop) private var stackTop
    @Environment(\.shellTop) private var shellTop
    /// The navigation bar's items go in iOS 27.1's vertical bar's column (the iPhone Duo's screens): the screen's
    /// actions go there as toolbar items (`screenHeader`), so iPhone's bar shows there, its items in the column.
    @Environment(\.verticalBarEdge) private var verticalBar
    /// The screen shows a header row (`screenHeader`), which draws the scroll edge under itself on iOS 26.
    @State private var headerRow = false

    func body(content: Content) -> some View {
        let compact = placement != .sidebar && placement != .topBar
        // Settings' bar shows its title on iPhone, as on a pushed page; on iPad the hub's column holds it.
        let untitled = destination != nil && (destination != .settings || !compact)
        let phone = untitled && onTop && compact
        let pad = untitled && onTop && !compact
        // iPhone's, and iPad's on the bar's line, whether or not a page is pushed over it.
        let keptTop = untitled && (compact || onBarLine) ? stackTop : nil
        content
            .environment(\.destinationBarEmpty, phone || pad && barEmpty)
            .environment(\.settingsTitleInContent, destination == .settings && !compact)
            .toolbar(phone && verticalBar == nil ? .hidden : .automatic, for: .navigationBar)
            .softTopEdge(softEdge(untitled: untitled, phone: phone))
            .onPreferenceChange(HeaderRowKey.self) { headerRow = $0 }
            // No title for the destination in iPhone's bar, which a page pushed over it brings and takes away: the
            // tab's name crossed the header row kept under it. Inline, so the title is the bar's title item that goes;
            // iPad's bar too.
            .toolbar(removing: untitled && (compact || onTop) ? .title : nil)
            .navigationBarTitleDisplayMode(untitled ? .inline : destination == .settings ? .large : .automatic)
            .safeAreaPadding(.top, keptTop ?? 0)
            .ignoresSafeArea(.container, edges: keptTop == nil ? [] : .top)
    }

    /// iPad on iOS 26 and later: the bar holds none of the screen's actions (the type's comment).
    private var barEmpty: Bool {
        if #available(iOS 26, *) { return true }
        return false
    }

    /// iPad on iOS 26 and later, beside the sidebar or under the floating tab bar where the stack's top safe area holds
    /// the tabs' line: the screen starts on the bar's line (the type's comment).
    private var onBarLine: Bool {
        guard #available(iOS 26, *) else { return false }
        if placement == .sidebar { return true }
        return placement == .topBar && (stackTop ?? 0) > (shellTop ?? 0)
    }

    /// The soft top edge (`softTopEdge`): on iOS 26 and later every untitled destination's without a header row (whose
    /// row draws the fade to the background under itself and hides the system's, `screenHeader`), under iPad's bar too,
    /// and whether or not a page is pushed over it; before, iPhone's on top only (the fade over the status bar).
    /// Settings' bar has its own. Covered, the destination took the navigation bar's own edge effect, and an
    /// interactive swipe back keeps it covered until the swipe ends, so iOS 27.1's vertical bar (the iPhone Duo's cover)
    /// drew a dark, blurred band over Library's header row and the posters' tops all through the swipe.
    private func softEdge(untitled: Bool, phone: Bool) -> Bool {
        if #available(iOS 26, *) { untitled && !headerRow } else { phone }
    }
}

/// iOS 17: iPhone's destinations as on iOS 18, but for the fade over the status bar, always shown (iOS 17 has no
/// scroll geometry to show it by); iPad's split view keeps their titles.
private struct LegacyDestinationChrome: ViewModifier {
    let destination: TopLevelDestination?
    let onTop: Bool

    @Environment(\.formFactor) private var formFactor
    @Environment(\.stackTop) private var stackTop

    func body(content: Content) -> some View {
        let untitled = destination != nil && destination != .settings && formFactor == .compact
        let phone = untitled && onTop
        let keptTop = untitled ? stackTop : nil
        content
            .environment(\.destinationBarEmpty, phone)
            .toolbar(phone ? .hidden : .automatic, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                if phone { SafeAreaTopFade(shown: true, below: statusBarFade) }
            }
            .safeAreaPadding(.top, keptTop ?? 0)
            .ignoresSafeArea(.container, edges: keptTop == nil ? [] : .top)
    }
}

/// Calls `action` with where the tabs show (iPad's sidebar or floating tab bar, iPhone's tab bar), as that changes, from
/// inside a tab.
@available(iOS 18, *)
struct TabBarPlacementReader: ViewModifier {
    let action: (TabBarPlacement?) -> Void

    @Environment(\.tabBarPlacement) private var placement

    func body(content: Content) -> some View {
        content.onChange(of: placement, initial: true) { _, placement in action(placement) }
    }
}
#endif
