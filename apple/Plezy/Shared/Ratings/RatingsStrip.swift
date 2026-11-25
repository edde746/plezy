import SwiftUI
import PlezyKit

/// The inline scores row (a detail page's scores, a spotlight's): one badge per score in order, each its source's logo
/// `iconSize` tall in the logo's own aspect, or a star (people for the audience) without one, then the value `iconGap`
/// after it; `entryGap` between badges, wrapping onto more lines, or with `oneLine` on one line, the badges that don't
/// fit left out. `ratings` are an item's own with the trackers' community scores merged in. Brand
/// logos keep their colours; tracker marks, the generic icons and the values draw in the foreground style. Sizes are in
/// the shared layouts' units, following Dynamic Type. One element for VoiceOver, read "<source> <value>, …"
/// (`ratingsSemanticLabel`); each badge's tooltip (pointer hover) reads its own score the same way (the people icon's:
/// "Audience 8"). Nothing without scores. Harness names: `ratings.strip`, each badge `ratings.badge.<source>` (`rating`
/// for an unattributed score).
struct RatingsStrip: View {
    let ratings: [MediaRatingSource]
    var textSize: CGFloat = 13
    var weight: Font.Weight = .bold
    var iconSize: CGFloat = 16
    var iconGap: CGFloat = 4
    var entryGap: CGFloat = 10
    var oneLine = false
    var alignment: HorizontalAlignment = .leading

    @ScaledMetric(relativeTo: .footnote) private var scale: CGFloat = 1
    @Environment(\.dimens) private var dimens

    var body: some View {
        if !ratings.isEmpty {
            let badges = RatingBadgesKt.inlineRatingBadges(ratings: ratings)
            let entries = Array(zip(ratings, badges).enumerated())
            Group {
                if oneLine {
                    // The longest run of badges that fits, from all of them down to the first alone.
                    ViewThatFits(in: .horizontal) {
                        ForEach((1...entries.count).reversed(), id: \.self) { count in
                            HStack(spacing: entryGap * size) {
                                ForEach(entries.prefix(count), id: \.offset) { badge($0.element.1, rating: $0.element.0) }
                            }
                        }
                    }
                } else {
                    FlowLayout(spacing: entryGap * size, lineSpacing: 4 * size, alignment: alignment) {
                        ForEach(entries, id: \.offset) { badge($0.element.1, rating: $0.element.0) }
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(RatingBadgesKt.ratingsSemanticLabel(ratings: ratings))
            .accessibilityIdentifier("ratings.strip")
        }
    }

    /// Points per size unit: the shared layouts' unit, scaled with the text.
    private var size: CGFloat { dimens.unit * scale }

    private func badge(_ badge: InlineRatingBadge, rating: MediaRatingSource) -> some View {
        HStack(spacing: iconGap * size) {
            if let icon = badge.icon {
                RatingLogo(icon: icon, height: iconSize * size)
            } else {
                Image(systemName: badge.generic == .people ? "person.2.fill" : "star.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize * size, height: iconSize * size)
            }
            Text(badge.value)
                .font(.system(size: textSize * size, weight: weight))
                .monospacedDigit()
        }
        .lineLimit(1)
        .fixedSize()
        .help(RatingBadgesKt.ratingsSemanticLabel(ratings: [rating]))
        .accessibilityIdentifier("ratings.badge.\(rating.source.isEmpty ? "rating" : rating.source)")
    }
}
