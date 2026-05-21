import SwiftUI

struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct MediaCard: View {
    let item: PlexMetadata
    let baseURL: String
    let token: String
    var width: CGFloat = 242
    var showTitle: Bool = true
    var onSelect: (() -> Void)?
    var onLongPress: (() -> Void)?

    @Environment(MediaFocusModel.self) private var focusModel
    @FocusState private var isFocused: Bool

    private var aspectRatio: CGFloat {
        if item.mediaType == .episode && item.grandparentThumb != nil {
            return 2/3
        }
        return item.usesWideAspectRatio ? 16/9 : 2/3
    }

    private var posterPath: String? {
        item.posterThumb()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                PlexImage(
                    path: posterPath,
                    token: token,
                    baseURL: baseURL,
                    width: width,
                    aspectRatio: aspectRatio,
                    tmdbId: item.tmdbId,
                    mediaType: item.type
                )

                // Watch progress bar
                if let progress = item.watchProgress {
                    ProgressBar(progress: progress)
                        .frame(height: 4)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                }

                // Watched indicator
                if item.isWatched {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }

                // Unwatched count badge
                if let count = item.unwatchedCount {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue)
                        .clipShape(Capsule())
                        .padding(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(width: width, height: width / aspectRatio)
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

            if showTitle {
                Text(item.displayTitle)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(width: width, alignment: .leading)

                if let subtitle = item.displaySubtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(width: width, alignment: .leading)
                } else if let year = item.year {
                    Text(String(year))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: width, alignment: .leading)
                }
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
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [item.displayTitle]
        if let subtitle = item.displaySubtitle {
            parts.append(subtitle)
        } else if let year = item.year {
            parts.append(String(year))
        }
        if item.isWatched {
            parts.append("Watched")
        } else if let count = item.unwatchedCount {
            parts.append("\(count) unwatched")
        } else if let progress = item.watchProgress {
            parts.append("\(Int(progress * 100))% watched")
        }
        return parts.joined(separator: ", ")
    }
}
