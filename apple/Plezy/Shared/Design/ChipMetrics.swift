import SwiftUI

/// The app's chips' size and type, one set per form factor: Detail's season chips (`DetailSeasonChips`, no fill at
/// rest), Home's shortcuts and Live TV's tabs and time chips (`ChipStyle`).
enum ChipMetrics {
    static func height(_ formFactor: FormFactor) -> CGFloat {
        #if os(macOS)
        28
        #else
        formFactor == .tv ? 72 : 36
        #endif
    }

    /// From a chip's edge to its name.
    static func inset(_ formFactor: FormFactor) -> CGFloat {
        formFactor == .tv ? 24 : 12
    }

    /// A chip's name, regular or, for a selected chip, semibold.
    static func font(_ formFactor: FormFactor) -> Font {
        formFactor == .tv ? .body : .subheadline
    }

    /// A name wider than this at the default text size is cut short; the cap grows with the text (`chipName`).
    static func maxNameWidth(_ formFactor: FormFactor) -> CGFloat {
        formFactor == .tv ? 560 : 240
    }
}

extension View {
    /// A chip's name: one line at its own width, cut short past `maxWidth` points at the default text size, a cap that
    /// grows with the text as the chips' font does (`ChipMetrics.font`: the subheadline, on tvOS the body), so a name
    /// whole at the default size stays whole at every size.
    func chipName(maxWidth: CGFloat) -> some View {
        modifier(ChipNameWidth(maxWidth: maxWidth))
    }
}

private struct ChipNameWidth: ViewModifier {
    let maxWidth: CGFloat

    /// The chips' font's size over its size at the default text size.
    #if os(tvOS)
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1
    #else
    @ScaledMetric(relativeTo: .subheadline) private var scale: CGFloat = 1
    #endif

    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .frame(maxWidth: maxWidth * scale)
            .fixedSize(horizontal: true, vertical: false)
    }
}
