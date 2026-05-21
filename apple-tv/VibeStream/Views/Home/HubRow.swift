import SwiftUI

struct HubRow: View {
    let title: String
    let items: [PlexMetadata]
    let baseURL: String
    let token: String
    var cardWidth: CGFloat = 242
    var onItemSelected: ((PlexMetadata) -> Void)?
    var onItemLongPressed: ((PlexMetadata) -> Void)?
    var onSeeAll: (() -> Void)?

    @FocusState private var seeAllFocused: Bool

    private var cardHeight: CGFloat {
        let wide = items.first?.usesWideAspectRatio ?? false
        let aspectRatio: CGFloat = wide ? 16.0 / 9.0 : 2.0 / 3.0
        return cardWidth / aspectRatio
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(items) { item in
                        MediaCard(
                            item: item,
                            baseURL: baseURL,
                            token: token,
                            width: cardWidth,
                            onSelect: { onItemSelected?(item) },
                            onLongPress: { onItemLongPressed?(item) }
                        )
                    }

                    if onSeeAll != nil {
                        VStack(spacing: 12) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 44))
                            Text("See All")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white.opacity(seeAllFocused ? 1 : 0.5))
                        .frame(width: 140)
                        .scaleEffect(seeAllFocused ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: seeAllFocused)
                        .focusable()
                        .focused($seeAllFocused)
                        .onPlayPauseCommand { onSeeAll?() }
                        .onTapGesture { onSeeAll?() }
                    }
                }
                .focusSection()
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
            }
        }
    }
}
