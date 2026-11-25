import SwiftUI

#if os(tvOS)
/// The Apple TV's sheet: a panel along the screen's trailing edge, full height, over the dimmed screen, in a full-screen
/// cover (`trailingPanel`) that the remote's Menu closes. tvOS's own sheet is a card about 620 pt wide that clips what
/// is laid out wider (a form's rows, a navigation title) and squeezes a page to a sliver, and leaves focus on the
/// screen behind it. The panel is 740 pt wide inside the safe area (820 pt with the screen's trailing safe area, which
/// its surface fills too); the content starts 48 pt in from its leading edge, at the top of the safe area, on the
/// panel's surface (`isInSheet`: a page draws no background of its own there). The screen under the cover
/// stays focusable, so the content moves focus in when it shows, and what it shows with nothing to focus (loading, a
/// check running) holds focus (`holdsBackFocus`: the panel is a pushed screen). `id` is its accessibility identifier.
struct TrailingPanel<Content: View>: View {
    let id: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            content()
                .environment(\.isPushedScreen, true)
                .environment(\.isInSheet, true)
                .padding(.leading, TrailingPanelInsets.leading)
                .frame(width: 740)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(Palette.surfaceContainerLow)
        }
        .background(Palette.scrim.opacity(0.6))
        // On the row around the content: on the content itself it would replace the content's own identifier.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(id)
        .presentationBackground(.clear)
    }
}

/// The room in a `TrailingPanel` around its content: its leading padding, and past the content's trailing edge the
/// screen's trailing safe area, which the panel's surface fills. A row that scrolls sideways reaches across both to the
/// panel's edges.
enum TrailingPanelInsets {
    static let leading: CGFloat = 48
    static let trailing: CGFloat = 80
}

extension View {
    /// Shows `content` in a `TrailingPanel` identified `id` while `isPresented` (`statePresentation`); the remote's Menu
    /// sets it false. `onDismiss` runs once it has gone.
    func trailingPanel<Content: View>(
        isPresented: Binding<Bool>,
        id: String,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        statePresentation(isPresented) { base, shown in
            base.fullScreenCover(isPresented: shown, onDismiss: onDismiss) {
                TrailingPanel(id: id, content: content)
            }
        }
    }

    /// Shows `item`'s `content` in a `TrailingPanel` identified `id` while `item` is set (`statePresentation`); the
    /// remote's Menu clears it.
    func trailingPanel<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        id: String,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        statePresentation(item) { base, item in
            base.fullScreenCover(item: item, onDismiss: onDismiss) { value in
                TrailingPanel(id: id) { content(value) }
            }
        }
    }
}
#endif
