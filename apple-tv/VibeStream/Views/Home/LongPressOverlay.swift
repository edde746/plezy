import SwiftUI

struct LongPressOverlay: View {
    let item: PlexMetadata
    let baseURL: String
    let token: String
    let isContinueWatching: Bool
    var onDismiss: () -> Void
    var onResume: ((Int) -> Void)?
    var onPlayFromBeginning: (() -> Void)?
    var onPlay: (() -> Void)?
    var onRemoveFromContinueWatching: (() -> Void)?
    var onMarkWatched: (() -> Void)?
    var onMarkUnwatched: (() -> Void)?
    var onMoreInfo: (() -> Void)?

    @FocusState private var focusedButton: ButtonID?

    private enum ButtonID: Hashable {
        case resume
        case startFromBeginning
        case play
        case removeContinueWatching
        case markWatched
        case markUnwatched
        case moreInfo
    }

    private var firstButton: ButtonID {
        if let viewOffset = item.viewOffset, viewOffset > 0 {
            return .resume
        }
        return .play
    }

    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            // Content
            HStack(alignment: .center, spacing: 60) {
                // Left side: Poster + title
                VStack(spacing: 16) {
                    PlexImage(
                        path: item.posterThumb(),
                        token: token,
                        baseURL: baseURL,
                        width: 400,
                        aspectRatio: 2.0 / 3.0,
                        tmdbId: item.tmdbId,
                        mediaType: item.type
                    )
                    .frame(width: 400, height: 600)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(spacing: 4) {
                        Text(item.displayTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)

                        if let year = item.year {
                            Text(String(year))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .frame(width: 400)
                }

                // Right side: Action buttons
                VStack(spacing: 12) {
                    if let viewOffset = item.viewOffset, viewOffset > 0 {
                        overlayButton(
                            "Resume from \(viewOffset.durationFormatted)",
                            icon: "play.fill",
                            id: .resume
                        ) {
                            onResume?(viewOffset)
                        }

                        overlayButton(
                            "Start from Beginning",
                            icon: "backward.end.fill",
                            id: .startFromBeginning
                        ) {
                            onPlayFromBeginning?()
                        }
                    } else {
                        overlayButton(
                            "Play",
                            icon: "play.fill",
                            id: .play
                        ) {
                            onPlay?()
                        }
                    }

                    if isContinueWatching {
                        overlayButton(
                            "Remove from Continue Watching",
                            icon: "xmark.circle",
                            id: .removeContinueWatching
                        ) {
                            onRemoveFromContinueWatching?()
                        }
                    }

                    if item.isWatched || (item.viewOffset ?? 0) > 0 {
                        overlayButton(
                            "Mark as Unwatched",
                            icon: "eye.slash",
                            id: .markUnwatched
                        ) {
                            onMarkUnwatched?()
                        }
                    } else {
                        overlayButton(
                            "Mark as Watched",
                            icon: "eye",
                            id: .markWatched
                        ) {
                            onMarkWatched?()
                        }
                    }

                    overlayButton(
                        "More Info",
                        icon: "info.circle",
                        id: .moreInfo
                    ) {
                        onMoreInfo?()
                    }
                }
            }
        }
        .focusSection()
        .onExitCommand {
            onDismiss()
        }
        .onAppear {
            focusedButton = firstButton
        }
    }

    @ViewBuilder
    private func overlayButton(_ title: String, icon: String, id: ButtonID, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(width: 500, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(focusedButton == id ? .white : .white.opacity(0.15))
        )
        .foregroundStyle(focusedButton == id ? .black : .white)
        .focusable()
        .focused($focusedButton, equals: id)
        .onTapGesture { action() }
    }
}

// MARK: - TV Long Press Modifier

/// Fires the action during the hold (at the duration mark), not on release.
/// Uses the `pressing` callback to start an async timer that fires while
/// the user is still pressing.
private struct TVLongPressModifier: ViewModifier {
    let duration: TimeInterval
    let action: () -> Void

    @State private var pressTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: duration, pressing: { pressing in
                if pressing {
                    pressTask?.cancel()
                    pressTask = Task {
                        try? await Task.sleep(for: .seconds(duration))
                        guard !Task.isCancelled else { return }
                        action()
                    }
                } else {
                    pressTask?.cancel()
                    pressTask = nil
                }
            }, perform: {})
    }
}

extension View {
    func onTVLongPress(duration: TimeInterval = 2.0, perform action: @escaping () -> Void) -> some View {
        modifier(TVLongPressModifier(duration: duration, action: action))
    }
}
