import SwiftUI

struct MediaGrid: View {
    let items: [PlexMetadata]
    let baseURL: String
    let token: String
    var cardWidth: CGFloat = 220
    var onItemSelected: ((PlexMetadata) -> Void)?
    var onLoadMore: (() async -> Void)?

    private var columns: [GridItem] {
        let first = items.first
        let isWide: Bool = {
            guard let item = first else { return false }
            if item.mediaType == .episode && item.grandparentThumb != nil {
                return false
            }
            return item.usesWideAspectRatio
        }()
        let itemWidth = isWide ? cardWidth * 1.6 : cardWidth
        return [GridItem(.adaptive(minimum: itemWidth, maximum: itemWidth + 40), spacing: 40)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 40) {
            ForEach(items) { item in
                MediaCard(
                    item: item,
                    baseURL: baseURL,
                    token: token,
                    width: cardWidth,
                    onSelect: { onItemSelected?(item) }
                )
                .task {
                    if item == items.last {
                        await onLoadMore?()
                    }
                }
            }
        }
        .focusSection()
        .padding(.horizontal, 50)
    }
}
