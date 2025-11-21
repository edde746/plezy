//
//  MediaCard.swift
//  Beacon tvOS
//
//  Unified media card component for consistent appearance across the app
//

import SwiftUI

/// Configuration for MediaCard display options
struct MediaCardConfig {
    /// Card dimensions
    let width: CGFloat
    let height: CGFloat

    /// Display options
    let showProgress: Bool
    let showLabel: LabelDisplay
    let showLogo: Bool

    /// Label display mode
    enum LabelDisplay {
        case none           // No label
        case inside         // Label overlaid inside card at bottom
        case outside        // Label below card (deprecated, causes alignment issues)
    }

    /// Predefined sizes for common use cases
    static let continueWatching = MediaCardConfig(
        width: 410,
        height: 231,
        showProgress: true,
        showLabel: .inside,
        showLogo: true
    )

    static let libraryGrid = MediaCardConfig(
        width: 358,
        height: 201,
        showProgress: true,
        showLabel: .inside,
        showLogo: true
    )

    static let seasonPoster = MediaCardConfig(
        width: 290,
        height: 435,
        showProgress: false,
        showLabel: .inside,
        showLogo: false
    )

    static func custom(
        width: CGFloat,
        height: CGFloat,
        showProgress: Bool = true,
        showLabel: LabelDisplay = .inside,
        showLogo: Bool = true
    ) -> MediaCardConfig {
        MediaCardConfig(
            width: width,
            height: height,
            showProgress: showProgress,
            showLabel: showLabel,
            showLogo: showLogo
        )
    }
}

/// Unified media card component that maintains consistent height and appearance
/// All content (image, progress, labels) fits within a fixed frame to prevent layout shifts
struct MediaCard: View {
    let media: PlexMetadata
    let config: MediaCardConfig
    let action: () -> Void

    @EnvironmentObject var authService: PlexAuthService
    @FocusState private var isFocused: Bool

    init(
        media: PlexMetadata,
        config: MediaCardConfig = .continueWatching,
        action: @escaping () -> Void
    ) {
        self.media = media
        self.config = config
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            // Everything inside one fixed-size ZStack
            ZStack(alignment: .bottomLeading) {
                // Layer 1: Background image
                CachedAsyncImage(url: artURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(.regularMaterial.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: config.width * 0.15))
                                .foregroundStyle(.tertiary)
                        )
                }
                .frame(width: config.width, height: config.height)

                // Layer 2: Gradient overlay for better text contrast
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .clear,
                        .black.opacity(config.showLabel == .inside || config.showProgress ? 0.75 : 0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Layer 3: Logo/Title overlay (if enabled and inside)
                if config.showLogo && config.showLabel == .inside {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()

                        HStack {
                            if let logoURL = logoURL, let clearLogo = media.clearLogo {
                                CachedAsyncImage(url: logoURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    cardTitleText
                                }
                                .frame(
                                    maxWidth: config.width * 0.5,
                                    maxHeight: config.height * 0.25
                                )
                                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
                                .id("\(media.id)-\(clearLogo)")
                            } else {
                                cardTitleText
                                    .frame(maxWidth: config.width * 0.5, alignment: .leading)
                            }
                            Spacer()
                        }
                        .padding(.leading, config.width * 0.05)
                        .padding(.bottom, config.showProgress ? config.height * 0.12 : config.height * 0.08)
                    }
                }

                // Layer 4: Progress bar overlay (if enabled)
                if config.showProgress && media.progress > 0 && media.progress < 0.98 {
                    VStack {
                        Spacer()
                        ZStack(alignment: .leading) {
                            // Background capsule
                            Capsule()
                                .fill(.regularMaterial.opacity(0.4))
                                .frame(width: config.width, height: 5)

                            // Progress capsule
                            Capsule()
                                .fill(Color.beaconGradient)
                                .frame(width: config.width * media.progress, height: 5)
                                .shadow(color: Color.beaconMagenta.opacity(0.6), radius: 4, x: 0, y: 0)
                        }
                        .padding(.bottom, 8)
                    }
                }

                // Layer 5: Label text (only if outside mode - deprecated)
                if config.showLabel == .outside {
                    VStack {
                        Spacer()

                        if media.type == "episode" {
                            Text(media.episodeInfo)
                                .font(.system(size: config.width * 0.048, weight: .semibold, design: .default))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(width: config.width, alignment: .leading)
                                .padding(.top, 12)
                                .padding(.horizontal, config.width * 0.05)
                        } else {
                            Text(media.title)
                                .font(.system(size: config.width * 0.048, weight: .semibold, design: .default))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(width: config.width, alignment: .leading)
                                .padding(.top, 12)
                                .padding(.horizontal, config.width * 0.05)
                        }
                    }
                    .padding(.bottom, config.height * 0.08)
                }
            }
            .frame(width: config.width, height: config.height)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge, style: .continuous))
            .shadow(
                color: .black.opacity(isFocused ? 0.6 : 0.4),
                radius: isFocused ? 30 : 16,
                x: 0,
                y: isFocused ? 15 : 8
            )
        }
        .buttonStyle(MediaCardButtonStyle())
        .focused($isFocused)
        .onPlayPauseCommand {
            action()
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Helper Properties

    private var cardTitleText: some View {
        Text(media.type == "episode" ? (media.grandparentTitle ?? media.title) : media.title)
            .font(.system(size: config.width * 0.053, weight: .bold, design: .default))
            .foregroundColor(.white)
            .lineLimit(2)
            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
    }

    private var accessibilityLabel: String {
        if media.type == "episode", let show = media.grandparentTitle {
            var label = "\(show), \(media.title)"
            label += " \(media.formatSeasonEpisode())"
            if media.progress > 0 {
                let percent = Int(media.progress * 100)
                label += ", \(percent)% watched"
            }
            return label
        } else {
            var label = media.title
            if media.progress > 0 {
                let percent = Int(media.progress * 100)
                label += ", \(percent)% watched"
            }
            return label
        }
    }

    private var artURL: URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let art = media.art else {
            return nil
        }

        var urlString = baseURL.absoluteString + art
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }

    private var logoURL: URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let clearLogo = media.clearLogo else {
            return nil
        }

        if clearLogo.starts(with: "http") {
            return URL(string: clearLogo)
        }

        var urlString = baseURL.absoluteString + clearLogo
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }
}

// MARK: - Preview

#Preview {
    // Note: PlexMetadata is Codable and doesn't have a public initializer
    // Preview would require sample JSON data. Use in actual app context.
    VStack {
        Text("MediaCard Preview")
            .font(.title)
        Text("Use within app with actual PlexMetadata")
            .foregroundColor(.gray)
    }
    .frame(width: 500, height: 300)
}
