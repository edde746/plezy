import SwiftUI

/// A page's title in its content, where the page names itself rather than its bar (`titleInContent`): a View all's, a
/// collection's, a person's, a music header's, Watch Together's lobby: the title 2 style,
/// semibold, in the text colour, a header to VoiceOver, its lines aligned as the page's text is (`multilineTextAlignment`).
/// `trailing` (a View all's Sort) sits at the row's end with its middle level with the middle of the title's capitals;
/// the title wraps before it narrows. `id` is the title's accessibility identifier.
struct PageHeading<Trailing: View>: View {
    let title: String
    let id: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.onBackground)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(id)
            if Trailing.self != EmptyView.self {
                Spacer(minLength: 0)
                trailing()
                    .layoutPriority(1)
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + Self.capHeight / 2 }
            }
        }
    }

    /// The height of the capitals of the title's font.
    private static var capHeight: CGFloat {
        #if os(macOS)
        NSFont.preferredFont(forTextStyle: .title2).capHeight
        #else
        UIFont.preferredFont(forTextStyle: .title2).capHeight
        #endif
    }
}

extension PageHeading where Trailing == EmptyView {
    init(title: String, id: String) {
        self.init(title: title, id: id) { EmptyView() }
    }
}
