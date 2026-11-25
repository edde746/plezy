import SwiftUI

/// The app's chip (Live TV's, Home's shortcuts): the system's glass button on Apple TV 26 and later (its
/// focus look: it lifts and turns white), `glassCapsule` on iOS and macOS 26 and later (interactive glass that lights
/// up and swells under a press); before 26 the surface (`SurfaceButtonStyle`: dims pressed; on Apple TV white with
/// black text while focused). Its label is `chipLabel`.
struct ChipStyle: ViewModifier {
    @Environment(\.formFactor) private var formFactor

    func body(content: Content) -> some View {
        #if os(tvOS)
        if #available(tvOS 26, *) {
            content.pillButtonStyle()
        } else {
            surface(content)
        }
        #else
        if #available(iOS 26, macOS 26, *) {
            content.glassCapsule()
        } else {
            surface(content)
        }
        #endif
    }

    private func surface(_ content: Content) -> some View {
        content.buttonStyle(SurfaceButtonStyle(fill: Palette.surfaceContainer, radius: ChipMetrics.height(formFactor) / 2))
    }
}

extension View {
    /// A chip's label (`ChipStyle`): one line at its own width in the chips' font, `ChipMetrics.inset` in from the
    /// capsule's ends, at the chips' height (`ChipMetrics`), the capsule taking the press. The system's glass button on
    /// Apple TV 26 and later pads its label itself.
    func chipLabel(_ formFactor: FormFactor) -> some View {
        font(ChipMetrics.font(formFactor))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .chipInsets(formFactor)
    }

    @ViewBuilder
    private func chipInsets(_ formFactor: FormFactor) -> some View {
        #if os(tvOS)
        if #available(tvOS 26, *) {
            contentShape(Capsule())
        } else {
            padded(formFactor)
        }
        #else
        padded(formFactor)
        #endif
    }

    private func padded(_ formFactor: FormFactor) -> some View {
        padding(.horizontal, ChipMetrics.inset(formFactor))
            .frame(minHeight: ChipMetrics.height(formFactor))
            .contentShape(Capsule())
    }
}
