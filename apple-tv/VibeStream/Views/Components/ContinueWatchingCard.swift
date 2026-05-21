import SwiftUI

struct ContinueWatchingCard: View {
    let item: PlexMetadata
    let baseURL: String
    let token: String
    var onSelect: (() -> Void)?
    var onLongPress: (() -> Void)?

    @Environment(MediaFocusModel.self) private var focusModel
    @FocusState private var isFocused: Bool

    private var imagePath: String? {
        switch item.mediaType {
        case .episode:
            return item.posterThumb(mode: .episodeThumb)
        default:
            // Prefer landscape art/backdrop for movies so all cards are uniform 16:9
            return item.art ?? item.thumb
        }
    }

    private var remainingTime: String? {
        guard let duration = item.duration, let viewOffset = item.viewOffset else { return nil }
        let remainingMs = duration - viewOffset
        guard remainingMs > 0 else { return nil }
        let remainingMinutes = remainingMs / 1000 / 60
        if remainingMinutes >= 60 {
            let hours = remainingMinutes / 60
            let mins = remainingMinutes % 60
            return "\(hours)h \(mins)m left"
        }
        return "\(remainingMinutes)m left"
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PlexImage(
                path: imagePath,
                token: token,
                baseURL: baseURL,
                width: 418,
                aspectRatio: 16/9,
                tmdbId: item.tmdbId,
                mediaType: item.type
            )

            // Bottom gradient scrim for text legibility
            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Overlay content
            VStack(alignment: .leading, spacing: 6) {
                Spacer()

                if item.mediaType == .episode, let subtitle = item.displaySubtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                if let progress = item.watchProgress {
                    HStack(spacing: 8) {
                        ProgressBar(progress: progress)
                            .tint(.white)
                            .frame(height: 6)

                        if let remaining = remainingTime {
                            Text(remaining)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                                .layoutPriority(1)
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 418, height: 418 / (16.0/9.0))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .opacity(isFocused ? 1 : 0)
        )
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
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [item.displayTitle]
        if let subtitle = item.displaySubtitle {
            parts.append(subtitle)
        }
        if let progress = item.watchProgress {
            parts.append("\(Int(progress * 100))% watched")
        }
        if let remaining = remainingTime {
            parts.append(remaining)
        }
        return parts.joined(separator: ", ")
    }
}
