import SwiftUI
import PlezyKit

/// A row that scrolls sideways, its scroll bar hidden: a shelf (`ShelfRow`), a show's seasons, Home's shortcuts, a TV
/// mode detail's episodes, the tag suggestions. Touch and focus scroll it as any scroll view (iPhone, iPad, Apple TV: a
/// remote's or a keyboard's focus moving along it scrolls it to the focused element).
///
/// On the Mac, where a mouse has no sideways swipe, the row also scrolls by the pointer (`PointerRow`):
/// - it fades out over its last `RowFade.width` at an end where more of it lies past that end, and is cut by nothing at
///   an end it has reached;
/// - while the pointer is over it, a round button at each such end (‹ `row.back`, › `row.forward`) scrolls it by about
///   its width, less the fades, so what was faded at that end shows whole;
/// - a press dragged along it more than `rowDragStart` scrolls it with the pointer, and flings on as the press
///   lets go at speed; the press then opens nothing. A press that hardly moves is a click on what it is on;
/// - a mouse's wheel turned over it scrolls it along (the wheel away from the user, back), until it reaches that end,
///   where the wheel scrolls the page again; shift and the wheel, and a trackpad's or a Magic Mouse's swipe, scroll it
///   as macOS does.
struct SideScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        #if os(macOS)
        PointerRow(content: content)
        #else
        ScrollView(.horizontal, showsIndicators: false) { content }
        #endif
    }
}

/// Where more of a sideways scrolling row lies past its ends: its content's frame (`proxy`) in its scroll view, which
/// shows it from `margin` (a leading content margin) on.
struct RowEnds: Equatable {
    var leading = false
    var trailing = false

    init() {}

    init(_ proxy: GeometryProxy, margin: CGFloat = 0) {
        let frame = proxy.frame(in: .scrollView)
        let width = proxy.bounds(of: .scrollView)?.width ?? frame.maxX
        leading = frame.minX < margin - 0.5
        trailing = frame.maxX > width + 0.5
    }
}

/// The mask of a sideways scrolling row: clear at an end where more of it lies past it (`ends`), opaque over `width`
/// inward from there; opaque everywhere else. Its change animates.
struct RowFade: View {
    let ends: RowEnds
    var width: CGFloat = Self.width

    /// The fade of a row on the Mac (`SideScroll`).
    static let width: CGFloat = 48

    var body: some View {
        HStack(spacing: 0) {
            edge(shown: ends.leading, from: .leading)
            Rectangle()
            edge(shown: ends.trailing, from: .trailing)
        }
        .animation(.easeOut(duration: 0.2), value: ends)
    }

    private func edge(shown: Bool, from end: UnitPoint) -> some View {
        LinearGradient(
            colors: [.black.opacity(shown ? 0 : 1), .black],
            startPoint: end,
            endPoint: end == .leading ? .trailing : .leading
        )
        .frame(width: width)
    }
}

#if os(macOS)
/// `SideScroll` on the Mac: the row's scroll view in AppKit (`RowScroller`) scrolled by its buttons, a drag and the
/// wheel, faded where more lies past an end.
private struct PointerRow<Content: View>: View {
    let content: Content

    @State private var scroller = RowScroller()
    @State private var ends = RowEnds()
    @State private var hovered = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // On the content, its gaps too: the scroll view's own content takes the presses in it.
            content
                .contentShape(Rectangle())
                .highPriorityGesture(drag)
                .onGeometryChange(for: RowEnds.self) { RowEnds($0) } action: { ends = $0 }
                .background(alignment: .topLeading) { RowScrollerAnchor(scroller: scroller).frame(width: 0, height: 0) }
        }
        // The fade's ends alone: what the row lets draw past its top and bottom (a focus ring, a lifted card) stays.
        .mask { RowFade(ends: ends).padding(.vertical, -rowOverflow) }
        .overlay(alignment: .leading) {
            button(shown: ends.leading, systemImage: "chevron.left", label: T.shared.accessibility.scrollBack, id: "row.back") {
                scroller.page(forward: false, less: 2 * RowFade.width)
            }
        }
        .overlay(alignment: .trailing) {
            button(shown: ends.trailing, systemImage: "chevron.right", label: T.shared.accessibility.scrollForward, id: "row.forward") {
                scroller.page(forward: true, less: 2 * RowFade.width)
            }
        }
        .onHover { inside in
            hovered = inside
            scroller.followWheel(inside)
        }
        .onDisappear { scroller.followWheel(false) }
    }

    /// A scroll button inside the row's end, while the pointer is over the row and more of it lies past that end.
    private func button(shown: Bool, systemImage: String, label: String, id: String, action: @escaping () -> Void) -> some View {
        ZStack {
            if hovered && shown {
                IconButton(systemImage: systemImage, label: label, id: id, action: action)
                    .padding(.horizontal, 8)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: hovered && shown)
    }

    /// A press dragged along the row: the row follows it, and flings on from where it lets go. It wins over the press of
    /// what it started on once it has moved `rowDragStart`, so a card dragged doesn't open.
    private var drag: some Gesture {
        DragGesture(minimumDistance: rowDragStart, coordinateSpace: .global)
            .onChanged { scroller.drag(by: $0.translation.width) }
            .onEnded { scroller.endDrag(by: $0.translation.width, flingTo: $0.predictedEndTranslation.width) }
    }
}

/// How far a press moves along a row on the Mac before it drags the row rather than clicks (`PointerRow`).
private let rowDragStart: CGFloat = 6

/// How far past its top and bottom a row on the Mac may draw: its fade masks its ends alone (`PointerRow`).
private let rowOverflow: CGFloat = 100
#endif
