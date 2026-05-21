import SwiftUI

// MARK: - Trending Card

private struct TrendingCard: View {
    let rank: Int
    let item: PlexMetadata
    let baseURL: String
    let token: String
    var onSelect: (() -> Void)?
    var onLongPress: (() -> Void)?

    @Environment(MediaFocusModel.self) private var focusModel
    @FocusState private var isFocused: Bool

    private let cardWidth: CGFloat = 200
    private let aspectRatio: CGFloat = 2.0 / 3.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                PlexImage(
                    path: item.posterThumb(),
                    token: token,
                    baseURL: baseURL,
                    width: cardWidth,
                    aspectRatio: aspectRatio,
                    tmdbId: item.tmdbId,
                    mediaType: item.type
                )
                .frame(width: cardWidth, height: cardWidth / aspectRatio)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .opacity(isFocused ? 1 : 0)
                )

                // Rank badge overlay on top-left of poster
                Text("\(rank)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 8, x: 1, y: 1)
                    .shadow(color: .black.opacity(0.6), radius: 3)
                    .padding(.leading, 10)
                    .padding(.top, 6)
            }

            Text(item.displayTitle)
                .font(.caption)
                .lineLimit(1)
                .frame(width: cardWidth, alignment: .leading)

            if let year = item.year {
                Text(String(year))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: cardWidth, alignment: .leading)
            }
        }
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onChange(of: isFocused) { _, focused in
            if focused {
                focusModel.updateFocus(item)
            }
        }
        .onPlayPauseCommand {
            onSelect?()
        }
        .onTapGesture {
            onSelect?()
        }
        .onTVLongPress(duration: 1.0) {
            onLongPress?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Number \(rank), \(item.displayTitle)")
    }
}

// MARK: - Trending Row

struct TrendingRow: View {
    let title: String
    let items: [(rank: Int, metadata: PlexMetadata)]
    let baseURL: String
    let token: String
    var onItemSelected: ((PlexMetadata) -> Void)?
    var onItemLongPressed: ((PlexMetadata) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 40) {
                    ForEach(items, id: \.metadata.ratingKey) { item in
                        TrendingCard(
                            rank: item.rank,
                            item: item.metadata,
                            baseURL: baseURL,
                            token: token,
                            onSelect: { onItemSelected?(item.metadata) },
                            onLongPress: { onItemLongPressed?(item.metadata) }
                        )
                    }
                }
                .focusSection()
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
            }
        }
    }
}
