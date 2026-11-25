import SwiftUI

extension EnvironmentValues {
    /// Inside a compact header row (`screenHeader` on a phone, and a one-line row on iPad and the Mac whose filters
    /// don't all fit whole): a capsule with a symbol shows the symbol alone, without its chevron, but a named one
    /// (`FilterMenu.named`: Library's library).
    @Entry var compactFilters = false
    /// In a one-line header row that gives way a step at a time (`screenHeader`'s `scrolls`, `HeaderRank`): the
    /// controls ranked up to this show their symbol alone (the Mac's actions their icon); 0, everything whole.
    @Entry var symbolRank = 0
}

/// The order a one-line header row gives way in (`symbolRank`): at each rank the controls ranked up to it show their
/// symbols alone. First the actions' titles, the secondary buttons (the Mac's; elsewhere they show their icons alone
/// already): Library's Shuffle, then its ⋯; then the filters: Library's sort, then its view, then its Filters and type.
/// Only past the last does a row cut its widest filter's text short (`compactFilters`, `FittingRow`): Library's name.
enum HeaderRank {
    static let shuffle = 1
    static let more = 2
    static let sort = 3
    static let view = 4
    static let filters = 5
    /// The ranks a whole line takes, actions and filters (iPad, the Mac).
    static let lineForms = [0, shuffle, more, sort, view, filters]
    /// The ranks a phone's filters take: its actions show their icons alone at every rank.
    static let filterForms = [0, sort, view, filters]
}

#if !os(tvOS)
/// Its children side by side, `spacing` apart, each at its own width while they all fit; past that the narrowest keep
/// their width and the widest share what is left evenly (a capsule then cuts its text short), so the row doesn't run
/// past the width it is given (Compose's `FittingRow`) unless a child takes more than its share there (a capsule's
/// padding and chevron around an ellipsis, a symbol): then the row is as wide as its children take, which a scrolling
/// row scrolls (`screenHeader`'s `scrolls`). Where it `wraps` (the header row on iOS, `HeaderMetrics.wraps`) the
/// children that don't fit go on more lines instead, `spacing` apart, each at its own width up to the row's, so their
/// text stays whole. On one line it tells `onLeadRoom`, after each placement, the room its first child (Library's
/// picker) has beside the others at their own widths (less than none where they don't fit), for a screen that frees
/// more of the row where its name would be cut too short.
struct FittingRow: Layout {
    /// First, so a trailing closure after the others is the row's content, not this.
    var onLeadRoom: (@MainActor @Sendable (CGFloat) -> Void)?
    let spacing: CGFloat
    var wraps = false

    /// A line's children: each one's index and its width on the line.
    private typealias Line = [(index: Int, width: CGFloat)]

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = arrange(subviews, in: proposal.width)
        let width = lines.map { $0.map(\.width).reduce(0, +) + gaps($0.count) }.max() ?? 0
        return CGSize(width: width, height: height(of: lines, subviews))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let lines = arrange(subviews, in: bounds.width)
        if let onLeadRoom, lines.count == 1, let width = proposal.width, width.isFinite {
            // The width given, not the bounds: a row whose children all fit is narrower than that.
            let others = subviews.dropFirst().map { $0.sizeThatFits(.unspecified).width }.reduce(0, +)
            let room = width - gaps(subviews.count) - others
            // After the update under way: SwiftUI's state changes in the next one.
            Task { @MainActor in onLeadRoom(room) }
        }
        // Centred on the bounds' height, as one line is.
        var y = bounds.midY - height(of: lines, subviews) / 2
        for line in lines {
            let lineHeight = height(of: line, subviews)
            var x = bounds.minX
            for (index, width) in line {
                subviews[index].place(at: CGPoint(x: x, y: y + lineHeight / 2), anchor: .leading, proposal: ProposedViewSize(width: width, height: nil))
                x += width + spacing
            }
            y += lineHeight + spacing
        }
    }

    private func gaps(_ count: Int) -> CGFloat {
        spacing * CGFloat(max(count - 1, 0))
    }

    private func height(of line: Line, _ subviews: Subviews) -> CGFloat {
        line.map { subviews[$0.index].sizeThatFits(ProposedViewSize(width: $0.width, height: nil)).height }.max() ?? 0
    }

    private func height(of lines: [Line], _ subviews: Subviews) -> CGFloat {
        lines.map { height(of: $0, subviews) }.reduce(0, +) + gaps(lines.count)
    }

    /// The children's lines within `available` (unlimited when nil or infinite): one line, each child at its own width
    /// while all fit, else the narrowest first at their own and the rest an even share of what is left; where it
    /// `wraps`, a new line wherever the next child doesn't fit, each child at its own width up to `available`.
    private func arrange(_ subviews: Subviews, in available: CGFloat?) -> [Line] {
        guard !subviews.isEmpty else { return [] }
        let wanted = subviews.map { $0.sizeThatFits(.unspecified).width }
        guard let available, available.isFinite else { return [wanted.indices.map { (index: $0, width: wanted[$0]) }] }
        if wraps, wanted.reduce(0, +) + gaps(wanted.count) > available {
            var lines: [Line] = []
            var lineWidth: CGFloat = 0
            for (index, wantedWidth) in wanted.enumerated() {
                let width = min(wantedWidth, available)
                if !lines.isEmpty, lineWidth + spacing + width <= available {
                    lines[lines.count - 1].append((index: index, width: width))
                    lineWidth += spacing + width
                } else {
                    lines.append([(index: index, width: width)])
                    lineWidth = width
                }
            }
            return lines
        }
        var left = max(available - gaps(wanted.count), 0)
        var widths = wanted
        for (done, index) in wanted.indices.sorted(by: { wanted[$0] < wanted[$1] }).enumerated() {
            let share = min(wanted[index], left / CGFloat(wanted.count - done))
            // A child that can't go as narrow as its share keeps the width it takes.
            widths[index] = max(share, subviews[index].sizeThatFits(ProposedViewSize(width: share, height: nil)).width)
            left = max(left - widths[index], 0)
        }
        return [widths.indices.map { (index: $0, width: widths[$0]) }]
    }
}
#endif
