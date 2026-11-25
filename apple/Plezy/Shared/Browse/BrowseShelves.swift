import SwiftUI
import PlezyKit

// Pieces Home, Explore and a hub's View all share: a screen's first focus on its first card (tvOS) and the focused
// item's backdrop behind the top of the page.

/// A screen's first focus on its first card (tvOS), kept by the screen's view: Home's first card, given once the screen
/// has one unless the user has moved focus while the screen was on top since it was asked for (`FocusRestore`): onto
/// the tab bar, a shortcut. Moves while another screen is on top don't count (a detail over Home, another tab, the
/// profile picker over the app): the screen tells it when it comes on top (`shown`) and leaves it (`hidden`), through
/// `firstFocus(_:to:isTop:focus:hold:)`, so a first focus asked for under another screen lands once that screen goes.
@MainActor
final class ScreenFirstFocus {
    private var pending: Bool
    /// The user's moves (`FocusRestore.userMoves`) as the screen last came on top or the first focus was asked for;
    /// nil while the screen isn't on top.
    private var since: Int?

    init(pending: Bool) {
        self.pending = pending
    }

    /// The screen is on top: the user's moves count from now, unless they already do (it was on top already).
    func shown() {
        if since == nil { since = FocusRestore.userMoves }
    }

    /// The screen left the top: a first focus still to give ends if the user moved focus while it was on top.
    func hidden() {
        if let since, FocusRestore.userMoves != since { pending = false }
        since = nil
    }

    /// The first focus still to give: the user's moves to count from (`FocusRestore.restore`'s `since`), or nil when
    /// none is pending. It stays pending until `given()`: a restore cut short (the target gone and back, the screen off
    /// the top) leaves it to the next.
    var pendingSince: Int? {
        guard pending else { return nil }
        return since ?? FocusRestore.userMoves
    }

    /// The first focus has been given, or the user moved first: none is pending any more.
    func given() {
        pending = false
    }
}

#if os(tvOS)
extension View {
    /// The screen's first focus (`ScreenFirstFocus`): `target` takes focus once there is one and the screen is on top, held
    /// for `hold` seconds (`FocusRestore.restore`), wherever the system put focus first (Home's first shortcut while its
    /// shelves load), as long as the user hasn't moved it; the screen coming on top and leaving it is told to
    /// `firstFocus`.
    func firstFocus<Value: Hashable>(
        _ firstFocus: ScreenFirstFocus,
        to target: Value?,
        isTop: Bool,
        focus: FocusState<Value?>.Binding,
        hold: Double = 0.5
    ) -> some View {
        onAppear { if isTop { firstFocus.shown() } }
            .onChange(of: isTop) { _, top in top ? firstFocus.shown() : firstFocus.hidden() }
            .onDisappear { firstFocus.hidden() }
            .task(id: FirstFocusTrigger(target: target.map(AnyHashable.init), isTop: isTop)) {
                guard let target, isTop, let since = firstFocus.pendingSince else { return }
                await FocusRestore.restore(focus, to: target, hold: hold, since: since, replacing: true)
                if !Task.isCancelled, focus.wrappedValue == target { firstFocus.given() }
            }
    }
}

/// When a screen's first-focus task runs: once its first card comes (or changes while still to be given), and again
/// once the screen is back on top.
private struct FirstFocusTrigger: Hashable {
    let target: AnyHashable?
    let isTop: Bool
}
#endif

/// How far down a screen's scroll view was scrolled (`scrollMemory`), kept beside the screen's store (`of`), which the
/// session keeps while the route is on a stack: the view, built again whenever its tab is shown again, opens where it
/// was.
@MainActor
final class ScrollMemory {
    /// The content's offset from its top at rest, in points.
    var y: CGFloat = 0

    private static let memories = NSMapTable<AnyObject, ScrollMemory>.weakToStrongObjects()

    /// The memory of the screen whose store is `store`, for as long as the store lives.
    static func of(_ store: AnyObject) -> ScrollMemory {
        if let memory = memories.object(forKey: store) { return memory }
        let memory = ScrollMemory()
        memories.setObject(memory, forKey: store)
        return memory
    }
}

extension View {
    /// This scroll view opens at `memory`'s offset and keeps there the offset each scroll comes to rest at. Before iOS
    /// 18 and macOS 15 (no scroll geometry to read the offset by) it opens at its top.
    @ViewBuilder
    func scrollMemory(_ memory: ScrollMemory) -> some View {
        if #available(iOS 18, macOS 15, *) {
            modifier(ScrollMemoryModifier(memory: memory))
        } else {
            self
        }
    }
}

/// The offset restored to the point (`ScrollPosition`). The point asked for isn't always where the view comes to rest
/// (a lazily laid out page comes back short of it), so until the view is scrolled the point asked for is corrected by
/// the difference between the offset measured and `memory`'s. A scroll view never scrolled opens at its top on its own.
@available(iOS 18, macOS 15, *)
private struct ScrollMemoryModifier: ViewModifier {
    let memory: ScrollMemory
    @State private var position: ScrollPosition
    /// The point asked of `position`, until the view is scrolled.
    @State private var asked: CGFloat?

    init(memory: ScrollMemory) {
        self.memory = memory
        let y = memory.y > 0 ? memory.y : nil
        _position = State(initialValue: y.map { ScrollPosition(y: $0) } ?? ScrollPosition())
        _asked = State(initialValue: y)
    }

    func body(content: Content) -> some View {
        content
            .scrollPosition($position)
            .onScrollGeometryChange(for: CGFloat.self, of: Self.offset) { _, y in
                guard let asked, abs(y - memory.y) > 0.5 else { return }
                self.asked = asked + memory.y - y
                position.scrollTo(y: asked + memory.y - y)
            }
            .onScrollPhaseChange { _, phase, context in
                if phase != .idle { asked = nil }
                if phase == .idle, asked == nil { memory.y = Self.offset(context.geometry) }
            }
    }

    /// How far the content is scrolled from its top at rest.
    private nonisolated static func offset(_ geometry: ScrollGeometry) -> CGFloat {
        geometry.contentOffset.y + geometry.contentInsets.top
    }
}

extension AppModel {
    /// `route` is the top screen of the shown stack: its tab is the one shown and nothing is pushed over it.
    func isTop(_ route: any Route) -> Bool {
        guard let last = backStack.last else { return false }
        return (last as AnyObject).isEqual(route as AnyObject)
    }
}

/// The backgrounds of the focused item (`key`) in turn (`CyclingBackdrop`), in colour and faint (30 %), fading into the
/// background towards the bottom and the leading edge so the content stays readable over it. It follows focus once focus
/// rests (a remote held down doesn't load every image), the next item's first background fading in over the last once
/// loaded. Behind the top of Home on tvOS and wide windows, and of a collection.
struct Backdrop: View {
    let key: String?
    let backdrops: [Artwork]

    @State private var shown: Shown?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let shown {
                    CyclingBackdrop(key: shown.key, backdrops: shown.backdrops, alignment: .topTrailing)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(0.3)
                }
                LinearGradient(
                    stops: [.init(color: Palette.background.opacity(0), location: 0.3), .init(color: Palette.background, location: 1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                LinearGradient(
                    stops: [.init(color: Palette.background, location: 0), .init(color: Palette.background.opacity(0), location: 0.55)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .containerRelativeFrame(.vertical) { height, _ in height * 0.7 }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .task(id: Shown(key: key, backdrops: backdrops)) {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            shown = Shown(key: key, backdrops: backdrops)
        }
    }

    private struct Shown: Equatable {
        let key: String?
        let backdrops: [Artwork]
    }
}
