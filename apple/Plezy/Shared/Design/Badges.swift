import SwiftUI
import PlezyKit

/// How strongly a `BadgeView` stands out.
enum BadgeEmphasis {
    /// A white fill with black text: the one thing to notice (a stream's resolution).
    case strong
    /// A solid grey fill: the rest of the facts.
    case tonal
}

/// A short fact about an item (resolution, HDR, codec, size, "Built in"), as preformatted by the store: a solid
/// rounded rectangle, never outlined. On a focused tvOS surface (white) the badges turn around, so none vanishes into
/// it: the strong badge black with white text, the others a mid grey with black text. Text wider than the room
/// (a narrow card's "Pending approval") wraps onto a second line rather than being cut.
struct BadgeView: View {
    let text: String
    var emphasis: BadgeEmphasis = .tonal

    @Environment(\.onFocusedSurface) private var onFocused

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: Radius.extraSmall, style: .continuous))
    }

    private var foreground: Color {
        switch emphasis {
        case .strong: onFocused ? Palette.focusedSurface : Palette.onPrimary
        case .tonal: onFocused ? Palette.onFocusedSurface : Palette.onBackground
        }
    }

    private var background: Color {
        switch emphasis {
        case .strong: onFocused ? Palette.onFocusedSurface : Palette.primary
        case .tonal: onFocused ? Palette.focusedTonalBadge : Palette.surfaceContainerHigh
        }
    }
}

/// Lays its children out left to right, `spacing` apart, starting a new line when the next one doesn't fit; each line
/// at the leading edge, or centred with `alignment` `.center`. Lines are `lineSpacing` apart (`spacing` by default).
/// Each child is as wide as it wants and as tall as it is at that width: a child that caps its width with its text
/// wrapping inside (a profile tile's name at the accessibility text sizes) is taller there than at its one-line size,
/// which left its text over what came after it (iOS 27.0).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat?
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + (lineSpacing ?? spacing) * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = alignment == .center ? bounds.minX + (bounds.width - row.width) / 2 : bounds.minX
            for index in row.indices {
                let size = Self.size(of: subviews[index])
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + (lineSpacing ?? spacing)
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// `subview`'s own width, and its height at that width.
    private static func size(of subview: LayoutSubview) -> CGSize {
        let width = subview.sizeThatFits(.unspecified).width
        return CGSize(width: width, height: subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height)
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = Self.size(of: subviews[index])
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if needed > width, !row.indices.isEmpty {
                rows.append(row)
                row = Row()
            }
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
        }
        if !row.indices.isEmpty { rows.append(row) }
        return rows
    }
}
