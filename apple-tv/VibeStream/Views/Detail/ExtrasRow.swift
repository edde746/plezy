import SwiftUI

private struct ExtraCard: View {
    let extra: PlexMetadata
    let token: String
    let baseURL: String
    let isFocused: Bool
    let onSelect: () -> Void

    let cardWidth: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PlexImage(
                path: extra.thumb,
                token: token,
                baseURL: baseURL,
                width: cardWidth,
                aspectRatio: 16/9
            )

            // Gradient scrim for text legibility
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Bottom-left overlay: title + play icon + duration
            VStack(alignment: .leading, spacing: 4) {
                Text(extra.title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))

                    if let duration = extra.durationFormatted {
                        Text(duration)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding(12)
        }
        .frame(width: cardWidth, height: cardWidth / (16/9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(isFocused ? 0.6 : 0), lineWidth: 2)
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .onPlayPauseCommand { onSelect() }
        .onTapGesture { onSelect() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(extra.title), \(extra.subtype.map(Self.formatSubtype) ?? "Extra")")
    }

    private static func formatSubtype(_ subtype: String) -> String {
        switch subtype {
        case "behindTheScenes": return "Behind the Scenes"
        case "deletedScenes": return "Deleted Scenes"
        case "featurette": return "Featurette"
        case "interview": return "Interview"
        case "scene": return "Scene"
        case "short": return "Short"
        case "trailer": return "Trailer"
        default:
            return subtype.prefix(1).uppercased() + subtype.dropFirst()
        }
    }
}

struct ExtrasRow: View {
    let extras: [PlexMetadata]
    let baseURL: String
    let token: String
    let onSelect: (PlexMetadata) -> Void
    var title: String = "Trailers & Extras"
    var cardWidth: CGFloat = 300

    @FocusState private var focusedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(Array(extras.enumerated()), id: \.element.id) { index, extra in
                        ExtraCard(
                            extra: extra,
                            token: token,
                            baseURL: baseURL,
                            isFocused: focusedIndex == index,
                            onSelect: { onSelect(extra) },
                            cardWidth: cardWidth
                        )
                        .focused($focusedIndex, equals: index)
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 10)
            }
            .focusSection()
        }
    }
}
