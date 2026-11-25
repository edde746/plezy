#if !os(tvOS)
import SwiftUI

/// A top scroll edge the app draws itself, where the system's soft scroll edge doesn't reach (Library's paged tabs,
/// under their header row; iOS 26's status bar alone; before iOS 26; the Mac's toolbar band): while `shown`, content
/// scrolled up under the top of the screen fades out into the screen's background: opaque down to `ramp` points above
/// its bottom, then easing out to clear with no edge where it ends (a smoothstep: no change of slope at either end of
/// the ramp, where a linear ramp showed a line). No blur: neither iOS nor macOS has a public progressive blur, and a
/// material over the content read as a grey band with a hard bottom edge. On iOS it eases in and out; on the Mac it
/// shows at once: there its animated opacity stayed at none over Library's grid (macOS 26), the posters sharp under the
/// band. It takes no touch.
struct ScrollEdgeFade: View {
    let shown: Bool
    var ramp: CGFloat = 32

    /// The ramp's samples: enough that its steps don't show.
    private static let steps = 16

    var body: some View {
        let background = Palette.background
        VStack(spacing: 0) {
            background
            LinearGradient(
                stops: (0...Self.steps).map { step in
                    let location = Double(step) / Double(Self.steps)
                    return .init(color: background.opacity(1 - location * location * (3 - 2 * location)), location: location)
                },
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: ramp)
        }
        .opacity(shown ? 1 : 0)
        #if os(iOS)
        .animation(.easeOut(duration: 0.2), value: shown)
        #endif
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// How far past the bottom of the controls a fade under them (`under`) reaches before it is clear.
    static let reach: CGFloat = 24

    /// The fade under controls `height` points from its top (iOS's header row, the Mac's toolbar band and the row on
    /// it), reaching `reach` past their bottom: opaque under most of them, so a title or a filter over posters stays on
    /// black, then easing out from `reach` above their bottom. Ending at their bottom, the Mac's band left the toolbar's
    /// title over half-faded posters.
    static func under(_ height: CGFloat, shown: Bool) -> some View {
        ScrollEdgeFade(shown: shown, ramp: reach * 2).frame(height: height + reach)
    }
}

#if os(iOS)
/// `ScrollEdgeFade` from the window's top to `below` points past the top of the safe area, where this view of no height
/// goes (as a bar or inset of no height, or at the top of the content under the bars): placed from a reader's frame and
/// safe area, a fade over the status bar came out 140 pt tall on iOS 26.5, both reading the status bar's 62 pt.
struct SafeAreaTopFade: View {
    let shown: Bool
    let below: CGFloat

    var body: some View {
        Color.clear
            .frame(height: 0)
            .overlay(alignment: .top) {
                Color.clear
                    .frame(height: below)
                    .background { ScrollEdgeFade(shown: shown).ignoresSafeArea(edges: .top) }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
#endif
#endif
